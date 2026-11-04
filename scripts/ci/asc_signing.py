"""App Store signing for CI through the App Store Connect API (S16.4).

xcodebuild's automatic signing rejects our API key, so CI signs by hand:
  setup    registers the App IDs if needed, creates a distribution certificate and
           App Store profiles, and writes the .p12, profiles and build settings to $RUNNER_TEMP.
  cleanup  deletes this run's profiles. The certificate is kept (encrypted in the Actions cache) and reused,
           because revoking it invalidates builds still waiting for review (ITMS-90035).
  builds   lists the builds App Store Connect has for the app.
  wait N   waits for build N to show up after an upload, since altool can report success when nothing arrived.
  expire T [--confirm]
           expires every unexpired build uploaded at or before T (ISO 8601 with a UTC offset, e.g.
           2026-11-02T14:30:00+05:30). Without --confirm it only lists them. Apple has no way to delete a build;
           expiring removes it from TestFlight for good.
  version [N]
           shows each App Store version and the build attached to it (App Store Connect's app icon comes from
           that build). With N, attaches build N to the version that's still being prepared.

Needs ASC_KEY_ID, ASC_ISSUER_ID and $RUNNER_TEMP/AuthKey_<id>.p8, plus pyjwt and cryptography.
"""
import base64
import json
import os
import sys
import time
import urllib.error
import urllib.request

import jwt
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives.serialization import pkcs12
from cryptography.x509.oid import NameOID

API = "https://api.appstoreconnect.apple.com/v1"
TEMP = os.environ["RUNNER_TEMP"]
STATE = os.path.join(TEMP, "signing.json")
TARGETS = {"in.dayxero.app": "DayXero", "in.dayxero.app.widgets": "DayXero Widgets"}
CAPABILITIES = ["APP_GROUPS"]


def token():
    kid = os.environ["ASC_KEY_ID"].strip()
    key = open(os.path.join(TEMP, f"AuthKey_{kid}.p8")).read()
    now = int(time.time())
    return jwt.encode({"iss": os.environ["ASC_ISSUER_ID"].strip(), "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"},
                      key, algorithm="ES256", headers={"kid": kid, "typ": "JWT"})


def call(method, path, body=None):
    req = urllib.request.Request(f"{API}/{path}", method=method, data=json.dumps(body).encode() if body else None,
                                 headers={"Authorization": f"Bearer {token()}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req) as r:
            raw = r.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as e:
        errors = json.loads(e.read() or b"{}").get("errors", [{}])
        detail = "; ".join(f"{x.get('title', '')}: {x.get('detail', '')}" for x in errors)
        print(f"::error title={method} {path.split('?')[0]} failed ({e.code})::{detail}")
        raise SystemExit(1)


def bundle_id(identifier, name):
    found = [b for b in call("GET", f"bundleIds?filter[identifier]={identifier}&limit=50")["data"]
             if b["attributes"]["identifier"] == identifier]
    if found:
        bid = found[0]["id"]
        print(f"{identifier}: App ID exists")
    else:
        bid = call("POST", "bundleIds", {"data": {"type": "bundleIds", "attributes": {
            "identifier": identifier, "name": name, "platform": "IOS"}}})["data"]["id"]
        print(f"{identifier}: App ID registered")
    have = {c["attributes"]["capabilityType"] for c in call("GET", f"bundleIds/{bid}/bundleIdCapabilities")["data"]}
    for cap in CAPABILITIES:
        if cap not in have:
            call("POST", "bundleIdCapabilities", {"data": {"type": "bundleIdCapabilities", "attributes": {"capabilityType": cap},
                                                           "relationships": {"bundleId": {"data": {"type": "bundleIds", "id": bid}}}}})
            print(f"{identifier}: {cap} turned on")
    return bid


def certificate(password):
    key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    csr = (x509.CertificateSigningRequestBuilder()
           .subject_name(x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, "DayXero CI"),
                                    x509.NameAttribute(NameOID.EMAIL_ADDRESS, "ci@dayxero.in")]))
           .sign(key, hashes.SHA256()))
    pem = csr.public_bytes(serialization.Encoding.PEM).decode()
    data = call("POST", "certificates", {"data": {"type": "certificates", "attributes": {
        "csrContent": pem, "certificateType": "DISTRIBUTION"}}})["data"]
    cert = x509.load_der_x509_certificate(base64.b64decode(data["attributes"]["certificateContent"]))
    # macOS `security import` only reads the older PKCS#12 encryption.
    encryption = (serialization.PrivateFormat.PKCS12.encryption_builder().kdf_rounds(50000)
                  .key_cert_algorithm(pkcs12.PBES.PBESv1SHA1And3KeyTripleDESCBC).hmac_hash(hashes.SHA1())
                  .build(password.encode()))
    p12 = pkcs12.serialize_key_and_certificates(b"DayXero CI", key, cert, None, encryption)
    open(os.path.join(TEMP, "dist.p12"), "wb").write(p12)
    print(f"Distribution certificate {data['id']} created")
    return data["id"]


