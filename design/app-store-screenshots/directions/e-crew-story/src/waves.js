/* DayXero App Store screenshots, Direction E "Meet the crew": the wavy landscape behind every frame.
   Direction C's idea (one continuous landscape whose layers meet exactly at every seam), redrawn in the designer's flat
   style and recoloured per frame: each frame keeps her ground colour as its sky, and the four layers in front of it
   (far, mid, near, front) take that character's realm: hills by day, Jelli's sea, Glim's night hills.

   Geometry is a function of the GLOBAL x across all ten frames (0 to 13200), so a ridge leaving frame 4 at its right
   edge enters frame 5 at exactly the same height. Colours are keyed per frame and blend across each seam in OKLab
   (over +-260 px), so a layer's colour at a seam is the same in both frames. The sky keeps her flat ground.

   DX_WAVES(frame) returns plain data. WAVES_TEMPLATE is the SVG with {{holes}}; dxWavesSVG(frame) fills it here, and the
   canvas component Waves.dc.html carries the same function and the same template, so the canvas draws the same art. */
(function (root) {
  'use strict';

  function DX_WAVES(frame, opt) {
    /* opt (for the iPad and iPhone Duo sets): { H: stage height at 1320 wide, ys: how much the ground is squashed,
       rs: how much the suns and moons shrink, moonDy: moves Glim's moon down }. With no opt this is the 1320 x 2868 iPhone stage, exactly as before. */
    opt = opt || {};
    var FW = 1320, H0 = 2868, H = opt.H || H0, YS = opt.ys || 1, RS = opt.rs || 1, MDY = opt.moonDy || 0, N = 10;
    function Y(y) { return H - (H0 - y) * YS; }
    var k = Math.max(1, Math.min(N, Math.round(frame) || 1));
    var off = (k - 1) * FW;

    /* ---------- colour: OKLab mixing ---------- */
    function h2r(h) { return [1, 3, 5].map(function (i) { return parseInt(h.slice(i, i + 2), 16); }); }
    function lin(c) { c /= 255; return c <= 0.04045 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4); }
    function unl(c) { c = c <= 0.0031308 ? 12.92 * c : 1.055 * Math.pow(c, 1 / 2.4) - 0.055; return Math.round(Math.max(0, Math.min(1, c)) * 255); }
    function lab(h) {
      var p = h2r(h).map(lin), r = p[0], g = p[1], b = p[2];
      var l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
      var m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
      var s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
      return [0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s, 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s, 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s];
    }
    function hex(v) {
      var L = v[0], A = v[1], B = v[2];
      var l = Math.pow(L + 0.3963377774 * A + 0.2158037573 * B, 3), m = Math.pow(L - 0.1055613458 * A - 0.0638541728 * B, 3), s = Math.pow(L - 0.0894841775 * A - 1.2914855480 * B, 3);
      var rgb = [4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s, -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s, -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s];
      return '#' + rgb.map(unl).map(function (x) { return (x < 16 ? '0' : '') + x.toString(16); }).join('').toUpperCase();
    }
    function mix(a, b, t) { if (t <= 0) return a; if (t >= 1) return b; var A = lab(a), B = lab(b); return hex(A.map(function (v, i) { return v + (B[i] - v) * t; })); }
    function smooth(t) { return t <= 0 ? 0 : t >= 1 ? 1 : t * t * (3 - 2 * t); }
    /* a per-frame value at global x, blended across the nearest seam over +-half px */
    function keyed(X, T, half, mixer) {
      var f = Math.max(0, Math.min(N - 1, Math.floor(X / FW))), u = X - f * FW;
      if (u < half && f > 0) return mixer(T[f - 1], T[f], smooth((u + half) / (2 * half)));
      if (u > FW - half && f < N - 1) return mixer(T[f], T[f + 1], smooth((u - FW + half) / (2 * half)));
      return T[f];
    }
    function num(a, b, t) { return a + (b - a) * t; }

    /* ---------- the ten realms (index 0 = frame 1). sky = the designer's ground colour for that frame ---------- */
    var SKY = ['#FFC289', '#9FE3BC', '#FFD3BF', '#D9D1F7', '#3F6BFF', '#FFC2CC', '#4A3496', '#BFE0F5', '#FFD966', '#A6CCFB'];
    var FAR = ['#FFDDB0', '#C6F0D6', '#FFE4D6', '#E9E3FB', '#7096FF', '#EDB6D3', '#5C46AA', '#A6D2F2', '#FFE89E', '#C3DCFD'];
    var MID = ['#B8EDCD', '#7FD3A6', '#FFC3AB', '#C9BFF0', '#5C84FF', '#A9B4FF', '#3A2880', '#7DB9F0', '#B5EBC9', '#7FA3FF'];
    var NEAR = ['#9FE3BC', '#5DBE8A', '#FFAD92', '#B3A6EA', '#4A72F5', '#8C9AF6', '#2E1F6B', '#5C9BEB', '#8FDBAF', '#5C84FF'];
    var FRONT = ['#7FD3A6', '#3FA273', '#F7967A', '#9C8CE0', '#3459E0', '#6F7FE8', '#241858', '#3F7FE0', '#6CC795', '#4A72F5'];
    var SEA = [0, 0, 0, 0, 1, 1, 0, 1, 0, 1];   // Jelli's sea in 5 and 6, the calm sea in 8, the finale sea in 10

    /* ---------- ridges: hills where SEA is 0, rolling waves where it is 1 ---------- */
    var TAU = Math.PI * 2;
    function sines(X, parts) { var s = 0; for (var i = 0; i < parts.length; i++) s += parts[i][0] * Math.sin(X * TAU / parts[i][1] + parts[i][2]); return s; }
    var LAYERS = {
      far: { hill: 1880, hp: [[70, 2600, 0.3], [34, 1100, 1.7], [13, 430, 0.9]], sea: 1965, a: 7, p: 260, ph: 0.4, half: 300 },
      mid: { hill: 2130, hp: [[58, 2200, 1.1], [28, 900, 0.2], [11, 380, 2.0]], sea: 2120, a: 18, p: 430, ph: 1.3, half: 330 },
      near: { hill: 2390, hp: [[52, 1900, 2.4], [24, 780, 0.7], [9, 330, 1.3]], sea: 2340, a: 26, p: 540, ph: 2.6, half: 360 },
      front: { hill: 2655, hp: [[42, 1700, 0.6], [20, 700, 2.2], [7, 290, 0.4]], sea: 2600, a: 32, p: 660, ph: 0.2, half: 390 }
    };
    function seaAt(X, half) { return keyed(X, SEA, half, num); }
    function ridgeY(name, X) {
      var L = LAYERS[name], e = seaAt(X, L.half);
      var hill = L.hill - sines(X, L.hp);
      var wave = L.sea - L.a * Math.sin(X * TAU / L.p + L.ph);
      return Y(hill + (wave - hill) * e);
    }
    function f1(v) { return Math.round(v * 10) / 10; }
    /* a smooth closed path under a ridge (Catmull-Rom through samples every 12 px), in frame-local coordinates */
    function ridgePath(name) {
      var pts = [], x0 = -24, x1 = FW + 24, step = 12, bottom = H + 40;
      for (var x = x0; x <= x1; x += step) pts.push([x, ridgeY(name, off + x)]);
      var d = 'M' + x0 + ' ' + bottom + ' L' + x0 + ' ' + f1(pts[0][1]);
      for (var i = 0; i < pts.length - 1; i++) {
        var p0 = pts[Math.max(0, i - 1)], p1 = pts[i], p2 = pts[i + 1], p3 = pts[Math.min(pts.length - 1, i + 2)];
        d += ' C' + f1(p1[0] + (p2[0] - p0[0]) / 6) + ' ' + f1(p1[1] + (p2[1] - p0[1]) / 6) + ' ' + f1(p2[0] - (p3[0] - p1[0]) / 6) + ' ' + f1(p2[1] - (p3[1] - p1[1]) / 6) + ' ' + p2[0] + ' ' + f1(p2[1]);
      }
      return d + ' L' + x1 + ' ' + bottom + ' Z';
    }
    /* gradient stops at fixed offsets (the template holds the offsets; these are the colours) */
    var SKY_X = [0, 40, 80, 120, 1200, 1240, 1280, 1320];
    var LAND_X = [0, 65, 130, 195, 260, 1060, 1125, 1190, 1255, 1320];
    function stops(T, xs, half) { return xs.map(function (x) { return keyed(off + x, T, half, mix); }); }

    /* ---------- decor, placed in GLOBAL coordinates; whatever touches this frame is drawn, shifted ---------- */
    function circ(cx, cy, r) { return 'M' + f1(cx - r) + ' ' + f1(cy) + ' a' + r + ' ' + r + ' 0 1 0 ' + (2 * r) + ' 0 a' + r + ' ' + r + ' 0 1 0 ' + (-2 * r) + ' 0Z'; }
    function ell(cx, cy, rx, ry) { return 'M' + f1(cx - rx) + ' ' + f1(cy) + ' a' + rx + ' ' + ry + ' 0 1 0 ' + (2 * rx) + ' 0 a' + rx + ' ' + ry + ' 0 1 0 ' + (-2 * rx) + ' 0Z'; }
    var rs = 11; function rnd() { rs = (rs * 16807) % 2147483647; return rs / 2147483647; }
    var sky = [], mid = [], top = [];
    function inFrame(x0, x1) { return x1 > off - 40 && x0 < off + FW + 40; }
    function add(list, x0, x1, item) { if (inFrame(x0, x1)) list.push(item); }
    function G(i) { return i * FW; } // global x of frame i+1's left edge

    // frame 1: the morning sun behind Glim
    add(sky, G(0) + 860, G(0) + 1300, { d: circ(G(0) + 1080 - off, Y(1430), 210 * RS), fill: '#FFD966', op: 1 });
    // frame 3: Xero's big peach sun, low on the left (the designer's disc)
    add(sky, G(2) - 300, G(2) + 900, { d: circ(G(2) + 300 - off, Y(2010), 560 * RS), fill: '#FFB49A', op: 1 });
    // frame 4: the lavender moon-disc on the right (the designer's)
    add(sky, G(3) + 700, G(3) + 1700, { d: circ(G(3) + 1180 - off, Y(1560), 430 * RS), fill: '#C9BFF0', op: 1 });
    // seam 6/7: the sun sets between Jelli's evening sea and Glim's night
    add(sky, G(6) - 420, G(6) + 420, { d: circ(G(6) - off, Y(1950), 330 * RS), fill: '#FFD9B0', op: 0.35 });
    add(sky, G(6) - 300, G(6) + 300, { d: circ(G(6) - off, Y(1950), 190 * RS), fill: '#FFB38A', op: 1 });
    // frame 7: the crescent moon (the designer's: a pale disc cut by the night) with two soft rings, and the stars
    add(sky, G(6), G(6) + 500, { d: circ(G(6) + 300 - off, (Y(905) + MDY), 200 * RS), fill: '#FFE9A8', op: 0.05 });
    add(sky, G(6), G(6) + 500, { d: circ(G(6) + 300 - off, (Y(905) + MDY), 140 * RS), fill: '#FFE9A8', op: 0.09 });
    add(sky, G(6), G(6) + 500, { d: circ(G(6) + 300 - off, (Y(905) + MDY), 96 * RS) + ' M' + f1(G(6) + 352 - off - 84 * RS) + ' ' + f1((Y(905) + MDY) - 25 * RS) + ' a' + 84 * RS + ' ' + 84 * RS + ' 0 1 1 ' + 168 * RS + ' 0 a' + 84 * RS + ' ' + 84 * RS + ' 0 1 1 ' + (-168 * RS) + ' 0Z', fill: '#FFE9A8', op: 1, rule: 'evenodd' });
    var stars = '';
    for (var i = 0; i < 70; i++) {
      var sx = G(6) - 160 + rnd() * (FW + 320), sy = Y(930 + rnd() * 950), sr = rnd() < 0.25 ? 6 : 3 + rnd() * 2;
      var fade = smooth((sx - (G(6) - 160)) / 260) * (1 - smooth((sx - (G(7) - 100)) / 260));
      if (fade > 0.4 && Math.hypot(sx - (G(6) + 300), sy - (Y(905) + MDY)) > 200 * RS) stars += circ(sx - off, sy, f1(sr)) + ' ';
    }
    add(sky, G(6) - 200, G(7) + 200, { d: stars, fill: '#FFF7EE', op: 0.85 });
    // seam 8/9: the sun comes up out of the calm sea into the rewards morning
    add(sky, G(8) - 480, G(8) + 480, { d: circ(G(8) - off, Y(1930), 360 * RS), fill: '#FFF1C2', op: 0.5 });
    add(sky, G(8) - 300, G(8) + 300, { d: circ(G(8) - off, Y(1930), 220 * RS), fill: '#FFD966', op: 1 });
    // frame 10: the finale sun (the designer's)
    add(sky, G(9) + 800, G(9) + 1320, { d: circ(G(9) + 1090 - off, Y(1330), 165 * RS), fill: '#FFD966', op: 1 });

    // frame 2: the prep path. Seven stones on the front hill lead right to the Day Xero flag
    var path = '', stones = '';
    for (var px = 70; px <= 1150; px += 10) { var gx = G(1) + px; path += (path ? ' L' : 'M') + (gx - off) + ' ' + f1(ridgeY('front', gx) + (70 + 26 * Math.sin(px / 150)) * YS); }
    add(top, G(1), G(2), { d: path, fill: 'none', op: 0.8, stroke: '#FFF8EE', sw: 30 });
    for (var si = 0; si < 7; si++) {
      var stx = G(1) + 110 + si * 165, sty = ridgeY('front', stx) + (70 + 26 * Math.sin((110 + si * 165) / 150)) * YS;
      stones += ell(stx - off, f1(sty), 44, 18) + ' ';
    }
    add(top, G(1), G(2), { d: stones, fill: '#FFF8EE', op: 1, stroke: '#0F6E43', sw: 6 });
    var fx = G(1) + 1225, fy = ridgeY('front', fx) + 48 * YS;
    add(top, G(1) + 1100, G(2) + 120, { d: 'M' + f1(fx - off - 4) + ' ' + f1(fy) + ' v-150 h8 v150Z', fill: '#201D2E', op: 1 });
    add(top, G(1) + 1100, G(2) + 120, { d: 'M' + f1(fx - off + 4) + ' ' + f1(fy - 146) + ' l86 22 l-86 26Z', fill: '#FF7A55', op: 1 });
    add(top, G(1) + 1100, G(2) + 120, { d: ell(fx - off, f1(fy + 4), 70, 14), fill: '#0F6E43', op: 0.25 });

    // the sea frames: foam curls on the crests of the near and front swells
    ['near', 'front'].forEach(function (nm) {
      var L = LAYERS[nm], foam = '';
      var first = Math.ceil((off - 60 - ((0.25 - L.ph / TAU) * L.p)) / L.p);
      for (var n = first; ; n++) {
        var cx = (0.25 - L.ph / TAU) * L.p + n * L.p; if (cx > off + FW + 60) break;
        if (seaAt(cx, L.half) < 0.95) continue;
        var cy = ridgeY(nm, cx), s = nm === 'front' ? 1.5 : 1.15;
        foam += 'M' + f1(cx - off - 24 * s) + ' ' + f1(cy + 3) + ' C' + f1(cx - off - 12 * s) + ' ' + f1(cy - 14 * s) + ' ' + f1(cx - off + 10 * s) + ' ' + f1(cy - 16 * s) + ' ' + f1(cx - off + 20 * s) + ' ' + f1(cy - 3 * s) + ' C' + f1(cx - off + 8 * s) + ' ' + f1(cy - 7 * s) + ' ' + f1(cx - off - 4 * s) + ' ' + f1(cy - 3 * s) + ' ' + f1(cx - off - 10 * s) + ' ' + f1(cy + 6 * s) + 'Z ';
      }
      (nm === 'near' ? mid : top).push({ d: foam, fill: '#FFFFFF', op: 0.8 });
    });

    // frame 7: fireflies over Glim's hills
    var ff = '', ffg = ''; rs = 29;
    for (var j = 0; j < 26; j++) {
      var fxx = G(6) + 40 + rnd() * (FW - 80), fyy = ridgeY('mid', fxx) + (20 + rnd() * 560) * YS;
      ff += circ(fxx - off, f1(fyy), 5) + ' '; ffg += circ(fxx - off, f1(fyy), 16) + ' ';
    }
    add(top, G(6), G(7), { d: ffg, fill: '#FFE27A', op: 0.22 });
    add(top, G(6), G(7), { d: ff, fill: '#FFE27A', op: 1 });
    // frame 9: flowers in the rewards meadow
    var fl = ['', '', '']; rs = 3;
    for (var q = 0; q < 54; q++) {
      var qx = G(8) + 30 + rnd() * (FW - 60), qy = ridgeY('front', qx) + (26 + rnd() * 150) * YS;
      fl[q % 3] += circ(qx - off, f1(qy), f1(5 + rnd() * 3)) + ' ';
    }
    add(top, G(8), G(9), { d: fl[0], fill: '#FFF8EE', op: 0.95 });
    add(top, G(8), G(9), { d: fl[1], fill: '#FF8FA3', op: 0.95 });
    add(top, G(8), G(9), { d: fl[2], fill: '#FFD966', op: 1 });
    // frame 10: the sand island the crew stands on (the designer's), with the Day Xero flag
    add(mid, G(9), G(10), { d: ell(G(9) + 640 - off, f1(Y(2392)), 560, f1(92 * YS)), fill: '#FFE3B8', op: 1 });
    add(mid, G(9), G(10), { d: ell(G(9) + 640 - off, f1(Y(2408)), 560, f1(84 * YS)), fill: 'none', op: 1, stroke: '#E2C49C', sw: 7 });
    add(mid, G(9), G(10), { d: 'M' + (G(9) + 1096 - off) + ' ' + f1(Y(2384)) + ' v-196 h10 v196Z', fill: '#201D2E', op: 1 });
    add(mid, G(9), G(10), { d: 'M' + (G(9) + 1106 - off) + ' ' + f1(Y(2384) - 192) + ' l96 25 l-96 30Z', fill: '#FF7A55', op: 1 });

    /* ---------- flatten to the template's fixed slots ---------- */
    var out = { id: 'dxw' + k, frame: k, H: H, H40: H + 40 };
    // the sky stays the designer's flat ground for the whole frame (a hard change at the seam, as on her canvas);
    // only the land and the sea run on across the seams
    SKY_X.forEach(function (x, i) { out['s' + i] = SKY[k - 1]; });
    [['far', FAR], ['mid', MID], ['near', NEAR], ['front', FRONT]].forEach(function (p) {
      var o = { d: ridgePath(p[0]) };
      stops(p[1], LAND_X, 260).forEach(function (c, i) { o['c' + i] = c; });
      out[p[0]] = o;
    });
    function slot(list, n, pre) {
      for (var i = 0; i < n; i++) {
        var it = list[i] || {};
        out[pre + i] = { d: it.d || 'M0 0', fill: it.fill || 'none', op: it.op == null ? 0 : it.op, stroke: it.stroke || 'none', sw: it.sw || 0, rule: it.rule || 'nonzero' };
      }
      if (list.length > n) throw new Error('waves: too many ' + pre + ' items in frame ' + k);
    }
    slot(sky, 8, 'sk'); slot(mid, 6, 'md'); slot(top, 8, 'tp');
    return out;
  }

  /* The SVG, with {{holes}}. Waves.dc.html holds this same markup. */
  var SK = [0, 1, 2, 3, 4, 5, 6, 7], MD = [0, 1, 2, 3, 4, 5], TP = [0, 1, 2, 3, 4, 5, 6, 7];
  var SKY_O = [0, 40, 80, 120, 1200, 1240, 1280, 1320], LAND_O = [0, 65, 130, 195, 260, 1060, 1125, 1190, 1255, 1320];
  function grad(id, pre, offs, path) {
    return '<linearGradient id="{{id}}' + id + '" gradientUnits="userSpaceOnUse" x1="0" y1="0" x2="1320" y2="0">' +
      offs.map(function (o, i) { return '<stop offset="' + (o / 1320).toFixed(4) + '" stop-color="{{' + path + pre + i + '}}"></stop>'; }).join('') + '</linearGradient>';
  }
  function deco(p) { return '<path d="{{' + p + '.d}}" fill="{{' + p + '.fill}}" fill-rule="{{' + p + '.rule}}" opacity="{{' + p + '.op}}" stroke="{{' + p + '.stroke}}" stroke-width="{{' + p + '.sw}}" stroke-linecap="round" stroke-linejoin="round"></path>'; }
  var WAVES_TEMPLATE =
    '<svg aria-hidden="true" width="1320" height="{{H}}" viewBox="0 0 1320 {{H}}" style="position: absolute; left: 0; top: 0; display: block; overflow: hidden">' +
    '<defs>' + grad('sky', 's', SKY_O, '') + grad('far', 'c', LAND_O, 'far.') + grad('mid', 'c', LAND_O, 'mid.') + grad('near', 'c', LAND_O, 'near.') + grad('front', 'c', LAND_O, 'front.') +
    '<filter id="{{id}}lift" x="-5%" y="-20%" width="110%" height="140%"><feDropShadow dx="0" dy="-6" stdDeviation="9" flood-color="#1A0B2E" flood-opacity=".14"></feDropShadow></filter>' +
    '</defs>' +
    '<rect x="0" y="0" width="1320" height="{{H40}}" fill="url(#{{id}}sky)"></rect>' +
    SK.map(function (i) { return deco('sk' + i); }).join('') +
    '<path d="{{far.d}}" fill="url(#{{id}}far)"></path>' +
    '<path d="{{mid.d}}" fill="url(#{{id}}mid)" filter="url(#{{id}}lift)"></path>' +
    '<path d="{{near.d}}" fill="url(#{{id}}near)" filter="url(#{{id}}lift)"></path>' +
    MD.map(function (i) { return deco('md' + i); }).join('') +
    '<path d="{{front.d}}" fill="url(#{{id}}front)" filter="url(#{{id}}lift)"></path>' +
    TP.map(function (i) { return deco('tp' + i); }).join('') +
    '</svg>';

  function fill(tpl, data) {
    return tpl.replace(/\{\{\s*([\w.]+)\s*\}\}/g, function (_, p) {
      var v = p.split('.').reduce(function (o, k) { return o == null ? o : o[k]; }, data);
      if (v == null) throw new Error('waves: no value for ' + p);
      return String(v);
    });
  }

  root.DX_WAVES = DX_WAVES;
  root.WAVES_TEMPLATE = WAVES_TEMPLATE;
  root.dxWavesSVG = function (frame, opt) { return fill(WAVES_TEMPLATE, DX_WAVES(frame, opt)); };
})(typeof window !== 'undefined' ? window : globalThis);
