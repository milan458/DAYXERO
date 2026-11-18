import os
OUT = '/home/user/DAYXERO/cook/site/screens'

HEAD = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=390">
<title>%TITLE%</title>
<meta name="motion" content="%MOTION%">
<link rel="stylesheet" href="../kit/kit.css">
<script src="../kit/chars.js"></script><script src="../kit/kit.js"></script>
<style>
%CSS%
</style>
</head><body>
'''

# shared screen-local helpers (kept per file so every screen stands alone)
COMMON_CSS = '''/* screen-local helpers: icon fill, section labels, small icon tiles, bottom toast */
.hd { display: grid; gap: 6px; padding-top: 58px; }
.sec { padding: 22px 4px 8px; color: var(--muted); }
.rt { font-weight: 600; }
.ico-tile.s { width: 34px; height: 34px; border-radius: 11px; }
.ico-tile.s svg { width: 19px; height: 19px; }
.val { color: var(--muted); font: 500 15px/1.2 var(--body); white-space: nowrap; }
.list > .row.tap { min-height: 56px; }
.toast.b { top: auto; opacity: 0; transform: translateY(18px); transition: opacity .4s var(--ease), transform .55s var(--settle); }
.toast.b.in { opacity: 1; transform: none; }
.toast.b .ck { flex: none; }
.opt.on { box-shadow: inset 0 0 0 2px var(--sel); }
html:not([data-theme="dark"]) .opt.on { box-shadow: inset 0 0 0 2px color-mix(in srgb, var(--sel) 72%, transparent); }
.pill { height: 34px; padding: 0 12px; border-radius: 11px; background: var(--card-2); display: inline-flex; align-items: center; font: 600 15px/1 var(--body); color: var(--fg); white-space: nowrap; font-variant-numeric: tabular-nums; }
'''

ICON_JS = '''document.querySelectorAll('[data-ic]').forEach(e => { e.innerHTML = DX.icon(e.dataset.ic, { size: +(e.dataset.s || 24), w: +(e.dataset.w || 2.2) }); });'''

TOAST_JS = '''const toast = document.querySelector('.toast.b');
DX.after(%T%, () => toast.classList.add('in'));
DX.onStill(() => toast.classList.add('in'));'''

def page(name, title, motion, ground, body, css='', js='', common=True):
    h = HEAD.replace('%TITLE%', title).replace('%MOTION%', motion).replace('%CSS%', (COMMON_CSS if common else '') + css)
    h += '<div class="screen" data-ground="%s">\n%s\n</div>\n<script>\n%s\n%s\n</script>\n</body></html>\n' % (ground, body, ICON_JS, js)
    with open(os.path.join(OUT, name + '.html'), 'w') as f:
        f.write(h)

def nav(kind='back'):
    return '<div class="nav"><button class="icon-btn" aria-label="%s" data-ic="%s"></button></div>' % ('Back' if kind == 'back' else 'Close', kind)

def header(title, sub, i0=0):
    return '<div class="hd"><h1 class="t-large" data-a style="--i:%d">%s</h1><p class="t-foot muted" data-a style="--i:%d">%s</p></div>' % (i0, title, i0 + 1, sub)

def row(ic, t, sub=None, trail='', extra='', cls=''):
    s = '<div class="t-foot muted">%s</div>' % sub if sub else ''
    tile = '<span class="ico-tile s" data-ic="%s"></span>' % ic if ic else ''
    return '<div class="row %s" %s>%s<div class="grow"><div class="t-body rt">%s</div>%s</div>%s</div>' % (cls, extra, tile, t, s, trail)

CHEV = '<span class="chev" data-ic="chev" data-s="18"></span>'
def toast(msg, d):
    return '<div class="toast b" role="status"><span class="ck">' + '%CHECK' + str(d) + '%</span>' + msg + '</div>'

def check_js(d):
    return "document.querySelectorAll('.ck').forEach(e => e.innerHTML = DX.check({ size: 26, d: %d }));" % d

# ======================================================================== 056 calm tools
css056 = """
.tool { display: flex; align-items: center; gap: 16px; padding: 12px 16px 12px 12px; }
.tool .grow { flex: 1; min-width: 0; display: grid; gap: 3px; }
.art { width: 92px; height: 92px; border-radius: 22px; flex: none; position: relative; overflow: hidden; background: var(--card-2); }
.art .scene { position: absolute; inset: 0; }
.art .who { position: absolute; left: 50%; bottom: -6px; transform: translateX(-50%); }
.dur { display: inline-flex; align-items: center; gap: 5px; color: var(--muted); margin-top: 2px; }
.dur svg { width: 14px; height: 14px; }
.sos { display: flex; align-items: center; gap: 12px; padding: 14px 16px; }
"""
TOOLS = [('box', 'Box breathing', 'In, hold, out, hold. Four counts each.', '2 min'),
         ('ground', '5-4-3-2-1 grounding', 'Come back to the room with your five senses.', '3 min'),
         ('urge', 'Notice the urge', 'Watch it rise and fall without acting.', '1 min'),
         ('wind', 'Wind down', 'A slow evening reset with Glim.', '5 min')]
body056 = nav('close') + """
<div class="scroll"><div class="pad">
  """ + header('Calm tools', 'A few minutes instead of reaching for nicotine. Pick the one that fits right now.') + """
  <div class="stack" style="margin-top:22px">""" + ''.join("""
    <div class="card tool" data-a style="--i:%d">
      <div class="art"><span class="scene" id="sc-%s"></span><span class="who" id="ch-%s"></span></div>
      <div class="grow"><div class="t-head">%s</div><div class="t-foot muted">%s</div><span class="t-cap dur"><span data-ic="clock" data-s="14"></span>%s</span></div>
      <span class="chev" data-ic="chev" data-s="18"></span>
    </div>""" % (i + 2, k, k, t, d, m) for i, (k, t, d, m) in enumerate(TOOLS)) + """
    <div class="card flat sos" data-a style="--i:6">
      <span class="ico-tile s" data-ic="wave" style="background:var(--card)"></span>
      <div class="grow" style="flex:1"><div class="t-body rt">Craving right now?</div><div class="t-foot muted">Craving SOS walks you through it.</div></div>
      <span class="chev" data-ic="chev" data-s="18"></span>
    </div>
  </div>
</div></div>"""
js056 = """
const S = { box: ['sea', 'jelli', 'breathe'], ground: ['path', 'xero', 'hello'], urge: ['dawn', 'jelli', 'calm'] };
Object.entries(S).forEach(([k, [sc, who, mood]]) => {
  document.getElementById('sc-' + k).innerHTML = DX.char('horizon', { scene: sc, w: 92, h: 92, clarity: 100 });
  document.getElementById('ch-' + k).innerHTML = DX.char(who, { mood, size: 66 });
});
document.getElementById('sc-wind').innerHTML = DX.nightSky({ w: 92, h: 92, moonX: 70, moonY: 22 });
document.getElementById('ch-wind').innerHTML = DX.char('glim', { mood: 'calm', size: 66 });
"""
page('056-calm', '056 Calm tools', 'Cards arrive top to bottom on the 90ms stagger; each tool is a paper-cut scene with its guide: Jelli breathes slowly on the sea, Xero waves on the path, Jelli floats at dawn, Glim flutters under the moon (all ambient loops). No haptic on load, light tap haptic on card press.', 'reading', body056, css056, js056)

# ======================================================================== 057 box breathing
css057 = """
.nav .title { flex: 1; text-align: center; margin-right: 56px; }
.wrap { position: absolute; left: 0; right: 0; top: 118px; display: grid; justify-items: center; gap: 0; }
.rnd { display: flex; gap: 8px; align-items: center; }
.rnd i { width: 8px; height: 8px; border-radius: 99px; background: var(--track); }
.rnd i.on { background: var(--fg); }
.box { position: relative; width: 320px; height: 320px; margin-top: 22px; transform: scale(1.08); transform-origin: top center; margin-bottom: 26px; }
.box svg { position: absolute; inset: 0; }
.fillsq { position: absolute; left: 60px; top: 60px; width: 200px; height: 200px; border-radius: 18px; overflow: hidden; transform: scale(.7); }
.fillsq .sea { position: absolute; inset: 0; }
.jel { position: absolute; left: 60px; top: 60px; width: 200px; height: 200px; display: grid; place-items: center; transform: scale(.82); }
.play .fillsq { animation: sq 16s cubic-bezier(.45,0,.55,1) infinite; }
.play .jel { animation: jl 16s cubic-bezier(.45,0,.55,1) infinite; }
@keyframes sq { 0% { transform: scale(.7); } 25%, 50% { transform: scale(1); } 75%, 100% { transform: scale(.7); } }
@keyframes jl { 0% { transform: scale(.82); } 25%, 50% { transform: scale(1.04); } 75%, 100% { transform: scale(.82); } }
.still .fillsq { animation: none !important; transform: scale(1); }
.still .jel { animation: none !important; transform: scale(1.04); }
.dot { position: absolute; left: 0; top: 0; width: 22px; height: 22px; border-radius: 99px; background: var(--fg); box-shadow: 0 0 0 6px color-mix(in srgb, var(--fg) 14%, transparent);
  offset-path: path("M50 270 V50 H270 V270 Z"); offset-rotate: 0deg; offset-distance: 0%; }
.play .dot { animation: go 16s linear infinite; }
@keyframes go { to { offset-distance: 100%; } }
.still .dot { animation: none !important; offset-distance: 37.5%; }
.side { position: absolute; color: var(--muted); font: 600 13px/1 var(--body); transition: color .5s var(--ease); white-space: nowrap; }
.side.on { color: var(--fg); font-weight: 700; }
.s0 { left: 22px; top: 160px; transform: translate(-50%, -50%) rotate(-90deg); }
.s1 { left: 160px; top: 22px; transform: translate(-50%, -50%); }
.s2 { left: 298px; top: 160px; transform: translate(-50%, -50%) rotate(90deg); }
.s3 { left: 160px; top: 298px; transform: translate(-50%, -50%); }
.say { margin-top: 44px; display: flex; align-items: baseline; gap: 14px; }
.say .num { font-size: 60px; line-height: 1; min-width: 34px; }
.lab { transition: opacity .35s var(--ease); }
.cue { margin-top: 14px; text-align: center; max-width: 300px; transition: opacity .4s var(--ease); }
"""
body057 = """<div class="nav"><button class="icon-btn" aria-label="Close" data-ic="close"></button><div class="title t-head" data-a style="--i:0">Box breathing</div></div>
<div class="wrap">
  <div class="rnd" data-a style="--i:1" aria-label="Round 2 of 4"><i class="on"></i><i class="on"></i><i></i><i></i></div>
  <p class="t-foot muted" data-a style="--i:1;margin-top:8px" id="round">Round 2 of 4</p>
  <div class="box" data-fade style="--d:200ms">
    <div class="fillsq"><span class="sea" id="sea"></span></div>
    <div class="jel" id="jel"></div>
    <svg width="320" height="320" viewBox="0 0 320 320"><rect x="50" y="50" width="220" height="220" rx="8" fill="none" stroke="var(--track)" stroke-width="5"/>
      <path id="act" d="M50 270 V50" fill="none" stroke="var(--fg)" stroke-width="5" stroke-linecap="round"/></svg>
    <span class="side s0 on">Breathe in</span><span class="side s1">Hold</span><span class="side s2">Breathe out</span><span class="side s3">Hold</span>
    <span class="dot"></span>
  </div>
  <div class="say" data-a style="--i:2"><span class="t-title lab" id="phase">Breathe in</span><span class="num" id="count">4</span></div>
  <p class="t-body muted cue" id="cue" data-a style="--i:3">In through your nose. Let your belly fill.</p>
</div>
<div class="dock"><button class="btn ghost" data-a style="--i:4">End session</button></div>"""
js057 = """
document.getElementById('sea').innerHTML = DX.char('horizon', { scene: 'sea', w: 200, h: 200, clarity: 100 });
document.getElementById('jel').innerHTML = DX.char('jelli', { mood: 'breathe', size: 150 });
const P = [
  { w: 'Breathe in', c: 'In through your nose. Let your belly fill.', d: 'M50 270 V50' },
  { w: 'Hold', c: 'Hold it softly. Shoulders down.', d: 'M50 50 H270' },
  { w: 'Breathe out', c: 'Out slowly through your mouth.', d: 'M270 50 V270' },
  { w: 'Hold', c: 'Rest here. Nothing to do.', d: 'M270 270 H50' }];
const sides = document.querySelectorAll('.side'), phase = document.getElementById('phase'), count = document.getElementById('count'), cue = document.getElementById('cue'), act = document.getElementById('act'), round = document.getElementById('round'), pips = document.querySelectorAll('.rnd i');
function set(k, n) {
  const p = P[k];
  if (n === 4) { phase.style.opacity = 0; cue.style.opacity = 0; setTimeout(() => { phase.textContent = p.w; cue.textContent = p.c; phase.style.opacity = 1; cue.style.opacity = 1; }, 220);
    sides.forEach((s, i) => s.classList.toggle('on', i === k)); act.setAttribute('d', p.d); }
  count.textContent = n;
}
for (let s = 0; s < 48; s++) { const k = Math.floor(s / 4) % 4, n = 4 - (s % 4); DX.after(s * 1000, () => set(k, n)); }
DX.after(16000, () => { round.textContent = 'Round 3 of 4'; pips[2].classList.add('on'); });
DX.after(32000, () => { round.textContent = 'Round 4 of 4'; pips[3].classList.add('on'); });
DX.onStill(() => { sides.forEach((s, i) => s.classList.toggle('on', i === 1)); act.setAttribute('d', P[1].d); phase.textContent = P[1].w; cue.textContent = P[1].c; count.textContent = 2; });
"""
page('057-calm-box', '057 Box breathing', 'The dot travels the square at an even pace, 4s per side (16s a round) while the sea window and Jelli inside it swell over the in side, hold, shrink over the out side and hold (Jelli breathes with it); on each corner the phase word, the lit side label and the cue cross-fade (220ms) and the count ticks 4 to 1 each second. A soft haptic tick at every corner, nothing else.', 'reading', body057, css057, js057)

# ======================================================================== 058 grounding
css058 = '''
.nav .steps { flex: 1; margin-right: 56px; }
.done-step { display: flex; align-items: center; gap: 12px; padding: 12px 16px; }
.done-step .tk { width: 26px; height: 26px; border-radius: 99px; background: var(--tick); color: #fff; display: grid; place-items: center; flex: none; }
[data-theme="dark"] .done-step .tk { color: #0B2A1C; }
.cur { padding: 22px 20px 20px; display: grid; gap: 10px; position: relative; }
.cur .xr { position: absolute; right: 10px; top: 8px; }
.cur .big { font: 800 88px/0.9 var(--display); letter-spacing: -3px; }
.pips { display: flex; gap: 10px; margin-top: 8px; }
.pips i { width: 44px; height: 44px; border-radius: 99px; box-shadow: inset 0 0 0 2px var(--line); display: grid; place-items: center; transition: background .3s var(--ease); }
.pips i.on { background: var(--sel); box-shadow: none; }
.pips i.on::after { content: ""; width: 18px; height: 18px; background: var(--sel-fg); -webkit-mask: var(--tick-svg) center/contain no-repeat; mask: var(--tick-svg) center/contain no-repeat; }
.ex { display: flex; flex-wrap: wrap; gap: 6px; }
.ex span { padding: 6px 10px; border-radius: 10px; background: var(--card-2); }
.later { display: flex; align-items: center; gap: 14px; padding: 6px 6px; color: var(--muted); min-height: 44px; }
.later b { font: 800 19px/1 var(--display); width: 36px; height: 36px; border-radius: 99px; display: grid; place-items: center; box-shadow: inset 0 0 0 2px var(--line); color: var(--fg); }
'''
body058 = '''<div class="nav"><button class="icon-btn" aria-label="Close" data-ic="close"></button><div class="steps" aria-label="Step 2 of 5"><i class="on"></i><i class="now"></i><i></i><i></i><i></i></div></div>
<div class="scroll"><div class="pad" style="padding-top:58px">
  <p class="t-foot muted" data-a style="--i:0">5-4-3-2-1 grounding</p>
  <div class="card flat done-step" data-a style="--i:1;margin-top:12px"><span class="tk" data-ic="check" data-s="16" data-w="3"></span><span class="t-body rt" style="flex:1">5 things you can see</span><span class="t-cap muted">Done</span></div>
  <div class="card cur" data-a style="--i:2;margin-top:10px">
    <div class="xr" id="xr058" data-settle style="--d:500ms"></div>
    <div style="display:flex;align-items:flex-end;gap:12px"><span class="big">4</span><span class="t-title" style="padding-bottom:6px">things you<br>can feel</span></div>
    <p class="t-body muted">Touch them, or just notice them.</p>
    <div class="ex"><span class="t-foot">Your feet on the floor</span><span class="t-foot">The chair</span><span class="t-foot">Your clothes</span><span class="t-foot">The air</span></div>
    <div class="pips" id="pips"><i></i><i></i><i></i><i></i></div>
    <p class="t-cap muted">Tap one for each thing you notice</p>
  </div>
  <div style="margin-top:14px;display:grid;gap:2px">
    <p class="t-foot muted" data-a style="--i:4;padding:4px 6px 2px">Still to come</p>
    <div class="later" data-a style="--i:4"><b>3</b><span class="t-body">things you can hear</span></div>
    <div class="later" data-a style="--i:5"><b>2</b><span class="t-body">things you can smell</span></div>
    <div class="later" data-a style="--i:6"><b>1</b><span class="t-body">thing you can taste</span></div>
  </div>
</div></div>
<div class="dock"><button class="btn" data-a style="--i:7">Next: 3 things you can hear</button></div>'''
js058 = '''
document.getElementById('xr058').innerHTML = DX.char('xero', { mood: 'hello', size: 96 });
const pips = document.querySelectorAll('#pips i'), seg = document.querySelector('.steps .now');
[900, 1700, 2500].forEach((t, i) => DX.after(t, () => { pips[i].classList.add('on'); pips[i].classList.add('bump'); }));
DX.onStill(() => { [0, 1, 2].forEach(i => pips[i].classList.add('on')); });
'''
page('058-calm-grounding', '058 Grounding', 'The done step slides in compact, then the current step card arrives large and Xero settles into its corner (500ms); the pips fill one by one at 0.9s, 1.7s and 2.5s with a small bump and a light haptic each, as if tapped; the last pip waits for the user. Tapping Next collapses this card into a done row and lifts the next step up (500ms settle).', 'reading', body058, css058, js058)

# ======================================================================== 059 notice the urge
css059 = """
.nav .title { flex: 1; text-align: center; margin-right: 56px; }
.prompt { position: absolute; left: 28px; right: 28px; top: 128px; text-align: center; display: grid; gap: 12px; justify-items: center; }
.prompt .say { font: 800 28px/1.18 var(--display); letter-spacing: -.6px; min-height: 100px; text-wrap: balance; transition: opacity .6s var(--ease), transform .6s var(--ease); }
.prompt .say.out { opacity: 0; transform: translateY(-8px); }
.sea { position: absolute; left: 0; right: 0; top: 296px; height: 548px; }
.sea svg { position: absolute; left: 0; top: 0; }
.rider { position: absolute; left: -44px; top: -44px; width: 88px; height: 88px;
  offset-path: path("M-10 220 C 70 220 110 56 195 56 S 320 220 400 220"); offset-rotate: 0deg; offset-distance: 8%; offset-anchor: 50% 78%; }
.play .rider { animation: ride 12s cubic-bezier(.4,0,.6,1) forwards; }
@keyframes ride { from { offset-distance: 8%; } to { offset-distance: 86%; } }
.still .rider { animation: none !important; offset-distance: 86%; }
.marks { position: absolute; left: 0; right: 0; top: 534px; display: flex; justify-content: space-between; padding: 0 30px; }
.marks span { font: 700 14px/1 var(--body); color: var(--fg); background: var(--card); padding: 8px 12px; border-radius: 99px; box-shadow: 0 2px 8px rgba(0,0,0,.08); }
.time { color: var(--muted); }
"""
body059 = """<div class="nav"><button class="icon-btn" aria-label="Close" data-ic="close"></button><div class="title t-head" data-a style="--i:0">Notice the urge</div></div>
<div class="prompt">
  <p class="t-foot time" data-a style="--i:1">About a minute. Just watch.</p>
  <p class="say" id="say" data-a style="--i:2">Notice where you feel it.</p>
</div>
<div class="sea">
  <svg width="390" height="548" viewBox="0 0 390 548" preserveAspectRatio="none">
    <path d="M-10 220 C 70 220 110 56 195 56 S 320 220 400 220 V548 H-10Z" fill="#5A9DFF" fill-opacity=".16" data-fade style="--d:900ms"/>
    <path d="M-10 220 H400" stroke="var(--line)" stroke-width="2" stroke-dasharray="2 8" stroke-linecap="round"/>
    <path d="M-10 220 C 70 220 110 56 195 56 S 320 220 400 220" fill="none" stroke="var(--fg)" stroke-width="3" stroke-linecap="round" class="draw" style="--len:520;--dur:2400ms;--d:300ms"/>
    <g data-fade style="--d:600ms">
      <path d="M-10 290 C 50 272 110 278 170 290 C 240 304 310 280 400 276 V548 H-10Z" fill="#9CCBFF"/>
      <path d="M-10 330 C 60 314 120 318 190 332 C 260 346 320 324 400 318 V548 H-10Z" fill="#5A9DFF"/>
      <path d="M-10 372 C 70 356 140 362 210 374 C 280 386 340 366 400 362 V548 H-10Z" fill="#2F72F2"/>
      <path d="M-10 414 C 80 400 160 404 240 416 C 300 424 350 412 400 408 V548 H-10Z" fill="#1C4FCC"/>
      <path d="M96 326 C 108 312 128 310 138 322 C 126 320 116 324 110 332 Z" fill="#FFF8EE"/>
    </g>
  </svg>
  <div data-fade style="--d:1200ms;position:absolute;inset:0"><span class="rider" id="rider"></span></div>
</div>
<div class="marks" data-a style="--i:3"><span>It rises</span><span>It peaks</span><span>It passes</span></div>
<div class="dock"><button class="btn" data-a style="--i:4">It's passing</button><button class="link" data-a style="--i:5">I need more help</button></div>"""
js059 = """
document.getElementById('rider').innerHTML = DX.char('jelli', { mood: 'calm', size: 88 });
const say = document.getElementById('say');
const lines = [[3000, 'It rises. You do not have to act.'], [6000, 'This is the peak. Breathe out slowly.'], [9000, 'Watch it fall away.']];
lines.forEach(([t, s]) => DX.after(t, () => { say.classList.add('out'); setTimeout(() => { say.textContent = s; say.classList.remove('out'); }, 600); }));
DX.onStill(() => { say.textContent = 'Watch it fall away.'; });
"""
page('059-calm-notice', '059 Notice the urge', 'The wave line draws left to right over 2.4s, the soft tint and the paper sea layers fade in under it; Jelli then rides the wave for 12s (slow ease), rising to the crest and gliding down, while the single 28px prompt cross-fades every 3s (600ms): notice, it rises, the peak, watch it fall. No springs, no haptic until It is passing is tapped (soft success haptic, goes to 060).', 'reading', body059, css059, js059)

# ======================================================================== 060 calm done
css060 = """
.top { padding-top: 70px; display: grid; justify-items: center; text-align: center; gap: 10px; }
.hero { position: relative; width: 240px; height: 210px; margin-bottom: 6px; }
.hero .halo { position: absolute; left: 20px; top: 10px; width: 200px; height: 200px; border-radius: 99px; overflow: hidden; }
.hero .jel { position: absolute; left: 30px; top: 6px; }
.hero .ck { position: absolute; right: 6px; top: 6px; }
.calm { display: flex; align-items: center; gap: 14px; padding: 14px 18px 14px 14px; margin-top: 22px; position: relative; }
.calm .ico-tile { width: 48px; height: 48px; border-radius: 15px; }
.calm .num { font-size: 40px; line-height: 1; }
.plus { position: absolute; left: 150px; top: 8px; color: var(--tick); font: 800 18px/1 var(--display); }
.feel { margin-top: 22px; display: grid; gap: 10px; }
"""
body060 = """<div class="nav"><button class="icon-btn" aria-label="Close" data-ic="close"></button></div>
<div class="scroll"><div class="pad">
  <div class="top">
    <div class="hero">
      <div class="halo" id="halo" data-fade style="--d:0ms"></div>
      <div class="jel" data-settle style="--d:250ms"><div id="jelli"></div></div>
      <div class="ck" id="ck"></div>
    </div>
    <h1 class="t-large" data-a style="--i:2">Nicely <span class="mark">done</span></h1>
    <p class="t-body muted" data-a style="--i:3">Two minutes, and the urge got smaller.<br>That is a skill you just practised.</p>
  </div>
  <div class="card calm" data-a style="--i:4">
    <span class="ico-tile" data-ic="leaf" data-s="26"></span>
    <div><div><span class="num" data-count="8" data-from="6" data-delay="1200">8</span> <span class="t-head">min</span></div><div class="t-foot muted">of calm today</div></div>
    <span class="plus float-up" style="--d:1300ms">+2</span>
  </div>
  <div class="feel">
    <p class="t-foot muted" data-a style="--i:5">A bit calmer? Optional</p>
    <div class="chips" data-a style="--i:6"><button class="chip">Much calmer</button><button class="chip on" id="pick">A bit</button><button class="chip">Not really</button></div>
  </div>
</div></div>
<div class="dock"><button class="btn" data-a style="--i:7">Back to my day</button><button class="link" data-a style="--i:8" data-go="019-sos">Still craving? Open Craving SOS</button></div>"""
js060 = """
document.getElementById('halo').innerHTML = DX.char('horizon', { scene: 'sea', w: 200, h: 200, clarity: 100 });
document.getElementById('jelli').innerHTML = DX.char('jelli', { mood: 'cheer', size: 180 });
document.getElementById('ck').innerHTML = DX.check({ size: 56, d: 900 });
"""
page('060-calm-done', '060 Calm done', 'The paper sea disc fades in, Jelli settles into it cheering (hop loop, 250ms), then the small check pops beside Jelli and its tick draws (900ms, success haptic); the headline with its drawn underline and the line arrive, minutes of calm counts 6 to 8 at 1.2s with a +2 floating up; chips arrive last. No other springs.', 'reading', body060, css060, js060)

# ======================================================================== 061 settings
css061 = '''
.prof { padding: 0; overflow: hidden; margin-top: 16px; }
.prof .top { display: flex; align-items: center; gap: 14px; padding: 14px 16px; }
.prof .av { width: 60px; height: 60px; border-radius: 99px; background: var(--card-2); display: grid; place-items: center; overflow: hidden; flex: none; }
.prof .grow { flex: 1; min-width: 0; }
.prof .subs { display: flex; align-items: center; gap: 12px; padding: 0 16px; min-height: 50px; border-top: 1px solid var(--line); }
.sec { padding: 14px 4px 7px; }
.list > .row { min-height: 48px; padding-top: 6px; padding-bottom: 6px; }
.ico-tile.s { width: 32px; height: 32px; }
.foot { display: flex; justify-content: center; gap: 6px; padding-top: 14px; color: var(--muted); }
'''
body061 = nav('close') + '''
<div class="scroll"><div class="pad">
  <div class="hd"><h1 class="t-large" data-a style="--i:0">Settings</h1></div>
  <div class="card prof" data-a style="--i:1">
    <div class="top">
      <div class="av" id="av"></div>
      <div class="grow"><div class="t-title">Sam</div><div class="t-foot muted">Day 7 &middot; 7 days free</div></div>
      <div id="bdg" data-stamp style="--d:500ms"></div>
    </div>
    <div class="subs"><span class="ico-tile s" data-ic="star"></span><span class="t-body rt" style="flex:1">DayXero Yearly</span><span class="val">Renews Nov 5</span>''' + CHEV + '''</div>
  </div>
  <p class="t-foot sec" data-a style="--i:2">Your plan</p>
  <div class="list" data-a style="--i:3">
    ''' + row('calendar', 'Quit Day', None, '<span class="val">Fri, Nov 6</span>' + CHEV) + '''
    ''' + row('cig', 'What you use', None, '<span class="val">Cigarettes, vape</span>' + CHEV) + '''
    ''' + row('globe', 'Currency', None, '<span class="val">USD</span>' + CHEV) + '''
  </div>
  <p class="t-foot sec" data-a style="--i:4">Reminders</p>
  <div class="list" data-a style="--i:5">
    ''' + row('bell', 'Reminders', None, '<span class="val">3 on</span>' + CHEV) + '''
    ''' + row('moon', 'Quiet hours', None, '<span class="val">10 PM to 7 AM</span>' + CHEV) + '''
    ''' + row('clock', 'Day ends at', None, '<span class="val">4 AM</span>' + CHEV) + '''
  </div>
  <p class="t-foot sec" data-a style="--i:6">Data</p>
  <div class="list" data-a style="--i:7">
    ''' + row('heart', 'Apple Health', None, '<span class="val">On</span>' + CHEV) + '''
    ''' + row('shield', 'Privacy and your data', None, CHEV) + '''
  </div>
  <div class="foot t-cap" data-a style="--i:8"><span>About DayXero</span><span>&middot;</span><span>Version 1.4</span><span>&middot;</span><span>Terms</span></div>
</div></div>'''
js061 = '''
document.getElementById('av').innerHTML = DX.char('xero', { mood: 'hello', size: 60 });
document.getElementById('bdg').innerHTML = DX.badge({ kind: 'day', n: 7, state: 'earned', size: 46 });
'''
page('061-settings-settings', '061 Settings', 'The large title, then the profile card (with the plan) and each group arrive top to bottom on the 90ms stagger; the 7-day badge on the profile card stamps in at 500ms. Rows highlight on press with a light tap haptic and push their page from the right.', 'reading', body061, css061, js061)

# ======================================================================== 062 reminders
css062 = '''
.list > .row.sub { min-height: 52px; padding-left: 64px; }
.sub .t-body { flex: 1; color: var(--muted); }
.fc { transition: background .4s var(--ease); }
'''
body062 = nav() + '''
<div class="scroll"><div class="pad">
  ''' + header('Reminders', 'A few gentle nudges. Never more than three a day.') + '''
  <p class="t-foot sec" data-a style="--i:2">Your day</p>
  <div class="list" data-a style="--i:3">
    ''' + row('sun', 'Morning pledge', 'Skipped once you pledge', '<span class="toggle on"></span>') + '''
    <div class="row sub"><span class="t-body">Pledge at</span><span class="pill">8:00 AM</span></div>
    ''' + row('moon', 'Evening check-in', 'Skipped once you check in', '<span class="toggle on"></span>') + '''
    <div class="row sub"><span class="t-body">Check in at</span><span class="pill">9:00 PM</span></div>
    ''' + row('note', 'Daily lesson', 'When a new day opens', '<span class="toggle on"></span>') + '''
    ''' + row('wave', 'Craving forecast', 'Before coffee and stress', '<span class="toggle" id="fc"></span>', cls='fc') + '''
  </div>
  <div class="list" data-a style="--i:4;margin-top:12px">
    ''' + row('moon', 'Quiet hours', '10:00 PM to 7:00 AM', CHEV) + '''
  </div>
</div></div>
''' + toast('Saved. Craving forecast is on.', 1400)
js062 = '''
const fc = document.getElementById('fc');
DX.after(1000, () => fc.classList.add('on'));
DX.onStill(() => fc.classList.add('on'));
''' + TOAST_JS.replace('%T%', '1300') + '\n' + check_js(1350)
page('062-settings-reminders', '062 Reminders', 'Groups arrive on the stagger; at 1.0s the Craving forecast toggle slides on (300ms settle, light haptic), then at 1.3s a Saved toast rises from the bottom with a check that pops and draws, and fades out after 2.5s in the app. Times open a wheel picker sheet.', 'reading', body062.replace('%CHECK1400%', ''), css062, js062)

# ======================================================================== 063 day end
css063 = '''
.opts { display: grid; gap: 8px; margin-top: 18px; }
.opts .opt { min-height: 58px; padding-top: 9px; padding-bottom: 9px; }
.tl { margin-top: 14px; padding: 12px 16px 12px; }
.tl .head { display: flex; align-items: center; gap: 12px; }
.bar { position: relative; height: 34px; margin-top: 12px; }
.bar .ln { position: absolute; left: 0; right: 0; top: 16px; height: 2px; background: var(--line); }
.bar .seg { position: absolute; left: 0; top: 14px; height: 6px; border-radius: 99px; background: var(--fg); width: 70%; }
.bar .tick { position: absolute; top: 8px; width: 2px; height: 18px; background: var(--fg); }
.bar .ci { position: absolute; top: 8px; width: 18px; height: 18px; border-radius: 99px; background: var(--card); box-shadow: inset 0 0 0 3px var(--mark); margin-left: -9px; }
.tlab { display: flex; justify-content: space-between; color: var(--muted); }
'''
def opt(t, sub='', on=False, idd=''):
    s = '<div class="t-foot">%s</div>' % sub if sub else ''
    return '<button class="opt%s" %s><div class="grow"><div class="t-head">%s</div>%s</div><span class="radio"></span></button>' % (' on' if on else '', ('id="%s"' % idd) if idd else '', t, s)
body063 = nav() + '''
<div class="scroll"><div class="pad">
  ''' + header('When your day ends', 'Up late? A check-in before this time still counts for the day you just had.') + '''
  <div class="opts">
    <div data-a style="--i:2">''' + opt('Midnight', '', True, 'o0') + '''</div>
    <div data-a style="--i:3">''' + opt('2 AM') + '''</div>
    <div data-a style="--i:4">''' + opt('4 AM', 'Default, fits most late nights', False, 'o4') + '''</div>
    <div data-a style="--i:5">''' + opt('6 AM', 'For night shifts and late finishes') + '''</div>
  </div>
  <div class="card flat tl" data-a style="--i:6">
    <div class="head"><span id="glim063"></span><p class="t-body" style="flex:1">A check-in at 1:30 AM still counts for Thursday.</p></div>
    <div class="bar"><div class="ln"></div><div class="seg"></div><div class="ci" style="left:41%"></div><div class="tick" style="left:70%"></div></div>
    <div class="tlab"><span class="t-foot">Thu 6 PM</span><span class="t-foot" style="margin-left:22%">Ends 4 AM</span><span class="t-foot">Fri</span></div>
  </div>
</div></div>
''' + toast('Saved. Your day now ends at 4 AM.', 1400)
js063 = '''
const o0 = document.getElementById('o0'), o4 = document.getElementById('o4');
document.getElementById('glim063').innerHTML = DX.char('glim', { mood: 'calm', size: 64 });
function pick() { o0.classList.remove('on'); o4.classList.add('on'); }
DX.after(1000, pick); DX.onStill(pick);
''' + TOAST_JS.replace('%T%', '1300') + '\n' + check_js(1350)
page('063-settings-dayEnd', '063 Day ends', 'Options arrive on the stagger with Midnight selected; at 1.0s the selection moves to 4 AM (ring and tick 250ms, selection haptic), the timeline below shows the 1:30 AM check-in landing on Thursday, and at 1.3s the Saved toast rises from the bottom with a drawn check.', 'reading', body063.replace('%CHECK1400%', ''), css063, js063)

# ======================================================================== 064 quiet hours
css064 = """
.dial { position: relative; width: 228px; height: 228px; margin: 34px auto 0; }
.dial .rot { position: absolute; inset: 0; transform: rotate(330deg); }
.dial .ctr { position: absolute; inset: 0; display: grid; place-content: center; text-align: center; gap: 2px; justify-items: center; }
.dial .ctr .num { font-size: 44px; line-height: 1; }
.hr { position: absolute; color: var(--muted); transform: translate(-50%, -50%); white-space: nowrap; font: 600 13px/1 var(--body); }
.times { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-top: 30px; }
.times .card { padding: 14px 16px; display: grid; gap: 4px; }
.times .num { font-size: 26px; line-height: 1.05; }
"""
body064 = nav() + """
<div class="scroll"><div class="pad">
  """ + header('Quiet hours', 'Nothing arrives between these times. Anything due waits until they end.') + """
  <div class="dial" data-a style="--i:2">
    <div class="rot" id="ring"></div>
    <div class="ctr"><span data-ic="moon" data-s="22"></span><span class="num" data-count="9">9</span><span class="t-foot muted">quiet hours</span></div>
    <span class="hr" style="left:114px;top:-14px">12 AM</span><span class="hr" style="left:258px;top:114px">6 AM</span><span class="hr" style="left:114px;top:242px">12 PM</span><span class="hr" style="left:-30px;top:114px">6 PM</span>
  </div>
  <div class="times" data-a style="--i:3">
    <div class="card"><span class="t-foot muted">From</span><span class="num">10:00 PM</span></div>
    <div class="card"><span class="t-foot muted">Until</span><span class="num">7:00 AM</span></div>
  </div>
  <p class="t-foot sec" data-a style="--i:4">While it is quiet</p>
  <div class="list" data-a style="--i:5">
    """ + row('bell', 'Pledge and check-in nudges', 'Wait until 7:00 AM', '') + """
    """ + row('wave', 'Craving forecast', 'Paused overnight', '') + """
    """ + row('patch', 'NRT reminders', 'Patch times still get through', '<span class="toggle on"></span>') + """
  </div>
</div></div>"""
js064 = """
document.getElementById('ring').innerHTML = DX.ring({ size: 228, stroke: 24, p: 9 / 24, color: 'var(--fg)', track: 'var(--track)', dot: true });
"""
page('064-settings-quietHours', '064 Quiet hours', 'The dial arc sweeps from 10 PM round to 7 AM (1.4s settle) as the 9 counts up in the centre; the From and Until tiles and the while-it-is-quiet list arrive below on the stagger. Changing a time drags the arc end with a selection haptic per 15 minutes.', 'reading', body064, css064, js064)

# ======================================================================== 065 products
css065 = '''
.opts { display: grid; gap: 10px; margin-top: 20px; }
.opt .ico-tile { width: 40px; height: 40px; }
.step { display: flex; align-items: center; gap: 10px; }
.step button { width: 34px; height: 34px; border-radius: 99px; background: var(--card-2); display: grid; place-items: center; color: var(--fg); }
.step button svg { width: 16px; height: 16px; }
.step .num { font-size: 19px; min-width: 40px; text-align: center; }
.sum { margin-top: 14px; display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
.sum .card { padding: 14px 16px; display: grid; gap: 2px; }
.sum .num { font-size: 30px; line-height: 1.05; }
.kept065 { margin-top: 10px; display: flex; align-items: center; gap: 12px; padding: 4px 16px 4px 8px; }
'''
def optic(ic, t, sub, on):
    return '<button class="opt%s"><span class="ico-tile" data-ic="%s"></span><div class="grow"><div class="t-head">%s</div><div class="t-foot">%s</div></div><span class="radio"></span></button>' % (' on' if on else '', ic, t, sub)
STEP = lambda v: '<div class="step"><button aria-label="Less" data-ic="minus" data-s="16" data-w="2.6"></button><span class="num">%s</span><button aria-label="More" data-ic="plus" data-s="16" data-w="2.6"></button></div>' % v
body065 = nav() + '''
<div class="scroll"><div class="pad">
  ''' + header('What you use', 'Pick everything you use. Your usual day sets money kept and your counters.') + '''
  <div class="opts">
    <div data-a style="--i:2">''' + optic('cig', 'Cigarettes', '12 a day', True) + '''</div>
    <div data-a style="--i:3">''' + optic('vape', 'Vape', '200 puffs a day', True) + '''</div>
    <div data-a style="--i:4">''' + optic('pouch', 'Nicotine pouches', 'Not used', False) + '''</div>
  </div>
  <p class="t-foot sec" data-a style="--i:5">Your usual day</p>
  <div class="list" data-a style="--i:6">
    ''' + row(None, 'Cigarettes a day', None, STEP('12')) + '''
    ''' + row(None, 'Pack of 20', None, STEP('$8.00')) + '''
    ''' + row(None, 'Vape spend a day', None, STEP('$2.20')) + '''
  </div>
  <div class="sum" data-a style="--i:7"><div class="card flat"><span class="num" data-count="7" data-prefix="$">$7</span><span class="t-foot muted">a day</span></div><div class="card flat"><span class="num" data-count="2555" data-prefix="$">$2,555</span><span class="t-foot muted">a year</span></div></div>
  <div class="card kept065" data-a style="--i:8"><span id="xr065"></span><p class="t-body" style="flex:1"><b>$49.00</b> kept since your Quit Day.</p></div>
</div></div>'''
page('065-settings-products', '065 What you use', 'Option rows and the usual-day list arrive on the stagger, then the daily and yearly totals count up ($7, $2,555). Each stepper tap nudges its number with a small bump, a selection haptic, and the totals recount live.', 'reading', body065, css065, "document.getElementById('xr065').innerHTML = DX.char('xero', { mood: 'cheer', size: 64 });")

# ======================================================================== 066 quit day
css066 = '''
.hero { display: flex; align-items: center; gap: 16px; padding: 18px; margin-top: 20px; }
.cal { width: 84px; border-radius: 18px; overflow: hidden; background: var(--card-2); text-align: center; flex: none; }
.cal .m { background: var(--fg); color: var(--g); padding: 6px 0; }
.cal .d { font: 800 40px/1 var(--display); padding: 8px 0 4px; letter-spacing: -1px; }
.cal .w { padding-bottom: 8px; color: var(--muted); }
.since .num { font-size: 40px; line-height: 1; }
.kept { margin-top: 12px; display: flex; align-items: center; gap: 14px; padding: 14px 16px; }
.btn.ghost.small { box-shadow: inset 0 0 0 2px var(--line); }
.wk { margin-top: 12px; padding: 14px 16px; }
.days { display: grid; grid-template-columns: repeat(8, 1fr); gap: 2px; margin-top: 12px; text-align: center; }
.days b { display: grid; place-items: center; width: 36px; height: 36px; margin: 0 auto; border-radius: 99px; background: var(--tick); color: #fff; }
[data-theme="dark"] .days b { color: #0B2A1C; }
.days b svg { width: 16px; height: 16px; }
.days .td b { background: transparent; box-shadow: inset 0 0 0 2.5px var(--fg); color: var(--fg); font: 800 13px/1 var(--display); }
.days .t-cap { color: var(--muted); display: block; margin-top: 5px; }
.warn { margin-top: 12px; padding: 18px; display: grid; gap: 10px; position: relative; }
.warn .xr { position: absolute; right: 8px; top: -10px; }
.keep { display: grid; gap: 8px; margin: 2px 0 4px; }
.keep div { display: flex; align-items: center; gap: 10px; }
.keep .ico-tile { width: 32px; height: 32px; border-radius: 10px; background: var(--card); }
.keep .ico-tile svg { width: 17px; height: 17px; }
'''
body066 = nav() + '''
<div class="scroll"><div class="pad">
  ''' + header('Your Quit Day', 'The day you stopped. Everything counts from here.') + '''
  <div class="card hero" data-a style="--i:2">
    <div class="cal"><div class="m t-cap">November</div><div class="d">6</div><div class="w t-cap">Friday</div></div>
    <div class="since" style="flex:1"><div><span class="num" data-count="7">7</span> <span class="t-head">days</span></div><div class="t-foot muted">free since Fri, Nov 6</div></div>
    <div id="xb" data-stamp style="--d:700ms"></div>
  </div>

  <div class="card wk" data-a style="--i:3"><div class="t-foot muted">Your first week</div><div class="days">''' + ''.join('<span data-pop style="--i:%d;--d:600ms"><b data-ic="check" data-s="14" data-w="3"></b><span class="t-cap">%s</span></span>' % (i, d) for i, d in enumerate(['Fri','Sat','Sun','Mon','Tue','Wed','Thu'])) + '''<span class="td" data-pop style="--i:7;--d:600ms"><b>13</b><span class="t-cap">Today</span></span></div></div>
  <div class="card flat warn" data-a style="--i:4">
    <div class="xr" id="xr066"></div>
    <div class="t-head" style="padding-right:90px">Need to change it?</div>
    <p class="t-foot muted" style="padding-right:84px">If you slipped, you do not start over. A new date only restarts the day count.</p>
    <div class="keep"><p class="t-foot muted">What stays with you</p>
      <div><span class="ico-tile" data-ic="medal"></span><span class="t-body">Your badges, Day Xero included</span></div>
      <div><span class="ico-tile" data-ic="note"></span><span class="t-body">Every lesson and card you finished</span></div>
      <div><span class="ico-tile" data-ic="chart"></span><span class="t-body">Your logs, waves and check-ins</span></div></div>
    <button class="btn ghost small" style="margin-top:4px">Choose a new date</button>
  </div>
</div></div>'''
js066 = "document.getElementById('xb').innerHTML = DX.badge({ kind: 'xero', n: '0', state: 'earned', size: 54, bare: true }); document.getElementById('xr066').innerHTML = DX.char('xero', { mood: 'calm', size: 88 });"
page('066-settings-quitDay', '066 Quit Day', 'The date card arrives, the day count rises 0 to 7 and the Day Xero badge stamps in at 700ms; the seven day ticks of the first week pop in left to right (110ms apart) ending on the Today ring; the change card follows. Choose a new date opens a calm confirm sheet first, never a direct date wheel.', 'reading', body066, css066, js066)

# ======================================================================== 067 currency
css067 = '''
.search { display: flex; align-items: center; gap: 10px; margin-top: 18px; }
.search svg { width: 18px; height: 18px; color: var(--muted); }
.opts { display: grid; gap: 8px; margin-top: 14px; }
.opt { min-height: 60px; padding: 10px 16px 10px 12px; }
.sym { width: 40px; height: 40px; border-radius: 12px; background: var(--card-2); display: grid; place-items: center; font: 800 16px/1 var(--display); flex: none; }
'''
def cur(sym, name, code, on=False, i=0, idd=''):
    return '<div data-a style="--i:%d"><button class="opt%s"%s><span class="sym">%s</span><div class="grow"><div class="t-body rt">%s</div><div class="t-foot">%s</div></div><span class="radio"></span></button></div>' % (i, ' on' if on else '', (' id="%s"' % idd) if idd else '', sym, name, code)
body067 = nav() + '''
<div class="scroll"><div class="pad">
  ''' + header('Currency', 'Used for money kept and the prices you entered.') + '''
  <div class="field ph search" data-a style="--i:2"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"><circle cx="11" cy="11" r="6.5"/><path d="M16 16l4.5 4.5"/></svg>Search currencies</div>
  <div class="opts">
    ''' + cur('$', 'US Dollar', 'USD, your region', False, 3, 'usd') + '''
    ''' + cur('&pound;', 'British Pound', 'GBP', False, 4) + '''
    ''' + cur('&euro;', 'Euro', 'EUR', False, 5) + '''
    ''' + cur('&#8377;', 'Indian Rupee', 'INR', False, 6) + '''
    ''' + cur('A$', 'Australian Dollar', 'AUD', False, 7) + '''
    ''' + cur('C$', 'Canadian Dollar', 'CAD', False, 8) + '''
    ''' + cur('&yen;', 'Japanese Yen', 'JPY', False, 9) + '''
    ''' + cur('Fr', 'Swiss Franc', 'CHF', False, 10) + '''
    ''' + cur('kr', 'Swedish Krona', 'SEK', False, 10) + '''
  </div>
</div></div>
<div class="tabfade" style="height:120px"></div>
''' + toast('Saved. Money shows in US dollars.', 1400)
js067 = '''
const usd = document.getElementById('usd');
DX.after(900, () => usd.classList.add('on')); DX.onStill(() => usd.classList.add('on'));
''' + TOAST_JS.replace('%T%', '1300') + '\n' + check_js(1350)
page('067-settings-currency', '067 Currency', 'The search field and rows arrive on the stagger; at 0.9s US Dollar is picked (ring and tick 250ms, selection haptic) and at 1.3s the Saved toast rises from the bottom with a drawn check. Typing in search filters rows with a 200ms fade.', 'reading', body067.replace('%CHECK1400%', ''), css067, js067)

# ======================================================================== 068 subscription
css068 = '''
.plan { margin-top: 20px; padding: 20px; display: grid; gap: 4px; position: relative; overflow: hidden; }
.plan .price { display: flex; align-items: baseline; gap: 6px; margin-top: 8px; }
.plan .price .num { font-size: 36px; line-height: 1; }
.plan .xr { position: absolute; right: 8px; top: 10px; }
.status { display: inline-flex; align-items: center; gap: 6px; color: var(--tick); }
.status i { width: 8px; height: 8px; border-radius: 99px; background: currentColor; }
.inc .row { min-height: 44px; gap: 12px; }
.inc .tk { width: 24px; height: 24px; border-radius: 99px; background: var(--card-2); display: grid; place-items: center; color: var(--fg); flex: none; }
'''
inc = ['Your 7-day prep and personal plan', 'Craving SOS and calm tools, any time', 'Daily lessons and evening check-ins', 'Progress, badges and money kept']
body068 = nav() + '''
<div class="scroll"><div class="pad">
  ''' + header('Subscription', 'Payment and renewal are handled by your Apple ID.') + '''
  <div class="card plan" data-a style="--i:2">
    <span class="status t-cap"><i></i>Active</span>
    <div class="t-title" style="margin-top:6px">DayXero Yearly</div>
    <div class="price"><span class="num" data-count="39.99" data-dec="2" data-prefix="$">$39.99</span><span class="t-head">a year</span></div><p class="t-foot muted">About $3.33 a month</p>
    <div class="divider" style="margin:14px 0 8px"></div>
    <p class="t-foot muted">Renews Fri, Nov 5, 2027. Your 7-day free trial ended Nov 5.</p>
    <div class="xr" id="xr" data-settle style="--d:400ms"></div>
  </div>
  <p class="t-foot sec" data-a style="--i:3">What is included</p>
  <div class="inc" data-a style="--i:4">''' + ''.join('<div class="row"><span class="tk" data-ic="check" data-s="14" data-w="3"></span><span class="t-foot" style="flex:1;font-size:15px">%s</span></div>' % t for t in inc) + '''</div>
</div></div>
<div class="dock"><button class="btn" data-a style="--i:5">Manage in the App Store</button><button class="link" data-a style="--i:6">Restore purchases</button></div>'''
js068 = "document.getElementById('xr').innerHTML = DX.char('xero', { mood: 'hello', size: 88 });"
page('068-settings-subscription', '068 Subscription', 'The plan card arrives and the price counts up to $39.99 while Xero settles into its corner (400ms); the included list follows on the stagger. Manage opens the App Store subscription sheet.', 'reading', body068, css068, js068)

# ======================================================================== 069 privacy
css069 = """
.lead { display: flex; gap: 12px; align-items: center; padding: 10px 16px 10px 8px; margin-top: 18px; }
.lead .grow { flex: 1; }
.list .row.tall { align-items: flex-start; padding-top: 14px; padding-bottom: 14px; }
.del { margin-top: 12px; padding: 18px; display: grid; gap: 10px; background: color-mix(in srgb, var(--coral) 13%, var(--card)); box-shadow: inset 0 0 0 1px color-mix(in srgb, var(--coral) 35%, transparent); }
.del .t-head { color: var(--danger-fg); }
.btn.danger { background: transparent; color: var(--danger-fg); box-shadow: inset 0 0 0 2px var(--danger-fg); }
.btn.danger svg { width: 18px; height: 18px; }
.screen { --danger-fg: #B53A22; }
[data-theme="dark"] .screen { --danger-fg: #FF9A7A; }
"""
body069 = nav() + """
<div class="scroll"><div class="pad">
  """ + header('Privacy and your data', 'No account, no ads, no selling. Here is exactly what happens.') + """
  <div class="card lead" data-a style="--i:2"><span id="xr069" data-settle style="--d:300ms"></span><div class="grow"><div class="t-head">It stays on this phone</div><div class="t-foot muted">Your plan, reasons, logs and notes never leave this iPhone.</div></div></div>
  <div class="list" data-a style="--i:3;margin-top:12px">
    """ + row('chart', 'Share anonymous usage', 'Counts like &ldquo;lesson started&rdquo;. Never your words.', '<span class="toggle on"></span>', cls='tall') + """
    """ + row('share', 'Export my data', 'A file you can keep or move', CHEV) + """
    """ + row('lock', 'Face ID lock', 'Ask for Face ID when DayXero opens', '<span class="toggle"></span>', cls='tall') + """
  </div>
  <div class="card flat del" data-a style="--i:4">
    <div class="t-head">Delete all my data</div>
    <p class="t-foot muted">This erases your plan, days, badges and notes from this phone. It cannot be undone, and we cannot recover it.</p>
    <button class="btn small danger" style="margin-top:4px">Delete everything</button>
  </div>
</div></div>"""
js069 = "document.getElementById('xr069').innerHTML = DX.char('xero', { mood: 'calm', size: 88 });"
page('069-settings-privacy', '069 Privacy and your data', 'The lead card arrives and Xero settles into it (300ms), then the data list and the coral delete card arrive on the stagger. Delete everything asks for a 2s hold on a confirm sheet (warning haptic), so it can never be a slip of the thumb.', 'reading', body069, css069, js069)

# ======================================================================== 070 health
css070 = """
.link-card { margin-top: 18px; padding: 22px 18px 18px; display: grid; justify-items: center; gap: 4px; text-align: center; }
.apps { display: flex; align-items: center; gap: 0; margin-bottom: 12px; }
.app { width: 84px; height: 84px; border-radius: 22px; display: grid; place-items: center; overflow: hidden; box-shadow: 0 6px 16px rgba(20,20,40,.14), inset 0 0 0 1px rgba(0,0,0,.06); flex: none; }
.app.dx { background: #FFD9B8; }
.app.hk { background: #FFFFFF; }
.wire { width: 64px; position: relative; height: 24px; display: grid; place-items: center; }
.wire::before { content: ""; position: absolute; left: 6px; right: 6px; top: 50%; border-top: 2.5px dotted var(--muted); }
.wire .ok { position: relative; width: 24px; height: 24px; border-radius: 99px; background: var(--tick); color: #fff; display: grid; place-items: center; }
[data-theme="dark"] .wire .ok { color: #0B2A1C; }
.wire .ok svg { width: 13px; height: 13px; }
.beat { transform-origin: center; }
.play .beat { animation: dx-bump 520ms var(--spring) both; animation-delay: 900ms; }
.status { display: inline-flex; align-items: center; gap: 6px; color: var(--tick); font-weight: 700; }
"""
HEART = '<svg width="54" height="54" viewBox="0 0 24 24" class="beat"><defs><linearGradient id="hk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FF5E7E"/><stop offset="1" stop-color="#FF2D55"/></linearGradient></defs><path d="M12 20.6C6.4 16.4 2.8 13.1 2.8 8.9 2.8 6.1 5 4 7.6 4c1.8 0 3.4 1 4.4 2.5C13 5 14.6 4 16.4 4 19 4 21.2 6.1 21.2 8.9c0 4.2-3.6 7.5-9.2 11.7z" fill="url(#hk)"/></svg>'
body070 = nav() + """
<div class="scroll"><div class="pad">
  """ + header('Apple Health', 'Keep your quit next to the rest of your health. You choose what is shared.') + """
  <div class="card link-card" data-a style="--i:2">
    <div class="apps"><span class="app dx" id="dx070"></span><span class="wire"><span class="ok" data-ic="check" data-s="13" data-w="3.2"></span></span><span class="app hk">""" + HEART + """</span></div>
    <div class="t-head">Connected to Health</div>
    <div class="t-foot muted">Since Fri, Oct 30</div>
  </div>
  <p class="t-foot sec" data-a style="--i:3">DayXero writes</p>
  <div class="list" data-a style="--i:4">
    """ + row('leaf', 'Mindful minutes', 'From calm tools and SOS', '<span class="toggle on"></span>') + """
  </div>
  <p class="t-foot sec" data-a style="--i:5">DayXero reads</p>
  <div class="list" data-a style="--i:6">
    """ + row('heart', 'Resting heart rate', 'To show your body recovering', '<span class="toggle on"></span>') + """
    """ + row('moon', 'Sleep', 'Sleep shifts in week one', '<span class="toggle on"></span>') + """
    """ + row('people', 'Steps', 'Not shared', '<span class="toggle"></span>') + """
  </div>
  <p class="t-foot muted" data-a style="--i:7;padding:14px 4px 0">Health asks you first, and DayXero never sees what you turn off.</p>
</div></div>"""
js070 = "document.getElementById('dx070').innerHTML = DX.char('xero', { mood: 'hello', size: 76 });"
page('070-settings-health', '070 Apple Health', 'The connected card arrives with the DayXero and Health tiles, the dotted link and its check; the Health heart gives one soft bump at 900ms; the write and read groups follow on the stagger. Flipping a toggle opens the system Health permission sheet.', 'reading', body070, css070, js070)
print('ok')
