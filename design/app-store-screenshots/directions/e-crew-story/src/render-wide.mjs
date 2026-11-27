// Renders the iPad 13" and iPhone Duo sets of Direction E ("Meet the crew") with Playwright (Chromium).
//   node render-wide.mjs                    all ten frames for ipad, duo-cover and duo-inner
//   node render-wide.mjs --dev ipad 03 07   one set, these frames
// Output: ../export/ipad-13/NN.png (2064 x 2752), ../export/duo-cover/NN.png (1398 x 2034),
//         ../export/duo-inner/NN.png (2007 x 2853), and a contact sheet per set.
// Each frame is frame-wide.html with frames-wide/NN-*.html, laid out on a 1320-wide stage as tall as the canvas at
// that width and scaled to the canvas in the browser, so it is rendered natively, never resampled. The phones and
// tablets hold real CI captures from ../real-<set>/. PNGs are 8-bit RGB with an sRGB chunk, as App Store Connect expects.
// CHROMIUM_PATH, if set, is the Chromium to launch (any recent Chromium works).
import { createRequire } from 'node:module';
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import zlib from 'node:zlib';
import { fileURLToPath } from 'node:url';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');

const SRC = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(SRC, '..');
const OUT = path.join(ROOT, 'export');
const SETS = {
  ipad: { dir: 'ipad-13', w: 2064, h: 2752 },
  'duo-cover': { dir: 'duo-cover', w: 1398, h: 2034 },
  'duo-inner': { dir: 'duo-inner', w: 2007, h: 2853 },
};
const ALL = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10'];
const args = process.argv.slice(2);
const devArg = args.includes('--dev') ? args[args.indexOf('--dev') + 1] : null;
const only = args.filter((a) => /^\d{1,2}$/.test(a)).map((a) => a.padStart(2, '0'));
const ids = only.length ? only : ALL;
const devs = devArg ? [devArg] : Object.keys(SETS).filter((d) => fs.existsSync(path.join(ROOT, 'real-' + d)));

const TYPES = { '.html': 'text/html', '.css': 'text/css', '.js': 'text/javascript', '.json': 'application/json', '.woff2': 'font/woff2', '.png': 'image/png', '.svg': 'image/svg+xml' };
function serve(root) {
  const server = http.createServer((req, res) => {
    const p = path.join(root, decodeURIComponent(new URL(req.url, 'http://x').pathname));
    if (!p.startsWith(root) || !fs.existsSync(p) || fs.statSync(p).isDirectory()) { res.writeHead(404); return res.end(); }
    res.writeHead(200, { 'content-type': TYPES[path.extname(p)] || 'application/octet-stream' });
    fs.createReadStream(p).pipe(res);
  });
  return new Promise((ok) => server.listen(0, '127.0.0.1', () => ok(server)));
}

const CRC = new Int32Array(256).map((_, n) => { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; return c; });
const crc32 = (buf) => { let c = -1; for (const b of buf) c = CRC[(c ^ b) & 0xff] ^ (c >>> 8); return (c ^ -1) >>> 0; };
function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const td = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(td));
  return Buffer.concat([len, td, crc]);
}
function toRGB(png) {
  let o = 8, w, h, depth, ctype; const idat = [];
  while (o < png.length) {
    const len = png.readUInt32BE(o), type = png.toString('ascii', o + 4, o + 8), data = png.subarray(o + 8, o + 8 + len);
    if (type === 'IHDR') { w = data.readUInt32BE(0); h = data.readUInt32BE(4); depth = data[8]; ctype = data[9]; }
    if (type === 'IDAT') idat.push(data);
    o += 12 + len;
  }
  if (depth !== 8 || (ctype !== 6 && ctype !== 2)) throw new Error(`unexpected PNG type ${ctype}/${depth}`);
  const bpp = ctype === 6 ? 4 : 3, stride = w * bpp;
  const raw = zlib.inflateSync(Buffer.concat(idat));
  const out = Buffer.alloc((w * 3 + 1) * h);
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
    const row = (w * 3 + 1) * y; out[row] = 0;
    for (let x = 0; x < w; x++) for (let k = 0; k < 3; k++) out[row + 1 + x * 3 + k] = cur[x * bpp + k]; // alpha is 255 everywhere (opaque page)
    [prev, cur] = [cur, prev];
  }
  const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4); ihdr[8] = 8; ihdr[9] = 2; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
  return Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ihdr), chunk('sRGB', Buffer.from([0])),
    chunk('IDAT', zlib.deflateSync(out, { level: 9 })), chunk('IEND', Buffer.alloc(0))]);
}


