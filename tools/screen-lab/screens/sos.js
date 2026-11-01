/* DayXero Screen Lab — Craving SOS (DayXero/SOS/CravingSOSView.swift, SOSV4.swift) and logging
   (DayXero/Log/LogSheet.swift, SlipFlow.swift). See ../FORMAT.md. */
(function () {
  'use strict';
  const Lab = window.Lab;
  const E = Lab.element, esc = Lab.esc, T = Lab.text, F = Lab.font;
  const SOS = 'DayXero/SOS/CravingSOSView.swift';
  const V4 = 'DayXero/SOS/SOSV4.swift';
  const LOG = 'DayXero/Log/LogSheet.swift';
  const SLIP = 'DayXero/Log/SlipFlow.swift';
  const ENUMS = 'DayXeroCore/Model/Enums.swift';
  const CREAM = Lab.CREAM;

  /* ---------- Colours (SOSColors in SOSV4.swift, Read4 in DayXero/Shared/V4Reading.swift) ---------- */
  const SOSC = {
    solid: ['#1D3A9E', '#1B2C66'],
    glow: ['rgba(156,203,255,0.30)', 'rgba(42,82,219,0.25)'],
    waveBack: ['#2449CC', '#13286A'],
    waveFront: ['#1F40B8', '#1A3384'],
    skyCard: ['rgba(255,248,238,0.72)', 'rgba(255,255,255,0.08)'],
    skyChip: ['#FFFFFF', 'rgba(255,255,255,0.08)'],
    bubble: ['rgba(255,248,238,0.85)', 'rgba(156,203,255,0.45)'],
  };
  const sc = (k, ctx) => Lab.c(SOSC[k], ctx.dark);
  function R4(ctx) {
    const d = ctx.dark, g = Lab.ground('reading', d);
    return {
      bg: g.bg, ink: g.ink, muted: g.muted,
      faint: d ? 'rgba(255,248,238,0.38)' : 'rgba(30,26,58,0.38)',
      hairline: d ? 'rgba(255,255,255,0.14)' : 'rgba(30,26,58,0.12)',
      track: d ? 'rgba(255,255,255,0.16)' : 'rgba(30,26,58,0.12)',
      card: Lab.c(Lab.fill.raised, d), surface: Lab.c(Lab.fill.surface, d),
      accent: Lab.c(Lab.fill.green, d), accentSoft: d ? 'rgba(47,208,138,0.16)' : 'rgba(15,110,67,0.12)',
    };
  }

  /* SF Symbols these screens use that lab.js doesn't draw. */
  const GLYPHS = {
    flame: '<path d="M12 2.8c.6 3.2 5.8 5.6 5.8 11a5.8 5.8 0 0 1-11.6 0c0-2.6 1.3-4.4 2.6-5.6.2 1.9 1 3 2.1 3.6-.6-3.3.2-6.4 1.1-9z" fill="currentColor"/>',
    smoke: '<path d="M6.5 17.5a3.6 3.6 0 0 1-.4-7.2A5 5 0 0 1 15.6 9a3.4 3.4 0 0 1 2.4 6.3 2.6 2.6 0 0 1-1.9 2.2z" fill="currentColor"/><path d="M15 7.2a3.2 3.2 0 0 1 5.6 2.4" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>',
    wind: '<path d="M3 9h10.5a2.8 2.8 0 1 0-2.8-2.8M3 13h15a2.8 2.8 0 1 1-2.8 2.8M3 17h7" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/>',
    'circle.grid.2x1': '<circle cx="7.5" cy="12" r="4.5" fill="none" stroke="currentColor" stroke-width="2.2"/><circle cx="16.5" cy="12" r="4.5" fill="none" stroke="currentColor" stroke-width="2.2"/>',
    'checkmark.circle.fill': '<circle cx="12" cy="12" r="10" fill="currentColor"/><path d="M7.5 12.3l3 3 6-6.3" fill="none" stroke="#FFFFFF" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>',
    'figure.walk.motion': '<circle cx="13.5" cy="4" r="2.1" fill="currentColor"/><path d="M12.5 7.5l-2.6 5 3.4 2.6-1 6M12.5 7.5l3.2 3.6 3 .4M9.9 12.5l-2.4 1-2 4.4M3 8h4M2 11h3.5" fill="none" stroke="currentColor" stroke-width="2.1" stroke-linecap="round" stroke-linejoin="round"/>',
  };
  function glyph(name, size, colour) {
    if (GLYPHS[name]) return `<svg viewBox="0 0 24 24" width="${size}" height="${size}" style="color:${colour};flex:none;display:block" aria-hidden="true">${GLYPHS[name]}</svg>`;
    return Lab.icon(name, size, colour);
  }

  /* ---------- Data (Enums.swift; persona Sam) ---------- */
  const TRIGGERS = [
    { key: 'morning', title: 'Waking up', situation: 'first thing in the morning', ideas: ['drink water before anything else', 'shower first', 'step outside for fresh air', 'open Craving SOS'] },
    { key: 'coffee', title: 'Coffee', situation: 'after coffee', ideas: ['take a short walk', 'switch to tea for a week', 'have it somewhere new', 'open Craving SOS'] },
    { key: 'meals', title: 'After meals', situation: 'after a meal', ideas: ['get up from the table straight away', 'brush my teeth', 'chew sugar-free gum', 'take a short walk'] },
    { key: 'stress', title: 'Stress', situation: 'a stressful moment', ideas: ['open Craving SOS', 'breathe slowly for one minute', 'step away for five minutes', 'text a friend'] },
    { key: 'alcohol', title: 'Drinking', situation: 'a night of drinking', ideas: ['alternate with water', 'stand away from smokers', 'leave a little earlier', 'keep gum in my pocket'] },
    { key: 'boredom', title: 'Boredom', situation: 'a bored moment', ideas: ['do something with my hands', 'go for a walk', 'play a quick game', 'open Craving SOS'] },
    { key: 'social', title: 'With friends', situation: 'time with friends', ideas: ["tell a friend I'm quitting", 'stand with non-smokers', 'have gum ready', 'step away and breathe'] },
    { key: 'driving', title: 'Driving', situation: 'a drive', ideas: ['keep mints in the car', 'put on a podcast', 'clear the car of vapes and lighters', 'open the window and breathe'] },
    { key: 'work', title: 'Work breaks', situation: 'a work break', ideas: ['take my break somewhere new', 'walk around the block', 'take a break with a non-smoker', 'drink water'] },
    { key: 'phone', title: 'On my phone', situation: 'scrolling time', ideas: ['put the phone down for five minutes', 'move to another room', 'chew sugar-free gum', 'open Craving SOS'] },
    { key: 'other', title: 'Something else', situation: 'a strong craving', ideas: ['open Craving SOS', 'take a short walk', 'drink water', 'text a friend'] },
  ];
  const TR = (k) => TRIGGERS.find((t) => t.key === k);
  const SAM_TRIGGERS = ['coffee', 'stress'];
  /** CravingLogForm.orderedTriggers and TriggerPicker with "More…" open: Sam's first, then the rest. */
  const ORDERED = SAM_TRIGGERS.concat(TRIGGERS.map((t) => t.key).filter((k) => !SAM_TRIGGERS.includes(k)));
  const MOODS = ['Low', 'Meh', 'Okay', 'Good', 'Great'];
  const PLACES = ['Home', 'Work', 'Out', 'Driving'];
  const REASON = 'To keep up with Maya at the park';
  const SITUATION_ALTS = TRIGGERS.map((t) => `If it's ${t.situation}, then I'll…`);

  /* ---------- Frames ---------- */
  function waterSVG(W, H, ctx, p) {
    const k = W / 390;
    const r = (125 + 40 * +p.breath) * k;
    const cy = 196 * k;
    const wave = (baseline, depth) => {
      const d = p.waves === 'still' ? 0 : depth;
      const y = H - (844 - baseline) * k;
      return `M0 ${y.toFixed(1)} C${(100 * k).toFixed(1)} ${(y - d * k).toFixed(1)} ${(290 * k).toFixed(1)} ${(y + d * k).toFixed(1)} ${W} ${y.toFixed(1)} L${W} ${H} L0 ${H} Z`;
    };
    return `<svg width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" style="position:absolute;left:0;top:0;pointer-events:none" aria-hidden="true">
      <circle cx="${W / 2}" cy="${cy.toFixed(1)}" r="${r.toFixed(1)}" fill="${sc('glow', ctx)}"/>
      <path d="${wave(730, 16)}" fill="${sc('waveBack', ctx)}"/><path d="${wave(774, -12)}" fill="${sc('waveFront', ctx)}"/></svg>`;
  }
  function bubblesSVG(W, H, ctx) {
    const k = W / 390;
    const rings = [[44, 5, 300], [120, 8, 180], [262, 6, 420], [346, 4, 250]]
      .map(([x, r, y]) => `<circle cx="${(x * k).toFixed(1)}" cy="${(y * k).toFixed(1)}" r="${(r * k).toFixed(1)}" fill="none" stroke="${sc('bubble', ctx)}" stroke-width="2.5"/>`).join('');
    return `<svg width="${W}" height="${H}" viewBox="0 0 ${W} ${H}" style="position:absolute;left:0;top:0;pointer-events:none" aria-hidden="true">${rings}</svg>`;
  }

  E({
    type: 'sosFrame', name: 'SOS full screen', group: 'SOS', source: SOS + ', ' + V4,
    description: 'The full-screen cover Craving SOS opens in: the ground runs under the status bar, with Jelli\'s water (a breathing glow ring and two slow waves) on the session, rising rings on Passed, or nothing on a slip. Content sits inside the safe area.',
    props: {
      backdrop: { label: 'Behind the content', kind: 'select', default: 'water', options: [['water', 'Water: glow ring and waves (session)'], ['bubbles', 'Rising rings (Passed)'], ['none', 'Nothing']] },
      breath: { label: 'Glow ring', kind: 'select', default: 0.375, options: [[0, 'Breath out (125 pt)'], [0.375, 'Still, Reduce Motion (140 pt)'], [1, 'Breath in (165 pt)']] },
      waves: { label: 'Waves', kind: 'select', default: 'moving', options: [['moving', 'At the top of their swell'], ['still', 'Flat (Reduce Motion)']] },
      padBottom: { label: 'Bottom padding', kind: 'number', options: [0, 4, 8, 12, 16], unit: ' pt', default: 8 },
    },
    examples: [{ label: 'Water on ocean', ground: 'ocean', props: {} }, { label: 'Rings on sky', ground: 'sky', props: { backdrop: 'bubbles' } }],
    render(p, ctx, kids) {
      const d = ctx.screenId !== '_lib' && ctx.device ? ctx.device : null;
      const W = d ? d.w : ctx.width || 362, H = d ? d.h : 420;
      const top = d ? d.top : 0, bottom = d ? d.bottom : 0;
      const pull = d ? `margin-bottom:-${d.bottom + 12}px;` : `min-height:${H}px;`;
      const back = p.backdrop === 'water' ? waterSVG(W, H, ctx, p) : p.backdrop === 'bubbles' ? bubblesSVG(W, H, ctx) : '';
      return `<div style="position:relative;flex:1;display:flex;flex-direction:column;background:${ctx.g.bg};color:${ctx.g.ink};padding:${top}px 0 ${bottom + p.padBottom}px;${pull}overflow:hidden">${back}<div style="position:relative;flex:1;display:flex;flex-direction:column">${kids()}</div></div>`;
    },
  });

  /* ---------- Session (F13) ---------- */
  E({
    type: 'sosTopBar', name: 'SOS top bar', group: 'SOS', source: SOS + ' (topBar), DayXeroCore/DesignSystem/V4/Cards4.swift (HandOverChip)',
    description: 'The hand-over chip (Xero on an apricot circle, footnote words, card-on-colour capsule) on the left and a plain 44 pt cream close cross on the right. The chip fades out after 3 seconds but keeps its space.',
    props: {
      text: { label: 'Chip words', kind: 'text', default: 'Xero passed you to Jelli' },
      avatar: { label: 'Chip avatar', kind: 'art', default: 'xero:calm' },
      avatarSize: { label: 'Avatar size', kind: 'select', default: 32, options: [[32, '32 pt in a 28 pt slot (as built)'], [28, '28 pt (fits the slot)']] },
      chip: { label: 'Chip', kind: 'select', default: 'shown', options: [['shown', 'Shown (first 3 seconds)'], ['faded', 'Faded out (space kept)']] },
      close: { label: 'Close icon', kind: 'icon', default: 'xmark' },
    },
    examples: [{ label: 'On ocean', ground: 'ocean', props: {} }],
    render(p, ctx) {
      const s = +p.avatarSize, over = (s - 28) / 2;
      const ap = Lab.ground('apricot', ctx.dark).bg;
      const chipInk = ctx.dark ? CREAM : Lab.NAVY;
      const avatar = `<div style="width:28px;height:28px;flex:none;position:relative"><div style="position:absolute;left:${-over}px;top:${-over}px;width:${s}px;height:${s}px;border-radius:50%;overflow:hidden;background:${ap};line-height:0">${Lab.art(p.avatar, { size: s, animate: false })}</div></div>`;
      return `<div style="display:flex;align-items:center;justify-content:space-between;min-height:48px;padding:4px 10px 0 14px;box-sizing:border-box">
        <div style="display:inline-flex;align-items:center;gap:8px;padding:6px 14px 6px 6px;border-radius:999px;background:${Lab.c(Lab.fill.cardOnColour, ctx.dark)};opacity:${p.chip === 'faded' ? 0 : 1}">${avatar}<span style="${F('footnote')}color:${chipInk}">${esc(p.text)}</span></div>
        <div role="button" aria-label="Close" style="width:44px;height:44px;display:flex;align-items:center;justify-content:center;flex:none">${Lab.icon(p.close, 18, CREAM)}</div></div>`;
    },
  });

  E({
    type: 'sosCrew', name: 'Crew member in a frame', group: 'SOS', source: SOS + ', ' + SLIP,
    description: 'A crew member at a set size and growth stage, in a frame: Jelli at hero size (200) in a 220 pt frame on the session, 230 pt bottom-aligned on Passed, 88 pt on an ocean tile in the slip flow, Xero as a 40 pt avatar on an apricot circle.',
    props: {
      art: { label: 'Character', kind: 'art', default: 'jelli:breathe' },
      size: { label: 'Size', kind: 'number', options: [40, 88, 140, 200], unit: ' pt', default: 200 },
      stage: { label: 'Growth stage', kind: 'select', default: 1, options: [[1, 'Stage 1 (under 7 days clear)'], [2, 'Stage 2'], [3, 'Stage 3'], [4, 'Stage 4']] },
      frame: { label: 'Frame height', kind: 'number', options: [40, 88, 200, 220, 230, 240], unit: ' pt', default: 220 },
      align: { label: 'Sits', kind: 'select', default: 'center', options: [['center', 'In the middle'], ['flex-end', 'At the bottom']] },
      backing: { label: 'Behind it', kind: 'select', default: 'none', options: [['none', 'Nothing'], ['ocean', 'Ocean tile'], ['apricot', 'Apricot']] },
      radius: { label: 'Backing corners', kind: 'select', default: 26, options: [[26, 'Rounded 26 pt'], [999, 'Circle']] },
    },
    examples: [{ label: 'Jelli breathing', ground: 'ocean', props: {} }, { label: 'Jelli on a tile', ground: 'reading', props: { art: 'jelli:calm', size: 88, frame: 88, backing: 'ocean', stage: 2 } }],
    render(p, ctx) {
      const s = +p.size;
      const bg = p.backing === 'none' ? '' : `background:${Lab.ground(p.backing, ctx.dark).bg};border-radius:${p.radius}px;overflow:hidden;`;
      const w = p.backing === 'none' ? 'align-self:stretch;' : `width:${s}px;`;
      return `<div aria-hidden="true" style="${w}height:${p.frame}px;flex:none;display:flex;flex-direction:column;align-items:center;justify-content:${p.align};line-height:0;${bg}">${Lab.art(p.art, { size: s, stage: +p.stage })}</div>`;
    },
  });

  E({
    type: 'sosBreathWords', name: 'SOS breathing words', group: 'SOS', source: V4 + ' (SOSBreathWords)',
    description: '"Breathe in… 4" and "…and out, 6" cross-fading on the 4 s in, 6 s out clock (the same clock as Jelli). Display 40, one line, cream, centred.',
    props: {
      inhale: { label: 'Breathe in words', kind: 'text', default: 'Breathe in… 4' },
      exhale: { label: 'Breathe out words', kind: 'text', default: '…and out, 6' },
      show: { label: 'Showing', kind: 'select', default: 'cycle', options: [['cycle', 'Both, on the breath clock'], ['in', 'Breathe in'], ['out', 'Breathe out']] },
      step: { label: 'Text style', kind: 'type', default: 'display' },
    },
    examples: [{ label: 'On ocean', ground: 'ocean', props: {} }],
    render(p, ctx) {
      const cyc = p.show === 'cycle' && Lab.view.motion;
      const inOp = p.show === 'out' ? 0 : 1, outOp = p.show === 'out' ? 1 : 0;
      const t = Lab.type[p.step] || Lab.type.display;
      const span = (cls, op, s) => `<span class="${cyc ? cls : ''}" style="position:absolute;inset:0;white-space:nowrap;${cyc ? '' : `opacity:${op};`}">${esc(s)}</span>`;
      return `<div style="position:relative;height:${Math.round(t.size * t.lh)}px;${F(p.step)}color:${CREAM};text-align:center">${span('bw-in', inOp, p.inhale)}${span('bw-out', outOp, p.exhale)}</div>`;
    },
  });

  E({
    type: 'sosRiddenLine', name: 'Time ridden line', group: 'SOS', source: SOS + ' (riddenLine)',
    description: 'Body 16 in ocean muted, centred, 12 pt in from the sides, ending with the time ridden in bold cream. The clock counts up every second; there is no countdown.',
    props: {
      lead: { label: 'Words', kind: 'text', default: 'Most cravings pass within a few minutes. Ride it with me.' },
      clock: { label: 'Time ridden', kind: 'text', default: "You've ridden 0:52." },
    },
    examples: [{ label: 'On ocean', ground: 'ocean', props: {} }],
    render(p, ctx) {
      return `<div style="${F('body')}color:${ctx.g.muted};text-align:center;padding:0 12px">${esc(p.lead)} <b style="font-weight:700;color:${CREAM}">${esc(p.clock)}</b></div>`;
    },
  });

  E({
    type: 'sosReasonCard', name: 'Reason card', group: 'SOS', source: V4 + ' (SOSReasonCard)',
    description: 'On the solid ocean fill, radius 22: "YOUR REASON" in caption, then the reason in 19 pt bold cream. A 64 pt photo (radius 14) sits on the right when the reason has one. Tapping shows the next reason.',
    props: {
      kicker: { label: 'Kicker', kind: 'text', default: 'Your reason' },
      reason: { label: 'Reason', kind: 'text', default: REASON },
      photo: { label: 'Photo', kind: 'art', default: 'none' },
      radius: { label: 'Corner radius', kind: 'number', options: [18, 20, 22, 24, 28], unit: ' pt', default: 22 },
    },
    examples: [{ label: 'On ocean', ground: 'ocean', props: {} }],
    render(p, ctx) {
      const photo = p.photo && p.photo !== 'none' ? `<div style="width:64px;height:64px;border-radius:14px;overflow:hidden;flex:none;line-height:0">${Lab.art(p.photo, { width: 64, height: 64, radius: 14 })}</div>` : '';
      return `<div role="button" style="display:flex;align-items:center;gap:12px;padding:14px 16px;border-radius:${p.radius}px;background:${sc('solid', ctx)}">
        <div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:4px">${T('caption', p.kicker, ctx, { tone: 'muted' })}<div style="${F('headline', { size: 19, weight: 700 })}color:${CREAM}">${esc(p.reason)}</div></div>${photo}</div>`;
    },
  });

  E({
    type: 'sosSolidPill', name: 'Solid ocean pill', group: 'SOS', source: SOS + ' (SolidPill)',
    description: '"Still strong": the solid ocean fill, 16 pt semibold cream words, 18 pt in from the ends, 58 pt tall, as wide as its words.',
    props: {
      label: { label: 'Words', kind: 'text', default: 'Still strong' },
      height: { label: 'Height', kind: 'number', options: [48, 52, 56, 58], unit: ' pt', default: 58 },
    },
    examples: [{ label: 'On ocean', ground: 'ocean', props: {} }],
    render(p, ctx) {
      return `<div role="button" style="flex:none;display:flex;align-items:center;justify-content:center;min-height:${p.height}px;padding:0 18px;border-radius:999px;background:${sc('solid', ctx)};${F('body', { size: 16, weight: 600 })}color:${CREAM};white-space:nowrap">${esc(p.label)}</div>`;
    },
  });

  E({
    type: 'sosQuietLinks', name: 'Quiet links row', group: 'SOS', source: SOS + ' (QuietLink)',
    description: 'Two 14 pt semibold cream links, 44 pt tall, with a muted dot between: "Text a friend · I slipped".',
    props: {
      left: { label: 'Left link', kind: 'text', default: 'Text a friend' },
      right: { label: 'Right link', kind: 'text', default: 'I slipped' },
    },
    examples: [{ label: 'On ocean', ground: 'ocean', props: {} }],
    render(p, ctx) {
      const link = (s) => `<span role="button" style="${F('footnote', { size: 14, weight: 600 })}color:${CREAM};padding:0 10px;min-height:44px;display:flex;align-items:center">${esc(s)}</span>`;
      return `<div style="display:flex;align-items:center;justify-content:center;gap:6px">${link(p.left)}<span aria-hidden="true" style="${F('body')}color:${ctx.g.muted}">·</span>${link(p.right)}</div>`;
    },
  });

  /* ---------- Passed (F14) ---------- */
  E({
    type: 'sosWavesTile', name: 'Waves ridden tile', group: 'SOS', source: SOS + ' (PassedView.wavesTile)',
    description: 'The count of waves ridden out in Large 32, a green "+1" that pops in 1.2 s after the screen opens and the count ticks up, "waves ridden out" under it. Sky card, radius 22.',
    props: {
      count: { label: 'Count', kind: 'text', default: '15' },
      plus: { label: '"+1"', kind: 'select', default: true, options: [[true, 'Shown (after the tick)'], [false, 'Not yet']] },
      label: { label: 'Label', kind: 'text', default: 'waves ridden out' },
    },
    examples: [{ label: 'On sky', ground: 'sky', props: {} }],
    render(p, ctx) {
      const green = Lab.c(Lab.fill.green, ctx.dark);
      return `<div style="display:flex;flex-direction:column;padding:14px 16px;border-radius:22px;background:${sc('skyCard', ctx)};color:${ctx.g.ink}">
        <div style="display:flex;align-items:baseline;gap:8px">${T('large', p.count, ctx, { style: 'font-variant-numeric:tabular-nums' })}<span style="${F('body', { size: 16, weight: 700 })}color:${green};opacity:${p.plus ? 1 : 0}">+1</span></div>
        ${T('footnote', p.label, ctx, { tone: 'muted' })}</div>`;
    },
  });

  E({
    type: 'sosCard', name: 'SOS card', group: 'SOS', source: SOS + ', ' + SLIP,
    description: 'A card holding other things: the sky card on Passed (cream 72%), the raised plan card with a soft shadow in the slip flow, or the reading surface card ("Your plan", the tough-day card). Radius 22.',
    props: {
      fill: { label: 'Fill', kind: 'select', default: 'sky', options: [['sky', 'Sky card (Passed)'], ['raised', 'Raised with a soft shadow'], ['surface', 'Reading surface']] },
      padX: { label: 'Side padding', kind: 'number', options: [12, 14, 16, 20], unit: ' pt', default: 16 },
      padY: { label: 'Top and bottom padding', kind: 'number', options: [12, 14, 16, 20], unit: ' pt', default: 14 },
      gap: { label: 'Gap between items', kind: 'number', options: [4, 6, 8, 10, 12, 14, 16], unit: ' pt', default: 10 },
      radius: { label: 'Corner radius', kind: 'number', options: [18, 20, 22, 24, 28], unit: ' pt', default: 22 },
    },
    examples: [{ label: 'Sky', ground: 'sky', props: {}, kids: [['text', { step: 'body', text: 'What set it off?' }]] }],
    render(p, ctx, kids) {
      const bg = p.fill === 'sky' ? sc('skyCard', ctx) : p.fill === 'raised' ? Lab.c(Lab.fill.raised, ctx.dark) : Lab.c(Lab.fill.surface, ctx.dark);
      const shadow = p.fill === 'raised' && !ctx.dark ? 'box-shadow:0 8px 22px rgba(30,26,58,0.07);' : '';
      return `<div style="display:flex;flex-direction:column;align-items:stretch;gap:${p.gap}px;padding:${p.padY}px ${p.padX}px;border-radius:${p.radius}px;background:${bg};${shadow}color:${ctx.g.ink}">${kids()}</div>`;
    },
  });

  E({
    type: 'sosAsideLine', name: 'Question with an aside', group: 'SOS', source: SOS + ', ' + LOG,
    description: 'A heading with a quieter "· optional" after it: 16 pt bold with a muted medium aside on Passed; a caption in capitals with a faint aside on the log form.',
    props: {
      text: { label: 'Words', kind: 'text', default: 'What set it off?' },
      aside: { label: 'Aside', kind: 'text', default: '· optional' },
      style: { label: 'Style', kind: 'select', default: 'bold', options: [['bold', '16 pt bold, muted aside'], ['caption', 'Caption capitals, faint aside']] },
    },
    examples: [{ label: 'On sky', ground: 'sky', props: {} }, { label: 'Caption', ground: 'reading', props: { text: 'Mood', style: 'caption' } }],
    render(p, ctx) {
      if (p.style === 'caption') {
        return `<div style="${F('caption')}color:${ctx.g.muted};text-transform:uppercase">${esc(p.text)}${p.aside ? ` <span style="color:${R4(ctx).faint}">${esc(p.aside)}</span>` : ''}</div>`;
      }
      return `<div style="${F('body', { size: 16, weight: 700 })}color:${ctx.g.ink}">${esc(p.text)}${p.aside ? ` <span style="font-weight:500;color:${ctx.g.muted}">${esc(p.aside)}</span>` : ''}</div>`;
    },
  });

  E({
    type: 'sosChip', name: 'Choice chip (44 pt)', group: 'SOS', source: V4 + ' (V4Chip), DayXero/Shared/V4Reading.swift (V4ToggleChip)',
    description: '44 pt chip, radius 14, 16 pt semibold, 14 pt in from the sides. Ink fill with ground-coloured words when picked. White (dark: 8% white) on the sky; the reading surface elsewhere. The log form\'s chips go bold when picked.',
    props: {
      label: { label: 'Words', kind: 'text', default: 'Coffee' },
      on: { label: 'State', kind: 'select', default: false, options: [[false, 'Not picked'], [true, 'Picked']] },
      fill: { label: 'Fill', kind: 'select', default: 'surface', options: [['surface', 'Reading surface'], ['sky', 'White on the sky']] },
      boldOn: { label: 'Bold when picked', kind: 'bool', labels: ['Yes', 'No'], default: false },
      radius: { label: 'Corner radius', kind: 'number', options: [14, 18, 22, 999], unit: ' pt', default: 14, global: true },
    },
    examples: [{ label: 'Picked', ground: 'reading', props: { on: true } }, { label: 'On sky', ground: 'sky', props: { label: 'Stress', fill: 'sky' } }],
    render(p, ctx) {
      const fill = p.fill === 'sky' ? sc('skyChip', ctx) : Lab.c(Lab.fill.surface, ctx.dark);
      return `<div role="button" style="${F('body', { size: 16, weight: p.on && p.boldOn ? 700 : 600 })}min-height:44px;padding:0 14px;display:inline-flex;align-items:center;border-radius:${p.radius}px;background:${p.on ? ctx.g.ink : fill};color:${p.on ? ctx.g.bg : ctx.g.ink};white-space:nowrap">${esc(p.label)}</div>`;
    },
  });

  E({
    type: 'sosHandBack', name: 'Hand back to Xero', group: 'SOS', source: SOS + ' (PassedView.handBack)',
    description: 'Xero cheering as a 40 pt avatar on an apricot circle, and one footnote line in Xero\'s voice.',
    props: {
      avatar: { label: 'Avatar', kind: 'art', default: 'xero:cheer' },
      text: { label: 'Words', kind: 'text', default: 'Back to Xero. I rose a little while you were out.' },
    },
    examples: [{ label: 'On sky', ground: 'sky', props: {} }],
    render(p, ctx) {
      const ap = Lab.ground('apricot', ctx.dark).bg;
      return `<div style="display:flex;align-items:center;gap:10px"><div aria-hidden="true" style="width:40px;height:40px;border-radius:50%;overflow:hidden;background:${ap};flex:none;line-height:0">${Lab.art(p.avatar, { size: 40, animate: false })}</div>${T('footnote', p.text, ctx, { style: 'flex:1;min-width:0' })}</div>`;
    },
  });

  /* ---------- Log sheet (S7.1, S7.2) ---------- */
  E({
    type: 'logSheet', name: 'Log sheet', group: 'Log', source: LOG,
    description: 'The log sheet over Today: half height for the menu, full height for a craving or a slip, with the grabber (two detents). Reading ground; the page behind is dimmed.',
    props: {
      detent: { label: 'Height', kind: 'select', default: 'medium', options: [['medium', 'Half (menu)'], ['large', 'Full (craving, slip)']] },
      radius: { label: 'Top corners', kind: 'number', options: [28, 34, 38], unit: ' pt', default: 38 },
      grabber: { label: 'Grabber', kind: 'bool', labels: ['Show', 'Hide'], default: true },
    },
    render(p, ctx, kids) {
      const d = ctx.screenId !== '_lib' && ctx.device ? ctx.device : null;
      const r = R4(ctx);
      const top = d ? (p.detent === 'medium' ? Math.round(d.h / 2) : d.top + 10) : 0;
      const panel = `<div style="${d ? `position:absolute;left:0;right:0;bottom:0;top:${top}px;` : 'position:relative;min-height:360px;'}display:flex;flex-direction:column;background:${r.bg};color:${r.ink};border-radius:${p.radius}px ${p.radius}px 0 0;overflow:hidden;padding-bottom:${d ? d.bottom : 0}px">
        ${p.grabber ? `<div style="position:absolute;top:5px;left:50%;transform:translateX(-50%);width:36px;height:5px;border-radius:3px;background:${r.ink};opacity:.25"></div>` : ''}
        <div style="flex:1;min-height:0;display:flex;flex-direction:column">${kids({ groundName: 'reading' })}</div></div>`;
      return d ? `<div style="position:absolute;inset:0;z-index:6;background:rgba(0,0,0,${ctx.dark ? 0.45 : 0.3})">${panel}</div>` : panel;
    },
  });

  E({
    type: 'logRow', name: 'Log row', group: 'Log', source: LOG + ' (LogRow)',
    description: 'A raised row, radius 22 with a hairline: a 42 pt circle icon (green on soft green for a craving, ink on the surface for a use), a 16 pt title over a footnote detail, and a 40 pt ink plus button.',
    props: {
      title: { label: 'Title', kind: 'text', default: 'A craving' },
      detail: { label: 'Detail', kind: 'text', default: 'How strong, what set it off' },
      icon: { label: 'Icon', kind: 'select', default: 'flame', options: [['flame', 'Flame (craving)'], ['smoke', 'Smoke (cigarettes)'], ['wind', 'Wind (vape)'], ['circle.grid.2x1', 'Two circles (pouches)']] },
      accent: { label: 'Icon colour', kind: 'select', default: true, options: [[true, 'Green (craving)'], [false, 'Ink (a use)']] },
    },
    examples: [{ label: 'Craving', ground: 'reading', props: {} }, { label: 'Cigarette', ground: 'reading', props: { title: 'Cigarette', detail: '0 today', icon: 'smoke', accent: false } }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div role="button" style="display:flex;align-items:center;gap:12px;padding:12px 14px;border-radius:22px;background:${r.card};box-shadow:inset 0 0 0 1px ${r.hairline}">
        <div style="width:42px;height:42px;border-radius:50%;flex:none;display:flex;align-items:center;justify-content:center;background:${p.accent ? r.accentSoft : r.surface}">${glyph(p.icon, 18, p.accent ? r.accent : r.ink)}</div>
        <div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:1px"><div style="${F('body', { size: 16, weight: 600 })}color:${r.ink}">${esc(p.title)}</div><div style="${F('footnote')}color:${r.muted}">${esc(p.detail)}</div></div>
        <div style="width:40px;height:40px;border-radius:50%;flex:none;display:flex;align-items:center;justify-content:center;background:${r.ink}">${Lab.icon('plus', 16, r.bg)}</div></div>`;
    },
  });

  E({
    type: 'logMoodRow', name: 'Mood buttons', group: 'Log', source: LOG + ' (CravingLogForm.moodButton)',
    description: 'Five raised buttons, radius 16, 6 pt apart: a 22 pt dot (green when picked, the track colour when not) over a 12 pt name. Picked has a green 1.5 pt outline.',
    props: {
      selected: { label: 'Picked', kind: 'select', default: '', options: [['', 'None']].concat(MOODS.map((m) => [m, m])) },
    },
    examples: [{ label: 'Okay picked', ground: 'reading', props: { selected: 'Okay' } }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="display:flex;gap:6px">${MOODS.map((m) => {
        const on = p.selected === m;
        return `<div role="button" style="flex:1;min-width:0;display:flex;flex-direction:column;align-items:center;gap:4px;padding:8px 0;border-radius:16px;background:${r.card};box-shadow:inset 0 0 0 ${on ? 1.5 : 1}px ${on ? r.accent : r.hairline}"><div style="width:22px;height:22px;border-radius:50%;background:${on ? r.accent : r.track}"></div><div style="${F('caption', { size: 12, weight: 500 })}color:${on ? r.ink : r.muted};white-space:nowrap">${esc(m)}</div></div>`;
      }).join('')}</div>`;
    },
  });

  /* ---------- Slip flow (F15) ---------- */
  E({
    type: 'logStepBar', name: 'Slip step bar', group: 'Log', source: SLIP + ' (topBar)',
    description: 'A plain 44 pt close cross (back chevron on "What happened?"), three 6 pt capsules filled in ink up to this step, and a 44 pt space. Telling Jelli or the log counts as step 1.',
    props: {
      icon: { label: 'Button', kind: 'select', default: 'xmark', options: [['xmark', 'Close'], ['chevron.left', 'Back']] },
      step: { label: 'This step', kind: 'select', default: 2, options: [[1, '1 of 3'], [2, '2 of 3 (the plan)'], [3, '3 of 3 (plan saved)']] },
    },
    examples: [{ label: 'Step 2', ground: 'reading', props: {} }],
    render(p, ctx) {
      const surface = Lab.c(Lab.fill.surface, ctx.dark);
      const caps = [1, 2, 3].map((i) => `<div style="flex:1;height:6px;border-radius:3px;background:${i <= p.step ? ctx.g.ink : surface}"></div>`).join('');
      return `<div style="display:flex;align-items:center;gap:10px;padding:8px 10px 0">
        <div role="button" aria-label="${p.icon === 'xmark' ? 'Close. The slip is saved.' : 'Back'}" style="width:44px;height:44px;flex:none;display:flex;align-items:center;justify-content:center">${Lab.icon(p.icon, 18, ctx.g.ink)}</div>
        <div style="flex:1;display:flex;gap:6px">${caps}</div><div style="width:44px;height:44px;flex:none"></div></div>`;
    },
  });

  E({
    type: 'logPracticeTag', name: 'Practice tag', group: 'Log', source: SLIP,
    description: 'Program Day 27\'s rehearsal of the slip flow: a caption in capitals with a walking figure, in a dashed muted capsule (1.5 pt, dashes 4 and 3).',
    props: { text: { label: 'Words', kind: 'text', default: 'Practice · nothing is logged' } },
    examples: [{ label: 'On reading', ground: 'reading', props: {} }],
    render(p, ctx) {
      return `<div style="align-self:center;margin-top:8px;display:inline-flex;align-items:center;gap:6px;padding:6px 12px;border-radius:999px;border:1.5px dashed ${ctx.g.muted};${F('caption')}color:${ctx.g.muted};text-transform:uppercase">${glyph('figure.walk.motion', 14, ctx.g.muted)}<span>${esc(p.text)}</span></div>`;
    },
  });

  E({
    type: 'logThenOption', name: '"Then I\'ll…" option', group: 'Log', source: SLIP + ' (ThenOption)',
    description: 'A radio row, 48 pt, radius 14: 16 pt semibold words and a 22 pt ring. Picked turns ink with a thick green ring around a bright green centre.',
    props: {
      text: { label: 'Words', kind: 'text', default: 'take a short walk' },
      on: { label: 'State', kind: 'select', default: false, options: [[false, 'Not picked'], [true, 'Picked']] },
    },
    examples: [{ label: 'Picked', ground: 'reading', props: { on: true } }, { label: 'Not picked', ground: 'reading', props: { text: 'switch to tea for a week' } }],
    render(p, ctx) {
      const r = R4(ctx);
      const ring = p.on
        ? `<div style="width:22px;height:22px;border-radius:50%;flex:none;box-sizing:border-box;border:6px solid ${r.accent};background:#2FD08A"></div>`
        : `<div style="width:22px;height:22px;border-radius:50%;flex:none;box-sizing:border-box;border:2px solid ${r.muted}"></div>`;
      return `<div role="button" style="display:flex;align-items:center;gap:8px;min-height:48px;box-sizing:border-box;padding:12px 14px;border-radius:14px;background:${p.on ? r.ink : r.surface};color:${p.on ? r.bg : r.ink}">
        <div style="flex:1;min-width:0;${F('body', { size: 16, weight: 600 })}">${esc(p.text)}</div>${ring}</div>`;
    },
  });

  E({
    type: 'logField', name: 'Plan field', group: 'Log', source: SLIP + ' (talk, "write my own")',
    description: 'A 48 pt field, radius 14, on the reading surface; 16 pt medium words.',
    props: {
      placeholder: { label: 'Placeholder', kind: 'text', default: 'go for a run' },
      value: { label: 'Typed', kind: 'text', default: '' },
    },
    examples: [{ label: 'Empty', ground: 'reading', props: {} }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="min-height:48px;padding:0 14px;display:flex;align-items:center;border-radius:14px;background:${r.surface};${F('body', { size: 16, weight: 500 })}color:${p.value ? r.ink : r.muted}">${esc(p.value || p.placeholder)}</div>`;
    },
  });

  E({
    type: 'logCheckLine', name: 'Ticked line', group: 'Log', source: SLIP + ' (done)',
    description: 'A green filled tick circle and a footnote line: what stays the same after a slip.',
    props: { text: { label: 'Words', kind: 'text', default: 'Still Day 3 clear. Nothing has changed on Today.' } },
    examples: [{ label: 'Day 3', ground: 'reading', props: {} }],
    render(p, ctx) {
      return `<div style="display:flex;align-items:flex-start;gap:8px">${glyph('checkmark.circle.fill', 17, Lab.c(Lab.fill.green, ctx.dark))}${T('footnote', p.text, ctx, { style: 'flex:1;min-width:0' })}</div>`;
    },
  });

  /* ---------- Shared builders ---------- */
  /** TriggerPicker: Sam's triggers, the picked one if it isn't one of theirs, then "More…" (or every trigger once opened). */
  function triggerChips(h, prefix, picked, more, fill) {
    const keys = more ? ORDERED : SAM_TRIGGERS.concat(picked && !SAM_TRIGGERS.includes(picked) ? [picked] : []);
    const chips = keys.map((k) => h('sosChip', `${prefix}-${k}`, { label: TR(k).title, on: picked === k, fill }));
    if (!more) chips.push(h('sosChip', `${prefix}-more`, { label: 'More…', fill }));
    return h('row', `${prefix}s`, { gap: 8, wrap: true }, chips);
  }

  /* ---------- Screen: Craving SOS session (F13) ---------- */
  Lab.screen({
    id: 'sos', name: 'Craving SOS', area: 'SOS', source: SOS + ', ' + V4, ground: 'ocean', fullBleed: true,
    note: 'Opened full screen above everything (fullScreenCover) from the tab bar\'s SOS button, widgets, Siri and links, so there is no tab bar. Jelli is stage 1 (Sam has 3 days clear). The time ridden (0:52, the example in the code) counts up live; the hand-over chip fades after 3 seconds. In the app Xero\'s avatar is 32 pt inside the chip\'s 28 pt slot, so it spills 2 pt each side; drawn as built. Sam\'s reason has no photo. "Still strong" opens Calm tools (screen "calm"); "I slipped" opens the slip flow; "Text a friend" opens the share sheet with "Having a craving right now. Could you talk for five minutes?".',
    statusInk: () => CREAM,
    states: [
      { id: 'start', label: 'Just opened · 0:00' },
      { id: 'riding', label: 'Riding it · 0:52' },
      { id: 'no-reason', label: 'Before onboarding · no reason' },
    ],
    build(h, state) {
      const s = state.id;
      return h('sosFrame', 'frame', { backdrop: 'water' }, [
        h('sosTopBar', 'top-bar', { chip: s === 'riding' ? 'faded' : 'shown' }),
        h('stack', 'session', { padX: 20, padTop: 8, padBottom: 16, gap: 14, style: 'flex:1' }, [
          h('sosCrew', 'jelli', { art: 'jelli:breathe', size: 200, frame: 220, stage: 1 }),
          h('sosBreathWords', 'breath-words', {}),
          h('sosRiddenLine', 'ridden', { clock: s === 'riding' ? "You've ridden 0:52." : "You've ridden 0:00.", alts: { clock: ["You've ridden 0:00.", "You've ridden 0:52."] } }),
          s === 'no-reason' ? null : h('stack', 'reason-wrap', { padTop: 10 }, [h('sosReasonCard', 'reason', {})]),
        ]),
        h('stack', 'actions', { padX: 20, gap: 8 }, [
          h('row', 'action-buttons', { gap: 8 }, [
            h('button', 'passed', { label: 'It passed' }),
            h('sosSolidPill', 'strong', {}),
          ]),
          h('sosQuietLinks', 'links', {}),
        ]),
      ]);
    },
  });

  /* ---------- Screen: Passed (F14) ---------- */
  Lab.screen({
    id: 'sos-passed', name: 'Craving SOS · Passed', area: 'SOS', source: SOS + ' (PassedView)', ground: 'sky', fullBleed: true,
    note: 'Shown after "It passed", on the sky ("relief after a wave"), not the sun. Jelli cheers at stage 2 (fixed in the code, whatever the days clear). Sam had ridden out 14 waves before this one; the count ticks to 15 and "+1" pops in 1.2 seconds after the screen opens. "2 minutes, 10 seconds" is the example in the code; the real line uses the session length (seconds only under a minute). The rising rings are drawn at their Reduce Motion positions. The trigger is optional and saved with "Back to my day".',
    states: [
      { id: 'ticked', label: 'After the tick · 15 waves' },
      { id: 'opening', label: 'Opening · 14 waves' },
      { id: 'coffee', label: 'Coffee picked' },
      { id: 'more', label: '"More…" opened' },
    ],
    build(h, state) {
      const s = state.id;
      return h('sosFrame', 'frame', { backdrop: 'bubbles' }, [
        h('stack', 'passed', { padX: 20, padTop: 16, padBottom: 16, gap: 10, style: 'flex:1' }, [
          h('sosCrew', 'jelli', { art: 'jelli:cheer', size: 200, frame: 230, align: 'flex-end', stage: 2 }),
          h('text', 'title', { step: 'large', align: 'center', text: 'You rode it out.' }),
          h('stack', 'lasted-wrap', { padX: 8 }, [
            h('text', 'lasted', { step: 'body', tone: 'muted', align: 'center', text: 'That wave lasted 2 minutes, 10 seconds. Each one you ride makes the next a little quieter.' }),
          ]),
          h('stack', 'waves-wrap', { padTop: 6 }, [
            h('sosWavesTile', 'waves', { count: s === 'opening' ? '14' : '15', plus: s !== 'opening', alts: { count: ['14', '15'] } }),
          ]),
          h('sosCard', 'trigger-card', { fill: 'sky', gap: 10 }, [
            h('sosAsideLine', 'trigger-ask', {}),
            triggerChips(h, 'trigger', s === 'coffee' ? 'coffee' : null, s === 'more', 'sky'),
          ]),
          h('sosHandBack', 'hand-back', {}),
        ]),
        h('stack', 'done-wrap', { padX: 22 }, [h('button', 'done', { label: 'Back to my day' })]),
      ]);
    },
  });

  /* ---------- Screen: Log menu (S7.1) ---------- */
  Lab.screen({
    id: 'log-menu', name: 'Log sheet', area: 'Log', source: LOG, ground: 'reading',
    note: 'A sheet over Today (Today is not drawn behind it here), opened from Home, Progress, the widget and Siri. Half height, with a full-height detent. Sam logs cigarettes (main) and a vape; "0 today" assumes nothing logged yet today. From Quit Day a use is a slip and opens the slip flow; before it, a tap logs the use and closes the sheet.',
    states: [
      { id: 'day3', label: 'Day 3 · Sun 8 Nov' },
      { id: 'prep', label: 'Prep · Mon 2 Nov' },
    ],
    build(h) { return h('stack', 'behind', {}); },
    overlay(h, state) {
      const slip = state.id === 'day3';
      return h('logSheet', 'sheet', { detent: 'medium' }, [
        h('stack', 'menu', { padX: 16, padTop: 16, padBottom: 16, gap: 8 }, [
          h('stack', 'title-wrap', { padBottom: 8 }, [h('text', 'title', { step: 'title', text: 'Log' })]),
          h('logRow', 'craving', {}),
          h('stack', 'used-wrap', { padTop: 12 }, [h('text', 'used', { step: 'caption', tone: 'muted', text: 'I used' })]),
          h('logRow', 'use-cigarettes', { title: 'Cigarette', detail: '0 today', icon: 'smoke', accent: false, alts: { title: ['Vaped', 'Pouch'] } }),
          h('logRow', 'use-vape', { title: 'Vaped', detail: '0 today', icon: 'wind', accent: false, alts: { title: ['Cigarette', 'Pouch'] } }),
          slip ? h('stack', 'slip-note-wrap', { padTop: 8 }, [
            h('text', 'slip-note', { step: 'footnote', tone: 'muted', align: 'center', text: 'A use after Quit Day is logged as a slip. Nothing resets.' }),
          ]) : null,
        ]),
      ]);
    },
  });

  /* ---------- Screen: Craving form (S7.2) ---------- */
  Lab.screen({
    id: 'log-craving', name: 'Log a craving', area: 'Log', source: LOG + ' (CravingLogForm)', ground: 'reading',
    note: 'The log sheet at full height. The date line is when the form opened, in the phone\'s format (US English shown; the alternative is UK English). The slider starts at 5. In the app the slider sits in a 110 pt frame, a little shorter than its own content (about 119 pt), so it runs into the gap below. "Add details" is the same form opened from Today or Progress for a logged use: no slider (it is not a craving) and no SOS link.',
    states: [
      { id: 'fresh', label: 'Opened · nothing picked' },
      { id: 'sam', label: 'Sam · 6, Coffee, Day 3 09:40' },
      { id: 'details', label: 'Add details · a logged use' },
    ],
    build(h) { return h('stack', 'behind', {}); },
    overlay(h, state) {
      const s = state.id;
      const sam = s === 'sam', details = s === 'details';
      const date = 'Sun, Nov 8, 9:40 AM';
      return h('logSheet', 'sheet', { detent: 'large', grabber: !details }, [
        h('stack', 'form', { padX: 16, padTop: 16, padBottom: 16, gap: 12, style: 'flex:1;min-height:0;overflow:auto' }, [
          h('stack', 'head', { gap: 2 }, [
            h('text', 'title', { step: 'title', text: details ? 'Add details' : 'A craving', alts: { text: ['A craving', 'Add details'] } }),
            h('text', 'when', { step: 'footnote', tone: 'muted', text: date, alts: { text: ['Sun 8 Nov, 09:40'] } }),
          ]),
          details ? null : h('cravingSlider', 'strength', { value: sam ? 6 : 5 }),
          h('stack', 'trigger-section', { padTop: 8, gap: 8 }, [
            h('sosAsideLine', 'trigger-label', { text: 'What set it off?', aside: '', style: 'caption' }),
            h('row', 'triggers', { gap: 8, wrap: true }, ORDERED.map((k) => h('sosChip', 'trigger-' + k, { label: TR(k).title, on: sam && k === 'coffee', boldOn: true }))),
          ]),
          h('stack', 'mood-section', { padTop: 8, gap: 8 }, [
            h('sosAsideLine', 'mood-label', { text: 'Mood', style: 'caption' }),
            h('logMoodRow', 'moods', {}),
          ]),
          h('stack', 'place-section', { padTop: 8, gap: 8 }, [
            h('sosAsideLine', 'place-label', { text: 'Where?', style: 'caption' }),
            h('row', 'places', { gap: 8, wrap: true }, PLACES.map((pl) => h('sosChip', 'place-' + pl.toLowerCase(), { label: pl, boldOn: true }))),
          ]),
        ]),
        h('stack', 'actions', { padX: 16, padBottom: 8, gap: 4 }, [
          h('button', 'save', { label: 'Save' }),
          details ? null : h('button', 'sos', { label: 'Ride it out with SOS instead', kind: 'quiet' }),
        ]),
      ]);
    },
  });

  /* ---------- Screen: Slip, thanks and a plan (F15) ---------- */
  const SLIP_NOTE = 'Opened from Craving SOS ("I slipped", full screen, as drawn) or from the log sheet (full height). The slip is already saved; this only adds details. ';
  Lab.screen({
    id: 'log-slip', name: 'Slip · thanks and a plan', area: 'Log', source: SLIP, ground: 'reading', fullBleed: true,
    note: SLIP_NOTE + 'Jelli is stage 2 here (fixed in the code). With no trigger picked the plan reads "a strong craving" with those ideas. Sam\'s picks: Coffee and "have it somewhere new" (the third idea, as the debug prefill picks). "Save my plan" stays at half strength until a plan is chosen. Practice is Program Day 27\'s rehearsal, where nothing is logged.',
    states: [
      { id: 'empty', label: 'Day 3 · nothing picked' },
      { id: 'coffee', label: 'Day 3 · Coffee, plan picked' },
      { id: 'own', label: 'Day 3 · write my own' },
      { id: 'more', label: '"More…" opened' },
      { id: 'prep', label: 'Prep · Mon 2 Nov' },
      { id: 'practice', label: 'Practice · Program Day 27' },
    ],
    build(h, state) {
      const s = state.id;
      const trigger = s === 'coffee' || s === 'own' ? 'coffee' : null;
      const t = TR(trigger || 'other');
      const action = s === 'coffee' ? t.ideas[2] : null;
      const ready = !!action;
      return h('sosFrame', 'frame', { backdrop: 'none' }, [
        h('logStepBar', 'step-bar', { step: 2 }),
        s === 'practice' ? h('logPracticeTag', 'practice', {}) : null,
        h('stack', 'talk', { padX: 20, padTop: 14, padBottom: 16, gap: 14, style: 'flex:1' }, [
          h('row', 'header', { gap: 14 }, [
            h('sosCrew', 'jelli', { art: 'jelli:calm', size: 88, frame: 88, backing: 'ocean', radius: 26, stage: 2 }),
            h('stack', 'header-words', { gap: 2 }, [
              h('text', 'with', { step: 'footnote', weight: 700, tone: 'muted', text: 'With Jelli' }),
              h('markedTitle', 'thanks', { lead: 'Thanks for', word: 'telling me', trail: '.', stacked: true, step: 'large', mark: 'underline' }),
            ]),
          ]),
          h('text', 'nothing-resets', {
            step: 'body', tone: 'muted',
            text: s === 'prep' ? "Logged. Prep is for learning your patterns, and this helps. Let's make a plan for next time." : "Waves come and go. Nothing resets: your days clear and Xero's sky stay just as they are. Let's make a plan for next time.",
            alts: { text: s === 'prep' ? ["Waves come and go. Nothing resets: your days clear and Xero's sky stay just as they are. Let's make a plan for next time."] : ["Logged. Prep is for learning your patterns, and this helps. Let's make a plan for next time."] },
          }),
          h('sosCard', 'plan-card', { fill: 'raised', padX: 16, padY: 16, gap: 12 }, [
            h('text', 'trigger-ask', { step: 'body', size: 16, weight: 700, text: 'What set it off?' }),
            triggerChips(h, 'trigger', trigger, s === 'more', 'surface'),
            h('stack', 'if-wrap', { padTop: 4 }, [
              h('text', 'if', { step: 'headline', text: `If it's ${t.situation}, then I'll…`, alts: { text: SITUATION_ALTS } }),
            ]),
            h('stack', 'options', { gap: 8 }, t.ideas.map((idea, i) => h('logThenOption', 'then-' + (i + 1), {
              text: idea, on: action === idea,
              alts: { text: TRIGGERS.map((x) => x.ideas[i]).filter((x, j, a) => x !== idea && a.indexOf(x) === j) },
            })).concat([
              h('logThenOption', 'then-own', { text: 'write my own', on: s === 'own' }),
              s === 'own' ? h('logField', 'own-field', {}) : null,
            ])),
          ]),
        ]),
        h('stack', 'actions', { padX: 22, padBottom: 8, gap: 4 }, [
          h('button', 'save', { label: 'Save my plan', disabled: !ready }),
          h('button', 'not-now', { label: 'Not now', kind: 'quiet' }),
        ]),
      ]);
    },
  });

  /* ---------- Screen: Plan saved ---------- */
  Lab.screen({
    id: 'log-slip-saved', name: 'Slip · plan saved', area: 'Log', source: SLIP + ' (done)', ground: 'reading', fullBleed: true,
    note: SLIP_NOTE + 'Sam\'s plan: after coffee, have it somewhere new. "Still Day 3 clear" uses Sam\'s 3 days clear. The tough-day card shows from the third slip in a day. Its two chips use the reading surface on a card that is also the reading surface, so in the app they barely show; drawn as built. "Add what happened" is missing in Practice (nothing is logged).',
    states: [
      { id: 'saved', label: 'Day 3 · plan saved' },
      { id: 'tough', label: 'Day 3 · third slip today' },
      { id: 'prep', label: 'Prep · Mon 2 Nov' },
    ],
    build(h, state) {
      const s = state.id;
      return h('sosFrame', 'frame', { backdrop: 'none' }, [
        h('logStepBar', 'step-bar', { step: 3 }),
        h('stack', 'done', { padX: 20, padTop: 20, padBottom: 16, gap: 14, style: 'flex:1' }, [
          h('text', 'title', { step: 'large', text: 'Plan saved' }),
          h('text', 'line', { step: 'body', tone: 'muted', text: "Every slip shows you something about your cravings. Now you've got a plan for this one." }),
          h('sosCard', 'plan', { fill: 'surface', padX: 16, padY: 16, gap: 4 }, [
            h('text', 'plan-kicker', { step: 'caption', tone: 'muted', text: 'Your plan' }),
            h('text', 'plan-text', { step: 'headline', text: "If it's after coffee, then I'll have it somewhere new." }),
          ]),
          h('logCheckLine', 'unchanged', {
            text: s === 'prep' ? 'Prep carries on as planned.' : 'Still Day 3 clear. Nothing has changed on Today.',
            alts: { text: s === 'prep' ? ['Still Day 3 clear. Nothing has changed on Today.'] : ['Prep carries on as planned.'] },
          }),
          s === 'tough' ? h('sosCard', 'tough', { fill: 'surface', padX: 16, padY: 16, gap: 10 }, [
            h('text', 'tough-text', { step: 'footnote', text: "It's been a tough day. That happens, especially early on. Want to look at NRT options, or go over your plan again?" }),
            h('row', 'tough-buttons', { gap: 8 }, [
              h('sosChip', 'nrt', { label: 'Look at NRT' }),
              h('sosChip', 'replan', { label: 'Go over my plan' }),
            ]),
          ]) : null,
        ]),
        h('stack', 'actions', { padX: 22, padBottom: 8, gap: 4 }, [
          h('button', 'back', { label: 'Back to Today' }),
          h('button', 'what', { label: 'Add what happened · optional', kind: 'quiet' }),
        ]),
      ]);
    },
  });

  /* ---------- Screen: What happened (optional) ---------- */
  const AMOUNTS = { cigarettes: ['A few drags', 'One', 'More'], vape: ['A few puffs', 'One session', 'More'], pouches: ['Briefly', 'One pouch', 'More'] };
  Lab.screen({
    id: 'log-slip-what', name: 'Slip · what happened', area: 'Log', source: SLIP + ' (what)', ground: 'reading', fullBleed: true,
    note: SLIP_NOTE + '"What did you have?" shows because Sam uses two products. The product starts on the logged one (cigarettes, the main product), so the amounts read for cigarettes; picking Vape changes them to "A few puffs" and "One session". "Just now" is picked from the start.',
    states: [
      { id: 'opened', label: 'Opened · Cigarettes, Just now' },
      { id: 'picked', label: 'Cigarettes · One · Just now' },
      { id: 'vape', label: 'Vape · One session' },
    ],
    build(h, state) {
      const s = state.id;
      const product = s === 'vape' ? 'vape' : 'cigarettes';
      const am = AMOUNTS[product];
      const amount = s === 'opened' ? null : 1;
      const label = (id, text) => h('stack', id + '-wrap', { padTop: 12 }, [h('text', id, { step: 'caption', tone: 'muted', text })]);
      return h('sosFrame', 'frame', { backdrop: 'none' }, [
        h('logStepBar', 'step-bar', { step: 3, icon: 'chevron.left' }),
        h('stack', 'what', { padX: 20, padTop: 20, padBottom: 16, gap: 12, style: 'flex:1' }, [
          h('text', 'title', { step: 'large', text: 'What happened?' }),
          h('text', 'line', { step: 'body', tone: 'muted', text: 'No judgement, just the facts so we can plan.' }),
          label('product-label', 'What did you have?'),
          h('row', 'products', { gap: 8, wrap: true }, [
            h('sosChip', 'product-cigarettes', { label: 'Cigarettes', on: product === 'cigarettes' }),
            h('sosChip', 'product-vape', { label: 'Vape', on: product === 'vape' }),
          ]),
          label('amount-label', 'How much?'),
          h('row', 'amounts', { gap: 8, wrap: true }, am.map((a, i) => h('sosChip', 'amount-' + i, {
            label: a, on: amount === i, alts: { label: [AMOUNTS.cigarettes[i], AMOUNTS.vape[i], AMOUNTS.pouches[i]].filter((x, j, arr) => x !== a && arr.indexOf(x) === j) },
          }))),
          label('when-label', 'When?'),
          h('row', 'whens', { gap: 8, wrap: true }, [
            h('sosChip', 'when-now', { label: 'Just now', on: true }),
            h('sosChip', 'when-earlier', { label: 'Earlier today' }),
            h('sosChip', 'when-yesterday', { label: 'Yesterday' }),
          ]),
        ]),
        h('stack', 'actions', { padX: 22, padBottom: 8 }, [h('button', 'save', { label: 'Save' })]),
      ]);
    },
  });
})();
