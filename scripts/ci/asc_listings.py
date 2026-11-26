"""Puts the store listings in store/listing/<locale>/ into App Store Connect, text only.

  show   prints what App Store Connect has now and what each locale would get, and changes nothing.
  apply  writes name and subtitle (app info) and description, keywords and promotional text (the version
         being prepared), creating the locales that don't exist yet. New locales copy the privacy policy,
         support and marketing URLs from the primary locale. Screenshots and submitting are left alone.

Needs the same key setup as asc_signing.py (ASC_KEY_ID, ASC_ISSUER_ID, $RUNNER_TEMP/AuthKey_<id>.p8).
"""
import os
import sys

from asc_signing import app_id, call

ROOT = os.path.join(os.path.dirname(__file__), "..", "..", "store", "listing")
EDITABLE = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED", "INVALID_BINARY"}
INFO_FIELDS = {"name": "name.txt", "subtitle": "subtitle.txt"}
VERSION_FIELDS = {"description": "description.txt", "keywords": "keywords.txt", "promotionalText": "promotional_text.txt"}
COPIED_INFO = ["privacyPolicyUrl"]
COPIED_VERSION = ["supportUrl", "marketingUrl"]


def planned():
    out = {}
    for locale in sorted(os.listdir(ROOT)):
        folder = os.path.join(ROOT, locale)
        if not os.path.isdir(folder):
            continue
        read = lambda f: open(os.path.join(folder, f), encoding="utf-8").read().strip()
        out[locale] = ({k: read(f) for k, f in INFO_FIELDS.items()}, {k: read(f) for k, f in VERSION_FIELDS.items()})
    return out


def state(attrs):
    return attrs.get("appVersionState") or attrs.get("appStoreState") or attrs.get("state")


def targets(aid):
    infos = call("GET", f"apps/{aid}/appInfos")["data"]
    info = next((i for i in infos if state(i["attributes"]) not in {"READY_FOR_DISTRIBUTION", "READY_FOR_SALE"}), None)
    versions = call("GET", f"apps/{aid}/appStoreVersions?filter[platform]=IOS&limit=20")["data"]
    version = next((v for v in versions if state(v["attributes"]) in EDITABLE), None)
    print("App info:", [(i["id"], state(i["attributes"])) for i in infos])
    print("iOS versions:", [(v["attributes"]["versionString"], state(v["attributes"])) for v in versions])
    if not info or not version:
        print("::error title=Nothing editable::App Store Connect has no app info or iOS version open for editing.")
        raise SystemExit(1)
    return info["id"], version


def short(value):
    value = (value or "").replace("\n", " / ")
    return value if len(value) <= 90 else value[:87] + "..."


def main(mode):
    aid = app_id()
    app = call("GET", f"apps/{aid}")["data"]["attributes"]
    primary = app.get("primaryLocale")
    print(f"App {app.get('name')} ({app.get('bundleId')}), primary locale {primary}")
    info_id, version = targets(aid)
    print(f"Writing to version {version['attributes']['versionString']}")
    info_locs = {l["attributes"]["locale"]: l for l in call("GET", f"appInfos/{info_id}/appInfoLocalizations?limit=50")["data"]}
    ver_locs = {l["attributes"]["locale"]: l for l in
                call("GET", f"appStoreVersions/{version['id']}/appStoreVersionLocalizations?limit=50")["data"]}
    base_info = info_locs.get(primary, {}).get("attributes", {})
    base_ver = ver_locs.get(primary, {}).get("attributes", {})
    print("Primary URLs:", {k: base_info.get(k) for k in COPIED_INFO}, {k: base_ver.get(k) for k in COPIED_VERSION})
    for locale in sorted(set(info_locs) | set(ver_locs)):
        a, b = info_locs.get(locale, {}).get("attributes", {}), ver_locs.get(locale, {}).get("attributes", {})
        print(f"NOW {locale}: name={a.get('name')!r} subtitle={a.get('subtitle')!r} keywords={short(b.get('keywords'))!r}")
        print(f"    description={short(b.get('description'))!r} promo={short(b.get('promotionalText'))!r}")
    failed = []
    for locale, (info, ver) in planned().items():
        action_i = "update" if locale in info_locs else "create"
        action_v = "update" if locale in ver_locs else "create"
        print(f"PLAN {locale}: app info {action_i}, version {action_v}: name={info['name']!r} subtitle={info['subtitle']!r}")
        if mode != "apply":
            continue
        try:
            if locale in info_locs:
                call("PATCH", f"appInfoLocalizations/{info_locs[locale]['id']}", {"data": {
                    "type": "appInfoLocalizations", "id": info_locs[locale]["id"], "attributes": info}})
            else:
                attrs = dict(info, locale=locale, **{k: base_info[k] for k in COPIED_INFO if base_info.get(k)})
                call("POST", "appInfoLocalizations", {"data": {"type": "appInfoLocalizations", "attributes": attrs,
                     "relationships": {"appInfo": {"data": {"type": "appInfos", "id": info_id}}}}})
            if locale in ver_locs:
                call("PATCH", f"appStoreVersionLocalizations/{ver_locs[locale]['id']}", {"data": {
                    "type": "appStoreVersionLocalizations", "id": ver_locs[locale]["id"], "attributes": ver}})
            else:
                attrs = dict(ver, locale=locale, **{k: base_ver[k] for k in COPIED_VERSION if base_ver.get(k)})
                call("POST", "appStoreVersionLocalizations", {"data": {"type": "appStoreVersionLocalizations",
                     "attributes": attrs, "relationships": {"appStoreVersion": {"data": {
                         "type": "appStoreVersions", "id": version["id"]}}}}})
            print(f"DONE {locale}")
        except SystemExit:
            failed.append(locale)
    if failed:
        print(f"::error title=Listings not written::{', '.join(failed)}")
        raise SystemExit(1)
    if mode == "apply":
        print(f"::notice title=Listings written::{', '.join(planned())}")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "show")
