"""Creates DayXero's plans in App Store Connect and wires them up in RevenueCat (S3.11).

Safe to run again: anything that already exists is left as it is.

  App Store Connect (ASC_KEY_ID, ASC_ISSUER_ID, $RUNNER_TEMP/AuthKey_<id>.p8):
    subscription group "DayXero Pro" with dayxero.annual (3-day free trial) and dayxero.quarterly, the two plans the
    app sells (16 Nov 2026), plus dayxero.monthly and the non-consumable dayxero.lifetime, which are no longer on
    the paywall but stay for anyone who bought them. English names, prices in every territory, review screenshots.
  "check" only reads App Store Connect and RevenueCat and prints what App Review will see.
  RevenueCat (RC_SECRET_KEY, RC_PROJECT_ID; skipped when not set):
    the four products, the "pro" entitlement, and the current "default" offering with
    $rc_annual, $rc_three_month, $rc_monthly and $rc_lifetime packages. Prints the app's public SDK key.
"""
import hashlib
import json
import os
import sys
import time
import urllib.error
import urllib.request

import jwt

BUNDLE_ID = "in.dayxero.app"
GROUP = "DayXero Pro"
SUBSCRIPTIONS = [
    # product ID, reference name, period, level, USD price, App Store name (30 max) and description (55 max)
    ("dayxero.annual", "Annual", "ONE_YEAR", 1, "39.99", "DayXero Pro Annual",
     "Full quit program, insights and NRT planner, yearly."),
    ("dayxero.quarterly", "Quarterly", "THREE_MONTHS", 2, "19.99", "DayXero Pro 3 Months",
     "Full quit program, insights and NRT planner, 3 months."),
    ("dayxero.monthly", "Monthly", "ONE_MONTH", 2, "9.99", "DayXero Pro Monthly",
     "Full quit program, insights and NRT planner, monthly."),
]
LIFETIME = ("dayxero.lifetime", "Lifetime", "79.99", "DayXero Pro Lifetime",
            "Full quit program, insights and NRT planner, for good.")
# 3 days, sold on the paywall after onboarding (16 Nov 2026). Only applied where no trial is set yet; change a live
# one in App Store Connect.
TRIAL = {"dayxero.annual": "THREE_DAYS"}
# Prices set by hand instead of Apple's equivalent of the US price: product ID -> territory -> price there.
# Only applied when the product's prices are first set; change a live price in App Store Connect.
LOCAL_PRICES = {"dayxero.quarterly": {"IND": "1499"}}
REVIEW_NOTE = "Unlocks DayXero Pro. The paywall appears after onboarding and from the program, NRT plan and heatmaps."
SCREENSHOT = os.environ.get("REVIEW_SCREENSHOT", "")


# MARK: App Store Connect

