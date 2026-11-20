/* DayXero App Store screenshots, Direction C: "The sky clears".
   One continuous landscape, 4400 x 956 CSS px (13200 x 2868 at 3x), sliced into ten 440 px frames.
   Every frame draws the same SVG, shifted left by 440 px per frame, so the art meets exactly at each seam.

   Left to right the journey runs: hazy dawn (Xero rises) > the prep path to Quit Day > the sea (Jelli) >
   the day's land (lessons, progress, body) > dusk (Xero sets) > night (Glim) > the next dawn, fully clear.
   Haze follows "the sky clears as you do" (design system section 3): clarity 20 at frame 1's centre, 100 at frame 10's.

   PANO.svg('back')  : sky, sun glows, clouds, stars, far hills, sea, mid and near hills, the risen and setting Xero
   PANO.svg('front') : the foreground ridge, the waves in front, the path, Jelli, Glim, the finale crew, confetti
   Phones sit between the two layers. */
(function () {
  'use strict';
  const W = 4400, H = 956, FW = 440;

  /* ------------------------------------------------------------ colour (OKLab mixing, so ramps never go muddy) */
  const h2r = h => [1, 3, 5].map(i => parseInt(h.slice(i, i + 2), 16));
  const lin = c => { c /= 255; return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4; };
  const unl = c => { c = c <= 0.0031308 ? 12.92 * c : 1.055 * c ** (1 / 2.4) - 0.055; return Math.round(Math.max(0, Math.min(1, c)) * 255); };
  function lab(h) {
    const [r, g, b] = h2r(h).map(lin);
    const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
    const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
    const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
    return [0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s, 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s, 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s];
  }
  function hex([L, A, B]) {
    const l = (L + 0.3963377774 * A + 0.2158037573 * B) ** 3, m = (L - 0.1055613458 * A - 0.0638541728 * B) ** 3, s = (L - 0.0894841775 * A - 1.2914855480 * B) ** 3;
    const rgb = [4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s, -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s, -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s];
    return '#' + rgb.map(unl).map(v => v.toString(16).padStart(2, '0')).join('').toUpperCase();
  }
  const mix = (a, b, t) => { const A = lab(a), B = lab(b); return hex(A.map((v, i) => v + (B[i] - v) * t)); };
  const smooth = t => t <= 0 ? 0 : t >= 1 ? 1 : t * t * (3 - 2 * t);
  /* a colour ramp along x: keys [[x, '#hex'], ...], eased between keys */
  const ramp = keys => x => {
    if (x <= keys[0][0]) return keys[0][1];
    for (let i = 1; i < keys.length; i++) if (x <= keys[i][0]) {
      const [x0, c0] = keys[i - 1], [x1, c1] = keys[i];
      return mix(c0, c1, smooth((x - x0) / (x1 - x0)));
    }
    return keys[keys.length - 1][1];
  };

  /* ------------------------------------------------------------ the clearing: clarity 20 > 100 across the set */
  const clarity = x => Math.max(20, Math.min(100, 20 + 80 * (x - 220) / 3960));
  const fog = x => 1 - clarity(x) / 100;
  const hazeC = ramp([[0, '#F6EEE4'], [2900, '#F6EEE4'], [3150, '#EAD8EE'], [3500, '#9C8ED0'], [3900, '#9C8ED0'], [4050, '#F6EEE4']]);
  /* a hazed colour: depth 0 (foreground) .. 1 (sky). Haze lifts with clarity, more on far layers. */
  const hz = (c, x, depth) => mix(c, hazeC(x), Math.min(0.92, fog(x) * (0.3 + 0.55 * depth)));

  /* ------------------------------------------------------------ palettes along the journey */
  // sky: zenith (top) and horizon colours. The caption band (y < 260) keeps the zenith colour; text colour per frame
  // is chosen against it and measured (see README: ink on frames 1-7 and 10, cream on 8 and 9).
  const zen = ramp([[0, '#FF8A66'], [440, '#FF9A70'], [720, '#FFB487'], [990, '#86BDF6'], [1100, '#5CA8F7'], [1540, '#62ACF8'],
    [1980, '#70B6FA'], [2420, '#7BBAF4'], [2780, '#8CBBEA'], [3010, '#A8B6E2'], [3160, '#4A3592'], [3420, '#2B2170'],
    [3620, '#1A1450'], [3895, '#1B1552'], [4030, '#FF8360'], [4400, '#FF8A64']]);
  const hor = ramp([[0, '#FFD29E'], [440, '#FFDCA6'], [760, '#FFE6C0'], [990, '#E4F0F7'], [1100, '#D3ECFF'], [1540, '#D8F0FF'],
    [1980, '#E4F6EF'], [2420, '#FFF0D4'], [2800, '#FFD6A2'], [3020, '#FFBE88'], [3200, '#F49AA6'], [3420, '#B572B8'],
    [3640, '#4E3A9C'], [3880, '#5D3FA4'], [3990, '#F7A08A'], [4100, '#FFE3BC'], [4400, '#FFE8C4']]);
  const land = {
    far: ramp([[0, '#FFB582'], [760, '#FFBE8C'], [960, '#93B4E6'], [1700, '#93B4E6'], [1880, '#A9DDB8'], [2780, '#B9DCB0'], [3000, '#E9B990'], [3170, '#B572C9'], [3420, '#7350C6'], [3620, '#5A3CC4'], [3900, '#5A3CC4'], [4050, '#FFB27E']]),
    mid: ramp([[0, '#FF9A6C'], [800, '#FF9A6C'], [1760, '#79C99A'], [2780, '#86C493'], [3000, '#C59A72'], [3170, '#8E55BF'], [3620, '#432AA6'], [3900, '#432AA6'], [4050, '#FF9D6E']]),
    near: ramp([[0, '#F07450'], [800, '#F07450'], [1760, '#44AE7C'], [2780, '#4FA676'], [3000, '#8E7A5E'], [3170, '#6A3AA8'], [3620, '#2F1C84'], [3900, '#2F1C84'], [4050, '#FF7A55']]),
    front: ramp([[0, '#CB4A31'], [800, '#CB4A31'], [1760, '#2C8A60'], [2780, '#2F8360'], [3000, '#5D5A4A'], [3170, '#4A2588'], [3620, '#1C1160'], [3900, '#1C1160'], [4050, '#E85A3E']])
  };

  /* ------------------------------------------------------------ geometry: ridge lines as functions of x */
  const SEA0 = 800, SEA1 = 1830; // sea from frame 2's right edge to frame 5's left edge
  const n = (x, parts) => parts.reduce((s, [a, f, p]) => s + a * Math.sin(x * f + p), 0);
  const bump = (x, c, w, h) => h * Math.exp(-(((x - c) / w) ** 2));
  /* sea envelope: 0 on land, 1 at sea; each layer's shore sits at its own x, so headlands overlap in depth */
  const sea = (x, a0, a1, b0, b1) => Math.min(smooth((x - a0) / (a1 - a0)), 1 - smooth((x - b0) / (b1 - b0)));
  const HORIZON = 654;
  const ridge = {
    far: x => {
      const landY = 596 + n(x, [[20, 0.0041, 0.4], [11, 0.0113, 2.1], [6, 0.027, 1.3]]) - bump(x, 2420, 260, 26) - bump(x, 3080, 180, 18);
      const isl = HORIZON + 4 - bump(x, 1010, 70, 34) - bump(x, 1090, 40, 14) - bump(x, 1600, 90, 30) - bump(x, 1690, 50, 18);
      return landY + (isl - landY) * sea(x, 860, 980, 1560, 1700);
    },
    mid: x => {
      const y = 676 + n(x, [[18, 0.0052, 1.7], [9, 0.0141, 0.3], [5, 0.031, 2.2]]) - bump(x, 440, 120, 14);
      return y + (1010 - y) * sea(x, 770, 930, 1700, 1830);
    },
    near: x => {
      const y = 752 + n(x, [[20, 0.0047, 2.9], [10, 0.0123, 1.1], [5, 0.029, 0.6]]) - bump(x, 2200, 70, 24) - bump(x, 2640, 70, 20) + bump(x, 440, 90, 6);
      return y + (1040 - y) * sea(x, 820, 950, 1730, 1850);
    },
    front: x => {
      // dips under the phones and rises in the gaps between them, where the crew stands
      const gap = [...Array(11)].reduce((s, _, i) => s + bump(x, i * FW, 95, 1), 0);
      const y = 878 + n(x, [[10, 0.0061, 0.9], [6, 0.0157, 2.4], [3, 0.037, 1.0]]) - 46 * gap;
      return y + (1080 - y) * sea(x, 860, 990, 1740, 1880);
    }
  };
  /* a smooth closed path under a ridge function (Catmull-Rom through samples) */
  function ridgePath(f, x0 = -20, x1 = W + 20, step = 10, bottom = H + 20) {
    const pts = []; for (let x = x0; x <= x1; x += step) pts.push([x, f(x)]);
    let d = `M${x0} ${bottom} L${pts[0][0]} ${pts[0][1].toFixed(1)}`;
    for (let i = 0; i < pts.length - 1; i++) {
      const p0 = pts[Math.max(0, i - 1)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[Math.min(pts.length - 1, i + 2)];
      const c1 = [p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6], c2 = [p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6];
      d += ` C${c1[0].toFixed(1)} ${c1[1].toFixed(1)} ${c2[0].toFixed(1)} ${c2[1].toFixed(1)} ${p2[0]} ${p2[1].toFixed(1)}`;
    }
    return d + ` L${x1} ${bottom} Z`;
  }
  /* a horizontal gradient along the whole panorama, sampled every 44 px */
  function hgrad(id, f, step = 44) {
    let s = ''; for (let x = 0; x <= W; x += step) s += `<stop offset="${(x / W).toFixed(4)}" stop-color="${f(x)}"/>`;
    return `<linearGradient id="${id}" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="${W}" y2="0">${s}</linearGradient>`;
  }
  const lift = (id, o) => `<filter id="${id}" x="-1%" y="-40%" width="102%" height="180%"><feDropShadow dx="0" dy="-3" stdDeviation="4" flood-color="#1A0B2E" flood-opacity="${o}"/></filter>`;

  /* ------------------------------------------------------------ characters, placed in panorama coordinates */
  function ch(name, o, cx, top) {
    const svg = window.DXC[name](Object.assign({ animate: false }, o));
    return svg.replace('<svg ', `<svg x="${(cx - o.size / 2).toFixed(1)}" y="${top}" overflow="visible" `);
  }

  /* ------------------------------------------------------------ the layers */
  function back() {
    const defs = [
      hgrad('zen', x => hz(zen(x), x, 1)), hgrad('hor', x => hz(hor(x), x, 1)),
      `<linearGradient id="vm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#000"/><stop offset=".25" stop-color="#000"/><stop offset=".69" stop-color="#fff"/><stop offset="1" stop-color="#fff"/></linearGradient>`,
      `<mask id="skym" maskUnits="userSpaceOnUse" x="0" y="0" width="${W}" height="${H}"><rect width="${W}" height="${H}" fill="url(#vm)"/></mask>`,
      hgrad('lfar', x => hz(land.far(x), x, 0.85)), hgrad('lmid', x => hz(land.mid(x), x, 0.6)), hgrad('lnear', x => hz(land.near(x), x, 0.4)),
      hgrad('sea0', x => hz('#5E9BF2', x, 0.65)), hgrad('sea1', x => hz('#8CC2FF', x, 0.6)), hgrad('sea2', x => hz('#4E8EF2', x, 0.42)),
      `<linearGradient id="seav" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2F72F2" stop-opacity="0"/><stop offset="1" stop-color="#1C4FCC" stop-opacity=".55"/></linearGradient>`,
      `<radialGradient id="glow"><stop offset="0" stop-color="#FFF8D6" stop-opacity=".95"/><stop offset=".3" stop-color="#FFE7A6" stop-opacity=".6"/><stop offset="1" stop-color="#FFD27A" stop-opacity="0"/></radialGradient>`,
      `<radialGradient id="glowp"><stop offset="0" stop-color="#FFD9A8" stop-opacity=".9"/><stop offset=".35" stop-color="#FFB38A" stop-opacity=".45"/><stop offset="1" stop-color="#F49AA6" stop-opacity="0"/></radialGradient>`,
      `<radialGradient id="glowm"><stop offset="0" stop-color="#FFF1C2" stop-opacity=".45"/><stop offset="1" stop-color="#FFF1C2" stop-opacity="0"/></radialGradient>`,
      `<radialGradient id="sun" cx=".38" cy=".32" r=".75"><stop offset="0" stop-color="#FFF6C8"/><stop offset="1" stop-color="#FFC23A"/></radialGradient>`,
      `<filter id="soft" x="-30%" y="-60%" width="160%" height="220%"><feGaussianBlur stdDeviation="5"/></filter>`,
      `<filter id="softer" x="-30%" y="-60%" width="160%" height="220%"><feGaussianBlur stdDeviation="14"/></filter>`,
      lift('lf', 0.14), lift('lm', 0.18), lift('ln', 0.22)
    ].join('');

    let s = `<rect width="${W}" height="${H}" fill="url(#zen)"/><rect width="${W}" height="${H}" fill="url(#hor)" mask="url(#skym)"/>`;

    // glows: dawn behind Xero (seam 1/2), the day sun (seam 4/5), sunset behind Xero (seam 7/8), moonlight, the clear dawn (seam 9/10)
    s += `<circle cx="440" cy="560" r="300" fill="url(#glow)" opacity=".85"/>`;
    s += `<circle cx="1760" cy="420" r="150" fill="url(#glow)" opacity=".7"/><circle cx="1760" cy="420" r="38" fill="url(#sun)"/>`;
    s += `<circle cx="3080" cy="600" r="260" fill="url(#glowp)"/>`;
    s += `<circle cx="3960" cy="560" r="300" fill="url(#glow)" opacity=".95"/>`;

    // stars: dusk to night, kept out of the caption blocks (only in the seam gaps above y 260)
    let stars = '', seed = 7;
    const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
    for (let i = 0; i < 150; i++) {
      const x = 3120 + rnd() * 860, y = 20 + rnd() * 560, r = rnd() < 0.2 ? 1.9 : 1.1 + rnd() * 0.5;
      const inCap = y < 268 && ((x % FW) > 14 && (x % FW) < 426);
      const fade = smooth((x - 3150) / 260) * (1 - smooth((x - 3900) / 70));
      if (!inCap && fade > 0.05) stars += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${r.toFixed(2)}" fill="#FFF8EE" opacity="${(fade * (0.5 + rnd() * 0.5)).toFixed(2)}"/>`;
    }
    s += stars;
    // the moon, in the gap between frames 8 and 9, above Glim
    s += `<circle cx="3520" cy="360" r="110" fill="url(#glowm)"/><path d="M3520 326 A34 34 0 1 0 3552 378 A28 28 0 1 1 3520 326 Z" fill="#FFF1C2"/>`;

    // clouds: paper clouds, more and softer where the haze is thick
    const cloud = (x, y, k, c, o) => `<g transform="translate(${x} ${y}) scale(${k})" fill="${c}" opacity="${o}" filter="url(#soft)"><ellipse cx="0" cy="0" rx="62" ry="15"/><ellipse cx="-22" cy="-11" rx="30" ry="15"/><ellipse cx="18" cy="-14" rx="26" ry="13"/></g>`;
    [[230, 300, 1.4], [600, 330, 1.1], [80, 520, 1.0], [800, 470, 0.9], [1180, 330, 1.0], [1420, 470, 0.8], [1990, 330, 1.1], [2330, 470, 0.9], [2560, 330, 1.0], [2900, 420, 0.9]]
      .forEach(([x, y, k]) => { s += cloud(x, y, k, hz('#FFFFFF', x, 0.6), (0.55 + 0.4 * fog(x)).toFixed(2)); });
    [[3150, 420, 0.9]].forEach(([x, y, k]) => { s += cloud(x, y, k, '#F2B8C8', 0.7); });
    // haze bands that sit low over the land at the start and thin out by frame 4
    s += `<g filter="url(#softer)" fill="${hazeC(0)}"><rect x="-40" y="560" width="1100" height="70" rx="35" opacity=".55"/><rect x="-40" y="660" width="900" height="50" rx="25" opacity=".45"/><rect x="700" y="610" width="900" height="44" rx="22" opacity=".3"/></g>`;

    // gulls over the sea
    const gull = (x, y, k) => `<path d="M${x - 9 * k} ${y} q${4.5 * k} ${-6 * k} ${9 * k} 0 q${4.5 * k} ${-6 * k} ${9 * k} 0" fill="none" stroke="#3B4A7A" stroke-width="2.2" stroke-linecap="round" opacity=".6"/>`;
    s += gull(1290, 420, 1.2) + gull(1335, 446, 0.9) + gull(1690, 520, 1.0);

    // far hills (islands across the sea)
    s += `<path filter="url(#lf)" d="${ridgePath(ridge.far)}" fill="url(#lfar)"/>`;
    // the sea: its body rises from behind the headlands (each edge slides down under the land drawn after it),
    // then two far swells. Shore edges follow the same envelope as the land layers, so no edge is ever in view.
    const shoreDrop = (x, a0, b1) => (1 - sea(x, a0, a0 + 150, b1 - 150, b1)) * 320;
    const body = x => HORIZON + shoreDrop(x, 750, 1900);
    s += `<path d="${ridgePath(body, 740, 1910, 10)}" fill="url(#sea0)"/><path d="${ridgePath(body, 740, 1910, 10)}" fill="url(#seav)"/>`;
    const swell = (y0, a, f, p) => x => y0 + a * Math.sin(x * f + p) + shoreDrop(x, 760, 1890);
    s += `<path filter="url(#lf)" d="${ridgePath(swell(690, 2.5, 0.031, 0.5), 740, 1910, 8)}" fill="url(#sea1)"/>`;
    s += `<path filter="url(#lm)" d="${ridgePath(swell(748, 4, 0.023, 1.7), 740, 1910, 8)}" fill="url(#sea2)"/>`;

    // Xero sets at seam 7/8 (sleepy), behind the mid hills: the sun of Day Zero going down
    s += ch('xero', { mood: 'sleepy', stage: 2, size: 150 }, 3080, 556);

    // mid hills
    s += `<path filter="url(#lm)" d="${ridgePath(ridge.mid)}" fill="url(#lmid)"/>`;

    // Xero rises at seam 1/2, his feet behind the near hills (hazy: he's still low in the morning haze)
    s += ch('xero', { mood: 'hello', stage: 1, size: 214 }, 440, 548);
    // and at seam 9/10 he is up, fully clear, stage 4 with his rays
    s += ch('xero', { mood: 'cheer', stage: 4, size: 214 }, 3962, 520);

    // near hills
    s += `<path filter="url(#ln)" d="${ridgePath(ridge.near)}" fill="url(#lnear)"/>`;

    // paper trees on the near hills of the day's land (seams 5/6 and 6/7)
    const tree = (x, k, c) => { const y = ridge.near(x); return `<g transform="translate(${x} ${y.toFixed(1)}) scale(${k})"><rect x="-3" y="-26" width="6" height="30" rx="3" fill="#5E4A3A"/><ellipse cx="0" cy="-46" rx="22" ry="28" fill="${c}"/><path d="M8 -66 C18 -58 22 -44 18 -30 C14 -40 12 -54 8 -66 Z" fill="#000" opacity=".12"/></g>`; };
    s += tree(2170, 1.0, '#2E9B6A') + tree(2214, 1.25, '#3FB37F') + tree(2246, 0.85, '#2A8F62');
    s += tree(2610, 0.9, '#4FB07A') + tree(2662, 1.15, '#3A9F6E');

    return `<defs>${defs}</defs>${s}`;
  }

  function front() {
    const defs = [
      hgrad('lfront', x => hz(land.front(x), x, 0.18)),
      hgrad('sea3', x => hz('#2F6FE8', x, 0.25)), hgrad('sea4', x => hz('#1C4FCC', x, 0.12)),
      lift('lfr', 0.24),
      `<radialGradient id="glimg"><stop offset="0" stop-color="#FFE27A" stop-opacity=".55"/><stop offset="1" stop-color="#FFE27A" stop-opacity="0"/></radialGradient>`,
      `<linearGradient id="sheen" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".18"/><stop offset=".3" stop-color="#fff" stop-opacity="0"/></linearGradient>`
    ].join('');
    let s = '';

    // the near swell rises around Jelli at seam 3/4 (a broad wave, calmer out in frame 4); the front swell runs the
    // whole sea and slides under the foreground headlands at both shores
    const fwA = x => 958 - 168 * Math.exp(-(((x - 1300) / 340) ** 2)) - 52 * Math.exp(-(((x - 1600) / 160) ** 2)) + 4 * Math.sin(x * 0.034 + 0.6);
    s += `<path filter="url(#lfr)" d="${ridgePath(fwA, 860, 1840, 8)}" fill="url(#sea3)"/>`;
    s += ch('jelli', { mood: 'breathe', stage: 1, size: 176 }, 1320, 706);
    const fw = x => 884 + 6 * Math.sin(x * 0.021 + 2.1) - 40 * Math.exp(-(((x - 1322) / 95) ** 2)) + (1 - sea(x, 860, 1060, 1660, 1880)) * 120;
    s += `<path filter="url(#lfr)" d="${ridgePath(fw, 840, 1900, 8)}" fill="url(#sea4)"/>`;
    // foam curls on the swells
    const curl = (f, x, k) => { const y = f(x); return `<path transform="translate(${x} ${(y + 2).toFixed(1)}) scale(${k})" d="M-22 0 C-12 -14 8 -16 18 -4 C6 -7 -4 -3 -10 6 Z" fill="#FFF8EE" opacity=".92"/>`; };
    s += curl(fwA, 1236, 1.1) + curl(fwA, 1420, 1.2) + curl(fw, 1110, 0.9) + curl(fw, 1530, 1.0) + curl(fw, 1700, 0.8);

    // the foreground ridge
    s += `<path filter="url(#lfr)" d="${ridgePath(ridge.front)}" fill="url(#lfront)"/>`;
    s += `<path d="${ridgePath(ridge.front)}" fill="url(#sheen)"/>`;

    // frame 2: the prep path. Seven stones, one per prep day, lead along the foreground to the Quit Day flag on the headland.
    const pathY = x => ridge.front(x) + 30 + 10 * Math.sin(x * 0.02);
    let path = ''; for (let x = 470; x <= 820; x += 6) path += `${path ? 'L' : 'M'}${x} ${pathY(x).toFixed(1)} `;
    s += `<path d="${path}" fill="none" stroke="${hz('#FFD2A8', 600, 0.2)}" stroke-width="16" stroke-linecap="round" opacity=".85"/>`;
    for (let i = 0; i < 7; i++) { const x = 490 + i * 46; s += `<ellipse cx="${x}" cy="${pathY(x).toFixed(1)}" rx="9" ry="4.2" fill="${hz('#FFF3E2', x, 0.2)}"/>`; }
    const fx = 836, fy = ridge.front(fx) + 4;
    s += `<g transform="translate(${fx} ${fy.toFixed(1)})"><rect x="-2" y="-78" width="4" height="80" rx="2" fill="#4A2810"/><path d="M2 -76 C16 -80 28 -70 42 -74 L42 -50 C28 -46 16 -56 2 -52 Z" fill="#FFD966"/><circle cx="22" cy="-63" r="6" fill="#FF7A55"/></g>`;
    // the program road picks up again after the sea, through frames 5 to 7, toward the evening
    let road = ''; for (let x = 1900; x <= 3010; x += 6) road += `${road ? 'L' : 'M'}${x} ${(ridge.front(x) + 34 + 8 * Math.sin(x * 0.013)).toFixed(1)} `;
    s += `<path d="${road}" fill="none" stroke="#E8F5DD" stroke-width="14" stroke-linecap="round" opacity=".5"/>`;
    // flowers in the meadow
    let fl = '', seed = 3; const rnd = () => (seed = (seed * 16807) % 2147483647) / 2147483647;
    for (let i = 0; i < 46; i++) { const x = 1900 + rnd() * 1100, y = ridge.front(x) + 12 + rnd() * 50; fl += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${(2.2 + rnd() * 1.6).toFixed(1)}" fill="${['#FFF8EE', '#FFD966', '#FF8FA3'][i % 3]}" opacity=".9"/>`; }
    s += fl;

    // night: Glim hovers in the gap between frames 8 and 9, and lights fireflies along the hills
    s += `<circle cx="3520" cy="672" r="120" fill="url(#glimg)"/>`;
    s += ch('glim', { mood: 'hello', stage: 1, size: 168 }, 3520, 560);
    let ff = ''; seed = 11;
    for (let i = 0; i < 22; i++) { const x = 3200 + rnd() * 720, y = 700 + rnd() * 230; if (Math.abs((x % FW) - 220) < 140 && y < 840) continue; ff += `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="7" fill="#FFE27A" opacity=".22"/><circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="2.4" fill="#FFE27A"/>`; }
    s += ff;

    // the finale: Jelli and Glim join Xero in the clear morning, at the foot of frame 10
    s += ch('jelli', { mood: 'cheer', stage: 4, size: 132 }, 4038, 806);
    s += ch('glim', { mood: 'cheer', stage: 4, size: 132 }, 4330, 790);
    // confetti, the finale's one celebration (design system 4.1), resting in the gaps, never over the caption
    const C = ['#FF7A55', '#2A52DB', '#4A3596', '#0F6E43', '#FF8FB8', '#FFF8EE'];
    const P = [[3988, 330, 0, 24], [4012, 420, 1, -30], [4370, 320, 3, 40], [4386, 430, 4, -16], [4378, 560, 5, 0], [3994, 520, 2, 0], [4362, 660, 0, -50], [4000, 300, 5, 60], [4060, 282, 4, 18], [4340, 286, 1, -24]];
    s += P.map(([x, y, c, r], i) => i % 3 === 2 ? `<circle cx="${x}" cy="${y}" r="5" fill="${C[c]}"/>`
      : `<rect x="${x - 4.5}" y="${y - 8}" width="9" height="16" rx="2.5" fill="${C[c]}" transform="rotate(${r} ${x} ${y})"/>`).join('');

    return `<defs>${defs}</defs>${s}`;
  }

  const cache = {};
  window.PANO = {
    W, H, FW, clarity, zen, hor,
    svg(layer, dx = 0) {
      cache[layer] = cache[layer] || (layer === 'back' ? back() : front());
      return `<svg class="pano ${layer}" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" style="left:${dx}px;top:0">${cache[layer]}</svg>`;
    }
  };
})();
