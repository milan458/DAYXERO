"""Checks deck sessions (docs/program/DECK_SCHEMA.md) before they go into program.json.

    python3 -I tools/program-deck/validate.py docs/program/json            # check the fragments
    python3 -I tools/program-deck/validate.py --program DayXeroCore/Resources/program.json   # check the merged file

It mirrors ProgramContent.problems() for beats and adds the deck rules. Exit code 1 when anything is wrong.
"""
import json, re, sys, pathlib

ORDER = ["P1", "P2", "P3", "P4", "P5", "P6", "P7", "DX"]
PRODUCTS = ["smoking", "vaping", "pouches"]
VARIED_KEYS = {"default", "smoking", "vaping", "pouches", "nrt"}
KNOWN = {"unit_singular", "unit_plural", "daily_units", "yearly_units", "currency", "yearly_cost", "quit_date",
         "primary_reason", "days_free", "money_kept", "cravings_ridden", "product", "product_plural", "item"}
KINDS = {"stat_reveal", "quiz", "choice", "slider", "slider_group", "reflect", "tap_reveal", "plan_builder", "checklist",
         "breathe", "commit", "scenario", "note", "info", "share", "nrt_choice", "nrt_stepdown", "slip_debrief_practice",
         "plan_card", "body_map", "scale", "timed_hold", "sos_practice", "per_item"}
PATTERNS = {"box", "478", "wave", "sigh", "slow"}
SETS = {"quit_timestamp", "dayxero_ready", "graduated_at"}
LOGTYPES = {"use", "morning_buffer", "mindful_use", "stress_sigh", "surf_practice", "craving_outcome"}
FORMATS = {"listen", "reveal", "myth", "try", "breathe"}
GROUNDS = {"apricot", "violet", "mint", "ocean", "sky", "sun"}
TEXT_FIELDS = ["prompt", "title", "text", "body", "label", "feedback", "footer", "placeholder", "minLabel", "maxLabel",
               "safetyText", "intro", "outro", "prefill"]
INLINE = re.compile(r"\{s:([^{}|]*)\|\s*v:([^{}|]*)\|\s*p:([^{}]*)\}")
ONBOARDING = {"reasons", "primary_reason"}

problems = []


def resolve(value, product):
    if value is None:
        return None
    if isinstance(value, dict):
        bad = set(value) - VARIED_KEYS
        if bad:
            return ("__BADKEYS__", bad)
        return value.get(product, value.get("default"))
    return value


def inline(text, product):
    k = PRODUCTS.index(product)
    return INLINE.sub(lambda m: m.group(k + 1).strip(), text)


def check_text(value, place, allow_missing=False):
    if value is None:
        return
    for product in PRODUCTS:
        v = resolve(value, product)
        if isinstance(v, tuple):
            problems.append(f"{place}: unknown product keys {sorted(v[1])}")
            return
        if v is None:
            if not allow_missing:
                problems.append(f"{place}: nothing for {product}")
            continue
        if not isinstance(v, str):
            problems.append(f"{place}: not text")
            continue
        t = inline(v, product)
        if "{s:" in t or "| v:" in t:
            problems.append(f"{place}: variant markup doesn't resolve ({product})")
        for name in re.findall(r"\{([^{}]*)\}", t):
            if name not in KNOWN:
                problems.append(f"{place}: unknown placeholder {{{name}}}")
        if "!" in t:
            problems.append(f"{place}: exclamation mark")


def beat_reads(b):
    keys = [b.get(k) for k in ("optionsFrom", "prefillFrom", "textFrom", "highlightFrom", "compareWith", "carryOverFrom", "quoteFrom")]
    keys += [c.get("backFrom") for c in b.get("cards", []) or []]
    keys += b.get("fields", []) or []
    return [k for k in keys if k]


def beat_writes(b):
    w = [b["saveAs"]] if b.get("saveAs") else []
    if b.get("type") == "slider_group":
        w += [i.get("saveAs") for i in b.get("items", []) if i.get("saveAs")]
    return w


