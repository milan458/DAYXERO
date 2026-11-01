/* DayXero Screen Lab — Evening and daily: the Evening tab and Wind down (DayXero/Evening/EveningView.swift:
   EveningView, WindDownView, GlimBreathingView), the evening check-in (DayXero/Daily/CheckInView.swift: CheckInView,
   TomorrowPlan, DayEndSettings) and the morning pledge (DayXero/Daily/PledgeView.swift). See ../FORMAT.md.
   The Orb views (DayXero/Orb) are only opened from Calm tools and Program, so they live in calm.js. */
(function () {
  'use strict';
  const Lab = window.Lab;
  const E = Lab.element, esc = Lab.esc, T = Lab.text, F = Lab.font;
  const EVE = 'DayXero/Evening/EveningView.swift';
  const CHECK = 'DayXero/Daily/CheckInView.swift';
  const PLEDGE = 'DayXero/Daily/PledgeView.swift';
  const CREAM = Lab.CREAM, NAVY = Lab.NAVY;
  const VIOLET = '#4A3596';

  /** A hex colour at an opacity, as SwiftUI's `.opacity` on a colour. */
  function hexA(hex, a) {
    const n = parseInt(String(hex).replace('#', '').slice(0, 6), 16);
    return `rgba(${(n >> 16) & 255},${(n >> 8) & 255},${n & 255},${a})`;
  }
  const inLib = (ctx) => ctx.screenId === '_lib' || !ctx.device;

  /* SF Symbols this file needs that lab.js doesn't draw. */
  const GLYPHS = {
    drop: '<path d="M12 3.2c3.2 4.1 6 7.6 6 11a6 6 0 0 1-12 0c0-3.4 2.8-6.9 6-11z" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linejoin="round"/>',
    'square.and.pencil': '<path d="M11 5H6.5A2.5 2.5 0 0 0 4 7.5v10A2.5 2.5 0 0 0 6.5 20h10a2.5 2.5 0 0 0 2.5-2.5V13" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/><path d="M17.6 3.6a1.9 1.9 0 0 1 2.8 2.8L12.5 14.3l-3.6.8.8-3.6z" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>',
    minus: '<path d="M5 12h14" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round"/>',
    'checkmark.circle.fill': '<circle cx="12" cy="12" r="10" fill="currentColor"/><path d="M7.5 12.3l3 3 6-6.3" fill="none" stroke="#FFFFFF" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>',
    circle: '<circle cx="12" cy="12" r="9.2" fill="none" stroke="currentColor" stroke-width="1.6"/>',
  };
  function glyph(name, size, colour) {
    if (GLYPHS[name]) return `<svg viewBox="0 0 24 24" width="${size}" height="${size}" style="color:${colour};flex:none;display:block" aria-hidden="true">${GLYPHS[name]}</svg>`;
    return Lab.icon(name, size, colour);
  }

  /* ---------- Hero (HeroScene + crew member) ---------- */
  E({
    type: 'eveningHero', name: 'Hero sky with crew member', group: 'Evening', source: 'DayXeroCore/DesignSystem/Art/HorizonScene.swift (HeroScene), ' + EVE,
    description: 'HeroScene: the horizon with a paper edge in the screen colour, run edge to edge and up under the status bar, with the crew member standing 10 pt above its bottom. Check-in and pledge add a 44 pt cream close button (50 pt down, 10 pt in).',
    props: {
      scene: { label: 'Sky', kind: 'select', default: 'night', options: [['night', 'Night (evening, check-in)'], ['dawn', 'Dawn (pledge)'], ['dusk', 'Dusk'], ['path', 'Path'], ['sea', 'Sea']] },
      clarity: { label: 'Sky clarity', kind: 'number', options: [20, 23, 26, 28, 34, 40, 48, 60, 80, 100], default: 28 },
      height: { label: 'Height', kind: 'number', options: [200, 240, 250, 280, 300, 330], unit: ' pt', default: 240 },
      character: { label: 'Crew member', kind: 'art', default: 'glim:sleepy' },
      size: { label: 'Crew size', kind: 'number', options: [88, 140, 200], unit: ' pt', default: 140 },
      stage: { label: 'Crew stage', kind: 'select', default: 1, options: [[1, 'Stage 1 (under 7 days)'], [2, 'Stage 2 (7–13 days)'], [3, 'Stage 3 (14–27 days)'], [4, 'Stage 4 (28+ days)']] },
      lift: { label: 'Crew above the bottom', kind: 'number', options: [0, 10, 20, 40], unit: ' pt', default: 10 },
      close: { label: 'Close button', kind: 'bool', labels: ['Show', 'Hide'], default: false },
      bleed: { label: 'Runs past the side padding', kind: 'number', options: [0, 20], unit: ' pt', default: 20 },
    },
    examples: [{ label: 'Night, Glim', ground: 'violet', props: {} }, { label: 'Dawn, Xero, close', ground: 'apricot', props: { scene: 'dawn', clarity: 26, height: 330, character: 'xero:hello', size: 200, close: true } }],
    render(p, ctx) {
      const lib = inLib(ctx);
      const w = lib ? (ctx.width || 362) : (ctx.width || 402);
      const sky = Lab.art('extra:hero', { width: w, height: +p.height, radius: 0, scene: { kind: p.scene, clarity: +p.clarity, edge: ctx.g.bg } });
      const crew = p.character && p.character !== 'none'
        ? `<div style="position:absolute;left:0;right:0;bottom:${p.lift}px;display:flex;justify-content:center;line-height:0">${Lab.art(p.character, { size: +p.size, stage: +p.stage })}</div>` : '';
      const close = p.close
        ? `<div role="button" aria-label="Close" style="position:absolute;top:50px;right:10px;width:44px;height:44px;border-radius:50%;background:${hexA(CREAM, 0.85)};display:flex;align-items:center;justify-content:center">${Lab.icon('xmark', 16, NAVY)}</div>` : '';
      return `<div style="position:relative;height:${p.height}px;line-height:0;flex:none;${lib || !p.bleed ? '' : `margin:0 -${p.bleed}px;`}">${sky}${crew}${close}</div>`;
    },
  });

  /* ---------- Cards and rows on the violet ground ---------- */
  E({
    type: 'eveningCard', name: 'Card on colour', group: 'Evening', source: EVE + ', ' + CHECK + ', ' + PLEDGE,
    description: 'The card-on-colour fill (DX.Fill.onColourCard) the evening and pledge screens put cards on: radius 18 for Your reason and Water, 22 for the check-in and pledge cards.',
    props: {
      radius: { label: 'Corner radius', kind: 'number', options: [14, 18, 22, 24, 28], unit: ' pt', default: 18 },
      padX: { label: 'Side padding', kind: 'number', options: [0, 12, 14, 16, 18, 20], unit: ' pt', default: 14 },
      padY: { label: 'Top and bottom padding', kind: 'number', options: [0, 4, 8, 12, 14, 16, 18, 20], unit: ' pt', default: 14 },
      gap: { label: 'Gap between items', kind: 'number', options: [0, 2, 4, 6, 8, 10, 12, 14, 16], unit: ' pt', default: 4 },
      above: { label: 'Extra space above', kind: 'number', options: [0, 6, 8, 12], unit: ' pt', default: 0 },
      fill: { label: 'Fill', kind: 'select', default: 'onColour', options: [['onColour', 'Card on colour'], ['cream', 'Cream'], ['none', 'No fill']] },
    },
    examples: [{ label: 'Your reason', ground: 'violet', props: {}, kids: [['text', { step: 'caption', tone: 'muted', text: 'Your reason' }], ['text', { step: 'headline', text: 'To keep up with Maya at the park' }]] }],
    render(p, ctx, kids) {
      const bg = p.fill === 'cream' ? CREAM : p.fill === 'none' ? 'transparent' : ctx.g.card;
      return `<div style="align-self:stretch;display:flex;flex-direction:column;align-items:stretch;text-align:left;gap:${p.gap}px;padding:${p.padY}px ${p.padX}px;border-radius:${p.radius}px;background:${bg};${p.above ? `margin-top:${p.above}px;` : ''}">${kids()}</div>`;
    },
  });

  E({
    type: 'eveningTonightCard', name: 'For tonight card', group: 'Evening', source: EVE + ' (WindDownView.tonight)',
    description: 'Slow breathing with Glim: a cream card (radius 24, lip shadow, 16 pt padding) with a violet kicker, navy title and a 44 pt violet play circle. The same colours in dark mode.',
    props: {
      kicker: { label: 'Kicker', kind: 'text', default: 'For tonight · 3 min' },
      title: { label: 'Title', kind: 'text', default: 'Slow breathing with Glim' },
      detail: { label: 'Line', kind: 'text', default: 'In for 4, out for 6. The same rhythm as SOS.' },
      radius: { label: 'Corner radius', kind: 'number', options: [18, 22, 24, 28], unit: ' pt', default: 24 },
      lip: { label: 'Lip shadow', kind: 'bool', labels: ['On', 'Off'], default: true },
      button: { label: 'Play circle', kind: 'bool', labels: ['Show', 'Hide'], default: true },
    },
    examples: [{ label: 'On violet', ground: 'violet', props: {} }],
    render(p) {
      return `<div role="button" style="display:flex;align-items:center;gap:12px;padding:16px;border-radius:${p.radius}px;background:${CREAM};${p.lip ? 'box-shadow:0 5px 0 rgba(0,0,0,.14);' : ''}">
        <div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:4px">
          <div style="${F('caption')}color:${VIOLET};text-transform:uppercase">${esc(p.kicker)}</div>
          <div style="${F('headline')}color:${NAVY}">${esc(p.title)}</div>
          <div style="${F('footnote')}color:#3A2A7A">${esc(p.detail)}</div></div>
        ${p.button ? `<div style="width:44px;height:44px;border-radius:50%;background:${VIOLET};display:flex;align-items:center;justify-content:center;flex:none">${Lab.icon('play.fill', 16, CREAM)}</div>` : ''}</div>`;
    },
  });

  E({
    type: 'eveningToolList', name: 'Calm tools list', group: 'Evening', source: EVE + ' (WindDownView.tools)',
    description: 'The five calm tools as plain rows on one card-on-colour card (radius 18, 14 pt sides), a hairline between rows.',
    props: {
      radius: { label: 'Corner radius', kind: 'number', options: [14, 18, 22, 24], unit: ' pt', default: 18 },
      padX: { label: 'Side padding', kind: 'number', options: [12, 14, 16, 18, 20], unit: ' pt', default: 14 },
    },
    examples: [{ label: 'Two tools', ground: 'violet', props: {}, kids: [['eveningToolRow', { divider: false }], ['eveningToolRow', { title: '5-4-3-2-1', detail: 'Use your five senses.', minutes: '2 min' }]] }],
    render(p, ctx, kids) {
      return `<div style="display:flex;flex-direction:column;padding:0 ${p.padX}px;border-radius:${p.radius}px;background:${ctx.g.card}">${kids()}</div>`;
    },
  });

  E({
    type: 'eveningToolRow', name: 'Calm tool row', group: 'Evening', source: EVE + ' (WindDownView.tools), DayXeroCore/Logic/CalmTools.swift',
    description: 'A 16 pt bold title over a 14 pt detail, and the length in small muted words on the right. 12 pt above and below; a hairline (ink at 14%) above every row but the first.',
    props: {
      title: { label: 'Title', kind: 'text', default: 'Box breathing' },
      detail: { label: 'Detail', kind: 'text', default: 'In, hold, out, hold.' },
      minutes: { label: 'Length', kind: 'text', default: '1 min' },
      divider: { label: 'Hairline above', kind: 'bool', labels: ['Show', 'Hide'], default: true },
    },
    examples: [{ label: 'Box breathing', ground: 'violet', props: { divider: false } }],
    render(p, ctx) {
      return `<div role="button" style="display:flex;align-items:center;gap:10px;padding:12px 0;${p.divider ? `border-top:1px solid ${hexA(ctx.g.ink, 0.14)};` : ''}">
        <div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:2px">
          <div style="${F('body', { size: 16, weight: 700 })}color:${ctx.g.ink}">${esc(p.title)}</div>
          <div style="${F('footnote')}color:${ctx.g.muted}">${esc(p.detail)}</div></div>
        <div style="${F('caption')}color:${ctx.g.muted};white-space:nowrap">${esc(p.minutes)}</div></div>`;
    },
  });

  E({
    type: 'eveningWaterRow', name: 'Water row', group: 'Evening', source: EVE + ' (WindDownView.extras)',
    description: 'Opens the water tracker: a drop and "Water" in 16 pt bold, a chevron on the right, on a card-on-colour row (48 pt, radius 18).',
    props: {
      label: { label: 'Words', kind: 'text', default: 'Water' },
      icon: { label: 'Drop icon', kind: 'bool', labels: ['Show', 'Hide'], default: true },
      chevron: { label: 'Chevron', kind: 'bool', labels: ['Show', 'Hide'], default: true },
    },
    examples: [{ label: 'On violet', ground: 'violet', props: {} }],
    render(p, ctx) {
      return `<div role="button" style="display:flex;align-items:center;gap:8px;min-height:48px;padding:14px;border-radius:18px;background:${ctx.g.card}">
        ${p.icon ? glyph('drop', 18, ctx.g.ink) : ''}<div style="${F('body', { size: 16, weight: 700 })}color:${ctx.g.ink};flex:1;min-width:0">${esc(p.label)}</div>
        ${p.chevron ? Lab.icon('chevron.right', 13, ctx.g.muted) : ''}</div>`;
    },
  });

  E({
    type: 'eveningLinkLine', name: 'Line with a link', group: 'Evening', source: EVE + ' (helpLine), ' + CHECK + ' (day end)',
    description: 'A 14 pt muted line with underlined link words: the helpline line (link in ink) and "Your day ends at 4 AM · change" (link in the same colour, 44 pt tall, centred).',
    props: {
      lead: { label: 'Words before the link', kind: 'text', default: "These tools aren't a substitute for professional help. If things feel like too much, " },
      link: { label: 'Link words', kind: 'text', default: 'find a helpline near you' },
      trail: { label: 'Words after the link', kind: 'text', default: '.' },
      linkTone: { label: 'Link colour', kind: 'select', default: 'ink', options: [['ink', 'Ink'], ['muted', 'Same as the line']] },
      align: { label: 'Align', kind: 'select', default: 'left', options: [['left', 'Left'], ['center', 'Centre']] },
      minHeight: { label: 'Height', kind: 'number', options: [0, 44], unit: ' pt', default: 0 },
    },
    examples: [{ label: 'Helpline', ground: 'violet', props: {} }, { label: 'Day end', ground: 'violet', props: { lead: 'Your day ends at 4 AM · ', link: 'change', trail: '', linkTone: 'muted', align: 'center', minHeight: 44 } }],
    render(p, ctx) {
      const lc = p.linkTone === 'ink' ? ctx.g.ink : ctx.g.muted;
      const box = p.minHeight ? `min-height:${p.minHeight}px;display:flex;align-items:center;justify-content:${p.align === 'center' ? 'center' : 'flex-start'};` : '';
      return `<div style="${F('footnote')}color:${ctx.g.muted};text-align:${p.align};${box}"><span>${esc(p.lead)}<span role="link" style="color:${lc};text-decoration:underline">${esc(p.link)}</span>${esc(p.trail)}</span></div>`;
    },
  });

  E({
    type: 'eveningFooter', name: 'Buttons pinned at the bottom', group: 'Evening', source: EVE + ', ' + CHECK + ', ' + PLEDGE,
    description: 'The button area under the scroll view: 22 pt sides, 8 pt above the home indicator, on the screen colour. It stays at the bottom while the rest scrolls.',
    props: {
      padX: { label: 'Side padding', kind: 'number', options: [16, 20, 22, 24], unit: ' pt', default: 22 },
      padBottom: { label: 'Space above the home indicator', kind: 'number', options: [0, 4, 8, 12, 16], unit: ' pt', default: 8 },
      gap: { label: 'Gap between items', kind: 'number', options: [0, 4, 6, 8, 10, 12], unit: ' pt', default: 6 },
    },
    examples: [{ label: 'Done', ground: 'violet', props: {}, kids: [['button', { label: 'Done' }]] }],
    render(p, ctx, kids) {
      const d = inLib(ctx) ? null : ctx.device;
      const pos = d
        ? `position:sticky;bottom:0;z-index:3;margin-top:auto;margin-bottom:-${d.bottom + 12}px;padding:0 ${p.padX}px ${d.bottom + p.padBottom}px;background:${ctx.g.bg};`
        : `padding:0 ${p.padX}px ${p.padBottom}px;`;
      return `<div style="${pos}display:flex;flex-direction:column;align-items:stretch;gap:${p.gap}px;flex:none">${kids()}</div>`;
    },
  });

  E({
    type: 'eveningCloseButton', name: 'Plain close button', group: 'Evening', source: EVE + ' (GlimBreathingView)',
    description: 'An 18 pt bold cross in a 44 pt tap area, no fill, at the top right.',
    props: {
      icon: { label: 'Icon', kind: 'icon', default: 'xmark' },
      label: { label: 'Spoken label', kind: 'text', default: 'Close' },
      fill: { label: 'Fill', kind: 'select', default: 'none', options: [['none', 'No fill'], ['onColour', 'Card on colour']] },
    },
    examples: [{ label: 'On violet', ground: 'violet', props: {} }],
    render(p, ctx) {
      return `<div role="button" aria-label="${esc(p.label)}" style="align-self:flex-end;width:44px;height:44px;border-radius:50%;background:${p.fill === 'onColour' ? ctx.g.card : 'transparent'};display:flex;align-items:center;justify-content:center;flex:none">${Lab.icon(p.icon, 17, ctx.g.ink)}</div>`;
    },
  });

  /* ---------- Check-in pieces ---------- */
  E({
    type: 'checkinChip', name: 'Choice chip (V4Chip)', group: 'Evening', source: 'DayXero/SOS/SOSV4.swift (V4Chip), ' + CHECK + ', ' + PLEDGE,
    description: '44 pt chip, radius 14, 16 pt semibold, 14 pt sides, on the card-on-colour fill. Picked: cream with violet words (check-in, plan) or ink with the ground colour (pledge). "In a half" keeps the chip its own size, centred in half the row, as the check-in\'s Clear day / Had a slip do.',
    props: {
      label: { label: 'Words', kind: 'text', default: 'Clear day' },
      on: { label: 'State', kind: 'select', default: false, options: [[false, 'Not picked'], [true, 'Picked']] },
      picked: { label: 'Picked colours', kind: 'select', default: 'cream', options: [['cream', 'Cream, violet words'], ['ink', 'Ink, ground-colour words']] },
      slot: { label: 'Width', kind: 'select', default: 'own', options: [['own', 'Its own size'], ['half', 'Centred in half the row'], ['fill', 'Fills half the row']] },
    },
    examples: [{ label: 'Picked', ground: 'violet', props: { on: true } }, { label: 'Not picked', ground: 'violet', props: { label: 'Had a slip' } }, { label: 'Pledge, picked', ground: 'apricot', props: { label: "Won't use nicotine", on: true, picked: 'ink' } }],
    render(p, ctx) {
      const bg = p.on ? (p.picked === 'ink' ? ctx.g.ink : CREAM) : ctx.g.card;
      const fg = p.on ? (p.picked === 'ink' ? ctx.g.bg : VIOLET) : ctx.g.ink;
      const chip = (extra) => `<div role="button" style="${F('body', { size: 16, weight: 600 })}min-height:44px;padding:0 14px;display:flex;align-items:center;border-radius:14px;background:${bg};color:${fg};${extra}">${esc(p.label)}</div>`;
      if (p.slot === 'half') return `<div style="flex:1 1 0;min-width:0;display:flex;justify-content:center">${chip('max-width:100%;')}</div>`;
      if (p.slot === 'fill') return chip('flex:1 1 0;min-width:0;justify-content:center;text-align:center;');
      return chip('flex:none;max-width:100%;');
    },
  });

  E({
    type: 'checkinWavesRow', name: 'Waves from today', group: 'Evening', source: CHECK + ' (wavesRow)',
    description: '"From today\'s SOS: 3 of 3 waves ridden out" with Edit, on a card-on-colour card (radius 22). Edit opens a stepper with 44 pt round buttons for cravings that weren\'t logged.',
    props: {
      lead: { label: 'Words', kind: 'text', default: "From today's SOS: " },
      bold: { label: 'Bold words', kind: 'text', default: '3 of 3 waves ridden out' },
      action: { label: 'Button words', kind: 'text', default: 'Edit' },
      editing: { label: 'Stepper', kind: 'select', default: false, options: [[false, 'Closed'], [true, 'Open']] },
      count: { label: 'Stepper number', kind: 'text', default: '3' },
    },
    examples: [{ label: 'Day 3', ground: 'violet', props: {} }, { label: 'Editing', ground: 'violet', props: { action: 'Done', editing: true } }],
    render(p, ctx) {
      const ink = ctx.g.ink;
      const step = (icon, label) => `<div role="button" aria-label="${label}" style="width:44px;height:44px;border-radius:50%;background:${ctx.g.card};display:flex;align-items:center;justify-content:center;flex:none">${glyph(icon, 16, ink)}</div>`;
      const stepper = p.editing
        ? `<div style="display:flex;align-items:center;justify-content:space-between">${step('minus', 'Fewer')}<div style="${F('title')}color:${ink};font-variant-numeric:tabular-nums">${esc(p.count)}</div>${step('plus', 'More')}</div>` : '';
      return `<div style="display:flex;flex-direction:column;gap:10px;padding:4px 14px;border-radius:22px;background:${ctx.g.card}">
        <div style="display:flex;align-items:center;gap:8px">
          <div style="${F('footnote')}color:${ink};flex:1;min-width:0">${esc(p.lead)}${p.bold ? `<b style="font-weight:700">${esc(p.bold)}</b>` : ''}</div>
          <div role="button" style="${F('footnote', { size: 14, weight: 700 })}color:${ink};min-width:44px;min-height:44px;display:flex;align-items:center;justify-content:center">${esc(p.action)}</div></div>${stepper}</div>`;
    },
  });

  E({
    type: 'checkinUseRow', name: 'Used today row', group: 'Evening', source: CHECK + ' (usedToday)',
    description: 'Prep week: one product, its count and 44 pt minus and plus buttons, on a card-on-colour row (radius 22). Minus is off when nothing is logged.',
    props: {
      label: { label: 'Product', kind: 'text', default: 'Cigarettes' },
      count: { label: 'Count', kind: 'text', default: '0' },
      minusOff: { label: 'Minus', kind: 'select', default: true, options: [[false, 'On'], [true, 'Off (half strength)']] },
    },
    examples: [{ label: 'Cigarettes', ground: 'violet', props: {} }],
    render(p, ctx) {
      const ink = ctx.g.ink;
      const step = (icon, label, off) => `<div role="button" aria-label="${label}" style="width:44px;height:44px;border-radius:50%;background:${ctx.g.card};display:flex;align-items:center;justify-content:center;flex:none;${off ? 'opacity:.5;' : ''}">${glyph(icon, 16, ink)}</div>`;
      return `<div style="display:flex;align-items:center;gap:8px;padding:4px 14px;border-radius:22px;background:${ctx.g.card}">
        <div style="${F('body', { size: 16, weight: 600 })}color:${ink};flex:1;min-width:0">${esc(p.label)}</div>
        ${step('minus', 'One fewer', p.minusOff)}<div style="${F('headline')}color:${ink};min-width:36px;text-align:center">${esc(p.count)}</div>${step('plus', 'One more', false)}</div>`;
    },
  });

  E({
    type: 'checkinNote', name: 'Note', group: 'Evening', source: CHECK + ' (noteField)',
    description: '"Anything to remember? · optional" with a pencil (44 pt tall). Tapped, it becomes a two-to-four-line field on a card-on-colour box (radius 18, 14 pt padding).',
    props: {
      open: { label: 'State', kind: 'select', default: false, options: [[false, 'Closed (link)'], [true, 'Open (field)']] },
      label: { label: 'Link words', kind: 'text', default: 'Anything to remember? · optional' },
      prompt: { label: 'Placeholder', kind: 'text', default: 'Busy day at work, coffee was hard' },
      value: { label: 'Typed', kind: 'text', default: '' },
    },
    examples: [{ label: 'Closed', ground: 'violet', props: {} }, { label: 'Open', ground: 'violet', props: { open: true } }],
    render(p, ctx) {
      if (!p.open) return `<div role="button" style="display:flex;align-items:center;gap:6px;min-height:44px;align-self:flex-start;${F('footnote')}color:${ctx.g.ink}">${glyph('square.and.pencil', 16, ctx.g.ink)}<span>${esc(p.label)}</span></div>`;
      return `<div aria-label="Anything to remember" style="padding:14px;border-radius:18px;background:${ctx.g.card};min-height:${48 + 28}px;${F('body')}color:${p.value ? ctx.g.ink : ctx.g.muted}">${esc(p.value || p.prompt)}</div>`;
    },
  });

  /* ---------- Day end sheet (DayEndSettings) ---------- */
  E({
    type: 'checkinSheet', name: 'Day end sheet', group: 'Evening', source: CHECK + ' (DayEndSettings)',
    description: 'A full-height sheet on the reading ground over the check-in, 16 pt sides, no grabber (one detent).',
    props: {
      top: { label: 'Starts at', kind: 'number', options: [62, 72, 80], unit: ' pt from the top', default: 72 },
      radius: { label: 'Corner radius', kind: 'number', options: [20, 28, 36], unit: ' pt', default: 28 },
      padX: { label: 'Side padding', kind: 'number', options: [16, 20, 22], unit: ' pt', default: 16 },
    },
    examples: [{ label: 'Sheet', ground: 'violet', props: {}, kids: [['text', { step: 'title', text: 'When does your day end?' }]] }],
    render(p, ctx, kids) {
      const r = Lab.ground('reading', ctx.dark);
      const d = inLib(ctx) ? null : ctx.device;
      const sheet = `<div style="${d ? `position:absolute;left:0;right:0;bottom:0;top:${p.top}px;` : 'position:relative;min-height:240px;'}display:flex;flex-direction:column;gap:8px;background:${r.bg};color:${r.ink};border-radius:${p.radius}px ${p.radius}px 0 0;box-shadow:0 -10px 40px rgba(0,0,0,.18);padding:0 ${p.padX}px ${d ? d.bottom + 8 : 8}px;overflow:auto">${kids({ groundName: 'reading' })}</div>`;
      return d ? `<div style="position:absolute;inset:0;z-index:6;background:rgba(0,0,0,.3)">${sheet}</div>` : `<div>${sheet}</div>`;
    },
  });

  E({
    type: 'checkinOptionCard', name: 'Day end option', group: 'Evening', source: 'DayXero/Onboarding/OnboardingV4.swift (OnbOptionCard)',
    description: 'A 64 pt option on the reading surface (radius 18): 19 pt title, optional 14 pt detail, and a 22 pt circle that turns into a green tick. Picked gets a 2 pt ink outline.',
    props: {
      title: { label: 'Title', kind: 'text', default: '4 AM' },
      detail: { label: 'Detail', kind: 'text', default: '' },
      on: { label: 'State', kind: 'select', default: false, options: [[false, 'Not picked'], [true, 'Picked']] },
    },
    examples: [{ label: 'Picked', ground: 'reading', props: { detail: 'Default', on: true } }],
    render(p, ctx) {
      const r = Lab.ground('reading', ctx.dark);
      const hairline = ctx.dark ? 'rgba(255,255,255,0.14)' : 'rgba(30,26,58,0.12)';
      return `<div role="button" style="display:flex;align-items:center;gap:12px;min-height:64px;padding:14px;border-radius:18px;background:${Lab.c(Lab.fill.surface, ctx.dark)};${p.on ? `box-shadow:inset 0 0 0 2px ${r.ink};` : ''}">
        <div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:2px"><div style="${F('headline')}color:${r.ink}">${esc(p.title)}</div>${p.detail ? `<div style="${F('footnote')}color:${r.muted}">${esc(p.detail)}</div>` : ''}</div>
        ${p.on ? glyph('checkmark.circle.fill', 24, Lab.c(Lab.fill.green, ctx.dark)) : glyph('circle', 24, hairline)}</div>`;
    },
  });

  /* ---------- Data ---------- */
  const REASON = 'To keep up with Maya at the park';
  // WindDownView.order: box breathing first, the longer out-breath last (CalmTools.swift titles, details, minutes).
  const TOOLS = [
    { key: 'box', title: 'Box breathing', detail: 'In, hold, out, hold.', minutes: 1 },
    { key: 'grounding', title: '5-4-3-2-1', detail: 'Use your five senses.', minutes: 2 },
    { key: 'notice', title: 'Notice and name', detail: 'Label the thought. Let it be.', minutes: 1 },
    { key: 'anchor', title: 'Drop anchor', detail: 'Feet down. Come back to the room.', minutes: 1 },
    { key: 'outbreath', title: 'Longer out-breath', detail: 'In 4, hold 7, out 8.', minutes: 1 },
  ];
  const WIND = {
    eyebrow: ['Evening', 'Check-in saved'],
    title: ['Wind down with Glim.', 'Rest well.'],
    line: ["A slow breath, a calm tool, then rest. I'm here if tonight feels restless.",
      "Tomorrow's pledge will be here in the morning. If tonight feels restless, breathe with me."],
  };
  const COFFEE_IDEAS = ['take a short walk', 'switch to tea for a week', 'have it somewhere new', 'open Craving SOS'];
  // Sam on Day 3 (codeTrue: Quit Day Fri 6 Nov counts as day 1, so Sun 8 Nov is 3 days clear): clarity round(20 + 2.8 × 3) = 28.
  const DAY3_CLARITY = 28, PREP_CLARITY = 20;

  /* ---------- Wind down body (WindDownView), shared by the Evening tab and "Check-in saved" ---------- */
  function windDown(h, o) {
    const i = o.saved ? 1 : 0;
    return h('stack', 'body', { padX: 20, gap: 12, padBottom: 20 }, [
      h('eveningHero', 'hero', { scene: 'night', clarity: o.clarity, height: 240, character: 'glim:sleepy', size: 140, stage: 1, lift: 10 }),
      h('stack', 'header', { gap: 4 }, [
        h('text', 'eyebrow', { step: 'footnote', size: 14, weight: 700, tone: 'muted', text: WIND.eyebrow[i], alts: { text: [WIND.eyebrow[1 - i]] } }),
        h('text', 'title', { step: 'large', text: WIND.title[i], alts: { text: [WIND.title[1 - i]] } }),
        h('text', 'line', { step: 'body', tone: 'muted', text: WIND.line[i], alts: { text: [WIND.line[1 - i]] } }),
      ]),
      o.checkInCard ? h('todayColourCard', 'checkin-card', { kicker: 'With Glim · 1 min', title: 'How was today, really?', detail: 'One question, then rest.', fill: '#2A1C6E' }) : null,
      h('eveningTonightCard', 'tonight', {}),
      h('eveningToolList', 'tools', {}, TOOLS.map((t, n) => h('eveningToolRow', 'tool-' + t.key, { title: t.title, detail: t.detail, minutes: `${t.minutes} min`, divider: n > 0 }))),
      o.extras ? h('eveningCard', 'reason', { radius: 18, padX: 14, padY: 14, gap: 4 }, [
        h('text', 'reason-kicker', { step: 'caption', tone: 'muted', text: 'Your reason' }),
        h('text', 'reason-text', { step: 'headline', text: REASON }),
      ]) : null,
      o.extras ? h('eveningWaterRow', 'water', {}) : null,
      h('stack', 'help-wrap', { padTop: 8 }, [h('eveningLinkLine', 'help', {})]),
    ]);
  }

  /* ---------- Screen: the Evening tab ---------- */
  Lab.screen({
    id: 'evening', name: 'Evening', area: 'Evening', source: EVE + ' (EveningView, WindDownView)', ground: 'violet', tab: 'evening', fullBleed: true,
    note: 'The Evening tab is Wind down (F17) with the check-in card on top until tonight\'s check-in is saved. The night sky runs up under the status bar (ignoresSafeArea); it is drawn from the very top here. Glim is sleepy, stage 1 (under 7 days clear). Sam has one reason and no photo, so the reason card does nothing when tapped (it moves to the next reason only with two or more). Water opens the water tracker; each tool opens its player (see the Calm screens); the cream card opens Slow breathing with Glim. Before Quit Day the only difference is the hazier sky (clarity 20).',
    states: [
      { id: 'day3', label: 'Day 3 · Sun 8 Nov 21:30 · before check-in' },
      { id: 'day3-done', label: 'Day 3 · Sun 8 Nov · after check-in' },
      { id: 'prep', label: 'Prep · Mon 2 Nov evening · before check-in' },
    ],
    build(h, state) {
      const done = state.id === 'day3-done';
      return windDown(h, { saved: done, checkInCard: !done, extras: true, clarity: state.id === 'prep' ? PREP_CLARITY : DAY3_CLARITY });
    },
  });

  /* ---------- Screen: Slow breathing with Glim (GlimBreathingView) ---------- */
  Lab.screen({
    id: 'evening-breathing', name: 'Slow breathing with Glim', area: 'Evening', source: EVE + ' (GlimBreathingView)', ground: 'violet',
    note: 'Opened full screen from the "For tonight" card. The words cross-fade on the 4 s in, 6 s out clock and the time counts up from 0:00; at three minutes it says "Three minutes. Rest well." It never ends by itself. "1:30" is an example moment. Haptics follow the breath when SOS haptics are on.',
    states: [
      { id: 'start', label: 'Just opened · 0:00' },
      { id: 'running', label: 'Breathing · 1:30' },
      { id: 'three', label: 'After three minutes' },
    ],
    build(h, state) {
      const time = state.id === 'three' ? 'Three minutes. Rest well.' : state.id === 'running' ? '1:30' : '0:00';
      return h('stack', 'body', { gap: 18, padX: 22, padBottom: 8, align: 'center', textAlign: 'center', style: 'flex:1;margin-bottom:-12px' }, [
        h('eveningCloseButton', 'close', {}),
        h('spacer', 'top-space', { flex: true, size: 0 }),
        h('art', 'glim', { art: 'glim:breathe', width: 200, height: 200 }),
        h('breathingWords', 'words', {}),
        h('text', 'time', { step: 'body', tone: 'muted', align: 'center', text: time, alts: { text: ['0:00', 'Three minutes. Rest well.'] } }),
        h('spacer', 'bottom-space', { flex: true, size: 0 }),
        h('stack', 'done-wrap', { style: 'align-self:stretch' }, [h('button', 'done', { label: 'Done' })]),
      ]);
    },
  });

  /* ---------- Check-in form (CheckInView.form) ---------- */
  const CHECKIN = {
    day3: {
      eyebrow: 'Sunday check-in · Day 3', headline: '3 of 3 waves. All yours.', line: 'Each one you ride out makes the next a little quieter.',
      lead: "From today's SOS: ", bold: '3 of 3 waves ridden out', save: 'Save and rest', prompt: 'Busy day at work, coffee was hard', clarity: DAY3_CLARITY,
    },
    prep: {
      eyebrow: 'Prep day 4 check-in · 4 days to Quit Day', headline: 'How did your prep go today?', line: 'Using normally is part of prep week. No guilt, just noticing.',
      lead: 'No cravings logged today', bold: '', save: 'Save prep day 4 check-in', prompt: "My 4 pm one didn't really help the stress", clarity: PREP_CLARITY,
    },
  };

  function checkinForm(h, s) {
    const prep = s === 'prep';
    const d = prep ? CHECKIN.prep : CHECKIN.day3;
    const mood = s === 'day3-good' ? 'good' : '';
    const slip = s === 'day3-slip';
    const editing = s === 'day3-edit';
    const choice = prep
      ? h('row', 'prep-choice', { gap: 8, align: 'flex-start' }, [
        h('checkinChip', 'choice-mindful', { label: 'Mindful, noticed my triggers', on: true, slot: 'half' }),
        h('checkinChip', 'choice-autopilot', { label: 'Mostly autopilot', on: false, slot: 'half' }),
      ])
      : h('stack', 'day-choice', { gap: 8 }, [
        h('row', 'day-choice-row', { gap: 8 }, [
          h('checkinChip', 'choice-clear', { label: 'Clear day', on: !slip, slot: 'half' }),
          h('checkinChip', 'choice-slip', { label: 'Had a slip', on: slip, slot: 'half' }),
        ]),
        slip ? h('text', 'slip-line', { step: 'footnote', tone: 'muted', text: "We'll help you log it after this. Nothing resets.", alts: { text: ["You've already logged it. Nothing resets."] } }) : null,
      ]);
    return [
      h('stack', 'body', { padX: 20, gap: 12, padBottom: 16 }, [
        h('eveningHero', 'hero', { scene: 'night', clarity: d.clarity, height: 250, character: mood === 'good' ? 'glim:cheer' : 'glim:calm', size: 140, stage: 1, lift: 10, close: true }),
        h('stack', 'header', { gap: 6 }, [
          h('text', 'eyebrow', { step: 'footnote', size: 14, weight: 700, tone: 'muted', text: d.eyebrow, alts: { text: prep ? [CHECKIN.day3.eyebrow] : [CHECKIN.prep.eyebrow] } }),
          h('text', 'headline', { step: 'large', text: d.headline, alts: { text: ['A quiet day. Those count too.', "Today was hard. You're still here.", prep ? CHECKIN.day3.headline : CHECKIN.prep.headline] } }),
          h('text', 'line', { step: 'body', tone: 'muted', text: d.line, alts: { text: ['No waves today. Your brain is learning that nothing is missing.', prep ? CHECKIN.day3.line : CHECKIN.prep.line] } }),
        ]),
        choice,
        prep ? h('stack', 'used-today', { gap: 6 }, [
          h('checkinUseRow', 'use-cigarettes', { label: 'Cigarettes', count: '0', minusOff: true }),
          h('checkinUseRow', 'use-puffs', { label: 'Puffs', count: '0', minusOff: true }),
        ]) : null,
        h('checkinWavesRow', 'waves', {
          lead: d.lead, bold: d.bold, action: editing ? 'Done' : prep ? 'Add' : 'Edit', editing, count: '3',
          alts: { lead: prep ? ["From today's SOS: "] : ['No cravings logged today'], action: ['Edit', 'Add', 'Done'] },
        }),
        h('eveningCard', 'mood-card', { radius: 22, padX: 14, padY: 14, gap: 10 }, [
          h('text', 'mood-ask', { step: 'body', size: 16, weight: 700, text: 'How are you feeling tonight?' }),
          h('moodPicker', 'mood', { selected: mood }),
        ]),
        h('checkinNote', 'note', { open: s === 'day3-note', prompt: d.prompt, alts: { prompt: [prep ? CHECKIN.day3.prompt : CHECKIN.prep.prompt] } }),
      ]),
      h('eveningFooter', 'footer', { gap: 6 }, [
        h('button', 'save', { label: d.save, disabled: !mood, alts: { label: ['Save and rest', 'Make a plan for tomorrow', 'Save prep day 4 check-in'] } }),
        h('eveningLinkLine', 'day-end', { lead: 'Your day ends at 4 AM · ', link: 'change', trail: '', linkTone: 'muted', align: 'center', minHeight: 44, alts: { lead: ['Your day ends at midnight · ', 'Your day ends at 2 AM · ', 'Your day ends at 6 AM · '] } }),
      ]),
    ];
  }

  Lab.screen({
    id: 'checkin-form', name: 'Evening check-in', area: 'Evening', source: CHECK + ' (CheckInView, F16)', ground: 'violet', fullBleed: true,
    note: 'F16, opened full screen from the Evening tab or Today. Day 3 numbers: 3 cravings logged in SOS today, all 3 ridden out, so the headline is "3 of 3 waves. All yours." Save stays at half strength until a face is picked; Glim cheers for Good or Proud and is calm otherwise. A day with a wave not ridden out says "Today was hard. You\'re still here." and the button becomes "Make a plan for tomorrow" (next screen). The prep state\'s counts (0 cigarettes, 0 puffs, no cravings) are unknown live values. The mood labels are 12 pt as in the app. The sky runs up under the status bar and is drawn from the very top.',
    states: [
      { id: 'day3', label: 'Day 3 · nothing picked' },
      { id: 'day3-good', label: 'Day 3 · Sam picked Good' },
      { id: 'day3-slip', label: 'Day 3 · "Had a slip" picked' },
      { id: 'day3-edit', label: 'Day 3 · editing the waves' },
      { id: 'day3-note', label: 'Day 3 · writing a note' },
      { id: 'prep', label: 'Prep · Mon 2 Nov' },
    ],
    build(h, state) { return checkinForm(h, state.id); },
  });

  /* ---------- Screen: For tomorrow (TomorrowPlan) ---------- */
  Lab.screen({
    id: 'checkin-plan', name: 'For tomorrow (plan)', area: 'Evening', source: CHECK + ' (TomorrowPlan)', ground: 'violet',
    note: 'Shown after "Make a plan for tomorrow" on a hard day (a wave not ridden out). Sam\'s Day 3 had none, so this is what a hard day would show: the trigger starts on today\'s most common one, or the first of Sam\'s (Coffee). Picking another trigger clears the idea. Save my plan stays at half strength until an idea is picked; the plan is then shown on Today and in SOS.',
    states: [
      { id: 'coffee', label: 'Coffee · nothing picked' },
      { id: 'coffee-picked', label: 'Coffee · "take a short walk" picked' },
    ],
    build(h, state) {
      const picked = state.id === 'coffee-picked' ? COFFEE_IDEAS[0] : null;
      return [
        h('stack', 'body', { padX: 20, padTop: 24, gap: 12, align: 'flex-start', padBottom: 16 }, [
          h('text', 'kicker', { step: 'caption', tone: 'muted', text: 'One small plan' }),
          h('markedTitle', 'title', { lead: 'For ', word: 'tomorrow', mark: 'underline', step: 'large' }),
          h('text', 'ask', { step: 'body', size: 16, weight: 700, text: "What's most likely to set it off?" }),
          h('row', 'triggers', { gap: 8, wrap: true }, [
            h('checkinChip', 'trigger-coffee', { label: 'Coffee', on: true }),
            h('checkinChip', 'trigger-stress', { label: 'Stress', on: false }),
            h('checkinChip', 'trigger-more', { label: 'More…', on: false }),
          ]),
          h('text', 'if', { step: 'headline', text: "If it's after coffee, then I'll…", alts: { text: ["If it's a stressful moment, then I'll…"] } }),
          ...COFFEE_IDEAS.map((idea, i) => h('checkinChip', 'idea-' + (i + 1), { label: idea, on: idea === picked, alts: { label: COFFEE_IDEAS.filter((x) => x !== idea) } })),
        ]),
        h('eveningFooter', 'footer', { gap: 4 }, [
          h('button', 'save', { label: 'Save my plan', disabled: !picked }),
          h('button', 'not-tonight', { label: 'Not tonight', kind: 'quiet' }),
        ]),
      ];
    },
  });

  /* ---------- Screen: Check-in saved (WindDownView after saving) ---------- */
  Lab.screen({
    id: 'checkin-saved', name: 'Check-in saved', area: 'Evening', source: CHECK + ' (done) → ' + EVE + ' (WindDownView)', ground: 'violet', fullBleed: true,
    note: 'What the check-in turns into after Save and rest (or after the plan): Wind down with "Check-in saved / Rest well.", no check-in card, no reason or water, and Done pinned at the bottom. Done closes it. The sky runs up under the status bar and is drawn from the very top.',
    states: [{ id: 'day3', label: 'Day 3 · Sun 8 Nov' }],
    build(h) {
      return [
        windDown(h, { saved: true, checkInCard: false, extras: false, clarity: DAY3_CLARITY }),
        h('eveningFooter', 'footer', {}, [h('button', 'done', { label: 'Done' })]),
      ];
    },
  });

  /* ---------- Screen: When does your day end? (DayEndSettings, a sheet over the check-in) ---------- */
  const DAY_END = [['midnight', ''], ['2 AM', ''], ['4 AM', 'Default'], ['6 AM', 'For night shifts and late finishes']];
  Lab.screen({
    id: 'checkin-dayend', name: 'When does your day end?', area: 'Evening', source: CHECK + ' (DayEndSettings)', ground: 'violet', fullBleed: true,
    note: 'Opened from "Your day ends at 4 AM · change" under the check-in\'s button, as a full-height sheet on the reading ground. Picking an hour saves straight away and moves the reminders. Sam keeps the default, 4 AM. Where the sheet\'s top sits is approximate.',
    states: [{ id: 'four', label: '4 AM (default) picked' }],
    build(h) { return checkinForm(h, 'day3'); },
    overlay(h) {
      return h('checkinSheet', 'dayend-sheet', {}, [
        h('stack', 'dayend-title-wrap', { padTop: 24 }, [h('text', 'dayend-title', { step: 'title', text: 'When does your day end?' })]),
        h('stack', 'dayend-sub-wrap', { padBottom: 12 }, [h('text', 'dayend-sub', { step: 'footnote', tone: 'muted', text: "Up late? A check-in before this time still counts for the day you've just had." })]),
        ...DAY_END.map(([t, detail], i) => h('checkinOptionCard', 'dayend-option-' + (i + 1), { title: t, detail, on: t === '4 AM' })),
        h('spacer', 'dayend-push', { flex: true, size: 0 }),
        h('text', 'dayend-foot', { step: 'footnote', tone: 'muted', align: 'center', text: 'Days clear, lessons and check-ins all follow this.' }),
        h('button', 'dayend-done', { label: 'Done' }),
      ]);
    },
  });

  /* ---------- Screen: Pledge (F09) ---------- */
  const WORDING = {
    wontUse: { chip: "Won't use nicotine", headline: "Today, I won't use nicotine." },
    oneWave: { chip: 'One wave at a time', headline: "Today, I'll take it one wave at a time." },
  };
  Lab.screen({
    id: 'pledge', name: 'Morning pledge', area: 'Evening', source: PLEDGE + ' (F09)', ground: 'apricot', fullBleed: true,
    note: 'F09, opened from Today in the morning (offered until noon). Optional; it never changes days clear. The wording chip is remembered for tomorrow and locks once pledged. Holding for one second fills the button left to right; Xero cheers and the pledge closes itself 1.6 s later. The reason shown is Sam\'s only one. The last line shows only while the check-in reminder is on (9:00 PM by default). The pledge sky works its clarity from days clear = day − 1, so Day 3 is 26 here (Today shows 28). The dawn sky runs up under the status bar and is drawn from the very top.',
    states: [
      { id: 'day3', label: 'Day 3 · Sun 8 Nov · not held' },
      { id: 'day3-held', label: 'Day 3 · pledged' },
      { id: 'day3-wave', label: 'Day 3 · "One wave at a time"' },
      { id: 'prep', label: 'Prep · Mon 2 Nov · not held' },
    ],
    build(h, state) {
      const s = state.id;
      const held = s === 'day3-held';
      const chosen = s === 'day3-wave' ? 'oneWave' : 'wontUse';
      const prep = s === 'prep';
      return [
        h('eveningHero', 'hero', { scene: 'dawn', clarity: prep ? PREP_CLARITY : 26, height: 330, character: held ? 'xero:cheer' : 'xero:hello', size: 200, stage: 1, lift: 10, close: true, bleed: 0 }),
        h('stack', 'body', { padX: 20, padTop: 6, gap: 10, align: 'center', textAlign: 'center', padBottom: 16 }, [
          h('text', 'day', { step: 'footnote', size: 14, weight: 700, tone: 'muted', align: 'center', text: prep ? 'Monday' : 'Sunday · Day 3', alts: { text: prep ? ['Sunday · Day 3'] : ['Monday'] } }),
          h('text', 'headline', { step: 'large', align: 'center', text: WORDING[chosen].headline, alts: { text: [WORDING[chosen === 'wontUse' ? 'oneWave' : 'wontUse'].headline] } }),
          h('row', 'wording', { gap: 6, justify: 'center' }, ['wontUse', 'oneWave'].map((w) => h('checkinChip', 'wording-' + w, { label: WORDING[w].chip, on: chosen === w, picked: 'ink' }))),
          h('eveningCard', 'because', { radius: 22, padX: 16, padY: 14, gap: 4, above: 6 }, [
            h('text', 'because-kicker', { step: 'caption', tone: 'muted', text: 'BECAUSE' }),
            h('text', 'because-text', { step: 'headline', text: REASON }),
          ]),
        ]),
        h('eveningFooter', 'footer', { gap: 8 }, [
          h('holdButton', 'hold', { label: 'Hold to pledge', doneLabel: 'Pledged for today ✓', progress: held ? 1 : 0 }),
          h('text', 'checkin-line', { step: 'footnote', tone: 'muted', align: 'center', text: 'Glim will check in tonight at 9:00 PM. No pressure.' }),
        ]),
      ];
    },
  });
})();
