# DayXero — Handoff: Widgets and Controls

Owner: Milan · Written: 26 Oct 2026 · Platform: iOS 18+ (Liquid Glass rendering on iOS 26), WidgetKit, App Intents, ControlWidget

Read alongside `DAYXERO_V1_HANDOFF.md` (tracker rules), `DAYXERO_NOTIFICATIONS_WATER_HANDOFF.md` (water model, `WaterPillView`, craving predictor, Live Activities) and `DAYXERO_BIO_ORB_SPEC.md` (orb colours).

---

## 0. Start here

### 0.1 Reference files — signed off

Unzip `dayxero_widgets_reference.zip` into the repo so the files land in `reference/widgets/`. Open them in Safari on a Mac, online (fonts load from Google Fonts).

| File | What it shows |
|---|---|
| `WgHome.html` | Home Screen widgets, full colour: Day counter, Craving SOS, Today, Water, Craving forecast |
| `WgHomeClear.html` | The same widgets in clear and tinted mode |
| `WgLock.html` | Lock Screen: inline, rectangular forecast, circular water gauge, circular SOS |
| `WgLockPrivate.html` | Lock Screen privacy mode |
| `WgControl.html` | Control Center controls, and the SOS control in the Lock Screen button slot |
| `WgStandBy.html` | StandBy (844 × 390) |

Milan signed these off on 26 Oct 2026, after his changes to the Day counter, SOS, Today and Water widgets. **Build them exactly as drawn.** No new mockup round. When built, post screenshots of every widget in every rendering mode next to the references in the tracker for him to confirm.

The StandBy Day counter keeps its ring (the Home Screen Day counter does not). Milan may still change this; it's a small edit if he does.

### 0.2 Tracker changes

Add a new **Section 17 · Widgets and controls** and build it before Section 16 (QA). Note on every task: "from DAYXERO_WIDGETS_HANDOFF.md". Mark S7.9 (water widget and control, from the notifications and water handoff) and the widget and control parts of S6.5 superseded by these tasks.

- S17.1 Shared widget data snapshot in the App Group, and reload rules (section 2)
- S17.2 App Intents: Log water, Open SOS, Start breathing, Guard next window (section 3)
- S17.3 Custom SF Symbols: wave, pill, ring, shield (section 3.2)
- S17.4 Day counter widget: small, inline, StandBy (4.1)
- S17.5 Craving SOS widget: small and circular (4.2)
- S17.6 Today widget: medium (4.3)
- S17.7 Water widget: small and circular (4.4)
- S17.8 Craving forecast widget: small and rectangular (4.5)
- S17.9 Controls: Craving SOS, Log water, Breathe, Guard 30 min (section 5)
- S17.10 Rendering modes: full colour, tinted/accented, clear, vibrant (section 6)
- S17.11 Privacy mode setting and redaction (section 7)
- S17.12 Phase and empty states (section 8)
- S17.13 Widget gallery names, descriptions and previews (section 9)

### 0.3 Rules for every widget

1. **Wins only.** Never show an empty, zero or broken-streak state. Slips don't change anything a widget shows.
2. **Act without opening.** Buttons run App Intents in the background wherever possible.
3. **No animation.** Widgets can't animate. The pill shows a still level; counters still tick because iOS updates timer text by itself.
4. **On the device.** Widgets read a local snapshot; nothing is fetched from a network.

---

## 1. Visual tokens (shared)

