# DayXero App Store screenshots, Direction E: "Meet the crew"

This is the designer's direction, built out for the App Store. Her Google Play draft (8 frames at 1080 × 1920, plus
a feature graphic) told the story through the three characters. First it introduces Xero, Jelli and Glim. Then it
explains what Day Xero is and what the plan is for. Then it shows how each character helps along the way. Direction E
keeps her story order, her voice and her speech bubbles, her colour per frame, and her type (Bricolage Grotesque and DM
Sans). Her crew is redrawn **exactly as the app draws Xero, Jelli and Glim** (see [Characters](#characters)). It extends her 8 frames to 10 and
re-lays them for the taller iPhone canvas. Every phone shows a **real CI capture of `main` (6498929)** in place of her
mock-ups. Behind everything runs **Direction C's wave language**: one continuous landscape whose layers meet exactly at
every seam, recoloured to her palette.

Editable canvas: https://claude.ai/artifact/MuTfRJftEMMZStuqPTDEQN ("DayXero App Store screenshots · Meet the crew").
It holds the same ten frames as artboards at 1320 × 2868, built from the same markup.

## Exports

| File | What it is |
|---|---|
| `export/iphone-6.9/01.png … 10.png` | 1320 × 2868, the iPhone 6.9" class (rendered 1:1) |
| `export/iphone-6.3/01.png … 10.png` | 1206 × 2622, the iPhone 6.3" class. The same stage, scaled in the browser and rendered natively, not resampled |
| `export/contact-sheet.png` | All ten at 300 px, butted edge to edge, so the landscape reads as one strip |
| `export/contact-sheet-gapped.png` | All ten with 14 px gaps and rounded corners, as the product page spaces them |
| `export/contact-sheet-search.png` | Frames 1–3 at 230 px, the size of a search result |

Every PNG is 8-bit RGB with no alpha channel and carries an sRGB chunk. `render.mjs` fails if Bricolage Grotesque or
DM Sans hasn't loaded, or if any screenshot hasn't loaded.

## The ten frames

| # | Headline | Subhead (and pill) | Real screen in the phone (`real/`) | Extends her frame |
|---|---|---|---|---|
| 1 | Quit smoking & vaping. No cold turkey. | Get your mind ready in 7 days, then quit on Day Xero. Fine print: "Requires a DayXero Pro subscription." The crew with her three bubbles: "I'm Jelli. Cravings? I've got you." / "Glim here. I check in at night." / "Hi, I'm Xero. We'll take it one day at a time." | `day12-today.png`, peeking up from the hills (the 7-day badge sun and Xero) | 01 Hook · meet the crew |
| 2 | Prep for 7 days. Then quit on Day Xero. | Keep using as normal while you learn how your habit works. Pill "The DayXero plan". Xero: "One stone a day. I'll walk it with you." Seven stepping stones lead to the Day Xero flag in the landscape | `home-quitday.png`: the prep path to DAY XERO, the week dots and "Prep 7 · 5 cards · 27 min" | 03 The 7-day plan |
| 3 | One small step, every day. | Xero shows you what's next and cheers every step you take. Pill "Meet Xero · your days". Xero: "Just today's step. That's all." | `home-day3.png`: "3-day badge earned", "4 days to your 7-day badge" | 02 Meet Xero · your days |
| 4 | Learn your habit, one card at a time. | Listen, reveal, myth or fact, try. Short cards on how the habit really works. Pill "Your daily hand of cards". Xero: "One card at a time. No rush." | `day3-program.png`, with its "Today · Day 3 · 4 cards · 3 min / The noisy passengers" row lifted out over itself | 04 5 minutes a day |
| 5 | Craving hits? Jelli breathes with you. | Tap SOS anytime. Ride the wave out together, one breath at a time. Pill "Meet Jelli · your waves". Jelli: "Breathe with me. It'll pass." | `sos-session.png`: Jelli breathing, "It passed", "Text a friend · I slipped" | 05 Meet Jelli · your waves |
| 6 | Slipped? Nothing resets. | Tell Jelli what happened. Your days stay, and you plan for next time. Pill "Jelli · after a slip". Jelli: "No guilt. Let's plan for next time." | `slip.png`: "Thanks for telling me.", "Since Day Xero 3 days", "Slips don't cloud it.", "Make a one-minute plan" | new (Jelli's second frame) |
| 7 | Wind down with Glim every night. | A one-minute check-in with Glim, then a slow breath before bed. Pill "Meet Glim · your evenings". Glim: "How was today? Tell me, then rest." | `winddown-dark.png` (Wind down, deep calm 4-7-8), plus the lifted "Check-in with Glim · Opens 6 PM" and "Wind-down breath · 10 PM · 3 min" rows from `today-later.png` | 06 Meet Glim · your evenings |
| 8 | A calm tool for every wave. | Box breathing, grounding and noticing the urge, one tap away in Calm. Pill "Calm tools · any time" | `notice-the-urge.png` and `box-breathing.png`, fanned | new |
| 9 | Celebrate progress, not perfection. | Badges as your days add up. Every wave you ride out counts. Pill "Badges and milestones". The crew cheers | `day12-progress.png`: badges 1, 3 and 7, "11 waves ridden" | 07 Progress, not perfection |
| 10 | Your Day Xero is waiting. | 7 days to get ready. A crew that's got your back the whole way. Chips: "No cold turkey", "Cigarettes, vapes and pouches", "Private on your phone". "Start your 7-day plan". Fine print: "Requires a DayXero Pro subscription." | none: her closer, with the crew on the island under the Day Xero flag | 08 Your Day Xero is waiting |

Frames 1–3 work on their own in search (`contact-sheet-search.png`): the promise and the crew, then the plan, then the
daily step. Each one is legible at 230 px.

### Where the real app won over her draft

Each change below was checked against the Swift source and `DayXeroCore/Resources/program.json` at 6498929.

- **"5 minutes a day" was dropped.** A prep day is one session of 5 cards, about 25–28 minutes in all (each card 4–7
  min). After Day Xero, a day is a short read of about 3 min. Her pill "Your daily hand of cards" and her card types
  ("Listen, reveal, myth or fact, try") are true, so frame 4 leads with those. Frame 2's subhead replaces "Cut down
  slowly with 5 minutes of prep a day" with the app's own prep rule, "Keep using as normal" (the prep phase subtitle is
  "Learn your habit. Keep using as normal.").
- **No sparks, no "+30 sparks", no "Stress Tamer" badge, no streak.** The app has day badges (1, 3, 7, 14 …) and
  "waves ridden". Frame 9's pill is "Badges and milestones", not "Badges, sparks and streaks".
- **Her check-in mock-up ("How are you feeling tonight?", "Your urge is lower than this morning")** isn't in the CI
  captures. Frame 7 shows what is: the Wind down screen and the Today rows "Check-in with Glim · Opens 6 PM" and
  "Wind-down breath · 10 PM · 3 min". The subhead's "one-minute check-in" is the app's own kicker, "With Glim · 1 min"
  (`TodayView.swift`, `EveningView.swift`).
- **The reason card "Running with Mia" and "Xero passed you to Jelli"** don't appear on the captured SOS screen. Frame 5
  shows the real screen.
- **Frame 10's chip** reads "Cigarettes, vapes and pouches" (the app covers all three), not "Cigarettes and vapes".
- **Pill text on coral (frame 3) is ink, not cream.** Cream on #FF7A55 is 2.6:1, which fails even for large text.

## Characters

Xero, Jelli and Glim are the app's own drawings, ported from the SwiftUI on `main` **6498929** (read with
`git show origin/main:<path>`):

- `DayXeroCore/DesignSystem/Art/XeroView.swift`, `JelliView.swift` and `GlimView.swift`: every path, colour, opacity,
  stroke width, pivot and the draw order, in the same 200 × 200 drawing space.
- `DayXeroCore/DesignSystem/Art/CrewDrawing.swift`: the five faces (`Crew.Face.make`), the ink (#24163A, Glim's face
  #FFF8EE), the yellow four-point sparkle, the zzz mark and the cream dark-mode marks.
- `DayXeroCore/Logic/CrewGrowth.swift`: the stages. Under 7 days clear is stage 1, under 14 is 2, under 28 is 3, then 4.
  Xero's stage 0 is the kit's Xero (`XeroView.kit`) that onboarding, the card deck and Progress draw: full size, #FF7155,
  no sprout. At stages 1–4 Xero grows from his feet (0.8, 0.88, 0.95, 1) and deepens in colour, his sun rises in the hole,
  and he gains a leaf (2), two leaves (3), then a bud, rays and a warm glow (4). Jelli gains glints (2, 3) and a crown
  (4). Glim's tail glow brightens, and stars appear at 4.
- `DayXeroTests/CrewArtTests.swift` holds the invariants the port keeps (Xero's body box 34–166 × 34–188, the grow
  factors, the crown star's box).

`src/char.js` holds the port: `DX_CREW(props)` returns the data and `CREW_TEMPLATE` is the SVG. The PNGs draw the rest
pose. This is every track's first value, which is what the app shows with motion off (`ArtTrack.value(animate: false)`).
The canvas component runs the app's idle motion with the same values, key times, durations and easing (keySpline
0.45 0 0.55 1): breathing, hops, sway, blinks on hello and cheer, the tentacles, wing flaps, the glow pulse, Jelli's
bubbles, Xero's sun and his wave. The box is `size` × `size`, as the app's `CrewCanvas` frames it (`size` is the app's
`points`). Marks, hops and the stage-4 glow can draw a little outside the box, as in the app.

**Checked against the CI captures.** Each render was aligned onto crops of the real screens and differenced. Xero matches
`home-day3.png` (stage 1, hello, 104 pt) to a mean of 0.5/765 per pixel, so the two are pixel-identical. Xero at stage 2
(`day12-today.png`), at stage 0 cheering (`day12-progress.png`) and at stage 0 breathing (onboarding `00-breathe`),
Jelli breathing (`sos-session.png`, `box-breathing.png`) and calm (`slip.png`), and Glim calm and sleepy (the
`ci-screens-core` check-in captures; `GlimView` has not changed since) match apart from where the capture caught the
animation (a hop, a breath, a wing flap, a bubble).

One deliberate difference from the Swift source: **Glim's tail glow uses normal blending.** `GlimView` draws it with
`.plusLighter`, but inside the Canvas's own transparent layer, so on screen it composites as plain source-over. The
check-in capture confirms this: over the night hills the glow adds yellow with no lift in blue.

Not ported, because no frame uses them: Xero's `breathPuffs` and `headphones` poses.

### Moods: the designer's expressions mapped to the app's

`<x-char expr>` takes the app's five moods (`hello`, `calm`, `breathe`, `cheer`, `sleepy`; `CrewMood`). Her three
expressions still work and map to the nearest mood: `happy` → `hello` (eyes open, smile), `cheer` → `cheer` (arms up,
^ ^ eyes, open smile, sparkles) and `sleepy` → `sleepy` (flat eyes, zzz). Where the app's own screen for a frame shows a
specific mood, the frame uses it:

| # | Character | Her expression | App mood, stage, pose | Why (the app's screen) |
|---|---|---|---|---|
| 1 | Xero | cheer | hello, 0, wave | Welcome (`WelcomeArt`): the kit's Xero waves beside "Hi, I'm Xero." |
| 1 | Jelli, Glim | happy | hello, 1 | Onboarding introduces them at stage 1 ("Meet Glim", `OnboardingV4Screens`) |
| 2 | Xero | happy | hello, 1 | The prep path on Today (`TodayPath`), the quit-day capture in the phone (0 days clear) |
| 3 | Xero | cheer | cheer, 1 | Today's badge hero (`TodayHero`: `cheer ? .cheer : .hello`, crew stage) on Day 3, as in the phone |
| 4 | Xero | cheer | cheer, 0 | The card deck draws the kit's Xero (`DeckViews`, `CardStack`, `SessionFlowView`) |
| 5 | Jelli | happy | breathe, 1 | Craving SOS (`CravingSOSView`), as in the phone |
| 6 | Jelli | happy | calm, 1 | The slip flow (`SlipFlow`), as in the phone |
| 7 | Glim | happy | calm, 1 | The check-in (`CheckInView`: calm until the mood is good or proud), Day 3 as in the lifted Today rows |
| 8 | Jelli | sleepy | calm, 1 | The Calm tools draw Jelli calm or breathing, never sleepy (`CalmGroundingView`, `CalmUrgeView`) |
| 9 | Xero | cheer | cheer, 0 | Progress (`ProgressHero`), as in the phone |
| 9 | Jelli, Glim | cheer | cheer, 2 | Milestones (`MilestoneViews`): Xero at 0, the others at the crew stage (Day 12 is stage 2) |
| 10 | all three | cheer | cheer, 4 | The finale (`FinaleView`, Day 31, program complete): the whole crew cheering at stage 4 |

Because the app's art sits smaller in its box than hers (and stage-1 Xero is drawn at 0.8), each character was re-laid
to keep her on-screen height, centre and ground line. Frames 3, 9 and 10 were then nudged so that no sparkle, wing or
star touches a frame edge, a phone or frame 10's flag.

### Rules check

- No "#1", awards, ratings, user counts, prices, "free" or trial text in any caption. No success-rate or medical
  claims. No exclamation marks. "It'll pass" (frame 5) is her bubble line, and it matches the app's own SOS guidance.
- No cigarettes, vapes or pouches are pictured.
- Hard paywall (2.3.2): frames 1 and 10 carry "Requires a DayXero Pro subscription.".
- The real screens keep their own wording, including "12 days free" (frame 9), "puffs not taken" and "kept". This is
  the app's UI, so it is left as it is.
- 2.3.3: nine of ten frames show the app in use. Frame 10 is her closer.

## The landscape (waves)

`src/waves.js` draws one landscape 13,200 px wide across all ten frames: a far, mid, near and front layer. Each layer is
a function of the global x, so a ridge leaves frame N at exactly the height at which it enters frame N+1, as in
Direction C. Each layer's colour is keyed per frame and blends across the seam in OKLab (±260 px). Her flat ground
colour stays as each frame's sky, so the sky changes at the seam, as it does on her canvas. The realms are:

| Frames | Realm |
|---|---|
| 1–4 | Hills: mint under her apricot hook, deep greens for the plan, Xero's peach land, lavender for the cards |
| 5–6 | Jelli's sea, rolling swells with foam. In 6 the sea turns to a pink evening, and the sun sets on the 6/7 seam |
| 7 | Glim's night hills, with her crescent moon, stars and fireflies |
| 8 | A calm dawn sea. The sun rises on the 8/9 seam |
| 9 | The rewards meadow with flowers |
| 10 | The finale sea, with her sand island and the Day Xero flag |

The waves are her own shape (smooth sine swells, as in her Jelli and Finale frames) with Direction C's soft lift shadow
between layers.

## Edit and re-render

```
cd design/app-store-screenshots/directions/e-crew-story/src
node render.mjs              # all ten frames, both sizes, then the three contact sheets
node render.mjs 03 07        # just these frames (contact sheets are rebuilt from whatever is in ../export/)
node render.mjs --size 6.9   # one size only
node build-canvas.mjs /path/to/folder   # writes the canvas files (project/…) from the same markup
```

You need Playwright with Chromium (`require('playwright')`). There are no other dependencies.

| File | What it is |
|---|---|
| `src/frames/NN-*.html` | **Edit here.** Each frame as plain HTML with inline styles, at 1320 × 2868. `<x-char who expr stage size>` (optional `pose`, `dark`) places a crew member, `<x-waves frame="N">` places the landscape, and `../real/*.png` are the real screens |
| `src/frames.json` | Frame order, artboard file names and titles |
| `src/char.js` | The app's Xero, Jelli and Glim (`DX_CREW` data and `CREW_TEMPLATE` SVG; see [Characters](#characters)). `DXCHAR` draws the still rest pose for the PNGs |
| `src/waves.js` | The landscape: `DX_WAVES(frame)` (data) and `WAVES_TEMPLATE` (the SVG) |
| `src/frame.html` | `frame.html?f=05` previews a frame at 1320 × 2868. Serve the `e-crew-story` folder, not `src/` |
| `src/render.mjs` | Renders the PNGs (RGB, no alpha, sRGB) and the contact sheets. Same approach as `../../src/render.mjs` |
| `src/build-canvas.mjs`, `src/canvas/` | Builds the Design canvas files. `Char.dc.html` is generated from `char.js`, with the idle motion on. `canvas/assets.json` maps each real screen to its uploaded copy on the canvas |
| `src/fonts/` | Bricolage Grotesque and DM Sans, bundled (SIL OFL), the same files as Directions A–D |
| `real/` | The real screenshots used, with `PROVENANCE.md` (branch, `main` commit, file name) |

To swap a screen, drop the new capture in `real/` and point the frame's `<img>` at it. Phones are 680 px wide on screen,
so a 1320 px capture is only ever scaled down. For the canvas, upload the file to the canvas's asset store, add it to
`canvas/assets.json`, run `build-canvas.mjs` and publish the changed artboard.

The canvas and the PNGs share the same markup. If the designer edits the canvas, copy her changes back into
`src/frames/` before re-rendering.

## Known limits and open items

- **Frame 7's phone is a small-device dark capture** (1170 × 2532, built from 2cc8b27, the parent of 6498929; Wind down
  didn't change between the two). Replace it with a large dark capture once CI makes one.
- **There's no Glim check-in screen among the CI captures.** If the UI tests add one (`CheckInView`, "How are you
  feeling tonight?"), it would make frame 7 stronger than Wind down.
- **The prep-cards screen during prep** (the opened day card with its five cards) isn't captured either. Frame 4
  therefore uses the Program tab's Week 1 row ("4 cards · 3 min"). A capture of the prep day card would let frame 4
  show the five card types directly.
- **The real screens use the simulator clock and dates** (4:53 PM, Fri, Nov 20), so different frames show different
  persona days: Day 3 on Today and the slip screen, Day 12 on Progress.
- **Frame 1's peeking phone and frame 9's Progress show "11d 6h free" and "12 days free".** In frame 1 that line is
  below the visible part. In frame 9 it's the app's own label, kept as it is. Renaming it in the app (see Direction A's
  open items) would remove any reading of "free" as a price.
- **On the canvas, the characters animate** with the app's idle motion. The PNGs show each one at rest, as the app does
  with motion off. Her original component is still on her own canvas and in git history
  (`src/canvas/Char.dc.html` before this change).
