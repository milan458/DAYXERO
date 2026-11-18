// Render screens to stills: node cook/tools/render.mjs <outDir> [screen ids or files...]  (default: all screens)
// Each screen in light and dark at 390x844, ?still=1 (final state). Also checks for overflow past the frame.
import { createRequire } from 'node:module'; import fs from 'node:fs'; import path from 'node:path';
const require = createRequire(import.meta.url); const { chromium } = require('playwright');
const root = path.resolve('cook/site/screens'); const out = path.resolve(process.argv[2] || 'cook/stills/tmp'); fs.mkdirSync(out, { recursive: true });
let files = process.argv.slice(3); if (!files.length) files = fs.readdirSync(root).filter(f => f.endsWith('.html'));
files = files.map(f => path.basename(f).replace(/\.html$/, '')).sort();
const b = await chromium.launch(); const ctx = await b.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: +(process.env.DPR || 1) });
const report = [];
for (const id of files) for (const theme of ['light', 'dark']) {
  const p = await ctx.newPage(); const errs = []; p.on('pageerror', e => errs.push(e.message)); p.on('console', m => { if (m.type() === 'error') errs.push(m.text()); });
  await p.goto('file://' + path.join(root, id + '.html') + `?still=1&theme=${theme}`);
  await p.waitForFunction(() => document.body.classList.contains('ready'), null, { timeout: 8000 }).catch(() => errs.push('never ready'));
  await p.waitForTimeout(250);
  const el = await p.$('.screen'); if (el) await el.screenshot({ path: path.join(out, `${id}-${theme}.png`) }); else errs.push('no .screen');
  if (errs.length) report.push(`${id} ${theme}: ${errs.join(' | ')}`);
  await p.close();
}
await b.close(); console.log(`rendered ${files.length} screens to ${out}`); if (report.length) console.log('PROBLEMS:\n' + report.join('\n'));
