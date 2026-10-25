# DayXero — Handoff: Notifications, Live Activities and Water Tracker

Owner: Milan · Written: 26 Oct 2026 · Platform: iOS 18+, SwiftUI, ActivityKit, UserNotifications, App Intents, WidgetKit

**This file replaces `DAYXERO_NOTIFICATIONS_WATER_SPEC.md`.** Don't use the older spec; everything from it that still applies is in here, with the water changes Milan has since approved.

Read alongside `DAYXERO_V1_HANDOFF.md` (the overall plan and tracker rules) and `DAYXERO_BIO_ORB_SPEC.md` (the breathing orb this work reuses). Visuals follow `DESIGN_METHODOLOGY.md`, except where this file says something is signed off exactly as drawn.

---

## 0. Start here

### 0.1 Reference files

Unzip `dayxero_notifications_water_reference.zip` into the repo at `reference/`. Open the files in Safari on a Mac (they load Inter and JetBrains Mono from Google Fonts, so stay online).

| File | What it is | Status |
|---|---|---|
| `reference/water/water-pill-preview.html` | The pill water tracker, fully clickable: pick a drink, tap Log, watch it fill | **Signed off. Build it exactly as drawn.** |
| `reference/water/WOnbBody.html`, `WOnbDay.html`, `WOnbGoal.html` | The three water-goal onboarding screens (they link to each other) | **Signed off** |
| `reference/notifications/NLock.html` | Lock Screen notification stack | Design reference |
| `reference/notifications/NCraving.html` | Craving heads-up, expanded, with the mini orb | Design reference |
| `reference/notifications/NWater.html` | Water reminder, expanded, with tappable glasses | Design reference |
| `reference/notifications/NCheckin.html` | Evening check-in, expanded | Design reference |
| `reference/notifications/NMilestone.html` | Milestone, expanded, with share card | Design reference |
| `reference/notifications/NIsland.html` | Dynamic Island states (compact, minimal, expanded) | Design reference |
| `reference/notifications/NLiveLock.html` | Lock Screen Live Activities (Window Guard and Day Xero) | Design reference |

**Signed off** means Milan has approved the look: no fresh mockup round. Build it, then post a screen recording of the real app next to the reference in the tracker so he can confirm the match.

**Design reference** means build from it, then post screenshots of every built notification and Live Activity state in the tracker and set the section to `awaiting_signoff`. Close it only once Milan approves.

The orb drawings in the notification references are static approximations. The real mini orb comes from `BioOrbView` (orb spec).

### 0.2 Tracker changes

Add these tasks to `planning/tasks.json` with the note "from DAYXERO_NOTIFICATIONS_WATER_HANDOFF.md". If tasks from the old spec are already in the tracker, mark them superseded by these. Mark the handoff's original S14.1–S14.3 superseded too.

**Section 2 · Onboarding**
- S2.14 Water goal onboarding: three screens after S2.9 (NRT interest) and before S2.10 (plan reveal) (Part A, section 2)
- S2.15 Show the water goal in the plan reveal (S2.10)

**Section 7 · Logging and insights (water)**
- S7.5 Water data model, goal calculation and logging (A3, A4)
- S7.6 `WaterPillView`, the signed-off tracker, exactly as drawn (A5)
- S7.7 Water tracker screen (A6)
- S7.8 Water on Home: mini pill card with one-tap +1 (A7)
- S7.9 Water widget and Control Center control (+1 glass via App Intent) (A7)
- S7.10 Apple Health sync for water: optional, off by default (A7)
- S7.11 Water in Insights (A7)

**Section 6 · Craving SOS**
- S6.11 SOS Live Activity upgrade (B3.1)

**Section 12 · Stress toolkit**
- S12.5 Breathing Live Activity (B3.2)

**Section 14 · Notifications and Live Activities**
- S14.1 `NotificationPlanner`: scheduling, caps, merging, quiet hours, 64-pending limit (B4)
- S14.2 `CravingPredictor`: high-risk windows from logs (B4.3)
- S14.3 Notification categories, actions and App Intents for every type (B2)
- S14.4 Notification Content Extension with interactive expanded views (B2.2)
- S14.5 Rich attachments: lesson covers and milestone share cards
- S14.6 Day Xero all-day Live Activity (B3.3)
- S14.7 Craving Window Guard Live Activity (B3.4)
- S14.8 Live Activity manager: relevance, limits, clean-up (B3.5)
- S14.9 Phase-based cadence (B5)
- S14.10 Adaptive back-off (B4.4)
- S14.11 Analytics events and guardrails (B7)
- S14.12 `blocked` Milan to approve notification copy (B6 has the defaults; build with those)

