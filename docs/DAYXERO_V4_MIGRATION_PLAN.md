# DayXero v4: SwiftUI migration plan

**Status:** draft for Milan's OK, 31 Oct 2026. **No Swift code changes until this plan is approved.**
**Source of truth for the design:** `design/handoff/DAYXERO_DESIGN_SYSTEM.md` (decisions 1–18) and `design/handoff/tokens.json`. Every screen is on the canvas "DayXero · v4 design system".

---

## 1. What changes and what doesn't

**Changes:** the look of the app. That means `DayXeroCore/DesignSystem/` (colours, type, motion, metrics, components), the view files in `DayXero/`, the widgets and the Live Activity, and two bundled fonts.

**Doesn't change:** the logic. `DayXeroCore/Logic/` and `DayXeroCore/Model/` stay as they are, except for the small product-logic changes the decisions require (§7). The program content (`program.json`), health copy (`health-timeline.json`), prices, slip rules and trigger list are untouched. All 23 existing test files must stay green.

**How far the old system reaches today** (counted 31 Oct):

| Token | Uses | Notes |
|---|---|---|
| `DX.Palette.*` | ~956 | `text` 158, `accentInk` 127, `sage` 102, `hairline` 89, `surface1` 85 |
| `.dxText(...)` | 306 | `subtitle` 149, `micro` 90, `title` 47 |
| `.custom(DX.Typeface…, size:)` | ~286 | 29 different sizes; 28 uses are 10 or 11 pt, below v4's 12 pt floor |
| `DX.Motion.*` | 52 | springs (`morph`, `press`) and `glide` |

So a find-and-replace would change about 1,600 call sites at once with no way to check each screen. The plan below avoids that.

---

## 2. Approach: build v4 next to the old system, then switch screen by screen

1. **Add** the v4 tokens and components under new names (`DX.Ground`, `DX.TypeStep`, `DX.Move`, …) without touching the old ones. The app looks the same after Phase 1.
2. **Rebuild one screen at a time** with only v4 tokens, matching its canvas board in light and dark.
3. **Remove** the old tokens once no screen uses them (Phase 8).

**Decided: no v4 switch (decision 19).** v4 is the new identity, so each finished screen replaces the old one on `main`. TestFlight shows a mixed look until the last phase.

**Branches and checks:**
- One branch per phase, then a PR into `main`.
- `ios.yml` runs on every pull request (macOS, Xcode 27.1): build plus all tests. That is the proof each step compiles. Claude's cloud machine is Linux and **cannot build or run the app**.
- You check the look on a phone through TestFlight (manual start in Xcode Cloud).

---

## 3. Phase 1: foundation (no visible change)

### 3.1 Colours → `Colors.swift`
- Add `DX.Ground`, one case per ground, with light and dark values from `tokens.json`:

  | Ground | Light | Dark |
  |---|---|---|
  | `coral` | #FF7A55 | #241433 |
  | `apricot` | #FFC38A | #241433 |
  | `lilac` | #D9CCFF | #1C1640 |
  | `mint` | #9FE3BC | #0F2A22 |
  | `ocean` | #2A52DB | #0B1A4A |
  | `sky` | #9CCBFF | #0F2550 |
  | `violet` | #4A3596 | #140E3A |
  | `sun` | #FFD966 | #241433 |
  | `reading` | #FBF7F1 | #0E0B2B |

- Each ground carries its `ink`, `muted`, `card`, `button` and `buttonInk`, so a screen asks for `ground.muted` and can't pick a colour that fails contrast.
- Add the fills: `green` #0F6E43/#2FD08A, `oceanSecondary` #1D3A9E/#1B2C66, `glimCard` #2A1C6E, `nightCard` #0E0B2B, `surf`, `raised` and the confetti set.
- Use the existing `Color(light:dark:)` helper, so appearance follows the phone automatically.
- **New test, `ContrastTests`:** computes the WCAG ratio for every text pair in design doc §5.3 and every ground's ink and muted colour, and fails under 4.5:1 (3:1 for 24 pt and up). A wrong hex then fails CI instead of shipping.
- Plum stays the dark ground for the warm screens, but is unconfirmed until your OLED check (decision 16). It is one value in one place, so changing it later is a one-line edit.

