// Render each mockup at 1440 and 390 widths. Google Fonts requests are fulfilled through curl
// (which uses the sandbox proxy + CA bundle) so Inter / JetBrains Mono render as on the live site.
const { chromium } = require('playwright');
const { execFileSync } = require('child_process');
const path = require('path');
const DIR = '/home/user/DAYXERO/research_notes/DayXero prelaunch waitlist marketing/mockups';
const only = process.argv[2];
const pages = ['a-hero-waitlist', 'b-pricing-founding', 'c-success-referral', 'd-guide-cta-sticky', 'e-beta-page', 'index'];
const cache = new Map();
(async () => {
  const browser = await chromium.launch();
  for (const name of pages) {
    if (only && !name.startsWith(only)) continue;
    for (const [label, width, height] of [['desktop', 1440, 900], ['mobile', 390, 844]]) {
      const ctx = await browser.newContext({ viewport: { width, height }, deviceScaleFactor: 1 });
      const page = await ctx.newPage();
      await page.route(/https:\/\/fonts\.(googleapis|gstatic)\.com\/.*/, async (route) => {
        const url = route.request().url();
        if (!cache.has(url)) {
          const ua = route.request().headers()['user-agent'];
          cache.set(url, execFileSync('curl', ['-sS', '--max-time', '30', '-A', ua, url], { maxBuffer: 1 << 26 }));
        }
        const ct = url.includes('googleapis') ? 'text/css' : 'font/woff2';
        await route.fulfill({ status: 200, body: cache.get(url), headers: { 'content-type': ct, 'access-control-allow-origin': '*' } });
      });
      await page.goto('file://' + path.join(DIR, name + '.html'), { waitUntil: 'networkidle' });
      await page.evaluate(() => document.fonts.ready);
      await page.waitForTimeout(400);
      await page.screenshot({ path: path.join(DIR, `${name}-${label}.png`), fullPage: true, animations: 'disabled' });
      if (name === 'd-guide-cta-sticky' && label === 'mobile') {
        // Viewport shots to show the sticky bar and the inline CTA in context
        await page.evaluate(() => document.getElementById('guide-cta-inline').scrollIntoView({ block: 'center', behavior: 'instant' }));
        await page.waitForTimeout(300);
        await page.screenshot({ path: path.join(DIR, `${name}-mobile-viewport-inline.png`), animations: 'disabled' });
        await page.evaluate(() => window.scrollTo({ top: 400, behavior: 'instant' }));
        await page.waitForTimeout(300);
        await page.screenshot({ path: path.join(DIR, `${name}-mobile-viewport-sticky.png`), animations: 'disabled' });
      }
      await ctx.close();
      console.log('shot', name, label);
    }
  }
  await browser.close();
})();