**Section 15 · Settings**
- S15.7 Notification, Live Activity and water settings (B8)

### 0.3 Build order

1. S7.5 and S7.6 first: the water model and `WaterPillView` are reused everywhere (tracker screen, Home, widget, notification, Live Activities).
2. S2.14 and S2.15 (onboarding), then S7.7–S7.11.
3. Then Section 14 in task order, with S6.11 and S12.5 alongside the Live Activity tasks.
4. S15.7 last.

### 0.4 Principles (apply to every task)

1. **Earned, not sent.** Every notification must be useful at that exact moment. If in doubt, don't send it.
2. **Act without opening.** Most actions work from the notification, the Lock Screen or the Dynamic Island.
3. **Never guilt.** No streak-loss threats, no red badges, no "you haven't…". The app icon badge stays off.
4. **Fewer as people succeed.** Cadence falls as the user gets further from Quit Day.
5. **On the device.** No server in v1. No log content, height or weight ever leaves the phone or goes into analytics.

---

# Part A — Water tracker

## A1. What it's for

Water is the easiest "do something else" during a craving: it occupies the hands and mouth and breaks the autopilot routine. It's also a small daily win that gives people a reason to open the app on good days.

Copy rules:
- **Don't** claim water flushes or detoxes nicotine, speeds up withdrawal or cures cravings. Those are myths.
- **Do** say things like "a glass of water gives your hands and mouth something to do while the craving passes."
- Never show a BMI number, a weight judgement or a calorie figure anywhere in the app.

## A2. Onboarding (S2.14, S2.15) — signed off

Three screens, matching `WOnbBody.html`, `WOnbDay.html` and `WOnbGoal.html`. They sit after S2.9 and before the plan reveal. Every screen has a back button and the onboarding progress bar.

**Screen 1 · Your body**
- Eyebrow "YOUR WATER GOAL", headline "A few basics so we can size your goal."
- Unit toggle: `cm · kg` / `ft · lb`. Default from the device locale (US: ft · lb).
- Height and weight on horizontal ruler pickers with a sage centre indicator and a large value above each. Snap to 1 cm / 1 kg (1 in / 1 lb). Haptic selection tick on each step.
- Ranges: height 120–220 cm, weight 35–200 kg.
- Lock line: "Only used to estimate your water goal. Stays on your phone. We never show you a BMI score."
- Primary: **Continue**. Secondary: **Skip, use 8 glasses** (sets a 2.0 L goal, skips screens 2 and 3).

**Screen 2 · Your day**
- Headline "How active is a normal day for you?"
- Activity, single select, as large cards with a title and subtitle: Mostly sitting · On my feet a lot · I work out most days · Very active.
- Climate, single select: Mild or cool · Hot or humid.
- Primary: **See my goal**.

**Screen 3 · Your water goal**
- The full pill vessel (static, full) beside "YOUR DAILY GOAL", the litres in large type and "about N glasses".
- "HOW WE GOT THERE" breakdown: base for their weight, each adjustment that applies, rounding.
- **Adjust** stepper: − / + one glass (250 ml), within 1.5–4.0 L. A manual change is saved as an override (A3).
- Footnote: "An estimate, not medical advice. If a doctor has told you to limit fluids, use their number instead."
- Primary: **Set my goal**.

**Plan reveal (S2.15):** add a line "Water: 2.75 L a day (11 glasses)" to the S2.10 summary.

## A3. Goal calculation (S7.5)

```
base_ml      = weight_kg × 33
activity_ml  = 0 (Mostly sitting, On my feet a lot) | 350 (I work out most days) | 700 (Very active)
climate_ml   = 0 (Mild or cool) | 500 (Hot or humid)
raw_ml       = base_ml + activity_ml + climate_ml
goal_ml      = clamp(round_to_nearest(raw_ml, 250), 1500, 4000)
glasses      = goal_ml / 250
```

Worked example (the reference screens): 72 kg, works out most days, mild climate → 2,376 + 350 = 2,726 → **2,750 ml, 11 glasses**.

- Weight in pounds is converted to kg before calculating. Height is collected but not used in this formula; keep it for future use (and so the onboarding feels complete), and never show BMI.
- Skipped onboarding: goal 2,000 ml.
- A manual adjustment (onboarding stepper or Settings) sets `goalOverrideMl`, which always wins. If the user changes weight, activity or climate in Settings, recalculate and offer "Update your goal to X L?" rather than silently overwriting an override.
- Unit-test the formula: the worked example, both clamps, rounding at exact .5 boundaries, lb input.

