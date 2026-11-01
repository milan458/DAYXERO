/* Me: Settings and side tools. DayXero/Settings/SettingsView.swift (SettingsSheet and every page it pushes),
   DayXero/Daily/NotificationSettingsView.swift (+ QuietHoursView), DayXero/Daily/CheckInView.swift (DayEndSettings),
   DayXero/NRT/ (NRTSetupView, StepEditor, TaperSetupView, NRTCards), DayXero/Water/ (WaterTrackerView, WaterGoalSheet,
   WaterPillView, DrinkIllustration, WaterHomeCard). See ../FORMAT.md. */
(function () {
  'use strict';
  const Lab = window.Lab;
  const E = Lab.element, esc = Lab.esc, T = Lab.text, F = Lab.font;
  const SET = 'DayXero/Settings/SettingsView.swift';
  const NOTI = 'DayXero/Daily/NotificationSettingsView.swift';
  const DAYEND = 'DayXero/Daily/CheckInView.swift (DayEndSettings)';
  const NRT = 'DayXero/NRT/NRTSetupView.swift';
  const NRTC = 'DayXero/NRT/NRTCards.swift';
  const WT = 'DayXero/Water/WaterTrackerView.swift';
  const WG = 'DayXero/Water/WaterGoalSheet.swift';
  const WP = 'DayXero/Water/WaterPillView.swift';
  const DI = 'DayXero/Water/DrinkIllustration.swift';
  const WH = 'DayXero/Water/WaterHomeCard.swift';
  const ONB = 'DayXero/Onboarding/OnboardingV4.swift (OnbOptionCard)';
  const V4R = 'DayXero/Shared/V4Reading.swift';
  const CREAM = Lab.CREAM, SAGE = '#BCC388';

  /* ---------- Colours ---------- */
  /** Read4 (DayXero/Shared/V4Reading.swift): the reading tier for the appearance. */
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
      accentTint: d ? 'rgba(47,208,138,0.12)' : 'rgba(15,110,67,0.12)',
      amber: d ? '#E5A93C' : '#8A5E0E',
      amberRGB: d ? '229,169,60' : '138,94,14',
    };
  }
  /** iOS system colours inside a sheet (grouped list, elevated in dark), plus the app's tints. */
  function SYS(ctx) {
    const d = ctx.dark;
    return {
      bg: d ? '#1C1C1E' : '#F2F2F7',
      cell: d ? '#2C2C2E' : '#FFFFFF',
      label: d ? '#FFFFFF' : '#000000',
      secondary: d ? 'rgba(235,235,245,0.6)' : 'rgba(60,60,67,0.6)',
      tertiary: d ? 'rgba(235,235,245,0.3)' : 'rgba(60,60,67,0.3)',
      sep: d ? 'rgba(84,84,88,0.65)' : 'rgba(60,60,67,0.29)',
      fill: d ? 'rgba(118,118,128,0.24)' : 'rgba(118,118,128,0.12)',
      red: d ? '#FF453A' : '#FF3B30',
      // The AccentColor asset (DayXero/Resources/Assets.xcassets): the old sage, not Read4.accent.
      app: d ? '#BCC388' : '#55621F',
      accent: Lab.c(Lab.fill.green, d),
    };
  }
  const SF = "-apple-system, 'SF Pro Text', system-ui, sans-serif";
  const TRACK = { 34: 0.4, 17: -0.43, 15: -0.23, 13: -0.08, 12: 0 };
  /** San Francisco, as system List rows, bars and alerts draw it. */
  const sf = (size, weight) => `font-family:${SF};font-size:${size}px;font-weight:${weight || 400};line-height:1.29;letter-spacing:${TRACK[size] != null ? TRACK[size] : 0}px;`;
  const subtitle = (str, ctx, extra) => `<div style="${F('footnote')}color:${R4(ctx).muted};${extra || ''}">${esc(str)}</div>`;

  /* ---------- SF Symbols this file needs that lab.js doesn't draw ---------- */
  const st = (d, w) => `<path d="${d}" fill="none" stroke="currentColor" stroke-width="${w || 2}" stroke-linecap="round" stroke-linejoin="round"/>`;
  const G = {
    cloud: st('M7 18.5h10a4 4 0 0 0 .7-7.94A5.5 5.5 0 0 0 7.4 9.1 4.7 4.7 0 0 0 7 18.5z'),
    moon: st('M15.5 3.5a8.5 8.5 0 1 0 5 13.6A7 7 0 0 1 15.5 3.5z'),
    banknote: '<rect x="2.5" y="6.5" width="19" height="11" rx="2" fill="none" stroke="currentColor" stroke-width="2"/><circle cx="12" cy="12" r="2.6" fill="none" stroke="currentColor" stroke-width="2"/><circle cx="6" cy="12" r="1" fill="currentColor"/><circle cx="18" cy="12" r="1" fill="currentColor"/>',
    bell: st('M6.5 16.5V11a5.5 5.5 0 0 1 11 0v5.5l1.5 2h-14z') + st('M10 20.5a2 2 0 0 0 4 0'),
    'water.waves': st('M3 8c2-2 4-2 6 0s4 2 6 0 4-2 6 0M3 12.5c2-2 4-2 6 0s4 2 6 0 4-2 6 0M3 17c2-2 4-2 6 0s4 2 6 0 4-2 6 0'),
    'circle.lefthalf.filled': '<circle cx="12" cy="12" r="8.5" fill="none" stroke="currentColor" stroke-width="2"/><path d="M12 3.5a8.5 8.5 0 0 0 0 17z" fill="currentColor"/>',
    'sparkles.rectangle.stack': '<rect x="3.5" y="8" width="17" height="12.5" rx="2.5" fill="none" stroke="currentColor" stroke-width="2"/>' + st('M6.5 4.8h11') + '<path d="M12 10.5l1 2.6 2.6 1-2.6 1-1 2.6-1-2.6-2.6-1 2.6-1z" fill="currentColor"/>',
    'eye.slash': st('M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z') + '<circle cx="12" cy="12" r="3" fill="none" stroke="currentColor" stroke-width="2"/>' + st('M4 4l16 16'),
    'apps.iphone': '<rect x="5.5" y="2.5" width="13" height="19" rx="3" fill="none" stroke="currentColor" stroke-width="2"/><rect x="8.5" y="7" width="2.6" height="2.6" rx=".7" fill="currentColor"/><rect x="12.9" y="7" width="2.6" height="2.6" rx=".7" fill="currentColor"/><rect x="8.5" y="11.4" width="2.6" height="2.6" rx=".7" fill="currentColor"/><rect x="12.9" y="11.4" width="2.6" height="2.6" rx=".7" fill="currentColor"/>',
    star: st('M12 3.5l2.6 5.4 5.9.8-4.3 4.1 1 5.9L12 16.9l-5.2 2.8 1-5.9-4.3-4.1 5.9-.8z'),
    lock: '<rect x="5" y="10.5" width="14" height="10" rx="2.5" fill="none" stroke="currentColor" stroke-width="2"/>' + st('M8 10.5V8a4 4 0 0 1 8 0v2.5'),
    'square.and.arrow.up': st('M8.5 9.5H7a2 2 0 0 0-2 2v7.5a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-7.5a2 2 0 0 0-2-2h-1.5M12 3v11.5M8.5 6.5L12 3l3.5 3.5'),
    trash: st('M4.5 6.5h15M9.5 6.5v-2h5v2M6.5 6.5l1 13a1.5 1.5 0 0 0 1.5 1.5h6a1.5 1.5 0 0 0 1.5-1.5l1-13M10 10.5v6M14 10.5v6'),
    heart: st('M12 20s-7.5-4.6-7.5-10A4.3 4.3 0 0 1 12 7.4 4.3 4.3 0 0 1 19.5 10c0 5.4-7.5 10-7.5 10z'),
    'doc.text': st('M6.5 3h7.5l4.5 4.5v12a1.5 1.5 0 0 1-1.5 1.5H6.5A1.5 1.5 0 0 1 5 19.5v-15A1.5 1.5 0 0 1 6.5 3zM14 3v4.5h4.5M8.5 12h7M8.5 15.5h7'),
    doc: st('M6.5 3h7.5l4.5 4.5v12a1.5 1.5 0 0 1-1.5 1.5H6.5A1.5 1.5 0 0 1 5 19.5v-15A1.5 1.5 0 0 1 6.5 3zM14 3v4.5h4.5'),
    iphone: '<rect x="6.5" y="2.5" width="11" height="19" rx="2.8" fill="none" stroke="currentColor" stroke-width="2"/>' + st('M10.5 5.2h3'),
    'chart.bar': st('M5 20v-6M10 20V8M15 20v-9M20 20V5', 2.6),
    'sun.max': '<circle cx="12" cy="12" r="4" fill="none" stroke="currentColor" stroke-width="2"/>' + st('M12 2.5V5M12 19v2.5M2.5 12H5M19 12h2.5M5.3 5.3l1.8 1.8M16.9 16.9l1.8 1.8M5.3 18.7l1.8-1.8M16.9 7.1l1.8-1.8'),
    flag: st('M6 21V4M6 4.5h11l-2.5 4 2.5 4H6'),
    bandage: '<g transform="rotate(-45 12 12)"><rect x="2.5" y="8" width="19" height="8" rx="4" fill="none" stroke="currentColor" stroke-width="2"/><path d="M9 8v8M15 8v8" stroke="currentColor" stroke-width="1.6"/></g>',
    minus: st('M5 12h14', 2.6),
    'chevron.up.chevron.down': st('M8 9.5l4-4 4 4M8 14.5l4 4 4-4', 2.4),
    'checkmark.circle.fill': '<circle cx="12" cy="12" r="10" fill="currentColor"/><path d="M7.5 12.3l3 3 6-6.3" fill="none" style="stroke:var(--on,#fff)" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>',
    circle: '<circle cx="12" cy="12" r="9.5" fill="none" stroke="currentColor" stroke-width="1.6"/>',
    'square.grid.2x2': '<rect x="4" y="4" width="7" height="7" rx="1.6" fill="none" stroke="currentColor" stroke-width="2"/><rect x="13" y="4" width="7" height="7" rx="1.6" fill="none" stroke="currentColor" stroke-width="2"/><rect x="4" y="13" width="7" height="7" rx="1.6" fill="none" stroke="currentColor" stroke-width="2"/><rect x="13" y="13" width="7" height="7" rx="1.6" fill="none" stroke="currentColor" stroke-width="2"/>',
    capsule: '<g transform="rotate(-40 12 12)"><rect x="3" y="8.3" width="18" height="7.4" rx="3.7" fill="none" stroke="currentColor" stroke-width="2"/><path d="M12 8.3v7.4" stroke="currentColor" stroke-width="2"/></g>',
    lungs: st('M12 3.5v7.5M12 10.5c-1.2 1-2.2 1.6-3.2 1.6M12 10.5c1.2 1 2.2 1.6 3.2 1.6') + st('M8.6 7C5.6 8 4 12 4 16c0 2.5 1.5 3.6 3.5 3.1 2-.5 2.6-2 2.6-4V9.6C10.1 8.1 9.6 6.7 8.6 7zM15.4 7c3 1 4.6 5 4.6 9 0 2.5-1.5 3.6-3.5 3.1-2-.5-2.6-2-2.6-4V9.6c0-1.5.5-2.9 1.5-2.6z'),
    drop: st('M12 3.5c3.5 4.5 6 7.7 6 10.5a6 6 0 0 1-12 0c0-2.8 2.5-6 6-10.5z', 1.4),
    magnifyingglass: '<circle cx="10.5" cy="10.5" r="6" fill="none" stroke="currentColor" stroke-width="2.2"/>' + st('M15 15l5 5', 2.4),
    'doc.on.doc': st('M8.5 7.5V5a1.5 1.5 0 0 1 1.5-1.5h8A1.5 1.5 0 0 1 19.5 5v10a1.5 1.5 0 0 1-1.5 1.5h-2.5') + '<rect x="4.5" y="7.5" width="11" height="13" rx="1.5" fill="none" stroke="currentColor" stroke-width="2"/>',
    folder: st('M3.5 7a1.5 1.5 0 0 1 1.5-1.5h4.5l2 2.5H19a1.5 1.5 0 0 1 1.5 1.5v8.5A1.5 1.5 0 0 1 19 19.5H5A1.5 1.5 0 0 1 3.5 18z'),
  };
  function glyph(name, size, colour, extra) {
    if (G[name]) return `<svg viewBox="0 0 24 24" width="${size}" height="${size}" style="color:${colour};flex:none;display:block;${extra || ''}" aria-hidden="true">${G[name]}</svg>`;
    return Lab.icon(name, size, colour, extra);
  }
  const GLYPH_OPTS = [['', 'None']].concat(Object.keys(G).concat(['calendar', 'clock', 'book.closed', 'info.circle', 'plus', 'xmark', 'checkmark', 'chevron.left', 'waveform']).map((n) => [n, n]));

  /* ---------- System pieces: sheet, bar, grouped list ---------- */
  E({
    type: 'settingsSheet', name: 'Page sheet', group: 'Settings', source: SET + ' (.sheet from Home)',
    description: 'The iOS page sheet that Settings, the product editor and the water goal open in: black behind, the screen it came from peeking at the top, then the sheet with rounded top corners.',
    props: {
      top: { label: 'Sheet starts at', kind: 'number', options: [62, 72, 84, 96, 120, 200, 300, 400, 437, 500], unit: ' pt from the top', default: 72 },
      radius: { label: 'Corner radius', kind: 'number', options: [10, 14, 20, 28, 38], unit: ' pt', default: 38, global: true },
      behind: { label: 'Behind it', kind: 'select', default: 'reading', options: [['reading', 'Today (reading ground)'], ['sheet', 'Another sheet (stacked)'], ['black', 'Water tracker (black)']] },
      fill: { label: 'Sheet colour', kind: 'select', default: 'grouped', options: [['grouped', 'System grouped grey (lists)'], ['reading', 'Reading ground (Read4)']] },
    },
    examples: [{ label: 'Settings sheet', ground: 'reading', props: { top: 72 }, kids: [['text', { step: 'body', text: 'Settings' }]] }],
    render(p, ctx, kids) {
      const s = SYS(ctx);
      const lib = ctx.screenId === '_lib' || !ctx.device;
      const d = ctx.device || { h: 874, bottom: 34 };
      const fill = p.fill === 'reading' ? R4(ctx).bg : s.bg;
      const behind = p.behind === 'black' ? '#000' : p.behind === 'sheet' ? s.bg : Lab.ground('reading', ctx.dark).bg;
      const top = lib ? 28 : p.top;
      const peek = p.behind === 'sheet'
        ? `<div style="position:absolute;left:20px;right:20px;top:${top - 22}px;height:60px;border-radius:${p.radius}px ${p.radius}px 0 0;background:${behind};opacity:.5"></div><div style="position:absolute;left:12px;right:12px;top:${top - 11}px;height:60px;border-radius:${p.radius}px ${p.radius}px 0 0;background:${behind};opacity:.7"></div>`
        : `<div style="position:absolute;left:12px;right:12px;top:${top - 11}px;height:60px;border-radius:${p.radius}px ${p.radius}px 0 0;background:${behind};opacity:${p.behind === 'black' ? 1 : 0.55};${p.behind === 'black' ? 'box-shadow:inset 0 0 0 1px rgba(255,255,255,.08);' : ''}"></div>`;
      return `<div style="flex:1;position:relative;display:flex;flex-direction:column;background:#000;padding-top:${top}px;${lib ? 'min-height:300px;' : `min-height:${d.h}px;margin-bottom:-${d.bottom + 12}px;`}">${peek}
        <div style="position:relative;flex:1;display:flex;flex-direction:column;background:${fill};border-radius:${p.radius}px ${p.radius}px 0 0;padding-bottom:${lib ? 16 : d.bottom + 8}px">${kids()}</div></div>`;
    },
  });

  E({
    type: 'settingsNavBar', name: 'Navigation bar', group: 'Settings', source: SET + ' (NavigationStack toolbar)',
    description: 'The system bar: a glass back or close circle, an inline title or a small-capitals step label, a glass "Done", and the 34 pt large title under it.',
    props: {
      title: { label: 'Title', kind: 'text', default: '' },
      mode: { label: 'Title style', kind: 'select', default: 'large', options: [['large', 'Large, under the bar'], ['inline', 'Small, in the bar'], ['none', 'No title']] },
      leading: { label: 'Left button', kind: 'select', default: '', options: [['', 'None'], ['back', 'Back'], ['xmark', 'Close']] },
      trailing: { label: 'Right button', kind: 'text', default: '' },
      principal: { label: 'Step label (centre)', kind: 'text', default: '' },
      tint: { label: 'Button colour', kind: 'select', default: 'label', global: true, options: [['label', 'Black or white (iOS 26 glass)'], ['app', 'AccentColor sage #55621F (iOS 18)'], ['green', 'Read4 green']] },
      padTop: { label: 'Top padding', kind: 'number', options: [0, 4, 8, 12, 16], unit: ' pt', default: 8 },
    },
    examples: [{ label: 'Settings', ground: 'reading', props: { title: 'Settings', trailing: 'Done' } }, { label: 'NRT step', ground: 'reading', props: { mode: 'none', leading: 'back', principal: 'What you use' } }],
    render(p, ctx) {
      const s = SYS(ctx);
      const ink = p.tint === 'app' ? s.app : p.tint === 'green' ? s.accent : s.label;
      const glass = `background:${ctx.dark ? 'rgba(120,120,128,0.36)' : 'rgba(255,255,255,0.86)'};box-shadow:${ctx.dark ? 'inset 0 0 0 .5px rgba(255,255,255,.14)' : '0 2px 10px rgba(0,0,0,.08), inset 0 0 0 .5px rgba(0,0,0,.06)'};`;
      const circ = (icon, label) => `<div role="button" aria-label="${label}" style="width:44px;height:44px;border-radius:50%;${glass}display:flex;align-items:center;justify-content:center;flex:none">${Lab.icon(icon, 17, ink)}</div>`;
      const left = p.leading === 'back' ? circ('chevron.left', 'Back') : p.leading === 'xmark' ? circ('xmark', 'Close') : '<div style="width:44px;flex:none"></div>';
      const right = p.trailing ? `<div role="button" style="height:44px;padding:0 16px;border-radius:22px;${glass}display:flex;align-items:center;flex:none;${sf(17, 600)}color:${ink}">${esc(p.trailing)}</div>` : '<div style="width:44px;flex:none"></div>';
      const centre = p.mode === 'inline' && p.title
        ? `<div style="flex:1;min-width:0;text-align:center;${sf(17, 600)}color:${s.label};white-space:nowrap;overflow:hidden;text-overflow:ellipsis">${esc(p.title)}</div>`
        : p.principal ? T('caption', p.principal, ctx.with({ groundName: 'reading' }), { tone: 'muted', align: 'center', style: 'flex:1;min-width:0' }) : '<div style="flex:1"></div>';
      const large = p.mode === 'large' && p.title ? `<div style="padding:8px 16px 2px;${sf(34, 700)}line-height:1.2;color:${s.label}">${esc(p.title)}</div>` : '';
      return `<div style="display:flex;flex-direction:column;padding-top:${p.padTop}px;flex:none"><div style="display:flex;align-items:center;gap:8px;padding:0 16px;min-height:44px">${left}${centre}${right}</div>${large}</div>`;
    },
  });

  const SEP_CSS = '<style>.dxs-sec .dxs-row + .dxs-sep::before{content:"";position:absolute;top:0;right:0;left:var(--sep);height:.5px;background:var(--dxs-sep)}</style>';
  E({
    type: 'settingsSection', name: 'List section', group: 'Settings', source: SET + ' (List, inset grouped)',
    description: 'One inset-grouped section: a small grey header, the rows on a rounded white card with hairlines between them, and a grey footer.',
    props: {
      header: { label: 'Header', kind: 'text', default: '' },
      footer: { label: 'Footer', kind: 'text', default: '' },
      footerAlign: { label: 'Footer align', kind: 'select', default: 'left', options: [['left', 'Left'], ['center', 'Centre']] },
      footerTop: { label: 'Space above the footer', kind: 'number', options: [7, 12, 19], unit: ' pt', default: 7 },
      gap: { label: 'Space above', kind: 'number', options: [0, 8, 12, 16, 20, 24, 28, 35], unit: ' pt', default: 24 },
      padX: { label: 'Side margin', kind: 'number', options: [16, 20], unit: ' pt', default: 16, global: true },
      radius: { label: 'Corner radius', kind: 'number', options: [10, 12, 20, 26], unit: ' pt', default: 26, global: true },
      headerCase: { label: 'Header capitals', kind: 'select', default: 'upper', global: true, options: [['upper', 'ALL CAPS (SwiftUI default)'], ['as', 'As written']] },
      fill: { label: 'Row colour', kind: 'select', default: 'cell', options: [['cell', 'White (system)'], ['amber', 'Amber 14% (warning)']] },
    },
    examples: [{ label: 'Your quit', ground: 'reading', props: { header: 'Your quit' }, kids: [['settingsRow', { label: 'Products', icon: 'cloud', value: 'Cigarettes and Vape' }], ['settingsRow', { label: 'Quit Day', icon: 'calendar', value: 'Fri 6 Nov' }]] }],
    render(p, ctx, kids) {
      const s = SYS(ctx), r = R4(ctx);
      const head = p.header ? `<div style="${sf(13)}color:${s.secondary};padding:0 16px 7px;${p.headerCase === 'upper' ? 'text-transform:uppercase;' : ''}">${esc(p.header)}</div>` : '';
      const foot = p.footer ? `<div style="${sf(13)}color:${s.secondary};padding:${p.footerTop}px 16px 0;text-align:${p.footerAlign}">${esc(p.footer)}</div>` : '';
      const cell = p.fill === 'amber' ? `rgba(${r.amberRGB},0.14)` : s.cell;
      return `<div class="dxs-sec" style="--dxs-sep:${s.sep};padding:${p.gap}px ${p.padX}px 0;flex:none">${SEP_CSS}${head}<div style="background:${cell};border-radius:${p.radius}px;overflow:hidden">${kids()}</div>${foot}</div>`;
    },
  });

  function switchHTML(on, ctx, style) {
    const s = SYS(ctx);
    const ios26 = style !== 'ios18';
    const w = ios26 ? 63 : 51, ht = ios26 ? 28 : 31, kw = ios26 ? 37 : 27, kh = ios26 ? 24 : 27;
    const off = ctx.dark ? 'rgba(120,120,128,0.32)' : 'rgba(120,120,128,0.16)';
    return `<div style="width:${w}px;height:${ht}px;border-radius:${ht}px;background:${on ? s.accent : off};position:relative;flex:none"><div style="position:absolute;top:2px;${on ? 'right:2px' : 'left:2px'};width:${kw}px;height:${kh}px;border-radius:${kh}px;background:#fff;box-shadow:0 2px 4px rgba(0,0,0,.15)"></div></div>`;
  }
  function stepperHTML(ctx, style) {
    const s = SYS(ctx);
    return `<div style="display:flex;align-items:center;width:94px;height:32px;border-radius:${style === 'ios18' ? 8 : 16}px;background:${s.fill};flex:none"><div style="flex:1;display:flex;justify-content:center">${glyph('minus', 16, s.label)}</div><div style="width:1px;height:18px;background:${s.sep}"></div><div style="flex:1;display:flex;justify-content:center">${Lab.icon('plus', 16, s.label)}</div></div>`;
  }
  const toneOf = (t, ctx) => { const s = SYS(ctx), r = R4(ctx); return { label: s.label, ink: r.ink, accent: s.accent, red: s.red, app: s.app, muted: r.muted }[t] || s.label; };

  E({
    type: 'settingsRow', name: 'List row', group: 'Settings', source: SET + ' (SettingLabel, Toggle, Picker, Stepper, DatePicker)',
    description: 'One system row: a 28 pt green icon box (or none), the label and a grey line, and on the right a value with a chevron, a switch, a menu, a tick, a time, a stepper or a typed value.',
    props: {
      label: { label: 'Label', kind: 'text', default: 'Products' },
      ink: { label: 'Words before, in ink', kind: 'text', default: '' },
      detail: { label: 'Line under it', kind: 'text', default: '' },
      value: { label: 'Value', kind: 'text', default: '' },
      kind: { label: 'Kind', kind: 'select', default: 'link', options: [['link', 'Opens a page (chevron)'], ['toggle', 'Switch'], ['menu', 'Menu picker'], ['button', 'Button'], ['check', 'Choice (tick)'], ['time', 'Time picker'], ['date', 'Date picker'], ['stepper', 'Stepper'], ['field', 'Typed value'], ['value', 'Value only'], ['info', 'Words only']] },
      on: { label: 'Switch or tick', kind: 'select', default: true, options: [[true, 'On'], [false, 'Off']] },
      icon: { label: 'Icon', kind: 'select', default: '', options: GLYPH_OPTS },
      iconStyle: { label: 'Icon style', kind: 'select', default: 'box28', options: [['box28', '28 pt rounded box (SettingLabel)'], ['box30', '30 pt rounded box (notifications)'], ['circle30', '30 pt circle (privacy)'], ['plain', 'Plain symbol'], ['none', 'No icon']] },
      font: { label: 'Label type', kind: 'select', default: 'system', options: [['system', 'System 17'], ['dx', 'DM Sans 16 semibold'], ['dxSmall', 'DM Sans 14'], ['subtitle', 'Footnote 14 medium (v4 subtitle)']] },
      tone: { label: 'Label colour', kind: 'select', default: 'label', options: [['label', 'System black/white'], ['ink', 'Read4 ink'], ['accent', 'Read4 green (tint)'], ['red', 'Red (destructive)'], ['app', 'AccentColor sage']] },
      align: { label: 'Line up', kind: 'select', default: 'center', options: [['center', 'Middles'], ['top', 'Tops']] },
      minHeight: { label: 'Minimum height', kind: 'number', options: [0, 36, 44, 52], unit: ' pt', default: 44 },
      padTop: { label: 'Top padding', kind: 'number', options: [0, 4, 8, 11, 15], unit: ' pt', default: 11 },
      padBottom: { label: 'Bottom padding', kind: 'number', options: [0, 4, 8, 11, 15], unit: ' pt', default: 11 },
      inset: { label: 'Side padding', kind: 'number', options: [0, 14, 16, 20], unit: ' pt', default: 16 },
      separator: { label: 'Hairline above', kind: 'bool', labels: ['Show', 'Hide'], default: true },
      disabled: { label: 'State', kind: 'select', default: false, options: [[false, 'Enabled'], [true, 'Disabled (greyed)']] },
      switchStyle: { label: 'Switch and stepper shape', kind: 'select', default: 'ios26', global: true, options: [['ios26', 'iOS 26 (wide switch, capsule stepper)'], ['ios18', 'iOS 18 (51 × 31)']] },
    },
    examples: [
      { label: 'Link', ground: 'reading', props: { label: 'Quit Day', icon: 'calendar', value: 'Fri 6 Nov' } },
      { label: 'Switch', ground: 'reading', props: { label: 'Breathing haptics', icon: 'water.waves', kind: 'toggle' } },
    ],
    render(p, ctx) {
      const s = SYS(ctx), r = R4(ctx);
      const tone = toneOf(p.tone, ctx);
      const style = p.icon && p.iconStyle !== 'none' ? p.iconStyle : 'none';
      const iconW = { box28: 28, box30: 30, circle30: 30, plain: 28 }[style] || 0;
      let icon = '';
      if (style === 'plain') icon = `<div style="width:28px;display:flex;justify-content:center;flex:none">${glyph(p.icon, 21, tone)}</div>`;
      else if (iconW) {
        const rad = style === 'box28' ? 8 : style === 'box30' ? 9 : 15;
        icon = `<div style="width:${iconW}px;height:${iconW}px;border-radius:${rad}px;background:${r.accentSoft};display:flex;align-items:center;justify-content:center;flex:none">${glyph(p.icon, style === 'box28' ? 16 : 17, r.accent)}</div>`;
      }
      const gap = p.font === 'system' && style !== 'box30' && style !== 'circle30' ? 16 : 12;
      const labelCss = p.font === 'dx' ? F('body', { size: 16, weight: 600 }) : p.font === 'dxSmall' ? F('body', { size: 14, weight: 400 }) : p.font === 'subtitle' ? F('footnote') : sf(17);
      const ink = p.ink ? `<span style="color:${r.ink}">${esc(p.ink)}</span>` : '';
      const text = `<div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:${p.font === 'system' ? 2 : 1}px"><div style="${labelCss}color:${tone}">${ink}${esc(p.label)}</div>${p.detail ? `<div style="${F('footnote')}color:${r.muted}">${esc(p.detail)}</div>` : ''}</div>`;
      const val = p.value ? `<span style="${sf(17)}color:${s.secondary};white-space:nowrap">${esc(p.value)}</span>` : '';
      const pill = (v) => `<span style="${sf(17)}color:${s.label};background:${s.fill};border-radius:8px;padding:6px 11px;white-space:nowrap">${esc(v)}</span>`;
      let right = '';
      switch (p.kind) {
        case 'link': right = val + Lab.icon('chevron.right', 13, s.tertiary); break;
        case 'toggle': right = switchHTML(p.on, ctx, p.switchStyle); break;
        case 'menu': right = `<span style="display:flex;align-items:center;gap:4px;${sf(17)}color:${s.accent};white-space:nowrap">${esc(p.value)}${glyph('chevron.up.chevron.down', 13, s.accent)}</span>`; break;
        case 'check': right = p.on ? Lab.icon('checkmark', 17, s.accent) : ''; break;
        case 'time': case 'date': right = pill(p.value); break;
        case 'stepper': right = val + stepperHTML(ctx, p.switchStyle); break;
        case 'field': right = `<span style="${sf(17)}color:${s.label};text-align:right">${esc(p.value)}</span>`; break;
        case 'value': right = val; break;
        default: right = '';
      }
      const sepLeft = p.inset + (iconW ? iconW + gap : 0);
      return `<div class="dxs-row${p.separator ? ' dxs-sep' : ''}" style="position:relative;--sep:${sepLeft}px;display:flex;align-items:${p.align === 'top' ? 'flex-start' : 'center'};gap:${gap}px;min-height:${p.minHeight}px;padding:${p.padTop}px ${p.inset}px ${p.padBottom}px;box-sizing:border-box;${p.disabled ? 'opacity:.45;' : ''}">${icon}${text}${right ? `<div style="display:flex;align-items:center;gap:8px;flex:none">${right}</div>` : ''}</div>`;
    },
  });

  E({
    type: 'settingsProductRow', name: 'Product row', group: 'Settings', source: SET + ' (ProductsSettingsView)',
    description: 'A product and its baseline: 16 pt semibold name, "MAIN" in green on the main one, and the baseline line under it. Tap to edit.',
    props: {
      title: { label: 'Product', kind: 'text', default: 'Cigarettes' },
      main: { label: '"Main" tag', kind: 'bool', labels: ['Show', 'Hide'], default: false },
      detail: { label: 'Baseline line', kind: 'text', default: '' },
    },
    examples: [{ label: 'Main', ground: 'reading', props: { main: true, detail: '12 cigarettes a day · $10.00 for 20' } }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div class="dxs-row dxs-sep" role="button" style="position:relative;--sep:16px;display:flex;flex-direction:column;gap:4px;padding:11px 16px">
        <div style="display:flex;align-items:center;gap:8px"><div style="flex:1;${F('body', { size: 16, weight: 600 })}color:${r.ink}">${esc(p.title)}</div>${p.main ? T('caption', 'Main', ctx, { color: r.accent }) : ''}</div>
        ${p.detail ? subtitle(p.detail, ctx) : ''}</div>`;
    },
  });

  E({
    type: 'settingsSearchBar', name: 'Search field', group: 'Settings', source: SET + ' (CurrencySettingsView .searchable)',
    props: { placeholder: { label: 'Placeholder', kind: 'text', default: 'Search currencies' }, typed: { label: 'Typed', kind: 'text', default: '' } },
    examples: [{ label: 'Empty', ground: 'reading', props: {} }],
    render(p, ctx) {
      const s = SYS(ctx);
      return `<div style="padding:8px 16px 0;flex:none"><div style="display:flex;align-items:center;gap:6px;height:36px;padding:0 8px;border-radius:18px;background:${s.fill}">${glyph('magnifyingglass', 17, s.secondary)}<span style="flex:1;${sf(17)}color:${p.typed ? s.label : s.secondary}">${esc(p.typed || p.placeholder)}</span>${p.typed ? `<span style="width:17px;height:17px;border-radius:50%;background:${s.tertiary};display:flex;align-items:center;justify-content:center">${Lab.icon('xmark', 9, s.cell)}</span>` : ''}</div></div>`;
    },
  });

  const MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  E({
    type: 'settingsCalendar', name: 'Calendar (graphical date picker)', group: 'Settings', source: SET + ' (QuitDaySettingsView DatePicker .graphical)',
    description: 'The month grid: month and year with arrows, weekday letters, and the days; the picked day in a tinted circle, days out of range greyed.',
    props: {
      month: { label: 'Month', kind: 'select', default: '2026-11', options: [['2026-10', 'October 2026'], ['2026-11', 'November 2026'], ['2026-12', 'December 2026']] },
      selected: { label: 'Picked day', kind: 'number', options: [0, 2, 3, 6, 8, 9, 13, 20], default: 6 },
      today: { label: 'Today', kind: 'number', options: [0, 1, 2, 8], default: 2 },
      min: { label: 'First day you can pick', kind: 'number', options: [1, 3, 8], default: 3 },
      weekStart: { label: 'Week starts', kind: 'select', default: 'mon', options: [['mon', 'Monday (en-GB)'], ['sun', 'Sunday (en-US)']] },
    },
    examples: [{ label: 'Quit Day in prep', ground: 'reading', props: {} }],
    render(p, ctx) {
      const s = SYS(ctx);
      const [y, m] = String(p.month).split('-').map(Number);
      const first = new Date(Date.UTC(y, m - 1, 1)).getUTCDay();
      const days = new Date(Date.UTC(y, m, 0)).getUTCDate();
      const lead = p.weekStart === 'mon' ? (first + 6) % 7 : first;
      const names = p.weekStart === 'mon' ? ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'] : ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
      const cells = [];
      for (let i = 0; i < lead; i++) cells.push('<div></div>');
      for (let d = 1; d <= days; d++) {
        const sel = d === +p.selected, off = d < +p.min, today = d === +p.today;
        const colour = sel || today ? s.accent : off ? s.tertiary : s.label;
        cells.push(`<div style="height:44px;display:flex;align-items:center;justify-content:center"><div style="width:40px;height:40px;border-radius:50%;display:flex;align-items:center;justify-content:center;${sel ? `background:${ctx.dark ? 'rgba(47,208,138,0.2)' : 'rgba(15,110,67,0.12)'};` : ''}${sf(20, sel ? 600 : 400)}color:${colour};${today && off ? 'opacity:.5;' : ''}">${d}</div></div>`);
      }
      return `<div style="padding:8px 12px 10px">
        <div style="display:flex;align-items:center;justify-content:space-between;height:44px;padding:0 4px"><div style="display:flex;align-items:center;gap:6px;${sf(17, 600)}color:${s.label}">${MONTHS[m - 1]} ${y}${Lab.icon('chevron.right', 13, s.accent)}</div><div style="display:flex;gap:28px">${Lab.icon('chevron.left', 20, s.accent)}${Lab.icon('chevron.right', 20, s.accent)}</div></div>
        <div style="display:grid;grid-template-columns:repeat(7,1fr);padding:4px 0">${names.map((n) => `<div style="text-align:center;${sf(13, 600)}color:${s.tertiary}">${n}</div>`).join('')}</div>
        <div style="display:grid;grid-template-columns:repeat(7,1fr)">${cells.join('')}</div></div>`;
    },
  });

  E({
    type: 'settingsAlert', name: 'Alert', group: 'Settings', source: SET + ' (.alert)',
    description: 'The system alert over a dimmed screen: bold title, message, an optional text field, and the buttons (cancel in bold, destructive in red).',
    props: {
      title: { label: 'Title', kind: 'text', default: 'Delete everything?' },
      message: { label: 'Message', kind: 'text', default: '' },
      field: { label: 'Text field placeholder', kind: 'text', default: '' },
      buttons: { label: 'Buttons (| between)', kind: 'text', default: 'Delete everything|Cancel' },
      roles: { label: 'Roles (| between)', kind: 'select', default: 'destructive|cancel', options: [['destructive|cancel', 'Destructive, Cancel'], ['default|cancel', 'Plain, Cancel'], ['cancel|default', 'Cancel, Plain']] },
      layout: { label: 'Buttons', kind: 'select', default: 'stacked', options: [['stacked', 'Stacked'], ['side', 'Side by side']] },
    },
    examples: [{ label: 'Delete', ground: 'reading', props: { message: 'This removes your plan, logs, check-ins and progress from this iPhone.' } }],
    render(p, ctx) {
      const s = SYS(ctx);
      const lib = ctx.screenId === '_lib';
      const names = String(p.buttons).split('|'), roles = String(p.roles).split('|');
      const side = p.layout === 'side';
      const btn = (t, i) => `<div role="button" style="flex:1;min-height:44px;display:flex;align-items:center;justify-content:center;padding:0 8px;text-align:center;${sf(17, roles[i] === 'cancel' ? 600 : 400)}color:${roles[i] === 'destructive' ? s.red : s.app};${i ? (side ? `border-left:.5px solid ${s.sep};` : `border-top:.5px solid ${s.sep};`) : ''}">${esc(t)}</div>`;
      const box = `<div style="width:270px;border-radius:14px;background:${ctx.dark ? 'rgba(44,44,46,0.97)' : 'rgba(242,242,247,0.97)'};overflow:hidden;box-shadow:0 10px 40px rgba(0,0,0,.2)">
        <div style="padding:19px 16px ${p.field ? 0 : 19}px;text-align:center"><div style="${sf(17, 600)}color:${s.label}">${esc(p.title)}</div>${p.message ? `<div style="${sf(13)}color:${s.label};margin-top:2px">${esc(p.message)}</div>` : ''}</div>
        ${p.field ? `<div style="margin:14px 16px 16px;height:30px;border-radius:7px;background:${ctx.dark ? '#1C1C1E' : '#FFFFFF'};border:.5px solid ${s.sep};padding:0 6px;display:flex;align-items:center;${sf(13)}color:${s.tertiary}">${esc(p.field)}</div>` : ''}
        <div style="display:flex;flex-direction:${side ? 'row' : 'column'};border-top:.5px solid ${s.sep}">${names.map(btn).join('')}</div></div>`;
      return lib ? `<div style="display:flex;justify-content:center;padding:20px;background:rgba(0,0,0,.2)">${box}</div>`
        : `<div style="position:absolute;inset:0;z-index:20;background:rgba(0,0,0,${ctx.dark ? 0.48 : 0.2});display:flex;align-items:center;justify-content:center">${box}</div>`;
    },
  });

  E({
    type: 'settingsShareSheet', name: 'Share sheet', group: 'Settings', source: SET + ' (ShareSheet, UIActivityViewController)',
    description: 'The system share sheet for the export: the file at the top, a row of apps, then actions. iOS draws it; only the file name is DayXero\'s.',
    props: {
      file: { label: 'File name', kind: 'text', default: 'dayxero-export-2026-11-08.json' },
      top: { label: 'Starts at', kind: 'number', options: [380, 420, 460, 500], unit: ' pt from the top', default: 460 },
    },
    render(p, ctx) {
      const s = SYS(ctx);
      const lib = ctx.screenId === '_lib';
      const app = (label, bg) => `<div style="display:flex;flex-direction:column;align-items:center;gap:6px;width:70px"><div style="width:60px;height:60px;border-radius:16px;background:${bg}"></div><span style="${sf(12)}color:${s.label}">${label}</span></div>`;
      const action = (label, icon, first) => `<div style="display:flex;align-items:center;justify-content:space-between;min-height:48px;padding:0 16px;${first ? '' : `border-top:.5px solid ${s.sep};`}${sf(17)}color:${s.label}">${label}${glyph(icon, 21, s.label)}</div>`;
      return `<div style="${lib ? 'position:relative;' : `position:absolute;left:0;right:0;bottom:0;top:${p.top}px;z-index:20;`}background:${s.bg};border-radius:38px 38px 0 0;box-shadow:0 -10px 40px rgba(0,0,0,.25);padding:16px 0 40px">
        <div style="display:flex;align-items:center;gap:12px;padding:4px 16px 16px"><div style="width:44px;height:52px;border-radius:8px;background:${s.cell};display:flex;align-items:center;justify-content:center">${glyph('doc', 26, s.secondary)}</div><div style="flex:1;min-width:0;${sf(15, 600)}color:${s.label};overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${esc(p.file)}</div><div style="width:30px;height:30px;border-radius:50%;background:${s.fill};display:flex;align-items:center;justify-content:center">${Lab.icon('xmark', 12, s.secondary)}</div></div>
        <div style="display:flex;gap:6px;padding:0 12px 18px;border-top:.5px solid ${s.sep};padding-top:18px">${app('AirDrop', '#2F80ED')}${app('Messages', '#34C759')}${app('Mail', '#1A8CFF')}${app('Notes', '#FFD60A')}</div>
        <div style="margin:0 16px;border-radius:12px;background:${s.cell}">${action('Copy', 'doc.on.doc', true)}${action('Save to Files', 'folder')}</div></div>`;
    },
  });

  E({
    type: 'settingsOptionCard', name: 'Option card', group: 'Settings', source: ONB,
    description: 'OnbOptionCard, used by "Day ends at" and NRT "What are you using?": optional 40 pt symbol circle, a 19 pt title and a 14 pt line, and a 22 pt tick circle. Ink outline when picked.',
    props: {
      title: { label: 'Title', kind: 'text', default: '04' },
      detail: { label: 'Line under it', kind: 'text', default: '' },
      icon: { label: 'Icon', kind: 'select', default: '', options: GLYPH_OPTS },
      on: { label: 'State', kind: 'select', default: false, options: [[false, 'Not picked'], [true, 'Picked']] },
      radius: { label: 'Corner radius', kind: 'number', options: [14, 18, 22], unit: ' pt', default: 18, global: true },
    },
    examples: [{ label: 'Picked', ground: 'reading', props: { title: '04', detail: 'Default', on: true } }],
    render(p, ctx) {
      const r = R4(ctx), c = ctx.with({ groundName: 'reading' });
      const icon = p.icon ? `<div style="width:40px;height:40px;border-radius:50%;background:${p.on ? r.ink : r.card};display:flex;align-items:center;justify-content:center;flex:none">${glyph(p.icon, 20, p.on ? r.onInk : r.ink)}</div>` : '';
      const tick = p.on ? glyph('checkmark.circle.fill', 24, r.accent, `--on:${r.surface}`) : glyph('circle', 24, r.hairline);
      return `<div role="button" style="display:flex;align-items:center;gap:12px;padding:14px;min-height:64px;box-sizing:border-box;border-radius:${p.radius}px;background:${r.surface};box-shadow:inset 0 0 0 2px ${p.on ? r.ink : 'transparent'}">${icon}<div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:2px">${T('headline', p.title, c)}${p.detail ? T('footnote', p.detail, c, { tone: 'muted' }) : ''}</div>${tick}</div>`;
    },
  });

  /* ---------- NRT pieces ---------- */
  E({
    type: 'nrtToggleChip', name: 'Toggle chip', group: 'NRT', source: V4R + ' (V4ToggleChip)',
    description: '44 pt chip, radius 14: 16 pt semibold on the surface, or bold cream-on-ink when on.',
    props: { label: { label: 'Words', kind: 'text', default: 'US' }, on: { label: 'State', kind: 'select', default: false, options: [[false, 'Off'], [true, 'On']] } },
    examples: [{ label: 'On', ground: 'reading', props: { on: true } }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div role="button" style="display:inline-flex;align-items:center;min-height:44px;padding:0 14px;border-radius:14px;background:${p.on ? r.ink : r.surface};${F('body', { size: 16, weight: p.on ? 700 : 600 })}color:${p.on ? r.onInk : r.ink};white-space:nowrap">${esc(p.label)}</div>`;
    },
  });

  E({
    type: 'nrtPresetCard', name: 'Label schedule card', group: 'NRT', source: NRT + ' (presetCard)',
    description: 'A label schedule to match against the pack: 16 pt title, the steps under it, and a 22 pt tick circle. Green outline when picked.',
    props: {
      title: { label: 'Title', kind: 'text', default: '10 weeks, starting on 21 mg' },
      detail: { label: 'Steps line', kind: 'text', default: '21 mg × 6 wk, 14 mg × 2 wk, 7 mg × 2 wk' },
      on: { label: 'State', kind: 'select', default: false, options: [[false, 'Not picked'], [true, 'Picked']] },
      radius: { label: 'Corner radius', kind: 'number', options: [18, 20, 22, 24], unit: ' pt', default: 22, global: true },
    },
    examples: [{ label: 'Picked', ground: 'reading', props: { on: true } }],
    render(p, ctx) {
      const r = R4(ctx);
      const tick = p.on ? glyph('checkmark.circle.fill', 24, r.accent, `--on:${r.card}`) : glyph('circle', 24, r.faint);
      return `<div role="button" style="display:flex;align-items:center;gap:12px;padding:14px;border-radius:${p.radius}px;background:${r.card};box-shadow:inset 0 0 0 ${p.on ? 1.5 : 1}px ${p.on ? r.accent : r.hairline}"><div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:2px"><div style="${F('body', { size: 16, weight: 600 })}color:${r.ink}">${esc(p.title)}</div>${subtitle(p.detail, ctx)}</div><div style="margin-left:-4px">${tick}</div></div>`;
    },
  });

  E({
    type: 'nrtStepRow', name: 'Step row', group: 'NRT', source: NRT + ' (StepRow)',
    description: 'One step of a plan: a 32 pt number circle (ink for this step, green when done), the strength, its dates, and its length.',
    props: {
      number: { label: 'Number', kind: 'text', default: '1' },
      title: { label: 'Strength', kind: 'text', default: '21 mg' },
      dates: { label: 'Dates', kind: 'text', default: 'Fri 6 Nov – Thu 17 Dec' },
      weeks: { label: 'Length', kind: 'text', default: '6 weeks' },
      state: { label: 'State', kind: 'select', default: 'plain', options: [['current', 'This step (ink)'], ['plain', 'Later step'], ['done', 'Done (green)']] },
      divider: { label: 'Hairline under it', kind: 'bool', labels: ['Show', 'Hide'], default: true },
    },
    examples: [{ label: 'First step', ground: 'reading', props: { state: 'current' } }],
    render(p, ctx) {
      const r = R4(ctx);
      const bg = p.state === 'done' ? r.accent : p.state === 'current' ? r.ink : r.track;
      const fg = p.state === 'done' ? CREAM : p.state === 'current' ? r.onInk : r.muted;
      return `<div role="button" style="display:flex;align-items:center;gap:12px;padding:10px 0;${p.divider ? `border-bottom:.5px solid ${r.hairline};` : ''}">
        <div style="width:32px;height:32px;border-radius:50%;background:${bg};display:flex;align-items:center;justify-content:center;flex:none;${F('caption', { size: 12, weight: 700 })}color:${fg}">${esc(p.number)}</div>
        <div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:1px"><div style="${F('body', { size: 16, weight: 600 })}color:${r.ink}">${esc(p.title)}</div>${subtitle(p.dates, ctx)}</div>${subtitle(p.weeks, ctx, 'flex:none')}</div>`;
    },
  });

  E({
    type: 'nrtLabelNotice', name: '"Follow the label" notice', group: 'NRT', source: NRT + ' (LabelNotice)',
    description: 'On every NRT screen: an amber info symbol and the dosing line in a soft amber box, radius 18, 12 pt below what comes before.',
    props: { text: { label: 'Words', kind: 'text', default: "Follow the label on your pack and ask a pharmacist or doctor. DayXero doesn't give dosing advice." } },
    examples: [{ label: 'On reading', ground: 'reading', props: {} }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="padding-top:12px"><div style="display:flex;align-items:flex-start;gap:8px;padding:12px;border-radius:18px;background:rgba(${r.amberRGB},0.12);box-shadow:inset 0 0 0 1px rgba(${r.amberRGB},0.35)">${Lab.icon('info.circle', 20, ctx.dark ? '#E5A93C' : '#B07A14')}<div style="${F('footnote', { size: 14, weight: 400, lh: 1.35 })}color:${r.ink}">${esc(p.text)}</div></div></div>`;
    },
  });

  E({
    type: 'nrtSourceLink', name: 'Source link', group: 'NRT', source: NRT + ' (SourceLink)',
    props: { text: { label: 'Words', kind: 'text', default: 'Source: Cochrane review of 133 trials, 2018' } },
    examples: [{ label: 'Cochrane', ground: 'reading', props: {} }],
    render(p, ctx) { return `<div role="link" style="${F('footnote', { size: 14, weight: 400, lh: 1.35 })}color:${R4(ctx).accent};text-decoration:underline">${esc(p.text)}</div>`; },
  });

  E({
    type: 'nrtSecondaryButton', name: 'Surface button', group: 'NRT', source: V4R + ' (V4SecondaryButtonStyle)',
    description: 'The reading-ground secondary: a 58 pt surface capsule with 16 pt semibold ink words, and an optional symbol.',
    props: { label: { label: 'Words', kind: 'text', default: 'Mark patch on' }, icon: { label: 'Symbol', kind: 'select', default: '', options: [['', 'None'], ['circle', 'Empty circle'], ['checkmark.circle.fill', 'Ticked circle']] } },
    examples: [{ label: 'Plain', ground: 'reading', props: {} }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div role="button" style="display:flex;align-items:center;justify-content:center;gap:8px;min-height:58px;padding:0 18px;border-radius:999px;background:${r.surface};${F('body', { size: 16, weight: 600 })}color:${r.ink};text-align:center">${p.icon ? glyph(p.icon, 18, r.ink, `--on:${r.surface}`) : ''}<span>${esc(p.label)}</span></div>`;
    },
  });

  E({
    type: 'nrtStrengthBars', name: 'Strength by step', group: 'NRT', source: NRTC + ' (StrengthBars)',
    description: 'The taper\'s steps as bars, tallest 72 pt, the first in green, ending in a thin "Quit Day" bar.',
    props: { steps: { label: 'Strengths (| between)', kind: 'text', default: '6|3|1.5' }, heading: { label: 'Heading', kind: 'text', default: 'Strength by step' } },
    examples: [{ label: 'Three steps', ground: 'reading', props: {} }],
    render(p, ctx) {
      const r = R4(ctx), c = ctx.with({ groundName: 'reading' });
      const mg = String(p.steps).split('|').map(Number).filter((n) => n > 0);
      const most = Math.max(1, ...mg);
      const col = (h, fill, label, radius) => `<div style="flex:1;min-width:0;display:flex;flex-direction:column;align-items:stretch;justify-content:flex-end;gap:4px"><div style="height:${h}px;border-radius:${radius}px;background:${fill}"></div>${subtitle(label, ctx, 'text-align:center;white-space:nowrap;overflow:hidden')}</div>`;
      return `<div style="display:flex;flex-direction:column;gap:8px;padding:14px;border-radius:18px;background:${r.card}">${T('headline', p.heading, c)}
        <div style="display:flex;align-items:flex-end;gap:8px;height:100px">${mg.map((m, i) => col(Math.max(6, (72 * m) / most), i === 0 ? r.accent : r.track, (m % 1 ? m.toFixed(1) : m) + ' mg', 8)).join('')}${col(3, r.track, 'Quit Day', 3)}</div></div>`;
    },
  });

  E({
    type: 'nrtCard', name: 'NRT plan card', group: 'NRT', source: NRTC + ' (NRTCard)',
    description: 'On Program and Progress once a plan exists: the product symbol, this step, progress through it, and when the next step starts. Patches add "Mark patch on".',
    props: {
      icon: { label: 'Symbol', kind: 'select', default: 'bandage', options: [['bandage', 'Patch'], ['square.grid.2x2', 'Gum'], ['capsule', 'Lozenge'], ['lungs', 'Inhaler']] },
      headline: { label: 'Headline', kind: 'text', default: '21 mg patch · Step 1 of 3' },
      progress: { label: 'Through this step', kind: 'number', options: [0, 0.05, 0.1, 0.25, 0.5, 0.75, 1], default: 0.05 },
      left: { label: 'Day line', kind: 'text', default: 'Day 2 of 42' },
      right: { label: 'Next step line', kind: 'text', default: '14 mg from Fri 18 Dec' },
      note: { label: 'Step note', kind: 'text', default: '' },
      patch: { label: 'Patch check', kind: 'select', default: 'off', options: [['none', 'None'], ['off', 'Mark patch on'], ['on', 'Patch on today']] },
    },
    examples: [{ label: 'Patch, step 1', ground: 'reading', props: {} }, { label: 'Not started', ground: 'reading', props: { headline: '21 mg patch', progress: 0, left: '', right: '', patch: 'none', note: 'Starts Friday 6 November' } }],
    render(p, ctx) {
      const r = R4(ctx);
      const bar = p.left || p.right ? `<div style="height:8px;border-radius:4px;background:${r.track};overflow:hidden"><div style="height:100%;width:${p.progress * 100}%;border-radius:4px;background:${r.accent}"></div></div><div style="display:flex;justify-content:space-between;gap:8px">${subtitle(p.left, ctx)}${subtitle(p.right, ctx)}</div>` : '';
      const check = p.patch === 'none' ? '' : Lab.render(Lab.h('nrtSecondaryButton', '_p', { label: p.patch === 'on' ? 'Patch on today' : 'Mark patch on', icon: p.patch === 'on' ? 'checkmark.circle.fill' : 'circle' }), Object.assign(ctx.with({}), { inert: true }));
      return `<div style="display:flex;flex-direction:column;gap:8px;padding:14px;border-radius:18px;background:${r.card}">
        <div style="display:flex;align-items:center;gap:12px"><div style="width:38px;height:38px;border-radius:50%;background:${r.accentSoft};display:flex;align-items:center;justify-content:center;flex:none">${glyph(p.icon, 20, r.accent)}</div><div style="${F('body', { size: 16, weight: 600 })}color:${r.ink}">${esc(p.headline)}</div></div>
        ${bar}${p.note ? subtitle(p.note, ctx) : ''}${check}</div>`;
    },
  });

  E({
    type: 'nrtTaperCard', name: 'Pouch taper card', group: 'NRT', source: NRTC + ' (TaperCard)',
    description: 'On Program during prep, for pouch users with a taper: the heading, this week\'s strength and the next step.',
    props: {
      heading: { label: 'Heading', kind: 'text', default: 'Your pouch taper' },
      line: { label: 'This week', kind: 'text', default: '6 mg this week · step 1 of 3' },
      next: { label: 'Next', kind: 'text', default: '3 mg from Mon 9 Nov' },
    },
    examples: [{ label: 'Step 1', ground: 'reading', props: {} }],
    render(p, ctx) {
      const r = R4(ctx), c = ctx.with({ groundName: 'reading' });
      return `<div role="button" style="display:flex;flex-direction:column;gap:8px;padding:14px;border-radius:18px;background:${r.card}">${T('headline', p.heading, c)}<div style="${F('body', { size: 16, weight: 600 })}color:${r.ink}">${esc(p.line)}</div>${p.next ? subtitle(p.next, ctx) : ''}</div>`;
    },
  });

  /* ---------- Water pieces ---------- */
  const DRINKS = {
    glass: { name: 'Glass', ml: 250, grad: ['#BFE6FF', '#3D8BF2'] },
    bottle: { name: 'Bottle', ml: 500, grad: ['#BFE6FF', '#3D8BF2'] },
    tea: { name: 'Tea', ml: 300, grad: ['#EBCB92', '#A8763A'] },
    sparkling: { name: 'Sparkling', ml: 330, grad: ['#E6F6FF', '#7CC4F2'] },
  };
  const DRINK_OPTS = Object.keys(DRINKS).map((k) => [k, DRINKS[k].name]);
  const OZ = 29.5735;
  /** WaterFormat.size / amount / unit. */
  const wSize = (ml, u) => (u === 'metric' ? `${ml} ml` : `${ml === 250 ? 8 : Math.round(ml / OZ)} fl oz`);
  const wAmount = (ml, u) => { if (u !== 'metric') return String(Math.round(ml / OZ)); let t = (ml / 1000).toFixed(2); if (t.endsWith('0')) t = t.slice(0, -1); return t; };
  const wUnit = (u) => (u === 'metric' ? 'L' : 'fl oz');
  const wLitres = (ml, u) => (u === 'metric' ? `${(ml / 1000).toFixed(2)} L` : `${Math.round(ml / OZ)} fl oz`);

  /** DrinkIllustration: white line work on a 34 × 34 grid, the drink's colour inside. */
  function drinkSVG(drink, size) {
    const line = 'rgba(255,255,255,0.85)', water = '#7DBBF2', foam = '#EAF5FF';
    const sk = (d, c, w) => `<path d="${d}" fill="none" stroke="${c}" stroke-width="${w || 1.4}" stroke-linecap="round" stroke-linejoin="round"/>`;
    let body = '';
    if (drink === 'bottle') {
      body = `<rect x="14" y="3" width="6" height="4" rx="1.2" fill="${line}"/><path d="M11.9 18L22.1 18L22.1 28Q22.1 30.1 20 30.1L14 30.1Q11.9 30.1 11.9 28Z" fill="${water}"/>${sk('M14 21L14 27', 'rgba(234,245,255,0.8)', 1.2)}${sk('M14.5 7L14.5 10Q11 12 11 16L11 28Q11 31 14 31L20 31Q23 31 23 28L23 16Q23 12 19.5 10L19.5 7', line)}`;
    } else if (drink === 'tea') {
      body = `${sk('M12 5Q10.5 7 12 9Q13.5 11 12 13M17 4Q15.5 6 17 8Q18.5 10 17 12', 'rgba(255,255,255,0.55)', 1.1)}<path d="M7 18L23 18L23 22Q23 28 17 28L13 28Q7 28 7 22Z" fill="#D9A35B"/>${sk('M6 16L24 16L24 22Q24 29 17 29L13 29Q6 29 6 22ZM24 18.5L26 18.5Q29 18.5 29 21.5Q29 24.5 26 24.5L23.5 24.5', line)}${sk('M5 31L25 31', 'rgba(255,255,255,0.5)', 1.3)}`;
    } else if (drink === 'sparkling') {
      body = `<path d="M11.6 12L22.4 12L21.9 29Q21.8 30.2 20.6 30.2L13.4 30.2Q12.2 30.2 12.1 29Z" fill="#A9D2F7"/>${[[15, 25, 1.3], [19, 20, 1.1], [16.5, 16, 0.9], [19.5, 27, 0.8]].map(([x, y, r]) => `<circle cx="${x}" cy="${y}" r="${r}" fill="#fff"/>`).join('')}${sk('M11 5L23 5L22 29Q21.9 31 19.9 31L14.1 31Q12.1 31 12 29Z', line)}`;
    } else {
      body = `<path d="M10.2 16L23.8 16L23 28Q22.8 29.2 21.6 29.2L12.4 29.2Q11.2 29.2 11 28Z" fill="${water}"/>${sk('M10.2 16Q13.6 14.6 17 16Q20.4 17.4 23.8 16', foam, 1)}${sk('M9 7L25 7L23 28Q22.8 30 20.8 30L13.2 30Q11.2 30 11 28Z', line)}`;
    }
    return `<svg viewBox="0 0 34 34" width="${size}" height="${size}" style="display:block;flex:none" aria-hidden="true">${body}</svg>`;
  }

  let pillSeq = 0;
  /** WaterPillView drawn still: the waves at rest, no bubbles. */
  function pillSVG(level, drink, mini) {
    const s = mini ? 56 / 200 : 1;
    const W = 200 * s, H = 340 * s;
    const id = 'mewp' + pillSeq++;
    const L = Math.min(Math.max(+level || 0, 0), 1);
    const g = (DRINKS[drink] || DRINKS.glass).grad;
    const top = H * (1 - L);
    const f = (n) => (+n).toFixed(1);
    const wave = (base, amp, shift, bottom) => {
      const half = 65 * s; let x = shift; let d = `M${f(x)} ${f(base)}`; let up = true;
      while (x < W + half) { const cx = x + half / 2, cy = base + (up ? -2 : 2) * amp; x += half; d += `Q${f(cx)} ${f(cy)} ${f(x)} ${f(base)}`; up = !up; }
      return d + `L${f(x)} ${f(bottom)}L${f(shift)} ${f(bottom)}Z`;
    };
    const liquid = L > 0 ? `<path d="${wave(top - 8 * s, 6 * s, -65 * s, top + 6 * s)}" fill="${g[0]}" fill-opacity=".45"/><rect x="0" y="${f(top)}" width="${f(W)}" height="${f(H - top)}" fill="url(#${id}g)"/><path d="${wave(top, 7 * s, 0, top + 14 * s)}" fill="${g[0]}"/>` : '';
    const lw = Math.max(2 * s, 1);
    return `<svg width="${f(W)}" height="${f(H)}" viewBox="0 0 ${f(W)} ${f(H)}" style="display:block;position:relative" aria-hidden="true"><defs><clipPath id="${id}c"><rect width="${f(W)}" height="${f(H)}" rx="${f(W / 2)}"/></clipPath><linearGradient id="${id}g" gradientUnits="userSpaceOnUse" x1="0" y1="${f(top)}" x2="0" y2="${f(H)}"><stop offset="0" stop-color="${g[0]}"/><stop offset="1" stop-color="${g[1]}"/></linearGradient></defs>
      <g clip-path="url(#${id}c)"><rect width="${f(W)}" height="${f(H)}" fill="#0C0F08"/>${liquid}<rect x="${f(26 * s)}" y="${f(40 * s)}" width="${f(12 * s)}" height="${f(230 * s)}" rx="${f(6 * s)}" fill="#fff" fill-opacity=".14"/></g>
      <rect x="${f(lw / 2)}" y="${f(lw / 2)}" width="${f(W - lw)}" height="${f(H - lw)}" rx="${f((W - lw) / 2)}" fill="none" stroke="#fff" stroke-opacity=".75" stroke-width="${f(lw)}"/></svg>`;
  }

  E({
    type: 'waterCanvas', name: 'Water page', group: 'Water', source: WT,
    description: 'The tracker\'s black page, always dark: 24 pt sides, 20 pt under the status bar and at the bottom.',
    props: { padX: { label: 'Side padding', kind: 'number', options: [16, 20, 24], unit: ' pt', default: 24 }, padTop: { label: 'Top padding', kind: 'number', options: [12, 16, 20, 24], unit: ' pt', default: 20 } },
    render(p, ctx, kids) {
      const d = ctx.screenId !== '_lib' && ctx.device ? ctx.device : null;
      return `<div style="flex:1;display:flex;flex-direction:column;background:#000;padding:${(d ? d.top : 0) + p.padTop}px ${p.padX}px ${(d ? d.bottom : 0) + 20}px;${d ? `margin-bottom:-${d.bottom + 12}px;min-height:${d.h}px;box-sizing:border-box;` : ''}">${kids({ groundName: 'reading', dark: true })}</div>`;
    },
  });

  E({
    type: 'waterHeader', name: 'Water header', group: 'Water', source: WT + ' (header)',
    description: '"Water" in 28 pt heavy white, the sage streak capsule once there is a streak, and the 44 pt close button.',
    props: {
      title: { label: 'Title', kind: 'text', default: 'Water' },
      streak: { label: 'Streak', kind: 'text', default: '' },
      close: { label: 'Close button', kind: 'bool', labels: ['Show', 'Hide'], default: true },
    },
    examples: [{ label: 'With streak', ground: 'reading', props: { streak: '1-DAY STREAK' } }],
    render(p, ctx) {
      const r = R4(ctx.with({ dark: true }));
      return `<div style="display:flex;align-items:center;gap:8px;background:${ctx.screenId === '_lib' ? '#000' : 'transparent'}"><div style="flex:1;${F('large', { size: 28, weight: 800, tracking: -0.5, lh: 1.15 })}color:#fff">${esc(p.title)}</div>
        ${p.streak ? `<span style="${F('caption', { size: 12, weight: 600, tracking: 0.6 })}color:${SAGE};background:rgba(188,195,136,0.12);padding:6px 10px;border-radius:999px;font-variant-numeric:tabular-nums">${esc(p.streak)}</span>` : ''}
        ${p.close ? `<div role="button" aria-label="Close" style="margin-left:4px;width:44px;height:44px;border-radius:50%;background:${r.surface};display:flex;align-items:center;justify-content:center">${Lab.icon('xmark', 16, r.ink)}</div>` : ''}</div>`;
    },
  });

  E({
    type: 'waterReadout', name: 'Today\'s amount', group: 'Water', source: WT + ' (readout)',
    description: 'The 54 pt amount over "/ goal", and the glasses line (sage once the goal is reached).',
    props: {
      amount: { label: 'Amount', kind: 'text', default: '27' },
      goal: { label: 'Goal', kind: 'text', default: '/ 68 fl oz' },
      line: { label: 'Line', kind: 'text', default: '3 of 8 glasses' },
      reached: { label: 'Goal', kind: 'select', default: false, options: [[false, 'Not reached'], [true, 'Reached (sage line)']] },
    },
    examples: [{ label: 'Partway', ground: 'reading', props: {} }],
    render(p, ctx) {
      return `<div style="display:flex;flex-direction:column;align-items:center;gap:6px;padding-top:18px;${ctx.screenId === '_lib' ? 'background:#000;padding-bottom:12px;' : ''}">
        <div style="display:flex;align-items:baseline;gap:6px"><span style="${F('display', { size: 54, weight: 800, tracking: -2, lh: 1 })}color:#fff;font-variant-numeric:tabular-nums">${esc(p.amount)}</span><span style="${F('body', { size: 19, weight: 600 })}color:rgba(255,255,255,0.55)">${esc(p.goal)}</span></div>
        <div style="${F('footnote', { size: 14, weight: 600 })}color:${p.reached ? SAGE : 'rgba(255,255,255,0.6)'}">${esc(p.line)}</div></div>`;
    },
  });

  E({
    type: 'waterQuietButton', name: 'Faint text button', group: 'Water', source: WT,
    description: '"Personalise goal" (14 pt) and "Undo last" (16 pt) in white at 60%.',
    props: {
      label: { label: 'Words', kind: 'text', default: 'Personalise goal' },
      size: { label: 'Size', kind: 'number', options: [14, 16], unit: ' pt', default: 14 },
      height: { label: 'Height', kind: 'number', options: [36, 40, 44], unit: ' pt', default: 36 },
      hidden: { label: 'Visibility', kind: 'select', default: false, options: [[false, 'Shown'], [true, 'Hidden (nothing logged today)']] },
    },
    render(p, ctx) {
      return `<div role="button" style="align-self:center;min-height:${p.height}px;padding:0 16px;display:flex;align-items:center;${F('body', { size: p.size, weight: 600 })}color:rgba(255,255,255,0.6);${p.hidden ? 'opacity:0;' : ''}${ctx.screenId === '_lib' ? 'background:#000;' : ''}">${esc(p.label)}</div>`;
    },
  });

  E({
    type: 'waterPill', name: 'Water pill', group: 'Water', source: WP,
    description: 'The signed-off pill: 200 × 340 capsule, the latest drink\'s colours rising to today\'s level, waves on top, a glass highlight, three marks at 25/50/75%, and a blue glow (brighter at the goal). Mini is 56 × 96.',
    props: {
      level: { label: 'Filled', kind: 'number', options: [0, 0.1, 0.25, 0.4, 0.5, 0.75, 0.9, 1], default: 0.4 },
      drink: { label: 'Latest drink', kind: 'select', default: 'glass', options: DRINK_OPTS },
      reached: { label: 'Goal', kind: 'select', default: false, options: [[false, 'Not reached (dim glow)'], [true, 'Reached (bright glow)']] },
      size: { label: 'Size', kind: 'select', default: 'full', options: [['full', 'Full 200 × 340'], ['mini', 'Mini 56 × 96']] },
    },
    examples: [{ label: 'Partway', ground: 'reading', props: {} }],
    render(p, ctx) {
      const mini = p.size === 'mini';
      if (mini) return `<div style="flex:none;line-height:0">${pillSVG(p.level, p.drink, true)}</div>`;
      const ticks = [85, 170, 255].map((t) => `<div style="position:absolute;left:206px;top:${t}px;width:8px;height:2px;border-radius:1px;background:rgba(255,255,255,0.35)"></div>`).join('');
      return `<div style="align-self:center;position:relative;width:200px;height:340px;margin-top:18px;flex:none;line-height:0;${ctx.screenId === '_lib' ? 'margin:30px 60px;' : ''}">
        <div style="position:absolute;left:-40px;top:-20px;width:280px;height:380px;background:radial-gradient(closest-side, rgba(84,164,255,0.24), rgba(84,164,255,0));opacity:${p.reached ? 1 : 0.35}"></div>${pillSVG(p.level, p.drink, false)}${ticks}</div>`;
    },
  });

  E({
    type: 'waterDrinkTile', name: 'Drink tile', group: 'Water', source: WT + ' (drinkPicker)',
    description: 'One of four drink buttons: the drawing, the name and size, 92 pt tall, radius 18; sage outline when picked. Long-press logs a custom amount.',
    props: {
      drink: { label: 'Drink', kind: 'select', default: 'glass', options: DRINK_OPTS },
      name: { label: 'Name', kind: 'text', default: 'Glass' },
      size: { label: 'Size', kind: 'text', default: '8 fl oz' },
      on: { label: 'State', kind: 'select', default: false, options: [[false, 'Not picked'], [true, 'Picked']] },
    },
    examples: [{ label: 'Picked', ground: 'reading', props: { on: true } }],
    render(p) {
      return `<div role="button" style="flex:1;min-width:0;min-height:92px;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:2px;border-radius:18px;background:${p.on ? 'rgba(188,195,136,0.12)' : 'rgba(255,255,255,0.04)'};box-shadow:inset 0 0 0 ${p.on ? 2 : 1}px ${p.on ? SAGE : 'rgba(255,255,255,0.12)'};color:#fff;white-space:nowrap">
        <div style="padding-bottom:2px">${drinkSVG(p.drink, 30)}</div><div style="${F('footnote', { size: 14, weight: 600 })}">${esc(p.name)}</div><div style="${F('caption', { size: 12, weight: 500 })}opacity:.65">${esc(p.size)}</div></div>`;
    },
  });

  E({
    type: 'waterLogButton', name: 'Log button', group: 'Water', source: WT + ' (logButton)',
    description: 'The 58 pt sage capsule with black "+ Log 8 fl oz".',
    props: { label: { label: 'Words', kind: 'text', default: 'Log 8 fl oz' } },
    examples: [{ label: 'Glass', ground: 'reading', props: {} }],
    render(p) {
      return `<div role="button" style="display:flex;align-items:center;justify-content:center;gap:8px;min-height:58px;border-radius:999px;background:${SAGE};color:#000;${F('body', { size: 16, weight: 600 })}margin-top:16px">${Lab.icon('plus', 16, '#000')}<span>${esc(p.label)}</span></div>`;
    },
  });

  E({
    type: 'waterTodayRow', name: 'Today\'s drink row', group: 'Water', source: WT + ' (todayList)',
    description: 'Time, the drawing, the drink and its size, on a faint hairline. Long-press to delete.',
    props: {
      time: { label: 'Time', kind: 'text', default: '13:10' },
      drink: { label: 'Drink', kind: 'select', default: 'glass', options: DRINK_OPTS },
      name: { label: 'Name', kind: 'text', default: 'Glass' },
      size: { label: 'Size', kind: 'text', default: '8 fl oz' },
    },
    render(p, ctx) {
      return `<div style="display:flex;align-items:center;gap:8px;padding:12px 0;border-bottom:1px solid rgba(255,255,255,0.08);${ctx.screenId === '_lib' ? 'background:#000;' : ''}">
        <div style="width:72px;flex:none;${F('footnote', { size: 14, weight: 500 })}color:rgba(255,255,255,0.55)">${esc(p.time)}</div>${drinkSVG(p.drink, 24)}
        <div style="flex:1;${F('body', { size: 16, weight: 600 })}color:#fff">${esc(p.name)}</div><div style="${F('footnote', { size: 14, weight: 500 })}color:rgba(255,255,255,0.7)">${esc(p.size)}</div></div>`;
    },
  });

  E({
    type: 'waterHomeCard', name: 'Water card (Home)', group: 'Water', source: WH,
    description: 'Home\'s logging card when there is one product or three: the drop and "Water today", glasses in 32 pt, the mini pill, and "+ Log water".',
    props: {
      glasses: { label: 'Glasses', kind: 'text', default: '3' },
      line: { label: 'Line', kind: 'text', default: 'of 8 glasses' },
      level: { label: 'Filled', kind: 'number', options: [0, 0.25, 0.4, 0.5, 0.75, 1], default: 0.4 },
      drink: { label: 'Latest drink', kind: 'select', default: 'glass', options: DRINK_OPTS },
      button: { label: 'Button', kind: 'text', default: '+ Log water' },
    },
    examples: [{ label: 'Partway', ground: 'reading', props: {} }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="display:flex;flex-direction:column;gap:10px;padding:14px;border-radius:24px;background:${r.card};box-shadow:inset 0 0 0 1px ${r.hairline}">
        <div role="button" style="display:flex;align-items:flex-start;gap:8px"><div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:10px">
          <div style="display:flex;align-items:center;gap:8px"><div style="width:28px;height:28px;border-radius:50%;background:rgba(61,139,242,0.18);display:flex;align-items:center;justify-content:center">${glyph('drop', 15, '#54A4FF')}</div><span style="${F('footnote', { size: 14, weight: 600 })}color:${r.muted}">Water today</span></div>
          <div style="display:flex;align-items:baseline;gap:6px"><span style="${F('large', { size: 32, weight: 700 })}color:${r.ink}">${esc(p.glasses)}</span><span style="${F('caption', { size: 12, weight: 400 })}color:${r.muted}">${esc(p.line)}</span></div></div>
          ${pillSVG(p.level, p.drink, true)}</div>
        <div role="button" style="min-height:40px;border-radius:999px;background:${r.surface};box-shadow:inset 0 0 0 1px ${r.hairline};display:flex;align-items:center;justify-content:center;${F('footnote', { size: 14, weight: 600 })}color:${r.ink}">${esc(p.button)}</div></div>`;
    },
  });

  /* Water goal sheet */
  E({
    type: 'waterUnitToggle', name: 'Units switch', group: 'Water', source: WG + ' (unitToggle)',
    props: { on: { label: 'Picked', kind: 'select', default: 'imperial', options: [['metric', 'kg · L'], ['imperial', 'lb · fl oz']] } },
    examples: [{ label: 'Imperial', ground: 'reading', props: {} }],
    render(p, ctx) {
      const r = R4(ctx);
      const seg = (v, t) => `<div role="button" style="min-height:34px;padding:0 16px;display:flex;align-items:center;border-radius:999px;${p.on === v ? `background:${r.ink};color:${r.onInk};` : `color:${r.muted};`}${F('footnote', { size: 14, weight: 600 })}">${t}</div>`;
      return `<div style="align-self:flex-start;display:flex;padding:3px;border-radius:999px;background:${r.surface}">${seg('metric', 'kg · L')}${seg('imperial', 'lb · fl oz')}</div>`;
    },
  });

  E({
    type: 'waterHeading', name: 'Small heading', group: 'Water', source: WG + ' (heading)',
    props: {
      text: { label: 'Words', kind: 'text', default: 'A normal day' },
      colour: { label: 'Colour', kind: 'select', default: 'muted', options: [['muted', 'Read4 muted (goal sheet)'], ['white', 'White 55% (water page)']] },
    },
    render(p, ctx) { return `<div style="${F('footnote', { size: 14, weight: 600 })}color:${p.colour === 'white' ? 'rgba(255,255,255,0.55)' : R4(ctx).muted}">${esc(p.text)}</div>`; },
  });

  E({
    type: 'waterBigNumber', name: 'Big number', group: 'Water', source: WG,
    description: '48 pt heavy number with its unit, and an optional muted line at the right ("9 glasses a day").',
    props: {
      value: { label: 'Number', kind: 'text', default: '154' },
      unit: { label: 'Unit', kind: 'text', default: 'lb' },
      trail: { label: 'At the right', kind: 'text', default: '' },
    },
    examples: [{ label: 'Weight', ground: 'reading', props: {} }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="display:flex;align-items:baseline;gap:6px"><span style="${F('display', { size: 48, weight: 800, tracking: -1.4, lh: 1.05 })}color:${r.ink};font-variant-numeric:tabular-nums">${esc(p.value)}</span><span style="${F('body', { size: 16, weight: 600 })}color:${r.muted}">${esc(p.unit)}</span>${p.trail ? `<span style="flex:1"></span><span style="${F('body', { size: 16, weight: 600 })}color:${r.muted}">${esc(p.trail)}</span>` : ''}</div>`;
    },
  });

  E({
    type: 'waterRuler', name: 'Weight ruler', group: 'Water', source: WG + ' (RulerPicker)',
    description: 'Drag sideways to pick: ticks every step (2 lb or 1 kg), taller every 10 with a label, and the green centre line.',
    props: {
      value: { label: 'Value', kind: 'number', options: [60, 70, 80, 154], default: 154 },
      units: { label: 'Units', kind: 'select', default: 'imperial', options: [['metric', 'kg (14 pt a step)'], ['imperial', 'lb (7 pt a step, a tick every 2)']] },
    },
    examples: [{ label: '154 lb', ground: 'reading', props: {} }],
    render(p, ctx) {
      const r = R4(ctx);
      const W = 370, mid = W / 2;
      const metric = p.units === 'metric';
      const pps = metric ? 14 : 7, minor = metric ? 1 : 2, major = 10;
      const v = +p.value;
      const lo = metric ? 35 : 77, hi = metric ? 200 : 441;
      const ink = ctx.dark ? '255,255,255' : '0,0,0';
      let out = '';
      for (let i = Math.floor(v - mid / pps) - 1; i <= Math.ceil(v + mid / pps) + 1; i++) {
        if (i < lo || i > hi || !(i % minor === 0 || i % major === 0)) continue;
        const x = mid + (i - v) * pps;
        const isMajor = i % major === 0, half = i % (major / 2) === 0;
        out += `<line x1="${x}" y1="${isMajor ? 16 : half ? 20 : 24}" x2="${x}" y2="34" stroke="rgba(${ink},0.28)" stroke-width="1.5" stroke-linecap="round"/>`;
        if (isMajor) out += `<text x="${x}" y="52" text-anchor="middle" font-family="DM Sans, system-ui, sans-serif" font-size="12" font-weight="600" fill="rgba(${ink},0.4)">${i}</text>`;
      }
      return `<div style="padding-top:8px;overflow:hidden"><svg width="100%" height="54" viewBox="0 0 ${W} 54" preserveAspectRatio="xMidYMid slice" style="display:block" aria-hidden="true">${out}<line x1="${mid}" y1="8" x2="${mid}" y2="40" stroke="${r.accent}" stroke-width="3" stroke-linecap="round"/></svg></div>`;
    },
  });

  E({
    type: 'waterLockLine', name: 'Privacy line', group: 'Water', source: WG + ' (weight)',
    props: { text: { label: 'Words', kind: 'text', default: 'Only used for your water goal. Stays on your phone.' } },
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="display:flex;align-items:flex-start;gap:10px;padding-top:8px"><div style="padding-top:2px">${glyph('lock', 16, r.accent)}</div><div style="${F('footnote', { size: 14, weight: 500 })}color:${r.muted}">${esc(p.text)}</div></div>`;
    },
  });

  E({
    type: 'waterChoiceCard', name: 'Activity card', group: 'Water', source: WG + ' (choiceCard)',
    description: '16 pt title and 14 pt line on a raised card, radius 20; green tint, 2 pt outline and a tick when picked.',
    props: {
      title: { label: 'Title', kind: 'text', default: 'Mostly sitting' },
      detail: { label: 'Line', kind: 'text', default: 'Desk, studies, driving' },
      on: { label: 'State', kind: 'select', default: false, options: [[false, 'Not picked'], [true, 'Picked']] },
    },
    examples: [{ label: 'Picked', ground: 'reading', props: { on: true } }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div role="button" style="display:flex;align-items:center;gap:12px;padding:16px 18px;border-radius:20px;background:${p.on ? r.accentTint : r.card};box-shadow:inset 0 0 0 ${p.on ? 2 : 1}px ${p.on ? r.accent : r.hairline}"><div style="flex:1;min-width:0;display:flex;flex-direction:column;gap:3px"><div style="${F('body', { size: 16, weight: 600 })}color:${r.ink}">${esc(p.title)}</div><div style="${F('footnote', { size: 14, weight: 500 })}color:${r.muted}">${esc(p.detail)}</div></div>${p.on ? glyph('checkmark.circle.fill', 24, r.accent, `--on:${CREAM}`) : ''}</div>`;
    },
  });

  E({
    type: 'waterClimatePill', name: 'Climate pill', group: 'Water', source: WG + ' (climate)',
    props: { title: { label: 'Words', kind: 'text', default: 'Mild or cool' }, on: { label: 'State', kind: 'select', default: false, options: [[false, 'Not picked'], [true, 'Picked']] } },
    render(p, ctx) {
      const r = R4(ctx);
      return `<div role="button" style="flex:1;min-height:52px;display:flex;align-items:center;justify-content:center;border-radius:999px;background:${p.on ? r.accentTint : r.card};box-shadow:inset 0 0 0 ${p.on ? 2 : 1}px ${p.on ? r.accent : r.hairline};${F('body', { size: 16, weight: 600 })}color:${r.ink}">${esc(p.title)}</div>`;
    },
  });

  E({
    type: 'waterBreakdownRow', name: 'Goal breakdown row', group: 'Water', source: WG + ' (row)',
    props: {
      label: { label: 'Label', kind: 'text', default: 'Base for 154 lb' },
      value: { label: 'Value', kind: 'text', default: '78 fl oz' },
      divider: { label: 'Hairline under it', kind: 'bool', labels: ['Show', 'Hide'], default: true },
    },
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="display:flex;align-items:center;gap:8px;padding:12px 0;${p.divider ? `border-bottom:.5px solid ${r.hairline};` : ''}${F('body', { size: 16, weight: 400 })}"><span style="flex:1;color:${r.muted}">${esc(p.label)}</span><span style="font-weight:600;color:${r.ink}">${esc(p.value)}</span></div>`;
    },
  });

  E({
    type: 'waterAdjustRow', name: 'Adjust stepper', group: 'Water', source: WG + ' (goal)',
    description: '"Adjust", then a 44 pt minus, the glasses, and a 44 pt plus. One glass at a time, 1.5 to 4 L.',
    props: { label: { label: 'Label', kind: 'text', default: 'Adjust' }, value: { label: 'Glasses', kind: 'text', default: '9 glasses' } },
    render(p, ctx) {
      const r = R4(ctx);
      const b = (icon, label) => `<div role="button" aria-label="${label}" style="width:44px;height:44px;border-radius:50%;background:${r.surface};display:flex;align-items:center;justify-content:center;flex:none">${glyph(icon, 18, r.ink)}</div>`;
      return `<div style="display:flex;align-items:center;gap:8px"><span style="flex:1;${F('body', { size: 16, weight: 600 })}color:${r.muted}">${esc(p.label)}</span>${b('minus', 'One glass less')}<span style="min-width:64px;text-align:center;${F('body', { size: 16, weight: 600 })}color:${r.ink}">${esc(p.value)}</span>${b('plus', 'One glass more')}</div>`;
    },
  });

  /* ---------- Shared builders ---------- */
  const SHEET_SCREEN = { area: 'Me', ground: 'reading', fullBleed: true, statusInk: CREAM, homeInk: 'ink' };
  const sheet = (h, kids, o) => h('settingsSheet', 'sheet', Object.assign({}, o || {}), kids);
  const nav = (h, p) => h('settingsNavBar', 'nav', p);
  const sec = (h, id, p, rows) => h('settingsSection', id, p, rows);
  const row = (h, id, p) => h('settingsRow', id, p);
  const notice = (h) => h('nrtLabelNotice', 'label-notice', {});

  /* ---------- Settings ---------- */
  const QUIT_SHORT = 'Fri 6 Nov';
  Lab.screen(Object.assign({}, SHEET_SCREEN, {
    id: 'settings', name: 'Settings', source: SET,
    note: 'How it is reached: only from the 44 pt "S" profile button on Today\'s header (TodayHeaderV4 onSettings → HomeView .sheet SettingsSheet). The Me tab opens ProgressTab ("Your progress"), which has no way into Settings, although HomeView\'s comment says "Me holds Progress and Settings (decision 21)". ' +
      'A system List (inset grouped, SF 17 pt rows) in an iOS page sheet; drawn as iOS 26 (glass bar buttons, wide switches) because the app links against the iOS 26 SDK; the switch shape and bar colour can be changed to iOS 18. Section headers and footers are 13 pt. ' +
      'Assumed: Sam\'s products are cigarettes (main) then vape; the en-GB style dates and 24-hour clock used across the lab ("Fri 6 Nov", "04"), but a US region so the currency reads "USD · $"; version 1.0.0 from project.yml. The share sheet is iOS\'s own; its app names are system labels, drawn approximately.',
    states: [
      { id: 'main', label: 'Sam on trial (App Store build)' },
      { id: 'free', label: 'Free (no Pro)' },
      { id: 'privacy', label: 'Lock Screen privacy on' },
      { id: 'test', label: 'Test build (Demo mode shown)' },
      { id: 'delete', label: 'Delete all data · alert' },
      { id: 'export', label: 'Export my data · share sheet' },
    ],
    build(h, st) {
      const privacy = st.id === 'privacy';
      return sheet(h, [
        nav(h, { title: 'Settings', trailing: 'Done' }),
        sec(h, 'sec-quit', { header: 'Your quit', gap: 12 }, [
          row(h, 'products', { label: 'Products', icon: 'cloud', value: 'Cigarettes and Vape', alts: { value: ['Vape and Cigarettes'] } }),
          row(h, 'quit-day', { label: 'Quit Day', icon: 'calendar', value: QUIT_SHORT }),
          row(h, 'day-end', { label: 'Day ends at', icon: 'moon', value: '04', alts: { value: ['midnight', '02', '06', '4 AM'] } }),
          row(h, 'currency', { label: 'Currency', icon: 'banknote', value: 'USD · $' }),
        ]),
        sec(h, 'sec-app', { header: 'App', footer: 'Other haptics follow System Haptics in iPhone Settings.' }, [
          row(h, 'notifications', { label: 'Notifications', icon: 'bell' }),
          row(h, 'haptics', { label: 'Breathing haptics', icon: 'water.waves', kind: 'toggle', on: true }),
          row(h, 'voice', { label: 'Voice guidance', icon: 'waveform', kind: 'toggle', on: true }),
          row(h, 'appearance', { label: 'Appearance', icon: 'circle.lefthalf.filled', kind: 'menu', value: 'Automatic', alts: { value: ['Light', 'Dark'] } }),
        ]),
        st.id === 'test' ? sec(h, 'sec-testing', { header: 'Testing', footer: 'Unlocks everything, opens every program session at any time, and lets you pick any Quit Day, past ones too. Only in test builds.' }, [
          row(h, 'demo', { label: 'Demo mode', icon: 'sparkles.rectangle.stack', kind: 'toggle', on: false }),
        ]) : null,
        sec(h, 'sec-widgets', { header: 'Widgets', footer: 'Hides money and the word nicotine from widgets anyone can see.' }, [
          row(h, 'widget-privacy', { label: 'Privacy mode on the Lock Screen', icon: 'eye.slash', kind: 'toggle', on: privacy }),
          privacy ? row(h, 'widget-home', { label: 'Apply to Home Screen', icon: 'apps.iphone', kind: 'toggle', on: false }) : null,
          row(h, 'lock-tip', { label: 'Add Craving SOS to your Lock Screen', detail: 'Long-press the Lock Screen, tap Customize, then swap the torch or camera button for Craving SOS.', kind: 'info', font: 'dx', iconStyle: 'none', padTop: 13, padBottom: 13 }),
        ]),
        sec(h, 'sec-sub', { header: 'Subscription' }, [
          row(h, 'pro', { label: 'DayXero Pro', icon: 'star', value: st.id === 'free' ? 'Free' : 'Pro', alts: { value: ['Pro', 'Free'] } }),
        ]),
        sec(h, 'sec-data', { header: 'Your data' }, [
          row(h, 'privacy', { label: 'Privacy', icon: 'lock' }),
          row(h, 'export', { label: 'Export my data', icon: 'square.and.arrow.up', kind: 'button', tone: 'ink' }),
          row(h, 'delete', { label: 'Delete all data', icon: 'trash', iconStyle: 'plain', kind: 'button', tone: 'red' }),
        ]),
        sec(h, 'sec-about', { header: 'About', footer: 'DayXero 1.0.0', footerAlign: 'center', footerTop: 19 }, [
          row(h, 'health', { label: 'Health information', icon: 'heart' }),
          row(h, 'terms', { label: 'Terms of use', icon: 'doc.text', kind: 'button', tone: 'ink' }),
        ]),
        h('spacer', 'end', { size: 32 }),
      ]);
    },
    overlay(h, st) {
      if (st.id === 'delete') return h('settingsAlert', 'delete-alert', { title: 'Delete everything?', message: "This removes your plan, logs, check-ins and progress from this iPhone. It can't be undone. Your subscription isn't affected.", buttons: 'Delete everything|Cancel', roles: 'destructive|cancel' });
      if (st.id === 'export') return h('settingsShareSheet', 'share', {});
      return null;
    },
  }));

  /* Products */
  const CIG_LINE = '12 cigarettes a day · $10.00 for 20';
  const VAPE_LINE = '2 pods a week · $10.00 each';
  Lab.screen(Object.assign({}, SHEET_SCREEN, {
    id: 'settings-products', name: 'Products', source: SET + ' (ProductsSettingsView)',
    note: 'Pushed from Settings. Main product first. Assumed baselines: cigarettes 12 a day at the US onboarding middle price ($10 for a pack of 20); vape at onboarding\'s default, 2 pods a week of 600 puffs at $10 each. Those come to about $8.86 a day, not the persona\'s $7, which the repo doesn\'t split by product. "Add a product" offers only Nicotine pouches here.',
    states: [{ id: 'list', label: 'Cigarettes main' }, { id: 'vape-main', label: 'After "Make this my main product" on vape' }],
    build(h, st) {
      const vapeMain = st.id === 'vape-main';
      const cig = h('settingsProductRow', 'product-cigarettes', { title: 'Cigarettes', main: !vapeMain, detail: CIG_LINE });
      const vape = h('settingsProductRow', 'product-vape', { title: 'Vape', main: vapeMain, detail: VAPE_LINE });
      return sheet(h, [
        nav(h, { title: 'Products', leading: 'back' }),
        sec(h, 'sec-products', { gap: 12, footer: "Changing a baseline updates money kept and counters from Quit Day. Days clear don't change." }, [
          vapeMain ? vape : cig, vapeMain ? cig : vape,
          row(h, 'add', { label: 'Add a product', icon: 'plus', iconStyle: 'plain', kind: 'button', tone: 'accent' }),
        ]),
      ]);
    },
  }));

  Lab.screen(Object.assign({}, SHEET_SCREEN, {
    id: 'settings-product-editor', name: 'Product editor', source: SET + ' (ProductEditor)',
    note: 'A second sheet (large) over Products. The price field shows the stored Decimal as typed text ("10"). "Make this my main product" shows only on a product that isn\'t main; "Remove …" only with two or more products. Picking "One at a time" for cigarettes swaps the price label to "Price of one cigarette" and hides "Cigarettes in a pack".',
    states: [{ id: 'cigarettes', label: 'Cigarettes (main)' }, { id: 'vape', label: 'Vape (make main)' }],
    build(h, st) {
      const vape = st.id === 'vape';
      const rows = vape ? [
        row(h, 'per-day', { label: 'Pods a week', kind: 'stepper', value: '2', iconStyle: 'none' }),
        row(h, 'price', { label: 'Price of one', kind: 'field', value: '10', iconStyle: 'none' }),
        row(h, 'per-purchase', { label: 'Puffs in a pod', kind: 'stepper', value: '600', iconStyle: 'none' }),
      ] : [
        row(h, 'per-day', { ink: 'cigarettes', label: ' a day', kind: 'stepper', value: '12', iconStyle: 'none' }),
        row(h, 'buy', { label: 'How you buy them', kind: 'menu', value: 'By the pack', iconStyle: 'none', alts: { value: ['One at a time'] } }),
        row(h, 'price', { label: 'Price of a pack', kind: 'field', value: '10', iconStyle: 'none', alts: { label: ['Price of one cigarette'] } }),
        row(h, 'per-purchase', { label: 'Cigarettes in a pack', kind: 'stepper', value: '20', iconStyle: 'none' }),
      ];
      return sheet(h, [
        nav(h, { title: vape ? 'Vape' : 'Cigarettes', trailing: 'Done' }),
        sec(h, 'sec-baseline', { gap: 12, footer: vape ? "That's about $1,043 a year." : "That's $0.50 a cigarette, about $2,190 a year." }, rows),
        vape ? sec(h, 'sec-main', { gap: 35 }, [row(h, 'make-main', { label: 'Make this my main product', kind: 'button', tone: 'accent', iconStyle: 'none' })]) : null,
        sec(h, 'sec-remove', { gap: 35 }, [row(h, 'remove', { label: vape ? 'Remove vape' : 'Remove cigarettes', kind: 'button', tone: 'red', iconStyle: 'none', alts: { label: ['Remove nicotine pouches'] } })]),
      ], { top: 96, behind: 'sheet' });
    },
  }));

  /* Currency */
  const CURRENCIES = [
    ['US Dollar', 'USD · $ · your region', true], ['Afghan Afghani', 'AFN · AFN'], ['Albanian Lek', 'ALL · ALL'], ['Algerian Dinar', 'DZD · DZD'],
    ['Angolan Kwanza', 'AOA · AOA'], ['Argentine Peso', 'ARS · ARS'], ['Armenian Dram', 'AMD · AMD'], ['Aruban Florin', 'AWG · AWG'],
    ['Australian Dollar', 'AUD · A$'], ['Azerbaijani Manat', 'AZN · AZN'], ['Bahamian Dollar', 'BSD · BSD'],
  ];
  const POUNDS = [['British Pound', 'GBP · £'], ['Egyptian Pound', 'EGP · EGP'], ['Falkland Islands Pound', 'FKP · FKP'], ['Gibraltar Pound', 'GIP · GIP'], ['Lebanese Pound', 'LBP · LBP'], ['South Sudanese Pound', 'SSP · SSP'], ['St. Helena Pound', 'SHP · SHP'], ['Sudanese Pound', 'SDG · SDG'], ['Syrian Pound', 'SYP · SYP']];
  Lab.screen(Object.assign({}, SHEET_SCREEN, {
    id: 'settings-currency', name: 'Currency', source: SET + ' (CurrencySettingsView)',
    note: 'Every common ISO currency: the region\'s first (Sam: US Dollar, with "your region"), then the rest by name, as Foundation names them in English. The rows after USD are the start of that list; the exact order and symbols come from the phone\'s locale. Picking one relabels money; it doesn\'t convert it.',
    states: [{ id: 'list', label: 'List' }, { id: 'search', label: 'Searching "pound"' }],
    build(h, st) {
      const search = st.id === 'search';
      const list = search ? POUNDS : CURRENCIES;
      return sheet(h, [
        nav(h, { title: 'Currency', leading: 'back' }),
        h('settingsSearchBar', 'search', { typed: search ? 'pound' : '' }),
        sec(h, 'sec-currencies', { gap: 16, footer: search ? '' : "Changes the currency your money is shown in. Prices you've entered keep their numbers, so if they were in another currency, update them in Products." },
          list.map(([name, line, on], i) => row(h, 'currency-' + i, { label: name, detail: line, kind: 'check', on: !!on, iconStyle: 'none', tone: 'ink', padTop: 9, padBottom: 9 }))),
      ]);
    },
  }));

  /* Quit Day */
  Lab.screen(Object.assign({}, SHEET_SCREEN, {
    id: 'settings-quit-day', name: 'Quit Day', source: SET + ' (QuitDaySettingsView)',
    note: 'Before Quit Day: the calendar from tomorrow to 30 days on (Sam on Mon 2 Nov: 3 Nov to 2 Dec). After: only by choice; the picker runs from today to 30 days on. The calendar week starts on Monday as en-GB phones do (Sunday on en-US). The app has no plural strings, so on the day before Quit Day this reads "In 1 days", and "1 days clear" on Quit Day.',
    states: [
      { id: 'prep', label: 'Prep · Mon 2 Nov' },
      { id: 'after', label: 'Day 3 · Sun 8 Nov' },
      { id: 'choosing', label: 'Day 3 · choosing a new date' },
      { id: 'confirm', label: 'Day 3 · confirm alert' },
      { id: 'demo', label: 'Demo mode (test builds)' },
    ],
    build(h, st) {
      const prep = st.id === 'prep' || st.id === 'demo';
      const head = sec(h, 'sec-date', { gap: 12 }, [
        row(h, 'date', { label: 'Friday 6 November', detail: prep ? 'In 4 days' : '3 days clear', kind: 'info', font: 'dx', iconStyle: 'none', alts: { detail: ['In 4 days', 'In 1 days', '3 days clear', '1 days clear'] } }),
      ]);
      let body;
      if (st.id === 'demo') {
        body = sec(h, 'sec-picker', { header: 'Demo mode', footer: 'Any date, past ones too. Counters, money kept and milestones follow it straight away.' }, [h('settingsCalendar', 'calendar', { selected: 6, today: 2, min: 1 })]);
      } else if (prep) {
        body = sec(h, 'sec-picker', { footer: 'Your prep days adjust to fit.' }, [h('settingsCalendar', 'calendar', { selected: 6, today: 2, min: 3 })]);
      } else {
        const choosing = st.id === 'choosing' || st.id === 'confirm';
        body = sec(h, 'sec-new', {}, [
          row(h, 'passed', { label: "Your Quit Day has passed. If you'd like to start counting again from a new date, you can set one. Your lessons, logs and plans all stay.", kind: 'info', iconStyle: 'none', font: 'subtitle', tone: 'muted' }),
          choosing ? h('settingsCalendar', 'calendar', { selected: 8, today: 8, min: 8 }) : null,
          row(h, 'action', { label: choosing ? 'Use this date' : 'Set a new Quit Day', kind: 'button', tone: 'accent', iconStyle: 'none', alts: { label: ['Set a new Quit Day', 'Use this date'] } }),
        ]);
      }
      return sheet(h, [nav(h, { title: 'Quit Day', leading: 'back' }), head, body]);
    },
    overlay(h, st) {
      if (st.id !== 'confirm') return null;
      return h('settingsAlert', 'confirm-alert', { title: 'Start counting from Sunday 8 November?', message: 'Days clear and milestones will count from the new date. Your lessons, logs and plans stay.', buttons: 'Set new Quit Day|Cancel', roles: 'default|cancel' });
    },
  }));

  /* Day ends at */
  Lab.screen(Object.assign({}, SHEET_SCREEN, {
    id: 'settings-day-end', name: 'Day ends at', source: DAYEND,
    note: 'Pushed from Settings with no title of its own. Hours are written as the phone formats an hour: "02", "04", "06" on a 24-hour en-GB phone ("2 AM" on en-US); midnight is the lower-case word. "Done" goes back.',
    states: [{ id: 'default', label: '04 (default)' }],
    build(h) {
      const opt = (hr, detail) => h('settingsOptionCard', 'option-' + hr, { title: hr, detail: detail || '', on: hr === '04', alts: { title: hr === 'midnight' ? [] : [String(+hr) + ' AM'] } });
      return sheet(h, [
        nav(h, { leading: 'back', mode: 'none' }),
        h('stack', 'page', { padX: 16, gap: 8, style: 'flex:1' }, [
          h('stack', 'title-wrap', { padTop: 24 }, [h('text', 'title', { step: 'title', text: 'When does your day end?' })]),
          h('stack', 'sub-wrap', { padBottom: 12 }, [h('text', 'sub', { step: 'footnote', tone: 'muted', text: "Up late? A check-in before this time still counts for the day you've just had." })]),
          opt('midnight'), opt('02'), opt('04', 'Default'), opt('06', 'For night shifts and late finishes'),
          h('spacer', 'push', { flex: true, size: 0 }),
          h('text', 'footer', { step: 'footnote', tone: 'muted', align: 'center', text: 'Days clear, lessons and check-ins all follow this.' }),
          h('button', 'done', { label: 'Done' }),
        ]),
      ], { fill: 'reading' });
    },
  }));

  /* Subscription */
  Lab.screen(Object.assign({}, SHEET_SCREEN, {
    id: 'settings-subscription', name: 'DayXero Pro', source: SET + ' (SubscriptionSettingsView)',
    note: 'Sam is on the annual plan\'s 3-day trial from Quit Day, so the plan line reads $39.99 a year (the design doc\'s price) and renews on Mon 9 Nov; StoreKit gives these at run time. "Unlock the full program" opens Superwall\'s paywall, or DayXero\'s.',
    states: [
      { id: 'trial', label: 'On trial (annual)' },
      { id: 'free', label: 'Free' },
      { id: 'restoring', label: 'Free · restoring' },
      { id: 'none', label: 'Free · nothing to restore' },
    ],
    build(h, st) {
      const pro = st.id === 'trial';
      const rows = pro ? [
        row(h, 'plan', { label: 'Annual · $39.99 a year', detail: 'Renews on 9 November 2026', kind: 'info', font: 'dx', iconStyle: 'none', tone: 'label', padTop: 4, alts: { label: ['Monthly · $9.99 a month', 'Lifetime · $79.99'], detail: ['Ends on 9 November 2026'] } }),
        row(h, 'manage', { label: 'Manage subscription', kind: 'button', tone: 'accent', iconStyle: 'none' }),
      ] : [row(h, 'unlock', { label: 'Unlock the full program', kind: 'button', tone: 'accent', iconStyle: 'none' })];
      rows.push(row(h, 'restore', { label: st.id === 'restoring' ? 'Restoring…' : 'Restore purchases', kind: 'button', tone: 'accent', iconStyle: 'none', disabled: st.id === 'restoring', alts: { label: ['Restoring…'] } }));
      const plan = pro ? [h('stack', 'plan-kicker', { padX: 16, padTop: 11 }, [h('text', 'your-plan', { step: 'caption', tone: 'muted', text: 'Your plan' })])] : [];
      return sheet(h, [
        nav(h, { title: 'DayXero Pro', leading: 'back' }),
        sec(h, 'sec-plan', { gap: 12, footer: st.id === 'none' ? 'No purchases found for this Apple ID.' : 'Payment, renewal and cancellation are handled by your Apple ID.', alts: { footer: ['Purchases restored.'] } }, plan.concat(rows)),
      ]);
    },
  }));

  /* Privacy */
  Lab.screen(Object.assign({}, SHEET_SCREEN, {
    id: 'settings-privacy', name: 'Privacy', source: SET + ' (PrivacySettingsView)',
    note: 'Usage data is on by default outside the EU, Iceland, Liechtenstein and Norway (opt-in there). The "Privacy policy" link shows only when AppLinks.privacy is set; it is nil in the code, so the app shows no policy link here.',
    states: [{ id: 'us', label: 'US (usage data on)' }, { id: 'eu', label: 'EU (opt-in, off)' }],
    build(h, st) {
      const fact = (id, icon, title, body) => row(h, id, { label: title, detail: body, icon, iconStyle: 'circle30', font: 'dx', kind: 'info', align: 'top', padTop: 15, padBottom: 15 });
      return sheet(h, [
        nav(h, { title: 'Privacy', leading: 'back' }),
        sec(h, 'sec-facts', { header: 'Your data stays on this iPhone', gap: 12 }, [
          fact('fact-account', 'iphone', 'No account', 'Your plan, reasons, photos, logs and notes are stored only on this iPhone.'),
          fact('fact-usage', 'chart.bar', 'Anonymous usage data', 'Things like "lesson started" or "paywall shown", so we can improve DayXero. Never your reasons, notes, photos or anything you type. Sent to PostHog (US).'),
          fact('fact-purchases', 'star', 'Purchases', 'Handled by Apple and RevenueCat with an anonymous ID.'),
        ]),
        sec(h, 'sec-consent', { gap: 35 }, [row(h, 'share-usage', { label: 'Share anonymous usage data', kind: 'toggle', on: st.id !== 'eu', iconStyle: 'none' })]),
      ]);
    },
  }));

  /* Health information */
  Lab.screen(Object.assign({}, SHEET_SCREEN, {
    id: 'settings-health', name: 'Health information', source: SET + ' (HealthInfoView)',
    note: 'The health disclaimer (S15.6), on the reading ground: four paragraphs, 16 pt, 12 pt apart.',
    states: [{ id: 'default', label: 'Default' }],
    build(h) {
      const lines = [
        "DayXero offers education and support to help you stop using nicotine. It isn't medical treatment, and it doesn't replace advice from a doctor or pharmacist.",
        "If you're pregnant, have a health condition or take other medication, talk to a doctor or pharmacist before using NRT.",
        'Health facts in the app name their sources, and you can open each one.',
        "If you're struggling with your mood, or in crisis, contact a doctor or your local emergency number.",
      ];
      return sheet(h, [
        nav(h, { title: 'Health information', leading: 'back' }),
        h('stack', 'body', { padX: 16, padTop: 16, gap: 12 }, lines.map((t, i) => h('text', 'line-' + (i + 1), { step: 'body', text: t }))),
      ], { fill: 'reading' });
    },
  }));

  /* ---------- Notifications ---------- */
  const DAY_ROWS = [
    ['pledge', 'Morning pledge', "Skipped once you've pledged", 'sun.max', '08:00'],
    ['lesson', 'Lesson ready', 'When a new day opens', 'book.closed', '12:00'],
    ['checkin', 'Evening check-in', "Skipped once you've checked in", 'moon', '21:00'],
    ['milestone', 'Milestones', 'On the day', 'flag', '09:00'],
  ];
  Lab.screen(Object.assign({}, SHEET_SCREEN, {
    id: 'notifications', name: 'Notifications', source: NOTI,
    note: 'Pushed from Settings → Notifications. Default times (08:00, 12:00, 21:00, 09:00; quiet 22:30 – 07:30) in the lab\'s 24-hour en-GB clock ("8:00 AM" on en-US). Turning a switch off hides its time. When iPhone Settings has notifications off, the amber row shows and both groups grey out.',
    states: [{ id: 'default', label: 'Defaults' }, { id: 'denied', label: 'Off in iPhone Settings' }, { id: 'quiet-off', label: 'Quiet hours off, milestones off' }],
    build(h, st) {
      const denied = st.id === 'denied', some = st.id === 'quiet-off';
      const dayRows = [];
      DAY_ROWS.forEach(([id, title, detail, icon, time]) => {
        const on = !(some && id === 'milestone');
        dayRows.push(row(h, id, { label: title, detail, icon, iconStyle: 'box30', font: 'dx', kind: 'toggle', on, disabled: denied, padBottom: on ? 0 : 11 }));
        if (on) dayRows.push(row(h, id + '-time', { label: 'Time', kind: 'time', value: time, font: 'dxSmall', iconStyle: 'none', separator: false, padTop: 8, minHeight: 0, disabled: denied }));
      });
      return sheet(h, [
        nav(h, { title: 'Notifications', leading: 'back' }),
        denied ? sec(h, 'sec-denied', { gap: 12, fill: 'amber' }, [h('notificationsDenied', 'denied', {})]) : null,
        sec(h, 'sec-day', { header: 'Your day', gap: denied ? 24 : 12 }, dayRows),
        sec(h, 'sec-plan', { header: 'Your plan' }, [
          row(h, 'nrt', { label: 'NRT', detail: 'Patch changes and step-downs', icon: 'bandage', iconStyle: 'box30', font: 'dx', kind: 'toggle', on: true, disabled: denied }),
          row(h, 'away', { label: "When you've been away", detail: 'Two gentle notes, then quiet', icon: 'water.waves', iconStyle: 'box30', font: 'dx', kind: 'toggle', on: true, disabled: denied }),
        ]),
        sec(h, 'sec-quiet', { header: 'Quiet hours', footer: 'At most three a day from the program. NRT reminders you set always arrive.' }, [
          row(h, 'quiet', { label: 'Quiet hours', detail: 'Nothing between these times', icon: 'clock', iconStyle: 'box30', font: 'dx', value: some ? 'Off' : '22:30 – 07:30', alts: { value: ['Off'] } }),
        ]),
        h('spacer', 'end', { size: 32 }),
      ]);
    },
  }));

  E({
    type: 'notificationsDenied', name: 'Notifications-off row', group: 'Settings', source: NOTI,
    description: 'Shown when iPhone Settings has DayXero\'s notifications off: a 14 pt line and an ink "Turn on" button, on an amber row.',
    props: { text: { label: 'Words', kind: 'text', default: 'Notifications are off for DayXero in iPhone Settings.' }, button: { label: 'Button', kind: 'text', default: 'Turn on' } },
    examples: [{ label: 'Default', ground: 'reading', props: {} }],
    render(p, ctx) {
      const r = R4(ctx);
      return `<div style="display:flex;align-items:center;gap:12px;padding:11px 16px"><div style="flex:1;${F('footnote', { size: 14, weight: 400, lh: 1.35 })}color:${SYS(ctx).label}">${esc(p.text)}</div><div role="button" style="flex:none;padding:7px 14px;border-radius:999px;background:${r.ink};${sf(15, 600)}color:${ctx.dark ? '#0E0B2B' : '#FFFFFF'}">${esc(p.button)}</div></div>`;
    },
  });

  E({
    type: 'notificationsQuietStrip', name: 'Quiet hours strip', group: 'Settings', source: NOTI + ' (QuietHoursView.strip)',
    description: '24 hours in a 34 pt strip, radius 12: the quiet band in grey, today\'s pledge, lesson and check-in as 6 × 14 pt green marks.',
    props: {
      start: { label: 'Quiet from', kind: 'number', options: [[1320, '22:00'], [1350, '22:30'], [1380, '23:00']], default: 1350 },
      end: { label: 'Quiet until', kind: 'number', options: [[390, '06:30'], [420, '07:00'], [450, '07:30']], default: 450 },
      marks: { label: 'Marks (minutes, | between)', kind: 'select', default: '480|720|1260', options: [['480|720|1260', 'Pledge 08:00, lesson 12:00, check-in 21:00'], ['480|720', 'Pledge and lesson']] },
    },
    examples: [{ label: 'Defaults', ground: 'reading', props: {} }],
    render(p, ctx) {
      const r = R4(ctx);
      const pc = (m) => (m / 1440) * 100;
      const band = p.start > p.end
        ? `<div style="position:absolute;top:0;bottom:0;left:0;width:${pc(p.end)}%;background:${r.track}"></div><div style="position:absolute;top:0;bottom:0;left:${pc(p.start)}%;right:0;background:${r.track}"></div>`
        : `<div style="position:absolute;top:0;bottom:0;left:${pc(p.start)}%;width:${pc(p.end - p.start)}%;background:${r.track}"></div>`;
      const marks = String(p.marks).split('|').map(Number).map((m) => `<div style="position:absolute;top:10px;left:calc(${pc(m)}% - 3px);width:6px;height:14px;border-radius:3px;background:${r.accent}"></div>`).join('');
      return `<div style="position:relative;height:34px;border-radius:12px;overflow:hidden;background:${r.card}">${band}${marks}</div>`;
    },
  });

  E({
    type: 'notificationsTimeCard', name: 'From / until card', group: 'Settings', source: NOTI + ' (QuietHoursView.timeCard)',
    props: { title: { label: 'Kicker', kind: 'text', default: 'From' }, time: { label: 'Time', kind: 'text', default: '22:30' } },
    examples: [{ label: 'From', ground: 'reading', props: {} }],
    render(p, ctx) {
      const r = R4(ctx), s = SYS(ctx);
      return `<div style="flex:1;min-width:0;display:flex;flex-direction:column;align-items:center;gap:4px;padding:14px;border-radius:18px;background:${r.card}">${T('caption', p.title, ctx.with({ groundName: 'reading' }), { tone: 'muted' })}<span style="${sf(17)}color:${s.label};background:${s.fill};border-radius:8px;padding:6px 11px">${esc(p.time)}</span></div>`;
    },
  });

  Lab.screen(Object.assign({}, SHEET_SCREEN, {
    id: 'notifications-quiet-hours', name: 'Quiet hours', source: NOTI + ' (QuietHoursView)',
    note: 'Pushed from Notifications. The legend says "Sage marks" but the marks are drawn in Read4.accent green. Times in the 24-hour en-GB clock.',
    states: [{ id: 'on', label: 'On · 22:30 – 07:30' }, { id: 'off', label: 'Off' }],
    build(h, st) {
      const on = st.id === 'on';
      const plain = (id, p) => row(h, id, Object.assign({ kind: 'toggle', iconStyle: 'none', inset: 0, minHeight: 0, padTop: 0, padBottom: 0, separator: false, font: 'dx' }, p));
      return sheet(h, [
        nav(h, { title: 'Quiet hours', leading: 'back' }),
        h('stack', 'body', { padX: 16, padTop: 16, gap: 12 }, [
          h('text', 'intro', { step: 'footnote', tone: 'muted', text: 'Nothing arrives between these times. Anything due waits until they end.' }),
          plain('quiet-toggle', { label: 'Quiet hours', on }),
          on ? h('row', 'times', { gap: 8 }, [h('notificationsTimeCard', 'from', { title: 'From', time: '22:30' }), h('notificationsTimeCard', 'until', { title: 'Until', time: '07:30' })]) : null,
          on ? h('notificationsQuietStrip', 'strip', {}) : null,
          on ? h('text', 'legend', { step: 'footnote', tone: 'muted', text: 'Grey is quiet. Sage marks are your daily notifications.' }) : null,
          h('stack', 'nrt-wrap', { padTop: 12 }, [plain('nrt-through', { label: 'Let my NRT times through', detail: 'Times you set yourself', on: true })]),
        ]),
      ], { fill: 'reading' });
    },
  }));

  /* ---------- NRT setup ---------- */
  const NRT_SCREEN = { area: 'Me', ground: 'reading' };
  const PATCH_US = [
    ['us-patch-10', '10 weeks, starting on 21 mg', '21 mg × 6 wk, 14 mg × 2 wk, 7 mg × 2 wk'],
    ['us-patch-8', '8 weeks, starting on 21 mg', '21 mg × 4 wk, 14 mg × 2 wk, 7 mg × 2 wk'],
    ['us-patch-14', '8 weeks, starting on 14 mg', '14 mg × 6 wk, 7 mg × 2 wk'],
  ];
  const COUNTRIES = ['US', 'UK', 'Australia', 'Germany', 'India', 'Elsewhere'];
  const NRT_TYPES = [
    ['patch', 'Patch', 'Worn all day, changed daily', 'bandage'],
    ['gum', 'Gum', 'Chew and park', 'square.grid.2x2'],
    ['lozenge', 'Lozenge', 'Dissolves slowly', 'capsule'],
    ['inhaler', 'Inhaler', 'Puff on a cartridge', 'lungs'],
  ];
  const PATCH_STEPS = [['21 mg', 'Fri 6 Nov – Thu 17 Dec', '6 weeks'], ['14 mg', 'Fri 18 Dec – Thu 31 Dec', '2 weeks'], ['7 mg', 'Fri 1 Jan – Thu 14 Jan', '2 weeks']];

  function nrtPage(h, bar, content, buttons) {
    return [
      h('settingsNavBar', 'nav', Object.assign({ mode: 'none', padTop: 0 }, bar)),
      h('stack', 'page', { padX: 16, gap: 8, style: 'flex:1' }, [
        h('stack', 'content', { gap: 8, padTop: 12 }, content),
        h('spacer', 'push', { flex: true, size: 0 }),
      ].concat(buttons)),
    ];
  }
  const countryChips = (h, picked) => h('row', 'countries', { gap: 8, wrap: true, style: 'padding-top:8px' }, COUNTRIES.map((c) => h('nrtToggleChip', 'country-' + c.toLowerCase(), { label: c, on: c === picked })));

  Lab.screen(Object.assign({}, NRT_SCREEN, {
    id: 'nrt-setup', name: 'NRT setup', source: NRT,
    note: 'Full screen, from Today\'s NRT invitation, Program (Day 4 beat) and the slip flow. Sam\'s onboarding sample uses a patch and gum, so both are picked and each gets a schedule then a plan; his US region preselects US labels. Sam smokes 12 a day, so the 10-week label is ticked (the app never picks). Starts on Quit Day, Fri 6 Nov. The step label in the bar is the 12 pt caption. The bar buttons take the app\'s AccentColor on iOS 18 (old sage #55621F).',
    states: [
      { id: 'intro', label: '1 · Intro' },
      { id: 'products-none', label: '2 · What are you using? (nothing yet)' },
      { id: 'products', label: '2 · Patch and gum picked' },
      { id: 'schedule-patch', label: '3 · Patch schedule, 10 weeks ticked' },
      { id: 'schedule-empty', label: '3 · Patch schedule, nothing ticked' },
      { id: 'schedule-elsewhere', label: '3 · Patch schedule, Elsewhere' },
      { id: 'plan-patch', label: '4 · Your patch plan' },
      { id: 'schedule-gum', label: '5 · Gum: what does your pack say?' },
      { id: 'reminders', label: '6 · Reminders' },
      { id: 'reminders-piece', label: '6 · Reminders, time for a piece on' },
    ],
    build(h, st) {
      const s = st.id;
      if (s === 'intro') {
        return nrtPage(h, { leading: 'xmark' }, [
          h('text', 'title', { step: 'title', text: 'Keep your NRT on track' }),
          h('text', 'sub', { step: 'footnote', tone: 'muted', text: "Tell us what's on your pack. We'll remind you to change patches and when each step down is due." }),
          h('stack', 'why', { fill: 'raised', radius: 18, padX: 20, padTop: 20, padBottom: 20, gap: 6, style: 'margin-top:12px' }, [
            h('text', 'why-kicker', { step: 'caption', tone: 'muted', text: "Why it's worth it" }),
            h('text', 'why-fact', { step: 'body', size: 16, weight: 600, text: "People who use NRT are 50–60% more likely to quit than people who don't." }),
            h('nrtSourceLink', 'why-source', { text: 'Source: Cochrane review of 133 trials, 2018' }),
          ]),
          notice(h),
        ], [h('button', 'next', { label: 'Set up my NRT' }), h('button', 'pharmacist', { label: 'Not using NRT yet? Ask a pharmacist', kind: 'quiet' })]);
      }
      if (s === 'products-none' || s === 'products') {
        const two = s === 'products';
        return nrtPage(h, { leading: 'back', principal: 'What you use' }, [
          h('text', 'title', { step: 'title', text: 'What are you using?' }),
          h('text', 'sub', { step: 'footnote', tone: 'muted', text: 'Pick up to two, as your pharmacist or doctor suggested, or as on your pack.' }),
          h('stack', 'types', { gap: 8, padTop: 12 }, NRT_TYPES.map(([id, t, d, icon]) => h('settingsOptionCard', 'type-' + id, { title: t, detail: d, icon, on: two && (id === 'patch' || id === 'gum') }))),
          two ? h('text', 'two-note', { step: 'footnote', tone: 'muted', text: 'Using two together? Only if a pharmacist or doctor suggested it.' }) : null,
        ], [h('button', 'next', { label: 'Next', disabled: !two })]);
      }
      if (s.startsWith('schedule-') && s !== 'schedule-gum') {
        const ticked = s === 'schedule-patch', elsewhere = s === 'schedule-elsewhere';
        const presets = elsewhere ? [] : PATCH_US.map(([id, t, d], i) => h('nrtPresetCard', 'preset-' + (i + 1), { title: t, detail: d, on: ticked && i === 0 }));
        return nrtPage(h, { leading: 'back', principal: 'Patch · 1 of 2', alts: { principal: ['Your plan'] } }, [
          h('text', 'title', { step: 'title', text: 'Which schedule is on your pack?' }),
          h('text', 'sub', { step: 'footnote', tone: 'muted', text: 'Labels differ by brand and country. Pick the one that matches, or enter your own.' }),
          countryChips(h, elsewhere ? 'Elsewhere' : 'US'),
          h('stack', 'presets', { gap: 8, padTop: 12 }, presets.concat([h('nrtPresetCard', 'preset-own', { title: 'My pack says something else', detail: 'Enter each step yourself', on: false })])),
          ticked ? h('text', 'label-note', { step: 'footnote', tone: 'muted', text: 'US labels: more than 10 cigarettes a day, start on 21 mg.', alts: { text: ['Some US packs use 4 weeks on 21 mg instead of 6.', 'US labels: 10 cigarettes a day or fewer, start on 14 mg.'] } }) : null,
          ticked ? h('nrtSourceLink', 'label-source', { text: 'Source: US Drug Facts label for nicotine patches' }) : null,
          notice(h),
        ], [h('button', 'next', { label: 'Use this schedule', disabled: !ticked })]);
      }
      if (s === 'schedule-gum') {
        return nrtPage(h, { leading: 'back', principal: 'Gum · 2 of 2' }, [
          h('text', 'title', { step: 'title', text: 'What does your pack say?' }),
          h('text', 'sub', { step: 'footnote', tone: 'muted', text: 'Labels differ by brand and country. Pick the one that matches, or enter your own.' }),
          countryChips(h, 'US'),
          h('stack', 'strength-wrap', { padTop: 12 }, [h('text', 'strength-kicker', { step: 'caption', tone: 'muted', text: 'Strength on your pack' })]),
          h('row', 'strengths', { gap: 8 }, [h('nrtToggleChip', 'strength-2', { label: '2 mg', on: true }), h('nrtToggleChip', 'strength-4', { label: '4 mg', on: false })]),
          h('stack', 'presets', { gap: 8, padTop: 12 }, [
            h('nrtPresetCard', 'preset-1', { title: '12 weeks, as on the pack', detail: '1 piece every 1–2 hours × 6 wk, 1 piece every 2–4 hours × 3 wk, 1 piece every 4–8 hours × 3 wk', on: true }),
            h('nrtPresetCard', 'preset-own', { title: 'My pack says something else', detail: 'Enter each step yourself', on: false }),
          ]),
          h('text', 'label-note', { step: 'footnote', tone: 'muted', text: 'US labels: 4 mg if your first cigarette is within 30 minutes of waking, otherwise 2 mg.' }),
          h('nrtSourceLink', 'label-source', { text: 'Source: US Drug Facts label for nicotine gum' }),
          notice(h),
        ], [h('button', 'next', { label: 'Use this schedule' })]);
      }
      if (s === 'plan-patch') {
        return nrtPage(h, { leading: 'back', principal: 'Patch · 1 of 2' }, [
          h('text', 'title', { step: 'title', text: 'Your patch plan', alts: { text: ['Your gum plan'] } }),
          h('text', 'sub', { step: 'footnote', tone: 'muted', text: "From your pack's label. Tap a step to change it." }),
          h('stack', 'start-wrap', { padTop: 8 }, [row(h, 'starting', { label: 'Starting', kind: 'date', value: '6 Nov 2026', font: 'dxSmall', iconStyle: 'none', inset: 0, padTop: 0, padBottom: 0, separator: false })]),
          h('stack', 'steps', { fill: 'raised', radius: 18, padX: 14, padTop: 4, padBottom: 4 }, PATCH_STEPS.map(([t, d, w], i) => h('nrtStepRow', 'step-' + (i + 1), { number: String(i + 1), title: t, dates: d, weeks: w, state: i === 0 ? 'current' : 'plain', divider: i < 2 }))),
          h('stack', 'add-wrap', { align: 'flex-start' }, [h('button', 'add-step', { label: 'Add a step', kind: 'quiet', icon: 'plus' })]),
          notice(h),
        ], [h('button', 'next', { label: 'Next product', alts: { label: ['Next: reminders'] } })]);
      }
      const piece = s === 'reminders-piece';
      const card = (id, kids) => h('stack', id, { fill: 'raised', radius: 18, padX: 14, padTop: 14, padBottom: 14, gap: 8 }, kids);
      const tog = (id, p) => row(h, id, Object.assign({ kind: 'toggle', font: 'dx', iconStyle: 'none', inset: 0, minHeight: 0, padTop: 0, padBottom: 0, separator: false }, p));
      const small = (id, p) => row(h, id, Object.assign({ font: 'dxSmall', iconStyle: 'none', inset: 0, minHeight: 0, padTop: 0, padBottom: 0, separator: false }, p));
      return nrtPage(h, { leading: 'back', principal: 'Reminders' }, [
        h('text', 'title', { step: 'title', text: 'Reminders' }),
        h('text', 'sub', { step: 'footnote', tone: 'muted', text: "So you don't have to remember." }),
        h('stack', 'cards', { gap: 8, padTop: 12 }, [
          card('daily-card', [tog('daily', { label: 'Fresh patch', detail: 'Every day', on: true, alts: { label: ['Daily reminder'] } }), small('daily-time', { label: 'Time', kind: 'time', value: '07:30' })]),
          card('steps-card', [tog('step-days', { label: 'Step-down days', detail: 'The evening before each step', on: true })]),
          card('piece-card', [tog('piece', { label: 'Time for a piece', detail: '8am to 10pm, as often as your label says', on: piece }), piece ? small('piece-every', { label: 'Every 2 hours', kind: 'stepper' }) : null]),
        ]),
        notice(h),
      ], [h('button', 'next', { label: 'Done' })]);
    },
  }));

  Lab.screen(Object.assign({}, NRT_SCREEN, {
    id: 'nrt-step-editor', name: 'Edit step', source: NRT + ' (StepEditor)',
    ground: 'reading', fullBleed: true, statusInk: CREAM, homeInk: 'ink',
    note: 'A medium sheet over the plan, from tapping a step. On a phone this height the content runs taller than half the screen, so in the app the Spacer collapses and the sheet\'s lower part may need the sheet pulled up. "Remove this step" shows when the plan has more than one step; it uses the quiet style, which draws it in ink, not red, despite role: .destructive. Patch strengths on sale: 25, 21, 15, 14, 10 and 7 mg.',
    states: [{ id: 'patch', label: 'Patch step 1 (21 mg, 6 weeks)' }, { id: 'single', label: 'Only step (no Remove)' }],
    build(h, st) {
      return h('settingsSheet', 'sheet', { top: 380, fill: 'reading' }, [
        h('stack', 'body', { padX: 16, gap: 12, style: 'flex:1' }, [
          h('stack', 'title-wrap', { padTop: 20 }, [h('text', 'title', { step: 'title', text: 'Edit step' })]),
          h('text', 'kicker', { step: 'caption', tone: 'muted', text: 'Strength' }),
          h('row', 'strengths', { gap: 8, wrap: true }, ['25', '21', '15', '14', '10', '7'].map((mg) => h('nrtToggleChip', 'mg-' + mg, { label: mg + ' mg', on: mg === '21' }))),
          row(h, 'weeks', { label: '6 weeks', kind: 'stepper', font: 'dx', iconStyle: 'none', inset: 0, minHeight: 0, padTop: 0, padBottom: 0, separator: false }),
          h('nrtLabelNotice', 'label-notice', {}),
          h('spacer', 'push', { flex: true, size: 0 }),
          h('button', 'done', { label: 'Done' }),
          st.id === 'single' ? null : h('button', 'remove', { label: 'Remove this step', kind: 'quiet' }),
        ]),
      ]);
    },
  }));

  Lab.screen(Object.assign({}, NRT_SCREEN, {
    id: 'nrt-taper', name: 'Pouch taper', source: NRTC + ' (TaperSetupView)',
    note: 'Optional, for pouch users in prep (Sam doesn\'t use pouches; shown with the app\'s suggested steps from 6 mg: 6, 3, 1.5 mg, a week each). On Mon 2 Nov three weeks don\'t fit before Quit Day, so the steps start today and "Save my taper" stays at half strength until the person shortens it or moves Quit Day. "Fits" shows one step, opened on Fri 30 Oct. With one step the line would read "This taper needs 1 weeks" (no plural strings). "Remove the taper" (shown once a taper is saved) draws in ink: the quiet style ignores the destructive role.',
    states: [{ id: 'no-fit', label: "Doesn't fit · Mon 2 Nov" }, { id: 'fits', label: 'Fits · one step, Fri 30 Oct' }, { id: 'saved', label: 'Fits · already saved' }],
    build(h, st) {
      const fits = st.id !== 'no-fit';
      const steps = fits ? [['6 mg', 'Fri 30 Oct – Thu 5 Nov', '1 week']] : [['6 mg', 'Mon 2 Nov – Sun 8 Nov', '1 week'], ['3 mg', 'Mon 9 Nov – Sun 15 Nov', '1 week'], ['1.5 mg', 'Mon 16 Nov – Sun 22 Nov', '1 week']];
      return [
        h('row', 'top-bar', { justify: 'space-between', padX: 16, style: 'padding-top:12px' }, [
          h('iconButton', 'close', { icon: 'xmark', fill: 'surface', label: 'Close' }),
          h('text', 'optional', { step: 'caption', tone: 'muted', text: 'Optional' }),
          h('stack', 'balance', { style: 'width:44px' }),
        ]),
        h('stack', 'page', { padX: 16, gap: 8, style: 'flex:1' }, [
          h('stack', 'content', { gap: 8, padTop: 8 }, [
            h('text', 'title', { step: 'title', text: 'Step down your pouches' }),
            h('text', 'sub', { step: 'footnote', tone: 'muted', text: 'Lower the strength before Quit Day, so stopping feels smaller.' }),
            h('nrtStrengthBars', 'bars', { steps: fits ? '6' : '6|3|1.5' }),
            h('stack', 'steps', { fill: 'raised', radius: 18, padX: 14, padTop: 4, padBottom: 4 }, steps.map(([t, d, w], i) => h('nrtStepRow', 'step-' + (i + 1), { number: String(i + 1), title: t, dates: d, weeks: w, state: i === 0 ? 'current' : 'plain', divider: false }))),
            fits ? h('text', 'ends', { step: 'footnote', tone: 'muted', text: 'Ends the day before Quit Day, Friday 6 November.' })
              : h('stack', 'fit', { fill: 'raised', radius: 18, padX: 14, padTop: 14, padBottom: 14, gap: 8 }, [
                h('text', 'fit-line', { step: 'footnote', size: 14, weight: 400, text: 'This taper needs 3 weeks, and Quit Day is sooner than that.' }),
                h('text', 'fit-sub', { step: 'footnote', tone: 'muted', text: "Shorten the steps, or move Quit Day if you'd like the full taper." }),
                h('nrtSecondaryButton', 'move', { label: 'Move Quit Day to Mon 23 Nov' }),
              ]),
            h('stack', 'remind-wrap', { padTop: 8 }, [row(h, 'remind', { label: 'Remind me the evening before each step', kind: 'toggle', on: true, font: 'dxSmall', iconStyle: 'none', inset: 0, minHeight: 0, padTop: 0, padBottom: 0, separator: false })]),
            h('text', 'not-nrt', { step: 'footnote', tone: 'muted', text: "Pouches aren't NRT, so there's no label for this. It's a plan you set; change any step to suit the strengths you can buy." }),
          ]),
          h('spacer', 'push', { flex: true, size: 0 }),
          h('button', 'save', { label: 'Save my taper', disabled: !fits }),
          st.id === 'saved' ? h('button', 'remove', { label: 'Remove the taper', kind: 'quiet' }) : null,
        ]),
      ];
    },
  }));

  /* ---------- Water ---------- */
  const WATER_DAYS = {
    empty: [],
    partial: [['07:45', 'glass'], ['10:30', 'tea'], ['13:10', 'glass']],
    reached: [['07:45', 'glass'], ['10:30', 'tea'], ['13:10', 'glass'], ['14:30', 'bottle'], ['16:20', 'sparkling'], ['18:05', 'glass'], ['19:30', 'tea']],
  };
  Lab.screen({
    id: 'water', name: 'Water', area: 'Me', source: WT + ', ' + WP + ', ' + DI, ground: 'reading', fullBleed: true,
    statusInk: CREAM, homeInk: '#FFFFFF',
    note: 'Full screen over Evening ("water") or Home, always dark on black, with a close button. Sam\'s goal is the default 8 glasses (2 L) and his US region gives fl oz; drinks and times are assumed (Day 3; the goal day counts as a 1-day streak). The pill is drawn still: in the app the waves scroll, bubbles rise and a "+8 fl oz" floats up on each log. The pill shrinks to 0.7 on shorter phones. Not on Today for Sam: Home only shows the water card with one or three products (see the "Water card (Home)" element).',
    states: [
      { id: 'partial', label: 'Day 3 · 3 drinks (800 ml)' },
      { id: 'empty', label: 'Nothing yet today' },
      { id: 'reached', label: 'Goal reached (2,180 ml)' },
      { id: 'metric', label: 'Metric (litres), 3 drinks' },
      { id: 'custom', label: 'Long-press: custom amount' },
    ],
    build(h, st) {
      const u = st.id === 'metric' ? 'metric' : 'imperial';
      const day = st.id === 'empty' ? 'empty' : st.id === 'reached' ? 'reached' : 'partial';
      const list = WATER_DAYS[day];
      const total = list.reduce((n, [, d]) => n + DRINKS[d].ml, 0);
      const goal = 2000, reached = total >= goal;
      const last = list.length ? list[list.length - 1][1] : 'glass';
      return h('waterCanvas', 'page', {}, [
        h('waterHeader', 'header', { streak: reached ? '1-DAY STREAK' : '' }),
        h('waterReadout', 'readout', { amount: wAmount(total, u), goal: `/ ${wAmount(goal, u)} ${wUnit(u)}`, line: reached ? 'Goal reached. Nice.' : `${Math.round(total / 250)} of 8 glasses`, reached, alts: { line: ['Goal reached. Nice.'] } }),
        h('waterQuietButton', 'personalise', { label: 'Personalise goal', alts: { label: ['Edit goal'] } }),
        h('waterPill', 'pill', { level: Math.min(total / goal, 1), drink: last, reached }),
        h('row', 'drinks', { gap: 8, style: 'padding-top:22px' }, Object.keys(DRINKS).map((k) => h('waterDrinkTile', 'drink-' + k, { drink: k, name: DRINKS[k].name, size: wSize(DRINKS[k].ml, u), on: k === 'glass' }))),
        h('waterLogButton', 'log', { label: 'Log ' + wSize(250, u), alts: { label: Object.keys(DRINKS).filter((k) => k !== 'glass').map((k) => 'Log ' + wSize(DRINKS[k].ml, u)) } }),
        h('stack', 'undo-wrap', { padTop: 6, align: 'center' }, [h('waterQuietButton', 'undo', { label: 'Undo last', size: 16, height: 40, hidden: !list.length })]),
        list.length ? h('stack', 'today', { padTop: 20 }, [
          h('stack', 'today-head', { padBottom: 8 }, [h('waterHeading', 'today-label', { text: 'Today', colour: 'white' })]),
        ].concat(list.slice().reverse().map(([t, d], i) => h('waterTodayRow', 'entry-' + (list.length - i), { time: t, drink: d, name: DRINKS[d].name, size: wSize(DRINKS[d].ml, u) })))) : null,
      ]);
    },
    overlay(h, st) {
      if (st.id !== 'custom') return null;
      return h('settingsAlert', 'custom-alert', { title: 'Custom amount', message: 'How much Glass?', field: 'fl oz', buttons: 'Cancel|Log', roles: 'cancel|default', layout: 'side', alts: { field: ['ml'], message: ['How much Bottle?', 'How much Tea?', 'How much Sparkling?'] } });
    },
  });

  const GOAL_STATES = {
    imperial: { u: 'imperial', weight: '154', activity: 'mostlySitting', climate: 'mild', goal: 2250, rows: [['Base for 154 lb', '78 fl oz'], ['Rounded to full glasses', '76 fl oz']] },
    metric: { u: 'metric', weight: '70', activity: 'mostlySitting', climate: 'mild', goal: 2250, rows: [['Base for 70 kg', '2.31 L'], ['Rounded to full glasses', '2.25 L']] },
    active: { u: 'metric', weight: '70', activity: 'worksOut', climate: 'hot', goal: 3250, rows: [['Base for 70 kg', '2.31 L'], ['Workouts most days', '+0.35 L'], ['Hot or humid days', '+0.50 L'], ['Rounded to full glasses', '3.25 L']] },
    adjusted: { u: 'metric', weight: '70', activity: 'mostlySitting', climate: 'mild', goal: 2500, rows: [['Base for 70 kg', '2.31 L'], ['Rounded to full glasses', '2.25 L'], ['Your adjustment', '2.50 L']] },
  };
  const ACTIVITIES = [['mostlySitting', 'Mostly sitting', 'Desk, studies, driving'], ['onMyFeet', 'On my feet a lot', 'Walking, standing at work'], ['worksOut', 'I work out most days', 'Gym, runs, sport, 30+ min'], ['veryActive', 'Very active', 'Physical job or training hard daily']];
  Lab.screen(Object.assign({}, SHEET_SCREEN, {
    id: 'water-goal', name: 'Your water goal', source: WG,
    note: '"Personalise goal" opens this large sheet over the tracker. No weight saved yet, so the ruler starts at 70 kg (154 lb); goal = weight × 33 ml + activity + climate, rounded to whole glasses, 1.5 to 4 L. The sheet follows the app\'s appearance, not the tracker\'s forced dark. The ruler drags sideways. The estimate line is 12 pt.',
    states: [
      { id: 'imperial', label: 'lb · fl oz (US default)' },
      { id: 'metric', label: 'kg · L' },
      { id: 'active', label: 'Works out, hot climate (kg · L)' },
      { id: 'adjusted', label: 'Adjusted one glass up (kg · L)' },
    ],
    build(h, st) {
      const g = GOAL_STATES[st.id] || GOAL_STATES.imperial;
      const u = g.u;
      const glasses = g.goal / 250;
      return sheet(h, [
        nav(h, { title: 'Your water goal', mode: 'inline', leading: 'xmark' }),
        h('stack', 'body', { padX: 16, padTop: 12, gap: 10, style: 'flex:1' }, [
          h('waterUnitToggle', 'units', { on: u }),
          h('stack', 'weight', { gap: 4, padTop: 8 }, [
            h('waterHeading', 'weight-heading', { text: 'Weight' }),
            h('waterBigNumber', 'weight-value', { value: g.weight, unit: u === 'metric' ? 'kg' : 'lb' }),
            h('waterRuler', 'ruler', { value: +g.weight, units: u }),
            h('waterLockLine', 'lock', {}),
          ]),
          h('stack', 'day-heading-wrap', { padTop: 12 }, [h('waterHeading', 'day-heading', { text: 'A normal day' })]),
          ...ACTIVITIES.map(([id, t, d]) => h('waterChoiceCard', 'activity-' + id, { title: t, detail: d, on: id === g.activity })),
          h('stack', 'climate-heading-wrap', { padTop: 12 }, [h('waterHeading', 'climate-heading', { text: 'Where you live, most days are' })]),
          h('row', 'climate', { gap: 10 }, [h('waterClimatePill', 'climate-mild', { title: 'Mild or cool', on: g.climate === 'mild' }), h('waterClimatePill', 'climate-hot', { title: 'Hot or humid', on: g.climate === 'hot' })]),
          h('stack', 'goal', { gap: 10, padTop: 16 }, [
            h('waterBigNumber', 'goal-value', { value: wAmount(g.goal, u), unit: wUnit(u), trail: `${glasses} glasses a day` }),
            h('stack', 'breakdown', { fill: 'raised', radius: 20, padX: 16, padTop: 4, padBottom: 4 }, g.rows.map(([l, v], i) => h('waterBreakdownRow', 'breakdown-' + (i + 1), { label: l, value: v, divider: i < g.rows.length - 1 }))),
            h('waterAdjustRow', 'adjust', { value: `${glasses} glasses` }),
          ]),
          h('stack', 'estimate-wrap', { padTop: 8, padBottom: 24 }, [h('text', 'estimate', { step: 'caption', upper: false, size: 12, weight: 500, tone: 'muted', text: 'An estimate, not medical advice. If a doctor has told you to limit fluids, use their number instead.' })]),
          h('spacer', 'push', { flex: true, size: 0 }),
          h('button', 'save', { label: 'Save goal' }),
        ]),
      ], { behind: 'black', fill: 'reading', top: 72 });
    },
  }));
})();