### 3.2 Fonts → `Resources/Fonts`, `Typography.swift`
- Add **Bricolage Grotesque** (display) and **DM Sans** (body). Both are Google Fonts under the OFL licence, which goes in next to the files like `Inter-LICENSE.txt`.
- **Variable font files** (decision 20): `BricolageGrotesque-Variable.ttf` (opsz 12–96, wght 200–800) and `DMSans-Variable.ttf` (opsz 9–40, wght 100–1000), about 650 KB together. Weight and optical size are set on the axes in `DX.Typeface4.font(_:size:weight:)`.
- Register them in `DX.Typeface.register()`. It already runs in the app and each extension.
- Add `DX.TypeStep` with the seven sizes, each tied to an iOS text style so Dynamic Type works:

  | Step | Size | Font | iOS style |
  |---|---|---|---|
  | `display` | 40 | Bricolage 800 | `.largeTitle` |
  | `large` | 32 | Bricolage 800 | `.largeTitle` |
  | `title` | 24 | Bricolage 800 | `.title2` |
  | `headline` | 19 | Bricolage 700 | `.headline` |
  | `body` | 16 | DM Sans | `.body` |
  | `footnote` | 14 | DM Sans | `.footnote` |
  | `caption` | 12 | DM Sans 700, +0.8 tracking | `.caption` |

  Tracking comes from `tokens.json`.
- Add a `.dxStep(_:)` modifier. Nothing below 12 pt exists in v4.
- Inter and JetBrains Mono stay until Phase 8. JetBrains Mono's 7 uses (numbers) move to Bricolage.

### 3.3 Motion → `Motion.swift`
- Add `DX.Move`:

  | Token | Spec |
  |---|---|
  | `arrive` | `timingCurve(0.2, 0.7, 0.2, 1, duration: 0.6)`, 18 pt rise, 0.09 s stagger |
  | `settle` | `timingCurve(0.2, 0.8, 0.2, 1, duration: 0.9)`, no overshoot |
  | `celebrate` | one spring, about 0.7 s, slight overshoot; only on Passed, milestones and the finale |
  | `breathe` | 4 s in, 6 s out |
  | `count` | 0.85 s ease-out |
  | `hold` | linear; 1.0 s pledge, 1.5 s Quit Day, 3.0 s Day Xero and Graduation, 2.0 s Prep 1 |

- Each token has a Reduce Motion fallback: show the final state, and turn breathing into a colour fade.
- Add helpers: `.arrive(index:)`, a `CountingText` view, and `BreathClock`, a `TimelineView`-driven phase shared by SOS, the intro and Jelli.
- Haptics stay as they are (`DX.Haptic`). The hold button adds `.commit` on completion.

### 3.4 Metrics → `Metrics.swift`
- Add a 58 pt primary button, 44–48 pt chips, card radius 18–24, 20–24 pt gutters, and `CharacterSize` avatar 40 / card 88 / scene 140 / hero 200.

### 3.5 Characters and scenes → `DayXeroCore/DesignSystem/Art/` (new)
- **Xero, Jelli and Glim become SwiftUI drawings**, not images. They need moods (hello, calm, breathe, cheer, sleepy), stages 1–4 and idle motion.
- The paths come straight from the canvas SVG (`Xero.dc.html`, `Jelli.dc.html`, `Glim2.dc.html`). Each becomes a `Shape` or `Canvas` view with `mood`, `stage`, `animated` and `size`.
- Idle motion is drawn per frame with `TimelineView(.animation)`. It stops when Reduce Motion is on or the view is off screen.
- `stage` comes from days clear (< 7 → 1, < 14 → 2, < 28 → 3, else 4). It lives in `DayXeroCore/Logic`, with a test.
- **Horizon and Hero scenes** (dawn, dusk, path, sea, night, with `clarity` 0–100) become layered SwiftUI shapes. Two effects get simpler: the paper "lift" becomes a SwiftUI shadow, and the grain becomes a small tiled noise image asset instead of the SVG turbulence filter.
- Clarity = 20 in prep, then `min(100, round(20 + 2.8 × days clear))`. It lives in Logic, with a test.
- A gallery page in `DayXero/Gallery/DesignSystemGallery.swift` shows every character, mood, stage and scene, so they can be compared with the canvas.

