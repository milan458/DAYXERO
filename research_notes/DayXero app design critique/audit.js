// DOM audit of every screen (default state, light): small text, small touch targets, tab-bar overlap, animation inventory.
const { chromium } = require('playwright');
const fs = require('fs');
(async () => {
  const base = process.argv[2], out = process.argv[3];
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 1900, height: 1250 } });
  await page.goto(base + '/index.html#s-today', { waitUntil: 'networkidle' });
  await page.waitForSelector('.glass');
  const ids = await page.evaluate(() => Lab.screens.map((s) => s.id));
  const res = [];
  for (const id of ids) {
    await page.evaluate((id) => { Lab.view.dark = false; Lab.view.screenId = id; location.hash = '#s-' + id; Lab.ui.refresh(); }, id);
    await page.waitForTimeout(250);
    const r = await page.evaluate(() => {
      const glass = document.querySelector('.glass');
      const gb = glass.getBoundingClientRect();
      const sizes = {}; const smallText = [];
      const tappable = []; const fams = {};
      glass.querySelectorAll('*').forEach((el) => {
        const cs = getComputedStyle(el);
        const txt = [...el.childNodes].filter((n) => n.nodeType === 3 && n.textContent.trim()).map((n) => n.textContent.trim()).join(' ');
        if (txt) {
          const fs = parseFloat(cs.fontSize); sizes[fs] = (sizes[fs] || 0) + 1;
          const fam = cs.fontFamily.split(',')[0].replace(/['"]/g, ''); fams[fam] = (fams[fam] || 0) + 1;
          if (fs < 12) smallText.push({ text: txt.slice(0, 40), size: fs });
        }
        const role = el.getAttribute('role') || '';
        const tag = el.tagName.toLowerCase();
        const dt = el.getAttribute('data-type') || '';
        if (tag === 'button' || tag === 'a' || role === 'button' || role === 'radio' || role === 'checkbox' || /button|chip|toggle|pill|link|row|tab|option|radio|check/i.test(dt)) {
          const b = el.getBoundingClientRect();
          if (b.width > 0 && b.height > 0 && b.height < 44) tappable.push({ type: dt || tag, text: (el.textContent || '').trim().slice(0, 30), w: Math.round(b.width), h: Math.round(b.height) });
        }
      });
      const bar = glass.querySelector('[data-node="_tabbar"]');
      const anims = [...glass.querySelectorAll('*')].filter((el) => { const cs = getComputedStyle(el); return cs.animationName && cs.animationName !== 'none'; }).map((el) => getComputedStyle(el).animationName);
      const smil = glass.querySelectorAll('animate, animateTransform, animateMotion').length;
      return { sizes, fams, smallText: smallText.slice(0, 10), tappable: tappable.slice(0, 12), hasBar: !!bar, cssAnims: [...new Set(anims)], smil };
    });
    res.push({ id, ...r });
  }
  fs.writeFileSync(out, JSON.stringify(res, null, 2));
  // summary
  const allSizes = {}; const allFams = {}; let smallTotal = 0, smallTap = 0; let smilTotal = 0;
  res.forEach((r) => { Object.entries(r.sizes).forEach(([k, v]) => allSizes[k] = (allSizes[k] || 0) + v); Object.entries(r.fams).forEach(([k, v]) => allFams[k] = (allFams[k] || 0) + v); smallTotal += r.smallText.length; smallTap += r.tappable.length; smilTotal += r.smil; });
  console.log('font sizes (px:count):', JSON.stringify(allSizes));
  console.log('families:', JSON.stringify(allFams));
  console.log('screens with <12px text:', res.filter((r) => r.smallText.length).map((r) => r.id + ':' + r.smallText.map((t) => t.size + 'px "' + t.text + '"').join('; ')).join('\n'));
  console.log('screens with tappables <44px tall:', res.filter((r) => r.tappable.length).map((r) => r.id + ' -> ' + r.tappable.map((t) => `${t.type}(${t.h}px) "${t.text}"`).join(', ')).join('\n'));
  console.log('SMIL animate elements total:', smilTotal, ' per screen:', res.map((r) => r.id + '=' + r.smil).join(' '));
  console.log('CSS anims:', [...new Set(res.flatMap((r) => r.cssAnims))]);
  await browser.close();
})();
