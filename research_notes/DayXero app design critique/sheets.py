# Build contact sheets from the shots folder. Usage: python3 -I sheets.py <shotsDir> <outDir>
import sys, os, json
from PIL import Image, ImageDraw
shots, out = sys.argv[1], sys.argv[2]
os.makedirs(out, exist_ok=True)
screens = json.load(open(os.path.join(shots, '_screens.json')))
TW, TH = 268, 583  # 2/3 scale of 402x874
def sheet(name, files, cols=6):
    files = [f for f in files if os.path.exists(os.path.join(shots, f))]
    if not files: return
    rows = (len(files) + cols - 1) // cols
    im = Image.new('RGB', (cols * (TW + 12) + 12, rows * (TH + 34) + 12), '#ECEAF2')
    d = ImageDraw.Draw(im)
    for i, f in enumerate(files):
        t = Image.open(os.path.join(shots, f)).convert('RGB').resize((TW, TH), Image.LANCZOS)
        x = 12 + (i % cols) * (TW + 12); y = 12 + (i // cols) * (TH + 34)
        im.paste(t, (x, y)); d.text((x, y + TH + 6), f.replace('.png', '')[:44], fill='#1E1A3A')
    im.save(os.path.join(out, name + '.png'))
    print(name, len(files))
areas = {}
for s in screens: areas.setdefault(s['area'], []).append(s['id'])
for a, ids in areas.items():
    sheet('sheet-' + a.lower() + '-light', [i + '--light.png' for i in ids])
    sheet('sheet-' + a.lower() + '-dark', [i + '--dark.png' for i in ids])
idx = json.load(open(os.path.join(shots, '_states_index.json')))
by = {}
for e in idx:
    if not e['dark']: by.setdefault(e['screen'], []).append(e['file'])
for sid, files in by.items():
    if len(files) >= 3: sheet('states-' + sid, files, cols=6)