### 3.6 Components → `DayXeroCore/DesignSystem/Components/`
- These are design doc §6, built once:
  - `V4Button` (primary, secondary, quiet) and `HoldButton`. The hold button has a visible fill, a haptic, and an accessibility action so VoiceOver users double-tap instead of holding.
  - `StatTile` (counts up) and `TopCard`.
  - `DayRow`, `PlanRow` and `ProgramDayCard`.
  - `AnswerTray` and `ReplyBubble` (with Edit).
  - `BreathingWords` (real text, read out politely by VoiceOver), `HandOverChip` and `MoodFaces` (drawn, with text labels).
  - `HealthFactCard`, which takes the entry's own `source` label, not a fixed "American Cancer Society".
  - `NotificationPreview` and the lesson bar.
  - `Nav2`, the floating tab bar, for which §9 question 3 must be answered first.

**Phase 1 is done when:** CI is green, `ContrastTests` passes, the gallery page shows the new parts in light and dark, and the app is otherwise unchanged.

---

## 4. Phases 2–7: screens, in this order

Each screen is done when it:
- matches its canvas board in light and dark mode;
- works at the largest Dynamic Type sizes without clipping;
- has VoiceOver labels on every control and Reduce Motion end states;
- shows numbers from the real logic (`ProgressStats`, `ProgramUnlock`, …), never the mock values;
- keeps CI green.

| Phase | Screens (canvas boards) | Why this order |
|---|---|---|
| **2. SOS** | F13 SOS (Jelli, ocean), F14 Passed (sky), F15 Slip (reading) | The most important moment in the app, and small. It proves the characters, breathing clock and hand-over chip on one screen |
| **2. Today** | F08 Today (time-of-day host and top card), F09 Pledge, Nav2 | The screen people open every day. It uses most foundation parts |
| **3. Program** | F10 map, P1–P6 session flow, the beats kit (all 19 beat types), F12 Progress | The lesson frame is one component reused by every beat. The kit is the checklist |
| **4. Evenings** | F16 Check-in, F17 Wind down (violet, Glim) | Needs Glim and the check-in prefill from today's SOS sessions |
| **5. Onboarding and paywall** | F01–F07, Q1 Day Xero, Q2 You're on Day Xero, Q3 Quit Day offer | Needs the product-logic changes for decision 15 (§7) |
| **6. Finale and milestones** | F18, plus the milestone screens once designed | Celebrate motion and confetti only here |
| **7. Widgets and Live Activity** | `DayXeroWidgets`, `CravingActivity` (Jelli during SOS) | The extension has its own font registration and size limits |

**Screens still to be designed**, built after their boards exist: milestones, Insights, the health timeline detail, the NRT plan and NRT info, Settings, the reasons and photo editor, the Calm library, the widgets, and the empty, error and offline states.

The current app also has areas with **no v4 design at all**: Water (a Today card and a tracker), Toolkit, the Log sheet, Resources and the Bio-Orb (§9).

---

## 5. Phase 8: clean-up
- Delete the old screens once nothing routes to them.
- Delete the old palette, the `DX.TextStyle` sizes, the `morph`/`glide`/`press` springs, Inter and JetBrains Mono.
- Mark `docs/DESIGN_METHODOLOGY.md` superseded by v4 and update the README line that says it "overrides the plan on visual questions" (decision 14).
- Refresh the App Store screenshots (`store-screens.yml`).

---

## 6. What it touches, file by file

| Area | Files |
|---|---|
| Tokens | `DayXeroCore/DesignSystem/Colors.swift`, `Typography.swift`, `Motion.swift`, `Metrics.swift` |
| New | `DayXeroCore/DesignSystem/Art/` (characters, scenes), `DesignSystem/V4/`, `DayXeroTests/V4TokenTests.swift` |
| Components | `DayXeroCore/DesignSystem/Components/*` (new v4 parts beside the old) |
| Fonts | `DayXeroCore/Resources/Fonts/` (+ OFL licences), `project.yml` if resources need listing |
| Screens | `DayXero/SOS`, `Home`, `Program`, `ProgramV2`, `Progress`, `Daily`, `Onboarding`, `Paywall`, `Milestones`, … |
| Extensions | `DayXeroWidgets/`, `DayXeroCore/Shared/CravingActivity.swift`, `Intents/` |

