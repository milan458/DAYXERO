/* DayXero App Store screenshots: the ten frames as data, plus the builder that turns one into a page.
   Edit copy, grounds, phone positions and breakouts here; render with `node render.mjs` (see README.md).

   Persona (design system section 7, code-true values from decision 17): Sam, cigarettes (12 a day) and a vape, triggers
   coffee then stress, reason "To keep up with Maya at the park.", Quit Day Fri, Nov 6, "today" Sun, Nov 8 = Day 3.
   Each app screen states its time in the status bar (?time=) and shows that time's numbers:
     07:30  25 cigarettes not smoked, $15.02 kept ($15 where the app rounds to whole dollars)
     09:40  26 cigarettes not smoked, $15.65 kept, 15 waves ridden out (after the morning coffee wave)
   Finale: the Week 4 row of section 7 (28 days, 61 waves, 26 check-ins, $196, 336 cigarettes). */

window.FRAMES = [
  { // 1 ── the promise and the three products. Its dawn horizon runs on into frame 2 (flat phones, no tilt).
    id: '01', ground: 'apricot',
    title: 'Quit nicotine on a<br>day you <mk>choose</mk>',
    sub: 'Cigarettes · Vapes · Pouches',
    fine: 'Requires a DayXero Pro subscription.',
    screen: 'today.html', time: '7:30',
    phone: { left: 16, top: 270, k: 0.82 },
    art: 'dawn', pano: 0
  },
  { // 2 ── the mechanic nobody else shows: prep week, then Quit Day
    id: '02', ground: 'apricot',
    title: 'Prep for 7 days.<br>Then <mk>quit.</mk>',
    sub: 'Keep using as normal while you get ready for Quit Day.',
    screen: 'quitday.html', time: '9:41',
    phone: { left: 45, top: 270, k: 0.84 },
    zoom: { sel: '.card.wk', scale: 1.12, dy: 40 },
    art: 'dawn', pano: -440
  },
  { // 3 ── Craving SOS with Jelli
    id: '03', ground: 'ocean',
    title: 'A craving?<br>Ride it <mk>out</mk> with Jelli.', size: 42,
    sub: 'Most cravings pass within a few minutes.',
    screen: 'sos.html', time: '9:39',
    phone: { left: 82, top: 270, k: 0.82 },
    art: 'sea'
  },
  { // 4 ── the slip rule, the most original message in the category
    id: '04', ground: 'cream',
    title: 'Slipped?<br>Nothing <mk>resets.</mk>',
    sub: 'Your days clear stay.<br>You get a plan for next time.',
    screen: 'slip.html', time: '9:39',
    phone: { left: 45, top: 270, k: 0.84 },
    zoom: { sel: '.grid2.kept', scale: 1.14, dy: 20 }
  },
  { // 5 ── the daily session
    id: '05', ground: 'mint',
    title: '3 minutes<br>a <mk>day</mk>',
    sub: 'One short lesson a day, in order. No rush.',
    screen: 'lesson.html', time: '2:00',
    phone: { left: 45, top: 270, k: 0.84 },
    card: { left: 22, top: 716, width: 396, html: `
      <div class="week">
        <div class="h"><b>Week 1</b><span>Through the hardest stretch.</span></div>
        <div class="r"><span class="ic done">{check}</span><span class="t"><b>Look after the basics</b><span>Day 2 · done</span></span></div>
        <div class="r today"><span class="ic now">{play}</span><span class="t"><b>The noisy passengers</b><span>Day 3 · today · 3 min</span></span></div>
        <div class="r"><span class="ic lock">{lock}</span><span class="t"><b>Lower the bar</b><span>Day 4 · opens tomorrow</span></span></div>
      </div>` }
  },
  { // 6 ── what you've kept
    id: '06', ground: 'apricot',
    title: 'See what<br>you\'ve <mk>kept</mk>',
    sub: 'Money, cigarettes not smoked and waves ridden out.',
    screen: 'progress.html', time: '9:40',
    phone: { left: 45, top: 270, k: 0.84 },
    card: { left: 22, width: 396, cover: ['.hero-card', '.quiet'], pad: 8, html: `
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
  { // 7 ── health changes, quoted from health-timeline.json with the source
    id: '07', ground: 'cream',
    title: 'What\'s changing<br>in your <mk>body</mk>',
    sub: 'Timings quoted from the American Cancer Society.',
    screen: 'health.html', time: '9:40',
    phone: { left: 45, top: 270, k: 0.84 },
    card: { left: 22, top: 610, width: 396, html: `
      <div class="fact">
        <span class="k"><i></i>Happening now · A few days</span>
        <b>Carbon monoxide in your blood drops to normal</b>
        <span class="l">More oxygen reaches your body.</span>
        <span class="src">Source: American Cancer Society</span>
      </div>` }
  },
  { // 8 ── evenings, with Glim (the dark shot)
    id: '08', ground: 'night',
    title: 'Hard evening?<br>Glim checks <mk>in.</mk>',
    sub: 'A one-minute check-in, then rest.',
    screen: 'checkin.html', time: '9:30',
    phone: { left: 45, top: 270, k: 0.84 },
    zoom: { sel: '.faces', scale: 1.14, pad: 10, radius: 26, dy: 10 }
  },
  { // 9 ── Lock Screen widgets and the SOS Live Activity (no benchmarked set shows a Live Activity)
    id: '09', ground: 'mint',
    title: 'SOS on your<br><mk>Lock Screen</mk>',
    sub: 'Start from a widget. Ride it out from the Live Activity.',
    screen: 'lock.html', time: '',
    phone: { left: 45, top: 270, k: 0.84 },
    zoom: { sel: '#la', scale: 1.14, dy: 0 }
  },
  { // 10 ── the finale, and a quiet privacy line
    id: '10', ground: 'sun',
    title: '28 days.<br>Clear <mk>skies.</mk>',
    sub: 'Private on this phone. No guilt, ever.',
    fine: 'Requires a DayXero Pro subscription.',
    screen: 'finale.html', time: '9:41',
    phone: { left: 45, top: 270, k: 0.84 },
    art: 'confetti'
  }
];

/* ---------------------------------------------------------------- builder */
(function () {
  const q = new URLSearchParams(location.search);
  const f = window.FRAMES.find(x => x.id === (q.get('f') || '01').padStart(2, '0'));
  const scale = Number(q.get('scale') || 1);
  const stage = document.querySelector('.stage');
  stage.dataset.ground = f.ground;
  stage.style.transform = `scale(${scale})`;
  stage.style.height = (window.innerHeight / scale) + 'px';
  const H = window.innerHeight / scale;

  const MK = `<svg viewBox="0 0 200 16" preserveAspectRatio="none" aria-hidden="true"><path d="M3 10 C40 4 90 5 122 7 C152 9 178 11 197 4"/></svg>`;
  const mk = s => s.replace(/<mk>(.*?)<\/mk>/g, `<span class="mk">$1${MK}</span>`);
  const ICON = {
    check: '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg>',
    play: '<svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5.5v13l11-6.5z"/></svg>',
    lock: '<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="M7 11V8a5 5 0 0110 0v3M5.5 11h13v9h-13z"/></svg>'
  };
  const fill = s => s.replace(/\{(check|play|lock)\}/g, (m, k) => ICON[k]);
  const src = `app/screens/${f.screen}?still=1${f.time ? '&time=' + encodeURIComponent(f.time) : ''}`;

  let html = `<div class="cap"><h1${f.size ? ` style="font-size:${f.size}px"` : ''}>${mk(f.title)}</h1>${f.sub ? `<p class="sub">${f.sub}</p>` : ''}${f.fine ? `<p class="fine">${f.fine}</p>` : ''}</div>`;
  const p = f.phone;
  html += `<div class="phone" style="left:${p.left}px;top:${p.top}px;--k:${p.k}"><div class="body">
      <div class="glass"><iframe src="${src}" title="DayXero screen" scrolling="no"></iframe></div>
      <div class="island"></div></div>
      <span class="btn-l" style="top:150px;height:30px"></span><span class="btn-l" style="top:205px;height:56px"></span><span class="btn-l" style="top:272px;height:56px"></span>
      <span class="btn-r" style="top:230px;height:88px"></span></div>`;
  if (f.zoom) html += `<div class="zoom" id="zoom" style="visibility:hidden"><iframe src="${src}" title="" scrolling="no"></iframe></div>`;
  if (f.card) html += `<div class="card-out" id="card" style="left:${f.card.left}px;top:${f.card.top || 0}px;width:${f.card.width}px${f.card.cover ? ';visibility:hidden' : ''}">${fill(f.card.html)}</div>`;
  stage.innerHTML = html;
  /* frame 6: Xero's sky in the card, at Day 3's clarity (20 + 2.8 x days clear = 28) */
  stage.querySelectorAll('[data-sky]').forEach(el => el.insertAdjacentHTML('afterbegin',
    window.DXC.horizon({ scene: 'dawn', clarity: 28, w: 368, h: 112, fit: 'xMidYMax slice', animate: false }) +
    `<span class="x">${window.DXC.xero({ mood: 'hello', stage: 1, size: 84, animate: false })}</span>`));

  if (f.art === 'dawn') dawn(stage, f.pano, H);
  if (f.art === 'sea') sea(stage, H);
  if (f.art === 'confetti') confetti(stage);

  /* Frames 1 and 2: one 880 px dawn horizon across both (the phones stay flat). Xero, the sun of Day Zero, rises over
     his hills in frame 1; the same hills run on under frame 2, under the prep-week phone.
     The far ridge sits behind the phone; the near ridges sit in front of it. */
  function dawn(stage, dx, H) {
    const BH = 330, top = H - BH;
    const back = `
      <defs><radialGradient id="pg"><stop offset="0" stop-color="#FFF8D6" stop-opacity="1"/><stop offset=".35" stop-color="#FFE7A6" stop-opacity=".8"/><stop offset="1" stop-color="#FFD27A" stop-opacity="0"/></radialGradient>
      <filter id="pl" x="-5%" y="-30%" width="110%" height="160%"><feDropShadow dx="0" dy="-3" stdDeviation="4" flood-color="#1A0B2E" flood-opacity=".18"/></filter></defs>
      <circle cx="350" cy="150" r="190" fill="url(#pg)"/>
      <path filter="url(#pl)" d="M0 150 C80 118 170 126 250 138 C330 150 400 172 470 170 C560 167 640 140 720 146 C790 152 840 162 880 158 L880 330 L0 330 Z" fill="#FFB27E"/>
      <path filter="url(#pl)" d="M0 214 C90 188 200 192 300 206 C380 218 430 238 520 246 C620 256 720 244 800 248 C840 250 860 252 880 250 L880 330 L0 330 Z" fill="#FF9D6E"/>`;
    const front = `
      <defs><filter id="pf" x="-5%" y="-30%" width="110%" height="160%"><feDropShadow dx="0" dy="-3" stdDeviation="4" flood-color="#1A0B2E" flood-opacity=".24"/></filter>
      <linearGradient id="sh" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".2"/><stop offset=".35" stop-color="#fff" stop-opacity="0"/></linearGradient></defs>
      <path filter="url(#pf)" d="M0 262 C80 246 170 244 240 226 C290 212 330 194 380 194 C420 194 446 208 470 228 C500 250 540 256 600 256 C700 256 800 250 880 252 L880 330 L0 330 Z" fill="#E85A3E"/>
      <path d="M0 262 C80 246 170 244 240 226 C290 212 330 194 380 194 C420 194 446 208 470 228 C500 250 540 256 600 256 C700 256 800 250 880 252 L880 330 L0 330 Z" fill="url(#sh)"/>
      <path filter="url(#pf)" d="M0 302 C140 290 300 294 440 302 C600 310 760 298 880 302 L880 330 L0 330 Z" fill="#C2402A"/>`;
    const svg = (inner) => `<svg width="880" height="${BH}" viewBox="0 0 880 ${BH}" style="left:${dx}px;top:${top}px">${inner}</svg>`;
    stage.insertAdjacentHTML('beforeend', `<div class="art back">${svg(back)}</div>`);
    if (dx === 0) stage.insertAdjacentHTML('beforeend', ch('xero', { mood: 'hello', stage: 1, size: 176 }, 262, top + 62, 4));
    stage.insertAdjacentHTML('beforeend', `<div class="art front">${svg(front)}</div>`);
  }

  /* Frame 3: Jelli rides the swell at the foot of the frame, in front of the phone. */
  function sea(stage, H) {
    const BH = 150, top = H - BH;
    const w = (y, d, c, extra = '') => `<path filter="url(#sf)" d="M-20 ${y} C60 ${y - d} 140 ${y + d} 220 ${y} C300 ${y - d} 380 ${y + d} 460 ${y} L460 ${BH} L-20 ${BH} Z" fill="${c}"/>${extra}`;
    const svg = (inner) => `<svg width="440" height="${BH}" viewBox="0 0 440 ${BH}" style="left:0;top:${top}px"><defs><filter id="sf" x="-5%" y="-30%" width="110%" height="160%"><feDropShadow dx="0" dy="-3" stdDeviation="4" flood-color="#06102E" flood-opacity=".3"/></filter></defs>${inner}</svg>`;
    stage.insertAdjacentHTML('beforeend', `<div class="art back">${svg(w(64, 10, '#2E5CC8'))}</div>`);
    stage.insertAdjacentHTML('beforeend', ch('jelli', { mood: 'breathe', stage: 1, size: 132 }, -18, top - 46, 5));
    stage.insertAdjacentHTML('beforeend', `<div class="art" style="z-index:6">${svg(w(104, 9, '#3A6BD6', '<path d="M392 98 C404 85 424 83 434 95 C422 92 412 96 406 104 Z" fill="#FFF8EE" opacity=".9"/>') + w(130, 7, '#244FBE'))}</div>`);
  }

  function ch(name, o, x, y, z) {
    return `<div class="char" style="left:${x}px;top:${y}px;z-index:${z}">${window.DXC[name](Object.assign({ animate: false }, o))}</div>`;
  }

  /* Frame 10: confetti, the finale's one celebration (design system 4.1, 5.2). Resting pieces, never over the caption. */
  function confetti(stage) {
    const C = ['#FF7A55', '#2A52DB', '#4A3596', '#0F6E43', '#FF8FB8', '#FFF8EE'];
    const P = [[22, 300, 0, 24], [30, 420, 1, -30], [16, 560, 2, 0], [404, 318, 3, 40], [418, 450, 4, -16], [410, 600, 5, 0], [28, 700, 3, 60], [414, 740, 0, -50], [20, 36, 4, 18], [418, 40, 1, -24], [60, 236, 5, 0], [384, 236, 2, 30]];
    const s = P.map(([x, y, c, r], i) => i % 3 === 2 ? `<circle cx="${x}" cy="${y}" r="5" fill="${C[c]}"/>`
      : `<rect x="${x - 4.5}" y="${y - 8}" width="9" height="16" rx="2.5" fill="${C[c]}" transform="rotate(${r} ${x} ${y})"/>`).join('');
    stage.insertAdjacentHTML('beforeend', `<div class="art back" style="z-index:3"><svg width="440" height="956" viewBox="0 0 440 956" style="left:0;top:0">${s}</svg></div>`);
  }

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
    Object.assign(card.style, { top: top + 'px', minHeight: h + 'px', display: 'flex', flexDirection: 'column', visibility: 'visible' });
  }
  Promise.all([document.fonts.ready, ...frames.map(iframeReady)]).then(() => {
    if (f.zoom) placeZoom();
    if (f.card && f.card.cover) coverCard();
    setTimeout(() => { document.body.dataset.ready = '1'; }, 250);
  });
})();
