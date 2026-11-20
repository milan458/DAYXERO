/* DayXero App Store screenshots, Direction B "Proof in numbers": the ten frames as data, plus the builder.
   Edit copy, phone positions and breakouts here; render with `node render.mjs` (see ../README.md).

   Persona (design system section 7, code-true values from decision 17): Sam, cigarettes (12 a day) and a vape, triggers
   coffee then stress, reason "To keep up with Maya at the park.", Quit Day Fri, Nov 6, "today" Sun, Nov 8 = Day 3.
   Each app screen states its time in the status bar (?time=) and shows that time's numbers:
     07:30  25 cigarettes not smoked, $15.02 kept ($15 where the app rounds to whole dollars)
     09:39  the coffee wave, ridden 0:52 (section 8)
     09:40  26 cigarettes not smoked, $15.65 kept, 15 waves ridden out (after the morning coffee wave)
     21:30  3 waves today, 3 ridden out (section 7: Day 3 cravings 3 logged, 3 ridden out); Glim's check-in time
   Finale: the Week 4 row of section 7 (Thu, Dec 3: 28 days clear, 61 waves, 26 check-ins, $196, 336 cigarettes).
   Every number in a caption or a proof chip is one of these, and the phone in the same frame shows it.

   Frame fields: title (<em> = the coral accent line), sub, fine, screen, time, theme ('dark' = the app's own Dark Mode),
   phone { left, top, k }, proof (the proof bar: top, or anchor { sel, dy } to sit over an element of the screen) and
   zoom { sel, scale, pad, dx, dy } (a real element lifted out of the screen). */

window.FRAMES = [
  { // 1 ── the outcome, as numbers, over the Week 4 finale
    id: '01',
    title: '28 days clear.<br><em>$196 kept.</em>', size: 56,
    sub: 'Quit cigarettes, vapes and pouches.',
    fine: 'Requires a DayXero Pro subscription.',
    screen: 'finale.html', time: '9:41', theme: 'dark',
    phone: { left: 53, top: 300, k: 0.80 },
    proof: { anchor: { sel: '.card.fact', dy: -4 }, html: `
      <span class="n">336</span>
      <span class="tx"><span class="k"><i></i>Week 4 · Thu, Dec 3</span><span class="l">cigarettes not smoked</span></span>` }
  },
  { // 2 ── the prep week, then Quit Day
    id: '02',
    title: '7 days of prep.<br><em>Then Day 1.</em>',
    sub: 'Keep using as normal while you get ready. Then quit on the day you chose.',
    screen: 'quitday.html', time: '9:41', theme: 'dark',
    phone: { left: 53, top: 300, k: 0.80 },
    proof: { cls: 'tall', top: 700, html: `
      <span class="n">Nov 6</span>
      <span class="tx"><span class="k"><i></i>Your Quit Day</span><span class="l">Friday, after 7 short prep sessions</span></span>` }
  },
  { // 3 ── Craving SOS: time ridden, never a countdown (section 8)
    id: '03',
    title: 'A craving?<br><em>Ride it out.</em>',
    sub: 'Most cravings pass within a few minutes. Breathe with Jelli while it does.',
    screen: 'sos.html', time: '9:39',
    phone: { left: 53, top: 300, k: 0.80 },
    proof: { anchor: { sel: '.reason, [class*=reason]', dy: -16 }, html: `
      <span class="n">0:52</span>
      <span class="tx"><span class="k"><i></i>Day 3 · 9:39 AM</span><span class="l">ridden so far</span></span>
      <span class="av" data-av="jelli"></span>` }
  },
  { // 4 ── the slip rule: nothing resets
    id: '04',
    title: 'Slipped?<br><em>Still 3 days clear.</em>',
    sub: 'Nothing resets. Your days clear and Xero\'s sky stay just as they are.',
    screen: 'slip.html', time: '9:39', theme: 'dark',
    phone: { left: 53, top: 300, k: 0.80 },
    zoom: { sel: '.grid2.kept', scale: 1.18, dy: 4 }
  },
  { // 5 ── money and cigarettes, Day 3 at 9:40
    id: '05',
    title: '26 cigarettes<br><em>not smoked.</em>',
    sub: 'Money kept, cigarettes not smoked and waves ridden out, counted for you.',
    screen: 'progress.html', time: '9:40', theme: 'dark',
    phone: { left: 53, top: 300, k: 0.80 },
    proof: { cls: 'stack cover', cover: '.hero-card', pad: 6, html: `
      <span class="k"><i></i>3 days clear · Sun, Nov 8 · 9:40 AM</span>
      <span class="nrow"><span class="n big">$15.65</span><span class="t">kept<br>so far</span></span>
      <span class="strip">{strip}</span>` }
  },
  { // 6 ── the daily lesson
    id: '06',
    title: '3 minutes.<br><em>One lesson a day.</em>',
    sub: 'A short read, a few taps and one small thing to try today.',
    screen: 'lesson.html', time: '2:00', theme: 'dark',
    phone: { left: 53, top: 300, k: 0.80 },
    zoom: { sel: '.list.inside', scale: 1.16, dy: 28 }
  },
  { // 7 ── health changes, quoted from health-timeline.json with the source
    id: '07',
    title: 'What\'s changing<br><em>on Day 3.</em>', size: 48,
    sub: 'Timings quoted from the American Cancer Society.',
    screen: 'health.html', time: '9:40', theme: 'dark',
    phone: { left: 53, top: 300, k: 0.80 },
    proof: { cls: 'stack', anchor: { sel: '.card.item.now', dy: -8 }, html: `
      <span class="k"><i></i>Happening now · Day 3</span>
      <span class="n">A few days</span>
      <span class="t">Carbon monoxide in your blood drops to normal</span>
      <span class="src">Source: American Cancer Society</span>` }
  },
  { // 8 ── the evening check-in with Glim (night ground in the app too)
    id: '08',
    title: '3 waves today.<br><em>3 ridden out.</em>',
    sub: 'Glim checks in each evening. One minute, then rest.',
    screen: 'checkin.html', time: '9:30',
    phone: { left: 53, top: 300, k: 0.80 },
    proof: { anchor: { sel: '.list.sos', dy: -2 }, html: `
      <span class="n">3<small>of</small>3</span>
      <span class="tx"><span class="k"><i></i>Day 3 · 9:30 PM</span><span class="l">waves ridden out today</span></span>
      <span class="av" data-av="glim"></span>` }
  },
  { // 9 ── Lock Screen widgets and the SOS Live Activity
    id: '09',
    title: 'SOS on your<br><em>Lock Screen.</em>',
    sub: 'Start from a widget. Ride it out in the Live Activity, timer running.',
    screen: 'lock.html', time: '',
    phone: { left: 53, top: 300, k: 0.80 },
    zoom: { sel: '#la', scale: 1.15, dy: 0 }
  },
  { // 10 ── the closer: you choose the day, the app keeps count; privacy and no guilt
    id: '10',
    title: 'You pick the day.<br><em>We keep count.</em>',
    sub: 'Private on this phone. No guilt, ever.',
    fine: 'Requires a DayXero Pro subscription.',
    screen: 'today.html', time: '7:30', theme: 'dark',
    phone: { left: 53, top: 300, k: 0.80 },
    proof: { top: 796, html: `
      <span class="n">3</span>
      <span class="tx"><span class="k"><i></i>Sun, Nov 8 · 7:30 AM</span><span class="l">days clear. 3-day badge earned.</span></span>` }
  }
];

