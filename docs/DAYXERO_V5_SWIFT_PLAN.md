# Build the v5 redesign in SwiftUI (restyle in place)

## Context
The UI redesign is done as HTML mockups. These live in `cook/site/`: the kit is `kit/kit.css`, `kit/kit.js` and `kit/chars.js`, plus 72 screen files. Each screen carries a `<meta name="motion">` spec. The summary is in `cook/FINAL.md` and the rules in `cook/site/GUIDE.md`. The mockups scored about 8.7 against the 6.5 baseline.

The iOS app already has a working SwiftUI design system, "v4", in `DayXeroCore/DesignSystem/`:
- `DX.Ground` grounds;
- `DX.TypeStep` with the bundled Bricolage Grotesque and DM Sans fonts;
- `DX.Move` motion;
- `Buttons4` with `HoldButton`;
- `Cards4`, and `Nav4` with `V4TabBar`;
- native Canvas characters: `XeroView`, `JelliView`, `GlimView` and `HorizonScene`, drawn from the original SVG paths.

It also has a screen for every flow: SwiftData models, roughly 37 logic files, widgets and tests.

The user chose:
- **restyle in place**: evolve v4 tokens and components into v5, then restyle the existing screens;
- **direct replace**, flow by flow;
- **Today and the tab bar first**.

The goal is for the shipped app to match the mockups in light and dark mode, including the motion specs, without touching logic, data or content.

## Approach

### Phase 0: v5 tokens (DayXeroCore, one PR)
Update the token layer so every existing call site picks up the new system. Nothing is renamed, so the widgets keep compiling.

**`DayXeroCore/DesignSystem/V4/Ground.swift`**
- New specs:

  | Ground | Light | Dark |
  |---|---|---|
  | apricot | `#FFC38A` | `#0E1322` |
  | mint | `#D3F0DF` | `#0E1322` |
  | ocean | `#1F3C8C` plus a gradient | `#0A1638` |
  | night | `#0F1B33` | `#0A1326` |
  | reading | `#FBF7F1` | `#0E1322` |
  | sun | (unchanged) | `#0E1322` |

  "Night" is the current `violet` case, which keeps its name but takes the night colours. Add a `table` case (light `#F6F0E6`, dark `#0E1322`). Move `sky` to the survivors of `resolved`, mapped to reading.
- Per-ground tokens, taken from `kit.css` `--card`, `--card-2`, `--line`, `--btn`, `--btn-fg`, `--track` and `--mark`.
- Selection tokens:
  - light: tint 20% `#FFB27A` over white, edge `#F26A45`;
  - dark neutral: 15% `#FFC89A` over card, edge `#FFB27A`;
  - ocean and night: cream edge.
- Done green becomes `#1F9D63`.
- Extend `V4TokenTests` with the new pairs and keep the 4.5:1 contrast checks.

**Other token files**
- `V4/TypeStep.swift`: footnote 15/500, caption 13/600, tracking from the kit table.
- `V4/Move.swift`:
  - `DX.Layout`: gutter 22, card radius 22, opt 18, field 16, chip 14, tabbar 28, sheet 30.
  - `DX.Move`: arrive 600ms with 90ms stagger, settle 900ms, pop 700ms spring, stamp 620ms, count 850ms ease-out cubic, ring 1400ms, breathe 4s/6s, bob 5s, float-up 1.4s, shine 1.4s.
- `Metrics.swift`: drop the duplicate button height (58 is the only one).
- Mark the `design/handoff/tokens.json` values that changed, or bump it to v5 to match `kit.css`. The kit is the source of truth.

### Phase 1: v5 components (DayXeroCore)
Port the kit components onto the existing files.

**`V4/Buttons4.swift`**
- `.dx(.primary)` is a 58pt pill with the kit shadow and a .98 press scale.
- Add `.ghost` and `.small` variants.
- `HoldButton` gets a left-to-right fill and a done state (green check plus label) that keeps the button colour.