def profile(identifier, bid, cert_id):
    name = f"DayXero CI {identifier} {os.environ.get('GITHUB_RUN_ID', int(time.time()))}"
    data = call("POST", "profiles", {"data": {"type": "profiles", "attributes": {"name": name, "profileType": "IOS_APP_STORE"},
                                              "relationships": {"bundleId": {"data": {"type": "bundleIds", "id": bid}},
                                                                "certificates": {"data": [{"type": "certificates", "id": cert_id}]}}}})["data"]
    content = base64.b64decode(data["attributes"]["profileContent"])
    uuid = data["attributes"]["uuid"]
    for folder in ["~/Library/MobileDevice/Provisioning Profiles", "~/Library/Developer/Xcode/UserData/Provisioning Profiles"]:
        folder = os.path.expanduser(folder)
        os.makedirs(folder, exist_ok=True)
        open(os.path.join(folder, f"{uuid}.mobileprovision"), "wb").write(content)
    open(os.path.join(TEMP, f"{identifier}.mobileprovision"), "wb").write(content)
    print(f"{identifier}: profile '{name}' installed")
    return data["id"], name


CERT_INFO = os.path.join(TEMP, "dist-cert.json")


def reusable_certificate():
    """The certificate kept from an earlier run (restored from the Actions cache), if Apple still has it valid."""
    if not (os.path.exists(CERT_INFO) and os.path.exists(os.path.join(TEMP, "dist.p12"))):
        return None
    cert_id = json.load(open(CERT_INFO)).get("id")
    req = urllib.request.Request(f"{API}/certificates/{cert_id}", headers={"Authorization": f"Bearer {token()}"})
    try:
        with urllib.request.urlopen(req) as r:
            attrs = json.loads(r.read())["data"]["attributes"]
    except urllib.error.HTTPError:
        print(f"Kept certificate {cert_id} is gone; making a new one")
        return None
    expires = attrs.get("expirationDate", "")
    if expires and expires[:10] < time.strftime("%Y-%m-%d", time.gmtime(time.time() + 14 * 86400)):
        print(f"Kept certificate {cert_id} expires {expires[:10]}; making a new one")
        return None
    print(f"Reusing distribution certificate {cert_id} (expires {expires[:10]})")
    return cert_id


def setup():
    state = {"profiles": {}}
    ids = {identifier: bundle_id(identifier, name) for identifier, name in TARGETS.items()}
    # One long-lived certificate: builds waiting for TestFlight or App Store review need it to stay valid,
    # so it's kept between runs and never revoked here (ITMS-90035).
    cert_id = reusable_certificate()
    if cert_id is None:
        cert_id = certificate(os.environ["P12_PASSWORD"])
        json.dump({"id": cert_id}, open(CERT_INFO, "w"))
        with open(os.environ["GITHUB_ENV"], "a") as env:
            env.write(f"DX_NEW_CERT={cert_id}\n")
    state["certificate"] = cert_id
    json.dump(state, open(STATE, "w"))
    for identifier, bid in ids.items():
        pid, name = profile(identifier, bid, state["certificate"])
        state["profiles"][identifier] = {"id": pid, "name": name}
        json.dump(state, open(STATE, "w"))
    with open(os.environ["GITHUB_ENV"], "a") as env:
        env.write(f"DX_PROFILE_APP={state['profiles']['in.dayxero.app']['name']}\n")
        env.write(f"DX_PROFILE_WIDGETS={state['profiles']['in.dayxero.app.widgets']['name']}\n")


def cleanup():
    if not os.path.exists(STATE):
        return
    state = json.load(open(STATE))
    for p in state.get("profiles", {}).values():
        try:
            call("DELETE", f"profiles/{p['id']}")
        except SystemExit:
            pass
    # The certificate stays: revoking it invalidates builds still waiting for review.
    print("Profiles deleted; certificate kept for the next run")


def app_id():
    apps = call("GET", "apps?filter[bundleId]=in.dayxero.app")["data"]
    if not apps:
        print("::error title=No app record::App Store Connect has no app with bundle ID in.dayxero.app")
        raise SystemExit(1)
    return apps[0]["id"]


def recent_builds():
    res = call("GET", f"builds?filter[app]={app_id()}&sort=-uploadedDate&limit=10&include=preReleaseVersion"
                      "&fields[builds]=version,processingState,uploadedDate,preReleaseVersion,iconAssetToken&fields[preReleaseVersions]=version")
    versions = {v["id"]: v["attributes"]["version"] for v in res.get("included", [])}
    return [(b["attributes"]["version"], b["attributes"]["processingState"], b["attributes"]["uploadedDate"],
             versions.get((b["relationships"]["preReleaseVersion"]["data"] or {}).get("id"), "?"),
             "icon" if b["attributes"].get("iconAssetToken") else "no icon") for b in res["data"]]


def builds():
    found = recent_builds()
    print(f"::notice title=Builds in App Store Connect::{found or 'none yet'}")


def next_build():
    """The UTC time as a build number, or one more than the highest build already uploaded (Xcode Cloud counts
    up from its own start number), whichever is higher, so TestFlight always lists the newest build on top."""
    stamp = int(time.strftime("%Y%m%d%H%M", time.gmtime()))
    numbers = [int(v) for v, *_ in recent_builds() if v.isdigit()]
    print(max([stamp] + [n + 1 for n in numbers]))


