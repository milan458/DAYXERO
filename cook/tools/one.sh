#!/bin/sh
# usage: cook/tools/one.sh rNN N  -> renders all, writes a 1x light|dark preview of screen N to cook/stills/rNN/_sN.png
node cook/tools/shot.mjs cook/stills/$1 1 2>&1 | tail -3
for n in $(echo $2 | tr ',' ' '); do python3 -c "
from PIL import Image
a=Image.open('cook/stills/$1/S$n-light.png');b=Image.open('cook/stills/$1/S$n-dark.png')
bg=Image.new('RGB',(800,a.height),(70,70,70));bg.paste(a,(0,0));bg.paste(b,(410,0));bg.save('cook/stills/$1/_s$n.png')"; done
