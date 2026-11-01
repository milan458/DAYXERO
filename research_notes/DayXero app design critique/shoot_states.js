// Screenshot every non-default state of every DayXero Screen Lab screen (light; dark for selected screens).
// Usage: node shoot_states.js <baseUrl> <outDir>
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

(async () => {
  const base = process.argv[2];
  const out = process.argv[3];
  fs.mkdirSync(out, { recursive: true });
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1900, height: 1250 }, deviceScaleFactor: 1 });
  await page.goto(base + '/index.html#s-today', { waitUntil: 'networkidle' });
  await page.waitForSelector('.glass', { timeout: 20000 });
  const screens = await page.evaluate(() => Lab.screens.map((s) => ({ id: s.id, states: (s.states || []).map((x) => ({ id: x.id, label: x.label })) })));
  const darkAlso = new Set(['milestone', 'session', 'onb-chat', 'today', 'sos', 'checkin-form', 'session-kit']);
  let n = 0;
  const index = [];
  for (const s of screens) {
    if (s.states.length < 2) continue;
    for (let i = 1; i < s.states.length; i++) {
      const st = s.states[i];
      for (const dark of darkAlso.has(s.id) ? [false, true] : [false]) {
        await page.evaluate(({ id, stId, dark }) => {
          Lab.view.state[id] = stId; Lab.view.dark = dark; Lab.view.screenId = id; Lab.view.mode = 'screens';
          location.hash = '#s-' + id; Lab.ui.refresh();
        }, { id: s.id, stId: st.id, dark });
        await page.waitForTimeout(900);
        const glass = await page.$('.glass');
        const file = `${s.id}--${st.id}--${dark ? 'dark' : 'light'}.png`;
        await glass.screenshot({ path: path.join(out, file) });
        index.push({ screen: s.id, state: st.id, label: st.label, dark, file });
        n++;
      }
    }
  }
  fs.writeFileSync(path.join(out, '_states_index.json'), JSON.stringify(index, null, 2));
  console.log('STATE SHOTS', n);
  await browser.close();
})().catch((e) => { console.error(e); process.exit(1); });
