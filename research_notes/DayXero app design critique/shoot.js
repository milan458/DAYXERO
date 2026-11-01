// Screenshot every DayXero Screen Lab screen (light + dark, viewport + full-length).
// Usage: node shoot.js <baseUrl> <outDir>
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

(async () => {
  const base = process.argv[2];
  const out = process.argv[3];
  fs.mkdirSync(out, { recursive: true });
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1900, height: 1250 }, deviceScaleFactor: 1 });
  page.on('console', (m) => { if (m.type() === 'error') console.log('console.error:', m.text()); });
  await page.goto(base + '/index.html#s-today', { waitUntil: 'networkidle' });
  await page.waitForSelector('.glass', { timeout: 20000 });
  // Font status
  const fonts = await page.evaluate(async () => {
    await document.fonts.ready;
    return {
      bricolage: document.fonts.check("800 24px 'Bricolage Grotesque'"),
      dmsans: document.fonts.check("400 16px 'DM Sans'"),
      loaded: [...document.fonts].filter((f) => f.status === 'loaded').map((f) => f.family + ' ' + f.weight).slice(0, 20),
    };
  });
  console.log('FONTS', JSON.stringify(fonts));
  const screens = await page.evaluate(() => Lab.screens.map((s) => ({ id: s.id, name: s.name, area: s.area, ground: s.ground || 'reading', tab: s.tab || null, fullBleed: !!s.fullBleed, states: (s.states || []).map((x) => x.id) })));
  fs.writeFileSync(path.join(out, '_screens.json'), JSON.stringify(screens, null, 2));
  console.log('SCREENS', screens.length);
  const setDark = async (dark) => {
    await page.selectOption('#opt-dark', dark ? '1' : '0');
    await page.waitForTimeout(150);
  };
  const metrics = [];
  for (const s of screens) {
    await page.evaluate((id) => { location.hash = '#s-' + id; }, s.id);
    await page.waitForTimeout(250);
    for (const dark of [false, true]) {
      await setDark(dark);
      await page.waitForTimeout(1200); // let marked-word draw animations finish
      const glass = await page.$('.glass');
      const suffix = dark ? 'dark' : 'light';
      await glass.screenshot({ path: path.join(out, `${s.id}--${suffix}.png`) });
      // full-length: expand the phone to the content height
      const m = await page.evaluate(() => {
        const scr = document.querySelector('.glass .scr');
        const sc = scr.querySelector('.scroll');
        const content = sc.querySelector('.content');
        return { scrollH: sc.scrollHeight, viewH: scr.clientHeight, contentH: content.scrollHeight };
      });
      if (!dark) metrics.push({ id: s.id, ...m });
      if (m.scrollH > m.viewH + 8 && !dark) {
        const H = Math.min(m.scrollH, 4000);
        await page.evaluate((H) => {
          const glass = document.querySelector('.glass'); const scr = glass.querySelector('.scr');
          glass.dataset.oh = glass.style.height; glass.style.height = H + 'px'; scr.style.height = H + 'px';
          document.querySelector('.phone').style.transform = 'none';
        }, H);
        await page.waitForTimeout(100);
        const g2 = await page.$('.glass');
        await g2.screenshot({ path: path.join(out, `${s.id}--${suffix}--full.png`) });
        await page.evaluate(() => { location.reload(); });
        await page.waitForSelector('.glass', { timeout: 20000 });
        await page.waitForTimeout(200);
      }
    }
  }
  fs.writeFileSync(path.join(out, '_metrics.json'), JSON.stringify(metrics, null, 2));
  await setDark(false);
  // Element library overview
  await page.evaluate(() => { location.hash = '#library'; });
  await page.waitForTimeout(800);
  await page.screenshot({ path: path.join(out, '_library.png'), fullPage: false });
  await browser.close();
  console.log('DONE');
})().catch((e) => { console.error(e); process.exit(1); });
