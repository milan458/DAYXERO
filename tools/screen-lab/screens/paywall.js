/* DayXero Screen Lab — Paywall (DayXero/Paywall: PaywallView, PaywallModel, QuitDayOffer, UpgradeSheet, BillingSheet)
   and Milestones (DayXero/Milestones: MilestoneMoment, ShareCardMaker, ShareCard, FinaleView). See ../FORMAT.md. */
(function () {
  'use strict';
  const Lab = window.Lab;
  const E = Lab.element, esc = Lab.esc, T = Lab.text, F = Lab.font;
  const PV = 'DayXero/Paywall/PaywallView.swift';
  const PM = 'DayXero/Paywall/PaywallModel.swift';
  const OFFER = 'DayXero/Paywall/QuitDayOffer.swift';
  const UPG = 'DayXero/Paywall/UpgradeSheet.swift';
  const MV = 'DayXero/Milestones/MilestoneViews.swift';
  const FIN = 'DayXero/Milestones/FinaleView.swift';
  const MM = 'DayXeroCore/Logic/MilestoneMoments.swift';

  /* Read4 (DayXero/Shared/V4Reading.swift): the reading tier's colours for the appearance. */
  function R4(ctx) {
    const d = ctx.dark;
    const g = Lab.ground('reading', d);
    return {
      bg: g.bg, ink: g.ink, muted: g.muted, onInk: g.bg,
      faint: d ? 'rgba(255,248,238,0.38)' : 'rgba(30,26,58,0.38)',
      hairline: d ? 'rgba(255,255,255,0.14)' : 'rgba(30,26,58,0.12)',
      track: d ? 'rgba(255,255,255,0.16)' : 'rgba(30,26,58,0.12)',
      card: Lab.c(Lab.fill.raised, d), surface: Lab.c(Lab.fill.surface, d),
      accent: Lab.c(Lab.fill.green, d),
      accentSoft: d ? 'rgba(47,208,138,0.16)' : 'rgba(15,110,67,0.12)',
      amber: d ? '#E5A93C' : '#8A5E0E',
      amberSoft: d ? 'rgba(229,169,60,0.12)' : 'rgba(138,94,14,0.12)',
    };
  }
  const isLib = (ctx) => ctx.screenId === '_lib' || !ctx.device;

  /* SF Symbols this file needs that lab.js doesn't draw. `knock` is the colour of a cut-out (the tick in a filled circle). */
  const GLYPHS = {
    'exclamationmark.circle': () => '<circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="2"/><path d="M12 7v6.3" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/><circle cx="12" cy="16.9" r="1.3" fill="currentColor"/>',
    'wifi.slash': () => '<path d="M3 9.5a13 13 0 0 1 18 0M6 13a8.5 8.5 0 0 1 12 0M9 16.4a4 4 0 0 1 6 0" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/><circle cx="12" cy="19.6" r="1.6" fill="currentColor"/><path d="M4 3.5l16 17" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/>',
    lock: () => '<rect x="5.5" y="10.5" width="13" height="10" rx="2.5" fill="none" stroke="currentColor" stroke-width="1.5"/><path d="M8.5 10.5V8a3.5 3.5 0 0 1 7 0v2.5" fill="none" stroke="currentColor" stroke-width="1.5"/>',
    'doc.text': () => '<path d="M6.5 3.5h7l4 4v13h-11z" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/><path d="M13.5 3.5v4h4M9 12h6M9 15h6M9 18h4" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>',
    'hand.tap': () => '<path d="M10 13.2V6.2a1.6 1.6 0 0 1 3.2 0v6l4.2.9a2 2 0 0 1 1.6 2.2l-.6 4.3a2 2 0 0 1-2 1.7h-5.3a2 2 0 0 1-1.6-.8l-3.2-4.3a1.5 1.5 0 0 1 2.2-2z" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linejoin="round"/><path d="M7.4 6.8a4.3 4.3 0 0 1 8.4 0" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>',
    'checkmark.circle.fill': (k) => `<circle cx="12" cy="12" r="10" fill="currentColor"/><path d="M7.4 12.4l3.1 3.1 6.1-6.4" fill="none" stroke="${k || '#fff'}" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round"/>`,
    'largecircle.fill.circle': () => '<circle cx="12" cy="12" r="10" fill="none" stroke="currentColor" stroke-width="1.7"/><circle cx="12" cy="12" r="5.6" fill="currentColor"/>',
    circle: () => '<circle cx="12" cy="12" r="10" fill="none" stroke="currentColor" stroke-width="1.7"/>',
    'square.and.arrow.up': () => '<path d="M8.6 9.5H7.2a1.7 1.7 0 0 0-1.7 1.7v7.6a1.7 1.7 0 0 0 1.7 1.7h9.6a1.7 1.7 0 0 0 1.7-1.7v-7.6a1.7 1.7 0 0 0-1.7-1.7h-1.4" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round"/><path d="M12 14.5V3.5M8.6 6.9L12 3.5l3.4 3.4" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linecap="round" stroke-linejoin="round"/>',
  };
  function glyph(name, size, colour, knock) {
    if (GLYPHS[name]) return `<svg viewBox="0 0 24 24" width="${size}" height="${size}" style="color:${colour};flex:none;display:block" aria-hidden="true">${GLYPHS[name](knock)}</svg>`;
    return Lab.icon(name, size, colour);
  }
  const DISC_ICONS = [['checkmark', 'Tick'], ['clock', 'Clock'], ['exclamationmark.circle', 'Exclamation'], ['wifi.slash', 'No wi-fi']];

  /** "Tap **Manage subscription** below": escapes, then bolds the ** parts (SwiftUI Markdown in LocalizedStringKey). */
  const md = (s) => esc(s).replace(/\*\*(.+?)\*\*/g, '<b style="font-weight:700">$1</b>');

  /* ================================================================================================
     Shared layout: a page that fills the phone, a scrolling middle and a pinned footer, and sheets.
     ================================================================================================ */
  E({
    type: 'paywallPage', name: 'Full-screen page', group: 'Paywall', source: PV,
    description: 'The whole screen between the status bar and the home indicator, so the footer stays pinned and the middle scrolls (as in the app). In a sheet it fills the sheet.',
    props: {
      gap: { label: 'Gap between items', kind: 'number', options: [0, 4, 8, 12, 14, 16], unit: ' pt', default: 0 },
      padX: { label: 'Side padding', kind: 'number', options: [0, 16, 20, 22, 24], unit: ' pt', default: 0 },
      padTop: { label: 'Top padding', kind: 'number', options: [0, 8, 12, 16], unit: ' pt', default: 0 },
      padBottom: { label: 'Bottom padding', kind: 'number', options: [0, 8, 12, 16], unit: ' pt', default: 8 },
      fill: { label: 'Fills', kind: 'select', default: 'screen', options: [['screen', 'The screen'], ['parent', 'The sheet it sits in']] },
    },
    render(p, ctx, kids) {
      let size = 'min-height:320px;';
      if (p.fill === 'parent') size = 'flex:1;min-height:0;';
      else if (!isLib(ctx)) {
        const scr = Lab.screens.find((s) => s.id === ctx.screenId) || {};
        const d = ctx.device;
        size = `height:${d.h - (scr.fullBleed ? 0 : d.top) - d.bottom}px;margin-bottom:-12px;flex:none;`;
      }
      return `<div style="${size}display:flex;flex-direction:column;gap:${p.gap}px;padding:${p.padTop}px ${p.padX}px ${p.padBottom}px;box-sizing:border-box;position:relative">${kids()}</div>`;
    },
  });

  E({
    type: 'paywallScroll', name: 'Scrolling middle', group: 'Paywall', source: PV + ' (ScrollView)',
    description: 'The part between the header and the pinned footer that scrolls.',
    props: {
      gap: { label: 'Gap between items', kind: 'number', options: [0, 4, 8, 10, 12, 16], unit: ' pt', default: 12 },
      padX: { label: 'Side padding', kind: 'number', options: [0, 16, 20, 24], unit: ' pt', default: 16 },
      padTop: { label: 'Top padding', kind: 'number', options: [0, 8, 12, 16, 20], unit: ' pt', default: 12 },
      padBottom: { label: 'Bottom padding', kind: 'number', options: [0, 8, 12, 16, 20, 24], unit: ' pt', default: 0 },
      align: { label: 'Align', kind: 'select', default: 'stretch', options: [['stretch', 'Left (full width)'], ['center', 'Centre']] },
    },
    render(p, ctx, kids) {
      return `<div style="flex:1 1 0;min-height:0;overflow-y:auto;overflow-x:hidden;scrollbar-width:none"><div style="display:flex;flex-direction:column;gap:${p.gap}px;align-items:${p.align};${p.align === 'center' ? 'text-align:center;' : ''}padding:${p.padTop}px ${p.padX}px ${p.padBottom}px">${kids()}</div></div>`;
    },
  });

  E({
    type: 'paywallFooter', name: 'Pinned footer', group: 'Paywall', source: PV + ' (footer, firstRunFooter)',
    description: 'The buttons pinned under the scroll. The first-run paywall puts the path horizon (clarity 60, 55%) behind it, running under the home indicator.',
    props: {
      gap: { label: 'Gap between items', kind: 'number', options: [0, 4, 8, 12], unit: ' pt', default: 8 },
      padX: { label: 'Side padding', kind: 'number', options: [0, 16, 20, 22, 24], unit: ' pt', default: 16 },
      padTop: { label: 'Top padding', kind: 'number', options: [0, 4, 8, 12], unit: ' pt', default: 0 },
      horizon: { label: 'Horizon behind', kind: 'select', default: 'none', options: [['none', 'None'], ['path', 'Path (first run)'], ['dawn', 'Dawn'], ['sea', 'Sea']] },
      horizonOpacity: { label: 'Horizon strength', kind: 'number', options: [0.35, 0.45, 0.55, 0.7, 1], default: 0.55 },
      horizonHeight: { label: 'Horizon height', kind: 'number', options: [120, 150, 180, 220], unit: ' pt', default: 150 },
    },
    examples: [{ label: 'First run', ground: 'reading', props: { horizon: 'path' }, kids: [['button', { label: 'Start my 3-day free trial' }]] }],
    render(p, ctx, kids) {
      const below = isLib(ctx) ? 0 : ctx.device.bottom;
      const art = p.horizon !== 'none'
        ? `<div style="position:absolute;left:0;right:0;bottom:-${below}px;height:${p.horizonHeight}px;opacity:${p.horizonOpacity};line-height:0;pointer-events:none;overflow:hidden">${Lab.art(p.horizon === 'dawn' ? 'scene:horizon' : 'scene:horizon:' + p.horizon, { width: ctx.width || 402, height: p.horizonHeight, scene: { clarity: 60, fit: 'bottom' } })}</div>`
        : '';
      return `<div style="position:relative;flex:none;padding:${p.padTop}px ${p.padX}px 0">${art}<div style="position:relative;display:flex;flex-direction:column;align-items:stretch;gap:${p.gap}px">${kids()}</div></div>`;
    },
  });

  E({
    type: 'paywallSheet', name: 'Sheet (detent)', group: 'Paywall', source: 'SwiftUI .sheet with .presentationDetents',
    description: 'A system sheet on the reading ground. Medium: half the screen over the dimmed screen behind. Large: from just under the status bar, with the screen behind pushed back on black.',
    props: {
      detent: { label: 'Height', kind: 'select', default: 'medium', options: [['medium', 'Medium (half)'], ['large', 'Large']] },
      grabber: { label: 'Grabber', kind: 'bool', labels: ['Show', 'Hide'], default: false },
      centre: { label: 'Content', kind: 'select', default: false, options: [[false, 'From the top'], [true, 'Centred in the sheet']] },
      radius: { label: 'Corner radius', kind: 'number', options: [20, 28, 34, 38], unit: ' pt', default: 28 },
    },
    examples: [{ label: 'Medium', ground: 'reading', props: { grabber: true }, kids: [['text', { step: 'title', text: 'How billing works' }]] }],
    render(p, ctx, kids) {
      const r = R4(ctx);
      const grab = p.grabber ? `<div style="position:absolute;top:5px;left:50%;margin-left:-18px;width:36px;height:5px;border-radius:3px;background:${r.muted};opacity:0.4"></div>` : '';
      const inner = (pad) => `<div style="flex:1;min-height:0;display:flex;flex-direction:column;${p.centre ? 'justify-content:center;' : ''}padding-bottom:${pad}px">${kids({ groundName: 'reading' })}</div>`;
      if (isLib(ctx)) return `<div style="position:relative;height:340px;display:flex;flex-direction:column;background:${r.bg};border-radius:${p.radius}px ${p.radius}px 0 0;overflow:hidden">${grab}${inner(0)}</div>`;
      const d = ctx.device;
      const large = p.detent === 'large';
      const top = large ? d.top + 10 : Math.round(d.h / 2);
      const behind = large
        ? `<div style="position:absolute;inset:0;background:#000"></div><div style="position:absolute;left:14px;right:14px;top:${d.top - 12}px;height:80px;border-radius:12px;background:${ctx.g.bg};opacity:0.55"></div>`
        : '<div style="position:absolute;inset:0;background:rgba(0,0,0,0.25)"></div>';
      return `<div style="position:absolute;inset:0;z-index:6">${behind}<div style="position:absolute;left:0;right:0;bottom:0;top:${top}px;display:flex;flex-direction:column;background:${r.bg};color:${r.ink};border-radius:${p.radius}px ${p.radius}px 0 0;overflow:hidden;box-shadow:0 -10px 40px rgba(0,0,0,.18)">${grab}${inner(d.bottom)}</div></div>`;
    },
  });

  /* ================================================================================================
     Paywall pieces (PaywallView.swift)
     ================================================================================================ */
  E({
    type: 'paywallHeader', name: 'Paywall header', group: 'Paywall', source: PV + ' (header)',
    description: 'A 36 pt close button (raised, hairline, 13 pt muted cross) and "Restore purchases" (14 pt, muted), 44 pt tall. On the first-run paywall the close fades in after 3 seconds.',
    props: {
      close: { label: 'Close button', kind: 'select', default: true, options: [[true, 'Shown'], [false, 'Hidden (first 3 seconds)']] },
      restore: { label: 'Restore words', kind: 'text', default: 'Restore purchases' },
      closeSize: { label: 'Close size', kind: 'number', options: [32, 36, 40, 44], unit: ' pt', default: 36, global: true },
      padX: { label: 'Side padding', kind: 'number', options: [12, 16, 20], unit: ' pt', default: 16 },
      padTop: { label: 'Top padding', kind: 'number', options: [0, 4, 8, 12], unit: ' pt', default: 8 },
    },
    examples: [{ label: 'Reading', ground: 'reading', props: {} }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="display:flex;align-items:center;justify-content:space-between;min-height:44px;padding:${p.padTop}px ${p.padX}px 0;flex:none">
        <div role="button" aria-label="Close and continue with the free version" style="width:${p.closeSize}px;height:${p.closeSize}px;border-radius:50%;background:${r.card};box-shadow:inset 0 0 0 1px ${r.hairline};display:flex;align-items:center;justify-content:center;opacity:${p.close ? 1 : 0}">${Lab.icon('xmark', 13, r.muted)}</div>
        <div role="button" style="${F('footnote', { size: 14, weight: 500 })}color:${r.muted}">${esc(p.restore)}</div></div>`;
    },
  });

  E({
    type: 'paywallIncluded', name: "What's included line", group: 'Paywall', source: PV + ' (included) and ' + OFFER,
    description: 'A tick and a line. The paywall: 12 pt bold green tick, 14 pt ink. The Quit Day offer: green filled tick circle, 16 pt body.',
    props: {
      text: { label: 'Words', kind: 'text', default: 'Insights on your triggers' },
      style: { label: 'Style', kind: 'select', default: 'paywall', options: [['paywall', 'Paywall (tick, 14 pt)'], ['offer', 'Offer (tick in a circle, 16 pt)']] },
    },
    examples: [{ label: 'Paywall', ground: 'reading', props: {} }, { label: 'Offer', ground: 'reading', props: { style: 'offer' } }],
    render(p, ctx) {
      const r = R4(ctx);
      if (p.style === 'offer') {
        return `<div style="display:flex;align-items:center;gap:8px">${glyph('checkmark.circle.fill', 20, r.accent, r.card)}<div style="${F('body')}color:${r.ink};min-width:0">${esc(p.text)}</div></div>`;
      }
      return `<div style="display:flex;align-items:center;gap:8px">${glyph('checkmark', 12, r.accent)}<div style="${F('footnote', { size: 14, weight: 400 })}color:${r.ink};min-width:0">${esc(p.text)}</div></div>`;
    },
  });

  E({
    type: 'paywallTrustCard', name: 'Trust card', group: 'Paywall', source: PV + ' (trustCard)',
    description: 'Plain facts in place of reviews: three lines with 13 pt light green icons and 14 pt muted words, on a raised card (radius 20, hairline, 16 pt padding).',
    props: {
      line1: { label: 'Line 1', kind: 'text', default: 'Your answers stay on this phone' },
      line2: { label: 'Line 2', kind: 'text', default: 'NRT advice from a Cochrane review of 133 trials' },
      line3: { label: 'Line 3', kind: 'text', default: 'Cancel in two taps, in Settings' },
      radius: { label: 'Corner radius', kind: 'number', options: [18, 20, 22, 24], unit: ' pt', default: 20 },
    },
    examples: [{ label: 'Reading', ground: 'reading', props: {} }],
    render(p, ctx) {
      const r = R4(ctx);
      const row = (icon, text) => `<div style="display:flex;align-items:center;gap:8px">${glyph(icon, 15, r.accent)}<div style="${F('footnote', { size: 14, weight: 400 })}color:${r.muted}">${esc(text)}</div></div>`;
      return `<div style="display:flex;flex-direction:column;gap:10px;padding:16px;border-radius:${p.radius}px;background:${r.card};box-shadow:inset 0 0 0 1px ${r.hairline}">${row('lock', p.line1)}${row('doc.text', p.line2)}${row('hand.tap', p.line3)}</div>`;
    },
  });

  E({
    type: 'paywallPlanCard', name: 'Plan card (first run)', group: 'Paywall', source: PV + ' (planCard)',
    description: 'Yearly and Monthly side by side: 14 pt label, price (24 pt yearly, 19 pt monthly), 12 pt detail, radius 22. Green 1.5 pt outline when picked. Yearly carries the green trial badge on its top edge.',
    props: {
      plan: { label: 'Plan', kind: 'select', default: 'annual', options: [['annual', 'Yearly (taller, 24 pt price)'], ['monthly', 'Monthly (19 pt price)']] },
      title: { label: 'Label', kind: 'text', default: 'Yearly' },
      price: { label: 'Price', kind: 'text', default: '$39.99/yr' },
      detail: { label: 'Detail', kind: 'text', default: '$3.33/mo' },
      badge: { label: 'Badge', kind: 'text', default: '' },
      selected: { label: 'State', kind: 'select', default: false, options: [[false, 'Not picked'], [true, 'Picked']] },
      radius: { label: 'Corner radius', kind: 'number', options: [18, 20, 22, 24], unit: ' pt', default: 22, global: true },
    },
    examples: [{ label: 'Yearly picked', ground: 'reading', props: { selected: true, badge: '3 DAYS FREE · SAVE 66%' } }],
    render(p, ctx) {
      const r = R4(ctx);
      const annual = p.plan === 'annual';
      const badge = p.badge ? `<div style="position:absolute;top:-10px;left:50%;transform:translateX(-50%);white-space:nowrap;${F('caption', { size: 12, weight: 700, tracking: 0.4 })}color:${Lab.CREAM};padding:4px 9px;border-radius:999px;background:${r.accent}">${esc(p.badge)}</div>` : '';
      return `<div role="button" style="position:relative;flex:1 1 0;min-width:0;display:flex;flex-direction:column;align-items:center;gap:4px;padding:${annual ? 22 : 14}px 10px 14px;border-radius:${p.radius}px;background:${r.card};box-shadow:inset 0 0 0 ${p.selected ? 1.5 : 1}px ${p.selected ? r.accent : r.hairline};text-align:center">
        ${badge}<div style="${F('footnote', { size: 14, weight: 600 })}color:${r.muted}">${esc(p.title)}</div>
        <div style="${F('title', { size: annual ? 24 : 19, weight: 700 })}color:${r.ink};white-space:nowrap">${esc(p.price)}</div>
        <div style="${F('caption', { size: 12, weight: 400 })}color:${r.muted}">${esc(p.detail)}</div></div>`;
    },
  });

  E({
    type: 'paywallPlanRow', name: 'Plan row', group: 'Paywall', source: PV + ' (PlanRow)',
    description: 'A 20 pt radio, 16 pt title over a 14 pt detail, and the price over its period. Raised, radius 20, green 1.5 pt outline when picked. A green trial badge sits on the top-right edge.',
    props: {
      title: { label: 'Title', kind: 'text', default: 'Lifetime' },
      detail: { label: 'Detail', kind: 'text', default: 'Pay once' },
      price: { label: 'Price', kind: 'text', default: '$79.99' },
      period: { label: 'Period', kind: 'text', default: 'one time' },
      badge: { label: 'Badge', kind: 'text', default: '' },
      selected: { label: 'State', kind: 'select', default: false, options: [[false, 'Not picked'], [true, 'Picked']] },
      radius: { label: 'Corner radius', kind: 'number', options: [16, 18, 20, 22, 24], unit: ' pt', default: 20, global: true },
    },
    examples: [{ label: 'Yearly picked', ground: 'reading', props: { title: 'Yearly', detail: '$3.33 a month', price: '$39.99', period: 'per year', badge: '3 DAYS FREE · SAVE 66%', selected: true } }],
    render(p, ctx) {
      const r = R4(ctx);
      const radio = p.selected
        ? `<div style="width:20px;height:20px;border-radius:50%;background:${r.accent};display:flex;align-items:center;justify-content:center;flex:none"><div style="width:7px;height:7px;border-radius:50%;background:#000"></div></div>`
        : `<div style="width:20px;height:20px;border-radius:50%;box-shadow:inset 0 0 0 1.5px ${r.faint};flex:none"></div>`;
      const badge = p.badge ? `<div style="position:absolute;top:-9px;right:14px;white-space:nowrap;${F('caption', { size: 12, weight: 700, tracking: 0.4 })}color:${Lab.CREAM};padding:3px 8px;border-radius:999px;background:${r.accent}">${esc(p.badge)}</div>` : '';
      return `<div role="button" style="position:relative;display:flex;align-items:center;gap:12px;padding:11px 14px;border-radius:${p.radius}px;background:${r.card};box-shadow:inset 0 0 0 ${p.selected ? 1.5 : 1}px ${p.selected ? r.accent : r.hairline}">
        ${badge}${radio}<div style="display:flex;flex-direction:column;gap:1px;min-width:0"><div style="${F('body', { size: 16, weight: 600 })}color:${r.ink}">${esc(p.title)}</div><div style="${F('footnote')}color:${r.muted}">${esc(p.detail)}</div></div>
        <div style="flex:1;min-width:8px"></div>
        <div style="display:flex;flex-direction:column;gap:1px;align-items:flex-end;flex:none"><div style="${F('body', { size: 16, weight: 700 })}color:${r.ink};font-variant-numeric:tabular-nums">${esc(p.price)}</div><div style="${F('caption', { size: 12, weight: 500 })}color:${r.muted}">${esc(p.period)}</div></div></div>`;
    },
  });

  E({
    type: 'paywallSkeleton', name: 'Loading placeholder', group: 'Paywall', source: PV + ' (plans while loading)',
    description: 'A plain surface block where a plan will be while the prices load.',
    props: {
      height: { label: 'Height', kind: 'number', options: [44, 60, 80, 120, 132], unit: ' pt', default: 60 },
      radius: { label: 'Corner radius', kind: 'number', options: [18, 20, 22], unit: ' pt', default: 20 },
      grow: { label: 'Width', kind: 'select', default: false, options: [[false, 'Full width'], [true, 'Share the row']] },
    },
    examples: [{ label: 'Plan row', ground: 'reading', props: {} }],
    render(p, ctx) {
      return `<div aria-hidden="true" style="${p.grow ? 'flex:1 1 0;min-width:0;' : ''}height:${p.height}px;border-radius:${p.radius}px;background:${R4(ctx).surface}"></div>`;
    },
  });

  E({
    type: 'paywallRichLine', name: 'Charge line', group: 'Paywall', source: PV + ' (chargeLine)',
    description: 'What gets charged and when, centred and muted, with the date or price in bold. An optional second line.',
    props: {
      lead: { label: 'Words before the bold', kind: 'text', default: '' },
      bold: { label: 'Bold words', kind: 'text', default: '' },
      trail: { label: 'Words after the bold', kind: 'text', default: '' },
      second: { label: 'Second line', kind: 'text', default: '' },
      size: { label: 'Size', kind: 'number', options: [12, 13, 14], unit: ' pt', default: 14 },
      align: { label: 'Align', kind: 'select', default: 'center', options: [['center', 'Centre'], ['left', 'Left']] },
    },
    examples: [{ label: 'Yearly with trial', ground: 'reading', props: { lead: 'Free until ', bold: 'Tue 10 Nov', trail: ', then $39.99 a year.', second: "We'll remind you 2 days before." } }],
    render(p, ctx) {
      const r = R4(ctx);
      const first = `${esc(p.lead)}${p.bold ? `<b style="font-weight:700">${esc(p.bold)}</b>` : ''}${esc(p.trail)}`;
      return `<div style="${F('footnote', { size: p.size, weight: 400, lh: 1.35 })}color:${r.muted};text-align:${p.align}">${first}${p.second ? '<br>' + esc(p.second) : ''}</div>`;
    },
  });

  E({
    type: 'paywallLinks', name: 'Terms and links', group: 'Paywall', source: PV + ' (terms) and ' + OFFER + ' (links)',
    description: 'The cancel line (not for lifetime) over underlined links separated by dots, 12 pt muted. The offer uses the bold caption style.',
    props: {
      cancel: { label: 'Cancel line', kind: 'text', default: 'Cancel in Settings › Apple ID › Subscriptions.' },
      link1: { label: 'Link 1', kind: 'text', default: 'How billing works' },
      link2: { label: 'Link 2', kind: 'text', default: 'Terms' },
      link3: { label: 'Link 3', kind: 'text', default: '' },
      style: { label: 'Style', kind: 'select', default: 'plain', options: [['plain', '12 pt regular (paywall)'], ['caption', '12 pt bold caption (offer)']] },
    },
    examples: [{ label: 'Paywall', ground: 'reading', props: {} }],
    render(p, ctx) {
      const r = R4(ctx);
      const font = p.style === 'caption' ? F('caption') : F('caption', { size: 12, weight: 400, lh: 1.3 });
      const links = [p.link1, p.link2, p.link3].filter(Boolean).map((l) => `<span role="link" style="text-decoration:underline">${esc(l)}</span>`).join('<span>·</span>');
      return `<div style="display:flex;flex-direction:column;align-items:center;gap:2px;text-align:center;${font}color:${r.muted}">${p.cancel ? `<div>${esc(p.cancel)}</div>` : ''}<div style="display:flex;gap:6px;justify-content:center;flex-wrap:wrap">${links}</div></div>`;
    },
  });

  E({
    type: 'paywallIconDisc', name: 'Icon disc', group: 'Paywall', source: PV + ' (PaywallMessage), V4StateView, ' + OFFER,
    description: 'A round disc with one icon: unlocked (green, cream tick), waiting (soft green), error (soft amber).',
    props: {
      icon: { label: 'Icon', kind: 'select', default: 'checkmark', options: DISC_ICONS },
      tint: { label: 'Colour', kind: 'select', default: 'sage', options: [['sage', 'Green with a cream icon'], ['accent', 'Soft green with a green icon'], ['amber', 'Soft amber with an amber icon']] },
      size: { label: 'Size', kind: 'number', options: [56, 64, 76, 88], unit: ' pt', default: 76 },
      glyph: { label: 'Icon size', kind: 'number', options: [22, 26, 28, 30, 34], unit: ' pt', default: 28 },
    },
    examples: [{ label: 'Unlocked', ground: 'reading', props: {} }, { label: 'Waiting', ground: 'reading', props: { icon: 'clock', tint: 'accent' } }],
    render(p, ctx) {
      const r = R4(ctx);
      const [bg, fg] = p.tint === 'sage' ? [r.accent, Lab.CREAM] : p.tint === 'amber' ? [r.amberSoft, r.amber] : [r.accentSoft, r.accent];
      return `<div aria-hidden="true" style="width:${p.size}px;height:${p.size}px;border-radius:50%;background:${bg};display:flex;align-items:center;justify-content:center;flex:none;align-self:center">${glyph(p.icon, p.glyph, fg)}</div>`;
    },
  });

  E({
    type: 'paywallNotice', name: 'Notice banner', group: 'Paywall', source: PV + ' (NoticeBanner) and ' + OFFER + ' (notice)',
    description: 'A message that drops in at the top after a restore or a failed purchase. Paywall: raised card with an amber icon and a cross. Offer: navy card with cream words.',
    props: {
      text: { label: 'Words', kind: 'text', default: "No purchases found. Make sure you're signed in with the Apple ID you bought with." },
      style: { label: 'Style', kind: 'select', default: 'card', options: [['card', 'Raised card (paywall)'], ['navy', 'Navy card (offer)']] },
      padX: { label: 'Side padding', kind: 'number', options: [12, 16, 20], unit: ' pt', default: 12 },
    },
    examples: [{ label: 'Paywall', ground: 'reading', props: {} }, { label: 'Offer', ground: 'reading', props: { style: 'navy', padX: 20 } }],
    render(p, ctx) {
      const r = R4(ctx);
      const pos = isLib(ctx) ? 'position:relative;' : `position:absolute;z-index:5;left:0;right:0;top:${ctx.device.top}px;`;
      if (p.style === 'navy') {
        return `<div style="${pos}padding:0 ${p.padX}px"><div role="button" style="padding:14px;border-radius:14px;background:${Lab.NAVY};${F('footnote')}color:${Lab.CREAM}">${esc(p.text)}</div></div>`;
      }
      return `<div style="${pos}padding:0 ${p.padX}px"><div style="display:flex;align-items:flex-start;gap:10px;padding:12px;border-radius:18px;background:${r.card};box-shadow:inset 0 0 0 1px ${r.hairline},0 8px 16px rgba(0,0,0,.15)">
        ${glyph('exclamationmark.circle', 20, r.amber)}<div style="flex:1;min-width:0;${F('footnote', { size: 14, weight: 400 })}color:${r.ink}">${esc(p.text)}</div>
        <div role="button" aria-label="Dismiss" style="padding-top:3px">${Lab.icon('xmark', 12, r.muted)}</div></div></div>`;
    },
  });

  E({
    type: 'paywallTextLink', name: 'Text link', group: 'Paywall', source: OFFER + ' (lifetime), ' + MV + ' (source link)',
    description: 'Words you can tap, optionally underlined: the offer\'s "Pay once" line (14 pt, bold and underlined when picked) and a milestone\'s source.',
    props: {
      text: { label: 'Words', kind: 'text', default: 'Pay once · $79.99' },
      step: { label: 'Size', kind: 'select', default: 'footnote', options: [['footnote', '14 pt'], ['caption', '12 pt caption']] },
      weight: { label: 'Weight', kind: 'number', options: [400, 500, 600, 700], default: 600 },
      underline: { label: 'Underline', kind: 'bool', labels: ['Yes', 'No'], default: false },
      tone: { label: 'Colour', kind: 'colour', default: 'ink' },
      height: { label: 'Height', kind: 'number', options: [0, 44], unit: ' pt', default: 44 },
    },
    examples: [{ label: 'Lifetime, picked', ground: 'reading', props: { weight: 700, underline: true } }],
    render(p, ctx) {
      return `<div role="link" style="display:flex;align-items:center;justify-content:center;text-align:center;${p.height ? `min-height:${p.height}px;` : ''}${F(p.step, { size: p.step === 'caption' ? 12 : 14, weight: p.weight, tracking: p.step === 'caption' ? 0.8 : 0 })}color:${Lab.colour(p.tone, ctx)};${p.underline ? 'text-decoration:underline;' : ''}">${esc(p.text)}</div>`;
    },
  });

  E({
    type: 'paywallSpinner', name: 'Loading spinner', group: 'Paywall', source: 'SwiftUI ProgressView',
    description: 'The system spinner, shown while the plans load.',
    props: { minHeight: { label: 'Space it takes', kind: 'number', options: [44, 80, 120], unit: ' pt', default: 120 } },
    render(p, ctx) {
      const c = R4(ctx).muted;
      const spokes = Array.from({ length: 8 }, (_, i) => `<rect x="11" y="2.5" width="2" height="5.5" rx="1" fill="${c}" opacity="${(0.25 + (i / 8) * 0.75).toFixed(2)}" transform="rotate(${i * 45} 12 12)"/>`).join('');
      return `<div style="min-height:${p.minHeight}px;display:flex;align-items:center;justify-content:center"><svg width="22" height="22" viewBox="0 0 24 24" aria-label="Loading">${spokes}</svg></div>`;
    },
  });

  E({
    type: 'paywallSecondaryButton', name: 'Surface button', group: 'Paywall', source: 'DayXero/Shared/V4Reading.swift (V4SecondaryButtonStyle)',
    description: 'The reading-tier secondary: a 58 pt surface pill with 16 pt ink words.',
    props: { label: { label: 'Words', kind: 'text', default: 'Manage subscription' } },
    render(p, ctx) {
      const r = R4(ctx);
      return `<div role="button" style="min-height:58px;padding:0 18px;border-radius:999px;background:${r.surface};display:flex;align-items:center;justify-content:center;text-align:center;${F('body', { size: 16, weight: 600 })}color:${r.ink}">${esc(p.label)}</div>`;
    },
  });

  E({
    type: 'paywallBillingStep', name: 'Numbered step', group: 'Paywall', source: PV + ' (BillingSheet.step)',
    description: 'A 24 pt surface circle with the number (12 pt bold) and a 14 pt step; ** marks the bold words.',
    props: {
      number: { label: 'Number', kind: 'text', default: '1' },
      text: { label: 'Words', kind: 'text', default: 'Tap **Manage subscription** below' },
    },
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="display:flex;align-items:center;gap:10px"><div style="width:24px;height:24px;border-radius:50%;background:${r.surface};display:flex;align-items:center;justify-content:center;flex:none;${F('caption', { size: 12, weight: 700 })}color:${r.ink}">${esc(p.number)}</div><div style="${F('footnote', { size: 14, weight: 400 })}color:${r.ink}">${md(p.text)}</div></div>`;
    },
  });

  /* ---------- Quit Day offer pieces (QuitDayOffer.swift) ---------- */
  E({
    type: 'paywallOfferHeader', name: 'Offer header', group: 'Paywall', source: OFFER + ' (offer)',
    description: "Xero's 40 pt avatar on an apricot circle at the left, a 44 pt surface close button at the right.",
    props: {
      avatar: { label: 'Avatar', kind: 'art', default: 'xero:calm' },
      avatarGround: { label: 'Avatar circle', kind: 'ground', default: 'apricot' },
      padX: { label: 'Side padding', kind: 'number', options: [16, 20, 24], unit: ' pt', default: 20 },
      padTop: { label: 'Top padding', kind: 'number', options: [0, 4, 8, 12], unit: ' pt', default: 8 },
    },
    render(p, ctx) {
      const r = R4(ctx);
      const g = Lab.ground(p.avatarGround, ctx.dark);
      return `<div style="display:flex;align-items:center;justify-content:space-between;padding:${p.padTop}px ${p.padX}px 0;flex:none">
        <div aria-hidden="true" style="width:40px;height:40px;border-radius:50%;background:${g.bg};overflow:hidden;line-height:0">${Lab.art(p.avatar, { width: 40, height: 40, stage: 1, animate: false })}</div>
        <div role="button" aria-label="Close and continue with the free version" style="width:44px;height:44px;border-radius:50%;background:${r.surface};display:flex;align-items:center;justify-content:center">${Lab.icon('xmark', 16, r.ink)}</div></div>`;
    },
  });

  E({
    type: 'paywallCard', name: 'Reading card', group: 'Paywall', source: 'DayXero/Shared/V4Reading.swift (v4Card)',
    description: 'A raised card on the reading ground: 16 pt padding, radius 18, no outline.',
    props: {
      gap: { label: 'Gap between items', kind: 'number', options: [0, 4, 6, 8, 10, 12], unit: ' pt', default: 8 },
      pad: { label: 'Padding', kind: 'number', options: [12, 14, 16, 20], unit: ' pt', default: 16 },
      radius: { label: 'Corner radius', kind: 'number', options: [14, 18, 20, 24], unit: ' pt', default: 18 },
      outline: { label: 'Outline', kind: 'select', default: 'none', options: [['none', 'None'], ['accent', 'Green 1.5 pt'], ['hairline', 'Hairline']] },
    },
    examples: [{ label: 'Reading', ground: 'reading', props: {}, kids: [['text', { step: 'body', text: 'Quit week and 4 weeks after' }]] }],
    render(p, ctx, kids) {
      const r = R4(ctx);
      const line = p.outline === 'accent' ? `box-shadow:inset 0 0 0 1.5px ${r.accent};` : p.outline === 'hairline' ? `box-shadow:inset 0 0 0 1px ${r.hairline};` : '';
      return `<div style="display:flex;flex-direction:column;gap:${p.gap}px;padding:${p.pad}px;border-radius:${p.radius}px;background:${r.card};${line}">${kids({ groundName: 'reading' })}</div>`;
    },
  });

  E({
    type: 'paywallOfferPlan', name: 'Offer plan card', group: 'Paywall', source: OFFER + ' (planCard)',
    description: 'A 22 pt radio, then (yearly with a trial) the green caption badge, the 19 pt plan name and a 14 pt detail, and the price at the right. Ink 2 pt outline when picked; radius 18.',
    props: {
      badge: { label: 'Badge', kind: 'text', default: '' },
      title: { label: 'Plan name', kind: 'text', default: 'Yearly' },
      detail: { label: 'Detail', kind: 'text', default: '$3.33 a month' },
      price: { label: 'Price', kind: 'text', default: '$39.99/yr' },
      selected: { label: 'State', kind: 'select', default: false, options: [[false, 'Not picked'], [true, 'Picked']] },
      radius: { label: 'Corner radius', kind: 'number', options: [14, 18, 20, 24], unit: ' pt', default: 18, global: true },
    },
    examples: [{ label: 'Yearly picked', ground: 'reading', props: { selected: true, badge: '3 DAYS FREE · SAVE 66%' } }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div role="button" style="display:flex;align-items:flex-start;gap:12px;padding:14px;border-radius:${p.radius}px;background:${r.card};${p.selected ? `box-shadow:inset 0 0 0 2px ${r.ink};` : ''}">
        ${glyph(p.selected ? 'largecircle.fill.circle' : 'circle', 22, p.selected ? r.accent : r.faint)}
        <div style="display:flex;flex-direction:column;gap:4px;min-width:0">${p.badge ? `<div style="${F('caption')}color:${r.accent}">${esc(p.badge)}</div>` : ''}<div style="${F('headline')}color:${r.ink}">${esc(p.title)}</div><div style="${F('footnote')}color:${r.muted}">${esc(p.detail)}</div></div>
        <div style="flex:1;min-width:0"></div><div style="${F('headline')}color:${r.ink};font-variant-numeric:tabular-nums;white-space:nowrap">${esc(p.price)}</div></div>`;
    },
  });

  E({
    type: 'paywallTimeline', name: 'Trial timeline', group: 'Paywall', source: OFFER + ' (timeline)',
    description: 'Today, the reminder and the first charge on a rail: 12 pt dots (green for today) joined by 2 pt lines, 14 pt bold dates over 14 pt muted lines, on a reading card.',
    props: {
      when1: { label: 'First date', kind: 'text', default: 'Today' }, what1: { label: 'First line', kind: 'text', default: 'The full program unlocks. Nothing charged.' },
      when2: { label: 'Second date', kind: 'text', default: 'Sat 7 Nov' }, what2: { label: 'Second line', kind: 'text', default: 'We remind you before the trial ends.' },
      when3: { label: 'Third date', kind: 'text', default: 'Mon 9 Nov' }, what3: { label: 'Third line', kind: 'text', default: '$39.99 unless you cancel.' },
    },
    examples: [{ label: 'Yearly trial', ground: 'reading', props: {} }],
    render(p, ctx) {
      const r = R4(ctx);
      const steps = [[p.when1, p.what1], [p.when2, p.what2], [p.when3, p.what3]];
      const rows = steps.map(([when, what], i) => {
        const first = i === 0, last = i === steps.length - 1;
        return `<div style="display:flex;align-items:stretch;gap:12px">
          <div style="width:12px;flex:none;display:flex;flex-direction:column;align-items:center"><div style="width:2px;height:6px;background:${first ? 'transparent' : r.track}"></div><div style="width:12px;height:12px;border-radius:50%;background:${first ? r.accent : r.track};flex:none"></div><div style="width:2px;flex:1;background:${last ? 'transparent' : r.track}"></div></div>
          <div style="display:flex;flex-direction:column;gap:2px;padding-bottom:${last ? 0 : 12}px;min-width:0"><div style="${F('footnote', { size: 14, weight: 700 })}color:${r.ink}">${esc(when)}</div><div style="${F('footnote')}color:${r.muted}">${esc(what)}</div></div></div>`;
      }).join('');
      return `<div style="display:flex;flex-direction:column;padding:16px;border-radius:18px;background:${r.card}">${rows}</div>`;
    },
  });

  /* ================================================================================================
     Milestone pieces (MilestoneViews.swift, FinaleView.swift)
     ================================================================================================ */
  const CONFETTI = ['#FF7A55', '#2A52DB', '#4A3596', '#0F6E43', '#FF8FB8', '#FFF8EE']; // DX.Fill.confetti
  /** Confetti.draw at time t: 42 pieces, 10 × 6 pt, radius 1.5, each with its own column, speed, delay, sway and turn. */
  function confettiSVG(W, H, t) {
    let s = '';
    for (let i = 0; i < 42; i++) {
      const x = ((i * 97) % 100) / 100 * W;
      const speed = 140 + ((i * 37) % 90);
      const delay = ((i * 13) % 10) / 10 * 0.8;
      const y = -20 + Math.max(0, Math.min(t - delay, 4.2)) * speed;
      if (y >= H + 20) continue;
      const sway = Math.sin((t + i) * 2.2) * 10;
      const angle = (t * 180 + i * 40) % 360;
      s += `<rect x="-5" y="-3" width="10" height="6" rx="1.5" fill="${CONFETTI[i % CONFETTI.length]}" transform="translate(${(x + sway).toFixed(1)} ${y.toFixed(1)}) rotate(${angle.toFixed(1)})"/>`;
    }
    return `<svg width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" style="position:absolute;left:0;top:0;overflow:hidden;pointer-events:none" aria-hidden="true">${s}</svg>`;
  }

  E({
    type: 'milestoneHero', name: 'Celebration hero', group: 'Milestones', source: MV + ' (MilestoneMoment), ' + FIN,
    description: 'HeroScene (a horizon with the paper edge in the ground colour) with the crew standing on it, 6 pt up. Milestones: Xero at hero size (200) and a close button. The finale: Jelli, Xero, Glim (88, 140, 88) and the confetti.',
    props: {
      scene: { label: 'Horizon', kind: 'select', default: 'dawn', options: [['dawn', 'Dawn'], ['dusk', 'Dusk'], ['path', 'Path'], ['sea', 'Sea'], ['night', 'Night']] },
      clarity: { label: 'Sky clarity', kind: 'number', options: [20, 23, 26, 28, 40, 59, 80, 100], default: 100 },
      height: { label: 'Height', kind: 'number', options: [240, 260, 280, 300, 320], unit: ' pt', default: 280 },
      crew: { label: 'Who stands on it', kind: 'select', default: 'xero', options: [['xero', 'Xero alone (milestones)'], ['crew', 'Jelli, Xero and Glim (finale)'], ['none', 'Nobody']] },
      mood: { label: 'Mood', kind: 'select', default: 'cheer', options: [['cheer', 'Cheer (after the spring)'], ['hello', 'Hello (before it)']] },
      stage: { label: 'Crew stage', kind: 'number', options: [1, 2, 3, 4], default: 1 },
      xeroSize: { label: "Xero's size", kind: 'number', options: [140, 160, 200, 240], unit: ' pt', default: 200 },
      confetti: { label: 'Confetti', kind: 'select', default: 'none', options: [['none', 'None'], ['0.6', 'Just started (0.6 s)'], ['1.2', 'Falling (1.2 s, as with Reduce Motion)'], ['2', 'Mostly fallen (2 s)']] },
      close: { label: 'Close button', kind: 'bool', labels: ['Show', 'Hide'], default: false },
      bleed: { label: 'Reaches the screen edges', kind: 'select', default: 20, options: [[20, 'Yes (20 pt past the gutter)'], [0, 'No']] },
    },
    examples: [{ label: 'Day 3', ground: 'sun', props: { clarity: 28, close: true, bleed: 0 } }, { label: 'Finale', ground: 'sun', props: { crew: 'crew', stage: 4, height: 300, confetti: '1.2', bleed: 0 } }],
    render(p, ctx) {
      const W = isLib(ctx) ? 362 : ctx.device.w;
      const H = p.height;
      const hero = Lab.art('extra:hero:' + p.scene, { width: W, height: H, scene: { clarity: p.clarity, edge: ctx.g.bg } });
      const char = (name, size) => `<div style="line-height:0;flex:none">${Lab.art(name + ':' + p.mood, { width: size, height: size, stage: p.stage })}</div>`;
      const crew = p.crew === 'xero' ? char('xero', p.xeroSize) : p.crew === 'crew' ? char('jelli', 88) + char('xero', 140) + char('glim', 88) : '';
      const close = p.close ? `<div role="button" aria-label="Close" style="position:absolute;right:10px;top:50px;width:44px;height:44px;border-radius:50%;background:rgba(255,248,238,0.85);display:flex;align-items:center;justify-content:center">${Lab.icon('xmark', 18, Lab.NAVY)}</div>` : '';
      return `<div style="position:relative;flex:none;height:${H}px;margin:0 -${p.bleed}px;overflow:hidden">
        <div style="position:absolute;inset:0;line-height:0">${hero}</div>
        <div style="position:absolute;left:0;right:0;bottom:6px;display:flex;justify-content:center;align-items:flex-end;gap:4px">${crew}</div>
        ${p.confetti !== 'none' ? confettiSVG(W, H, +p.confetti) : ''}${close}</div>`;
    },
  });

  E({
    type: 'milestoneNumber', name: 'Milestone number', group: 'Milestones', source: MV + ' (MilestoneMoment)',
    description: 'The big number (40 pt, counts up) with its caption (19 pt) on the same baseline, in the ground ink.',
    props: {
      number: { label: 'Number', kind: 'text', default: '3' },
      caption: { label: 'Caption', kind: 'text', default: 'days clear' },
    },
    examples: [{ label: 'Day 3', ground: 'sun', props: {} }],
    render(p, ctx) {
      return `<div style="display:flex;align-items:baseline;justify-content:center;gap:8px;color:${ctx.g.ink}"><div style="${F('display')}font-variant-numeric:tabular-nums">${esc(p.number)}</div><div style="${F('headline')}">${esc(p.caption)}</div></div>`;
    },
  });

  E({
    type: 'milestoneShareButton', name: 'Share button (quiet)', group: 'Milestones', source: MV + ' (MilestoneMoment), ' + FIN,
    description: 'The quiet button with the share icon: 14 pt words in the ground ink, 44 pt tall.',
    props: { label: { label: 'Words', kind: 'text', default: 'Share my card' }, icon: { label: 'Icon', kind: 'bool', labels: ['Show', 'Hide'], default: true } },
    examples: [{ label: 'On sun', ground: 'sun', props: {} }],
    render(p, ctx) {
      return `<div role="button" style="align-self:center;min-height:44px;padding:0 8px;display:flex;align-items:center;justify-content:center;gap:6px;${F('footnote')}color:${ctx.g.ink}">${p.icon ? glyph('square.and.arrow.up', 17, ctx.g.ink) : ''}<span>${esc(p.label)}</span></div>`;
    },
  });

  /** ShareCard laid out at 1080 pt and drawn at `s` (the maker previews it at 15% for Story, 20% for Square). */
  function shareCardHTML(p, s) {
    const dawn = p.look === 'dawn';
    const W = 1080, H = p.format === 'story' ? 1920 : 1080;
    const bg = dawn ? '#FFC38A' : '#4A3596', ink = dawn ? '#1E1A3A' : '#FFF8EE';
    const days = parseInt(p.days, 10) || 1;
    const clarity = days > 0 ? Math.min(100, Math.round(20 + 2.8 * days)) : 20;
    const stage = days < 7 ? 1 : days < 14 ? 2 : days < 28 ? 3 : 4;
    const sky = Lab.art(dawn ? 'scene:horizon' : 'scene:horizon:night', { width: W * s, height: 760 * s, animate: false, scene: { clarity, fit: 'bottom' } });
    const char = Lab.art((dawn ? 'xero:cheer' : 'glim:calm'), { width: 420 * s, height: 420 * s, stage, animate: false });
    // The number has minimumScaleFactor(0.4): it shrinks when the column runs out of room (Square).
    const lh = 1.15, room = H - 200 - 64 * 1.2 - 420 - 72 * 1.2 - (p.extras ? 36 + 46 * 1.3 : 0);
    const num = Math.max(380 * 0.4, Math.min(380, room / lh));
    const fd = Lab.FONT.display, fb = Lab.FONT.body;
    return `<div style="position:relative;width:${W * s}px;height:${H * s}px;background:${bg};overflow:hidden;color:${ink}">
      <div style="position:absolute;left:0;top:0;line-height:0">${sky}</div>
      <div style="position:absolute;inset:0;padding:${100 * s}px;display:flex;flex-direction:column">
        <div style="font-family:${fd};font-weight:800;font-size:${64 * s}px;line-height:1.2">${esc(p.wordmark)}</div>
        <div style="flex:1"></div>
        <div style="align-self:center;line-height:0">${char}</div>
        <div style="font-family:${fd};font-weight:800;font-size:${(num * s).toFixed(2)}px;line-height:${lh};white-space:nowrap">${esc(p.days)}</div>
        <div style="font-family:${fd};font-weight:700;font-size:${72 * s}px;line-height:1.2">${esc(p.caption)}</div>
        ${p.extras ? `<div style="font-family:${fb};font-weight:500;font-size:${46 * s}px;line-height:1.3;opacity:.85;margin-top:${36 * s}px">${esc(p.extras)}</div>` : ''}
      </div></div>`;
  }

  E({
    type: 'milestoneShareCard', name: 'Share card', group: 'Milestones', source: MV + ' (ShareCard, ShareCardMaker)',
    description: 'The card that gets shared, drawn at 1080 pt wide (Story 1080 × 1920, Square 1080 × 1080) and previewed small with radius 18 and a soft shadow. Dawn: Xero cheering on apricot. Night: Glim on violet. The wordmark always; no name or photo.',
    props: {
      days: { label: 'Days', kind: 'text', default: '3' },
      caption: { label: 'Caption', kind: 'text', default: 'days nicotine-free' },
      extras: { label: 'Extra numbers', kind: 'text', default: '' },
      wordmark: { label: 'Wordmark', kind: 'text', default: 'DayXero' },
      look: { label: 'Look', kind: 'select', default: 'dawn', options: [['dawn', 'Dawn (apricot, Xero)'], ['night', 'Night (violet, Glim)']] },
      format: { label: 'Format', kind: 'select', default: 'story', options: [['story', 'Story (9:16)'], ['square', 'Square']] },
      scale: { label: 'Preview size', kind: 'select', default: 'app', options: [['app', 'As in the app (15% story, 20% square)'], ['0.25', '25%'], ['0.3', '30%']] },
    },
    examples: [{ label: 'Story, dawn', ground: 'reading', props: {} }, { label: 'Square, night', ground: 'reading', props: { look: 'night', format: 'square' } }],
    render(p) {
      const s = p.scale === 'app' ? (p.format === 'story' ? 0.15 : 0.2) : +p.scale;
      return `<div aria-label="Card preview: ${esc(p.days)} days nicotine-free" style="align-self:center;flex:none;border-radius:18px;overflow:hidden;box-shadow:0 10px 36px rgba(0,0,0,.18);line-height:normal">${shareCardHTML(p, s)}</div>`;
    },
  });

  E({
    type: 'milestoneSegment', name: 'Two-way picker', group: 'Milestones', source: MV + ' (ShareCardMaker.picker)',
    description: 'Two 12 pt options in a surface capsule (3 pt inset); the picked one sits in an ink capsule.',
    props: {
      left: { label: 'First option', kind: 'text', default: 'Story' },
      right: { label: 'Second option', kind: 'text', default: 'Square' },
      selected: { label: 'Picked', kind: 'select', default: 'left', options: [['left', 'First'], ['right', 'Second']] },
    },
    examples: [{ label: 'Story', ground: 'reading', props: {} }],
    render(p, ctx) {
      const r = R4(ctx);
      const opt = (label, on) => `<div role="button" style="padding:6px 12px;border-radius:999px;${F('caption', { size: 12, weight: 600 })}${on ? `background:${r.ink};color:${r.onInk};` : `color:${r.muted};`}">${esc(label)}</div>`;
      return `<div style="display:flex;padding:3px;border-radius:999px;background:${r.surface};flex:none">${opt(p.left, p.selected === 'left')}${opt(p.right, p.selected === 'right')}</div>`;
    },
  });

  E({
    type: 'milestoneToggleRow', name: 'Card number switch', group: 'Milestones', source: MV + ' (ShareCardMaker.toggleRow)',
    description: 'A 14 pt semibold name and its value in muted 14 pt, with a green switch, on a raised card (radius 18, hairline). Days clear is always on and can\'t be switched off.',
    props: {
      title: { label: 'Name', kind: 'text', default: 'Money kept' },
      detail: { label: 'Value', kind: 'text', default: '' },
      on: { label: 'Switch', kind: 'select', default: false, options: [[true, 'On'], [false, 'Off']] },
      locked: { label: 'Can be changed', kind: 'select', default: false, options: [[false, 'Yes'], [true, 'No (always on, dimmed)']] },
    },
    examples: [{ label: 'Off', ground: 'reading', props: { detail: '$15.65' } }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="display:flex;align-items:center;gap:12px;padding:8px 12px;border-radius:18px;background:${r.card};box-shadow:inset 0 0 0 1px ${r.hairline}">
        <div style="flex:1;min-width:0;display:flex;align-items:baseline;gap:6px;flex-wrap:wrap"><div style="${F('footnote', { size: 14, weight: 600 })}color:${r.ink}">${esc(p.title)}</div>${p.detail ? `<div style="${F('footnote')}color:${r.muted}">${esc(p.detail)}</div>` : ''}</div>
        <div role="switch" aria-checked="${p.on}" style="width:51px;height:31px;border-radius:16px;background:${p.on ? r.accent : r.track};position:relative;flex:none;opacity:${p.locked ? 0.5 : 1}"><div style="position:absolute;top:2px;${p.on ? 'right:2px' : 'left:2px'};width:27px;height:27px;border-radius:50%;background:#fff;box-shadow:0 2px 4px rgba(0,0,0,.2)"></div></div></div>`;
    },
  });

  E({
    type: 'milestoneShareHeader', name: 'Card maker header', group: 'Milestones', source: MV + ' (ShareCardMaker)',
    description: 'A 44 pt surface close button, the title in small capitals in the middle, and a 44 pt space to balance it.',
    props: { title: { label: 'Title', kind: 'text', default: 'Share card' } },
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="display:flex;align-items:center;justify-content:space-between;flex:none"><div role="button" aria-label="Close" style="width:44px;height:44px;border-radius:50%;background:${r.surface};display:flex;align-items:center;justify-content:center;flex:none">${Lab.icon('xmark', 16, r.ink)}</div><div style="${F('caption')}color:${r.muted};text-transform:uppercase">${esc(p.title)}</div><div style="width:44px;flex:none"></div></div>`;
    },
  });

  /* ================================================================================================
     Data: plans (MockStore in Subscriptions.swift = tokens.json "pricing"), dates, milestones.
     ================================================================================================ */
  const PRICE = { annual: '$39.99', monthly: '$9.99', lifetime: '$79.99', perMonth: '$3.33' };
  const TRIAL = 3;
  const SAVE = Math.floor((1 - 39.99 / (9.99 * 12)) * 100); // annualSavingPercent: 66
  const BADGE = `${TRIAL} DAYS FREE · SAVE ${SAVE}%`;
  const CTA = { annual: `Start my ${TRIAL}-day free trial`, monthly: `Subscribe for ${PRICE.monthly} a month`, lifetime: `Buy lifetime for ${PRICE.lifetime}` };
  const CTA_ALTS = Object.values(CTA).concat([`Subscribe for ${PRICE.annual} a year`, 'Loading prices…']);
  const NOTICES = [
    "No purchases found. Make sure you're signed in with the Apple ID you bought with.",
    "The purchase didn't go through. You haven't been charged.",
    "Couldn't reach the App Store. Check your connection and try again.",
  ];

  const DAYS = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const MONTHS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const QUIT = Date.UTC(2026, 10, 6);
  const dayFrom = (base, n) => new Date(base + n * 86400000);
  /** .dateTime.weekday(.abbreviated).day().month(.abbreviated) in en_GB: "Fri 6 Nov". */
  const fmt = (d) => `${DAYS[d.getUTCDay()]} ${d.getUTCDate()} ${MONTHS[d.getUTCMonth()]}`;
  const money = (v) => '$' + Math.floor(v).toString().replace(/\B(?=(\d{3})+(?!\d))/g, ',') + '.' + String(Math.round((v % 1) * 100)).padStart(2, '0');
  const thousands = (n) => String(n).replace(/\B(?=(\d{3})+(?!\d))/g, ',');

  /* When each paywall is seen, and when the 3-day trial would end (trialEndDate = now + 3 days). */
  const WHEN = {
    firstRun: { today: Date.UTC(2026, 9, 30) },   // the first-run paywall right after onboarding (Sam joined Fri 30 Oct)
    plans: { today: Date.UTC(2026, 10, 7) },      // "See all plans" from the upgrade sheet when Day 1 opens, Sat 7 Nov
    offer: { today: QUIT },                        // the Quit Day offer after the Day Xero session, Fri 6 Nov
  };
  Object.values(WHEN).forEach((w) => { w.end = fmt(dayFrom(w.today, TRIAL)); w.remind = fmt(dayFrom(w.today, TRIAL - 2)); });

  /* Milestone (MilestoneMoments.swift). reached = days clear on which it's reached. */
  const SOURCE = { 'cdc-cotinine': 'Source: CDC', smokefree: 'Source: smokefree.gov', 'smokefree-mood': 'Source: smokefree.gov' };
  const MILESTONES = [
    { id: 'quitDay', number: 1, reached: 1, title: 'Quit Day', line: "Today's the day. You've prepared for this.", caption: 'Quit Day' },
    { id: '1', number: 1, reached: 2, title: 'Your first full day', line: "One whole day without nicotine. That's real.", caption: 'full day clear' },
    { id: '3', number: 3, reached: 3, title: 'Three days clear', line: 'By now most of the nicotine has left your body.', caption: 'days clear', source: 'cdc-cotinine' },
    { id: '7', number: 7, reached: 7, title: 'One week clear', line: 'The first week is the hardest for most people. You did it.', caption: 'days clear', source: 'smokefree' },
    { id: '14', number: 14, reached: 14, title: 'Two weeks clear', line: 'Mood changes from withdrawal usually ease around now.', caption: 'days clear', source: 'smokefree-mood' },
    { id: '30', number: 30, reached: 30, title: 'One month clear', line: 'A whole month. Cravings come less often as the weeks go by.', caption: 'days clear', source: 'smokefree' },
    { id: '60', number: 60, reached: 60, title: 'Two months clear', line: 'Two months of choosing this, day after day.', caption: 'days clear' },
    { id: '90', number: 90, reached: 90, title: 'Three months clear', line: 'Three months. This is becoming your normal.', caption: 'days clear' },
    { id: '100', number: 100, reached: 100, title: '100 days clear', line: 'Triple digits.', caption: 'days clear' },
    { id: '180', number: 180, reached: 180, title: 'Six months clear', line: "Half a year. Look how far you've come.", caption: 'days clear' },
    { id: '365', number: 365, reached: 365, title: 'One year clear', line: 'A full year nicotine-free.', caption: 'days clear' },
  ];
  /* Sam at 09:40 on the day (codeTrue): Quit Day starts 04:00, 12 cigarettes and $7 a day. */
  MILESTONES.forEach((m) => {
    const elapsed = (m.reached - 1) + 340 / 1440;
    m.date = fmt(dayFrom(QUIT, m.reached - 1));
    m.cigs = thousands(Math.floor(12 * elapsed + 1e-9));
    m.kept = money(Math.floor(700 * elapsed + 1e-9) / 100);
    m.clarity = Math.min(100, Math.round(20 + 2.8 * m.reached));
    m.stage = m.reached < 7 ? 1 : m.reached < 14 ? 2 : m.reached < 28 ? 3 : 4;
  });
  const COUNTER_ALTS = ['puffs not taken', 'pouches not used'];

  /* ================================================================================================
     Screens: the paywall
     ================================================================================================ */
  const PLAN_STATES = [
    { id: 'annual', label: 'Yearly picked', plan: 'annual' },
    { id: 'monthly', label: 'Monthly picked', plan: 'monthly' },
    { id: 'lifetime', label: 'Lifetime picked', plan: 'lifetime' },
  ];
  const AFTER_STATES = [
    { id: 'loading', label: 'Loading prices' },
    { id: 'notice', label: 'Restore found nothing (banner)', plan: 'annual' },
    { id: 'unlocked', label: 'Unlocked (trial started)' },
    { id: 'pending', label: 'Waiting for approval' },
    { id: 'failed', label: "Couldn't reach the App Store" },
  ];

  /** PaywallMessage: the full-screen "unlocked" and "waiting" confirmations. */
  function paywallMessage(h, kind, w, firstRun) {
    const unlocked = kind === 'unlocked';
    const msg = `Your free trial runs until ${w.end}. We'll remind you 2 days before it ends.`;
    return h('paywallPage', 'message', { padX: 20, padBottom: 8, gap: 12 }, [
      h('spacer', 'message-top', { flex: true, size: 0 }),
      h('paywallIconDisc', 'message-icon', unlocked ? { icon: 'checkmark', tint: 'sage', glyph: 28 } : { icon: 'clock', tint: 'accent', glyph: 28 }),
      unlocked
        ? h('text', 'message-title', { step: 'title', align: 'center', text: "You're all set, Sam" })
        : h('text', 'message-title', { step: 'title', align: 'center', text: 'Waiting for approval' }),
      unlocked
        ? h('text', 'message-line', { step: 'footnote', tone: 'muted', align: 'center', text: msg,
          alts: { text: [`Your free trial runs until ${w.end}.`, `Your free trial runs until ${w.end}. We'll remind you the day before it ends.`, "The full program is unlocked. Let's get you ready for Quit Day."] } })
        : h('text', 'message-line', { step: 'footnote', tone: 'muted', align: 'center', text: "Your purchase needs approval (for example, Ask to Buy). We'll unlock everything as soon as it goes through." }),
      h('spacer', 'message-bottom', { flex: true, size: 0 }),
      h('button', 'message-button', { label: unlocked ? 'Start prep day 1' : 'Start Day 1 meanwhile' }),
    ]);
  }

  /** The failed state: header, V4StateView(.error) in the middle, "Continue with free" at the bottom. */
  function paywallFailed(h) {
    return h('paywallPage', 'failed', { padBottom: 8 }, [
      h('paywallHeader', 'header', {}),
      h('spacer', 'failed-top', { flex: true, size: 0 }),
      h('stack', 'failed-state', { padX: 20, padTop: 20, padBottom: 20, gap: 12, align: 'center', textAlign: 'center' }, [
        h('paywallIconDisc', 'failed-icon', { icon: 'exclamationmark.circle', tint: 'amber', size: 64, glyph: 26 }),
        h('text', 'failed-title', { step: 'title', align: 'center', text: "Couldn't reach the App Store" }),
        h('text', 'failed-line', { step: 'body', tone: 'muted', align: 'center', text: 'Check your connection and try again. Day 1, your counter and Craving SOS work without it.' }),
        h('stack', 'failed-retry-wrap', { padTop: 6, style: 'align-self:stretch' }, [h('button', 'failed-retry', { label: 'Try again' })]),
      ]),
      h('spacer', 'failed-bottom', { flex: true, size: 0 }),
      h('button', 'continue-free', { label: 'Continue with free', kind: 'quiet' }),
    ]);
  }

  const termsNode = (h, plan) => h('paywallLinks', 'terms', { cancel: plan === 'lifetime' ? '' : 'Cancel in Settings › Apple ID › Subscriptions.', alts: { cancel: ['Cancel in Settings › Apple ID › Subscriptions.'] } });

  /* ---------- First-run paywall (S22) ---------- */
  Lab.screen({
    id: 'paywall', name: 'Paywall · first run', area: 'Paywall', source: PV + ', ' + PM, ground: 'reading',
    note: 'The one-time paywall right after onboarding (FirstRunPaywall, when Superwall falls back to the app\'s own). Prices are the MockStore / tokens.json plans: $39.99 a year with a 3-day trial, $9.99 a month, $79.99 once; yearly saves 66% on twelve months of monthly. ' +
      'Sam has no saved obstacles here, so the title uses his triggers (Coffee, Stress); the alternatives are the obstacle and no-focus versions. His pack price is unknown, so the yearly card shows "$3.33/mo" alone; with a pack of $6.66 or more it adds "Less than half a pack a month" (alternatives). ' +
      'The trial starts when he buys (now + 3 days), so bought on Fri 30 Oct it runs to Mon 2 Nov: the code does not wait for Quit Day as decision 15 says. ' +
      'The banner\'s cross is 11 pt in the app, drawn at 12 here. "Purchasing" (a spinner in the button) is not drawn.',
    states: PLAN_STATES.concat([{ id: 'arriving', label: 'First 3 seconds · close hidden', plan: 'annual' }], AFTER_STATES),
    build(h, state) {
      const w = WHEN.firstRun;
      if (state.id === 'unlocked' || state.id === 'pending') return paywallMessage(h, state.id, w, true);
      if (state.id === 'failed') return paywallFailed(h);
      const plan = state.plan || null;
      const loading = state.id === 'loading';
      const due = plan === 'annual'
        ? h('paywallRichLine', 'charge', { lead: '$0 due today. Cancel any time in Settings.', size: 12 })
        : plan === 'monthly'
          ? h('paywallRichLine', 'charge', { bold: `${PRICE.monthly} today`, trail: ', then every month until you cancel.' })
          : plan === 'lifetime'
            ? h('paywallRichLine', 'charge', { bold: `${PRICE.lifetime} once.`, trail: ' No subscription, nothing to cancel.' })
            : null;
      return h('paywallPage', 'page', { padBottom: 0 }, [
        h('paywallHeader', 'header', { close: state.id !== 'arriving' }),
        h('paywallScroll', 'scroll', { gap: 12, padX: 16, padTop: 12, padBottom: 24 }, [
          h('text', 'kicker', { step: 'caption', tone: 'green', text: 'Custom plan ready · Fri 6 Nov' }),
          h('text', 'title', { step: 'title', text: 'Beat coffee and stress on Fri 6 Nov',
            alts: { text: ['Beat stress and cravings on Fri 6 Nov', 'Beat stress on Fri 6 Nov', 'Quit on Fri 6 Nov without the cold-turkey shock'] } }),
          h('stack', 'included', { gap: 8, padTop: 4, padBottom: 4 }, [
            h('paywallIncluded', 'included-1', { text: 'Complete prep, Quit week and 4 weeks after' }),
            h('paywallIncluded', 'included-2', { text: 'Craving SOS any time, plus your dual-use tracker', alts: { text: ['Craving SOS any time, plus your daily tracker'] } }),
            h('paywallIncluded', 'included-3', { text: 'NRT step-down planner for patches and gum' }),
          ]),
          h('paywallTrustCard', 'trust', {}),
          loading
            ? h('row', 'plan-cards', { gap: 12 }, [h('paywallSkeleton', 'plan-skeleton-1', { height: 132, radius: 22, grow: true }), h('paywallSkeleton', 'plan-skeleton-2', { height: 132, radius: 22, grow: true })])
            : h('row', 'plan-cards', { gap: 12, align: 'flex-end', style: 'padding-top:12px' }, [
              h('paywallPlanCard', 'plan-annual', { plan: 'annual', title: 'Yearly', price: `${PRICE.annual}/yr`, detail: `${PRICE.perMonth}/mo`, badge: BADGE, selected: plan === 'annual',
                alts: { detail: [`${PRICE.perMonth}/mo · Less than half a pack a month`, `${PRICE.perMonth}/mo · Less than a pack a month`, 'Billed yearly'], badge: [`${TRIAL} DAYS FREE`] } }),
              h('paywallPlanCard', 'plan-monthly', { plan: 'monthly', title: 'Monthly', price: `${PRICE.monthly}/mo`, detail: 'Billed today · Cancel anytime', selected: plan === 'monthly',
                alts: { detail: [`${TRIAL} days free · Cancel anytime`] } }),
            ]),
          loading ? null : h('paywallPlanRow', 'plan-lifetime', { title: 'Lifetime', detail: 'Pay once', price: PRICE.lifetime, period: 'one time', selected: plan === 'lifetime' }),
        ]),
        h('paywallFooter', 'footer', { gap: 8, padX: 16, horizon: 'path' }, [
          h('button', 'cta', { label: loading ? 'Loading prices…' : CTA[plan], disabled: loading, alts: { label: CTA_ALTS } }),
          due,
          termsNode(h, plan),
          h('spacer', 'footer-bottom', { size: 8 }),
        ]),
      ]);
    },
    overlay(h, state) {
      return state.id === 'notice' ? h('paywallNotice', 'notice', { padX: 12, alts: { text: NOTICES.slice(1) } }) : null;
    },
  });

  /* ---------- The plain paywall (Program, Home, Settings, "See all plans") ---------- */
  Lab.screen({
    id: 'paywall-plans', name: 'Paywall · all plans', area: 'Paywall', source: PV + ', ' + PM, ground: 'reading',
    note: 'The plain paywall, full screen, from a locked day ("See all plans" on the upgrade sheet), Home and Settings. Sam opens it on Sat 7 Nov when Day 1 opens, so a 3-day trial bought then runs to Tue 10 Nov and the reminder comes 2 days before. ' +
      'Same plans as the first-run paywall; with a trial the yearly row\'s badge carries the saving. From Settings the app passes no name and today as the Quit Day, so the title reads ", your plan is ready" (see the reply). "Purchasing" (a spinner in the button) is not drawn.',
    states: PLAN_STATES.concat(AFTER_STATES),
    build(h, state) {
      const w = WHEN.plans;
      if (state.id === 'unlocked' || state.id === 'pending') return paywallMessage(h, state.id, w, false);
      if (state.id === 'failed') return paywallFailed(h);
      const plan = state.plan || null;
      const loading = state.id === 'loading';
      const charge = plan === 'annual'
        ? h('paywallRichLine', 'charge', { lead: 'Free until ', bold: w.end, trail: `, then ${PRICE.annual} a year.`, second: "We'll remind you 2 days before.", alts: { second: ["We'll remind you the day before.", ''] } })
        : plan === 'monthly'
          ? h('paywallRichLine', 'charge', { bold: `${PRICE.monthly} today`, trail: ', then every month until you cancel.' })
          : plan === 'lifetime'
            ? h('paywallRichLine', 'charge', { bold: `${PRICE.lifetime} once.`, trail: ' No subscription, nothing to cancel.' })
            : null;
      const rows = loading
        ? [1, 2, 3].map((i) => h('paywallSkeleton', 'plan-skeleton-' + i, { height: 60, radius: 20 }))
        : [
          h('paywallPlanRow', 'plan-annual', { title: 'Yearly', detail: `${PRICE.perMonth} a month`, price: PRICE.annual, period: 'per year', badge: BADGE, selected: plan === 'annual',
            alts: { detail: [`${PRICE.perMonth} a month · save ${SAVE}%`, 'Billed yearly'], badge: [`${TRIAL} DAYS FREE`] } }),
          h('paywallPlanRow', 'plan-monthly', { title: 'Monthly', detail: 'Cancel anytime', price: PRICE.monthly, period: 'per month', selected: plan === 'monthly' }),
          h('paywallPlanRow', 'plan-lifetime', { title: 'Lifetime', detail: 'Pay once', price: PRICE.lifetime, period: 'one time', selected: plan === 'lifetime' }),
        ];
      return h('paywallPage', 'page', { padBottom: 8 }, [
        h('paywallHeader', 'header', {}),
        h('paywallScroll', 'scroll', { gap: 8, padX: 16, padTop: 16, padBottom: 0 }, [
          h('text', 'title', { step: 'title', text: 'Sam, your plan is ready' }),
          h('text', 'subtitle', { step: 'footnote', tone: 'muted', text: 'Everything for your Fri 6 Nov Quit Day.' }),
          h('stack', 'included', { gap: 7, padTop: 12, padBottom: 12 }, [
            h('paywallIncluded', 'included-1', { text: 'All of prep, Quit week and 4 weeks after' }),
            h('paywallIncluded', 'included-2', { text: 'Insights on your triggers' }),
            h('paywallIncluded', 'included-3', { text: 'NRT planner, health timeline, share cards' }),
          ]),
          h('stack', 'plans', { gap: 8, padTop: 8 }, rows),
        ]),
        h('paywallFooter', 'footer', { gap: 8, padX: 16 }, [
          charge,
          h('button', 'cta', { label: loading ? 'Loading prices…' : CTA[plan], disabled: loading, alts: { label: CTA_ALTS } }),
          termsNode(h, plan),
        ]),
      ]);
    },
    overlay(h, state) {
      return state.id === 'notice' ? h('paywallNotice', 'notice', { padX: 12, alts: { text: NOTICES.slice(1) } }) : null;
    },
  });

  /* ---------- How billing works (BillingSheet) ---------- */
  Lab.screen({
    id: 'paywall-billing', name: 'How billing works', area: 'Paywall', source: PV + ' (BillingSheet)', ground: 'reading',
    note: 'A sheet from "How billing works" on the paywall and the Quit Day offer, medium or large (two detents, so the grabber shows). The paywall behind it is drawn as a plain dimmed ground. "Manage subscription" opens the App Store\'s own subscriptions sheet.',
    statusInk: (state) => (state.id === 'large' ? Lab.CREAM : undefined),
    states: [{ id: 'medium', label: 'Medium (half height)' }, { id: 'large', label: 'Large' }],
    build(h) { return h('stack', 'behind', {}); },
    overlay(h, state) {
      return h('paywallSheet', 'sheet', { detent: state.id, grabber: true }, [
        h('paywallScroll', 'scroll', { gap: 8, padX: 20, padTop: 20, padBottom: 20 }, [
          h('text', 'title', { step: 'title', text: 'How billing works' }),
          h('text', 'subtitle', { step: 'footnote', tone: 'muted', text: 'Plain and simple. Apple handles every payment.' }),
          h('stack', 'cancel-wrap', { padTop: 16 }, [h('text', 'cancel-heading', { step: 'caption', tone: 'muted', text: 'Cancel in two taps' })]),
          h('paywallBillingStep', 'step-1', { number: '1', text: 'Tap **Manage subscription** below' }),
          h('paywallBillingStep', 'step-2', { number: '2', text: 'Tap **Cancel subscription**' }),
          h('stack', 'trial-wrap', { padTop: 12 }, [h('text', 'trial-heading', { step: 'caption', tone: 'muted', text: 'Free trial' })]),
          h('text', 'trial-line', { step: 'footnote', tone: 'muted', text: "Cancel any time before it ends and you pay nothing. We'll remind you 2 days before." }),
          h('stack', 'refunds-wrap', { padTop: 12 }, [h('text', 'refunds-heading', { step: 'caption', tone: 'muted', text: 'Refunds' })]),
          h('text', 'refunds-line', { step: 'footnote', tone: 'muted', text: 'Refunds go through Apple. You can request one at reportaproblem.apple.com.' }),
          h('stack', 'manage-wrap', { padTop: 16 }, [h('paywallSecondaryButton', 'manage', { label: 'Manage subscription' })]),
        ]),
      ]);
    },
  });

  /* ---------- Upgrade sheet (S3.5) ---------- */
  Lab.screen({
    id: 'upgrade', name: 'Upgrade sheet', area: 'Paywall', source: UPG, ground: 'mint',
    note: 'A medium sheet (no grabber) when Sam taps the next locked day without the full program: from the Program tab, the Today card or Home. Here Day 1, "Look after the basics", on Sat 7 Nov after closing the Quit Day offer, so a 3-day trial runs to Tue 10 Nov. ' +
      'The screen behind (Program) is drawn as a plain dimmed ground. The content is centred in the sheet. The line "You finished Day 1." is fixed copy in the app, though the free part now ends after Day Xero (see the reply).',
    states: [{ id: 'trial', label: 'Yearly with a trial' }, { id: 'loading', label: 'Loading prices' }, { id: 'failed', label: "Couldn't reach the App Store" }],
    build(h) { return h('stack', 'behind', {}); },
    overlay(h, state) {
      const w = WHEN.plans;
      let middle;
      if (state.id === 'trial') {
        middle = [
          h('stack', 'plan-wrap', { padTop: 12 }, [
            h('paywallCard', 'plan', { gap: 2, pad: 14, radius: 20, outline: 'accent' }, [
              h('text', 'plan-title', { step: 'body', size: 16, weight: 600, text: 'Yearly', alts: { text: ['Full program'] } }),
              h('text', 'plan-line', { step: 'footnote', tone: 'muted', text: `Free until ${w.end}, then ${PRICE.annual} a year`, alts: { text: [PRICE.annual] } }),
            ]),
          ]),
          h('stack', 'cta-wrap', { padTop: 12 }, [h('button', 'cta', { label: `Start my free ${TRIAL} days`, alts: { label: [`Unlock for ${PRICE.annual}`] } })]),
        ];
      } else if (state.id === 'failed') {
        middle = [h('text', 'failed-line', { step: 'footnote', tone: 'muted', text: "Couldn't reach the App Store. Check your connection and try again." })];
      } else {
        middle = [h('stack', 'spinner-wrap', { padTop: 20, padBottom: 20 }, [h('paywallSpinner', 'spinner', { minHeight: 44 })])];
      }
      return h('paywallSheet', 'sheet', { detent: 'medium', grabber: false, centre: true }, [
        h('stack', 'body', { gap: 8, padX: 20, padTop: 20, padBottom: 20 }, [
          h('text', 'title', { step: 'title', text: 'Keep going with Look after the basics', alts: { text: ['Keep going with The noisy passengers', 'Keep going with Lower the bar'] } }),
          h('text', 'subtitle', { step: 'footnote', tone: 'muted', text: 'You finished Day 1. The full program takes you through Quit Day and the four weeks after.' }),
          ...middle,
          h('button', 'all-plans', { label: 'See all plans', kind: 'quiet' }),
        ]),
      ]);
    },
  });

  /* ---------- Quit Day offer (Q3) ---------- */
  function offerMessage(h, s) {
    const m = {
      unlocked: ['checkmark', "You're all set", `Your free trial runs until ${WHEN.offer.end}. Week 1 is ready when it opens.`, 'Back to my day', ['The full program is unlocked. Week 1 is ready when it opens.']],
      pending: ['clock', 'Waiting for approval', "Your purchase needs approval (for example, Ask to Buy). We'll unlock everything as soon as it goes through.", 'Back to my day', []],
      failed: ['wifi.slash', "Couldn't load the plans", 'Check your connection and try again. Everything free keeps working.', 'Not now', []],
    }[s];
    return h('paywallPage', 'message', { padX: 22, padBottom: 8, gap: 14 }, [
      h('spacer', 'message-top', { flex: true, size: 0 }),
      h('paywallIconDisc', 'message-icon', { icon: m[0], tint: 'accent', glyph: 30 }),
      h('text', 'message-title', { step: 'large', align: 'center', text: m[1] }),
      h('text', 'message-line', { step: 'body', tone: 'muted', align: 'center', text: m[2], alts: { text: m[4] } }),
      h('spacer', 'message-bottom', { flex: true, size: 0 }),
      h('button', 'message-button', { label: m[3] }),
    ]);
  }

  Lab.screen({
    id: 'offer', name: 'Quit Day offer', area: 'Paywall', source: OFFER + ', ' + PM, ground: 'reading',
    note: 'Shown once after the Day Xero session on Quit Day (Fri 6 Nov) to anyone without the full program. Day 1, "Look after the basics", opens tomorrow, so the headline is "Week 1 starts tomorrow"; the alternatives are the other ProgramUnlock states. ' +
      'A 3-day trial bought now ends Mon 9 Nov; the reminder comes 2 days before (Sat 7 Nov). While the prices load there is no trial yet, so the line ends "Unlock the full program to keep going." The cards arrive one after another (dxArrive); they are drawn settled.',
    states: PLAN_STATES.concat([
      { id: 'loading', label: 'Loading prices' },
      { id: 'notice', label: 'Restore found nothing (banner)', plan: 'annual' },
      { id: 'unlocked', label: 'Unlocked (trial started)' },
      { id: 'pending', label: 'Waiting for approval' },
      { id: 'failed', label: "Couldn't load the plans" },
    ]),
    build(h, state) {
      if (['unlocked', 'pending', 'failed'].includes(state.id)) return offerMessage(h, state.id);
      const plan = state.plan || null;
      const loading = state.id === 'loading';
      const w = WHEN.offer;
      const opens = `Day 1, Look after the basics, opens on ${fmt(dayFrom(QUIT, 1))}.`;
      const offer = loading ? 'Unlock the full program to keep going.' : `Try the full program free for ${TRIAL} days.`;
      const plans = loading
        ? [h('paywallSpinner', 'plans-loading', { minHeight: 120 })]
        : [h('stack', 'plans', { gap: 8 }, [
          h('paywallOfferPlan', 'plan-annual', { badge: BADGE, title: 'Yearly', detail: `${PRICE.perMonth} a month`, price: `${PRICE.annual}/yr`, selected: plan === 'annual', alts: { badge: [`${TRIAL} DAYS FREE`] } }),
          h('paywallOfferPlan', 'plan-monthly', { title: 'Monthly', detail: 'Billed today · Cancel anytime', price: `${PRICE.monthly}/mo`, selected: plan === 'monthly' }),
          h('paywallTextLink', 'plan-lifetime', { text: `Pay once · ${PRICE.lifetime}`, weight: plan === 'lifetime' ? 700 : 600, underline: plan === 'lifetime' }),
        ])];
      return h('paywallPage', 'page', { padBottom: 8 }, [
        h('paywallOfferHeader', 'header', {}),
        h('paywallScroll', 'scroll', { gap: 12, padX: 20, padTop: 12, padBottom: 16 }, [
          h('text', 'headline', { step: 'large', text: 'Week 1 starts tomorrow', alts: { text: ['Week 1 is ready'] } }),
          h('text', 'line', { step: 'body', tone: 'muted', text: `${opens} ${offer}`,
            alts: { text: [`Day 1, Look after the basics, is ready now. Try the full program free for ${TRIAL} days.`, `Day 1, Look after the basics, opens soon. Try the full program free for ${TRIAL} days.`, `${opens} Unlock the full program to keep going.`] } }),
          h('paywallCard', 'included', { gap: 8 }, [
            h('paywallIncluded', 'included-1', { style: 'offer', text: 'Quit week and 4 weeks after' }),
            h('paywallIncluded', 'included-2', { style: 'offer', text: 'Insights on your triggers' }),
            h('paywallIncluded', 'included-3', { style: 'offer', text: 'NRT planner, health timeline, share cards' }),
            h('stack', 'always-free-wrap', { padTop: 2 }, [h('text', 'always-free', { step: 'footnote', tone: 'muted', text: 'Always free: your counter and Craving SOS.' })]),
          ]),
          ...plans,
          plan === 'annual' ? h('paywallTimeline', 'timeline', { when1: 'Today', what1: 'The full program unlocks. Nothing charged.', when2: w.remind, what2: 'We remind you before the trial ends.', when3: w.end, what3: `${PRICE.annual} unless you cancel.` }) : null,
        ]),
        h('paywallFooter', 'footer', { gap: 4, padX: 22 }, [
          h('button', 'cta', { label: loading ? 'Loading prices…' : CTA[plan], disabled: loading, alts: { label: CTA_ALTS } }),
          h('button', 'not-now', { label: 'Not now', kind: 'quiet' }),
          h('paywallLinks', 'links', { cancel: '', link1: 'Restore purchases', link2: 'How billing works', link3: 'Terms', style: 'caption' }),
        ]),
      ]);
    },
    overlay(h, state) {
      return state.id === 'notice' ? h('paywallNotice', 'notice', { style: 'navy', padX: 20, alts: { text: NOTICES.slice(1) } }) : null;
    },
  });

  /* ================================================================================================
     Screens: milestones
     ================================================================================================ */
  const altsOf = (key) => MILESTONES.map((m) => m[key]).filter((v, i, a) => v && a.indexOf(v) === i);

  Lab.screen({
    id: 'milestone', name: 'Milestone moment', area: 'Milestones', source: MV + ' (MilestoneMoment), ' + MM, ground: 'sun', fullBleed: true,
    note: 'Full screen on the sun ground, from Home on a milestone day (and from Progress for one already reached). The milestone days are codeTrue: Quit Day, then 1, 3, 7, 14, 30, 60, 90, 100, 180 and 365 days clear; "Your first full day" comes the day after Quit Day. ' +
      'Numbers are Sam at 09:40 on that day (12 cigarettes and $7 a day from Fri 6 Nov 04:00). The sky clears and Xero grows with days clear (stage 1 under 7 days, 2 under 14, 3 under 28, then 4). Xero springs in from 85% and the number counts up; they are drawn settled. No tiles on Quit Day.',
    states: MILESTONES.map((m) => ({ id: m.id === 'quitDay' ? 'quit-day' : 'day-' + m.id, label: `${m.title} · ${m.date}`, m })),
    build(h, state) {
      const m = state.m || MILESTONES[2];
      return h('paywallPage', 'page', { padBottom: 8 }, [
        h('paywallScroll', 'scroll', { gap: 10, padX: 20, padTop: 0, padBottom: 16, align: 'center' }, [
          h('milestoneHero', 'hero', { scene: 'dawn', clarity: m.clarity, height: 280, crew: 'xero', mood: 'cheer', stage: m.stage, close: true }),
          h('milestoneNumber', 'number', { number: String(m.number), caption: m.caption, alts: { caption: altsOf('caption') } }),
          h('text', 'title', { step: 'title', align: 'center', text: m.title, alts: { text: altsOf('title') } }),
          h('text', 'line', { step: 'body', tone: 'muted', align: 'center', text: m.line, alts: { text: altsOf('line') } }),
          m.source ? h('paywallTextLink', 'source', { text: SOURCE[m.source], step: 'caption', weight: 700, underline: true, tone: 'muted', height: 0, alts: { text: ['Source: CDC', 'Source: smokefree.gov'] } }) : null,
          m.id !== 'quitDay' ? h('stack', 'tiles-wrap', { padTop: 6, style: 'align-self:stretch' }, [
            h('row', 'tiles', { gap: 8, align: 'stretch' }, [
              h('statTile', 'tile-counter', { value: m.cigs, label: 'cigarettes not smoked', alts: { label: COUNTER_ALTS } }),
              h('statTile', 'tile-money', { value: m.kept, label: 'kept' }),
            ]),
          ]) : null,
        ]),
        h('paywallFooter', 'footer', { gap: 4, padX: 22 }, [
          h('button', 'keep-going', { label: 'Keep going' }),
          h('milestoneShareButton', 'share', {}),
        ]),
      ]);
    },
  });

  /* ---------- The card maker (S13.3, S13.4) ---------- */
  const D3 = MILESTONES[2];
  const RIDDEN = 14; // persona day3.wavesBefore: cravings ridden out so far (not in codeTrue)
  Lab.screen({
    id: 'milestone-share', name: 'Share card maker', area: 'Milestones', source: MV + ' (ShareCardMaker, ShareCard)', ground: 'sun',
    note: 'A large sheet from "Share my card" on a milestone (here Three days clear, Sun 8 Nov 09:40) or the finale. Only days clear is on the card unless a number is switched on. "Cravings ridden out" (14) is the persona\'s waves so far; it is not a codeTrue number. ' +
      'The preview is the 1080 pt card scaled to 15% (Story) or 20% (Square), as in the app, so the words on it read smaller than 12 pt: it is a picture of the shared image, not interface text. In Square the big number shrinks to fit (minimumScaleFactor 0.4); the shrink here is estimated. The milestone behind is drawn as a dimmed strip.',
    statusInk: () => Lab.CREAM,
    states: [
      { id: 'story-dawn', label: 'Story · Dawn' },
      { id: 'story-night', label: 'Story · Night' },
      { id: 'square-dawn', label: 'Square · Dawn' },
      { id: 'square-night', label: 'Square · Night' },
      { id: 'all-numbers', label: 'Story · Dawn · every number on' },
    ],
    build(h) { return h('stack', 'behind', {}); },
    overlay(h, state) {
      const all = state.id === 'all-numbers';
      const format = state.id.startsWith('square') ? 'square' : 'story';
      const look = state.id.endsWith('night') ? 'night' : 'dawn';
      const extras = all ? `${D3.kept} kept · ${RIDDEN} cravings ridden out · ${D3.cigs} cigarettes not smoked` : '';
      return h('paywallSheet', 'sheet', { detent: 'large', grabber: false }, [
        h('paywallPage', 'page', { fill: 'parent', gap: 12, padX: 16, padBottom: 8 }, [
          h('stack', 'header-wrap', { padTop: 12 }, [h('milestoneShareHeader', 'header', {})]),
          h('paywallScroll', 'scroll', { gap: 12, padX: 0, padTop: 0, padBottom: 0, align: 'center' }, [
            h('milestoneShareCard', 'card', { days: String(D3.number), caption: 'days nicotine-free', extras, look, format, alts: { caption: ['day nicotine-free'], extras: [`${D3.kept} kept`, `${RIDDEN} cravings ridden out`, `${D3.cigs} cigarettes not smoked`] } }),
            h('row', 'pickers', { gap: 8, justify: 'center' }, [
              h('milestoneSegment', 'format', { left: 'Story', right: 'Square', selected: format === 'story' ? 'left' : 'right' }),
              h('milestoneSegment', 'look', { left: 'Dawn', right: 'Night', selected: look === 'dawn' ? 'left' : 'right' }),
            ]),
            h('stack', 'switches', { gap: 6, style: 'align-self:stretch' }, [
              h('milestoneToggleRow', 'switch-days', { title: 'Days clear', on: true, locked: true }),
              h('milestoneToggleRow', 'switch-money', { title: 'Money kept', detail: D3.kept, on: all }),
              h('milestoneToggleRow', 'switch-cravings', { title: 'Cravings ridden out', detail: String(RIDDEN), on: all }),
              h('milestoneToggleRow', 'switch-counter', { title: 'Cigarettes not smoked', detail: D3.cigs, on: all, alts: { title: ['Puffs not taken', 'Pouches not used'] } }),
            ]),
          ]),
          h('button', 'share', { label: 'Share' }),
        ]),
      ]);
    },
  });

  /* ---------- Finale (F18) ---------- */
  const DONE = { label: 'Day 30', date: 'Sun 6 Dec', days: 31, cigs: '362', kept: '$211.45', waves: 61, checkIns: 26 };
  Lab.screen({
    id: 'finale', name: 'Finale', area: 'Milestones', source: FIN + ', DayXero/ProgramV2/SessionFlowView.swift', ground: 'sun',
    note: 'The last step of the graduation session (W4S3, "Day 30"), on Sun 6 Dec 09:00: codeTrue programComplete, 31 days clear, $211.45 kept, 362 cigarettes not smoked. Waves ridden (61) and check-ins (26) are not defined in codeTrue; these are the persona\'s pre-decision-17 finale numbers. ' +
      'The session flow pads it (20 pt sides, 12 pt top, 8 pt bottom), so the hero starts under the status bar. The health card is the change under way 30 days 5 hours in for cigarettes. Xero, Jelli and Glim spring in one after another and the tiles count up; they are drawn settled. ' +
      'The confetti is the app\'s own drawing (42 pieces) at 1.2 s, the frame Reduce Motion holds; it has fallen away after about 5 s.',
    states: [{ id: 'confetti', label: 'Confetti falling (as with Reduce Motion)' }, { id: 'settled', label: 'After the confetti' }],
    build(h, state) {
      return h('paywallPage', 'page', { padTop: 12, padBottom: 8 }, [
        h('paywallScroll', 'scroll', { gap: 12, padX: 20, padTop: 0, padBottom: 16, align: 'center' }, [
          h('milestoneHero', 'hero', { scene: 'dawn', clarity: 100, height: 300, crew: 'crew', mood: 'cheer', stage: 4, confetti: state.id === 'confetti' ? '1.2' : 'none' }),
          h('text', 'kicker', { step: 'caption', tone: 'muted', align: 'center', text: `${DONE.label} · program complete · ${DONE.date}` }),
          h('text', 'title', { step: 'display', align: 'center', text: `${DONE.days} days. Clear skies.`, alts: { text: ['1 day. Clear skies.'] } }),
          h('row', 'tiles', { gap: 8, align: 'stretch', style: 'align-self:stretch' }, [
            h('statTile', 'tile-days', { value: String(DONE.days), label: 'days clear · Xero', alts: { label: ['day clear · Xero'] } }),
            h('statTile', 'tile-waves', { value: String(DONE.waves), label: 'waves ridden · Jelli' }),
            h('statTile', 'tile-checkins', { value: String(DONE.checkIns), label: 'check-ins · Glim' }),
          ]),
          h('text', 'money', { step: 'body', align: 'center', text: `${DONE.kept} kept and ${DONE.cigs} cigarettes not smoked. Because: To keep up with Maya at the park`,
            alts: { text: [`${DONE.kept} kept and ${DONE.cigs} cigarettes not smoked.`] } }),
          h('stack', 'health-wrap', { style: 'align-self:stretch' }, [
            h('healthFactCard', 'health', { status: 'Starting now', when: '1 to 12 months', title: 'Coughing and shortness of breath ease', line: '', sourceLabel: 'Source: American Cancer Society',
              alts: { status: ['Next'] } }),
          ]),
        ]),
        h('paywallFooter', 'footer', { gap: 4, padX: 20 }, [
          h('button', 'keep-going', { label: 'Keep going' }),
          h('milestoneShareButton', 'share', {}),
        ]),
      ]);
    },
  });
})();
