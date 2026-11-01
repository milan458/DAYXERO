/* DayXero Screen Lab — core: tokens, element and screen registries, renderer, editor, saved changes.
   Screens and elements are defined in elements.js and screens/*.js; see FORMAT.md. No build step. */
(function () {
  'use strict';
  const Lab = (window.Lab = window.Lab || {});
  Lab.elements = {};
  Lab.screens = [];
  Lab.changes = {}; // key -> change doc

  /* ---------- Tokens (DayXeroCore/DesignSystem/V4/Ground.swift, design/handoff/tokens.json) ---------- */
  const NAVY = '#1E1A3A', CREAM = '#FFF8EE', PLUM = '#241433';
  Lab.grounds = {
    coral:      { light: '#FF7A55', dark: PLUM,      inkLight: NAVY,  inkDark: CREAM, mutedLight: '#3B1A24', mutedDark: '#E0C8E8', use: 'First breath, beginnings' },
    apricot:    { light: '#FFC38A', dark: PLUM,      inkLight: NAVY,  inkDark: CREAM, mutedLight: '#4A2A1A', mutedDark: '#E0C8E8', use: 'Xero: days, pledge, Quit Day, welcome' },
    lilac:      { light: '#D9CCFF', dark: '#1C1640', inkLight: NAVY,  inkDark: CREAM, mutedLight: '#4A3E7A', mutedDark: '#C9BFF2', use: 'Talking with Xero (chat)' },
    mint:       { light: '#9FE3BC', dark: '#0F2A22', inkLight: NAVY,  inkDark: CREAM, mutedLight: '#24493A', mutedDark: '#A9D9C0', use: 'Your plan, Program' },
    ocean:      { light: '#2A52DB', dark: '#0B1A4A', inkLight: CREAM, inkDark: CREAM, mutedLight: '#E3EAFF', mutedDark: '#B9C9FF', use: 'Jelli: SOS, cravings' },
    sky:        { light: '#9CCBFF', dark: '#0F2550', inkLight: NAVY,  inkDark: CREAM, mutedLight: '#24406E', mutedDark: '#B9D6FF', use: 'Relief after a wave' },
    violet:     { light: '#4A3596', dark: '#140E3A', inkLight: CREAM, inkDark: CREAM, mutedLight: '#D2C8FF', mutedDark: '#B8B3D9', use: 'Glim: evenings, nights' },
    sun:        { light: '#FFD966', dark: PLUM,      inkLight: NAVY,  inkDark: CREAM, mutedLight: '#5A4A10', mutedDark: '#E0C8E8', use: 'Celebrations only' },
    reading:    { light: '#FBF7F1', dark: '#0E0B2B', inkLight: NAVY,  inkDark: CREAM, mutedLight: '#5E5975', mutedDark: '#B8B3D9', use: 'Lesson, progress, slip' },
    lime:       { light: '#C1F07A', dark: '#0F2A22', inkLight: NAVY,  inkDark: CREAM, mutedLight: '#33470F', mutedDark: '#A9D9C0', use: "What's changing" },
    mist:       { light: '#C9D6FF', dark: '#0B1A4A', inkLight: NAVY,  inkDark: CREAM, mutedLight: '#24406E', mutedDark: '#B9C9FF', use: 'Your patterns' },
    periwinkle: { light: '#B4C4FF', dark: '#140E3A', inkLight: NAVY,  inkDark: CREAM, mutedLight: '#24406E', mutedDark: '#B8B3D9', use: 'Calm tools' },
  };
  Lab.groundNames = Object.keys(Lab.grounds);
  Lab.NAVY = NAVY; Lab.CREAM = CREAM; Lab.PLUM = PLUM;

  /** A resolved ground for the current appearance: { name, bg, ink, muted, creamInk, card }. */
  Lab.ground = function (name, dark) {
    const s = Lab.grounds[name] || Lab.grounds.reading;
    const creamInk = s.inkLight === CREAM;
    return {
      name: name in Lab.grounds ? name : 'reading',
      bg: dark ? s.dark : s.light,
      ink: dark ? s.inkDark : s.inkLight,
      muted: dark ? s.mutedDark : s.mutedLight,
      creamInk,
      // DX.Fill.onColourCard(for:) — decision 25.
      card: dark ? 'rgba(255,255,255,0.10)' : creamInk ? 'rgba(30,26,58,0.20)' : 'rgba(255,248,238,0.70)',
    };
  };

  /** DX.Fill pairs [light, dark]. */
  Lab.fill = {
    surface: ['#F1EBE2', '#1B1747'],
    raised: ['#FFFFFF', '#2A255F'],
    cardOnColour: ['rgba(255,248,238,0.70)', 'rgba(255,255,255,0.10)'],
    green: ['#0F6E43', '#2FD08A'],
    oceanSecondary: ['#1D3A9E', '#1B2C66'],
    navy: [NAVY, NAVY],
    cream: [CREAM, CREAM],
  };
  Lab.c = (pair, dark) => (Array.isArray(pair) ? pair[dark ? 1 : 0] : pair);

  /** Named colours offered in colour dropdowns. */
  Lab.palette = [
    ['ink', 'Ground ink'], ['muted', 'Ground muted'], [NAVY, 'Navy'], [CREAM, 'Cream'], ['#FF7A55', 'Coral'],
    ['#FFC38A', 'Apricot'], ['#FFD966', 'Sun'], ['#9FE3BC', 'Mint'], ['#C1F07A', 'Lime'], ['#2A52DB', 'Ocean'],
    ['#4A3596', 'Violet'], ['#0F6E43', 'Green'], ['#2FD08A', 'Green (dark mode)'], ['#5E5975', 'Reading muted'], ['#FFFFFF', 'White'],
  ];

  /* ---------- Type (V4/TypeStep.swift) ---------- */
  Lab.type = {
    display:  { size: 40, family: 'display', weight: 800, tracking: -1.2, lh: 1.02 },
    large:    { size: 32, family: 'display', weight: 800, tracking: -1.0, lh: 1.08 },
    title:    { size: 24, family: 'display', weight: 800, tracking: -0.6, lh: 1.15 },
    headline: { size: 19, family: 'display', weight: 700, tracking: 0, lh: 1.2 },
    body:     { size: 16, family: 'body', weight: 400, tracking: 0, lh: 1.5 },
    footnote: { size: 14, family: 'body', weight: 500, tracking: 0, lh: 1.3 },
    caption:  { size: 12, family: 'body', weight: 700, tracking: 0.8, lh: 1.3 },
  };
  Lab.typeNames = Object.keys(Lab.type);
  Lab.FONT = { display: "'Bricolage Grotesque', 'DM Sans', system-ui, sans-serif", body: "'DM Sans', system-ui, sans-serif" };

  /** Inline CSS for a type step, or for an explicit size/weight (dxFont / Typeface4.swiftUIFont). */
  Lab.font = function (step, opts) {
    opts = opts || {};
    const t = Lab.type[step] || Lab.type.body;
    const size = opts.size || t.size;
    const weight = opts.weight || t.weight;
    const family = opts.family || (opts.size ? (size >= 19 && weight >= 700 ? 'display' : 'body') : t.family);
    const tracking = opts.tracking != null ? opts.tracking : opts.size ? 0 : t.tracking;
    const lh = opts.lh || (opts.size ? 1.2 : t.lh);
    return `font-family:${Lab.FONT[family]};font-size:${size}px;font-weight:${weight};letter-spacing:${tracking}px;line-height:${lh};`;
  };

  Lab.esc = (s) => String(s == null ? '' : s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

  /** A text block: Lab.text('headline', 'Hello', ctx, {tone:'muted', upper:true, align:'center', style:''}). */
  Lab.text = function (step, str, ctx, o) {
    o = o || {};
    const color = o.color ? Lab.colour(o.color, ctx) : o.tone === 'muted' ? ctx.g.muted : ctx.g.ink;
    const upper = o.upper || (step === 'caption' && o.upper !== false && o.caption !== 'mixed');
    return `<div style="${Lab.font(step, o)}color:${color};${o.align ? 'text-align:' + o.align + ';' : ''}${upper ? 'text-transform:uppercase;' : ''}${o.style || ''}">${Lab.esc(str)}</div>`;
  };

  /** Resolves a colour token ('ink', 'muted', 'green', a [light,dark] pair or a hex) for the context. */
  Lab.colour = function (v, ctx) {
    if (v === 'ink') return ctx.g.ink;
    if (v === 'muted') return ctx.g.muted;
    if (v === 'bg') return ctx.g.bg;
    if (v === 'card') return ctx.g.card;
    if (typeof v === 'string' && Lab.fill[v]) return Lab.c(Lab.fill[v], ctx.dark);
    return Lab.c(v, ctx.dark);
  };

  /* ---------- Icons (SF Symbols the app uses, drawn as simple SVG) ---------- */
  const ICONS = {
    'chevron.right': '<path d="M9 5l7 7-7 7" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>',
    'chevron.left': '<path d="M15 5l-7 7 7 7" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>',
    'chevron.down': '<path d="M5 9l7 7 7-7" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>',
    checkmark: '<path d="M5 12.5l4.5 4.5L19 7.5" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>',
    'play.fill': '<path d="M8 5.5v13a1 1 0 0 0 1.5.86l10.6-6.5a1 1 0 0 0 0-1.72L9.5 4.64A1 1 0 0 0 8 5.5z" fill="currentColor"/>',
    'lock.fill': '<rect x="5" y="10.5" width="14" height="10" rx="2.5" fill="currentColor"/><path d="M8 10.5V8a4 4 0 0 1 8 0v2.5" fill="none" stroke="currentColor" stroke-width="2.4"/>',
    'lock.open.fill': '<rect x="5" y="10.5" width="14" height="10" rx="2.5" fill="currentColor"/><path d="M8 10.5V8a4 4 0 0 1 7.6-1.7" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/>',
    'star.fill': '<path d="M12 3.5l2.6 5.4 5.9.8-4.3 4.1 1 5.9L12 16.9l-5.2 2.8 1-5.9-4.3-4.1 5.9-.8z" fill="currentColor"/>',
    xmark: '<path d="M6 6l12 12M18 6L6 18" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round"/>',
    plus: '<path d="M12 5v14M5 12h14" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round"/>',
    'gearshape.fill': '<circle cx="12" cy="12" r="3.2" fill="none" stroke="currentColor" stroke-width="2.4"/><path d="M12 2.8v3M12 18.2v3M2.8 12h3M18.2 12h3M5.5 5.5l2.1 2.1M16.4 16.4l2.1 2.1M5.5 18.5l2.1-2.1M16.4 7.6l2.1-2.1" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/>',
    'bell.fill': '<path d="M6 16V11a6 6 0 0 1 12 0v5l1.5 2h-15z" fill="currentColor"/><path d="M10 20a2 2 0 0 0 4 0" fill="currentColor"/>',
    'info.circle': '<circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="2"/><path d="M12 11v6M12 7.5v.5" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/>',
    'arrow.right': '<path d="M5 12h14M13 6l6 6-6 6" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>',
    'heart.fill': '<path d="M12 20s-7.5-4.6-7.5-10A4.3 4.3 0 0 1 12 7.4 4.3 4.3 0 0 1 19.5 10c0 5.4-7.5 10-7.5 10z" fill="currentColor"/>',
    'phone.fill': '<path d="M6.6 3.5l2.8.2 1.4 4-2 1.6a12 12 0 0 0 5.9 5.9l1.6-2 4 1.4.2 2.8a2 2 0 0 1-2.2 2A16.5 16.5 0 0 1 4.6 5.7a2 2 0 0 1 2-2.2z" fill="currentColor"/>',
    ellipsis: '<circle cx="6" cy="12" r="1.8" fill="currentColor"/><circle cx="12" cy="12" r="1.8" fill="currentColor"/><circle cx="18" cy="12" r="1.8" fill="currentColor"/>',
    'speaker.wave.2.fill': '<path d="M4 9.5h3.5L12 6v12l-4.5-3.5H4z" fill="currentColor"/><path d="M15 9a4 4 0 0 1 0 6M17.5 6.5a7.5 7.5 0 0 1 0 11" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>',
    'pause.fill': '<rect x="6.5" y="5" width="4" height="14" rx="1.2" fill="currentColor"/><rect x="13.5" y="5" width="4" height="14" rx="1.2" fill="currentColor"/>',
    'calendar': '<rect x="4" y="5.5" width="16" height="14.5" rx="3" fill="none" stroke="currentColor" stroke-width="2.2"/><path d="M4 10h16M8.5 3.5v4M15.5 3.5v4" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/>',
    'clock': '<circle cx="12" cy="12" r="8.5" fill="none" stroke="currentColor" stroke-width="2.2"/><path d="M12 7.5V12l3 2" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/>',
    'arrow.counterclockwise': '<path d="M5 12a7 7 0 1 0 2.1-5" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/><path d="M4.5 4v4.5H9" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"/>',
    'book.closed': '<path d="M6 4.5h11a1 1 0 0 1 1 1v14H7.5A1.5 1.5 0 0 1 6 18V4.5z" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linejoin="round"/><path d="M6 17.5A1.5 1.5 0 0 1 7.5 16H18" fill="none" stroke="currentColor" stroke-width="2.2"/>',
    waveform: '<path d="M4 10v4M8 7v10M12 4v16M16 8v8M20 10.5v3" stroke="currentColor" stroke-width="2.4" stroke-linecap="round"/>',
    'figure.stand': '<circle cx="12" cy="4.5" r="2.2" fill="currentColor"/><path d="M12 8v7M8 10.5l4-2 4 2M10 21l2-6 2 6" fill="none" stroke="currentColor" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round"/>',
    'sparkles': '<path d="M10 3l1.6 4.4L16 9l-4.4 1.6L10 15l-1.6-4.4L4 9l4.4-1.6zM17.5 13l.9 2.1 2.1.9-2.1.9-.9 2.1-.9-2.1-2.1-.9 2.1-.9z" fill="currentColor"/>',
  };
  Lab.iconNames = Object.keys(ICONS);
  Lab.icon = function (name, size, color, extra) {
    const body = ICONS[name] || ICONS['info.circle'];
    return `<svg viewBox="0 0 24 24" width="${size || 18}" height="${size || 18}" style="color:${color || 'currentColor'};flex:none;display:block;${extra || ''}" aria-hidden="true">${body}</svg>`;
  };

  /* ---------- Illustrations: one dropdown for every drawn thing (Art lives in art.js) ---------- */
  Lab.artOptions = function () {
    const A = window.Art || {};
    const groups = [];
    groups.push({ label: 'None', options: [['none', 'No illustration']] });
    if (A.kitKinds) groups.push({ label: 'Illustration kit', options: A.kitKinds.map((k) => ['kit:' + k, 'Kit · ' + k]) });
    if (A.personPoses) groups.push({ label: 'Person', options: A.personPoses.map((p) => ['person:' + p, 'Person · ' + p]) });
    if (A.characters) {
      const opts = [];
      A.characters.forEach((c) => {
        const moods = (A.moods && A.moods[c]) || [''];
        moods.forEach((m) => opts.push([c + ':' + m, cap(c) + (m ? ' · ' + m : '')]));
      });
      groups.push({ label: 'Characters', options: opts });
    }
    const scenes = [];
    if (A.horizon) {
      scenes.push(['scene:horizon', 'Horizon · dawn']);
      (A.horizonKinds || []).filter((k) => k !== 'dawn').forEach((k) => scenes.push(['scene:horizon:' + k, 'Horizon · ' + k]));
    }
    if (A.calmHeader) scenes.push(['scene:calmHeader', 'Calm tools header']);
    if (scenes.length) groups.push({ label: 'Scenes', options: scenes });
    (A.extras || []).filter((x) => x.name !== 'calmHeader').forEach((x) => {
      if (x.variants && x.variants.values) groups.push({ label: x.label, options: x.variants.values.map((v) => ['extra:' + x.name + ':' + v, x.label.replace(/ \(.*\)$/, '') + ' · ' + v]) });
      else groups.push({ label: x.label, options: [['extra:' + x.name, x.label]] });
    });
    return groups;
  };
  function cap(s) { return s.charAt(0).toUpperCase() + s.slice(1); }
  Lab.cap = cap;

  /** Renders an art value ('kit:dawn', 'person:walk', 'xero:hello', 'scene:horizon', 'none') at a size. */
  Lab.art = function (value, o) {
    o = o || {};
    const A = window.Art;
    const w = o.width || o.size || 64, h = o.height || o.size || w;
    if (!value || value === 'none') return '';
    const animate = o.animate != null ? o.animate : Lab.view.motion;
    const fallback = `<div style="width:${w}px;height:${h}px;border-radius:${o.radius != null ? o.radius : 12}px;background:repeating-linear-gradient(45deg,rgba(0,0,0,.08) 0 6px,transparent 6px 12px);"></div>`;
    if (!A) return fallback;
    const [kind, sub, variant] = String(value).split(':');
    try {
      if (kind === 'kit') return A.kit(sub, { width: w, height: h, radius: o.radius != null ? o.radius : 28, animate });
      if (kind === 'person') return A.person(sub, { height: h, shirt: o.shirt, skin: o.skin, animate });
      if (kind === 'scene' && sub === 'horizon') return A.horizon(Object.assign({ width: w, height: h, animate }, variant ? { kind: variant } : {}, o.scene || {}));
      if (kind === 'scene' && sub === 'calmHeader') return A.calmHeader({ width: w, height: h, animate });
      if (kind === 'extra') {
        const x = (A.extras || []).find((e) => e.name === sub);
        if (!x) return fallback;
        const opts = Object.assign({ width: w, height: h, size: Math.min(w, h), animate }, o.scene || {});
        if (variant && x.variants) opts[x.variants.key] = variant;
        return x.fn(opts);
      }
      if (A.characters && A.characters.includes(kind)) return A.character(kind, { size: Math.min(w, h), mood: sub || undefined, stage: o.stage, animate });
    } catch (e) { console.warn('art', value, e); }
    return fallback;
  };

  /* ---------- Registries ---------- */
  /** Registers an element type. See FORMAT.md. */
  Lab.element = function (def) {
    def.props = def.props || {};
    if (!def.props.visible) def.props.visible = { label: 'Show', kind: 'bool', default: true, order: 999 };
    Lab.elements[def.type] = def;
    return def;
  };
  /** Registers a screen. See FORMAT.md. */
  Lab.screen = function (def) {
    const i = Lab.screens.findIndex((s) => s.id === def.id);
    if (i >= 0) Lab.screens[i] = def; else Lab.screens.push(def);
    return def;
  };

  /** Node builder: h(type, id, props, kids). props.alts = { prop: [alternatives] } feeds the text dropdowns. */
  Lab.h = function (t, id, p, kids) {
    if (Array.isArray(p)) { kids = p; p = {}; }
    p = Object.assign({}, p || {});
    const alts = p.alts; delete p.alts;
    return { t, id, p, alts: alts || {}, kids: (kids || []).filter(Boolean) };
  };

  /* ---------- Changes (db-backed, localStorage fallback) ---------- */
  const keyFor = (scope, a, prop) => [scope, a, prop].map((s) => String(s).replace(/[^A-Za-z0-9_\-~:@+.]/g, '_')).join('~').replace(/^\.+/, '_');
  Lab.nodeKey = (screenId, nodeId, prop) => keyFor(screenId, nodeId, prop);
  Lab.libKey = (type, prop) => keyFor('lib', type, prop);

  /** Effective props for a node: element defaults < node props < library change < node change. */
  Lab.resolve = function (node, screenId) {
    const def = Lab.elements[node.t];
    const out = {};
    if (def) for (const k in def.props) if (def.props[k].default !== undefined) out[k] = def.props[k].default;
    Object.assign(out, node.p);
    if (def) for (const k in def.props) {
      const lib = Lab.changes[Lab.libKey(node.t, k)];
      if (lib && def.props[k].global) out[k] = lib.to;
    }
    for (const k in out) {
      const ch = Lab.changes[Lab.nodeKey(screenId, node.id, k)];
      if (ch) out[k] = ch.to;
    }
    if (def) for (const k in def.props) {
      if (out[k] === undefined) { const ch = Lab.changes[Lab.nodeKey(screenId, node.id, k)]; if (ch) out[k] = ch.to; }
    }
    return out;
  };

  /* ---------- Rendering ---------- */
  Lab.view = { device: 'i17pro', dark: false, motion: true, state: {}, screenId: null, selected: null, mode: 'screens', libSelected: null };

  function makeCtx(base) {
    const ctx = Object.assign({}, base);
    ctx.g = Lab.ground(ctx.groundName, ctx.dark);
    ctx.with = (patch) => makeCtx(Object.assign({}, ctx, patch));
    return ctx;
  }
  Lab.makeCtx = makeCtx;

  /** Renders a node tree to HTML. Each element's root tag gets data-node so it can be selected. */
  Lab.render = function (node, ctx) {
    if (!node) return '';
    if (Array.isArray(node)) return node.map((n) => Lab.render(n, ctx)).join('');
    const def = Lab.elements[node.t];
    if (!def) return `<div style="padding:8px;border:1px dashed red;color:red;font:12px monospace">Unknown element: ${Lab.esc(node.t)}</div>`;
    const p = Lab.resolve(node, ctx.screenId);
    if (p.visible === false) return '';
    ctx.index && ctx.index.push({ node, def, depth: ctx.depth || 0 });
    const kidCtx = (patch) => makeCtx(Object.assign({}, ctx, { depth: (ctx.depth || 0) + 1 }, patch || {}));
    const kids = (patch) => node.kids.map((k) => Lab.render(k, kidCtx(patch))).join('');
    let html;
    try { html = def.render(p, ctx, kids, node); } catch (e) {
      console.error('render', node.t, node.id, e);
      html = `<div style="padding:8px;border:1px dashed red;color:red;font:12px monospace">${Lab.esc(node.t)} failed: ${Lab.esc(e.message)}</div>`;
    }
    html = String(html).trim();
    const tag = ctx.inert ? '' : ` data-node="${Lab.esc(node.id)}" data-type="${Lab.esc(node.t)}"`;
    return html.replace(/^<([a-zA-Z][a-zA-Z0-9-]*)/, `<$1${tag}`);
  };

  /* ---------- Devices ---------- */
  // iPhone 17 Pro: 402 × 874 pt, 62 pt top inset, 34 pt bottom, Dynamic Island 125 × 37 at 11 pt.
  // iPhone 18 Pro: not confirmed by Apple at the time of writing; same grid with the leaked smaller island (13.49 mm ≈ 81 pt).
  Lab.devices = {
    i17pro: { label: 'iPhone 17 Pro · 402 × 874', w: 402, h: 874, top: 62, bottom: 34, radius: 62, island: [125, 37, 11] },
    i18pro: { label: 'iPhone 18 Pro · leaked island', w: 402, h: 874, top: 62, bottom: 34, radius: 62, island: [81, 37, 11] },
    i17promax: { label: 'iPhone 17 Pro Max · 440 × 956', w: 440, h: 956, top: 62, bottom: 34, radius: 62, island: [125, 37, 11] },
  };

  /* ---------- Screen-level settings ---------- */
  Lab.wallpapers = [
    ['flat', 'Flat colour (as in the app)'], ['glow', 'Soft glow at the top'], ['dots', 'Soft dots'],
    ['scene:horizon', 'Horizon scene'], ['kit:dawn', 'Kit · dawn'], ['kit:sea', 'Kit · sea'], ['kit:night', 'Kit · night'],
    ['kit:clouds', 'Kit · clouds'], ['kit:sprout', 'Kit · sprout'], ['kit:peak', 'Kit · peak'],
  ];
  Lab.SCREEN_PROPS = {
    ground: { label: 'Background colour', kind: 'ground' },
    wallpaper: { label: 'Wallpaper', kind: 'select', options: Lab.wallpapers, default: 'flat' },
  };
  Lab.screenSetting = function (screen, prop) {
    const ch = Lab.changes[Lab.nodeKey(screen.id, '_screen', prop)];
    if (ch) return ch.to;
    if (prop === 'ground') return screen.ground || 'reading';
    return Lab.SCREEN_PROPS[prop].default;
  };

  function wallpaperHTML(value, d, ctx) {
    if (!value || value === 'flat') return '';
    if (value === 'glow') return `<div class="wp" style="background:radial-gradient(120% 50% at 50% 0%, rgba(255,255,255,${ctx.dark ? 0.12 : 0.55}), transparent 70%)"></div>`;
    if (value === 'dots') return `<div class="wp" style="background-image:radial-gradient(${ctx.g.ink}22 1.4px, transparent 1.6px);background-size:22px 22px"></div>`;
    return `<div class="wp">${Lab.art(value, { width: d.w, height: d.h, radius: 0 })}</div>`;
  }

  /** Builds the screen's node tree for a state. */
  Lab.build = function (screen, stateId) {
    const state = (screen.states || []).find((s) => s.id === stateId) || (screen.states || [])[0] || { id: 'default' };
    const tree = screen.build(Lab.h, state, Lab);
    return { state, tree: Array.isArray(tree) ? tree : [tree] };
  };

  /** Full phone screen HTML for a screen (used by the editor and by tests). */
  Lab.renderScreen = function (screen, opts) {
    opts = opts || {};
    const d = Lab.devices[opts.device || Lab.view.device];
    const dark = opts.dark != null ? opts.dark : Lab.view.dark;
    const groundName = Lab.screenSetting(screen, 'ground');
    const ctx = makeCtx({ groundName, dark, screenId: screen.id, device: d, index: opts.index || null, depth: 0, width: d.w });
    const { state, tree } = Lab.build(screen, opts.state || Lab.view.state[screen.id]);
    ctx.state = state;
    const body = Lab.render(tree, ctx);
    const bar = screen.tab ? Lab.render(Lab.h('tabBar', '_tabbar', { selected: screen.tab }), ctx) : '';
    const wp = wallpaperHTML(Lab.screenSetting(screen, 'wallpaper'), d, ctx);
    const pad = `padding-top:${screen.fullBleed ? 0 : d.top}px;padding-bottom:${d.bottom + (screen.tab ? 96 : 12)}px;`;
    const overlay = screen.overlay ? Lab.render(screen.overlay(Lab.h, state, Lab), ctx) : '';
    return `<div class="scr" data-node="_screen" data-type="_screen" style="background:${ctx.g.bg};color:${ctx.g.ink};width:${d.w}px;height:${d.h}px">${wp}<div class="scroll"><div class="content" style="${pad}">${body}</div></div>${overlay}${bar}${statusBar(d, ctx, screen)}<div class="home-ind" style="background:${homeInk(screen, ctx)}"></div></div>`;
  };

  function homeInk(screen, ctx) {
    const v = typeof screen.homeInk === 'function' ? screen.homeInk(ctx.state || {}, ctx) : screen.homeInk || (typeof screen.statusInk === 'function' ? screen.statusInk(ctx.state || {}, ctx) : screen.statusInk);
    return v ? Lab.colour(v, ctx) : ctx.g.ink;
  }

  function statusBar(d, ctx, screen) {
    const pick = (v) => (typeof v === 'function' ? v(ctx.state || {}, ctx) : v);
    const si = pick(screen.statusInk);
    const ink = si ? Lab.colour(si, ctx) : ctx.g.ink;
    const [iw, ih, iy] = d.island;
    return `<div class="status" style="color:${ink}">
      <span class="time">9:41</span>
      <span class="island" style="width:${iw}px;height:${ih}px;top:${iy}px"></span>
      <span class="sys"><svg width="19" height="12" viewBox="0 0 19 12"><rect x="0" y="8" width="3.2" height="4" rx="1" fill="currentColor"/><rect x="5.2" y="5.5" width="3.2" height="6.5" rx="1" fill="currentColor"/><rect x="10.4" y="3" width="3.2" height="9" rx="1" fill="currentColor"/><rect x="15.6" y="0" width="3.2" height="12" rx="1" fill="currentColor"/></svg>
      <svg width="17" height="12" viewBox="0 0 17 12"><path d="M8.5 2.2c2.4 0 4.6.9 6.3 2.5l1.2-1.2A10.6 10.6 0 0 0 8.5.5 10.6 10.6 0 0 0 1 3.5l1.2 1.2a9 9 0 0 1 6.3-2.5zm0 3.4c1.5 0 2.9.6 3.9 1.5l1.2-1.2a7.3 7.3 0 0 0-10.2 0l1.2 1.2c1-1 2.4-1.5 3.9-1.5zm0 3.4c.6 0 1.2.2 1.6.6L8.5 11.2 6.9 9.6c.4-.4 1-.6 1.6-.6z" fill="currentColor"/></svg>
      <svg width="27" height="13" viewBox="0 0 27 13"><rect x=".5" y=".5" width="23" height="12" rx="3.8" fill="none" stroke="currentColor" opacity=".4"/><rect x="2" y="2" width="20" height="9" rx="2.5" fill="currentColor"/><path d="M25 4.5v4c.8-.3 1.3-1.1 1.3-2s-.5-1.7-1.3-2z" fill="currentColor" opacity=".45"/></svg></span>
    </div>`;
  }

  /* ---------- Storage ---------- */
  const store = { db: null, user: null, uid: null, mode: 'local', status: 'Connecting…' };
  Lab.store = store;
  const LS_KEY = 'dayxero-screen-lab-changes';
  function lsRead() { try { return JSON.parse(localStorage.getItem(LS_KEY) || '{}'); } catch (e) { return {}; } }
  function lsWrite() { try { localStorage.setItem(LS_KEY, JSON.stringify(Lab.changes)); } catch (e) { /* storage blocked */ } }

  Lab.connect = async function () {
    Lab.changes = lsRead();
    if (!window.claude || !window.claude.use) { store.status = 'Saved in this browser only'; Lab.ui && Lab.ui.refresh(); return; }
    let db = null, user = null;
    try { [db, user] = await Promise.all([window.claude.use('db'), window.claude.use('user')]); } catch (e) { db = null; }
    if (!db) { store.status = 'Saved in this browser only'; Lab.ui && Lab.ui.refresh(); return; }
    store.db = db; store.user = user; store.mode = 'db';
    try { store.uid = user ? await user.id() : null; } catch (e) { store.uid = null; }
    store.status = 'Loading saved changes…';
    Lab.ui && Lab.ui.refresh();
    const timer = setTimeout(() => { store.status = 'Saved changes are slow to load'; Lab.ui && Lab.ui.refresh(); }, 10000);
    db.collection('changes').onSnapshot((snap) => {
      clearTimeout(timer);
      const next = {};
      snap.docs.forEach((d) => { next[d.id] = Object.assign({ id: d.id }, d.data()); });
      Lab.changes = next;
      store.status = 'Changes are saved for Claude';
      Lab.ui && Lab.ui.refresh();
    }, (err) => { clearTimeout(timer); store.status = 'Could not load saved changes (' + err.code + ')'; Lab.ui && Lab.ui.refresh(); });
    db.collection('notes').onSnapshot((snap) => {
      Lab.notes = {};
      snap.docs.forEach((d) => { Lab.notes[d.id] = d.data(); });
      Lab.ui && Lab.ui.refreshNotes && Lab.ui.refreshNotes();
    }, () => {});
  };
  Lab.notes = {};

  /** Saves (or clears, when `to` equals the original) one change. */
  Lab.setChange = async function (key, meta, to) {
    const same = JSON.stringify(to) === JSON.stringify(meta.from);
    if (same) return Lab.clearChange(key);
    const doc = Object.assign({}, meta, { to, status: 'open', at: new Date().toISOString() });
    if (store.uid) doc.by = store.uid;
    Lab.changes[key] = Object.assign({ id: key }, doc);
    lsWrite();
    Lab.ui && Lab.ui.refresh();
    if (store.db) {
      try { await store.db.collection('changes').doc(key).set(doc); }
      catch (e) { Lab.ui && Lab.ui.toast('That change was not saved: ' + (e.code || e.message)); }
    }
  };
  Lab.clearChange = async function (key) {
    delete Lab.changes[key];
    lsWrite();
    Lab.ui && Lab.ui.refresh();
    if (store.db) { try { await store.db.collection('changes').doc(key).delete(); } catch (e) { Lab.ui && Lab.ui.toast('Could not undo that change: ' + (e.code || e.message)); } }
  };
  Lab.saveNote = async function (screenId, text) {
    Lab.notes[screenId] = { text, at: new Date().toISOString() };
    if (store.db) { try { await store.db.collection('notes').doc(keyFor('note', screenId, 'text')).set({ screen: screenId, text, at: new Date().toISOString() }); } catch (e) { Lab.ui && Lab.ui.toast('Note not saved: ' + (e.code || e.message)); } }
    else { try { localStorage.setItem('dayxero-screen-lab-note-' + screenId, text); } catch (e) { /* blocked */ } }
  };
  Lab.noteFor = function (screenId) {
    const n = Lab.notes[keyFor('note', screenId, 'text')] || Lab.notes[screenId];
    if (n) return n.text || '';
    try { return localStorage.getItem('dayxero-screen-lab-note-' + screenId) || ''; } catch (e) { return ''; }
  };
})();
