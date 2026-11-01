/* DayXero Screen Lab — Program tab (DayXero/Program/ProgramView.swift, ProgramPathMap.swift).
   Sessions and phases from DayXeroCore/Resources/program.json; states from ProgramUnlock (one session open, Demo mode off). */
(function () {
  'use strict';
  const Lab = window.Lab;
  const E = Lab.element, esc = Lab.esc, T = Lab.text, F = Lab.font;
  const VIEW = 'DayXero/Program/ProgramView.swift';
  const MAP = 'DayXero/Program/ProgramPathMap.swift';
  const CORAL = '#FF7A55';

  /* ---------- Program content (program.json: phases, sessions; ProgramArt.kind(for:)) ---------- */
  const PHASES = [
    { id: 'prep', title: 'Prep', ids: ['P1', 'P2', 'P3', 'P4', 'P5', 'P6', 'P7'] },
    { id: 'dayxero', title: 'Day Xero', ids: ['DX'] },
    { id: 'w1', title: 'Week 1', ids: ['W1D1', 'W1D2', 'W1D3', 'W1D4', 'W1D5', 'W1D6', 'W1D7'] },
    { id: 'w2', title: 'Week 2', ids: ['W2S1', 'W2S2', 'W2S3'] },
    { id: 'w3', title: 'Week 3', ids: ['W3S1', 'W3S2', 'W3S3'] },
    { id: 'w4', title: 'Week 4', ids: ['W4S1', 'W4S2', 'W4S3'] },
  ];
  // [label, title, durationMinutes, ProgramArt kit kind]
  const S = {
    P1: ['Prep 1', "You don't have to quit today", 5, 'dawn'],
    P2: ['Prep 2', 'The first one of the day', 5, 'cup'],
    P3: ['Prep 3', 'Use with your eyes open', 6, 'eye'],
    P4: ['Prep 4', 'The stress loop', 6, 'breath'],
    P5: ['Prep 5', 'Riding the wave', 6, 'sea'],
    P6: ['Prep 6', 'Make it easy on yourself', 6, 'heart'],
    P7: ['Prep 7', 'The night before', 5, 'night'],
    DX: ['Day Xero', 'Day Xero', 5, 'flower'],
    W1D1: ['Day 1', 'Look after the basics', 3, 'glass'],
    W1D2: ['Day 2', 'The noisy passengers', 3, 'clouds'],
    W1D3: ['Day 3', 'Lower the bar', 3, 'sprout'],
    W1D4: ['Day 4', 'If things feel flat', 3, 'sparkle'],
    W1D5: ['Day 5', 'Nights out', 4, 'night'],
    W1D6: ['Day 6', '“Just one”', 4, 'tag'],
    W1D7: ['Day 7', 'One week', 3, 'peak'],
    W2S1: ['Day 8', 'The empty minutes', 4, 'clouds'],
    W2S2: ['Day 10', 'Sleep and strange dreams', 4, 'night'],
    W2S3: ['Day 14', "Two weeks: what's changed", 4, 'peak'],
    W3S1: ['Day 16', 'When life gets heavy', 5, 'anchor'],
    W3S2: ['Day 19', 'Out of nowhere', 4, 'sea'],
    W3S3: ['Day 21', "Three weeks: you're rewiring", 4, 'sprout'],
    W4S1: ['Day 24', 'Your body, moving forward', 4, 'heart'],
    W4S2: ['Day 27', 'If you ever slip', 4, 'shield'],
    W4S3: ['Day 30', 'Graduation', 5, 'flower'],
  };
  const session = (id) => ({ id, label: S[id][0], title: S[id][1], minutes: S[id][2], kit: S[id][3] });
  const phaseById = (id) => PHASES.find((p) => p.id === id) || PHASES[0];

  /** Each stop of a phase. `open`: index of the session open in this phase, 'none' (none yet) or 'all' (all done).
      Mirrors ProgramView.stops(): done, today (open and not needing an upgrade), the last one the goal, the rest locked. */
  function phaseStops(phaseId, open, upgrade) {
    const ids = phaseById(phaseId).ids;
    const at = open === 'all' ? ids.length : open === 'none' || open === '' || open == null ? -1 : Math.min(+open, ids.length - 1);
    return ids.map((id, i) => {
      const s = session(id);
      const done = open === 'all' || (at >= 0 && i < at);
      const isOpen = at >= 0 && i === at && open !== 'all';
      const needsUpgrade = isOpen && !!upgrade;
      s.state = done ? 'done' : isOpen ? (needsUpgrade ? 'upgrade' : 'today') : 'locked';
      s.needsUpgrade = needsUpgrade;
      s.kind = done ? 'done' : isOpen && !needsUpgrade ? 'today' : i === ids.length - 1 ? 'goal' : 'locked';
      return s;
    });
  }
  Lab.programStops = phaseStops;

  /* ---------- Small drawings the shared icon set doesn't have ---------- */
  const svg = (size, colour, body) => `<svg viewBox="0 0 24 24" width="${size}" height="${size}" style="color:${colour};flex:none;display:block" aria-hidden="true">${body}</svg>`;
  const ICON = {
    lockOpen: '<rect x="5" y="10.5" width="14" height="10" rx="2.5" fill="none" stroke="currentColor" stroke-width="2.2"/><path d="M8 10.5V8a4 4 0 0 1 7.6-1.7" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/>',
    replay: '<path d="M5.2 12.5a7 7 0 1 0 2.1-5.4" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round"/><path d="M6.6 3.6v4.2h4.2" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>',
    book: '<path d="M7 3.5h10.5a1 1 0 0 1 1 1v15a1 1 0 0 1-1 1H7a2 2 0 0 1-2-2v-13a2 2 0 0 1 2-2z" fill="none" stroke="currentColor" stroke-width="2"/><path d="M8.5 3.5v17" stroke="currentColor" stroke-width="2"/>',
  };

  /* ---------- Colours the Program tab uses ---------- */
  const tileFill = (dark) => (dark ? '#16382D' : '#FFF8EE'); // tileFill / ProgramPathMap.tile
  const reading = (dark) => Lab.ground('reading', dark); // DX.Ground.reading (Read4)
  const green = (dark) => Lab.c(Lab.fill.green, dark); // DX.Fill.green
  const kitValue = (v) => (String(v).includes(':') ? v : 'kit:' + v);

  /* ---------- Phase picker ---------- */
  E({
    type: 'programPhasePicker', name: 'Phase picker', group: 'Program', source: VIEW,
    description: 'The program’s phases as pills in a soft track. The phase shown is an ink pill; a finished phase gets a tick. Scrolls sideways.',
    props: {
      selected: { label: 'Phase shown', kind: 'select', default: 'prep', options: PHASES.map((p) => [p.id, p.title]) },
      done: { label: 'Phases finished', kind: 'number', default: 0, options: [[0, 'None'], [1, 'Prep'], [2, 'Up to Day Xero'], [3, 'Up to Week 1'], [4, 'Up to Week 2'], [5, 'Up to Week 3'], [6, 'All']] },
      ticks: { label: 'Tick on finished phases', kind: 'bool', labels: ['Show', 'Hide'], default: true },
      height: { label: 'Pill height', kind: 'number', options: [36, 40, 44], unit: ' pt', default: 40, global: true },
      track: { label: 'Track', kind: 'select', default: 'soft', global: true, options: [['soft', 'Soft track (8%)'], ['none', 'No track']] },
    },
    examples: [{ label: 'Week 1 shown', ground: 'mint', props: { selected: 'w1', done: 2 } }],
    render(p, ctx) {
      const dark = ctx.dark;
      const pills = PHASES.map((ph, i) => {
        const on = ph.id === p.selected;
        const fg = on ? reading(dark).bg : ctx.g.ink;
        const tick = p.ticks && i < +p.done ? Lab.icon('checkmark', 16, fg) : '';
        return `<div role="button" style="flex:none;display:flex;align-items:center;gap:4px;padding:0 14px;min-height:${p.height}px;border-radius:999px;${on ? `background:${ctx.g.ink};` : ''}color:${fg};${F('footnote', { size: 14, weight: 700, family: 'body' })}white-space:nowrap">${esc(ph.title)}${tick}</div>`;
      }).join('');
      const track = p.track === 'soft' ? (dark ? 'rgba(255,255,255,0.08)' : 'rgba(30,26,58,0.08)') : 'transparent';
      return `<div style="margin:0 -20px;padding:0 20px;overflow-x:auto;scrollbar-width:none"><div style="display:inline-flex;gap:2px;padding:4px;border-radius:999px;background:${track}">${pills}</div></div>`;
    },
  });

  /* ---------- Path map ---------- */
  const ROAD = [['app', 'Cream (dark: deep green), as in the app'], ['#FFFFFF', 'White'], ['#C1F07A', 'Lime'], ['#FFC38A', 'Apricot'], ['#FFD966', 'Sun']];
  const ROAD_DONE = [['app', 'Green #3E9E6A (dark: #2FD08A), as in the app'], ['#0F6E43', 'Deep green'], ['#2FD08A', 'Bright green'], ['#FF7A55', 'Coral'], ['#2A52DB', 'Ocean']];
  const curve = (pts, from, to) => {
    if (from >= to || to >= pts.length) return '';
    let d = `M${pts[from].x} ${pts[from].y}`;
    for (let i = from + 1; i <= to; i++) {
      const a = pts[i - 1], b = pts[i], m = (a.y + b.y) / 2;
      d += ` C${a.x} ${m} ${b.x} ${m} ${b.x} ${b.y}`;
    }
    return d;
  };

  E({
    type: 'programPathMap', name: 'Program path map', group: 'Program', source: MAP,
    description: 'One phase as a winding road, bottom to top: done stops ticked on a green road, today’s a coral play button with a person walking beside it, later ones locked behind a dotted line, the phase’s last session a yellow star.',
    props: {
      phase: { label: 'Phase', kind: 'select', default: 'prep', options: PHASES.map((p) => [p.id, p.title]) },
      open: { label: 'Where you are', kind: 'select', default: 0, options: [['none', 'Nothing open in this phase yet'], [0, 'Stop 1 open'], [1, 'Stop 2 open'], [2, 'Stop 3 open'], [3, 'Stop 4 open'], [4, 'Stop 5 open'], [5, 'Stop 6 open'], [6, 'Stop 7 open'], ['all', 'Every stop done']] },
      upgrade: { label: 'Open stop needs Pro', kind: 'bool', labels: ['Yes', 'No'], default: false },
      person: { label: 'Walking person', kind: 'bool', labels: ['Show', 'Hide'], default: true },
      labels: { label: 'Stop titles', kind: 'bool', labels: ['Show', 'Hide'], default: true },
      dotted: { label: 'Dotted line ahead', kind: 'bool', labels: ['Show', 'Hide'], default: true },
      road: { label: 'Road colour', kind: 'select', default: 'app', global: true, options: ROAD },
      roadDone: { label: 'Done road colour', kind: 'select', default: 'app', global: true, options: ROAD_DONE },
      roadWidth: { label: 'Road width', kind: 'number', options: [20, 24, 28, 32, 36], unit: ' pt', default: 28, global: true },
      step: { label: 'Space between stops', kind: 'number', options: [56, 60, 66, 72, 80], unit: ' pt', default: 66, global: true },
    },
    examples: [
      { label: 'Week 1, Day 2 today', ground: 'mint', props: { phase: 'w1', open: 1 } },
      { label: 'Prep, Prep 4 today', ground: 'mint', props: { phase: 'prep', open: 3 } },
    ],
    render(p, ctx) {
      const dark = ctx.dark;
      const width = ctx.device ? ctx.device.w - 40 : ctx.width || 362;
      const stops = phaseStops(p.phase, p.open, p.upgrade);
      const n = stops.length;
      const step = +p.step;
      const height = Math.max((n - 1) * step + 84, 120);
      const pts = stops.map((s, i) => {
        const last = i === n - 1 && n > 1;
        const f = last ? 0.52 : i % 2 === 0 ? 0.32 : 0.66;
        return { x: Math.round(width * f), y: height - 42 - i * step };
      });
      let todayIndex = stops.findIndex((s) => s.kind === 'today');
      if (todayIndex < 0) todayIndex = null;
      let lastDone = -1;
      stops.forEach((s, i) => { if (s.kind === 'done') lastDone = i; });
      const doneUpTo = todayIndex != null ? todayIndex : lastDone;

      const road = p.road === 'app' ? (dark ? '#1F4A3B' : '#FFF8EE') : p.road;
      const roadDone = p.roadDone === 'app' ? (dark ? '#2FD08A' : '#3E9E6A') : p.roadDone;
      const rw = +p.roadWidth;
      let paths = '';
      if (n > 1) {
        paths += `<path d="${curve(pts, 0, n - 1)}" fill="none" stroke="${road}" stroke-width="${rw}" stroke-linecap="round"/>`;
        if (doneUpTo > 0) paths += `<path d="${curve(pts, 0, doneUpTo)}" fill="none" stroke="${roadDone}" stroke-width="${rw}" stroke-linecap="round"/>`;
        const ahead = curve(pts, Math.max(doneUpTo, 0), n - 1);
        if (p.dotted && ahead) paths += `<path d="${ahead}" fill="none" stroke="${ctx.g.ink}" stroke-width="3" stroke-linecap="round" stroke-dasharray="2 9"/>`;
      }
      const svgRoad = `<svg width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" style="position:absolute;left:0;top:0;overflow:visible" aria-hidden="true">${paths}</svg>`;

      const R = reading(dark);
      const node = (s) => {
        if (s.kind === 'done') return `<div style="width:44px;height:44px;display:flex;align-items:center;justify-content:center"><div style="width:36px;height:36px;border-radius:50%;background:${green(dark)};display:flex;align-items:center;justify-content:center">${Lab.icon('checkmark', 22, R.bg)}</div></div>`;
        if (s.kind === 'today') return `<div style="position:relative;width:56px;height:56px"><div style="position:absolute;inset:-10px;border-radius:50%;background:rgba(255,122,85,0.25)"></div><div style="position:absolute;inset:0;border-radius:50%;background:${CORAL};display:flex;align-items:center;justify-content:center">${Lab.icon('play.fill', 30, Lab.NAVY, 'margin-left:2px')}</div></div>`;
        if (s.kind === 'goal') return `<div style="width:46px;height:46px;border-radius:50%;background:#FFD966;display:flex;align-items:center;justify-content:center">${Lab.icon('star.fill', 27, Lab.NAVY)}</div>`;
        return `<div style="width:44px;height:44px;display:flex;align-items:center;justify-content:center"><div style="width:30px;height:30px;border-radius:50%;background:${tileFill(dark)};box-shadow:inset 0 0 0 3px ${ctx.g.bg};display:flex;align-items:center;justify-content:center">${Lab.icon(s.needsUpgrade ? 'lock.open.fill' : 'lock.fill', 16, R.ink)}</div></div>`;
      };
      const label = (s, pt) => {
        const right = pt.x < width / 2;
        const radius = s.kind === 'today' ? 28 : s.kind === 'goal' ? 23 : 18;
        const gap = radius + 12;
        const w = Math.max(right ? width - pt.x - gap - 4 : pt.x - gap - 4, 60);
        const left = right ? pt.x + gap : pt.x - gap - w;
        const big = s.kind === 'today' || s.kind === 'goal';
        const font = big ? F('headline', { size: 18, weight: 800, family: 'display', lh: 1.15 }) : F('body', { size: 16, weight: s.kind === 'locked' ? 600 : 700, family: 'body', lh: 1.25 });
        return `<div style="position:absolute;left:${left}px;top:${pt.y}px;width:${w}px;transform:translateY(-50%);display:flex;flex-direction:column;gap:1px;align-items:${right ? 'flex-start' : 'flex-end'};text-align:${right ? 'left' : 'right'}">${s.kind === 'today' ? T('caption', `Today · ${s.minutes} min`, ctx) : ''}<div style="${font}color:${ctx.g.ink};display:-webkit-box;-webkit-line-clamp:2;-webkit-box-orient:vertical;overflow:hidden">${esc(s.title)}</div></div>`;
      };
      const items = stops.map((s, i) => `${p.labels ? label(s, pts[i]) : ''}<div role="button" aria-label="${esc(s.title)}" style="position:absolute;left:${pts[i].x}px;top:${pts[i].y}px;transform:translate(-50%,-50%)">${node(s)}</div>`).join('');

      let person = '';
      if (p.person && todayIndex != null) {
        const pt = pts[todayIndex];
        const leftSide = pt.x < width / 2;
        const x = leftSide ? Math.max(pt.x - 74, 40) : Math.min(pt.x + 74, width - 40);
        const ph = 92, pw = (ph * 100) / 120;
        person = `<div style="position:absolute;left:${x - pw / 2}px;top:${pt.y - 18 - ph / 2}px;width:${pw}px;height:${ph}px;line-height:0;pointer-events:none">${Lab.art('person:walk', { width: Math.round(pw), height: ph, shirt: '#FFC38A' })}</div>`;
      }
      return `<div style="position:relative;height:${height}px;width:${width}px;max-width:100%">${svgRoad}${items}${person}</div>`;
    },
  });

  /* ---------- Session tile ---------- */
  E({
    type: 'programTile', name: 'Program session tile', group: 'Program', source: VIEW,
    description: 'One session: its kit illustration with a done or lock badge, a kicker ("Today · 3 min", "Done" or its label) and the title. Today’s has a coral ring and play button; done ones show a replay arrow.',
    props: {
      title: { label: 'Title', kind: 'text', default: 'The noisy passengers' },
      kicker: { label: 'Kicker', kind: 'text', default: 'Today · 3 min' },
      state: { label: 'State', kind: 'select', default: 'today', options: [['done', 'Done (plays again)'], ['today', 'Today (open)'], ['locked', 'Locked or waiting'], ['upgrade', 'Open, needs Pro']] },
      art: { label: 'Illustration', kind: 'kit', default: 'clouds' },
      artSize: { label: 'Illustration size', kind: 'number', options: [48, 56, 64, 72, 80], unit: ' pt', default: 64, global: true },
      artRadius: { label: 'Illustration corners', kind: 'number', options: [12, 14, 18, 22], unit: ' pt', default: 18, global: true },
      badge: { label: 'Done or lock badge', kind: 'bool', labels: ['Show', 'Hide'], default: true, global: true },
      ring: { label: 'Coral ring on today', kind: 'bool', labels: ['Show', 'Hide'], default: true, global: true },
      radius: { label: 'Corner radius', kind: 'number', options: [18, 20, 22, 24, 28], unit: ' pt', default: 22, global: true },
    },
    examples: [
      { label: 'Today', ground: 'mint', props: {} },
      { label: 'Done', ground: 'mint', props: { state: 'done', kicker: 'Done', title: 'Look after the basics', art: 'glass' } },
      { label: 'Locked', ground: 'mint', props: { state: 'locked', kicker: 'Day 3', title: 'Lower the bar', art: 'sprout' } },
    ],
    render(p, ctx) {
      const dark = ctx.dark, R = reading(dark), fill = tileFill(dark);
      const today = p.state === 'today', done = p.state === 'done', up = p.state === 'upgrade';
      const size = +p.artSize;
      const badge = p.badge && !today
        ? `<div style="position:absolute;right:-4px;bottom:-4px;width:24px;height:24px;border-radius:50%;background:${done ? green(dark) : fill};box-shadow:inset 0 0 0 2.5px ${fill};display:flex;align-items:center;justify-content:center">${Lab.icon(done ? 'checkmark' : up ? 'lock.open.fill' : 'lock.fill', 15, done ? R.bg : R.ink)}</div>`
        : '';
      const kickerColour = today ? (dark ? '#FFB59E' : '#B2361C') : R.muted;
      const trailing = today
        ? `<div style="width:44px;height:44px;border-radius:50%;background:${CORAL};display:flex;align-items:center;justify-content:center;flex:none">${Lab.icon('play.fill', 22, Lab.NAVY, 'margin-left:2px')}</div>`
        : done ? svg(19, R.muted, ICON.replay) : '';
      return `<div role="button" style="display:flex;align-items:center;gap:12px;padding:8px 14px 8px 8px;border-radius:${p.radius}px;background:${fill};${today && p.ring ? `box-shadow:inset 0 0 0 2.5px ${CORAL};` : ''}">
        <div style="position:relative;width:${size}px;height:${size}px;flex:none;line-height:0">${Lab.art(kitValue(p.art), { width: size, height: size, radius: +p.artRadius })}${badge}</div>
        <div style="display:flex;flex-direction:column;gap:2px;min-width:0">${T('caption', String(p.kicker).toUpperCase(), ctx, { color: kickerColour })}${T('headline', p.title, ctx, { color: R.ink })}</div>
        <div style="flex:1;min-width:0"></div>${trailing}</div>`;
    },
  });

  /* ---------- "Next up" line ---------- */
  E({
    type: 'programNextLine', name: 'Next up line', group: 'Program', source: VIEW,
    description: 'An open lock and the next session that’s waiting, on a cream card. "No rush."',
    props: {
      text: { label: 'Words', kind: 'text', default: "Next up: Lower the bar, after today's. No rush." },
      icon: { label: 'Open lock', kind: 'bool', labels: ['Show', 'Hide'], default: true },
      radius: { label: 'Corner radius', kind: 'number', options: [14, 18, 20, 22, 24], unit: ' pt', default: 20, global: true },
    },
    examples: [{ label: 'On mint', ground: 'mint', props: {} }],
    render(p, ctx) {
      const R = reading(ctx.dark);
      return `<div style="display:flex;align-items:flex-start;gap:10px;padding:14px;border-radius:${p.radius}px;background:${tileFill(ctx.dark)}">${p.icon ? `<div style="flex:none;padding-top:1px">${svg(18, green(ctx.dark), ICON.lockOpen)}</div>` : ''}${T('footnote', p.text, ctx, { color: R.ink, style: 'flex:1;min-width:0' })}</div>`;
    },
  });

  /* ---------- Variant line ---------- */
  E({
    type: 'programVariantLine', name: 'Program variant line', group: 'Program', source: VIEW,
    description: 'Which version of the program you get: the primary product, then notes for the others.',
    props: {
      name: { label: 'Program', kind: 'text', default: 'Smoking program' },
      rest: { label: 'Notes for', kind: 'text', default: ', with notes for vape' },
      icon: { label: 'Book icon', kind: 'bool', labels: ['Show', 'Hide'], default: true },
    },
    examples: [{ label: 'Sam', ground: 'mint', props: {} }],
    render(p, ctx) {
      const R = reading(ctx.dark);
      return `<div style="display:flex;align-items:center;gap:8px;padding:12px;border-radius:18px;background:${Lab.c(Lab.fill.raised, ctx.dark)}">${p.icon ? svg(20, green(ctx.dark), ICON.book) : ''}<div style="${F('footnote')}color:${R.muted};flex:1;min-width:0"><span style="${F('footnote', { size: 14, weight: 600, family: 'body', lh: 1.3 })}color:${R.ink}">${esc(p.name)}</span>${esc(p.rest)}</div></div>`;
    },
  });

  /* ---------- Program complete header ---------- */
  E({
    type: 'programCompleteHeader', name: 'Program complete header', group: 'Program', source: VIEW,
    description: 'After graduation: the date in green, your own identity statement (if you wrote one) and "Replay any session, any time."',
    props: {
      kicker: { label: 'Kicker', kind: 'text', default: 'Program complete · Sun, 6 Dec' },
      quote: { label: 'Identity statement', kind: 'text', default: '' },
      line: { label: 'Line', kind: 'text', default: 'Replay any session, any time.' },
    },
    examples: [{ label: 'On mint', ground: 'mint', props: {} }],
    render(p, ctx) {
      const R = reading(ctx.dark);
      const soft = ctx.dark ? 'rgba(47,208,138,0.16)' : 'rgba(15,110,67,0.12)';
      return `<div style="display:flex;flex-direction:column;gap:6px;padding:16px;border-radius:22px;background:${soft}">${T('caption', p.kicker, ctx, { color: green(ctx.dark) })}${p.quote ? T('headline', `“${p.quote}.”`, ctx, { color: R.ink }) : ''}${T('footnote', p.line, ctx, { color: R.muted })}</div>`;
    },
  });

  /* ---------- The Program tab ---------- */
  const STATES = {
    // Sam joined Fri 30 Oct and does one session a day: P1 Fri, P2 Sat, P3 Sun, so Prep 4 is open on Mon 2 Nov.
    prep: { phase: 'prep', open: 3, phasesDone: 0, next: "Next up: Riding the wave, after today's. No rush.", nextAlts: ['Next up: Riding the wave, tomorrow. No rush.'] },
    // Day Xero Fri 6 Nov, Day 1 Sat 7 Nov; Sun 8 Nov is 2 days since quit, so W1D2 is open.
    week1: { phase: 'w1', open: 1, phasesDone: 2, next: "Next up: Lower the bar, after today's. No rush.", nextAlts: ['Next up: Lower the bar, on Day 3. No rush.'] },
    // Graduation (W4S3) opens Sun 6 Dec and is finished that day: nothing open, the last phase shown.
    complete: { phase: 'w4', open: 'all', phasesDone: 6, next: null, complete: 'Program complete · Sun, 6 Dec' },
  };

  Lab.screen({
    id: 'program',
    name: 'Program',
    area: 'Program',
    source: VIEW,
    ground: 'mint',
    tab: 'program',
    note: 'Sam does one session a day from Fri 30 Oct, so Mon 2 Nov has Prep 1–3 done and Prep 4 open. On Sun 8 Nov (Day 3) Day Xero and Day 1 are done and W1D2 is open; Sam is in the trial (decision 15), so Week 1 needs no upgrade. Sam has no NRT plan or pouch taper, so the NRT group is not shown. The identity statement on the complete header is left out because it is Sam’s own words.',
    states: [
      { id: 'prep', label: 'Prep · Mon 2 Nov' },
      { id: 'week1', label: 'Day 3 · Sun 8 Nov' },
      { id: 'complete', label: 'Complete · Sun 6 Dec' },
    ],
    build(h, state) {
      const st = STATES[state.id] || STATES.prep;
      const phase = phaseById(st.phase);
      const stops = phaseStops(st.phase, st.open, false);
      const doneCount = stops.filter((s) => s.state === 'done').length;
      const tiles = stops.map((s) => {
        const kicker = s.state === 'today' ? `Today · ${s.minutes} min` : s.state === 'upgrade' ? 'Unlock to start' : s.state === 'done' ? 'Done' : s.label;
        const alts = {};
        if (s.state === 'locked' && st.next && stops.indexOf(s) === stops.findIndex((x) => x.state === 'today') + 1) {
          alts.kicker = st.phase === 'w1' ? ['Unlocks on Day 3'] : ['Unlocks tomorrow'];
        }
        return h('programTile', 'tile-' + s.id, { title: s.title, kicker, state: s.state, art: s.kit, alts });
      });
      return h('stack', 'body', { padX: 20, padTop: 20, padBottom: 20, gap: 12 }, [
        h('stack', 'header', { gap: 4 }, [
          h('text', 'eyebrow', { step: 'footnote', tone: 'muted', text: 'Prep, Quit Day, then four weeks' }),
          h('markedTitle', 'title', { lead: 'Your ', word: 'program', mark: 'underline', step: 'large' }),
        ]),
        h('programPhasePicker', 'phases', { selected: st.phase, done: st.phasesDone }),
        st.complete ? h('programCompleteHeader', 'complete-header', { kicker: st.complete }) : null,
        h('programPathMap', 'path', { phase: st.phase, open: st.open }),
        st.next ? h('programNextLine', 'next-up', { text: st.next, alts: { text: st.nextAlts } }) : null,
        h('stack', 'phase-heading-box', { padTop: 12 }, [
          h('text', 'phase-heading', { step: 'caption', tone: 'muted', text: `${phase.title} · ${doneCount} of ${phase.ids.length} done` }),
        ]),
        ...tiles,
        h('stack', 'variant-box', { padTop: 12 }, [
          h('programVariantLine', 'variant', { name: 'Smoking program', rest: ', with notes for vape', alts: { name: ['Vaping program', 'Pouches program'] } }),
        ]),
      ]);
    },
  });
})();
