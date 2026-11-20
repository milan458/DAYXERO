// Checks for Direction C. Run after editing pano.js or the captions:   node check.mjs
//  1. Seams: renders the whole panorama once (pano.html, 13200 x 2868) and compares every 1320 px slice with the art of
//     that frame rendered on its own (frame.html?f=NN&art=1). Identical slices mean the frames meet exactly at each seam.
//     Also writes ../export/panorama-art.png (the art alone, half size) for review.
//  2. Caption contrast: for every caption line box, measures the WCAG contrast of the caption colour against every
//     pixel of the frame behind it (rendered without the caption, &nocap=1). Fails under 4.5:1.
import { createRequire } from 'node:module';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');
const SRC = path.dirname(fileURLToPath(import.meta.url));
const OUT = path.resolve(SRC, '../export');
const ALL = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10'];

const TYPES = { '.html': 'text/html', '.css': 'text/css', '.js': 'text/javascript', '.woff2': 'font/woff2', '.png': 'image/png', '.svg': 'image/svg+xml' };
function serve(root) {
  const server = http.createServer((req, res) => {
    const p = path.join(root, decodeURIComponent(new URL(req.url, 'http://x').pathname));
    if (!p.startsWith(root) || !fs.existsSync(p) || fs.statSync(p).isDirectory()) { res.writeHead(404); return res.end(); }
    res.writeHead(200, { 'content-type': TYPES[path.extname(p)] || 'application/octet-stream' });
    fs.createReadStream(p).pipe(res);
  });
  return new Promise((ok) => server.listen(0, '127.0.0.1', () => ok(server)));
}
// decode Chromium's PNG (8-bit RGBA or RGB) into { w, h, px: RGB bytes }
function decode(png) {
  let o = 8, w, h, ctype; const idat = [];
  while (o < png.length) {
    const len = png.readUInt32BE(o), type = png.toString('ascii', o + 4, o + 8), data = png.subarray(o + 8, o + 8 + len);
    if (type === 'IHDR') { w = data.readUInt32BE(0); h = data.readUInt32BE(4); ctype = data[9]; }
    if (type === 'IDAT') idat.push(data);
    o += 12 + len;
  }
  const bpp = ctype === 6 ? 4 : 3, stride = w * bpp, raw = zlib.inflateSync(Buffer.concat(idat));
  const px = Buffer.alloc(w * h * 3);
  let prev = Buffer.alloc(stride), cur = Buffer.alloc(stride);
  for (let y = 0; y < h; y++) {
    const f = raw[y * (stride + 1)], line = raw.subarray(y * (stride + 1) + 1, (y + 1) * (stride + 1));
    for (let x = 0; x < stride; x++) {
      const a = x >= bpp ? cur[x - bpp] : 0, b = prev[x], c = x >= bpp ? prev[x - bpp] : 0;
      let v = line[x];
      if (f === 1) v += a; else if (f === 2) v += b; else if (f === 3) v += (a + b) >> 1;
      else if (f === 4) { const p = a + b - c, pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c); v += pa <= pb && pa <= pc ? a : pb <= pc ? b : c; }
      cur[x] = v & 0xff;
    }
    for (let x = 0; x < w; x++) for (let k = 0; k < 3; k++) px[(y * w + x) * 3 + k] = cur[x * bpp + k];
    [prev, cur] = [cur, prev];
  }
  return { w, h, px };
}
const L = (r, g, b) => [r, g, b].map((c) => { c /= 255; return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4; }).reduce((s, c, i) => s + c * [0.2126, 0.7152, 0.0722][i], 0);
const ratio = (a, b) => (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05);

