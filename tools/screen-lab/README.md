# DayXero Screen Lab

The Screen Lab shows every DayXero screen in an iPhone 17 Pro frame. You can change anything on a screen through dropdowns, including:

- the words
- the background colour and wallpaper
- the illustrations and characters
- buttons and cards
- show or hide

Each element is a web copy of its SwiftUI view. The sizes, colours, type and copy come from the Swift files named in the inspector. It's a careful copy, not the app itself, so TestFlight is still the final check.

## Using it

1. Pick a screen. On narrow windows the screen dropdown sits at the top.
2. Pick Sam's day if the screen has more than one state.
3. Tap anything on the phone, or pick it from "Everything on this screen".
4. Change it with the dropdowns on the right. Each element and the screen also have a **Colours** section, where background, text, secondary text and the cards inside are set separately for light mode and dark mode. Colours on a box apply to that section and everything in it. Use the dropdown, the colour picker beside it, or "Write your own colour…".
5. Each colour row says which mode is on screen; "Show dark" flips the phone. A changed setting is outlined. "Undo all changes here" puts the element back.
6. Use **Element library** to see every building block and the screens that use it. Settings there apply app-wide.
7. Use **Changes** to see everything you changed, from what to what.

## How changes reach the app

On the published page, every change is saved to the page's database: the `changes` collection, plus `notes` for the free-text note on each screen. Opened as a local file, changes stay in that browser. Use "Copy as text" on the Changes view to pass them on.

To build them, ask Claude to "build my Screen Lab changes". Claude then:

1. reads the collection;
2. edits the Swift named in each change's `source`;
3. opens a pull request;
4. sets each built change's `status` to `built`.

A change document looks like this:

```json
{ "scope": "node", "screen": "today", "screenName": "Today", "node": "top-card", "element": "topCard",
  "elementName": "Top card", "prop": "title", "label": "Title", "from": "The noisy passengers",
  "to": "Noisy thoughts", "status": "open", "at": "2026-11-01T10:00:00Z" }
```

`scope` is one of three values:

- `node`: one element on one screen. Colour props are `bgLight`/`bgDark`, `inkLight`/`inkDark`, `mutedLight`/`mutedDark` and `cardLight`/`cardDark`; empty means "as designed".
- `screen`: the screen's colour set, wallpaper or light/dark colours.
- `library`: an element's app-wide setting.

## Running it locally

```sh
cd tools/screen-lab && python3 -m http.server 8080   # then open http://localhost:8080
node tools/screen-lab/check.js                        # render every screen and state, light and dark
```

## Adding or updating a screen

See [FORMAT.md](FORMAT.md). When a SwiftUI screen changes, update its `screens/*.js` file in the same pull request so the lab stays one-to-one with the app.