## A4. Data model and logging (S7.5)

- `WaterProfile`: heightCm, weightKg, activity, climate, unitSystem, goalMl (calculated), goalOverrideMl (optional).
- `WaterEntry`: id, timestamp, drinkId, amountMl, hydrationFactor (1.0 for every v1 drink), countedMl (amountMl × factor), source (app, widget, notification, liveActivity, controlCenter, siri).
- **Drinks (v1):** Glass 250 ml · Bottle 500 ml · Tea 300 ml · Sparkling 330 ml. All count at 100% (Milan's call; tea is about 99% water and hydrates about as well as water). Keep `hydrationFactor` on the model so it can change later without a migration. Long-press any drink to log a custom amount.
- **No alcohol** in the drink list, ever (it's a common slip trigger). No sugary drinks as quick-log buttons.
- Units: ml/L, or fl oz in the US unit system (1 glass shown as 8 fl oz; store ml).
- The day resets at the user's day boundary (handoff S11.3).
- Undo: per-day stack; the tracker's Undo removes the last entry; widget and notification logs can be undone from the tracker.
- Store height and weight locally only. Exclude them from analytics and from any export the user hasn't asked for.

## A5. `WaterPillView` — signed off, build exactly (S7.6)

Reference: `reference/water/water-pill-preview.html`. Match it side by side. The numbers below are the source of truth for the SwiftUI build. Sizes are in points.

### Geometry (full size)

| Element | Value |
|---|---|
| Vessel | 200 × 340, `Capsule()` (corner radius 100) |
| Empty interior | `#0C0F08` |
| Outline | 2 pt stroke, white @ 0.75, drawn on top of the liquid |
| Glass highlight | 12 × 230 rounded bar at x 26, y 40 inside the vessel, white @ 0.14, above the liquid |
| Scale ticks | 3 ticks outside the right edge (14 pt out), 8 × 2, radius 1, white @ 0.35, at 25%, 50% and 75% of the height |
| Outer glow | Radial glow 280 × 380 centred on the vessel: sage `#BCC388` @ 0.22 at the centre fading to 0 at the edge. Opacity 0.35 normally, 1.0 once the goal is reached, 600 ms ease transition |

### Liquid

- Fills from the bottom; height = `min(countedMlToday / goalMl, 1)` of the vessel, clipped to the capsule.
- Vertical gradient by the **most recently logged drink**:

| Drink | Top | Bottom |
|---|---|---|
| Glass, Bottle | `#E9EECF` | `#9DA66A` |
| Tea | `#EBCB92` | `#A8763A` |
| Sparkling | `#F3F5E6` | `#BFC79A` |

- **Level change:** animate the fill height over **0.9 s** with timing curve **(0.22, 1, 0.36, 1)** (`.timingCurve(0.22, 1, 0.36, 1, duration: 0.9)`). The colour change can be instant.
- **Waves:** two sine waves sit on the liquid surface, filled with the gradient's top colour.
  - Front wave: wavelength 130, amplitude 7, its baseline exactly at the liquid's top edge, filled down into the liquid. Scrolls left 260 pt every **3 s**, linear, looping seamlessly.
  - Back wave: same wavelength, amplitude 6, baseline 8 pt above the liquid's top edge, **45% opacity**, drawn behind the front wave. Scrolls right 260 pt every **4.5 s**.
  - The level number (fill height) refers to the liquid's top edge, so at 100% the waves sit just above the vessel and are clipped, which reads as full.
  - Build with a `Shape` that takes an animatable phase, driven by `TimelineView(.animation)`; use real elapsed time so 60 Hz and 120 Hz devices match.
- **Bubbles:** three white dots rising through the liquid and fading:

| Bubble | Diameter | x from left | Start above bottom | Cycle | Delay | Peak opacity |
|---|---|---|---|---|---|---|
| 1 | 7 | 48 | 10 | 3.2 s | 0 s | 0.7 |
| 2 | 5 | 120 | 30 | 4.1 s | 1.2 s | 0.6 |
| 3 | 4 | 150 | 6 | 3.6 s | 2.1 s | 0.6 |

  Each rises 300 pt with ease-in, fading in over the first 15% and out by the end. Bubbles are clipped by the liquid surface (they never show above it). Sparkling: add 3 more bubbles (sizes 3–5) for a fizzier look.

### Log feedback

- Floating label "+250 ml" (the logged amount): Inter ExtraBold 18, sage, appears to the upper right of the amount readout, rises from +10 to −46 pt over **1.1 s** ease-out, fading in by 20% and out by the end. Restarts on every log.
- Haptics: `.impact(.medium)` on each log; `.success` notification haptic the moment the goal is first reached that day.
- At goal: glow to full (above), status text to "Goal reached. Nice." in sage. Logging past the goal keeps counting (the amount readout goes above the goal), the liquid stays full.

### Sizes and variants

- `full` (200 × 340): tracker screen and onboarding screen 3 (static, full, no waves moving is fine there but waves are allowed).
- `mini` (56 × 96, scale every value proportionally, no ticks, no glow, bubbles off): Home card, expanded water notification header if used, widget.
- `glyph` (for Live Activities): a static capsule outline with a flat sage fill at the current level and no waves or bubbles, because Live Activities ignore custom animations. Updates only when water is logged.

### Accessibility and motion

- One accessibility element: label "Water today", value "1.25 of 2.75 litres, 5 of 11 glasses", adjustable action increments by the selected drink (so VoiceOver users can log by swiping up).
- **Reduce Motion:** waves stop (draw a still wave), bubbles off, the level change becomes a 0.25 s ease. The floating label still appears, without travel.
- Respect the app's haptics setting.
- Performance: 60 fps (120 on ProMotion) on the oldest supported device; profile with Instruments.

## A6. Tracker screen (S7.7) — signed off

Layout matches the reference top to bottom, black background:

1. Header row: "Water" (Inter ExtraBold 28, tracking −0.5) and a streak pill on the right ("5-DAY STREAK", JetBrains Mono SemiBold 11, sage on sage @ 0.12, capsule). The streak counts consecutive goal days; a missed day ends it quietly with no message and is never shown as a failure.
2. Amount readout: today's total in litres (Inter ExtraBold 54, tracking −2) with "/ 2.75 L" (Inter SemiBold 20, white @ 0.55). Under it, "5 of 11 glasses" (SemiBold 14, white @ 0.6), or "Goal reached. Nice." in sage.
3. `WaterPillView` full size, 18 pt below.
4. Drink picker: 4 equal columns, 8 pt gaps, each 62 tall, radius 18: name (SemiBold 14) and size (Medium 12, 65% opacity). Unselected: 1 pt border white @ 0.12, fill white @ 0.04. Selected: 2 pt sage border, sage @ 0.12 fill. Remember the last selected drink.
5. **Log** button: full width, 58 tall, capsule, sage fill, black "+ Log 250 ml" (SemiBold 17) with a plus icon.
6. **Undo last**: text button, SemiBold 15, white @ 0.6, only shown when there's something to undo today.

Below the fold (scroll): today's entries list (time, drink, amount, swipe to delete) and a link to Insights.

## A7. Water elsewhere in the app

- **Home (S7.8):** a card with the mini pill, "6 of 11 glasses" and a one-tap +1 (the last selected drink). Long-press opens the tracker.
- **Craving SOS:** after **It passed**, offer "+1 water?" as a one-tap follow-up. Water is also one of the go-to actions users can pick in lesson D9.
- **Widget and Control Center (S7.9):** small widget with the mini pill and an interactive +1 button; a Control Center control "Log a glass of water"; the same App Intent is exposed to Siri and Shortcuts.
- **Live Activities:** +1 water button on Day Xero and Window Guard (B3).
- **Apple Health (S7.10):** optional, off by default; write dietary water only, read nothing; ask permission only when turned on.
- **Insights (S7.11):** goal history (bar per day vs goal) and best streak. After 14+ days, a neutral observation card "On days you hit your water goal, you logged X fewer cravings", shown only if the difference is meaningful, phrased as an observation about their own data, never as cause and effect.

---

# Part B — Notifications and Live Activities

## B1. In one paragraph

The app learns **when each user's cravings hit** from their logs and gets there ten minutes early, with one tap to breathe, drink water or say "I'm fine". Most actions work **straight from the notification, the Dynamic Island or the Lock Screen**. Water reminders are paired with craving windows where possible. Everything runs on the device.

## B2. Notification catalogue (S14.3)

### B2.1 Types

| ID | Type | When | Collapsed copy (default) | Lock-screen actions (no app open) | Expanded view (long-press) | Reference |
|---|---|---|---|---|---|---|
| N1 | Morning pledge | User's morning time (default 8:30) | "Day {n}. Today I stay free because {primary_reason}." | **Pledge** | Reason photo, day count, press-and-hold **Pledge** | NLock |
| N2 | Craving heads-up | 10 min before a predicted window | "Your {time} craving usually shows up soon. Want to get ahead of it?" | **+1 water**, **I'm good** | Mini Bio-Orb, 2 breath cycles; **Breathe now** opens the breathing screen | NCraving |
| N3 | Water reminder | Smart, inside water hours (B2.4) | "{glasses_left} glasses to go today." | **+1 glass**, **+2**, **Later** (1 h snooze) | Tappable glasses row, progress bar, streak | NWater |
| N4 | Lesson ready | Next lesson unlocks | "Day {n} is ready: {lesson_title}. {minutes} min." | **Start** (opens lesson) | Lesson cover image | NLock |
| N5 | Evening check-in | User's evening time (default 21:00) | "How was today?" | **Good**, **OK**, **Rough**; **Reply** (text input) | Mood chips, today's stats, craving timeline | NCheckin |
| N6 | Milestone | Milestone reached (handoff S13.1) | "{milestone_label}! {money_kept} kept." | **Share** | Share card image | NMilestone |
| N7 | Quit Day eve | Day 6, 19:00 | "Tomorrow is Day Xero. Your kit ready?" | **Open checklist** | D6 checklist preview | — |
| N8 | Day Xero morning | Quit Day, pledge time | "It's Day Xero. Start your day." | **Start Day Xero** (opens app, starts B3.3) | Hero visual, one line | — |
| N9 | NRT reminder | Patch time and step-down dates (S9.4) | "Patch time." / "Step-down day: {new_strength}." | **Done**, **Snooze 30 min** | none | — |
| N10 | Come back | Per the handoff's open inactivity decision. Default if undecided: after 2 idle days, after 5, then stop | "Your progress is still here. Pick up where you left off?" | **Open** | none | — |
| N11 | Window passed | A Window Guard ends with no slip, and its Live Activity was dismissed | "You got through your {time} window." | none | none | — |

If a placeholder value is missing, use the fallback line in B6.

### B2.2 Expanded views (S14.4)

- One Notification Content Extension with a category per type (N1, N2, N3, N5, N6). Set `UNNotificationExtensionUserInteractionEnabled = YES` so controls inside the view work.
- SwiftUI views hosted in the extension's view controller, reading and writing the shared store through the App Group.
- **N2:** `BioOrbView` mini size, `wave` pattern, 2 cycles, captions only (no voice), Reduce Motion behaviour as in the orb spec. Runs only while expanded.
- **N3:** a row of glasses equal to the goal's glass count (max 16, wrap to two rows); filled glasses in sage; the next one dashed with a "+". Tap a glass to log one; undo within 10 s by tapping again. Progress bar, "WATER STREAK · N DAYS" and "LAST · time" as in NWater.
- **N1:** press and hold 1.5 s, success haptic, "Pledged ✓".
- Every control has a VoiceOver label; Dynamic Type and Reduce Motion honoured.

### B2.3 Actions

- Background actions (water, pledge, mood, I'm good, Done, Snooze) are `UNNotificationAction`s without the foreground option. They write to the shared store, reload widgets, update running Live Activities and notify the planner.
- Foreground actions (Start, Breathe now, Share, Open checklist, Start Day Xero) deep-link to the right screen.
- N5 **Reply** is a `UNTextInputNotificationAction`; the text is saved to that day's check-in.
- Every action logs an analytics event (B7).

### B2.4 Water reminders (N3)

- Only inside water hours (default 09:00–21:00).
- At most 4 a day; none once the goal is met; none within 90 minutes of the last water log.
- Copy uses the user's own goal ("4 glasses to go today").
- **Pairing:** if a craving window starts within 20 minutes, merge into N2 instead (B4.2).
- On by default; "Fewer water reminders" in the expanded view's menu.

## B3. Live Activities

They appear on the Lock Screen and in the Dynamic Island, and the system mirrors them to Apple Watch, CarPlay and Mac. **Buttons don't work in CarPlay**, so every activity must read sensibly there, and nothing may ask for action while driving.

Constraints that shape these designs (check against current Apple docs before building):
- Up to **8 hours** active, then up to 4 more on the Lock Screen.
- Static plus dynamic data **≤ 4 KB**.
- **Custom animations are ignored.** Only system transitions run (text blur, symbol and image transitions, fades, `numericText` on timers). Use glyph states, not the animated orb or the animated pill.
- Starting needs the app in the foreground, **except** via an App Intent conforming to `LiveActivityIntent`, or by **scheduling** an activity for a future date with an alert configuration (check which iOS version added scheduling; fall back as in B3.4).
- Self-updating timers (`Text(timerInterval:)`, `Text(date, style: .timer)`, `ProgressView(timerInterval:)`) need no updates; use them.
- Lock Screen presentations over 160 pt tall may be truncated.
- Compact presentations must also work in the reduced-width layout (fit a 28 pt circle).

### B3.1 Craving SOS (S6.11)

| Presentation | Content |
|---|---|
| Compact leading | Ring glyph (static orb in 3 states: inhale, hold, exhale) |
| Compact trailing | Session countdown, self-updating |
| Minimal | Ring glyph |
| Expanded | Phase word, countdown, progress bar; **It passed**, **I slipped** |
| Lock Screen | Phase word, countdown, progress ring, a line from their reasons; same buttons |

- Phase changes need app updates. While voice guidance plays, the app has a legitimate audio session and can update each phase in the background. With voice off in the background, show the pattern ("in 5 · hold 2 · out 5") and the session countdown instead. **Never play silent audio to stay alive.**
- **It passed** logs the outcome and ends with "Urge surfed ✓", dismissed after 1 hour. **I slipped** opens the slip debrief.

### B3.2 Breathing session (S12.5) — see NIsland

| Presentation | Content |
|---|---|
| Compact leading | Ring glyph in the current phase state |
| Compact trailing | "in · 0:04" style phase countdown |
| Minimal | Ring glyph |
| Expanded | Ring glyph, phase word ("Breathe in"), "DEEP CALM · CYCLE 2 OF 4", phase seconds, session progress bar; **Pause**, **Stop** |
| Lock Screen | Same as expanded |

- Started from the toolkit, N2's Breathe now, or the **Breathe** button on Day Xero and Window Guard (a `LiveActivityIntent`, works without opening the app).
- Pattern data from `breathing_orb_data.json`. Same background rule as B3.1. Ends after `recommendedCycles` with "Done ✓", dismissed after 15 minutes. Haptics only while the app is active.

### B3.3 Day Xero (S14.6) — see NLiveLock

| Presentation | Content |
|---|---|
| Compact leading | Small "0" ring mark in sage |
| Compact trailing | Time since quitting, counting up |
| Minimal | "0" ring mark |
| Expanded / Lock Screen | Ring glyph, "DAY XERO", time free (large, counting up), "nicotine-free", cravings ridden, glasses of water; **SOS**, **+1 water**, **Breathe** |

- Started by the D7 commit ("Hold to start Day Xero") or N8. Updates only on a craving outcome or a water log.
- The system ends it at 8 hours. If the app is running at 7 h 45 min, push a final state ("8 hours free. Huge."); otherwise accept the system end.
- Optional (Settings, default on): a fresh Day Xero activity each morning for the first 3 days after Quit Day.

### B3.4 Craving Window Guard (S14.7) — see NIsland and NLiveLock

| Presentation | Content |
|---|---|
| Compact leading | Shield-ring glyph |
| Compact trailing | "until 3:40" |
| Minimal | Glyph |
| Expanded | "Your 3:00 window", "You've ridden out 6 of these.", countdown; **Breathe**, **+1 water**, **I'm good** |
| Lock Screen | Glyph, "Your 3:00 window", trigger line ("After lunch. You've got this."), countdown and "UNTIL 3:40" |

Starting:
1. **Preferred (where supported):** schedule the activity for the window start with an alert configuration; that alert replaces N2 for the window.
2. **Fallback:** N2 fires 10 minutes early; **Breathe now** opens the app, which starts the guard.
3. Manually from Home: "Guard my next 30 min".

Ending:
- At the window end: "Window passed ✓", logs `window_survived` (counts toward cravings ridden out), dismissed after 30 minutes.
- **I'm good** ends it early with the same final state. A slip logged during the window ends it quietly.
- At most **2 guards a day**, high-confidence windows only, never in quiet hours.

### B3.5 Live Activity manager (S14.8)

- Relevance: SOS 100, Breathing 90, Window Guard 70, Day Xero 50.
- Never more than 2 DayXero activities at once; starting a third ends the lowest-relevance one.
- On every launch, list `Activity.activities`, end stale ones and resync from the store.
- If starting fails (disabled, device limit), fall back to the notification silently.
- Respect the in-app toggle (B8) and the system setting (`areActivitiesEnabled`, `activityEnablementUpdates`).

## B4. Scheduling engine

### B4.1 `NotificationPlanner` (S14.1)

One component owns every local notification and scheduled Live Activity; nothing else schedules them.

- **Runs:** on launch and foreground, after any log (use, craving, slip, water, pledge, check-in), after a lesson completes, after settings change, and from `BGAppRefreshTask`.
- **Plans 48 hours ahead**, applies B4.2, then replaces the pending set.
- **64-pending limit:** never schedule beyond 48 h; target ≤ 40 pending.
- **Priority when something must give:** SOS-related > N2 > N8/N7 > N4 > N1 > N5 > N9 > N6 > N3 > N10. N9 is never dropped if enabled and sits outside the cap.

### B4.2 Rules for every candidate

1. **Quiet hours:** default 22:30–07:30, user-editable; only N9 may fire inside, if allowed.
2. **Daily cap** per phase (B5); N9 outside; N3 has its own cap (B2.4).
3. **Merging:** two candidates within 20 minutes become one. N2 + N3: "Craving time soon. Grab a glass of water and get ahead of it." with **+1 water** and **I'm good** (see NLock, top card).
4. **Recency:** skip a reminder if the user did that thing in the last 30 minutes.
5. **No stacking:** one visible notification per category; replace with the newer one (`threadIdentifier` per category).
6. **Interruption levels:** default `.active`. N2 and the Window Guard alert use `.timeSensitive` only if the user opts in (needs the Time Sensitive entitlement). N6 is `.passive`.

### B4.3 `CravingPredictor` (S14.2)

- **Inputs:** craving logs, SOS sessions, slips, and in the prep phase, use logs; each with time and optional trigger tag. Before 7 days of data, seed from onboarding S2.5.
- **Model:** a 7 × 48 grid (day of week × 30-minute slot); events add weight with exponential decay (half-life about 7 days); smooth ±30 minutes; pool weekdays/weekends when data is thin.
- **Window:** adjacent slots above a threshold with at least 3 events in the last 14 days. Confidence = score relative to the user's own maximum.
- **Output:** up to 3 windows a day with start, end, confidence and top trigger tag.
- After Quit Day, cravings and SOS sessions drive it; decay makes windows fade as cravings drop.
- Recompute after each log and on background refresh.
- Unit tests: a fixed 3 pm habit, weekday-only, a sparse user, cravings fading over 3 weeks.

### B4.4 Adaptive back-off (S14.10)

- Track each notification's outcome: opened, acted on, dismissed, ignored.
- Per type and slot: after **3 ignores or dismissals in a row**, halve frequency for 7 days; after 3 more, stop that slot and show a one-time card: "We'll stop the {time} reminders. Turn them back on anytime in Settings."
- Acting on a notification restores normal frequency. Never back off N9 or anything the user scheduled.

## B5. Cadence by phase (S14.9)

The cap counts N1–N8 and N10; N9 is outside; N3 has its own cap.

| Phase | Daily cap | On by default | Live Activities |
|---|---|---|---|
| Before Day 1 lesson | 1 | N4 | none |
| Prep, Days 1–6 | 3 | N1 (prep wording), N4, N5, N2 as practice, N7 on Day 6 | SOS and Breathing on demand |
| Day Xero | 4 | N8, N2, N5 | Day Xero; Guards up to 2 |
| Week 2 | 4 | N1, N2 (up to 2), N4, N5, N6 | Day Xero Days 8–9 if enabled; Guards up to 2/day |
| Weeks 3–5 | 3 | N1, N2 (high confidence), N4, N5 every other day, N6 | Guards up to 1/day |
| After the program | 1 (some days 0) | N2 (high confidence), N6, Sunday weekly summary | Guards on request |
| Inactive | per N10 | N10 only | none |

Prep-phase copy invites practice, because users are still allowed to use.

## B6. Copy defaults (S14.12 — Milan to approve)

Warm, short, a little dry. No guilt. No exclamation marks except milestones. No emoji. Store everything in the strings catalog with placeholders.

| ID | Variant | Line |
|---|---|---|
| N1 | Prep | "Day {n}. Today's job: just notice." |
| N1 | Post-quit | "Day {n}. Today I stay free because {primary_reason}." |
| N1 | Fallback | "Day {n}. Here's to another one." |
| N2 | Prep | "Your {time} one usually shows up soon. Try the 10-minute delay?" |
| N2 | Post-quit | "Your {time} craving usually shows up soon. Want to get ahead of it?" |
| N2 | With trigger | "{trigger_label} coming up. That's usually a craving moment. You've got this." |
| N2 + N3 | Merged | "Craving time soon. Grab a glass of water and get ahead of it." |
| N3 | | "{glasses_left} glasses to go today." / "Quick glass of water?" |
| N4 | | "Day {n} is ready: {lesson_title}. {minutes} min." |
| N5 | | "How was today?" |
| N6 | | "{milestone_label}! {money_kept} kept." |
| N7 | | "Tomorrow is Day Xero. Your kit ready?" |
| N8 | | "It's Day Xero. Start your day." |
| N10 | | "Your progress is still here. Pick up where you left off?" |
| Weekly | | "This week: {cravings_ridden} cravings ridden out, {water_goal_days} water-goal days, {money_kept} kept." |

## B7. Analytics and guardrails (S14.11)

No log content, free text, height, weight or health details in any property.

- `notif_scheduled`, `notif_opened`, `notif_action` (type, action), `notif_dismissed`, `notif_backoff_applied`
- `la_started`, `la_action`, `la_ended` (type, reason)
- `window_predicted` (confidence bucket), `window_survived`, `window_slip`
- `water_goal_set` (source: calculated, override, skipped; goal bucket only), `water_logged` (source, drink), `water_goal_met`
- `notif_permission`, `time_sensitive_opt_in`, per-type toggle changes

Guardrail: if any notification type's disable rate passes 5% in a week, add a tracker task for Milan to review it.

## B8. Settings (S15.7)

- Master notifications switch; per-type toggles grouped as Daily (pledge, check-in), Program (lessons, Quit Day), Craving help (heads-ups, Window Guards, Time Sensitive opt-in), Water (reminders, water hours), NRT, Milestones and weekly summary.
- Times: morning pledge, evening check-in, quiet hours, water hours.
- "Notifications per day": Fewer / Normal / More (caps × 0.5 / 1 / 1.25).
- Live Activities: on/off, plus Day Xero on Days 1–3.
- Water: height, weight, activity, climate (recalculate offer, A3), goal override, units, Apple Health sync.
- A "Why am I getting this?" link from every expanded notification to the right section.

## B9. Permissions

- Notification permission stays at S2.11 (after the plan reveal), with one screen explaining craving heads-ups.
- If denied, everything works in-app; a quiet Home card once a week for the first 3 weeks offers to turn them on. Then stop.
- **Craving Guard setup card** (Day 3, once the predictor has data): explains heads-ups and guards, offers the Time Sensitive opt-in, previews a guard.
- Live Activities need no prompt, but respect the system toggle.

---

## C. Done when

**Water**
- [ ] `WaterPillView` matches `water-pill-preview.html` side by side: vessel size and outline, gradient colours, 0.9 s fill curve, both waves' speeds and directions, bubbles, the "+250 ml" float, glow at goal. Screen recording attached to S7.6.
- [ ] Wave speed identical on 60 Hz and 120 Hz devices; 60/120 fps held on the oldest supported device.
- [ ] Goal formula unit tests pass (worked example 72 kg → 2,750 ml; clamps; lb input).
- [ ] Onboarding screens match the references; skip sets 2.0 L; the goal appears in the plan reveal.
- [ ] Logging works from all six sources and updates the pill, Home, widget and any running Live Activity.
- [ ] No BMI, weight judgement or detox claim anywhere; no alcohol in the drink list.
- [ ] Reduce Motion, VoiceOver (including adjustable logging) and Dynamic Type verified.

**Notifications and Live Activities**
- [ ] The planner never exceeds the phase cap, quiet hours or 64 pending (simulated-week tests).
- [ ] The predictor finds a fixed 3 pm habit within 7 days and fades it within about 3 weeks of no cravings.
- [ ] N2 and N3 merge within 20 minutes; nothing duplicates.
- [ ] Every lock-screen action works with the app killed and updates Home, widgets and Live Activities.
- [ ] Expanded views for N1, N2, N3, N5 and N6 work, with VoiceOver and Reduce Motion.
- [ ] All four Live Activities render in every presentation, including StandBy, Apple Watch and reduced width; buttons work from the Lock Screen and Dynamic Island.
- [ ] Day Xero runs from the D7 commit to the 8-hour limit without errors.
- [ ] Window Guards start by schedule where supported and by tap-to-start otherwise; never more than 2 a day.
- [ ] Back-off triggers after 3 ignores and shows the one-time card.
- [ ] Screenshots of every built notification and Live Activity state posted to the tracker and signed off by Milan.
- [ ] No guilt language in any copy; all analytics events free of personal content.
