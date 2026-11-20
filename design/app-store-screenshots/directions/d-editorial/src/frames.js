/* DayXero App Store screenshots, Direction D "Calm and credible": the ten frames as data, plus the builder.
   Edit copy, chips and the lifted pieces here; render with `node render.mjs` (see ../README.md).

   Every piece of UI is a crop of a real app screen (app/screens/*.html, the persona-true v5 screens shared with Direction A,
   plus privacy.html drawn from PrivacySettingsView), so what the frame shows is what the app renders. Characters stay out of
   frame: crops are chosen to leave out Xero, Jelli and Glim; the only character left is the 30-34 px avatar the UI itself
   carries (the Live Activity's Jelli, the privacy tile's Xero).

   Persona (design system section 7, code-true values from decision 17): Sam, cigarettes (12 a day) and a vape, reason
   "To keep up with Maya at the park.", Quit Day Fri, Nov 6, "today" Sun, Nov 8 = Day 3.
     07:30  25 cigarettes not smoked, $15 kept (the Today hero rounds to whole dollars)
     09:39  SOS: coffee wave, ridden 0:52. Lock Screen "Day 3 · $15 kept"
     09:40  26 cigarettes not smoked, $15.65 kept, 15 waves ridden
     21:30  3 waves today, 3 ridden out
   Finale: the Week 4 row of section 7 (28 days, 61 waves, 26 check-ins, $196.00, 336 cigarettes).

   Piece syntax: { s: screen, t: status-bar time, sel: CSS selector | rect: [x, y, w, h] (screen px), pad, k: scale,
                   x: left | 'c' (centred) , y: top, r: corner radius, cls: 'sm' | 'flat', z } */

