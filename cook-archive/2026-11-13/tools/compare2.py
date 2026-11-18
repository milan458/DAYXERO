"""Full-size critic sheets: per screen [AFTER light | AFTER dark] at 390px (real phone size), 2 screens per row, 2 rows per sheet.
usage: python3 -I compare2.py <stills_dir> <out_prefix> [ids...]"""
import sys, os, glob
from PIL import Image, ImageDraw
st, outp = sys.argv[1], sys.argv[2]
ids = sys.argv[3:] or sorted({os.path.basename(f)[:-10] for f in glob.glob(os.path.join(st, '*-light.png'))})
TW, TH, GAP, LAB = 390, 844, 10, 26
def tile(p):
    im = Image.open(p).convert('RGB')
    return im.resize((TW, TH)) if im.size != (TW, TH) else im
per = 4
for n, s in enumerate(range(0, len(ids), per), 1):
    chunk = ids[s:s + per]; rows = (len(chunk) + 1) // 2
    W = 2 * (2 * TW + GAP) + 40; H = rows * (TH + LAB + GAP) + GAP
    sh = Image.new('RGB', (W, H), (90, 90, 90)); d = ImageDraw.Draw(sh)
    for k, i in enumerate(chunk):
        x0 = (k % 2) * (2 * TW + GAP + 40); y0 = (k // 2) * (TH + LAB + GAP) + GAP
        d.text((x0 + 4, y0 + 6), f'{i}   [light | dark]  (real size)', fill='white')
        for j, m in enumerate(['light', 'dark']): sh.paste(tile(os.path.join(st, f'{i}-{m}.png')), (x0 + j * (TW + GAP), y0 + LAB))
    o = f'{outp}{n:02d}.jpg'; sh.save(o, quality=86); print(o)