/* ---------------------------------------------------------------- builder */
(function () {
  const q = new URLSearchParams(location.search);
  const f = window.FRAMES.find(x => x.id === (q.get('f') || '01').padStart(2, '0'));
  const scale = Number(q.get('scale') || 1);
  const stage = document.querySelector('.stage');
  stage.style.transform = `scale(${scale})`;
  stage.style.height = (window.innerHeight / scale) + 'px';

  const src = `app/screens/${f.screen}?still=1${f.time ? '&time=' + encodeURIComponent(f.time) : ''}${f.theme ? '&theme=' + f.theme : ''}`;
  const p = f.phone;

  let html = `<div class="cap"><h1${f.size ? ` style="font-size:${f.size}px"` : ''}>${f.title}</h1>${f.sub ? `<p class="sub">${f.sub}</p>` : ''}${f.fine ? `<p class="fine">${f.fine}</p>` : ''}</div>`;
  html += `<div class="phone" style="left:${p.left}px;top:${p.top}px;--k:${p.k}"><div class="body">
      <div class="glass"><iframe src="${src}" title="DayXero screen" scrolling="no"></iframe></div>
      <div class="island"></div></div>
      <span class="btn-l" style="top:150px;height:30px"></span><span class="btn-l" style="top:205px;height:56px"></span><span class="btn-l" style="top:272px;height:56px"></span>
      <span class="btn-r" style="top:230px;height:88px"></span></div>`;
  if (f.zoom) html += `<div class="zoom" id="zoom" style="visibility:hidden"><iframe src="${src}" title="" scrolling="no"></iframe></div>`;
  if (f.proof) html += `<div class="proof${f.proof.cls ? ' ' + f.proof.cls : ''}" id="proof" style="top:${f.proof.top || 0}px${f.proof.anchor || f.proof.cover ? ';visibility:hidden' : ''}">${f.proof.html}</div>`;
  /* frame 5: the app's since-Quit-Day strip (ProgressDayStrip): Quit Day, two clear days, today, then days to come */
  const TICK = '<svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>';
  const SUN = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round"><path d="M12 16a4 4 0 100-8 4 4 0 000 8zM12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2M5.3 5.3l1.4 1.4M17.3 17.3l1.4 1.4M5.3 18.7l1.4-1.4M17.3 6.7l1.4-1.4"/></svg>';
  html = html.replace('{strip}', ['Fri', 'Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'].map((d, i) =>
    `<span class="${i === 0 ? 'xd' : i === 2 ? 'today' : i > 2 ? 'future' : 'done'}"><i>${i === 0 ? SUN : i > 2 ? '' : TICK}</i>${i === 0 ? 'Quit Day' : i === 2 ? 'Today' : d}</span>`).join(''));
  stage.innerHTML = html;
  /* avatar-size characters only (Direction B keeps the crew small) */
  stage.querySelectorAll('[data-av]').forEach(el => {
    const who = el.dataset.av;
    el.innerHTML = window.DXC[who]({ mood: who === 'jelli' ? 'breathe' : 'calm', stage: 1, size: 48, animate: false });
  });

  /* Ready when every iframe has finished its still render and every font is in. render.mjs waits for this. */
  const frames = [...document.querySelectorAll('iframe')];
  const iframeReady = fr => new Promise(res => {
    const check = () => { try { const d = fr.contentDocument; if (d && d.location.href.includes(f.screen) && d.readyState === 'complete' && (d.body.classList.contains('ready') || !d.querySelector('script[src*="kit.js"]') || f.screen === 'lock.html') && d.fonts.status === 'loaded') return res(); } catch (e) {} setTimeout(check, 50); };
    check();
  });
  /* where an element of the screen sits on the stage */
  function onStage(sel) {
    const doc = frames[0].contentDocument, el = doc.querySelector(sel);
    if (!el) throw new Error('no ' + sel);
    const r = el.getBoundingClientRect();
    return { el, doc, r, top: p.top + p.k * (14 + r.top), left: p.left + p.k * (14 + r.left), bottom: p.top + p.k * (14 + r.bottom) };
  }
  /* A zoom breakout lifts one element out of the phone: measured inside the screen, magnified by z.scale (in screen px;
     the phone itself shows at p.k), and centred on where the element sits in the phone (plus z.dx / z.dy). */
  function placeZoom() {
    const z = f.zoom, { el, doc, r } = onStage(z.sel), pad = z.pad || 0;
    const x = r.left - pad, y = r.top - pad, w = r.width + 2 * pad, h = r.height + 2 * pad, m = z.scale;
    const cx = p.left + p.k * (14 + x + w / 2) + (z.dx || 0), cy = p.top + p.k * (14 + y + h / 2) + (z.dy || 0);
    const W = w * m, Hh = h * m, left = Math.max(12, Math.min(440 - 12 - W, cx - W / 2));
    const rad = (z.radius != null ? z.radius : parseFloat(doc.defaultView.getComputedStyle(el).borderTopLeftRadius) || 22) * m;
    const box = document.getElementById('zoom');
    Object.assign(box.style, { left: left + 'px', top: (cy - Hh / 2) + 'px', width: W + 'px', height: Hh + 'px', borderRadius: rad + 'px', visibility: 'visible' });
    box.querySelector('iframe').style.transform = `scale(${m}) translate(${-x}px, ${-y}px)`;
  }
  /* A proof chip anchored to an element of the screen (frame 5: over the Progress hero). */
  function anchorProof() {
    const a = f.proof.anchor, s = onStage(a.sel), box = document.getElementById('proof');
    Object.assign(box.style, { top: (s.top + (a.dy || 0)) + 'px', visibility: 'visible' });
  }
  /* A proof card that covers an element of the screen (frame 5: the Progress hero, whose app label reads "days free"). */
  function coverProof() {
    const s = onStage(f.proof.cover), pad = f.proof.pad || 0, box = document.getElementById('proof');
    Object.assign(box.style, { top: (s.top - pad) + 'px', minHeight: (s.bottom - s.top + 2 * pad) + 'px', visibility: 'visible' });
  }
  Promise.all([document.fonts.ready, ...frames.map(iframeReady)]).then(() => {
    if (f.zoom) placeZoom();
    if (f.proof && f.proof.anchor) anchorProof();
    if (f.proof && f.proof.cover) coverProof();
    setTimeout(() => { document.body.dataset.ready = '1'; }, 250);
  });
})();
