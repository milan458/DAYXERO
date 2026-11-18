# usage: python3 cook/tools/sheet.py rNN -> cook/stills/rNN/sheet-light.jpg, sheet-dark.jpg (all eight screens at 1x)
import sys
from PIL import Image
r = sys.argv[1]
for th in ('light', 'dark'):
    ims = [Image.open(f'cook/stills/{r}/S{i}-{th}.png') for i in range(1, 9)]
    ims = [i.resize((i.width // 2, i.height // 2), Image.LANCZOS) for i in ims]
    H = max(i.height for i in ims); W = sum(i.width for i in ims) + 24 * 9
    bg = Image.new('RGB', (W, H + 48), (38, 38, 42)); x = 24
    for im in ims: bg.paste(im, (x, 24)); x += im.width + 24
    bg.save(f'cook/stills/{r}/sheet-{th}.jpg', quality=90)
