/*
 * DayXero screen lab: the app's illustrations as SVG strings.
 *
 * A one-to-one port of the SwiftUI Canvas drawing in
 *   DayXeroCore/DesignSystem/Art/{KitArt,PersonFigure,XeroView,JelliView,GlimView,CrewDrawing,ArtTrack,HorizonScene}.swift
 *   DayXero/Calm/CalmToolsView.swift (CalmHeaderArt)
 *   DayXero/Health/MilestoneIllustrations.swift (HealthArt, HealthBadge)
 * The Swift is the source of truth: same path data, colours, layering and loop timings.
 * ArtTrack keyframes become SMIL <animate>/<animateTransform> with the same values, keyTimes and
 * durations (repeatCount indefinite). With animate:false the first frame (the Reduce Motion state) is drawn.
 *
 * Plain browser script, no modules or dependencies: defines window.Art.
 */
(function (root) {
  'use strict';

  // ---------------------------------------------------------------------------
  // Basics
  // ---------------------------------------------------------------------------

  let counter = 0;
  /** A fresh id namespace per SVG, so many drawings can share a page. */
  function ids() {
    const n = ++counter;
    return (name) => 'dxart' + n + '-' + name;
  }

  /** ArtTrack's keySpline (the canvas files' "0.45 0 0.55 1"). */
  const SPL = '0.45 0 0.55 1';
  /** 0.5 − 0.5·cos(πx), the half-cosine ease used by the health loops and DX.Move.breath. */
  const SINE = '0.37 0 0.63 1';

  function f(n) {
    const r = Math.round(n * 10000) / 10000;
    return Object.is(r, -0) ? '0' : String(r);
  }
  function fv(v) {
    if (Array.isArray(v)) return v.map(f).join(' ');
    return typeof v === 'number' ? f(v) : String(v);
  }
  function hex(c) {
    return typeof c === 'number' ? '#' + c.toString(16).padStart(6, '0').toUpperCase() : c;
  }
  const nz = (op) => (op === undefined || op === null || op === 1 ? undefined : op);

  /** <tag a="…"/> or <tag a="…">kids</tag>; undefined/null/false attributes are left out. */
  function el(tag, attrs, kids) {
    let s = '<' + tag;
    for (const k in attrs) {
      const v = attrs[k];
      if (v === undefined || v === null || v === false) continue;
      s += ' ' + k + '="' + (typeof v === 'number' ? f(v) : v) + '"';
    }
    return kids ? s + '>' + kids + '</' + tag + '>' : s + '/>';
  }
  function g(transform, inner) {
    return transform ? '<g transform="' + transform + '">' + inner + '</g>' : '<g>' + inner + '</g>';
  }
  /** Adds attributes and child animations to one element string built by `el`. */
  function inject(elem, attrs, kids) {
    const m = elem.match(/^<(\w+)([\s\S]*?)\/>$/);
    if (m) return '<' + m[1] + m[2] + attrs + (kids ? '>' + kids + '</' + m[1] + '>' : '/>');
    const o = elem.match(/^<(\w+)([^>]*)>/);
    return '<' + o[1] + o[2] + attrs + '>' + (kids || '') + elem.slice(o[0].length);
  }

  // ---------------------------------------------------------------------------
  // Tracks → SMIL
  // ---------------------------------------------------------------------------

  function evenTimes(n) {
    return n > 1 ? Array.from({ length: n }, (_, i) => i / (n - 1)) : [0];
  }
  /**
   * ArtTrack's `begin` (and the health Clock's `delay`) shift a loop that runs on the wall clock, so the
   * app never shows the "before begin" state. A negative SMIL begin gives the same steady-state phase.
   */
  function beginAttr(begin, dur) {
    if (!begin) return '';
    const b = ((begin % dur) + dur) % dur;
    if (b < 1e-9) return '';
    return ' begin="-' + f(dur - b) + 's"';
  }
  function timing(n, o) {
    const times = o.times || evenTimes(n);
    let s = ' dur="' + f(o.dur) + 's"';
    s += o.once ? ' fill="freeze"' : ' repeatCount="indefinite"';
    s += ' keyTimes="' + times.map(f).join(';') + '"';
    if (o.discrete) s += ' calcMode="discrete"';
    else if (o.spline) {
      const k = o.spline === true ? SPL : o.spline;
      s += ' calcMode="spline" keySplines="' + Array(n - 1).fill(k).join(';') + '"';
    }
    if (!o.once) s += beginAttr(o.begin, o.dur);
    return s;
  }
  /** track: {values, times?, dur, spline?, begin?, discrete?, once?} */
  function anim(attr, t) {
    return '<animate attributeName="' + attr + '" values="' + t.values.map(fv).join(';') + '"' + timing(t.values.length, t) + '/>';
  }
  function animT(type, t) {
    return '<animateTransform attributeName="transform" type="' + type + '" values="' + t.values.map(fv).join(';') + '"' + timing(t.values.length, t) + '/>';
  }
  const T = (values, dur, o) => Object.assign({ values, dur }, o || {});

  /** A group whose transform follows a track; when still, the resting value (first value unless given). */
  function tg(on, type, track, inner, rest) {
    if (on && track) return '<g>' + animT(type, track) + inner + '</g>';
    const r = rest === undefined ? (track ? track.values[0] : undefined) : rest;
    const identity = r === undefined || (type === 'rotate' && r === 0) || (type === 'scale' && (r === 1 || (Array.isArray(r) && r[0] === 1 && r[1] === 1))) ||
      (type === 'translate' && (r === 0 || (Array.isArray(r) && r[0] === 0 && r[1] === 0))) || ((type === 'skewY' || type === 'skewX') && r === 0);
    return identity ? '<g>' + inner + '</g>' : '<g transform="' + type + '(' + fv(r) + ')">' + inner + '</g>';
  }
  /** translate(p) <transform> translate(−p): Crew.pose and the health drawings' scaled/rotated(around:). */
  function around(px, py, wrap, content) {
    return g('translate(' + f(px) + ' ' + f(py) + ')', wrap(g('translate(' + f(-px) + ' ' + f(-py) + ')', content)));
  }
  /** GraphicsContext.opacity applies to each drawing operation, so it goes on each element. */
  function withOpacity(elem, on, rest, track) {
    if (on && track) return inject(elem, ' opacity="' + f(rest) + '"', anim('opacity', track));
    return rest === 1 ? elem : inject(elem, ' opacity="' + f(rest) + '"', '');
  }
  /**
   * A linear track passed through a piecewise-linear function (a clamp). New keyframes are added where the
   * input crosses each kink, so the SMIL output equals fn(track) exactly.
   */
  function mapTrack(values, times, fn, kinks) {
    const V = [], Ts = [];
    for (let i = 0; i < values.length; i++) {
      if (i > 0) {
        const v0 = values[i - 1], v1 = values[i], t0 = times[i - 1], t1 = times[i];
        const cross = kinks.filter((k) => (k - v0) * (k - v1) < 0)
          .map((k) => t0 + ((k - v0) / (v1 - v0)) * (t1 - t0)).sort((a, b) => a - b);
        for (const t of cross) {
          Ts.push(t);
          V.push(fn(v0 + ((v1 - v0) * (t - t0)) / (t1 - t0)));
        }
      }
      Ts.push(times[i]);
      V.push(fn(values[i]));
    }
    return { values: V, times: Ts };
  }

  // Shapes ---------------------------------------------------------------------

  function fillP(d, c, op, extra, kids) {
    return el('path', Object.assign({ d, fill: hex(c), 'fill-opacity': nz(op) }, extra || {}), kids);
  }
  /** StrokeStyle(lineWidth:, lineCap: .round, lineJoin: .round) unless cap/join are given. */
  function strokeP(d, c, w, o) {
    o = o || {};
    return el('path', Object.assign({
      d, fill: 'none', stroke: hex(c), 'stroke-width': w, 'stroke-opacity': nz(o.op),
      'stroke-linecap': o.cap || 'round', 'stroke-linejoin': o.join || 'round',
      'stroke-dasharray': o.dash, 'stroke-dashoffset': o.offset,
    }, o.attrs || {}), o.kids);
  }
  function fillC(cx, cy, r, c, op, kids, extra) {
    return el('circle', Object.assign({ cx, cy, r, fill: hex(c), 'fill-opacity': nz(op) }, extra || {}), kids);
  }
  function fillE(cx, cy, rx, ry, c, op, kids, extra) {
    return el('ellipse', Object.assign({ cx, cy, rx, ry, fill: hex(c), 'fill-opacity': nz(op) }, extra || {}), kids);
  }
  function strokeC(cx, cy, r, c, w, o) {
    o = o || {};
    return el('circle', Object.assign({ cx, cy, r, fill: 'none', stroke: hex(c), 'stroke-width': w, 'stroke-opacity': nz(o.op),
      'stroke-linecap': o.cap, 'stroke-dasharray': o.dash }, o.attrs || {}), o.kids);
  }
  function strokeE(cx, cy, rx, ry, c, w) {
    return el('ellipse', { cx, cy, rx, ry, fill: 'none', stroke: hex(c), 'stroke-width': w, 'stroke-linecap': 'round', 'stroke-linejoin': 'round' });
  }

  /**
   * RoundedRectangle(style: .continuous): the iOS "squircle" corner (three cubics per corner, reaching
   * 1.52866 × radius along each edge). Radii too large for that fall back to circular corners.
   */
  function continuousRect(x, y, w, h, r) {
    r = Math.max(0, Math.min(r, Math.min(w, h) / 2));
    if (r === 0) return 'M' + f(x) + ' ' + f(y) + ' H' + f(x + w) + ' V' + f(y + h) + ' H' + f(x) + ' Z';
    if (r * 1.52866483 > Math.min(w, h) / 2) {
      return 'M' + f(x + r) + ' ' + f(y) + ' H' + f(x + w - r) + ' A' + f(r) + ' ' + f(r) + ' 0 0 1 ' + f(x + w) + ' ' + f(y + r) +
        ' V' + f(y + h - r) + ' A' + f(r) + ' ' + f(r) + ' 0 0 1 ' + f(x + w - r) + ' ' + f(y + h) +
        ' H' + f(x + r) + ' A' + f(r) + ' ' + f(r) + ' 0 0 1 ' + f(x) + ' ' + f(y + h - r) +
        ' V' + f(y + r) + ' A' + f(r) + ' ' + f(r) + ' 0 0 1 ' + f(x + r) + ' ' + f(y) + ' Z';
    }
    const k = [1.52866483, 1.08849323, 0.86840689, 0.63149399, 0.07491100, 0.37282392, 0.16905899];
    // Corner points as (u, v): u back along the incoming edge, v along the outgoing edge.
    const seq = [[k[0], 0], [k[1], 0], [k[2], 0], [k[3], k[4]], [k[5], k[6]], [k[6], k[5]], [k[4], k[3]], [0, k[2]], [0, k[1]], [0, k[0]]];
    const corners = [
      { o: [x + w, y], e1: [-1, 0], e2: [0, 1] },
      { o: [x + w, y + h], e1: [0, -1], e2: [-1, 0] },
      { o: [x, y + h], e1: [1, 0], e2: [0, -1] },
      { o: [x, y], e1: [0, 1], e2: [1, 0] },
    ];
    const pt = (c, uv) => f(c.o[0] + (uv[0] * c.e1[0] + uv[1] * c.e2[0]) * r) + ' ' + f(c.o[1] + (uv[0] * c.e1[1] + uv[1] * c.e2[1]) * r);
    let d = 'M' + pt(corners[3], seq[9]);
    for (const c of corners) {
      d += ' L' + pt(c, seq[0]);
      d += ' C' + pt(c, seq[1]) + ' ' + pt(c, seq[2]) + ' ' + pt(c, seq[3]);
      d += ' C' + pt(c, seq[4]) + ' ' + pt(c, seq[5]) + ' ' + pt(c, seq[6]);
      d += ' C' + pt(c, seq[7]) + ' ' + pt(c, seq[8]) + ' ' + pt(c, seq[9]);
    }
    return d + ' Z';
  }

  function svgOpen(w, h, viewBox, style) {
    return '<svg xmlns="http://www.w3.org/2000/svg" width="' + f(w) + '" height="' + f(h) + '" viewBox="' + viewBox + '"' +
      (style ? ' style="' + style + '"' : '') + ' aria-hidden="true">';
  }

  // ---------------------------------------------------------------------------
  // KitArt
  // ---------------------------------------------------------------------------

  const CREAM = '#FFF8EE', INK = '#1E1A3A', SUN = '#FFD966';
  const kitKinds = ['dawn', 'sea', 'sprout', 'night', 'breath', 'peak', 'sparkle', 'clouds', 'flower',
    'cup', 'eye', 'glass', 'heart', 'box', 'outbreath', 'grounding', 'tag', 'anchor',
    'berry', 'lungs', 'lips', 'shield'];

  const KIT_SPEC = {
    dawn: ['#FF7A55', '#FFC38A', ['rings']],
    sea: ['#2A52DB', '#9CCBFF', ['sea']],
    sprout: ['#6FCB98', '#9FE3BC', ['hill'], ['#3E9E6A', '#2F8A5A']],
    night: ['#2A1C6E', '#4A3596', ['hill'], ['#1E1458', '#2A1C6E']],
    breath: ['#2A52DB', '#5B7FF0', ['pulse']],
    peak: ['#FF8FB8', '#FFC3D8', []],
    sparkle: ['#FFC94A', '#FFD966', ['rings']],
    clouds: ['#4A3596', '#8E73F0', []],
    flower: ['#FF7A55', '#FFA46B', []],
    cup: ['#FFA46B', '#FFC38A', ['rings']],
    eye: ['#8E73F0', '#B9A6FF', ['rings']],
    glass: ['#5B7FF0', '#9CCBFF', ['rings']],
    heart: ['#FF7A55', '#FF8FB8', ['rings']],
    box: ['#FFC94A', '#FFD966', []],
    outbreath: ['#6FCB98', '#9FE3BC', []],
    grounding: ['#3E9E6A', '#6FCB98', []],
    tag: ['#FF8FB8', '#FFB3CF', []],
    anchor: ['#FFA46B', '#FFC38A', ['floor'], ['#E8894A', '#E8894A']],
    berry: ['#FFD966', '#FFE59A', ['rings']],
    lungs: ['#5B7FF0', '#9CCBFF', ['rings']],
    lips: ['#FFC3D8', '#FFE1EC', ['rings']],
    shield: ['#3E9E6A', '#6FCB98', ['rings']],
  };

  /** KitDraw.safeArea: inset max(12% of the short side, 30% of the corner radius, 6), both rounded. */
  function kitSafeArea(w, h, radius) {
    const short = Math.min(w, h);
    const inset = Math.max(Math.round(short * 0.12), Math.round(radius * 0.3), 6);
    const side = Math.max(short - inset * 2, 1);
    return { x: (w - side) / 2, y: (h - side) / 2, width: side, height: side };
  }

  function star(x, y, r) {
    const k = r * 0.25;
    return 'M' + f(x) + ' ' + f(y - r) + ' L' + f(x + k) + ' ' + f(y - k) + ' L' + f(x + r) + ' ' + f(y) + ' L' + f(x + k) + ' ' + f(y + k) +
      ' L' + f(x) + ' ' + f(y + r) + ' L' + f(x - k) + ' ' + f(y + k) + ' L' + f(x - r) + ' ' + f(y) + ' L' + f(x - k) + ' ' + f(y - k) + ' Z';
  }
  function kitWave(y, from, step, count, depth, bottom) {
    let d = 'M' + f(from) + ' ' + f(y) + ' Q' + f(from + step / 2) + ' ' + f(y - depth) + ' ' + f(from + step) + ' ' + f(y);
    for (let i = 2; i <= count; i++) d += ' T' + f(from + step * i) + ' ' + f(y);
    return d + ' V' + f(bottom) + ' H' + f(from) + ' Z';
  }

  function kitLayer(layer, hills, on) {
    switch (layer) {
      case 'rings':
        return fillC(100, 150, 150, '#FFFFFF', 0.08) + fillC(100, 150, 110, '#FFFFFF', 0.10) + fillC(100, 150, 72, '#FFFFFF', 0.12);
      case 'pulse':
        return [0, 2.5].map((b) => strokeC(100, 70, 40, '#FFFFFF', 10, {
          op: 0.22,
          kids: on ? anim('r', T([40, 95], 5, { begin: b })) + anim('stroke-opacity', T([0.22, 0], 5, { begin: b })) : '',
        })).join('');
      case 'sea':
        return tg(on, 'translate', T([[0, 0], [-60, 0]], 6), fillP(kitWave(104, -10, 30, 10, 8, 150), '#7F9CF5')) +
          tg(on, 'translate', T([[-60, 0], [0, 0]], 4.5), fillP(kitWave(118, -70, 30, 10, 8, 150), '#2A52DB'));
      case 'hill':
        return fillE(40, 160, 140, 44, hills[0]) + fillE(190, 168, 120, 46, hills[1]);
      case 'floor':
        return fillP('M0 122 Q50 112 100 120 T200 116 V140 H0 Z', hills[0]);
    }
    return '';
  }

  function kitSubject(kind, bottom, on, id) {
    const track = (values, dur, times) => T(values, dur, { times });
    const a = (attr, values, dur, times) => (on ? anim(attr, track(values, dur, times)) : '');
    const glow = (x, y, r) => el('circle', { cx: x, cy: y, r, fill: 'url(#' + id('glow') + ')' });
    const twinkle = () => a('fill-opacity', [1, 0.3, 1], 2.6);
    switch (kind) {
      case 'dawn':
        return glow(50, 62, 34) +
          fillC(50, 66, 20, SUN, 1, a('cy', [66, 58, 66], 7)) +
          fillP('M14 86 a8 8 0 0 1 12 -8 a10 10 0 0 1 18 2 a7 7 0 0 1 8 6 Z', CREAM) +
          fillP(star(80, 24, 8), CREAM, 1, null, twinkle());
      case 'sea':
        return glow(74, 28, 20) + fillC(74, 28, 12, SUN) +
          fillP(star(22, 27, 7), CREAM, 1, null, twinkle()) +
          tg(on, 'translate', T([[0, 0], [0, -3], [0, 0]], 3),
            fillP('M28 76 C34 62 50 58 58 64 C50 64 44 70 42 80 Z', CREAM) + fillC(62, 62, 2.5, CREAM) + fillC(68, 58, 2, CREAM));
      case 'sprout':
        return glow(74, 28, 20) + fillC(74, 28, 12, SUN) +
          g('translate(46 92)', tg(on, 'rotate', T([-3, 3, -3], 5),
            strokeP('M0 0 L0 -56', '#0F6E43', 5) +
            fillP('M0 -30 C-6 -44 -26 -48 -32 -40 C-24 -30 -10 -28 0 -30 Z', '#9FE3BC') +
            fillP('M0 -40 C8 -54 30 -56 36 -46 C28 -36 10 -36 0 -40 Z', '#C6F2D8') +
            fillC(0, -60, 7, '#FF8FB8')));
      case 'night':
        return glow(58, 40, 30) +
          fillP('M62 18 A24 24 0 1 0 80 52 A19 19 0 1 1 62 18 Z', '#FFF1C2') +
          fillC(20, 26, 2, CREAM, 1, a('fill-opacity', [1, 0.2, 1], 2.4)) +
          fillC(30, 56, 1.6, CREAM, 0.2, a('fill-opacity', [0.2, 1, 0.2], 3)) +
          fillP(star(18, 76, 6), SUN, 1, null, a('fill-opacity', [1, 0.3, 1], 2.8));
      case 'breath': {
        const times = [0, 0.4, 1.0];
        return fillC(50, 50, 22, '#FFFFFF', 0.18, a('r', [22, 34, 22], 10, times)) +
          fillC(50, 50, 14, '#FFFFFF', 0.35, a('r', [14, 24, 14], 10, times)) +
          fillC(50, 50, 9, '#FFFFFF') + fillP(star(82, 24, 7), SUN);
      }
      case 'peak': {
        // flag(): skew around the pole's x — y' = y + tan(angle)·(x − 67).
        const flag = g('translate(67 0)', tg(on, 'skewY', T([0, -5, 0, 4, 0], 2.4), g('translate(-67 0)', fillP('M67 17 L80 21 L67 26 Z', '#FF7A55'))));
        return glow(26, 26, 16) + fillC(26, 26, 9, SUN) +
          fillP('M4 96 L36 52 L66 96 Z', '#6C4FD8') +
          fillP('M30 96 L66 34 L100 96 Z', '#8E73F0') +
          fillP('M66 34 L100 96 L80 96 Z', '#6C4FD8', 0.6) +
          fillP('M60 44 L66 34 L72 44 L68 42 L66 46 L63 42 Z', CREAM) +
          strokeP('M66 46 C62 60 70 70 60 86', CREAM, 2.5, { dash: '3 4', offset: 14, kids: a('stroke-dashoffset', [14, 0], 1.6) }) +
          strokeP('M66 34 L66 16', INK, 2.5) + flag;
      }
      case 'sparkle':
        return fillC(46, 54, 34, '#FFF1C2', 0.55) +
          g('translate(46 54)', tg(on, 'scale', T([0.9, 1.05, 0.9], 3),
            fillP('M0 -28 C3 -8 8 -3 28 0 C8 3 3 8 0 28 C-3 8 -8 3 -28 0 C-8 -3 -3 -8 0 -28 Z', CREAM))) +
          fillP('M82 22 C83 28 85 30 91 31 C85 32 83 34 82 40 C81 34 79 32 73 31 C79 30 81 28 82 22 Z', '#FF7A55', 1, null, a('fill-opacity', [1, 0.4, 1], 2.2)) +
          fillP('M18 80 C19 84 20 85 24 86 C20 87 19 88 18 92 C17 88 16 87 12 86 C16 85 17 84 18 80 Z', '#FF8FB8');
      case 'clouds':
        return glow(30, 28, 16) + fillC(30, 28, 9, SUN) +
          tg(on, 'translate', T([[-3, 0], [3, 0], [-3, 0]], 8),
            fillP('M14 84 C12 72 26 66 34 72 C38 58 60 58 64 72 C74 66 88 72 86 84 Z', '#9CCBFF') +
            fillP('M40 84 C40 76 50 72 56 77 C60 70 74 70 76 78 C82 76 90 80 88 84 Z', '#6E94F0'));
      case 'flower': {
        const petals = [[0, -22], [21, -7], [13, 18], [-13, 18], [-21, -7]].map((p) => fillC(p[0], p[1], 14, CREAM)).join('');
        return strokeP('M50 84 C40 90 30 96 22 100', '#3E9E6A', 5) +
          fillP('M34 92 C24 80 10 82 8 90 C16 98 28 98 34 92 Z', '#3E9E6A') +
          g('translate(54 48)', tg(on, 'rotate', T([0, 360], 40), petals) + fillC(0, 0, 12, '#FFC94A') + fillC(-3, -3, 4, '#FFE59A'));
      }
      case 'cup': {
        const steam = [[0, 'M36 34 C34 24 42 20 40 12'], [1.3, 'M52 34 C50 24 58 20 56 12']].map(([b, d]) =>
          tg(on, 'translate', T([[0, 6], [0, -3]], 2.6, { begin: b }),
            strokeP(d, CREAM, 3, { op: 0.7, kids: on ? anim('stroke-opacity', T([0, 1, 0], 2.6, { times: [0, 0.5, 1], begin: b })) : '' }), 0)).join('');
        return steam +
          strokeP('M70 50 C84 50 84 72 68 72', CREAM, 5) +
          fillP('M22 42 L72 42 L68 80 Q66 88 58 88 L36 88 Q28 88 26 80 Z', CREAM) +
          strokeP('M24 52 L71 52', '#FF7A55', 6) +
          fillE(47, 92, 32, 4, INK, 0.15);
      }
      case 'eye': {
        let s = kitEye('#4A3596');
        if (on) {
          s += g('translate(50 50)', '<g transform="scale(1 0)">' +
            animT('scale', T([[1, 0], [1, 0], [1, 1], [1, 0], [1, 0]], 4.5, { times: [0, 0.9, 0.95, 0.98, 1] })) +
            fillP('M-41 0 C-25 -27 25 -27 41 0 C25 27 -25 27 -41 0 Z', bottom) + '</g>');
        }
        return s;
      }
      case 'glass': {
        const shape = 'M30 18 L70 18 L65 84 Q64 88 60 88 L40 88 Q36 88 35 84 Z';
        return '<defs>' + el('clipPath', { id: id('glass') }, el('path', { d: shape })) + '</defs>' +
          strokeP('M60 6 L54 50', '#FF7A55', 5) +
          fillP(shape, CREAM, 0.92) +
          el('g', { 'clip-path': 'url(#' + id('glass') + ')' },
            tg(on, 'translate', T([[0, 0], [-30, 0]], 2.6), fillP(kitWave(50, 10, 15, 7, 5, 95), '#2A52DB')) +
            fillC(46, on ? 82 : 76, 2.5, CREAM, 1, on ? anim('cy', T([82, 56], 2.2)) + anim('fill-opacity', T([1, 0], 2.2)) : ''));
      }
      case 'heart':
        return fillC(50, 52, 34, '#FFFFFF', 0.18) +
          g('translate(50 54)', tg(on, 'scale', T([1, 1.1, 1, 1.05, 1, 1], 1.6, { times: [0, 0.12, 0.24, 0.36, 0.5, 1] }),
            fillP('M0 26 C-28 8 -32 -12 -20 -22 C-10 -30 -2 -24 0 -16 C2 -24 10 -30 20 -22 C32 -12 28 8 0 26 Z', CREAM) +
            strokeP('M-16 -12 C-14 -16 -10 -18 -6 -17', '#FF7A55', 3)));
      case 'box':
        // In, hold, out, hold: one side every 4 seconds, starting bottom-left and going up.
        return el('path', { d: continuousRect(22, 22, 56, 56, 6), fill: 'none', stroke: INK, 'stroke-width': 4 }) +
          fillC(22, 78, 7, '#FF7A55', 1, on
            ? anim('cx', T([22, 22, 78, 78, 22], 16, { times: [0, 0.25, 0.5, 0.75, 1] })) + anim('cy', T([78, 22, 22, 78, 78], 16, { times: [0, 0.25, 0.5, 0.75, 1] }))
            : '');
      case 'outbreath': {
        // In 4, hold 7, out 8.
        const wind = on ? anim('stroke-opacity', T([0, 0, 0, 1, 0], 19, { times: [0, 0.21, 0.58, 0.75, 1] })) : '';
        return fillC(50, 50, 14, CREAM, 1, a('r', [14, 30, 30, 14], 19, [0, 0.21, 0.58, 1.0])) +
          strokeP('M66 40 C74 40 78 36 84 36', '#0F6E43', 3.5, { op: on ? 0 : 1, kids: wind }) +
          strokeP('M68 52 C76 52 80 56 88 56', '#0F6E43', 3.5, { op: on ? 0 : 1, kids: wind });
      }
      case 'grounding': {
        // Five senses, lit one by one: dot i is lit once the 6 s loop passes (i + 1) / 6.
        let s = fillP('M14 42 C28 22 72 22 86 42 C72 62 28 62 14 42 Z', CREAM) + fillC(50, 42, 11, '#0F6E43') + fillC(50, 42, 4.5, INK);
        for (let i = 0; i < 5; i++) {
          s += fillC(22 + i * 14, 80, 5, CREAM, 1, on ? anim('fill-opacity', T([0.25, 1], 6, { times: [0, (i + 1) / 6], discrete: true })) : '');
        }
        return s;
      }
      case 'tag':
        return tg(on, 'translate', T([[0, 8], [0, -6], [0, 8]], 6),
          fillP('M22 50 C14 50 12 36 22 34 C22 22 40 18 46 28 C54 18 74 22 72 36 C84 36 84 52 72 52 L30 52 Z', CREAM) +
          fillC(26, 62, 4, CREAM) + fillC(18, 72, 2.5, CREAM) +
          g('translate(58 46) rotate(18)', fillP('M0 0 L22 0 L28 7 L22 14 L0 14 Z', '#FFD966') + fillC(21, 7, 2, INK)));
      case 'anchor':
        return g('translate(50 20)', tg(on, 'rotate', T([-6, 6, -6], 5),
          strokeC(0, 6, 6, INK, 5) +
          strokeP('M0 12 L0 64', INK, 5) + strokeP('M-14 26 L14 26', INK, 5) +
          strokeP('M-24 50 C-22 62 -12 66 0 66 C12 66 22 62 24 50', INK, 5)));
      case 'berry': {
        const seeds = [[-10, -4], [6, -6], [-4, 8], [12, 6], [2, 18]].map((p) => fillC(p[0], p[1], 2, '#FFE59A')).join('');
        return g('translate(50 56)', tg(on, 'rotate', T([-5, 5, -5], 4),
          fillP('M0 30 C-26 18 -30 -6 -18 -16 C-10 -22 -4 -20 0 -18 C4 -20 10 -22 18 -16 C30 -6 26 18 0 30 Z', '#FF5A5F') + seeds +
          fillP('M-14 -20 C-8 -30 -2 -28 0 -20 C2 -28 8 -30 14 -20 C6 -16 -6 -16 -14 -20 Z', '#3E9E6A'))) +
          fillP(star(80, 24, 7), CREAM, 1, null, a('fill-opacity', [1, 0.3, 1], 2.4));
      }
      case 'lungs':
        return strokeP('M50 18 L50 46', CREAM, 5) +
          g('translate(50 58)', tg(on, 'scale', T([0.92, 1.06, 0.92], 5, { times: [0, 0.4, 1] }),
            fillP('M-5 -14 C-14 -22 -32 -16 -36 6 C-40 28 -30 36 -16 32 C-8 30 -5 22 -5 12 Z', CREAM) +
            fillP('M5 -14 C14 -22 32 -16 36 6 C40 28 30 36 16 32 C8 30 5 22 5 12 Z', CREAM)));
      case 'lips':
        return g('translate(50 52)', tg(on, 'scale', T([1, 1.06, 1], 3),
          fillP('M-34 0 C-24 -16 -10 -18 0 -10 C10 -18 24 -16 34 0 C22 -2 10 -2 0 2 C-10 -2 -22 -2 -34 0 Z', '#FF5A5F') +
          fillP('M-34 0 C-22 -2 -10 -2 0 2 C10 -2 22 -2 34 0 C26 18 -26 18 -34 0 Z', '#FF7A80') +
          strokeP('M-14 8 C-8 10 -2 10 2 10', CREAM, 3)));
      case 'shield':
        return fillP('M50 12 L80 24 L80 50 C80 70 66 84 50 90 C34 84 20 70 20 50 L20 24 Z', CREAM) +
          g('translate(50 52)', tg(on, 'scale', T([1, 1.1, 1, 1, 1], 2, { times: [0, 0.15, 0.3, 0.6, 1] }),
            fillP('M0 16 C-16 6 -18 -6 -11 -12 C-6 -16 -1 -13 0 -9 C1 -13 6 -16 11 -12 C18 -6 16 6 0 16 Z', '#2F7A52')));
    }
    return '';
  }

  function kitEye(iris) {
    return fillP('M10 50 C26 24 74 24 90 50 C74 76 26 76 10 50 Z', CREAM) +
      fillC(50, 50, 15, iris) + fillC(50, 50, 6, INK) + fillC(55, 45, 3, CREAM);
  }

  function kit(kind, opts) {
    opts = opts || {};
    const W = opts.width || 160, H = opts.height || 120;
    const radius = opts.radius === undefined ? 28 : opts.radius;
    const on = opts.animate !== false;
    const spec = KIT_SPEC[kind];
    if (!spec) throw new Error('Art.kit: unknown kind ' + kind);
    const [top, bottom, layers, hills] = spec;
    const id = ids();
    const scale = Math.max(W / 200, H / 140);
    const safe = kitSafeArea(W, H, radius);
    let s = svgOpen(W, H, '0 0 ' + f(W) + ' ' + f(H));
    s += '<defs>' +
      el('linearGradient', { id: id('bg'), gradientUnits: 'userSpaceOnUse', x1: 0, y1: 0, x2: 0, y2: H },
        el('stop', { offset: 0, 'stop-color': top }) + el('stop', { offset: 1, 'stop-color': bottom })) +
      el('clipPath', { id: id('clip') }, el('path', { d: continuousRect(0, 0, W, H, radius) })) +
      el('radialGradient', { id: id('glow'), cx: 0.5, cy: 0.5, r: 0.5 },
        el('stop', { offset: 0, 'stop-color': '#FFF4C2', 'stop-opacity': 0.9 }) + el('stop', { offset: 1, 'stop-color': '#FFF4C2', 'stop-opacity': 0 })) +
      '</defs>';
    s += '<g clip-path="url(#' + id('clip') + ')">';
    s += el('rect', { width: W, height: H, fill: 'url(#' + id('bg') + ')' });
    // Layers: 200 × 140, scaled to fill (slice) and centred.
    s += g('translate(' + f((W - 200 * scale) / 2) + ' ' + f((H - 140 * scale) / 2) + ') scale(' + f(scale) + ')',
      layers.map((l) => kitLayer(l, hills || ['#3E9E6A', '#2F8A5A'], on)).join(''));
    // Subject: 100 × 100, scaled into the safe square.
    s += g('translate(' + f(safe.x) + ' ' + f(safe.y) + ') scale(' + f(safe.width / 100) + ')', kitSubject(kind, bottom, on, id));
    return s + '</g></svg>';
  }

  // ---------------------------------------------------------------------------
  // PersonFigure (100 × 120)
  // ---------------------------------------------------------------------------

  const personPoses = ['cheer', 'magnify', 'meditate', 'walk'];
  const TROUSERS = '#2B2A6B';

  function personBody(pose, shirt, skin, on) {
    const legs = (left, right, shoes) => strokeP(left, TROUSERS, 9) + strokeP(right, TROUSERS, 9) + strokeP(shoes, INK, 5);
    const arm = (d, hand, pivot, track) =>
      around(pivot[0], pivot[1], (x) => tg(on, 'rotate', track, x), strokeP(d, shirt, 8) + fillC(hand[0], hand[1], 4.5, skin));
    const head = (y, eyes, smile) =>
      fillC(50, y, 13, skin) +
      fillP('M37 30 C37 18 63 16 63 29 C58 24 46 23 37 30 Z', INK) +
      fillC(eyes[0], y + 1, 1.6, INK) + fillC(eyes[1], y + 1, 1.6, INK) +
      strokeP(smile, INK, 2);
    let s = fillE(50, 114, 26, 4, INK, 0.15);
    switch (pose) {
      case 'cheer':
        s += tg(on, 'translate', T([[0, 0], [0, -4], [0, 0]], 1.6),
          legs('M42 78 L40 108', 'M58 78 L60 108', 'M36 110 h8 M56 110 h8') +
          fillP('M36 48 Q50 42 64 48 L62 82 L38 82 Z', shirt) +
          arm('M38 50 L24 30 L20 14', [20, 12], [38, 50], T([0, -8, 0], 1.6)) +
          arm('M62 50 L76 30 L80 14', [80, 12], [62, 50], T([0, 8, 0], 1.6)) +
          head(32, [45, 55], 'M45 38 Q50 42 55 38'));
        break;
      case 'magnify':
        s += legs('M44 78 L42 108', 'M56 78 L58 108', 'M38 110 h8 M54 110 h8') +
          fillP('M38 48 Q50 42 62 48 L60 82 L40 82 Z', shirt) +
          strokeP('M40 52 L34 72', shirt, 8) + fillC(33, 75, 4.5, skin) +
          around(60, 52, (x) => tg(on, 'rotate', T([0, -6, 0], 3), x),
            strokeP('M60 52 L72 58 L76 50', shirt, 8) +
            fillC(77, 48, 4.5, skin) +
            strokeP('M78 46 L84 36', INK, 4) +
            fillC(88, 28, 9, '#E3EEFC') +
            strokeC(88, 28, 9, INK, 3.5) +
            strokeP('M84 24 a5 5 0 0 1 5 -2', '#FFFFFF', 2)) +
          head(32, [47, 57], 'M48 38 Q52 40 56 38');
        break;
      case 'meditate':
        s += fillP('M22 100 C26 88 74 88 78 100 C70 106 30 106 22 100 Z', TROUSERS) +
          tg(on, 'translate', T([[0, 0], [0, -2], [0, 0]], 10, { times: [0, 0.4, 1] }),
            fillP('M36 58 Q50 52 64 58 L66 94 L34 94 Z', shirt) +
            strokeP('M38 62 L28 88 L36 94', shirt, 8) + fillC(38, 95, 4, skin) +
            strokeP('M62 62 L72 88 L64 94', shirt, 8) + fillC(62, 95, 4, skin) +
            fillC(50, 42, 13, skin) +
            fillP('M37 40 C37 28 63 26 63 39 C58 34 46 33 37 40 Z', INK) +
            fillC(50, 24, 6, INK) +
            strokeP('M43 43 q2 2 4 0 M53 43 q2 2 4 0', INK, 1.8) +
            strokeP('M47 48 Q50 50 53 48', INK, 1.8));
        break;
      case 'walk':
        s += tg(on, 'translate', T([[0, 0], [0, -2], [0, 0]], 1.2),
          legs('M44 78 L36 108', 'M56 78 L62 108', 'M30 110 h8 M60 110 h8') +
          fillP('M38 48 Q50 42 62 48 L60 82 L40 82 Z', shirt) +
          strokeP('M40 52 L34 72', shirt, 8) + fillC(33, 75, 4.5, skin) +
          arm('M60 50 L70 36 L72 24', [72, 21], [60, 50], T([0, -14, 0], 1.2)) +
          head(32, [46, 56], 'M46 38 Q51 42 56 38'));
        break;
      default:
        throw new Error('Art.person: unknown pose ' + pose);
    }
    return s;
  }

  function person(pose, opts) {
    opts = opts || {};
    const H = opts.height || 120;
    const W = (H * 100) / 120;
    const on = opts.animate !== false;
    return svgOpen(W, H, '0 0 100 120') + personBody(pose, hex(opts.shirt || '#FF7A55'), hex(opts.skin || '#8A5A3C'), on) + '</svg>';
  }

  // ---------------------------------------------------------------------------
  // The crew (200 × 200): Xero, Jelli, Glim
  // ---------------------------------------------------------------------------

  const MOODS = ['hello', 'calm', 'breathe', 'cheer', 'sleepy'];
  const CREW_INK = '#24163A';
  const CREW_SPLINE = [0, 0.5, 1];
  const CHEER_TIMES = [0, 0.15, 0.35, 0.55, 1.0];
  const characterSizes = { avatar: 40, card: 88, scene: 140, hero: 200 };

  function makeFace(mood, y) {
    const c = 100, l = 86, r = 114;
    const closed = (x) => 'M' + (x - 6) + ' ' + y + ' Q' + x + ' ' + (y + 5) + ' ' + (x + 6) + ' ' + y;
    switch (mood) {
      case 'hello':
        return { eyeL: 'M' + l + ' ' + (y - 3) + ' L' + l + ' ' + (y + 3), eyeR: 'M' + r + ' ' + (y - 3) + ' L' + r + ' ' + (y + 3), eyeWidth: 8,
          mouth: 'M' + (c - 8) + ' ' + (y + 14) + ' Q' + c + ' ' + (y + 22) + ' ' + (c + 8) + ' ' + (y + 14), filled: false };
      case 'calm':
        return { eyeL: closed(l), eyeR: closed(r), eyeWidth: 3.5,
          mouth: 'M' + (c - 5) + ' ' + (y + 15) + ' Q' + c + ' ' + (y + 19) + ' ' + (c + 5) + ' ' + (y + 15), filled: false };
      case 'breathe':
        return { eyeL: closed(l), eyeR: closed(r), eyeWidth: 3.5,
          mouth: 'M' + c + ' ' + (y + 12) + ' C' + (c + 6) + ' ' + (y + 12) + ' ' + (c + 6) + ' ' + (y + 23) + ' ' + c + ' ' + (y + 23) +
            ' C' + (c - 6) + ' ' + (y + 23) + ' ' + (c - 6) + ' ' + (y + 12) + ' ' + c + ' ' + (y + 12) + ' Z', filled: true };
      case 'cheer':
        return { eyeL: 'M' + (l - 6) + ' ' + (y + 2) + ' Q' + l + ' ' + (y - 5) + ' ' + (l + 6) + ' ' + (y + 2),
          eyeR: 'M' + (r - 6) + ' ' + (y + 2) + ' Q' + r + ' ' + (y - 5) + ' ' + (r + 6) + ' ' + (y + 2), eyeWidth: 3.5,
          mouth: 'M' + (c - 10) + ' ' + (y + 12) + ' L' + (c + 10) + ' ' + (y + 12) + ' Q' + c + ' ' + (y + 28) + ' ' + (c - 10) + ' ' + (y + 12) + ' Z', filled: true };
      case 'sleepy':
        return { eyeL: 'M' + (l - 6) + ' ' + (y + 1) + ' L' + (l + 6) + ' ' + (y + 1), eyeR: 'M' + (r - 6) + ' ' + (y + 1) + ' L' + (r + 6) + ' ' + (y + 1), eyeWidth: 3.5,
          mouth: 'M' + (c - 3) + ' ' + (y + 16) + ' Q' + c + ' ' + (y + 18) + ' ' + (c + 3) + ' ' + (y + 16), filled: false };
    }
    throw new Error('Art.character: unknown mood ' + mood);
  }

  /** Crew.Face.draw: eyes blink (scale y to 0.1 around the eye line) on hello and cheer only. */
  function crewFace(mood, y, on, blinkPeriod, color) {
    const F = makeFace(mood, y);
    const blinks = on && (mood === 'hello' || mood === 'cheer');
    const eyes = strokeP(F.eyeL, color, F.eyeWidth) + strokeP(F.eyeR, color, F.eyeWidth);
    let s = around(100, y, (x) => tg(blinks, 'scale', T([[1, 1], [1, 1], [1, 0.1], [1, 1]], blinkPeriod, { times: [0, 0.92, 0.96, 1] }), x), eyes);
    if (F.filled) s += fillP(F.mouth, color);
    return s + strokeP(F.mouth, color, 3.5);
  }

  function crewZzz(x, y, on, color) {
    return tg(on, 'translate', T([[0, 0], [5, -8], [0, 0]], 3),
      strokeP('M' + x + ' ' + y + ' h12 l-12 12 h12', color, 3) +
      strokeP('M' + (x + 20) + ' ' + (y - 20) + ' h8 l-8 8 h8', color, 3));
  }

  /** Crew.pose: translate(p) scale(s) rotate(r) translate(−p), each part following its own track. */
  function crewPose(on, px, py, scaleTrack, swayTrack, content) {
    return around(px, py, (x) => tg(on, 'scale', scaleTrack, swayTrack ? tg(on, 'rotate', swayTrack, x) : x), content);
  }

  function xeroBody(mood, stage, on, id) {
    const cheer = mood === 'cheer';
    const body = {
      hello: T([[1, 1], [1.025, 0.985], [1, 1]], 5, { times: CREW_SPLINE, spline: true }),
      calm: T([[1, 1], [1.02, 0.99], [1, 1]], 6, { times: CREW_SPLINE, spline: true }),
      breathe: T([[1, 1], [1.07, 1.07], [1, 1]], 10, { times: [0, 0.4, 1], spline: true }),
      cheer: T([[1, 1], [1.08, 0.9], [0.96, 1.06], [1, 1], [1, 1]], 1.4, { times: CHEER_TIMES, spline: true }),
      sleepy: T([[1, 1], [1.015, 0.99], [1, 1]], 7, { times: CREW_SPLINE, spline: true }),
    }[mood];
    const hop = cheer ? T([[0, 0], [0, 0], [0, -18], [0, 0], [0, 0]], 1.4, { times: CHEER_TIMES, spline: true }) : null;
    const sway = mood === 'sleepy' ? T([-3, 3, -3], 7, { times: CREW_SPLINE, spline: true }) : null;
    const sunRest = [168, 156, 142, 128][stage - 1];
    const sunTrack = mood === 'breathe'
      ? T([sunRest, sunRest - 16, sunRest], 10, { times: [0, 0.4, 1], spline: true })
      : T([sunRest, sunRest - 3, sunRest], 4, { times: CREW_SPLINE, spline: true });
    const coral = '#FF7155';

    let inner = '<defs>' + el('clipPath', { id: id('hole') }, el('ellipse', { cx: 100, cy: 138, rx: 21, ry: 29 })) + '</defs>';
    // The hole: sky, a rising sun and a hill, clipped to the hole.
    inner += fillE(100, 138, 21, 29, '#BFD7FF');
    inner += el('g', { 'clip-path': 'url(#' + id('hole') + ')' },
      fillC(100, sunRest, 11, '#FFC93C', 1, on ? anim('cy', sunTrack) : '') +
      fillP('M76 160 C90 152 110 156 124 150 L124 172 L76 172 Z', '#3FB37F'));
    // Feet and arms.
    inner += fillE(84, 188, 12, 7, '#C9542F') + fillE(116, 188, 12, 7, '#C9542F');
    inner += strokeP(cheer ? 'M38 112 C28 98 24 86 26 74' : 'M36 124 C26 132 22 142 24 152', coral, 12);
    inner += strokeP(cheer ? 'M162 112 C172 98 176 86 174 74' : 'M164 124 C174 132 178 142 176 152', coral, 12);
    // Body with the hole cut out, shade and highlight.
    inner += fillP('M100 34 C138 34 166 68 166 112 C166 156 138 188 100 188 C62 188 34 156 34 112 C34 68 62 34 100 34 Z M100 109 C112 109 121 121 121 138 C121 155 112 167 100 167 C88 167 79 155 79 138 C79 121 88 109 100 109 Z',
      coral, 1, { 'fill-rule': 'evenodd' });
    inner += fillP('M136 52 C156 70 166 92 166 112 C166 156 138 188 100 188 C126 178 146 150 146 112 C146 88 142 68 136 52 Z', '#E85A3E');
    inner += strokeP('M58 82 C62 66 74 52 90 46', '#FFB09C', 6);
    if (stage >= 4) {
      inner += strokeP('M100 24 l0 -10', '#FFC93C', 3) + strokeP('M146 40 l7 -7', '#FFC93C', 3) + strokeP('M54 40 l-7 -7', '#FFC93C', 3);
    }
    inner += fillC(72, 92, 7, '#FFB09C', 0.8) + fillC(128, 92, 7, '#FFB09C', 0.8);
    inner += crewFace(mood, 78, on, 4.5, CREW_INK);

    // Ground shadow stays put.
    let s = fillE(100, 192, 48, 6, '#000000', 0.12);
    s += tg(on, 'translate', hop, crewPose(on, 100, 190, body, sway, inner));
    // Marks outside the body.
    if (cheer) s += strokeP('M26 64 l0 12 M20 70 l12 0', CREW_INK, 3) + strokeP('M174 70 l0 10 M169 75 l10 0', CREW_INK, 3);
    if (mood === 'sleepy') s += crewZzz(150, 40, on, CREW_INK);
    if (mood === 'breathe') {
      s += tg(on, 'translate', T([[0, 0], [8, 0], [0, 0]], 5),
        strokeP('M172 100 q8 -5 16 0', CREW_INK, 3) + strokeP('M176 112 q6 -4 12 0', CREW_INK, 3));
    }
    return s;
  }

  /** A tentacle; `k` runs 1 → −1 → 1 to make it wave (the path is linear in k, so SMIL d-morphing is exact). */
  function tentacle(x, k) {
    return 'M' + f(x) + ' 122 C' + f(x - 6 * k) + ' 138 ' + f(x + 6 * k) + ' 152 ' + f(x) + ' 166 C' + f(x - 4 * k) + ' 174 ' + f(x + 2 * k) + ' 180 ' + f(x - 2 * k) + ' 186';
  }

  function jelliBody(mood, stage, on) {
    const cheer = mood === 'cheer';
    const body = {
      hello: T([[1, 1], [1.06, 0.95], [1, 1]], 3, { times: [0, 0.35, 1], spline: true }),
      calm: T([[1, 1], [1.04, 0.97], [1, 1]], 5, { times: [0, 0.4, 1], spline: true }),
      breathe: T([[1, 1], [1.12, 1.05], [1, 1]], 10, { times: [0, 0.4, 1], spline: true }),
      cheer: T([[1, 1], [1.12, 0.88], [0.95, 1.06], [1, 1], [1, 1]], 1.2, { times: CHEER_TIMES, spline: true }),
      sleepy: T([[1, 1], [1.03, 0.98], [1, 1]], 7, { times: CREW_SPLINE, spline: true }),
    }[mood];
    const hop = cheer
      ? T([[0, 0], [0, 0], [0, -18], [0, 0], [0, 0]], 1.2, { times: CHEER_TIMES, spline: true })
      : T([[0, 0], [0, -7], [0, 0]], mood === 'sleepy' ? 7 : 4, { times: CREW_SPLINE, spline: true });
    const sway = mood === 'sleepy' ? T([-4, 4, -4], 7, { times: CREW_SPLINE, spline: true }) : null;

    let s = fillE(100, 194, 34, 4, '#000000', 0.08);
    if (mood === 'breathe' || mood === 'calm') {
      s += strokeC(160, 150, 5, '#FFFFFF', 2.5, { kids: on ? anim('cy', T([160, 60], 4)) : '' });
      s += strokeC(44, 130, 3.5, '#FFFFFF', 2.5, { kids: on ? anim('cy', T([130, 40], 5, { begin: 1 })) : '' });
    }
    let inner = '';
    if (stage >= 4) inner += fillP('M100 18 l4 9 l9 1 l-7 6 l2 9 l-8 -5 l-8 5 l2 -9 l-7 -6 l9 -1 Z', '#FFC93C');
    // Four tentacles wave out of step, 0.3 s apart.
    [78, 93, 108, 123].forEach((x, i) => {
      inner += strokeP(tentacle(x, 1), i % 2 === 0 ? '#F07188' : '#FF8FA3', 5,
        { kids: on ? anim('d', T([tentacle(x, 1), tentacle(x, -1), tentacle(x, 1)], 2.4, { begin: 0.3 * i })) : '' });
    });
    inner += strokeP(cheer ? 'M56 118 C42 106 38 92 44 78' : 'M58 120 C50 136 60 150 52 166', '#FFC2CD', 10);
    inner += strokeP(cheer ? 'M144 118 C158 106 162 92 156 78' : 'M142 120 C150 136 140 150 148 166', '#FFC2CD', 10);

    const glint = '#FFF1B8';
    let b = fillP('M42 112 C40 68 66 44 100 44 C134 44 160 68 158 112 C158 120 152 124 144 121 C136 128 126 128 118 121 C110 128 90 128 82 121 C74 128 64 128 56 121 C48 124 42 120 42 112 Z', '#FF8FA3');
    b += fillP('M120 48 C146 58 160 82 158 112 C158 120 152 124 144 121 C148 94 140 68 120 48 Z', '#F07188');
    b += fillP('M48 110 C70 116 130 116 152 110 C152 114 150 116 146 116 C120 122 80 122 54 116 C50 116 48 114 48 110 Z', '#FFB3C1');
    b += strokeP('M62 78 C66 62 78 52 94 48', '#FFD6DE', 7);
    b += fillC(62, 96, 4, glint);
    if (stage >= 2) b += fillC(140, 88, 4, glint) + fillC(132, 66, 3, glint);
    if (stage >= 3) b += fillC(74, 64, 3, glint) + fillC(148, 104, 3, glint);
    b += fillC(72, 104, 7, '#FF6F8E', 0.6) + fillC(128, 104, 7, '#FF6F8E', 0.6);
    b += crewFace(mood, 92, on, 4.2, CREW_INK);
    inner += crewPose(on, 100, 44, body, sway, b);

    s += tg(on, 'translate', hop, inner);
    if (cheer) s += strokeP('M24 60 l0 12 M18 66 l12 0', CREW_INK, 3) + strokeP('M176 56 l0 10 M171 61 l10 0', CREW_INK, 3);
    if (mood === 'sleepy') s += crewZzz(154, 30, on, CREW_INK);
    return s;
  }

  function glimBody(mood, stage, on, id) {
    const cheer = mood === 'cheer';
    const yellow = '#FFE27A';
    const body = {
      hello: T([[1, 1], [1.025, 0.985], [1, 1]], 4, { times: CREW_SPLINE, spline: true }),
      calm: T([[1, 1], [1.02, 0.99], [1, 1]], 6, { times: CREW_SPLINE, spline: true }),
      breathe: T([[1, 1], [1.07, 1.07], [1, 1]], 10, { times: [0, 0.4, 1], spline: true }),
      cheer: T([[1, 1], [1.08, 0.9], [0.96, 1.06], [1, 1], [1, 1]], 1.3, { times: CHEER_TIMES, spline: true }),
      sleepy: T([[1, 1], [1.015, 0.99], [1, 1]], 7, { times: CREW_SPLINE, spline: true }),
    }[mood];
    const hop = cheer
      ? T([[0, 0], [0, 0], [0, -18], [0, 0], [0, 0]], 1.3, { times: CHEER_TIMES, spline: true })
      : T([[0, 0], [0, -7], [0, 0]], mood === 'sleepy' ? 7 : 3, { times: CREW_SPLINE, spline: true });
    const sway = mood === 'sleepy' ? T([-4, 4, -4], 7, { times: CREW_SPLINE, spline: true }) : null;
    // Wings flap fast when awake, slowly when calm or breathing, not at all when sleepy.
    const flap = mood === 'sleepy' ? null : (mood === 'breathe' || mood === 'calm' ? 1.2 : 0.3);
    const base = [30, 38, 48, 58][stage - 1];
    const glowPeriod = mood === 'breathe' ? 10 : 2.6;
    const m = 1 + 0.15 * (stage - 1);
    const reachOf = (r) => Math.min(r * 1.6, 50);
    const stop0 = (o) => Math.min(1, o * m * 2);
    const stop1 = (o) => Math.min(1, o * m * 1.4);

    let s = fillE(100, 194, 34, 4, '#000000', 0.1);
    if (stage >= 4) {
      [['M30 60 l3 7 l7 3 l-7 3 l-3 7 l-3 -7 l-7 -3 l7 -3 Z', 1.8, 0],
        ['M168 120 l2.5 5 l5 2.5 l-5 2.5 l-2.5 5 l-2.5 -5 l-5 -2.5 l5 -2.5 Z', 2.3, 0.6],
        ['M40 160 l2 4 l4 2 l-4 2 l-2 4 l-2 -4 l-4 -2 l4 -2 Z', 2.0, 1.1]].forEach(([d, period, begin]) => {
        s += fillP(d, yellow, 1, null, on ? anim('fill-opacity', T([0.2, 1, 0.2], period, { begin })) : '');
      });
    }

    // Tail glow: a radial light added (plus-lighter) to what's behind it, capped at reach 50.
    const rT = mapTrack([base, base + 10, base], [0, 0.5, 1], reachOf, [50 / 1.6]);
    const o0 = mapTrack([0.22, 0.45, 0.22], [0, 0.5, 1], stop0, [1 / (2 * m)]);
    const o1 = mapTrack([0.22, 0.45, 0.22], [0, 0.5, 1], stop1, [1 / (1.4 * m)]);
    const reach = reachOf(base);
    const strength = 0.3 * m;
    let defs = '<defs>' + el('radialGradient', { id: id('tail'), gradientUnits: 'userSpaceOnUse', cx: 100, cy: 150, r: reach },
      el('stop', { offset: 0, 'stop-color': yellow, 'stop-opacity': Math.min(1, strength * 2) }, on ? anim('stop-opacity', T(o0.values, glowPeriod, { times: o0.times })) : '') +
      el('stop', { offset: 0.4, 'stop-color': yellow, 'stop-opacity': Math.min(1, strength * 1.4) }, on ? anim('stop-opacity', T(o1.values, glowPeriod, { times: o1.times })) : '') +
      el('stop', { offset: 1, 'stop-color': yellow, 'stop-opacity': 0 }) +
      (on ? anim('r', T(rT.values, glowPeriod, { times: rT.times })) : '')) + '</defs>';
    let inner = defs + el('circle', { cx: 100, cy: 150, r: reach, fill: 'url(#' + id('tail') + ')', style: 'mix-blend-mode:plus-lighter' },
      on ? anim('r', T(rT.values, glowPeriod, { times: rT.times })) : '');

    let b = '';
    // Wings rotate about their roots.
    for (const side of [-1, 1]) {
      const rootX = 100 + 16 * side, cx = 100 + 42 * side;
      const wingTrack = flap ? T([0, 14 * side, 0], flap) : null;
      b += around(rootX, 82, (x) => tg(on && !!flap, 'rotate', wingTrack, x, 0),
        g('translate(' + cx + ' 66) rotate(' + 28 * side + ') translate(' + -cx + ' -66)',
          fillE(cx, 66, 30, 17, '#E9F1FF', 0.92) + strokeE(cx, 66, 30, 17, '#B9C6F2', 2)) +
        strokeP(side < 0 ? 'M40 74 C52 66 66 62 80 64' : 'M160 74 C148 66 134 62 120 64', '#B9C6F2', 1.5));
    }
    const shade = '#5638C4', head = '#6B4FD8';
    b += strokeP('M90 62 C84 50 78 40 74 32', shade, 3.5) + strokeP('M110 62 C116 50 122 40 126 32', shade, 3.5);
    b += fillC(73, 29, 6, yellow) + fillC(127, 29, 6, yellow);
    b += fillE(100, 150, 33, 31, yellow);
    b += strokeP('M70 146 C84 154 116 154 130 146 M72 160 C86 168 114 168 128 160', '#F2C94C', 3.5);
    b += strokeP('M80 132 C86 126 94 124 100 124', '#FFF6C8', 4);
    b += strokeP(cheer ? 'M66 108 C54 98 50 86 52 74' : 'M64 114 C54 120 50 128 52 136', head, 9);
    b += strokeP(cheer ? 'M134 108 C146 98 150 86 148 74' : 'M136 114 C146 120 150 128 148 136', head, 9);
    b += fillC(100, 96, 40, head);
    b += fillP('M124 64 C136 74 142 88 140 102 C138 118 126 132 108 136 C124 124 132 108 130 94 C129 82 126 72 124 64 Z', shade);
    b += strokeP('M70 84 C72 72 80 64 90 60', '#9A84F0', 5);
    b += fillC(74, 106, 6, '#FF8FA3', 0.8) + fillC(126, 106, 6, '#FF8FA3', 0.8);
    b += crewFace(mood, 94, on, 4.4, '#FFF8EE');
    inner += crewPose(on, 100, 120, body, sway, b);

    s += tg(on, 'translate', hop, inner);
    if (mood === 'sleepy') s += crewZzz(150, 34, on, '#9A84F0');
    return s;
  }

  const characters = ['xero', 'jelli', 'glim'];
  const moods = { xero: MOODS.slice(), jelli: MOODS.slice(), glim: MOODS.slice() };

  function character(name, opts) {
    opts = opts || {};
    let size = opts.size === undefined ? 140 : opts.size;
    if (typeof size === 'string') size = characterSizes[size] || 140;
    const mood = opts.mood || 'hello';
    if (MOODS.indexOf(mood) < 0) throw new Error('Art.character: unknown mood ' + mood);
    const stage = Math.min(4, Math.max(1, Math.round(opts.stage || 1)));
    const on = opts.animate !== false;
    const id = ids();
    let inner;
    if (name === 'xero') inner = xeroBody(mood, stage, on, id);
    else if (name === 'jelli') inner = jelliBody(mood, stage, on);
    else if (name === 'glim') inner = glimBody(mood, stage, on, id);
    else throw new Error('Art.character: unknown character ' + name);
    // isolation: the Canvas is its own layer, so Glim's plus-lighter glow only adds to the drawing itself.
    return svgOpen(size, size, '0 0 200 200', 'isolation:isolate') + inner + '</svg>';
  }

  // ---------------------------------------------------------------------------
  // HorizonScene (400 × 300) and HeroScene
  // ---------------------------------------------------------------------------

  const horizonKinds = ['dawn', 'dusk', 'path', 'sea', 'night'];
  const horizonFits = ['top', 'middle', 'bottom'];
  const SKIES = {
    dawn: [[0, '#FF7E5A'], [0.55, '#FFB877'], [1, '#FFE6BF']],
    day: [[0, '#5AA9FF'], [1, '#D3EEFF']],
    dusk: [[0, '#7A5CE0'], [0.6, '#E58BB8'], [1, '#FFC59A']],
    night: [[0, '#180F52'], [1, '#5A3CC4']],
  };

  function horizonContent(kind, clarity, on, id) {
    const defs = [];
    const fog = 1 - clarity / 100;
    const haze = kind === 'night' ? '#8E80C9' : (kind === 'dusk' ? '#E9D6F0' : '#F3ECE3');
    const hazeRect = (op) => (op > 0 ? el('rect', { width: 400, height: 300, fill: haze, 'fill-opacity': op }) : '');
    const box = 'filterUnits="userSpaceOnUse" x="-120" y="-60" width="640" height="420" color-interpolation-filters="sRGB"';
    defs.push('<filter id="' + id('lift') + '" ' + box + '><feDropShadow dx="0" dy="-3" stdDeviation="4" flood-color="#1A0B2E" flood-opacity="0.22"/></filter>');
    defs.push('<filter id="' + id('soft') + '" ' + box + '><feGaussianBlur stdDeviation="4"/></filter>');
    defs.push(el('radialGradient', { id: id('sun'), cx: 0.38, cy: 0.32, r: 0.75 },
      el('stop', { offset: 0, 'stop-color': '#FFF6C8' }) + el('stop', { offset: 1, 'stop-color': '#FFC23A' })));
    defs.push(el('radialGradient', { id: id('glow'), cx: 0.5, cy: 0.5, r: 0.5 },
      el('stop', { offset: 0, 'stop-color': '#FFFFFF', 'stop-opacity': 0.75 }) + el('stop', { offset: 1, 'stop-color': '#FFFFFF', 'stop-opacity': 0 })));

    const sky = (name) => {
      defs.push(el('linearGradient', { id: id('sky'), gradientUnits: 'userSpaceOnUse', x1: 0, y1: 0, x2: 0, y2: 300 },
        SKIES[name].map(([o, c]) => el('stop', { offset: o, 'stop-color': c })).join('')));
      return el('rect', { width: 400, height: 300, fill: 'url(#' + id('sky') + ')' });
    };
    const sheen = (d, y0) => {
      defs.push(el('linearGradient', { id: id('sheen'), gradientUnits: 'userSpaceOnUse', x1: 0, y1: y0, x2: 0, y2: 300 },
        el('stop', { offset: 0, 'stop-color': '#FFFFFF', 'stop-opacity': 0.22 }) + el('stop', { offset: 0.35, 'stop-color': '#FFFFFF', 'stop-opacity': 0 })));
      return el('path', { d, fill: 'url(#' + id('sheen') + ')' });
    };
    // The sun's radial gradient sits up and left (cx 0.38, cy 0.32, r 0.75 of the bounding box).
    const sunDisc = (cx, cy, r, kids) => el('circle', { cx, cy, r, fill: 'url(#' + id('sun') + ')' }, kids);
    const glowDisc = (cx, cy, r, opacity, kids) => el('circle', { cx, cy, r, fill: 'url(#' + id('glow') + ')', opacity }, kids);
    /** A paper layer with the upward "lift" shadow. */
    const layer = (d, c) => el('path', { d, fill: c, filter: 'url(#' + id('lift') + ')' });
    const clouds = (ellipses, c, opacity, period) =>
      tg(on, 'translate', T([[0, 0], [22, 0], [0, 0]], period),
        ellipses.map((e) => el('ellipse', { cx: e[0], cy: e[1], rx: e[2], ry: e[3], fill: c, opacity, filter: 'url(#' + id('soft') + ')' })).join(''));
    const twinkle = (attr, period, begin) => (on ? anim(attr, T([0.25, 1, 0.25], period, { begin: begin || 0 })) : '');
    const pulseKids = (dur) => (on ? anim('r', T([120, 140, 120], dur)) : '');

    let s = '';
    switch (kind) {
      case 'dawn': {
        s += sky('dawn');
        s += glowDisc(200, 168, 130, 0.6, pulseKids(6));
        const sunY = 168 + Math.round(fog * 20);
        // The sun rises 60 pt over 2.6 s when the scene appears, then stays.
        s += sunDisc(200, sunY, 70, on ? anim('cy', T([sunY + 60, sunY], 2.6, { once: true, spline: '0.2 0.7 0.2 1' })) : '');
        s += clouds([[70, 86, 46, 14], [98, 74, 28, 14], [330, 62, 40, 12]], '#FFF4E6', 0.85, 24);
        s += hazeRect(fog * 0.7);
        s += layer('M0 192 C60 162 120 172 180 187 C250 204 320 172 400 166 L400 300 L0 300 Z', '#FF9D6E');
        const middle = 'M0 222 C80 196 150 206 220 224 C290 240 350 216 400 206 L400 300 L0 300 Z';
        s += layer(middle, '#FF7A55');
        s += layer('M0 252 C70 233 140 241 210 256 C280 271 340 251 400 243 L400 300 L0 300 Z', '#E85A3E');
        s += layer('M0 282 C90 267 180 273 260 283 C320 291 360 285 400 279 L400 300 L0 300 Z', '#C2402A');
        s += sheen(middle, 196);
        s += el('path', { d: 'M330 34 Q330 46 342 46 Q330 46 330 58 Q330 46 318 46 Q330 46 330 34 Z', fill: '#FFF8EE' }, twinkle('opacity', 2.2));
        break;
      }
      case 'dusk':
        s += sky('dusk');
        s += glowDisc(300, 190, 110, 0.45);
        s += fillC(300, 196, 44, '#FFB86B');
        s += clouds([[90, 80, 52, 14], [120, 68, 30, 14]], '#FFE0EE', 0.8, 26);
        s += [[70, 40, 1.6, 1.9, 0], [200, 30, 1.4, 2.6, 0.7]].map(([x, y, r, p, b]) => fillC(x, y, r, '#FFF8EE', 1, twinkle('fill-opacity', p, b))).join('');
        s += hazeRect(fog * 0.7);
        s += layer('M0 196 C70 170 140 178 200 192 C270 208 330 180 400 172 L400 300 L0 300 Z', '#B572C9');
        s += layer('M0 228 C90 202 160 212 230 230 C300 246 350 222 400 214 L400 300 L0 300 Z', '#8E55BF');
        s += layer('M0 258 C80 238 150 246 220 262 C290 278 350 258 400 250 L400 300 L0 300 Z', '#6A3AA8');
        s += layer('M0 286 C90 272 160 278 240 288 C310 296 360 290 400 284 L400 300 L0 300 Z', '#4A2588');
        break;
      case 'path': {
        s += sky('day');
        s += glowDisc(300, 78, 70, 0.6);
        s += sunDisc(300, 78, 30);
        s += clouds([[80, 70, 50, 15], [110, 58, 30, 15], [370, 130, 40, 12]], '#FFFFFF', 0.9, 22);
        s += hazeRect(fog * 0.7);
        s += layer('M0 176 C70 150 140 158 200 172 C270 188 330 160 400 150 L400 300 L0 300 Z', '#9FE3AE');
        s += fillP('M70 168 L78 146 L86 168 Z M92 166 L98 150 L104 166 Z', '#3FA868');
        const middle = 'M0 210 C90 184 160 194 230 212 C300 228 350 204 400 196 L400 300 L0 300 Z';
        s += layer(middle, '#5CC984');
        s += layer('M0 246 C80 226 150 234 220 250 C290 266 350 246 400 238 L400 300 L0 300 Z', '#2FA262');
        s += fillP('M176 300 C188 282 236 272 228 256 C222 244 202 236 206 224 L212 224 C212 236 236 244 242 258 C252 278 216 288 224 300 Z', '#FFF1D2');
        s += layer('M0 284 C90 270 160 276 240 286 C310 294 360 288 400 282 L400 300 L0 300 Z', '#1E7A4B');
        s += sheen(middle, 184);
        break;
      }
      case 'sea': {
        s += sky('day');
        s += glowDisc(110, 96, 130, 0.6, pulseKids(10));
        s += sunDisc(110, 96, 34);
        s += clouds([[300, 64, 56, 15], [330, 52, 30, 14]], '#FFFFFF', 0.9, 20);
        s += hazeRect(fog * 0.7);
        const a = [[0, 0], [-18, 2], [0, 0]], b = [[0, 0], [20, -3], [0, 0]], c = [[0, 0], [-26, 3], [0, 0]];
        const wave = (values, period, inner) => tg(on, 'translate', T(values, period), inner);
        s += wave(a, 7, layer('M-40 176 C10 166 60 172 110 168 C180 162 260 170 440 164 L440 300 L-40 300 Z', '#9CCBFF'));
        s += wave(b, 5, layer('M-40 206 C20 190 70 196 120 208 C180 222 240 196 300 194 C350 193 400 198 440 202 L440 300 L-40 300 Z', '#5A9DFF'));
        s += wave(c, 6, layer('M-40 240 C10 222 60 226 110 240 C160 254 210 230 260 228 C320 226 380 234 440 240 L440 300 L-40 300 Z', '#2F72F2') +
          fillP('M90 236 C102 222 122 220 132 232 C120 230 110 234 104 242 Z', '#FFF8EE'));
        s += wave(b, 8, layer('M-40 276 C20 262 80 266 140 276 C200 286 260 268 440 272 L440 300 L-40 300 Z', '#1C4FCC'));
        s += fillC(300, on ? 270 : 260, 3, '#FFFFFF', 0.7, on ? anim('cy', T([270, 170], 5)) : '');
        break;
      }
      case 'night': {
        s += sky('night');
        s += [[60, 40, 1.8, 2, 0], [150, 24, 1.4, 2.7, 0.4], [230, 60, 1.6, 1.8, 1], [360, 110, 1.4, 2.4, 0.2], [30, 120, 1.2, 3, 0.9]]
          .map(([x, y, r, p, b]) => fillC(x, y, r, '#FFF8EE', 1, twinkle('fill-opacity', p, b))).join('');
        s += glowDisc(290, 80, 70, 0.35);
        s += fillP('M290 46 A34 34 0 1 0 322 98 A28 28 0 1 1 290 46 Z', '#FFF1C2');
        s += hazeRect(fog * 0.7);
        s += layer('M0 184 C70 158 140 166 200 180 C270 196 330 168 400 160 L400 300 L0 300 Z', '#5A3CC4');
        s += layer('M0 218 C90 192 160 202 230 220 C300 236 350 212 400 204 L400 300 L0 300 Z', '#432AA6');
        s += layer('M0 252 C80 232 150 240 220 256 C290 272 350 252 400 244 L400 300 L0 300 Z', '#2F1C84');
        s += layer('M0 284 C90 270 160 276 240 286 C310 294 360 288 400 282 L400 300 L0 300 Z', '#1C1160');
        // Fireflies drift together.
        const yellow = '#FFE27A';
        s += tg(on, 'translate', T([[0, 0], [14, -10], [-8, -4], [0, 0]], 9),
          [[96, 230, 3, 8, 1.6, 0], [300, 250, 2.5, 7, 2.1, 0.5], [190, 214, 2, 0, 1.3, 0.2]].map(([x, y, r, halo, p, b]) =>
            fillC(x, y, r, yellow, 1, twinkle('fill-opacity', p, b)) + (halo > 0 ? fillC(x, y, halo, yellow, 0.25) : '')).join(''));
        break;
      }
      default:
        throw new Error('Art.horizon: unknown kind ' + kind);
    }
    s += hazeRect(fog * 0.35);
    return '<defs>' + defs.join('') + '</defs>' + s;
  }

  /** HorizonScene's canvas transform: cover (slice), centred horizontally, top/middle/bottom vertically. */
  function horizonTransform(W, H, fit) {
    const scale = Math.max(W / 400, H / 300);
    const dx = (W - 400 * scale) / 2;
    const slack = H - 300 * scale;
    const dy = fit === 'top' ? 0 : (fit === 'bottom' ? slack : slack / 2);
    return 'translate(' + f(dx) + ' ' + f(dy) + ') scale(' + f(scale) + ')';
  }

  function horizon(opts) {
    opts = opts || {};
    const W = opts.width || 390, H = opts.height || 300;
    const kind = opts.kind || 'dawn';
    const clarity = Math.min(100, Math.max(0, opts.clarity === undefined ? 100 : opts.clarity));
    const fit = opts.fit || 'middle';
    const on = opts.animate !== false;
    const id = ids();
    return svgOpen(W, H, '0 0 ' + f(W) + ' ' + f(H), 'overflow:hidden') +
      '<defs>' + el('clipPath', { id: id('clip') }, el('rect', { width: W, height: H })) + '</defs>' +
      el('g', { 'clip-path': 'url(#' + id('clip') + ')' }, g(horizonTransform(W, H, fit), horizonContent(kind, clarity, on, id))) + '</svg>';
  }

  /** HeroScene: a horizon (fit bottom) with the curved paper edge in the screen's ground colour. */
  function hero(opts) {
    opts = opts || {};
    const W = opts.width || 390, H = opts.height || 300;
    const kind = opts.kind || 'dawn';
    const clarity = Math.min(100, Math.max(0, opts.clarity === undefined ? 100 : opts.clarity));
    const on = opts.animate !== false;
    const edge = hex(opts.edge || '#FBF7F1');
    const id = ids();
    const sx = W / 390;
    const d = 'M0 ' + f(H - 30) + ' C' + f(110 * sx) + ' ' + f(H - 54) + ' ' + f(280 * sx) + ' ' + f(H - 54) + ' ' + f(390 * sx) + ' ' + f(H - 30) +
      ' L' + f(W) + ' ' + f(H) + ' L0 ' + f(H) + ' Z';
    return svgOpen(W, H, '0 0 ' + f(W) + ' ' + f(H), 'overflow:hidden') +
      '<defs>' + el('clipPath', { id: id('clip') }, el('rect', { width: W, height: H })) +
      '<filter id="' + id('edge') + '" filterUnits="userSpaceOnUse" x="-20" y="' + f(H - 100) + '" width="' + f(W + 40) + '" height="140" color-interpolation-filters="sRGB">' +
      '<feDropShadow dx="0" dy="-4" stdDeviation="6" flood-color="#1A0B2E" flood-opacity="0.26"/></filter></defs>' +
      el('g', { 'clip-path': 'url(#' + id('clip') + ')' },
        g(horizonTransform(W, H, 'bottom'), horizonContent(kind, clarity, on, id)) +
        el('path', { d, fill: edge, filter: 'url(#' + id('edge') + ')' })) + '</svg>';
  }

  // ---------------------------------------------------------------------------
  // CalmHeaderArt (240 × 196)
  // ---------------------------------------------------------------------------

  /**
   * A person sitting on a cloud, a dotted halo breathing on the 4 in, 6 out clock (DX.Move.breath).
   * The frame is a fixed 240 × 196, centred in the requested size, as `.frame(maxWidth: .infinity)` does.
   */
  function calmHeader(opts) {
    opts = opts || {};
    const W = opts.width || 240, H = opts.height || 196;
    const on = opts.animate !== false;
    // Circle().strokeBorder(2.5) in a (104 + 20·breath) square: radius = side / 2 − 1.25, centre (120, 98 − 18).
    const r = (b) => (104 + 20 * b) / 2 - 1.25;
    const halo = strokeC(120, 80, r(0.5), CREAM, 2.5, {
      cap: 'round', dash: '2 7',
      kids: on ? anim('r', T([r(0), r(1), r(0)], 10, { times: [0, 0.4, 1], spline: SINE })) : '',
    });
    const cloud = g('translate(36 126) scale(' + f(168 / 170) + ' 1)',
      fillP('M16 52 C4 52 0 34 14 30 C14 14 34 8 44 18 C50 2 76 0 84 16 C92 4 118 4 124 20 C136 12 156 18 154 34 C168 34 170 52 156 52 Z', CREAM));
    // PersonFigure(.meditate, height: 112, shirt: 0xFF8FB8), offset y 4.
    const pw = (112 * 100) / 120;
    const figure = g('translate(' + f((240 - pw) / 2) + ' ' + f((196 - 112) / 2 + 4) + ') scale(' + f(112 / 120) + ')',
      personBody('meditate', '#FF8FB8', '#8A5A3C', on));
    return svgOpen(W, H, f((240 - W) / 2) + ' ' + f((196 - H) / 2) + ' ' + f(W) + ' ' + f(H)) + halo + cloud + figure + '</svg>';
  }

  // ---------------------------------------------------------------------------
  // Health timeline illustrations (MilestoneIllustrations.swift), 64 × 64
  // ---------------------------------------------------------------------------

  const healthIds = ['heart-rate', 'carbon-monoxide', 'circulation', 'coughing', 'heart-attack', 'mouth-cancer',
    'lung-cancer', 'heart-disease', 'withdrawal-start', 'nicotine-gone', 'withdrawal-peak', 'mood',
    'cravings-fade', 'taste', 'fresh-breath', 'lips', 'skin-glow', 'hair', 'even-tone', 'sleep'];

  const HI = {
    coral: '#FF7A66', coralDeep: '#E2563F', sky: '#7FC0F5', skyDeep: '#4F9BE6', sage: '#BCC388', sageDeep: '#8E9A55',
    olive: '#55621F', oliveDeep: '#3C4614', sun: '#F7C548', sunDeep: '#D9A52E', glass: '#FFF3CF',
    lilac: '#B7A4F2', lilacDeep: '#8E78E0', grey: '#B3B6A4', greyDeep: '#868A74', cloudShade: '#D9DCCB', white: '#FFFFFF',
  };
  const HP = {
    heart: 'M32 54 C15 43 8 33 8 23 C8 15 14 9.5 21.5 9.5 C26.5 9.5 30 12.5 32 16.5 C34 12.5 37.5 9.5 42.5 9.5 C50 9.5 56 15 56 23 C56 33 49 43 32 54 Z',
    lobeLeft: 'M29 20 C22 18 12 26 11 40 C10 50 16 54 22 52 C27 50 29 46 29 40 Z',
    lobeRight: 'M35 20 C42 18 52 26 53 40 C54 50 48 54 42 52 C37 50 35 46 35 40 Z',
    shield: 'M32 6 L53 13.5 V30 C53 43 44 52 32 58 C20 52 11 43 11 30 V13.5 Z',
    bubble: 'M14 12 H50 Q56 12 56 18 V38 Q56 44 50 44 H30 L20 53 V44 H14 Q8 44 8 38 V18 Q8 12 14 12 Z',
    vessel: 'M9 44 C9 22 28 18 32 32 C36 46 55 42 55 20',
    tooth: 'M18 14 C24 10 28 13 32 13 C36 13 40 10 46 14 C52 18 50 30 47 38 C45 45 44 54 40 54 C36 54 36 42 32 42 C28 42 28 54 24 54 C20 54 19 45 17 38 C14 30 12 18 18 14 Z',
    lips: 'M10 32 C14 24 20 20 26 22 C29 23 31 25 32 26 C33 25 35 23 38 22 C44 20 50 24 54 32 C48 44 40 48 32 48 C24 48 16 44 10 32 Z',
    moon: 'M36 10 C24 12 16 22 16 34 C16 46 26 56 38 56 C44 56 48 54 51 50 C36 50 26 40 26 28 C26 20 30 14 36 10 Z',
    cloud: 'M14 54 H40 C45 54 48 50.5 48 46 C48 41.5 44.5 38 40 38 C39 33 35 30 30 30 C24.5 30 20 34 20 39.5 C16 39.5 12 42.5 12 46.5 C12 50.5 14 54 14 54 Z',
  };

  function healthHue(id) {
    switch (id) {
      case 'heart-rate': case 'circulation': case 'heart-disease': case 'lips': return 'coral';
      case 'carbon-monoxide': case 'coughing': case 'lung-cancer': case 'fresh-breath': return 'sky';
      case 'withdrawal-start': case 'cravings-fade': case 'hair': case 'sleep': return 'lilac';
      case 'nicotine-gone': case 'mood': case 'skin-glow': return 'sun';
      default: return 'sage';
    }
  }
  const HEALTH_TINT = {
    coral: [['#FFE5DF', 1], ['#FF7A66', 0.18]],
    sky: [['#E1F0FD', 1], ['#7FC0F5', 0.18]],
    sage: [['#E9ECD7', 1], ['#BCC388', 0.2]],
    lilac: [['#EEEAFD', 1], ['#B7A4F2', 0.2]],
    sun: [['#FDF2D2', 1], ['#F7C548', 0.18]],
  };

  function healthContent(id, still, ids_) {
    const on = !still;
    /** Clock.swing: 0.5 − 0.5·cos(2πp) mapped to lo…hi…lo (half-cosine ease each way). */
    const swing = (lo, hi, period, delay) => T([lo, hi, lo], period, { times: [0, 0.5, 1], spline: SINE, begin: delay || 0 });
    const swingXY = (lo, hi, period, delay) => T([lo, hi, lo], period, { times: [0, 0.5, 1], spline: SINE, begin: delay || 0 });
    const beat = T([1, 1.1, 1, 1.06, 1, 1], 1.6, { times: [0, 0.14, 0.28, 0.42, 0.6, 1] });
    const scaled = (px, py, track, rest, content) => around(px, py, (x) => tg(on, 'scale', track, x, rest), content);
    const rotated = (px, py, track, rest, content) => around(px, py, (x) => tg(on, 'rotate', track, x, rest), content);
    const bob = (amount, content) => tg(on, 'translate', swingXY([0, 0], [0, -amount], 2.8), content, 0);
    const sw = (d, c, w, o) => strokeP(d, c, w, o);
    const E = (cx, cy, rx, ry, c, op, extra) => fillE(cx, cy, rx, ry, c, op, null, extra);
    const off = (dy) => ({ transform: 'translate(0 ' + f(dy) + ')' });
    const sway = (px, py, content) => rotated(px, py, swing(-7, 7, 3.2), 0, content);
    const breathe = (px, py, content) => scaled(px, py, swing(0.93, 1.04, 3.8), 0.996, content);

    const drawHeart = () => fillP(HP.heart, HI.coralDeep, 1, off(3)) + fillP(HP.heart, HI.coral) +
      g('translate(20 19) rotate(-35)', E(0, 0, 5, 3, HI.white, 0.55));
    const drawLungs = () => fillP(HP.lobeLeft, HI.skyDeep, 1, off(2)) + fillP(HP.lobeRight, HI.skyDeep, 1, off(2)) +
      fillP(HP.lobeLeft, HI.sky) + fillP(HP.lobeRight, HI.sky) +
      g('translate(18 34) rotate(18)', E(0, 0, 2.4, 6, HI.white, 0.5));
    const heartBeat = () => scaled(32, 32, beat, 1, drawHeart());
    /** A four-point star that twinkles every 2.2 s. */
    const sparkle = (x, y, s, delay) => {
      const d = 'M' + f(x) + ' ' + f(y - s) + ' Q' + f(x) + ' ' + f(y) + ' ' + f(x + s) + ' ' + f(y) + ' Q' + f(x) + ' ' + f(y) + ' ' + f(x) + ' ' + f(y + s) +
        ' Q' + f(x) + ' ' + f(y) + ' ' + f(x - s) + ' ' + f(y) + ' Q' + f(x) + ' ' + f(y) + ' ' + f(x) + ' ' + f(y - s) + ' Z';
      return scaled(x, y, swing(0.55, 1, 2.2, delay), 1, withOpacity(fillP(d, HI.sun), on, 1, swing(0.25, 1, 2.2, delay)));
    };
    const dashFlow = (d, c, w, op) => sw(d, c, w, { op, dash: '3 7', offset: 0, kids: on ? anim('stroke-dashoffset', T([0, 20], 1.1)) : '' });

    switch (id) {
      case 'heart-rate': {
        const trace = 'M10 32 H21 L25 25 L30 39 L34 28 L37 32 H54';
        return heartBeat() + (on
          ? sw(trace, HI.white, 3.2, { attrs: { pathLength: 1, 'stroke-dasharray': '1 1.01', 'stroke-dashoffset': 1.001 },
            kids: anim('stroke-dashoffset', T([1.001, 0, 0], 1.6, { times: [0, 0.55, 1] })) })
          : sw(trace, HI.white, 3.2));
      }
      case 'carbon-monoxide': {
        let s = E(30, 43, 19, 13, HI.coralDeep) + E(30, 41, 19, 13, HI.coral) + E(30, 41, 9, 5.5, HI.coralDeep, 0.55) +
          g('translate(20 36) rotate(-20)', E(0, 0, 4, 2, HI.white, 0.55));
        for (const [x, y, r, delay] of [[16, 20, 6, 0], [34, 14, 7.5, 0.9], [50, 22, 5, 1.7]]) {
          const fade = T([0, 1, 0], 2.6, { times: [0, 0.25, 1], begin: delay });
          const parts = withOpacity(E(x, y, r, r, HI.sky), on, 1, fade) +
            withOpacity(E(x - r * 0.33, y - r * 0.33, r * 0.3, r * 0.3, HI.white, 0.85), on, 1, fade);
          s += tg(on, 'translate', T([[0, 6], [0, -9]], 2.6, { begin: delay }), parts, 0);
        }
        s += scaled(55, 45, swing(1, 0.82, 3), 1, withOpacity(E(55, 45, 3.6, 3.6, HI.grey), on, 0.95, swing(0.95, 0.25, 3)));
        return s;
      }
      case 'circulation':
        return sw(HP.vessel, HI.coralDeep, 9, { attrs: off(2.5) }) + sw(HP.vessel, HI.coral, 9) +
          dashFlow(HP.vessel, HI.white, 2.6) + sparkle(50, 50, 5, 0) + sparkle(15, 13, 4, 0.7);
      case 'coughing':
        return breathe(32, 36, drawLungs()) +
          sw('M32 7 V25 M32 24 Q32 28 27 31 M32 24 Q32 28 37 31', HI.olive, 4) +
          [['M43 11 Q47.5 8.5 52 11', 0], ['M45 16.5 Q50 14 55.5 16.5', 0.7]].map(([d, delay]) =>
            withOpacity(sw(d, HI.skyDeep, 2.6), on, 1, swing(0.25, 1, 2.2, delay))).join('');
      case 'heart-attack':
        return fillP(HP.shield, HI.oliveDeep, 1, off(2.5)) + fillP(HP.shield, HI.olive) +
          fillP('M32 6 L53 13.5 V30 C53 43 44 52 32 58 Z', HI.white, 0.08) +
          g('translate(17.6 16.6) scale(0.45)', heartBeat()) + sparkle(53, 9, 4.5, 0);
      case 'mouth-cancer': {
        let s = fillP(HP.bubble, HI.sageDeep, 1, off(2.5)) + fillP(HP.bubble, HI.sage);
        for (let i = 0; i < 4; i++) {
          const h = (k) => 16 * k;
          const x = 19.5 + i * 7;
          const still_h = h(0.7);
          s += el('rect', { x, y: 28 - still_h / 2, width: 4.5, height: still_h, rx: 2.25, fill: HI.white },
            on ? anim('height', swing(h(0.35), h(1), 1.1, i * 0.2)) + anim('y', swing(28 - h(0.35) / 2, 28 - h(1) / 2, 1.1, i * 0.2)) : '');
        }
        return s;
      }
      case 'lung-cancer':
        return g('translate(4.8 6) scale(0.85)', breathe(32, 36, drawLungs())) +
          sw('M32 13 V27 M32 26 Q32 29 28 31.5 M32 26 Q32 29 36 31.5', HI.olive, 3.6) +
          sway(32, 14, fillP('M32 14 C26 14 20 10.5 19 4.5 C25 4.5 31 7.5 32 14 Z', HI.sage) +
            fillP('M32 14 C38 13 44 8.5 45 3.5 C39 3.5 33 7 32 14 Z', HI.sageDeep));
      case 'heart-disease':
        return g('translate(6.4 12.5) scale(0.8)', heartBeat()) +
          sw('M32 26 Q32 18 33 11', HI.sageDeep, 3) +
          sway(33, 13, fillP('M33 13 C28 13 24 10 23 5 C28 5 32 8 33 13 Z', HI.sage) +
            fillP('M33 11 C37 10 41 7 42 3 C37 3 34 6 33 11 Z', HI.sageDeep));
      case 'withdrawal-start':
        return fillP('M6 40 Q14 32 22 40 T38 40 T58 40 V54 Q58 57 55 57 H9 Q6 57 6 54 Z', HI.lilacDeep) +
          bob(2.5, sw('M33 13 V36', HI.olive, 2.4) + fillP('M34.5 15 L46 34 H34.5 Z', HI.coral) +
            fillP('M31.5 19 L23 34 H31.5 Z', HI.white) + fillP('M20 36 H46 L41.5 43 H24.5 Z', HI.olive)) +
          fillP('M6 46 Q14 40 22 46 T38 46 T58 46 V54 Q58 57 55 57 H9 Q6 57 6 54 Z', HI.lilac) +
          sw('M12 50 Q16 48 20 50', HI.white, 2, { op: 0.7 });
      case 'nicotine-gone': {
        const fade = swing(0.95, 0.25, 3);
        const mol = [sw('M22 38 L38 25 L46 42', HI.greyDeep, 3.5), E(22, 38, 8, 8, HI.grey), E(38, 25, 6, 6, HI.grey),
          E(46, 42, 6.5, 6.5, HI.grey), E(19.5, 35.5, 2.2, 2.2, HI.white, 0.6)].map((e) => withOpacity(e, on, 0.95, fade)).join('');
        return scaled(34, 33, swing(1, 0.82, 3), 1, mol) + sparkle(52, 13, 5.5, 0) + sparkle(13, 18, 4, 0.7) + sparkle(32, 53, 3.5, 1.4);
      }
      case 'withdrawal-peak':
        return fillP('M30 55 L45.5 27 L60 55 Z', HI.sage) + fillP('M4 55 L26 15 L48 55 Z', HI.olive) +
          fillP('M26 15 L33 27.7 L29.5 25 L26 29 L22.5 25 L19 27.7 Z', HI.white) +
          dashFlow('M12 55 Q20 47 17 42 Q24 37 24.5 31', HI.white, 1.8, 0.75) +
          sw('M26 15 V4', HI.oliveDeep, 2) +
          around(26, 7.5, (x) => tg(on, 'skewY', swing(0, -10, 1.4), x, 0), fillP('M26 4.5 L37 7.5 L26 10.5 Z', HI.coral)) +
          sw('M4 55 H60', HI.oliveDeep, 2.4);
      case 'mood': {
        let rays = '';
        for (let i = 0; i < 8; i++) {
          const a = (i * Math.PI) / 4;
          rays += sw('M' + f(40 + 14 * Math.cos(a)) + ' ' + f(24 + 14 * Math.sin(a)) + ' L' + f(40 + 18.5 * Math.cos(a)) + ' ' + f(24 + 18.5 * Math.sin(a)), HI.sun, 3);
        }
        return rotated(40, 24, T([0, 360], 24), 0, rays) +
          E(40, 24, 10.5, 10.5, HI.sun) + E(36.5, 20.5, 2.6, 2.6, HI.white, 0.6) +
          bob(2.5, fillP(HP.cloud, HI.cloudShade, 1, off(2.5)) + fillP(HP.cloud, HI.white));
      }
      case 'cravings-fade':
        return bob(2.5, sw('M8 21 Q14 11 20 21 T32 21 T44 21 T56 21', HI.lilacDeep, 4, { op: 0.55 })) +
          sw('M8 35 Q14 29.5 20 35 T32 35 T44 35 T56 35', HI.lilac, 4) +
          sw('M8 48 Q14 46.5 20 48 T32 48 T44 48 T50 48', HI.skyDeep, 4) +
          sparkle(56, 48, 4.5, 0);
      case 'taste': {
        // Two cherries swinging gently from their stalk.
        let bunch = sw('M22 36 Q25 21 36 11 M43 38 Q40 23 36 11', HI.olive, 3) +
          fillP('M36 11 C41 6 50 6 53 11 C48 15 41 15 36 11 Z', HI.sageDeep);
        for (const [x, y] of [[21, 42], [43, 44]]) {
          bunch += E(x, y + 2.5, 10.5, 10.5, HI.coralDeep) + E(x, y, 10.5, 10.5, HI.coral) +
            g('translate(' + f(x - 4.5) + ' ' + f(y - 4) + ') rotate(-30)', E(0, 0, 3.6, 2, HI.white, 0.55));
        }
        return sway(36, 11, bunch);
      }
      case 'fresh-breath':
        // A clean tooth that bobs a little, with twinkles.
        return bob(2, fillP(HP.tooth, HI.cloudShade, 1, off(2.5)) + fillP(HP.tooth, HI.white) +
          g('translate(22 22) rotate(-15)', E(0, 0, 2.4, 5, HI.sky, 0.6))) +
          sparkle(53, 11, 5, 0) + sparkle(10, 29, 3.2, 0.9);
      case 'lips':
        // Lips that soften and fill out, slowly.
        return scaled(32, 35, swing(0.96, 1.02, 2.6), 0.996,
          fillP(HP.lips, HI.coralDeep, 1, off(2.5)) + fillP(HP.lips, HI.coral) +
          sw('M11 32 Q32 37 53 32', HI.coralDeep, 2.6) +
          g('translate(24 40.5) rotate(-10)', E(0, 0, 5, 2.2, HI.white, 0.55))) +
          sparkle(53, 12, 5, 0.4);
      case 'skin-glow': {
        // A hand mirror with a glint sweeping across the glass.
        const clip = ids_('mirror');
        return el('path', { d: continuousRect(28.5, 40, 7, 19, 3.5), fill: HI.oliveDeep }) +
          el('path', { d: continuousRect(28.5, 38, 7, 19, 3.5), fill: HI.olive }) +
          E(32, 27.5, 17, 17, HI.sunDeep) + E(32, 25, 17, 17, HI.sun) + E(32, 25, 11.5, 11.5, HI.glass) +
          '<defs>' + el('clipPath', { id: clip }, el('ellipse', { cx: 32, cy: 25, rx: 11.5, ry: 11.5 })) + '</defs>' +
          el('g', { 'clip-path': 'url(#' + clip + ')' },
            tg(on, 'translate', T([[-14, 0], [14, 0]], 3.2), g('rotate(25)', el('rect', { x: 28, y: -10, width: 4, height: 60, fill: HI.white, 'fill-opacity': 0.8 })), [-5.6, 0])) +
          sparkle(54, 11, 5, 0) + sparkle(9, 17, 3.2, 1.1);
      }
      case 'hair': {
        // Three strands swaying from the root, each a beat behind the last.
        let s = '';
        [20, 32, 44].forEach((x, i) => {
          const d = 'M' + x + ' 56 C' + (x - 4) + ' 40 ' + (x + 6) + ' 28 ' + x + ' ' + (i === 1 ? 8 : 11);
          s += rotated(x, 56, swing(-5, 5, 3.2, i * 0.35), 0,
            sw(d, HI.lilacDeep, 7, { attrs: off(2) }) + sw(d, HI.lilac, 7) +
            (i === 1 ? sw('M33.5 13 C35 19 34.5 23 33.5 26', HI.white, 2, { op: 0.7 }) : ''));
        });
        return s + sparkle(54, 9, 4.5, 0.6);
      }
      case 'even-tone':
        // Two tones in one circle, the sun side slowly giving way. The app's absolute-path reader
        // (MilestoneDrawing.svg) has no "A" command and skips the arc's numbers, so the closing arc
        // "A19 19 0 0 1 32 15" becomes the straight close line drawn here.
        return E(32, 36.5, 19, 19, HI.sageDeep) + E(32, 34, 19, 19, HI.sage) +
          withOpacity(fillP('M32 15 C26 23 38 29 32 35 C26 41 38 46 32 53 Z', HI.sun), on, 1, swing(1, 0.55, 4)) +
          g('translate(22 26) rotate(-35)', E(0, 0, 4, 2.4, HI.white, 0.55)) +
          sparkle(53, 11, 5, 0);
      case 'sleep': {
        // A moon bobbing gently while the Zs drift up.
        let s = bob(2.5, fillP(HP.moon, HI.lilacDeep, 1, off(2.5)) + fillP(HP.moon, HI.lilac) +
          g('translate(22 30) rotate(12)', E(0, 0, 2.4, 6, HI.white, 0.5)));
        for (const [d, delay, w] of [['M40 14 H48 L40 22 H48', 0, 2.6], ['M50 28 H55 L50 33 H55', 0.8, 2.2]]) {
          s += tg(on, 'translate', T([[0, 3], [0, -3]], 2.8, { begin: delay }),
            withOpacity(sw(d, HI.white, w), on, 1, T([0, 1, 0], 2.8, { times: [0, 0.3, 1], begin: delay })), 0);
        }
        return s;
      }
      default:
        return sparkle(32, 32, 20, 0);
    }
  }

  /** HealthArt: one drawing on its 64-point grid, scaled to `size`. */
  function healthArt(id, opts) {
    opts = opts || {};
    const size = opts.size || 40;
    const still = opts.animate === false || !!opts.still;
    return svgOpen(size, size, '0 0 64 64') + healthContent(id, still, ids()) + '</svg>';
  }

  /**
   * HealthBadge: the soft circle in the body-part colour, the drawing at 68%, and the state:
   * 'done' (check), 'underWay' (progress ring, `progress` 0…1) or 'ahead' (grey and still).
   * The ring and check overhang the frame as in the app (overflow visible).
   */
  function healthBadge(id, opts) {
    opts = opts || {};
    const S = opts.size || 48;
    const state = opts.state || 'underWay';
    const dark = !!opts.dark;
    const ahead = state === 'ahead';
    const still = ahead || opts.animate === false;
    const nid = ids();
    const tint = ahead ? (dark ? ['#FFFFFF', 0.07] : ['#E7E9DD', 1]) : HEALTH_TINT[healthHue(id)][dark ? 1 : 0];
    const accent = dark ? '#2FD08A' : '#0F6E43';
    const a = S * 0.68, o = (S - a) / 2;
    let s = svgOpen(S, S, '0 0 ' + f(S) + ' ' + f(S), 'overflow:visible');
    if (ahead) s += '<defs><filter id="' + nid('grey') + '" color-interpolation-filters="sRGB"><feColorMatrix type="saturate" values="0"/></filter></defs>';
    s += fillC(S / 2, S / 2, S / 2, tint[0], tint[1]);
    s += el('g', { transform: 'translate(' + f(o) + ' ' + f(o) + ') scale(' + f(a / 64) + ')', filter: ahead ? 'url(#' + nid('grey') + ')' : undefined, opacity: ahead ? 0.5 : undefined },
      healthContent(id, still, nid));
    if (opts.showsRing !== false && state === 'underWay') {
      const p = Math.max(Number(opts.progress) || 0, 0.03);
      s += el('circle', { cx: S / 2, cy: S / 2, r: S * 0.59, fill: 'none', stroke: accent, 'stroke-width': Math.max(2, S / 22), 'stroke-linecap': 'round',
        pathLength: 1, 'stroke-dasharray': f(Math.min(p, 1)) + ' 2', transform: 'rotate(-90 ' + f(S / 2) + ' ' + f(S / 2) + ')' });
    }
    if (state === 'done') {
      const d = Math.max(S * 0.36, 14);
      const cx = S - d / 2 + d * 0.15, cy = cx;
      const onInk = dark ? '#0E0B2B' : '#FBF7F1', card = dark ? '#2A255F' : '#FFFFFF';
      const k = d * 0.5; // SF Symbol "checkmark" at font size d·0.5, heavy (approximated).
      s += fillC(cx, cy, d / 2, accent) + strokeC(cx, cy, d / 2 - 1, card, 2) +
        strokeP('M' + f(cx - 0.36 * k) + ' ' + f(cy + 0.02 * k) + ' L' + f(cx - 0.1 * k) + ' ' + f(cy + 0.3 * k) + ' L' + f(cx + 0.38 * k) + ' ' + f(cy - 0.3 * k),
          onInk, 0.17 * k);
    }
    return s + '</svg>';
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  const Art = {
    kitKinds,
    kit,
    kitSafeArea,
    personPoses,
    person,
    characters,
    moods,
    characterSizes,
    stages: [1, 2, 3, 4],
    character,
    horizonKinds,
    horizonFits,
    horizon,
    hero,
    calmHeader,
    healthIds,
    healthHue,
    healthArt,
    healthBadge,
    healthStates: ['done', 'underWay', 'ahead'],
  };
  Art.extras = [
    { name: 'calmHeader', label: 'Calm tools header (CalmHeaderArt)', fn: (o) => calmHeader(o) },
    { name: 'hero', label: 'Hero horizon with paper edge (HeroScene)', fn: (o) => hero(o), variants: { key: 'kind', values: horizonKinds } },
    { name: 'healthArt', label: 'Health timeline drawing (HealthArt)', fn: (o) => healthArt((o && o.id) || 'heart-rate', o), variants: { key: 'id', values: healthIds.concat(['sparkle']) } },
    { name: 'healthBadge', label: 'Health timeline badge (HealthBadge)', fn: (o) => healthBadge((o && o.id) || 'heart-rate', o), variants: { key: 'id', values: healthIds.concat(['sparkle']) } },
  ];

  root.Art = Art;
})(typeof window !== 'undefined' ? window : this);
