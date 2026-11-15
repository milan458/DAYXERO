#!/usr/bin/env python3
"""Render the DayXero program audio with ElevenLabs, following docs/program/RENDER_PLAN.md.

    python3 tools/vo_render.py --dry-run            # print the queue and total, no API calls
    python3 tools/vo_render.py --limit 3            # render the next 3 files, then stop
    python3 tools/vo_render.py --through W1D7.1:smoking
    python3 tools/vo_render.py                      # carry on until the plan ends or the budget guard stops it
    python3 tools/vo_render.py --timestamps         # same, and save word timings for captions with each render
    python3 tools/vo_render.py --align              # word timings for files rendered without them (forced alignment)

The API key is read from the environment variable ELEVENLABS_API_KEY and is never printed or written.
One request per track: the whole script goes in a single Create speech call (model eleven_v4).
Reruns never pay twice: a text whose hash is already in the manifest is skipped (or copied).

API reference used (read 15 Nov 2026):
  POST /v1/text-to-speech/{voice_id}                  Create speech; eleven_v4 limit is 10,000 characters
  POST /v1/text-to-speech/{voice_id}/with-timestamps  same, plus character-level alignment (--timestamps)
  POST /v1/forced-alignment                           word timings for an existing audio file and its text
  GET  /v1/user/subscription                          character_count / character_limit
  GET  /v1/voices/{voice_id}                          is the voice usable by this account
  Response headers: request-id, character-cost
"""
import argparse, base64, datetime, hashlib, json, os, pathlib, re, shutil, subprocess, sys
import urllib.error, urllib.request

REPO = pathlib.Path(__file__).resolve().parent.parent
PROGRAM = REPO / "docs" / "program"
PLAN = PROGRAM / "RENDER_PLAN.md"

VOICE_ID = "gYGXjks6FzTWwNQ6X7hC"   # Monique - Empathetic, Calm & Nurturing
MODEL_ID = "eleven_v4"
MODEL_CHAR_LIMIT = 10_000
JOB_BUDGET = 130_000
API = "https://api.elevenlabs.io"
VARIANTS = {"smoking": 0, "vaping": 1, "pouches": 2}
LOUDNORM = "I=-16:TP=-1.5:LRA=11"

# Same expressions as tools/program-scripts/extract.py
VAR = re.compile(r"\{s:\s*((?:[^{}|])*)\|\s*v:\s*((?:[^{}|])*)\|\s*p:\s*((?:[^{}])*)\}")
STEP = re.compile(r"^## Step (\d) · Listen · (.+?)\s*\(([^)]*)\)\s*$(.*?)(?=^## Step \d|^## End of day|^# |\Z)", re.M | re.S)
SCRIPT = re.compile(r"### Script[^\n]*\n(.*?)\nWord count:\s*([^\n]+)", re.S)


class Stop(Exception):
    """A condition the person has to look at. Nothing is retried."""


# ---------- scripts ----------

def load_tracks():
    """{"P1.5": (title, raw script body)} for every Listen step."""
    tracks = {}

    def take(sid, text):
        for m in STEP.finditer(text):
            step, title, _mins, block = m.groups()
            sm = SCRIPT.search(block)
            if not sm:
                raise Stop(f"{sid} step {step}: no '### Script … Word count:' block found")
            tracks[f"{sid}.{step}"] = (title.strip(), sm.group(1))

    for sid in ["P1", "P2", "P3", "P4", "P5", "P6", "P7", "DX"] + [f"W1D{d}" for d in range(1, 8)]:
        take(sid, (PROGRAM / f"{sid}.md").read_text(encoding="utf-8"))
    draft = (PROGRAM / "W2_W4_SCRIPTS_DRAFT.md").read_text(encoding="utf-8")
    for m in re.finditer(r"^# (W\dS\d) · [^\n]*\n(.*?)(?=^# W\dS\d · |\Z)", draft, re.M | re.S):
        take(m.group(1), m.group(2))
    return tracks


