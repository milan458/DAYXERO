# usage: python3 cook/tools/pairs.py cook/stills/rNN  -> writes P1..P8.png (light | dark) into cook/compare/rNN
import sys, os
from PIL import Image
src = sys.argv[1]; out = src.replace('stills', 'compare'); os.makedirs(out, exist_ok=True)
for i in range(1, 9):
    a = Image.open(f'{src}/S{i}-light.png'); b = Image.open(f'{src}/S{i}-dark.png')
    bg = Image.new('RGB', (a.width + b.width + 40, a.height), (70, 70, 70))
    bg.paste(a, (0, 0)); bg.paste(b, (a.width + 40, 0)); bg.save(f'{out}/P{i}.png')
