#!/usr/bin/env python3
"""For each mockup, generate Tailwind utilities with the site's config and inline only the rules
whose classes are missing from website/assets/site.css (plus responsive variants, to keep cascade order)."""
import os, re, subprocess, sys, tempfile, glob
SITE_CSS = "/home/user/DAYXERO/website/assets/site.css"
CONFIG = "/home/user/DAYXERO/website/tailwind.config.js"
OUT = "/home/user/DAYXERO/research_notes/DayXero prelaunch waitlist marketing/mockups"
here = os.path.dirname(os.path.abspath(__file__))

def classes_in_css(css):
    names = set()
    for m in re.finditer(r'\.((?:\\.|[A-Za-z0-9_-])+)', css):
        names.add(re.sub(r'\\(.)', r'\1', m.group(1)))
    return names

site = classes_in_css(open(SITE_CSS).read())

def split_rules(css):
    """Top-level blocks: returns list of (prelude, body) where body may contain nested rules."""
    out, i, n = [], 0, len(css)
    while i < n:
        j = css.find('{', i)
        if j < 0: break
        prelude = css[i:j].strip()
        depth, k = 1, j + 1
        while depth and k < n:
            if css[k] == '{': depth += 1
            elif css[k] == '}': depth -= 1
            k += 1
        out.append((prelude, css[j+1:k-1]))
        i = k
    return out

def keep(prelude):
    sel_classes = [re.sub(r'\\(.)', r'\1', c) for c in re.findall(r'\.((?:\\.|[A-Za-z0-9_-])+)', prelude)]
    if not sel_classes: return False
    for c in sel_classes:
        if c not in site: return True
        if re.match(r'^(sm|md|lg|xl|2xl):', c): return True
    return False

def build(html_path):
    with tempfile.TemporaryDirectory() as td:
        cfg = os.path.join(td, 'tw.config.js')
        open(cfg, 'w').write(f"const base = require({CONFIG!r});\nmodule.exports = {{...base, content: [{html_path!r}]}};\n")
        inp = os.path.join(td, 'in.css'); open(inp, 'w').write('@tailwind utilities;\n')
        outp = os.path.join(td, 'out.css')
        subprocess.run(['npx', '-y', 'tailwindcss@3.4.17', '-c', cfg, '-i', inp, '-o', outp], check=True, capture_output=True, cwd=here)
        css = open(outp).read()
    kept = []
    for prelude, body in split_rules(css):
        if prelude.startswith('@media'):
            inner = [(p, b) for p, b in split_rules(body) if keep(p)]
            if inner:
                kept.append(prelude + ' {\n' + '\n'.join(f'  {p} {{{b}}}' for p, b in inner) + '\n}')
        elif keep(prelude):
            kept.append(f'{prelude} {{{body}}}')
    return '\n'.join(kept)

for f in sorted(glob.glob(os.path.join(OUT, '*.html'))):
    html = open(f).read()
    if '/*MOCKUP-UTILITIES*/' not in html and 'id="mockup-utilities"' not in html: continue
    css = build(f)
    html = re.sub(r'(<style id="mockup-utilities">)(.*?)(</style>)', lambda m: m.group(1) + '\n/*MOCKUP-UTILITIES*/\n' + css + '\n  ' + m.group(3), html, flags=re.S)
    open(f, 'w').write(html)
    print(os.path.basename(f), css.count('{'), 'rules')
