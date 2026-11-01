// The DayXero crew for the website: Xero, Jelli, Glim and the Horizon scene, drawn as inline SVG.
// Ported from the v4 design canvas (design/handoff/canvas/project/{Xero,Jelli,Glim2,Horizon2}.dc.html).
// Usage: <span data-crew="xero" data-mood="hello" data-stage="2" data-size="240"></span>
//        <span data-horizon="dawn" data-clarity="100" data-w="1800" data-h="920" data-fit="xMidYMax slice"></span>
// Also runs the homepage intro (section.hero) and the FAQ. No dependencies.
(function () {
  'use strict';

  const REDUCE = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  const INK = '#24163A';
  let uid = 0;

  const ks = (n) => Array(n).fill('0.45 0 0.55 1').join(';');
  function anim(on, vals, kt, dur) {
    return { v: (on ? vals : vals.map(() => vals[0])).join(';'), kt: kt.join(';'), ks: ks(kt.length - 1), dur: dur + 's' };
  }
  function faces(L, R, y, C, fillInk) {
    const closed = { eyeL: `M${L - 6} ${y} Q${L} ${y + 5} ${L + 6} ${y}`, eyeR: `M${R - 6} ${y} Q${R} ${y + 5} ${R + 6} ${y}`, eyeW: 3.5 };
    return {
      hello: { eyeL: `M${L} ${y - 3} L${L} ${y + 3}`, eyeR: `M${R} ${y - 3} L${R} ${y + 3}`, eyeW: 8, mouth: `M${C - 8} ${y + 14} Q${C} ${y + 22} ${C + 8} ${y + 14}`, mouthFill: 'none' },
      calm: { ...closed, mouth: `M${C - 5} ${y + 15} Q${C} ${y + 19} ${C + 5} ${y + 15}`, mouthFill: 'none' },
      breathe: { ...closed, mouth: `M${C} ${y + 12} C${C + 6} ${y + 12} ${C + 6} ${y + 23} ${C} ${y + 23} C${C - 6} ${y + 23} ${C - 6} ${y + 12} ${C} ${y + 12} Z`, mouthFill: fillInk },
      cheer: { eyeL: `M${L - 6} ${y + 2} Q${L} ${y - 5} ${L + 6} ${y + 2}`, eyeR: `M${R - 6} ${y + 2} Q${R} ${y - 5} ${R + 6} ${y + 2}`, eyeW: 3.5, mouth: `M${C - 10} ${y + 12} L${C + 10} ${y + 12} Q${C} ${y + 28} ${C - 10} ${y + 12} Z`, mouthFill: fillInk },
      sleepy: { eyeL: `M${L - 6} ${y + 1} L${L + 6} ${y + 1}`, eyeR: `M${R - 6} ${y + 1} L${R + 6} ${y + 1}`, eyeW: 3.5, mouth: `M${C - 3} ${y + 16} Q${C} ${y + 18} ${C + 3} ${y + 16}`, mouthFill: 'none' }
    };
  }
  const AT = (name, type, a) => `<animateTransform attributeName="transform" type="${type}" values="${a.v}" keyTimes="${a.kt}" keySplines="${a.ks}" calcMode="spline" dur="${a.dur}" repeatCount="indefinite"></animateTransform>`;
  const eyes = (f, on, blink, dur, C, y, stroke) => `<g transform="translate(${C} ${y})"><g><animateTransform attributeName="transform" type="scale" values="${on && blink ? '1 1;1 1;1 0.1;1 1' : '1 1;1 1;1 1;1 1'}" keyTimes="0;0.92;0.96;1" dur="${dur}s" repeatCount="indefinite"></animateTransform><g transform="translate(${-C} ${-y})"><path d="${f.eyeL}" fill="none" stroke="${stroke}" stroke-width="${f.eyeW}" stroke-linecap="round"></path><path d="${f.eyeR}" fill="none" stroke="${stroke}" stroke-width="${f.eyeW}" stroke-linecap="round"></path></g></g></g>`;

  function xero(o) {
    const { mood, stage, size, on } = o;
    const id = 'xh' + (++uid);
    const C = 100, L = 86, R = 114, y = 78;
    const f = faces(L, R, y, C, INK)[mood] || faces(L, R, y, C, INK).hello;
    const body = ({
      hello: anim(on, ['1 1', '1.025 0.985', '1 1'], [0, 0.5, 1], 5),
      calm: anim(on, ['1 1', '1.02 0.99', '1 1'], [0, 0.5, 1], 6),
      breathe: anim(on, ['1 1', '1.07 1.07', '1 1'], [0, 0.4, 1], 10),
      cheer: anim(on, ['1 1', '1.08 0.9', '0.96 1.06', '1 1', '1 1'], [0, 0.15, 0.35, 0.55, 1], 1.4),
      sleepy: anim(on, ['1 1', '1.015 0.99', '1 1'], [0, 0.5, 1], 7)
    })[mood];
    const hop = mood === 'cheer' ? anim(on, ['0 0', '0 0', '0 -18', '0 0', '0 0'], [0, 0.15, 0.35, 0.55, 1], 1.4) : anim(on, ['0 0', '0 0'], [0, 1], 1);
    const sway = mood === 'sleepy' ? anim(on, ['-3', '3', '-3'], [0, 0.5, 1], 7) : anim(on, ['0', '0'], [0, 1], 1);
    const sunY = { 1: 168, 2: 156, 3: 142, 4: 128 }[stage] || 156;
    const sun = mood === 'breathe' ? anim(on, [`${sunY}`, `${sunY - 16}`, `${sunY}`], [0, 0.4, 1], 10) : anim(on, [`${sunY}`, `${sunY - 3}`, `${sunY}`], [0, 0.5, 1], 4);
    const up = mood === 'cheer';
    const armL = up ? 'M38 112 C28 98 24 86 26 74' : 'M36 124 C26 132 22 142 24 152';
    const armR = up ? 'M162 112 C172 98 176 86 174 74' : 'M164 124 C174 132 178 142 176 152';
    return `<svg width="${size}" height="${size}" viewBox="0 0 200 200" role="img" aria-label="Xero, ${mood}">
<defs><clipPath id="${id}"><ellipse cx="100" cy="138" rx="21" ry="29"></ellipse></clipPath></defs>
<ellipse cx="100" cy="192" rx="48" ry="6" fill="#000" opacity="0.12"></ellipse>
<g>${AT('hop', 'translate', hop)}<g transform="translate(100 190)"><g>${AT('body', 'scale', body)}<g>${AT('sway', 'rotate', sway)}<g transform="translate(-100 -190)">
<ellipse cx="100" cy="138" rx="21" ry="29" fill="#BFD7FF"></ellipse>
<g clip-path="url(#${id})"><circle cx="100" cy="${sunY}" r="11" fill="#FFC93C"><animate attributeName="cy" values="${sun.v}" keyTimes="${sun.kt}" keySplines="${sun.ks}" calcMode="spline" dur="${sun.dur}" repeatCount="indefinite"></animate></circle><path d="M76 160 C90 152 110 156 124 150 L124 172 L76 172 Z" fill="#3FB37F"></path></g>
<ellipse cx="84" cy="188" rx="12" ry="7" fill="#C9542F"></ellipse><ellipse cx="116" cy="188" rx="12" ry="7" fill="#C9542F"></ellipse>
<path d="${armL}" fill="none" stroke="#FF7155" stroke-width="12" stroke-linecap="round"></path><path d="${armR}" fill="none" stroke="#FF7155" stroke-width="12" stroke-linecap="round"></path>
<path fill-rule="evenodd" d="M100 34 C138 34 166 68 166 112 C166 156 138 188 100 188 C62 188 34 156 34 112 C34 68 62 34 100 34 Z M100 109 C112 109 121 121 121 138 C121 155 112 167 100 167 C88 167 79 155 79 138 C79 121 88 109 100 109 Z" fill="#FF7155"></path>
<path d="M136 52 C156 70 166 92 166 112 C166 156 138 188 100 188 C126 178 146 150 146 112 C146 88 142 68 136 52 Z" fill="#E85A3E"></path>
<path d="M58 82 C62 66 74 52 90 46" fill="none" stroke="#FFB09C" stroke-width="6" stroke-linecap="round"></path>
<g opacity="${stage >= 4 ? 1 : 0}" stroke="#FFC93C" stroke-width="3" stroke-linecap="round"><path d="M100 24 l0 -10"></path><path d="M146 40 l7 -7"></path><path d="M54 40 l-7 -7"></path></g>
<circle cx="72" cy="92" r="7" fill="#FFB09C" opacity="0.8"></circle><circle cx="128" cy="92" r="7" fill="#FFB09C" opacity="0.8"></circle>
${eyes(f, on, mood === 'hello' || up, 4.5, C, y, INK)}
<path d="${f.mouth}" fill="${f.mouthFill}" stroke="${INK}" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"></path>
</g></g></g></g></g>
<g opacity="${up ? 1 : 0}" stroke="${INK}" stroke-width="3" stroke-linecap="round"><path d="M26 64 l0 12 M20 70 l12 0"></path><path d="M174 70 l0 10 M169 75 l10 0"></path></g>
<g opacity="${mood === 'sleepy' ? 1 : 0}" fill="none" stroke="${INK}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><animateTransform attributeName="transform" type="translate" values="${on ? '0 0;5 -8;0 0' : '0 0;0 0;0 0'}" dur="3s" repeatCount="indefinite"></animateTransform><path d="M150 40 h12 l-12 12 h12"></path><path d="M170 20 h8 l-8 8 h8"></path></g>
<g opacity="${mood === 'breathe' ? 1 : 0}" fill="none" stroke="${INK}" stroke-width="3" stroke-linecap="round"><animateTransform attributeName="transform" type="translate" values="${on ? '0 0;8 0;0 0' : '0 0;0 0;0 0'}" dur="5s" repeatCount="indefinite"></animateTransform><path d="M172 100 q8 -5 16 0"></path><path d="M176 112 q6 -4 12 0"></path></g>
</svg>`;
  }

  function jelli(o) {
    const { mood, stage, size, on } = o;
    const C = 100, L = 86, R = 114, y = 92;
    const f = faces(L, R, y, C, INK)[mood] || faces(L, R, y, C, INK).hello;
    const body = ({
      hello: anim(on, ['1 1', '1.06 0.95', '1 1'], [0, 0.35, 1], 3),
      calm: anim(on, ['1 1', '1.04 0.97', '1 1'], [0, 0.4, 1], 5),
      breathe: anim(on, ['1 1', '1.12 1.05', '1 1'], [0, 0.4, 1], 10),
      cheer: anim(on, ['1 1', '1.12 0.88', '0.95 1.06', '1 1', '1 1'], [0, 0.15, 0.35, 0.55, 1], 1.2),
      sleepy: anim(on, ['1 1', '1.03 0.98', '1 1'], [0, 0.5, 1], 7)
    })[mood];
    const hop = mood === 'cheer' ? anim(on, ['0 0', '0 0', '0 -18', '0 0', '0 0'], [0, 0.15, 0.35, 0.55, 1], 1.2) : anim(on, ['0 0', '0 -7', '0 0'], [0, 0.5, 1], mood === 'sleepy' ? 7 : 4);
    const sway = mood === 'sleepy' ? anim(on, ['-4', '4', '-4'], [0, 0.5, 1], 7) : anim(on, ['0', '0'], [0, 1], 1);
    const tent = (x, col, begin) => {
      const a = `M${x} 122 C${x - 6} 138 ${x + 6} 152 ${x} 166 C${x - 4} 174 ${x + 2} 180 ${x - 2} 186`;
      const b = `M${x} 122 C${x + 6} 138 ${x - 6} 152 ${x} 166 C${x + 4} 174 ${x - 2} 180 ${x + 2} 186`;
      return `<path d="${a}" fill="none" stroke="${col}" stroke-width="5" stroke-linecap="round"><animate attributeName="d" values="${on ? `${a};${b};${a}` : `${a};${a};${a}`}" dur="2.4s" begin="${begin}s" repeatCount="indefinite"></animate></path>`;
    };
    const up = mood === 'cheer';
    const bubbles = mood === 'breathe' || mood === 'calm';
    return `<svg width="${size}" height="${size}" viewBox="0 0 200 200" role="img" aria-label="Jelli, ${mood}">
<ellipse cx="100" cy="194" rx="34" ry="4" fill="#000" opacity="0.08"></ellipse>
<g opacity="${bubbles ? 1 : 0}" fill="none" stroke="#FFFFFF" stroke-width="2.5"><circle cx="160" cy="150" r="5"><animate attributeName="cy" values="${on ? '160;60' : '150;150'}" dur="4s" repeatCount="indefinite"></animate></circle><circle cx="44" cy="130" r="3.5"><animate attributeName="cy" values="${on ? '130;40' : '130;130'}" dur="5s" begin="1s" repeatCount="indefinite"></animate></circle></g>
<g>${AT('hop', 'translate', hop)}
<g opacity="${stage >= 4 ? 1 : 0}"><path d="M100 18 l4 9 l9 1 l-7 6 l2 9 l-8 -5 l-8 5 l2 -9 l-7 -6 l9 -1 Z" fill="#FFC93C"></path></g>
${tent(78, '#F07188', 0)}${tent(93, '#FF8FA3', 0.3)}${tent(108, '#F07188', 0.6)}${tent(123, '#FF8FA3', 0.9)}
<path d="${up ? 'M56 118 C42 106 38 92 44 78' : 'M58 120 C50 136 60 150 52 166'}" fill="none" stroke="#FFC2CD" stroke-width="10" stroke-linecap="round"></path>
<path d="${up ? 'M144 118 C158 106 162 92 156 78' : 'M142 120 C150 136 140 150 148 166'}" fill="none" stroke="#FFC2CD" stroke-width="10" stroke-linecap="round"></path>
<g transform="translate(100 44)"><g>${AT('body', 'scale', body)}<g>${AT('sway', 'rotate', sway)}<g transform="translate(-100 -44)">
<path d="M42 112 C40 68 66 44 100 44 C134 44 160 68 158 112 C158 120 152 124 144 121 C136 128 126 128 118 121 C110 128 90 128 82 121 C74 128 64 128 56 121 C48 124 42 120 42 112 Z" fill="#FF8FA3"></path>
<path d="M120 48 C146 58 160 82 158 112 C158 120 152 124 144 121 C148 94 140 68 120 48 Z" fill="#F07188"></path>
<path d="M48 110 C70 116 130 116 152 110 C152 114 150 116 146 116 C120 122 80 122 54 116 C50 116 48 114 48 110 Z" fill="#FFB3C1"></path>
<path d="M62 78 C66 62 78 52 94 48" fill="none" stroke="#FFD6DE" stroke-width="7" stroke-linecap="round"></path>
<circle cx="62" cy="96" r="4" fill="#FFF1B8"></circle><circle cx="140" cy="88" r="4" fill="#FFF1B8" opacity="${stage >= 2 ? 1 : 0}"></circle><circle cx="132" cy="66" r="3" fill="#FFF1B8" opacity="${stage >= 2 ? 1 : 0}"></circle><circle cx="74" cy="64" r="3" fill="#FFF1B8" opacity="${stage >= 3 ? 1 : 0}"></circle><circle cx="148" cy="104" r="3" fill="#FFF1B8" opacity="${stage >= 3 ? 1 : 0}"></circle>
<circle cx="72" cy="104" r="7" fill="#FF6F8E" opacity="0.6"></circle><circle cx="128" cy="104" r="7" fill="#FF6F8E" opacity="0.6"></circle>
${eyes(f, on, mood === 'hello' || up, 4.2, C, y, INK)}
<path d="${f.mouth}" fill="${f.mouthFill}" stroke="${INK}" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"></path>
</g></g></g></g></g>
<g opacity="${up ? 1 : 0}" stroke="${INK}" stroke-width="3" stroke-linecap="round"><path d="M24 60 l0 12 M18 66 l12 0"></path><path d="M176 56 l0 10 M171 61 l10 0"></path></g>
<g opacity="${mood === 'sleepy' ? 1 : 0}" fill="none" stroke="${INK}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><animateTransform attributeName="transform" type="translate" values="${on ? '0 0;5 -8;0 0' : '0 0;0 0;0 0'}" dur="3s" repeatCount="indefinite"></animateTransform><path d="M154 30 h12 l-12 12 h12"></path><path d="M174 12 h8 l-8 8 h8"></path></g>
</svg>`;
  }

  function glim(o) {
    const { mood, size, on } = o;
    const stage = Math.min(4, Math.max(1, o.stage));
    const C = 100, L = 86, R = 114, y = 94, fc = '#FFF8EE';
    const f = faces(L, R, y, C, fc)[mood] || faces(L, R, y, C, fc).hello;
    const body = ({
      hello: anim(on, ['1 1', '1.025 0.985', '1 1'], [0, 0.5, 1], 4),
      calm: anim(on, ['1 1', '1.02 0.99', '1 1'], [0, 0.5, 1], 6),
      breathe: anim(on, ['1 1', '1.07 1.07', '1 1'], [0, 0.4, 1], 10),
      cheer: anim(on, ['1 1', '1.08 0.9', '0.96 1.06', '1 1', '1 1'], [0, 0.15, 0.35, 0.55, 1], 1.3),
      sleepy: anim(on, ['1 1', '1.015 0.99', '1 1'], [0, 0.5, 1], 7)
    })[mood];
    const hop = mood === 'cheer' ? anim(on, ['0 0', '0 0', '0 -18', '0 0', '0 0'], [0, 0.15, 0.35, 0.55, 1], 1.3) : anim(on, ['0 0', '0 -7', '0 0'], [0, 0.5, 1], mood === 'sleepy' ? 7 : 3);
    const sway = mood === 'sleepy' ? anim(on, ['-4', '4', '-4'], [0, 0.5, 1], 7) : anim(on, ['0', '0'], [0, 1], 1);
    const up = mood === 'cheer';
    const base = [30, 38, 48, 58][stage - 1];
    const flap = mood === 'sleepy' ? null : (mood === 'breathe' || mood === 'calm' ? '1.2s' : '0.3s');
    const glowDur = mood === 'breathe' ? '10s' : '2.6s';
    const twinkle = on ? '0.2;1;0.2' : '1;1;1';
    const wing = (cx, cy, vals, inner) => `<g transform="translate(${cx} ${cy})"><g><animateTransform attributeName="transform" type="rotate" values="${on && flap ? vals : '0;0;0'}" dur="${flap || '1s'}" repeatCount="indefinite"></animateTransform><g transform="translate(${-cx} ${-cy})">${inner}</g></g></g>`;
    return `<svg width="${size}" height="${size}" viewBox="0 0 200 200" role="img" aria-label="Glim, ${mood}">
<ellipse cx="100" cy="194" rx="34" ry="4" fill="#000" opacity="0.1"></ellipse>
<g opacity="${stage >= 4 ? 1 : 0}" fill="#FFE27A"><path d="M30 60 l3 7 l7 3 l-7 3 l-3 7 l-3 -7 l-7 -3 l7 -3 Z"><animate attributeName="opacity" values="${twinkle}" dur="1.8s" repeatCount="indefinite"></animate></path><path d="M168 120 l2.5 5 l5 2.5 l-5 2.5 l-2.5 5 l-2.5 -5 l-5 -2.5 l5 -2.5 Z"><animate attributeName="opacity" values="${twinkle}" dur="2.3s" begin="0.6s" repeatCount="indefinite"></animate></path><path d="M40 160 l2 4 l4 2 l-4 2 l-2 4 l-2 -4 l-4 -2 l4 -2 Z"><animate attributeName="opacity" values="${twinkle}" dur="2s" begin="1.1s" repeatCount="indefinite"></animate></path></g>
<g>${AT('hop', 'translate', hop)}
<circle cx="100" cy="150" r="${base}" fill="#FFE27A" opacity="0.3" style="mix-blend-mode: plus-lighter"><animate attributeName="r" values="${on ? `${base};${base + 10};${base}` : `${base};${base};${base}`}" dur="${glowDur}" repeatCount="indefinite"></animate><animate attributeName="opacity" values="${on ? '0.22;0.45;0.22' : '0.3;0.3;0.3'}" dur="${glowDur}" repeatCount="indefinite"></animate></circle>
<g transform="translate(100 120)"><g>${AT('body', 'scale', body)}<g>${AT('sway', 'rotate', sway)}<g transform="translate(-100 -120)">
${wing(84, 82, '0;-14;0', '<ellipse cx="58" cy="66" rx="30" ry="17" transform="rotate(-28 58 66)" fill="#E9F1FF" opacity="0.92" stroke="#B9C6F2" stroke-width="2"></ellipse><path d="M40 74 C52 66 66 62 80 64" fill="none" stroke="#B9C6F2" stroke-width="1.5" stroke-linecap="round"></path>')}
${wing(116, 82, '0;14;0', '<ellipse cx="142" cy="66" rx="30" ry="17" transform="rotate(28 142 66)" fill="#E9F1FF" opacity="0.92" stroke="#B9C6F2" stroke-width="2"></ellipse><path d="M160 74 C148 66 134 62 120 64" fill="none" stroke="#B9C6F2" stroke-width="1.5" stroke-linecap="round"></path>')}
<path d="M90 62 C84 50 78 40 74 32" fill="none" stroke="#5638C4" stroke-width="3.5" stroke-linecap="round"></path><path d="M110 62 C116 50 122 40 126 32" fill="none" stroke="#5638C4" stroke-width="3.5" stroke-linecap="round"></path>
<circle cx="73" cy="29" r="6" fill="#FFE27A"></circle><circle cx="127" cy="29" r="6" fill="#FFE27A"></circle>
<ellipse cx="100" cy="150" rx="33" ry="31" fill="#FFE27A"></ellipse>
<path d="M70 146 C84 154 116 154 130 146 M72 160 C86 168 114 168 128 160" fill="none" stroke="#F2C94C" stroke-width="3.5" stroke-linecap="round"></path>
<path d="M80 132 C86 126 94 124 100 124" fill="none" stroke="#FFF6C8" stroke-width="4" stroke-linecap="round"></path>
<path d="${up ? 'M66 108 C54 98 50 86 52 74' : 'M64 114 C54 120 50 128 52 136'}" fill="none" stroke="#6B4FD8" stroke-width="9" stroke-linecap="round"></path>
<path d="${up ? 'M134 108 C146 98 150 86 148 74' : 'M136 114 C146 120 150 128 148 136'}" fill="none" stroke="#6B4FD8" stroke-width="9" stroke-linecap="round"></path>
<circle cx="100" cy="96" r="40" fill="#6B4FD8"></circle>
<path d="M124 64 C136 74 142 88 140 102 C138 118 126 132 108 136 C124 124 132 108 130 94 C129 82 126 72 124 64 Z" fill="#5638C4"></path>
<path d="M70 84 C72 72 80 64 90 60" fill="none" stroke="#9A84F0" stroke-width="5" stroke-linecap="round"></path>
<circle cx="74" cy="106" r="6" fill="#FF8FA3" opacity="0.8"></circle><circle cx="126" cy="106" r="6" fill="#FF8FA3" opacity="0.8"></circle>
${eyes(f, on, mood === 'hello' || up, 4.4, C, y, fc)}
<path d="${f.mouth}" fill="${f.mouthFill}" stroke="${fc}" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"></path>
</g></g></g></g></g>
<g opacity="${mood === 'sleepy' ? 1 : 0}" fill="none" stroke="#9A84F0" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><animateTransform attributeName="transform" type="translate" values="${on ? '0 0;5 -8;0 0' : '0 0;0 0;0 0'}" dur="3s" repeatCount="indefinite"></animateTransform><path d="M150 34 h12 l-12 12 h12"></path><path d="M170 16 h8 l-8 8 h8"></path></g>
</svg>`;
  }

  // Horizon: paper-cut scenes. `clarity` 0–100 controls the haze ("the sky clears as you do").
  function horizon(o) {
    const { scene, w, h, fit, on } = o;
    const clarity = Math.min(100, Math.max(0, o.clarity));
    const fog = 1 - clarity / 100;
    const p = 'hz' + (++uid);
    const S = (a, b) => (on ? a : b);
    const haze = scene === 'night' ? '#8E80C9' : scene === 'dusk' ? '#E9D6F0' : '#F3ECE3';
    const hazeO = (fog * 0.7).toFixed(2), hazeTop = (fog * 0.35).toFixed(2);
    const sunY = 168;
    const twinkle = S('0.25;1;0.25', '1;1;1'), drift = S('0 0;22 0;0 0', '0 0;0 0;0 0'), pulseR = S('120;140;120', '130;130;130');
    const waveA = S('0 0;-18 2;0 0', '0 0;0 0;0 0'), waveB = S('0 0;20 -3;0 0', '0 0;0 0;0 0'), waveC = S('0 0;-26 3;0 0', '0 0;0 0;0 0');
    const lift = `filter="url(#${p}Lift)"`;
    const hz = `<rect class="hz-haze" width="400" height="300" fill="${haze}" opacity="${hazeO}"></rect>`;
    const scenes = {
      dawn: `<rect width="400" height="300" fill="url(#${p}Dawn)"></rect>
<circle cx="200" cy="168" r="130" fill="url(#${p}Glow)" opacity="0.6"><animate attributeName="r" values="${pulseR}" dur="6s" repeatCount="indefinite"></animate></circle>
<circle cx="200" cy="${sunY}" r="70" fill="url(#${p}Sun)"><animate attributeName="cy" values="${S(`${sunY + 60};${sunY}`, `${sunY};${sunY}`)}" dur="2.6s" fill="freeze" calcMode="spline" keySplines="0.2 0.7 0.2 1" keyTimes="0;1"></animate></circle>
<g filter="url(#${p}Soft)" opacity="0.85" fill="#FFF4E6"><animateTransform attributeName="transform" type="translate" values="${drift}" dur="24s" repeatCount="indefinite"></animateTransform><ellipse cx="70" cy="86" rx="46" ry="14"></ellipse><ellipse cx="98" cy="74" rx="28" ry="14"></ellipse><ellipse cx="330" cy="62" rx="40" ry="12"></ellipse></g>
${hz}
<path ${lift} d="M0 192 C60 162 120 172 180 187 C250 204 320 172 400 166 L400 300 L0 300 Z" fill="#FF9D6E"></path>
<path ${lift} d="M0 222 C80 196 150 206 220 224 C290 240 350 216 400 206 L400 300 L0 300 Z" fill="#FF7A55"></path>
<path ${lift} d="M0 252 C70 233 140 241 210 256 C280 271 340 251 400 243 L400 300 L0 300 Z" fill="#E85A3E"></path>
<path ${lift} d="M0 282 C90 267 180 273 260 283 C320 291 360 285 400 279 L400 300 L0 300 Z" fill="#C2402A"></path>
<path d="M0 222 C80 196 150 206 220 224 C290 240 350 216 400 206 L400 300 L0 300 Z" fill="url(#${p}Sheen)"></path>
<path d="M330 34 Q330 46 342 46 Q330 46 330 58 Q330 46 318 46 Q330 46 330 34 Z" fill="#FFF8EE"><animate attributeName="opacity" values="${twinkle}" dur="2.2s" repeatCount="indefinite"></animate></path>`,
      dusk: `<rect width="400" height="300" fill="url(#${p}Dusk)"></rect>
<circle cx="300" cy="190" r="110" fill="url(#${p}Glow)" opacity="0.45"></circle><circle cx="300" cy="196" r="44" fill="#FFB86B"></circle>
<g filter="url(#${p}Soft)" opacity="0.8" fill="#FFE0EE"><animateTransform attributeName="transform" type="translate" values="${drift}" dur="26s" repeatCount="indefinite"></animateTransform><ellipse cx="90" cy="80" rx="52" ry="14"></ellipse><ellipse cx="120" cy="68" rx="30" ry="14"></ellipse></g>
<circle cx="70" cy="40" r="1.6" fill="#FFF8EE"><animate attributeName="opacity" values="${twinkle}" dur="1.9s" repeatCount="indefinite"></animate></circle><circle cx="200" cy="30" r="1.4" fill="#FFF8EE"><animate attributeName="opacity" values="${twinkle}" dur="2.6s" begin="0.7s" repeatCount="indefinite"></animate></circle>
${hz}
<path ${lift} d="M0 196 C70 170 140 178 200 192 C270 208 330 180 400 172 L400 300 L0 300 Z" fill="#B572C9"></path>
<path ${lift} d="M0 228 C90 202 160 212 230 230 C300 246 350 222 400 214 L400 300 L0 300 Z" fill="#8E55BF"></path>
<path ${lift} d="M0 258 C80 238 150 246 220 262 C290 278 350 258 400 250 L400 300 L0 300 Z" fill="#6A3AA8"></path>
<path ${lift} d="M0 286 C90 272 160 278 240 288 C310 296 360 290 400 284 L400 300 L0 300 Z" fill="#4A2588"></path>`,
      sea: `<rect width="400" height="300" fill="url(#${p}Day)"></rect>
<circle cx="110" cy="96" r="80" fill="url(#${p}Glow)" opacity="0.6"><animate attributeName="r" values="${pulseR}" dur="10s" repeatCount="indefinite"></animate></circle><circle cx="110" cy="96" r="34" fill="url(#${p}Sun)"></circle>
<g filter="url(#${p}Soft)" opacity="0.9" fill="#FFFFFF"><animateTransform attributeName="transform" type="translate" values="${drift}" dur="20s" repeatCount="indefinite"></animateTransform><ellipse cx="300" cy="64" rx="56" ry="15"></ellipse><ellipse cx="330" cy="52" rx="30" ry="14"></ellipse></g>
${hz}
<g><animateTransform attributeName="transform" type="translate" values="${waveA}" dur="7s" repeatCount="indefinite"></animateTransform><path ${lift} d="M-40 176 C10 166 60 172 110 168 C180 162 260 170 440 164 L440 300 L-40 300 Z" fill="#9CCBFF"></path></g>
<g><animateTransform attributeName="transform" type="translate" values="${waveB}" dur="5s" repeatCount="indefinite"></animateTransform><path ${lift} d="M-40 206 C20 190 70 196 120 208 C180 222 240 196 300 194 C350 193 400 198 440 202 L440 300 L-40 300 Z" fill="#5A9DFF"></path></g>
<g><animateTransform attributeName="transform" type="translate" values="${waveC}" dur="6s" repeatCount="indefinite"></animateTransform><path ${lift} d="M-40 240 C10 222 60 226 110 240 C160 254 210 230 260 228 C320 226 380 234 440 240 L440 300 L-40 300 Z" fill="#2F72F2"></path><path d="M90 236 C102 222 122 220 132 232 C120 230 110 234 104 242 Z" fill="#FFF8EE"></path></g>
<g><animateTransform attributeName="transform" type="translate" values="${waveB}" dur="8s" repeatCount="indefinite"></animateTransform><path ${lift} d="M-40 276 C20 262 80 266 140 276 C200 286 260 268 440 272 L440 300 L-40 300 Z" fill="#1C4FCC"></path></g>`,
      night: `<rect width="400" height="300" fill="url(#${p}Night)"></rect>
<circle cx="60" cy="40" r="1.8" fill="#FFF8EE"><animate attributeName="opacity" values="${twinkle}" dur="2s" repeatCount="indefinite"></animate></circle><circle cx="150" cy="24" r="1.4" fill="#FFF8EE"><animate attributeName="opacity" values="${twinkle}" dur="2.7s" begin="0.4s" repeatCount="indefinite"></animate></circle><circle cx="230" cy="60" r="1.6" fill="#FFF8EE"><animate attributeName="opacity" values="${twinkle}" dur="1.8s" begin="1s" repeatCount="indefinite"></animate></circle><circle cx="360" cy="110" r="1.4" fill="#FFF8EE"><animate attributeName="opacity" values="${twinkle}" dur="2.4s" begin="0.2s" repeatCount="indefinite"></animate></circle><circle cx="30" cy="120" r="1.2" fill="#FFF8EE"><animate attributeName="opacity" values="${twinkle}" dur="3s" begin="0.9s" repeatCount="indefinite"></animate></circle>
<circle cx="290" cy="80" r="70" fill="url(#${p}Glow)" opacity="0.35"></circle>
<path d="M290 46 A34 34 0 1 0 322 98 A28 28 0 1 1 290 46 Z" fill="#FFF1C2"></path>
${hz}
<path ${lift} d="M0 184 C70 158 140 166 200 180 C270 196 330 168 400 160 L400 300 L0 300 Z" fill="#5A3CC4"></path>
<path ${lift} d="M0 218 C90 192 160 202 230 220 C300 236 350 212 400 204 L400 300 L0 300 Z" fill="#432AA6"></path>
<path ${lift} d="M0 252 C80 232 150 240 220 256 C290 272 350 252 400 244 L400 300 L0 300 Z" fill="#2F1C84"></path>
<path ${lift} d="M0 284 C90 270 160 276 240 286 C310 294 360 288 400 282 L400 300 L0 300 Z" fill="#1C1160"></path>
<g fill="#FFE27A"><animateTransform attributeName="transform" type="translate" values="${S('0 0;14 -10;-8 -4;0 0', '0 0;0 0;0 0;0 0')}" dur="9s" repeatCount="indefinite"></animateTransform><circle cx="96" cy="230" r="3"><animate attributeName="opacity" values="${twinkle}" dur="1.6s" repeatCount="indefinite"></animate></circle><circle cx="96" cy="230" r="8" opacity="0.25"></circle><circle cx="300" cy="250" r="2.5"><animate attributeName="opacity" values="${twinkle}" dur="2.1s" begin="0.5s" repeatCount="indefinite"></animate></circle><circle cx="300" cy="250" r="7" opacity="0.25"></circle><circle cx="190" cy="214" r="2"><animate attributeName="opacity" values="${twinkle}" dur="1.3s" begin="0.2s" repeatCount="indefinite"></animate></circle></g>`
    };
    return `<svg width="${w}" height="${h}" viewBox="0 0 400 300" preserveAspectRatio="${fit}" aria-hidden="true" focusable="false">
<defs>
<linearGradient id="${p}Dawn" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FF7E5A"></stop><stop offset="0.55" stop-color="#FFB877"></stop><stop offset="1" stop-color="#FFE6BF"></stop></linearGradient>
<linearGradient id="${p}Day" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5AA9FF"></stop><stop offset="1" stop-color="#D3EEFF"></stop></linearGradient>
<linearGradient id="${p}Dusk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7A5CE0"></stop><stop offset="0.6" stop-color="#E58BB8"></stop><stop offset="1" stop-color="#FFC59A"></stop></linearGradient>
<linearGradient id="${p}Night" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#180F52"></stop><stop offset="1" stop-color="#5A3CC4"></stop></linearGradient>
<radialGradient id="${p}Sun" cx="0.38" cy="0.32" r="0.75"><stop offset="0" stop-color="#FFF6C8"></stop><stop offset="1" stop-color="#FFC23A"></stop></radialGradient>
<radialGradient id="${p}Glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.75"></stop><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"></stop></radialGradient>
<linearGradient id="${p}Sheen" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.22"></stop><stop offset="0.35" stop-color="#FFFFFF" stop-opacity="0"></stop></linearGradient>
<filter id="${p}Lift" x="-5%" y="-20%" width="110%" height="140%"><feDropShadow dx="0" dy="-3" stdDeviation="4" flood-color="#1A0B2E" flood-opacity="0.22"></feDropShadow></filter>
<filter id="${p}Soft" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="4"></feGaussianBlur></filter>
<filter id="${p}Grain" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.85" numOctaves="2" stitchTiles="stitch"></feTurbulence><feColorMatrix values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0.09 0"></feColorMatrix></filter>
</defs>
${scenes[scene] || scenes.dawn}
<rect class="hz-top" width="400" height="300" fill="${haze}" opacity="${hazeTop}"></rect>
<rect width="400" height="300" filter="url(#${p}Grain)"></rect>
</svg>`;
  }

  function renderCrew(el) {
    const who = el.dataset.crew;
    const o = { mood: el.dataset.mood || 'hello', stage: Number(el.dataset.stage || 2), size: Number(el.dataset.size || 200), on: !REDUCE && el.dataset.animate !== 'false' };
    el.innerHTML = who === 'jelli' ? jelli(o) : who === 'glim' ? glim(o) : xero(o);
    if (!el.hasAttribute('aria-hidden')) el.setAttribute('aria-hidden', 'true');
  }
  function renderHorizon(el) {
    el.innerHTML = horizon({ scene: el.dataset.horizon || 'dawn', clarity: Number(el.dataset.clarity ?? 100), w: Number(el.dataset.w || 400), h: Number(el.dataset.h || 300), fit: el.dataset.fit || 'xMidYMid slice', on: !REDUCE && el.dataset.animate !== 'false' });
    el.setAttribute('aria-hidden', 'true');
  }
  function setClarity(el, clarity) {
    const fog = 1 - Math.min(100, Math.max(0, clarity)) / 100;
    const a = el.querySelector('.hz-haze'), b = el.querySelector('.hz-top');
    if (a) a.setAttribute('opacity', (fog * 0.7).toFixed(2));
    if (b) b.setAttribute('opacity', (fog * 0.35).toFixed(2));
  }
  function renderAll(root) {
    (root || document).querySelectorAll('[data-crew]').forEach(renderCrew);
    (root || document).querySelectorAll('[data-horizon]').forEach(renderHorizon);
  }
  renderAll();
  window.DXCrew = { renderAll, renderCrew, renderHorizon, setClarity };

  // --- Homepage intro: night, then first light. Full the first time in a tab, short after that. ---
  const hero = document.querySelector('.hero[data-intro]');
  if (hero) {
    const sky = hero.querySelector('[data-horizon]');
    let timers = [], skyTimer = null;
    const seen = (() => { try { return sessionStorage.getItem('dx_intro') === '1'; } catch (e) { return false; } })();
    const clear = () => { timers.forEach(clearTimeout); timers = []; clearInterval(skyTimer); };
    const phase = (n) => { for (let i = 1; i <= 4; i++) hero.classList.toggle('is-p' + i, i <= n); };

    function finish() {
      clear();
      if (sky) { sky.dataset.clarity = '100'; renderHorizon(sky); }
      phase(4);
      hero.classList.add('is-done');
    }
    function play() {
      clear();
      hero.classList.remove('is-done');
      phase(0);
      if (sky) { sky.dataset.clarity = '0'; renderHorizon(sky); }
      timers.push(setTimeout(() => {
        phase(1);
        let c = 0;
        skyTimer = setInterval(() => { c = Math.min(100, c + 2); if (sky) setClarity(sky, c); if (c >= 100) clearInterval(skyTimer); }, 48);
      }, 400));
      timers.push(setTimeout(() => phase(2), 1500));
      timers.push(setTimeout(() => phase(3), 2100));
      timers.push(setTimeout(() => { phase(4); hero.classList.add('is-done'); }, 2900));
      try { sessionStorage.setItem('dx_intro', '1'); } catch (e) {}
    }
    if (REDUCE) finish();
    else if (seen) { hero.classList.add('is-quick'); finish(); }
    else play();
    hero.querySelectorAll('[data-replay]').forEach((b) => b.addEventListener('click', () => { hero.classList.remove('is-quick'); play(); }));
  }

  // --- FAQ: one open at a time ---
  const faq = document.querySelector('[data-faq]');
  if (faq) {
    faq.querySelectorAll('details').forEach((d) => d.addEventListener('toggle', () => {
      if (d.open) faq.querySelectorAll('details[open]').forEach((o) => { if (o !== d) o.open = false; });
    }));
  }

  // --- Reveal on scroll ---
  const els = document.querySelectorAll('.rv');
  if ('IntersectionObserver' in window && !REDUCE) {
    const io = new IntersectionObserver((entries) => entries.forEach((en) => { if (en.isIntersecting) { en.target.classList.add('is-in'); io.unobserve(en.target); } }), { rootMargin: '0px 0px -8% 0px' });
    els.forEach((el) => { el.classList.add('rv-js'); io.observe(el); });
  } else els.forEach((el) => el.classList.add('is-in'));
})();
