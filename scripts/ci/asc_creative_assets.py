"""App Store creative assets (the product page Header and the Search Results image) for the editable iOS version.

  show   prints the asset library, the reference data and what each version localization has placed now.
  apply  uploads header.png once and search-<lang>.png once per language from the folder given, then places
         them on every localization of the editable version (replacing any earlier placement of the same kind).

This never creates a review submission: the art goes to App Review with the version when it is submitted.
Uses the App Asset Library API (appAssetLibraryImages + appAssetLibraryPlacements).
"""
import json
import os
import sys
import time
import urllib.error
import urllib.request

from asc_signing import API, app_id, token
from asc_listings import targets

HEADER, SEARCH = "PRODUCT_PAGE_HEADER_ASSET", "APP_STORE_SEARCH_RESULTS_ASSET"
# Which search image each store locale gets; English and Spanish locales share one.
LANG = {"en-US": "en", "en-GB": "en", "en-AU": "en", "en-CA": "en", "es-ES": "es", "es-MX": "es",
        "de-DE": "de-DE", "fr-FR": "fr-FR", "it": "it", "nl-NL": "nl-NL", "pt-BR": "pt-BR", "sv": "sv"}


def req(method, path, body=None):
    """Like asc_signing.call, but returns (status, json) instead of exiting, so a refusal can be read."""
    r = urllib.request.Request(f"{API}/{path}", method=method, data=json.dumps(body).encode() if body else None,
                               headers={"Authorization": f"Bearer {token()}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(r) as resp:
            raw = resp.read()
            return resp.status, (json.loads(raw) if raw else {})
    except urllib.error.HTTPError as e:
        raw = e.read() or b"{}"
        try:
            return e.code, json.loads(raw)
        except ValueError:
            return e.code, {"raw": raw.decode(errors="replace")[:500]}


def must(method, path, body=None):
    code, data = req(method, path, body)
    if code >= 300:
        print(f"::error title={method} {path.split('?')[0]} failed ({code})::{errors(data)}")
        raise SystemExit(1)
    return data


def errors(data):
    return "; ".join(f"{x.get('code', '')} {x.get('title', '')}: {x.get('detail', '')}" for x in data.get("errors", [])) or json.dumps(data)[:400]


def short(obj, n=3000):
    s = json.dumps(obj, indent=1)
    return s if len(s) <= n else s[:n] + f"\n... ({len(s)} chars)"


def library(aid):
    data = must("GET", f"apps/{aid}/assetLibrary")["data"]
    print("Asset library:", data["id"])
    return data["id"]


def placements(loc_id):
    code, data = req("GET", f"appStoreVersionLocalizations/{loc_id}/placements?include=image")
    if code >= 300:
        print(f"  placements read refused ({code}): {errors(data)}")
        return []
    imgs = {i["id"]: i["attributes"] for i in data.get("included", [])}
    out = []
    for p in data.get("data", []):
        img = (p.get("relationships", {}).get("image", {}).get("data") or {}).get("id")
        a = imgs.get(img, {})
        out.append({"id": p["id"], **p["attributes"], "image": img, "file": a.get("fileName"), "imageState": a.get("state")})
    return out


def localizations(version):
    return must("GET", f"appStoreVersions/{version['id']}/appStoreVersionLocalizations?limit=50")["data"]


def icons(aid):
    """The icon Apple took from each recent build (what TestFlight and App Store Connect show)."""
    res = must("GET", f"builds?filter[app]={aid}&sort=-uploadedDate&limit=4&fields[builds]=version,processingState,uploadedDate,iconAssetToken")
    for b in res["data"]:
        a = b["attributes"]
        t = a.get("iconAssetToken") or {}
        url = (t.get("templateUrl") or "").replace("{w}", "512").replace("{h}", "512").replace("{f}", "png")
        print(f"Build {a['version']} {a['processingState']} {a['uploadedDate']} icon: {url or 'none'}")
        if url and os.environ.get("DUMP_ICONS"):
            import base64
            small = url.replace("512x512bb", "256x256bb")
            with urllib.request.urlopen(small) as r:
                print(f"ICON {a['version']} " + base64.b64encode(r.read()).decode())
    _, version = targets(aid)
    code, data = req("GET", f"appStoreVersions/{version['id']}/build")
    b = (data.get("data") or {}) if code < 300 else {}
    a = b.get("attributes") or {}
    print("Build attached to", version["attributes"]["versionString"], ":", a.get("version", "none"), a.get("uploadedDate"))
    t = (a.get("iconAssetToken") or {}).get("templateUrl")
    if t and os.environ.get("DUMP_ICONS"):
        import base64
        with urllib.request.urlopen(t.replace("{w}", "256").replace("{h}", "256").replace("{f}", "png")) as r:
            print(f"ICON attached-{a.get('version')} " + base64.b64encode(r.read()).decode())


def show(_folder=None):
    aid = app_id()
    icons(aid)
    library(aid)
    code, ref = req("GET", "appAssetLibraryRefData")
    print(f"Reference data ({code}):\n{short(ref, 6000)}")
    _, version = targets(aid)
    print("Version:", version["attributes"]["versionString"], version["id"])
    for loc in localizations(version):
        print(loc["attributes"]["locale"], loc["id"], placements(loc["id"]))


def upload(lib, path):
    size = os.path.getsize(path)
    name = os.path.basename(path)
    data = must("POST", "appAssetLibraryImages", {"data": {"type": "appAssetLibraryImages", "attributes": {
        "category": "CREATIVE_ASSETS", "fileName": name, "fileSize": size},
        "relationships": {"assetLibrary": {"data": {"type": "appAssetLibraries", "id": lib}}}}})["data"]
    blob = open(path, "rb").read()
    for op in data["attributes"].get("uploadOperations") or []:
        part = blob[op["offset"]:op["offset"] + op["length"]]
        headers = {h["name"]: h["value"] for h in op.get("requestHeaders") or []}
        with urllib.request.urlopen(urllib.request.Request(op["url"], data=part, method=op["method"], headers=headers)) as r:
            r.read()
    must("PATCH", f"appAssetLibraryImages/{data['id']}", {"data": {"type": "appAssetLibraryImages", "id": data["id"],
                                                                   "attributes": {"uploaded": True}}})
    attrs = {}
    for _ in range(60):   # about 5 minutes
        attrs = must("GET", f"appAssetLibraryImages/{data['id']}")["data"]["attributes"]
        if attrs.get("state") not in {"AWAITING_UPLOAD", "UPLOAD_COMPLETE", "PROCESSING", None}:  # ready reads PREPARE_FOR_SUBMISSION
            break
        time.sleep(5)
    shown = {k: v for k, v in attrs.items() if k != "uploadOperations"}
    print(f"{name}: image {data['id']} {short(shown, 1200)}")
    if attrs.get("state") in {"FAILED", "REJECTED"}:
        print(f"::error title={name} was refused::{attrs.get('stateDetails') or attrs.get('state')}")
        raise SystemExit(1)
    return data["id"], attrs


def place(loc_id, kind, image_id):
    # The reference data allows one of each in the DEFAULT_PROFILE group per localization.
    data = must("POST", "appAssetLibraryPlacements", {"data": {
        "type": "appAssetLibraryPlacements", "attributes": {"placementType": kind, "placementGroup": "DEFAULT_PROFILE"},
        "relationships": {"appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations", "id": loc_id}},
                          "image": {"data": {"type": "appAssetLibraryImages", "id": image_id}}}}})
    return data["data"]["id"]


