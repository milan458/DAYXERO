# Audio scripts page

Builds the one-page reader of every program audio script (https://claude.ai/artifact/VGZgv3fQMr31DzAU3HxhWu).

    python3 -I tools/program-scripts/extract.py docs/program /tmp/tracks.json
    python3 -I -c "d=open('/tmp/tracks.json').read().replace('</','<\\/'); t=open('tools/program-scripts/template.html').read().replace('__DATA__',d); open('/tmp/dayxero-audio-scripts.html','w').write(t)"

`extract.py` pulls every Listen step's script out of `docs/program/*.md` and checks the `{s: … | v: … | p: …}` markup resolves for all three products.
