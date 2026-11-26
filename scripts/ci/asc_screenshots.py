"""Uploads one iPhone screenshot set to every language of the version being prepared in App Store Connect.

  show  DIR   prints the screenshot sets each language has now, and changes nothing.
  apply DIR   uploads DIR/*.png, in name order, as the 6.9-inch iPhone set of every language, then puts them in
              that order and waits for Apple to finish processing them. A set that already holds other files is
              left alone; a set holding only these files (an earlier, unfinished run) is redone. Nothing is submitted.

Needs the same key setup as asc_signing.py.
"""
import glob
import hashlib
import os
import sys
import time
import urllib.request

from asc_signing import app_id, call
from asc_listings import targets

DISPLAY = "APP_IPHONE_67"   # the 6.9-inch slot (1320 x 2868) in the API


def sets_of(loc_id):
    out = {}
    for s in call("GET", f"appStoreVersionLocalizations/{loc_id}/appScreenshotSets?limit=50")["data"]:
        shots = call("GET", f"appScreenshotSets/{s['id']}/appScreenshots?limit=50")["data"]
        out[s["attributes"]["screenshotDisplayType"]] = (s["id"], shots)
    return out


def upload(set_id, path):
    data = open(path, "rb").read()
    shot = call("POST", "appScreenshots", {"data": {"type": "appScreenshots",
                "attributes": {"fileName": os.path.basename(path), "fileSize": len(data)},
                "relationships": {"appScreenshotSet": {"data": {"type": "appScreenshotSets", "id": set_id}}}}})["data"]
    for op in shot["attributes"]["uploadOperations"]:
        part = data[op["offset"]:op["offset"] + op["length"]]
        req = urllib.request.Request(op["url"], data=part, method=op["method"],
                                     headers={h["name"]: h["value"] for h in op.get("requestHeaders") or []})
        urllib.request.urlopen(req).read()
    call("PATCH", f"appScreenshots/{shot['id']}", {"data": {"type": "appScreenshots", "id": shot["id"], "attributes": {
        "uploaded": True, "sourceFileChecksum": hashlib.md5(data).hexdigest()}}})
    return shot["id"]


def main(mode, folder):
    files = sorted(glob.glob(os.path.join(folder, "*.png")))
    names = [os.path.basename(f) for f in files]
    print(f"{len(files)} files: {names}")
    if not files:
        raise SystemExit("No screenshots found")
    _, version = targets(app_id())
    locs = {l["attributes"]["locale"]: l["id"] for l in
            call("GET", f"appStoreVersions/{version['id']}/appStoreVersionLocalizations?limit=50")["data"]}
    pending, failed = [], []
    for locale, loc_id in sorted(locs.items()):
        have = sets_of(loc_id)
        print(f"NOW {locale}: " + (", ".join(f"{k} {len(v[1])}" for k, v in have.items()) or "no screenshots"))
        if mode != "apply":
            continue
        set_id, shots = have.get(DISPLAY, (None, []))
        current = [s["attributes"]["fileName"] for s in shots]
        done = [s["attributes"].get("assetDeliveryState", {}).get("state") for s in shots]
        if current == names and all(d == "COMPLETE" for d in done):
            print(f"SKIP {locale}: already has this set")
            continue
        if current and not set(current) <= set(names):
            print(f"::error title=Left alone::{locale} already has other {DISPLAY} screenshots: {current}")
            failed.append(locale)
            continue
        try:
            for s in shots:
                call("DELETE", f"appScreenshots/{s['id']}")
            if not set_id:
                set_id = call("POST", "appScreenshotSets", {"data": {"type": "appScreenshotSets",
                              "attributes": {"screenshotDisplayType": DISPLAY}, "relationships": {
                                  "appStoreVersionLocalization": {"data": {"type": "appStoreVersionLocalizations",
                                                                           "id": loc_id}}}}})["data"]["id"]
            ids = [upload(set_id, f) for f in files]
            call("PATCH", f"appScreenshotSets/{set_id}/relationships/appScreenshots",
                 {"data": [{"type": "appScreenshots", "id": i} for i in ids]})
            pending.append((locale, set_id))
            print(f"UPLOADED {locale}")
        except SystemExit:
            failed.append(locale)
    for _ in range(40):   # up to about 10 minutes for Apple to process them
        if not pending:
            break
        time.sleep(15)
        still = []
        for locale, set_id in pending:
            shots = call("GET", f"appScreenshotSets/{set_id}/appScreenshots?limit=50")["data"]
            states = [s["attributes"].get("assetDeliveryState", {}) for s in shots]
            if any(s.get("state") == "FAILED" for s in states):
                print(f"::error title=Processing failed::{locale}: {[s.get('errors') for s in states if s.get('errors')]}")
                failed.append(locale)
            elif all(s.get("state") == "COMPLETE" for s in states):
                print(f"READY {locale}: {[s['attributes']['fileName'] for s in shots]}")
            else:
                still.append((locale, set_id))
        pending = still
    if pending:
        print(f"::warning title=Still processing::{[l for l, _ in pending]}")
    if failed:
        print(f"::error title=Screenshots not done::{', '.join(failed)}")
        raise SystemExit(1)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