const server = await serve(SRC);
const base = `http://127.0.0.1:${server.address().port}`;
const browser = await chromium.launch();
let failed = false;
try {
  // ---------- 1. seams
  const ctxP = await browser.newContext({ viewport: { width: 4400, height: 956 }, deviceScaleFactor: 3 });
  const pp = await ctxP.newPage();
  await pp.goto(`${base}/pano.html`, { waitUntil: 'load' });
  await pp.waitForFunction(() => document.body.dataset.ready === '1');
  const panoPng = await pp.screenshot({ type: 'png' });
  const pano = decode(panoPng);
  // half-size review copy of the art
  const ctxH = await browser.newContext({ viewport: { width: 4400, height: 956 }, deviceScaleFactor: 1.5 });
  const ph = await ctxH.newPage();
  await ph.goto(`${base}/pano.html`, { waitUntil: 'load' });
  await ph.waitForFunction(() => document.body.dataset.ready === '1');
  fs.writeFileSync(path.join(OUT, 'panorama-art.png'), await ph.screenshot({ type: 'png' }));
  await ctxH.close(); await ctxP.close();

  const ctx = await browser.newContext({ viewport: { width: 440, height: 956 }, deviceScaleFactor: 3 });
  const page = await ctx.newPage();
  page.on('pageerror', (e) => console.error('page error:', e.message));
  console.log('Seams: each frame\'s art against its slice of the single 13200 px render');
  for (const [i, id] of ALL.entries()) {
    await page.goto(`${base}/frame.html?f=${id}&art=1`, { waitUntil: 'load' });
    await page.waitForFunction(() => document.body.dataset.ready === '1');
    const a = decode(await page.screenshot({ type: 'png' }));
    let max = 0, sum = 0, n = 0, big = 0;
    for (let y = 0; y < a.h; y++) for (let x = 0; x < a.w; x++) {
      let dp = 0;
      for (let k = 0; k < 3; k++) { const d = Math.abs(a.px[(y * a.w + x) * 3 + k] - pano.px[(y * pano.w + x + i * 1320) * 3 + k]); if (d > dp) dp = d; sum += d; n++; }
      if (dp > max) max = dp; if (dp > 16) big++;
    }
    const mean = sum / n;
    if (process.env.DIFF) { // where the differences are: a coarse histogram of rows and columns with diff > 8
      const rows = {}, cols = {};
      for (let y = 0; y < a.h; y++) for (let x = 0; x < a.w; x++) { let d = 0; for (let k = 0; k < 3; k++) d = Math.max(d, Math.abs(a.px[(y * a.w + x) * 3 + k] - pano.px[(y * pano.w + x + i * 1320) * 3 + k])); if (d > 8) { rows[y / 60 | 0] = (rows[y / 60 | 0] || 0) + 1; cols[x / 60 | 0] = (cols[x / 60 | 0] || 0) + 1; } }
      console.log('    rows(x60):', JSON.stringify(rows), ' cols(x60):', JSON.stringify(cols));
    }
    // Chromium rasterises a 13200 px layer in different tiles than a 1320 px one, so a few anti-aliased edge pixels
    // differ slightly. A shifted or mismatched slice would differ along every edge in the frame instead.
    const share = big / (a.w * a.h), ok = mean < 0.25 && share < 2e-4;
    if (!ok) failed = true;
    console.log(`  ${id}: mean |diff| ${mean.toFixed(4)}, pixels off by > 16: ${big} of ${a.w * a.h} (${(share * 100).toFixed(4)}%)  ${ok ? 'ok' : 'MISMATCH'}`);
  }

  // the exported PNGs: the step across each seam (last column of frame N against the first of N+1) should be no bigger
  // than the step between two neighbouring columns inside a frame
  for (const dir of ['iphone-6.9', 'iphone-6.3']) {
    const ims = ALL.map((id) => path.join(OUT, dir, `${id}.png`));
    if (!ims.every((f) => fs.existsSync(f))) continue;
    const D = ims.map((f) => decode(fs.readFileSync(f)));
    const step = (A, xa, B, xb) => { let s = 0; for (let y = 0; y < A.h; y++) for (let k = 0; k < 3; k++) s += Math.abs(A.px[(y * A.w + xa) * 3 + k] - B.px[(y * B.w + xb) * 3 + k]); return s / (A.h * 3); };
    const seams = [], inner = [];
    for (let i = 0; i < 9; i++) { const A = D[i], B = D[i + 1]; seams.push(step(A, A.w - 1, B, 0)); inner.push(step(A, A.w - 2, A, A.w - 1), step(B, 0, B, 1)); }
    const worst = Math.max(...seams), base = Math.max(...inner);
    const ok = worst <= base * 1.6 + 0.5;
    if (!ok) failed = true;
    console.log(`Seams in export/${dir}: step across seams ${seams.map((v) => v.toFixed(2)).join(' ')}; worst neighbouring-column step inside a frame ${base.toFixed(2)}  ${ok ? 'ok' : 'JUMP'}`);
  }

  // ---------- 2. caption contrast
  console.log('Caption contrast (WCAG 2.x), caption colour against every pixel behind each line box');
  for (const id of ALL) {
    await page.goto(`${base}/frame.html?f=${id}`, { waitUntil: 'load' });
    await page.waitForFunction(() => document.body.dataset.ready === '1');
    const boxes = await page.evaluate(() => [...document.querySelectorAll('.cap h1, .cap .sub, .cap .fine')].flatMap((el) => {
      const r = document.createRange(); r.selectNodeContents(el);
      const col = getComputedStyle(el).color.match(/\d+/g).slice(0, 3).map(Number);
      return [...r.getClientRects()].map((b) => ({ cls: el.tagName === 'H1' ? 'title' : el.className, x0: b.left, y0: b.top, x1: b.right, y1: b.bottom, col }));
    }));
    await page.goto(`${base}/frame.html?f=${id}&nocap=1`, { waitUntil: 'load' });
    await page.waitForFunction(() => document.body.dataset.ready === '1');
    const bg = decode(await page.screenshot({ type: 'png' }));
    const res = {};
    for (const b of boxes) {
      const lt = L(...b.col);
      let min = 99;
      for (let y = Math.max(0, Math.floor(b.y0 * 3)); y < Math.min(bg.h, Math.ceil(b.y1 * 3)); y++)
        for (let x = Math.max(0, Math.floor(b.x0 * 3)); x < Math.min(bg.w, Math.ceil(b.x1 * 3)); x++) {
          const o = (y * bg.w + x) * 3, c = ratio(lt, L(bg.px[o], bg.px[o + 1], bg.px[o + 2]));
          if (c < min) min = c;
        }
      res[b.cls] = Math.min(res[b.cls] ?? 99, min);
    }
    const worst = Math.min(...Object.values(res));
    if (worst < 4.5) failed = true;
    console.log(`  ${id}: ${Object.entries(res).map(([k, v]) => `${k} ${v.toFixed(2)}`).join(', ')}  ${worst >= 4.5 ? 'ok' : 'LOW'}`);
  }
  await ctx.close();
} finally {
  await browser.close();
  server.close();
}
if (failed) { console.log('FAILED'); process.exit(1); } else console.log('All checks passed.');
