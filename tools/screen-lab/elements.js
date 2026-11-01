/* DayXero Screen Lab — design-system elements (DayXeroCore/DesignSystem). Screen-only elements live in screens/*.js. */
(function () {
  'use strict';
  const Lab = window.Lab;
  const E = Lab.element, esc = Lab.esc, T = Lab.text, F = Lab.font;
  const CARDS = 'DayXeroCore/DesignSystem/V4/Cards4.swift';
  const GAP = [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 24, 28, 32, 40, 48];
  const PAD = [0, 4, 8, 12, 14, 16, 18, 20, 22, 24, 28, 32, 40, 48, 56, 64];
  const groundOrInherit = { label: 'Colour', kind: 'select', default: 'inherit', options: [['inherit', 'Same as the screen']].concat(Lab.groundNames.map((g) => [g, Lab.cap(g)])) };
  const sub = (ctx, g) => (g && g !== 'inherit' ? ctx.with({ groundName: g }) : ctx);

  /* ---------- Layout boxes ---------- */
  const FILLS = [['none', 'No fill'], ['onColour', 'Card on colour'], ['surface', 'Reading surface'], ['raised', 'Raised (white)'], ['cream', 'Cream'], ['ground', 'Its own colour'], ['navy', 'Navy']];
  function fillCss(fill, ctx) {
    switch (fill) {
      case 'onColour': return ctx.g.card;
      case 'surface': return Lab.c(Lab.fill.surface, ctx.dark);
      case 'raised': return Lab.c(Lab.fill.raised, ctx.dark);
      case 'cream': return ctx.dark ? '#16382D' : Lab.CREAM;
      case 'ground': return ctx.g.bg;
      case 'navy': return Lab.NAVY;
      default: return 'transparent';
    }
  }
  Lab.fillCss = fillCss;

  E({
    type: 'stack', name: 'Box (vertical)', group: 'Layout', source: 'SwiftUI VStack',
    description: 'Stacks what is inside it top to bottom. Change the gap, padding, fill and corner radius.',
    props: {
      gap: { label: 'Gap between items', kind: 'number', options: GAP, unit: ' pt', default: 0 },
      padX: { label: 'Side padding', kind: 'number', options: PAD, unit: ' pt', default: 0 },
      padTop: { label: 'Top padding', kind: 'number', options: PAD, unit: ' pt', default: 0 },
      padBottom: { label: 'Bottom padding', kind: 'number', options: PAD, unit: ' pt', default: 0 },
      align: { label: 'Align', kind: 'select', default: 'stretch', options: [['stretch', 'Full width'], ['flex-start', 'Left'], ['center', 'Centre'], ['flex-end', 'Right']] },
      fill: { label: 'Fill', kind: 'select', options: FILLS, default: 'none' },
      ground: groundOrInherit,
      radius: { label: 'Corner radius', kind: 'number', options: [0, 12, 14, 18, 20, 24, 28, 36], unit: ' pt', default: 0 },
      lip: { label: 'Lip shadow', kind: 'bool', labels: ['On', 'Off'], default: false },
      textAlign: { label: 'Text align', kind: 'select', default: 'left', options: [['left', 'Left'], ['center', 'Centre']] },
    },
    examples: [{ label: 'Card on colour, 16 pt padding', ground: 'mint', props: { fill: 'onColour', padX: 16, padTop: 16, padBottom: 16, radius: 18, gap: 4 }, kids: [['text', { step: 'caption', text: 'Kicker' }], ['text', { step: 'headline', text: 'A title' }]] }],
    render(p, ctx, kids) {
      const c = sub(ctx, p.ground);
      const fill = p.ground && p.ground !== 'inherit' && p.fill === 'none' ? 'ground' : p.fill;
      return `<div style="display:flex;flex-direction:column;gap:${p.gap}px;padding:${p.padTop}px ${p.padX}px ${p.padBottom}px;align-items:${p.align};background:${fillCss(fill, c)};border-radius:${p.radius}px;color:${c.g.ink};text-align:${p.textAlign};${p.lip ? 'box-shadow:0 5px 0 rgba(0,0,0,.14);' : ''}${p.style || ''}">${kids(p.ground && p.ground !== 'inherit' ? { groundName: p.ground } : null)}</div>`;
    },
  });

  E({
    type: 'row', name: 'Box (side by side)', group: 'Layout', source: 'SwiftUI HStack',
    description: 'Puts what is inside it in a row.',
    props: {
      gap: { label: 'Gap between items', kind: 'number', options: GAP, unit: ' pt', default: 8 },
      align: { label: 'Line up', kind: 'select', default: 'center', options: [['center', 'Middles'], ['flex-start', 'Tops'], ['flex-end', 'Bottoms'], ['baseline', 'Text baselines']] },
      justify: { label: 'Spread', kind: 'select', default: 'flex-start', options: [['flex-start', 'From the left'], ['space-between', 'Spread to the edges'], ['center', 'Centred'], ['flex-end', 'From the right']] },
      wrap: { label: 'Wrap onto new lines', kind: 'bool', labels: ['Yes', 'No'], default: false },
      padX: { label: 'Side padding', kind: 'number', options: PAD, unit: ' pt', default: 0 },
      padY: { label: 'Top and bottom padding', kind: 'number', options: PAD, unit: ' pt', default: 0 },
      fill: { label: 'Fill', kind: 'select', options: FILLS, default: 'none' },
      radius: { label: 'Corner radius', kind: 'number', options: [0, 12, 14, 18, 20, 24, 28, 36, 999], unit: ' pt', default: 0 },
    },
    render(p, ctx, kids) {
      return `<div class="row" style="display:flex;flex-direction:row;gap:${p.gap}px;align-items:${p.align};justify-content:${p.justify};flex-wrap:${p.wrap ? 'wrap' : 'nowrap'};padding:${p.padY}px ${p.padX}px;background:${fillCss(p.fill, ctx)};border-radius:${p.radius}px;${p.style || ''}">${kids()}</div>`;
    },
  });

  E({
    type: 'spacer', name: 'Space', group: 'Layout', source: 'SwiftUI Spacer / padding',
    props: { size: { label: 'Height', kind: 'number', options: [0, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64], unit: ' pt', default: 16 }, flex: { label: 'Stretch', kind: 'bool', labels: ['Yes', 'No'], default: false } },
    render(p) { return `<div style="${p.flex ? 'flex:1;min-width:0;' : ''}height:${p.size}px;flex-shrink:0"></div>`; },
  });

  E({
    type: 'divider', name: 'Hairline', group: 'Layout', source: CARDS,
    props: { opacity: { label: 'Strength', kind: 'number', options: [0.12, 0.25, 0.4], default: 0.25 } },
    render(p, ctx) { return `<div style="height:1px;background:${ctx.g.muted};opacity:${p.opacity}"></div>`; },
  });

  /* ---------- Text ---------- */
  const STEP = { label: 'Text style', kind: 'type', default: 'body', global: false };
  const TONE = { label: 'Colour', kind: 'colour', default: 'ink' };
  E({
    type: 'text', name: 'Text', group: 'Text', source: 'DayXeroCore/DesignSystem/V4/TypeStep.swift',
    description: 'Any line of words. Seven type sizes; 12 pt is the smallest the app uses.',
    props: {
      text: { label: 'Words', kind: 'text', default: 'Text' },
      step: STEP,
      tone: TONE,
      align: { label: 'Align', kind: 'select', default: 'left', options: [['left', 'Left'], ['center', 'Centre'], ['right', 'Right']] },
      upper: { label: 'Capitals', kind: 'select', default: 'auto', options: [['auto', 'As the style says'], [true, 'ALL CAPS'], [false, 'As written']] },
      size: { label: 'Exact size', kind: 'number', options: [['', 'From the style'], 12, 13, 14, 15, 16, 17, 18, 19, 20, 22, 24, 28, 32, 36, 40, 48, 56], unit: ' pt', default: '' },
      weight: { label: 'Weight', kind: 'number', options: [['', 'From the style'], 400, 500, 600, 700, 800], default: '' },
    },
    examples: [
      { label: 'Display 40', props: { step: 'display', text: 'Day 3' } },
      { label: 'Large 32', props: { step: 'large', text: 'Your program' } },
      { label: 'Title 24', props: { step: 'title', text: 'For tomorrow' } },
      { label: 'Headline 19', props: { step: 'headline', text: 'The noisy passengers' } },
      { label: 'Body 16', props: { step: 'body', text: 'A craving peaks and passes in a few minutes.' } },
      { label: 'Footnote 14', props: { step: 'footnote', text: 'Next up: The noisy passengers, tomorrow.', tone: 'muted' } },
      { label: 'Caption 12', props: { step: 'caption', text: 'Today · 3 min', tone: 'muted' } },
    ],
    render(p, ctx) {
      const color = Lab.colour(p.tone, ctx);
      const o = { color, align: p.align };
      if (p.size) o.size = +p.size;
      if (p.weight) o.weight = +p.weight;
      if (p.size && !p.weight) o.weight = Lab.type[p.step].weight;
      if (p.size) o.family = Lab.type[p.step].family;
      if (p.upper === true) o.upper = true;
      if (p.upper === false) o.upper = false;
      if (p.lines) o.style = `display:-webkit-box;-webkit-line-clamp:${p.lines};-webkit-box-orient:vertical;overflow:hidden;`;
      return T(p.step, p.text, ctx, o).replace('<div ', `<div class="t" `);
    },
  });

  /* Hand-drawn mark (decision 32): DayXeroCore/DesignSystem/V4/Emphasis.swift */
  Lab.markColour = function (ctx) {
    const n = ctx.groundName;
    if (n === 'ocean' || n === 'violet') return '#FFD966';
    if (['apricot', 'coral', 'sun', 'periwinkle'].includes(n)) return ctx.dark ? '#FF7A55' : Lab.CREAM;
    return '#FF7A55';
  };
  Lab.markSVG = function (mark, colour) {
    if (mark === 'circle') return `<svg class="mk mk-c" viewBox="0 0 100 50" preserveAspectRatio="none" aria-hidden="true"><path d="M72 5 C40 -1 4 8 3 26 C2 44 52 49 82 41 C99 35 101 15 85 7 C77 3 64 3 56 5" fill="none" stroke="${colour}" stroke-width="3" stroke-linecap="round" vector-effect="non-scaling-stroke" pathLength="1"/></svg>`;
    return `<svg class="mk mk-u" viewBox="0 0 200 16" preserveAspectRatio="none" aria-hidden="true"><path d="M3 10 C40 4 90 5 122 7 C152 9 178 11 197 4" fill="none" stroke="${colour}" stroke-width="4" stroke-linecap="round" vector-effect="non-scaling-stroke" pathLength="1"/></svg>`;
  };
  E({
    type: 'markedTitle', name: 'Title with a marked word', group: 'Text', source: 'DayXeroCore/DesignSystem/V4/Emphasis.swift',
    description: 'A screen title with one word underlined or looped by hand (decision 32). One per screen.',
    props: {
      lead: { label: 'Words before', kind: 'text', default: '' },
      word: { label: 'Marked word', kind: 'text', default: 'word' },
      trail: { label: 'Words after', kind: 'text', default: '' },
      mark: { label: 'Mark', kind: 'select', default: 'underline', options: [['underline', 'Underline'], ['circle', 'Loop around it'], ['none', 'No mark']] },
      stacked: { label: 'Lines', kind: 'select', default: false, options: [[false, 'One line'], [true, 'Marked word on its own line']] },
      step: { label: 'Text style', kind: 'type', default: 'large' },
      colour: { label: 'Mark colour', kind: 'select', default: 'auto', global: true, options: [['auto', 'Automatic (per ground)'], ['#FF7A55', 'Coral'], [Lab.CREAM, 'Cream'], ['#FFD966', 'Sun'], [Lab.NAVY, 'Navy']] },
    },
    examples: [
      { label: 'Underline on mint', ground: 'mint', props: { lead: 'Your ', word: 'program' } },
      { label: 'Loop on periwinkle', ground: 'periwinkle', props: { word: 'Calm', trail: ' tools', mark: 'circle' } },
      { label: 'Stacked on lime', ground: 'lime', props: { lead: "What's", word: 'changing', stacked: true } },
    ],
    render(p, ctx) {
      const colour = p.colour && p.colour !== 'auto' ? p.colour : Lab.markColour(ctx);
      const wordHTML = `<span class="mw">${esc(p.word)}${p.mark !== 'none' ? Lab.markSVG(p.mark, colour) : ''}</span>`;
      const lead = esc(p.lead).replace(/ $/, '&nbsp;'), trail = esc(p.trail).replace(/^ /, '&nbsp;');
      const inner = p.stacked ? `${p.lead ? `<div>${lead}</div>` : ''}<div>${wordHTML}${trail}</div>` : `<div>${lead}${wordHTML}${trail}</div>`;
      return `<div class="marked" style="${F(p.step)}color:${ctx.g.ink}">${inner}</div>`;
    },
  });

  /* ---------- Buttons (V4/Buttons4.swift) ---------- */
  Lab.buttonColours = function (kind, groundName, dark) {
    const s = Lab.grounds[groundName] || Lab.grounds.reading;
    if (kind === 'primary' && !dark) {
      if (groundName === 'ocean' || groundName === 'violet') return { bg: Lab.CREAM, fg: s.light, fill: '#E3EAFF', lip: true };
      if (groundName === 'reading') return { bg: Lab.NAVY, fg: Lab.CREAM, fill: '#3A3460', lip: false };
      return { bg: Lab.NAVY, fg: Lab.CREAM, fill: '#3A3460', lip: true };
    }
    if (kind === 'primary' && dark) {
      if (['apricot', 'coral', 'sun'].includes(groundName)) return { bg: s.light, fg: s.dark, fill: '#FFD9B0', lip: false };
      return { bg: Lab.CREAM, fg: s.dark, fill: '#E3DCF5', lip: false };
    }
    if (kind === 'secondary' && groundName === 'ocean') return { bg: dark ? '#1B2C66' : '#1D3A9E', fg: Lab.CREAM, fill: '#2A52DB', lip: false };
    return { bg: null, fg: dark ? s.inkDark : s.inkLight, fill: null, lip: false };
  };
  const BTN = 'DayXeroCore/DesignSystem/V4/Buttons4.swift';
  E({
    type: 'button', name: 'Button', group: 'Buttons', source: BTN,
    description: 'Full-width pill, 58 pt, with a lip shadow on colour grounds. Colours follow the ground it sits on.',
    props: {
      label: { label: 'Words', kind: 'text', default: 'Continue' },
      kind: { label: 'Kind', kind: 'select', default: 'primary', options: [['primary', 'Primary (filled)'], ['secondary', 'Secondary (outline)'], ['quiet', 'Quiet (text only)']] },
      ground: groundOrInherit,
      height: { label: 'Height', kind: 'number', options: [44, 48, 52, 56, 58, 64], unit: ' pt', default: 58, global: true },
      lip: { label: 'Lip shadow', kind: 'select', default: 'auto', global: true, options: [['auto', 'As the ground says'], [true, 'Always'], [false, 'Never']] },
      icon: { label: 'Icon', kind: 'select', default: '', options: [['', 'None']].concat(Lab.iconNames.map((n) => [n, n])) },
      disabled: { label: 'State', kind: 'select', default: false, options: [[false, 'Ready'], [true, 'Not ready yet (50%)']] },
    },
    examples: [
      { label: 'Primary on apricot', ground: 'apricot', props: { label: 'Start Day 3' } },
      { label: 'Primary on ocean', ground: 'ocean', props: { label: 'I rode it out' } },
      { label: 'Secondary on ocean', ground: 'ocean', props: { label: 'Talk to Jelli', kind: 'secondary' } },
      { label: 'Primary on reading', ground: 'reading', props: { label: 'Next · 1 of 3' } },
      { label: 'Quiet', ground: 'mint', props: { label: 'Not now', kind: 'quiet' } },
    ],
    render(p, ctx) {
      const g = p.ground && p.ground !== 'inherit' ? p.ground : ctx.groundName;
      const c = Lab.buttonColours(p.kind, g, ctx.dark);
      const quiet = p.kind === 'quiet';
      const lip = p.lip === 'auto' ? c.lip : p.lip && !!c.bg;
      const h = quiet ? 44 : p.height;
      const style = `${F(quiet ? 'footnote' : 'headline')}color:${c.fg};min-height:${h}px;${quiet ? 'padding:0 8px;align-self:center;' : 'width:100%;padding:0 24px;'}border-radius:999px;display:flex;align-items:center;justify-content:center;gap:8px;box-sizing:border-box;` +
        (c.bg ? `background:${c.bg};` : p.kind === 'secondary' ? `box-shadow:inset 0 0 0 2px ${c.fg};` : '') + (lip ? 'box-shadow:0 6px 0 rgba(0,0,0,.2);' : '') + (p.disabled ? 'opacity:.5;' : '');
      return `<div class="btn4" role="button" style="${style}">${p.icon ? Lab.icon(p.icon, 18, c.fg) : ''}<span>${esc(p.label)}</span></div>`;
    },
  });

  E({
    type: 'holdButton', name: 'Hold button', group: 'Buttons', source: BTN,
    description: 'Press and hold to commit: Quit Day 1.5 s, pledge 1 s, Day Xero 3 s. Fills left to right.',
    props: {
      label: { label: 'Words', kind: 'text', default: 'Hold to commit' },
      doneLabel: { label: 'Words when done', kind: 'text', default: 'Done' },
      progress: { label: 'Preview', kind: 'select', default: 0, options: [[0, 'Not pressed'], [0.45, 'Half held'], [1, 'Done']] },
    },
    examples: [{ label: 'Quit Day, half held', ground: 'apricot', props: { label: 'Hold to start Quit Day', progress: 0.45 } }],
    render(p, ctx) {
      const c = Lab.buttonColours('primary', ctx.groundName, ctx.dark);
      return `<div class="btn4" style="position:relative;height:58px;border-radius:999px;background:${c.bg};${c.lip ? 'box-shadow:0 6px 0 rgba(0,0,0,.2);' : ''}overflow:hidden;display:flex;align-items:center;justify-content:center">
        <div style="position:absolute;inset:0 auto 0 0;width:${p.progress * 100}%;background:${c.fill}"></div>
        <span style="position:relative;${F('headline')}color:${c.fg}">${esc(p.progress >= 1 ? p.doneLabel : p.label)}</span></div>`;
    },
  });

  E({
    type: 'iconButton', name: 'Round icon button', group: 'Buttons', source: 'DayXero (back, close and more buttons)',
    props: {
      icon: { label: 'Icon', kind: 'icon', default: 'chevron.left' },
      size: { label: 'Size', kind: 'number', options: [32, 36, 40, 44, 48, 52], unit: ' pt', default: 44 },
      fill: { label: 'Fill', kind: 'select', options: FILLS, default: 'onColour' },
      label: { label: 'Spoken label', kind: 'text', default: 'Back' },
    },
    examples: [{ label: 'Back on mint', ground: 'mint', props: {} }],
    render(p, ctx) {
      return `<div role="button" aria-label="${esc(p.label)}" style="width:${p.size}px;height:${p.size}px;border-radius:50%;background:${fillCss(p.fill, ctx)};display:flex;align-items:center;justify-content:center;color:${ctx.g.ink};flex:none">${Lab.icon(p.icon, Math.round(p.size * 0.38), ctx.g.ink)}</div>`;
    },
  });

  E({
    type: 'chip', name: 'Answer chip', group: 'Buttons', source: 'DayXeroCore/DesignSystem/V4/Nav4.swift (AnswerTray)',
    description: '48 pt chip, radius 14. Ink fill when picked.',
    props: {
      label: { label: 'Words', kind: 'text', default: 'Coffee' },
      on: { label: 'State', kind: 'select', default: false, options: [[false, 'Not picked'], [true, 'Picked']] },
      shape: { label: 'Shape', kind: 'select', default: 'chip', global: true, options: [['chip', 'Rounded rectangle (14)'], ['pill', 'Pill']] },
      outline: { label: 'Style', kind: 'select', default: false, options: [[false, 'Filled'], [true, 'Outline ("More…")']] },
    },
    examples: [{ label: 'Picked and not', ground: 'reading', props: { label: 'Coffee', on: true } }, { label: 'Not picked', ground: 'reading', props: { label: 'Stress' } }],
    render(p, ctx) {
      const ink = ctx.g.ink;
      const bg = p.outline ? 'transparent' : p.on ? ink : Lab.c(Lab.fill.surface, ctx.dark);
      return `<div role="button" style="${F('footnote')}min-height:48px;padding:0 14px;display:flex;align-items:center;justify-content:center;text-align:center;border-radius:${p.shape === 'pill' ? 999 : 14}px;background:${bg};color:${p.on ? ctx.g.bg : ink};${p.outline ? `box-shadow:inset 0 0 0 1.5px ${ink}4D;` : ''}flex:1">${esc(p.label)}</div>`;
    },
  });

  /* ---------- Cards (V4/Cards4.swift) ---------- */
  E({
    type: 'topCard', name: 'Top card', group: 'Cards', source: CARDS,
    description: "Today's top card: coloured action card with kicker, 19 pt title, 14 pt detail and a chevron in a 44 pt circle.",
    props: {
      kicker: { label: 'Kicker', kind: 'text', default: 'Today' },
      title: { label: 'Title', kind: 'text', default: 'Title' },
      detail: { label: 'Detail', kind: 'text', default: '' },
      ground: { label: 'Colour', kind: 'ground', default: 'apricot' },
      art: { label: 'Illustration', kind: 'art', default: 'none' },
      radius: { label: 'Corner radius', kind: 'number', options: [18, 24, 28, 36], unit: ' pt', default: 24, global: true },
    },
    examples: [{ label: 'Apricot', ground: 'reading', props: { kicker: 'Day 3 · 3 min', title: 'The noisy passengers', detail: 'Thoughts that get loud around cravings.' } }],
    render(p, ctx) {
      const c = ctx.with({ groundName: p.ground });
      const g = c.g;
      return `<div role="button" style="display:flex;align-items:center;gap:14px;padding:18px;border-radius:${p.radius}px;background:${g.bg};box-shadow:0 5px 0 rgba(0,0,0,.14)">
        ${p.art && p.art !== 'none' ? `<div style="flex:none">${Lab.art(p.art, { size: 64, radius: 18 })}</div>` : ''}
        <div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:4px">
          ${T('caption', p.kicker, c, { tone: 'muted' })}${T('headline', p.title, c)}${p.detail ? T('footnote', p.detail, c, { tone: 'muted' }) : ''}
        </div>
        <div style="width:44px;height:44px;border-radius:50%;background:${g.card};display:flex;align-items:center;justify-content:center;flex:none">${Lab.icon('chevron.right', 16, g.ink)}</div></div>`;
    },
  });

  E({
    type: 'statTile', name: 'Stat tile', group: 'Cards', source: CARDS,
    description: '24 pt number over a 12 pt label, on a card. Counts up when it appears.',
    props: { value: { label: 'Number', kind: 'text', default: '36' }, label: { label: 'Label', kind: 'text', default: 'Not smoked' } },
    examples: [{ label: 'On apricot', ground: 'apricot', width: 160, props: { value: '$15.65', label: 'Kept' } }],
    render(p, ctx) {
      return `<div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:2px;padding:16px;border-radius:18px;background:${ctx.g.card}">${T('title', p.value, ctx, { style: 'font-variant-numeric:tabular-nums;white-space:nowrap' })}${T('caption', p.label, ctx, { tone: 'muted' })}</div>`;
    },
  });

  E({
    type: 'dayRow', name: 'Day row', group: 'Rows', source: CARDS,
    description: 'A 22 pt status dot (green when done), label and meta, with a hairline under it.',
    props: { label: { label: 'Label', kind: 'text', default: 'Morning check-in' }, meta: { label: 'Meta', kind: 'text', default: '8:00' }, done: { label: 'State', kind: 'select', default: false, options: [[false, 'Not done'], [true, 'Done']] } },
    examples: [{ label: 'Done', props: { done: true, label: 'Coffee wave', meta: '9:40' } }, { label: 'Not done', props: { label: 'Evening check-in', meta: '21:00' } }],
    render(p, ctx) {
      const green = Lab.c(Lab.fill.green, ctx.dark);
      return `<div style="display:flex;align-items:center;gap:12px;padding:12px 0;border-bottom:1px solid ${ctx.g.muted}40">
        <div style="width:22px;height:22px;border-radius:50%;flex:none;display:flex;align-items:center;justify-content:center;${p.done ? `background:${green}` : `box-shadow:inset 0 0 0 2px ${ctx.g.muted}`}">${p.done ? Lab.icon('checkmark', 11, '#fff') : ''}</div>
        ${T('body', p.label, ctx, { style: 'flex:1;min-width:0' })}${T('footnote', p.meta, ctx, { tone: 'muted' })}</div>`;
    },
  });

  E({
    type: 'planStepRow', name: 'Plan row', group: 'Rows', source: CARDS,
    description: 'Tick circle, caption kicker and body value, on a card.',
    props: { kicker: { label: 'Kicker', kind: 'text', default: 'Quit Day' }, value: { label: 'Value', kind: 'text', default: 'Friday 6 November' } },
    examples: [{ label: 'On mint', ground: 'mint', props: {} }],
    render(p, ctx) {
      return `<div style="display:flex;align-items:flex-start;gap:12px;padding:16px;border-radius:18px;background:${ctx.g.card}">
        <div style="width:26px;height:26px;border-radius:50%;background:${Lab.c(Lab.fill.green, ctx.dark)};display:flex;align-items:center;justify-content:center;flex:none">${Lab.icon('checkmark', 12, Lab.CREAM)}</div>
        <div style="display:flex;flex-direction:column;gap:2px">${T('caption', p.kicker, ctx, { tone: 'muted' })}${T('body', p.value, ctx)}</div></div>`;
    },
  });

  E({
    type: 'programDayCard', name: 'Program day card', group: 'Cards', source: CARDS,
    description: 'A 40 pt icon box (done, play, lock, star), kicker and title. Today is apricot with a lip.',
    props: {
      kicker: { label: 'Kicker', kind: 'text', default: 'Day 2' }, title: { label: 'Title', kind: 'text', default: 'The noisy passengers' },
      state: { label: 'State', kind: 'select', default: 'today', options: [['done', 'Done'], ['today', 'Today'], ['locked', 'Locked'], ['graduation', 'Graduation']] },
    },
    examples: [{ label: 'Today', props: {} }, { label: 'Done', props: { state: 'done', kicker: 'Day 1', title: 'Day one' } }],
    render(p, ctx) {
      const today = p.state === 'today';
      const c = today ? ctx.with({ groundName: 'apricot' }) : ctx.with({ groundName: 'reading' });
      const icon = { done: 'checkmark', today: 'play.fill', locked: 'lock.fill', graduation: 'star.fill' }[p.state];
      const box = { done: Lab.c(Lab.fill.green, ctx.dark), today: ctx.dark ? '#FFC38A' : Lab.NAVY }[p.state] || Lab.c(Lab.fill.surface, ctx.dark);
      const ink = { done: Lab.CREAM, today: ctx.dark ? Lab.PLUM : Lab.CREAM }[p.state] || Lab.ground('reading', ctx.dark).muted;
      return `<div style="display:flex;align-items:center;gap:14px;padding:14px;border-radius:18px;background:${today ? c.g.bg : Lab.c(Lab.fill.raised, ctx.dark)};${today ? 'box-shadow:0 5px 0 rgba(0,0,0,.14)' : ''}">
        <div style="width:40px;height:40px;border-radius:12px;background:${box};display:flex;align-items:center;justify-content:center;flex:none">${Lab.icon(icon, 16, ink)}</div>
        <div style="display:flex;flex-direction:column;gap:2px">${T('caption', p.kicker, c, { tone: 'muted' })}${T('headline', p.title, c)}</div></div>`;
    },
  });

  E({
    type: 'healthFactCard', name: 'Health fact card', group: 'Cards', source: CARDS,
    props: {
      status: { label: 'Status', kind: 'text', default: 'Happening now' }, when: { label: 'When', kind: 'text', default: '72 hours' },
      title: { label: 'Title', kind: 'text', default: 'Breathing feels easier' }, line: { label: 'Line', kind: 'text', default: '' },
      sourceLabel: { label: 'Source', kind: 'text', default: 'Source: American Cancer Society' },
    },
    render(p, ctx) {
      const c = ctx.with({ groundName: 'reading' });
      return `<div style="display:flex;flex-direction:column;gap:6px;padding:16px;border-radius:18px;background:${Lab.c(Lab.fill.surface, ctx.dark)}">${T('caption', p.status + ' · ' + p.when, c, { tone: 'muted' })}${T('headline', p.title, c)}${p.line ? T('body', p.line, c) : ''}${T('caption', p.sourceLabel, c, { tone: 'muted', upper: false })}</div>`;
    },
  });

  E({
    type: 'notificationPreview', name: 'Notification preview', group: 'Cards', source: CARDS,
    props: {
      sender: { label: 'Character', kind: 'text', default: 'Xero' }, time: { label: 'Time', kind: 'text', default: '9:30' },
      message: { label: 'Message', kind: 'text', default: 'Coffee wave in 10 minutes. I am here.' }, avatar: { label: 'Avatar', kind: 'art', default: 'xero:hello' },
    },
    examples: [{ label: 'On apricot', ground: 'apricot', props: {} }],
    render(p) {
      return `<div style="display:flex;align-items:flex-start;gap:12px;padding:14px;border-radius:20px;background:${Lab.CREAM}">
        <div style="width:40px;height:40px;border-radius:10px;overflow:hidden;flex:none;background:#FFC38A;display:flex;align-items:center;justify-content:center">${Lab.art(p.avatar, { size: 40 })}</div>
        <div style="flex:1;display:flex;flex-direction:column;gap:2px"><div style="display:flex;justify-content:space-between;${F('caption')}color:#5E5975;text-transform:uppercase"><span>DayXero · ${esc(p.sender)}</span><span>${esc(p.time)}</span></div><div style="${F('footnote')}color:${Lab.NAVY}">${esc(p.message)}</div></div></div>`;
    },
  });

  E({
    type: 'handOverChip', name: 'Hand-over chip', group: 'Cards', source: CARDS,
    props: { text: { label: 'Words', kind: 'text', default: 'Xero passed you to Jelli' }, avatar: { label: 'Avatar', kind: 'art', default: 'jelli:calm' } },
    examples: [{ label: 'On ocean', ground: 'ocean', props: {} }],
    render(p, ctx) {
      return `<div style="display:inline-flex;align-self:flex-start;align-items:center;gap:8px;padding:6px 14px 6px 6px;border-radius:999px;background:${Lab.c(Lab.fill.cardOnColour, ctx.dark)}"><div style="width:28px;height:28px">${Lab.art(p.avatar, { size: 28 })}</div><span style="${F('footnote')}color:${ctx.dark ? Lab.CREAM : Lab.NAVY}">${esc(p.text)}</span></div>`;
    },
  });

  E({
    type: 'breathingWords', name: 'Breathing words', group: 'Motion', source: CARDS,
    description: 'Two words cross-fading on the 4 s in, 6 s out clock.',
    props: { inhale: { label: 'Breathe in words', kind: 'text', default: 'Breathe in' }, exhale: { label: 'Breathe out words', kind: 'text', default: 'Breathe out' } },
    examples: [{ label: 'On ocean', ground: 'ocean', props: {} }],
    render(p, ctx) {
      const anim = Lab.view.motion;
      return `<div style="position:relative;height:40px;${F('large')}color:${ctx.g.ink};text-align:center"><span class="${anim ? 'bw-in' : ''}" style="position:absolute;inset:0">${esc(p.inhale)}</span><span class="${anim ? 'bw-out' : ''}" style="position:absolute;inset:0;opacity:${anim ? 0 : 0}">${esc(p.exhale)}</span></div>`;
    },
  });

  const MOUTH = { rough: 'M11 22 Q16 18 21 22', okay: 'M11 20.5 L21 20.5', good: 'M11 19 Q16 23 21 19', proud: 'M10 18 Q16 26 22 18' };
  E({
    type: 'moodPicker', name: 'Mood picker', group: 'Inputs', source: CARDS,
    description: 'Drawn faces, no emoji: Rough, Okay, Good, Proud.',
    props: { selected: { label: 'Picked', kind: 'select', default: '', options: [['', 'None'], ['rough', 'Rough'], ['okay', 'Okay'], ['good', 'Good'], ['proud', 'Proud']] } },
    examples: [{ label: 'On violet', ground: 'violet', props: { selected: 'good' } }],
    render(p, ctx) {
      return `<div style="display:flex;gap:8px">${['rough', 'okay', 'good', 'proud'].map((m) => {
        const on = p.selected === m;
        return `<div style="flex:1;min-height:64px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:6px"><svg width="32" height="32" viewBox="0 0 32 32"><circle cx="16" cy="16" r="16" fill="${on ? ctx.g.ink : ctx.g.card}"/><g fill="${on ? ctx.g.bg : ctx.g.ink}"><circle cx="11.5" cy="12.5" r="1.5"/><circle cx="20.5" cy="12.5" r="1.5"/></g><path d="${MOUTH[m]}" fill="none" stroke="${on ? ctx.g.bg : ctx.g.ink}" stroke-width="2.2" stroke-linecap="round"/></svg>${T('caption', Lab.cap(m), ctx, { upper: false })}</div>`;
      }).join('')}</div>`;
    },
  });

  E({
    type: 'cravingSlider', name: 'Craving slider', group: 'Inputs', source: 'DayXeroCore/DesignSystem/Components/Controls.swift',
    props: { value: { label: 'Value', kind: 'number', options: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], default: 6 } },
    examples: [{ label: 'Moderate', props: {} }],
    render(p, ctx) {
      const c = ctx.with({ groundName: 'reading' });
      const word = p.value <= 3 ? 'Mild' : p.value <= 7 ? 'Moderate' : 'Intense';
      const x = ((p.value - 1) / 9) * 100;
      return `<div style="display:flex;flex-direction:column;gap:12px">
        <div style="display:flex;justify-content:space-between">${T('caption', 'How strong is it?', c, { tone: 'muted' })}${T('footnote', word, c, { tone: 'muted' })}</div>
        <div style="display:flex;align-items:baseline;gap:4px">${T('large', String(p.value), c)}${T('headline', '/ 10', c, { tone: 'muted' })}</div>
        <div style="position:relative;height:44px"><div style="position:absolute;left:14px;right:14px;top:19px;height:6px;border-radius:3px;background:linear-gradient(90deg,${Lab.c(Lab.fill.green, ctx.dark)},#E5A93C,#C85A54)"></div>
        <div style="position:absolute;top:8px;left:calc((100% - 28px) * ${x / 100});width:28px;height:28px;border-radius:50%;background:#fff;box-shadow:0 4px 6px rgba(0,0,0,.35)"></div></div></div>`;
    },
  });

  E({
    type: 'progressBar', name: 'Progress bar', group: 'Inputs', source: 'DayXeroCore/DesignSystem/Metrics.swift (progressHeight 6)',
    props: { value: { label: 'Filled', kind: 'number', options: [0, 0.1, 0.2, 0.25, 0.3, 0.4, 0.5, 0.6, 0.7, 0.75, 0.8, 0.9, 1], default: 0.4 }, colour: { label: 'Colour', kind: 'colour', default: 'ink' }, height: { label: 'Height', kind: 'number', options: [4, 6, 8, 10, 12], unit: ' pt', default: 6 } },
    render(p, ctx) {
      return `<div style="height:${p.height}px;border-radius:999px;background:${ctx.g.ink}22;overflow:hidden"><div style="height:100%;width:${p.value * 100}%;border-radius:999px;background:${Lab.colour(p.colour, ctx)}"></div></div>`;
    },
  });

  /* ---------- Chat (V4/Nav4.swift) ---------- */
  E({
    type: 'replyBubble', name: 'Reply bubble', group: 'Chat', source: 'DayXeroCore/DesignSystem/V4/Nav4.swift',
    props: { text: { label: 'Words', kind: 'text', default: 'Coffee and stress' }, edit: { label: 'Edit link', kind: 'bool', labels: ['Show', 'Hide'], default: true } },
    examples: [{ label: 'On lilac', ground: 'lilac', props: {} }],
    render(p, ctx) {
      return `<div style="display:flex;flex-direction:column;align-items:flex-end;gap:4px"><div style="${F('body')}color:${ctx.g.bg};background:${ctx.g.ink};padding:12px 16px;border-radius:20px 20px 4px 20px;max-width:80%">${esc(p.text)}</div>${p.edit ? `<div style="${F('footnote')}color:${ctx.g.muted};min-height:44px;display:flex;align-items:center">Edit</div>` : ''}</div>`;
    },
  });
  E({
    type: 'xeroBubble', name: 'Character message', group: 'Chat', source: 'DayXero/Onboarding (chat messages)',
    props: { text: { label: 'Words', kind: 'text', default: "Hi, I'm Xero. I'll be with you every day." }, avatar: { label: 'Avatar', kind: 'art', default: 'xero:hello' } },
    examples: [{ label: 'On lilac', ground: 'lilac', props: {} }],
    render(p, ctx) {
      return `<div style="display:flex;align-items:flex-end;gap:8px">${p.avatar !== 'none' ? `<div style="width:40px;height:40px;flex:none">${Lab.art(p.avatar, { size: 40 })}</div>` : ''}<div style="${F('body')}color:${ctx.g.ink};background:${Lab.c(Lab.fill.cardOnColour, ctx.dark)};padding:12px 16px;border-radius:20px 20px 20px 4px;max-width:80%">${esc(p.text)}</div></div>`;
    },
  });
  E({
    type: 'typingDots', name: 'Typing dots', group: 'Chat', source: 'DayXeroCore/DesignSystem/V4/Nav4.swift',
    props: {}, examples: [{ label: 'On lilac', ground: 'lilac', props: {} }],
    render(p, ctx) {
      return `<div style="align-self:flex-start;display:flex;gap:5px;padding:12px 14px;border-radius:999px;background:${Lab.c(Lab.fill.cardOnColour, ctx.dark)}">${[0.6, 0.4, 0.25].map((o) => `<span style="width:8px;height:8px;border-radius:50%;background:${ctx.g.ink};opacity:${o}"></span>`).join('')}</div>`;
    },
  });
  E({
    type: 'answerTray', name: 'Answer tray', group: 'Chat', source: 'DayXeroCore/DesignSystem/V4/Nav4.swift',
    description: 'A sheet at the bottom of chat: "YOUR ANSWER", a two-column grid of 48 pt chips and "Next · n of 3".',
    props: {
      options: { label: 'Answers', kind: 'select', default: 'Waking up|Coffee|After meals|Stress', options: [['Waking up|Coffee|After meals|Stress', 'Triggers (4)'], ['Cigarettes|Vape|Both', 'What you use'], ['Yes|Not yet', 'Yes / Not yet']] },
      picked: { label: 'Picked', kind: 'text', default: 'Coffee' },
      more: { label: '"More…" chip', kind: 'bool', labels: ['Show', 'Hide'], default: true },
      next: { label: 'Button words', kind: 'text', default: 'Next · 2 of 3' },
    },
    examples: [{ label: 'Triggers', ground: 'lilac', props: {} }],
    render(p, ctx) {
      const c = ctx.with({ groundName: 'reading' });
      const opts = String(p.options).split('|');
      const picked = String(p.picked).split('|');
      const chip = (o) => Lab.render(Lab.h('chip', '_c', { label: o, on: picked.includes(o) }), Object.assign(c, { inert: true }));
      return `<div style="display:flex;flex-direction:column;gap:12px;padding:18px 20px 8px;border-radius:28px 28px 0 0;background:${ctx.dark ? '#2A255F' : '#FFFFFF'};margin:0 -20px">
        ${T('caption', 'Your answer', c, { tone: 'muted' })}
        <div style="display:grid;grid-template-columns:1fr 1fr;gap:8px">${opts.map(chip).join('')}${p.more ? Lab.render(Lab.h('chip', '_m', { label: 'More…', outline: true }), c) : ''}</div>
        ${Lab.render(Lab.h('button', '_n', { label: p.next }), c)}</div>`;
    },
  });

  /* ---------- Illustrations ---------- */
  E({
    type: 'art', name: 'Illustration', group: 'Illustrations', source: 'DayXeroCore/DesignSystem/Art',
    description: 'Any drawn thing: the 22 kit panels, the person, Xero, Jelli, Glim and the scenes. Pick another from the dropdown.',
    props: {
      art: { label: 'Illustration', kind: 'art', default: 'kit:dawn' },
      width: { label: 'Width', kind: 'number', options: [28, 40, 48, 56, 64, 72, 88, 96, 120, 140, 160, 200, 240, 280, 320, 362, 402], unit: ' pt', default: 64 },
      height: { label: 'Height', kind: 'number', options: [28, 40, 48, 56, 64, 72, 88, 96, 110, 120, 140, 160, 180, 200, 240, 280, 320], unit: ' pt', default: 64 },
      radius: { label: 'Corner radius (kit panels)', kind: 'number', options: [0, 12, 14, 18, 20, 24, 28, 36], unit: ' pt', default: 28 },
      shirt: { label: 'Shirt colour (person)', kind: 'select', default: '#FF7A55', options: [['#FF7A55', 'Coral'], ['#FFC38A', 'Apricot'], ['#2A52DB', 'Ocean'], ['#4A3596', 'Violet'], ['#0F6E43', 'Green'], ['#FFD966', 'Sun']] },
      align: { label: 'Position', kind: 'select', default: 'auto', options: [['auto', 'Where it is'], ['flex-start', 'Left'], ['center', 'Centre'], ['flex-end', 'Right']] },
    },
    examples: [
      { label: 'Kit · sprout, 64 pt', props: { art: 'kit:sprout' } },
      { label: 'Person · walk', ground: 'mint', props: { art: 'person:walk', width: 80, height: 96 } },
      { label: 'Xero', ground: 'apricot', props: { art: 'xero:hello', width: 120, height: 120 } },
    ],
    render(p) {
      const isPerson = String(p.art).startsWith('person:');
      const inner = Lab.art(p.art, { width: p.width, height: p.height, radius: p.radius, shirt: p.shirt });
      if (!inner) return `<div style="display:none"></div>`;
      return `<div class="art" style="flex:none;line-height:0;${p.align !== 'auto' ? 'align-self:' + p.align + ';' : ''}${isPerson ? '' : `width:${p.width}px;height:${p.height}px;`}">${inner}</div>`;
    },
  });

  /* ---------- Navigation ---------- */
  const TAB_ICONS = {
    today: ['M3 11.5 12 4l9 7.5V20a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1z', true, 'Today'],
    program: ['M12 21V11 M12 13C6 13 4 9 4 5c5 0 8 3 8 8Z M12 11c0-4 3-7 8-7 0 4-3 7-8 7Z', false, 'Program'],
    sos: ['M3 12c3-4 6-4 9 0s6 4 9 0', false, 'SOS'],
    evening: ['M15 3a8.5 8.5 0 1 0 6 13.5A7 7 0 0 1 15 3Z', true, 'Evening'],
    me: ['M12 3.5a4.5 4.5 0 1 1 0 9 4.5 4.5 0 0 1 0-9Z M3.5 21c1.2-4.6 4.6-7 8.5-7s7.3 2.4 8.5 7z', true, 'Me'],
  };
  E({
    type: 'tabBar', name: 'Tab bar', group: 'Navigation', source: 'DayXeroCore/DesignSystem/V4/Nav4.swift',
    description: 'The floating pill: Today · Program · SOS · Evening · Me. SOS is always ocean.',
    props: {
      selected: { label: 'Selected tab', kind: 'select', default: 'today', options: Object.keys(TAB_ICONS).map((k) => [k, TAB_ICONS[k][2]]) },
      labels: { label: 'Labels', kind: 'bool', labels: ['Show', 'Hide'], default: true, global: true },
      sosColour: { label: 'SOS colour', kind: 'select', default: 'ocean', global: true, options: [['ocean', 'Ocean (always)'], ['same', 'Same as other tabs']] },
    },
    examples: [{ label: 'Today selected', props: {} }],
    render(p, ctx) {
      const dark = ctx.dark;
      const tabs = Object.keys(TAB_ICONS).map((k) => {
        const [d, filled, label] = TAB_ICONS[k];
        const on = k === p.selected;
        const color = k === 'sos' && p.sosColour === 'ocean' ? (dark ? '#7FB0FF' : '#2A52DB') : on ? (dark ? Lab.CREAM : Lab.NAVY) : dark ? '#B8B3D9' : '#5E5975';
        const icon = filled ? `<path d="${d}" fill="${color}"/>` : `<path d="${d}" fill="none" stroke="${color}" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>`;
        return `<div style="flex:1;min-height:58px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:3px;border-radius:999px;${on ? `background:${dark ? '#2A255F' : '#F1EBE2'}` : ''}"><svg width="22" height="22" viewBox="0 0 24 24">${icon}</svg>${p.labels ? `<span style="font-family:${Lab.FONT.body};font-size:12px;font-weight:${on ? 700 : 600};color:${color}">${label}</span>` : ''}</div>`;
      }).join('');
      const pos = ctx.screenId === '_lib' ? '' : 'position:absolute;left:12px;right:12px;bottom:26px;z-index:5;';
      return `<div class="tabbar" style="${pos}height:70px;padding:0 6px;display:flex;align-items:center;border-radius:999px;background:${dark ? 'rgba(27,23,71,.96)' : 'rgba(255,255,255,.96)'};box-shadow:0 12px 30px ${dark ? 'rgba(0,0,0,.5)' : 'rgba(30,26,58,.14)'}, inset 0 0 0 1px ${dark ? 'rgba(255,255,255,.08)' : 'rgba(30,26,58,.06)'}">${tabs}</div>`;
    },
  });

  E({
    type: 'navBar', name: 'Top bar', group: 'Navigation', source: 'DayXero (back button and title on pushed screens)',
    props: {
      title: { label: 'Title', kind: 'text', default: '' },
      left: { label: 'Left button', kind: 'select', default: 'chevron.left', options: [['', 'None'], ['chevron.left', 'Back'], ['xmark', 'Close']] },
      right: { label: 'Right button', kind: 'select', default: '', options: [['', 'None'], ['xmark', 'Close'], ['ellipsis', 'More'], ['gearshape.fill', 'Settings'], ['info.circle', 'Info']] },
      fill: { label: 'Button fill', kind: 'select', options: FILLS, default: 'onColour' },
    },
    render(p, ctx) {
      const b = (icon) => (icon ? Lab.render(Lab.h('iconButton', '_b', { icon, fill: p.fill }), Object.assign(ctx.with({}), { inert: true })) : '<div style="width:44px"></div>');
      return `<div style="display:flex;align-items:center;justify-content:space-between;gap:8px;min-height:44px">${b(p.left)}${p.title ? T('headline', p.title, ctx, { align: 'center', style: 'flex:1' }) : '<div style="flex:1"></div>'}${b(p.right)}</div>`;
    },
  });

  E({
    type: 'sheet', name: 'Sheet', group: 'Navigation', source: 'SwiftUI .sheet',
    description: 'A card that slides up over the screen, with a grabber.',
    props: {
      fill: { label: 'Fill', kind: 'select', options: FILLS, default: 'raised' },
      ground: groundOrInherit,
      top: { label: 'Starts at', kind: 'number', options: [80, 120, 200, 300, 400, 500, 600], unit: ' pt from the top', default: 120 },
    },
    render(p, ctx, kids) {
      const c = sub(ctx, p.ground);
      return `<div style="position:absolute;left:0;right:0;bottom:0;top:${p.top}px;z-index:6;background:${fillCss(p.ground !== 'inherit' ? 'ground' : p.fill, c)};border-radius:28px 28px 0 0;box-shadow:0 -10px 40px rgba(0,0,0,.18);overflow:auto;padding:8px 20px 40px;color:${c.g.ink}"><div style="width:36px;height:5px;border-radius:3px;background:${c.g.muted};opacity:.4;margin:0 auto 14px"></div>${kids(p.ground !== 'inherit' ? { groundName: p.ground } : null)}</div>`;
    },
  });

  E({
    type: 'toggleRow', name: 'Switch row', group: 'Inputs', source: 'SwiftUI Toggle (Settings, reminders)',
    props: { label: { label: 'Label', kind: 'text', default: 'Morning reminder' }, detail: { label: 'Detail', kind: 'text', default: '' }, on: { label: 'State', kind: 'select', default: true, options: [[true, 'On'], [false, 'Off']] } },
    examples: [{ label: 'On', props: {} }],
    render(p, ctx) {
      const green = '#34C759';
      return `<div style="display:flex;align-items:center;gap:12px;min-height:44px;padding:6px 0"><div style="flex:1;min-width:0">${T('body', p.label, ctx)}${p.detail ? T('footnote', p.detail, ctx, { tone: 'muted' }) : ''}</div>
        <div style="width:51px;height:31px;border-radius:16px;background:${p.on ? green : ctx.g.ink + '33'};position:relative;flex:none"><div style="position:absolute;top:2px;${p.on ? 'right:2px' : 'left:2px'};width:27px;height:27px;border-radius:50%;background:#fff;box-shadow:0 2px 4px rgba(0,0,0,.2)"></div></div></div>`;
    },
  });

  E({
    type: 'listRow', name: 'List row', group: 'Rows', source: 'DayXero (Settings and Me rows)',
    props: {
      label: { label: 'Label', kind: 'text', default: 'Reminders' }, value: { label: 'Value', kind: 'text', default: '' },
      icon: { label: 'Leading icon', kind: 'select', default: '', options: [['', 'None']].concat(Lab.iconNames.map((n) => [n, n])) },
      chevron: { label: 'Chevron', kind: 'bool', labels: ['Show', 'Hide'], default: true },
      hairline: { label: 'Hairline under it', kind: 'bool', labels: ['Show', 'Hide'], default: true },
    },
    render(p, ctx) {
      return `<div style="display:flex;align-items:center;gap:12px;min-height:52px;${p.hairline ? `border-bottom:1px solid ${ctx.g.muted}40;` : ''}">${p.icon ? Lab.icon(p.icon, 20, ctx.g.ink) : ''}${T('body', p.label, ctx, { style: 'flex:1;min-width:0' })}${p.value ? T('footnote', p.value, ctx, { tone: 'muted' }) : ''}${p.chevron ? Lab.icon('chevron.right', 14, ctx.g.muted) : ''}</div>`;
    },
  });

  E({
    type: 'textField', name: 'Text field', group: 'Inputs', source: 'DayXeroCore/DesignSystem/Metrics.swift (input 52 pt, radius 20)',
    props: { placeholder: { label: 'Placeholder', kind: 'text', default: 'Your name' }, value: { label: 'Typed', kind: 'text', default: '' } },
    render(p, ctx) {
      return `<div style="min-height:52px;border-radius:20px;background:${Lab.c(Lab.fill.surface, ctx.dark)};display:flex;align-items:center;padding:0 16px;${F('body')}color:${p.value ? ctx.g.ink : ctx.g.muted}">${esc(p.value || p.placeholder)}</div>`;
    },
  });

  E({
    type: 'html', name: 'Drawn detail', group: 'Layout', hidden: true, source: '',
    description: 'A fixed piece of drawing (a chart or decoration) that has no settings of its own.',
    props: {},
    render(p, ctx) { return typeof p.fn === 'function' ? p.fn(ctx) : `<div>${p.html || ''}</div>`; },
  });
})();
