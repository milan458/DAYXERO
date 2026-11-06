import re, json, sys, pathlib
root = pathlib.Path(sys.argv[1]); out = pathlib.Path(sys.argv[2])
tracks = []
VAR = re.compile(r"\{s:\s*((?:[^{}|])*)\|\s*v:\s*((?:[^{}|])*)\|\s*p:\s*((?:[^{}])*)\}")
for sid in ["P1","P2","P3","P4","P5","P6","P7","DX"]:
    t = (root/f"{sid}.md").read_text()
    daytitle = t.splitlines()[0].split("·",1)[1].strip()
    for m in re.finditer(r"^## Step (\d) · Listen · (.+?)\s*\(([^)]*)\)\s*$(.*?)(?=^## Step \d|^## End of day)", t, re.M|re.S):
        step, title, mins, block = m.groups()
        sm = re.search(r"### Script[^\n]*\n(.*?)\nWord count:\s*([^\n]+)", block, re.S)
        body, wc = sm.group(1), sm.group(2)
        vd = re.search(r"^Voice direction:\s*(.+)$", body, re.M)
        body = re.sub(r"^Voice direction:.*$", "", body, flags=re.M).strip()
        screen = re.search(r"\*\*Screen:\*\*\s*(.+)|^Screen:\s*(.+)$", block, re.M)
        commit = re.search(r"Commit button:\**\s*\"?“?([^\"\n”]+)", block)
        chapters = []
        for cm in re.finditer(r"^## (Chapter[^\n]*)\n(.*?)(?=^## Chapter|\Z)", body, re.M|re.S):
            chapters.append({"h": cm.group(1).strip(), "text": cm.group(2).strip()})
        if not chapters: chapters=[{"h":"","text":body}]
        tracks.append({"sid":sid,"day":daytitle,"step":int(step),"title":title.strip(),"mins":mins,
            "voice": vd.group(1).strip() if vd else "", "wc": wc.strip(),
            "commit": commit.group(1).strip().strip('*').strip() if commit else "", "chapters":chapters})
# test variant resolution
bad=0
for tr in tracks:
    for ch in tr["chapters"]:
        for k in range(3):
            r = VAR.sub(lambda m: m.group(k+1).strip(), ch["text"])
            if re.search(r"\{[svp]:", r) or "{" in r or "}" in r:
                bad+=1; print("LEFTOVER", tr["sid"], tr["step"], k, re.findall(r".{30}\{.{60}", r)[:2])
print(len(tracks), "tracks; leftover problems:", bad)
for tr in tracks: print(tr["sid"], tr["step"], tr["title"], "|", len(tr["chapters"]), "ch | commit:", tr["commit"])
out.write_text(json.dumps(tracks, ensure_ascii=False))