**`V4/Cards4.swift` / `Components/Selection.swift`**
- One `DXChip`: 44pt high, radius 14, tint and 2pt edge when selected.
- One `DXOptionRow`: 64pt minimum, a radio, and a multi variant with a rounded-square check.
- `DXToggle`: coral when on, the 30% track when off.
- `DXCard` with a `.flat` variant.
- `DXList` and `DXRow` with a 40pt icon tile and a chevron.
- `DXField`.

**`V4/Nav4.swift`**
- `V4TabBar` becomes five slots: Today, Program, raised SOS (58pt circle `#1F3C8C`, label under it), Calm, Progress.
- Add a `tabFade` overlay: 150pt, ground at 0, 85% at 30% height, 100% at 40%.
- A nav row with a 44pt leading icon button and a centred title or progress.
- A `DXProgress` with a `.sun` variant (14pt amber dot with a rim).
- `DXDock` (in `Components/`): the bottom fade and the primary button area.

**Other components**
- `V4/Emphasis.swift`: the `dxMark` underline with the kit path `M3 10 C40 4 90 5 122 7 C152 9 178 11 197 4`. Coral on day grounds, gold on ocean, night and table.
- New `V4/Badge5.swift`:
  - `DXBadge(kind: .prep/.xero/.day/.wave/.night, n:, state: .earned/.next(p)/.locked, size:)`.
  - Ported from `kit.js` `badge()`: scallop edge for prep, face, art clip, numeral, the xero "zero" mark, progress arc and padlock.
  - Reuse `SVGPath.swift` for the path strings.
- New `V4/Ring5.swift`: `DXRing(p:, size:, stroke:, dot:)` with the sweep animation. Also `DXCheck`, a disc pop followed by the tick draw.
- New `Art/NightSky.swift`:
  - Port `DX.nightSky` from `kit.js`: three-stop sky, moon with halo or a dawn sun glow, 12 twinkling stars, three hills, four fireflies.
  - Draw it with `Canvas` and `TimelineView`, like `CrewCanvas`.
- `Art/HorizonScene.swift`: dark mode switches to `NightSky(dawn:)`, matching the kit's `charSvg`. Remove the "+" sparkle stars and turn ink marks cream in dark mode, as in the `charSvg` post-processing.
- Motion modifiers in `V4/Move.swift`:
  - `.dxArrive(i)` exists; add `.dxSettle`, `.dxPop`, `.dxStamp`, `.dxBob`, `.dxShine`, `.dxFloatUp("+1")` and `.dxBump`.
  - Add `CountingText` with from, prefix and decimals; it exists in `Cards4`.
  - Every modifier respects `MotionPolicy` and Reduce Motion.
- Haptics: map the specs' "light / success / soft impact" to the existing `DX.Haptic` and `HapticPlayer`.
- Update `DayXero/Gallery/V4Gallery.swift` (opened with `-dx.v4Gallery`) to show every v5 component in both modes. It is the visual check against `cook/stills/now/`.

### Phase 2: Today and tab bar (first flow)
Mockups 015 (prep morning), 016 (Day 7), 017 (lower Today), 018 (evening) and 022 (Program tab); stills are in `cook/stills/now/`.

- `Home/HomeView.swift`: add the Calm tab, which opens `Calm/CalmToolsView` as a tab. SOS keeps opening the cover. `DuoSupport` gets the same five items.
- `Home/TodayHero.swift`, `TodayView.swift`, `TodayTimeline.swift`, `TodayV4.swift` and `TodayCardsV4.swift`, restyled to match:
  - Prep variant (015): the hero knoll, session card and countdown stamps.
  - Quit variant (016): the 7-day badge hero, next-badge chip and "Now" peek.
  - Lower Today (017): the pinned header, Now card and Later list.
  - Evening (018): night ground with `NightSky`, Glim and the 7-night strip.
  - Data stays wired through `HomeSnapshot` and `TodayPlan`.