window.FRAMES = [
  { // 1 ── the promise: calmer, prepared. Today after Quit Day (7:30), cropped below the hero; the 3-day badge lifted out
    id: '01', size: 54,
    title: 'A calmer way<br>to quit <g>nicotine</g>',
    sub: 'Prepare for a week, then quit on a day you choose.',
    chips: [['check', 'Cigarettes · Vapes · Pouches']],
    fine: 'Requires a DayXero Pro subscription.',
    pieces: [
      { s: 'today', t: '7:30', rect: [0, 404, 390, 440], k: 1.046, x: 'c', y: 498, r: 34 },
      { s: 'today', t: '7:30', sel: '.stage', k: 0.8, x: 254, y: 356, r: 999, cls: 'sm', z: 6 }
    ]
  },
  { // 2 ── the mechanic: Quit Day, with a prep week first (onboarding 010), in three parts; the prep-week card lifted
    id: '02',
    title: 'Choose your<br><g>Quit Day</g>',
    sub: 'Prep for 7 days first. Keep using as normal until then.',
    chips: [['check', 'You can change it later']],
    pieces: [
      { s: 'quitday', t: '9:41', rect: [0, 104, 390, 132], k: 1.046, x: 'c', y: 344, r: 28 },
      { s: 'quitday', t: '9:41', sel: '.card.wk', k: 1.1, x: 'c', y: 462, r: 25, z: 6 },
      { s: 'quitday', t: '9:41', rect: [0, 690, 390, 154], k: 1.046, x: 'c', y: 694, r: 28 }
    ]
  },
  { // 3 ── Craving SOS at 9:39, cropped below the breathing ring so Jelli stays out of frame; the timer lifted out
    id: '03',
    title: 'When a craving<br>hits, <g>breathe.</g>',
    sub: 'Breathe in for 4, out for 6. Most cravings pass in a few minutes.',
    chips: [['lock', 'Your reason stays on this phone']],
    pieces: [
      { s: 'sos', t: '9:39', rect: [8, 416, 374, 408], k: 1.13, x: 'c', y: 412, r: 32 },
      { s: 'sos', t: '9:39', sel: '.nav .timer', k: 1.6, x: 214, y: 386, r: 99, cls: 'sm', z: 6 }
    ]
  },
  { // 4 ── the slip rule (SlipFlow step 1), the alternative branch of the Day 3 SOS; the kept tiles magnified in place
    id: '04',
    title: 'A slip doesn\'t<br><g>reset your days</g>',
    sub: 'Nothing resets. Make a one-minute plan for next time.',
    chips: [['heart', 'No guilt, ever']],
    pieces: [
      { s: 'slip', t: '9:39', rect: [0, 390, 390, 440], k: 1.046, x: 'c', y: 360, r: 32 },
      { s: 'slip', t: '9:39', sel: '.grid2.kept', pad: 0, k: 1.12, of: 0, dy: -6, r: 22, cls: 'sm', z: 6 }
    ]
  },
  { // 5 ── the Day 3 lesson (W1D2, 3 min), and Week 1 in order
    id: '05',
    title: 'Three minutes<br><g>a day</g>',
    sub: 'One short lesson a day, in order. No rush.',
    pieces: [
      { s: 'lesson', t: '2:00', rect: [0, 368, 390, 318], k: 1.0, x: 'c', y: 318, r: 30 },
      { card: `
        <div class="week">
          <div class="h"><b>Week 1</b><span>Through the hardest stretch.</span></div>
          <div class="r"><span class="ic done">{check}</span><span class="t"><b>Look after the basics</b><span>Day 2 · done</span></span></div>
          <div class="r today"><span class="ic now">{play}</span><span class="t"><b>The noisy passengers</b><span>Day 3 · today · 3 min</span></span></div>
          <div class="r"><span class="ic lock">{lock}</span><span class="t"><b>Lower the bar</b><span>Day 4 · opens tomorrow</span></span></div>
        </div>`, x: 64, y: 614, w: 352 }
    ]
  },
  { // 6 ── Progress at 9:40 in parts: the stats, badges and tab bar, and the money line lifted from the hero (cropped clear
        //    of its "days free" count and Xero)
    id: '06', size: 50,
    title: 'Your progress,<br><g>in plain numbers</g>',
    sub: 'Money kept, cigarettes not smoked and waves ridden out.',
    pieces: [
      { s: 'progress', t: '9:40', rect: [0, 424, 390, 420], k: 1.046, x: 'c', y: 474, r: 32 },
      { s: 'progress', t: '9:40', rect: [22, 212, 236, 96], k: 1.5, x: 32, y: 322, r: 26, cls: 'sm', z: 6 }
    ]
  },
  { // 7 ── What's changing, Day 3, quoted from health-timeline.json with its source; the change under way magnified
    id: '07',
    title: 'What\'s changing<br>in your <g>body</g>',
    sub: 'Typical times, each with its source. Everyone is different.',
    chips: [['doc', 'Source: American Cancer Society']],
    pieces: [
      { s: 'health', t: '9:40', rect: [0, 236, 390, 608], k: 0.98, x: 'c', y: 338, r: 32 },
      { s: 'health', t: '9:40', sel: '.card.item.now', k: 1.1, of: 0, r: 26, cls: 'sm', z: 6 }
    ]
  },
  { // 8 ── the evening check-in at 9:30 PM (the dark shot), cropped below Glim; the mood faces magnified in place
    id: '08',
    title: 'One minute<br><g>each evening</g>',
    sub: 'Count the day\'s waves, say how you feel, then rest.',
    pieces: [
      { s: 'checkin', t: '9:30', rect: [0, 284, 390, 560], k: 1.046, x: 'c', y: 330, r: 32 },
      { s: 'checkin', t: '9:30', sel: '.faces', pad: 8, k: 1.1, of: 0, r: 28, cls: 'sm', z: 6 }
    ]
  },
  { // 9 ── Lock Screen widgets and the SOS Live Activity; the one cropped phone in the set
    id: '09',
    title: 'Help on your<br><g>Lock Screen</g>',
    sub: 'Start SOS from a widget. Ride it out from the Live Activity.',
    phone: { s: 'lock', t: '', x: 'c', y: 306, k: 0.88 },
    pieces: [
      { s: 'lock', t: '', sel: '#la', k: 1.1, of: 'phone', r: 32, cls: 'sm', z: 6 }
    ]
  },
  { // 10 ── the closer: privacy (PrivacySettingsView) and the user's own reason (the finale, Week 4)
    id: '10',
    title: 'Private, and<br><g>on your side</g>',
    sub: 'No account, no ads, no selling. Your plan and notes never leave this iPhone.',
    chips: [['lock', 'Private on this phone'], ['heart', 'No guilt, ever']],
    fine: 'Requires a DayXero Pro subscription.',
    pieces: [
      { s: 'privacy', t: '9:41', rect: [0, 100, 390, 340], k: 1.0, x: 'c', y: 356, r: 32 },
      { s: 'finale', t: '9:41', rect: [14, 384, 362, 198], k: 1.0, x: 'c', y: 714, r: 26, cls: 'sm', z: 6 }
    ]
  }
];