def check_beat(b, place, saved, ids):
    bid = b.get("id")
    if not bid:
        problems.append(f"{place}: beat without id"); return
    if bid in ids:
        problems.append(f"{place}: id {bid} used twice")
    ids.add(bid)
    p = f"{place}/{bid}"
    kind = b.get("type")
    if kind not in KINDS:
        problems.append(f"{p}: unknown kind {kind}"); return
    for f in TEXT_FIELDS:
        check_text(b.get(f), f"{p}.{f}", allow_missing=(f == "footer"))
    for i, line in enumerate(b.get("lines", []) or []):
        check_text(line, f"{p}.lines[{i}]")
        if "{s:" in json.dumps(line):
            problems.append(f"{p}.lines[{i}]: no inline {{s:|v:|p:}} in stat lines; use an object by product")
    opts = b.get("options")
    if opts is not None:
        for product in PRODUCTS:
            o = resolve(opts, product)
            if not isinstance(o, list):
                problems.append(f"{p}.options: nothing for {product}"); continue
            for j, opt in enumerate(o):
                if "id" not in opt or "text" not in opt:
                    problems.append(f"{p}.options[{j}]: needs id and text")
                else:
                    check_text(opt["text"], f"{p}.options[{j}].text")
                    if "{s:" in json.dumps(opt):
                        problems.append(f"{p}.options[{j}]: no inline {{s:|v:|p:}} in options (saved as written); use an options object by product")
                    if opt.get("feedback"): check_text(opt["feedback"], f"{p}.options[{j}].feedback")
            if kind == "quiz" and b.get("correctId") not in [x.get("id") for x in o]:
                problems.append(f"{p}: quiz answer isn't one of its options ({product})")
    if kind in ("choice", "quiz") and opts is None and not b.get("optionsFrom"):
        problems.append(f"{p}: {kind} has no options")
    if kind == "breathe" and b.get("pattern") not in PATTERNS:
        problems.append(f"{p}: breathes a pattern the orb doesn't have ({b.get('pattern')})")
    if kind == "commit":
        if not b.get("text"): problems.append(f"{p}: commit has no text")
        if b.get("sets") and b["sets"] not in SETS: problems.append(f"{p}: commit sets unknown key {b['sets']}")
    if kind == "per_item":
        if not b.get("optionsFrom"): problems.append(f"{p}: per_item names no list (optionsFrom)")
        qs = b.get("questions") or []
        if not qs: problems.append(f"{p}: per_item has no questions")
        for qi, q in enumerate(qs):
            check_text(q.get("prompt"), f"{p}.questions[{qi}].prompt")
            for product in PRODUCTS:
                o = resolve(q.get("options"), product)
                if not isinstance(o, list) or not o: problems.append(f"{p}.questions[{qi}]: no options for {product}")
    if kind in ("scale", "body_map") and not b.get("saveAs"):
        problems.append(f"{p}: {kind} saves nothing")
    if kind == "timed_hold" and not (b.get("holdSeconds") or 0) > 0:
        problems.append(f"{p}: timed_hold holds for no time")
    if kind == "slider" and not b.get("saveAs"):
        problems.append(f"{p}: slider saves nothing")
    if kind == "checklist":
        items = b.get("items")
        for product in PRODUCTS:
            it = resolve(items, product) if isinstance(items, dict) else items
            if not isinstance(it, list) or not it:
                problems.append(f"{p}.items: nothing for {product}")
        if "{s:" in json.dumps(items):
            problems.append(f"{p}.items: no inline {{s:|v:|p:}} in checklist items (saved as written); use an items object by product")
    for c in b.get("cards", []) or []:
        check_text(c.get("front"), f"{p}.cards.front")
        if c.get("back") is not None: check_text(c.get("back"), f"{p}.cards.back")
    for key in beat_reads(b):
        if key not in saved:
            problems.append(f"{p}: reads {key} before anything saves it")
    saved.update(beat_writes(b))


