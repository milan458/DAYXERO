/* DayXero App Store screenshots, Direction C: "The sky clears". The ten frames as data, plus the builder.
   The art is one continuous panorama (pano.js); each frame shows its 440 px slice of it. Phones are smaller than in
   Direction A, flat and centred, so the landscape carries the set. Render with `node render.mjs` (see README.md).

   Persona (design system section 7, code-true values from decision 17): Sam, cigarettes (12 a day) and a vape, triggers
   coffee then stress, reason "To keep up with Maya at the park.", Quit Day Fri, Nov 6, "today" Sun, Nov 8 = Day 3.
   Each app screen states its time in the status bar (?time=) and shows that time's numbers:
     07:30  25 cigarettes not smoked, $15.02 kept ($15 where the app rounds to whole dollars)
     09:40  26 cigarettes not smoked, $15.65 kept, 15 waves ridden out (after the morning coffee wave)
   Finale: the Week 4 row of section 7 (28 days, 61 waves, 26 check-ins, $196, 336 cigarettes).

   tone: the caption colour, chosen against the sky behind it and measured (node check.mjs): ink, or cream at night. */

window.PHONE = { k: 0.62, top: 292 };

window.FRAMES = [
  { // 1 ── hazy dawn: the promise and the three products. Xero rises at the seam with frame 2.
    id: '01', tone: 'ink',
    title: 'Quit nicotine on a day you choose',
    sub: 'Cigarettes · Vapes · Pouches',
    fine: 'Requires a DayXero Pro subscription.',
    screen: 'today.html', time: '7:30'
  },
  { // 2 ── the prep path: seven stones to the Quit Day flag on the headland
    id: '02', tone: 'ink',
    title: 'Prep for 7 days. Then quit.',
    sub: 'Keep using as normal while you get ready for Quit Day.',
    screen: 'quitday.html', time: '9:41',
    zoom: { sel: '.card.wk', scale: 0.8, dy: 0 }
  },
  { // 3 ── the sea: Craving SOS, Jelli rides the swell at the seam with frame 4
    id: '03', tone: 'ink',
    title: 'A craving? Ride the wave.',
    sub: 'Breathe with Jelli. Most cravings pass within a few minutes.',
    screen: 'sos.html', time: '9:39'
  },
  { // 4 ── the slip rule, out on calm water
    id: '04', tone: 'ink',
    title: 'Slipped? Nothing resets.',
    sub: 'Your sky stays clearer. You get a plan for next time.',
    screen: 'slip.html', time: '9:39',
    zoom: { sel: '.grid2.kept', scale: 0.84, dy: 0 }
  },
  { // 5 ── back on land: the daily lesson
    id: '05', tone: 'ink',
    title: '3 minutes a day',
    sub: 'One short lesson a day, in order. No rush.',
    screen: 'lesson.html', time: '2:00'
  },
  { // 6 ── what you've kept (the card covers the Progress hero, which says "days free")
    id: '06', tone: 'ink',
    title: 'See what you\'ve kept',
    sub: 'Money, cigarettes not smoked and waves ridden out.',
    screen: 'progress.html', time: '9:40',
    card: { width: 316, z: 0.8, cover: ['.hero-card', '.quiet'], pad: 6, html: `
      <div class="kept">
        <div class="sky" data-sky><span class="pill">Sky 28% clear</span></div>
        <div class="row1"><span class="big">$15.65</span><span>kept so far</span></div>
        <div class="grid">
          <div><b>26</b><span>cigarettes not smoked</span></div>
          <div><b>15</b><span>waves ridden out</span></div>
          <div><b>2</b><span>check-ins with Glim</span></div>
        </div>
        <p class="foot">$7 a day, about $2,555 a year.</p>
      </div>` }
  },
  { // 7 ── health changes, quoted from health-timeline.json with the source, in the late-afternoon light
    id: '07', tone: 'ink',
    title: 'What\'s changing in your body',
    sub: 'Timings quoted from the American Cancer Society.',
    screen: 'health.html', time: '9:40',
    card: { width: 324, z: 0.82, top: 512, html: `
      <div class="fact">
        <span class="k"><i></i>Happening now · A few days</span>
        <b>Carbon monoxide in your blood drops to normal</b>
        <span class="l">More oxygen reaches your body.</span>
        <span class="src">Source: American Cancer Society</span>
      </div>` }
  },
  { // 8 ── dusk into night: Xero sets at the seam with frame 7, Glim lights up at the seam with frame 9
    id: '08', tone: 'cream',
    title: 'Hard evening? Glim checks in.',
    sub: 'A one-minute check-in, then rest.',
    screen: 'checkin.html', time: '9:30'
  },
  { // 9 ── night: the Lock Screen widgets and the SOS Live Activity
    id: '09', tone: 'cream',
    title: 'SOS on your Lock Screen',
    sub: 'Start from a widget. Ride it out from the Live Activity.',
    screen: 'lock.html', time: '',
    zoom: { sel: '#la', scale: 0.86, dy: 0 }
  },
  { // 10 ── the next dawn, fully clear: the whole crew
    id: '10', tone: 'ink',
    title: '28 days. Clear skies.',
    sub: 'Private on this phone. No guilt, ever.',
    fine: 'Requires a DayXero Pro subscription.',
    screen: 'finale.html', time: '9:41'
  }
];