def render_text(body, variant):
    """The exact text sent to ElevenLabs. Only three things are removed: the 'Voice direction:'
    line, chapter headings and lines starting with '>'. Tags and IPA stay as written."""
    body = re.sub(r"^Voice direction:.*$", "", body, flags=re.M)
    body = re.sub(r"^## Chapter[^\n]*$", "", body, flags=re.M)
    body = re.sub(r"^>.*$", "", body, flags=re.M)
    body = re.sub(r"\n{3,}", "\n\n", body).strip()
    k = VARIANTS[variant]
    text = VAR.sub(lambda m: m.group(k + 1).strip(), body)
    if "{" in text or "}" in text:
        raise Stop(f"unresolved variant markup left in a {variant} script: {re.findall(r'.{0,30}[{}].{0,40}', text)[:2]}")
    return text


def load_plan():
    rows = []
    for line in PLAN.read_text(encoding="utf-8").splitlines():
        c = [x.strip() for x in line.split("|")]
        if len(c) > 7 and c[1].isdigit():
            rows.append({"n": int(c[1]), "track": c[2], "variant": c[3], "title": c[4],
                         "credits": int(c[5]), "running": int(c[6]), "note": c[7]})
    if not rows:
        raise Stop("no rows found in RENDER_PLAN.md")
    return rows


def build_queue():
    """Plan rows with their text, checked against the plan's character counts."""
    tracks, problems, queue = load_tracks(), [], []
    for r in load_plan():
        if r["track"] not in tracks:
            problems.append(f"#{r['n']} {r['track']}: no script found"); continue
        title, body = tracks[r["track"]]
        text = render_text(body, r["variant"])
        sid, step = r["track"].split(".")
        q = dict(r, text=text, chars=len(text), sha=hashlib.sha256(text.encode("utf-8")).hexdigest(),
                 file=f"vo_{sid}_{step}_{r['variant']}.m4a", doc_title=title)
        if r["note"].startswith("done"):
            q["kind"] = "done"
        elif r["note"].startswith("copy of"):
            q["kind"], q["src_variant"] = "copy", r["note"].split()[-1]
            src = render_text(body, q["src_variant"])
            if src != text:
                problems.append(f"#{r['n']} {r['track']} {r['variant']}: plan says copy of {q['src_variant']} but the texts differ ({len(text)} vs {len(src)} chars)")
            q["src_file"] = f"vo_{sid}_{step}_{q['src_variant']}.m4a"
        else:
            q["kind"] = "render"
            if q["chars"] != r["credits"]:
                problems.append(f"#{r['n']} {r['track']} {r['variant']}: {q['chars']} characters here, {r['credits']} in the plan")
            if q["chars"] > MODEL_CHAR_LIMIT:
                problems.append(f"#{r['n']} {r['track']} {r['variant']}: {q['chars']} characters is over the {MODEL_ID} limit of {MODEL_CHAR_LIMIT}")
        if title != r["title"]:
            problems.append(f"#{r['n']} {r['track']}: title '{title}' in the script, '{r['title']}' in the plan")
        queue.append(q)
    return queue, problems


# ---------- manifest ----------

