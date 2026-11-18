// usage: node cook/tools/shot.mjs <outDir> [scale]
// Renders each Evidence story screen, light and dark, from cook/canvas/project.
import { createRequire } from 'module'; const { chromium } = createRequire(import.meta.url)('playwright');
import http from 'http'; import fs from 'fs'; import path from 'path';
const root = path.resolve('cook/canvas/project');
const out = process.argv[2]; const scale = Number(process.argv[3] || 2);
fs.mkdirSync(out, { recursive: true });
const types = { '.html': 'text/html', '.js': 'text/javascript', '.json': 'application/json' };
const srv = http.createServer((q, r) => {
  const u = new URL(q.url, 'http://x'); const f = path.join(root, decodeURIComponent(u.pathname));
  if (!f.startsWith(root) || !fs.existsSync(f)) { r.writeHead(404); return r.end(); }
  r.writeHead(200, { 'content-type': types[path.extname(f)] || 'application/octet-stream' }); r.end(fs.readFileSync(f));
}).listen(0);
const port = srv.address().port;
const shots = [['S1','EvCompany',844],['S2','EvWorks',844],['S3','EvTriggers',844],['S4','EvObstacles',844],['S5','EvNRT',900],['S6','EvQuitDay',990],['S7','EvPlan',1120],['S8','EvSources',844]];
const b = await chromium.launch();
for (const theme of ['light','dark']) for (const [id, name, h] of shots) {
  const pg = await b.newPage({ viewport: { width: 390, height: h }, deviceScaleFactor: scale });
  const errs = []; pg.on('pageerror', e => errs.push(String(e)));
  let src = fs.readFileSync(path.join(root, name + '.dc.html'), 'utf8');
  if (theme === 'dark') src = src.replace('"theme":{"editor":"enum","options":["light","dark"],"default":"light"}', '"theme":{"editor":"enum","options":["light","dark"],"default":"dark"}');
  await pg.route('**/__shot.dc.html', r => r.fulfill({ contentType: 'text/html', body: src }));
  await pg.goto(`http://localhost:${port}/__shot.dc.html`);
  await pg.waitForTimeout(3500);
  await pg.screenshot({ path: path.join(out, `${id}-${theme}.png`) });
  if (errs.length) console.log(id, theme, errs.slice(0, 2));
  await pg.close();
}
await b.close(); srv.close();
