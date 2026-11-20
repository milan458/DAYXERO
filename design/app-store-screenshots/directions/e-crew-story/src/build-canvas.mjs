// Writes the editable Design canvas for Direction E from the same frame markup the PNGs are rendered from.
//   node build-canvas.mjs <out-folder>     writes <out-folder>/project/canvas.json, one .dc.html per frame,
//                                          Char.dc.html (the designer's component, verbatim) and Waves.dc.html
// Each frames/NN-*.html becomes a .dc.html artboard: <x-char …> turns into <dc-import name="Char" …>, <x-waves frame="N">
// into <dc-import name="Waves" frame="N">, and ../real/<name>.png into that file's uploaded /_blob/ url (canvas/assets.json).
// Waves.dc.html carries waves.js's DX_WAVES function and WAVES_TEMPLATE unchanged, so the canvas draws the same landscape.
// Publish the folder to the canvas with the Artifact tool (url + root + file_path + files), canvas.json and Main first.
import fs from 'node:fs';
import path from 'node:path';
import vm from 'node:vm';
import { fileURLToPath } from 'node:url';

const SRC = path.dirname(fileURLToPath(import.meta.url));
const out = process.argv[2];
if (!out) { console.error('usage: node build-canvas.mjs <out-folder>'); process.exit(1); }
const P = path.join(out, 'project');
fs.mkdirSync(P, { recursive: true });

const frames = JSON.parse(fs.readFileSync(path.join(SRC, 'frames.json'), 'utf8'));
const { blobs } = JSON.parse(fs.readFileSync(path.join(SRC, 'canvas/assets.json'), 'utf8'));
const W = 1320, H = 2868, GAP = 80;

// ---------- the waves component: run waves.js to get the function source and the template
const ctx = { globalThis: {} }; ctx.window = ctx;
vm.runInNewContext(fs.readFileSync(path.join(SRC, 'waves.js'), 'utf8'), ctx);
const fnSrc = ctx.DX_WAVES.toString();
const FONT = '<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,600..800&amp;family=DM+Sans:wght@400;500;700&amp;display=swap">';

const head = (title) => `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>${title}</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
${FONT}
<style>
body{margin:0}
</style>
</helmet>
`;
const tail = (props, logic = '  renderVals() { return {}; }') => `
</x-dc>
<script type="text/x-dc" data-dc-script data-props='${JSON.stringify(props)}'>
class Component extends DCLogic {
${logic}
}
</script>
</body>
</html>
`;

// ---------- the artboards
for (const f of frames) {
  let html = fs.readFileSync(path.join(SRC, 'frames', f.file), 'utf8').trim();
  html = html.replace(/<x-waves frame="(\d+)"><\/x-waves>/g, (_, n) =>
    `<div style="position: absolute; left: 0; top: 0; width: ${W}px; height: ${H}px"><dc-import name="Waves" frame="${n}" hint-size="${W}px,${H}px"></dc-import></div>`);
  html = html.replace(/<x-char ([^>]*)><\/x-char>/g, (_, attrs) => {
    const size = Number(/size="(\d+)"/.exec(attrs)[1]);
    return `<dc-import name="Char" ${attrs} hint-size="${size}px,${Math.round(size * 1.1)}px"></dc-import>`;
  });
  html = html.replace(/\.\.\/real\/([\w-]+\.png)/g, (_, name) => {
    if (!blobs[name]) throw new Error(`no uploaded asset for ${name}`);
    return blobs[name];
  });
  if (/x-char|x-waves|\.\.\/real/.test(html)) throw new Error(`${f.file}: unconverted markup`);
  fs.writeFileSync(path.join(P, f.dc), head(f.title) + html + tail({ $preview: { width: W, height: H } }));
}

// ---------- Waves.dc.html
const waves = head('DayXero landscape (Waves)') +
  `<div style="width: ${W}px; height: ${H}px; position: relative; overflow: hidden">\n${ctx.WAVES_TEMPLATE}\n</div>` +
  tail({ frame: { editor: 'int', default: 1, min: 1, max: 10 }, $preview: { width: W, height: H } },
    `  // One continuous landscape across the ten frames; "frame" picks this artboard's 1320 px slice, so the
  // layers meet at every seam. The same function as src/waves.js in the repository.
  renderVals() {
    const DX_WAVES = ${fnSrc.replace(/\n/g, '\n    ')};
    return DX_WAVES(Number(this.props.frame) || 1);
  }`);
if (waves.includes("'</script")) throw new Error('script terminator in waves');
fs.writeFileSync(path.join(P, 'Waves.dc.html'), waves);

// ---------- Char.dc.html, the designer's component, verbatim
fs.copyFileSync(path.join(SRC, 'canvas/Char.dc.html'), path.join(P, 'Char.dc.html'));

// ---------- canvas.json
const boards = {}, order = [];
frames.forEach((f, i) => { boards[f.dc] = { x: i * (W + GAP), y: 0, w: W, h: H, title: f.board }; order.push(f.dc); });
const row2 = H + 240;
boards['Char.dc.html'] = { x: 0, y: row2, w: 300, h: 330, title: 'Crew component (Xero, Jelli, Glim)', is_interactive: true };
boards['Waves.dc.html'] = { x: 380, y: row2, w: W, h: H, title: 'Landscape component (Waves · frame 1–10)' };
order.push('Char.dc.html', 'Waves.dc.html');
const rowW = frames.length * (W + GAP) - GAP;
const canvas = {
  v: 3,
  createdOnFiles: { v: 1, at: process.env.CANVAS_AT || new Date().toISOString().replace(/\.\d+Z$/, 'Z') },
  title: 'DayXero App Store screenshots · Meet the crew',
  launch: { view: 'canvas' },
  pages: [],
  boards,
  order,
  notes: {
    title: { x: 0, y: -340, text: 'DayXero · App Store screenshots · Meet the crew (iPhone 6.9″, 1320×2868)', kind: 'title1', maxW: rowW },
    spec: {
      x: 380 + W + GAP, y: row2, w: 560, fill: 'orange',
      text: 'App Store: iPhone 6.9″ 1320×2868 (these artboards, 1:1) and 6.3″ 1206×2622; up to 10, PNG or JPEG, RGB with no alpha. ' +
        'Story: hook and the crew → the 7-day plan → Xero, your days → daily cards → Jelli, your waves → after a slip → Glim, your evenings → calm tools → progress → your Day Xero is waiting. ' +
        'Frames 1–3 must read on their own at 230 px wide in search. No prices, "free", trials, ratings, "#1" or success claims in captions; frames 1 and 10 carry "Requires a DayXero Pro subscription." ' +
        'Every phone is a real CI capture of main 6498929 (swap the image, never redraw app UI). Crew: the Char component (who, expr). Landscape: the Waves component, one continuous scene; each artboard shows its own slice (frame 1–10), so the waves meet at the seams. ' +
        'Upload-ready PNGs: repo design/app-store-screenshots/directions/e-crew-story, run node src/render.mjs (same markup, bundled fonts, RGB without alpha). Share › Export from here is fine for review.'
    }
  },
  designSystems: []
};
fs.writeFileSync(path.join(P, 'canvas.json'), JSON.stringify(canvas, null, 1) + '\n');
console.log(fs.readdirSync(P).map((f) => `${f}  ${fs.statSync(path.join(P, f)).size} B`).join('\n'));