def asc_token():
    kid = os.environ["ASC_KEY_ID"].strip()
    key = open(os.path.join(os.environ["RUNNER_TEMP"], f"AuthKey_{kid}.p8")).read()
    now = int(time.time())
    return jwt.encode({"iss": os.environ["ASC_ISSUER_ID"].strip(), "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
                      key, algorithm="ES256", headers={"kid": kid, "typ": "JWT"})


def request(method, url, body=None, headers=None, ok=(200, 201, 204)):
    data = json.dumps(body).encode() if isinstance(body, dict) else body
    req = urllib.request.Request(url, method=method, data=data, headers=headers or {})
    try:
        with urllib.request.urlopen(req) as r:
            raw = r.read()
            return r.status, (json.loads(raw) if raw and raw[:1] in b"{[" else {})
    except urllib.error.HTTPError as e:
        raw = e.read()
        try:
            return e.code, json.loads(raw)
        except ValueError:
            return e.code, {"raw": raw.decode(errors="replace")[:500]}


def asc(method, path, body=None, allow=()):
    url = path if path.startswith("http") else f"https://api.appstoreconnect.apple.com{path}"
    status, data = request(method, url, body, {"Authorization": f"Bearer {asc_token()}", "Content-Type": "application/json"})
    if status >= 300 and status not in allow:
        errors = data.get("errors", [data])
        detail = "; ".join(f"{e.get('title', '')}: {e.get('detail', e.get('raw', ''))}" for e in errors)
        print(f"::error title={method} {path.split('?')[0]} ({status})::{detail}")
        raise SystemExit(1)
    return status, data


def all_pages(path):
    items, url = [], path
    while url:
        _, data = asc("GET", url)
        items += data["data"]
        url = data.get("links", {}).get("next")
    return items


def rel(kind, id_):
    return {"data": {"type": kind, "id": id_}}


def app_id():
    _, data = asc("GET", f"/v1/apps?filter[bundleId]={BUNDLE_ID}")
    if not data["data"]:
        print(f"::error title=No app record::App Store Connect has no app with bundle ID {BUNDLE_ID}")
        raise SystemExit(1)
    return data["data"][0]["id"]


def territories():
    return [t["id"] for t in all_pages("/v1/territories?limit=200")]


def subscription_group(app):
    groups = all_pages(f"/v1/apps/{app}/subscriptionGroups?limit=50")
    group = next((g for g in groups if g["attributes"]["referenceName"] == GROUP), None)
    if group:
        print(f"Subscription group '{GROUP}' exists")
        gid = group["id"]
    else:
        _, data = asc("POST", "/v1/subscriptionGroups", {"data": {"type": "subscriptionGroups", "attributes": {"referenceName": GROUP},
                                                                  "relationships": {"app": rel("apps", app)}}})
        gid = data["data"]["id"]
        print(f"Subscription group '{GROUP}' created")
    locs = all_pages(f"/v1/subscriptionGroups/{gid}/subscriptionGroupLocalizations")
    if not any(l["attributes"]["locale"] == "en-US" for l in locs):
        asc("POST", "/v1/subscriptionGroupLocalizations", {"data": {"type": "subscriptionGroupLocalizations",
                                                                    "attributes": {"name": GROUP, "locale": "en-US"},
                                                                    "relationships": {"subscriptionGroup": rel("subscriptionGroups", gid)}}})
    return gid


def subscription(gid, product_id, ref, period, level, usd, name, description, all_territories):
    subs = all_pages(f"/v1/subscriptionGroups/{gid}/subscriptions?limit=50")
    sub = next((s for s in subs if s["attributes"]["productId"] == product_id), None)
    if sub:
        sid = sub["id"]
        print(f"{product_id}: exists ({sub['attributes'].get('state')})")
    else:
        _, data = asc("POST", "/v1/subscriptions", {"data": {"type": "subscriptions", "attributes": {
            "name": ref, "productId": product_id, "subscriptionPeriod": period, "groupLevel": level,
            "familySharable": False, "reviewNote": REVIEW_NOTE}, "relationships": {"group": rel("subscriptionGroups", gid)}}})
        sid = data["data"]["id"]
        print(f"{product_id}: created")

    locs = all_pages(f"/v1/subscriptions/{sid}/subscriptionLocalizations")
    if not any(l["attributes"]["locale"] == "en-US" for l in locs):
        asc("POST", "/v1/subscriptionLocalizations", {"data": {"type": "subscriptionLocalizations",
                                                               "attributes": {"name": name, "description": description, "locale": "en-US"},
                                                               "relationships": {"subscription": rel("subscriptions", sid)}}})
        print(f"{product_id}: English name and description added")

    status, _ = asc("GET", f"/v1/subscriptions/{sid}/subscriptionAvailability", allow=(404,))
    if status == 404:
        asc("POST", "/v1/subscriptionAvailabilities", {"data": {"type": "subscriptionAvailabilities",
                                                                "attributes": {"availableInNewTerritories": True},
                                                                "relationships": {"subscription": rel("subscriptions", sid),
                                                                                  "availableTerritories": {"data": [{"type": "territories", "id": t} for t in all_territories]}}}})
        print(f"{product_id}: available in {len(all_territories)} territories")

    existing = all_pages(f"/v1/subscriptions/{sid}/prices?limit=200&include=territory")
    if existing:
        print(f"{product_id}: prices already set ({len(existing)})")
    else:
        points = all_pages(f"/v1/subscriptions/{sid}/pricePoints?filter[territory]=USA&limit=200")
        usa = next((p for p in points if p["attributes"]["customerPrice"] == usd), None)
        if not usa:
            print(f"::error title={product_id}: no ${usd} price point::Closest: {[p['attributes']['customerPrice'] for p in points][:40]}")
            raise SystemExit(1)
        # The US price, plus Apple's equivalent price in every other territory, unless a local price is set above.
        equal = all_pages(f"/v1/subscriptionPricePoints/{usa['id']}/equalizations?limit=200&include=territory")
        local = {}
        for territory, amount in LOCAL_PRICES.get(product_id, {}).items():
            there = all_pages(f"/v1/subscriptions/{sid}/pricePoints?filter[territory]={territory}&limit=200")
            point = next((p for p in there if float(p["attributes"]["customerPrice"]) == float(amount)), None)
            if point:
                local[territory] = point["id"]
                print(f"{product_id}: {amount} in {territory}")
            else:
                print(f"::warning title={product_id}: no {amount} price point in {territory}::Left on Apple's equivalent of ${usd}; set it in App Store Connect.")
        swapped = set()
        targets = [usa["id"]]
        for p in equal:
            territory = ((p.get("relationships") or {}).get("territory") or {}).get("data") or {}
            if territory.get("id") in local:
                targets.append(local[territory["id"]])
                swapped.add(territory["id"])
            else:
                targets.append(p["id"])
        for territory in set(local) - swapped:
            print(f"::warning title={product_id}: {territory} price not applied::Couldn't tell which equivalent price is {territory}'s; set it in App Store Connect.")
        for ppid in targets:
            asc("POST", "/v1/subscriptionPrices", {"data": {"type": "subscriptionPrices", "attributes": {"startDate": None, "preserveCurrentPrice": False},
                                                            "relationships": {"subscription": rel("subscriptions", sid),
                                                                              "subscriptionPricePoint": rel("subscriptionPricePoints", ppid)}}},
                allow=(409,))
        print(f"{product_id}: ${usd} in the US and equivalents in {len(targets) - 1} other territories")

    if product_id in TRIAL:
        offers = all_pages(f"/v1/subscriptions/{sid}/introductoryOffers?limit=200")
        if offers:
            print(f"{product_id}: free trial already set ({len(offers)} territories)")
        else:
            for t in all_territories:
                asc("POST", "/v1/subscriptionIntroductoryOffers", {"data": {"type": "subscriptionIntroductoryOffers", "attributes": {
                    "duration": TRIAL[product_id], "offerMode": "FREE_TRIAL", "numberOfPeriods": 1},
                    "relationships": {"subscription": rel("subscriptions", sid), "territory": rel("territories", t)}}}, allow=(409,))
            print(f"{product_id}: {TRIAL[product_id].replace('_', ' ').lower()} free trial in every territory")

    review_screenshot("subscriptionAppStoreReviewScreenshots", "subscription", "subscriptions", sid,
                      f"/v1/subscriptions/{sid}/appStoreReviewScreenshot", product_id)
    return sid


def lifetime(app, all_territories):
    product_id, ref, usd, name, description = LIFETIME
    iaps = all_pages(f"/v1/apps/{app}/inAppPurchasesV2?limit=200")
    iap = next((i for i in iaps if i["attributes"]["productId"] == product_id), None)
    if iap:
        iid = iap["id"]
        print(f"{product_id}: exists ({iap['attributes'].get('state')})")
    else:
        _, data = asc("POST", "/v2/inAppPurchases", {"data": {"type": "inAppPurchases", "attributes": {
            "name": ref, "productId": product_id, "inAppPurchaseType": "NON_CONSUMABLE", "reviewNote": REVIEW_NOTE},
            "relationships": {"app": rel("apps", app)}}})
        iid = data["data"]["id"]
        print(f"{product_id}: created")

    locs = all_pages(f"/v2/inAppPurchases/{iid}/inAppPurchaseLocalizations")
    if not any(l["attributes"]["locale"] == "en-US" for l in locs):
        asc("POST", "/v1/inAppPurchaseLocalizations", {"data": {"type": "inAppPurchaseLocalizations",
                                                                "attributes": {"name": name, "description": description, "locale": "en-US"},
                                                                "relationships": {"inAppPurchaseV2": rel("inAppPurchases", iid)}}})
        print(f"{product_id}: English name and description added")

    status, _ = asc("GET", f"/v2/inAppPurchases/{iid}/inAppPurchaseAvailability", allow=(404,))
    if status == 404:
        asc("POST", "/v1/inAppPurchaseAvailabilities", {"data": {"type": "inAppPurchaseAvailabilities",
                                                                 "attributes": {"availableInNewTerritories": True},
                                                                 "relationships": {"inAppPurchase": rel("inAppPurchases", iid),
                                                                                   "availableTerritories": {"data": [{"type": "territories", "id": t} for t in all_territories]}}}})
        print(f"{product_id}: available in {len(all_territories)} territories")

    status, _ = asc("GET", f"/v2/inAppPurchases/{iid}/iapPriceSchedule", allow=(404,))
    if status == 404:
        points = all_pages(f"/v2/inAppPurchases/{iid}/pricePoints?filter[territory]=USA&limit=200")
        usa = next((p for p in points if p["attributes"]["customerPrice"] == usd), None)
        if not usa:
            print(f"::error title={product_id}: no ${usd} price point::Closest: {[p['attributes']['customerPrice'] for p in points][:40]}")
            raise SystemExit(1)
        # A US base price; Apple sets the other territories from it.
        asc("POST", "/v1/inAppPurchasePriceSchedules", {
            "data": {"type": "inAppPurchasePriceSchedules", "relationships": {
                "inAppPurchase": rel("inAppPurchases", iid), "baseTerritory": rel("territories", "USA"),
                "manualPrices": {"data": [{"type": "inAppPurchasePrices", "id": "${price}"}]}}},
            "included": [{"type": "inAppPurchasePrices", "id": "${price}", "attributes": {"startDate": None},
                          "relationships": {"inAppPurchasePricePoint": rel("inAppPurchasePricePoints", usa["id"])}}]})
        print(f"{product_id}: ${usd} in the US, other territories set by Apple")
    else:
        print(f"{product_id}: price already set")

    review_screenshot("inAppPurchaseAppStoreReviewScreenshots", "inAppPurchaseV2", "inAppPurchases", iid,
                      f"/v2/inAppPurchases/{iid}/appStoreReviewScreenshot", product_id)
    return iid


def review_screenshot(kind, relation, owner_type, owner_id, existing_path, product_id):
    """App Review needs a screenshot of the purchase for each product."""
    if not SCREENSHOT or not os.path.exists(SCREENSHOT):
        print(f"{product_id}: no review screenshot file, skipped")
        return
    status, data = asc("GET", existing_path, allow=(404,))
    if status == 200 and data.get("data"):
        print(f"{product_id}: review screenshot already uploaded")
        return
    blob = open(SCREENSHOT, "rb").read()
    _, data = asc("POST", f"/v1/{kind}", {"data": {"type": kind, "attributes": {"fileName": "paywall.png", "fileSize": len(blob)},
                                                   "relationships": {relation: rel(owner_type, owner_id)}}})
    shot = data["data"]
    for op in shot["attributes"]["uploadOperations"]:
        part = blob[op["offset"]:op["offset"] + op["length"]]
        headers = {h["name"]: h["value"] for h in op.get("requestHeaders", [])}
        status, _ = request(op["method"], op["url"], part, headers)
        if status >= 300:
            print(f"::error title={product_id}: screenshot upload failed ({status})::")
            raise SystemExit(1)
    asc("PATCH", f"/v1/{kind}/{shot['id']}", {"data": {"type": kind, "id": shot["id"], "attributes": {
        "uploaded": True, "sourceFileChecksum": hashlib.md5(blob).hexdigest()}}})
    print(f"{product_id}: review screenshot uploaded")


# MARK: RevenueCat

def rc(method, path, body=None, allow=()):
    url = f"https://api.revenuecat.com/v2/projects/{os.environ['RC_PROJECT_ID'].strip()}{path}"
    status, data = request(method, url, body, {"Authorization": f"Bearer {os.environ['RC_SECRET_KEY'].strip()}",
                                               "Content-Type": "application/json"})
    if status >= 300 and status not in allow:
        print(f"::error title=RevenueCat {method} {path} ({status})::{json.dumps(data)[:600]}")
        raise SystemExit(1)
    return status, data


def rc_items(path):
    items, url = [], path
    while url:
        _, data = rc("GET", url)
        items += data.get("items", [])
        nxt = data.get("next_page")
        url = nxt.split(f"/projects/{os.environ['RC_PROJECT_ID'].strip()}", 1)[1] if nxt else None
    return items


def revenuecat():
    apps = [a for a in rc_items("/apps") if a.get("type") == "app_store" and (a.get("app_store") or {}).get("bundle_id") == BUNDLE_ID]
    if not apps:
        print(f"::error title=No RevenueCat app::Add an App Store app with bundle ID {BUNDLE_ID} to the RevenueCat project first.")
        raise SystemExit(1)
    app = apps[0]["id"]

    wanted = [(s[0], "subscription", s[5]) for s in SUBSCRIPTIONS] + [(LIFETIME[0], "non_consumable", LIFETIME[3])]
    products = {p["store_identifier"]: p["id"] for p in rc_items("/products") if p.get("app_id") == app}
    for store_id, kind, name in wanted:
        if store_id not in products:
            _, data = rc("POST", "/products", {"store_identifier": store_id, "app_id": app, "type": kind, "display_name": name})
            products[store_id] = data["id"]
            print(f"RevenueCat: product {store_id} added")
        else:
            print(f"RevenueCat: product {store_id} exists")

    existing = rc_items("/entitlements")
    print("::notice title=RevenueCat entitlements before setup::" + ", ".join(f"{e['lookup_key']} ({e.get('display_name')})" for e in existing))
    ents = {e["lookup_key"]: e["id"] for e in existing}
    if "pro" not in ents:
        # The app checks the "pro" lookup key; the display name only has to be unique.
        taken = {e.get("display_name") for e in existing}
        _, data = rc("POST", "/entitlements", {"lookup_key": "pro", "display_name": "Pro" if "Pro" not in taken else "DayXero Pro (app)"})
        ents["pro"] = data["id"]
        print("RevenueCat: entitlement 'pro' added")
    rc("POST", f"/entitlements/{ents['pro']}/actions/attach_products", {"product_ids": [products[w[0]] for w in wanted]}, allow=(409, 422))
    print("RevenueCat: every product unlocks 'pro'")

    offerings = {o["lookup_key"]: o for o in rc_items("/offerings")}
    if "default" not in offerings:
        taken = {o.get("display_name") for o in offerings.values()}
        _, data = rc("POST", "/offerings", {"lookup_key": "default", "display_name": "Default" if "Default" not in taken else "DayXero default"})
        offerings["default"] = data
        print("RevenueCat: offering 'default' added")
    offering = offerings["default"]["id"]
    if not offerings["default"].get("is_current"):
        rc("POST", f"/offerings/{offering}", {"is_current": True})
        print("RevenueCat: 'default' is now the current offering")

    packages = {p["lookup_key"]: p["id"] for p in rc_items(f"/offerings/{offering}/packages")}
    for position, (key, store_id, label) in enumerate([("$rc_annual", "dayxero.annual", "Annual"),
                                                       ("$rc_three_month", "dayxero.quarterly", "3 months"),
                                                       ("$rc_monthly", "dayxero.monthly", "Monthly"),
                                                       ("$rc_lifetime", "dayxero.lifetime", "Lifetime")], start=1):
        if key not in packages:
            _, data = rc("POST", f"/offerings/{offering}/packages", {"lookup_key": key, "display_name": label, "position": position})
            packages[key] = data["id"]
            print(f"RevenueCat: package {key} added")
        rc("POST", f"/packages/{packages[key]}/actions/attach_products",
           {"products": [{"product_id": products[store_id], "eligibility_criteria": "all"}]}, allow=(409, 422))
    print("RevenueCat: packages hold their products")

    status, data = rc("GET", f"/apps/{app}/public_api_keys", allow=(404,))
    keys = [k.get("key") for k in data.get("items", [])] if status == 200 else []
    if keys:
        # Public SDK keys ship inside the app, so printing it is fine.
        print(f"::notice title=RevenueCat public SDK key::{keys[0]} (save it as the REVENUECAT_API_KEY repo secret)")


# MARK: Check (read only)

def check():
    """Reads every plan, the 1.0 version and RevenueCat and prints what App Review will see. Changes nothing."""
    app = app_id()
    n_territories = len(territories())
    out = []

    def got(path):
        status, data = asc("GET", path, allow=(404,))
        return data.get("data") if status == 200 else None

    try:
        for g in all_pages(f"/v1/apps/{app}/subscriptionGroups?limit=50"):
            gid, ga = g["id"], g["attributes"]
            glocs = all_pages(f"/v1/subscriptionGroups/{gid}/subscriptionGroupLocalizations")
            out.append(f"GROUP {ga['referenceName']}: localizations " +
                       ", ".join(f"{l['attributes']['locale']}={l['attributes'].get('name')!r} ({l['attributes'].get('state')})" for l in glocs))
            for sub in all_pages(f"/v1/subscriptionGroups/{gid}/subscriptions?limit=50"):
                sid, a = sub["id"], sub["attributes"]
                locs = all_pages(f"/v1/subscriptions/{sid}/subscriptionLocalizations")
                prices = all_pages(f"/v1/subscriptions/{sid}/prices?limit=200&include=subscriptionPricePoint,territory")
                avail = got(f"/v1/subscriptions/{sid}/subscriptionAvailability")
                avail_n = len(all_pages(f"/v1/subscriptionAvailabilities/{avail['id']}/availableTerritories?limit=200")) if avail else 0
                trial = all_pages(f"/v1/subscriptions/{sid}/introductoryOffers?limit=200")
                shot = got(f"/v1/subscriptions/{sid}/appStoreReviewScreenshot")
                usd = ""
                _, pp = asc("GET", f"/v1/subscriptions/{sid}/prices?limit=200&include=subscriptionPricePoint&filter[territory]=USA")
                for inc in pp.get("included", []):
                    if inc["type"] == "subscriptionPricePoints":
                        usd = inc["attributes"].get("customerPrice")
                out.append(f"  SUB {a['productId']}: state {a.get('state')}, level {a.get('groupLevel')}, {a.get('subscriptionPeriod')}, "
                           f"US ${usd}, {len(prices)} price rows, available in {avail_n}/{n_territories}, trial rows {len(trial)}"
                           f"{' (' + trial[0]['attributes'].get('duration', '') + ')' if trial else ''}, "
                           f"review screenshot {'yes ' + str((shot or {}).get('attributes', {}).get('assetDeliveryState', {}).get('state')) if shot else 'NO'}, "
                           f"family {a.get('familySharable')}, review note {a.get('reviewNote')!r}")
                for l in locs:
                    la = l["attributes"]
                    out.append(f"    {la['locale']}: {la.get('name')!r} / {la.get('description')!r} ({la.get('state')})")
    except SystemExit:
        out.append("(could not read this part; see the error above)")
    try:
        for iap in all_pages(f"/v1/apps/{app}/inAppPurchasesV2?limit=200"):
            iid, a = iap["id"], iap["attributes"]
            locs = all_pages(f"/v2/inAppPurchases/{iid}/inAppPurchaseLocalizations")
            sched = got(f"/v2/inAppPurchases/{iid}/iapPriceSchedule")
            usd = ""
            if sched:
                _, mp = asc("GET", f"/v1/inAppPurchasePriceSchedules/{sched['id']}/manualPrices?include=inAppPurchasePricePoint,territory&limit=50")
                usd = ", ".join(sorted({i["attributes"].get("customerPrice", "") for i in mp.get("included", []) if i["type"] == "inAppPurchasePricePoints"}))
            avail = got(f"/v2/inAppPurchases/{iid}/inAppPurchaseAvailability")
            avail_n = len(all_pages(f"/v1/inAppPurchaseAvailabilities/{avail['id']}/availableTerritories?limit=200")) if avail else 0
            shot = got(f"/v2/inAppPurchases/{iid}/appStoreReviewScreenshot")
            out.append(f"IAP {a['productId']} ({a.get('inAppPurchaseType')}): state {a.get('state')}, base price {usd or 'NONE'}, "
                       f"available in {avail_n}/{n_territories}, review screenshot "
                       f"{'yes ' + str((shot or {}).get('attributes', {}).get('assetDeliveryState', {}).get('state')) if shot else 'NO'}, "
                       f"family {a.get('familySharable')}, review note {a.get('reviewNote')!r}")
            for l in locs:
                la = l["attributes"]
                out.append(f"    {la['locale']}: {la.get('name')!r} / {la.get('description')!r} ({la.get('state')})")
    except SystemExit:
        out.append("(could not read this part; see the error above)")
    try:
        for v in all_pages(f"/v1/apps/{app}/appStoreVersions?limit=10"):
            va = v["attributes"]
            b = got(f"/v1/appStoreVersions/{v['id']}/build")
            out.append(f"VERSION {va.get('versionString')} {va.get('platform')}: {va.get('appStoreState')}, "
                       f"build {(b or {}).get('attributes', {}).get('version', 'NONE')}")
            rd = got(f"/v1/appStoreVersions/{v['id']}/appStoreReviewDetail")
            if rd:
                ra = rd["attributes"]
                out.append(f"  review detail: contact {'set' if ra.get('contactEmail') else 'MISSING'}, demo account required "
                           f"{ra.get('demoAccountRequired')}, notes {ra.get('notes')!r}")
            else:
                out.append("  review detail: NONE")
    except SystemExit:
        out.append("(could not read this part; see the error above)")
    try:
        _, rs = asc("GET", f"/v1/reviewSubmissions?filter[app]={app}&include=items&limit=20", allow=(404,))
    except SystemExit:
        out.append("(could not read this part; see the error above)")
    try:
        for r in rs.get("data", []):
            out.append(f"REVIEW SUBMISSION {r['id']}: {r['attributes'].get('state')}, items {len(r.get('relationships', {}).get('items', {}).get('data', []))}")
    except SystemExit:
        out.append("(could not read this part; see the error above)")
    try:
        for info in all_pages(f"/v1/apps/{app}/appInfos"):
            for l in all_pages(f"/v1/appInfos/{info['id']}/appInfoLocalizations?limit=50"):
                la = l["attributes"]
                out.append(f"APP INFO {info['attributes'].get('appStoreState')} {la['locale']}: privacy {la.get('privacyPolicyUrl')!r}")
    except SystemExit:
        out.append("(could not read this part; see the error above)")
    try:
        status, eula = asc("GET", f"/v1/apps/{app}/endUserLicenseAgreement", allow=(404,))
        out.append("CUSTOM EULA: " + ("yes" if status == 200 and eula.get("data") else "none (Apple's standard EULA applies)"))
    except SystemExit:
        out.append("(could not read this part; see the error above)")
    try:
        if os.environ.get("RC_SECRET_KEY") and os.environ.get("RC_PROJECT_ID"):
            products = {p["id"]: p for p in rc_items("/products")}
            out.append("RC products: " + ", ".join(f"{p['store_identifier']} ({p.get('type')})" for p in products.values()))
            for e in rc_items("/entitlements"):
                _, ep = rc("GET", f"/entitlements/{e['id']}/products")
                out.append(f"RC entitlement {e['lookup_key']}: " + ", ".join(p.get("store_identifier", "") for p in ep.get("items", [])))
            for o in rc_items("/offerings"):
                pk = []
                for p in rc_items(f"/offerings/{o['id']}/packages"):
                    _, pp = rc("GET", f"/packages/{p['id']}/products")
                    pk.append(f"{p['lookup_key']}=" + "+".join(products.get(x.get("product", {}).get("id") or x.get("product_id", ""), {}).get("store_identifier", "?")
                                                              for x in pp.get("items", [])))
                out.append(f"RC offering {o['lookup_key']}{' (current)' if o.get('is_current') else ''}: " + ", ".join(pk))
    except SystemExit:
        out.append("(could not read this part; see the error above)")
    print("\n".join(out))


if __name__ == "__main__":
    step = sys.argv[1] if len(sys.argv) > 1 else "all"
    if step == "check":
        check()
        raise SystemExit(0)
    if step in ("all", "appstore"):
        app = app_id()
        all_territories = territories()
        gid = subscription_group(app)
        for s in SUBSCRIPTIONS:
            subscription(gid, *s, all_territories)
        lid = lifetime(app, all_territories)
        summary = []
        for sub in all_pages(f"/v1/subscriptionGroups/{gid}/subscriptions?limit=50"):
            sid, a = sub["id"], sub["attributes"]
            prices = len(all_pages(f"/v1/subscriptions/{sid}/prices?limit=200"))
            trial = len(all_pages(f"/v1/subscriptions/{sid}/introductoryOffers?limit=200"))
            summary.append(f"{a['productId']}: {a.get('state')}, {prices} prices, trial in {trial} territories")
        _, data = asc("GET", f"/v2/inAppPurchases/{lid}")
        parts = []
        for label, path in [("price", f"/v2/inAppPurchases/{lid}/iapPriceSchedule"),
                            ("availability", f"/v2/inAppPurchases/{lid}/inAppPurchaseAvailability"),
                            ("screenshot", f"/v2/inAppPurchases/{lid}/appStoreReviewScreenshot")]:
            status, got = asc("GET", path, allow=(404,))
            parts.append(f"{label} {'yes' if status == 200 and got.get('data') else 'no'}")
        locs = len(all_pages(f"/v2/inAppPurchases/{lid}/inAppPurchaseLocalizations"))
        summary.append(f"{LIFETIME[0]}: {data['data']['attributes'].get('state')} ({', '.join(parts)}, {locs} localizations)")
        print("::notice title=App Store Connect products::" + " | ".join(summary))
    if step in ("all", "revenuecat"):
        if os.environ.get("RC_SECRET_KEY") and os.environ.get("RC_PROJECT_ID"):
            revenuecat()
        else:
            print("::notice title=RevenueCat skipped::Add RC_SECRET_KEY and RC_PROJECT_ID repo secrets to set up RevenueCat.")
