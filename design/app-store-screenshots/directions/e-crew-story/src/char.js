/* DayXero crew: Xero, Jelli and Glim, ported from the app's SwiftUI drawings on main 6498929:
     DayXeroCore/DesignSystem/Art/XeroView.swift, JelliView.swift, GlimView.swift and CrewDrawing.swift (the faces, the
     sparkle and zzz marks), with the stages of DayXeroCore/Logic/CrewGrowth.swift.
   Every path, colour, opacity, stroke width and pivot is the Swift's, in the same 200 x 200 drawing space. The box is
   size x size, as the app's CrewCanvas frames it, and the art scales with it (marks, hops and the stage-4 glow may draw
   a little outside the box, as in the app).

   DX_CREW(props) returns plain data and CREW_TEMPLATE is the SVG with {{holes}}; DXCHAR(props) fills one here, still,
   for the PNGs. The canvas component Char.dc.html carries the same function and the same template (build-canvas.mjs
   copies them in), with animate on, so the canvas runs the app's idle motion and the PNGs show its rest pose.

   Props (the frames' <x-char> attributes):
     who    xero | jelli | glim
     expr   the app's moods: hello | calm | breathe | cheer | sleepy. The designer's three expressions still work and map
            to the nearest app mood: happy -> hello, cheer -> cheer, sleepy -> sleepy.
     size   the box in px (the app's `points`)
     stage  0-4 (CrewGrowth.stage: under 7 days clear 1, under 14 2, under 28 3, then 4). Xero's 0 is the kit's Xero
            that onboarding, cards and Progress draw (full size, #FF7155, no sprout); Jelli and Glim clamp to 1-4.
            Default 1.
     pose   Xero only: standard | wave (Welcome, 002) | holdFlag (010) | hold (evidence screens). Default standard.
     dark   true draws the zzz and breeze marks in cream, as the app does in dark mode. Default false.
     animate  (canvas) true runs the idle motion; DXCHAR always draws the rest pose.
     delay  (canvas, kept from the designer's component) is ignored: the app's tracks start together. */
