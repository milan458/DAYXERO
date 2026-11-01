# Screen Lab: how screens and elements are written

The Screen Lab (`tools/screen-lab/`) shows every DayXero screen in an iPhone frame and lets Milan change any element through dropdowns. Changes are saved with the published page (the `changes` collection of its database) and Claude builds them into the Swift code later.

Everything is plain browser JavaScript, with no build step. Files load in this order:

1. `lab.js`: tokens, registries and the renderer.
2. `art.js`: illustrations.
3. `elements.js`: design-system elements.
4. `screens/manifest.js`: the list of screen files.
5. Each `screens/<name>.js` in the order the manifest lists them.

## Fidelity rules

- **The Swift code is the source of truth.** Copy sizes, paddings, gaps, radii, colours, fonts and copy exactly from the view's `body`. When the Swift uses `DX.Layout.gutter` (20) or `DX.Space.m` (16), use those numbers.
- **Copy is the app's real copy,** taken from the Swift or from the JSON it reads (`DayXeroCore/Resources/*.json`). Never invent product facts. Text that depends on data uses the persona Sam (see `design/handoff/tokens.json` → `persona`):
  - Quit Day: Fri 6 Nov 2026.
  - 12 cigarettes a day, plus a vape.
  - Triggers: Coffee and Stress.
  - Reason: "To keep up with Maya at the park".
  - Day 3 is Sun 8 Nov.
  - Use the `codeTrue` numbers.
- **Dropdown alternatives.** Each `text` prop's dropdown shows the app copy first. Add `alts` only when they are real alternatives, such as the other strings the same Swift switch can produce (other states, other days). Don't add made-up suggestions.
- **Visual constraints:**
  - No emoji.
  - Nothing smaller than 12 pt.
  - Characters speak as "I".
- **Unknown values.** When a value can't be known (a live number), use the persona value and say so in the screen's `note`.

## A screen

```js
Lab.screen({
  id: 'today',                       // letters, digits, hyphens; used in the URL (#s-today) and saved change keys — never rename
  name: 'Today',                     // shown in the picker
  area: 'Today',                     // picker group: Onboarding, Today, Program, Sessions, SOS, Evening, Progress, Me, Paywall, Sheets…
  source: 'DayXero/Home/HomeView.swift',
  ground: 'apricot',                 // the screen's background ground (Lab.groundNames)
  tab: 'today',                      // floating tab bar selection, or omit for screens without the tab bar
  fullBleed: false,                  // true when the screen draws under the status bar itself (then add your own top padding)
  note: 'Numbers are Sam on Day 3.', // optional, shown in the inspector
  statusInk: (state) => '#FFF8EE',   // optional: status bar ink (string or function of state); homeInk likewise for the home indicator
  states: [                          // Sam's day: each a real app state; first is the default
    { id: 'prep', label: 'Prep · Mon 2 Nov' },
    { id: 'day3', label: 'Day 3 · Sun 8 Nov' },
  ],
  build(h, state, Lab) {             // returns one node or an array of nodes
    return h('stack', 'body', { padX: 20, gap: 16 }, [
      h('markedTitle', 'title', { lead: 'Your ', word: 'program', mark: 'underline' }),
      state.id === 'prep'
        ? h('text', 'next', { step: 'footnote', tone: 'muted', text: 'Quit Day in 4 days' })
        : h('text', 'next', { step: 'footnote', tone: 'muted', text: 'Day 3' }),
    ]);
  },
  overlay(h, state, Lab) { ... },    // optional: nodes drawn above the scroll (sheets, floating buttons)
});
```

- **Building nodes:** `h(type, id, props, kids)` builds a node.
- **Ids:**
  - Ids must be unique within the screen and stable. Saved changes are keyed by `screen id + node id + prop`.
  - Use readable ids such as `'top-card'`, `'tile-W1D2'` or `'title'`.
  - Give a node the same id in every state when it's the same element.