/* ---------------------------------------------------------------- builder */
(function () {
  const q = new URLSearchParams(location.search);
  const f = window.FRAMES.find(x => x.id === (q.get('f') || '01').padStart(2, '0'));
  const scale = Number(q.get('scale') || 1);
  const stage = document.querySelector('.stage');
  stage.style.transform = `scale(${scale})`;
  const H = window.innerHeight / scale;
  stage.style.height = H + 'px';

  const ICON = {
    check: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>',
    play: '<svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5.5v13l11-6.5z"/></svg>',
    lock: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M7 11V8a5 5 0 0110 0v3M5.5 11h13v9h-13z"/></svg>',
    doc: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M6 3.5h9l3 3V20.5H6zM9 11h6M9 15h6"/></svg>',
    heart: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M12 20s-7-4.4-7-10a4 4 0 017-2.6A4 4 0 0119 10c0 5.6-7 10-7 10z"/></svg>'
  };
  const fill = s => s.replace(/\{(check|play|lock)\}/g, (m, k) => k === 'play' ? ICON.play : ICON[k].replace('<svg ', '<svg width="20" height="20" '));
  const src = (s, t) => `app/screens/${s}.html?still=1${t ? '&time=' + encodeURIComponent(t) : ''}`;
  const title = f.title.replace(/<g>(.*?)<\/g>/g, '<span class="acc">$1</span>');

  let html = '';
  if (f.table) html += `<div class="table" style="top:${f.table}px"></div>`;
  html += `<div class="cap"><h1${f.size ? ` style="font-size:${f.size}px"` : ''}>${title}</h1>`
    + (f.sub ? `<p class="sub">${f.sub}</p>` : '')
    + (f.chips ? `<div class="chips">${f.chips.map(([ic, t]) => `<span class="tchip">${ICON[ic]}${t}</span>`).join('')}</div>` : '')
    + (f.fine ? `<p class="fine">${f.fine}</p>` : '') + `</div>`;
  if (f.phone) {
    const p = f.phone, left = p.x === 'c' ? (440 - 408 * p.k) / 2 : p.x;
    html += `<div class="phone" style="left:${left}px;top:${p.y}px;--k:${p.k}"><div class="body"><div class="glass"><iframe src="${src(p.s, p.t)}" title="DayXero screen" scrolling="no"></iframe></div><div class="island"></div></div></div>`;
  }
  f.pieces.forEach((p, i) => {
    if (p.card) {
      html += `<div class="card-out" style="left:${p.x}px;top:${p.y}px;width:${p.w}px;z-index:${p.z || 5}">${fill(p.card)}</div>`;
    } else {
      html += `<div class="piece ${p.cls || ''}" id="pc${i}" style="z-index:${p.z || 4}"><iframe src="${src(p.s, p.t)}" title="" scrolling="no"></iframe></div>`;
    }
  });
  stage.innerHTML = html;

  /* Ready when every iframe has finished its still render and every font is in. render.mjs waits for this. */
  const frames = [...document.querySelectorAll('iframe')];
  const iframeReady = fr => new Promise(res => {
    const want = fr.getAttribute('src').split('?')[0];
    const check = () => { try { const d = fr.contentDocument; if (d && d.location.href.includes(want) && d.readyState === 'complete' && (d.body.classList.contains('ready') || !d.querySelector('script[src*="kit.js"]')) && d.fonts.status === 'loaded') return res(); } catch (e) {} setTimeout(check, 50); };
    check();
  });
  /* Place each piece: measure its crop inside the screen (a selector plus pad, or a fixed rect), scale it by k and put its
     top-left corner at (x, y) on the stage ('c' centres it). */
  const placed = [];
  const PH = f.phone ? { left: f.phone.x === 'c' ? (440 - 408 * f.phone.k) / 2 : f.phone.x, top: f.phone.y, k: f.phone.k } : null;
  function place(p, i) {
    const box = document.getElementById('pc' + i), fr = box.querySelector('iframe'), doc = fr.contentDocument;
    let x, y, w, h;
    if (p.rect) [x, y, w, h] = p.rect;
    else {
      const el = doc.querySelector(p.sel);
      if (!el) throw new Error('piece: no ' + p.sel);
      const r = el.getBoundingClientRect(), pad = p.pad || 0;
      x = r.left - pad; y = r.top - pad; w = r.width + 2 * pad; h = r.height + 2 * pad;
    }
    const W = w * p.k, Hh = h * p.k;
    let left = p.x === 'c' ? (440 - W) / 2 : p.x, top = p.y;
    if (p.of != null) {  /* a lens: magnified over where the element sits in the base piece (or the phone) */
      const b = p.of === 'phone' ? { left: PH.left + PH.k * 9, top: PH.top + PH.k * 9, x: 0, y: 0, k: PH.k } : placed[p.of];
      left = b.left + (x + w / 2 - b.x) * b.k - W / 2 + (p.dx || 0);
      top = b.top + (y + h / 2 - b.y) * b.k - Hh / 2 + (p.dy || 0);
    }
    placed[i] = { left, top, x, y, k: p.k };
    const rad = p.r != null ? (p.r === 999 ? Math.min(W, Hh) / 2 : p.r) : 26;
    Object.assign(box.style, { left: left + 'px', top: top + 'px', width: W + 'px', height: Hh + 'px', borderRadius: rad + 'px', visibility: 'visible' });
    fr.style.transform = `scale(${p.k}) translate(${-x}px, ${-y}px)`;
  }
  Promise.all([document.fonts.ready, ...frames.map(iframeReady)]).then(() => {
    f.pieces.forEach((p, i) => { if (!p.card) place(p, i); });
    setTimeout(() => { document.body.dataset.ready = '1'; }, 250);
  });
})();
