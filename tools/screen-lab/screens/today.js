/* Today tab (F08): DayXero/Home/HomeView.swift (TodayView), TodayHeaderV4.swift, TodayCardsV4.swift, HomeSnapshot.swift,
   DayXero/ProgramV2/ProgramTodayCard.swift, DayXero/NRT/NRTCards.swift (NRTInviteRow). See ../FORMAT.md. */
(function () {
  'use strict';
  const Lab = window.Lab;
  const E = Lab.element, esc = Lab.esc, T = Lab.text, F = Lab.font;
  const HOME = 'DayXero/Home/HomeView.swift';
  const HEADER = 'DayXero/Home/TodayHeaderV4.swift';
  const CARDS = 'DayXero/Home/TodayCardsV4.swift';
  const CREAM = Lab.CREAM;
  /** DX.Ground.reading, which every Today card below the header uses explicitly. */
  const R = (ctx) => Lab.ground('reading', ctx.dark);
  const raised = (ctx) => Lab.c(Lab.fill.raised, ctx.dark);
  const surface = (ctx) => Lab.c(Lab.fill.surface, ctx.dark);
  const green = (ctx) => Lab.c(Lab.fill.green, ctx.dark);
  /** Ink at an opacity, as SwiftUI's `.opacity` on a colour. */
  const inkA = (ctx, a) => (ctx.dark ? `rgba(255,248,238,${a})` : `rgba(30,26,58,${a})`);

  /* SF Symbols this screen uses that lab.js doesn't draw (smoke, wind, bandage, sos.circle). */
  const SYMBOLS = {
    smoke: (c) => `<path d="M6.5 17.5a3.6 3.6 0 0 1-.4-7.2A5 5 0 0 1 15.6 9a3.4 3.4 0 0 1 2.4 6.3 2.6 2.6 0 0 1-1.9 2.2z" fill="${c}"/><path d="M15 7.2a3.2 3.2 0 0 1 5.6 2.4" fill="none" stroke="${c}" stroke-width="2" stroke-linecap="round"/>`,
    wind: (c) => `<path d="M3 9h10.5a2.8 2.8 0 1 0-2.8-2.8M3 13h15a2.8 2.8 0 1 1-2.8 2.8M3 17h7" fill="none" stroke="${c}" stroke-width="2.2" stroke-linecap="round"/>`,
    pouch: (c) => `<circle cx="7.5" cy="12" r="4.5" fill="none" stroke="${c}" stroke-width="2.2"/><circle cx="16.5" cy="12" r="4.5" fill="none" stroke="${c}" stroke-width="2.2"/>`,
    bandage: (c) => `<g transform="rotate(-45 12 12)"><rect x="2" y="7.6" width="20" height="8.8" rx="4.4" fill="none" stroke="${c}" stroke-width="2"/><path d="M8.5 7.6v8.8M15.5 7.6v8.8" stroke="${c}" stroke-width="1.6"/><circle cx="11" cy="10.8" r=".9" fill="${c}"/><circle cx="13" cy="13.2" r=".9" fill="${c}"/></g>`,
    'sos.circle': (c) => `<circle cx="12" cy="12" r="10" fill="none" stroke="${c}" stroke-width="1.8"/><g fill="none" stroke="${c}" stroke-width="1.4" stroke-linecap="round"><path d="M8.4 10.3c-.3-.5-.8-.8-1.4-.8-.8 0-1.3.4-1.3 1.1 0 1.4 2.8.9 2.8 2.5 0 .7-.6 1.2-1.5 1.2-.7 0-1.2-.3-1.5-.8"/><ellipse cx="12" cy="12" rx="1.6" ry="2.5"/><path d="M18.3 10.3c-.3-.5-.8-.8-1.4-.8-.8 0-1.3.4-1.3 1.1 0 1.4 2.8.9 2.8 2.5 0 .7-.6 1.2-1.5 1.2-.7 0-1.2-.3-1.5-.8"/></g>`,
  };
  const symbol = (name, size, colour) => (SYMBOLS[name]
    ? `<svg viewBox="0 0 24 24" width="${size}" height="${size}" style="flex:none;display:block" aria-hidden="true">${SYMBOLS[name](colour)}</svg>`
    : Lab.icon(name, size, colour));

  /* ---------- Header (TodayHeaderV4) ---------- */
  E({
    type: 'todayHeader', name: 'Today header', group: 'Today', source: HEADER,
    description: "The coloured header card: sky and crew member, the date line and greeting, and three stat tiles. Apricot (Xero) in the morning and afternoon, violet (Glim) in the evening and at night.",
    props: {
      ground: { label: 'Colour', kind: 'select', default: 'apricot', options: [['apricot', 'Apricot (morning, afternoon)'], ['violet', 'Violet (evening, night)']].concat(Lab.groundNames.filter((g) => g !== 'apricot' && g !== 'violet').map((g) => [g, Lab.cap(g)])) },
      radius: { label: 'Corner radius', kind: 'number', options: [18, 24, 28, 36], unit: ' pt', default: 24 },
    },
    examples: [{ label: 'Morning', ground: 'reading', props: {}, kids: [['todayStat', { value: '3', label: 'days clear' }]] }],
    render(p, ctx, kids) {
      const c = ctx.with({ groundName: p.ground });
      return `<div style="display:flex;flex-direction:column;background:${c.g.bg};color:${c.g.ink};border-radius:${p.radius}px;overflow:hidden">${kids({ groundName: p.ground })}</div>`;
    },
  });

  E({
    type: 'todaySky', name: 'Today sky', group: 'Today', source: HEADER,
    description: 'HeroScene, 210 pt: the horizon by time of day with a paper edge in the header colour, the crew member (scene size, 140 pt) standing on it, and the 44 pt profile button.',
    props: {
      scene: { label: 'Sky', kind: 'select', default: 'dawn', options: [['dawn', 'Dawn (morning)'], ['path', 'Path (afternoon)'], ['dusk', 'Dusk (evening)'], ['night', 'Night'], ['sea', 'Sea']] },
      clarity: { label: 'Sky clarity', kind: 'number', options: [20, 23, 26, 28, 34, 40, 48, 60, 80, 100], default: 28 },
      character: { label: 'Crew member', kind: 'art', default: 'xero:hello' },
      size: { label: 'Crew size', kind: 'number', options: [88, 120, 140, 160, 200], unit: ' pt', default: 140 },
      stage: { label: 'Crew stage', kind: 'select', default: 1, options: [[1, 'Stage 1 (under 7 days)'], [2, 'Stage 2 (7–13 days)'], [3, 'Stage 3 (14–27 days)'], [4, 'Stage 4 (28+ days)']] },
      height: { label: 'Height', kind: 'number', options: [160, 180, 210, 240, 280], unit: ' pt', default: 210 },
      initial: { label: 'Profile button letter', kind: 'text', default: 'S' },
      avatar: { label: 'Profile button', kind: 'bool', labels: ['Show', 'Hide'], default: true },
    },
    examples: [{ label: 'Dawn, Xero', ground: 'apricot', props: {} }],
    render(p, ctx) {
      const w = Math.max(200, (ctx.width || 402) - 32);
      const sky = Lab.art('extra:hero', { width: w, height: p.height, radius: 0, scene: { kind: p.scene, clarity: +p.clarity, edge: ctx.g.bg } });
      const crew = p.character && p.character !== 'none'
        ? `<div style="position:absolute;left:0;right:0;bottom:6px;display:flex;justify-content:center;line-height:0">${Lab.art(p.character, { size: +p.size, stage: +p.stage })}</div>` : '';
      const avatar = p.avatar
        ? `<div role="button" aria-label="Profile and settings" style="position:absolute;top:12px;right:12px;width:44px;height:44px;border-radius:50%;background:rgba(255,248,238,.9);display:flex;align-items:center;justify-content:center;${F('headline')}color:${Lab.NAVY}">${esc(String(p.initial).slice(0, 1).toUpperCase())}</div>` : '';
      return `<div style="position:relative;height:${p.height}px;overflow:hidden;line-height:0">${sky}${crew}${avatar}</div>`;
    },
  });

  E({
    type: 'todayStat', name: 'Today stat tile', group: 'Today', source: 'DayXeroCore/DesignSystem/V4/Cards4.swift (StatTile)',
    description: '24 pt number over a 12 pt label in sentence case, on the card-on-colour fill (16 pt padding, radius 18). Counts up when it appears.',
    props: { value: { label: 'Number', kind: 'text', default: '3' }, label: { label: 'Label', kind: 'text', default: 'days clear' } },
    examples: [{ label: 'On apricot', ground: 'apricot', props: { value: '$15.65', label: 'kept' } }],
    render(p, ctx) {
      return `<div style="flex:1 1 0;min-width:0;display:flex;flex-direction:column;gap:2px;padding:16px;border-radius:18px;background:${ctx.g.card}">${T('title', p.value, ctx, { style: 'font-variant-numeric:tabular-nums;white-space:nowrap;overflow:hidden' })}${T('caption', p.label, ctx, { tone: 'muted', upper: false })}</div>`;
    },
  });

  /* ---------- Coloured action card (ColourCard) ---------- */
  const FILLS = [['#2A52DB', 'Ocean (wave)'], ['#0F6E43', 'Lesson green'], ['#2A1C6E', 'Glim violet (check-in)'], ['#0E0B2B', 'Night (wind down)'], ['#4A3596', 'Violet'], ['#FF7A55', 'Coral']];
  E({
    type: 'todayColourCard', name: 'Today colour card', group: 'Today', source: CARDS + ' (ColourCard)',
    description: 'A coloured action card: caption kicker in capitals, 19 pt title, 14 pt line and a chevron in a 44 pt circle. Cream text on every fill, 16 pt padding, radius 24, lip shadow.',
    props: {
      kicker: { label: 'Kicker', kind: 'text', default: 'Your coffee wave' },
      title: { label: 'Title', kind: 'text', default: 'Usually comes around 09:40' },
      detail: { label: 'Line', kind: 'text', default: '' },
      fill: { label: 'Fill', kind: 'select', default: '#2A52DB', options: FILLS },
      chevron: { label: 'Chevron', kind: 'bool', labels: ['Show', 'Hide'], default: true },
      radius: { label: 'Corner radius', kind: 'number', options: [18, 24, 28, 36], unit: ' pt', default: 24, global: true },
    },
    examples: [
      { label: 'Wave (ocean)', ground: 'reading', props: { detail: 'Jelli is ready if the wave comes.' } },
      { label: 'Lesson (green)', ground: 'reading', props: { kicker: 'Today · Day 2 · 3 min', title: 'The noisy passengers', fill: '#0F6E43' } },
    ],
    render(p, ctx) {
      const t = (step, s) => T(step, s, ctx, { color: CREAM });
      return `<div role="button" style="display:flex;align-items:center;gap:12px;padding:16px;border-radius:${p.radius}px;background:${esc(p.fill)};box-shadow:0 5px 0 rgba(0,0,0,.14)">
        <div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:4px">${t('caption', p.kicker)}${t('headline', p.title)}${p.detail ? t('footnote', p.detail) : ''}</div>
        ${p.chevron ? `<div style="width:44px;height:44px;border-radius:50%;background:rgba(255,248,238,.2);display:flex;align-items:center;justify-content:center;flex:none">${Lab.icon('chevron.right', 18, CREAM)}</div>` : ''}</div>`;
    },
  });

  /* ---------- Your day (YourDayList) ---------- */
  E({
    type: 'todayYourDay', name: 'Your day list', group: 'Today', source: CARDS + ' (YourDayList)',
    description: '"YOUR DAY": the pledge, today\'s session and the evening check-in on a raised card (radius 18, 14 pt sides).',
    props: { title: { label: 'Heading', kind: 'text', default: 'YOUR DAY' } },
    examples: [{ label: 'Day 3', ground: 'reading', props: {}, kids: [['todayDayRow', { label: 'Morning pledge', meta: 'done', done: true, divider: false }], ['todayDayRow', { label: 'The noisy passengers', meta: '3 min' }]] }],
    render(p, ctx, kids) {
      const r = R(ctx);
      return `<div style="display:flex;flex-direction:column;padding:0 14px 4px;border-radius:18px;background:${raised(ctx)}">
        <div style="${F('caption')}color:${r.muted};padding:12px 0 2px">${esc(p.title)}</div>${kids({ groundName: 'reading' })}</div>`;
    },
  });

  E({
    type: 'todayDayRow', name: 'Your day row', group: 'Today', source: CARDS + ' (YourDayList.line)',
    description: 'A 22 pt dot (green with a cream tick when done), the label, the meta and, when it opens something, a chevron. 48 pt tall, a hairline above every row but the first.',
    props: {
      label: { label: 'Label', kind: 'text', default: 'Morning pledge' },
      meta: { label: 'Meta', kind: 'text', default: '10 sec' },
      done: { label: 'State', kind: 'select', default: false, options: [[false, 'Not done'], [true, 'Done']] },
      chevron: { label: 'Chevron (opens something)', kind: 'bool', labels: ['Show', 'Hide'], default: false },
      divider: { label: 'Hairline above', kind: 'bool', labels: ['Show', 'Hide'], default: true },
    },
    examples: [{ label: 'Done', ground: 'reading', props: { done: true, meta: 'done', divider: false } }, { label: 'Opens the pledge', ground: 'reading', props: { chevron: true, divider: false } }],
    render(p, ctx) {
      const r = R(ctx);
      const dot = `<div style="width:22px;height:22px;border-radius:50%;flex:none;display:flex;align-items:center;justify-content:center;background:${p.done ? green(ctx) : inkA(ctx, 0.16)}">${p.done ? Lab.icon('checkmark', 13, CREAM) : ''}</div>`;
      return `<div style="display:flex;align-items:center;gap:10px;min-height:48px;${p.divider ? `border-top:1px solid ${inkA(ctx, 0.1)};` : ''}">${dot}
        <div style="${F('body')}color:${r.ink};flex:1;min-width:0">${esc(p.label)}</div>
        <div style="${F('footnote')}color:${r.muted}">${esc(p.meta)}</div>${p.chevron ? Lab.icon('chevron.right', 14, r.muted) : ''}</div>`;
    },
  });

  /* ---------- SOS tip (Quit Day only) ---------- */
  E({
    type: 'todaySosHint', name: 'SOS tip', group: 'Today', source: HOME + ' (sosHint)',
    description: 'Shown on Quit Day until dismissed: the SOS symbol, a 14 pt line and a close mark, on a raised card with a dashed outline.',
    props: { text: { label: 'Words', kind: 'text', default: 'Craving? Tap SOS any time. It takes 3 minutes.' } },
    examples: [{ label: 'Quit Day', ground: 'reading', props: {} }],
    render(p, ctx) {
      const r = R(ctx);
      return `<div role="button" style="position:relative;display:flex;align-items:center;gap:8px;padding:12px;border-radius:18px;background:${raised(ctx)}">
        <svg aria-hidden="true" style="position:absolute;inset:0;width:100%;height:100%;overflow:visible;pointer-events:none"><rect x=".5" y=".5" rx="17.5" style="width:calc(100% - 1px);height:calc(100% - 1px)" fill="none" stroke="${inkA(ctx, 0.38)}" stroke-width="1" stroke-dasharray="4 4"/></svg>
        ${symbol('sos.circle', 20, green(ctx))}
        <div style="${F('footnote', { weight: 400 })}color:${r.muted};flex:1;min-width:0">${esc(p.text)}</div>${Lab.icon('xmark', 12, r.muted)}</div>`;
    },
  });

  /* ---------- Quick log cards (productCard) ---------- */
  E({
    type: 'todayLogCard', name: 'Quick log card', group: 'Today', source: HOME + ' (productCard)',
    description: 'One per product, two to a row. Prep: uses logged today with a one-tap log (vapes add "+ Urge"). From Quit Day: what has not been used since, and "+ Log craving or slip".',
    props: {
      icon: { label: 'Icon', kind: 'select', default: 'smoke', options: [['smoke', 'Smoke (cigarettes)'], ['wind', 'Wind (vape)'], ['pouch', 'Two circles (pouches)']] },
      title: { label: 'Title', kind: 'text', default: 'Not smoked' },
      count: { label: 'Number', kind: 'text', default: '26' },
      unit: { label: 'After the number', kind: 'text', default: 'since Quit Day' },
      button: { label: 'Button', kind: 'text', default: '+ Log craving or slip' },
      urge: { label: 'Second button', kind: 'text', default: '+ Urge' },
      showUrge: { label: 'Second button (vape, prep)', kind: 'bool', labels: ['Show', 'Hide'], default: false },
    },
    examples: [{ label: 'Cigarettes, Day 3', ground: 'reading', props: {} }, { label: 'Vape, prep', ground: 'reading', props: { icon: 'wind', title: 'Puffs and urges', count: '0', unit: 'logged', button: '+1 Puff', showUrge: true } }],
    render(p, ctx) {
      const r = R(ctx);
      const pill = (s, accent) => `<div role="button" style="flex:1 1 0;min-width:0;min-height:44px;display:flex;align-items:center;justify-content:center;border-radius:999px;${F('footnote', { weight: 700 })}white-space:nowrap;overflow:hidden;background:${accent ? r.ink : surface(ctx)};color:${accent ? r.bg : r.ink}">${esc(s)}</div>`;
      return `<div style="flex:1 1 0;min-width:0;display:flex;flex-direction:column;gap:10px;padding:14px;border-radius:18px;background:${raised(ctx)}">
        <div style="display:flex;align-items:center;gap:8px"><div style="width:30px;height:30px;border-radius:50%;background:${surface(ctx)};display:flex;align-items:center;justify-content:center;flex:none">${symbol(p.icon, 16, r.ink)}</div>
          <div style="${F('footnote', { weight: 600 })}color:${r.muted};display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden">${esc(p.title)}</div></div>
        <div style="display:flex;align-items:baseline;gap:6px">${T('title', p.count, ctx.with({ groundName: 'reading' }), { style: 'font-variant-numeric:tabular-nums' })}${T('caption', p.unit, ctx.with({ groundName: 'reading' }), { tone: 'muted', upper: false })}</div>
        <div style="flex:1"></div>
        <div style="display:flex;gap:6px">${pill(p.button, false)}${p.showUrge ? pill(p.urge, true) : ''}</div></div>`;
    },
  });

  /* ---------- Streak card (streakCard) ---------- */
  E({
    type: 'todayStreak', name: 'Streak card', group: 'Today', source: HOME + ' (streakCard)',
    description: 'Prep: lessons done in a row, the Quit Day countdown and a segment per prep day (done full, today half). From Quit Day: days clear and a bar to the next milestone.',
    props: {
      left: { label: 'Left words (capitals)', kind: 'text', default: 'Smoke-free · 3 days' },
      right: { label: 'Right words', kind: 'text', default: 'Next milestone · 7 days' },
      mode: { label: 'Track', kind: 'select', default: 'bar', options: [['bar', 'One bar'], ['segments', 'A segment per prep day']] },
      value: { label: 'Bar filled', kind: 'number', options: [0, 0.1, 0.25, 0.5, 0.75, 1], default: 0 },
      segments: { label: 'Segments', kind: 'number', options: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], default: 7 },
      done: { label: 'Segments done', kind: 'number', options: [0, 1, 2, 3, 4, 5, 6, 7], default: 0 },
      half: { label: "Today's segment half filled", kind: 'bool', labels: ['Yes', 'No'], default: false },
    },
    examples: [{ label: 'Day 3', ground: 'reading', props: {} }, { label: 'Prep', ground: 'reading', props: { left: 'Prep streak · 3 / 7', right: 'Quit Day Fri 6 Nov · 4 days', mode: 'segments', done: 3, half: true } }],
    render(p, ctx) {
      const r = R(ctx);
      const track = inkA(ctx, 0.12), g = green(ctx);
      let bar;
      if (p.mode === 'segments') {
        const n = Math.max(+p.segments || 1, 1);
        bar = `<div style="display:flex;gap:6px">${Array.from({ length: n }, (_, i) => {
          const full = i < +p.done, half = p.half && i === +p.done;
          return `<div style="flex:1 1 0;height:8px;border-radius:999px;position:relative;overflow:hidden;background:${full ? g : track}">${half ? `<div style="position:absolute;left:0;top:0;bottom:0;width:50%;border-radius:999px;background:${g};opacity:.6"></div>` : ''}</div>`;
        }).join('')}</div>`;
      } else {
        bar = `<div style="height:8px;border-radius:999px;background:${track};overflow:hidden"><div style="height:100%;width:${Math.min(1, Math.max(0, +p.value)) * 100}%;border-radius:999px;background:${g}"></div></div>`;
      }
      return `<div style="display:flex;flex-direction:column;gap:12px;padding:14px 16px;border-radius:18px;background:${raised(ctx)}">
        <div style="display:flex;align-items:baseline;gap:8px"><div style="${F('caption')}color:${r.ink};text-transform:uppercase">${esc(p.left)}</div><div style="flex:1;min-width:8px"></div><div style="${F('caption')}color:${r.muted};text-align:right">${esc(p.right)}</div></div>
        ${bar}</div>`;
    },
  });

  /* ---------- NRT invitation (NRTInviteRow) ---------- */
  E({
    type: 'todayInviteRow', name: 'NRT invitation row', group: 'Today', source: 'DayXero/NRT/NRTCards.swift (NRTInviteRow)',
    description: 'A 40 pt symbol circle, a 16 pt bold title and a 14 pt line, with a chevron, on a raised card. Shown until an NRT plan is set up.',
    props: {
      title: { label: 'Title', kind: 'text', default: 'Set up your NRT' },
      detail: { label: 'Line', kind: 'text', default: 'Reminders for patches and step-downs' },
      icon: { label: 'Icon', kind: 'select', default: 'bandage', options: [['bandage', 'Bandage (NRT)'], ['chart.line.downtrend', 'Downward chart (pouches)'], ['calendar', 'Calendar'], ['clock', 'Clock']] },
    },
    examples: [{ label: 'NRT', ground: 'reading', props: {} }],
    render(p, ctx) {
      const r = R(ctx);
      const icon = p.icon === 'chart.line.downtrend'
        ? `<svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true"><path d="M4 6l6 6 4-3 6 7M15 16h5v-5" fill="none" stroke="${r.ink}" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>`
        : symbol(p.icon, 18, r.ink);
      return `<div role="button" style="display:flex;align-items:center;gap:12px;padding:14px;border-radius:18px;background:${raised(ctx)}">
        <div style="width:40px;height:40px;border-radius:50%;background:${surface(ctx)};display:flex;align-items:center;justify-content:center;flex:none">${icon}</div>
        <div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:2px"><div style="${F('body', { size: 16, weight: 700, family: 'body' })}color:${r.ink}">${esc(p.title)}</div><div style="${F('footnote')}color:${r.muted}">${esc(p.detail)}</div></div>
        ${Lab.icon('chevron.right', 16, r.muted)}</div>`;
    },
  });

  /* ---------- Next change in the body (milestoneRow) ---------- */
  const HEALTH_IDS = ['heart-rate', 'carbon-monoxide', 'taste', 'fresh-breath', 'skin-glow', 'lips', 'circulation', 'hair', 'even-tone', 'coughing', 'heart-attack', 'mouth-cancer', 'lung-cancer', 'heart-disease'];
  E({
    type: 'todayHealthRow', name: 'Body change row', group: 'Today', source: HOME + ' (milestoneRow)',
    description: "What's changing in the body now, or the first change before Quit Day: the 44 pt health badge (with its progress ring once under way), a 16 pt bold title, a 14 pt line and a chevron in a 32 pt circle. Opens the health timeline.",
    props: {
      badge: { label: 'Badge drawing', kind: 'select', default: 'taste', options: HEALTH_IDS.map((x) => [x, x]) },
      ring: { label: 'Progress ring (under way)', kind: 'bool', labels: ['Show', 'Hide'], default: true },
      progress: { label: 'Ring filled', kind: 'number', options: [0, 0.13, 0.25, 0.5, 0.75], default: 0.13 },
      title: { label: 'Title', kind: 'text', default: 'Food starts tasting like food again' },
      line: { label: 'Line', kind: 'text', default: 'Next milestone: Fresher breath, brighter smile (in 5 days)' },
    },
    examples: [{ label: 'Day 3', ground: 'reading', props: {} }],
    render(p, ctx) {
      const r = R(ctx);
      const badge = Lab.art('extra:healthBadge', { width: 44, height: 44, radius: 22, scene: { id: p.badge, state: 'underWay', progress: +p.progress, showsRing: !!p.ring, dark: ctx.dark } });
      return `<div role="button" style="display:flex;align-items:center;gap:12px;padding:14px;border-radius:18px;background:${raised(ctx)}">
        <div style="flex:none;line-height:0;padding:${p.ring ? 4 : 0}px">${badge}</div>
        <div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:2px"><div style="${F('body', { size: 16, weight: 700, family: 'body' })}color:${r.ink}">${esc(p.title)}</div><div style="${F('footnote')}color:${r.muted}">${esc(p.line)}</div></div>
        <div style="width:32px;height:32px;border-radius:50%;background:${surface(ctx)};display:flex;align-items:center;justify-content:center;flex:none">${Lab.icon('chevron.right', 14, r.ink)}</div></div>`;
    },
  });

  /* ---------- Sam's three days (design/handoff/tokens.json → persona, codeTrue) ---------- */
  const WAVE_KICKERS = ['Your stress wave', 'Your after-meal wave', 'Your morning wave', 'Your drinking wave', 'Your boredom wave', 'Your work-break wave', 'Your driving wave', 'Your phone wave', 'Your social wave', 'Your usual wave'];
  const CHECKIN_META = ['9:00 PM', 'Tonight', 'done'];
  const DAYS = {
    prep: {
      date: 'Mon 2 Nov · Prep day 4 of 7', clarity: 20, stage: 1,
      tiles: [['0', 'of 7 prep done', ['3']], ['4', 'days to Quit Day'], ['$2,555', 'to keep a year']],  // [value, label, value alts, label alts]
      wave: null,
      lesson: { kicker: 'Today · Prep 4 · 6 min', title: 'The stress loop', mission: 'Do one session today with no phone and full attention, then log what you noticed.' },
      pledge: { meta: '10 sec', done: false },
      sos: false,
      log: [
        { id: 'log-cigarettes', icon: 'smoke', title: 'Cigarettes today', count: '0', unit: 'logged', button: '+ Log cigarette', alts: { title: ['Not smoked'], unit: ['since Quit Day'], button: ['+ Log craving or slip'] } },
        { id: 'log-vape', icon: 'wind', title: 'Puffs and urges', count: '0', unit: 'logged', button: '+1 Puff', showUrge: true, alts: { title: ['Puffs not taken'], unit: ['since Quit Day'], button: ['+ Log craving or slip'] } },
      ],
      streak: { left: 'Prep streak · 0 / 7', right: 'Quit Day Fri 6 Nov · 4 days', mode: 'segments', done: 0, half: false, alts: { left: ['Prep streak · 3 / 7'] } },
      health: { badge: 'heart-rate', ring: false, progress: 0, title: 'Heart rate and blood pressure start to come down', line: 'Starts on Quit Day · Within minutes' },
    },
    quitday: {
      date: 'Fri 6 Nov · Quit Day', clarity: 23, stage: 1,
      tiles: [['1', 'day clear', [], ['days clear']], ['2', 'not smoked', [], ['puffs not taken', 'pouches not used']], ['$1.65', 'kept']],
      wave: null,
      lesson: { kicker: 'Today · Day Xero · 5 min', title: 'Day Xero', mission: 'Make your last use a conscious one, then clear everything out.' },
      pledge: { meta: '10 sec', done: false },
      sos: true,
      log: [
        { id: 'log-cigarettes', icon: 'smoke', title: 'Not smoked', count: '2', unit: 'since Quit Day', button: '+ Log craving or slip', alts: { title: ['Cigarettes today'], unit: ['logged'], button: ['+ Log cigarette'] } },
        { id: 'log-vape', icon: 'wind', title: 'Puffs not taken', count: '40', unit: 'since Quit Day', button: '+ Log craving or slip', alts: { title: ['Puffs and urges'], unit: ['logged'], button: ['+1 Puff'] } },
      ],
      streak: { left: 'Smoke-free · 1 day', right: 'Next milestone · 3 days', mode: 'bar', value: 0 },
      health: { badge: 'carbon-monoxide', ring: false, progress: 0, title: 'Carbon monoxide in your blood drops to normal', line: 'Next milestone: Carbon monoxide in your blood drops to normal (in 3h)' },
    },
    day3: {
      date: 'Sun 8 Nov · Day 3', clarity: 28, stage: 1,
      tiles: [['3', 'days clear', [], ['day clear']], ['26', 'not smoked', [], ['puffs not taken', 'pouches not used']], ['$15.65', 'kept']],
      wave: { kicker: 'Your coffee wave', title: 'Usually comes around 09:40', detail: 'Jelli is ready if the wave comes.' },
      lesson: { kicker: 'Today · Day 2 · 3 min', title: 'The noisy passengers', mission: 'Three proper meals, water close by, and tap “It passed” after every craving you ride.', unlock: 'Unlock Day 2' },
      pledge: { meta: 'done', done: true },
      sos: false,
      log: [
        { id: 'log-cigarettes', icon: 'smoke', title: 'Not smoked', count: '26', unit: 'since Quit Day', button: '+ Log craving or slip', alts: { title: ['Cigarettes today'], unit: ['logged'], button: ['+ Log cigarette'] } },
        { id: 'log-vape', icon: 'wind', title: 'Puffs not taken', count: '383', unit: 'since Quit Day', button: '+ Log craving or slip', alts: { title: ['Puffs and urges'], unit: ['logged'], button: ['+1 Puff'] } },
      ],
      streak: { left: 'Smoke-free · 3 days', right: 'Next milestone · 7 days', mode: 'bar', value: 0 },
      health: { badge: 'taste', ring: true, progress: 0.13, title: 'Food starts tasting like food again', line: 'Next milestone: Fresher breath, brighter smile (in 5 days)' },
    },
  };

  Lab.screen({
    id: 'today',
    name: 'Today',
    area: 'Today',
    source: HOME,
    ground: 'reading',
    tab: 'today',
    note: "Sam at 09:40 (morning: apricot, dawn sky, Xero). Day 3 and Quit Day numbers are codeTrue (26 / $15.65; 2 / $1.65). " +
      "\"Of 7 prep done\" and the prep streak read the old program's completions, which Program v2 sessions don't write, so the app shows 0 even after Prep 1–3 (3 is in the dropdown). " +
      "Assumed: Sam is on the trial from Quit Day (no Unlock line); prep and Quit Day have no logged wave yet, so the top card is the lesson card alone; " +
      "the pledge is done on Day 3 only; vape baseline is onboarding's default (2 pods a week × 600 puffs); prep use counts are 0 (not known); " +
      "the NRT invitation shows because onboarding's Sam sample says he uses NRT and has no plan yet; times use the en-GB clock (09:40, 21:00).",
    states: [
      { id: 'prep', label: 'Prep · Mon 2 Nov' },
      { id: 'quitday', label: 'Quit Day · Fri 6 Nov' },
      { id: 'day3', label: 'Day 3 · Sun 8 Nov, 09:40' },
    ],
    build(h, state) {
      const d = DAYS[state.id] || DAYS.day3;

      const header = h('todayHeader', 'header', { ground: 'apricot' }, [
        h('todaySky', 'sky', { scene: 'dawn', clarity: d.clarity, character: 'xero:hello', stage: d.stage, initial: 'S' }),
        h('stack', 'header-words', { gap: 4, padX: 18, padTop: 4 }, [
          h('text', 'date', { step: 'caption', tone: 'muted', text: d.date }),
          h('stack', 'greeting-pad', { style: 'padding-left:6px' }, [
            h('markedTitle', 'greeting', {
              lead: 'Morning, ', word: 'Sam', trail: '.', mark: 'circle', step: 'large',
              alts: { lead: ['Afternoon, ', 'Evening, ', 'Still up, '], trail: ['?'] },
            }),
          ]),
        ]),
        h('row', 'tiles', { gap: 8, padX: 12, style: 'padding:12px 12px 14px' }, d.tiles.map((t, i) => h('todayStat', 'tile-' + (i + 1), {
          value: t[0], label: t[1],
          alts: Object.assign({}, t[2] && t[2].length ? { value: t[2] } : {}, t[3] ? { label: t[3] } : {}),
        }))),
      ]);

      const top = d.wave && h('todayColourCard', 'top-card', {
        kicker: d.wave.kicker, title: d.wave.title, detail: d.wave.detail, fill: '#2A52DB',
        alts: {
          kicker: WAVE_KICKERS.concat(['With Glim · 1 min', 'Wind down']),
          title: ['Usually comes around 9:40 AM', 'How was today, really?', "Can't sleep? Breathe with Glim"],
          detail: ['One question, then rest.', 'A slow breath, then rest.'],
        },
      });

      const lessonDetailAlts = ['Xero saved your place.', "Finish prep when you're ready. Day Xero starts the morning after."];
      if (d.lesson.unlock) lessonDetailAlts.unshift(d.lesson.unlock);
      const lesson = h('todayColourCard', 'lesson-card', {
        kicker: d.lesson.kicker, title: d.lesson.title, detail: '', fill: '#0F6E43',
        alts: {
          kicker: ["Today's mission", 'Up next', 'Program complete'],
          title: [d.lesson.mission, 'Next session tomorrow', 'Replay any session.'],
          detail: lessonDetailAlts.concat(['Next session tomorrow']),
        },
      });

      const yourDay = h('todayYourDay', 'your-day', {}, [
        h('todayDayRow', 'day-pledge', { label: 'Morning pledge', meta: d.pledge.meta, done: d.pledge.done, chevron: !d.pledge.done, divider: false, alts: { meta: d.pledge.done ? ['10 sec'] : ['done'] } }),
        h('todayDayRow', 'day-lesson', { label: d.lesson.title, meta: d.lesson.kicker.split(' · ').pop(), done: false, chevron: false, alts: { label: ["Today's session"], meta: ['done'] } }),
        h('todayDayRow', 'day-checkin', { label: 'Evening check-in', meta: '21:00', done: false, chevron: false, alts: { meta: CHECKIN_META } }),
      ]);

      const sos = d.sos && h('todaySosHint', 'sos-hint', {});

      const log = h('row', 'log-grid', { gap: 12, align: 'stretch' }, d.log.map((c) => h('todayLogCard', c.id, {
        icon: c.icon, title: c.title, count: c.count, unit: c.unit, button: c.button, showUrge: !!c.showUrge, alts: c.alts,
      })));

      const streak = h('todayStreak', 'streak', Object.assign({}, d.streak, { segments: 7 }));

      const nrt = h('todayInviteRow', 'nrt-invite', {
        title: 'Set up your NRT', detail: 'Reminders for patches and step-downs', icon: 'bandage',
        alts: { title: ['Step down your pouches'], detail: ['Optional, before Quit Day'] },
      });

      const health = h('todayHealthRow', 'body-change', Object.assign({}, d.health, {
        alts: { line: ['Every change on the timeline is under way'], title: ['Your body is recovering'] },
      }));

      // TodayView.column: 16 pt sides, 12 pt top, 20 pt bottom, 16 pt between sections (overview, then actions).
      return h('stack', 'column', { gap: 16, padX: 16, padTop: 12, padBottom: 20 }, [
        header, top, lesson, yourDay, sos, log, streak, nrt, health,
      ]);
    },
  });
})();
