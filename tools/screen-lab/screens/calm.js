/* DayXero Screen Lab — Calm tools (DayXero/Calm/CalmToolsView.swift, DayXeroCore/Logic/CalmTools.swift)
   and each tool's player (CalmToolPlayer, OrbBreathingPanel, BioOrbView). See ../FORMAT.md. */
(function () {
  'use strict';
  const Lab = window.Lab;
  const E = Lab.element, esc = Lab.esc, T = Lab.text, F = Lab.font;
  const SRC = 'DayXero/Calm/CalmToolsView.swift';
  const LOGIC = 'DayXeroCore/Logic/CalmTools.swift';
  const ORB = 'DayXero/Orb/OrbBreathingPanel.swift';
  const BIO = 'DayXero/Orb/BioOrbView.swift';
  const V4 = 'DayXero/Shared/V4Reading.swift';

  /* Read4 (DayXero/Shared/V4Reading.swift): the reading tier's colours for the appearance. */
  function R4(ctx) {
    const d = ctx.dark;
    const g = Lab.ground('reading', d);
    return {
      bg: g.bg, ink: g.ink, muted: g.muted,
      faint: d ? 'rgba(255,248,238,0.38)' : 'rgba(30,26,58,0.38)',
      hairline: d ? 'rgba(255,255,255,0.14)' : 'rgba(30,26,58,0.12)',
      track: d ? 'rgba(255,255,255,0.16)' : 'rgba(30,26,58,0.12)',
      card: Lab.c(Lab.fill.raised, d), surface: Lab.c(Lab.fill.surface, d),
      accent: Lab.c(Lab.fill.green, d), accentRGB: d ? '47,208,138' : '15,110,67',
      accentSoft: d ? 'rgba(47,208,138,0.16)' : 'rgba(15,110,67,0.12)',
    };
  }
  const readCtx = (ctx) => ctx.with({ groundName: 'reading' });

  /* SF Symbols this file needs that lab.js doesn't draw. */
  const GLYPHS = {
    'figure.stand': '<circle cx="12" cy="4.2" r="2.3" fill="currentColor"/><path d="M9.2 7.6h5.6a1.6 1.6 0 0 1 1.6 1.6v5.2a.9.9 0 0 1-1.8 0V10.6h-.5V20.8a1.1 1.1 0 0 1-2.2 0v-5.6h-.8v5.6a1.1 1.1 0 0 1-2.2 0V10.6h-.5v3.8a.9.9 0 0 1-1.8 0V9.2a1.6 1.6 0 0 1 1.6-1.6z" fill="currentColor"/>',
    waveform: '<path d="M4 10v4M8 7v10M12 4v16M16 8v8M20 10.5v3" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/>',
    'arrow.counterclockwise': '<path d="M5.5 12a6.5 6.5 0 1 0 2-4.7" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/><path d="M4.5 4.5v4h4" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>',
  };
  function glyph(name, size, colour) {
    if (GLYPHS[name]) return `<svg viewBox="0 0 24 24" width="${size}" height="${size}" style="color:${colour};flex:none;display:block" aria-hidden="true">${GLYPHS[name]}</svg>`;
    return Lab.icon(name, size, colour);
  }
  const ICON_OPTS = [['', 'None'], ['play.fill', 'Play'], ['pause.fill', 'Pause'], ['checkmark', 'Tick'], ['waveform', 'Waveform'], ['arrow.counterclockwise', 'Again arrow'], ['figure.stand', 'Standing figure'], ['xmark', 'Close']];

  /* ---------- Calm tools list ---------- */
  E({
    type: 'calmToolRow', name: 'Calm tool tile', group: 'Calm', source: SRC,
    description: 'CalmToolRow: a 64 pt kit illustration (radius 18), a 16 pt bold title over a 14 pt detail, and a chevron, on a cream tile with radius 22.',
    props: {
      title: { label: 'Title', kind: 'text', default: 'Box breathing' },
      detail: { label: 'Detail', kind: 'text', default: 'In, hold, out, hold.' },
      art: { label: 'Illustration', kind: 'art', default: 'kit:box' },
      artSize: { label: 'Illustration size', kind: 'number', options: [48, 56, 64, 72, 80], unit: ' pt', default: 64, global: true },
      artRadius: { label: 'Illustration corner radius', kind: 'number', options: [12, 14, 18, 20, 24], unit: ' pt', default: 18, global: true },
      chevron: { label: 'Chevron', kind: 'bool', labels: ['Show', 'Hide'], default: true, global: true },
      fill: { label: 'Tile colour', kind: 'select', default: 'cream', global: true, options: [['cream', 'Cream (dark: deep violet)'], ['raised', 'Raised (white)'], ['surface', 'Reading surface'], ['onColour', 'Card on colour']] },
      radius: { label: 'Corner radius', kind: 'number', options: [18, 20, 22, 24, 28], unit: ' pt', default: 22, global: true },
      gap: { label: 'Gap after the illustration', kind: 'number', options: [10, 12, 14, 16, 20], unit: ' pt', default: 14, global: true },
    },
    examples: [{ label: 'Box breathing on periwinkle', ground: 'periwinkle', props: {} }],
    render(p, ctx) {
      const r = Lab.ground('reading', ctx.dark);
      const bg = p.fill === 'cream' ? (ctx.dark ? '#221A52' : '#FFF8EE') : p.fill === 'onColour' ? ctx.g.card : Lab.c(Lab.fill[p.fill] || Lab.fill.raised, ctx.dark);
      const art = p.art && p.art !== 'none' ? `<div style="flex:none;width:${p.artSize}px;height:${p.artSize}px;line-height:0">${Lab.art(p.art, { width: p.artSize, height: p.artSize, radius: p.artRadius })}</div>` : '';
      return `<div role="button" style="display:flex;align-items:center;gap:${p.gap}px;padding:8px 16px 8px 8px;border-radius:${p.radius}px;background:${bg}">
        ${art}<div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:2px">
          <div style="${F('body', { size: 16, weight: 700 })}color:${r.ink}">${esc(p.title)}</div>
          <div style="${F('footnote')}color:${r.muted}">${esc(p.detail)}</div></div>
        ${p.chevron ? glyph('chevron.right', 13, r.ink) : ''}</div>`;
    },
  });

  E({
    type: 'calmHelpLine', name: 'Help line', group: 'Calm', source: SRC,
    description: 'HelpLine: the plain line pointing to professional help. Compact (12 pt, muted, bold underlined link) on the calm tools list; in full (dashed box) where a lesson needs it.',
    props: {
      style: { label: 'Style', kind: 'select', default: 'compact', options: [['compact', 'Compact line'], ['full', 'Full, in a dashed box']] },
      text: { label: 'Words', kind: 'text', default: 'Feeling like too much? In a crisis, call your local emergency number.' },
      link: { label: 'Link words', kind: 'text', default: 'Find a helpline' },
      tone: { label: 'Colour', kind: 'colour', default: 'muted' },
    },
    examples: [
      { label: 'Compact on periwinkle', ground: 'periwinkle', props: {} },
      { label: 'Full on reading', ground: 'reading', props: { style: 'full', text: 'If stress or anxiety is getting in the way of everyday life, talk to a doctor or a mental health professional. In a crisis, call your local emergency number.', link: 'Find a helpline near you' } },
    ],
    render(p, ctx) {
      if (p.style === 'full') {
        const r = R4(ctx);
        return `<div style="display:flex;flex-direction:column;gap:6px;padding:12px;border-radius:18px;border:1px dashed ${r.faint}">
          <div style="${F('footnote')}color:${r.muted}">${esc(p.text)}</div>
          <div role="link" style="${F('footnote', { size: 14, weight: 400 })}color:${r.accent};text-decoration:underline">${esc(p.link)}</div></div>`;
      }
      return `<div role="link" style="${F('caption', { size: 12, weight: 400, lh: 1.35 })}color:${Lab.colour(p.tone, ctx)}">${esc(p.text)} <b style="font-weight:700;text-decoration:underline">${esc(p.link)}</b></div>`;
    },
  });

  E({
    type: 'calmCloseButton', name: 'Close button (top left)', group: 'Calm', source: SRC,
    description: 'The 44 pt round close button (.v4Icon) floating at the top left, 16 pt in and 12 pt below the status bar.',
    props: {
      icon: { label: 'Icon', kind: 'icon', default: 'xmark' },
      label: { label: 'Spoken label', kind: 'text', default: 'Close' },
      size: { label: 'Size', kind: 'number', options: [36, 40, 44, 48], unit: ' pt', default: 44 },
      fill: { label: 'Fill', kind: 'select', default: 'surface', options: [['surface', 'Reading surface'], ['raised', 'Raised (white)'], ['onColour', 'Card on colour']] },
    },
    render(p, ctx) {
      const top = ctx.screenId === '_lib' ? 'position:relative;' : `position:absolute;z-index:4;left:16px;top:${(ctx.device ? ctx.device.top : 62) + 12}px;`;
      const ink = Lab.ground('reading', ctx.dark).ink;
      const bg = p.fill === 'onColour' ? ctx.g.card : Lab.c(Lab.fill[p.fill], ctx.dark);
      return `<div role="button" aria-label="${esc(p.label)}" style="${top}width:${p.size}px;height:${p.size}px;border-radius:50%;background:${bg};display:flex;align-items:center;justify-content:center">${Lab.icon(p.icon, 16, ink)}</div>`;
    },
  });

  /* ---------- Player frame ---------- */
  E({
    type: 'calmPlayer', name: 'Calm tool canvas', group: 'Calm', source: SRC + ' (CalmToolPlayer, PlayerCanvas)',
    description: 'The full-screen player: 16 pt sides, 8 pt above the home indicator. Breathing tools sit on the orb\'s black canvas in dark mode; the rest on the reading ground.',
    props: {
      canvas: { label: 'Canvas', kind: 'select', default: 'reading', options: [['reading', 'Reading ground'], ['orb', 'Black (orb), always dark']] },
      padX: { label: 'Side padding', kind: 'number', options: [12, 16, 20, 24], unit: ' pt', default: 16 },
      padBottom: { label: 'Bottom padding', kind: 'number', options: [0, 8, 12, 16, 20], unit: ' pt', default: 8 },
    },
    render(p, ctx, kids) {
      const orb = p.canvas === 'orb';
      const d = ctx.screenId !== '_lib' && ctx.device ? ctx.device : null;
      const bg = orb ? '#000000' : Lab.ground('reading', ctx.dark).bg;
      const top = d ? d.top : 0, bottom = d ? d.bottom : 0;
      const pull = d ? `margin-bottom:-${d.bottom + 12}px;` : '';
      return `<div style="flex:1;min-height:${d ? 0 : 240}px;display:flex;flex-direction:column;background:${bg};padding:${top}px ${p.padX}px ${bottom + p.padBottom}px;${pull}">${kids(orb ? { groundName: 'reading', dark: true } : { groundName: 'reading' })}</div>`;
    },
  });

  E({
    type: 'calmPanel', name: 'Calm tool body', group: 'Calm', source: SRC + ' (CalmToolPlayer)',
    description: 'The tool\'s body under the top bar: a column that fills the screen, so the button sits at the bottom.',
    props: {
      gap: { label: 'Gap between items', kind: 'number', options: [6, 8, 10, 12, 16, 20, 24], unit: ' pt', default: 12 },
      align: { label: 'Align', kind: 'select', default: 'stretch', options: [['stretch', 'Left (full width)'], ['center', 'Centre']] },
      padTop: { label: 'Top padding', kind: 'number', options: [0, 8, 12, 16, 20, 24, 32], unit: ' pt', default: 0 },
    },
    render(p, ctx, kids) {
      return `<div style="flex:1;display:flex;flex-direction:column;gap:${p.gap}px;align-items:${p.align};padding-top:${p.padTop}px;${p.align === 'center' ? 'text-align:center;' : ''}">${kids()}</div>`;
    },
  });

  E({
    type: 'calmTopBar', name: 'Calm tool top bar', group: 'Calm', source: SRC + ' (CalmToolPlayer.topBar)',
    description: 'Step capsules (4 pt, ink up to this step) over a row: the 44 pt Stop button, the tool\'s name in small capitals, and a 44 pt space.',
    props: {
      title: { label: 'Tool name', kind: 'text', default: '5-4-3-2-1' },
      steps: { label: 'Step capsules', kind: 'select', default: 0, options: [[0, 'None (breathing tools)'], [3, 'Three'], [5, 'Five']] },
      step: { label: 'This step', kind: 'select', default: 0, options: [[0, 'First'], [1, 'Second'], [2, 'Third'], [3, 'Fourth'], [4, 'Fifth']] },
      icon: { label: 'Stop icon', kind: 'icon', default: 'xmark' },
    },
    examples: [{ label: 'Grounding, step 2 of 5', ground: 'reading', props: { steps: 5, step: 1 } }],
    render(p, ctx) {
      const r = R4(ctx);
      const caps = p.steps ? `<div style="display:flex;gap:4px">${Array.from({ length: p.steps }, (_, i) => `<div style="flex:1;height:4px;border-radius:2px;background:${i <= p.step ? r.ink : r.track}"></div>`).join('')}</div>` : '';
      return `<div style="display:flex;flex-direction:column;gap:12px;padding-top:12px">${caps}
        <div style="display:flex;align-items:center;justify-content:space-between;gap:8px">
          <div role="button" aria-label="Stop" style="width:44px;height:44px;border-radius:50%;background:${r.surface};display:flex;align-items:center;justify-content:center;flex:none">${Lab.icon(p.icon, 16, r.ink)}</div>
          ${T('caption', p.title, readCtx(ctx), { tone: 'muted', align: 'center', style: 'flex:1;min-width:0' })}
          <div style="width:44px;flex:none"></div></div></div>`;
    },
  });

  /* ---------- Breathing tools: the Bio-Orb (BioOrbView, breathing_orb_data.json) ---------- */
  const PLASMA = [
    { hex: '#43511C', opacity: 0.75, width: 24, glow: '#BCC388', blur: 18, amp: 5.5, f1: 3, f2: 5, speed: 1.1, mult: 1.03 },
    { hex: '#BCC388', opacity: 0.65, width: 12, glow: '#BCC388', blur: 12, amp: 4.2, f1: 4, f2: 7, speed: -1.5, mult: 1.0 },
    { hex: '#BCC388', opacity: 0.9, width: 5.5, glow: '#BCC388', blur: 6, amp: 3.2, f1: 5, f2: 9, speed: 2.2, mult: 0.985 },
    { hex: '#FFFFFF', opacity: 0.92, width: 2.6, glow: '#FFFFFF', blur: 3, amp: 2.4, f1: 6, f2: 11, speed: -2.6, mult: 0.975 },
  ];
  const SAGE = '#BCC388', MOSS = '#43511C';
  let orbSeq = 0;
  function orbSVG(side, scale) {
    const id = 'calmorb' + (orbSeq++);
    const W = side + 120, c = W / 2;
    const R = side * 0.3432 * scale, E0 = 0.3, T0 = 0;
    const haloOuter = R * 1.25, inner = (R * 0.4) / haloOuter;
    const at = (s) => (inner + s * (1 - inner)).toFixed(3);
    const lens = R * 0.8 * 1.06;
    const rings = PLASMA.map((l, idx) => {
      const mod = (Math.sin(T0 * 11 + idx) * 0.5 + 0.5) * E0;
      const pts = [];
      for (let i = 0; i <= 120; i++) {
        const th = (i / 120) * 2 * Math.PI;
        const r = R * l.mult + Math.sin(th * l.f1 + T0 * l.speed) * l.amp * (0.4 + mod) + Math.cos(th * l.f2 - T0 * l.speed * 1.3) * (l.amp * 0.6) * mod + Math.sin(th * 2 + T0 * 0.7) * 2;
        pts.push(`${(c + Math.cos(th) * r).toFixed(1)},${(c + Math.sin(th) * r).toFixed(1)}`);
      }
      return `<path d="M${pts.join('L')}Z" fill="none" stroke="${l.hex}" stroke-opacity="${l.opacity}" stroke-width="${(l.width * (1 + E0 * 0.22)).toFixed(2)}" stroke-linejoin="round" style="mix-blend-mode:screen;filter:drop-shadow(0 0 ${l.blur}px ${l.glow})"/>`;
    }).join('');
    return `<svg width="${W}" height="${W}" viewBox="0 0 ${W} ${W}" style="position:absolute;left:-60px;top:-60px;overflow:visible" aria-hidden="true">
      <defs><radialGradient id="${id}h" gradientUnits="userSpaceOnUse" cx="${c}" cy="${c}" r="${haloOuter.toFixed(1)}">
        <stop offset="0" stop-color="${MOSS}" stop-opacity="0.42"/><stop offset="${at(0)}" stop-color="${MOSS}" stop-opacity="0.42"/><stop offset="${at(0.7)}" stop-color="${SAGE}" stop-opacity="0.18"/><stop offset="1" stop-color="${SAGE}" stop-opacity="0"/></radialGradient>
      <radialGradient id="${id}l" gradientUnits="userSpaceOnUse" cx="${c}" cy="${c}" r="${lens.toFixed(1)}">
        <stop offset="0" stop-color="#10160A"/><stop offset="0.55" stop-color="#070A04"/><stop offset="0.9" stop-color="#040602"/><stop offset="1" stop-color="#040602" stop-opacity="0"/></radialGradient></defs>
      <circle cx="${c}" cy="${c}" r="${haloOuter.toFixed(1)}" fill="url(#${id}h)"/>${rings}
      <circle cx="${c}" cy="${c}" r="${lens.toFixed(1)}" fill="url(#${id}l)"/></svg>`;
  }

  E({
    type: 'calmBioOrb', name: 'Bio-Orb', group: 'Calm', source: BIO,
    description: 'The breathing orb on black: moss halo, four plasma rings and a dark lens, with the readout (seconds and phase, the count, the cycle and four bars) in the middle. 320 pt.',
    props: {
      label: { label: 'Phase line', kind: 'text', default: '4 seconds · inhale' },
      numeral: { label: 'Count', kind: 'text', default: '4' },
      cycle: { label: 'Cycle line', kind: 'text', default: 'CYCLE 1 OF 4' },
      scale: { label: 'Breath size', kind: 'select', default: 0.9, options: [[0.82, 'Out (0.82)'], [0.86, 'Finished (0.86)'], [0.9, 'Start (0.9)'], [1, 'Middle (1.0)'], [1.12, 'In (1.12)'], [1.14, 'Hold (1.14)'], [1.15, 'Hold, 4-7-8 (1.15)']] },
      side: { label: 'Size', kind: 'number', options: [180, 240, 280, 320], unit: ' pt', default: 320 },
      bars: { label: 'Bars', kind: 'bool', labels: ['Show', 'Hide'], default: true },
    },
    examples: [{ label: 'Ready', ground: 'reading', props: { side: 240 } }],
    render(p) {
      const side = +p.side, k = side / 320;
      const bars = [0, 1, 2, 3].map((b) => {
        const h = 3 + 9 * 0.36 * (0.35 + 0.65 * Math.abs(Math.sin(b * 1.3)));
        return `<span style="display:block;width:2.5px;height:${h.toFixed(1)}px;border-radius:2px;background:${b % 2 ? '#FFFFFF' : SAGE}"></span>`;
      }).join('');
      // Readout sizes from breathing_orb_data.json (readout.full). The cycle line is 10 pt in the app; 12 pt here (lab floor).
      return `<div role="img" aria-label="Breathing guide" style="position:relative;width:${side}px;height:${side}px;flex:none;align-self:center">${orbSVG(side, +p.scale)}
        <div style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center"><div style="display:flex;flex-direction:column;align-items:center;transform:scale(${Math.min(1, k)})">
          <div style="height:14px;display:flex;align-items:center;${F('body', { size: 12, weight: 500, lh: 1 })}color:${SAGE};opacity:.85;white-space:nowrap">${esc(p.label)}</div>
          <div style="height:34px;margin:8px 0;display:flex;align-items:center;${F('display', { size: 48, weight: 800, lh: 1, family: 'display' })}letter-spacing:-0.96px;color:#FFFFFF;font-variant-numeric:tabular-nums">${esc(p.numeral)}</div>
          <div style="height:14px;display:flex;align-items:center;gap:6px"><span style="${F('body', { size: 12, weight: 600, lh: 1 })}letter-spacing:0.6px;color:rgba(255,255,255,.4);white-space:nowrap;font-variant-numeric:tabular-nums">${esc(p.cycle)}</span>${p.bars ? `<span style="display:flex;align-items:center;gap:2px;height:12px">${bars}</span>` : ''}</div>
        </div></div></div>`;
    },
  });

  E({
    type: 'calmOrbCaption', name: 'Orb caption', group: 'Calm', source: BIO + ' (OrbCaption)',
    description: 'What the coach says, as a quiet 16 pt caption on the black, with room for two lines.',
    props: { text: { label: 'Words', kind: 'text', default: 'Inhale slowly through your nose... watch the sage ring expand.' } },
    examples: [{ label: 'On black', ground: 'violet', props: {} }],
    render(p) {
      return `<div style="align-self:stretch;min-height:48px;${F('body', { size: 16, weight: 600, lh: 1.39 })}color:rgba(255,255,255,.6);text-align:center">${esc(p.text)}</div>`;
    },
  });

  E({
    type: 'calmOrbButton', name: 'Orb button', group: 'Calm', source: ORB + ' (OrbPanelButtonStyle)',
    description: 'A capsule under the orb: porcelain (white, black words) for the main action, moss (sage words) for the second. 14 pt bold with a 12 pt icon.',
    props: {
      label: { label: 'Words', kind: 'text', default: 'Start' },
      icon: { label: 'Icon', kind: 'select', default: 'play.fill', options: ICON_OPTS },
      kind: { label: 'Kind', kind: 'select', default: 'porcelain', options: [['porcelain', 'Porcelain (main)'], ['moss', 'Moss (second)']] },
    },
    examples: [{ label: 'Start', ground: 'violet', props: {} }, { label: 'Coach me', ground: 'violet', props: { label: 'Coach me', icon: 'waveform', kind: 'moss' } }],
    render(p) {
      const fg = p.kind === 'moss' ? SAGE : '#000000', bg = p.kind === 'moss' ? MOSS : '#FFFFFF';
      return `<div role="button" style="display:inline-flex;align-items:center;gap:8px;padding:14px 20px;border-radius:999px;background:${bg};${F('footnote', { size: 14, weight: 700 })}color:${fg};white-space:nowrap">${p.icon ? glyph(p.icon, 12, fg) : ''}<span>${esc(p.label)}</span></div>`;
    },
  });

  /* ---------- Grounding, Notice and name, Drop anchor ---------- */
  E({
    type: 'calmCount', name: 'Big count', group: 'Calm', source: SRC + ' (grounding)',
    description: 'The 5-4-3-2-1 step number: 40 pt bold, green.',
    props: {
      value: { label: 'Number', kind: 'text', default: '5' },
      colour: { label: 'Colour', kind: 'select', default: 'accent', options: [['accent', 'Green (accent)'], ['ink', 'Ink']] },
      size: { label: 'Size', kind: 'number', options: [32, 40, 48, 56], unit: ' pt', default: 40 },
    },
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="${F('display', { size: +p.size, weight: 700, family: 'display', lh: 1.1 })}color:${p.colour === 'ink' ? r.ink : r.accent}">${esc(p.value)}</div>`;
    },
  });

  E({
    type: 'calmFoundRow', name: 'Found circles', group: 'Calm', source: SRC + ' (grounding)',
    description: 'One 44 pt circle per thing to find. Tapped ones fill green with a cream tick; the rest are faint rings.',
    props: {
      count: { label: 'Circles', kind: 'select', default: 5, options: [[1, '1'], [2, '2'], [3, '3'], [4, '4'], [5, '5']] },
      found: { label: 'Found so far', kind: 'select', default: 0, options: [[0, 'None'], [1, '1'], [2, '2'], [3, '3'], [4, '4'], [5, '5']] },
      size: { label: 'Circle size', kind: 'number', options: [36, 40, 44, 48, 52], unit: ' pt', default: 44, global: true },
    },
    examples: [{ label: 'Two of five', ground: 'reading', props: { found: 2 } }],
    render(p, ctx) {
      const r = R4(ctx);
      const dots = Array.from({ length: +p.count }, (_, i) => {
        const on = i < p.found;
        return `<div role="button" aria-label="Found ${i + 1}" style="width:${p.size}px;height:${p.size}px;border-radius:50%;display:flex;align-items:center;justify-content:center;${on ? `background:${r.accent}` : `box-shadow:inset 0 0 0 1.5px ${r.faint}`}">${on ? Lab.icon('checkmark', 15, Lab.CREAM) : ''}</div>`;
      }).join('');
      return `<div style="display:flex;flex-wrap:wrap;gap:8px;padding-top:8px">${dots}</div>`;
    },
  });

  E({
    type: 'calmToggleChip', name: 'Thought chip', group: 'Calm', source: V4 + ' (V4ToggleChip)',
    description: '44 pt chip, radius 14, 16 pt words. Ink fill and bold when picked.',
    props: {
      label: { label: 'Words', kind: 'text', default: 'I need one' },
      on: { label: 'State', kind: 'select', default: false, options: [[false, 'Not picked'], [true, 'Picked']] },
    },
    examples: [{ label: 'Picked', ground: 'reading', props: { on: true } }, { label: 'Not picked', ground: 'reading', props: { label: "I can't cope" } }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div role="button" style="${F('body', { size: 16, weight: p.on ? 700 : 600 })}min-height:44px;padding:0 14px;display:inline-flex;align-items:center;border-radius:14px;background:${p.on ? r.ink : r.surface};color:${p.on ? r.bg : r.ink}">${esc(p.label)}</div>`;
    },
  });

  E({
    type: 'calmField', name: 'Labelled field', group: 'Calm', source: V4 + ' (V4TextField)',
    description: 'A small-capitals label over a 48 pt field, radius 14, on the reading surface.',
    props: {
      label: { label: 'Label', kind: 'text', default: 'The thought' },
      prompt: { label: 'Placeholder', kind: 'text', default: "I'll never manage" },
      value: { label: 'Typed', kind: 'text', default: '' },
    },
    examples: [{ label: 'Empty', ground: 'reading', props: {} }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="display:flex;flex-direction:column;gap:6px">${T('caption', p.label, readCtx(ctx), { tone: 'muted' })}
        <div style="min-height:48px;padding:0 14px;display:flex;align-items:center;border-radius:14px;background:${r.surface};${F('body')}color:${p.value ? r.ink : r.muted}">${esc(p.value || p.prompt)}</div></div>`;
    },
  });

  E({
    type: 'calmSayCard', name: 'Say it this way card', group: 'Calm', source: SRC + ' (notice and name)',
    description: 'A raised card, radius 26 with a hairline: a small-capitals kicker over the thought said as "I\'m noticing I\'m having the thought", the thought in green.',
    props: {
      kicker: { label: 'Kicker', kind: 'text', default: 'Say it this way' },
      lead: { label: 'Words before the thought', kind: 'text', default: "I'm noticing I'm having the thought" },
      thought: { label: 'The thought', kind: 'text', default: 'I need one' },
      radius: { label: 'Corner radius', kind: 'number', options: [18, 22, 24, 26, 28], unit: ' pt', default: 26 },
    },
    examples: [{ label: 'I need one', ground: 'reading', props: {} }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="display:flex;flex-direction:column;gap:6px;padding:16px;border-radius:${p.radius}px;background:${r.card};box-shadow:inset 0 0 0 1px ${r.hairline}">
        ${T('caption', p.kicker, readCtx(ctx), { tone: 'muted' })}
        <div style="${F('title', { size: 24, weight: 600 })}color:${r.ink}">${esc(p.lead)} <span style="color:${r.accent}">“${esc(p.thought)}”</span></div></div>`;
    },
  });

  E({
    type: 'calmBreathCircle', name: 'Breaths circle', group: 'Calm', source: SRC + ' (timedBreaths)',
    description: 'A 180 pt soft green glow that grows and shrinks with the breath, "3 breaths" over it.',
    props: {
      label: { label: 'Words', kind: 'text', default: '3 breaths' },
      scale: { label: 'Breath size', kind: 'select', default: 0.86, options: [[0.7, 'Out (0.7)'], [0.86, 'Still (0.86, Reduce Motion)'], [1, 'In (1.0)']] },
      size: { label: 'Size', kind: 'number', options: [140, 160, 180, 200], unit: ' pt', default: 180 },
    },
    examples: [{ label: 'Still', ground: 'reading', props: {} }],
    render(p, ctx) {
      const r = R4(ctx), s = +p.size;
      return `<div style="position:relative;width:${s}px;height:${s}px;flex:none;align-self:center">
        <div style="position:absolute;inset:0;border-radius:50%;transform:scale(${p.scale});background:radial-gradient(circle closest-side, rgba(${r.accentRGB},.6) 0%, rgba(${r.accentRGB},.2) 50%, rgba(${r.accentRGB},0) 100%)"></div>
        <div style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center;${F('headline', { size: 19, weight: 600 })}color:${r.ink}">${esc(p.label)}</div></div>`;
    },
  });

  E({
    type: 'calmIconDisc', name: 'Icon in a soft circle', group: 'Calm', source: SRC + ' (drop anchor, done)',
    description: 'A green symbol in a soft green circle: the standing figure (70 pt) on Drop anchor, the tick (76 pt) when a tool is done.',
    props: {
      icon: { label: 'Icon', kind: 'select', default: 'figure.stand', options: ICON_OPTS.slice(1) },
      size: { label: 'Circle size', kind: 'number', options: [56, 64, 70, 76, 88], unit: ' pt', default: 70 },
      glyph: { label: 'Icon size', kind: 'number', options: [24, 28, 30, 34], unit: ' pt', default: 30 },
    },
    examples: [{ label: 'Figure', ground: 'reading', props: {} }, { label: 'Tick', ground: 'reading', props: { icon: 'checkmark', size: 76 } }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div aria-hidden="true" style="width:${p.size}px;height:${p.size}px;border-radius:50%;background:${r.accentSoft};display:flex;align-items:center;justify-content:center;flex:none">${glyph(p.icon, p.glyph, r.accent)}</div>`;
    },
  });

  /* ---------- Done ---------- */
  E({
    type: 'calmOptionalLine', name: 'Question with a faint aside', group: 'Calm', source: SRC + ' (done)',
    description: '"A bit calmer?" in muted footnote, with "· optional" in the faint colour.',
    props: {
      text: { label: 'Question', kind: 'text', default: 'A bit calmer?' },
      aside: { label: 'Aside', kind: 'text', default: '· optional' },
    },
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="${F('footnote')}color:${r.muted};text-align:center">${esc(p.text)}${p.aside ? ` <span style="color:${r.faint}">${esc(p.aside)}</span>` : ''}</div>`;
    },
  });

  E({
    type: 'calmChoiceButton', name: 'Calmer answer', group: 'Calm', source: SRC + ' (calmerButton)',
    description: '52 pt raised button, radius 20, 16 pt words; a green outline when picked, a hairline when not.',
    props: {
      label: { label: 'Words', kind: 'text', default: 'A bit' },
      on: { label: 'State', kind: 'select', default: false, options: [[false, 'Not picked'], [true, 'Picked']] },
    },
    examples: [{ label: 'Picked', ground: 'reading', props: { on: true } }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div role="button" style="flex:1;min-width:0;min-height:52px;display:flex;align-items:center;justify-content:center;border-radius:20px;background:${r.card};box-shadow:inset 0 0 0 ${p.on ? 1.5 : 1}px ${p.on ? r.accent : r.hairline};${F('body', { size: 16, weight: 600 })}color:${r.ink}">${esc(p.label)}</div>`;
    },
  });

  /* ---------- Data (CalmTools.swift, breathing_orb_data.json) ---------- */
  const TOOLS = [
    { key: 'boxBreathing', title: 'Box breathing', detail: 'In, hold, out, hold.', art: 'kit:box' },
    { key: 'longerOutBreath', title: 'Longer out-breath', detail: 'In 4, hold 7, out 8.', art: 'kit:outbreath' },
    { key: 'grounding', title: '5-4-3-2-1', detail: 'Use your five senses.', art: 'kit:grounding' },
    { key: 'noticeAndName', title: 'Notice and name', detail: 'Label the thought. Let it be.', art: 'kit:tag' },
    { key: 'dropAnchor', title: 'Drop anchor', detail: 'Feet down. Come back to the room.', art: 'kit:anchor' },
  ];
  const GROUNDING = [
    { count: 5, sense: 'things you can see', hint: 'Look around slowly. Colours, shapes, light.' },
    { count: 4, sense: 'things you can feel', hint: 'Your feet on the floor, the chair, your clothes, the air.' },
    { count: 3, sense: 'things you can hear', hint: 'Near and far. Traffic, voices, your own breathing.' },
    { count: 2, sense: 'things you can smell', hint: "Or two smells you like, if nothing's around." },
    { count: 1, sense: 'thing you can taste', hint: "A sip of water, or just what's in your mouth now." },
  ];
  const THOUGHTS = ['I need one', "I can't cope", 'Just one won\'t hurt', 'I deserve it', 'This will never get easier'];
  const ANCHOR = [
    { title: "Notice what's here", body: "Notice the thoughts and feelings that are here right now. You don't have to change them." },
    { title: 'Feel your body', body: 'Push your feet into the floor. Straighten your back. Feel your hands, your shoulders, your breath.' },
    { title: 'Come back to the room', body: "Look around. Notice where you are and what you're doing. Then carry on with it." },
  ];
  const SCRIPTS = {
    inhale: ['Inhale slowly through your nose... watch the sage ring expand.', 'Draw clean air deep into your lower ribs... let the wave rise.', 'Breathe in slowly... let your shoulders drop.'],
    hold: ['Hold gently at the crest... notice the sensation without fighting it.', 'Pause in stillness... a craving is a wave, and waves pass.', 'Suspend the breath... your streak and progress are completely safe.'],
    exhale: ['Exhale softly... release the tension from your jaw and shoulders.', 'Let the urge dissolve into the dark moss core... you are in control.', 'Breathe out slowly... longer than you breathed in.'],
    rest: ['Rest at zero... steady and calm, zero guilt.', 'Notice the calm between waves... you rode it out.'],
  };
  const PATTERNS = {
    box: { name: 'Box breathing', counts: '4·4·4·4', phases: [['inhale', 4], ['hold', 4], ['exhale', 4], ['rest', 4]], cycles: 4, holdScale: 1.14 },
    478: { name: 'Deep calm', counts: '4·7·8', phases: [['inhale', 4], ['hold', 7], ['exhale', 8]], cycles: 4, holdScale: 1.15 },
  };

  /* ---------- Screen: the list ---------- */
  Lab.screen({
    id: 'calm', name: 'Calm tools', area: 'Calm', source: SRC, ground: 'periwinkle',
    note: 'Opened full screen (no tab bar) from Today\'s wind-down top card and from Craving SOS ("Still strong"). Tapping a tile opens that tool full screen; see the other Calm screens. Each tile reads its tool\'s length to VoiceOver (1 min; 5-4-3-2-1 is 2 min) but shows no length.',
    states: [{ id: 'list', label: 'List' }],
    build(h) {
      return h('stack', 'body', { padX: 16, gap: 8, padBottom: 20 }, [
        h('stack', 'header', { padTop: 8, align: 'center' }, [
          h('art', 'header-art', { art: 'scene:calmHeader', width: 240, height: 196, radius: 0 }),
        ]),
        h('stack', 'title-wrap', { padX: 6 }, [
          h('markedTitle', 'title', { lead: '', word: 'Calm', trail: ' tools', mark: 'circle', step: 'large' }),
        ]),
        h('stack', 'intro-wrap', { padBottom: 8 }, [
          h('text', 'intro', { step: 'body', tone: 'muted', text: 'Short things to do instead of reaching for nicotine.' }),
        ]),
        ...TOOLS.map((t) => h('calmToolRow', 'tool-' + t.key, { title: t.title, detail: t.detail, art: t.art })),
        h('stack', 'help-wrap', { padTop: 12 }, [h('calmHelpLine', 'help', {})]),
      ]);
    },
    overlay(h) { return h('calmCloseButton', 'close', {}); },
  });

  /* ---------- Shared player pieces ---------- */
  const DONE_STATES = [{ id: 'done', label: 'Done · Nicely done' }, { id: 'done-not', label: 'Done · "Not really" picked' }];

  function doneView(h, state) {
    const not = state.id === 'done-not';
    return h('calmPlayer', 'player', { canvas: 'reading' }, [
      h('calmPanel', 'done', { align: 'center' }, [
        h('spacer', 'done-top', { flex: true, size: 0 }),
        h('calmIconDisc', 'done-tick', { icon: 'checkmark', size: 76, glyph: 30 }),
        h('text', 'done-title', { step: 'title', text: 'Nicely done', align: 'center' }),
        h('calmOptionalLine', 'done-ask', {}),
        h('row', 'done-choices', { gap: 8, style: 'align-self:stretch' }, [
          h('calmChoiceButton', 'done-abit', { label: 'A bit', on: false }),
          h('calmChoiceButton', 'done-notreally', { label: 'Not really', on: not }),
        ]),
        not ? h('text', 'done-okay', { step: 'footnote', tone: 'muted', align: 'center', text: "That's okay. Try another tool, or ride it out with Craving SOS." }) : null,
        h('spacer', 'done-bottom', { flex: true, size: 0 }),
        h('stack', 'done-buttons', { gap: 12, style: 'align-self:stretch' }, [
          h('button', 'done-button', { label: 'Done' }),
          h('button', 'done-sos', { label: 'Still craving? Start Craving SOS', kind: 'quiet', alts: { label: ['Back to Craving SOS'] } }),
        ]),
      ]),
    ]);
  }

  /* ---------- Screens: the breathing tools on the Bio-Orb ---------- */
  function orbScreen(id, tool, patternId, name) {
    const pat = PATTERNS[patternId];
    const phaseAlts = pat.phases.map(([w, s]) => `${s} seconds · ${w}`);
    const hold = pat.phases[1];
    Lab.screen({
      id, name, area: 'Calm', source: SRC + ', ' + ORB, ground: 'reading', fullBleed: true,
      note: `${tool.title} runs on the Bio-Orb with the "${patternId}" pattern (${pat.name}, ${pat.counts}, ${pat.cycles} cycles) on a black canvas that stays dark in light mode. "Running" shows second 2 of the hold in cycle 1 (an example moment). The orb's cycle line is 10 pt in the app; it is drawn at 12 pt here. The orb is drawn still.`,
      states: [
        { id: 'ready', label: 'Ready · Start' },
        { id: 'running', label: 'Running · hold, cycle 1' },
        { id: 'paused', label: 'Paused' },
        { id: 'cycles', label: 'Cycles done · Continue' },
      ].concat(DONE_STATES),
      // The orb canvas is black in both appearances, so the status bar and home indicator are cream there.
      statusInk: (state) => (String(state.id).startsWith('done') ? undefined : Lab.CREAM),
      build(h, state) {
        const orb = !state.id.startsWith('done');
        if (!orb) return doneView(h, state);
        const s = state.id;
        const live = s === 'running' || s === 'paused';
        const fin = s === 'cycles';
        const label = fin ? 'done' : live ? `${hold[1]} seconds · hold` : `${pat.phases[0][1]} seconds · inhale`;
        const numeral = fin ? '✓' : live ? String(hold[1] - 2) : String(pat.phases[0][1]);
        const caption = fin ? `Nice work. You finished ${pat.cycles} cycles.` : live ? SCRIPTS.hold[1] : SCRIPTS.inhale[0];
        const primary = fin ? ['Continue', 'checkmark'] : s === 'ready' ? ['Start', 'play.fill'] : s === 'paused' ? ['Resume', 'play.fill'] : ['Pause', 'pause.fill'];
        const secondary = fin ? ['Again', 'arrow.counterclockwise'] : ['Coach me', 'waveform'];
        return h('calmPlayer', 'player', { canvas: 'orb' }, [
          h('calmTopBar', 'top-bar', { title: tool.title, steps: 0 }),
          h('stack', 'orb-panel', { gap: 24, align: 'center', padTop: 12, padBottom: 16, textAlign: 'center' }, [
            h('text', 'pattern', { step: 'caption', tone: 'muted', align: 'center', text: `${pat.name} · ${pat.counts}` }),
            h('calmBioOrb', 'orb', { label, numeral, cycle: `CYCLE ${fin ? pat.cycles : 1} OF ${pat.cycles}`, scale: fin ? 0.86 : live ? pat.holdScale : 0.9, alts: { label: phaseAlts.concat(['done']) } }),
            h('calmOrbCaption', 'caption', { text: caption, alts: { text: [].concat(SCRIPTS.inhale, SCRIPTS.hold, SCRIPTS.exhale, SCRIPTS.rest, [`Nice work. You finished ${pat.cycles} cycles.`]) } }),
            h('row', 'controls', { gap: 10, justify: 'center' }, [
              h('calmOrbButton', 'primary', { label: primary[0], icon: primary[1], kind: 'porcelain', alts: { label: ['Start', 'Pause', 'Resume', 'Continue'] } }),
              h('calmOrbButton', 'secondary', { label: secondary[0], icon: secondary[1], kind: 'moss', alts: { label: ['Coach me', 'Again'] } }),
            ]),
          ]),
        ]);
      },
    });
  }
  orbScreen('calm-box', TOOLS[0], 'box', 'Box breathing');
  orbScreen('calm-478', TOOLS[1], '478', 'Longer out-breath (4-7-8)');

  /* ---------- Screen: 5-4-3-2-1 grounding ---------- */
  const SENSE_IDS = ['see', 'feel', 'hear', 'smell', 'taste'];
  Lab.screen({
    id: 'calm-grounding', name: '5-4-3-2-1 grounding', area: 'Calm', source: SRC + ', ' + LOGIC, ground: 'reading', fullBleed: true,
    note: 'One sense per step. The circles fill as you tap them; "Found so far" on the circles shows that. The last step\'s button says Done.',
    states: GROUNDING.map((g, i) => ({ id: SENSE_IDS[i], label: `Step ${i + 1} · ${g.count} ${g.sense}` })).concat(DONE_STATES),
    build(h, state) {
      if (state.id.startsWith('done')) return doneView(h, state);
      const i = Math.max(0, SENSE_IDS.indexOf(state.id));
      const g = GROUNDING[i];
      const next = GROUNDING[i + 1];
      const nextLabels = GROUNDING.slice(1).map((n) => `Next: ${n.count} ${n.sense}`).concat(['Done']);
      return h('calmPlayer', 'player', { canvas: 'reading' }, [
        h('calmTopBar', 'top-bar', { title: '5-4-3-2-1', steps: 5, step: i }),
        h('calmPanel', 'body', { gap: 12 }, [
          h('stack', 'count-wrap', { padTop: 20 }, [h('calmCount', 'count', { value: String(g.count), alts: { value: GROUNDING.map((x) => String(x.count)) } })]),
          h('text', 'sense', { step: 'title', text: g.sense, alts: { text: GROUNDING.map((x) => x.sense) } }),
          h('text', 'hint', { step: 'footnote', tone: 'muted', text: g.hint, alts: { text: GROUNDING.map((x) => x.hint) } }),
          h('calmFoundRow', 'found', { count: g.count, found: 0 }),
          h('spacer', 'push', { flex: true, size: 0 }),
          h('button', 'next', { label: next ? `Next: ${next.count} ${next.sense}` : 'Done', alts: { label: nextLabels } }),
        ]),
      ]);
    },
  });

  /* ---------- Screen: Notice and name ---------- */
  Lab.screen({
    id: 'calm-notice', name: 'Notice and name', area: 'Calm', source: SRC + ', ' + LOGIC, ground: 'reading', fullBleed: true,
    note: 'Three steps: pick the thought, say it the noticing way, three slow breaths. "I need one" stands in for the picked thought. Next stays at half strength until a thought is picked or typed. The breaths circle grows and shrinks with the breath in the app; it is drawn still here.',
    states: [
      { id: 'pick', label: 'Step 1 · nothing picked' },
      { id: 'picked', label: 'Step 1 · "I need one" picked' },
      { id: 'own', label: 'Step 1 · write my own' },
      { id: 'say', label: 'Step 2 · say it this way' },
      { id: 'breaths', label: 'Step 3 · three breaths' },
    ].concat(DONE_STATES),
    build(h, state) {
      const s = state.id;
      if (s.startsWith('done')) return doneView(h, state);
      const step = s === 'say' ? 1 : s === 'breaths' ? 2 : 0;
      let body;
      if (step === 0) {
        const ready = s === 'picked';
        body = [
          h('stack', 'ask-wrap', { padTop: 20 }, [h('text', 'ask', { step: 'title', text: "What's your mind telling you?" })]),
          h('text', 'ask-sub', { step: 'footnote', tone: 'muted', text: 'Pick the closest, or write your own.' }),
          h('row', 'thoughts', { gap: 8, wrap: true }, THOUGHTS.map((t, i) => h('calmToggleChip', 'thought-' + (i + 1), { label: t, on: s === 'picked' && i === 0 }))
            .concat([h('calmToggleChip', 'thought-own', { label: 'write my own', on: s === 'own' })])),
          s === 'own' ? h('calmField', 'own-field', { label: 'The thought', prompt: "I'll never manage" }) : null,
          h('spacer', 'push', { flex: true, size: 0 }),
          h('button', 'next', { label: 'Next', disabled: !ready }),
        ];
      } else if (step === 1) {
        body = [
          h('stack', 'say-wrap', { padTop: 20 }, [h('calmSayCard', 'say', { thought: 'I need one', alts: { thought: THOUGHTS.slice(1) } })]),
          h('text', 'say-sub', { step: 'footnote', tone: 'muted', text: "It's a thought, not an order. You can let it sit there while you get on with your day." }),
          h('spacer', 'push', { flex: true, size: 0 }),
          h('button', 'next', { label: 'Next' }),
        ];
      } else {
        body = [
          h('spacer', 'push-top', { flex: true, size: 0 }),
          h('stack', 'breaths', { gap: 12, align: 'center' }, [
            h('calmBreathCircle', 'breath-circle', {}),
            h('text', 'breath-word', { step: 'footnote', tone: 'muted', align: 'center', text: 'Breathe in', alts: { text: ['Breathe out'] } }),
          ]),
          h('spacer', 'push', { flex: true, size: 0 }),
          h('button', 'next', { label: 'Done' }),
        ];
      }
      return h('calmPlayer', 'player', { canvas: 'reading' }, [
        h('calmTopBar', 'top-bar', { title: 'Notice and name', steps: 3, step }),
        h('calmPanel', 'body', { gap: 12 }, body),
      ]);
    },
  });

  /* ---------- Screen: Drop anchor ---------- */
  const ANCHOR_IDS = ['notice', 'body', 'room'];
  Lab.screen({
    id: 'calm-anchor', name: 'Drop anchor', area: 'Calm', source: SRC + ', ' + LOGIC, ground: 'reading', fullBleed: true,
    note: 'Three steps; the last button says Done.',
    states: ANCHOR.map((a, i) => ({ id: ANCHOR_IDS[i], label: `Step ${i + 1} · ${a.title}` })).concat(DONE_STATES),
    build(h, state) {
      if (state.id.startsWith('done')) return doneView(h, state);
      const i = Math.max(0, ANCHOR_IDS.indexOf(state.id));
      const a = ANCHOR[i];
      return h('calmPlayer', 'player', { canvas: 'reading' }, [
        h('calmTopBar', 'top-bar', { title: 'Drop anchor', steps: 3, step: i }),
        h('calmPanel', 'body', { gap: 12 }, [
          h('stack', 'figure-wrap', { padTop: 20 }, [h('calmIconDisc', 'figure', { icon: 'figure.stand', size: 70, glyph: 30 })]),
          h('text', 'step-title', { step: 'title', text: a.title, alts: { text: ANCHOR.map((x) => x.title) } }),
          h('text', 'step-body', { step: 'body', tone: 'muted', text: a.body, alts: { text: ANCHOR.map((x) => x.body) } }),
          h('spacer', 'push', { flex: true, size: 0 }),
          h('button', 'next', { label: i + 1 < ANCHOR.length ? 'Next' : 'Done', alts: { label: ['Next', 'Done'] } }),
        ]),
      ]);
    },
  });
})();
