// Renders the ten DayXero App Store frames with Playwright (Chromium).
//   node render.mjs                 all frames, both sizes, plus the contact sheets
//   node render.mjs 03 07           only these frames (both sizes), then the contact sheets
//   node render.mjs --size 6.9      one size only
// Output: ../export/iphone-6.9/NN.png (1320 x 2868), ../export/iphone-6.3/NN.png (1206 x 2622),
//         ../export/contact-sheet.png and ../export/contact-sheet-search.png.
// Every PNG is re-encoded as 8-bit RGB (no alpha channel) with an sRGB chunk, as App Store Connect expects.
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
const SIZES = {
  '6.9': { dir: 'iphone-6.9', w: 1320, h: 2868 },
  '6.3': { dir: 'iphone-6.3', w: 1206, h: 2622 },
};
const ALL = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10'];

const args = process.argv.slice(2);
const sizeArg = args.includes('--size') ? args[args.indexOf('--size') + 1] : null;
const only = args.filter((a) => /^\d{1,2}$/.test(a)).map((a) => a.padStart(2, '0'));
const ids = only.length ? only : ALL;
const sizes = sizeArg ? [sizeArg] : Object.keys(SIZES);

// ---------- a tiny static server, so the frame page can read its iframes (file:// would make them cross-origin)
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

// ---------- PNG: decode Chromium's RGBA output, write RGB + sRGB
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

// ---------- render
const server = await serve(SRC);
const base = `http://127.0.0.1:${server.address().port}`;
const browser = await chromium.launch();
try {
  for (const key of sizes) {
    const S = SIZES[key];
    // Design width is 440 CSS px. 6.9": 440 x 956 at 3x. 6.3": 402 x 874 at 3x, the 440-wide stage scaled by 402/440.
    const vw = S.w / 3, vh = S.h / 3, scale = vw / 440;
    const ctx = await browser.newContext({ viewport: { width: vw, height: vh }, deviceScaleFactor: 3 });
    const page = await ctx.newPage();
    page.on('pageerror', (e) => console.error('page error:', e.message));
    fs.mkdirSync(path.join(OUT, S.dir), { recursive: true });
    for (const id of ids) {
      await page.goto(`${base}/frame.html?f=${id}&scale=${scale}`, { waitUntil: 'load' });
      await page.waitForFunction(() => document.body.dataset.ready === '1', null, { timeout: 30000 });
      const fonts = await page.evaluate(() => ['800 46px "Bricolage Grotesque"', '500 18px "DM Sans"'].map((f) => document.fonts.check(f)));
      if (fonts.includes(false)) throw new Error(`frame ${id}: fonts not loaded`);
      const png = await page.screenshot({ type: 'png', fullPage: false });
      const file = path.join(OUT, S.dir, `${id}.png`);
      fs.writeFileSync(file, toRGB(png));
      console.log(`${S.dir}/${id}.png  ${S.w}x${S.h}`);
    }
    await ctx.close();
  }

  // ---------- contact sheets, from the 6.9" exports
  const dir69 = path.join(OUT, SIZES['6.9'].dir);
  if (ALL.every((id) => fs.existsSync(path.join(dir69, `${id}.png`)))) {
    const ctx = await browser.newContext({ viewport: { width: 400, height: 400 }, deviceScaleFactor: 1 });
    const page = await ctx.newPage();
    const sheet = async (list, w, gap, pad, bg, file) => {
      const h = Math.round(w * 2868 / 1320);
      const width = pad * 2 + list.length * w + (list.length - 1) * gap, height = pad * 2 + h;
      await page.setViewportSize({ width, height });
      const imgs = list.map((id) => `<img src="data:image/png;base64,${fs.readFileSync(path.join(dir69, `${id}.png`)).toString('base64')}" style="width:${w}px;height:${h}px;border-radius:${Math.round(w * 0.045)}px;display:block">`).join('');
      await page.setContent(`<body style="margin:0;background:${bg}"><div style="display:flex;gap:${gap}px;padding:${pad}px">${imgs}</div></body>`);
      await page.waitForFunction(() => [...document.images].every((i) => i.complete));
      fs.writeFileSync(path.join(OUT, file), toRGB(await page.screenshot({ type: 'png' })));
      console.log(`${file}  ${width}x${height}`);
    };
    await sheet(ALL, 300, 14, 24, '#F2F2F7', 'contact-sheet.png');
    await sheet(['01', '02', '03'], 230, 10, 16, '#FFFFFF', 'contact-sheet-search.png');
    await ctx.close();
  }
} finally {
  await browser.close();
  server.close();
}