/* ---------------------------------------------------------------- builder */
(function () {
  if (!document.querySelector('.stage')) return;
  const q = new URLSearchParams(location.search);
  const f = window.FRAMES.find(x => x.id === (q.get('f') || '01').padStart(2, '0'));
  const idx = window.FRAMES.indexOf(f);
  const scale = Number(q.get('scale') || 1);
  const artOnly = q.get('art') === '1';   // check.mjs: the art alone (seam test)
  const noCap = q.get('nocap') === '1';   // check.mjs: everything but the caption (contrast test)
  const stage = document.querySelector('.stage');
  stage.dataset.tone = f.tone;
  stage.style.transform = `scale(${scale})`;
  stage.style.height = (window.innerHeight / scale) + 'px';

  const ICON = {
    check: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>'
  };
  const fill = s => s.replace(/\{(check)\}/g, (m, k) => ICON[k]);
  const src = `app/screens/${f.screen}?still=1${f.time ? '&time=' + encodeURIComponent(f.time) : ''}`;
  const P = window.PHONE, pw = 418 * P.k, pl = (440 - pw) / 2;
  const p = { left: pl, top: P.top, k: P.k };

  let html = `<div class="art back">${window.PANO.svg('back', -440 * idx)}</div>`;
  if (!artOnly) html += `<div class="phone" style="left:${p.left}px;top:${p.top}px;--k:${p.k}"><div class="body">
      <div class="glass"><iframe src="${src}" title="DayXero screen" scrolling="no"></iframe></div>
      <div class="island"></div></div>
      <span class="btn-l" style="top:150px;height:30px"></span><span class="btn-l" style="top:205px;height:56px"></span><span class="btn-l" style="top:272px;height:56px"></span>
      <span class="btn-r" style="top:230px;height:88px"></span></div>`;
  html += `<div class="art front">${window.PANO.svg('front', -440 * idx)}</div>`;
  if (!artOnly && !noCap) html += `<div class="cap"><h1>${f.title}</h1>${f.sub ? `<p class="sub">${f.sub}</p>` : ''}${f.fine ? `<p class="fine">${f.fine}</p>` : ''}</div>`;
  if (!artOnly && f.zoom) html += `<div class="zoom" id="zoom" style="visibility:hidden"><iframe src="${src}" title="" scrolling="no"></iframe></div>`;
  if (!artOnly && f.card) {
    const left = (440 - f.card.width) / 2;
    html += `<div class="card-out" id="card" style="left:${left}px;top:${f.card.top || 0}px;width:${f.card.width}px${f.card.cover ? ';visibility:hidden' : ''}"><div class="zin" style="zoom:${f.card.z};width:${f.card.width / f.card.z}px">${fill(f.card.html)}</div></div>`;
  }
  stage.innerHTML = html;
  /* frame 6: Xero's sky in the card, at Day 3's clarity (20 + 2.8 x days clear = 28) */
  stage.querySelectorAll('[data-sky]').forEach(el => el.insertAdjacentHTML('afterbegin',
    window.DXC.horizon({ scene: 'dawn', clarity: 28, w: 368, h: 112, fit: 'xMidYMax slice', animate: false }) +
    `<span class="x">${window.DXC.xero({ mood: 'hello', stage: 1, size: 84, animate: false })}</span>`));

  /* Ready when every iframe has finished its still render and every font is in. render.mjs waits for this. */
  const frames = [...document.querySelectorAll('iframe')];
  const iframeReady = fr => new Promise(res => {
    const check = () => { try { const d = fr.contentDocument; if (d && d.location.href.includes(f.screen) && d.readyState === 'complete' && (d.body.classList.contains('ready') || !d.querySelector('script[src*="kit.js"]') || f.screen === 'lock.html') && d.fonts.status === 'loaded') return res(); } catch (e) {} setTimeout(check, 50); };
    check();
  });
  /* A zoom breakout lifts one element out of the phone: measured inside the screen, magnified by z.scale (in screen px;
     the phone itself shows at p.k), and centred on where the element sits in the phone (plus z.dx / z.dy). */
  function placeZoom() {
    const z = f.zoom, doc = frames[0].contentDocument, el = doc.querySelector(z.sel);
    if (!el) throw new Error('zoom: no ' + z.sel);
    const r = el.getBoundingClientRect(), pad = z.pad || 0;
    const x = r.left - pad, y = r.top - pad, w = r.width + 2 * pad, h = r.height + 2 * pad, m = z.scale;
    const cx = p.left + p.k * (14 + x + w / 2) + (z.dx || 0), cy = p.top + p.k * (14 + y + h / 2) + (z.dy || 0);
    const W = w * m, Hh = h * m, left = Math.max(10, Math.min(440 - 10 - W, cx - W / 2));
    const rad = (z.radius != null ? z.radius : parseFloat(doc.defaultView.getComputedStyle(el).borderTopLeftRadius) || 22) * m;
    const box = document.getElementById('zoom');
    Object.assign(box.style, { left: left + 'px', top: (cy - Hh / 2) + 'px', width: W + 'px', height: Hh + 'px', borderRadius: rad + 'px', visibility: 'visible' });
    box.querySelector('iframe').style.transform = `scale(${m}) translate(${-x}px, ${-y}px)`;
  }
  /* A card that covers elements of the screen (frame 6: the hero and the stats row): it spans their union, plus pad. */
  function coverCard() {
    const doc = frames[0].contentDocument, rs = f.card.cover.map(sel => doc.querySelector(sel).getBoundingClientRect());
    const y0 = Math.min(...rs.map(r => r.top)), y1 = Math.max(...rs.map(r => r.bottom)), pad = f.card.pad || 0;
    const card = document.getElementById('card'), top = p.top + p.k * (14 + y0) - pad, h = p.k * (y1 - y0) + 2 * pad;
    const zin = card.querySelector('.zin');
    Object.assign(card.style, { top: top + 'px', visibility: 'visible' });
    Object.assign(zin.style, { minHeight: (h / f.card.z) + 'px', display: 'flex', flexDirection: 'column' });
  }
  Promise.all([document.fonts.ready, ...frames.map(iframeReady)]).then(() => {
    if (f.zoom && !artOnly) placeZoom();
    if (f.card && f.card.cover && !artOnly) coverCard();
    setTimeout(() => { document.body.dataset.ready = '1'; }, 250);
  });
})();