const server = await serve(ROOT);
const base = `http://127.0.0.1:${server.address().port}`;
const launch = process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH, args: ['--no-sandbox', '--font-render-hinting=none'] } : {};
const browser = await chromium.launch(launch);
try {
  for (const dev of devs) {
    const S = SETS[dev];
    const ctx = await browser.newContext({ viewport: { width: S.w, height: S.h }, deviceScaleFactor: 1 });
    const page = await ctx.newPage();
    page.on('pageerror', (e) => console.error('page error:', e.message));
    page.on('requestfailed', (r) => console.error('request failed:', r.url()));
    page.on('response', (r) => { if (r.status() >= 400) console.error('HTTP', r.status(), r.url()); });
    fs.mkdirSync(path.join(OUT, S.dir), { recursive: true });
    for (const id of ids) {
      await page.goto(`${base}/src/frame-wide.html?f=${id}&dev=${dev}`, { waitUntil: 'load' });
      await page.waitForFunction(() => document.body.dataset.ready === '1' || document.body.dataset.error, null, { timeout: 30000 });
      const err = await page.evaluate(() => document.body.dataset.error);
      if (err) throw new Error(`${dev} frame ${id}: ${err}`);
      const fonts = await page.evaluate(() => ['800 120px "Bricolage Grotesque"', '500 50px "DM Sans"', '700 40px "DM Sans"'].map((f) => document.fonts.check(f)));
      if (fonts.includes(false)) throw new Error(`${dev} frame ${id}: fonts not loaded`);
      const broken = await page.evaluate(() => [...document.images].filter((i) => !i.naturalWidth).map((i) => i.src));
      if (broken.length) throw new Error(`${dev} frame ${id}: images not loaded: ${broken.join(', ')}`);
      const png = await page.screenshot({ type: 'png', fullPage: false });
      fs.writeFileSync(path.join(OUT, S.dir, `${id}.png`), toRGB(png));
      console.log(`${S.dir}/${id}.png  ${S.w}x${S.h}`);
    }
    await ctx.close();
    const dir = path.join(OUT, S.dir);
    if (ALL.every((id) => fs.existsSync(path.join(dir, `${id}.png`)))) {
      const w = 300, h = Math.round(w * S.h / S.w), gap = 14, pad = 24;
      const c2 = await browser.newContext({ viewport: { width: pad * 2 + 10 * w + 9 * gap, height: pad * 2 + h }, deviceScaleFactor: 1 });
      const p2 = await c2.newPage();
      const imgs = ALL.map((id) => `<img src="data:image/png;base64,${fs.readFileSync(path.join(dir, `${id}.png`)).toString('base64')}" style="width:${w}px;height:${h}px;border-radius:14px;display:block">`).join('');
      await p2.setContent(`<body style="margin:0;background:#F2F2F7"><div style="display:flex;gap:${gap}px;padding:${pad}px">${imgs}</div></body>`);
      await p2.waitForFunction(() => [...document.images].every((i) => i.complete));
      fs.writeFileSync(path.join(OUT, `contact-sheet-${S.dir}.png`), toRGB(await p2.screenshot({ type: 'png' })));
      console.log(`contact-sheet-${S.dir}.png`);
      await c2.close();
    }
  }
} finally {
  await browser.close();
  server.close();
}
