#!/usr/bin/env node
// Builds bubbles.html from bubbles.src.html: each <crew name="Xero" mood="hello" stage="1" size="120"></crew> and
// <crew name="Hero2" scene="dawn" ...></crew> tag is replaced with the inline SVG the design canvas
// (design/handoff/canvas/project/*.dc.html) renders for those props. Run: node planning/mockups/S33/build.js
const fs = require('fs');
const path = require('path');

const CANVAS = path.join(__dirname, '../../../design/handoff/canvas/project');
const cache = {};

class DCLogic { constructor(props) { this.props = props; } }

function load(name) {
  if (cache[name]) return cache[name];
  const src = fs.readFileSync(path.join(CANVAS, `${name}.dc.html`), 'utf8');
  const body = src.split('<x-dc>')[1].split('</x-dc>')[0].replace(/<helmet>[\s\S]*?<\/helmet>/, '').trim();
  const script = src.match(/<script type="text\/x-dc"[^>]*data-props='([^']*)'>([\s\S]*?)<\/script>/);
  const defaults = {};
  for (const [k, v] of Object.entries(JSON.parse(script[1]))) if (!k.startsWith('$')) defaults[k] = v.default;
  const Component = new Function('DCLogic', `${script[2]}\nreturn Component;`)(DCLogic);
  return (cache[name] = { body, defaults, Component });
}

const lookup = (vals, key) => key.split('.').reduce((o, k) => (o == null ? '' : o[k]), vals);

function render(name, props) {
  const { body, defaults, Component } = load(name);
  const vals = new Component({ ...defaults, ...props }).renderVals();
  const filled = body.replace(/\{\{([^}]+)\}\}/g, (_, k) => String(lookup(vals, k.trim()) ?? ''));
  return expand(filled);
}

const attrs = (s) => Object.fromEntries([...s.matchAll(/([a-zA-Z-]+)="([^"]*)"/g)].map((m) => [m[1], m[2]]));

function expand(html) {
  return html.replace(/<dc-import ([^>]*)><\/dc-import>/g, (_, a) => {
    const { name, 'hint-size': _hint, ...props } = attrs(a);
    return render(name, props);
  });
}

const src = fs.readFileSync(path.join(__dirname, 'bubbles.src.html'), 'utf8');
const out = src.replace(/<crew ([^>]*)><\/crew>/g, (_, a) => {
  const { name, ...props } = attrs(a);
  return render(name, props);
});
// Published beside the tracker as its own page, so it carries its own document head.
const head = '<!doctype html>\n<html lang="en">\n<meta charset="utf-8">\n<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">\n';
fs.writeFileSync(path.join(__dirname, 'bubbles.html'), head + out);
console.log(`bubbles.html: ${(out.length / 1024).toFixed(0)} KB`);