(function (root) {
  'use strict';

  var MOOD = { happy: 'hello', hello: 'hello', calm: 'calm', breathe: 'breathe', cheer: 'cheer', sleepy: 'sleepy' };

  function DX_CREW(p) {
    p = p || {};
    var who = p.who === 'jelli' || p.who === 'glim' ? p.who : 'xero';
    var mood = MOOD[p.expr] || MOOD[p.mood] || 'hello';
    var size = Number(p.size) || 300;
    var on = p.animate === true || p.animate === 'true';
    var dark = p.dark === true || p.dark === 'true';
    var pose = ['wave', 'holdFlag', 'hold'].indexOf(p.pose) >= 0 ? p.pose : 'standard';
    var rawStage = p.stage == null || p.stage === '' ? 1 : Math.round(Number(p.stage));
    if (!isFinite(rawStage)) rawStage = 1;
    var cheer = mood === 'cheer';
    var SPL = '0.45 0 0.55 1', LIN = '0 0 1 1';
    var show = function (b) { return b ? 'inline' : 'none'; };

    /* One SMIL track, the shape of ArtTrack: values, keyTimes, duration, spline easing, begin. With animate off every
       value is the rest value (ArtTrack.value(animate: false) is the first value, or `rest` where the Swift says so). */
    function track(vals, opt) {
      opt = opt || {};
      var n = vals.length;
      var times = opt.times || vals.map(function (_, i) { return i / (n - 1); });
      var rest = opt.rest != null ? opt.rest : vals[0];
      var v = on ? vals : vals.map(function () { return rest; });
      return {
        v: v.join(';'), kt: times.join(';'), dur: (opt.dur || 1) + 's', begin: (opt.begin || 0) + 's',
        mode: opt.spline ? 'spline' : 'linear',
        ks: times.slice(1).map(function () { return opt.spline ? SPL : LIN; }).join(';'),
        rest: rest
      };
    }
    var still = function (v) { return track([v, v], { dur: 1 }); };
    var CT = [0, 0.15, 0.35, 0.55, 1], SP = [0, 0.5, 1];

    /* Crew.Face.make: the five faces, the same across the crew apart from the eye line y. */
    function face(y, color, blinkPeriod) {
      var c = 100, l = 86, r = 114, f;
      var closed = function (x) { return 'M' + (x - 6) + ' ' + y + ' Q' + x + ' ' + (y + 5) + ' ' + (x + 6) + ' ' + y; };
      switch (mood) {
        case 'calm': f = { eyeL: closed(l), eyeR: closed(r), w: 3.5, mouth: 'M' + (c - 5) + ' ' + (y + 15) + ' Q' + c + ' ' + (y + 19) + ' ' + (c + 5) + ' ' + (y + 15), filled: false }; break;
        case 'breathe': f = { eyeL: closed(l), eyeR: closed(r), w: 3.5, mouth: 'M' + c + ' ' + (y + 12) + ' C' + (c + 6) + ' ' + (y + 12) + ' ' + (c + 6) + ' ' + (y + 23) + ' ' + c + ' ' + (y + 23) + ' C' + (c - 6) + ' ' + (y + 23) + ' ' + (c - 6) + ' ' + (y + 12) + ' ' + c + ' ' + (y + 12) + ' Z', filled: true }; break;
        case 'cheer': f = { eyeL: 'M' + (l - 6) + ' ' + (y + 2) + ' Q' + l + ' ' + (y - 5) + ' ' + (l + 6) + ' ' + (y + 2), eyeR: 'M' + (r - 6) + ' ' + (y + 2) + ' Q' + r + ' ' + (y - 5) + ' ' + (r + 6) + ' ' + (y + 2), w: 3.5, mouth: 'M' + (c - 10) + ' ' + (y + 12) + ' L' + (c + 10) + ' ' + (y + 12) + ' Q' + c + ' ' + (y + 28) + ' ' + (c - 10) + ' ' + (y + 12) + ' Z', filled: true }; break;
        case 'sleepy': f = { eyeL: 'M' + (l - 6) + ' ' + (y + 1) + ' L' + (l + 6) + ' ' + (y + 1), eyeR: 'M' + (r - 6) + ' ' + (y + 1) + ' L' + (r + 6) + ' ' + (y + 1), w: 3.5, mouth: 'M' + (c - 3) + ' ' + (y + 16) + ' Q' + c + ' ' + (y + 18) + ' ' + (c + 3) + ' ' + (y + 16), filled: false }; break;
        default: f = { eyeL: 'M' + l + ' ' + (y - 3) + ' L' + l + ' ' + (y + 3), eyeR: 'M' + r + ' ' + (y - 3) + ' L' + r + ' ' + (y + 3), w: 8, mouth: 'M' + (c - 8) + ' ' + (y + 14) + ' Q' + c + ' ' + (y + 22) + ' ' + (c + 8) + ' ' + (y + 14), filled: false };
      }
      var blinks = mood === 'hello' || mood === 'cheer';
      return {
        eyeL: f.eyeL, eyeR: f.eyeR, w: f.w, mouth: f.mouth, mouthFill: f.filled ? color : 'none', color: color,
        pin: 'translate(100 ' + y + ')', unpin: 'translate(-100 -' + y + ')',
        blink: blinks ? track(['1 1', '1 1', '1 0.1', '1 1'], { times: [0, 0.92, 0.96, 1], dur: blinkPeriod }) : still('1 1')
      };
    }
    function sparkle(x, top, len) {
      var y = top + len / 2, r = len / 2 + 1;
      return 'M' + x + ' ' + (y - r) + ' Q' + x + ' ' + y + ' ' + (x + r) + ' ' + y + ' Q' + x + ' ' + y + ' ' + x + ' ' + (y + r) +
        ' Q' + x + ' ' + y + ' ' + (x - r) + ' ' + y + ' Q' + x + ' ' + y + ' ' + x + ' ' + (y - r) + 'Z';
    }
    function zzz(x, y, color, visible) {
      return {
        show: show(visible), color: color,
        a: 'M' + x + ' ' + y + ' h12 l-12 12 h12', b: 'M' + (x + 20) + ' ' + (y - 20) + ' h8 l-8 8 h8',
        float: track(['0 0', '5 -8', '0 0'], { dur: 3 })
      };
    }
    var ink = '#24163A', markColor = dark ? '#F3E9DE' : ink;
    var noSpark = { show: 'none', a: '', b: '' };

    /* ---------- Xero (XeroView.draw) ---------- */
    function xero() {
      var stage = Math.min(4, Math.max(0, rawStage));
      var LOOK = [
        { grow: 1, body: '#FF7155', shade: '#E85A3E', highlight: '#FFB09C', feet: '#C9542F', cheek: 0.8 },   // 0: the kit's Xero
        { grow: 0.8, body: '#FF9478', shade: '#F27858', highlight: '#FFC8B8', feet: '#D86A48', cheek: 0.55 },
        { grow: 0.88, body: '#FF8064', shade: '#EC6648', highlight: '#FFBBA8', feet: '#CF5E3B', cheek: 0.65 },
        { grow: 0.95, body: '#FF7155', shade: '#E85A3E', highlight: '#FFB09C', feet: '#C9542F', cheek: 0.8 },
        { grow: 1, body: '#F2583A', shade: '#D24328', highlight: '#FFA286', feet: '#B4441F', cheek: 0.95 }
      ];
      var look = LOOK[stage];
      var body = {
        hello: track(['1 1', '1.025 0.985', '1 1'], { times: SP, dur: 5, spline: true }),
        calm: track(['1 1', '1.02 0.99', '1 1'], { times: SP, dur: 6, spline: true }),
        breathe: track(['1 1', '1.07 1.07', '1 1'], { times: [0, 0.4, 1], dur: 10, spline: true }),
        cheer: track(['1 1', '1.08 0.9', '0.96 1.06', '1 1', '1 1'], { times: CT, dur: 1.4, spline: true }),
        sleepy: track(['1 1', '1.015 0.99', '1 1'], { times: SP, dur: 7, spline: true })
      }[mood];
      var sunRest = [168, 156, 142, 128][Math.max(stage, 1) - 1];
      var top = stage >= 3 ? 12 : 20;
      var holding = pose === 'hold';
      return {
        show: show(who === 'xero'),
        shadowRx: 48 * look.grow,
        hop: cheer ? track(['0 0', '0 0', '0 -18', '0 0', '0 0'], { times: CT, dur: 1.4, spline: true }) : still('0 0'),
        body: body,
        sway: mood === 'sleepy' ? track(['-3', '3', '-3'], { times: SP, dur: 7, spline: true }) : still('0'),
        grow: 'scale(' + look.grow + ')',
        sun: mood === 'breathe'
          ? track([sunRest, sunRest - 16, sunRest], { times: [0, 0.4, 1], dur: 10, spline: true })
          : track([sunRest, sunRest - 3, sunRest], { times: SP, dur: 4, spline: true }),
        glow: show(stage >= 4),
        feet: look.feet, coral: look.body, shade: look.shade, highlight: look.highlight, cheek: look.cheek,
        armL: holding ? 'M38 118 C26 116 16 108 12 96' : cheer ? 'M38 112 C28 98 24 86 26 74' : 'M36 124 C26 132 22 142 24 152',
        armR: holding ? 'M162 118 C174 116 184 108 188 96'
          : pose === 'wave' ? 'M162 112 C172 98 178 86 176 74'
          : pose === 'holdFlag' ? 'M164 122 C176 118 183 110 186 100'
          : cheer ? 'M162 112 C172 98 176 86 174 74' : 'M164 124 C174 132 178 142 176 152',
        // `wave`: two 16-degree swings from 1.2 s (2 x 800 ms), then the arm rests raised.
        wave: pose === 'wave' && on
          ? { v: '0;-16;0;-16;0', kt: '0;0.25;0.5;0.75;1', ks: [SPL, SPL, SPL, SPL].join(';'), mode: 'spline', dur: '1.6s', begin: '1.2s' }
          : { v: '0;0', kt: '0;1', ks: LIN, mode: 'linear', dur: '1s', begin: '0s' },
        waveMarks: show(pose === 'wave'), waveInk: dark ? '#F3E9DE' : '#24163A',
        sprout1: show(stage >= 2), sprout2: show(stage >= 3), bud: show(stage >= 4),
        stem: 'M100 36 C100 30 101 ' + (top + 8) + ' 102 ' + top,
        leaf: 'M102 ' + (top + 4) + ' C108 ' + (top - 8) + ' 124 ' + (top - 10) + ' 130 ' + (top - 4) + ' C122 ' + (top + 6) + ' 110 ' + (top + 8) + ' 102 ' + (top + 4) + ' Z',
        face: face(78, ink, 4.5),
        spark: cheer ? { show: 'inline', a: sparkle(26, 64, 12), b: sparkle(174, 70, 10) } : noSpark,
        zzz: zzz(150, 40, markColor, mood === 'sleepy'),
        breeze: show(mood === 'breathe'), breezeInk: markColor,
        drift: track(['0 0', '8 0', '0 0'], { dur: 5 })
      };
    }

    /* ---------- Jelli (JelliView.draw) ---------- */
    function jelli() {
      var stage = Math.min(4, Math.max(1, rawStage));
      var body = {
        hello: track(['1 1', '1.06 0.95', '1 1'], { times: [0, 0.35, 1], dur: 3, spline: true }),
        calm: track(['1 1', '1.04 0.97', '1 1'], { times: [0, 0.4, 1], dur: 5, spline: true }),
        breathe: track(['1 1', '1.12 1.05', '1 1'], { times: [0, 0.4, 1], dur: 10, spline: true }),
        cheer: track(['1 1', '1.12 0.88', '0.95 1.06', '1 1', '1 1'], { times: CT, dur: 1.2, spline: true }),
        sleepy: track(['1 1', '1.03 0.98', '1 1'], { times: SP, dur: 7, spline: true })
      }[mood];
      // JelliView.tentacle: k runs 1 -> -1 -> 1.
      var tent = function (x, k) { return 'M' + x + ' 122 C' + (x - 6 * k) + ' 138 ' + (x + 6 * k) + ' 152 ' + x + ' 166 C' + (x - 4 * k) + ' 174 ' + (x + 2 * k) + ' 180 ' + (x - 2 * k) + ' 186'; };
      // Four tentacles wave out of step, 0.3 s apart (keyed t0-t3: the canvas's holes are dotted lookups).
      var t = {};
      [78, 93, 108, 123].forEach(function (x, i) {
        t['t' + i] = { d: tent(x, 1), color: i % 2 === 0 ? '#F07188' : '#FF8FA3', anim: track([tent(x, 1), tent(x, -1), tent(x, 1)], { dur: 2.4, begin: 0.3 * i }) };
      });
      return {
        show: show(who === 'jelli'),
        bubbles: show(mood === 'breathe' || mood === 'calm'),
        // At rest the first bubble sits at y 150 (the Swift's `on ? y1 : 150`), the second at its first value, 130.
        bub1: track(['160', '60'], { dur: 4, rest: '150' }),
        bub2: track(['130', '40'], { dur: 5, begin: 1 }),
        hop: cheer ? track(['0 0', '0 0', '0 -18', '0 0', '0 0'], { times: CT, dur: 1.2, spline: true })
          : track(['0 0', '0 -7', '0 0'], { times: SP, dur: mood === 'sleepy' ? 7 : 4, spline: true }),
        body: body,
        sway: mood === 'sleepy' ? track(['-4', '4', '-4'], { times: SP, dur: 7, spline: true }) : still('0'),
        crown: show(stage >= 4),
        t: t,
        armL: cheer ? 'M56 118 C42 106 38 92 44 78' : 'M58 120 C50 136 60 150 52 166',
        armR: cheer ? 'M144 118 C158 106 162 92 156 78' : 'M142 120 C150 136 140 150 148 166',
        g2: show(stage >= 2), g3: show(stage >= 3),
        face: face(92, ink, 4.2),
        spark: cheer ? { show: 'inline', a: sparkle(24, 60, 12), b: sparkle(176, 56, 10) } : noSpark,
        zzz: zzz(154, 30, markColor, mood === 'sleepy')
      };
    }

    /* ---------- Glim (GlimView.draw) ---------- */
    function glim() {
      var stage = Math.min(4, Math.max(1, rawStage));
      var body = {
        hello: track(['1 1', '1.025 0.985', '1 1'], { times: SP, dur: 4, spline: true }),
        calm: track(['1 1', '1.02 0.99', '1 1'], { times: SP, dur: 6, spline: true }),
        breathe: track(['1 1', '1.07 1.07', '1 1'], { times: [0, 0.4, 1], dur: 10, spline: true }),
        cheer: track(['1 1', '1.08 0.9', '0.96 1.06', '1 1', '1 1'], { times: CT, dur: 1.3, spline: true }),
        sleepy: track(['1 1', '1.015 0.99', '1 1'], { times: SP, dur: 7, spline: true })
      }[mood];
      // Wings flap fast when awake, slowly when calm or breathing, not at all when sleepy.
      var flap = mood === 'sleepy' ? null : (mood === 'breathe' || mood === 'calm' ? 1.2 : 0.3);
      // Each wing turns about its root (100 -/+ 16, 82) by -wing x side.
      var wingL = flap ? track(['0 84 82', '-14 84 82', '0 84 82'], { dur: flap }) : still('0 84 82');
      var wingR = flap ? track(['0 116 82', '14 116 82', '0 116 82'], { dur: flap }) : still('0 116 82');
      // Tail glow: base radius by stage, pulsing to base + 10 and opacity .22 -> .45 (at rest: base and .3); the light
      // reaches 1.6 x the radius, capped at 50, and later stages glow brighter, not wider.
      var base = [30, 38, 48, 58][stage - 1];
      var period = mood === 'breathe' ? 10 : 2.6;
      var reach = function (r) { return Math.min(r * 1.6, 50); };
      var stops = function (o) { var s = o * (1 + 0.15 * (stage - 1)); return [Math.min(1, s * 2), Math.min(1, s * 1.4)]; };
      var rest = stops(0.3), lo = stops(0.22), hi = stops(0.45);
      var r3 = function (x) { return Math.round(x * 1000) / 1000; };
      var stars = [
        ['M30 60 l3 7 l7 3 l-7 3 l-3 7 l-3 -7 l-7 -3 l7 -3 Z', 1.8, 0],
        ['M168 120 l2.5 5 l5 2.5 l-5 2.5 l-2.5 5 l-2.5 -5 l-5 -2.5 l5 -2.5 Z', 2.3, 0.6],
        ['M40 160 l2 4 l4 2 l-4 2 l-2 4 l-2 -4 l-4 -2 l4 -2 Z', 2.0, 1.1]
      ].reduce(function (o, s, i) { o['s' + i] = { d: s[0], tw: track(['0.2', '1', '0.2'], { dur: s[1], begin: s[2], rest: '1' }) }; return o; }, {});
      return {
        show: show(who === 'glim'),
        stars: show(stage >= 4), s: stars,
        hop: cheer ? track(['0 0', '0 0', '0 -18', '0 0', '0 0'], { times: CT, dur: 1.3, spline: true })
          : track(['0 0', '0 -7', '0 0'], { times: SP, dur: mood === 'sleepy' ? 7 : 3, spline: true }),
        glowR: reach(base),
        glowRV: track([reach(base), reach(base + 10), reach(base)], { dur: period, rest: reach(base) }),
        o0: r3(rest[0]), o1: r3(rest[1]),
        o0V: track([r3(lo[0]), r3(hi[0]), r3(lo[0])], { dur: period, rest: r3(rest[0]) }),
        o1V: track([r3(lo[1]), r3(hi[1]), r3(lo[1])], { dur: period, rest: r3(rest[1]) }),
        body: body,
        sway: mood === 'sleepy' ? track(['-4', '4', '-4'], { times: SP, dur: 7, spline: true }) : still('0'),
        wingL: wingL, wingR: wingR,
        armL: cheer ? 'M66 108 C54 98 50 86 52 74' : 'M64 114 C54 120 50 128 52 136',
        armR: cheer ? 'M134 108 C146 98 150 86 148 74' : 'M136 114 C146 120 150 128 148 136',
        face: face(94, '#FFF8EE', 4.4),
        zzz: zzz(150, 34, '#9A84F0', mood === 'sleepy')
      };
    }

    return {
      id: p.id || 'dxc',
      size: size + 'px',
      label: who === 'jelli' ? 'Jelli' : who === 'glim' ? 'Glim' : 'Xero',
      x: xero(), j: jelli(), g: glim()
    };
  }

  /* ---------- the template ---------- */
  function anim(key, type, attr) {
    var a = ' values="{{' + key + '.v}}" keyTimes="{{' + key + '.kt}}" keySplines="{{' + key + '.ks}}" calcMode="{{' + key + '.mode}}" dur="{{' + key + '.dur}}" begin="{{' + key + '.begin}}" repeatCount="indefinite"';
    return type
      ? '<animateTransform attributeName="transform" type="' + type + '"' + a + '></animateTransform>'
      : '<animate attributeName="' + attr + '"' + a + '></animate>';
  }
  var ST = ' fill="none" stroke-linecap="round" stroke-linejoin="round"';
  function stroke(d, color, w, extra) { return '<path d="' + d + '"' + ST + ' stroke="' + color + '" stroke-width="' + w + '"' + (extra || '') + '></path>'; }
  function faceT(k) {
    return '<g transform="{{' + k + '.face.pin}}"><g>' + anim(k + '.face.blink', 'scale') + '<g transform="{{' + k + '.face.unpin}}">' +
      stroke('{{' + k + '.face.eyeL}}', '{{' + k + '.face.color}}', '{{' + k + '.face.w}}') +
      stroke('{{' + k + '.face.eyeR}}', '{{' + k + '.face.color}}', '{{' + k + '.face.w}}') +
      '</g></g></g>' +
      '<path d="{{' + k + '.face.mouth}}" fill="{{' + k + '.face.mouthFill}}" stroke="{{' + k + '.face.color}}" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"></path>';
  }
  function sparkT(k) {
    return '<g display="{{' + k + '.spark.show}}"><path d="{{' + k + '.spark.a}}" fill="#FFC93C"></path><path d="{{' + k + '.spark.b}}" fill="#FFC93C"></path></g>';
  }
  function zzzT(k) {
    return '<g display="{{' + k + '.zzz.show}}"><g>' + anim(k + '.zzz.float', 'translate') +
      stroke('{{' + k + '.zzz.a}}', '{{' + k + '.zzz.color}}', 3) + stroke('{{' + k + '.zzz.b}}', '{{' + k + '.zzz.color}}', 3) + '</g></g>';
  }

  var XERO =
    '<g display="{{x.show}}">' +
    '<defs>' +
    '<clipPath id="{{id}}-hole"><ellipse cx="100" cy="138" rx="21" ry="29"></ellipse></clipPath>' +
    '<radialGradient id="{{id}}-glow" gradientUnits="userSpaceOnUse" cx="100" cy="112" r="96">' +
    '<stop offset="0" stop-color="#FFF1C2" stop-opacity="0.75"></stop><stop offset="0.6" stop-color="#FFD966" stop-opacity="0.35"></stop><stop offset="1" stop-color="#FFD966" stop-opacity="0"></stop>' +
    '</radialGradient>' +
    '</defs>' +
    '<ellipse cx="100" cy="192" rx="{{x.shadowRx}}" ry="6" fill="#000000" fill-opacity="0.12"></ellipse>' +
    '<g>' + anim('x.hop', 'translate') +
    '<g transform="translate(100 190)"><g>' + anim('x.body', 'scale') + '<g>' + anim('x.sway', 'rotate') +
    '<g transform="{{x.grow}}"><g transform="translate(-100 -190)">' +
    // the hole: sky, the rising sun and a hill, clipped to the hole
    '<ellipse cx="100" cy="138" rx="21" ry="29" fill="#BFD7FF"></ellipse>' +
    '<g clip-path="url(#{{id}}-hole)">' +
    '<circle cx="100" cy="{{x.sun.rest}}" r="11" fill="#FFC93C">' + anim('x.sun', null, 'cy') + '</circle>' +
    '<path d="M76 160 C90 152 110 156 124 150 L124 172 L76 172 Z" fill="#3FB37F"></path>' +
    '</g>' +
    '<circle display="{{x.glow}}" cx="100" cy="112" r="96" fill="url(#{{id}}-glow)"></circle>' +
    '<ellipse cx="84" cy="188" rx="12" ry="7" fill="{{x.feet}}"></ellipse>' +
    '<ellipse cx="116" cy="188" rx="12" ry="7" fill="{{x.feet}}"></ellipse>' +
    stroke('{{x.armL}}', '{{x.coral}}', 12) +
    '<g transform="translate(162 112)"><g>' + anim('x.wave', 'rotate') + '<g transform="translate(-162 -112)">' +
    stroke('{{x.armR}}', '{{x.coral}}', 12) + '</g></g></g>' +
    '<path d="M100 34 C138 34 166 68 166 112 C166 156 138 188 100 188 C62 188 34 156 34 112 C34 68 62 34 100 34 Z M100 109 C112 109 121 121 121 138 C121 155 112 167 100 167 C88 167 79 155 79 138 C79 121 88 109 100 109 Z" fill="{{x.coral}}" fill-rule="evenodd"></path>' +
    '<path d="M136 52 C156 70 166 92 166 112 C166 156 138 188 100 188 C126 178 146 150 146 112 C146 88 142 68 136 52 Z" fill="{{x.shade}}"></path>' +
    stroke('M58 82 C62 66 74 52 90 46', '{{x.highlight}}', 6) +
    '<g display="{{x.sprout1}}">' + stroke('{{x.stem}}', '#2F8A5A', 4) + '<path d="{{x.leaf}}" fill="#3FB37F"></path></g>' +
    '<path display="{{x.sprout2}}" d="M101 24 C94 14 80 12 74 17 C80 26 92 28 101 24 Z" fill="#3FB37F"></path>' +
    '<g display="{{x.bud}}"><circle cx="102" cy="9" r="7" fill="#FFC93C"></circle><circle cx="102" cy="9" r="3" fill="#FFF1C2"></circle>' +
    stroke('M150 44 l8 -8', '#FFC93C', 3) + stroke('M50 44 l-8 -8', '#FFC93C', 3) + '</g>' +
    '<circle cx="72" cy="92" r="7" fill="{{x.highlight}}" fill-opacity="{{x.cheek}}"></circle>' +
    '<circle cx="128" cy="92" r="7" fill="{{x.highlight}}" fill-opacity="{{x.cheek}}"></circle>' +
    faceT('x') +
    '</g></g></g></g></g></g>' +
    // marks outside the body
    '<g display="{{x.waveMarks}}" opacity="0.55">' + stroke('M186 62 q7 6 6 14', '{{x.waveInk}}', 3) + stroke('M193 52 q9 9 6 22', '{{x.waveInk}}', 3) + '</g>' +
    sparkT('x') + zzzT('x') +
    '<g display="{{x.breeze}}"><g>' + anim('x.drift', 'translate') +
    stroke('M172 100 q8 -5 16 0', '{{x.breezeInk}}', 3) + stroke('M176 112 q6 -4 12 0', '{{x.breezeInk}}', 3) + '</g></g>' +
    '</g>';

  var JELLI =
    '<g display="{{j.show}}">' +
    '<ellipse cx="100" cy="194" rx="34" ry="4" fill="#000000" fill-opacity="0.08"></ellipse>' +
    '<g display="{{j.bubbles}}">' +
    '<circle cx="160" cy="{{j.bub1.rest}}" r="5" fill="none" stroke="#FFFFFF" stroke-width="2.5">' + anim('j.bub1', null, 'cy') + '</circle>' +
    '<circle cx="44" cy="{{j.bub2.rest}}" r="3.5" fill="none" stroke="#FFFFFF" stroke-width="2.5">' + anim('j.bub2', null, 'cy') + '</circle>' +
    '</g>' +
    '<g>' + anim('j.hop', 'translate') +
    '<path display="{{j.crown}}" d="M100 18 l4 9 l9 1 l-7 6 l2 9 l-8 -5 l-8 5 l2 -9 l-7 -6 l9 -1 Z" fill="#FFC93C"></path>' +
    [0, 1, 2, 3].map(function (i) {
      return '<path d="{{j.t.t' + i + '.d}}"' + ST + ' stroke="{{j.t.t' + i + '.color}}" stroke-width="5">' + anim('j.t.t' + i + '.anim', null, 'd') + '</path>';
    }).join('') +
    stroke('{{j.armL}}', '#FFC2CD', 10) + stroke('{{j.armR}}', '#FFC2CD', 10) +
    '<g transform="translate(100 44)"><g>' + anim('j.body', 'scale') + '<g>' + anim('j.sway', 'rotate') + '<g transform="translate(-100 -44)">' +
    '<path d="M42 112 C40 68 66 44 100 44 C134 44 160 68 158 112 C158 120 152 124 144 121 C136 128 126 128 118 121 C110 128 90 128 82 121 C74 128 64 128 56 121 C48 124 42 120 42 112 Z" fill="#FF8FA3"></path>' +
    '<path d="M120 48 C146 58 160 82 158 112 C158 120 152 124 144 121 C148 94 140 68 120 48 Z" fill="#F07188"></path>' +
    '<path d="M48 110 C70 116 130 116 152 110 C152 114 150 116 146 116 C120 122 80 122 54 116 C50 116 48 114 48 110 Z" fill="#FFB3C1"></path>' +
    stroke('M62 78 C66 62 78 52 94 48', '#FFD6DE', 7) +
    '<circle cx="62" cy="96" r="4" fill="#FFF1B8"></circle>' +
    '<g display="{{j.g2}}"><circle cx="140" cy="88" r="4" fill="#FFF1B8"></circle><circle cx="132" cy="66" r="3" fill="#FFF1B8"></circle></g>' +
    '<g display="{{j.g3}}"><circle cx="74" cy="64" r="3" fill="#FFF1B8"></circle><circle cx="148" cy="104" r="3" fill="#FFF1B8"></circle></g>' +
    '<circle cx="72" cy="104" r="7" fill="#FF6F8E" fill-opacity="0.6"></circle>' +
    '<circle cx="128" cy="104" r="7" fill="#FF6F8E" fill-opacity="0.6"></circle>' +
    faceT('j') +
    '</g></g></g></g>' +
    '</g>' +
    sparkT('j') + zzzT('j') +
    '</g>';

  function wing(side) {
    var k = side < 0 ? 'g.wingL' : 'g.wingR', cx = 100 + 42 * side;
    return '<g>' + anim(k, 'rotate') +
      '<ellipse cx="' + cx + '" cy="66" rx="30" ry="17" transform="rotate(' + 28 * side + ' ' + cx + ' 66)" fill="#E9F1FF" fill-opacity="0.92" stroke="#B9C6F2" stroke-width="2"></ellipse>' +
      stroke(side < 0 ? 'M40 74 C52 66 66 62 80 64' : 'M160 74 C148 66 134 62 120 64', '#B9C6F2', 1.5) + '</g>';
  }
  var GLIM =
    '<g display="{{g.show}}">' +
    '<defs><radialGradient id="{{id}}-tail" gradientUnits="userSpaceOnUse" cx="100" cy="150" r="{{g.glowR}}">' +
    anim('g.glowRV', null, 'r') +
    '<stop offset="0" stop-color="#FFE27A" stop-opacity="{{g.o0}}">' + anim('g.o0V', null, 'stop-opacity') + '</stop>' +
    '<stop offset="0.4" stop-color="#FFE27A" stop-opacity="{{g.o1}}">' + anim('g.o1V', null, 'stop-opacity') + '</stop>' +
    '<stop offset="1" stop-color="#FFE27A" stop-opacity="0"></stop>' +
    '</radialGradient></defs>' +
    '<ellipse cx="100" cy="194" rx="34" ry="4" fill="#000000" fill-opacity="0.1"></ellipse>' +
    '<g display="{{g.stars}}">' + [0, 1, 2].map(function (i) {
      return '<path d="{{g.s.s' + i + '.d}}" fill="#FFE27A" opacity="{{g.s.s' + i + '.tw.rest}}">' + anim('g.s.s' + i + '.tw', null, 'opacity') + '</path>';
    }).join('') + '</g>' +
    '<g>' + anim('g.hop', 'translate') +
    // The tail glow. The Swift draws it with .plusLighter, but inside the Canvas's own transparent layer, so on screen
    // it composites as plain source-over (checked against the CI check-in capture: over the night hills it adds yellow
    // with no lift in blue). Normal blending here gives the same pixels.
    '<circle cx="100" cy="150" r="{{g.glowR}}" fill="url(#{{id}}-tail)">' + anim('g.glowRV', null, 'r') + '</circle>' +
    '<g transform="translate(100 120)"><g>' + anim('g.body', 'scale') + '<g>' + anim('g.sway', 'rotate') + '<g transform="translate(-100 -120)">' +
    wing(-1) + wing(1) +
    stroke('M90 62 C84 50 78 40 74 32', '#5638C4', 3.5) + stroke('M110 62 C116 50 122 40 126 32', '#5638C4', 3.5) +
    '<circle cx="73" cy="29" r="6" fill="#FFE27A"></circle><circle cx="127" cy="29" r="6" fill="#FFE27A"></circle>' +
    '<ellipse cx="100" cy="150" rx="33" ry="31" fill="#FFE27A"></ellipse>' +
    stroke('M70 146 C84 154 116 154 130 146 M72 160 C86 168 114 168 128 160', '#F2C94C', 3.5) +
    stroke('M80 132 C86 126 94 124 100 124', '#FFF6C8', 4) +
    stroke('{{g.armL}}', '#6B4FD8', 9) + stroke('{{g.armR}}', '#6B4FD8', 9) +
    '<circle cx="100" cy="96" r="40" fill="#6B4FD8"></circle>' +
    '<path d="M124 64 C136 74 142 88 140 102 C138 118 126 132 108 136 C124 124 132 108 130 94 C129 82 126 72 124 64 Z" fill="#5638C4"></path>' +
    stroke('M70 84 C72 72 80 64 90 60', '#9A84F0', 5) +
    '<circle cx="74" cy="106" r="6" fill="#FF8FA3" fill-opacity="0.8"></circle>' +
    '<circle cx="126" cy="106" r="6" fill="#FF8FA3" fill-opacity="0.8"></circle>' +
    faceT('g') +
    '</g></g></g></g>' +
    '</g>' +
    zzzT('g') +
    '</g>';

  var CREW_TEMPLATE =
    '<svg role="img" aria-label="{{label}}" width="{{size}}" height="{{size}}" viewBox="0 0 200 200" style="display: block; overflow: visible">' +
    XERO + JELLI + GLIM + '</svg>';

  function fill(tpl, data) {
    return tpl.replace(/\{\{\s*([\w.]+)\s*\}\}/g, function (_, p) {
      var v = p.split('.').reduce(function (o, k) { return o == null ? o : o[k]; }, data);
      if (v == null) throw new Error('crew: no value for ' + p);
      return String(v);
    });
  }

  var n = 0;
  root.DX_CREW = DX_CREW;
  root.CREW_TEMPLATE = CREW_TEMPLATE;
  /* A still crew member for the PNGs: a size x size box holding the SVG at its rest pose. */
  root.DXCHAR = function (props) {
    var p = Object.assign({}, props, { animate: false, id: 'dxc' + (++n) });
    var d = DX_CREW(p);
    return '<div style="width: ' + d.size + '; height: ' + d.size + '; position: relative">' + fill(CREW_TEMPLATE, d) + '</div>';
  };
})(typeof window !== 'undefined' ? window : globalThis);
