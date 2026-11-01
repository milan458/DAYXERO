/* DayXero Screen Lab — Onboarding (F01–F07): DayXero/Onboarding/OnboardingFlow.swift (flow, top bar, scaffold),
   OnboardingV4.swift (answer tray, bubble, option card), OnboardingV4Screens.swift (breathe, welcome, Quit Day,
   building, plan reveal, reminders), DetailScreens.swift (products to NRT), IntroScreens.swift (products, under-age),
   PlanScreens.swift (Quit Day calendar), OnboardingModel.swift (steps, Sam's sample answers). See ../FORMAT.md. */
(function () {
  'use strict';
  const Lab = window.Lab;
  const E = Lab.element, esc = Lab.esc, T = Lab.text, F = Lab.font;
  const DIR = 'DayXero/Onboarding/';
  const FLOW = DIR + 'OnboardingFlow.swift';
  const V4 = DIR + 'OnboardingV4.swift';
  const V4S = DIR + 'OnboardingV4Screens.swift';
  const DETAIL = DIR + 'DetailScreens.swift';
  const INTRO = DIR + 'IntroScreens.swift';
  const PLAN = DIR + 'PlanScreens.swift';
  const CREAM = Lab.CREAM, NAVY = Lab.NAVY;

  /* Onb (OnboardingV4.swift): the answer tray's colours, which are the reading ground's. */
  function O(ctx) {
    const d = ctx.dark;
    const r = Lab.ground('reading', d);
    return {
      ink: r.ink, muted: r.muted, onInk: r.bg,
      raised: Lab.c(Lab.fill.raised, d), surface: Lab.c(Lab.fill.surface, d),
      hairline: d ? 'rgba(255,255,255,0.14)' : 'rgba(30,26,58,0.12)',
      accent: Lab.c(Lab.fill.green, d),
      accentSoft: d ? 'rgba(47,208,138,0.16)' : 'rgba(15,110,67,0.12)',
      accentA: (a) => (d ? `rgba(47,208,138,${a})` : `rgba(15,110,67,${a})`),
    };
  }
  const groundBg = (name, ctx) => Lab.ground(name, ctx.dark).bg;
  const inert = (ctx) => Object.assign(ctx.with({}), { inert: true });

  /* SF Symbols the onboarding uses that lab.js doesn't draw. Each takes (colour, knockout colour). */
  const SYMBOLS = {
    smoke: (c) => `<path d="M6.5 17.5a3.6 3.6 0 0 1-.4-7.2A5 5 0 0 1 15.6 9a3.4 3.4 0 0 1 2.4 6.3 2.6 2.6 0 0 1-1.9 2.2z" fill="${c}"/><path d="M15 7.2a3.2 3.2 0 0 1 5.6 2.4" fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round"/>`,
    wind: (c) => `<path d="M3 9h10.5a2.8 2.8 0 1 0-2.8-2.8M3 13h15a2.8 2.8 0 1 1-2.8 2.8M3 17h7" fill="none" stroke="${c}" stroke-width="2.2" stroke-linecap="round"/>`,
    capsule: (c) => `<g transform="rotate(-45 12 12)"><rect x="2.5" y="7.5" width="19" height="9" rx="4.5" fill="none" stroke="${c}" stroke-width="2"/><path d="M12 7.5v9" stroke="${c}" stroke-width="2"/></g>`,
    lightbulb: (c) => `<path d="M9 17.5h6M10 20.5h4M12 3.5a6 6 0 0 0-3.6 10.8c.7.6 1.1 1.4 1.1 2.2h5c0-.8.4-1.6 1.1-2.2A6 6 0 0 0 12 3.5z" fill="none" stroke="${c}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>`,
    creditcard: (c) => `<rect x="3" y="5.5" width="18" height="13" rx="2.5" fill="none" stroke="${c}" stroke-width="1.5"/><path d="M3 9.8h18" stroke="${c}" stroke-width="2.2"/><path d="M6.5 15h4" stroke="${c}" stroke-width="1.5" stroke-linecap="round"/>`,
    hourglass: (c) => `<path d="M7 3.5h10M7 20.5h10M8 3.5c0 4 4 5.5 4 8.5s-4 4.5-4 8.5M16 3.5c0 4-4 5.5-4 8.5s4 4.5 4 8.5" fill="none" stroke="${c}" stroke-width="1.5" stroke-linecap="round"/>`,
    calendar: (c) => `<rect x="4" y="5.5" width="16" height="14.5" rx="3" fill="none" stroke="${c}" stroke-width="1.5"/><path d="M4 10h16M8.5 3.5v4M15.5 3.5v4" stroke="${c}" stroke-width="1.5" stroke-linecap="round"/>`,
    sparkles: (c) => `<path d="M10 3l1.6 4.4L16 9l-4.4 1.6L10 15l-1.6-4.4L4 9l4.4-1.6zM17.5 13l.9 2.1 2.1.9-2.1.9-.9 2.1-.9-2.1-2.1-.9 2.1-.9z" fill="none" stroke="${c}" stroke-width="1.3" stroke-linejoin="round"/>`,
    camera: (c) => `<path d="M4 8.5a2 2 0 0 1 2-2h2l1.5-2h5L16 6.5h2a2 2 0 0 1 2 2v9a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2z" fill="none" stroke="${c}" stroke-width="1.5" stroke-linejoin="round"/><circle cx="12" cy="13" r="3.5" fill="none" stroke="${c}" stroke-width="1.5"/>`,
    'doc.text': (c) => `<path d="M6.5 3.5h7l4 4v13h-11z" fill="none" stroke="${c}" stroke-width="1.5" stroke-linejoin="round"/><path d="M9 11.5h6M9 14.5h6M9 17.5h4" stroke="${c}" stroke-width="1.5" stroke-linecap="round"/>`,
    clock: (c) => `<circle cx="12" cy="12" r="8.5" fill="none" stroke="${c}" stroke-width="2"/><path d="M12 7.5V12l3 2" fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round"/>`,
    minus: (c) => `<path d="M5.5 12h13" stroke="${c}" stroke-width="2.6" stroke-linecap="round"/>`,
    plus: (c) => `<path d="M12 5.5v13M5.5 12h13" stroke="${c}" stroke-width="2.6" stroke-linecap="round"/>`,
    'arrow.up.right': (c) => `<path d="M7 17L17 7M9 7h8v8" fill="none" stroke="${c}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>`,
    'checkmark.circle.fill': (c, k) => `<circle cx="12" cy="12" r="10" fill="${c}"/><path d="M7.5 12.3l3 3 6-6.3" fill="none" stroke="${k}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/>`,
    circle: (c) => `<circle cx="12" cy="12" r="9.6" fill="none" stroke="${c}" stroke-width="1.6"/>`,
  };
  const sym = (name, size, colour, knock) => (SYMBOLS[name]
    ? `<svg viewBox="0 0 24 24" width="${size}" height="${size}" style="flex:none;display:block" aria-hidden="true">${SYMBOLS[name](colour, knock || 'transparent')}</svg>`
    : Lab.icon(name, size, colour));
  const PRODUCT_ICONS = [['', 'None'], ['smoke', 'Smoke (cigarettes)'], ['wind', 'Wind (vape)'], ['capsule', 'Capsule (pouches)']];

  /** "**bold**" and "[link]" inside a string: bold keeps the colour, a link takes the ink (as .tint does). */
  function rich(str, ctx, linkColour) {
    return String(str).split(/(\*\*[^*]+\*\*|\[[^\]]+\])/).map((part) => {
      if (/^\*\*[^*]+\*\*$/.test(part)) return `<b style="font-weight:700">${esc(part.slice(2, -2))}</b>`;
      if (/^\[[^\]]+\]$/.test(part)) return `<span style="color:${linkColour}">${esc(part.slice(1, -1))}</span>`;
      return esc(part);
    }).join('');
  }

  /* ---------- Shared pieces: top bar, bubble, answer tray ---------- */
  const PROGRESS = [[0, '0 (Welcome)']].concat(Array.from({ length: 12 }, (_, i) => [+((i + 1) / 12).toFixed(3), `${i + 1} of 12 steps`]), [[0.1, '1 of 10 steps (nothing picked yet)']]);

  E({
    type: 'onbAvatar', name: 'Crew avatar', group: 'Onboarding', source: FLOW,
    description: "A 40 pt crew member, still, on a circle of their colour (Xero on apricot, Jelli on ocean, Glim on violet).",
    props: {
      art: { label: 'Character', kind: 'art', default: 'xero:hello' },
      ground: { label: 'Circle colour', kind: 'ground', default: 'apricot' },
      size: { label: 'Size', kind: 'number', options: [28, 32, 40, 48], unit: ' pt', default: 40 },
    },
    examples: [{ label: 'Xero', ground: 'lilac', props: {} }],
    render(p, ctx) {
      return `<div style="width:${p.size}px;height:${p.size}px;border-radius:50%;overflow:hidden;flex:none;line-height:0;background:${groundBg(p.ground, ctx)}">${Lab.art(p.art, { size: p.size, animate: false })}</div>`;
    },
  });

  E({
    type: 'onbProgress', name: 'Setup progress bar', group: 'Onboarding', source: V4 + ' (OnbProgressBar)',
    description: 'Green fill on a soft track (ground ink at 14%), 8 pt tall. Fills by step across the whole flow.',
    props: {
      value: { label: 'Filled', kind: 'number', options: PROGRESS, default: 0.25 },
      height: { label: 'Height', kind: 'number', options: [4, 6, 8, 10], unit: ' pt', default: 8, global: true },
    },
    examples: [{ label: 'On lilac', ground: 'lilac', props: { value: 0.417 } }],
    render(p, ctx) {
      const track = ctx.g.creamInk || ctx.dark ? 'rgba(255,248,238,0.14)' : 'rgba(30,26,58,0.14)';
      return `<div role="progressbar" style="flex:1 1 auto;min-width:0;height:${p.height}px;border-radius:999px;background:${track};overflow:hidden"><div style="height:100%;width:${Math.min(1, Math.max(0, +p.value)) * 100}%;border-radius:999px;background:${Lab.c(Lab.fill.green, ctx.dark)}"></div></div>`;
    },
  });

  E({
    type: 'onbTopBar', name: 'Onboarding top bar', group: 'Onboarding', source: FLOW + ' (topBar)',
    description: "F03 header on the question screens: back in a 44 pt circle (card-on-colour), Xero's 40 pt avatar on apricot, and the green progress bar. 48 pt tall, 12 pt gaps.",
    props: {
      back: { label: 'Back button', kind: 'bool', labels: ['Show', 'Hide'], default: true },
      avatar: { label: 'Avatar', kind: 'art', default: 'xero:hello' },
      value: { label: 'Progress', kind: 'number', options: PROGRESS, default: 0.25 },
      gap: { label: 'Gap', kind: 'number', options: [8, 10, 12, 14, 16], unit: ' pt', default: 12, global: true },
    },
    examples: [{ label: 'On lilac', ground: 'lilac', props: { value: 0.417 } }],
    render(p, ctx) {
      const c = inert(ctx);
      const back = p.back ? `<div role="button" aria-label="Back" style="width:44px;height:44px;border-radius:50%;flex:none;display:flex;align-items:center;justify-content:center;background:${Lab.c(Lab.fill.cardOnColour, ctx.dark)}">${Lab.icon('chevron.left', 16, ctx.g.ink)}</div>` : '';
      const avatar = p.avatar && p.avatar !== 'none' ? Lab.render(Lab.h('onbAvatar', '_a', { art: p.avatar, ground: 'apricot' }), c) : '';
      return `<div style="display:flex;align-items:center;gap:${p.gap}px;min-height:48px">${back}${avatar}${Lab.render(Lab.h('onbProgress', '_p', { value: p.value }), c)}</div>`;
    },
  });

  E({
    type: 'onbBubble', name: "Xero's question bubble", group: 'Onboarding', source: V4 + ' (XeroBubble)',
    description: "Xero asks in a bubble: left-aligned, card-on-colour fill, radius 20 20 20 4, 16 × 12 pt padding, 24 pt clear on the right. The question is 19 pt; a follow-up line is 16 pt.",
    props: {
      text: { label: 'Words', kind: 'text', default: 'What are we leaving behind?' },
      large: { label: 'Size', kind: 'select', default: true, options: [[true, 'Question (19 pt headline)'], [false, 'Follow-up (16 pt body)']] },
    },
    examples: [{ label: 'Question', ground: 'lilac', props: {} }, { label: 'Follow-up', ground: 'lilac', props: { large: false, text: "Pick everything you use now. We'll set up your counters and biology for each one." } }],
    render(p, ctx) {
      const ink = Lab.ground('lilac', ctx.dark).ink;
      return `<div style="display:flex;padding-right:24px"><div style="${F(p.large ? 'headline' : 'body')}color:${ink};padding:12px 16px;border-radius:20px 20px 20px 4px;background:${Lab.c(Lab.fill.cardOnColour, ctx.dark)}">${esc(p.text)}</div></div>`;
    },
  });

  E({
    type: 'onbTray', name: 'Answer tray', group: 'Onboarding', source: V4 + ' (AnswerTrayCard)',
    description: 'The reading surface the controls sit on, under the question: "YOUR ANSWER", then the controls, 10 pt apart. White (#2A255F in dark), 18 pt padding, radius 24.',
    props: {
      label: { label: 'Label', kind: 'text', default: 'YOUR ANSWER' },
      gap: { label: 'Gap between items', kind: 'number', options: [6, 8, 10, 12, 14, 16], unit: ' pt', default: 10, global: true },
      padding: { label: 'Padding', kind: 'number', options: [14, 16, 18, 20, 24], unit: ' pt', default: 18, global: true },
      radius: { label: 'Corner radius', kind: 'number', options: [18, 20, 24, 28], unit: ' pt', default: 24, global: true },
    },
    examples: [{ label: 'With a chip', ground: 'lilac', props: {}, kids: [['onbChip', { label: 'Coffee', on: true }]] }],
    render(p, ctx, kids) {
      const o = O(ctx);
      return `<div style="display:flex;flex-direction:column;align-items:stretch;gap:${p.gap}px;padding:${p.padding}px;border-radius:${p.radius}px;background:${o.raised};color:${o.ink}">
        <div style="${F('caption')}color:${o.muted}">${esc(p.label)}</div>${kids({ groundName: 'reading' })}</div>`;
    },
  });

  /* ---------- Controls inside the tray ---------- */
  E({
    type: 'onbOption', name: 'Option card', group: 'Onboarding', source: V4 + ' (OnbOptionCard)',
    description: 'An optional 40 pt icon circle, a 19 pt title and 14 pt detail, and a 22 pt tick circle (green when chosen). Surface fill, radius 18, 14 pt padding, 64 pt tall; a 2 pt ink outline when chosen.',
    props: {
      title: { label: 'Title', kind: 'text', default: 'Cigarettes' },
      detail: { label: 'Detail', kind: 'text', default: 'Manufactured or roll-ups' },
      icon: { label: 'Icon', kind: 'select', default: 'smoke', options: PRODUCT_ICONS },
      selected: { label: 'State', kind: 'select', default: false, options: [[false, 'Not chosen'], [true, 'Chosen']] },
      radius: { label: 'Corner radius', kind: 'number', options: [14, 16, 18, 20, 24], unit: ' pt', default: 18, global: true },
    },
    examples: [{ label: 'Chosen', ground: 'reading', props: { selected: true } }, { label: 'Not chosen', ground: 'reading', props: { title: 'Vape or e-cigarette', detail: 'Disposables, pods or refillable tanks', icon: 'wind' } }],
    render(p, ctx) {
      const o = O(ctx);
      const on = !!p.selected;
      const icon = p.icon ? `<div style="width:40px;height:40px;border-radius:50%;flex:none;display:flex;align-items:center;justify-content:center;background:${on ? o.ink : o.raised}">${sym(p.icon, 20, on ? o.onInk : o.ink)}</div>` : '';
      const tick = on ? sym('checkmark.circle.fill', 24, o.accent, o.surface) : sym('circle', 24, o.hairline);
      return `<div role="button" style="display:flex;align-items:center;gap:12px;padding:14px;min-height:64px;box-sizing:border-box;border-radius:${p.radius}px;background:${o.surface};${on ? `box-shadow:inset 0 0 0 2px ${o.ink};` : ''}">
        ${icon}<div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:2px"><div style="${F('headline')}color:${o.ink}">${esc(p.title)}</div>${p.detail ? `<div style="${F('footnote')}color:${o.muted}">${esc(p.detail)}</div>` : ''}</div>${tick}</div>`;
    },
  });

  E({
    type: 'onbSegment', name: 'Segment chip', group: 'Onboarding', source: DETAIL + ' (OnboardingSegments)',
    description: 'One of a row of equal-width chips (one choice from a few): 14 pt, bold when picked, 48 pt tall, radius 14. Ink fill when picked, surface otherwise.',
    props: {
      label: { label: 'Words', kind: 'text', default: '20 pack' },
      on: { label: 'State', kind: 'select', default: false, options: [[false, 'Not picked'], [true, 'Picked']] },
      scale: { label: 'Shrink to fit', kind: 'number', options: [[1, 'Full size (14 pt)'], [0.93, '13 pt'], [0.9, '12.6 pt'], [0.86, '12 pt (the lab\'s floor)']], default: 1 },
      radius: { label: 'Corner radius', kind: 'number', options: [10, 12, 14, 18, 999], unit: ' pt', default: 14, global: true },
    },
    examples: [{ label: 'Picked', ground: 'reading', props: { on: true } }],
    render(p, ctx) {
      const o = O(ctx);
      return `<div role="button" style="flex:1 1 0;min-width:0;min-height:48px;display:flex;align-items:center;justify-content:center;padding:0 4px;border-radius:${p.radius}px;background:${p.on ? o.ink : o.surface};${F('footnote', { size: 14 * (+p.scale || 1), weight: p.on ? 700 : 500 })}color:${p.on ? o.onInk : o.ink};white-space:nowrap;overflow:hidden;text-overflow:clip">${esc(p.label)}</div>`;
    },
  });

  E({
    type: 'onbChip', name: 'Answer chip', group: 'Onboarding', source: DETAIL + ' (OnboardingChip)',
    description: 'A chip in a wrapping row (pick any): 14 pt, bold when picked, 16 pt sides, 48 pt tall, radius 14. Ink fill when picked.',
    props: {
      label: { label: 'Words', kind: 'text', default: 'Coffee' },
      on: { label: 'State', kind: 'select', default: false, options: [[false, 'Not picked'], [true, 'Picked']] },
      radius: { label: 'Corner radius', kind: 'number', options: [10, 12, 14, 18, 999], unit: ' pt', default: 14, global: true },
    },
    examples: [{ label: 'Picked', ground: 'reading', props: { on: true } }, { label: 'Not picked', ground: 'reading', props: { label: 'Stress' } }],
    render(p, ctx) {
      const o = O(ctx);
      return `<div role="button" style="flex:none;min-height:48px;display:flex;align-items:center;padding:0 16px;border-radius:${p.radius}px;background:${p.on ? o.ink : o.surface};${F('footnote', { size: 14, weight: p.on ? 700 : 500 })}color:${p.on ? o.onInk : o.ink}">${esc(p.label)}</div>`;
    },
  });

  E({
    type: 'onbStepper', name: 'Amount stepper', group: 'Onboarding', source: DETAIL + ' (AmountStepper)',
    description: 'A big centred number (32 pt) over a 13 pt unit line, with a 48 pt minus (outlined) and plus (ink). Surface fill, radius 20, 16 pt padding, hairline.',
    props: {
      value: { label: 'Number', kind: 'text', default: '12' },
      unit: { label: 'Unit line', kind: 'text', default: 'cigarettes a day' },
    },
    examples: [{ label: '12 a day', ground: 'reading', props: {} }],
    render(p, ctx) {
      const o = O(ctx);
      const btn = (name, primary) => `<div role="button" style="width:48px;height:48px;border-radius:50%;flex:none;display:flex;align-items:center;justify-content:center;background:${primary ? o.ink : o.surface};${primary ? '' : `box-shadow:inset 0 0 0 1px ${o.hairline};`}">${sym(name, 20, primary ? o.onInk : o.ink)}</div>`;
      return `<div style="display:flex;align-items:center;padding:16px;border-radius:20px;background:${o.surface};box-shadow:inset 0 0 0 1px ${o.hairline}">
        ${btn('minus', false)}<div style="flex:1;min-width:0;display:flex;flex-direction:column;align-items:center">
        <div style="${F('large')}color:${o.ink};font-variant-numeric:tabular-nums">${esc(p.value)}</div>
        <div style="${F('footnote', { size: 13, weight: 400 })}color:${o.muted};text-align:center">${esc(p.unit)}</div></div>${btn('plus', true)}</div>`;
    },
  });

  E({
    type: 'onbPriceStepper', name: 'Price stepper', group: 'Onboarding', source: DETAIL + ' (PriceStepper)',
    description: "A price with 40 pt minus and plus, for things with one usual price (a pod or disposable): 24 pt bold, surface fill, radius 20, 12 pt padding.",
    props: { price: { label: 'Price', kind: 'text', default: '$10' } },
    examples: [{ label: '$10', ground: 'reading', props: {} }],
    render(p, ctx) {
      const o = O(ctx);
      const btn = (name, primary) => `<div role="button" style="width:40px;height:40px;border-radius:50%;flex:none;display:flex;align-items:center;justify-content:center;background:${primary ? o.ink : o.surface}">${sym(name, 18, primary ? o.onInk : o.ink)}</div>`;
      return `<div style="display:flex;align-items:center;padding:12px;border-radius:20px;background:${o.surface};box-shadow:inset 0 0 0 1px ${o.hairline}">
        ${btn('minus', false)}<div style="flex:1;min-width:0;text-align:center;${F('title', { size: 24, weight: 700 })}color:${o.ink};font-variant-numeric:tabular-nums">${esc(p.price)}</div>${btn('plus', true)}</div>`;
    },
  });

  E({
    type: 'onbSummary', name: 'Live summary', group: 'Onboarding', source: DETAIL + ' (LiveSummary)',
    description: 'Money and nicotine as the numbers change: a 14 pt icon and a 14 pt semibold line in green, on soft green, radius 14.',
    props: {
      text: { label: 'Words', kind: 'text', default: '$2,190 a year · about 14 mg nicotine a day' },
      icon: { label: 'Icon', kind: 'select', default: 'creditcard', options: [['creditcard', 'Card'], ['sparkles', 'Sparkles'], ['', 'None']] },
    },
    examples: [{ label: 'Cigarettes', ground: 'reading', props: {} }],
    render(p, ctx) {
      const o = O(ctx);
      return `<div style="display:flex;align-items:center;gap:8px;padding:12px 16px;border-radius:14px;background:${o.accentSoft};${F('footnote', { size: 14, weight: 600 })}color:${o.accent}">${p.icon ? sym(p.icon, 16, o.accent) : ''}<span>${esc(p.text)}</span></div>`;
    },
  });

  E({
    type: 'onbDualUse', name: 'Dual use note', group: 'Onboarding', source: INTRO + ' (ProductsScreen)',
    description: 'Shown when more than one product is picked: a light bulb, a 14 pt green title and a 14 pt muted line, on soft green with a dashed green outline, radius 20.',
    props: {
      title: { label: 'Title', kind: 'text', default: 'Dual use detected' },
      text: { label: 'Line', kind: 'text', default: "Quitting more than one together needs its own approach. We'll sync them all in your prep plan." },
    },
    examples: [{ label: 'Dual use', ground: 'reading', props: {} }],
    render(p, ctx) {
      const o = O(ctx);
      return `<div style="position:relative;display:flex;align-items:flex-start;gap:12px;padding:14px 16px;border-radius:20px;background:${o.accentSoft}">
        <svg aria-hidden="true" style="position:absolute;inset:0;width:100%;height:100%;overflow:visible;pointer-events:none"><rect x=".5" y=".5" rx="19.5" style="width:calc(100% - 1px);height:calc(100% - 1px)" fill="none" stroke="${o.accent}" stroke-opacity=".7" stroke-width="1" stroke-dasharray="5 4"/></svg>
        ${sym('lightbulb', 18, o.accent)}<div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:4px"><div style="${F('footnote', { size: 14, weight: 600 })}color:${o.accent}">${esc(p.title)}</div><div style="${F('footnote')}color:${o.muted}">${esc(p.text)}</div></div></div>`;
    },
  });

  E({
    type: 'onbLoadCard', name: 'Nicotine load card', group: 'Onboarding', source: DETAIL + ' (BaselineSummaryScreen.hero)',
    description: 'Navy in both appearances: "TOTAL DAILY NICOTINE LOAD", the cigarettes-a-day equivalent in 48 pt green, then a row per product. 20 pt padding, radius 24.',
    props: {
      label: { label: 'Label', kind: 'text', default: 'Total daily nicotine load' },
      value: { label: 'Number', kind: 'text', default: '≈ 21' },
      unit: { label: 'After the number', kind: 'text', default: 'cigarettes a day' },
    },
    examples: [{ label: 'Sam', ground: 'reading', props: {}, kids: [['onbLoadRow', {}]] }],
    render(p, ctx, kids) {
      const d = Lab.ground('reading', true);
      const green = Lab.c(Lab.fill.green, true);
      return `<div style="display:flex;flex-direction:column;gap:12px;padding:20px;border-radius:24px;background:${NAVY}">
        <div style="${F('caption')}color:${d.muted};text-transform:uppercase">${esc(p.label)}</div>
        <div style="display:flex;align-items:baseline;gap:8px;flex-wrap:wrap"><div style="${F('display', { size: 48, weight: 800, tracking: -1.4, lh: 1 })}color:${green};white-space:nowrap">${esc(p.value)}</div><div style="${F('body', { size: 17, weight: 500 })}color:#FFFFFF">${esc(p.unit)}</div></div>
        ${kids({ dark: true, groundName: 'reading' })}</div>`;
    },
  });

  E({
    type: 'onbLoadRow', name: 'Nicotine load row', group: 'Onboarding', source: DETAIL + ' (BaselineSummaryScreen.hero)',
    description: 'One product on the navy card: its icon in a 36 pt circle, a 14 pt line and a 12 pt line at 60%.',
    props: {
      icon: { label: 'Icon', kind: 'select', default: 'smoke', options: PRODUCT_ICONS.slice(1) },
      line: { label: 'Line', kind: 'text', default: '12 cigarettes' },
      detail: { label: 'Detail', kind: 'text', default: 'About 14 mg nicotine absorbed' },
    },
    render(p) {
      const green = Lab.c(Lab.fill.green, true);
      return `<div style="display:flex;align-items:center;gap:12px"><div style="width:36px;height:36px;border-radius:50%;flex:none;display:flex;align-items:center;justify-content:center;background:rgba(255,255,255,0.1)">${sym(p.icon, 18, green)}</div>
        <div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:1px"><div style="${F('footnote', { size: 14, weight: 600 })}color:#FFFFFF">${esc(p.line)}</div><div style="${F('caption', { size: 12, weight: 400 })}color:rgba(255,255,255,0.6)">${esc(p.detail)}</div></div></div>`;
    },
  });

  E({
    type: 'onbStatTile', name: 'Baseline tile', group: 'Onboarding', source: DETAIL + ' (BaselineSummaryScreen.tile)',
    description: 'A 14 pt icon in a 32 pt soft-green circle, a caption label, a 22 pt bold value and a 12 pt detail. Surface fill, radius 24, 16 pt padding, hairline.',
    props: {
      icon: { label: 'Icon', kind: 'select', default: 'creditcard', options: [['creditcard', 'Card'], ['hourglass', 'Hourglass'], ['calendar', 'Calendar']] },
      label: { label: 'Label', kind: 'text', default: 'Yearly drain' },
      value: { label: 'Value', kind: 'text', default: '$2,555' },
      detail: { label: 'Detail', kind: 'text', default: '$7 gone every day' },
    },
    examples: [{ label: 'Yearly drain', ground: 'reading', props: {} }],
    render(p, ctx) {
      const o = O(ctx);
      return `<div style="flex:1 1 0;min-width:0;display:flex;flex-direction:column;align-items:flex-start;gap:6px;padding:16px;border-radius:24px;background:${o.surface};box-shadow:inset 0 0 0 1px ${o.hairline}">
        <div style="width:32px;height:32px;border-radius:50%;display:flex;align-items:center;justify-content:center;background:${o.accentSoft}">${sym(p.icon, 16, o.accent)}</div>
        <div style="${F('caption')}color:${o.muted};text-transform:uppercase">${esc(p.label)}</div>
        <div style="${F('title', { size: 22, weight: 700 })}color:${o.ink};white-space:nowrap">${esc(p.value)}</div>
        <div style="${F('caption', { size: 12, weight: 400 })}color:${o.muted}">${esc(p.detail)}</div></div>`;
    },
  });

  E({
    type: 'onbNote', name: 'Good news note', group: 'Onboarding', source: DETAIL + ' (BaselineSummaryScreen)',
    description: 'A 16 pt green icon beside a 14 pt muted line, on the surface with a hairline, radius 20, 14 pt padding.',
    props: {
      icon: { label: 'Icon', kind: 'select', default: 'sparkles', options: [['sparkles', 'Sparkles'], ['lightbulb', 'Light bulb']] },
      text: { label: 'Words', kind: 'text', default: 'Good news: in your prep week your brain steps down from this dose, without the shock of quitting cold turkey today.' },
    },
    examples: [{ label: 'Good news', ground: 'reading', props: {} }],
    render(p, ctx) {
      const o = O(ctx);
      return `<div style="display:flex;align-items:flex-start;gap:12px;padding:14px;border-radius:20px;background:${o.surface};box-shadow:inset 0 0 0 1px ${o.hairline}">${sym(p.icon, 18, o.accent)}<div style="flex:1;min-width:0;${F('footnote')}color:${o.muted}">${esc(p.text)}</div></div>`;
    },
  });

  E({
    type: 'onbLabel', name: 'Icon line', group: 'Onboarding', source: DETAIL + ' (TriggersScreen)',
    description: 'A SwiftUI Label: a small icon and a 14 pt muted line.',
    props: {
      icon: { label: 'Icon', kind: 'select', default: 'clock', options: [['clock', 'Clock'], ['sparkles', 'Sparkles'], ['', 'None']] },
      text: { label: 'Words', kind: 'text', default: 'Using within 30 minutes of waking is a strong sign of dependence. We plan your mornings first.' },
    },
    examples: [{ label: 'Early mornings', ground: 'reading', props: {} }],
    render(p, ctx) {
      const o = O(ctx);
      return `<div style="display:flex;align-items:flex-start;gap:8px;${F('footnote')}color:${o.muted}">${p.icon ? `<div style="padding-top:1px">${sym(p.icon, 16, o.muted)}</div>` : ''}<div style="flex:1;min-width:0">${esc(p.text)}</div></div>`;
    },
  });

  E({
    type: 'onbField', name: 'Text field', group: 'Onboarding', source: DETAIL + ' (FieldStyle)',
    description: '16 pt text on the surface, 18 × 14 pt padding, radius 14, a hairline (1.5 pt green while typing). 52 pt tall; the reason field is 96 pt and grows to six lines.',
    props: {
      placeholder: { label: 'Placeholder', kind: 'text', default: 'Your name' },
      value: { label: 'Typed', kind: 'text', default: '' },
      tall: { label: 'Height', kind: 'select', default: false, options: [[false, 'One line (52 pt)'], [true, 'Reason (96 pt)']] },
      focused: { label: 'Focus', kind: 'select', default: false, options: [[false, 'Not typing'], [true, 'Typing (green outline)']] },
    },
    examples: [{ label: 'Empty', ground: 'reading', props: {} }, { label: 'Typed', ground: 'reading', props: { value: 'Sam', focused: true } }],
    render(p, ctx) {
      const o = O(ctx);
      const ring = p.focused ? `inset 0 0 0 1.5px ${o.accent}` : `inset 0 0 0 1px ${o.hairline}`;
      return `<div style="min-height:${p.tall ? 96 : 52}px;box-sizing:border-box;padding:14px 18px;border-radius:14px;background:${o.surface};box-shadow:${ring};${F('body')}color:${p.value ? o.ink : o.muted}">${esc(p.value || p.placeholder)}</div>`;
    },
  });

  E({
    type: 'onbPhotoRow', name: 'Photo picker row', group: 'Onboarding', source: DETAIL + ' (PersonalScreen)',
    description: 'Opens Photos: a camera in a 40 pt soft-green circle, a 14 pt semibold line and a 12 pt muted line, inside a dashed muted outline, radius 20.',
    props: {
      title: { label: 'Line', kind: 'text', default: "Add a photo of who you're doing this for" },
      detail: { label: 'Detail', kind: 'text', default: 'Optional · stays on this phone' },
    },
    examples: [{ label: 'No photo', ground: 'reading', props: {} }],
    render(p, ctx) {
      const o = O(ctx);
      return `<div role="button" style="position:relative;display:flex;align-items:center;gap:12px;padding:14px">
        <svg aria-hidden="true" style="position:absolute;inset:0;width:100%;height:100%;overflow:visible;pointer-events:none"><rect x=".5" y=".5" rx="19.5" style="width:calc(100% - 1px);height:calc(100% - 1px)" fill="none" stroke="${o.muted}" stroke-width="1" stroke-dasharray="5 4"/></svg>
        <div style="width:40px;height:40px;border-radius:50%;flex:none;display:flex;align-items:center;justify-content:center;background:${o.accentSoft}">${sym('camera', 18, o.accent)}</div>
        <div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:2px"><div style="${F('footnote', { size: 14, weight: 600 })}color:${o.ink}">${esc(p.title)}</div><div style="${F('caption', { size: 12, weight: 400 })}color:${o.muted}">${esc(p.detail)}</div></div></div>`;
    },
  });

  E({
    type: 'onbSlider', name: 'Confidence slider', group: 'Onboarding', source: DETAIL + ' (PastAttemptsScreen)',
    description: 'The system slider, 0 to 10 in whole steps, tinted green.',
    props: { value: { label: 'Value', kind: 'number', options: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], default: 5 } },
    examples: [{ label: '5', ground: 'reading', props: {} }],
    render(p, ctx) {
      const o = O(ctx);
      const x = Math.min(10, Math.max(0, +p.value)) / 10;
      const track = ctx.dark ? 'rgba(120,120,128,0.36)' : 'rgba(120,120,128,0.2)';
      return `<div role="slider" style="position:relative;height:34px"><div style="position:absolute;left:0;right:0;top:15px;height:4px;border-radius:2px;background:${track}"></div>
        <div style="position:absolute;left:0;top:15px;height:4px;border-radius:2px;width:calc(14px + (100% - 28px) * ${x});background:${o.accent}"></div>
        <div style="position:absolute;top:3px;left:calc((100% - 28px) * ${x});width:28px;height:28px;border-radius:50%;background:#FFFFFF;box-shadow:0 0.5px 4px rgba(0,0,0,.12),0 6px 13px rgba(0,0,0,.12)"></div></div>`;
    },
  });

  E({
    type: 'onbConfidence', name: 'Confidence reply', group: 'Onboarding', source: DETAIL + ' (PastAttemptsScreen)',
    description: 'The slider value in 15 pt green and a 14 pt line that changes with it, on soft green, radius 18.',
    props: {
      value: { label: 'Value', kind: 'text', default: '5/10' },
      text: { label: 'Line', kind: 'text', default: "Totally normal. That's why we prepare first." },
    },
    examples: [{ label: '5 of 10', ground: 'reading', props: {} }],
    render(p, ctx) {
      const o = O(ctx);
      return `<div style="display:flex;align-items:center;gap:10px;padding:12px 14px;border-radius:18px;background:${o.accentSoft}"><div style="${F('footnote', { size: 15, weight: 700 })}color:${o.accent};white-space:nowrap">${esc(p.value)}</div><div style="flex:1;min-width:0;${F('footnote')}color:${o.ink}">${esc(p.text)}</div></div>`;
    },
  });

  E({
    type: 'onbSourcePill', name: 'Source link pill', group: 'Onboarding', source: DETAIL + ' (NRTScreen)',
    description: 'Opens the study: a 12 pt document icon and a 12 pt muted line in a surface capsule with a hairline.',
    props: { text: { label: 'Words', kind: 'text', default: 'Source: Cochrane review of 133 trials, 2018' } },
    examples: [{ label: 'Cochrane', ground: 'reading', props: {} }],
    render(p, ctx) {
      const o = O(ctx);
      return `<div role="link" style="align-self:flex-start;display:inline-flex;align-items:center;gap:6px;padding:6px 12px;border-radius:999px;background:${o.surface};box-shadow:inset 0 0 0 1px ${o.hairline};${F('caption', { size: 12, weight: 500 })}color:${o.muted}">${sym('doc.text', 14, o.muted)}<span>${esc(p.text)}</span></div>`;
    },
  });

  E({
    type: 'onbYouthRow', name: 'Youth support row', group: 'Onboarding', source: INTRO + ' (UnderAgeScreen.row)',
    description: 'A 15 pt semibold title and a 14 pt muted line on the surface, radius 22, hairline; an arrow when it links out.',
    props: {
      title: { label: 'Title', kind: 'text', default: 'Youth quit support (US)' },
      detail: { label: 'Detail', kind: 'text', default: 'Free text-message program' },
      external: { label: 'Link arrow', kind: 'bool', labels: ['Show', 'Hide'], default: false },
    },
    examples: [{ label: 'US', ground: 'reading', props: {} }],
    render(p, ctx) {
      const o = O(ctx);
      return `<div style="display:flex;align-items:center;gap:8px;padding:14px;border-radius:22px;background:${o.surface};box-shadow:inset 0 0 0 1px ${o.hairline}">
        <div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:2px"><div style="${F('body', { size: 15, weight: 600 })}color:${o.ink}">${esc(p.title)}</div><div style="${F('footnote')}color:${o.muted}">${esc(p.detail)}</div></div>${p.external ? sym('arrow.up.right', 16, o.muted) : ''}</div>`;
    },
  });

  E({
    type: 'onbRichText', name: 'Text with bold or link words', group: 'Onboarding', source: V4S,
    description: 'A line where some words are bold (**like this**) or a link in the ink colour ([like this]).',
    props: {
      text: { label: 'Words', kind: 'text', default: 'I recommend **Fri 6 Nov**.' },
      step: { label: 'Text style', kind: 'type', default: 'body' },
      tone: { label: 'Colour', kind: 'colour', default: 'muted' },
      align: { label: 'Align', kind: 'select', default: 'left', options: [['left', 'Left'], ['center', 'Centre']] },
    },
    examples: [{ label: 'Quit Day', ground: 'apricot', props: {} }],
    render(p, ctx) {
      return `<div style="${F(p.step)}color:${Lab.colour(p.tone, ctx)};text-align:${p.align}">${rich(p.text, ctx, ctx.g.ink)}</div>`;
    },
  });

  /* ---------- F01 Breathe ---------- */
  E({
    type: 'onbBreatheOrb', name: 'Breathing rings and Xero', group: 'Onboarding', source: V4S + ' (BreatheScreen)',
    description: 'Three cream rings (170, 230 and 290 pt at 16%, 12% and 8%) breathing on the 4 s in, 6 s out clock behind Xero (hero size, 200 pt). 340 pt tall.',
    props: {
      character: { label: 'Character', kind: 'art', default: 'xero:breathe' },
      size: { label: 'Character size', kind: 'number', options: [140, 160, 200, 240], unit: ' pt', default: 200 },
      breath: { label: 'Breath', kind: 'select', default: 0.5, options: [[0, 'Breathed out (rings at 82%)'], [0.5, 'Halfway (as with Reduce Motion)'], [1, 'Breathed in (rings full)']] },
      height: { label: 'Height', kind: 'number', options: [280, 300, 340, 380], unit: ' pt', default: 340 },
    },
    examples: [{ label: 'On coral', ground: 'coral', props: {} }],
    render(p, ctx) {
      const s = 0.82 + 0.18 * +p.breath;
      const rings = [0, 1, 2].map((r) => {
        const d = (170 + r * 60) * s;
        return `<div style="position:absolute;left:50%;top:50%;width:${d}px;height:${d}px;margin:${-d / 2}px 0 0 ${-d / 2}px;border-radius:50%;background:rgba(255,248,238,${(0.16 - r * 0.04).toFixed(2)})"></div>`;
      }).reverse().join('');
      return `<div style="position:relative;height:${p.height}px;line-height:0">${rings}<div style="position:absolute;inset:0;display:flex;align-items:center;justify-content:center">${Lab.art(p.character, { size: +p.size })}</div></div>`;
    },
  });

  /* ---------- F02 Welcome ---------- */
  E({
    type: 'onbWelcomeHero', name: 'Welcome hero', group: 'Onboarding', source: V4S + ' (WelcomeScreen)',
    description: 'HeroScene at dawn (prep clarity 20) under the status bar, 360 pt (240 at accessibility sizes), with Xero at hero size 18 pt up from the paper edge and his cream "Hi! I\'m Xero." callout.',
    props: {
      height: { label: 'Height', kind: 'number', options: [240, 300, 360, 400], unit: ' pt', default: 360 },
      scene: { label: 'Sky', kind: 'select', default: 'dawn', options: [['dawn', 'Dawn'], ['path', 'Path'], ['dusk', 'Dusk'], ['sea', 'Sea'], ['night', 'Night']] },
      clarity: { label: 'Sky clarity', kind: 'number', options: [20, 28, 40, 60, 100], default: 20 },
      character: { label: 'Character', kind: 'art', default: 'xero:hello' },
      bubble: { label: 'Callout', kind: 'bool', labels: ['Show', 'Hide'], default: true },
      text: { label: 'Callout words', kind: 'text', default: "Hi! I'm Xero." },
    },
    examples: [{ label: 'Apricot', ground: 'apricot', props: { height: 300 } }],
    render(p, ctx) {
      const w = ctx.width || 402;
      const sky = Lab.art('extra:hero', { width: w, height: +p.height, radius: 0, scene: { kind: p.scene, clarity: +p.clarity, edge: ctx.g.bg } });
      const xs = 200, xl = (w - xs) / 2, xb = 18;
      const bubble = p.bubble ? `<div style="position:absolute;right:${w - (xl + xs) - 70}px;top:${+p.height - xb - xs + 10}px;${F('headline')}color:${NAVY};background:${CREAM};padding:10px 14px;border-radius:18px 18px 18px 4px;white-space:nowrap;line-height:1.2">${esc(p.text)}</div>` : '';
      return `<div style="position:relative;height:${p.height}px;overflow:hidden;line-height:0;flex:none">${sky}<div style="position:absolute;left:${xl}px;bottom:${xb}px;line-height:0">${Lab.art(p.character, { size: xs })}</div>${bubble}</div>`;
    },
  });

  /* ---------- F04 Quit Day ---------- */
  E({
    type: 'onbQuitHero', name: 'Quit Day hero', group: 'Onboarding', source: V4S + ' (QuitDayScreen)',
    description: 'HeroScene at dawn, 250 pt under the status bar, Xero at scene size (140 pt) 14 pt up from the edge, and a back button (cream at 85%, navy chevron) 54 pt from the top.',
    props: {
      height: { label: 'Height', kind: 'number', options: [200, 220, 250, 280, 300], unit: ' pt', default: 250 },
      character: { label: 'Character', kind: 'art', default: 'xero:hello' },
      size: { label: 'Character size', kind: 'number', options: [88, 120, 140, 160], unit: ' pt', default: 140 },
      back: { label: 'Back button', kind: 'bool', labels: ['Show', 'Hide'], default: true },
    },
    examples: [{ label: 'Apricot', ground: 'apricot', props: {} }],
    render(p, ctx) {
      const w = ctx.width || 402;
      const sky = Lab.art('extra:hero', { width: w, height: +p.height, radius: 0, scene: { kind: 'dawn', clarity: 20, edge: ctx.g.bg } });
      const back = p.back ? `<div role="button" aria-label="Back" style="position:absolute;left:20px;top:54px;width:44px;height:44px;border-radius:50%;background:rgba(255,248,238,0.85);display:flex;align-items:center;justify-content:center">${Lab.icon('chevron.left', 16, NAVY)}</div>` : '';
      return `<div style="position:relative;height:${p.height}px;overflow:hidden;line-height:0;flex:none">${sky}<div style="position:absolute;left:0;right:0;bottom:14px;display:flex;justify-content:center;line-height:0">${Lab.art(p.character, { size: +p.size })}</div>${back}</div>`;
    },
  });

  /* Sam joins on Fri 30 Oct 2026; the recommended Quit Day is a week later, Fri 6 Nov (earliest 6 Nov, latest 29 Nov). */
  const WD = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const STRIP = [['Fri', 30], ['Sat', 31], ['Sun', 1], ['Mon', 2], ['Tue', 3], ['Wed', 4], ['Thu', 5], ['Fri', 6]];
  const QUIT_OPTS = Array.from({ length: 24 }, (_, i) => { const n = 6 + i; return [n, `${WD[(4 + i) % 7]} ${n} Nov${n === 6 ? ' (recommended)' : ''}`]; });

  E({
    type: 'onbDateStrip', name: 'Quit Day strip', group: 'Onboarding', source: V4S + ' (QuitDayScreen.dateStrip)',
    description: 'The eight days from today to the recommended Quit Day: 12 pt weekday over a 19 pt date, 58 pt tall, radius 14, 4 pt apart. Prep days on card-on-colour, Quit Day in ink. Only days from a week out can be picked.',
    props: {
      quit: { label: 'Quit Day', kind: 'select', default: 6, options: QUIT_OPTS },
      gap: { label: 'Gap', kind: 'number', options: [2, 4, 6, 8], unit: ' pt', default: 4, global: true },
    },
    examples: [{ label: 'Sam', ground: 'apricot', props: {} }],
    render(p, ctx) {
      const q = +p.quit;
      const cells = STRIP.map(([wd, n], i) => {
        const quit = i === 7 && q === 6;
        const prep = i < 7 || (i === 7 && q > 6);
        const bg = quit ? ctx.g.ink : prep ? Lab.c(Lab.fill.cardOnColour, ctx.dark) : 'transparent';
        const fg = quit ? ctx.g.bg : ctx.g.ink;
        return `<div role="button" style="flex:1 1 0;min-width:0;min-height:58px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:2px;border-radius:14px;background:${bg};color:${fg}"><div style="${F('caption')}">${wd}</div><div style="${F('headline')}">${n}</div></div>`;
      }).join('');
      return `<div style="display:flex;gap:${p.gap}px">${cells}</div>`;
    },
  });

  E({
    type: 'onbLegend', name: 'Strip legend', group: 'Onboarding', source: V4S + ' (QuitDayScreen.legend)',
    description: 'A 14 pt swatch (radius 4) and a caption in the muted colour.',
    props: {
      swatch: { label: 'Swatch', kind: 'select', default: 'card', options: [['card', 'Card on colour (prep days)'], ['ink', 'Ink (Quit Day)']] },
      text: { label: 'Words', kind: 'text', default: 'Prep week · 7 days' },
    },
    examples: [{ label: 'Prep', ground: 'apricot', props: {} }],
    render(p, ctx) {
      const c = p.swatch === 'ink' ? ctx.g.ink : Lab.c(Lab.fill.cardOnColour, ctx.dark);
      return `<div style="display:flex;align-items:center;gap:6px"><div style="width:14px;height:14px;border-radius:4px;flex:none;background:${c}"></div><div style="${F('caption')}color:${ctx.g.muted}">${esc(p.text)}</div></div>`;
    },
  });

  E({
    type: 'onbSheetBar', name: 'Sheet title bar', group: 'Onboarding', source: V4S + ' (QuitDayScreen sheet)',
    description: 'The navigation bar of the "Pick another date" sheet: an inline 17 pt title and a bold Done on the right.',
    props: { title: { label: 'Title', kind: 'text', default: 'Pick your Quit Day' }, action: { label: 'Button', kind: 'text', default: 'Done' } },
    examples: [{ label: 'Quit Day', ground: 'reading', props: {} }],
    render(p, ctx) {
      const r = Lab.ground('reading', ctx.dark);
      return `<div style="display:grid;grid-template-columns:1fr auto 1fr;align-items:center;min-height:44px"><div></div><div style="${F('body', { size: 17, weight: 600 })}color:${r.ink}">${esc(p.title)}</div><div role="button" style="justify-self:end;${F('body', { size: 17, weight: 600 })}color:${r.ink}">${esc(p.action)}</div></div>`;
    },
  });

  E({
    type: 'onbCalendar', name: 'Quit Day calendar', group: 'Onboarding', source: PLAN + ' (QuitDayCalendar)',
    description: 'Weeks from this one to the last allowed Quit Day. Prep days are one soft-green track into Quit Day (a 40 pt green circle with a glow); today has a green ring. On white with a hairline, radius 18, 16 pt padding.',
    props: {
      quit: { label: 'Quit Day', kind: 'select', default: 6, options: QUIT_OPTS },
      header: { label: 'Months', kind: 'text', default: 'Oct – Nov 2026' },
    },
    examples: [{ label: 'Sam', ground: 'reading', props: {} }],
    render(p, ctx) {
      const o = O(ctx);
      const q = +p.quit;
      // Mon 26 Oct to Sun 29 Nov 2026 (weeks start on Monday). Index 4 is today, Fri 30 Oct.
      const days = Array.from({ length: 35 }, (_, i) => (i < 6 ? { n: 26 + i, m: 10 } : { n: i - 5, m: 11 }));
      const idxQuit = 5 + q;
      const isPrep = (i) => i >= 4 && i < idxQuit;
      const legend = (t) => `<div style="display:flex;align-items:center;gap:5px;padding-left:12px"><div style="width:7px;height:7px;border-radius:50%;background:${o.accent}"></div><div style="${F('caption', { size: 12, weight: 400 })}color:${o.muted}">${esc(t)}</div></div>`;
      const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((s) => `<div style="flex:1;text-align:center;${F('caption', { size: 12, weight: 600 })}color:${o.muted}">${s}</div>`).join('');
      const rows = [0, 1, 2, 3, 4].map((w) => `<div style="display:flex">${[0, 1, 2, 3, 4, 5, 6].map((c) => {
        const i = w * 7 + c, d = days[i];
        const quit = i === idxQuit, prep = isPrep(i), today = i === 4;
        const starts = c === 0 || !isPrep(i - 1), ends = c === 6 || !isPrep(i + 1);
        const tint = prep ? `<div style="position:absolute;inset:0;background:${o.accentSoft};border-radius:${starts ? 20 : 0}px ${ends ? 20 : 0}px ${ends ? 20 : 0}px ${starts ? 20 : 0}px"></div>` : '';
        const mark = quit ? `<div style="position:absolute;left:50%;top:50%;width:40px;height:40px;margin:-20px 0 0 -20px;border-radius:50%;background:${o.accent};box-shadow:0 0 10px ${o.accentA(0.6)}"></div>`
          : today ? `<div style="position:absolute;left:50%;top:50%;width:34px;height:34px;margin:-17px 0 0 -17px;border-radius:50%;box-shadow:inset 0 0 0 1.5px ${o.accent}"></div>` : '';
        const colour = quit ? o.onInk : prep ? o.ink : o.muted;
        return `<div role="button" style="flex:1;padding:2px 0"><div style="position:relative;height:40px;display:flex;align-items:center;justify-content:center">${tint}${mark}<span style="position:relative;${F('body', { size: 15, weight: quit || prep || today ? 700 : 400 })}color:${colour}">${d.n}</span></div></div>`;
      }).join('')}</div>`).join('');
      return `<div style="display:flex;flex-direction:column;gap:10px;padding:16px;border-radius:18px;background:${o.raised};box-shadow:inset 0 0 0 1px ${o.hairline}">
        <div style="display:flex;align-items:center"><div style="flex:1;${F('body', { size: 15, weight: 600 })}color:${o.ink}">${esc(p.header)}</div>${legend('Prep')}${legend('Quit Day')}</div>
        <div style="display:flex">${weekdays}</div>${rows}</div>`;
    },
  });

  /* ---------- F05 Building, F06 Reveal ---------- */
  E({
    type: 'onbFriends', name: 'Two friends card', group: 'Onboarding', source: V4S + ' (BuildingScreen)',
    description: "Jelli and Glim as 40 pt avatars overlapping by 10 pt, and a 14 pt line with their names in bold, on card-on-colour (radius 18, 16 pt padding).",
    props: { text: { label: 'Words', kind: 'text', default: 'Two friends join later. **Jelli** at your first craving, **Glim** on your first evening.' } },
    examples: [{ label: 'On mint', ground: 'mint', props: {} }],
    render(p, ctx) {
      const c = inert(ctx);
      const av = (art, g) => Lab.render(Lab.h('onbAvatar', '_' + g, { art, ground: g }), c);
      return `<div style="display:flex;align-items:center;gap:12px;padding:16px;border-radius:18px;background:${ctx.g.card}"><div style="display:flex;flex:none">${av('jelli:hello', 'ocean')}<div style="margin-left:-10px">${av('glim:hello', 'violet')}</div></div><div style="flex:1;min-width:0;${F('footnote')}color:${ctx.g.ink}">${rich(p.text, ctx, ctx.g.ink)}</div></div>`;
    },
  });

  E({
    type: 'onbSavings', name: 'Money card', group: 'Onboarding', source: V4S + ' (PlanRevealScreen.savings)',
    description: '"MONEY YOU\'LL KEEP IN YEAR 1" over the yearly amount in 40 pt display, on card-on-colour, radius 24, 16 pt padding.',
    props: { label: { label: 'Label', kind: 'text', default: "Money you'll keep in year 1" }, value: { label: 'Amount', kind: 'text', default: '$2,555' } },
    examples: [{ label: 'On mint', ground: 'mint', props: {} }],
    render(p, ctx) {
      return `<div style="display:flex;flex-direction:column;gap:4px;padding:16px;border-radius:24px;background:${ctx.g.card}">${T('caption', p.label, ctx, { tone: 'muted' })}${T('display', p.value, ctx, { style: 'white-space:nowrap' })}</div>`;
    },
  });

  E({
    type: 'onbTrialCard', name: 'Quit Day trial card', group: 'Onboarding', source: V4S + ' (PlanRevealScreen.trialCard)',
    description: 'Navy in both appearances, radius 24, 16 pt padding, 6 pt gaps: the Quit Day kicker, the trial offer in 19 pt cream, the monthly price, and the dates and how to cancel in 12 pt.',
    props: {
      kicker: { label: 'Kicker', kind: 'text', default: 'On your Quit Day · Fri 6 Nov' },
      title: { label: 'Offer', kind: 'text', default: '3 days free, then $39.99 a year' },
      line: { label: 'Monthly line', kind: 'text', default: "That's $3.33 a month. We'll ask you on Quit Day, not before." },
      detail: { label: 'Dates line', kind: 'text', default: "If you start the trial on Fri 6 Nov it runs to Mon 9 Nov, and we'll remind you on Sat 7 Nov. Cancel any time in Settings › Apple ID › Subscriptions." },
    },
    examples: [{ label: 'Sam', ground: 'mint', props: {} }],
    render(p) {
      const soft = 'rgba(255,248,238,0.85)';
      return `<div style="display:flex;flex-direction:column;gap:6px;padding:16px;border-radius:24px;background:${NAVY}">
        <div style="${F('caption')}color:${soft};text-transform:uppercase">${esc(p.kicker)}</div>
        <div style="${F('headline')}color:${CREAM}">${esc(p.title)}</div>
        ${p.line ? `<div style="${F('footnote')}color:${soft}">${esc(p.line)}</div>` : ''}
        <div style="${F('caption')}color:${soft}">${esc(p.detail)}</div></div>`;
    },
  });

  /* ---------- F07 Reminders ---------- */
  E({
    type: 'onbNotification', name: 'Reminder preview', group: 'Onboarding', source: 'DayXeroCore/DesignSystem/V4/Cards4.swift (NotificationPreview), ' + V4S,
    description: "A cream notification card: the crew member's 40 pt avatar on their colour (radius 10), DAYXERO · NAME and the time, and the message in 14 pt navy.",
    props: {
      sender: { label: 'Character', kind: 'text', default: 'Xero' },
      time: { label: 'Time', kind: 'text', default: '08:00' },
      message: { label: 'Message', kind: 'text', default: "Good morning. Ten seconds for today's pledge?" },
      avatar: { label: 'Avatar', kind: 'art', default: 'xero:hello' },
      avatarGround: { label: 'Avatar colour', kind: 'ground', default: 'apricot' },
    },
    examples: [{ label: 'Xero', ground: 'apricot', props: {} }],
    render(p, ctx) {
      return `<div style="display:flex;align-items:flex-start;gap:12px;padding:14px;border-radius:20px;background:${CREAM}">
        <div style="width:40px;height:40px;border-radius:10px;overflow:hidden;flex:none;line-height:0;background:${groundBg(p.avatarGround, ctx)}">${Lab.art(p.avatar, { size: 40, animate: false })}</div>
        <div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:2px"><div style="display:flex;justify-content:space-between;gap:8px;${F('caption')}color:#5E5975"><span>DAYXERO · ${esc(String(p.sender).toUpperCase())}</span><span>${esc(p.time)}</span></div><div style="${F('footnote')}color:${NAVY}">${esc(p.message)}</div></div></div>`;
    },
  });

  E({
    type: 'onbFooter', name: 'Pinned footer', group: 'Onboarding', source: FLOW + ' (OnboardingScaffold)',
    description: 'The buttons pinned under the scroll: 22 pt sides, 8 pt above the home indicator, on the screen colour so the scroll ends at its top edge.',
    props: {
      gap: { label: 'Gap between items', kind: 'number', options: [0, 4, 6, 8, 12, 16], unit: ' pt', default: 8 },
      padX: { label: 'Side padding', kind: 'number', options: [16, 20, 22, 24, 28], unit: ' pt', default: 22, global: true },
      padBottom: { label: 'Space above the home indicator', kind: 'number', options: [0, 4, 8, 12, 16, 20], unit: ' pt', default: 8, global: true },
    },
    examples: [{ label: 'Continue on lilac', ground: 'lilac', props: {}, kids: [['button', { label: 'Continue' }]] }],
    render(p, ctx, kids) {
      const pos = ctx.screenId === '_lib' ? '' : 'position:absolute;left:0;right:0;bottom:0;z-index:4;';
      const bottom = (ctx.device ? ctx.device.bottom : 34) + +p.padBottom;
      return `<div style="${pos}display:flex;flex-direction:column;align-items:stretch;gap:${p.gap}px;padding:0 ${p.padX}px ${ctx.screenId === '_lib' ? 0 : bottom}px;background:${ctx.g.bg}">${kids()}</div>`;
    },
  });

  /* =====================================================================
     Screens. Sam (design/handoff/tokens.json → persona): joins Fri 30 Oct 2026, cigarettes 12 a day and a vape,
     first use 6–30 min after waking, Coffee and Stress, "To keep up with Maya at the park", Quit Day Fri 6 Nov.
     Money is the persona's $7 a day ($2,555 a year), so the baselines are: cigarettes $10 a 20 pack ($6 a day)
     and the vape 1 pod a week at $7, 600 puffs, 5% ($1 a day). USD prices, en-GB dates and clock.
     ===================================================================== */
  // OnboardingModel.sequence for Sam: welcome, products, baseline ×2, summary, triggers, personal, past attempts, NRT,
  // Quit Day, building, reveal, trial — 13 steps, so progress is index / 12.
  const step = (i) => +(i / 12).toFixed(3);
  const slug = (s) => String(s).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');

  /** OnboardingSection: a caption over its controls, 10 pt apart, 12 pt above. */
  const section = (h, id, title, kids, alts) => h('stack', id, { gap: 10, padTop: 12 }, [h('text', id + '-title', { step: 'caption', tone: 'muted', text: title, alts: alts ? { text: alts } : undefined })].concat(kids));
  const segments = (h, id, labels, picked, scale) => h('row', id, { gap: 8, align: 'stretch' }, labels.map((l, i) => h('onbSegment', id + '-' + (i + 1), { label: l, on: picked === l, scale: scale || 1 })));
  const chips = (h, id, labels, picked) => h('row', id, { gap: 8, wrap: true }, labels.map((l) => h('onbChip', id + '-' + slug(l), { label: l, on: (picked || []).includes(l) })));

  /** OnboardingFlow top bar + OnboardingScaffold: Xero's bubbles, the answer tray, a pinned footer. */
  function scaffold(h, o) {
    return [
      o.topBar === false ? null : h('stack', 'top-bar-wrap', { padX: 20, padTop: 8 }, [h('onbTopBar', 'top-bar', { back: true, value: o.progress })]),
      h('stack', 'question', { padX: 20, padTop: 16, padBottom: 24, gap: 10 }, [
        o.eyebrow ? h('text', 'eyebrow', { step: 'caption', tone: 'muted', text: o.eyebrow, alts: o.eyebrowAlts ? { text: o.eyebrowAlts } : undefined }) : null,
        h('onbBubble', 'ask', { text: o.title, large: true }),
        o.subtitle ? h('onbBubble', 'ask-more', { text: o.subtitle, large: false, alts: o.subtitleAlts ? { text: o.subtitleAlts } : undefined }) : null,
        h('stack', 'tray-wrap', { padTop: 8 }, [h('onbTray', 'tray', {}, o.tray)]),
      ]),
      // Room so the end of the scroll clears the pinned footer.
      h('spacer', 'footer-room', { size: o.room || 52 }),
    ];
  }
  /** A question screen: build() draws the scroll, overlay() the pinned footer (22 pt sides, 8 pt gaps). */
  function qscreen(def) {
    def.build = (h, state) => scaffold(h, def.spec(h, state));
    def.overlay = (h, state) => h('onbFooter', 'footer', { gap: 8 }, def.spec(h, state).footer);
    return Lab.screen(def);
  }
  const cont = (h, label, disabled, alts) => h('button', 'continue', { label, disabled: !!disabled, alts: alts ? { label: alts } : undefined });

  /* ---------- F01 Breathe ---------- */
  Lab.screen({
    id: 'onb-breathe', name: 'Breathe', area: 'Onboarding', source: V4S + ' (BreatheScreen)', ground: 'coral',
    note: 'F01: one slow breath before any question, shown once before Welcome. Skip fades in after one full 10 s breath; the screen moves on by itself after a second. The rings and words breathe on the 4 s in, 6 s out clock (drawn still here at the halfway point, as with Reduce Motion).',
    states: [{ id: 'in', label: 'First breath · Skip hidden' }, { id: 'skip', label: 'After 10 s · Skip shown' }],
    build(h, state) {
      return h('stack', 'body', { padTop: 12, padBottom: 12, style: 'flex:1' }, [
        h('row', 'skip-row', { padX: 20, justify: 'flex-end', style: state.id === 'skip' ? '' : 'opacity:0' }, [h('button', 'skip', { label: 'Skip', kind: 'quiet' })]),
        h('spacer', 'top-space', { flex: true, size: 12 }),
        h('onbBreatheOrb', 'orb', {}),
        h('stack', 'words-wrap', { padTop: 8 }, [h('breathingWords', 'words', { inhale: 'Breathe in', exhale: '…and out' })]),
        h('stack', 'line-wrap', { padX: 40, padTop: 10 }, [h('text', 'line', { step: 'body', tone: 'muted', align: 'center', text: 'One slow breath before we begin. In for 4, out for 6.' })]),
        h('spacer', 'bottom-space', { flex: true, size: 0 }),
      ]);
    },
  });

  /* ---------- F02 Welcome ---------- */
  Lab.screen({
    id: 'onb-welcome', name: 'Welcome', area: 'Onboarding', source: V4S + ' (WelcomeScreen)', ground: 'apricot', fullBleed: true,
    note: "F02. Xero rises, the callout appears after 1.3 s and he cheers once. Continuing confirms 18+. The legal line links only Terms until AppLinks has a Privacy Policy URL (the longer line is in the dropdown). \"Restore purchases\" shows one of three notes after it runs. At accessibility text sizes the page scrolls and the hero is 240 pt.",
    states: [{ id: 'hello', label: 'Hello' }, { id: 'restore', label: 'After Restore purchases' }],
    build(h, state) {
      const words = h('stack', 'words', { padX: 22, gap: 10, style: 'flex:1;padding-bottom:8px;margin-bottom:-4px' }, [
        h('stack', 'title', { gap: 0 }, [
          h('text', 'title-1', { step: 'large', text: "Don't quit today." }),
          h('text', 'title-2', { step: 'large', text: 'Quit on your Quit Day.' }),
        ]),
        h('text', 'promise', { step: 'body', tone: 'muted', text: 'Prep for 7 days while you still use as normal, then quit on the day you choose.' }),
        state.id === 'restore' ? h('text', 'restore-note', {
          step: 'footnote', tone: 'muted', text: 'Your purchase is restored. Set up your plan and everything is unlocked.',
          alts: { text: ['No purchases found for this Apple ID.', "Couldn't reach the App Store. You can restore later in Settings."] },
        }) : null,
        h('spacer', 'push', { flex: true, size: 8 }),
        h('button', 'start', { label: 'Get started' }),
        h('button', 'restore', { label: 'Restore purchases', kind: 'quiet' }),
        h('onbRichText', 'legal', {
          step: 'caption', tone: 'muted', align: 'center',
          text: "Takes 2 minutes and stays private on this phone. By continuing you confirm you're 18+ and agree to the [Terms].",
          alts: { text: ["Takes 2 minutes and stays private on this phone. By continuing you confirm you're 18+ and agree to the [Terms] and [Privacy Policy]."] },
        }),
      ]);
      return [h('onbWelcomeHero', 'hero', { character: 'xero:hello' }), words];
    },
  });

  /* ---------- Screen 2: products ---------- */
  qscreen({
    id: 'onb-products', name: 'What you use', area: 'Onboarding', source: INTRO + ' (ProductsScreen)', ground: 'lilac',
    note: 'Screen 2 (S22). Pick any; Continue is at half strength until one is picked. The dual-use note slides in when more than one is picked. Progress is step 1 of 12 for Sam (1 of 10 before anything is picked, as the baselines are not in the flow yet).',
    states: [{ id: 'empty', label: 'Nothing picked' }, { id: 'sam', label: "Sam's picks · cigarettes and vape" }],
    spec(h, state) {
      const sam = state.id === 'sam';
      return ({
        progress: sam ? step(1) : 0.1,
        title: 'What are we leaving behind?',
        subtitle: "Pick everything you use now. We'll set up your counters and biology for each one.",
        tray: [
          h('onbOption', 'cigarettes', { title: 'Cigarettes', detail: 'Manufactured or roll-ups', icon: 'smoke', selected: sam }),
          h('onbOption', 'vape', { title: 'Vape or e-cigarette', detail: 'Disposables, pods or refillable tanks', icon: 'wind', selected: sam }),
          h('onbOption', 'pouches', { title: 'Nicotine pouches or snus', detail: 'Zyn, Velo or other oral pouches', icon: 'capsule', selected: false }),
          sam ? h('stack', 'dual-wrap', { padTop: 12 }, [h('onbDualUse', 'dual-use', {})]) : null,
        ],
        footer: [cont(h, 'Continue', !sam)],
      });
    },
  });

  /* ---------- Screens 3–4: baselines ---------- */
  const YEARS = ['< 1 yr', '1–3 yrs', '3–5 yrs', '5+ yrs'];
  qscreen({
    id: 'onb-baseline-cigarettes', name: 'Baseline · cigarettes', area: 'Onboarding', source: DETAIL + ' (BaselineScreen)', ground: 'lilac',
    note: 'Screen 3 (S22), once per product picked. Opens at 10 a day with the middle US pack price ($10 for 20); Sam moves it to 12 and picks 3–5 years. Pack prices follow the region (USD: $8, $10, $12); "Custom" opens a price field. "Loose" turns the section into "Price of one cigarette". The summary line updates as the numbers change.',
    states: [{ id: 'start', label: 'As it opens · 10 a day' }, { id: 'sam', label: 'Sam · 12 a day, 3–5 yrs' }],
    spec(h, state) {
      const sam = state.id === 'sam';
      return ({
        progress: step(2),
        eyebrow: 'Cigarettes · step 1 of 2', eyebrowAlts: ['Cigarettes'],
        title: 'How much do you smoke?',
        subtitle: 'A rough estimate is fine, with zero judgement. You can change it any time.',
        tray: [
          h('onbStepper', 'amount', { value: sam ? '12' : '10', unit: 'cigarettes a day' }),
          section(h, 'pack', 'Pack price and size', [
            segments(h, 'price', ['$8', '$10', '$12', 'Custom'], '$10'),
            segments(h, 'size', ['10 pack', '20 pack', 'Loose'], '20 pack'),
          ], ['Price of one cigarette']),
          section(h, 'years', 'How long have you smoked?', [segments(h, 'years-chips', YEARS, sam ? '3–5 yrs' : null)]),
          h('stack', 'summary-wrap', { padTop: 12 }, [h('onbSummary', 'summary', { text: sam ? '$2,190 a year · about 14 mg nicotine a day' : '$1,825 a year · about 12 mg nicotine a day' })]),
        ],
        footer: [cont(h, 'Next: your vape', false, ['Next: nicotine pouches', 'Continue', 'Calculate my baseline'])],
      });
    },
  });

  qscreen({
    id: 'onb-baseline-vape', name: 'Baseline · vape', area: 'Onboarding', source: DETAIL + ' (BaselineScreen)', ground: 'lilac',
    note: 'Screen 4 (S22). Vapers say pods or disposables a week (stepping by half a pod), stored as puffs a day; "By daily puffs" counts puffs instead (stepping by 10). It opens at 2 pods a week at the US price ($10, 600 puffs, 5% where 50 mg/ml is sold). Assumed for Sam: 1 pod a week at $7, so his money totals the persona\'s $7 a day. "By pods or disposables" shrinks to fit (the app allows down to 75%); it is drawn at 90% (12.6 pt) here, about what fits.',
    states: [{ id: 'start', label: 'As it opens · 2 pods a week' }, { id: 'sam', label: 'Sam · 1 pod at $7, 1–3 yrs' }],
    spec(h, state) {
      const sam = state.id === 'sam';
      return ({
        progress: step(3),
        eyebrow: 'Vape · step 2 of 2', eyebrowAlts: ['Vape'],
        title: 'Tell us about your vape',
        subtitle: 'Vape strength varies up to 5×. This sets your real nicotine load.',
        tray: [
          segments(h, 'mode', ['By pods or disposables', 'By daily puffs'], 'By pods or disposables', 0.9),
          h('onbStepper', 'amount', { value: sam ? '1' : '2', unit: 'pods or disposables a week', alts: { unit: ['puffs a day'] } }),
          section(h, 'strength', 'Nicotine strength (check your pod or box)', [chips(h, 'strength-chips', ['0.6–1.2% · Low', '2% · 20 mg', '3% · 30 mg', '5% · 50 mg', 'Not sure'], ['5% · 50 mg'])]),
          section(h, 'price', 'Price of one', [h('onbPriceStepper', 'price-stepper', { price: sam ? '$7' : '$10' })]),
          section(h, 'puffs', 'Puffs in one', [segments(h, 'puffs-chips', ['600', '1,500', '5,000+'], '600')]),
          section(h, 'years', 'How long have you vaped?', [segments(h, 'years-chips', YEARS, sam ? '1–3 yrs' : null)]),
          h('stack', 'summary-wrap', { padTop: 12 }, [h('onbSummary', 'summary', { text: sam ? '$365 a year · about 10 mg nicotine a day' : '$1,043 a year · about 21 mg nicotine a day' })]),
        ],
        footer: [cont(h, 'Calculate my baseline', false, ['Continue', 'Next: nicotine pouches'])],
      });
    },
  });

  /* ---------- Screen 5: baseline summary ---------- */
  qscreen({
    id: 'onb-baseline-summary', name: 'Your baseline', area: 'Onboarding', source: DETAIL + ' (BaselineSummaryScreen)', ground: 'lilac',
    note: "Screen 5. Sam's numbers: 14.4 mg from 12 cigarettes plus 10.3 mg from about 86 puffs (1 pod a week, 600 puffs, 5%) ≈ 21 cigarettes' worth; $2,555 a year ($7 a day); 438 + 52 = 490 hours a year (6 min a cigarette, 6 s a puff). The navy card is navy in both appearances. Without a vape the subtitle is \"Seeing it in one place is the first step.\"; pouch-only users get \"In 5 years\" instead of \"Time back\". The small print is 11 pt in the code, which the app's font helper raises to 12.",
    states: [{ id: 'sam', label: 'Sam · cigarettes and vape' }],
    spec(h) {
      return ({
        progress: step(4),
        eyebrow: 'Your baseline',
        title: "Here's what your body processes every day",
        subtitle: 'Most people underestimate vaping, because a vape never burns out like a cigarette.',
        subtitleAlts: ['Seeing it in one place is the first step.'],
        tray: [
          h('onbLoadCard', 'load', { label: 'Total daily nicotine load', value: '≈ 21', unit: 'cigarettes a day', alts: { unit: ['cigarette a day'] } }, [
            h('onbLoadRow', 'load-cigarettes', { icon: 'smoke', line: '12 cigarettes', detail: 'About 14 mg nicotine absorbed' }),
            h('onbLoadRow', 'load-vape', { icon: 'wind', line: '~86 vape puffs at 5%', detail: 'About 9 cigarettes’ worth of nicotine', alts: { line: ['~86 vape puffs'] } }),
          ]),
          h('row', 'tiles', { gap: 12, align: 'stretch' }, [
            h('onbStatTile', 'tile-money', { icon: 'creditcard', label: 'Yearly drain', value: '$2,555', detail: '$7 gone every day' }),
            h('onbStatTile', 'tile-time', { icon: 'hourglass', label: 'Time back', value: '490 hours', detail: '20 full days a year', alts: { label: ['In 5 years'], value: ['$12,775'], detail: ["At today's prices"] } }),
          ]),
          h('onbNote', 'good-news', {}),
          h('text', 'small-print', { step: 'caption', size: 12, weight: 400, upper: false, tone: 'muted', text: 'Rough estimates for comparison. Real intake varies with your product and how you use it.' }),
        ],
        footer: [cont(h, 'Continue')],
      });
    },
  });

  /* ---------- Screen 6: triggers ---------- */
  const TRIGGERS = ['Waking up', 'Coffee', 'After meals', 'Stress', 'Drinking', 'Boredom', 'With friends', 'Driving', 'Work breaks', 'On my phone', 'Something else'];
  qscreen({
    id: 'onb-triggers', name: 'When cravings hit', area: 'Onboarding', source: DETAIL + ' (TriggersScreen)', ground: 'lilac',
    note: 'Screen 6. Continue needs a first-use answer and at least one trigger. The clock line appears when the first use is within 30 minutes of waking. Sam: 6–30 min, Coffee and Stress.',
    states: [{ id: 'empty', label: 'Nothing picked' }, { id: 'sam', label: "Sam's picks · 6–30 min, Coffee, Stress" }],
    spec(h, state) {
      const sam = state.id === 'sam';
      return ({
        progress: step(5),
        title: 'When do cravings hit hardest?',
        subtitle: "We'll time your prep check-ins and defences around your biggest moments.",
        tray: [
          section(h, 'first-use', 'How soon after waking do you first use?', [
            h('stack', 'first-use-rows', { gap: 8 }, [
              segments(h, 'first-use-a', ['Within 5 min', '6–30 min'], sam ? '6–30 min' : null),
              segments(h, 'first-use-b', ['31–60 min', 'After 60 min'], null),
            ]),
          ]),
          section(h, 'sets-off', 'What sets you off? Pick any that apply', [chips(h, 'trigger', TRIGGERS, sam ? ['Coffee', 'Stress'] : [])]),
          sam ? h('stack', 'early-wrap', { padTop: 12 }, [h('onbLabel', 'early', {})]) : null,
        ],
        footer: [cont(h, 'Continue', !sam)],
      });
    },
  });

  /* ---------- Screen 7: name and reason ---------- */
  qscreen({
    id: 'onb-personal', name: 'Make this personal', area: 'Onboarding', source: DETAIL + ' (PersonalScreen)', ground: 'lilac',
    note: 'Screen 7. "Save my reason" needs a name and a reason. Each starter chip adds its sentence to the reason ("Save $2.6K a year" adds "Keep the $2.6K a year I spend on nicotine."); a chip shows picked while its sentence is in the text. The photo row opens Photos; with a photo it reads "Photo added. Tap to change it".',
    states: [{ id: 'empty', label: 'Empty' }, { id: 'sam', label: 'Sam · name and reason typed' }],
    spec(h, state) {
      const sam = state.id === 'sam';
      return ({
        progress: step(6),
        title: 'Make this personal',
        subtitle: 'Your name and your reason. Both stay on this phone.',
        tray: [
          section(h, 'name', 'First name or nickname', [h('onbField', 'name-field', { placeholder: 'Your name', value: sam ? 'Sam' : '' })]),
          section(h, 'why', sam ? 'Why are you quitting, Sam?' : 'Why are you quitting?', [
            h('onbField', 'why-field', { placeholder: 'Write it in your own words, or tap a reason below', value: sam ? 'To keep up with Maya at the park' : '', tall: true }),
            h('text', 'why-hint', { step: 'caption', size: 12, weight: 400, upper: false, tone: 'muted', text: "When a craving hits, we'll show you this." }),
          ], sam ? ['Why are you quitting?'] : ['Why are you quitting, Sam?']),
          section(h, 'starters', 'Tap to add to your reason', [chips(h, 'starter', ['Save $2.6K a year', 'Breathe easier', 'Be there for family', 'More energy', 'Break the chain'], [])]),
          h('stack', 'photo-wrap', { padTop: 12 }, [h('onbPhotoRow', 'photo', { alts: { title: ['Photo added. Tap to change it'] } })]),
        ],
        footer: [cont(h, 'Save my reason', !sam)],
      });
    },
  });

  /* ---------- Screen 8: past attempts ---------- */
  const OBSTACLES = ['Cravings', 'Stress', 'Social situations', 'Irritability', 'Weight', 'Sleep', 'Lost motivation', 'Other'];
  const FEEDBACK = ['Nervous is normal. Prep is built for exactly this.', "Totally normal. That's why we prepare first.", 'Great. Prep turns that into a plan.'];
  qscreen({
    id: 'onb-past-attempts', name: 'Tried before', area: 'Onboarding', source: DETAIL + ' (PastAttemptsScreen)', ground: 'lilac',
    note: 'Screen 8. "What got in the way most?" appears once an attempt other than "First time" is picked; Continue needs at least one there (or "First time"). Confidence starts at 5; the line changes under 4 and from 7. Sam: once or twice, Cravings and Stress, confidence left at 5 (the sample sets none).',
    states: [{ id: 'empty', label: 'Nothing picked' }, { id: 'sam', label: 'Sam · once or twice' }],
    spec(h, state) {
      const sam = state.id === 'sam';
      return ({
        progress: step(7),
        title: 'Have you tried to quit before?',
        subtitle: 'Every attempt is data, not failure. Tell us what tripped you up so we can block it this time.',
        tray: [
          section(h, 'attempts', 'Past attempts', [segments(h, 'attempts-chips', ['First time', 'Once or twice', 'Lots of times'], sam ? 'Once or twice' : null)]),
          sam ? section(h, 'obstacles', 'What got in the way most?', [chips(h, 'obstacle', OBSTACLES, ['Cravings', 'Stress'])]) : null,
          section(h, 'confidence', 'How confident do you feel right now?', [
            h('onbSlider', 'slider', { value: 5 }),
            h('row', 'slider-ends', { justify: 'space-between' }, [
              h('text', 'nervous', { step: 'caption', size: 12, weight: 400, upper: false, tone: 'muted', text: 'Nervous · 0' }),
              h('text', 'ready', { step: 'caption', size: 12, weight: 400, upper: false, tone: 'muted', text: 'Ready · 10' }),
            ]),
            h('onbConfidence', 'reply', { value: '5/10', text: FEEDBACK[1], alts: { text: [FEEDBACK[0], FEEDBACK[2]] } }),
          ]),
        ],
        footer: [cont(h, 'Continue', !sam)],
      });
    },
  });

  /* ---------- Screen 9: NRT ---------- */
  qscreen({
    id: 'onb-nrt', name: 'Nicotine replacement', area: 'Onboarding', source: DETAIL + ' (NRTScreen)', ground: 'lilac',
    note: 'Screen 9. The source pill opens the Cochrane summary. Picking "Yes, I\'m already using it" adds its detail line and the four formats below it. Sam (sample answers): already using patches and gum.',
    states: [{ id: 'empty', label: 'Nothing picked' }, { id: 'sam', label: 'Sam · using patch and gum' }],
    spec(h, state) {
      const sam = state.id === 'sam';
      return ({
        progress: step(8),
        title: 'Want to use nicotine replacement?',
        subtitle: 'Patches, gum and lozenges make quitting more likely by smoothing out physical withdrawal.',
        tray: [
          h('onbSourcePill', 'source', {}),
          h('stack', 'using-group', { gap: 0 }, [
            h('onbOption', 'using', { title: "Yes, I'm already using it", detail: sam ? 'Tell us what you use' : '', icon: '', selected: sam, alts: { detail: ['Tell us what you use'] } }),
            sam ? h('stack', 'formats-wrap', { padX: 6, padTop: 10 }, [chips(h, 'format', ['Patch', 'Gum', 'Lozenge', 'Spray or inhaler'], ['Patch', 'Gum'])]) : null,
          ]),
          h('onbOption', 'want', { title: "I'd like to try it", detail: "We'll suggest talking to a pharmacist", icon: '', selected: false }),
          h('onbOption', 'not-for-me', { title: 'Not for me', detail: 'Behavioural prep only', icon: '', selected: false }),
          h('stack', 'label-note-wrap', { padTop: 8 }, [h('text', 'label-note', { step: 'caption', size: 12, weight: 400, upper: false, tone: 'muted', text: 'Always follow the product label, and check with a pharmacist or doctor.' })]),
        ],
        footer: [cont(h, 'Continue', !sam)],
      });
    },
  });

  /* ---------- F04 Quit Day ---------- */
  Lab.screen({
    id: 'onb-quit-day', name: 'Pick your Quit Day', area: 'Onboarding', source: V4S + ' (QuitDayScreen), ' + PLAN, ground: 'apricot', fullBleed: true,
    note: 'F04. Sam joins Fri 30 Oct; the recommended (and earliest) Quit Day is a week later, Fri 6 Nov, and the latest is Sun 29 Nov. Days in the strip before 6 Nov can\'t be picked (the code disables them; drawn without dimming). Hold for 1.5 s to set it; the button fills left to right, then shows the done line and moves on after 0.8 s. "Pick another date" opens a sheet at half height (it can be pulled up) with the calendar; its weekday letters are 11 pt in the code, which the app\'s font helper raises to 12. Weeks start on Monday (en-GB).',
    states: [
      { id: 'ready', label: 'Ready' },
      { id: 'holding', label: 'Holding' },
      { id: 'set', label: 'Quit Day set' },
      { id: 'calendar', label: 'Pick another date (sheet)' },
    ],
    build(h, state) {
      const words = h('stack', 'words', { padX: 20, gap: 12 }, [
        h('text', 'title', { step: 'title', text: 'Pick your Quit Day, Sam', alts: { text: ['Pick your Quit Day'] } }),
        h('onbRichText', 'recommend', { step: 'body', tone: 'muted', text: 'I recommend **Fri 6 Nov**. It gives you the full 7-day prep window. Keep using as normal until then.' }),
        h('onbDateStrip', 'strip', { quit: 6 }),
        h('row', 'legend', { justify: 'space-between' }, [
          h('onbLegend', 'legend-prep', { swatch: 'card', text: 'Prep week · 7 days' }),
          h('onbLegend', 'legend-quit', { swatch: 'ink', text: 'Quit Day' }),
        ]),
        h('row', 'another-row', {}, [h('button', 'another', { label: 'Pick another date', kind: 'quiet' })]),
      ]);
      return [h('onbQuitHero', 'hero', {}), words, h('spacer', 'footer-room', { size: 64 })];
    },
    overlay(h, state) {
      const progress = { ready: 0, holding: 0.45, set: 1, calendar: 0 }[state.id] || 0;
      const footer = h('onbFooter', 'footer', { gap: 6 }, [
        h('holdButton', 'hold', { label: 'Hold to set Fri 6 Nov', doneLabel: 'Quit Day set · Fri 6 Nov ✓', progress }),
        h('text', 'hold-hint', { step: 'caption', tone: 'muted', upper: false, align: 'center', text: 'Hold for 1.5 seconds. You can change the date later.' }),
      ]);
      if (state.id !== 'calendar') return footer;
      return [footer, h('sheet', 'date-sheet', { ground: 'reading', top: 400 }, [
        h('stack', 'sheet-body', { gap: 8 }, [
          h('onbSheetBar', 'sheet-bar', {}),
          h('onbCalendar', 'calendar', { quit: 6 }),
        ]),
      ])];
    },
  });

  /* ---------- F05 Building ---------- */
  const PLAN_ROWS = [
    { id: 'row-prep', kicker: 'Prep week', value: 'Fri 30 Oct to Thu 5 Nov' },
    { id: 'row-quit', kicker: 'Quit Day', value: 'Fri 6 Nov · no more cigarettes and vape' },
    { id: 'row-waves', kicker: 'Waves to watch', value: 'Coffee and stress' },
    { id: 'row-reason', kicker: 'Your reason', value: '“To keep up with Maya at the park”' },
  ];
  Lab.screen({
    id: 'onb-building', name: 'Your plan builds', area: 'Onboarding', source: V4S + ' (BuildingScreen)', ground: 'mint',
    note: 'F05. The rows settle in one by one, 0.6 s apart, then the two-friends card fades in and "See my plan" turns on. No back button: the build moment is not a place to come back to. "Waves to watch" lists the first two triggers in the app\'s order.',
    states: [{ id: 'building', label: 'Building · 2 rows in' }, { id: 'built', label: 'Built · all rows and friends' }],
    build(h, state) {
      const built = state.id === 'built';
      const rows = (built ? PLAN_ROWS : PLAN_ROWS.slice(0, 2)).map((r) => h('planStepRow', r.id, { kicker: r.kicker, value: r.value }));
      return [
        h('stack', 'column', { padX: 20, padTop: 16, gap: 12 }, [
          h('stack', 'progress-wrap', { padBottom: 6 }, [h('onbProgress', 'progress', { value: step(10) })]),
          h('row', 'heading', { gap: 12 }, [
            h('art', 'xero', { art: 'xero:hello', width: 88, height: 88 }),
            h('text', 'title', { step: 'title', text: 'Your plan, built around you' }),
          ]),
          ...rows,
          built ? h('onbFriends', 'friends', {}) : null,
        ]),
        h('spacer', 'footer-room', { size: 52 }),
      ];
    },
    overlay(h, state) {
      return h('onbFooter', 'footer', {}, [h('button', 'see-plan', { label: 'See my plan', disabled: state.id !== 'built' })]);
    },
  });

  /* ---------- F06 Plan reveal ---------- */
  Lab.screen({
    id: 'onb-reveal', name: 'Your plan is ready', area: 'Onboarding', source: V4S + ' (PlanRevealScreen)', ground: 'mint',
    note: 'F06. Prep week is free; the 3-day trial is offered on Quit Day (decision 15) and nothing is charged here. Prices are the App Store\'s (tokens.json → pricing: $39.99 a year, $3.33 a month, $9.99 monthly, $79.99 lifetime). The trial ends 3 days after Quit Day and the reminder comes 2 days before the end. Until the prices load the card says it will ask on Quit Day and "See all plans" is hidden. With Pro, the line reads "Everything is unlocked." and there is no trial card or plans link. "Start my prep week" saves the answers.',
    states: [{ id: 'free', label: 'Free · prices loaded' }, { id: 'loading', label: 'Prices not loaded yet' }, { id: 'pro', label: 'Already Pro (restored)' }],
    build(h, state) {
      const pro = state.id === 'pro', loading = state.id === 'loading';
      const trial = pro ? null : loading
        ? h('onbTrialCard', 'trial', { title: "We'll ask you about the full program on Quit Day, not before.", line: '' })
        : h('onbTrialCard', 'trial', {});
      return [
        h('stack', 'column', { padX: 20, padTop: 16, gap: 12 }, [
          h('stack', 'progress-wrap', { padBottom: 6 }, [h('onbProgress', 'progress', { value: step(11) })]),
          h('row', 'step-row', { gap: 10 }, [
            h('onbAvatar', 'avatar', { art: 'xero:hello', ground: 'apricot' }),
            h('text', 'step', { step: 'caption', tone: 'muted', text: 'Step 6 of 6' }),
          ]),
          h('markedTitle', 'title', { lead: 'Your plan is ', word: 'ready', mark: 'underline', step: 'title' }),
          h('text', 'charge', { step: 'body', tone: 'muted', text: pro ? 'Everything is unlocked.' : 'Prep week is on us. Nothing is charged today.', alts: { text: pro ? ['Prep week is on us. Nothing is charged today.'] : ['Everything is unlocked.'] } }),
          h('onbSavings', 'savings', {}),
          h('stack', 'includes', { fill: 'onColour', radius: 18, padX: 16, padTop: 16, padBottom: 16, gap: 8 }, [
            h('onbRichText', 'free-now', { step: 'footnote', tone: 'ink', text: '**Free now:** prep week, your counter, Craving SOS and Day 1' }),
            h('onbRichText', 'full', { step: 'footnote', tone: 'ink', text: '**With the full program:** four weeks of lessons, evening check-ins, an NRT plan, insights' }),
          ]),
          trial,
          h('text', 'health-line', { step: 'caption', tone: 'muted', upper: false, align: 'center', text: "DayXero offers education and support. It isn't medical treatment." }),
        ]),
        h('spacer', 'footer-room', { size: pro || loading ? 52 : 100 }),
      ];
    },
    overlay(h, state) {
      const plans = state.id === 'free';
      return h('onbFooter', 'footer', { gap: 4 }, [
        h('button', 'start', { label: 'Start my prep week' }),
        plans ? h('button', 'plans', { label: 'See all plans · $9.99 a month · $79.99 lifetime', kind: 'quiet' }) : null,
      ]);
    },
  });

  /* ---------- F07 Reminders (TrialScreen) ---------- */
  Lab.screen({
    id: 'onb-trial', name: 'Two small nudges', area: 'Onboarding', source: V4S + ' (TrialScreen)', ground: 'apricot',
    note: 'F07, the last onboarding screen (TrialScreen in the code; it asks for notifications). The times are the reminder defaults, 8:00 and 21:00, in the en-GB clock. "Yes, remind me" shows the system permission prompt, then opens the app; "Not right now" opens it straight away. No back button.',
    states: [{ id: 'ask', label: 'Ask' }],
    build(h) {
      return [
        h('stack', 'column', { padX: 20, padTop: 24, gap: 14 }, [
          h('text', 'title', { step: 'title', text: 'Two small nudges a day' }),
          h('text', 'intro', { step: 'body', tone: 'muted', text: "Xero says good morning, Glim checks in at night. That's it. No guilt, ever, and quiet hours by default." }),
          h('onbNotification', 'xero-note', { sender: 'Xero', time: '08:00', message: "Good morning. Ten seconds for today's pledge?", avatar: 'xero:hello', avatarGround: 'apricot', alts: { time: ['8:00 AM'] } }),
          h('onbNotification', 'glim-note', { sender: 'Glim', time: '21:00', message: 'How did today go? A one-minute check-in, if you have it.', avatar: 'glim:hello', avatarGround: 'violet', alts: { time: ['9:00 PM'] } }),
          h('text', 'settings', { step: 'footnote', tone: 'muted', text: 'You can change the times in Settings.' }),
        ]),
        h('spacer', 'footer-room', { size: 100 }),
      ];
    },
    overlay(h) {
      return h('onbFooter', 'footer', { gap: 4 }, [
        h('button', 'yes', { label: 'Yes, remind me' }),
        h('button', 'not-now', { label: 'Not right now', kind: 'quiet' }),
      ]);
    },
  });

  /* ---------- Under-age (outside the flow) ---------- */
  qscreen({
    id: 'onb-under-age', name: 'Under 18', area: 'Onboarding', source: INTRO + ' (UnderAgeScreen), DayXero/App/DayXeroApp.swift', ground: 'reading',
    note: 'Not a step in the current flow: the app shows it, on the reading ground, to anyone who said they were under 18 in an earlier version (the dx.underAge flag persists). It uses the question layout without the top bar, and the footer is a line instead of a button. The services are placeholders until Milan confirms them, so no row links out yet (with a URL a row gets an arrow). Xero\'s bubbles use the card-on-colour fill, which nearly vanishes on the cream reading ground in light mode.',
    states: [{ id: 'shown', label: 'Shown' }],
    spec(h) {
      return ({
        topBar: false,
        title: 'Wanting to quit is a great call',
        subtitle: "DayXero is for adults, but there's free support made for people your age.",
        tray: [
          h('onbYouthRow', 'youth-us', { title: 'Youth quit support (US)', detail: 'Free text-message program' }),
          h('onbYouthRow', 'youth-uk', { title: 'Youth quit support (UK)', detail: 'Free local stop smoking service' }),
          h('onbYouthRow', 'youth-au-ca', { title: 'Youth quit support (AU, CA)', detail: 'Free quitline' }),
        ],
        footer: [h('text', 'grown-ups', { step: 'footnote', tone: 'muted', align: 'center', text: 'You can also talk to a parent, school nurse or doctor.' })],
      });
    },
  });
})();
