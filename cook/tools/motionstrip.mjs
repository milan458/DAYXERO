// Motion strips: frames of live screens at fixed times. node cook/tools/motionstrip.mjs <outDir> id id ...
import { createRequire } from 'node:module'; import fs from 'node:fs'; import path from 'node:path';
const require = createRequire(import.meta.url); const { chromium } = require('playwright');
const out = path.resolve(process.argv[2]); fs.mkdirSync(out, { recursive: true });
const times = (process.env.TIMES || '0,250,600,1000,1600,2400,3400').split(',').map(Number);
const b = await chromium.launch(); const ctx = await b.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1 });
for (const id of process.argv.slice(3)) {
  const p = await ctx.newPage(); await p.goto('file://' + path.resolve('cook/site/screens', id + '.html'));
  await p.evaluate(() => document.fonts.ready); const t0 = Date.now();
  for (const t of times) { const w = t - (Date.now() - t0); if (w > 0) await p.waitForTimeout(w); await p.screenshot({ path: path.join(out, `${id}-${String(t).padStart(5, '0')}.png`) }); }
  await p.close();
}
await b.close(); console.log('done');
