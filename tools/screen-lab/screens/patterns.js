/* Screen Lab — Your progress, with the "Your patterns" panel (DayXero/Progress/ProgressTab.swift). See ../FORMAT.md. */
(function () {
  'use strict';
  const Lab = window.Lab;
  const E = Lab.element, esc = Lab.esc, T = Lab.text, F = Lab.font;
  const SRC = 'DayXero/Progress/ProgressTab.swift';
  const MILESTONE_SRC = 'DayXero/Milestones/MilestoneViews.swift (MilestonesRow)';

  /* Read4 (DayXero/Shared/V4Reading.swift): the reading-tier colours every card here uses. */
  const R4 = {
    hairline: (d) => (d ? 'rgba(255,255,255,0.14)' : 'rgba(30,26,58,0.12)'),
    track: (d) => (d ? 'rgba(255,255,255,0.16)' : 'rgba(30,26,58,0.12)'),
    faint: (d) => (d ? 'rgba(255,248,238,0.38)' : 'rgba(30,26,58,0.38)'),
    accent: (d) => Lab.c(Lab.fill.green, d),
    card: (d) => Lab.c(Lab.fill.raised, d),
    surface: (d) => Lab.c(Lab.fill.surface, d),
  };
  const reading = (ctx) => ctx.with({ groundName: 'reading' });
  /** ProgressTab.patternCard: Color(light: 0xFFF8EE, dark: 0x14265E). */
  const PATTERN_CARD = (d) => (d ? '#14265E' : '#FFF8EE');

  /* HeatMap.cravingScale / HeatMap.useScale: five steps, none to most (decision 31). */
  const SCALES = {
    cravings: [['#ECE6F7', '#1B2C66'], '#B9C6FF', '#7F9CF5', '#2A52DB', ['#1E1A3A', '#E3EAFF']],
    uses: [['#F6EBD9', '#3A2A10'], '#F2C98A', '#E5A93C', '#B07A1C', ['#5A3A10', '#FFE8C2']],
  };
  const TIMES = ['Morning', 'Midday', 'Afternoon', 'Evening', 'Late night'];
  const WEEKDAY_LETTERS = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  /** ProgressTab.sampleGrid: a made-up shape for the blurred placeholder only; never shown as data. */
  const SAMPLE_GRID = [[3, 4, 3, 4, 3, 1, 1], [1, 2, 1, 1, 2, 2, 1], [2, 3, 2, 2, 1, 1, 0], [1, 1, 2, 1, 3, 4, 3], [0, 0, 1, 0, 1, 2, 1]];
  const PEAK_NAMES = [
    'Weekday mornings', 'Weekday middays', 'Weekday afternoons', 'Weekday evenings', 'Weekday late nights',
    'Weekend mornings', 'Weekend middays', 'Weekend afternoons', 'Weekend evenings', 'Weekend late nights',
  ];
  const TRIGGER_TITLES = ['Coffee', 'Stress', 'Waking up', 'After meals', 'Drinking', 'Boredom', 'With friends', 'Driving', 'Work breaks', 'On my phone', 'Something else'];

  /** Insights.peaks: the two busiest stretches; weekend cells count per day. Returns [{weekend, row}]. */
  function peaks(grid) {
    const scores = [];
    grid.forEach((r, row) => {
      const wd = r.slice(0, 5).reduce((a, b) => a + b, 0), we = r.slice(5).reduce((a, b) => a + b, 0);
      if (wd > 0) scores.push({ weekend: false, row, s: wd / 5 });
      if (we > 0) scores.push({ weekend: true, row, s: we / 2 });
    });
    return scores.sort((a, b) => b.s - a.s).slice(0, 2);
  }
  const peakName = (p) => PEAK_NAMES[(p.weekend ? 5 : 0) + p.row];

  /* ---------- Gained (S7.4) ---------- */

  E({
    type: 'progressLogButton', name: 'Log button', group: 'Progress', source: SRC + ' (LogButton)',
    description: 'The "Log" pill beside the title: plus icon, 14 pt semibold, raised fill with a hairline, 36 pt tall.',
    props: {
      label: { label: 'Words', kind: 'text', default: 'Log' },
      icon: { label: 'Icon', kind: 'icon', default: 'plus' },
      height: { label: 'Height', kind: 'number', options: [32, 36, 40, 44], unit: ' pt', default: 36 },
      outline: { label: 'Hairline', kind: 'bool', labels: ['Show', 'Hide'], default: true },
    },
    examples: [{ label: 'On reading', props: {} }],
    render(p, ctx) {
      const d = ctx.dark;
      return `<div role="button" style="flex:none;display:flex;align-items:center;gap:6px;padding:0 14px;min-height:${p.height}px;border-radius:999px;background:${R4.card(d)};${p.outline ? `box-shadow:inset 0 0 0 1px ${R4.hairline(d)};` : ''}${F('footnote', { size: 14, weight: 600 })}color:${ctx.g.ink}">${p.icon ? Lab.icon(p.icon, 14, ctx.g.ink) : ''}<span>${esc(p.label)}</span></div>`;
    },
  });

  E({
    type: 'progressSkyStrip', name: 'Sky strip', group: 'Progress', source: SRC + ' (skyStrip)',
    description: 'The path horizon at the sky\'s clarity, 130 pt tall, with the "Sky 28% clear" pill in the bottom-left corner.',
    props: {
      pill: { label: 'Pill words', kind: 'text', default: 'Sky 28% clear · clears a little each day' },
      clarity: { label: 'Sky clarity', kind: 'number', options: [0, 20, 23, 26, 28, 40, 60, 80, 98, 100], unit: '%', default: 28 },
      height: { label: 'Height', kind: 'number', options: [100, 110, 120, 130, 140, 160, 180], unit: ' pt', default: 130 },
      radius: { label: 'Corner radius', kind: 'number', options: [18, 24, 28, 36], unit: ' pt', default: 24 },
      pillShow: { label: 'Pill', kind: 'bool', labels: ['Show', 'Hide'], default: true },
    },
    examples: [{ label: 'Day 3', props: {} }],
    render(p, ctx) {
      const w = Math.max(200, (ctx.width || 402) - 40);
      const art = Lab.art('scene:horizon', { width: w, height: p.height, radius: 0, scene: { kind: 'path', clarity: p.clarity, fit: 'bottom' } });
      const pill = p.pillShow ? `<div style="position:absolute;left:12px;bottom:12px;padding:6px 12px;border-radius:999px;background:rgba(255,248,238,0.92);${F('caption')}color:${Lab.NAVY}">${esc(p.pill)}</div>` : '';
      return `<div style="position:relative;height:${p.height}px;border-radius:${p.radius}px;overflow:hidden;line-height:0"><div style="position:absolute;inset:0;line-height:0">${art}</div>${pill}</div>`;
    },
  });

  E({
    type: 'progressStatGrid', name: 'Stat grid', group: 'Progress', source: SRC + ' (tiles)',
    description: 'The grid the progress stats sit in: two columns 8 pt apart (one column at accessibility text sizes).',
    props: {
      columns: { label: 'Columns', kind: 'select', default: 2, options: [[2, 'Two'], [1, 'One (accessibility sizes)']] },
      gap: { label: 'Gap', kind: 'number', options: [6, 8, 10, 12, 16], unit: ' pt', default: 8 },
    },
    render(p, ctx, kids) {
      return `<div style="display:grid;grid-template-columns:repeat(${p.columns},minmax(0,1fr));gap:${p.gap}px">${kids()}</div>`;
    },
  });

  E({
    type: 'progressStat', name: 'Progress stat', group: 'Progress', source: SRC + ' (ProgressStat)',
    description: 'A counting stat on the reading ground (F12): 24 pt number over a 12 pt label, raised card, padding 14, radius 18.',
    props: {
      value: { label: 'Number', kind: 'text', default: '3' },
      label: { label: 'Label', kind: 'text', default: 'days clear' },
      padding: { label: 'Padding', kind: 'number', options: [12, 14, 16, 18], unit: ' pt', default: 14 },
      radius: { label: 'Corner radius', kind: 'number', options: [14, 18, 20, 24], unit: ' pt', default: 18 },
      fill: { label: 'Fill', kind: 'select', default: 'raised', options: [['raised', 'Raised (white)'], ['surface', 'Reading surface']] },
    },
    examples: [{ label: 'Day 3', props: { value: '26', label: 'cigarettes not smoked' } }],
    render(p, ctx) {
      const bg = p.fill === 'surface' ? R4.surface(ctx.dark) : R4.card(ctx.dark);
      return `<div style="min-width:0;min-height:64px;box-sizing:border-box;display:flex;flex-direction:column;align-items:flex-start;gap:2px;padding:${p.padding}px;border-radius:${p.radius}px;background:${bg}">${T('title', p.value, ctx, { style: 'font-variant-numeric:tabular-nums;white-space:nowrap' })}${T('caption', p.label, ctx, { tone: 'muted', upper: false })}</div>`;
    },
  });

  E({
    type: 'progressMilestones', name: 'Milestones row', group: 'Progress', source: MILESTONE_SRC,
    description: 'Quit Day and the ten milestone days as circles, four to a row: green when reached, an ink ring on the next one ("in 4 days"), dashed when ahead.',
    props: {
      daysClear: { label: 'Days clear', kind: 'number', options: [1, 2, 3, 7, 14, 28, 30, 60], default: 3 },
      title: { label: 'Heading', kind: 'text', default: 'Milestones' },
      columns: { label: 'Per row', kind: 'number', options: [3, 4, 5, 6], default: 4 },
      gap: { label: 'Gap', kind: 'number', options: [4, 6, 8, 10, 12], unit: ' pt', default: 8 },
    },
    examples: [{ label: 'Day 3', props: {} }],
    render(p, ctx) {
      const d = ctx.dark, dc = +p.daysClear;
      const all = [{ q: true, day: 1 }].concat([1, 3, 7, 14, 30, 60, 90, 100, 180, 365].map((n) => ({ n, day: n === 1 ? 2 : n })));
      const reached = all.filter((m) => dc >= m.day);
      const next = all.find((m) => dc < m.day);
      const badge = (m) => {
        const isR = dc >= m.day, isN = m === next;
        const top = m.q ? 'QD' : m.n === 365 ? '1y' : String(m.n);
        const bottom = isN ? `in ${m.day - dc} days` : m.q ? 'Quit Day' : m.n === 1 ? 'day' : m.n === 365 ? 'year' : 'days';
        const color = isR ? Lab.CREAM : isN ? ctx.g.ink : ctx.g.muted;
        const ring = isN ? `box-shadow:inset 0 0 0 2px ${ctx.g.ink};` : !isR ? `border:1px dashed ${R4.faint(d)};` : '';
        return `<div style="aspect-ratio:1;box-sizing:border-box;border-radius:50%;display:flex;flex-direction:column;align-items:center;justify-content:center;${isR ? `background:${R4.accent(d)};` : ''}${ring}">${T('headline', top, ctx, { color })}${T('caption', bottom, ctx, { color, upper: false, style: 'white-space:nowrap' })}</div>`;
      };
      return `<div style="display:flex;flex-direction:column;gap:8px;padding-top:12px">
        <div style="display:flex;align-items:baseline;justify-content:space-between">${T('caption', p.title, ctx, { tone: 'muted' })}${T('footnote', `${reached.length} of ${all.length}`, ctx, { tone: 'muted' })}</div>
        <div style="display:grid;grid-template-columns:repeat(${p.columns},minmax(0,1fr));gap:${p.gap}px">${all.map(badge).join('')}</div></div>`;
    },
  });

  E({
    type: 'progressLink', name: 'Text link with chevron', group: 'Progress', source: SRC + ' (See the whole timeline)',
    description: 'A plain button: 14 pt bold words, then a 12 pt chevron, 44 pt tall.',
    props: { label: { label: 'Words', kind: 'text', default: 'See the whole timeline' }, icon: { label: 'Icon', kind: 'icon', default: 'chevron.right' } },
    render(p, ctx) {
      return `<div role="button" style="align-self:flex-start;display:flex;align-items:center;gap:6px;min-height:44px;${F('footnote', { size: 14, weight: 700 })}color:${ctx.g.ink}"><span>${esc(p.label)}</span>${p.icon ? Lab.icon(p.icon, 12, ctx.g.ink) : ''}</div>`;
    },
  });

  /* ---------- Your patterns (S7.3, decision 31) ---------- */

  E({
    type: 'patternsPanel', name: 'Pattern card', group: 'Progress', source: SRC + ' (patternPanel)',
    description: 'A cream card inside the mist "Your patterns" panel: padding 14, radius 24, navy #14265E in dark mode. What sits in it uses the reading colours.',
    props: {
      gap: { label: 'Gap between items', kind: 'number', options: [4, 6, 8, 10, 12, 14, 16], unit: ' pt', default: 12 },
      padding: { label: 'Padding', kind: 'number', options: [12, 14, 16, 18, 20], unit: ' pt', default: 14, global: true },
      radius: { label: 'Corner radius', kind: 'number', options: [18, 20, 24, 28], unit: ' pt', default: 24, global: true },
      fill: { label: 'Fill', kind: 'select', default: 'cream', global: true, options: [['cream', 'Cream (as in the app)'], ['raised', 'Raised (white)'], ['onColour', 'Card on colour']] },
    },
    examples: [{ label: 'On mist', ground: 'mist', props: {}, kids: [['text', { step: 'headline', text: 'Top triggers' }]] }],
    render(p, ctx, kids) {
      const bg = p.fill === 'raised' ? R4.card(ctx.dark) : p.fill === 'onColour' ? ctx.g.card : PATTERN_CARD(ctx.dark);
      const c = reading(ctx);
      return `<div style="display:flex;flex-direction:column;gap:${p.gap}px;padding:${p.padding}px;border-radius:${p.radius}px;background:${bg};color:${c.g.ink}">${kids({ groundName: 'reading' })}</div>`;
    },
  });

  E({
    type: 'patternsSeriesToggle', name: 'Cravings / Uses switch', group: 'Progress', source: SRC + ' (SeriesToggle)',
    description: 'Two 12 pt options in a surface capsule; the picked one is an ink capsule.',
    props: {
      selected: { label: 'Picked', kind: 'select', default: 'cravings', options: [['cravings', 'Cravings'], ['uses', 'Uses']] },
      first: { label: 'First option', kind: 'text', default: 'Cravings' },
      second: { label: 'Second option', kind: 'text', default: 'Uses' },
    },
    examples: [{ label: 'Cravings picked', props: {} }],
    render(p, ctx) {
      const opt = (label, on) => `<span style="${F('caption', { size: 12, weight: 600 })}padding:5px 10px;border-radius:999px;${on ? `background:${ctx.g.ink};color:${ctx.g.bg}` : `color:${ctx.g.muted}`}">${esc(label)}</span>`;
      return `<div role="group" style="flex:none;display:flex;padding:3px;border-radius:999px;background:${R4.surface(ctx.dark)}">${opt(p.first, p.selected === 'cravings')}${opt(p.second, p.selected === 'uses')}</div>`;
    },
  });

  E({
    type: 'patternsSummary', name: 'Peak line', group: 'Progress', source: SRC + ' (summary)',
    description: 'The line under "When cravings hit": the busiest stretches in 14 pt semibold ink, the rest in footnote muted.',
    props: {
      peak: { label: 'Busiest stretch', kind: 'text', default: 'Weekday mornings' },
      rest: { label: 'Middle words', kind: 'text', default: ' are your toughest time, then ' },
      peak2: { label: 'Second stretch', kind: 'text', default: 'weekend mornings' },
      end: { label: 'End', kind: 'text', default: '.' },
    },
    examples: [{ label: 'Two peaks', props: {} }],
    render(p, ctx) {
      const b = (s) => (s ? `<span style="${F('footnote', { size: 14, weight: 600 })}color:${ctx.g.ink}">${esc(s)}</span>` : '');
      return `<div style="${F('footnote')}color:${ctx.g.muted}">${b(p.peak)}${esc(p.rest)}${b(p.peak2)}${esc(p.end)}</div>`;
    },
  });

  function heatMapHTML(p, ctx, grid) {
    const d = ctx.dark;
    const scale = (SCALES[p.series] || SCALES.cravings).map((c) => Lab.c(c, d));
    const most = Math.max(1, ...grid.flat());
    const marks = p.highlight === 'peaks' ? peaks(grid) : [];
    const marked = (row, col) => marks.some((m) => m.row === row && (m.weekend ? col >= 5 : col < 5));
    const ring = '#FF7A55';
    const head = `<div style="display:flex;gap:${p.gap}px;align-items:center"><div style="width:${p.labelWidth}px;flex:none"></div>${WEEKDAY_LETTERS.map((l) => `<div style="flex:1;min-width:0;text-align:center;${F('caption', { size: 12, weight: 400 })}color:${ctx.g.muted}">${l}</div>`).join('')}</div>`;
    const rows = TIMES.map((t, row) => {
      const cells = (grid[row] || []).map((v, col) => {
        const level = v === 0 ? 0 : Math.min(4, Math.max(1, Math.ceil((4 * v) / most)));
        return `<div title="${v}" style="flex:1;min-width:0;height:${p.cellHeight}px;border-radius:${p.cellRadius}px;background:${scale[level]};${marked(row, col) ? `box-shadow:inset 0 0 0 2px ${ring};` : ''}"></div>`;
      }).join('');
      return `<div style="display:flex;gap:${p.gap}px;align-items:center"><div style="width:${p.labelWidth}px;flex:none;white-space:nowrap;overflow:hidden;${F('caption', { size: 12, weight: 400 })}color:${ctx.g.muted}">${esc(t)}</div>${cells}</div>`;
    }).join('');
    return `<div style="display:flex;flex-direction:column;gap:${p.gap}px">${head}${rows}</div>`;
  }

  const HEAT_PROPS = {
    series: { label: 'Showing', kind: 'select', default: 'cravings', options: [['cravings', 'Cravings (ocean blues)'], ['uses', 'Uses and slips (amber)']] },
    highlight: { label: 'Mark the peaks', kind: 'select', default: 'none', options: [['none', 'No (as in the app)'], ['peaks', 'Ring the two busiest stretches']] },
    cellHeight: { label: 'Cell height', kind: 'number', options: [20, 22, 24, 26, 28, 32], unit: ' pt', default: 26, global: true },
    cellRadius: { label: 'Cell corner radius', kind: 'number', options: [4, 6, 8, 10, 13], unit: ' pt', default: 8, global: true },
    gap: { label: 'Gap between cells', kind: 'number', options: [2, 3, 4, 5, 6], unit: ' pt', default: 4, global: true },
    labelWidth: { label: 'Time label width', kind: 'number', options: [56, 64, 72, 80], unit: ' pt', default: 64, global: true },
  };

  E({
    type: 'patternsHeatMap', name: 'Heat map', group: 'Progress', source: SRC + ' (HeatMap)',
    description: 'Five times of day (rows) by weekday, Monday first. Five colour steps from none to most: ocean blues for cravings, amber for uses and slips.',
    props: HEAT_PROPS,
    examples: [{ label: 'Cravings', props: {} }, { label: 'Uses', props: { series: 'uses' } }],
    render(p, ctx) {
      const grid = (p.series === 'uses' ? p.gridUses : p.grid) || SAMPLE_GRID;
      return heatMapHTML(p, ctx, grid).replace('<div ', '<div role="img" aria-label="Heat map" ');
    },
  });

  E({
    type: 'patternsFirstLog', name: 'Blurred map, no logs yet', group: 'Progress', source: SRC + ' (earlyPatterns, no logs)',
    description: 'Before any log: the sample heat map blurred at 40% with one line over it in a surface capsule.',
    props: {
      text: { label: 'Words', kind: 'text', default: 'Your first log starts the map' },
      blur: { label: 'Blur', kind: 'number', options: [0, 2, 4, 6, 8], unit: ' pt', default: 4 },
      opacity: { label: 'Map strength', kind: 'number', options: [0.2, 0.3, 0.4, 0.6], default: 0.4 },
    },
    examples: [{ label: 'No logs yet', props: {} }],
    render(p, ctx) {
      const map = heatMapHTML(Object.assign({ series: 'cravings', highlight: 'none', cellHeight: 26, cellRadius: 8, gap: 4, labelWidth: 64 }), ctx, SAMPLE_GRID);
      return `<div style="position:relative;display:flex;align-items:center;justify-content:center"><div aria-hidden="true" style="width:100%;filter:blur(${p.blur}px);opacity:${p.opacity}">${map}</div><div style="position:absolute;padding:8px 14px;border-radius:999px;background:${R4.surface(ctx.dark)};${F('footnote', { size: 14, weight: 600 })}color:${ctx.g.ink}">${esc(p.text)}</div></div>`;
    },
  });

  E({
    type: 'patternsTriggers', name: 'Trigger bars', group: 'Progress', source: SRC + ' (triggersCard, CoralBar)',
    description: 'Top triggers, most first: the trigger (14 pt, 96 pt wide), a 12 pt coral bar against the most common one, and the count in 16 pt bold.',
    props: {
      first: { label: 'First trigger', kind: 'text', default: 'Coffee' },
      firstCount: { label: 'First count', kind: 'number', options: [1, 2, 3, 5, 8, 12, 16, 21, 30], default: 21 },
      second: { label: 'Second trigger', kind: 'text', default: 'Stress' },
      secondCount: { label: 'Second count', kind: 'number', options: [0, 1, 2, 3, 5, 8, 12, 16, 21], default: 12 },
      barColour: { label: 'Bar colour', kind: 'colour', default: '#FF7A55', global: true },
      barHeight: { label: 'Bar height', kind: 'number', options: [6, 8, 10, 12, 14, 16], unit: ' pt', default: 12, global: true },
      labelWidth: { label: 'Trigger width', kind: 'number', options: [72, 84, 96, 110], unit: ' pt', default: 96, global: true },
      gap: { label: 'Gap between rows', kind: 'number', options: [4, 6, 8, 10, 12], unit: ' pt', default: 8 },
    },
    examples: [{ label: 'Coffee and Stress', props: {} }],
    render(p, ctx) {
      const rows = [[p.first, +p.firstCount], [p.second, +p.secondCount]].filter((r) => r[0] && r[1] > 0);
      const most = Math.max(1, rows.length ? rows[0][1] : 1);
      const track = ctx.dark ? '#1B2C66' : '#EDE6DA';
      const row = ([name, n]) => `<div style="display:flex;align-items:center;gap:8px">
        <div style="width:${p.labelWidth}px;flex:none;${F('footnote', { size: 14, weight: 400 })}color:${ctx.g.ink}">${esc(name)}</div>
        <div style="flex:1;min-width:0;height:${p.barHeight}px;border-radius:999px;background:${track};overflow:hidden"><div style="height:100%;width:${Math.min(100, (n / most) * 100)}%;border-radius:999px;background:${Lab.colour(p.barColour, ctx)}"></div></div>
        <div style="min-width:24px;text-align:right;${F('body', { size: 16, weight: 700 })}font-variant-numeric:tabular-nums;color:${ctx.g.ink}">${n}</div></div>`;
      return `<div style="display:flex;flex-direction:column;gap:${p.gap}px">${rows.map(row).join('')}</div>`;
    },
  });

  E({
    type: 'patternsTimeRow', name: 'Time-of-day row', group: 'Progress', source: SRC + ' (earlyPatterns)',
    description: 'Early patterns, before a week of logs: the time of day (14 pt, 84 pt wide), an 8 pt green bar against the busiest time, and the count.',
    props: {
      label: { label: 'Time of day', kind: 'text', default: 'Morning' },
      count: { label: 'Count', kind: 'number', options: [0, 1, 2, 3, 4, 5, 6, 8, 9, 12], default: 3 },
      most: { label: 'Busiest count (bar full)', kind: 'number', options: [1, 2, 3, 4, 5, 6, 8, 9, 12], default: 3 },
      labelWidth: { label: 'Label width', kind: 'number', options: [72, 84, 96], unit: ' pt', default: 84, global: true },
      barHeight: { label: 'Bar height', kind: 'number', options: [6, 8, 10, 12], unit: ' pt', default: 8, global: true },
    },
    examples: [{ label: 'Morning', props: {} }],
    render(p, ctx) {
      const v = Math.min(1, Math.max(0, +p.count / Math.max(1, +p.most)));
      return `<div style="display:flex;align-items:center;gap:8px">
        <div style="width:${p.labelWidth}px;flex:none;${F('footnote', { size: 14, weight: 400 })}color:${ctx.g.ink}">${esc(p.label)}</div>
        <div style="flex:1;min-width:0;height:${p.barHeight}px;border-radius:999px;background:${R4.track(ctx.dark)};overflow:hidden"><div style="height:100%;width:${v * 100}%;border-radius:999px;background:${R4.accent(ctx.dark)}"></div></div>
        <div style="min-width:22px;text-align:right;${F('footnote', { size: 14, weight: 400 })}font-variant-numeric:tabular-nums;color:${ctx.g.muted}">${+p.count}</div></div>`;
    },
  });

  E({
    type: 'progressReadyBar', name: 'Patterns-ready bar', group: 'Progress', source: 'DayXero/Shared/V4Reading.swift (V4ProgressBar)',
    description: 'How close the full patterns are: the lesser of days (of 7) and logs (of 5). Green on a soft track, 8 pt.',
    props: {
      value: { label: 'Filled', kind: 'number', options: [0, 0.14, 0.29, 0.43, 0.57, 0.71, 0.86, 1], default: 0 },
      height: { label: 'Height', kind: 'number', options: [4, 6, 8, 10, 12], unit: ' pt', default: 8, global: true },
    },
    render(p, ctx) {
      return `<div role="progressbar" aria-label="Patterns ready" style="height:${p.height}px;border-radius:999px;background:${R4.track(ctx.dark)};overflow:hidden"><div style="height:100%;width:${Math.min(1, Math.max(0, +p.value)) * 100}%;border-radius:999px;background:${R4.accent(ctx.dark)}"></div></div>`;
    },
  });

  E({
    type: 'progressWeekBars', name: 'Cravings by week bars', group: 'Progress', source: SRC + ' (trendCard)',
    description: 'Three weeks side by side: the count, a bar up to 72 pt (green for this week, track for the others) and the week label.',
    props: {
      w1: { label: 'Two weeks ago', kind: 'number', options: [0, 4, 7, 10, 13, 16, 20], default: 13 },
      w2: { label: 'Last week', kind: 'number', options: [0, 4, 7, 10, 13, 16, 20], default: 10 },
      w3: { label: 'This week', kind: 'number', options: [0, 4, 7, 10, 13, 16, 20], default: 7 },
      l1: { label: 'First label', kind: 'text', default: '16 Nov' },
      l2: { label: 'Second label', kind: 'text', default: 'Last week' },
      l3: { label: 'Third label', kind: 'text', default: 'This week' },
      maxBar: { label: 'Tallest bar', kind: 'number', options: [56, 64, 72, 80, 96], unit: ' pt', default: 72 },
      radius: { label: 'Bar corner radius', kind: 'number', options: [4, 6, 8, 12], unit: ' pt', default: 8 },
    },
    examples: [{ label: 'Week 4', props: {} }],
    render(p, ctx) {
      const ws = [[+p.w1, p.l1, false], [+p.w2, p.l2, false], [+p.w3, p.l3, true]];
      const most = Math.max(1, ...ws.map((w) => w[0]));
      const col = ([n, label, cur]) => `<div style="flex:1;min-width:0;display:flex;flex-direction:column;align-items:center;gap:4px">
        <div style="${F('caption', { size: 12, weight: 600 })}color:${ctx.g.ink}">${n}</div>
        <div style="width:100%;height:${Math.max(4, (p.maxBar * n) / most)}px;border-radius:${p.radius}px;background:${cur ? R4.accent(ctx.dark) : R4.track(ctx.dark)}"></div>
        <div style="${F('caption', { size: 12, weight: 400 })}color:${ctx.g.muted};white-space:nowrap">${esc(label)}</div></div>`;
      return `<div style="height:112px;display:flex;align-items:flex-end;gap:12px">${ws.map(col).join('')}</div>`;
    },
  });

  const FLAME = '<path d="M12 3c.6 3-1.8 4.6-3.2 6.6C7.4 11.5 7 13 7 14.5a5 5 0 0 0 10 0c0-2-1-3.6-2-4.8-.2 1.3-.9 2.1-1.8 2.4.6-3.2-.2-6.5-1.2-9.1z" fill="currentColor"/>';
  E({
    type: 'progressLogRow', name: 'Log row', group: 'Progress', source: SRC + ' (LogEntryRow)',
    description: 'One line in "Recent logs": a 30 pt icon circle (green with a tick when ridden out), the kind in 14 pt semibold and when, trigger and strength under it.',
    props: {
      kind: { label: 'Kind', kind: 'select', default: 'passed', options: [['passed', 'Craving ridden out'], ['craving', 'Craving'], ['slip', 'Slip'], ['use', 'Use']] },
      title: { label: 'Title', kind: 'text', default: 'Craving ridden out' },
      detail: { label: 'Detail', kind: 'text', default: 'Today 09:40 · Coffee' },
      radius: { label: 'Corner radius', kind: 'number', options: [14, 18, 20, 24], unit: ' pt', default: 20, global: true },
    },
    examples: [{ label: 'Ridden out', props: {} }, { label: 'Craving', props: { kind: 'craving', title: 'Craving', detail: 'Mon 30 Nov 16:05 · Stress · strong' } }],
    render(p, ctx) {
      const d = ctx.dark, passed = p.kind === 'passed';
      const fg = passed ? Lab.CREAM : ctx.g.muted;
      const icon = p.kind === 'craving' ? `<svg viewBox="0 0 24 24" width="13" height="13" style="color:${fg};display:block">${FLAME}</svg>`
        : Lab.icon(passed ? 'checkmark' : p.kind === 'slip' ? 'heart.fill' : 'plus', 13, fg);
      return `<div role="button" style="display:flex;align-items:center;gap:12px;padding:10px 12px;border-radius:${p.radius}px;background:${R4.card(d)};box-shadow:inset 0 0 0 1px ${R4.hairline(d)}">
        <div style="width:30px;height:30px;border-radius:50%;flex:none;display:flex;align-items:center;justify-content:center;background:${passed ? R4.accent(d) : R4.track(d)}">${icon}</div>
        <div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:1px">${T('footnote', p.title, ctx, { size: 14, weight: 600 })}${T('footnote', p.detail, ctx, { tone: 'muted' })}</div></div>`;
    },
  });

  /* ---------- Sam's data per state ---------- */
  // Times are 09:40, Sam's morning coffee wave. Counters follow the code (decision 17, persona codeTrue).
  const WEEK4_CRAVINGS = [ // illustrative: four weeks of craving logs, Monday first
    [5, 4, 5, 4, 5, 3, 3],
    [1, 1, 0, 1, 1, 1, 0],
    [2, 3, 2, 2, 3, 1, 1],
    [1, 1, 1, 0, 1, 2, 2],
    [0, 0, 0, 0, 0, 1, 0],
  ];
  const WEEK4_USES = [ // illustrative: prep-week uses on Thu 5 Nov, the only ones inside the 28-day window; no slips
    [0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 2, 0, 0, 0],
    [0, 0, 0, 2, 0, 0, 0],
    [0, 0, 0, 3, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0],
  ];
  const DATA = {
    early: {
      prep: true,
      eyebrow: 'Quit Day in 4 days',
      clarity: 20, pill: 'Sky 20% clear · clears from Quit Day',
      tiles: [['3', 'of 7 prep days done'], ['0', 'waves ridden out'], ['$2,555', 'to keep a year'], ['4', 'days to Quit Day']],
      money: '$7 a day, about $2,555 a year.',
      health: [{ id: 'next', status: 'Starting on Quit Day', when: 'Within minutes', title: 'Heart rate and blood pressure start to come down', line: 'From your first smoke-free hours.', source: 'Source: American Cancer Society' }],
      ready: false,
      // DebugScenario.prep: today's uses at 07:00, 08:00 and 09:00, Sam's first logs.
      counts: [3, 0, 0, 0, 0], readiness: 0, readyLine: 'Full patterns in 7 days',
    },
    day3: {
      eyebrow: 'Since Quit Day · Fri 6 Nov',
      clarity: 28, pill: 'Sky 28% clear · clears a little each day',
      daysClear: 3,
      tiles: [['3', 'days clear'], ['15', 'waves ridden out'], ['26', 'cigarettes not smoked'], ['$15.65', 'kept']],
      money: '$7 a day, about $2,555 a year. 2 evening check-ins with Glim.',
      // health-timeline.json at 53.7 h: taste (from 48 h) is the latest under way; fresh breath (168 h) is next.
      health: [
        { id: 'now', status: 'Happening now', when: '2 to 5 days', title: 'Food starts tasting like food again', line: 'Taste and smell wake back up.', source: '' },
        { id: 'next', status: 'Next', when: '1 to 2 weeks', title: 'Fresher breath, brighter smile', line: '', source: '' },
      ],
      ready: false,
      counts: [9, 2, 5, 4, 1], readiness: 6 / 7, readyLine: 'Full patterns tomorrow',
    },
    week4: {
      eyebrow: 'Since Quit Day · Fri 6 Nov',
      clarity: 98, pill: 'Sky 98% clear · clears a little each day',
      daysClear: 28,
      tiles: [['28', 'days clear'], ['61', 'waves ridden out'], ['326', 'cigarettes not smoked'], ['$190.65', 'kept']],
      money: '$7 a day, about $2,555 a year. 26 evening check-ins with Glim.',
      // health-timeline.json at 653.7 h: skin glow (336–1008 h) is the first of three under way from 336 h; coughing (720 h) is next.
      health: [
        { id: 'now', status: 'Happening now', when: '2 to 6 weeks', title: 'Your skin starts to glow', line: 'Better blood flow, a brighter, fresher face.', source: '' },
        { id: 'next', status: 'Next', when: '1 to 12 months', title: 'Coughing and shortness of breath ease', line: '', source: 'Source: American Cancer Society' },
      ],
      ready: true,
      grid: WEEK4_CRAVINGS, gridUses: WEEK4_USES,
      triggers: [['Coffee', 21], ['Stress', 12]], tagged: 33,
      weeks: [13, 10, 7], weekLabels: ['16 Nov', 'Last week', 'This week'], change: 'Down 30%', riddenLine: 'You rode out 6 of 7 cravings this week.',
      logs: [
        ['passed', 'Today 09:40 · Coffee · moderate'],
        ['passed', 'Yesterday 15:10 · Stress · mild'],
        ['passed', 'Yesterday 09:35 · Coffee · moderate'],
        ['passed', 'Tue 1 Dec 14:20 · Stress'],
        ['passed', 'Tue 1 Dec 09:50 · Coffee · mild'],
        ['craving', 'Mon 30 Nov 16:05 · Stress · strong'],
        ['passed', 'Mon 30 Nov 09:45 · Coffee · moderate'],
        ['passed', 'Sun 29 Nov 10:30 · Coffee · mild'],
      ],
    },
  };

  const HEALTH_ALTS = {
    status: ['Happening now', 'Next', 'Starting on Quit Day'],
    title: ['Carbon monoxide in your blood drops to normal', 'Circulation and lung function improve'],
    line: ['More oxygen reaches your body.'],
  };

  Lab.screen({
    id: 'progress',
    name: 'Your progress',
    area: 'Progress',
    source: SRC,
    ground: 'reading',
    tab: 'me',
    note: 'Me tab (HomeView: "progress"/"me" opens ProgressTab). Sam at 09:40 each day. Counters follow the code (decision 17): 26 / $15.65 on Day 3, 326 / $190.65 on Thu 3 Dec; 61 waves and 26 check-ins on Thu 3 Dec are the persona finale values. Sam\'s first log is taken as Mon 2 Nov 07:00 (the prep debug scenario\'s logs that day), so patterns open on Mon 9 Nov. The pattern numbers are illustrative: the Day 3 time-of-day counts, the Week 4 heat map, trigger counts (Coffee 21, Stress 12), weekly bars and recent logs are not in the repo. No vape counter tile ("puffs not taken") is shown because the persona has no vape baseline; no NRT plan cards. Dates are written "Fri 6 Nov" as in the design doc. The Week 4 heat-map card also has a Uses series (amber) in the switch.',
    states: [
      { id: 'early', label: 'Prep · Mon 2 Nov (patterns not ready)' },
      { id: 'day3', label: 'Day 3 · Sun 8 Nov' },
      { id: 'week4', label: 'Week 4 · Thu 3 Dec (heat map)' },
    ],
    build(h, state) {
      const D = DATA[state.id] || DATA.early;
      const kids = [];

      // Header (F12): eyebrow + "Your progress", Log beside it; 16 pt above.
      kids.push(h('stack', 'header-wrap', { padTop: 16 }, [
        h('row', 'header', { justify: 'space-between', align: 'center', gap: 8 }, [
          h('stack', 'header-text', { gap: 2 }, [
            h('text', 'eyebrow', { step: 'caption', tone: 'muted', text: D.eyebrow, alts: { text: ['Quit Day in 4 days', 'Since Quit Day · Fri 6 Nov'] } }),
            h('markedTitle', 'title', { lead: 'Your ', word: 'progress', mark: 'underline', step: 'large' }),
          ]),
          h('progressLogButton', 'log-button', {}),
        ]),
      ]));

      kids.push(h('progressSkyStrip', 'sky', { clarity: D.clarity, pill: D.pill, alts: { pill: ['Sky 20% clear · clears from Quit Day', 'Sky 28% clear · clears a little each day'] } }));

      kids.push(h('progressStatGrid', 'tiles', {}, D.tiles.map((t, i) => h('progressStat', 'tile-' + (i + 1), { value: t[0], label: t[1] }))));

      kids.push(h('text', 'money-line', { step: 'footnote', tone: 'muted', text: D.money }));

      if (!D.prep) kids.push(h('progressMilestones', 'milestones', { daysClear: D.daysClear }));

      // What's changing (S10).
      kids.push(h('stack', 'changing-wrap', { padTop: 16 }, [h('text', 'changing-heading', { step: 'caption', tone: 'muted', text: "What's changing" })]));
      D.health.forEach((f) => kids.push(h('healthFactCard', 'health-' + f.id, {
        status: f.status, when: f.when, title: f.title, line: f.line, sourceLabel: f.source,
        alts: { status: HEALTH_ALTS.status, title: HEALTH_ALTS.title, line: HEALTH_ALTS.line, sourceLabel: ['Source: American Cancer Society'] },
      })));
      kids.push(h('progressLink', 'timeline-link', {}));

      // Your patterns: the mist panel (decision 31), 16 pt above, padding 16, radius 28, 12 pt between.
      const panel = [
        h('row', 'patterns-header', { align: 'flex-end', justify: 'space-between', gap: 8 }, [
          h('stack', 'patterns-header-text', { gap: 4, padBottom: 8 }, [
            h('text', 'patterns-kicker', { step: 'footnote', tone: 'muted', text: D.ready ? 'Last 4 weeks' : 'From your logs', alts: { text: ['Last 4 weeks', 'From your logs'] } }),
            h('markedTitle', 'patterns-title', { lead: 'Your ', word: 'patterns', mark: 'underline', step: 'title' }),
          ]),
          h('art', 'patterns-person', { art: 'person:magnify', width: 72, height: 96, shirt: '#FFC38A' }),
        ]),
      ];
      if (D.ready) {
        const pk = peaks(D.grid);
        panel.push(h('patternsPanel', 'heat-card', { gap: 12 }, [
          h('row', 'heat-head', { align: 'flex-start', justify: 'space-between', gap: 8 }, [
            h('text', 'heat-title', { step: 'headline', text: 'When cravings hit', alts: { text: ['When cravings hit', 'When you used'] } }),
            h('patternsSeriesToggle', 'series', { selected: 'cravings' }),
          ]),
          h('patternsSummary', 'heat-summary', {
            peak: pk[0] ? peakName(pk[0]) : '', rest: pk[1] ? ' are your toughest time, then ' : ' are your toughest time.',
            peak2: pk[1] ? peakName(pk[1]).toLowerCase() : '', end: pk[1] ? '.' : '',
            alts: { peak: PEAK_NAMES, peak2: PEAK_NAMES.map((n) => n.toLowerCase()), rest: [' are your toughest time, then ', ' are your toughest time.', " are when you've used most."] },
          }),
          h('patternsHeatMap', 'heat-map', { series: 'cravings', grid: D.grid, gridUses: D.gridUses }),
        ]));
        panel.push(h('patternsPanel', 'triggers-card', { gap: 8 }, [
          h('row', 'triggers-head', { align: 'baseline', justify: 'space-between', gap: 8 }, [
            h('text', 'triggers-title', { step: 'headline', text: 'Top triggers' }),
            h('text', 'triggers-count', { step: 'caption', tone: 'muted', text: `${D.tagged} logged` }),
          ]),
          h('patternsTriggers', 'triggers', {
            first: D.triggers[0][0], firstCount: D.triggers[0][1], second: D.triggers[1][0], secondCount: D.triggers[1][1],
            alts: { first: TRIGGER_TITLES, second: TRIGGER_TITLES },
          }),
        ]));
      } else {
        const most = Math.max(1, ...D.counts);
        panel.push(h('patternsPanel', 'early-card', { gap: 12 }, [
          h('text', 'early-title', { step: 'headline', text: "When you've logged so far" }),
          ...TIMES.map((t, i) => h('patternsTimeRow', 'time-' + i, { label: t, count: D.counts[i], most, alts: { label: TIMES } })),
          h('progressReadyBar', 'ready-bar', { value: Math.round(D.readiness * 100) / 100 }),
          h('text', 'ready-line', { step: 'headline', text: D.readyLine, alts: { text: ['Full patterns in 7 days', 'Full patterns tomorrow', 'Full patterns after 1 more log'] } }),
          h('text', 'from-setup', { step: 'footnote', tone: 'muted', text: 'You said: Coffee · Stress', alts: { text: ['You said: Coffee · Stress · mornings'] } }),
        ]));
      }
      kids.push(h('stack', 'patterns-wrap', { padTop: 16 }, [
        h('stack', 'patterns', { ground: 'mist', padX: 16, padTop: 16, padBottom: 16, radius: 28, gap: 12 }, panel),
      ]));

      if (D.ready) {
        kids.push(h('stack', 'trend-card', { fill: 'raised', radius: 18, padX: 14, padTop: 14, padBottom: 14, gap: 12 }, [
          h('row', 'trend-head', { align: 'baseline', justify: 'space-between', gap: 8 }, [
            h('text', 'trend-title', { step: 'headline', text: 'Cravings by week' }),
            h('text', 'trend-change', { step: 'caption', tone: 'muted', text: D.change, alts: { text: ['Same as last week'] } }),
          ]),
          h('progressWeekBars', 'trend-bars', { w1: D.weeks[0], w2: D.weeks[1], w3: D.weeks[2], l1: D.weekLabels[0], l2: D.weekLabels[1], l3: D.weekLabels[2] }),
          h('text', 'trend-line', { step: 'footnote', tone: 'muted', text: D.riddenLine }),
        ]));
        kids.push(h('stack', 'recent-wrap', { padTop: 12 }, [h('text', 'recent-heading', { step: 'caption', tone: 'muted', text: 'Recent logs' })]));
        D.logs.forEach((l, i) => kids.push(h('progressLogRow', 'log-' + (i + 1), {
          kind: l[0], title: l[0] === 'passed' ? 'Craving ridden out' : 'Craving', detail: l[1],
          alts: { title: ['Craving ridden out', 'Craving', 'Slip'] },
        })));
      }

      // ProgressTab.column: VStack spacing 10, gutter 20, 12 above, 20 below.
      return h('stack', 'body', { padX: 20, padTop: 12, padBottom: 20, gap: 10 }, kids);
    },
  });
})();
