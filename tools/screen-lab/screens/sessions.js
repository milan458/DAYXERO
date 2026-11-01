/* DayXero Screen Lab — Program sessions (DayXero/ProgramV2: SessionFlowView, BeatKit, BeatsA, BeatsB, MissionPrompts)
   and the lesson audio player (DayXero/Program/LessonAudio.swift) on the reading tier (DayXero/Shared/V4Reading.swift).
   Copy from DayXeroCore/Resources/program.json and the Swift. Sam: smoking variant, no NRT plan. See ../FORMAT.md. */
(function () {
  'use strict';
  const Lab = window.Lab;
  const E = Lab.element, esc = Lab.esc, T = Lab.text, F = Lab.font;
  const FLOW = 'DayXero/ProgramV2/SessionFlowView.swift';
  const KIT = 'DayXero/ProgramV2/BeatKit.swift';
  const BA = 'DayXero/ProgramV2/BeatsA.swift';
  const BB = 'DayXero/ProgramV2/BeatsB.swift';
  const MP = 'DayXero/ProgramV2/MissionPrompts.swift';
  const AUDIO = 'DayXero/Program/LessonAudio.swift';
  const V4 = 'DayXero/Shared/V4Reading.swift';

  /* Read4 (V4Reading.swift): the reading tier's colours for the appearance. */
  function R4(ctx) {
    const d = ctx.dark;
    const g = Lab.ground('reading', d);
    return {
      bg: g.bg, ink: g.ink, muted: g.muted,
      faint: d ? 'rgba(255,248,238,0.38)' : 'rgba(30,26,58,0.38)',
      hairline: d ? 'rgba(255,255,255,0.14)' : 'rgba(30,26,58,0.12)',
      track: d ? 'rgba(255,255,255,0.16)' : 'rgba(30,26,58,0.12)',
      card: Lab.c(Lab.fill.raised, d), surface: Lab.c(Lab.fill.surface, d),
      accent: Lab.c(Lab.fill.green, d),
      accentSoft: d ? 'rgba(47,208,138,0.16)' : 'rgba(15,110,67,0.12)',
      amber: d ? '#E5A93C' : '#8A5E0E', amberRGB: d ? '229,169,60' : '138,94,14',
      // SwiftUI's placeholder text and a plain Slider's empty track.
      placeholder: d ? 'rgba(235,235,245,0.3)' : 'rgba(60,60,67,0.3)',
      sliderTrack: d ? 'rgba(120,120,128,0.36)' : 'rgba(120,120,128,0.2)',
    };
  }
  const TONES = [['ink', 'Ink'], ['muted', 'Muted'], ['accent', 'Green (accent)'], ['amber', 'Amber']];
  const tone = (r, t) => (t === 'muted' ? r.muted : t === 'accent' ? r.accent : t === 'amber' ? r.amber : r.ink);

  /* SF Symbols this file needs that lab.js doesn't draw. The 15 in the skip glyphs is part of the symbol. */
  const GLYPHS = {
    headphones: '<path d="M4 15.5V12a8 8 0 0 1 16 0v3.5" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/><rect x="3" y="13.5" width="5" height="7.5" rx="2" fill="currentColor"/><rect x="16" y="13.5" width="5" height="7.5" rx="2" fill="currentColor"/>',
    sparkle: '<path d="M12 2.5c.8 5.3 4.2 8.7 9.5 9.5-5.3.8-8.7 4.2-9.5 9.5-.8-5.3-4.2-8.7-9.5-9.5 5.3-.8 8.7-4.2 9.5-9.5z" fill="currentColor"/>',
    heart: '<path d="M12 20s-7.5-4.6-7.5-10A4.3 4.3 0 0 1 12 7.4 4.3 4.3 0 0 1 19.5 10c0 5.4-7.5 10-7.5 10z" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/>',
    flip: '<path d="M4.5 11.5a7.5 7.5 0 0 1 13-4.6M17.8 3.6v3.6h-3.6" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/><path d="M19.5 12.5a7.5 7.5 0 0 1-13 4.6M6.2 20.4v-3.6h3.6" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>',
    share: '<path d="M12 3.5v11M8 7.5l4-4 4 4" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/><path d="M8 10.5H6.5A1.5 1.5 0 0 0 5 12v7.5A1.5 1.5 0 0 0 6.5 21h11a1.5 1.5 0 0 0 1.5-1.5V12a1.5 1.5 0 0 0-1.5-1.5H16" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>',
    pencil: '<path d="M4.5 19.5l1-4.4L15.6 5a2.1 2.1 0 0 1 3 3L8.5 18.3z" fill="none" stroke="currentColor" stroke-width="1.9" stroke-linejoin="round"/><path d="M13.6 7l3 3" stroke="currentColor" stroke-width="1.9"/>',
    photo: '<rect x="3" y="5" width="18" height="14" rx="2.5" fill="none" stroke="currentColor" stroke-width="2"/><circle cx="8.5" cy="10" r="1.7" fill="currentColor"/><path d="M4 17.5l5-5 4 4 2.8-2.8L20 18" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>',
    walk: '<circle cx="14.5" cy="4.3" r="2" fill="currentColor"/><path d="M13.5 8.2l-2.4 5 3 2.6V21M11.1 13.2L9.3 21M13.5 8.2l2.6 3.4 2.6.6M13.5 8.2l-3 1.4-1.4 2.8" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/><path d="M2.5 10h3.5M3.5 14h3M2.5 18h4" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" opacity=".7"/>',
    back15: '<path d="M6.3 7.2A8 8 0 1 1 4 12.8" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><path d="M9.8 3.4L6 7.2l3.9 2.4" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/><path d="M9.4 10.4l1.2-.8v6M13.6 9.6h2.6M13.6 9.6l-.3 2.6c.4-.3.9-.4 1.4-.4 1 0 1.6.8 1.6 1.8s-.7 1.9-1.7 1.9c-.6 0-1.1-.3-1.4-.7" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>',
    fwd15: '<path d="M17.7 7.2A8 8 0 1 0 20 12.8" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><path d="M14.2 3.4L18 7.2l-3.9 2.4" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/><path d="M8.4 10.4l1.2-.8v6M12.6 9.6h2.6M12.6 9.6l-.3 2.6c.4-.3.9-.4 1.4-.4 1 0 1.6.8 1.6 1.8s-.7 1.9-1.7 1.9c-.6 0-1.1-.3-1.4-.7" fill="none" stroke="currentColor" stroke-width="1.4" stroke-linecap="round" stroke-linejoin="round"/>',
    battery: '<rect x="2" y="7" width="17.5" height="10" rx="2.6" fill="none" stroke="currentColor" stroke-width="1.8"/><path d="M21.5 10.3v3.4" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/><path d="M11.8 8.6L8.6 12.6h2.8l-.9 3 3.4-4.2h-2.8l.7-2.8z" fill="currentColor"/>',
  };
  const ICONS = [['', 'None'], ['headphones', 'Headphones'], ['clock', 'Clock'], ['calendar', 'Calendar'], ['checkmark', 'Tick'], ['checkcircle', 'Tick in a circle'], ['sparkle', 'Sparkle'], ['heart', 'Heart'], ['flip', 'Flip arrows'], ['share', 'Share'], ['pencil', 'Pencil'], ['photo', 'Photo'], ['walk', 'Walking figure'], ['plus', 'Plus'], ['info.circle', 'Info'], ['battery', 'Battery']];
  /** A glyph; `knock` is the colour the tick shows through in "Tick in a circle". */
  function glyph(name, size, colour, knock) {
    if (name === 'checkcircle') return `<svg viewBox="0 0 24 24" width="${size}" height="${size}" style="flex:none;display:block" aria-hidden="true"><circle cx="12" cy="12" r="10" fill="${colour}"/><path d="M7.6 12.4l3 3 5.8-6.2" fill="none" stroke="${knock || '#fff'}" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/></svg>`;
    if (GLYPHS[name]) return `<svg viewBox="0 0 24 24" width="${size}" height="${size}" style="color:${colour};flex:none;display:block" aria-hidden="true">${GLYPHS[name]}</svg>`;
    return name ? Lab.icon(name, size, colour) : '';
  }
  const inert = (ctx) => Object.assign(ctx.with({}), { inert: true });

  /* ===================== Session chrome (SessionFlowView) ===================== */
  E({
    type: 'sessionFrame', name: 'Session canvas', group: 'Sessions', source: FLOW,
    description: 'The full-screen session: 20 pt sides, 12 pt under the status bar, 8 pt above the home indicator. Reading ground; apricot for Day Xero’s hold, sun for its completion.',
    props: {
      ground: { label: 'Ground', kind: 'select', default: 'reading', options: [['reading', 'Reading (most steps)'], ['apricot', 'Apricot (Day Xero hold)'], ['sun', 'Sun (Day Xero done)']] },
      padX: { label: 'Side padding', kind: 'number', options: [16, 20, 24], unit: ' pt', default: 20, global: true },
      padTop: { label: 'Top padding', kind: 'number', options: [0, 8, 12, 16], unit: ' pt', default: 12, global: true },
      padBottom: { label: 'Bottom padding', kind: 'number', options: [0, 4, 8, 12, 16], unit: ' pt', default: 8, global: true },
    },
    render(p, ctx, kids) {
      const d = ctx.screenId !== '_lib' && ctx.device ? ctx.device : null;
      const g = Lab.ground(p.ground, ctx.dark);
      const pull = d ? `margin-bottom:-${d.bottom + 12}px;` : '';
      return `<div style="flex:1;min-height:${d ? 0 : 300}px;display:flex;flex-direction:column;background:${g.bg};color:${g.ink};padding:${(d ? d.top : 0) + +p.padTop}px ${p.padX}px ${(d ? d.bottom : 0) + +p.padBottom}px;${pull}">${kids({ groundName: p.ground })}</div>`;
    },
  });

  E({
    type: 'sessionHeader', name: 'Lesson bar', group: 'Sessions', source: FLOW + ' (header)',
    description: 'Close (44 pt, "Your place is saved."), a green 8 pt bar over the steps, "Replay" on replays, and Xero’s 40 pt avatar on apricot. Hidden on the completion step.',
    props: {
      step: { label: 'Step', kind: 'number', options: [1, 2, 3, 4, 5, 6, 7, 8, 9], default: 1 },
      total: { label: 'Steps in the session', kind: 'number', options: [5, 6, 7, 8, 9], default: 7 },
      replay: { label: '"Replay" tag', kind: 'bool', labels: ['Show', 'Hide'], default: false },
      avatar: { label: 'Avatar', kind: 'art', default: 'xero:hello' },
      barHeight: { label: 'Bar height', kind: 'number', options: [4, 6, 8, 10], unit: ' pt', default: 8, global: true },
    },
    examples: [{ label: 'Step 3 of 7', ground: 'reading', props: { step: 3 } }],
    render(p, ctx) {
      const r = R4(ctx);
      const frac = Math.min(1, Math.max(0, +p.step / Math.max(+p.total, 1)));
      const tag = p.replay ? `<div style="flex:none;padding:6px 10px;border-radius:999px;background:${r.surface}">${T('caption', 'Replay', ctx, { color: r.muted })}</div>` : '';
      const av = p.avatar && p.avatar !== 'none' ? `<div style="width:40px;height:40px;border-radius:50%;overflow:hidden;flex:none;background:${Lab.ground('apricot', ctx.dark).bg};line-height:0">${Lab.art(p.avatar, { size: 40, animate: false })}</div>` : '';
      return `<div style="display:flex;align-items:center;gap:12px;padding-bottom:12px">
        <div role="button" aria-label="Close. Your place is saved." style="width:44px;height:44px;border-radius:50%;background:${r.surface};display:flex;align-items:center;justify-content:center;flex:none">${Lab.icon('xmark', 16, r.ink)}</div>
        <div style="flex:1;min-width:0;height:${p.barHeight}px;border-radius:999px;background:${r.track};overflow:hidden"><div style="height:100%;width:${(frac * 100).toFixed(1)}%;border-radius:999px;background:${r.accent}"></div></div>${tag}${av}</div>`;
    },
  });

  E({
    type: 'sessionScene', name: 'Session scene', group: 'Sessions', source: FLOW + ' (SessionIntro, SessionCompletion)',
    description: 'The horizon at the sky’s clarity (fit to the bottom) with Xero standing in front, clipped to a 24 pt card.',
    props: {
      scene: { label: 'Horizon', kind: 'select', default: 'path', options: [['path', 'Path'], ['dawn', 'Dawn'], ['dusk', 'Dusk'], ['sea', 'Sea'], ['night', 'Night']] },
      clarity: { label: 'Sky clarity', kind: 'number', options: [[20, '20 (prep)'], [23, '23 (Day 1)'], [28, '28 (Day 3)'], [40, '40 (Day 7)'], [60, '60'], [100, '100']], default: 28 },
      character: { label: 'Character', kind: 'art', default: 'xero:hello' },
      charSize: { label: 'Character size', kind: 'number', options: [88, 140, 200], unit: ' pt', default: 140 },
      lift: { label: 'Character lifted by', kind: 'number', options: [0, 2, 4, 8], unit: ' pt', default: 4 },
      height: { label: 'Height', kind: 'number', options: [180, 200, 220, 240, 260], unit: ' pt', default: 220 },
      radius: { label: 'Corner radius', kind: 'number', options: [0, 18, 24, 28], unit: ' pt', default: 24, global: true },
    },
    examples: [{ label: 'Intro, Day 3', ground: 'reading', props: {} }],
    render(p, ctx) {
      const w = (ctx.device ? ctx.device.w : ctx.width || 402) - 40;
      const sky = Lab.art('scene:horizon:' + p.scene, { width: w, height: +p.height, scene: { clarity: +p.clarity, fit: 'bottom' } });
      const ch = p.character && p.character !== 'none' ? `<div style="position:absolute;left:50%;bottom:${p.lift}px;transform:translateX(-50%);width:${p.charSize}px;height:${p.charSize}px;line-height:0">${Lab.art(p.character, { size: +p.charSize })}</div>` : '';
      return `<div style="position:relative;height:${p.height}px;border-radius:${p.radius}px;overflow:hidden;line-height:0;flex:none"><div style="position:absolute;inset:0">${sky}</div>${ch}</div>`;
    },
  });

  E({
    type: 'sessionIconLabel', name: 'Icon and words', group: 'Sessions', source: FLOW + ' (Label)',
    description: 'A SwiftUI Label: an icon and a line of words. Optionally on a raised 18 pt card (v4Card), as the "Next" line on the completion step.',
    props: {
      text: { label: 'Words', kind: 'text', default: '' },
      icon: { label: 'Icon', kind: 'select', default: 'headphones', options: ICONS },
      iconTone: { label: 'Icon colour', kind: 'select', default: 'same', options: [['same', 'Same as the words']].concat(TONES) },
      step: { label: 'Text style', kind: 'type', default: 'footnote' },
      size: { label: 'Exact size', kind: 'number', options: [['', 'From the style'], 12, 14, 16], unit: ' pt', default: '' },
      weight: { label: 'Weight', kind: 'number', options: [['', 'From the style'], 400, 500, 600, 700], default: '' },
      tone: { label: 'Colour', kind: 'select', default: 'ink', options: TONES },
      card: { label: 'Card', kind: 'select', default: 'none', options: [['none', 'None'], ['raised', 'Raised card (v4Card, 16 pt, radius 18)']] },
      align: { label: 'Position', kind: 'select', default: 'flex-start', options: [['flex-start', 'Left'], ['center', 'Centre']] },
    },
    examples: [{ label: 'Session length', props: { text: "3 min · Audio, activities and today's mission" } }],
    render(p, ctx) {
      const r = R4(ctx);
      const g = ctx.groundName === 'reading' ? null : ctx.g;
      const col = g && p.tone === 'ink' ? g.ink : g && p.tone === 'muted' ? g.muted : tone(r, p.tone);
      const ic = p.iconTone === 'same' ? col : tone(r, p.iconTone);
      const o = { color: col };
      if (p.size) { o.size = +p.size; o.family = Lab.type[p.step].family; o.weight = +(p.weight || Lab.type[p.step].weight); }
      else if (p.weight) o.weight = +p.weight;
      const fs = p.size ? +p.size : Lab.type[p.step].size;
      const box = p.card === 'raised' ? `align-self:stretch;padding:16px;border-radius:18px;background:${r.card};` : `align-self:${p.align};`;
      return `<div style="display:flex;align-items:center;gap:6px;${box}">${glyph(p.icon, Math.round(fs * 1.05), ic, r.bg)}${T(p.step, p.text, ctx, o).replace('<div ', '<div class="t" ')}</div>`;
    },
  });

  E({
    type: 'sessionSoonPill', name: '"Coming soon" pill', group: 'Sessions', source: FLOW + ' (ProgramAudioStep.comingSoon)',
    description: 'Headphones and "Audio coming soon" in amber, 14 pt bold, on a 12% amber capsule.',
    props: { text: { label: 'Words', kind: 'text', default: 'Audio coming soon' } },
    examples: [{ label: 'Reading', props: {} }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="display:inline-flex;align-self:center;align-items:center;gap:6px;padding:8px 14px;border-radius:999px;background:rgba(${r.amberRGB},0.12)">${glyph('headphones', 15, r.amber)}<span style="${F('footnote', { size: 14, weight: 700 })}color:${r.amber}">${esc(p.text)}</span></div>`;
    },
  });

  E({
    type: 'sessionMissionCard', name: 'Mission card', group: 'Sessions', source: FLOW + ' (MissionCard)',
    description: 'Today’s mission on an apricot card (Xero’s colour): caption, the mission at 24 pt and a footnote. 20 pt padding, radius 24, lip shadow.',
    props: {
      kicker: { label: 'Kicker', kind: 'text', default: "Today's mission" },
      text: { label: 'Mission', kind: 'text', default: '' },
      note: { label: 'Footnote', kind: 'text', default: 'It stays on your Today card until the next session.' },
      ground: { label: 'Colour', kind: 'ground', default: 'apricot' },
      radius: { label: 'Corner radius', kind: 'number', options: [18, 22, 24, 28], unit: ' pt', default: 24, global: true },
      lip: { label: 'Lip shadow', kind: 'bool', labels: ['On', 'Off'], default: true, global: true },
    },
    examples: [{ label: 'Day 2', ground: 'reading', props: { text: 'Name one passenger today when it shows up.' } }],
    render(p, ctx) {
      const c = ctx.with({ groundName: p.ground });
      return `<div style="display:flex;flex-direction:column;gap:12px;padding:20px;border-radius:${p.radius}px;background:${c.g.bg};${p.lip ? 'box-shadow:0 5px 0 rgba(0,0,0,.12);' : ''}">${T('caption', p.kicker, c, { tone: 'muted' })}${T('title', p.text, c)}${p.note ? T('footnote', p.note, c, { tone: 'muted' }) : ''}</div>`;
    },
  });

  E({
    type: 'sessionDoneMission', name: 'Mission note (Day Xero done)', group: 'Sessions', source: FLOW + ' (SessionCompletion.dayXeroDone)',
    description: 'The mission again under "You’re on Day Xero": caption and body on the card-on-colour fill, 14 pt padding, radius 22.',
    props: {
      kicker: { label: 'Kicker', kind: 'text', default: "Today's mission" },
      text: { label: 'Mission', kind: 'text', default: '' },
      radius: { label: 'Corner radius', kind: 'number', options: [18, 22, 24], unit: ' pt', default: 22 },
    },
    examples: [{ label: 'On sun', ground: 'sun', props: { text: 'Every craving you ride out today, tap “It passed”. Every single one counts.' } }],
    render(p, ctx) {
      return `<div style="align-self:stretch;display:flex;flex-direction:column;gap:4px;padding:14px;border-radius:${p.radius}px;background:${ctx.g.card};text-align:left">${T('caption', p.kicker, ctx, { tone: 'muted' })}${T('body', p.text, ctx)}</div>`;
    },
  });

  E({
    type: 'sessionSheet', name: 'Mission sheet', group: 'Sessions', source: MP + ' (.sheet)',
    description: 'The sheet Home raises when a log answers today’s mission: medium for a quick question, large for the follow-up. Reading ground, 20 pt sides, no grabber.',
    props: {
      top: { label: 'Starts at', kind: 'number', options: [[72, '72 pt (large)'], [437, '437 pt (medium, half the screen)']], unit: ' pt from the top', default: 437 },
      radius: { label: 'Corner radius', kind: 'number', options: [28, 34, 38], unit: ' pt', default: 38 },
      scrim: { label: 'Dimming behind', kind: 'number', options: [0, 0.1, 0.2, 0.3], default: 0.2 },
    },
    render(p, ctx, kids) {
      const r = R4(ctx);
      const d = ctx.device || { bottom: 34 };
      const lib = ctx.screenId === '_lib';
      return `<div style="${lib ? 'position:relative;height:420px;' : 'position:absolute;inset:0;'}z-index:6">
        <div style="position:absolute;inset:0;background:rgba(0,0,0,${p.scrim})"></div>
        <div style="position:absolute;left:0;right:0;bottom:0;top:${lib ? 40 : p.top}px;background:${r.bg};color:${r.ink};border-radius:${p.radius}px ${p.radius}px 0 0;display:flex;flex-direction:column;padding:0 20px ${d.bottom + 12}px;overflow:hidden">${kids({ groundName: 'reading' })}</div></div>`;
    },
  });

  /* ===================== Beats kit (BeatKit.swift) ===================== */
  E({
    type: 'beatPrompt', name: 'Beat prompt', group: 'Beats', source: KIT + ' (BeatPrompt)',
    description: 'The question at the top of most activities: an optional green caption ("Quick check", "Picture it") over 24 pt bold.',
    props: {
      eyebrow: { label: 'Eyebrow', kind: 'text', default: '' },
      text: { label: 'Prompt', kind: 'text', default: '' },
      size: { label: 'Prompt size', kind: 'number', options: [19, 22, 24, 28], unit: ' pt', default: 24, global: true },
    },
    examples: [{ label: 'Quiz', props: { eyebrow: 'Quick check', text: 'A loud craving thought shows up. The bus approach is to…' } }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="display:flex;flex-direction:column;gap:8px;padding-bottom:8px">${p.eyebrow ? T('caption', p.eyebrow, ctx, { color: r.accent }) : ''}${p.text ? `<div style="${F('title', { size: +p.size, weight: 700 })}color:${r.ink}">${esc(p.text)}</div>` : ''}</div>`;
    },
  });

  E({
    type: 'beatOption', name: 'Option row', group: 'Beats', source: KIT + ' (OptionRow)',
    description: 'A radio circle and the option, 16 pt medium, on a raised card (radius 20, min 56 pt). Picked: green tick on soft green with a green edge. A quiz’s wrong pick: a thick grey ring. The rest fade to 50%.',
    props: {
      text: { label: 'Option', kind: 'text', default: '' },
      state: { label: 'State', kind: 'select', default: 'plain', options: [['plain', 'Not answered yet'], ['selected', 'Picked or correct (green)'], ['pick', 'Your pick, not the answer (ring)'], ['dimmed', 'Faded (50%)']] },
      detail: { label: 'Tag under it', kind: 'text', default: '' },
      detailTone: { label: 'Tag colour', kind: 'select', default: 'accent', options: [['accent', 'Green'], ['muted', 'Muted']] },
      radius: { label: 'Corner radius', kind: 'number', options: [14, 18, 20, 24], unit: ' pt', default: 20, global: true },
    },
    examples: [
      { label: 'Correct', props: { text: 'Let it talk, and keep driving', state: 'selected', detail: 'Your pick · correct answer' } },
      { label: 'Your pick', props: { text: 'Argue with it until it stops', state: 'pick', detail: 'Your pick', detailTone: 'muted' } },
    ],
    render(p, ctx, kids) {
      const r = R4(ctx);
      const sel = p.state === 'selected', ring = p.state === 'pick';
      const circle = sel
        ? `<div style="width:24px;height:24px;border-radius:50%;background:${r.accent};display:flex;align-items:center;justify-content:center;flex:none">${Lab.icon('checkmark', 11, r.bg)}</div>`
        : `<div style="width:24px;height:24px;border-radius:50%;box-sizing:border-box;border:${ring ? 6 : 1.5}px solid ${r.faint};flex:none"></div>`;
      const edge = sel ? `1.5px ${r.accent}` : ring ? `1.5px ${r.faint}` : `1px ${r.hairline}`;
      const tag = p.detail ? T('caption', p.detail, ctx, { color: p.detailTone === 'muted' ? r.muted : r.accent }) : '';
      return `<div role="button" style="display:flex;align-items:flex-start;gap:12px;min-height:56px;box-sizing:border-box;padding:14px 16px;border-radius:${p.radius}px;background:${sel ? r.accentSoft : r.card};box-shadow:inset 0 0 0 ${edge.split(' ')[0]} ${edge.split(' ')[1]};opacity:${p.state === 'dimmed' ? 0.5 : 1}">${circle}<div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:4px"><div style="${F('body', { size: 16, weight: 500, lh: 1.5 })}color:${r.ink}">${esc(p.text)}</div>${tag}${kids()}</div></div>`;
    },
  });

  E({
    type: 'beatFeedback', name: 'Feedback panel', group: 'Beats', source: KIT + ' (BeatFeedback)',
    description: 'A green sparkle and a 16 pt line on the reading surface, radius 18, 16 pt padding. Read out to VoiceOver when it appears.',
    props: { text: { label: 'Words', kind: 'text', default: '' }, radius: { label: 'Corner radius', kind: 'number', options: [14, 18, 22], unit: ' pt', default: 18, global: true } },
    examples: [{ label: 'Quiz', props: { text: "Right. It can shout. It can't steer." } }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="display:flex;align-items:flex-start;gap:10px;padding:16px;border-radius:${p.radius}px;background:${r.surface}"><div style="padding-top:3px">${glyph('sparkle', 17, r.accent)}</div><div style="${F('body', { size: 16, weight: 400, lh: 1.5 })}color:${r.ink};flex:1;min-width:0">${esc(p.text)}</div></div>`;
    },
  });

  E({
    type: 'beatChip', name: 'Beat chip', group: 'Beats', source: KIT + ' (BeatChip)',
    description: 'An on/off capsule, 44 pt, 16 pt words. On: soft green with a green edge and semibold words. Faded to 45% when the pick limit is reached.',
    props: {
      text: { label: 'Words', kind: 'text', default: '' },
      on: { label: 'State', kind: 'select', default: false, options: [[false, 'Off'], [true, 'On']] },
      muted: { label: 'Faded (limit reached)', kind: 'bool', labels: ['Yes', 'No'], default: false },
    },
    examples: [{ label: 'On', props: { text: 'Walk outside', on: true } }, { label: 'Off', props: { text: 'Music' } }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div role="button" style="display:inline-flex;align-items:center;min-height:44px;padding:0 16px;border-radius:999px;background:${p.on ? r.accentSoft : r.card};box-shadow:inset 0 0 0 ${p.on ? '1.5px ' + r.accent : '1px ' + r.hairline};${F('body', { size: 16, weight: p.on ? 600 : 500, lh: 1.25 })}color:${r.ink};opacity:${p.muted ? 0.45 : 1}">${esc(p.text)}</div>`;
    },
  });

  E({
    type: 'beatField', name: 'Answer field', group: 'Beats', source: BA + ' (ReflectBeat, ChoiceBeat), ' + BB + ' (PlanBuilderBeat, ShareBeat)',
    description: 'Where people type: a saved list entry (with a remove button), the dashed "add another" field, the multi-line box (green edge when focused), the small inset field of plans, or the share message box.',
    props: {
      kind: { label: 'Kind', kind: 'select', default: 'area', options: [['entry', 'List entry (radius 18, remove button)'], ['add', 'Add to the list (dashed)'], ['area', 'Multi-line box (radius 18)'], ['inline', 'Inset field (radius 14)'], ['message', 'Message box (radius 20, green edge)']] },
      text: { label: 'Typed', kind: 'text', default: '' },
      placeholder: { label: 'Placeholder', kind: 'text', default: '' },
      lines: { label: 'Height in lines', kind: 'number', options: [1, 2, 4, 8], default: 2 },
      focused: { label: 'Focused', kind: 'bool', labels: ['Yes', 'No'], default: false },
    },
    examples: [{ label: 'Add', props: { kind: 'add', placeholder: '“Just one won\'t hurt.”' } }, { label: 'Box', props: { kind: 'area', placeholder: 'I hear you. Still not stopping.' } }],
    render(p, ctx) {
      const r = R4(ctx);
      const k = p.kind;
      const words = p.text ? `<span style="color:${r.ink}">${esc(p.text)}</span>` : `<span style="color:${r.placeholder}">${esc(p.placeholder)}</span>`;
      const font = F('body', { size: 16, weight: k === 'inline' ? 500 : 400, lh: 1.5 });
      if (k === 'entry') return `<div style="display:flex;align-items:center;min-height:54px;padding-left:16px;border-radius:18px;background:${r.card};box-shadow:inset 0 0 0 1px ${r.hairline}"><div style="flex:1;min-width:0;${font}">${words}</div><div role="button" aria-label="Remove" style="width:44px;height:44px;display:flex;align-items:center;justify-content:center;flex:none">${Lab.icon('xmark', 12, r.muted)}</div></div>`;
      if (k === 'add') return `<div style="display:flex;align-items:center;min-height:54px;padding:0 16px;border-radius:18px;border:1.5px dashed ${r.faint};box-sizing:border-box;${font}">${words}</div>`;
      if (k === 'inline') return `<div style="padding:12px;border-radius:14px;background:${r.surface};${font}">${words}</div>`;
      const msg = k === 'message';
      const edge = msg ? `1.5px ${r.accent}` : `1.5px ${p.focused ? r.accent : r.hairline}`;
      return `<div style="padding:16px;border-radius:${msg ? 20 : 18}px;background:${r.card};box-shadow:inset 0 0 0 ${edge};${font}min-height:${(+p.lines) * 24}px;white-space:pre-wrap">${words}</div>`;
    },
  });

  E({
    type: 'beatCard', name: 'Beat card', group: 'Beats', source: BB + ' (note, info, plan builder, plan card)',
    description: 'A raised card with a hairline edge on the reading ground, holding other things. Soft green for Day Xero’s note and saved plans.',
    props: {
      fill: { label: 'Fill', kind: 'select', default: 'card', options: [['card', 'Raised (white)'], ['accentSoft', 'Soft green'], ['surface', 'Reading surface']] },
      hairline: { label: 'Hairline edge', kind: 'bool', labels: ['Show', 'Hide'], default: true },
      radius: { label: 'Corner radius', kind: 'number', options: [18, 20, 22, 24], unit: ' pt', default: 24 },
      padX: { label: 'Side padding', kind: 'number', options: [12, 16, 20, 24], unit: ' pt', default: 20 },
      padY: { label: 'Top and bottom padding', kind: 'number', options: [0, 12, 16, 20, 24], unit: ' pt', default: 20 },
      gap: { label: 'Gap between items', kind: 'number', options: [0, 4, 8, 10, 12, 16], unit: ' pt', default: 12 },
    },
    render(p, ctx, kids) {
      const r = R4(ctx);
      return `<div style="display:flex;flex-direction:column;gap:${p.gap}px;padding:${p.padY}px ${p.padX}px;border-radius:${p.radius}px;background:${r[p.fill] || r.card};${p.hairline ? `box-shadow:inset 0 0 0 1px ${r.hairline};` : ''}">${kids()}</div>`;
    },
  });

  E({
    type: 'beatGlyph', name: 'Beat icon', group: 'Beats', source: BB + ' (InfoBeat)',
    props: {
      icon: { label: 'Icon', kind: 'select', default: 'heart', options: ICONS },
      size: { label: 'Size', kind: 'number', options: [20, 24, 30, 36], unit: ' pt', default: 30 },
      tone: { label: 'Colour', kind: 'select', default: 'accent', options: TONES },
    },
    render(p, ctx) { const r = R4(ctx); return `<div style="line-height:0;align-self:flex-start">${glyph(p.icon, +p.size, tone(r, p.tone), r.bg)}</div>`; },
  });

  E({
    type: 'beatSecondary', name: 'Secondary button (reading)', group: 'Beats', source: V4 + ' (V4SecondaryButtonStyle)',
    description: 'A surface pill, 58 pt, ink words at 16 pt semibold, with an icon. Share, plan the step-down, start the practice.',
    props: { label: { label: 'Words', kind: 'text', default: 'Send it' }, icon: { label: 'Icon', kind: 'select', default: 'share', options: ICONS } },
    examples: [{ label: 'Send it', props: {} }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div role="button" style="display:flex;align-items:center;justify-content:center;gap:8px;min-height:58px;padding:0 18px;border-radius:999px;background:${r.surface};${F('body', { size: 16, weight: 600, lh: 1.25 })}color:${r.ink}">${glyph(p.icon, 17, r.ink)}<span>${esc(p.label)}</span></div>`;
    },
  });

  E({
    type: 'beatLink', name: 'Text button', group: 'Beats', source: BB + ' (PlanBuilderBeat, "Add another plan")',
    props: {
      label: { label: 'Words', kind: 'text', default: 'Add another plan' },
      icon: { label: 'Icon', kind: 'select', default: 'plus', options: ICONS },
      disabled: { label: 'State', kind: 'select', default: false, options: [[false, 'Ready'], [true, 'Not ready yet (50%)']] },
    },
    render(p, ctx) {
      const r = R4(ctx);
      return `<div role="button" style="display:inline-flex;align-self:flex-start;align-items:center;gap:6px;min-height:44px;${F('body', { size: 16, weight: 600, lh: 1.25 })}color:${r.accent};opacity:${p.disabled ? 0.5 : 1}">${glyph(p.icon, 16, r.accent)}<span>${esc(p.label)}</span></div>`;
    },
  });

  /* ---------- stat_reveal, sliders (BeatsA.swift) ---------- */
  E({
    type: 'beatStatLine', name: 'Stat line', group: 'Beats', source: BA + ' (StatRevealBeat)',
    description: 'One line of a stat reveal, 32 pt semibold. The last line is green. Lines arrive one by one, 0.6 s apart.',
    props: {
      text: { label: 'Line', kind: 'text', default: '' },
      accent: { label: 'Colour', kind: 'select', default: false, options: [[false, 'Ink'], [true, 'Green (last line)']] },
      size: { label: 'Size', kind: 'number', options: [24, 28, 32, 36, 40], unit: ' pt', default: 32, global: true },
    },
    examples: [{ label: 'Last line', props: { text: "You're about to take that back.", accent: true } }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="${F('body', { size: +p.size, weight: 600, lh: 1.2 })}color:${p.accent ? r.accent : r.ink}">${esc(p.text)}</div>`;
    },
  });

  function sliderHTML(r, value, minLabel, maxLabel, large) {
    const v = Math.min(10, Math.max(0, +value)), x = v / 10;
    return `<div style="display:flex;flex-direction:column;gap:12px">
      ${large ? `<div style="${F('display', { size: 40, weight: 700, lh: 1.1 })}color:${r.ink};text-align:center;font-variant-numeric:tabular-nums">${v}</div>` : ''}
      <div style="position:relative;height:30px"><div style="position:absolute;left:0;right:0;top:13px;height:4px;border-radius:2px;background:${r.sliderTrack}"></div><div style="position:absolute;left:0;top:13px;height:4px;width:${(x * 100).toFixed(1)}%;border-radius:2px;background:${r.accent}"></div>
        <div style="position:absolute;top:1px;left:calc((100% - 28px) * ${x.toFixed(3)});width:28px;height:28px;border-radius:50%;background:#FFFFFF;box-shadow:0 0.5px 4px rgba(0,0,0,.12),0 6px 13px rgba(0,0,0,.12)"></div></div>
      <div style="display:flex;justify-content:space-between;gap:12px;${F('footnote', { size: 14, weight: 400, lh: 1.3 })}color:${r.muted}"><span>${esc(minLabel)}</span><span style="text-align:right">${esc(maxLabel)}</span></div></div>`;
  }
  E({
    type: 'beatSlider', name: '0–10 slider', group: 'Beats', source: BA + ' (BeatSlider)',
    description: 'The value at 40 pt bold (large), a green-tinted slider with a haptic per step, and the end labels at 14 pt.',
    props: {
      value: { label: 'Value', kind: 'number', options: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], default: 5 },
      large: { label: 'Big number on top', kind: 'bool', labels: ['Show', 'Hide'], default: true },
      minLabel: { label: 'Left label', kind: 'text', default: '' },
      maxLabel: { label: 'Right label', kind: 'text', default: '' },
    },
    examples: [{ label: 'P2.2', props: { minLabel: 'A real choice', maxLabel: "I don't even notice it" } }],
    render(p, ctx) { return `<div>${sliderHTML(R4(ctx), p.value, p.minLabel, p.maxLabel, p.large)}</div>`; },
  });

  E({
    type: 'beatSliderCard', name: 'Slider card', group: 'Beats', source: BA + ' (SliderGroupBeat)',
    description: 'One slider of a group: its name (16 pt semibold) and value (24 pt bold) over the slider, on a raised card, radius 20.',
    props: {
      label: { label: 'Name', kind: 'text', default: '' },
      value: { label: 'Value', kind: 'number', options: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], default: 5 },
      minLabel: { label: 'Left label', kind: 'text', default: '' },
      maxLabel: { label: 'Right label', kind: 'text', default: '' },
    },
    examples: [{ label: 'Cravings', props: { label: 'Cravings', minLabel: 'None', maxLabel: 'Constant' } }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="display:flex;flex-direction:column;gap:8px;padding:16px;border-radius:20px;background:${r.card};box-shadow:inset 0 0 0 1px ${r.hairline}">
        <div style="display:flex;align-items:baseline;justify-content:space-between;gap:8px;color:${r.ink}"><span style="${F('body', { size: 16, weight: 600, lh: 1.3 })}">${esc(p.label)}</span><span style="${F('title', { size: 24, weight: 700, lh: 1.1 })}font-variant-numeric:tabular-nums">${esc(p.value)}</span></div>
        ${sliderHTML(r, p.value, p.minLabel, p.maxLabel, false)}</div>`;
    },
  });

  E({
    type: 'beatCompare', name: 'Before and after', group: 'Beats', source: BA + ' (CompareValues)',
    description: 'Two boxes side by side: the earlier value on the surface, the new one on soft green, each a caption over 40 pt. No comment on the difference.',
    props: {
      firstLabel: { label: 'First label', kind: 'text', default: 'Before' },
      first: { label: 'First value', kind: 'number', options: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], default: 6 },
      secondLabel: { label: 'Second label', kind: 'text', default: 'After' },
      second: { label: 'Second value', kind: 'number', options: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], default: 3 },
    },
    examples: [{ label: 'Before, after', props: {} }],
    render(p, ctx) {
      const r = R4(ctx);
      const box = (label, v, hi) => `<div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:8px;padding:16px;border-radius:22px;background:${hi ? r.accentSoft : r.surface}">${T('caption', label, ctx, { color: hi ? r.accent : r.muted })}<div style="${F('display', { size: 40, weight: 700, lh: 1.1 })}color:${r.ink}">${esc(v)}</div></div>`;
      return `<div style="display:flex;gap:12px">${box(p.firstLabel, p.first, false)}${box(p.secondLabel, p.second, true)}</div>`;
    },
  });

  E({
    type: 'beatEnds', name: 'End labels', group: 'Beats', source: BA + ' (SliderBeat, comparing)',
    description: '"0 · …" and "10 · …" under the comparison, as 14 pt muted words.',
    props: { left: { label: 'Left', kind: 'text', default: '' }, right: { label: 'Right', kind: 'text', default: '' } },
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="display:flex;justify-content:space-between;gap:12px;${F('footnote')}color:${r.muted}"><span>${esc(p.left)}</span><span style="text-align:right">${esc(p.right)}</span></div>`;
    },
  });

  /* ---------- reflect, tap_reveal (BeatsA.swift) ---------- */
  E({
    type: 'beatGuidePill', name: 'Writing prompt pill', group: 'Beats', source: BA + ' (ReflectBeat.guidePrompts)',
    description: 'A small idea to write about: 14 pt muted on a surface capsule. Not tappable.',
    props: { text: { label: 'Words', kind: 'text', default: '' } },
    examples: [{ label: 'Prompt', props: { text: 'What was hardest?' } }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="display:inline-flex;padding:6px 10px;border-radius:999px;background:${r.surface};${F('footnote', { size: 14, weight: 400, lh: 1.3 })}color:${r.muted}">${esc(p.text)}</div>`;
    },
  });

  E({
    type: 'beatFlipCard', name: 'Flip card', group: 'Beats', source: BA + ' (FlipCard)',
    description: 'Front: the thought at 19 pt with "Tap to flip", on a raised card. Back: the front as a green caption over the answer, on soft green. Radius 22, min 120 pt. Turns over in 3D (cross-fades under Reduce Motion).',
    props: {
      front: { label: 'Front', kind: 'text', default: '' },
      back: { label: 'Back', kind: 'text', default: '' },
      side: { label: 'Showing', kind: 'select', default: 'front', options: [['front', 'Front'], ['back', 'Back (flipped)']] },
      hint: { label: 'Hint', kind: 'text', default: 'Tap to flip' },
      radius: { label: 'Corner radius', kind: 'number', options: [18, 20, 22, 24], unit: ' pt', default: 22, global: true },
      minHeight: { label: 'Minimum height', kind: 'number', options: [96, 120, 140], unit: ' pt', default: 120, global: true },
    },
    examples: [{ label: 'Front', props: { front: '“It calms me down”', back: 'It settles the restlessness that builds between doses. The stress itself is still there.' } }, { label: 'Back', props: { side: 'back', front: '“It calms me down”', back: 'It settles the restlessness that builds between doses. The stress itself is still there.' } }],
    render(p, ctx) {
      const r = R4(ctx);
      const back = p.side === 'back';
      const inner = back
        ? `${T('caption', p.front, ctx, { color: r.accent })}<div style="${F('body', { size: 16, weight: 400, lh: 1.5 })}color:${r.ink}">${esc(p.back)}</div>`
        : `<div style="${F('headline', { size: 19, weight: 600, lh: 1.25 })}color:${r.ink}">${esc(p.front)}</div><div style="display:flex;align-items:center;gap:6px">${glyph('flip', 15, r.muted)}<span style="${F('footnote', { size: 14, weight: 400 })}color:${r.muted}">${esc(p.hint)}</span></div>`;
      return `<div role="button" style="display:flex;flex-direction:column;gap:8px;min-height:${p.minHeight}px;box-sizing:border-box;padding:16px;border-radius:${p.radius}px;background:${back ? r.accentSoft : r.card};${back ? '' : `box-shadow:inset 0 0 0 1px ${r.hairline};`}">${inner}</div>`;
    },
  });

  /* ---------- plan_builder, checklist, breathe (BeatsB.swift) ---------- */
  E({
    type: 'beatPlanLine', name: 'Saved plan', group: 'Beats', source: BB + ' (PlanBuilderBeat)',
    description: 'A plan already added: "Plan 1" in green over the if-then line, with a remove button, on soft green, radius 18.',
    props: { kicker: { label: 'Kicker', kind: 'text', default: 'Plan 1' }, text: { label: 'Plan', kind: 'text', default: '' } },
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="display:flex;align-items:flex-start;padding:16px;border-radius:18px;background:${r.accentSoft}"><div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:4px">${T('caption', p.kicker, ctx, { color: r.accent })}<div style="${F('body', { size: 16, weight: 400 })}color:${r.ink}">${esc(p.text)}</div></div><div style="width:44px;height:44px;display:flex;align-items:center;justify-content:center;flex:none">${Lab.icon('xmark', 12, r.muted)}</div></div>`;
    },
  });

  E({
    type: 'beatCheckRow', name: 'Checklist row', group: 'Beats', source: BB + ' (ChecklistBeat.row)',
    description: 'A 26 pt rounded box (radius 8) and the item at 16 pt, on a raised card, radius 18. Ticked: green box, white tick, the words go muted.',
    props: {
      text: { label: 'Item', kind: 'text', default: '' },
      on: { label: 'State', kind: 'select', default: false, options: [[false, 'Not done'], [true, 'Ticked']] },
      boxRadius: { label: 'Box corners', kind: 'number', options: [6, 8, 13], unit: ' pt', default: 8, global: true },
    },
    examples: [{ label: 'Not done', props: { text: 'Out of the car' } }, { label: 'Ticked', props: { text: 'Pack and lighter out of my pocket', on: true } }],
    render(p, ctx) {
      const r = R4(ctx);
      const box = p.on
        ? `<div style="width:26px;height:26px;border-radius:${p.boxRadius}px;background:${r.accent};display:flex;align-items:center;justify-content:center;flex:none">${Lab.icon('checkmark', 13, r.bg)}</div>`
        : `<div style="width:26px;height:26px;border-radius:${p.boxRadius}px;box-sizing:border-box;border:1.5px solid ${r.faint};flex:none"></div>`;
      return `<div role="button" style="display:flex;align-items:center;gap:14px;min-height:56px;box-sizing:border-box;padding:12px 16px;border-radius:18px;background:${r.card};box-shadow:inset 0 0 0 1px ${r.hairline}">${box}<div style="${F('body', { size: 16, weight: 500 })}color:${p.on ? r.muted : r.ink};flex:1;min-width:0">${esc(p.text)}</div></div>`;
    },
  });

  E({
    type: 'beatAmberNote', name: 'Amber note', group: 'Beats', source: BB + ' (ChecklistBeat footer)',
    description: 'A battery icon and a 14 pt line on 18% amber, radius 16. The vaping clear-out’s battery recycling note.',
    props: { text: { label: 'Words', kind: 'text', default: '' } },
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="display:flex;align-items:flex-start;gap:10px;padding:12px;border-radius:16px;background:rgba(${r.amberRGB},0.18)"><div style="padding-top:1px">${glyph('battery', 18, r.amber)}</div><div style="${F('footnote', { size: 14, weight: 400 })}color:${r.ink};flex:1;min-width:0">${esc(p.text)}</div></div>`;
    },
  });

  E({
    type: 'beatOrbPanel', name: 'Breathing panel', group: 'Beats', source: BB + ' (BreatheBeat), DayXero/Orb/OrbBreathingPanel.swift',
    description: 'The Bio-Orb’s black canvas, always dark, clipped to radius 28 under the beat’s line. Holds the pattern, the orb, the coach’s caption and the buttons.',
    props: { radius: { label: 'Corner radius', kind: 'number', options: [20, 24, 28, 32], unit: ' pt', default: 28, global: true } },
    render(p, ctx, kids) {
      return `<div style="flex:1;display:flex;flex-direction:column;align-items:center;gap:24px;padding:12px 0 16px;border-radius:${p.radius}px;background:#000000;overflow:hidden;text-align:center">${kids({ groundName: 'reading', dark: true })}</div>`;
    },
  });

  /* ---------- note, info, share, NRT, plan card (BeatsB.swift) ---------- */
  E({
    type: 'beatHelpLine', name: 'Help line (full)', group: 'Beats', source: 'DayXero/Calm/CalmToolsView.swift (HelpLine)',
    description: 'Where to get professional help, inside a dashed box (radius 18): a 14 pt muted line and an underlined green link.',
    props: {
      text: { label: 'Words', kind: 'text', default: 'If stress or anxiety is getting in the way of everyday life, talk to a doctor or a mental health professional. In a crisis, call your local emergency number.' },
      link: { label: 'Link', kind: 'text', default: 'Find a helpline near you' },
    },
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="display:flex;flex-direction:column;gap:6px;padding:12px;border-radius:18px;border:1px dashed ${r.faint}">${T('footnote', p.text, ctx, { color: r.muted })}<div role="link" style="${F('footnote', { size: 14, weight: 400 })}color:${r.accent};text-decoration:underline">${esc(p.link)}</div></div>`;
    },
  });

  E({
    type: 'beatSafetyNote', name: 'Safety note', group: 'Beats', source: BB + ' (SafetyNote)',
    description: 'An info icon and the product-label safety line, 14 pt muted on the surface, radius 18. Always showing.',
    props: { text: { label: 'Words', kind: 'text', default: '' } },
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="display:flex;align-items:flex-start;gap:10px;padding:16px;border-radius:18px;background:${r.surface}"><div style="padding-top:1px">${Lab.icon('info.circle', 17, r.muted)}</div><div style="${F('footnote', { size: 14, weight: 400 })}color:${r.muted};flex:1;min-width:0">${esc(p.text)}</div></div>`;
    },
  });

  E({
    type: 'beatShareCard', name: 'Share card', group: 'Beats', source: 'DayXero/Milestones/MilestoneViews.swift (ShareCard), ' + BB + ' (ShareBeat)',
    description: 'The milestone card as it will be shared, shown 260 pt wide (laid out at 1080): the wordmark, Xero cheering on the apricot dawn, the number of days and "days nicotine-free". Nothing personal on it.',
    props: {
      days: { label: 'Days', kind: 'select', default: 7, options: [[7, '7'], [14, '14'], [21, '21'], [30, '30']] },
      look: { label: 'Look', kind: 'select', default: 'dawn', options: [['dawn', 'Dawn (Xero on apricot)'], ['night', 'Night (Glim on violet)']] },
      width: { label: 'Width on screen', kind: 'number', options: [200, 240, 260, 300], unit: ' pt', default: 260 },
      radius: { label: 'Corner radius', kind: 'number', options: [18, 24, 28], unit: ' pt', default: 24 },
      extra: { label: 'Line from your note', kind: 'text', default: '' },
    },
    examples: [{ label: '7 days', props: {} }],
    render(p) {
      const w = +p.width, k = w / 1080, days = +p.days;
      const dawn = p.look !== 'night';
      const bg = dawn ? '#FFC38A' : '#4A3596', ink = dawn ? Lab.NAVY : Lab.CREAM;
      const clarity = Math.min(100, Math.round(20 + 2.8 * days));
      const stage = days < 7 ? 1 : days < 14 ? 2 : days < 28 ? 3 : 4;
      const sky = Lab.art('scene:horizon:' + (dawn ? 'dawn' : 'night'), { width: w, height: Math.round(760 * k), animate: false, scene: { clarity, fit: 'bottom' } });
      const ch = Math.round(420 * k);
      const crew = Lab.art((dawn ? 'xero:cheer' : 'glim:calm'), { size: ch, stage, animate: false });
      const pad = 100 * k;
      return `<div role="img" aria-label="Share card: ${days} days nicotine-free" style="position:relative;width:${w}px;height:${w}px;align-self:center;border-radius:${p.radius}px;overflow:hidden;background:${bg};line-height:0;flex:none">
        <div style="position:absolute;left:0;top:0;right:0">${sky}</div>
        <div style="position:absolute;inset:0;padding:${pad}px;display:flex;flex-direction:column;color:${ink};line-height:1">
          <div style="${F('display', { size: Math.max(12, Math.round(64 * k)), weight: 800, lh: 1, family: 'display' })}">DayXero</div>
          <div style="flex:1"></div>
          <div style="align-self:center;width:${ch}px;height:${ch}px">${crew}</div>
          <div style="${F('display', { size: Math.round(380 * k * 0.6), weight: 800, lh: 0.95, family: 'display' })}">${days}</div>
          <div style="${F('headline', { size: Math.max(12, Math.round(72 * k)), weight: 700, lh: 1.1, family: 'display' })}">${days === 1 ? 'day nicotine-free' : 'days nicotine-free'}</div>
          ${p.extra ? `<div style="${F('body', { size: Math.max(12, Math.round(46 * k)), weight: 500, lh: 1.2 })}opacity:.85;padding-top:${Math.round(36 * k)}px">${esc(p.extra)}</div>` : ''}
        </div></div>`;
    },
  });

  E({
    type: 'beatPlanRow', name: 'Plan card row', group: 'Beats', source: BB + ' (PlanCardBeat)',
    description: 'One part of your plan: its heading as a green caption over your words, with a pencil to edit text and lists. A hairline divides the rows.',
    props: {
      heading: { label: 'Heading', kind: 'text', default: '' },
      editable: { label: 'Pencil', kind: 'bool', labels: ['Show', 'Hide'], default: true },
      divider: { label: 'Hairline above', kind: 'bool', labels: ['Show', 'Hide'], default: false },
    },
    render(p, ctx, kids) {
      const r = R4(ctx);
      return `<div style="display:flex;align-items:flex-start;padding:12px 0;${p.divider ? `border-top:0.5px solid ${r.faint};` : ''}"><div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:3px">${T('caption', p.heading, ctx, { color: r.accent })}${kids()}</div>${p.editable ? `<div role="button" aria-label="Edit ${esc(p.heading)}" style="width:44px;height:44px;display:flex;align-items:center;justify-content:center;flex:none">${glyph('pencil', 18, r.muted)}</div>` : ''}</div>`;
    },
  });

  /* ===================== Lesson audio (LessonAudio.swift) ===================== */
  E({
    type: 'lessonBreathRing', name: 'Xero breath ring', group: 'Lessons', source: AUDIO + ' (XeroBreathRing)',
    description: 'Xero (140 pt) inside a soft green disc and a 3 pt green ring that breathe on the 4 s in, 6 s out clock while the audio plays. 200 pt tall.',
    props: {
      breath: { label: 'Breath', kind: 'select', default: 0.4, options: [[0, 'Out (0)'], [0.4, 'Resting (0.4, not playing)'], [1, 'In (1)']] },
      mood: { label: 'Xero', kind: 'art', default: 'xero:calm' },
      height: { label: 'Height', kind: 'number', options: [160, 180, 200, 220], unit: ' pt', default: 200 },
    },
    examples: [{ label: 'Resting', props: {} }],
    render(p, ctx) {
      const r = R4(ctx);
      const b = +p.breath, disc = 168 + 28 * b, ring = 192 + 28 * b;
      return `<div style="position:relative;height:${p.height}px;display:flex;align-items:center;justify-content:center;line-height:0">
        <div style="position:absolute;width:${disc}px;height:${disc}px;border-radius:50%;background:${r.accentSoft}"></div>
        <div style="position:absolute;width:${ring}px;height:${ring}px;border-radius:50%;box-sizing:border-box;border:3px solid ${r.accent};opacity:.35"></div>
        <div style="position:relative;width:140px;height:140px">${Lab.art(p.mood, { size: 140 })}</div></div>`;
    },
  });

  E({
    type: 'lessonScrubber', name: 'Audio scrubber', group: 'Lessons', source: AUDIO + ' (LessonAudioStep.scrubber)',
    description: 'A 4 pt track with an ink fill and a 14 pt knob, then the time gone and the time left at 12 pt semibold.',
    props: {
      elapsed: { label: 'Time gone', kind: 'text', default: '1:05' },
      remaining: { label: 'Time left', kind: 'text', default: '1:55' },
      fraction: { label: 'Position', kind: 'number', options: [0, 0.1, 0.25, 0.36, 0.5, 0.75, 1], default: 0.36 },
    },
    render(p, ctx) {
      const r = R4(ctx);
      const f = Math.min(1, Math.max(0, +p.fraction));
      return `<div style="display:flex;flex-direction:column;gap:6px;align-self:stretch">
        <div style="position:relative;height:24px"><div style="position:absolute;left:0;right:0;top:10px;height:4px;border-radius:2px;background:${r.track}"></div><div style="position:absolute;left:0;top:10px;height:4px;width:${(f * 100).toFixed(1)}%;border-radius:2px;background:${r.ink}"></div><div style="position:absolute;top:5px;left:calc(${(f * 100).toFixed(1)}% - 7px);width:14px;height:14px;border-radius:50%;background:${r.ink}"></div></div>
        <div style="display:flex;justify-content:space-between;${F('caption', { size: 12, weight: 600 })}color:${r.muted};font-variant-numeric:tabular-nums"><span>${esc(p.elapsed)}</span><span>${esc(p.remaining)}</span></div></div>`;
    },
  });

  E({
    type: 'lessonControls', name: 'Audio controls', group: 'Lessons', source: AUDIO + ' (LessonAudioStep.controls)',
    description: 'Speed on a surface capsule (1.0×, 1.25×, 0.8×), back 15, a 60 pt ink play or pause button, forward 15.',
    props: {
      speed: { label: 'Speed', kind: 'text', default: '1.0×' },
      playing: { label: 'Middle button', kind: 'select', default: true, options: [[true, 'Pause (playing)'], [false, 'Play (paused)']] },
    },
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="display:flex;align-items:center;align-self:stretch">
        <div role="button" aria-label="Speed" style="min-width:52px;min-height:34px;padding:0 8px;box-sizing:border-box;border-radius:999px;background:${r.surface};display:flex;align-items:center;justify-content:center;${F('footnote', { size: 14, weight: 600 })}color:${r.ink}">${esc(p.speed)}</div>
        <div style="flex:1"></div>
        <div role="button" aria-label="Back 15 seconds" style="width:48px;height:48px;display:flex;align-items:center;justify-content:center">${glyph('back15', 26, r.ink)}</div>
        <div style="padding:0 12px"><div role="button" style="width:60px;height:60px;border-radius:50%;background:${r.ink};display:flex;align-items:center;justify-content:center">${Lab.icon(p.playing ? 'pause.fill' : 'play.fill', 22, r.bg, p.playing ? '' : 'margin-left:2px')}</div></div>
        <div role="button" aria-label="Forward 15 seconds" style="width:48px;height:48px;display:flex;align-items:center;justify-content:center">${glyph('fwd15', 26, r.ink)}</div>
        <div style="flex:1"></div><div style="width:52px;height:34px"></div></div>`;
    },
  });

  E({
    type: 'lessonCaptions', name: 'Captions', group: 'Lessons', source: AUDIO + ' (LessonAudioStep.captions)',
    description: 'The transcript as centred lines that rise and fade out at the top and bottom; the line being spoken sits in the middle. At least 180 pt tall.',
    props: { minHeight: { label: 'Minimum height', kind: 'number', options: [140, 180, 220], unit: ' pt', default: 180 } },
    render(p, ctx, kids) {
      const mask = 'linear-gradient(to bottom, transparent 0, #000 24%, #000 76%, transparent 100%)';
      return `<div style="flex:1;min-height:${p.minHeight}px;align-self:stretch;display:flex;flex-direction:column;justify-content:center;gap:16px;-webkit-mask-image:${mask};mask-image:${mask}">${kids()}</div>`;
    },
  });

  E({
    type: 'lessonCaption', name: 'Caption line', group: 'Lessons', source: AUDIO + ' (LessonAudioStep.captions)',
    description: 'One sentence of the transcript, 24 pt, centred. Bold and full strength while spoken; 45%, 20% and 8% as it moves away. Tap to play from it.',
    props: {
      text: { label: 'Sentence', kind: 'text', default: '' },
      distance: { label: 'Lines from the one spoken', kind: 'select', default: 0, options: [[0, 'Being spoken'], [1, 'Next to it (45%)'], [2, 'Two away (20%)'], [3, 'Further (8%)']] },
    },
    render(p, ctx) {
      const r = R4(ctx);
      const d = +p.distance;
      return `<div role="button" style="${F('title', { size: 24, weight: d === 0 ? 700 : 500, lh: 1.3, tracking: -0.3 })}color:${r.ink};opacity:${[1, 0.45, 0.2, 0.08][Math.min(d, 3)]};text-align:center">${esc(p.text)}</div>`;
    },
  });

  /* ===================== Content (program.json) ===================== */
  // Sam: Quit Day Fri 6 Nov, 12 cigarettes a day at $7, smoking variant, one reason, no NRT plan.
  const REASON = 'To keep up with Maya at the park';
  const W1D2 = {
    label: 'Day 2', title: 'The noisy passengers', subtitle: 'Let them talk. Keep driving.', minutes: 3,
    mission: 'Name one passenger today when it shows up.', completion: "They can shout. They can't drive.",
    quiz: { prompt: 'A loud craving thought shows up. The bus approach is to…', options: [['a', 'Argue with it until it stops'], ['b', 'Let it talk, and keep driving'], ['c', 'Pull over and give it what it wants']], correct: 'b', feedback: "Right. It can shout. It can't steer." },
  };
  const SAFETY = "Follow the product label. If you're pregnant, have a heart condition or take other medicines, check with a pharmacist or doctor first.";
  const NEXT_ALTS = ['Next: Day 3 · Lower the bar, ready now', 'Next: Prep 2 · The first one of the day, tomorrow', 'Day Xero is Fri 6 Nov'];

  /* ---------- Builders ---------- */
  /** The session canvas: lesson bar (unless it's the completion step), then the step's column. */
  function flow(h, o) {
    return h('sessionFrame', 'frame', { ground: o.ground || 'reading' }, [
      o.header === false ? null : h('sessionHeader', 'lesson-bar', { step: o.step, total: o.total, replay: !!o.replay }),
      h('stack', 'step', { gap: o.gap != null ? o.gap : 8, style: 'flex:1 1 auto;min-height:0' }, o.body),
    ]);
  }
  /** BeatFrame: the content (scrolls in the app, 16 pt under it), Continue, and Skip on optional beats. */
  function frame(h, content, o) {
    o = o || {};
    return [
      h('stack', 'content', { gap: o.gap != null ? o.gap : 10, padBottom: 16, style: 'flex:1 0 auto' }, content),
      h('button', 'continue', { label: o.cont || 'Continue', disabled: !!o.disabled, alts: o.contAlts ? { label: o.contAlts } : undefined }),
      o.skip ? h('button', 'skip', { label: 'Skip', kind: 'quiet' }) : null,
    ];
  }
  const prompt = (h, text, eyebrow, id) => h('beatPrompt', id || 'prompt', { text, eyebrow: eyebrow || '' });
  const subtitle = (h, id, text, extra) => h('text', id, Object.assign({ step: 'footnote', tone: 'muted', text }, extra || {}));
  const feedback = (h, text, id) => h('stack', (id || 'feedback') + '-wrap', { padTop: 8 }, [h('beatFeedback', id || 'feedback', { text })]);
  const options = (h, list, stateOf, detailOf) => list.map(([id, text]) => {
    const d = detailOf ? detailOf(id) : null;
    return h('beatOption', 'option-' + id, { text, state: stateOf ? stateOf(id) : 'plain', detail: d ? d[0] : '', detailTone: d ? d[1] : 'accent' });
  });
  const chips = (h, id, list, onOf, mutedOf) => h('row', id, { gap: 8, wrap: true, align: 'flex-start' }, list.map((t, i) => h('beatChip', id + '-' + i, { text: t, on: !!(onOf && onOf(t)), muted: !!(mutedOf && mutedOf(t)) })));

  /* ---------- Steps of a session (SessionFlowView) ---------- */
  function introStep(h, s) {
    return [
      h('stack', 'intro', { gap: 10, style: 'flex:1 0 auto' }, [
        h('stack', 'scene-wrap', { padBottom: 12 }, [h('sessionScene', 'scene', { scene: 'path', clarity: s.clarity, character: 'xero:hello', lift: 4 })]),
        h('text', 'eyebrow', { step: 'caption', tone: 'muted', text: s.eyebrow }),
        h('text', 'title', { step: 'large', text: s.title }),
        h('text', 'subtitle', { step: 'body', tone: 'muted', text: s.subtitle }),
        h('sessionIconLabel', 'length', { icon: 'headphones', text: `${s.minutes} min · Audio, activities and today's mission` }),
        s.hint ? h('stack', 'hint-wrap', { padTop: 8 }, [h('sessionIconLabel', 'hint', { icon: 'clock', text: s.hint, card: 'raised' })]) : null,
      ]),
      h('button', 'begin', { label: s.replay ? 'Replay' : 'Begin', alts: { label: s.replay ? ['Begin'] : ['Replay'] } }),
    ];
  }
  function soonStep(h, title) {
    return [h('stack', 'soon', { gap: 16, align: 'center', textAlign: 'center', style: 'flex:1 1 auto' }, [
      h('text', 'audio-title', { step: 'title', align: 'center', text: title }),
      h('lessonBreathRing', 'ring', {}),
      h('sessionSoonPill', 'soon-pill', {}),
      h('text', 'soon-text', { step: 'footnote', tone: 'muted', align: 'center', text: 'The guided audio for this session is on its way. Everything after it works now, so carry on.' }),
      h('spacer', 'soon-space', { flex: true, size: 0 }),
      h('button', 'continue', { label: 'Continue' }),
    ])];
  }
  function missionStep(h, text, followUp) {
    const a = 'It stays on your Today card until the next session.';
    const b = "When you log it, we'll ask two quick questions. It stays on your Today card until the next session.";
    return [
      h('spacer', 'mission-top', { flex: true, size: 0 }),
      h('sessionMissionCard', 'mission', { text, note: followUp ? b : a, alts: { note: [followUp ? a : b] } }),
      h('spacer', 'mission-bottom', { flex: true, size: 0 }),
      h('button', 'got-it', { label: 'Got it' }),
    ];
  }
  function lessonDoneStep(h, s) {
    return [
      h('stack', 'done', { gap: 10, align: 'center', textAlign: 'center', style: 'flex:1 0 auto' }, [
        h('stack', 'scene-wrap', { padTop: 16, style: 'align-self:stretch' }, [h('sessionScene', 'scene', { scene: 'path', clarity: s.clarity, character: 'xero:calm', lift: 4 })]),
        h('stack', 'done-label-wrap', { padTop: 12 }, [h('text', 'done-label', { step: 'caption', tone: 'muted', text: `${s.label} done` })]),
        h('text', 'completion', { step: 'large', align: 'center', text: s.completion }),
        s.next ? h('stack', 'next-wrap', { padTop: 12, style: 'align-self:stretch' }, [h('sessionIconLabel', 'next', { icon: 'calendar', text: s.next, card: 'raised', alts: { text: NEXT_ALTS.filter((x) => x !== s.next) } })]) : null,
      ]),
      h('button', 'done-button', { label: 'Done' }),
    ];
  }

  /* ---------- Beat bodies ---------- */
  function quizBody(h, q, picked, o) {
    o = o || {};
    const stateOf = (id) => (!picked ? 'plain' : id === q.correct ? 'selected' : id === picked ? 'pick' : 'dimmed');
    const detailOf = (id) => {
      if (!picked) return null;
      if (id === q.correct) return [id === picked ? 'Your pick · correct answer' : 'Correct answer', 'accent'];
      if (id === picked) return ['Your pick', 'muted'];
      return null;
    };
    return frame(h, [
      prompt(h, q.prompt, 'Quick check'),
      ...options(h, q.options, stateOf, detailOf),
      picked && q.feedback ? feedback(h, q.feedback) : null,
    ], { disabled: !picked, skip: o.optional });
  }

  /* ===================== Screen: the W1D2 session, step by step ===================== */
  const W = W1D2;
  const S_STATES = [
    { id: 'intro', label: '1 · Intro' },
    { id: 'audio', label: '2 · Audio (coming soon)' },
    { id: 'W1D2.1', label: '3 · W1D2.1 Reflect (list)' },
    { id: 'W1D2.2', label: '4 · W1D2.2 Reflect' },
    { id: 'W1D2.3', label: '5 · W1D2.3 Quiz' },
    { id: 'W1D2.3-answered', label: '5 · W1D2.3 Quiz, answered' },
    { id: 'mission', label: '6 · Mission' },
    { id: 'done', label: '7 · Day 2 done' },
  ];
  Lab.screen({
    id: 'session', name: 'Session · The noisy passengers', area: 'Sessions', source: FLOW + ', ' + BA, ground: 'reading', fullBleed: true,
    note: 'W1D2 "The noisy passengers", opened by Sam on Sun 8 Nov (2 days after Day Xero, so it is open). Seven steps: intro, audio, three activities, mission, done; the lesson bar counts them. No recordings are in the app yet, so the audio step is "Audio coming soon" (see "Lesson audio" for the player). Sam’s own answers are not known, so the reflect fields show their placeholders; in the answered quiz Sam picks the right answer. The eyebrow’s date format follows the comment in SessionIntro ("SUN 8 NOV · DAY 2"). The sky clarity is 28 (3 days clear).',
    states: S_STATES,
    build(h, state) {
      const id = state.id;
      const total = 7;
      if (id === 'intro') return flow(h, { step: 1, total, gap: 16, body: introStep(h, { clarity: 28, eyebrow: 'SUN 8 NOV · DAY 2', title: W.title, subtitle: W.subtitle, minutes: W.minutes }) });
      if (id === 'audio') return flow(h, { step: 2, total, gap: 12, body: soonStep(h, W.title) });
      if (id === 'W1D2.1') return flow(h, { step: 3, total, body: frame(h, [
        prompt(h, 'What do your loudest passengers say?'),
        subtitle(h, 'count', '0 of 3', { alts: { text: ['1 of 3', '2 of 3', '3 of 3'] } }),
        h('beatField', 'add', { kind: 'add', placeholder: '“Just one won\'t hurt.”' }),
      ]) });
      if (id === 'W1D2.2') return flow(h, { step: 4, total, body: frame(h, [
        prompt(h, 'What do you say back, calmly, while you keep driving?'),
        h('beatField', 'answer', { kind: 'area', placeholder: 'I hear you. Still not stopping.', lines: 2 }),
        subtitle(h, 'counter', '0 / 140', { align: 'right' }),
      ]) });
      if (id === 'W1D2.3' || id === 'W1D2.3-answered') return flow(h, { step: 5, total, body: quizBody(h, W.quiz, id === 'W1D2.3' ? null : 'b') });
      if (id === 'mission') return flow(h, { step: 6, total, gap: 16, body: missionStep(h, W.mission, false) });
      return flow(h, { header: false, gap: 16, body: lessonDoneStep(h, { clarity: 28, label: W.label, completion: W.completion, next: 'Next session on Day 3' }) });
    },
  });

  /* ===================== Screen: every beat type, filled from a session that uses it ===================== */
  const P14 = { prompt: 'A lot of the relief from nicotine comes from…', options: [['a', "It adds something extra that non-users don't have"], ['b', 'It settles the restlessness left by the last dose'], ['c', 'The flavour or the ritual']], correct: 'b', feedback: "Right. That's the battery. You'll start spotting it everywhere this week." };
  const P44 = [
    ['“It calms me down”', 'It settles the restlessness that builds between doses. The stress itself is still there.'],
    ['“I need it when things get hard”', 'You need a break when things get hard. You can keep the break.'],
    ['“Quitting will make me more stressed”', 'It can feel that way in the first days. Over time, many people who quit feel calmer than before.'],
  ];
  const LIFTS = ['Walk outside', 'Music', 'Call a friend', 'Cold water on my face', 'A shower', 'Cook something', 'Daylight', 'Exercise', 'Something creative', 'A game'];
  const KIT_STATES = [
    ['stat', 'stat_reveal · P1.1'],
    ['quiz', 'quiz · P1.4'],
    ['quiz-answered', 'quiz · P1.4, answered'],
    ['choice', 'choice (one) · P2.1'],
    ['choice-multi', 'choice (pick 3) · W1D4.1'],
    ['slider', 'slider · P2.2'],
    ['slider-compare', 'slider (compare) · P4.2'],
    ['slider-group', 'slider_group · W1D1.1'],
    ['reflect-list', 'reflect (list) · P1.2'],
    ['reflect-long', 'reflect (long) · W4S3.2'],
    ['reflect-chips', 'reflect (chips) · W1D7.2'],
    ['flip', 'tap_reveal · P4.4'],
    ['flip-turned', 'tap_reveal · P4.4, one flipped'],
    ['plan-builder', 'plan_builder · W1D3.2'],
    ['checklist', 'checklist · P6.1'],
    ['checklist-carry', 'checklist (carry-over) · P7.1'],
    ['checklist-footer', 'checklist (vaping footer) · P7.1'],
    ['breathe', 'breathe · P4.3'],
    ['commit', 'commit · P1.5'],
    ['commit-done', 'commit · P1.5, replay'],
    ['commit-dayxero', 'commit (Day Xero) · DX.2'],
    ['scenario', 'scenario · W1D5.1'],
    ['note', 'note · W1D3.1'],
    ['info', 'info · W3S1.5'],
    ['share-message', 'share (message) · P6.4'],
    ['share-card', 'share (card) · W1D7.3'],
    ['nrt-choice', 'nrt_choice · P6.3'],
    ['nrt-stepdown', 'nrt_stepdown · W4S1.2'],
    ['slip-practice', 'slip_debrief_practice · W4S2.1'],
    ['plan-card', 'plan_card · W4S3.3'],
  ];

  const KIT_BUILD = {
    stat: (h) => ({ step: 3, total: 9, body: frame(h, [
      h('stack', 'lines', { gap: 20, padTop: 32 }, [
        h('beatStatLine', 'line-1', { text: "At your current pace, that's about 4,380 cigarettes a year." }),
        h('beatStatLine', 'line-2', { text: 'Roughly $2,555.' }),
        h('beatStatLine', 'line-3', { text: "You're about to take that back.", accent: true }),
      ]),
    ]) }),
    quiz: (h) => ({ step: 6, total: 9, body: quizBody(h, P14, null) }),
    'quiz-answered': (h) => ({ step: 6, total: 9, body: quizBody(h, P14, 'a') }),
    choice: (h) => ({ step: 3, total: 7, body: frame(h, [
      prompt(h, 'Which moment will you put a gap after?'),
      ...options(h, [['waking', 'Waking up'], ['coffee', 'First coffee or tea'], ['commute', 'The commute'], ['scroll', 'First scroll of the day']], (id) => (id === 'coffee' ? 'selected' : 'plain')),
      h('beatOption', 'option-other', { text: 'Something else' }),
      feedback(h, "Set. We'll remind you in the morning."),
    ]) }),
    'choice-multi': (h) => {
      const on = (t) => LIFTS.slice(0, 3).includes(t);
      return { step: 3, total: 6, body: frame(h, [
        prompt(h, 'Pick three lifts for flat days.'),
        h('text', 'picked', { step: 'body', size: 16, weight: 600, tone: 'green', text: '3 of 3 picked', alts: { text: ['0 of 3 picked', '1 of 3 picked', '2 of 3 picked'] } }),
        chips(h, 'lifts', LIFTS, on, (t) => !on(t)),
        feedback(h, "These are your lifts. We'll suggest them on flat days."),
      ]) };
    },
    slider: (h) => ({ step: 4, total: 7, body: frame(h, [
      prompt(h, 'How automatic does your first one of the day feel?'),
      h('stack', 'slider-wrap', { padTop: 20 }, [h('beatSlider', 'slider', { value: 5, minLabel: 'A real choice', maxLabel: "I don't even notice it" })]),
    ], { gap: 20 }) }),
    'slider-compare': (h) => ({ step: 4, total: 8, body: frame(h, [
      prompt(h, 'And now?'),
      h('beatCompare', 'compare', { firstLabel: 'Before', first: 6, secondLabel: 'After', second: 3 }),
      h('beatEnds', 'ends', { left: '0 · Calm', right: '10 · Very tense' }),
    ], { gap: 20 }) }),
    'slider-group': (h) => ({ step: 3, total: 6, body: frame(h, [
      prompt(h, 'Quick check-in'),
      h('beatSliderCard', 'cravings', { label: 'Cravings', minLabel: 'None', maxLabel: 'Constant' }),
      h('beatSliderCard', 'irritability', { label: 'Irritability', minLabel: 'None', maxLabel: 'A lot' }),
      h('beatSliderCard', 'sleep', { label: 'Sleep quality', minLabel: 'Poor', maxLabel: 'Great' }),
    ], { gap: 12 }) }),
    'reflect-list': (h) => ({ step: 4, total: 9, body: frame(h, [
      prompt(h, 'Your reasons. Anything to add?'),
      subtitle(h, 'count', '1 of 5'),
      h('beatField', 'entry-0', { kind: 'entry', text: REASON }),
      h('beatField', 'add', { kind: 'add', placeholder: 'Why now?' }),
    ]) }),
    'reflect-long': (h) => ({ step: 4, total: 8, body: frame(h, [
      prompt(h, 'A short note to the you of Prep 1.'),
      h('row', 'guides', { gap: 6, wrap: true, align: 'flex-start' }, ['What was hardest?', 'What helped?', "What's better now?"].map((t, i) => h('beatGuidePill', 'guide-' + i, { text: t }))),
      h('beatField', 'answer', { kind: 'area', placeholder: '', lines: 8 }),
      subtitle(h, 'counter', '0 / 1,000', { align: 'right' }),
    ], { skip: true }) }),
    'reflect-chips': (h) => ({ step: 4, total: 7, body: frame(h, [
      prompt(h, 'What helped most this week?'),
      chips(h, 'helped', ['Craving SOS', 'Water', 'My reasons', 'A person', 'Breathing', 'Moving', 'Staying busy']),
      h('beatField', 'answer', { kind: 'area', placeholder: '', lines: 2 }),
      subtitle(h, 'counter', '0 / 140', { align: 'right' }),
    ], { skip: true }) }),
    flip: (h) => ({ step: 6, total: 8, body: frame(h, [
      subtitle(h, 'flipped', '0 of 3 flipped', { size: 14, weight: 600, alts: { text: ['1 of 3 flipped', '2 of 3 flipped', '3 of 3 flipped'] } }),
      ...P44.map(([f, b], i) => h('beatFlipCard', 'card-' + i, { front: f, back: b })),
    ], { gap: 12, disabled: true }) }),
    'flip-turned': (h) => ({ step: 6, total: 8, body: frame(h, [
      subtitle(h, 'flipped', '1 of 3 flipped', { size: 14, weight: 600, alts: { text: ['0 of 3 flipped', '2 of 3 flipped', '3 of 3 flipped'] } }),
      ...P44.map(([f, b], i) => h('beatFlipCard', 'card-' + i, { front: f, back: b, side: i === 0 ? 'back' : 'front' })),
    ], { gap: 12, disabled: true }) }),
    'plan-builder': (h) => ({ step: 4, total: 7, body: frame(h, [
      prompt(h, 'If today gets hard, then I will…'),
      h('beatCard', 'plan-editor', { radius: 18, padX: 16, padY: 16, gap: 10 }, [
        h('text', 'plan-n', { step: 'caption', tone: 'muted', text: 'Plan 1' }),
        h('text', 'if', { step: 'footnote', size: 14, weight: 600, text: 'If' }),
        h('beatField', 'situation', { kind: 'inline', text: 'today gets hard', placeholder: 'what happens' }),
        h('text', 'then', { step: 'footnote', size: 14, weight: 600, text: 'Then I will' }),
        chips(h, 'actions', ['Walk for 5 minutes', 'Text or call someone', 'Open Craving SOS', 'Have a shower', 'Go to bed early', 'Eat something proper', 'Type my own']),
      ]),
      h('beatLink', 'add-plan', { label: 'Add another plan', disabled: true }),
    ], { gap: 12, disabled: true }) }),
    checklist: (h) => ({ step: 3, total: 8, body: frame(h, [
      prompt(h, 'Make it harder to reach'),
      subtitle(h, 'tick-hint', "Tick what you've done. The rest can wait."),
      ...['Pack and lighter out of my pocket', 'Out of the car', 'Out of my bag', 'In one inconvenient spot'].map((t, i) => h('beatCheckRow', 'item-' + i, { text: t })),
    ]) }),
    'checklist-carry': (h) => ({ step: 3, total: 7, body: frame(h, [
      prompt(h, 'Last clear-out'),
      h('text', 'still-open', { step: 'caption', tone: 'muted', text: 'Still open from before' }),
      ...['Out of my bag', 'In one inconvenient spot'].map((t, i) => h('beatCheckRow', 'carried-' + i, { text: t })),
      h('stack', 'tonight-wrap', { padTop: 8 }, [h('text', 'tonight', { step: 'caption', tone: 'muted', text: 'Tonight' })]),
      ...['Leftover cigarettes soaked and binned', 'Lighters gone', 'Ashtrays gone', 'Checked jacket and car'].map((t, i) => h('beatCheckRow', 'item-' + i, { text: t })),
    ]) }),
    'checklist-footer': (h) => ({ step: 3, total: 7, body: frame(h, [
      prompt(h, 'Last clear-out'),
      subtitle(h, 'tick-hint', "Tick what you've done. The rest can wait."),
      ...['Vapes and pods handed over or set aside for battery recycling', 'Charger with them', 'Checked bag and car'].map((t, i) => h('beatCheckRow', 'item-' + i, { text: t })),
      h('beatAmberNote', 'footer', { text: "Vapes have batteries. Please don't put them in the bin. Take them to a battery or electronics recycling point." }),
    ]) }),
    breathe: (h) => ({ step: 5, total: 8, gap: 12, body: [
      h('text', 'label', { step: 'headline', size: 19, weight: 600, align: 'center', text: 'Two more sighs, with the ring.' }),
      h('beatOrbPanel', 'orb-panel', {}, [
        h('text', 'pattern', { step: 'caption', tone: 'muted', align: 'center', text: 'Physiological sigh · 2·1·6' }),
        h('calmBioOrb', 'orb', { label: '2 seconds · inhale', numeral: '2', cycle: 'CYCLE 1 OF 3', scale: 0.9, side: 300 }),
        h('calmOrbCaption', 'caption', { text: 'Inhale slowly through your nose... watch the sage ring expand.' }),
        h('row', 'controls', { gap: 10, justify: 'center' }, [
          h('calmOrbButton', 'primary', { label: 'Start', icon: 'play.fill', kind: 'porcelain', alts: { label: ['Pause', 'Resume', 'Continue'] } }),
          h('calmOrbButton', 'secondary', { label: 'Coach me', icon: 'waveform', kind: 'moss', alts: { label: ['Again'] } }),
        ]),
      ]),
    ] }),
    commit: (h) => ({ step: 7, total: 9, gap: 20, body: [
      h('spacer', 'top', { flex: true, size: 0 }),
      h('text', 'words', { step: 'title', align: 'center', text: 'Hold to commit to your Quit Day: Fri 6 Nov', alts: { text: ['Committed.'] } }),
      h('spacer', 'bottom', { flex: true, size: 0 }),
      h('holdButton', 'hold', { label: 'Hold to commit', doneLabel: 'Committed ✓' }),
      h('text', 'hold-hint', { step: 'footnote', tone: 'muted', align: 'center', text: 'Hold for 2 seconds' }),
    ] }),
    'commit-done': (h) => ({ step: 7, total: 9, replay: true, gap: 20, body: [
      h('spacer', 'top', { flex: true, size: 0 }),
      h('text', 'words', { step: 'title', align: 'center', text: 'Committed.', alts: { text: ['Hold to commit to your Quit Day: Fri 6 Nov'] } }),
      h('sessionIconLabel', 'done-on', { icon: 'checkcircle', iconTone: 'accent', tone: 'muted', text: 'Done on Fri 30 Oct', align: 'center' }),
      h('spacer', 'bottom', { flex: true, size: 0 }),
      h('button', 'continue', { label: 'Continue' }),
    ] }),
    'commit-dayxero': (h) => ({ ground: 'apricot', step: 4, total: 8, gap: 0, body: [
      h('stack', 'content', { gap: 10, style: 'flex:1 0 auto' }, [
        h('sessionScene', 'scene', { scene: 'dawn', clarity: 23, character: 'xero:hello', charSize: 200, lift: 2, height: 260 }),
        h('stack', 'eyebrow-wrap', { padTop: 8 }, [h('text', 'eyebrow', { step: 'caption', tone: 'muted', text: 'FRI 6 NOV · QUIT DAY · 5 MIN' })]),
        h('text', 'title', { step: 'large', text: 'Day Xero' }),
        h('text', 'subtitle', { step: 'body', tone: 'muted', text: 'Your first day. Best heard in the morning.' }),
        h('stack', 'because', { fill: 'onColour', radius: 22, padX: 16, padTop: 14, padBottom: 14, gap: 4 }, [
          h('text', 'because-label', { step: 'caption', tone: 'muted', text: 'BECAUSE' }),
          h('text', 'reason', { step: 'headline', size: 19, weight: 700, text: REASON }),
        ]),
      ]),
      h('stack', 'hold-wrap', { padTop: 8, gap: 6 }, [
        h('holdButton', 'hold', { label: 'Hold to start Day Xero', doneLabel: 'Day Xero started ✓' }),
      ]),
    ] }),
    scenario: (h) => ({ step: 3, total: 7, body: frame(h, [
      prompt(h, 'Someone offers you one at a party. You say…', 'Picture it'),
      ...options(h, [['no', "“No thanks, I've stopped.”"], ['later', '“Maybe later.”'], ['one', '“Go on then, just one.”']], (id) => (id === 'no' ? 'selected' : 'dimmed')),
      h('stack', 'feedback-wrap', { padTop: 8 }, [h('beatFeedback', 'feedback', { text: "Clear and done. That's the strongest answer.", alts: { text: ["That leaves later-you to deal with it. A clear no is kinder to yourself.", "If it happens, it's a slip, not a reset. Log it and keep going."] } })]),
    ]) }),
    note: (h) => ({ step: 3, total: 7, body: frame(h, [
      h('spacer', 'top', { size: 24 }),
      h('text', 'title', { step: 'caption', tone: 'muted', text: 'Your reasons' }),
      h('beatCard', 'note-card', { padX: 20, padY: 20, gap: 16 }, [
        h('stack', 'highlight', { gap: 4 }, [
          h('text', 'matters', { step: 'caption', tone: 'green', text: 'Matters most' }),
          h('text', 'top-reason', { step: 'title', size: 24, weight: 700, text: REASON }),
        ]),
      ]),
    ], { gap: 12 }) }),
    info: (h) => ({ step: 7, total: 9, body: frame(h, [
      h('spacer', 'top', { size: 24 }),
      h('beatCard', 'info-card', { padX: 20, padY: 20, gap: 12 }, [
        h('beatGlyph', 'heart', { icon: 'heart', size: 30 }),
        h('text', 'title', { step: 'title', size: 24, weight: 700, text: 'If it stays heavy' }),
        h('text', 'body', { step: 'body', text: 'If a heavy feeling stays with you for weeks, talking to a doctor or someone you trust can really help.' }),
        h('beatHelpLine', 'help', {}),
      ]),
    ], { gap: 12 }) }),
    'share-message': (h) => ({ step: 6, total: 8, body: frame(h, [
      prompt(h, 'Give someone a heads-up?'),
      subtitle(h, 'lead', "A message from a friend helps more than you'd think. Change it however you like."),
      h('beatField', 'message', { kind: 'message', lines: 4, text: "Heads up: I'm quitting nicotine in two days. If I'm a bit cranky, that's why. A message from you would really help." }),
      h('beatSecondary', 'send', { label: 'Send it', icon: 'share' }),
    ], { gap: 12, cont: 'Done', skip: true }) }),
    'share-card': (h) => ({ step: 5, total: 7, body: frame(h, [
      prompt(h, 'Share it, if you like'),
      h('beatShareCard', 'card', { days: 7 }),
      h('beatSecondary', 'share', { label: 'Share', icon: 'share' }),
    ], { gap: 12, cont: 'Done', skip: true }) }),
    'nrt-choice': (h) => ({ step: 5, total: 8, body: frame(h, [
      prompt(h, 'Want nicotine replacement for the first weeks?'),
      ...options(h, [['setup', 'Yes, set it up'], ['have', 'I already have it'], ['no', 'Not this time']]),
      h('stack', 'safety-wrap', { padTop: 8 }, [h('beatSafetyNote', 'safety', { text: SAFETY })]),
    ], { disabled: true }) }),
    'nrt-stepdown': (h) => ({ step: 4, total: 7, body: frame(h, [
      prompt(h, 'Plan your step-down'),
      subtitle(h, 'body', "Follow the step-down plan on your product's label. We'll remind you on each date."),
      h('beatSecondary', 'plan', { label: 'Plan my step-down', icon: 'calendar' }),
      h('beatSafetyNote', 'safety', { text: SAFETY }),
    ], { gap: 12 }) }),
    'slip-practice': (h) => ({ step: 3, total: 7, body: frame(h, [
      h('spacer', 'top', { size: 24 }),
      prompt(h, "Let's run through it once, so it feels familiar.", '', 'prompt'),
      h('beatSecondary', 'start', { label: 'Start the practice', icon: 'walk' }),
      subtitle(h, 'not-logged', 'Nothing here is logged as a slip.'),
    ], { gap: 16, disabled: true }) }),
    'plan-card': (h) => ({ step: 5, total: 8, body: frame(h, [
      prompt(h, 'Your plan'),
      h('beatCard', 'plan', { radius: 24, padX: 16, padY: 0, gap: 0 }, [
        h('beatPlanRow', 'row-identity', { heading: 'Who I am now' }, [h('text', 'identity', { step: 'headline', size: 19, weight: 700, text: "I don't use nicotine", alts: { text: ["I'm nicotine-free", "I don't smoke"] } })]),
        h('beatPlanRow', 'row-reason', { heading: "Why I'm doing this", divider: true }, [h('text', 'reason', { step: 'body', text: REASON })]),
        h('beatPlanRow', 'row-rough', { heading: 'On a rough day', divider: true, editable: false }, [h('text', 'rough', { step: 'body', text: 'If today gets hard, then I will walk for 5 minutes.' })]),
        h('beatPlanRow', 'row-breaks', { heading: 'My breaks', divider: true }, [
          h('text', 'break-0', { step: 'body', text: 'Step outside' }),
          h('text', 'break-1', { step: 'body', text: 'Make tea or coffee properly' }),
          h('text', 'break-2', { step: 'body', text: 'Stretch' }),
        ]),
      ]),
      h('beatSecondary', 'save', { label: 'Save to Photos or share', icon: 'photo' }),
    ], { gap: 12 }) }),
  };

  Lab.screen({
    id: 'session-kit', name: 'Session beats kit', area: 'Sessions', source: KIT + ', ' + BA + ', ' + BB, ground: 'reading', fullBleed: true,
    note: 'Every activity type the beats kit draws, each with real content from a session that uses it and the lesson bar at that step. Sam’s own words aren’t known, so fields show placeholders and only real option text is used. Assumed answers: P1.4 Sam picks "It adds something extra…" (to show the "Your pick" ring); P2.1 First coffee or tea; W1D4.1 the first three lifts; P4.2 tension 6 before and 3 after; P7.1 carries over two items left unticked in P6.1; W1D5.1 "No thanks"; plan card: identity "I don\'t use nicotine", rough-day plan "Walk for 5 minutes", the first three breaks (no-line and hard-day line are Sam’s own words, so hidden as when empty). The vaping footer state uses the vaping copy. The nrt_stepdown beat only shows with an active NRT plan; Sam has none. The breathing orb is drawn still (its cycle line is 10 pt in the app, 12 pt here); its first caption follows the Calm screens. Day Xero assumes Sam wrote a note last night, so DX has 8 steps.',
    states: KIT_STATES.map(([id, label]) => ({ id, label })),
    build(h, state) {
      const b = (KIT_BUILD[state.id] || KIT_BUILD.stat)(h);
      return flow(h, b);
    },
  });

  /* ===================== Screen: session done ===================== */
  Lab.screen({
    id: 'session-done', name: 'Session done', area: 'Sessions', source: FLOW + ' (SessionCompletion)', ground: 'reading', fullBleed: true,
    note: 'The last step of a session, with no lesson bar. "Day 2" is W1D2 on Sun 8 Nov: W1D3 opens 3 days after Day Xero, so "Next session on Day 3". "Prep 1" is P1 on Fri 30 Oct (sky clarity 20 in prep). A replay hides the next line. Day Xero (Q2) is on sun with Xero cheering; its numbers assume it is finished at 09:00 on Fri 6 Nov (1 day clear, 2 not smoked, $1.45 kept, from the codeTrue formulas). Graduation ends on the finale (FinaleView), which is not part of this batch.',
    states: [
      { id: 'day2', label: 'Day 2 done · Sun 8 Nov' },
      { id: 'prep1', label: 'Prep 1 done · Fri 30 Oct' },
      { id: 'replay', label: 'Day 2 replay done' },
      { id: 'dayxero', label: "You're on Day Xero · Fri 6 Nov" },
    ],
    build(h, state) {
      if (state.id === 'prep1') return flow(h, { header: false, gap: 16, body: lessonDoneStep(h, { clarity: 20, label: 'Prep 1', completion: "First prep day done. You didn't have to change a thing. Just notice.", next: 'Next: Prep 2 · The first one of the day, tomorrow' }) });
      if (state.id === 'replay') return flow(h, { header: false, gap: 16, body: lessonDoneStep(h, { clarity: 28, label: W.label, completion: W.completion, next: null }) });
      if (state.id === 'dayxero') return flow(h, { ground: 'sun', header: false, gap: 16, body: [
        h('stack', 'done', { gap: 12, align: 'center', textAlign: 'center', padTop: 20, style: 'flex:1 0 auto' }, [
          h('stack', 'xero-wrap', { align: 'center', style: 'height:220px;justify-content:flex-end' }, [h('art', 'xero', { art: 'xero:cheer', width: 200, height: 200 })]),
          h('text', 'completion', { step: 'large', align: 'center', text: "You're on Day Xero. Your counter has started." }),
          h('sessionDoneMission', 'mission', { text: 'Every craving you ride out today, tap “It passed”. Every single one counts.' }),
          h('row', 'stats', { gap: 8, align: 'stretch', style: 'align-self:stretch;text-align:left' }, [
            h('todayStat', 'stat-days', { value: '1', label: 'day clear', alts: { label: ['days clear'] } }),
            h('todayStat', 'stat-avoided', { value: '2', label: 'not smoked', alts: { label: ['puffs not taken', 'pouches not used'] } }),
            h('todayStat', 'stat-kept', { value: '$1.45', label: 'kept' }),
          ]),
        ]),
        h('button', 'continue', { label: 'Continue' }),
      ] });
      return flow(h, { header: false, gap: 16, body: lessonDoneStep(h, { clarity: 28, label: W.label, completion: W.completion, next: 'Next session on Day 3' }) });
    },
  });

  /* ===================== Screen: mission card and the sheets that follow it up ===================== */
  function sheetSlider(h, o) {
    return [h('stack', 'follow-up', { gap: 12, style: 'flex:1 1 auto' }, [
      h('stack', 'sheet-head', { padTop: 20 }, [h('text', 'sheet-kicker', { step: 'caption', tone: 'green', text: o.kicker })]),
      h('stack', 'beat', { gap: 8, style: 'flex:1 1 auto' }, o.body),
    ])];
  }
  Lab.screen({
    id: 'session-mission', name: 'Mission and follow-ups', area: 'Sessions', source: FLOW + ' (MissionCard), ' + MP, ground: 'reading', fullBleed: true,
    note: 'The mission step of P3 (the one with a follow-up), then the sheets Home raises when a log answers a mission: the P3 follow-up (large sheet, two activities) the first time Sam logs a use, and the one quick question for P2 (after the first use of the day), P4 (after a use) and P5 (after Craving SOS) on a medium sheet. Behind the sheets is Today, drawn here as its reading ground only. In "compared" Sam expected 7 and it was 4 (assumed). The sheets have no grabber in the app (one detent each).',
    states: [
      { id: 'card', label: 'Mission step · P3 (with follow-up)' },
      { id: 'follow-1', label: 'P3 follow-up 1 of 2 · slider' },
      { id: 'follow-1-compare', label: 'P3 follow-up 1 of 2 · compared' },
      { id: 'follow-2', label: 'P3 follow-up 2 of 2 · choice' },
      { id: 'q-morning', label: 'Question · P2 morning gap' },
      { id: 'q-sigh', label: 'Question · P4 sighs first' },
      { id: 'q-surf', label: 'Question · P5 craving peak' },
    ],
    build(h, state) {
      if (state.id === 'card') return flow(h, { step: 4, total: 5, gap: 16, body: missionStep(h, 'Do one session today with no phone and full attention, then log what you noticed.', true) });
      return h('spacer', 'today-behind', { size: 0 });
    },
    overlay(h, state) {
      const id = state.id;
      if (id === 'card') return null;
      if (id.startsWith('follow')) {
        let body;
        if (id === 'follow-1') body = frame(h, [
          prompt(h, 'How good did it actually feel?'),
          h('stack', 'slider-wrap', { padTop: 20 }, [h('beatSlider', 'slider', { value: 5, minLabel: 'Not good at all', maxLabel: 'Really good' })]),
        ], { gap: 20 });
        else if (id === 'follow-1-compare') body = frame(h, [
          prompt(h, 'How good did it actually feel?'),
          h('beatCompare', 'compare', { firstLabel: 'Expected', first: 7, secondLabel: 'Actual', second: 4 }),
          h('beatEnds', 'ends', { left: '0 · Not good at all', right: '10 · Really good' }),
        ], { gap: 20 });
        else body = frame(h, [
          prompt(h, 'What did you notice most?'),
          chips(h, 'noticed', ['Harsh taste', 'Heat in my throat', 'Tight chest', 'Smell on my hands', 'Head rush', 'The good part was short', 'I liked parts of it']),
        ], { disabled: true });
        const n = id === 'follow-2' ? 2 : 1;
        return h('sessionSheet', 'sheet', { top: 72 }, sheetSlider(h, { kicker: `Prep 3 mission · ${n} of 2`, body }));
      }
      const q = {
        'q-morning': { text: 'How long was your gap?', choices: ['0 min', '5 min', '10 min', '15+ min'] },
        'q-sigh': { text: 'Did you do the sighs first?', choices: ['Yes', 'Not this time'] },
        'q-surf': { text: 'How strong was it at its peak?', slider: true },
      }[id];
      return h('sessionSheet', 'sheet', { top: 437 }, [
        h('stack', 'question', { gap: 16, padTop: 20 }, [
          h('text', 'sheet-kicker', { step: 'caption', tone: 'green', text: "Today's mission" }),
          h('text', 'question-text', { step: 'title', size: 24, weight: 700, text: q.text, alts: { text: ['How long was your gap?', 'Did you do the sighs first?', 'How strong was it at its peak?'].filter((x) => x !== q.text) } }),
          ...(q.slider
            ? [h('beatSlider', 'slider', { value: 5, minLabel: 'Barely there', maxLabel: 'Overwhelming' }), h('button', 'save', { label: 'Save' })]
            : q.choices.map((c, i) => h('beatOption', 'choice-' + i, { text: c }))),
          h('button', 'not-now', { label: 'Not now', kind: 'quiet' }),
        ]),
      ]);
    },
  });

  /* ===================== Screen: the lesson audio player ===================== */
  Lab.screen({
    id: 'lesson-audio', name: 'Lesson audio', area: 'Sessions', source: AUDIO + ' (LessonAudioStep), ' + FLOW + ' (ProgramAudioStep)', ground: 'reading', fullBleed: true,
    note: 'The audio step once a session’s recording is in the app (none are yet: until then it shows "Audio coming soon"; see the Session screen). W1D2 is 3 min. No timed transcripts exist yet, so the captions are just the title, as the app does with no transcript. "Playing" and "Paused" show 1:05 gone (an example moment). Continue appears only when the audio ends. The skip buttons are SF Symbols with a small 15 inside; that numeral is part of the symbol. LessonLibrary.swift has no screen of its own any more (the old lesson player was removed in Phase 8), so there is no separate lesson reading screen to show.',
    states: [{ id: 'playing', label: 'Playing' }, { id: 'paused', label: 'Paused' }, { id: 'finished', label: 'Finished' }],
    build(h, state) {
      const fin = state.id === 'finished', playing = state.id === 'playing';
      return flow(h, { step: 2, total: 7, gap: 12, body: [
        h('stack', 'player', { gap: 12, align: 'center', textAlign: 'center', style: 'flex:1 1 auto' }, [
          h('stack', 'heading', { gap: 4, align: 'center' }, [
            h('sessionIconLabel', 'kind', { icon: 'headphones', step: 'caption', tone: 'muted', text: 'Audio session', align: 'center' }),
            h('text', 'title', { step: 'title', align: 'center', text: W.title }),
          ]),
          h('lessonBreathRing', 'ring', { breath: playing ? 1 : 0.4, mood: playing ? 'xero:breathe' : 'xero:calm' }),
          h('lessonScrubber', 'scrubber', fin ? { elapsed: '3:00', remaining: '0:00', fraction: 1 } : { elapsed: '1:05', remaining: '1:55', fraction: 0.36 }),
          h('lessonControls', 'controls', { playing, alts: { speed: ['1.25×', '0.8×'] } }),
          h('lessonCaptions', 'captions', {}, [h('lessonCaption', 'caption-0', { text: W.title })]),
          fin ? h('sessionIconLabel', 'finished', { icon: 'checkmark', step: 'footnote', size: 14, weight: 600, tone: 'accent', text: 'Nice. On to the exercise.', align: 'center' }) : null,
        ]),
        fin ? h('button', 'continue', { label: 'Continue' }) : null,
      ] });
    },
  });
})();
