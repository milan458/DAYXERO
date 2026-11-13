/* DayXero redesign kit: helpers every screen uses. Requires chars.js first. */
(function () {
  const q = new URLSearchParams(location.search);
  const theme = q.get('theme') === 'dark' ? 'dark' : 'light';
  const still = q.get('still') === '1';
  document.documentElement.setAttribute('data-theme', theme);

  const P = {
    back: 'M15 5l-7 7 7 7', close: 'M6 6l12 12M18 6L6 18', check: 'M5 12.5l4.5 4.5L19 7.5', plus: 'M12 5v14M5 12h14', minus: 'M5 12h14',
    chev: 'M9 6l6 6-6 6', down: 'M6 9l6 6 6-6', play: 'M8 5.5v13l11-6.5z', pause: 'M8 5v14M16 5v14', lock: 'M7 11V8a5 5 0 0110 0v3M5.5 11h13v9h-13z',
    gear: 'M12 15.2a3.2 3.2 0 100-6.4 3.2 3.2 0 000 6.4zM19.4 13.5l1.6 1.2-2 3.4-1.9-.7a7.4 7.4 0 01-1.9 1.1L15 20.5h-4l-.3-2a7.4 7.4 0 01-1.9-1.1l-1.9.7-2-3.4 1.6-1.2a7.6 7.6 0 010-2.9L4.9 9.4l2-3.4 1.9.7a7.4 7.4 0 011.9-1.1l.3-2h4l.3 2a7.4 7.4 0 011.9 1.1l1.9-.7 2 3.4-1.6 1.2a7.6 7.6 0 010 2.9z',
    share: 'M12 15V4M7.5 8.5L12 4l4.5 4.5M5 13v6h14v-6', bell: 'M6 16V11a6 6 0 0112 0v5l1.5 2h-15zM10 20.5h4',
    wave: 'M3 14c2.5-3 5-3 7.5 0s5 3 7.5 0 2.5-1.5 3-1.5M3 9c2.5-3 5-3 7.5 0s5 3 7.5 0', drop: 'M12 3.5c3 4 6 7.2 6 10.5a6 6 0 01-12 0c0-3.3 3-6.5 6-10.5z',
    moon: 'M19 14.5A7.5 7.5 0 019.5 5a7.5 7.5 0 109.5 9.5z', sun: 'M12 16a4 4 0 100-8 4 4 0 000 8zM12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2M5.3 5.3l1.4 1.4M17.3 17.3l1.4 1.4M5.3 18.7l1.4-1.4M17.3 6.7l1.4-1.4',
    leaf: 'M5 19c0-8 5-13 14-14 0 9-5 14-13 14zM5 19l7-7', home: 'M4 10.5L12 4l8 6.5V20h-5.5v-6h-5v6H4z', path: 'M9 4.5L3.5 6.8v12.7L9 17.2l6 2.3 5.5-2.3V4.5L15 6.8zM9 4.5v12.7M15 6.8v12.7',
    chart: 'M5 20V10M12 20V4M19 20v-7', heart: 'M12 20s-7-4.4-7-10a4 4 0 017-2.6A4 4 0 0119 10c0 5.6-7 10-7 10z', lungs: 'M12 4v7M12 11c-2 0-3-1.5-4.5-1.5C5 9.5 4 13 4 16c0 2 1 3.5 3 3.5 2.5 0 5-2 5-6zM12 11c2 0 3-1.5 4.5-1.5C19 9.5 20 13 20 16c0 2-1 3.5-3 3.5-2.5 0-5-2-5-6z',
    cig: 'M3 14h14v4H3zM17 14h4v4h-4zM18 11c0-2 2-2 2-4', vape: 'M9 3h6v4H9zM8 7h8v14H8zM11 11h2', pouch: 'M5 8h14v10a2 2 0 01-2 2H7a2 2 0 01-2-2zM8 8V6a4 4 0 018 0v2',
    patch: 'M5 5h14v14H5zM9 9h6v6H9z', calendar: 'M4 6h16v14H4zM4 10h16M8 3.5v4M16 3.5v4', clock: 'M12 21a9 9 0 100-18 9 9 0 000 18zM12 7v5l3 2',
    headphones: 'M4 15v-3a8 8 0 0116 0v3M4 15h3v5H5a1 1 0 01-1-1zM20 15h-3v5h2a1 1 0 001-1z', note: 'M6 3.5h9l3 3V20.5H6zM9 11h6M9 15h6', star: 'M12 3.5l2.6 5.4 5.9.8-4.3 4.1 1 5.8L12 16.8l-5.2 2.8 1-5.8-4.3-4.1 5.9-.8z',
    flame: 'M12 21c-4 0-6.5-2.6-6.5-6 0-4 4-6 4-10 2 1 6 4 6 8.5 1-1 1.5-2 1.5-3 1.5 1.5 1.5 3 1.5 4.5 0 3.4-2.5 6-6.5 6z', shield: 'M12 3l7 3v6c0 4.5-3 7.5-7 9-4-1.5-7-4.5-7-9V6z',
    hand: 'M8 13V6.5a1.5 1.5 0 013 0V12M11 11V5a1.5 1.5 0 013 0v6M14 11V6.5a1.5 1.5 0 013 0V14c0 4-2.5 7-6 7-2.5 0-4-1.2-5.5-3.5L4 15a1.5 1.5 0 012.5-1.6L8 15',
    eye: 'M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12zM12 15a3 3 0 100-6 3 3 0 000 6z', globe: 'M12 21a9 9 0 100-18 9 9 0 000 18zM3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18',
    card: 'M3.5 6h17v12h-17zM3.5 10h17', text: 'M5 6h14M5 11h14M5 16h9', people: 'M9 11a3.5 3.5 0 100-7 3.5 3.5 0 000 7zM2.5 20c0-3.6 2.9-6 6.5-6s6.5 2.4 6.5 6M16 4.5a3.5 3.5 0 010 6.5M18 14c2 .6 3.5 2.6 3.5 6',
    sparkle: 'M12 3v5M12 16v5M3 12h5M16 12h5', search: 'M10.5 17a6.5 6.5 0 100-13 6.5 6.5 0 000 13zM15.5 15.5L20 20', medal: 'M12 21a6 6 0 100-12 6 6 0 000 12zM9 9.5L6 3h4l2 4 2-4h4l-3 6.5', trophy: 'M7 4h10v5a5 5 0 01-10 0zM7 6H4c0 3 1.5 4.5 3.5 4.5M17 6h3c0 3-1.5 4.5-3.5 4.5M12 14v4M8 20.5h8'
  };
  function icon(name, o = {}) {
    const w = o.w || 2.2, s = o.size || 24, fill = o.fill || 'none';
    return `<svg width="${s}" height="${s}" viewBox="0 0 24 24" fill="${fill}" stroke="currentColor" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="${P[name] || ''}"/></svg>`;
  }

  function statusBar(cls = '') {
    return `<div class="sbar ${cls}"><span>9:41</span><span class="ic">
      <svg width="18" height="12" viewBox="0 0 18 12" fill="currentColor"><rect x="0" y="8" width="3" height="4" rx="1"/><rect x="5" y="5.5" width="3" height="6.5" rx="1"/><rect x="10" y="3" width="3" height="9" rx="1"/><rect x="15" y="0" width="3" height="12" rx="1"/></svg>
      <svg width="16" height="12" viewBox="0 0 16 12" fill="currentColor"><path d="M8 2.2c2.4 0 4.6.9 6.2 2.5l1.3-1.3A10.6 10.6 0 008 .3 10.6 10.6 0 00.5 3.4l1.3 1.3A8.7 8.7 0 018 2.2zm0 3.7c1.4 0 2.7.5 3.6 1.4l1.4-1.3A7 7 0 008 4a7 7 0 00-5 2l1.4 1.3c.9-.9 2.2-1.4 3.6-1.4zM8 9.6l2-2a2.8 2.8 0 00-4 0z"/></svg>
      <svg width="27" height="13" viewBox="0 0 27 13" fill="none"><rect x=".5" y=".5" width="23" height="12" rx="3.5" stroke="currentColor" opacity=".4"/><rect x="2" y="2" width="20" height="9" rx="2.2" fill="currentColor"/><path d="M25 4.5v4c.8-.3 1.3-1.1 1.3-2s-.5-1.7-1.3-2z" fill="currentColor" opacity=".45"/></svg>
    </span></div>`;
  }

  function tabbar(active) {
    const t = (k, label, ic) => `<a class="${active === k ? 'on' : ''}" data-go="${{ today: '016-today-quit', program: '022-program', progress: '036-progress' }[k]}">${icon(ic)}<span>${label}</span></a>`;
    return `<div class="tabfade"></div><nav class="tabbar" style="grid-template-columns:repeat(4,1fr)">
      ${t('today', 'Today', 'home')}${t('program', 'Program', 'path')}
      <a class="sos" data-go="019-sos" aria-label="Craving SOS">${icon('wave', { size: 26, w: 2.4 })}<span>SOS</span></a>
      ${t('progress', 'Progress', 'chart')}</nav>`;
  }

  /* Progress ring. p 0..1. Animates from 0 unless still. */
  function ring(o = {}) {
    const s = o.size || 220, w = o.stroke || 14, r = (s - w) / 2, c = 2 * Math.PI * r, p = Math.max(0, Math.min(1, o.p ?? .5));
    const col = o.color || 'currentColor', tr = o.track || 'var(--track)';
    return `<svg width="${s}" height="${s}" viewBox="0 0 ${s} ${s}" style="transform:rotate(-90deg);display:block">
      <circle cx="${s / 2}" cy="${s / 2}" r="${r}" fill="none" stroke="${tr}" stroke-width="${w}"/>
      <circle class="ringarc" cx="${s / 2}" cy="${s / 2}" r="${r}" fill="none" stroke="${col}" stroke-width="${w}" stroke-linecap="round"
        stroke-dasharray="${c}" style="--c:${c};--to:${c * (1 - p)};stroke-dashoffset:${c * (1 - p)}" data-ring/>
      ${o.dot ? `<circle cx="${s / 2 + r * Math.cos(2 * Math.PI * p)}" cy="${s / 2 + r * Math.sin(2 * Math.PI * p)}" r="${w * .75}" fill="#fff" stroke="${col}" stroke-width="${w * .35}" data-fade style="--d:900ms"/>` : ''}
    </svg>`;
  }

  /* Animated completion check: disc pops, tick draws. */
  function check(o = {}) {
    const s = o.size || 96, col = o.color || 'var(--tick)', fg = o.fg || '#fff';
    return `<svg width="${s}" height="${s}" viewBox="0 0 100 100" aria-label="Done" style="display:block">
      <circle cx="50" cy="50" r="46" fill="${col}" ${o.calm ? 'data-fade' : 'data-pop'} style="transform-origin:50px 50px;--d:${o.d || 0}ms"/>
      <path d="M30 52l13 13 28-30" fill="none" stroke="${fg}" stroke-width="9" stroke-linecap="round" stroke-linejoin="round" class="draw" style="--len:70;--d:${(o.d || 0) + 320}ms;--dur:420ms"/>
    </svg>`;
  }

  /* Badges. kind: prep | xero | day | wave. state: earned | next | locked. One medallion family everywhere. */
  function scallop(cx, cy, r, n, a) { let d = ''; for (let i = 0; i <= n * 2; i++) { const ang = Math.PI * i / n - Math.PI / 2; const rr = i % 2 ? r - a : r; d += (i ? 'L' : 'M') + (cx + rr * Math.cos(ang)).toFixed(1) + ' ' + (cy + rr * Math.sin(ang)).toFixed(1); } return d + 'Z'; }
  let bid = 0;
  function badge(o = {}) {
    const kind = o.kind || 'day', state = o.state || 'earned', s = o.size || 72, n = o.n ?? '', id = 'b' + (++bid);
    const pal = {
      prep: { edge: '#FF9A5C', face: '#FFC38A', hill: '#FFAE73', ink: '#1E1A3A', sun: '#FFD966' },
      xero: { edge: '#F5B83D', face: '#FFD966', hill: '#FFC38A', ink: '#1E1A3A', sun: '#FF7A55' },
      day: { edge: '#FF7155', face: '#FFC38A', hill: '#FF9A6B', ink: '#1E1A3A', sun: '#FFD966' },
      wave: { edge: '#1D3A9E', face: '#2A52DB', hill: '#5C7FF0', ink: '#FFF8EE', sun: '#9CCBFF' },
      night: { edge: '#0D182E', face: '#1C2C4E', hill: '#2C3D6A', ink: '#F6EFE2', sun: '#FFD37A' }
    }[kind];
    const locked = state === 'locked', next = state === 'next';
    const edgePath = kind === 'prep' ? scallop(50, 50, 48, 14, 4) : '';
    const label = String(n).length > 2 ? 22 : 30;
    let art = '';
    if (kind === 'wave') art = `<path d="M8 66c8-7 16-7 24 0s16 7 24 0 16-7 24 0 12 5 16 2v40H8z" fill="${pal.hill}"/><path d="M8 78c8-6 16-6 24 0s16 6 24 0 16-6 24 0 12 5 16 2v30H8z" fill="${pal.edge}" opacity=".7"/>`;
    else if (kind === 'night') art = `<circle cx="70" cy="30" r="9" fill="${pal.sun}"/><path d="M0 72 C30 60 60 80 100 66 V100 H0z" fill="${pal.hill}"/>`;
    else art = `<circle cx="${kind === 'xero' ? 50 : 66}" cy="${kind === 'xero' ? 74 : 64}" r="${kind === 'xero' ? 18 : 12}" fill="${pal.sun}"/><path d="M0 74 C24 62 48 66 70 72 S96 70 100 68 V100 H0z" fill="${pal.hill}"/><path d="M0 84 C30 76 60 90 100 80 V100 H0z" fill="${pal.edge}" opacity=".55"/>`;
    const rays = kind === 'xero' ? `<g class="rays" style="transform-origin:50px 50px" opacity=".9">${Array.from({ length: 12 }, (_, i) => `<path d="M50 -4 L53 8 L47 8Z" fill="#F5B83D" transform="rotate(${i * 30} 50 50)"/>`).join('')}</g>` : '';
    const face = locked
      ? `<circle cx="50" cy="50" r="44" fill="none" stroke="currentColor" stroke-opacity=".35" stroke-width="3" stroke-dasharray="6 6"/>
         <text x="50" y="${n === '' ? 58 : 50}" text-anchor="middle" font-family="Bricolage Grotesque" font-weight="800" font-size="${label}" fill="currentColor" fill-opacity=".45">${n}</text>
         <path d="M43 62v-3a7 7 0 0114 0v3M40 62h20v12H40z" fill="none" stroke="currentColor" stroke-opacity=".45" stroke-width="3" stroke-linejoin="round" transform="translate(0 ${n === '' ? -12 : 2}) scale(1)" />`
      : `${rays}${edgePath ? `<path d="${edgePath}" fill="${pal.edge}"/>` : `<circle cx="50" cy="50" r="47" fill="${pal.edge}"/>`}
         <clipPath id="${id}"><circle cx="50" cy="50" r="39"/></clipPath>
         <circle cx="50" cy="50" r="39" fill="${pal.face}"/><g clip-path="url(#${id})">${art}</g>
         <circle cx="50" cy="50" r="39" fill="none" stroke="#fff" stroke-opacity=".35" stroke-width="2"/>
         <text x="50" y="${kind === 'xero' ? 42 : 50}" text-anchor="middle" dominant-baseline="middle" font-family="Bricolage Grotesque" font-weight="800" font-size="${label}" fill="${pal.ink}" letter-spacing="-1">${n}</text>`;
    const ringNext = next ? `<circle cx="50" cy="50" r="48" fill="none" stroke="currentColor" stroke-opacity=".22" stroke-width="3"/>` + (o.p != null ? `<circle cx="50" cy="50" r="48" fill="none" stroke="var(--fg)" stroke-width="3" stroke-linecap="round" stroke-dasharray="${2 * Math.PI * 48}" stroke-dashoffset="${2 * Math.PI * 48 * (1 - o.p)}" transform="rotate(-90 50 50)"/>` : '') : '';
    const svg = `<svg width="${s}" height="${s}" viewBox="0 0 100 100" style="display:block;overflow:visible" role="img" aria-label="${o.label || ''} ${state}">${next ? `<circle cx="50" cy="50" r="45" fill="currentColor" fill-opacity=".06"/><circle cx="50" cy="50" r="45" fill="none" stroke="${pal.edge}" stroke-width="3.5" stroke-dasharray="6 5"/>${kind === 'xero' ? `<circle cx="50" cy="66" r="13" fill="#F5B83D" fill-opacity=".6"/>` : ''}<text x="50" y="${kind === 'xero' ? 44 : 50}" text-anchor="middle" dominant-baseline="middle" font-family="Bricolage Grotesque" font-weight="800" font-size="${label}" fill="currentColor" letter-spacing="-1">${n}</text>` : face}${ringNext}</svg>`;
    if (o.bare) return svg;
    return `<div class="badge ${o.cls || ''}" ${o.attr || ''}>${svg}${o.label ? `<span class="t-cap">${o.label}</span>` : ''}</div>`;
  }


  /* Night sky for Glim's evenings ("Midnight meadow"): gradient sky, moon with halo, a few stars, three hills, four firefly glows.
     DX.nightSky({w:390, h:430, moonX:336, moonY:236}) ; fades into the night ground at the bottom. Stars twinkle, fireflies drift. */
  let nid = 0;
  function nightSky(o = {}) {
    const w = o.w || 390, h = o.h || 430, id = 'n' + (++nid), mx = o.moonX ?? w - 54, my = o.moonY ?? h * .55;
    const dark = theme === 'dark';
    const sky = dark ? ['#08101F', '#111D38', '#22315A'] : ['#0B1430', '#16244A', '#2C3D6A'], hills = dark ? ['#16233F', '#0F1A31', '#0A1326'] : ['#1C2C4E', '#132240', '#0F1B33'];
    const ground = dark ? '#0A1326' : '#0F1B33', moon = '#F6E7C1', glow = '#FFD37A';
    const st = [[.15, .09], [.38, .07], [.64, .15], [.82, .05], [.1, .26], [.51, .22], [.9, .28], [.28, .35], [.74, .4], [.05, .47], [.46, .14], [.95, .16]];
    const sx = w / 390, hy = y => (y / 430 * h).toFixed(1);
    return `<svg width="${w}" height="${h}" viewBox="0 0 ${w} ${h}" style="display:block" aria-hidden="true"><defs>
      <linearGradient id="s${id}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${sky[0]}"/><stop offset=".55" stop-color="${sky[1]}"/><stop offset="1" stop-color="${sky[2]}"/></linearGradient>
      <radialGradient id="m${id}"><stop offset="0" stop-color="${moon}" stop-opacity=".32"/><stop offset="1" stop-color="${moon}" stop-opacity="0"/></radialGradient>
      <radialGradient id="f${id}"><stop offset="0" stop-color="${glow}" stop-opacity=".9"/><stop offset="1" stop-color="${glow}" stop-opacity="0"/></radialGradient>
      <linearGradient id="g${id}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="${ground}" stop-opacity="0"/><stop offset="1" stop-color="${ground}"/></linearGradient></defs>
      <rect width="${w}" height="${h}" fill="url(#s${id})"/>
      <circle cx="${mx}" cy="${my}" r="70" fill="url(#m${id})"/><circle cx="${mx}" cy="${my}" r="20" fill="${moon}"/>
      ${st.map(([x, y], i) => `<circle cx="${(x * w).toFixed(1)}" cy="${(y * h).toFixed(1)}" r="${i % 3 ? 1.2 : 1.8}" fill="#fff" opacity="${i % 2 ? .5 : .85}">${still ? '' : `<animate attributeName="opacity" values="${i % 2 ? '.5;.15;.5' : '.85;.35;.85'}" dur="${(1.6 + (i % 5) * .35).toFixed(2)}s" repeatCount="indefinite"/>`}</circle>`).join('')}
      <path d="M0 ${hy(300)} C${70 * sx} ${hy(270)} ${140 * sx} ${hy(282)} ${210 * sx} ${hy(296)} S${330 * sx} ${hy(300)} ${w} ${hy(270)} V${h} H0z" fill="${hills[0]}"/>
      <path d="M0 ${hy(340)} C${90 * sx} ${hy(316)} ${170 * sx} ${hy(340)} ${250 * sx} ${hy(332)} S${350 * sx} ${hy(318)} ${w} ${hy(326)} V${h} H0z" fill="${hills[1]}"/>
      <path d="M0 ${hy(380)} C${80 * sx} ${hy(368)} ${160 * sx} ${hy(386)} ${240 * sx} ${hy(378)} S${350 * sx} ${hy(366)} ${w} ${hy(372)} V${h} H0z" fill="${hills[2]}"/>
      ${[[.18, 320], [.3, 352], [.77, 346], [.88, 312]].map(([x, y], i) => `<g>${still ? '' : `<animateTransform attributeName="transform" type="translate" values="0 0;${i % 2 ? 6 : -6} -8;0 0" dur="${5 + i}s" repeatCount="indefinite"/>`}<circle cx="${(x * w).toFixed(1)}" cy="${hy(y)}" r="9" fill="url(#f${id})"/><circle cx="${(x * w).toFixed(1)}" cy="${hy(y)}" r="1.8" fill="${glow}"/></g>`).join('')}
      <rect y="${h - 70}" width="${w}" height="70" fill="url(#g${id})"/></svg>`;
  }

  function charSvg(name, o = {}) {
    const f = window.DXC && window.DXC[name]; if (!f) return '';
    let svg = f(Object.assign({ animate: !still }, o));
    /* Dark mode: horizon scenes become dusk (dimmer, warmer) so heroes never glare at night. */
    /* Dark mode: the sparkles, zzz and breeze marks around characters turn cream so they show on navy. */
    if (name !== 'horizon' && theme === 'dark') svg = svg.replace(/(<g opacity="[^"]*" (?:fill="none" )?stroke=")#24163A/g, '$1#F3E9DE');
    if (name === 'horizon' && theme === 'dark' && !o.noDusk) {
      const id = 'dusk' + Math.random().toString(36).slice(2, 7);
      svg = svg.replace(/<\/svg>\s*$/, `<defs><linearGradient id="${id}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#0E1322" stop-opacity=".62"/><stop offset=".6" stop-color="#0E1322" stop-opacity=".38"/><stop offset="1" stop-color="#0E1322" stop-opacity=".5"/></linearGradient></defs><rect x="-50%" y="-50%" width="200%" height="200%" fill="url(#${id})"/></svg>`);
    }
    return svg;
  }

  /* Count-ups: <span data-count="49" data-prefix="$" data-dec="2" data-from="0"> */
  function counts(root) {
    root.querySelectorAll('[data-count]').forEach(el => {
      const to = parseFloat(el.dataset.count), from = parseFloat(el.dataset.from || 0), dec = +(el.dataset.dec || 0), pre = el.dataset.prefix || '', suf = el.dataset.suffix || '';
      const fmt = v => pre + v.toLocaleString('en-US', { minimumFractionDigits: dec, maximumFractionDigits: dec }) + suf;
      if (still) { el.textContent = fmt(to); return; }
      el.textContent = fmt(from);
      const dur = +(el.dataset.dur || 850), delay = +(el.dataset.delay || 300); const t0 = performance.now() + delay;
      const step = t => { const k = Math.min(1, Math.max(0, (t - t0) / dur)); const e = 1 - Math.pow(1 - k, 3); el.textContent = fmt(from + (to - from) * e); if (k < 1) requestAnimationFrame(step); };
      requestAnimationFrame(step);
    });
  }

  /* Rings animate from empty to their value. */
  function rings(root) {
    root.querySelectorAll('[data-ring]').forEach(el => {
      if (still) return;
      const c = el.style.getPropertyValue('--c'), to = el.style.getPropertyValue('--to');
      el.style.transition = 'none'; el.style.strokeDashoffset = c;
      requestAnimationFrame(() => requestAnimationFrame(() => { el.style.transition = 'stroke-dashoffset 1400ms cubic-bezier(.2,.8,.2,1) 250ms'; el.style.strokeDashoffset = to; }));
    });
  }

  /* Hold-to-confirm buttons: <button class="btn" data-hold="1500" data-done="Quit Day set"> */
  function holds(root) {
    root.querySelectorAll('[data-hold]').forEach(btn => {
      if (!btn.querySelector('.fill')) { const lbl = btn.innerHTML; btn.innerHTML = `<span class="fill"></span><span class="lbl">${lbl}</span>`; }
      const ms = +btn.dataset.hold, fill = btn.querySelector('.fill'), lbl = btn.querySelector('.lbl'), orig = lbl.innerHTML;
      let timer = null;
      const finish = () => { btn.classList.add('done-state'); lbl.innerHTML = icon('check', { size: 20, w: 3 }) + (btn.dataset.done || 'Done'); btn.dispatchEvent(new CustomEvent('held', { bubbles: true })); };
      const start = () => { if (btn.classList.contains('done-state')) return; fill.style.transition = `transform ${ms}ms linear`; fill.style.transform = 'scaleX(1)'; timer = setTimeout(finish, ms); };
      const stop = () => { if (btn.classList.contains('done-state')) return; clearTimeout(timer); fill.style.transition = 'transform 250ms ease-out'; fill.style.transform = 'scaleX(0)'; };
      btn.onpointerdown = start; btn.onpointerup = stop; btn.onpointerleave = stop;
      btn._reset = () => { clearTimeout(timer); btn.classList.remove('done-state'); lbl.innerHTML = orig; fill.style.transition = 'none'; fill.style.transform = 'scaleX(0)'; };
      btn._auto = () => { btn.classList.add('press'); start(); setTimeout(() => btn.classList.remove('press'), ms); };
      btn._finish = () => { fill.style.transition = 'none'; fill.style.transform = 'scaleX(1)'; finish(); };
    });
  }

  /* Wire links: data-go="019-sos" keeps theme. */
  function links(root) {
    root.querySelectorAll('[data-go]').forEach(a => {
      const href = a.dataset.go + '.html' + (theme === 'dark' ? '?theme=dark' : '');
      if (a.tagName === 'A') a.setAttribute('href', href); else a.addEventListener('click', () => { location.href = href; });
      a.style.cursor = 'pointer';
    });
  }

  let timers = [];
  function play() {
    timers.forEach(clearTimeout); timers = [];
    document.body.classList.remove('play');
    document.querySelectorAll('[data-hold]').forEach(b => b._reset && b._reset());
    void document.body.offsetWidth;
    document.body.classList.add('play');
    counts(document); rings(document);
    if (!still) {
      document.querySelectorAll('[data-autohold]').forEach(b => timers.push(setTimeout(() => b._auto && b._auto(), +b.dataset.autohold)));
      (window.DX_SCRIPT || []).forEach(fn => fn(timers));
    }
  }

  function init() {
    if (still) document.body.classList.add('still');
    document.querySelectorAll('.screen').forEach(sc => { if (!sc.querySelector('.sbar') && !sc.hasAttribute('data-nostatus')) sc.insertAdjacentHTML('afterbegin', statusBar(sc.dataset.status || '')); });
    holds(document); links(document);
    const go = () => { play(); if (still) {
      document.querySelectorAll('[data-autohold]').forEach(b => b._finish && b._finish());   // stills show the held, final state
      (window.DX_BEATS || []).forEach(fn => fn()); (window.DX_STILL || []).forEach(fn => fn()); document.body.classList.add('ready'); } };
    (document.fonts && document.fonts.ready ? document.fonts.ready : Promise.resolve()).then(() => requestAnimationFrame(go));
    window.addEventListener('message', e => { if (e.data === 'replay') play(); });
    document.addEventListener('keydown', e => { if (e.key === 'r') play(); });
  }

  window.DX = { icon, statusBar, tabbar, ring, check, badge, nightSky, char: charSvg, theme, still, play, init,
    after(ms, fn) { (window.DX_SCRIPT = window.DX_SCRIPT || []).push(t => t.push(setTimeout(fn, ms))); },
    /* beat: a scripted step that also runs (instantly) in still renders, so stills show the final state. */
    beat(ms, fn) { (window.DX_SCRIPT = window.DX_SCRIPT || []).push(t => t.push(setTimeout(fn, ms))); (window.DX_BEATS = window.DX_BEATS || []).push(fn); },
    onStill(fn) { (window.DX_STILL = window.DX_STILL || []).push(fn); } };
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', init); else init();
})();
