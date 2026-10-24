"""Creates DayXero's plans in App Store Connect and wires them up in RevenueCat (S3.11).

Safe to run again: anything that already exists is left as it is.

  App Store Connect (ASC_KEY_ID, ASC_ISSUER_ID, $RUNNER_TEMP/AuthKey_<id>.p8):
    subscription group "DayXero Pro" with dayxero.annual (3-day free trial) and dayxero.monthly,
    the non-consumable dayxero.lifetime, English names, prices in every territory, and review screenshots.
  RevenueCat (RC_SECRET_KEY, RC_PROJECT_ID; skipped when not set):
    the three products, the "pro" entitlement, and the current "default" offering with
    $rc_annual, $rc_monthly and $rc_lifetime packages. Prints the app's public SDK key.
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
    ("dayxero.monthly", "Monthly", "ONE_MONTH", 2, "9.99", "DayXero Pro Monthly",
     "Full quit program, insights and NRT planner, monthly."),
]
LIFETIME = ("dayxero.lifetime", "Lifetime", "79.99", "DayXero Pro Lifetime",
            "Full quit program, insights and NRT planner, for good.")
TRIAL = {"dayxero.annual": "THREE_DAYS"}
REVIEW_NOTE = "Unlocks DayXero Pro. The paywall appears after onboarding and from locked lessons."
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
        # The US price, plus Apple's equivalent price in every other territory.
        targets = [usa["id"]] + [p["id"] for p in all_pages(f"/v1/subscriptionPricePoints/{usa['id']}/equalizations?limit=200")]
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

    ents = {e["lookup_key"]: e["id"] for e in rc_items("/entitlements")}
    if "pro" not in ents:
        _, data = rc("POST", "/entitlements", {"lookup_key": "pro", "display_name": "DayXero Pro"})
        ents["pro"] = data["id"]
        print("RevenueCat: entitlement 'pro' added")
    rc("POST", f"/entitlements/{ents['pro']}/actions/attach_products", {"product_ids": [products[w[0]] for w in wanted]}, allow=(409, 422))
    print("RevenueCat: all three products unlock 'pro'")

    offerings = {o["lookup_key"]: o for o in rc_items("/offerings")}
    if "default" not in offerings:
        _, data = rc("POST", "/offerings", {"lookup_key": "default", "display_name": "DayXero Pro"})
        offerings["default"] = data
        print("RevenueCat: offering 'default' added")
    offering = offerings["default"]["id"]
    if not offerings["default"].get("is_current"):
        rc("POST", f"/offerings/{offering}", {"is_current": True})
        print("RevenueCat: 'default' is now the current offering")

    packages = {p["lookup_key"]: p["id"] for p in rc_items(f"/offerings/{offering}/packages")}
    for position, (key, store_id, label) in enumerate([("$rc_annual", "dayxero.annual", "Annual"),
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


if __name__ == "__main__":
    step = sys.argv[1] if len(sys.argv) > 1 else "all"
    if step in ("all", "appstore"):
        app = app_id()
        all_territories = territories()
        gid = subscription_group(app)
        for s in SUBSCRIPTIONS:
            subscription(gid, *s, all_territories)
        lifetime(app, all_territories)
    if step in ("all", "revenuecat"):
        if os.environ.get("RC_SECRET_KEY") and os.environ.get("RC_PROJECT_ID"):
            revenuecat()
        else:
            print("::notice title=RevenueCat skipped::Add RC_SECRET_KEY and RC_PROJECT_ID repo secrets to set up RevenueCat.")