def check_session(s, saved, ids):
    sid = s.get("id", "?")
    for k in ("id", "phaseId", "label", "title", "subtitle", "durationMinutes", "unlock", "audio", "beats", "deck", "completionText"):
        if k not in s:
            problems.append(f"{sid}: missing {k}")
    if s.get("beats") != []:
        problems.append(f"{sid}: beats must be [] for a deck session")
    if "cards" in s:
        problems.append(f"{sid}: no old 'cards' stack in a deck session")
    for k in ("title", "subtitle", "completionText"):
        check_text(s.get(k), f"{sid}.{k}")
    deck = s.get("deck", [])
    if len(deck) != 5:
        problems.append(f"{sid}: {len(deck)} cards; a day has 5")
    if sum(c.get("minutes", 0) for c in deck) != s.get("durationMinutes"):
        problems.append(f"{sid}: durationMinutes isn't the sum of the card minutes")
    for n, card in enumerate(deck, 1):
        cid = card.get("id")
        place = f"{sid}/{cid}"
        if cid != f"{sid}.{n}":
            problems.append(f"{place}: card id should be {sid}.{n}")
        fmt = card.get("format")
        if fmt not in FORMATS:
            problems.append(f"{place}: unknown format {fmt}"); continue
        if not isinstance(card.get("minutes"), int):
            problems.append(f"{place}: minutes must be a whole number")
        if card.get("ground") and card["ground"] not in GROUNDS:
            problems.append(f"{place}: unknown ground {card['ground']}")
        for k in ("title", "commit", "intro", "after"):
            check_text(card.get(k), f"{place}.{k}")
        if not card.get("commit"):
            problems.append(f"{place}: no commit button")
        for b in card.get("before", []) or []:
            check_beat(b, place, saved, ids)
        if fmt == "listen":
            ch = (card.get("script") or {}).get("chapters") or []
            if not ch:
                problems.append(f"{place}: listen card without script chapters")
            for i, c in enumerate(ch):
                if not c.get("title") or c["title"].lower().startswith("chapter"):
                    problems.append(f"{place}.script.chapters[{i}]: title missing or still says Chapter")
                for product in PRODUCTS:
                    t = resolve(c.get("text"), product)
                    if not t or len(t.split()) < 30:
                        problems.append(f"{place}.script.chapters[{i}]: text missing or very short ({product})")
                    elif "{s:" in inline(t, product):
                        problems.append(f"{place}.script.chapters[{i}]: variant markup doesn't resolve")
        if fmt == "reveal":
            cards = card.get("cards") or []
            if not 4 <= len(cards) <= 6:
                problems.append(f"{place}: reveal has {len(cards)} cards (4 to 6)")
            for i, c in enumerate(cards):
                for k in ("front", "answer", "deeper"):
                    if not c.get(k): problems.append(f"{place}.cards[{i}]: no {k}")
                    else: check_text(c[k], f"{place}.cards[{i}].{k}")
                for k in ("keep", "source"):
                    if c.get(k): check_text(c[k], f"{place}.cards[{i}].{k}")
        if fmt == "myth":
            st = card.get("statements") or []
            if len(st) != 5:
                problems.append(f"{place}: {len(st)} statements (5)")
            for i, x in enumerate(st):
                for k in ("text", "verdict", "explanation"):
                    if not x.get(k): problems.append(f"{place}.statements[{i}]: no {k}")
                    else: check_text(x[k], f"{place}.statements[{i}].{k}")
                if x.get("source"): check_text(x["source"], f"{place}.statements[{i}].source")
                for product in PRODUCTS:
                    a = resolve(x.get("answer"), product)
                    if a not in ("myth", "fact", "partly"):
                        problems.append(f"{place}.statements[{i}]: answer for {product} is {a!r}")
        if fmt in ("try", "breathe") and not card.get("beats"):
            problems.append(f"{place}: {fmt} card without beats")
        for b in card.get("beats", []) or []:
            check_beat(b, place, saved, ids)
        if card.get("opensAt") is not None and not (isinstance(card["opensAt"], int) and 0 <= card["opensAt"] <= 23):
            problems.append(f"{place}: opensAt must be an hour, 0 to 23")
        if card.get("showCount") is not None and not (1 <= card["showCount"] <= len(card.get("cards") or [])):
            problems.append(f"{place}: showCount is more than the cards it has")
    rec = s.get("recap") or {}
    learned = rec.get("learned") or []
    if len(learned) != 3:
        problems.append(f"{sid}.recap: learned needs 3 lines")
    for i, l in enumerate(learned):
        check_text(l, f"{sid}.recap.learned[{i}]")
    for i, l in enumerate(rec.get("statLines") or []):
        check_text(l, f"{sid}.recap.statLines[{i}]")
    if rec.get("tomorrow"): check_text(rec["tomorrow"], f"{sid}.recap.tomorrow")
    m = s.get("mission")
    if m:
        check_text(m.get("text"), f"{sid}.mission")
        if m.get("logType") and m["logType"] not in LOGTYPES:
            problems.append(f"{sid}.mission: unknown logType {m['logType']}")
        for b in m.get("followUp", []) or []:
            check_beat(b, f"{sid}/mission", saved, ids)


def main():
    args = sys.argv[1:]
    saved, ids = set(ONBOARDING), set()
    if args and args[0] == "--program":
        prog = json.loads(pathlib.Path(args[1]).read_text())
        sessions = {s["id"]: s for s in prog["sessions"]}
        for sid in ORDER:
            if sid in sessions and "deck" in sessions[sid]:
                check_session(sessions[sid], saved, ids)
            else:
                problems.append(f"{sid}: not a deck session yet")
        # the later sessions' beats must not reuse an id, and must still find what they read
        for s in prog["sessions"]:
            if s["id"] in ORDER: continue
            for b in s.get("beats", []) + (s.get("mission") or {}).get("followUp", []):
                if b["id"] in ids: problems.append(f"{s['id']}: beat id {b['id']} also used in a deck")
                for key in beat_reads(b):
                    if key not in saved and key not in {x for bb in s.get('beats', []) for x in beat_writes(bb)}:
                        pass
                saved.update(beat_writes(b))
    else:
        folder = pathlib.Path(args[0] if args else "docs/program/json")
        for sid in ORDER:
            f = folder / f"{sid}.json"
            if not f.exists():
                print(f"{sid}: (no file yet)"); continue
            try:
                s = json.loads(f.read_text())
            except json.JSONDecodeError as e:
                problems.append(f"{sid}.json: not valid JSON: {e}"); continue
            check_session(s, saved, ids)
    for p in problems:
        print(p)
    print(f"{len(problems)} problem(s)")
    sys.exit(1 if problems else 0)


if __name__ == "__main__":
    main()
