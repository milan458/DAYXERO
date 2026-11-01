#!/usr/bin/env node
/* Renders every Screen Lab screen in every state, light and dark, and every library example.
   Fails on render errors, unknown elements, duplicate node ids and unbalanced tags. Usage: node tools/screen-lab/check.js [screen-file …] */
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const dir = __dirname;
const sandbox = { console, window: {}, localStorage: { getItem: () => null, setItem() {} }, setTimeout, clearTimeout };
sandbox.window = sandbox;
vm.createContext(sandbox);
const load = (f) => { const p = path.join(dir, f); if (fs.existsSync(p)) vm.runInContext(fs.readFileSync(p, 'utf8'), sandbox, { filename: f }); else console.warn('missing ' + f); };
['lab.js', 'art.js', 'elements.js', 'screens/manifest.js'].forEach(load);
const only = process.argv.slice(2);
(sandbox.LabScreens || []).forEach((n) => load(`screens/${n}.js`));

const Lab = sandbox.Lab;
let failures = 0;
const fail = (msg) => { failures++; console.log('FAIL ' + msg); };
const VOID = new Set(['area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link', 'meta', 'source', 'track', 'wbr']);
function balanced(html) {
  const stack = [];
  const re = /<\/?([a-zA-Z][a-zA-Z0-9-]*)\b[^>]*?(\/?)>/g;
  let m;
  while ((m = re.exec(html))) {
    const [all, tag, self] = m; const t = tag.toLowerCase();
    if (all.startsWith('</')) { const top = stack.pop(); if (top !== t) return `</${t}> closes <${top}> near …${html.slice(Math.max(0, m.index - 80), m.index + 20)}`; }
    else if (!self && !VOID.has(t)) stack.push(t);
  }
  return stack.length ? 'unclosed: ' + stack.slice(-3).join(', ') : null;
}

const screens = Lab.screens.filter((s) => !only.length || only.some((o) => s.source && s.id.startsWith(o)) || only.includes(s.id));
let rendered = 0;
for (const s of screens) {
  const states = s.states && s.states.length ? s.states : [{ id: undefined, label: 'default' }];
  for (const st of states) {
    for (const dark of [false, true]) {
      let html;
      const index = [];
      try { html = Lab.renderScreen(s, { state: st.id, dark, device: 'i17pro', index }); } catch (e) { fail(`${s.id} [${st.label}] threw: ${e.stack}`); continue; }
      rendered++;
      if (/Unknown element:/.test(html)) fail(`${s.id} [${st.label}] has an unknown element: ${(html.match(/Unknown element: [^<]*/) || [])[0]}`);
      if (/ failed: /.test(html)) fail(`${s.id} [${st.label}] element failed: ${(html.match(/[a-zA-Z]+ failed: [^<]*/) || [])[0]}`);
      if (/undefined|NaN|\[object Object\]/.test(html.replace(/<[^>]*>/g, ''))) fail(`${s.id} [${st.label}${dark ? ', dark' : ''}] shows "undefined", "NaN" or "[object Object]" as text`);
      const b = balanced(html); if (b) fail(`${s.id} [${st.label}] tags: ${b}`);
      const seen = new Map();
      for (const { node } of index) { if (seen.has(node.id)) fail(`${s.id} [${st.label}] duplicate node id "${node.id}" (${node.t} and ${seen.get(node.id)})`); seen.set(node.id, node.t); }
    }
  }
}
for (const e of Object.values(Lab.elements)) {
  for (const [i, x] of (e.examples || [{ props: {} }]).entries()) {
    try {
      const ctx = Lab.makeCtx({ groundName: x.ground || 'reading', dark: false, screenId: '_lib', inert: true, width: 362 });
      const html = Lab.render(Lab.h(e.type, '_ex' + i, x.props || {}, (x.kids || []).map((k, j) => Lab.h(k[0], '_k' + j, k[1] || {}))), ctx);
      if (/ failed: /.test(html)) fail(`library ${e.type} example ${i} failed`);
      const b = balanced(html); if (b) fail(`library ${e.type} example ${i} tags: ${b}`);
    } catch (err) { fail(`library ${e.type} example ${i} threw: ${err.message}`); }
  }
}
console.log(`${screens.length} screens, ${rendered} renders, ${Object.keys(Lab.elements).length} elements, ${failures} failures`);
process.exit(failures ? 1 : 0);