def wait(version):
    for _ in range(40):   # about 20 minutes
        for v, state, uploaded, *_ in recent_builds():
            if v == version:
                print(f"::notice title=Build {v} received::{state}, uploaded {uploaded}")
                if state == "INVALID":
                    print(f"::error title=Build {v} was rejected::Apple marked it invalid; the account holder gets an email with the reason.")
                    raise SystemExit(1)
                return
        time.sleep(30)
    print(f"::error title=Build {version} never arrived::The upload reported success but App Store Connect has no build {version}. Latest: {recent_builds()}")
    raise SystemExit(1)


def all_builds(query):
    path, found = f"builds?filter[app]={app_id()}&limit=200&{query}", []
    while path:
        res = call("GET", path)
        found += res["data"]
        path = res.get("links", {}).get("next", "").replace(API + "/", "")
    return found


def expire(through, confirm):
    from datetime import datetime
    try:
        cutoff = datetime.fromisoformat(through.strip())
    except ValueError:
        cutoff = None
    if cutoff is None or cutoff.tzinfo is None:
        print(f"::error title=Bad time::{through!r} needs a date, time and UTC offset, e.g. 2026-11-02T14:30:00+05:30")
        raise SystemExit(1)
    found = all_builds("filter[expired]=false&fields[builds]=version,uploadedDate,processingState")
    old = sorted((b for b in found if datetime.fromisoformat(b["attributes"]["uploadedDate"]) <= cutoff),
                 key=lambda b: b["attributes"]["uploadedDate"])
    kept = len(found) - len(old)
    print(f"{len(old)} of {len(found)} unexpired builds were uploaded at or before {cutoff.isoformat()}; {kept} stay.")
    for b in old:
        a = b["attributes"]
        print(f"  build {a['version']}  uploaded {a['uploadedDate']}  {a['processingState']}")
    if not confirm:
        print("::notice title=Dry run::Nothing expired. Run again with confirm to expire the builds listed.")
        return
    failed = []
    for b in old:
        a = b["attributes"]
        req = urllib.request.Request(f"{API}/builds/{b['id']}", method="PATCH",
                                     data=json.dumps({"data": {"type": "builds", "id": b["id"], "attributes": {"expired": True}}}).encode(),
                                     headers={"Authorization": f"Bearer {token()}", "Content-Type": "application/json"})
        try:
            urllib.request.urlopen(req).read()
            print(f"Expired build {a['version']}")
        except urllib.error.HTTPError as e:
            detail = "; ".join(x.get("detail", "") for x in json.loads(e.read() or b"{}").get("errors", [{}]))
            print(f"::warning title=Build {a['version']} not expired ({e.code})::{detail}")
            failed.append(a["version"])
    print(f"::notice title=Expired {len(old) - len(failed)} builds::{len(failed)} failed: {failed or 'none'}")
    if failed:
        raise SystemExit(1)


def version(number=None):
    app = app_id()
    res = call("GET", f"apps/{app}/appStoreVersions?include=build&limit=50"
                      "&fields[appStoreVersions]=versionString,appStoreState,platform,build"
                      "&fields[builds]=version,expired,uploadedDate")
    builds_by_id = {b["id"]: b["attributes"] for b in res.get("included", [])}
    editable = None
    for v in res["data"]:
        a = v["attributes"]
        link = (v["relationships"]["build"].get("data") or {}).get("id")
        b = builds_by_id.get(link)
        shown = f"build {b['version']} (uploaded {b['uploadedDate']}, expired {b['expired']})" if b else "no build attached"
        print(f"::notice title=App Store version {a['versionString']} ({a['platform']}, {a['appStoreState']})::{shown}")
        if a["appStoreState"] in ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED", "REJECTED", "METADATA_REJECTED") and editable is None:
            editable = v
    if not res["data"]:
        print("::notice title=No App Store version::The app has no App Store version yet")
    if not number:
        return
    if editable is None:
        print("::error title=No editable version::No App Store version is being prepared, so no build can be attached")
        raise SystemExit(1)
    found = call("GET", f"builds?filter[app]={app}&filter[version]={number}&limit=1")["data"]
    if not found:
        print(f"::error title=No build {number}::App Store Connect has no build {number}")
        raise SystemExit(1)
    call("PATCH", f"appStoreVersions/{editable['id']}/relationships/build", {"data": {"type": "builds", "id": found[0]["id"]}})
    print(f"::notice title=Attached build {number}::to App Store version {editable['attributes']['versionString']}")


if __name__ == "__main__":
    commands = {"setup": setup, "cleanup": cleanup, "builds": builds, "next": next_build}
    if sys.argv[1] == "wait":
        wait(sys.argv[2])
    elif sys.argv[1] == "version":
        version(sys.argv[2] if len(sys.argv) > 2 else None)
    elif sys.argv[1] == "expire":
        expire(sys.argv[2], "--confirm" in sys.argv[3:])
    else:
        commands[sys.argv[1]]()