class Manifest:
    def __init__(self, out):
        self.path = out / "manifest.json"
        self.items = json.loads(self.path.read_text(encoding="utf-8")) if self.path.exists() else []

    def by_file(self, name):
        return next((i for i in self.items if i["file"] == name), None)

    def by_hash(self, sha):
        return next((i for i in self.items if i["text_sha256"] == sha and i["kind"] == "render"), None)

    def add(self, item):
        self.items = [i for i in self.items if i["file"] != item["file"]] + [item]
        tmp = self.path.with_suffix(".tmp")
        tmp.write_text(json.dumps(self.items, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        tmp.replace(self.path)

    def spent(self):
        return sum(i.get("credits", 0) + i.get("align_credits", 0) for i in self.items)


# ---------- ElevenLabs ----------

def api_key():
    key = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    if not key:
        raise Stop("ELEVENLABS_API_KEY is not set in the environment")
    return key


def call(method, path, body=None, timeout=900, content_type="application/json"):
    """One HTTP request. Returns (status, headers, bytes). Never raises on an HTTP status."""
    data = body if isinstance(body, bytes) else json.dumps(body).encode("utf-8") if body is not None else None
    req = urllib.request.Request(API + path, method=method, data=data,
                                 headers={"xi-api-key": api_key(), "Content-Type": content_type})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, r.headers, r.read()
    except urllib.error.HTTPError as e:
        return e.code, e.headers, e.read()


def remaining_credits():
    status, _, data = call("GET", "/v1/user/subscription", timeout=60)
    if status != 200:
        raise Stop(f"could not read credits: HTTP {status} {data[:300].decode('utf-8', 'replace')}")
    sub = json.loads(data)
    return sub["character_limit"] - sub["character_count"], sub.get("tier", "")


def check_voice():
    status, _, data = call("GET", f"/v1/voices/{VOICE_ID}", timeout=60)
    if status != 200:
        raise Stop(f"voice {VOICE_ID} is not usable by this account (HTTP {status} {data[:200].decode('utf-8', 'replace')}). "
                   "It is a Voice Library voice: add it to My Voices first (Voice Library > Monique > Add, or "
                   "POST /v1/voices/add/{public_user_id}/{voice_id}), then run again.")


def synthesize(text, output_format, timestamps):
    """One Create speech request, retried at most once and only where no audio can have been made
    (HTTP 429 or 5xx, or a connection that never opened). Returns (audio, alignment, request_id, cost)."""
    path = f"/v1/text-to-speech/{VOICE_ID}{'/with-timestamps' if timestamps else ''}?output_format={output_format}"
    body = {"text": text, "model_id": MODEL_ID}
    last = None
    for attempt in (1, 2):
        try:
            status, headers, data = call("POST", path, body)
        except (urllib.error.URLError, ConnectionError) as e:
            last = f"connection failed: {getattr(e, 'reason', e)}"
            if isinstance(getattr(e, "reason", None), TimeoutError):
                break                     # the request may have been charged; do not send it again
            continue
        except TimeoutError:
            last = "timed out waiting for the audio (it may have been charged; check the ElevenLabs history)"
            break
        if status == 200:
            cost = headers.get("character-cost")
            alignment = None
            if timestamps:
                j = json.loads(data)
                data, alignment = base64.b64decode(j["audio_base64"]), j.get("alignment")
            return data, alignment, headers.get("request-id", ""), int(cost) if cost and cost.isdigit() else None
        last = f"HTTP {status} {data[:400].decode('utf-8', 'replace')}"
        if status != 429 and status < 500:
            break
        print(f"    attempt {attempt} failed ({last[:120]})" + ("; retrying once" if attempt == 1 else ""))
    raise Stop(f"request failed: {last}")


def caption_text(text):
    """The words that are heard: the script without [tags] and without IPA in slashes."""
    text = re.sub(r"\[[^\]]*\]", "", text)
    text = re.sub(r"\s*/[^/\s][^/\n]*/", "", text)
    return re.sub(r"[ \t]+", " ", text).strip()


def force_align(audio_path, text):
    """Word timings for an existing file (POST /v1/forced-alignment). Retried at most once, on 429/5xx only."""
    boundary = "----dayxero" + hashlib.sha256(audio_path.name.encode()).hexdigest()[:24]
    body = (f'--{boundary}\r\nContent-Disposition: form-data; name="text"\r\n\r\n{caption_text(text)}\r\n'
            f'--{boundary}\r\nContent-Disposition: form-data; name="file"; filename="{audio_path.name}"\r\n'
            f'Content-Type: audio/mp4\r\n\r\n').encode("utf-8") + audio_path.read_bytes() + f"\r\n--{boundary}--\r\n".encode()
    last = None
    for attempt in (1, 2):
        try:
            status, _, data = call("POST", "/v1/forced-alignment", body, content_type=f"multipart/form-data; boundary={boundary}")
        except (urllib.error.URLError, ConnectionError, TimeoutError) as e:
            last = f"connection failed or timed out: {getattr(e, 'reason', e)}"; break
        if status == 200:
            j = json.loads(data)
            return {"source": "forced-alignment", "loss": j.get("loss"),
                    "words": [{"word": w["text"], "start": round(w["start"], 3), "end": round(w["end"], 3)}
                              for w in j["words"] if w["text"].strip()]}
        last = f"HTTP {status} {data[:400].decode('utf-8', 'replace')}"
        if status != 429 and status < 500:
            break
    raise Stop(f"alignment failed for {audio_path.name}: {last}")


def words_from_alignment(al):
    """Word-level timings from ElevenLabs' character-level alignment; [tags] and /IPA/ are left out."""
    words, cur, start, end, depth = [], "", None, None, 0
    for ch, s, e in zip(al["characters"], al["character_start_times_seconds"], al["character_end_times_seconds"]):
        if ch == "[": depth += 1
        if depth == 0 and not ch.isspace():
            cur, start, end = cur + ch, s if start is None else start, e
        elif cur:
            words.append({"word": cur, "start": round(start, 3), "end": round(end, 3)}); cur, start = "", None
        if ch == "]" and depth: depth -= 1
    if cur:
        words.append({"word": cur, "start": round(start, 3), "end": round(end, 3)})
    return [w for w in words if not re.fullmatch(r"/[^/]+/[.,;:]?", w["word"])]


# ---------- audio ----------

def encode_m4a(src, dst):
    """AAC mono at -16 LUFS: measure, then a second loudnorm pass with the measured values."""
    probe = subprocess.run(["ffmpeg", "-hide_banner", "-nostdin", "-i", str(src), "-ac", "1",
                            "-af", f"loudnorm={LOUDNORM}:print_format=json", "-f", "null", "-"],
                           capture_output=True, text=True)
    m = re.search(r"\{[^{}]*\"input_i\"[^{}]*\}", probe.stderr, re.S)
    if probe.returncode or not m:
        raise Stop(f"ffmpeg could not measure {src.name}: {probe.stderr[-300:]}")
    s = json.loads(m.group(0))
    af = (f"loudnorm={LOUDNORM}:measured_I={s['input_i']}:measured_TP={s['input_tp']}:measured_LRA={s['input_lra']}"
          f":measured_thresh={s['input_thresh']}:offset={s['target_offset']}:linear=true")
    tmp = dst.with_suffix(".tmp.m4a")
    run = subprocess.run(["ffmpeg", "-hide_banner", "-nostdin", "-y", "-i", str(src), "-ac", "1", "-af", af,
                          "-ar", "44100", "-c:a", "aac", "-b:a", "96k", "-movflags", "+faststart", str(tmp)],
                         capture_output=True, text=True)
    if run.returncode:
        raise Stop(f"ffmpeg could not encode {dst.name}: {run.stderr[-300:]}")
    tmp.replace(dst)


# ---------- main ----------

def print_queue(queue, man):
    print(f"{'#':>3} {'track':7} {'variant':8} {'chars':>6} {'running':>8}  action")
    total = 0
    for q in queue:
        have = man.by_file(q["file"])
        if q["kind"] == "done":
            action = "skip: done 15 Nov, download from ElevenLabs"
        elif have:
            action = f"skip: in manifest ({have['kind']})"
        elif q["kind"] == "copy":
            action = f"copy of {q['src_file']}"
        else:
            action = "RENDER"; total += q["chars"]
        if q["kind"] == "render" and have:
            total += have.get("credits", 0)
        print(f"{q['n']:>3} {q['track']:7} {q['variant']:8} {q['chars']:>6} {total:>8}  {action}")
    return total


def align_missing(queue, man, args):
    """Word timings for every finished file that has none. The credits count toward the job total."""
    made, stopped = 0, "nothing left to align"
    try:
        for q in queue:
            m4a, cap = args.out / q["file"], args.out / "captions" / f"{pathlib.Path(q['file']).stem}.json"
            have = man.by_file(q["file"])
            if cap.exists() or not m4a.exists():
                continue                                  # has timings already, or no audio yet
            if have and have["kind"] == "copy":
                src = args.out / "captions" / f"{pathlib.Path(have['copy_of']).stem}.json"
                if src.exists(): shutil.copyfile(src, cap)
                continue
            if args.limit is not None and made >= args.limit:
                stopped = f"--limit {args.limit}"; break
            before, _ = remaining_credits()
            if man.spent() >= args.budget or before <= 0:
                stopped = "budget guard"; break
            result = force_align(m4a, q["text"])
            cap.write_text(json.dumps(result, ensure_ascii=False), encoding="utf-8")
            after, _ = remaining_credits()
            if have:
                man.add(dict(have, align_credits=before - after))
            made += 1
            print(f"#{q['n']} {q['track']} {q['variant']}: {len(result['words'])} words aligned, {before - after:,} credits, loss {result['loss']}")
    except Stop as e:
        stopped = f"STOPPED: {e}"
    print(f"\nAligned {made} file(s). Job total {man.spent():,} of {args.budget:,}. Stopped at: {stopped}")
    return 1 if stopped.startswith("STOPPED") else 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--dry-run", action="store_true", help="print the queue and total; no API calls")
    ap.add_argument("--limit", type=int, help="render at most this many new files, then stop")
    ap.add_argument("--through", metavar="TRACK:VARIANT", help="stop after this plan row, e.g. W1D7.1:smoking")
    ap.add_argument("--out", type=pathlib.Path, default=REPO / "vo_out", help="output folder (default: vo_out/)")
    ap.add_argument("--budget", type=int, default=JOB_BUDGET, help=f"hard stop for this job's running total (default {JOB_BUDGET})")
    ap.add_argument("--output-format", help="ElevenLabs output_format for the download (default: by plan tier)")
    ap.add_argument("--timestamps", action="store_true", help="use the with-timestamps endpoint and save word timings for captions")
    ap.add_argument("--align", action="store_true", help="no rendering: make word timings for files that have none (forced alignment)")
    args = ap.parse_args()

    queue, problems = build_queue()
    man = Manifest(args.out)
    if problems:
        print("STOP: the scripts do not match RENDER_PLAN.md:")
        for p in problems: print("  -", p)
        return 2

    if args.through:
        tr, _, va = args.through.partition(":")
        idx = [i for i, q in enumerate(queue) if q["track"] == tr and q["variant"] == va]
        if not idx:
            print(f"STOP: --through {args.through} is not a row in the plan"); return 2
        queue_run = queue[: idx[0] + 1]
    else:
        queue_run = queue

    if args.dry_run:
        total = print_queue(queue, man)
        renders = [q for q in queue if q["kind"] == "render"]
        print(f"\n{len(queue)} rows: {len(renders)} renders, {sum(q['kind'] == 'copy' for q in queue)} copies, "
              f"{sum(q['kind'] == 'done' for q in queue)} already done.")
        print(f"Whole plan: {total:,} characters. Longest track {max(q['chars'] for q in renders):,} (limit {MODEL_CHAR_LIMIT:,}).")
        within = [q for q in renders if q["running"] <= args.budget]
        print(f"Budget guard {args.budget:,}: stops after #{within[-1]['n']} {within[-1]['track']} {within[-1]['variant']} "
              f"at {within[-1]['running']:,}; already spent on this job: {man.spent():,}.")
        return 0

    for d in (args.out, args.out / "originals", args.out / "captions"):
        d.mkdir(parents=True, exist_ok=True)
    api_key(); check_voice()
    _, tier = remaining_credits()
    fmt = args.output_format or ("mp3_44100_128" if tier in ("free", "starter") else "mp3_44100_192")
    ext = "mp3" if fmt.startswith("mp3") else fmt.split("_")[0]
    rendered, stopped = 0, "end of the plan" if not args.through else f"--through {args.through}"
    if args.align:
        return align_missing(queue_run, man, args)

    try:
        for q in queue_run:
            label = f"#{q['n']} {q['track']} {q['variant']}"
            m4a = args.out / q["file"]
            have = man.by_file(q["file"])
            if q["kind"] == "done":
                continue
            if have:                                          # paid for (or copied) already
                orig = args.out / have.get("original", "")
                if not m4a.exists() and have["kind"] == "render" and orig.is_file():
                    encode_m4a(orig, m4a); print(f"{label}: re-encoded from the saved original")
                continue
            twin = man.by_hash(q["sha"])
            if twin:                                          # identical text already rendered: copy it
                if not (args.out / twin["file"]).exists():
                    raise Stop(f"{label}: source {twin['file']} is in the manifest but the file is missing")
                shutil.copyfile(args.out / twin["file"], m4a)
                cap = args.out / "captions" / f"{pathlib.Path(twin['file']).stem}.json"
                if cap.exists():
                    shutil.copyfile(cap, args.out / "captions" / f"{m4a.stem}.json")
                man.add({"file": q["file"], "kind": "copy", "copy_of": twin["file"], "text_sha256": q["sha"],
                         "characters": q["chars"], "credits": 0, "request_id": twin["request_id"],
                         "date": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")})
                print(f"{label}: copied from {twin['file']}")
                continue
            if q["kind"] == "copy":
                print(f"{label}: copy pending, {q['src_file']} has not been rendered yet")
                continue
            if args.limit is not None and rendered >= args.limit:
                stopped = f"--limit {args.limit}, next is {label}"; break

            spent = man.spent()                               # budget guard, before every request
            if spent + q["chars"] > args.budget:
                stopped = f"budget guard: job total {spent:,} + {q['chars']:,} for {label} would pass {args.budget:,}"; break
            left, _ = remaining_credits()
            if left < q["chars"]:
                stopped = f"budget guard: {left:,} credits left, {label} needs {q['chars']:,}"; break

            print(f"{label}: rendering {q['chars']:,} characters ({left:,} credits left, job total {spent:,})")
            audio, alignment, request_id, cost = synthesize(q["text"], fmt, args.timestamps)
            orig = args.out / "originals" / f"{m4a.stem}.{ext}"
            orig.write_bytes(audio)
            man.add({"file": q["file"], "kind": "render", "original": f"originals/{orig.name}", "text_sha256": q["sha"],
                     "characters": q["chars"], "credits": cost if cost is not None else q["chars"],
                     "credits_source": "character-cost header" if cost is not None else "character count",
                     "request_id": request_id, "voice_id": VOICE_ID, "model_id": MODEL_ID, "output_format": fmt,
                     "date": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds")})
            rendered += 1
            if alignment:
                (args.out / "captions" / f"{m4a.stem}.json").write_text(
                    json.dumps({"source": "with-timestamps", "words": words_from_alignment(alignment), "alignment": alignment},
                               ensure_ascii=False), encoding="utf-8")
            encode_m4a(orig, m4a)
            if cost is not None and cost > q["chars"]:
                raise Stop(f"{label} was charged {cost:,} credits for {q['chars']:,} characters. The plan assumes at most "
                           "one credit per character, so the totals are off. Saved the file; stopping for you to look.")
            print(f"    saved {q['file']} (request {request_id}, {cost if cost is not None else q['chars']:,} credits)")
    except Stop as e:
        stopped = f"STOPPED: {e}"

    print(f"\nRendered {rendered} file(s) this run. Job total {man.spent():,} of {args.budget:,}. Stopped at: {stopped}")
    return 1 if stopped.startswith("STOPPED") else 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Stop as e:
        print(f"STOP: {e}"); sys.exit(2)