def apply(folder):
    aid = app_id()
    lib = library(aid)
    _, version = targets(aid)
    print("Version:", version["attributes"]["versionString"], version["id"])
    locs = localizations(version)
    missing = [l["attributes"]["locale"] for l in locs if l["attributes"]["locale"] not in LANG]
    if missing:
        print(f"::error title=No search image for {missing}::Add them to LANG and render their images first.")
        raise SystemExit(1)
    header, _ = upload(lib, os.path.join(folder, "header.png"))
    search = {}
    for lang in sorted({LANG[l["attributes"]["locale"]] for l in locs}):
        search[lang] = upload(lib, os.path.join(folder, f"search-{lang}.png"))
    summary = []
    for loc in locs:
        locale = loc["attributes"]["locale"]
        for p in placements(loc["id"]):
            if p.get("placementType") in {HEADER, SEARCH}:
                must("DELETE", f"appAssetLibraryPlacements/{p['id']}")
                print(f"{locale}: removed earlier {p.get('placementType')} placement {p['id']}")
        sid, _ = search[LANG[locale]]
        place(loc["id"], HEADER, header)
        place(loc["id"], SEARCH, sid)
        now = placements(loc["id"])
        summary.append((locale, [(p.get("placementType"), p.get("file"), p.get("state")) for p in now]))
        print(f"{locale}: {now}")
    print(f"::notice title=Creative assets placed::{summary}")


if __name__ == "__main__":
    {"show": show, "apply": apply}[sys.argv[1]](sys.argv[2] if len(sys.argv) > 2 else None)