- **Alternative copy:** `props.alts = { title: ['Other copy', '...'] }` adds alternative copy to that prop's dropdown.
- **What can be changed:**
  - Everything the user can see should be an element with props, so it can be changed.
  - Use `stack` and `row` for layout, `text` for words, `art` for every illustration and character, and the specific element for cards, buttons and rows.
  - `html` (hidden from the library) takes `{ fn: (ctx) => '<svg…>' }`. Use it only for fixed drawing such as a chart grid.
- **Screen frame:**
  - The content area gets top padding for the status bar (62) unless `fullBleed` is set.
  - It gets bottom padding for the home indicator, plus 96 when there is a tab bar.

## An element

Elements that only one area uses go in that area's screen file, registered before the screen. Elements shared by several screens go in `elements.js`.

```js
Lab.element({
  type: 'programTile',               // unique across the lab
  name: 'Program session tile',      // human name shown in the inspector and library
  group: 'Program',                  // library section
  source: 'DayXero/Program/ProgramView.swift',
  description: 'One session: kit illustration, kicker, title, done or lock badge.',
  props: {
    title:  { label: 'Title', kind: 'text', default: '' },
    art:    { label: 'Illustration', kind: 'art', default: 'kit:dawn' },
    state:  { label: 'State', kind: 'select', default: 'locked', options: [['done','Done'],['today','Today'],['locked','Locked']] },
    radius: { label: 'Corner radius', kind: 'number', options: [18, 24, 28], unit: ' pt', default: 24, global: true },
  },
  examples: [{ label: 'Today', ground: 'mint', props: { title: 'The noisy passengers', state: 'today' } }],
  render(p, ctx, kids, node) { return `<div …>…</div>`; },   // ONE root element; HTML string
});
```

### Prop kinds

Each prop kind gets its own dropdown:

| Kind | Dropdown |
|---|---|
| `text` | The app copy, plus `alts`, plus "Write your own…" |
| `select` | `options` given as `[[value, label], …]` |
| `number` | `options` numbers (with `unit`) |
| `bool` | `labels: ['Show','Hide']` |
| `ground` | The 12 grounds |
| `colour` | The palette, including `'ink'` and `'muted'` |
| `type` | The seven type steps |
| `art` | Every illustration, as values like `kit:<kind>`, `person:<pose>`, `<character>:<mood>`, `scene:horizon`, `scene:calmHeader` or `none` |
| `kit` | Kit kinds only |
| `pose` | Person poses only |
| `icon` | The icon names in `lab.js` |

- **App-wide props:** `global: true` makes a prop editable from the Element library. A change there applies everywhere the element is used.
- **Show/Hide:** every element gets a `visible` prop automatically.

### Context and helpers

The `ctx` passed to `render` carries:

- `ctx.g`: the ground resolved for the appearance. It has `bg`, `ink`, `muted`, `card` (the card-on-colour fill) and `creamInk`.
- `ctx.dark`, `ctx.groundName` and `ctx.state`.
- `ctx.with({ groundName })`: a context for content that sits on another ground.

`kids(patch?)` renders the children. Pass `{ groundName }` when the children sit on a different ground.

Helpers:

- `Lab.text(step, str, ctx, { tone:'muted', color, align, upper, size, weight, style })`
- `Lab.font(step, {size, weight})`
- `Lab.icon(name, size, colour)`
- `Lab.art(value, { width, height, radius, shirt })`
- `Lab.c(Lab.fill.surface, ctx.dark)`
- `Lab.colour('ink'|'muted'|'green'|hex, ctx)`
- `Lab.buttonColours(kind, ground, dark)`
- `Lab.esc(str)`
- `Lab.render(Lab.h(...), ctx)`, to draw another element inside yours (pass `Object.assign(ctx.with({}), {inert:true})` so it isn't separately selectable)

### Writing renderers

- Escape every string with `Lab.esc`.
- Use flex and gap.
- No external images. Draw with SVG or `Lab.art`.
- Colours come from `ctx`, so dark mode works.

## Adding the file

Add the file name, without `.js`, to `screens/manifest.js`.

## Checking a screen

Run `node tools/screen-lab/check.js`. It renders every screen in every state, in light and dark, and fails on:

- a render error
- an unknown element
- a duplicate node id
- a missing copy string