- `Program/ProgramView.swift` and `ProgramPathMap.swift` (022): the road with prep stamps (`DXBadge .prep`), the up-next card and Day Xero on the horizon.
- Motion follows each mockup's `<meta name="motion">` text. Copy the spec into a doc comment at the top of each view.

### Phase 3+: remaining flows, one PR each, in this order
1. **SOS** (019-021), in `SOS/` and `Orb/`.
2. **Onboarding and paywall** (000-014): `Onboarding/*`, `App/LaunchGrow.swift` for the 2.4 s launch and the new app icon in `Assets.xcassets/AppIcon` from `cook/site/icon/*.svg`, and `Paywall/PaywallView.swift`.
3. **Prep session** (023-032), in `ProgramV2/`, on the new `table` ground.
4. **Lessons, progress, health and milestones** (033-040): `ProgramV2/DeckViews`, `Progress/ProgressTab`, `Health/*` and `Milestones/*`.
5. **Log, slips, NRT, taper and pledge** (041-053): `Log/*`, `NRT/*` and `Daily/PledgeView`.
6. **Check-in** (054-055), **Calm** (056-060) and **Settings** (061-070): `Daily/CheckInView`, `Evening/*`, `Calm/*` and `Settings/*`.
7. **Widgets**: `WidgetViews/DXWidgetViews.swift` picks up the new tokens automatically; review the glyphs and grounds.

### Rules for every flow PR
- No logic, model or content changes. Copy that diverged in the mockups is listed in the PR for the owner to approve. Examples: the 038 timing copy and 066 "Day 1-7".
- Keep the open decisions out of scope: paywall charge date, a "Continue free" option, merging 011 into 012.
- Gutter 22, one primary button, no uppercase eyebrows, and a 13pt minimum text size.
- Characters stand on a ground; no stickers.

## Critical files
- **Tokens:** `DayXeroCore/DesignSystem/V4/Ground.swift`, `TypeStep.swift`, `Move.swift`, `Metrics.swift`
- **Components:** `V4/Buttons4.swift`, `Cards4.swift`, `Nav4.swift`, `Emphasis.swift`, `Components/Selection.swift`, `Components/Controls.swift`; new files `V4/Badge5.swift`, `V4/Ring5.swift`, `Art/NightSky.swift`
- **Art:** `Art/HorizonScene.swift`, `CrewDrawing.swift` (reuse `SVGPath.swift` and `ArtTrack.swift`)
- **Shell:** `DayXero/Home/HomeView.swift`, `App/DuoSupport.swift`
- **First flow:** `DayXero/Home/*`, `DayXero/Program/ProgramView.swift`, `ProgramPathMap.swift`
- **Specs:** `cook/site/kit/kit.css`, `kit.js` and `screens/015-018,022-*.html` (motion meta), with `cook/stills/now/*.png` as the visual reference

## Verification
- `xcodegen generate` then build `DayXero` for the iOS 18 simulator under Swift 6 strict concurrency. The widget target must also build.
- `DayXeroTests`, especially `V4TokenTests` for contrast with the new pairs, `CrewArtTests` and `HomeTests`.
- Visual parity:
  - Launch with `-dx.v4Gallery` and `-dx.scenario` / `-dx.tab` (see `App/DebugScenarios.swift`) to seed the persona state: Mon, Nov 2 prep; Fri, Nov 13 Day 7.
  - Screenshot light and dark on iPhone 17 and compare side by side with `cook/stills/now/<id>-light|dark.png`.
  - Check large text (Dynamic Type) and Reduce Motion.
- `DayXeroUITests/JourneyUITests.swift` passes, and CI `ios.yml` and `devices.yml` are green.
- On a device, check motion against each screen's `<meta name="motion">` timeline and haptics. The hold buttons and the SOS breath haptic matter most.