---

## 7. Product-logic changes the decisions require (with tests)

1. **Free tier and trial on Quit Day (decision 15).**
   - `ProgramV2Access.freeSessions` becomes all of prep (P1–P7). It also includes DX, if you confirm the Day Xero session is free.
   - The paywall moves to after Day Xero (Q3), and the trial starts there.
   - Superwall and RevenueCat placements change accordingly.
   - `TrialReminder` already handles "2 days before" at 10:00.
2. **Today's host and top card by time of day.** Morning and afternoon are Xero on apricot; evening and night are Glim on violet. The top card follows the same split: wave prediction, lesson, check-in, wind down. This becomes a small pure function in Logic, with tests.
3. **Sky clarity and character stage** as functions of days clear (§3.5), with tests.
4. **Nothing else changes in behaviour:** day boundary (4:00 am), counters on elapsed time, unlock rules and slip rules all stay as the code has them (decision 17).

---

## 8. Risks
- **Characters drawn in code** are the biggest unknown. If the SwiftUI drawing of Xero looks wrong next to the canvas, the fallback is exporting each mood and stage as vector PDF assets and animating only the simple parts.
- **The mixed look in TestFlight** until the last phase: some screens v4, some old (decision 19).
- **Contrast in dark mode** depends on the exact hex values. `ContrastTests` covers text pairs but not art, so art is checked by eye on a device.
- **Nothing in the canvas has been rendered on a phone yet** (design doc §0.3). The first TestFlight build is also the first real look.

---

## 9. Decisions (answered 31 Oct 2026)

1. **No v4 switch.** v4 is the new identity; screens replace the old ones directly (decision 19).
2. **Fonts:** one variable Bricolage Grotesque file, and DM Sans variable too (decision 20).
3. **Tab bar:** v4 Nav2, Today · Program · SOS · Evening · Me. Progress and Settings under Me, calm tools under Evening, Water stays on Today (decision 21).
4. **SOS:** Jelli replaces the Bio-Orb (decision 22).
5. **Day Xero session:** free, with the offer after it (decision 23).

## 10. Progress

- **Phase 1a (this PR):** variable fonts and licences, `DX.Ground`, `DX.Fill`, `DX.TypeStep` with `.dxType(_:)`, `DX.Move` with `.dxArrive(_:)`, `DX.Layout`, `DX.CharacterSize`, and `V4TokenTests` (contrast for every ground pair, the 12 pt floor, Dynamic Type scaling, holds, the 4 s in / 6 s out breath). No screen uses them yet.
- **Phase 1b–1d (merged with 1a in PR #3):** the crew, scenes, components, Nav2 and the gallery. Decision 24 (Glim's glow).
- **Order change (31 Oct 2026, Milan):** screens are built a whole flow at a time, screenshotted once, then merged for TestFlight. Onboarding through Today comes first, ahead of SOS.
- **Phase 5 + Today (PR #4):** F01 Breathe, F02 Welcome, F03 questions as Xero's bubbles over an answer tray, F04 Quit Day with the hold, F05 the plan builds, F06 the plan is ready (no charge), F07 reminders, the F08 Today header and Nav2.
  - Logic: prep week and Day Xero are free (`ProgramV2Access`, `FreeTier`); no paywall after onboarding; the app's paywall is offered once after the Day Xero session until the v4 offer screen (G03) is built.
  - Where the canvas and the code differ, the code wins (decision 17):
    - prices come from the store;
    - the check-in reminder default is 21:00, not 21:30;
    - notification copy is `NotificationCopy`;
    - "I already have an account" is "Restore purchases", since there are no accounts;
    - Terms links to Apple's standard EULA, and Privacy is linked only once `AppLinks.privacy` is set;
    - the date line uses the app's own day count.
  - Not in the canvas:
    - F01 continues by itself after a second breath;
    - "Change the times" points to Settings.
  - Below the Today header, the cards (program, logging, streak, NRT, milestones, pledge and check-in) keep their current look until Phase 2. Evening and Me show the current Toolkit and Progress screens.
