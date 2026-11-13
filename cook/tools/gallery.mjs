// Build cook/site/index.html from the screen files: sections, live phones (light/dark), replay, motion spec, before shots.
import fs from 'node:fs';
const dir = 'cook/site/screens';
const files = fs.readdirSync(dir).filter(f => /^\d{3}-.*\.html$/.test(f)).sort();
const round = process.argv[2] || 'r01'; const score = process.argv[3] || '';
const sections = [
  ['launch', 'Launch', 0, 0, 'The intro, now a 2.4 s paper-cut sunrise.'],
  ['onboarding', 'Onboarding', 1, 13, 'One apricot ground; the sun rides the progress bar.'],
  ['paywall', 'Paywall', 14, 14, 'Calm, credible, one plan picker.'],
  ['today', 'Today', 15, 18, 'Prep, Day 7, through the day, evening with Glim.'],
  ['sos', 'Craving SOS', 19, 21, 'Ocean and Jelli only here. Calm motion, one +1.'],
  ['program', 'Program', 22, 22, 'The path, with prep stamps on its nodes.'],
  ['session', 'Prep session', 23, 32, 'The hand on a dark card table; cards carry the colour.'],
  ['lesson', 'Lesson', 33, 35, 'Reading ground, short pages.'],
  ['progress', 'Progress', 36, 36, 'Stats and the badge shelf.'],
  ['health', 'Health', 37, 38, 'What is changing, with sources.'],
  ['milestone', 'Milestones', 39, 40, 'The celebration and the share card.'],
  ['log', 'Logging', 41, 42, 'Log sheet and a craving, with a done toast.'],
  ['slip', 'Slips', 43, 46, 'Serious and kind. Nothing resets.'],
  ['nrt', 'NRT set-up', 47, 51, 'Step by step, with sources and a done beat.'],
  ['taper', 'Taper', 52, 52, ''],
  ['pledge', 'Daily pledge', 53, 53, 'Hold to pledge; the sun comes up.'],
  ['checkin', 'Check-in', 54, 55, 'Violet is Glim’s evening. A night badge on save.'],
  ['calm', 'Calm tools', 56, 60, ''],
  ['settings', 'Settings', 61, 70, 'Navy in dark mode now, one header, one list style.']];
const esc = s => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;');
const meta = f => { const t = fs.readFileSync(`${dir}/${f}`, 'utf8'); return { title: (t.match(/<title>([^<]*)<\/title>/) || [, f])[1].replace(/^\d{3}\s*/, ''), motion: (t.match(/<meta name="motion" content="([^"]*)"/) || [, ''])[1] }; };
let nav = '', body = '';
for (const [id, name, a, b, note] of sections) {
  const fs_ = files.filter(f => { const n = +f.slice(0, 3); return n >= a && n <= b; }); if (!fs_.length) continue;
  nav += `<a href="#${id}">${name}</a>`;
  body += `<section id="${id}"><div class="sechead"><h2>${name}</h2>${note ? `<p>${esc(note)}</p>` : ''}</div><div class="grid">`;
  for (const f of fs_) {
    const m = meta(f), base = f.replace('.html', ''), n = base.slice(0, 3);
    const before = n === '000' ? '' : `before/${base}`;
    body += `<article class="scr" data-id="${base}"><header><span class="n">${n}</span><h3>${esc(m.title)}</h3>
      <button class="rp" aria-label="Play the motion of ${esc(m.title)}">Play motion</button></header>
      <div class="pair">
        <div class="ph" data-mode="light" data-live="screens/${f}"><img data-src="stills/${base}-light.jpg" alt="${esc(m.title)}, light"><button class="open" data-src="screens/${f}" aria-label="Open ${esc(m.title)} light"></button></div>
        <div class="ph" data-mode="dark" data-live="screens/${f}?theme=dark"><img data-src="stills/${base}-dark.jpg" alt="${esc(m.title)}, dark"><button class="open" data-src="screens/${f}?theme=dark" aria-label="Open ${esc(m.title)} dark"></button></div>
        ${before ? `<div class="ph before" data-mode="before"><img data-src="${before}-light.jpg" alt="Before: ${esc(m.title)}, light"></div>` : ''}
      </div>
      ${m.motion ? `<p class="mo"><b>Motion</b> ${esc(m.motion)}</p>` : ''}</article>`;
  }
  body += `</div></section>`;
}
const html = fs.readFileSync('cook/tools/gallery.tpl.html', 'utf8').replace('{{NAV}}', nav).replace('{{BODY}}', body).replace('{{COUNT}}', files.length).replace('{{ROUND}}', round).replace('{{SCORE}}', score);
fs.writeFileSync('cook/site/index.html', html); console.log('gallery with', files.length, 'screens');
