"""Compare sheets for critics: per screen [before light | after light | after dark], 2 screens per row, 3 rows per sheet.
usage: python3 -I compare.py <stills_dir> <before_dir> <out_prefix>"""
import sys, os, glob
from PIL import Image, ImageDraw
st, bf, outp = sys.argv[1], sys.argv[2], sys.argv[3]
ids = sorted({os.path.basename(f)[:-10] for f in glob.glob(os.path.join(st, '*-light.png'))})
TW = 230; TH = int(TW * 844 / 390); GAP = 8; LAB = 22
def tile(path):
    if path and os.path.exists(path):
        im = Image.open(path).convert('RGB'); im = im.resize((TW, int(TW * im.height / im.width))); return im.crop((0, 0, TW, TH))
    t = Image.new('RGB', (TW, TH), (120, 120, 120)); ImageDraw.Draw(t).text((10, TH // 2), 'new screen', fill='white'); return t
rows = []
for i in ids:
    b = os.path.join(bf, i + '-light.jpg')
    rows.append((i, [tile(b if os.path.exists(b) else None), tile(os.path.join(st, i + '-light.png')), tile(os.path.join(st, i + '-dark.png'))]))
per = 6; n = 0
for s in range(0, len(rows), per):
    chunk = rows[s:s + per]; W = 2 * (3 * TW + 2 * GAP) + 40; H = 3 * (TH + LAB + GAP) + GAP
    sh = Image.new('RGB', (W, H), (90, 90, 90)); d = ImageDraw.Draw(sh)
    for k, (i, tiles) in enumerate(chunk):
        x0 = (k % 2) * (3 * TW + 2 * GAP + 40); y0 = (k // 2) * (TH + LAB + GAP) + GAP
        d.text((x0 + 4, y0 + 4), f'{i}   [before light | AFTER light | AFTER dark]', fill='white')
        for j, t in enumerate(tiles): sh.paste(t, (x0 + j * (TW + GAP), y0 + LAB))
    n += 1; o = f'{outp}{n:02d}.jpg'; sh.save(o, quality=85); print(o)
