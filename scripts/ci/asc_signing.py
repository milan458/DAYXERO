"""App Store signing for CI through the App Store Connect API (S16.4).

xcodebuild's automatic signing rejects our API key, so CI signs by hand:
  setup    registers the App IDs if needed, creates a distribution certificate and
           App Store profiles, and writes the .p12, profiles and build settings to $RUNNER_TEMP.
  cleanup  deletes this run's profiles. The certificate is kept (encrypted in the Actions cache) and reused,
           because revoking it invalidates builds still waiting for review (ITMS-90035).
  builds   lists the builds App Store Connect has for the app.
  wait N   waits for build N to show up after an upload, since altool can report success when nothing arrived.

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


if __name__ == "__main__":
    commands = {"setup": setup, "cleanup": cleanup, "builds": builds}
    if sys.argv[1] == "wait":
        wait(sys.argv[2])
    else:
        commands[sys.argv[1]]()
