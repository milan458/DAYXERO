/* "What's changing": the health timeline sheet (DayXero/Health/HealthTimelineView.swift) and the full story of one
   change (HealthItemDetail, same file). Items, copy and sources come from DayXeroCore/Resources/health-timeline.json. */
(function () {
  'use strict';
  const Lab = window.Lab;
  const E = Lab.element, esc = Lab.esc, T = Lab.text;
  const SRC = 'DayXero/Health/HealthTimelineView.swift';
  const BADGE_SRC = 'DayXero/Health/MilestoneIllustrations.swift';

  /* ---------- Colours from HealthTimelineView / Read4 ---------- */
  const pick = (ctx, light, dark) => (ctx.dark ? dark : light);
  const CORAL = '#FF7A55';
  const cardFill = (ctx) => pick(ctx, '#FFF8EE', '#16382D');            // `card`
  const coralInk = (ctx) => pick(ctx, '#B2361C', '#FFB59E');            // `coralInk`
  const green = (ctx) => Lab.c(Lab.fill.green, ctx.dark);               // DX.Fill.green / Read4.accent
  const reading = (ctx) => Lab.ground('reading', ctx.dark);             // DX.Ground.reading
  const surface = (ctx) => Lab.c(Lab.fill.surface, ctx.dark);           // Read4.surface
  const accentSoft = (ctx) => pick(ctx, 'rgba(15,110,67,0.12)', 'rgba(47,208,138,0.16)');

  /* HealthKitArt.kind(for:) */
  const KIT = {
    'heart-rate': 'heart', 'heart-disease': 'heart', 'carbon-monoxide': 'clouds', 'nicotine-gone': 'clouds', taste: 'berry',
    'fresh-breath': 'sparkle', mood: 'sparkle', circulation: 'breath', 'cravings-fade': 'breath', lips: 'lips', 'skin-glow': 'dawn',
    coughing: 'lungs', 'lung-cancer': 'lungs', hair: 'sprout', 'even-tone': 'flower', 'heart-attack': 'shield', 'mouth-cancer': 'shield',
    'withdrawal-start': 'sea', 'withdrawal-peak': 'peak', sleep: 'night',
  };
  const kitFor = (id) => 'kit:' + (KIT[id] || 'dawn');

  /* MilestoneDrawing.hue(_:) and HealthBadge.tint(for:) */
  const hueFor = (id) => {
    if (['heart-rate', 'circulation', 'heart-disease', 'lips'].includes(id)) return 'coral';
    if (['carbon-monoxide', 'coughing', 'lung-cancer', 'fresh-breath'].includes(id)) return 'sky';
    if (['withdrawal-start', 'cravings-fade', 'hair', 'sleep'].includes(id)) return 'lilac';
    if (['nicotine-gone', 'mood', 'skin-glow'].includes(id)) return 'sun';
    return 'sage';
  };
  const TINT = {
    coral: ['#FFE5DF', 'rgba(255,122,102,0.18)'], sky: ['#E1F0FD', 'rgba(127,192,245,0.18)'], sage: ['#E9ECD7', 'rgba(188,195,136,0.2)'],
    lilac: ['#EEEAFD', 'rgba(183,164,242,0.2)'], sun: ['#FDF2D2', 'rgba(247,197,72,0.18)'],
  };
  const HUES = [['coral', 'Coral (heart, lips)'], ['sky', 'Sky (lungs, breath)'], ['sage', 'Sage'], ['lilac', 'Lilac (mind, sleep)'], ['sun', 'Sun (skin, mood)']];
  const tint = (hue, ctx) => Lab.c(TINT[hue] || TINT.sage, ctx.dark);

  /* ---------- Data: health-timeline.json ---------- */
  // [id, fromHours, toHours, when, title, source]; in items(for:) order (sorted by toHours, then fromHours).
  const ITEMS = {
    cigarettes: [
      ['heart-rate', 0, 1, 'Within minutes', 'Heart rate and blood pressure start to come down', 'acs'],
      ['carbon-monoxide', 12, 72, 'A few days', 'Carbon monoxide in your blood drops to normal', 'acs'],
      ['taste', 48, 120, '2 to 5 days', 'Food starts tasting like food again', null],
      ['fresh-breath', 168, 336, '1 to 2 weeks', 'Fresher breath, brighter smile', null],
      ['skin-glow', 336, 1008, '2 to 6 weeks', 'Your skin starts to glow', null],
      ['lips', 336, 1344, '2 to 8 weeks', 'Your lips get their colour back', null],
      ['circulation', 336, 2184, '2 weeks to 3 months', 'Circulation and lung function improve', 'acs'],
      ['hair', 1440, 2880, '2 to 4 months', 'Stronger, fuller-feeling hair', null],
      ['even-tone', 2184, 4380, '3 to 6 months', 'Dull, tanned patches start to even out', null],
      ['coughing', 720, 8760, '1 to 12 months', 'Coughing and shortness of breath ease', 'acs'],
      ['heart-attack', 8760, 17520, '1 to 2 years', 'Heart attack risk drops sharply', 'acs'],
      ['mouth-cancer', 43800, 87600, '5 to 10 years', 'Risk of mouth, throat and voice-box cancer is about halved', 'acs'],
      ['lung-cancer', 87600, 87600, '10 years', 'Lung cancer risk is about half that of someone who still smokes', 'acs'],
      ['heart-disease', 131400, 131400, '15 years', 'Heart disease risk is close to that of a non-smoker', 'acs'],
    ],
    vape: [
      ['withdrawal-start', 0, 4, 'A few hours', 'Withdrawal can start', 'smokefree-vaping'],
      ['nicotine-gone', 24, 72, 'A few days', 'Most nicotine has left your body', 'cdc-cotinine'],
      ['withdrawal-peak', 0, 168, 'First week', 'Withdrawal is usually at its strongest', 'smokefree'],
      ['mood', 168, 336, '1 to 2 weeks', 'Mood changes from withdrawal usually ease', 'smokefree-mood'],
      ['sleep', 168, 336, '1 to 2 weeks', 'Deeper, steadier sleep', null],
      ['cravings-fade', 336, 672, 'A few weeks', 'Cravings come less often', 'smokefree'],
      ['lips', 336, 1008, '2 to 6 weeks', 'Healthier lips and gums', null],
      ['skin-glow', 720, 2184, '1 to 3 months', 'Clearer, better-hydrated skin', null],
    ],
  };
  const SOURCES = {
    acs: { label: 'Source: American Cancer Society', title: 'American Cancer Society, "Health benefits of quitting smoking over time"' },
    smokefree: { label: 'Source: smokefree.gov', title: 'Smokefree.gov (US National Cancer Institute), "Nicotine withdrawal"' },
    'smokefree-mood': { label: 'Source: smokefree.gov', title: 'Smokefree.gov, "Managing nicotine withdrawal"' },
    'smokefree-vaping': { label: 'Source: smokefree.gov', title: 'Smokefree.gov, "Nicotine withdrawal and vaping"' },
    'cdc-cotinine': { label: 'Source: CDC', title: 'CDC, National Health and Nutrition Examination Survey: cotinine documentation' },
  };
  const NOTE = { vape: "Research on the long-term effects of vaping is still young, so this timeline sticks to what's known." };
  const SWITCH_LABEL = { cigarettes: 'Smoking', vape: 'Vaping' };

  // Sam: Quit Day Fri 6 Nov 2026, day boundary 04:00. Day 3 at 09:40 is 53 h 40 min after Quit Day began.
  const DAY3_ELAPSED = 53 + 40 / 60;

  /** HealthTimeline.state(of:elapsedHours:) */
  function itemState(from, to, elapsed) {
    if (elapsed < 0 || elapsed < from) return { s: 'ahead' };
    if (elapsed >= to) return { s: 'done' };
    const span = Math.max(to - from, 1);
    return { s: 'now', f: Math.min(Math.max((elapsed - from) / span, 0), 1) };
  }
  /** rowState(_:index:elapsed:) */
  const rowState = (item, i, elapsed) => (elapsed < 0 ? { s: i === 0 ? 'first' : 'ahead' } : itemState(item[1], item[2], elapsed));
  const round2 = (x) => Math.round(x * 100) / 100;
  const pct = (f) => Math.round(f * 100) + '%';

  /* ---------- Elements: the timeline ---------- */
  E({
    type: 'changingHeader', name: "What's changing header", group: "What's changing", source: SRC,
    description: 'Eyebrow and stacked marked title on the left; the cheering person in a 128 pt soft circle on the right; the close button over its top corner.',
    props: {
      figure: { label: 'Illustration', kind: 'art', default: 'person:cheer' },
      figureHeight: { label: 'Figure height', kind: 'number', options: [88, 96, 108, 120], unit: ' pt', default: 108 },
      circle: { label: 'Soft circle behind it', kind: 'bool', labels: ['Show', 'Hide'], default: true },
      close: { label: 'Close button', kind: 'bool', labels: ['Show', 'Hide'], default: true },
    },
    examples: [{ label: 'On lime', ground: 'lime', props: {}, kids: [['text', { step: 'footnote', tone: 'muted', text: 'Quit Day in 4 days' }], ['markedTitle', { lead: "What's", word: 'changing', stacked: true }]] }],
    render(p, ctx, kids) {
      const r = reading(ctx);
      const circle = p.circle ? `background:${pick(ctx, 'rgba(255,255,255,0.45)', 'rgba(255,255,255,0.08)')};border-radius:50%;` : '';
      const close = p.close ? `<div role="button" aria-label="Close" style="position:absolute;top:0;right:0;width:44px;height:44px;border-radius:50%;background:${surface(ctx)};display:flex;align-items:center;justify-content:center">${Lab.icon('xmark', 24, r.ink)}</div>` : '';
      return `<div style="position:relative;display:flex;align-items:center;gap:8px">
        <div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:4px">${kids()}</div>
        <div style="width:128px;height:128px;flex:none;display:flex;align-items:center;justify-content:center;overflow:hidden;${circle}">${Lab.art(p.figure, { width: 128, height: p.figureHeight, shirt: CORAL })}</div>
        ${close}</div>`;
    },
  });

  E({
    type: 'changingSwitcher', name: 'Product switcher', group: "What's changing", source: SRC,
    description: 'A capsule with one 44 pt segment per product Sam uses; the picked one is an ink capsule. Shown only with more than one product.',
    props: {
      first: { label: 'First segment', kind: 'text', default: 'Smoking' },
      second: { label: 'Second segment', kind: 'text', default: 'Vaping' },
      selected: { label: 'Picked', kind: 'select', default: 'first', options: [['first', 'First'], ['second', 'Second']] },
    },
    examples: [{ label: 'Smoking picked', ground: 'lime', props: {} }],
    render(p, ctx) {
      const seg = (label, on) => `<div role="button" style="${Lab.font('footnote', { size: 14, weight: 700 })}flex:1;min-height:44px;display:flex;align-items:center;justify-content:center;border-radius:999px;${on ? `background:${ctx.g.ink};color:${reading(ctx).bg};` : `color:${ctx.g.ink};`}">${esc(label)}</div>`;
      return `<div style="display:flex;padding:4px;border-radius:999px;background:${pick(ctx, 'rgba(30,26,58,0.08)', 'rgba(255,255,255,0.08)')}">${seg(p.first, p.selected === 'first')}${seg(p.second, p.selected === 'second')}</div>`;
    },
  });

  function railHTML(kind, ctx) {
    if (kind === 'none') return '';
    const box = 'position:absolute;left:11.5px;width:3px;top:14px;bottom:-14px;';
    if (kind === 'solid') return `<div style="${box}background:${green(ctx)}"></div>`;
    return `<div style="${box}"><svg width="3" height="100%" style="display:block;overflow:visible" aria-hidden="true"><line x1="1.5" y1="0" x2="1.5" y2="100%" stroke="${ctx.g.ink}" stroke-width="3" stroke-linecap="round" stroke-dasharray="1 6"/></svg></div>`;
  }
  function nodeHTML(state, ctx) {
    if (state === 'done') return `<div style="width:26px;height:26px;border-radius:50%;background:${green(ctx)};display:flex;align-items:center;justify-content:center">${Lab.icon('checkmark', 18, reading(ctx).bg)}</div>`;
    if (state === 'now' || state === 'first') return `<div style="width:26px;height:26px;border-radius:50%;background:${CORAL};box-shadow:0 0 0 6px rgba(255,122,85,0.25)"></div>`;
    return `<div style="width:26px;height:26px;border-radius:50%;box-sizing:border-box;border:3px solid ${ctx.g.ink};background:${ctx.g.bg}"></div>`;
  }

  E({
    type: 'changingRow', name: 'Timeline row', group: "What's changing", source: SRC,
    description: 'One change on the rail. Done: green tick on a solid line. Under way: raised cream card with a coral bar. From Quit Day (before it): raised, no bar. Ahead: open ring on a dotted line. Kit illustration 64 pt raised, 48 pt flat.',
    props: {
      state: { label: 'State', kind: 'select', default: 'ahead', options: [['done', 'Done'], ['now', 'Under way'], ['first', 'From Quit Day (before it)'], ['ahead', 'Ahead']] },
      kicker: { label: 'Kicker', kind: 'text', default: 'A few days' },
      title: { label: 'Title', kind: 'text', default: 'Carbon monoxide in your blood drops to normal' },
      art: { label: 'Illustration', kind: 'art', default: 'kit:clouds' },
      progress: { label: 'Bar filled (under way)', kind: 'number', options: [[0, '0%'], [0.08, '8%'], [0.25, '25%'], [0.32, '32%'], [0.5, '50%'], [0.62, '62%'], [0.69, '69%'], [0.75, '75%'], [1, '100%']], default: 0.5 },
      rail: { label: 'Line below', kind: 'select', default: 'dotted', options: [['solid', 'Solid green'], ['dotted', 'Dotted'], ['none', 'None (last row)']] },
      cardRadius: { label: 'Card corner radius', kind: 'number', options: [14, 18, 20, 24, 28], unit: ' pt', default: 20, global: true },
    },
    examples: [
      { label: 'Under way', ground: 'lime', props: { state: 'now', kicker: 'Under way · A few days', progress: 0.69, rail: 'solid' } },
      { label: 'Done', ground: 'lime', props: { state: 'done', kicker: 'Within minutes', title: 'Heart rate and blood pressure start to come down', art: 'kit:heart', rail: 'solid' } },
      { label: 'Ahead', ground: 'lime', props: { state: 'ahead', kicker: '1 to 2 weeks', title: 'Fresher breath, brighter smile', art: 'kit:sparkle' } },
    ],
    render(p, ctx) {
      const raised = p.state === 'now' || p.state === 'first';
      const size = raised ? 64 : 48;
      const titleColour = raised ? reading(ctx).ink : ctx.g.ink;
      const bar = p.state === 'now'
        ? `<div style="height:8px;margin-top:4px;border-radius:999px;background:${pick(ctx, '#EDE6DA', '#2A4A3E')};overflow:hidden"><div style="height:100%;width:${Math.min(1, Math.max(0, +p.progress)) * 100}%;border-radius:999px;background:${CORAL}"></div></div>`
        : '';
      const card = raised ? `padding:12px;border-radius:${p.cardRadius}px;background:${cardFill(ctx)};box-shadow:0 4px 10px rgba(0,0,0,0.08);` : '';
      return `<div role="button" style="display:flex;align-items:stretch;gap:12px;padding-bottom:12px">
        <div style="position:relative;width:26px;flex:none">${railHTML(p.rail, ctx)}<div style="position:relative;margin-top:${raised ? 30 : 10}px">${nodeHTML(p.state, ctx)}</div></div>
        <div style="flex:1;min-width:0;display:flex;align-items:center;gap:12px;${card}">
          <div style="flex:none;width:${size}px;height:${size}px">${Lab.art(p.art, { width: size, height: size, radius: raised ? 18 : 14 })}</div>
          <div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:3px">
            ${T('caption', p.kicker, ctx, { color: raised ? coralInk(ctx) : ctx.g.muted })}
            ${T(raised ? 'headline' : 'body', p.title, ctx, { size: raised ? 18 : 16, weight: raised ? 800 : 700, color: titleColour })}
            ${bar}
          </div>
        </div></div>`;
    },
  });

  E({
    type: 'changingNote', name: 'Thin-evidence note', group: "What's changing", source: SRC,
    description: 'The plain note under a product whose research is still young: 14 pt muted, 12 pt padding, dashed 18 pt outline.',
    props: { text: { label: 'Words', kind: 'text', default: NOTE.vape } },
    examples: [{ label: 'Vaping', ground: 'lime', props: {} }],
    render(p, ctx) {
      return `<div style="padding:12px;border-radius:18px;border:1px dashed ${ctx.g.muted}">${T('footnote', p.text, ctx, { tone: 'muted' })}</div>`;
    },
  });

  E({
    type: 'changingLink', name: 'Source link', group: "What's changing", source: SRC,
    description: 'A 12 pt underlined link to a source.',
    props: {
      text: { label: 'Words', kind: 'text', default: 'Source: American Cancer Society' },
      weight: { label: 'Weight', kind: 'number', options: [400, 600, 700], default: 600 },
      tone: { label: 'Colour', kind: 'colour', default: 'ink' },
    },
    examples: [{ label: 'On lime', ground: 'lime', props: {} }],
    render(p, ctx) {
      return `<div role="link" style="${Lab.font('footnote', { size: 12, weight: +p.weight })}color:${Lab.colour(p.tone, ctx)};text-decoration:underline">${esc(p.text)}</div>`;
    },
  });

  /* ---------- Elements: the full story (HealthItemDetail) ---------- */
  // MilestoneDrawing, held still (as with Reduce Motion), on its 64-point grid. Ported: the two changes Sam opens.
  const INK = { coral: '#FF7A66', coralDeep: '#E2563F', sky: '#7FC0F5', grey: '#B3B6A4' };
  const HEART = 'M32 54 C15 43 8 33 8 23 C8 15 14 9.5 21.5 9.5 C26.5 9.5 30 12.5 32 16.5 C34 12.5 37.5 9.5 42.5 9.5 C50 9.5 56 15 56 23 C56 33 49 43 32 54 Z';
  const DRAWINGS = {
    'heart-rate': () => `<path d="${HEART}" transform="translate(0 3)" fill="${INK.coralDeep}"/><path d="${HEART}" fill="${INK.coral}"/>
      <ellipse cx="0" cy="0" rx="5" ry="3" transform="translate(20 19) rotate(-35)" fill="rgba(255,255,255,0.55)"/>
      <path d="M10 32 H21 L25 25 L30 39 L34 28 L37 32 H54" fill="none" stroke="#fff" stroke-width="3.2" stroke-linecap="round" stroke-linejoin="round"/>`,
    'carbon-monoxide': () => `<ellipse cx="30" cy="43" rx="19" ry="13" fill="${INK.coralDeep}"/><ellipse cx="30" cy="41" rx="19" ry="13" fill="${INK.coral}"/>
      <ellipse cx="30" cy="41" rx="9" ry="5.5" fill="${INK.coralDeep}" fill-opacity="0.55"/>
      <ellipse cx="0" cy="0" rx="4" ry="2" transform="translate(20 36) rotate(-20)" fill="rgba(255,255,255,0.55)"/>
      ${[[16, 20, 6], [34, 14, 7.5], [50, 22, 5]].map(([x, y, r]) => `<circle cx="${x}" cy="${y}" r="${r}" fill="${INK.sky}"/><circle cx="${x - r * 0.33}" cy="${y - r * 0.33}" r="${r * 0.3}" fill="rgba(255,255,255,0.85)"/>`).join('')}
      <circle cx="55" cy="45" r="3.6" fill="${INK.grey}" opacity="0.95"/>`,
  };
  const DRAWING_OPTIONS = [['heart-rate', 'Heart rate (heart and trace)'], ['carbon-monoxide', 'Carbon monoxide (blood cell and bubbles)']];

  /** HealthBadge at a size, for a state. */
  function badgeHTML(id, state, progress, size, ctx) {
    const ahead = state === 'ahead';
    const fill = ahead ? pick(ctx, '#E7E9DD', 'rgba(255,255,255,0.07)') : tint(hueFor(id), ctx);
    const art = size * 0.68;
    const draw = DRAWINGS[id] ? DRAWINGS[id]() : '';
    let ring = '';
    if (state === 'now') {
      const pad = size * 0.09, d = size + 2 * pad, lw = Math.max(2, size / 22), r = d / 2;
      ring = `<svg width="${d}" height="${d}" viewBox="0 0 ${d} ${d}" style="position:absolute;left:${-pad}px;top:${-pad}px;overflow:visible;transform:rotate(-90deg)" aria-hidden="true"><circle cx="${r}" cy="${r}" r="${r}" fill="none" stroke="${green(ctx)}" stroke-width="${lw}" stroke-linecap="round" pathLength="1" stroke-dasharray="${Math.max(+progress, 0.03)} 1"/></svg>`;
    }
    let check = '';
    if (state === 'done') {
      const d = Math.max(size * 0.36, 14);
      check = `<div style="position:absolute;right:${-d * 0.15}px;bottom:${-d * 0.15}px;width:${d}px;height:${d}px;border-radius:50%;background:${green(ctx)};box-shadow:inset 0 0 0 2px ${Lab.c(Lab.fill.raised, ctx.dark)};display:flex;align-items:center;justify-content:center">${Lab.icon('checkmark', d * 0.8, reading(ctx).bg)}</div>`;
    }
    return `<div style="position:relative;width:${size}px;height:${size}px;flex:none">
      <div style="position:absolute;inset:0;border-radius:50%;background:${fill};display:flex;align-items:center;justify-content:center">
        <svg width="${art}" height="${art}" viewBox="0 0 64 64" style="${ahead ? 'filter:grayscale(1);opacity:0.5;' : ''}" aria-hidden="true">${draw}</svg></div>${ring}${check}</div>`;
  }

  E({
    type: 'changingHero', name: 'Full story hero', group: "What's changing", source: BADGE_SRC,
    description: "The change's 150 pt badge on a soft radial glow in its body-part colour, 20 pt above and below, with the close button top right. Reached gets a tick, under way a green ring, ahead goes grey.",
    props: {
      drawing: { label: 'Drawing', kind: 'select', default: 'carbon-monoxide', options: DRAWING_OPTIONS },
      state: { label: 'State', kind: 'select', default: 'now', options: [['done', 'Reached'], ['now', 'Under way'], ['ahead', 'Ahead']] },
      progress: { label: 'Ring filled (under way)', kind: 'number', options: [[0, '0%'], [0.25, '25%'], [0.5, '50%'], [0.69, '69%'], [0.75, '75%'], [1, '100%']], default: 0.5 },
      size: { label: 'Badge size', kind: 'number', options: [120, 140, 150, 160, 180], unit: ' pt', default: 150 },
      glow: { label: 'Soft glow', kind: 'bool', labels: ['Show', 'Hide'], default: true },
      close: { label: 'Close button', kind: 'bool', labels: ['Show', 'Hide'], default: true },
    },
    examples: [{ label: 'Under way', ground: 'reading', props: { progress: 0.69 } }, { label: 'Reached', ground: 'reading', props: { drawing: 'heart-rate', state: 'done' } }],
    render(p, ctx) {
      const glow = p.glow ? `background:radial-gradient(circle at center, ${tint(hueFor(p.drawing), ctx)} 40px, rgba(255,255,255,0) 190px);` : '';
      const close = p.close ? `<div role="button" aria-label="Close" style="position:absolute;top:12px;right:0;width:44px;height:44px;border-radius:50%;background:${surface(ctx)};display:flex;align-items:center;justify-content:center">${Lab.icon('xmark', 24, ctx.g.ink)}</div>` : '';
      return `<div style="position:relative"><div style="padding:20px 0;display:flex;justify-content:center;${glow}">${badgeHTML(p.drawing, p.state, p.progress, +p.size, ctx)}</div>${close}</div>`;
    },
  });

  E({
    type: 'changingParagraph', name: 'Story paragraph', group: "What's changing", source: SRC,
    description: '16 pt body with 5 pt extra line spacing, ink at 86%.',
    props: { text: { label: 'Words', kind: 'text', default: 'A paragraph of the story.' } },
    render(p, ctx) {
      return T('body', p.text, ctx, { size: 16, weight: 400, lh: 1.625, style: 'opacity:0.86' });
    },
  });

  const SPARKLE = '<path d="M12 1.5 Q12 12 22.5 12 Q12 12 12 22.5 Q12 12 1.5 12 Q12 12 12 1.5 Z" fill="currentColor"/>';
  E({
    type: 'changingNoticeRow', name: 'Notice row', group: "What's changing", source: SRC,
    description: 'A green sparkle in a 34 pt circle in the change\'s colour, then one thing you might notice.',
    props: {
      text: { label: 'Words', kind: 'text', default: 'More energy as the days go on' },
      hue: { label: 'Circle colour', kind: 'select', default: 'sky', options: HUES },
    },
    examples: [{ label: 'Sky', ground: 'reading', props: {} }],
    render(p, ctx) {
      return `<div style="display:flex;align-items:center;gap:12px">
        <div style="width:34px;height:34px;flex:none;border-radius:50%;background:${tint(p.hue, ctx)};display:flex;align-items:center;justify-content:center;color:${green(ctx)}"><svg width="14" height="14" viewBox="0 0 24 24" aria-hidden="true">${SPARKLE}</svg></div>
        ${T('body', p.text, ctx, { size: 16, weight: 400, style: 'flex:1;min-width:0' })}</div>`;
    },
  });

  E({
    type: 'changingHelps', name: 'Help it along card', group: "What's changing", source: SRC,
    description: 'Soft green card, 16 pt padding, radius 22: a green caption and one line of advice.',
    props: {
      heading: { label: 'Heading', kind: 'text', default: 'Help it along' },
      text: { label: 'Words', kind: 'text', default: 'Get outside and move a little.' },
      radius: { label: 'Corner radius', kind: 'number', options: [18, 20, 22, 24, 28], unit: ' pt', default: 22 },
    },
    examples: [{ label: 'Reading', ground: 'reading', props: {} }],
    render(p, ctx) {
      return `<div style="display:flex;flex-direction:column;gap:6px;padding:16px;border-radius:${p.radius}px;background:${accentSoft(ctx)}">${T('caption', p.heading, ctx, { color: green(ctx) })}${T('body', p.text, ctx, { size: 16, weight: 400 })}</div>`;
    },
  });

  E({
    type: 'changingGrabber', name: 'Sheet grabber', group: "What's changing", source: 'SwiftUI .presentationDragIndicator(.visible)',
    description: "The system sheet's drag indicator.",
    props: {},
    render(p, ctx) {
      return `<div style="position:absolute;top:${(ctx.device ? ctx.device.top : 62) + 5}px;left:50%;margin-left:-18px;width:36px;height:5px;border-radius:3px;background:${ctx.g.muted};opacity:0.4;z-index:4"></div>`;
    },
  });

  /* ---------- Screen: the timeline ---------- */
  const DISCLAIMER = "General information, not medical advice. Everyone's body moves at its own pace.";

  Lab.screen({
    id: 'changing',
    name: "What's changing",
    area: 'Progress',
    source: SRC,
    ground: 'lime',
    note: 'A sheet, opened from "See the whole timeline" on Progress and from the body card on Today, so no tab bar. Sam uses cigarettes (primary) and a vape, so the switcher shows Smoking and Vaping. Quit Day starts Fri 6 Nov 04:00 (day boundary 4); Day 3 is Sun 8 Nov 09:40, 53 h 40 min in. Bars are rounded to the nearest percent. The eyebrow date is the en_US format; en_GB reads "Sun 8 Nov".',
    states: [
      { id: 'prep', label: 'Prep · Mon 2 Nov · Smoking' },
      { id: 'day3', label: 'Day 3 · Sun 8 Nov 09:40 · Smoking' },
      { id: 'day3-vape', label: 'Day 3 · Sun 8 Nov 09:40 · Vaping' },
    ],
    build(h, state) {
      const prep = state.id === 'prep';
      const product = state.id === 'day3-vape' ? 'vape' : 'cigarettes';
      const elapsed = prep ? -1 : DAY3_ELAPSED;
      const items = ITEMS[product];
      const key = product === 'vape' ? 'vape' : 'smoking';

      const eyebrow = prep
        ? h('text', 'eyebrow', { step: 'footnote', tone: 'muted', text: 'Quit Day in 4 days', alts: { text: ['Quit Day tomorrow'] } })
        : h('text', 'eyebrow', { step: 'footnote', tone: 'muted', text: 'Day 3 · Sun, Nov 8', alts: { text: ['Day 3 · Sun 8 Nov'] } });

      const rows = items.map((item, i) => {
        const st = rowState(item, i, elapsed);
        const next = i + 1 < items.length ? rowState(items[i + 1], i + 1, elapsed) : null;
        const solid = ['done', 'now'].includes(st.s) && next && ['done', 'now'].includes(next.s);
        const [id, , , when, title] = item;
        const kicker = st.s === 'now' ? 'Under way · ' + when : st.s === 'first' ? 'From Quit Day' : when;
        const alts = [when, 'Under way · ' + when].concat(i === 0 ? ['From Quit Day'] : []).filter((k) => k !== kicker);
        return h('changingRow', `row-${key}-${id}`, {
          state: st.s, kicker, title, art: kitFor(id),
          progress: st.s === 'now' ? round2(st.f) : 0,
          rail: i === items.length - 1 ? 'none' : solid ? 'solid' : 'dotted',
          alts: { kicker: alts },
        });
      });

      // sources(for:): every cited source once, in first-appearance order; "(health changes)" when looks items are listed.
      const seen = new Set();
      const sourceIds = items.map((it) => it[5]).filter((s) => s && !seen.has(s) && seen.add(s));
      const links = sourceIds.map((s, i) => h('changingLink', `source-${key}-${i}`, {
        text: SOURCES[s].label + ' (health changes)', weight: 600, tone: 'ink', alts: { text: [SOURCES[s].label] },
      }));

      return h('stack', 'body', { padX: 16, padTop: 12, padBottom: 32, gap: 12 }, [
        h('changingHeader', 'header', {}, [
          eyebrow,
          h('markedTitle', 'title', { lead: "What's", word: 'changing', stacked: true, step: 'large', mark: 'underline' }),
        ]),
        h('changingSwitcher', 'switcher', {
          first: SWITCH_LABEL.cigarettes, second: SWITCH_LABEL.vape, selected: product === 'vape' ? 'second' : 'first',
          alts: { first: ['Vaping', 'Pouches'], second: ['Smoking', 'Pouches'] },
        }),
        h('stack', 'rows-' + key, { padTop: 8, gap: 0 }, rows),
        NOTE[product] ? h('changingNote', 'note-' + key, { text: NOTE[product] }) : null,
        h('stack', 'sources', { padTop: 12, gap: 4 }, links.concat([
          h('text', 'disclaimer', { step: 'footnote', size: 12, weight: 400, tone: 'muted', text: DISCLAIMER }),
        ])),
      ]);
    },
  });

  /* ---------- Screen: the full story of one change ---------- */
  const STORY = {
    'heart-rate': {
      when: 'Within minutes', title: 'Heart rate and blood pressure start to come down', source: 'acs', from: 0, to: 1,
      paragraphs: [
        'Nicotine keeps your heart on a gentle sprint all day: a little faster, a little tighter, a little more pressure in every beat. The moment it stops arriving, your heart gets to ease off the pedal.',
        "In your first smoke-free hours your pulse and blood pressure start drifting back towards where they want to be. You won't feel fireworks. You might feel a bit calmer in your chest, a bit warmer in your hands. That's your heart getting a breather it hasn't had in a long time.",
      ],
      notice: ['Warmer hands and feet', 'A steadier, slower heartbeat at rest', 'Feeling a little calmer in your chest'],
      helps: 'Slow breaths help this along. Try the breathing orb when you feel wired.',
    },
    'carbon-monoxide': {
      when: 'A few days', title: 'Carbon monoxide in your blood drops to normal', source: 'acs', from: 12, to: 72,
      paragraphs: [
        'Smoke carries carbon monoxide, the same gas that comes out of a car exhaust. It sneaks into your blood and sits where oxygen should be, so every part of you runs on a little less air than it needs.',
        "Within a few days it's gone. Your blood carries a full load of oxygen again, to your muscles, your brain, your skin. Many people notice more energy and clearer thinking in this first stretch, even while cravings are loud.",
      ],
      notice: ['More energy as the days go on', 'Clearer, less foggy thinking', 'Easier breath on a short walk'],
      helps: 'Get outside and move a little. Fresh air and a short walk make the most of all that new oxygen.',
    },
  };

  /** TodayView.relative(hours:) */
  function relative(hours) {
    const hh = Math.max(hours, 0);
    if (hh < 48) return `in ${Math.max(Math.ceil(hh), 1)}h`;
    const days = Math.round(hh / 24);
    if (days < 14) return `in ${days} days`;
    if (days < 60) return `in ${Math.round(days / 7)} weeks`;
    if (days < 730) return `in ${Math.round(days / 30.4)} months`;
    return `in ${Math.round(days / 365)} years`;
  }

  Lab.screen({
    id: 'changing-detail',
    name: "What's changing · full story",
    area: 'Progress',
    source: SRC + ' (HealthItemDetail)',
    ground: 'reading',
    note: 'The sheet a timeline row opens (large detent, grabber visible), on the reading ground. The badge drawings are MilestoneDrawing held still, as with Reduce Motion; in the app they loop. Day 3 is Sun 8 Nov 09:40, 53 h 40 min after Quit Day began.',
    states: [
      { id: 'prep', label: 'Prep · Mon 2 Nov · Heart rate (ahead)' },
      { id: 'day3', label: 'Day 3 · Carbon monoxide (under way)' },
      { id: 'day3-done', label: 'Day 3 · Heart rate (reached)' },
    ],
    overlay(h) {
      return h('changingGrabber', 'grabber', {});
    },
    build(h, state) {
      const id = state.id === 'day3' ? 'carbon-monoxide' : 'heart-rate';
      const it = STORY[id];
      const elapsed = state.id === 'prep' ? -1 : DAY3_ELAPSED;
      const st = itemState(it.from, it.to, elapsed);

      const eyebrows = { done: 'Reached · ' + it.when, now: 'Happening now · ' + it.when, ahead: 'Ahead · ' + it.when };
      const status = st.s === 'now' ? `${pct(st.f)} of the way · done ${relative(it.to - elapsed)}`
        : st.s === 'ahead' && elapsed >= 0 ? `Starts ${relative(it.from - elapsed)}`
          : st.s === 'ahead' ? 'Counts from Quit Day' : null;

      return h('stack', 'body', { padX: 20, padBottom: 20, gap: 16 }, [
        h('changingHero', 'hero', { drawing: id, state: st.s, progress: st.s === 'now' ? round2(st.f) : 0 }),
        h('stack', 'head', { gap: 6, align: 'center', textAlign: 'center' }, [
          h('text', 'eyebrow', { step: 'caption', tone: st.s === 'ahead' ? 'muted' : 'green', align: 'center', text: eyebrows[st.s],
            alts: { text: Object.values(eyebrows).filter((e) => e !== eyebrows[st.s]) } }),
          h('text', 'story-title', { step: 'title', align: 'center', text: it.title }),
          status ? h('text', 'status', { step: 'footnote', tone: 'muted', align: 'center', text: status }) : null,
        ]),
        ...it.paragraphs.map((t, i) => h('changingParagraph', 'para-' + i, { text: t })),
        h('stack', 'notice', { gap: 12 }, [
          h('text', 'notice-heading', { step: 'caption', tone: 'muted', text: 'What you might notice' }),
          ...it.notice.map((t, i) => h('changingNoticeRow', 'notice-' + i, { text: t, hue: hueFor(id) })),
        ]),
        h('changingHelps', 'helps', { heading: 'Help it along', text: it.helps }),
        h('stack', 'footer', { padTop: 8, gap: 4 }, [
          h('changingLink', 'source', { text: SOURCES[it.source].title, weight: 400, tone: 'green' }),
          h('text', 'disclaimer', { step: 'footnote', size: 12, weight: 400, tone: 'muted',
            text: "Everyone's body moves at its own pace, and a slip doesn't undo what's already healed. Not medical advice." }),
        ]),
      ]);
    },
  });
})();