| Token | Value |
|---|---|
| Widget background | `#070806` via `.containerBackground(for: .widget)` |
| Corner radius | System-provided (don't draw your own) |
| Sage | `#BCC388` |
| Moss | `#43511C` |
| Lens | `#070A04` |
| Primary text | white |
| Secondary text | white @ 0.55 |
| Labels (eyebrows) | JetBrains Mono SemiBold 10, tracking 0.8, uppercase |
| Numbers | Inter ExtraBold, tight tracking as listed per widget |
| Body | Inter Medium / SemiBold |
| Buttons | Capsule, 34 pt tall in small widgets |

Bundle Inter and JetBrains Mono in the widget extension too (the app already bundles them per the orb spec).

---

## 2. Data and refresh (S17.1)

- **`WidgetSnapshot`** (Codable, written to the App Group by the app after every relevant change): phase (prep / quit / post-program), quitDate, prepDay, daysFree, currentDayStart, moneyKept and currency, cravingsRidden, waterCountedMl, waterGoalMl, glassesToday, glassesGoal, lastDrinkId, nextWindow (start, end, triggerLabel, confidence, or nil), nextLesson (title, minutes, or nil), privacyMode, updatedAt.
- Keep the snapshot small and never put free text from logs or check-ins in it.
- **Reload:** after any use, craving, slip, water log, lesson completion, settings change or predictor recompute, call `WidgetCenter.shared.reloadTimelines(ofKind:)` for the affected kinds (not `reloadAllTimelines` every time).
- **Timelines:**
  - Counters use `Text(currentDayStart, style: .timer)` or `.relative`, so they tick with no reloads.
  - Add a timeline entry at the user's day boundary (handoff S11.3) so "12 days free" becomes 13 on time.
  - Forecast: entries at the window start and end, and a refresh after the window ends.
  - Policy `.atEnd`, plus the day-boundary entry. Stay well inside the system refresh budget.

---

## 3. App Intents and symbols (S17.2, S17.3)

### 3.1 Intents

| Intent | Used by | Behaviour |
|---|---|---|
| `LogWaterIntent` (amount defaults to the last drink, else 250 ml) | Water widget +1, Today water button, circular water gauge, Log water control, Siri/Shortcuts | Writes a `WaterEntry` (source: widget or controlCenter), updates the snapshot, reloads widgets, updates any running Live Activity. Haptic where the system allows. |
| `OpenSOSIntent` (opens the app) | SOS widget, Today SOS button, circular SOS, Craving SOS control, Lock Screen button | Opens straight into Craving SOS (deep link), which starts the SOS session and its Live Activity |
| `StartBreathingIntent` (`LiveActivityIntent`) | Breathe control | Starts the Breathing Live Activity without opening the app (notifications and water handoff B3.2), using the user's default pattern |
| `GuardWindowIntent` (`LiveActivityIntent`) | Forecast "Guard it", Guard 30 min control | Starts the Craving Window Guard Live Activity for the next predicted window, or for the next 30 minutes if none is predicted (handoff B3.4) |

Intents that write data must work with the app not running. Lock Screen taps may require the device to be unlocked; let the system handle that.

### 3.2 Custom SF Symbols

Controls need SF Symbol images. Export these as custom symbols (template SVGs in the asset catalog) from the reference drawings:
- `dx.wave`: the craving wave line (SOS)
- `dx.pill`: the capsule with a fill (water)
- `dx.ring`: the double ring (breathe, privacy SOS)
- `dx.shield`: the shield with a ring (guard, forecast)

---

## 4. Widgets — exact specs

Sizes are the system's; values below are for the standard iPhone sizes (small 170 × 170, medium 364 × 170). Scale padding proportionally on other devices.

### 4.1 Day counter (S17.4) — `systemSmall`, `accessoryInline`, StandBy

**Small (Home Screen):**
- No ring. Content vertically centred, leading-aligned, padding 16 top/bottom and 18 sides.
- "12": Inter ExtraBold 76, tracking −3, line height 0.9, white.
- "Days free": Inter SemiBold 17, sage, 8 below the number.
- Accessibility: "12 days nicotine-free" (or "12 days" in privacy mode).

**Inline (Lock Screen, beside the date):** ring symbol (`dx.ring`) then "Day 12 · $84 kept". Privacy mode: "Day 12".

**StandBy** (detect with `\.showsWidgetContainerBackground == false`):
- Ring glyph (the orb drawing at 206 pt: halo, moss and sage rings, white filament, dark lens) with the day count in the lens (Inter ExtraBold 50).
- Beside it: "DAYS FREE" (JetBrains Mono SemiBold 12, tracking 1, sage); the time into the current day as a ticking timer (Inter ExtraBold 40, tracking −1), e.g. "6:42:18"; "into day 13" (Medium 14, white @ 0.55); 14 below, "$84" (ExtraBold 22) "kept" (Medium 14, white @ 0.55).
- StandBy night mode renders in red; let the system handle it, and check it stays legible.

### 4.2 Craving SOS (S17.5) — `systemSmall`, `accessoryCircular`

**Small:**
- Orb centred horizontally, its centre **60 pt from the top** of the widget: halo (radial, moss @ 0.5 at 30% fading to transparent, radius 58); glow ring (sage, width 12, @ 0.5, blurred 4); moss ring width 11; sage ring width 4.5; white filament width 1.4 @ 0.92 at radius 33.2; ring radius 34; lens radius 25 `#070A04`; "SOS" in the lens, Inter ExtraBold 13, white.
- Bottom-aligned stack, padding 14: "Craving?" (SemiBold 13, white @ 0.7), then 6 below, a full-width 34 pt capsule button, sage, "Ride it out" (SemiBold 14, black) → `OpenSOSIntent`.
- The whole widget also deep-links to SOS.

**Circular (Lock Screen):** `AccessoryWidgetBackground`, ring symbol (30 pt) over "SOS" (Bold 11, tracking 0.6). Privacy mode: ring only, no label; VoiceOver label "Open DayXero help". Tap → `OpenSOSIntent`.

### 4.3 Today (S17.6) — `systemMedium`

Padding 14 top, 14 right, 12 bottom, 16 left.

- **Left column, 92 wide, centred vertically and horizontally** (equal space above and below as one group): "DAY 12" (eyebrow, sage) · 6 below "$84" (Inter ExtraBold 32, tracking −1) · 3 below "kept" (Medium 12, white @ 0.55).
- 14 pt gap, then a 1 pt divider (white @ 0.1), then 14 pt gap.
- **Middle column, flexible:** three rows spread evenly top to bottom, 13 pt: label left in white @ 0.6, value right in SemiBold white. Rows: "Cravings ridden out · 31", "Water · 6 / 11", "Next window · 3:00 pm" (if no window predicted: "Water goal · 11 glasses" instead of the window row; never an empty row).
- **Right:** two 48 pt circles stacked with 8 pt gap, vertically centred: sage circle with black `dx.wave` (→ `OpenSOSIntent`); white @ 0.10 circle with sage water drop (→ `LogWaterIntent`).
- **Footer:** 10 above a 0.5 pt divider (white @ 0.1), 10 below it: "NEXT" (mono 10, white @ 0.45), the lesson title (SemiBold 13), "· 2 min" (white @ 0.5). After the program ends: "Weekly summary on Sunday" or the next milestone instead.

### 4.4 Water (S17.7) — `systemSmall`, `accessoryCircular`

**Small:**
- Padding 14 top, right and bottom, 12 left; 20 pt gap between the pill and the text column.
- **Pill** (static `WaterPillView` glyph variant): 52 × 96 capsule, vertically centred in a 56 × 142 area; empty `#0C0F08`; outline 1.5 pt white @ 0.75; highlight bar 4 × 64 at x 9, white @ 0.18; liquid with the last drink's gradient (water `#E9EECF` → `#9DA66A`), level = glasses today / goal, with a still wave (wavelength 28, amplitude 2) on top.
- **Text column:** "WATER" (eyebrow, white @ 0.5) at the top; then, bottom-aligned: "6" (Inter ExtraBold 34) and, 4 pt after it, "/ 11" (Inter Bold 17, white @ 0.5); "glasses" (Medium 12, white @ 0.55); 10 below, a full-width 34 pt sage capsule "+1" with a plus icon (→ `LogWaterIntent`).
- At goal: number in sage and the button reads "+1" still (logging past goal is allowed). No other change.

**Circular (Lock Screen):** `Gauge` with `.accessoryCircular` style: a 270° arc (background white @ 0.28, value white), the `dx.pill` symbol over "6/11" (Bold 13). Tap → `LogWaterIntent`.

### 4.5 Craving forecast (S17.8) — `systemSmall`, `accessoryRectangular`

**Small:**
- Top row: `dx.shield` (18 pt, moss @ 0.5 fill, sage outline) and "NEXT WINDOW" (eyebrow, white @ 0.5).
- Bottom-aligned: "3:00" (Inter ExtraBold 34, tracking −1) with " pm" (16, white @ 0.5); "After lunch · in 2h 40m" (Medium 12, white @ 0.55; the "in …" part is a relative timer); 10 below, a 34 pt capsule "Guard it" (sage @ 0.16 fill, 1 pt sage @ 0.5 border, sage SemiBold 14) → `GuardWindowIntent`.
- During a window: "NOW" eyebrow, "until 3:40", button "Guarding ✓" disabled if a guard is running.

**Rectangular (Lock Screen):** shield (14 pt) and "Next window" (SemiBold 12 @ 0.8); "3:00 pm" (Bold 22); "After lunch · in 2h 57m" (Medium 12 @ 0.75). Privacy mode: title "Heads-up", subline "in 2h 57m" only, no trigger.

---

## 5. Controls (S17.9) — see `WgControl.html`

`ControlWidgetButton`s, available in Control Center, on the Lock Screen button slots and on the Action button.

| Control | Symbol | Tint | Intent | Size shown |
|---|---|---|---|---|
| Craving SOS | `dx.wave` | Sage | `OpenSOSIntent` | Medium (icon + "Craving SOS" + "DayXero") |
| Log water | `dx.pill` | Default | `LogWaterIntent` | Small, label "Log water" |
| Breathe | `dx.ring` | Default | `StartBreathingIntent` | Small, label "Breathe" |
| Guard 30 min | `dx.shield` | Default | `GuardWindowIntent` | Medium |

In onboarding's final screen or the Settings widgets section, show a short "Add Craving SOS to your Lock Screen" tip with a picture of the Lock Screen button slot. Don't nag; show it once.

---

## 6. Rendering modes (S17.10)

Read `\.widgetRenderingMode` and design each widget for all three:

- **Full colour:** exactly as `WgHome.html`.
- **Accented (tinted and clear Home Screens):** match `WgHomeClear.html`. All sage and moss become white or the system tint; the pill liquid becomes a flat white fill at 85%; lens becomes black @ 0.28. Mark the key glyphs (ring, pill fill, shield, number) with `.widgetAccentable()` so they pick up the tint. Use `.widgetAccentedRenderingMode(...)` where it helps.
- **Vibrant (Lock Screen, StandBy at night):** white only, as `WgLock.html`; use `AccessoryWidgetBackground` for circular widgets.

Check every widget in each mode on device; the ring and pill shapes must stay readable without colour.

---

## 7. Privacy mode (S17.11)

- Setting in Settings › Widgets: "Privacy mode on the Lock Screen", default **off**, with an explanation: "Hides money and the word nicotine from widgets anyone can see."
- When on, the Lock Screen widgets switch as in `WgLockPrivate.html`: inline "Day 12"; forecast "Heads-up · in 2h 57m"; SOS is a plain ring. Home Screen widgets are unchanged unless the user also turns on "Apply to Home Screen".
- Independently, mark money values with `.privacySensitive()` so iOS redacts them when the user's system setting hides sensitive widget data on a locked phone.

---

## 8. Phase and empty states (S17.12)

| Situation | Day counter | Today | Forecast | Water |
|---|---|---|---|---|
| Before Day 1 lesson | "Day 1" with "Starts today" | Next lesson only; stats hidden | "Learning your patterns" + "Log cravings to unlock" | Default goal (2.0 L) |
| Prep, Days 1–6 | "Prep · Day 3" and "Day Xero in 4 days" | Prep stats (cravings ridden out, water) | Practice windows from use logs | Normal |
| Day Xero onward | Days free | As specced | As specced | Normal |
| No predicted window today | — | Water goal row instead | "No risky windows predicted today" with a quiet ring, no button | — |
| After a slip | Unchanged | Unchanged | Unchanged | Unchanged |

Never show zero as a failure ("0 days" is shown as "Day Xero" on Quit Day).

---

## 9. Gallery entries (S17.13)

| Widget | Display name | Description |
|---|---|---|
| Day counter | Days free | Your days nicotine-free, at a glance. |
| Craving SOS | Craving SOS | One tap to ride out a craving. |
| Today | Today | Days, money kept, water and your next lesson. |
| Water | Water | See today's water and log a glass. |
| Craving forecast | Craving forecast | Your next likely craving, and a one-tap guard. |

Provide preview snapshots with realistic sample data matching the references.

---

## 10. Done when

- [ ] Every widget matches its reference side by side in full colour, accented/clear and vibrant modes; screenshots posted to the tracker and confirmed by Milan.
- [ ] Day counter has no ring on the Home Screen; StandBy keeps the ring.
- [ ] SOS orb centre sits 60 pt from the top; Today's left column is centred with equal space above and below; Water has a 20 pt gap and the spaced "6 / 11".
- [ ] All buttons and controls work with the app killed; water logs update the tracker, Home, other widgets and any running Live Activity within a second.
- [ ] Counters tick without timeline reloads; the day count rolls over exactly at the user's day boundary.
- [ ] Privacy mode and `.privacySensitive()` verified on a locked device.
- [ ] Phase and empty states render as in section 8; no widget ever shows a failure or zero state.
- [ ] VoiceOver labels on every widget and control; text scales or truncates gracefully at large accessibility sizes.
- [ ] Widget gallery names, descriptions and previews in place.
