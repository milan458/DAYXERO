/* DayXero Screen Lab — editor UI: screen picker, phone stage, inspector dropdowns, element library, changes list. */
(function () {
  'use strict';
  const Lab = window.Lab;
  const $ = (sel, root) => (root || document).querySelector(sel);
  const esc = Lab.esc;
  const V = Lab.view;
  const ui = (Lab.ui = {});

  try { const s = JSON.parse(localStorage.getItem('dayxero-screen-lab-view') || '{}'); Object.assign(V, s, { selected: null }); } catch (e) { /* none */ }
  if (!Lab.devices[V.device]) V.device = 'i17pro';
  function saveView() { try { localStorage.setItem('dayxero-screen-lab-view', JSON.stringify({ device: V.device, dark: V.dark, motion: V.motion, state: V.state, screenId: V.screenId })); } catch (e) { /* blocked */ } }

  const reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  if (reduce && V.motion == null) V.motion = false;

  /* ---------- Routing (#s-<screen>, #library, #changes) ---------- */
  function readHash() {
    const h = (location.hash || '').slice(1);
    if (h === 'library') V.mode = 'library';
    else if (h === 'changes') V.mode = 'changes';
    else if (h.startsWith('s-')) { V.mode = 'screens'; const id = h.slice(2); if (Lab.screens.some((s) => s.id === id)) V.screenId = id; }
  }
  function writeHash() {
    const h = V.mode === 'screens' ? 's-' + V.screenId : V.mode;
    if (location.hash.slice(1) !== h) { try { history.replaceState(null, '', '#' + h); } catch (e) { location.hash = h; } }
  }

  /* ---------- Helpers ---------- */
  function currentScreen() { return Lab.screens.find((s) => s.id === V.screenId) || Lab.screens[0]; }
  function areas() {
    const map = new Map();
    Lab.screens.forEach((s) => { const a = s.area || 'Other'; if (!map.has(a)) map.set(a, []); map.get(a).push(s); });
    return map;
  }
  function changeCount(screenId) { return Object.values(Lab.changes).filter((c) => c.screen === screenId).length; }
  function optionHTML(opts, value) {
    return opts.map((o) => {
      const [v, l] = Array.isArray(o) ? o : [o, o];
      return `<option value="${esc(JSON.stringify(v))}"${JSON.stringify(v) === JSON.stringify(value) ? ' selected' : ''}>${esc(l)}</option>`;
    }).join('');
  }
  function groupedHTML(groups, value) {
    return groups.map((g) => `<optgroup label="${esc(g.label)}">${optionHTML(g.options, value)}</optgroup>`).join('');
  }

  /** Options for a prop, given the element def, the node and the original value. */
  function propOptions(def, key, node, original, current) {
    const pd = def.props[key];
    const kind = pd.kind;
    const ensure = (opts) => {
      const has = (v) => opts.some((o) => JSON.stringify(Array.isArray(o) ? o[0] : o) === JSON.stringify(v));
      if (current !== undefined && !has(current)) opts = opts.concat([[current, String(current)]]);
      return opts;
    };
    if (kind === 'text') {
      const list = [original].concat((node && node.alts && node.alts[key]) || [], pd.alts || []).filter((v, i, a) => v != null && a.indexOf(v) === i);
      const opts = list.map((v, i) => [v, (i === 0 ? 'App copy: ' : '') + (v === '' ? '(empty)' : v)]);
      if (current !== undefined && !list.includes(current)) opts.push([current, 'Your text: ' + current]);
      opts.push(['__custom__', 'Write your own…']);
      return { flat: opts };
    }
    if (kind === 'ground') return { flat: ensure(Lab.groundNames.map((g) => [g, Lab.cap(g) + ' · ' + Lab.grounds[g].use])) };
    if (kind === 'art') {
      const groups = Lab.artOptions();
      const all = groups.flatMap((g) => g.options.map((o) => o[0]));
      if (current && !all.includes(current)) groups.push({ label: 'Current', options: [[current, current]] });
      return { groups };
    }
    if (kind === 'kit') return { flat: ensure(((window.Art && window.Art.kitKinds) || []).map((k) => [k, k])) };
    if (kind === 'pose') return { flat: ensure(((window.Art && window.Art.personPoses) || []).map((k) => [k, k])) };
    if (kind === 'type') return { flat: ensure(Lab.typeNames.map((t) => [t, `${Lab.cap(t)} · ${Lab.type[t].size} pt`])) };
    if (kind === 'colour') return { flat: ensure(Lab.palette.slice()) };
    if (kind === 'icon') return { flat: ensure(Lab.iconNames.map((n) => [n, n])) };
    if (kind === 'bool') return { flat: [[true, (pd.labels || ['Show', 'Hide'])[0]], [false, (pd.labels || ['Show', 'Hide'])[1]]] };
    if (kind === 'number') return { flat: ensure((pd.options || []).map((n) => (Array.isArray(n) ? n : [n, String(n) + (pd.unit || '')]))) };
    return { flat: ensure((pd.options || []).slice()) };
  }

  /** Original value of a prop (without this node's change). */
  function originalValue(def, node, key) {
    if (node.p[key] !== undefined) return node.p[key];
    const lib = Lab.changes[Lab.libKey(node.t, key)];
    if (lib && def.props[key].global) return lib.to;
    return def.props[key].default;
  }

  /* ---------- Shell ---------- */
  function shell() {
    document.getElementById('app').innerHTML = `
      <header class="bar">
        <div class="brand"><span class="mark" aria-hidden="true"></span><span>DayXero Screen Lab</span></div>
        <nav class="modes" aria-label="Views">
          <button type="button" data-mode="screens">Screens</button>
          <button type="button" data-mode="library">Element library</button>
          <button type="button" data-mode="changes">Changes <span class="count" id="chg-count"></span></button>
        </nav>
        <div class="viewopts">
          <label class="mini"><span>Phone</span><select id="opt-device">${Object.entries(Lab.devices).map(([k, d]) => `<option value="${k}">${esc(d.label)}</option>`).join('')}</select></label>
          <label class="mini"><span>Appearance</span><select id="opt-dark"><option value="0">Light</option><option value="1">Dark</option></select></label>
          <label class="mini"><span>Motion</span><select id="opt-motion"><option value="1">On</option><option value="0">Reduce Motion</option></select></label>
        </div>
      </header>
      <main class="work">
        <aside class="left" id="left"></aside>
        <section class="stage" id="stage" aria-label="Phone preview"></section>
        <aside class="right" id="right"></aside>
      </main>
      <div class="toast" id="toast" role="status" aria-live="polite" hidden></div>`;
    document.querySelectorAll('.modes button').forEach((b) => b.addEventListener('click', () => { V.mode = b.dataset.mode; V.selected = null; V.libSelected = null; writeHash(); ui.refresh(); }));
    const dev = $('#opt-device'), dark = $('#opt-dark'), motion = $('#opt-motion');
    dev.value = V.device; dark.value = V.dark ? '1' : '0'; motion.value = V.motion === false ? '0' : '1';
    dev.addEventListener('change', () => { V.device = dev.value; saveView(); ui.refresh(); });
    dark.addEventListener('change', () => { V.dark = dark.value === '1'; saveView(); ui.refresh(); });
    motion.addEventListener('change', () => { V.motion = motion.value === '1'; saveView(); ui.refresh(); });
    window.addEventListener('resize', fitPhone);
    window.addEventListener('hashchange', () => { readHash(); ui.refresh(); });
  }

  ui.toast = function (msg) {
    const t = $('#toast'); if (!t) return;
    t.textContent = msg; t.hidden = false;
    clearTimeout(ui._tt); ui._tt = setTimeout(() => { t.hidden = true; }, 3200);
  };

  /* ---------- Left: screen picker ---------- */
  function renderLeft() {
    const left = $('#left');
    if (V.mode === 'library') {
      const groups = new Map();
      Object.values(Lab.elements).forEach((e) => { if (e.hidden) return; const g = e.group || 'Other'; if (!groups.has(g)) groups.set(g, []); groups.get(g).push(e); });
      left.innerHTML = `<label class="field"><span>Element</span><select id="lib-pick"><option value="">All elements</option>${[...groups].map(([g, list]) => `<optgroup label="${esc(g)}">${list.map((e) => `<option value="${e.type}"${V.libSelected === e.type ? ' selected' : ''}>${esc(e.name)}</option>`).join('')}</optgroup>`).join('')}</select></label>
        <div class="list">${[...groups].map(([g, list]) => `<div class="grp">${esc(g)}</div>${list.map((e) => `<button type="button" class="item${V.libSelected === e.type ? ' on' : ''}" data-el="${e.type}">${esc(e.name)}</button>`).join('')}`).join('')}</div>`;
      $('#lib-pick').addEventListener('change', (ev) => { V.libSelected = ev.target.value || null; ui.refresh(); scrollLibTo(V.libSelected); });
      left.querySelectorAll('[data-el]').forEach((b) => b.addEventListener('click', () => { V.libSelected = b.dataset.el; ui.refresh(); scrollLibTo(V.libSelected); }));
      return;
    }
    const s = currentScreen();
    const map = areas();
    const states = (s && s.states) || [];
    left.innerHTML = `
      <label class="field"><span>Screen</span><select id="pick-screen">${[...map].map(([a, list]) => `<optgroup label="${esc(a)}">${list.map((x) => `<option value="${x.id}"${x.id === (s && s.id) ? ' selected' : ''}>${esc(x.name)}</option>`).join('')}</optgroup>`).join('')}</select></label>
      ${states.length > 1 ? `<label class="field"><span>Sam's day</span><select id="pick-state">${states.map((st) => `<option value="${st.id}"${st.id === (V.state[s.id] || states[0].id) ? ' selected' : ''}>${esc(st.label)}</option>`).join('')}</select></label>` : ''}
      <div class="list">${[...map].map(([a, list]) => `<div class="grp">${esc(a)}</div>${list.map((x) => { const n = changeCount(x.id); return `<button type="button" class="item${x.id === (s && s.id) ? ' on' : ''}" data-screen="${x.id}"><span>${esc(x.name)}</span>${n ? `<span class="dot" title="${n} change${n > 1 ? 's' : ''}">${n}</span>` : ''}</button>`; }).join('')}`).join('')}</div>`;
    $('#pick-screen').addEventListener('change', (e) => pickScreen(e.target.value));
    const ps = $('#pick-state');
    if (ps) ps.addEventListener('change', (e) => { V.state[s.id] = e.target.value; V.selected = null; saveView(); ui.refresh(); });
    left.querySelectorAll('[data-screen]').forEach((b) => b.addEventListener('click', () => pickScreen(b.dataset.screen)));
  }
  function pickScreen(id) { V.screenId = id; V.selected = null; V.mode = 'screens'; saveView(); writeHash(); ui.refresh(); const st = $('#stage'); st && st.scrollTo && st.scrollTo(0, 0); }

  /* ---------- Stage: the phone ---------- */
  let lastIndex = [];
  function renderStage() {
    const stage = $('#stage');
    if (V.mode === 'library') return renderLibrary(stage);
    if (V.mode === 'changes') return renderChanges(stage);
    const s = currentScreen();
    if (!s) { stage.innerHTML = '<p class="empty">No screens are registered yet.</p>'; return; }
    const prevScroll = stage.querySelector('.scroll');
    const keep = prevScroll && stage.dataset.screen === s.id ? prevScroll.scrollTop : 0;
    const d = Lab.devices[V.device];
    lastIndex = [];
    let html;
    try { html = Lab.renderScreen(s, { index: lastIndex }); } catch (e) { console.error(e); html = `<p class="empty">This screen failed to draw: ${esc(e.message)}</p>`; }
    stage.dataset.screen = s.id;
    stage.innerHTML = `<div class="phone-wrap"><div class="phone" style="--w:${d.w}px;--h:${d.h}px;--r:${d.radius}px">
        <span class="btn b1"></span><span class="btn b2"></span><span class="btn b3"></span><span class="btn b4"></span>
        <div class="glass">${html}</div></div></div>
      <p class="stage-note">${esc(s.name)} · ${esc(((s.states || []).find((x) => x.id === V.state[s.id]) || (s.states || [])[0] || { label: '' }).label)} · from <code>${esc(s.source || '')}</code></p>`;
    const sc = stage.querySelector('.scroll'); if (sc) sc.scrollTop = keep;
    markSelected();
    fitPhone();
    const glass = stage.querySelector('.glass');
    glass.addEventListener('click', (e) => {
      const n = e.target.closest('[data-node]');
      e.preventDefault(); e.stopPropagation();
      if (!n) return;
      V.selected = n.dataset.node === '_screen' ? null : n.dataset.node;
      markSelected(); renderRight();
    }, true);
    glass.addEventListener('mouseover', (e) => {
      glass.querySelectorAll('.hov').forEach((x) => x.classList.remove('hov'));
      const n = e.target.closest('[data-node]'); if (n && n.dataset.node !== '_screen') n.classList.add('hov');
    });
    glass.addEventListener('mouseleave', () => glass.querySelectorAll('.hov').forEach((x) => x.classList.remove('hov')));
  }
  function markSelected() {
    const stage = $('#stage');
    stage.querySelectorAll('.sel').forEach((x) => x.classList.remove('sel'));
    if (!V.selected) return;
    const el = stage.querySelector(`[data-node="${CSS.escape(V.selected)}"]`);
    if (el) el.classList.add('sel');
  }
  function fitPhone() {
    const wrap = document.querySelector('.phone-wrap'); if (!wrap) return;
    const phone = wrap.querySelector('.phone');
    const d = Lab.devices[V.device];
    const W = d.w + 24, H = d.h + 24;
    const stage = $('#stage');
    const narrow = window.innerWidth < 900;
    const availW = stage.clientWidth - 24;
    const availH = narrow ? Infinity : window.innerHeight - stage.getBoundingClientRect().top - 56;
    const k = Math.max(0.4, Math.min(1, availW / W, availH / H));
    phone.style.transform = `scale(${k})`;
    wrap.style.width = W * k + 'px'; wrap.style.height = H * k + 'px';
  }

  /* ---------- Right: inspector ---------- */
  function renderRight() {
    const right = $('#right');
    if (V.mode === 'library') return renderLibInspector(right);
    if (V.mode === 'changes') { right.innerHTML = changesHelp(); return; }
    const s = currentScreen(); if (!s) { right.innerHTML = ''; return; }
    const entry = V.selected && lastIndex.find((x) => x.node.id === V.selected);
    let top;
    if (entry) top = elementPanel(s, entry);
    else top = screenPanel(s);
    right.innerHTML = top + treePanel(s);
    wireControls(right, s);
  }

  function screenPanel(s) {
    const props = Lab.SCREEN_PROPS;
    const rows = Object.keys(props).map((k) => {
      const pd = props[k];
      const value = Lab.screenSetting(s, k);
      const original = k === 'ground' ? s.ground || 'reading' : pd.default;
      const fake = { props: { [k]: pd } };
      const { flat } = propOptions(fake, k, null, original, value);
      const changed = !!Lab.changes[Lab.nodeKey(s.id, '_screen', k)];
      return control({ key: k, label: pd.label, flat, value, changed, data: `data-screen-prop="${k}"` });
    }).join('');
    return `<section class="panel">
      <div class="eyebrow">Screen</div>
      <h2>${esc(s.name)}</h2>
      ${s.note ? `<p class="hint">${esc(s.note)}</p>` : ''}
      ${rows}
      <label class="field"><span>Note for Claude</span><textarea id="note" rows="3" placeholder="Anything the dropdowns can't say, e.g. 'make this feel calmer'">${esc(Lab.noteFor(s.id))}</textarea></label>
      <p class="hint">Tap anything on the phone to change it. ${esc(Lab.store.status)}.</p>
    </section>`;
  }

  function elementPanel(s, entry) {
    const { node, def } = entry;
    const keys = Object.keys(def.props).sort((a, b) => (def.props[a].order || 0) - (def.props[b].order || 0));
    const p = Lab.resolve(node, s.id);
    const rows = keys.map((k) => {
      const pd = def.props[k];
      if (pd.when && !pd.when(p)) return '';
      const original = originalValue(def, node, k);
      const value = p[k];
      const { flat, groups } = propOptions(def, k, node, original, value);
      const changed = !!Lab.changes[Lab.nodeKey(s.id, node.id, k)];
      return control({ key: k, label: pd.label, flat, groups, value, changed, data: `data-prop="${k}"`, hint: pd.hint });
    }).join('');
    const parent = findParent(s, node.id);
    const any = keys.some((k) => Lab.changes[Lab.nodeKey(s.id, node.id, k)]);
    return `<section class="panel">
      <div class="eyebrow">${esc(def.group || 'Element')}</div>
      <h2>${esc(def.name)}</h2>
      <p class="hint">${def.description ? esc(def.description) + ' ' : ''}<button type="button" class="link" data-goto-lib="${def.type}">See it in the library</button></p>
      ${rows}
      <div class="actions">
        ${parent ? `<button type="button" class="ghost" data-select="${esc(parent.id)}">Select the box around it</button>` : ''}
        <button type="button" class="ghost" data-select="">Back to screen settings</button>
        ${any ? `<button type="button" class="ghost warn" data-reset-node="${esc(node.id)}">Undo all changes here</button>` : ''}
      </div>
      <p class="src">Code: <code>${esc(def.source || s.source || '')}</code> · id <code>${esc(node.id)}</code></p>
    </section>`;
  }

  function control({ label, flat, groups, value, changed, data, hint }) {
    const isCustom = value === '__custom__';
    return `<label class="field${changed ? ' changed' : ''}"><span>${esc(label)}${changed ? ' <em>changed</em>' : ''}</span>
      <select ${data}>${groups ? groupedHTML(groups, value) : optionHTML(flat, value)}</select>
      ${hint ? `<small>${esc(hint)}</small>` : ''}${isCustom ? '' : ''}</label>`;
  }

  function treePanel(s) {
    if (!lastIndex.length) return '';
    return `<section class="panel tree"><div class="eyebrow">Everything on this screen</div><ol>${lastIndex.map(({ node, def, depth }) => {
      const p = Lab.resolve(node, s.id);
      const peek = p.text || p.title || p.label || p.word || p.kicker || p.art || '';
      return `<li style="--d:${depth}"><button type="button" class="${V.selected === node.id ? 'on' : ''}" data-select="${esc(node.id)}"><b>${esc(def.name)}</b>${peek ? ` <span>${esc(String(peek).slice(0, 34))}</span>` : ''}</button></li>`;
    }).join('')}</ol></section>`;
  }

  function findParent(s, id) {
    const { tree } = Lab.build(s, V.state[s.id]);
    let found = null;
    (function walk(list, parent) { list.forEach((n) => { if (!n) return; if (n.id === id) found = parent; else walk(n.kids || [], n); }); })(tree, null);
    return found;
  }
  function findNode(s, id) { const e = lastIndex.find((x) => x.node.id === id); return e && e.node; }

  function wireControls(root, s) {
    root.querySelectorAll('select[data-prop]').forEach((sel) => sel.addEventListener('change', () => {
      const node = findNode(s, V.selected); if (!node) return;
      const def = Lab.elements[node.t];
      const k = sel.dataset.prop;
      let to = JSON.parse(sel.value);
      const meta = { scope: 'node', screen: s.id, screenName: s.name, node: node.id, element: node.t, elementName: def.name, prop: k, label: def.props[k].label, from: originalValue(def, node, k) };
      if (to === '__custom__') return askText(sel, (text) => Lab.setChange(Lab.nodeKey(s.id, node.id, k), meta, text));
      Lab.setChange(Lab.nodeKey(s.id, node.id, k), meta, to);
    }));
    root.querySelectorAll('select[data-screen-prop]').forEach((sel) => sel.addEventListener('change', () => {
      const k = sel.dataset.screenProp;
      const to = JSON.parse(sel.value);
      const from = k === 'ground' ? s.ground || 'reading' : Lab.SCREEN_PROPS[k].default;
      Lab.setChange(Lab.nodeKey(s.id, '_screen', k), { scope: 'screen', screen: s.id, screenName: s.name, node: '_screen', element: 'screen', elementName: 'Screen', prop: k, label: Lab.SCREEN_PROPS[k].label, from }, to);
    }));
    root.querySelectorAll('[data-select]').forEach((b) => b.addEventListener('click', () => { V.selected = b.dataset.select || null; markSelected(); renderRight(); scrollToSelected(); }));
    root.querySelectorAll('[data-reset-node]').forEach((b) => b.addEventListener('click', () => {
      Object.keys(Lab.changes).forEach((k) => { const c = Lab.changes[k]; if (c.screen === s.id && c.node === b.dataset.resetNode) Lab.clearChange(k); });
    }));
    root.querySelectorAll('[data-goto-lib]').forEach((b) => b.addEventListener('click', () => { V.mode = 'library'; V.libSelected = b.dataset.gotoLib; writeHash(); ui.refresh(); scrollLibTo(V.libSelected); }));
    const note = $('#note', root);
    if (note) note.addEventListener('change', () => { Lab.saveNote(s.id, note.value); ui.toast('Note saved'); });
  }

  /** Inline text entry for "Write your own…" (the viewer blocks prompt()). */
  function askText(sel, done) {
    const field = sel.closest('.field');
    if (field.querySelector('.own')) return;
    const box = document.createElement('div');
    box.className = 'own';
    box.innerHTML = `<input type="text" id="own-text" aria-label="Your text"><div class="actions"><button type="button" class="solid">Use this text</button><button type="button" class="ghost">Cancel</button></div>`;
    field.appendChild(box);
    const input = box.querySelector('input'); input.focus();
    const [ok, cancel] = box.querySelectorAll('button');
    ok.addEventListener('click', () => { const v = input.value.trim(); if (v) done(v); });
    input.addEventListener('keydown', (e) => { if (e.key === 'Enter') { e.preventDefault(); ok.click(); } });
    cancel.addEventListener('click', () => renderRight());
  }

  function scrollToSelected() {
    const el = document.querySelector('#stage .sel');
    if (el && el.scrollIntoView) el.scrollIntoView({ block: 'center', behavior: 'smooth' });
  }

  /* ---------- Element library ---------- */
  function usage() {
    if (ui._usage && ui._usageFor === Lab.screens.length) return ui._usage;
    const map = {};
    Lab.screens.forEach((s) => (s.states && s.states.length ? s.states : [{ id: undefined }]).forEach((st) => {
      let tree; try { tree = Lab.build(s, st.id).tree; } catch (e) { return; }
      (function walk(list) { list.forEach((n) => { if (!n) return; (map[n.t] = map[n.t] || new Set()).add(s.id); walk(n.kids || []); }); })(tree);
    }));
    ui._usage = map; ui._usageFor = Lab.screens.length;
    return map;
  }
  function renderLibrary(stage) {
    const u = usage();
    const groups = new Map();
    Object.values(Lab.elements).forEach((e) => { if (e.hidden) return; const g = e.group || 'Other'; if (!groups.has(g)) groups.set(g, []); groups.get(g).push(e); });
    stage.innerHTML = `<div class="library">${[...groups].map(([g, list]) => `<h2 class="lib-group">${esc(g)}</h2>${list.map((e) => libCard(e, u)).join('')}`).join('')}</div>`;
    stage.querySelectorAll('[data-libcard]').forEach((c) => c.addEventListener('click', () => { V.libSelected = c.dataset.libcard; renderLeft(); renderRight(); stage.querySelectorAll('.libcard').forEach((x) => x.classList.toggle('on', x.dataset.libcard === V.libSelected)); }));
  }
  function libCard(e, u) {
    const examples = (e.examples && e.examples.length ? e.examples : [{ label: 'Default', props: {} }]);
    const used = [...(u[e.type] || [])].map((id) => (Lab.screens.find((s) => s.id === id) || {}).name).filter(Boolean);
    return `<article class="libcard${V.libSelected === e.type ? ' on' : ''}" id="lib-${e.type}" data-libcard="${e.type}">
      <header><h3>${esc(e.name)}</h3><code>${esc(e.type)}</code></header>
      ${e.description ? `<p>${esc(e.description)}</p>` : ''}
      <div class="examples">${examples.map((x, i) => {
        const ground = x.ground || 'reading';
        const ctx = Lab.makeCtx({ groundName: ground, dark: V.dark, screenId: '_lib', inert: true, width: x.width || 362 });
        let html = '';
        try { html = Lab.render(Lab.h(e.type, '_ex' + i, x.props || {}, (x.kids || []).map((k, j) => Lab.h(k[0], '_k' + j, k[1] || {}))), ctx); } catch (err) { html = esc(err.message); }
        const g = ctx.g;
        return `<figure><div class="ex" style="background:${g.bg};color:${g.ink};width:${(x.width || 362) + 32}px">${html}</div><figcaption>${esc(x.label || '')}${x.ground ? ' · on ' + esc(x.ground) : ''}</figcaption></figure>`;
      }).join('')}</div>
      <footer><span>Code: <code>${esc(e.source || '')}</code></span><span>${used.length ? 'Used on: ' + esc(used.join(', ')) : 'Not on any screen in the lab yet'}</span></footer>
    </article>`;
  }
  function scrollLibTo(type) { if (!type) return; setTimeout(() => { const el = document.getElementById('lib-' + type); if (el) el.scrollIntoView({ block: 'start', behavior: 'smooth' }); }, 30); }

  function renderLibInspector(right) {
    const e = V.libSelected && Lab.elements[V.libSelected];
    if (!e) { right.innerHTML = `<section class="panel"><div class="eyebrow">Element library</div><h2>Every building block</h2><p class="hint">Each element here is drawn by the same code as the screens, so a change you make here shows on every screen that uses it. Pick an element to see what can change across the whole app.</p></section>`; return; }
    const globals = Object.keys(e.props).filter((k) => e.props[k].global);
    const rows = globals.map((k) => {
      const pd = e.props[k];
      const original = pd.default;
      const ch = Lab.changes[Lab.libKey(e.type, k)];
      const value = ch ? ch.to : original;
      const { flat, groups } = propOptions(e, k, null, original, value);
      return control({ key: k, label: pd.label, flat, groups, value, changed: !!ch, data: `data-libprop="${k}"`, hint: pd.hint });
    }).join('');
    right.innerHTML = `<section class="panel"><div class="eyebrow">${esc(e.group || 'Element')}</div><h2>${esc(e.name)}</h2>
      ${e.description ? `<p class="hint">${esc(e.description)}</p>` : ''}
      ${rows ? `<p class="hint">These change it everywhere in the app:</p>${rows}` : '<p class="hint">This element has no app-wide settings. Change its words, colours or art on each screen where it appears.</p>'}
      <p class="src">Code: <code>${esc(e.source || '')}</code></p></section>`;
    right.querySelectorAll('select[data-libprop]').forEach((sel) => sel.addEventListener('change', () => {
      const k = sel.dataset.libprop; const to = JSON.parse(sel.value);
      Lab.setChange(Lab.libKey(e.type, k), { scope: 'library', screen: '_library', screenName: 'Element library', node: e.type, element: e.type, elementName: e.name, prop: k, label: e.props[k].label, from: e.props[k].default }, to);
    }));
  }

  /* ---------- Changes ---------- */
  function fmt(v) { if (v === true) return 'Show'; if (v === false) return 'Hide'; if (v == null || v === '') return '(none)'; return String(v); }
  function renderChanges(stage) {
    const list = Object.values(Lab.changes).sort((a, b) => String(a.screenName).localeCompare(String(b.screenName)) || String(a.at).localeCompare(String(b.at)));
    const by = new Map();
    list.forEach((c) => { const k = c.screenName || c.screen; if (!by.has(k)) by.set(k, []); by.get(k).push(c); });
    const open = list.filter((c) => c.status !== 'built').length;
    stage.innerHTML = `<div class="changes">
      <header class="ch-head"><div><h2>Your changes</h2><p>${list.length ? `${open} waiting for Claude, ${list.length - open} built into the app.` : 'Nothing changed yet. Pick a screen, tap something on the phone and choose a new option.'}</p></div>
        ${list.length ? '<button type="button" class="solid" id="copy-changes">Copy as text</button>' : ''}</header>
      ${[...by].map(([name, items]) => `<section><h3>${esc(name)}</h3><table><thead><tr><th>Element</th><th>What</th><th>Was</th><th>Now</th><th>Status</th><th></th></tr></thead><tbody>${items.map((c) => `<tr>
        <td>${esc(c.elementName || c.element)}</td><td>${esc(c.label || c.prop)}</td><td class="was">${esc(fmt(c.from))}</td><td class="now">${esc(fmt(c.to))}</td>
        <td><span class="chip ${c.status === 'built' ? 'built' : 'open'}">${c.status === 'built' ? 'Built' : 'Waiting for Claude'}</span></td>
        <td><button type="button" class="ghost" data-undo="${esc(c.id)}">Undo</button> ${c.screen && c.screen !== '_library' ? `<button type="button" class="ghost" data-open="${esc(c.screen)}" data-node-id="${esc(c.node)}">Show</button>` : ''}</td></tr>`).join('')}</tbody></table></section>`).join('')}
      ${Object.keys(Lab.notes).length ? `<section><h3>Notes</h3>${Object.values(Lab.notes).filter((n) => n.text).map((n) => `<p class="note"><b>${esc((Lab.screens.find((s) => s.id === n.screen) || {}).name || n.screen || '')}</b> ${esc(n.text)}</p>`).join('')}</section>` : ''}
    </div>`;
    stage.querySelectorAll('[data-undo]').forEach((b) => b.addEventListener('click', () => Lab.clearChange(b.dataset.undo)));
    stage.querySelectorAll('[data-open]').forEach((b) => b.addEventListener('click', () => { pickScreen(b.dataset.open); V.selected = b.dataset.nodeId === '_screen' ? null : b.dataset.nodeId; ui.refresh(); scrollToSelected(); }));
    const copy = $('#copy-changes');
    if (copy) copy.addEventListener('click', () => {
      const text = list.map((c) => `${c.screenName} › ${c.elementName} (${c.node}) › ${c.label}: "${fmt(c.from)}" → "${fmt(c.to)}"`).join('\n');
      const done = () => ui.toast('Copied ' + list.length + ' changes');
      try { navigator.clipboard.writeText(text).then(done, () => fallbackCopy(text)); } catch (e) { fallbackCopy(text); }
    });
  }
  function fallbackCopy(text) {
    const ta = document.createElement('textarea'); ta.value = text; ta.style.position = 'fixed'; ta.style.opacity = '0';
    document.body.appendChild(ta); ta.select();
    try { document.execCommand('copy'); ui.toast('Copied'); } catch (e) { ui.toast('Select the text and copy it'); }
    ta.remove();
  }
  function changesHelp() {
    return `<section class="panel"><div class="eyebrow">How this works</div><h2>From here to the app</h2>
      <p class="hint">Every change you make is saved with this page. When you're ready, tell Claude "build my Screen Lab changes". Claude reads this list, changes the Swift code, opens a pull request and marks each change Built.</p>
      <p class="hint">${esc(Lab.store.status)}.</p></section>`;
  }

  /* ---------- Refresh ---------- */
  ui.refresh = function () {
    if (!document.getElementById('left')) return;
    document.querySelectorAll('.modes button').forEach((b) => b.setAttribute('aria-pressed', String(b.dataset.mode === V.mode)));
    const n = Object.values(Lab.changes).filter((c) => c.status !== 'built').length;
    const cc = $('#chg-count'); if (cc) cc.textContent = n ? String(n) : '';
    document.body.dataset.mode = V.mode;
    document.body.classList.toggle('still', V.motion === false);
    if (V.mode === 'library') ui._usage = null;
    renderLeft(); renderStage(); renderRight();
  };
  ui.refreshNotes = function () { if (V.mode === 'changes') renderStage(); };

  Lab.start = function () {
    shell();
    if (!V.screenId || !Lab.screens.some((s) => s.id === V.screenId)) V.screenId = (Lab.screens[0] || {}).id;
    readHash();
    writeHash();
    ui.refresh();
    Lab.connect();
  };
})();
