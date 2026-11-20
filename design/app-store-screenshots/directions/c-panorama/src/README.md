# DayXero App Store screenshots

Ten iPhone screenshots for the App Store product page, in two sizes:

| Folder | Size | Device class in App Store Connect |
|---|---|---|
| `../export/iphone-6.9/01.png … 10.png` | 1320 × 2868 | iPhone with Dynamic Island (large display) |
| `../export/iphone-6.3/01.png … 10.png` | 1206 × 2622 | iPhone with Dynamic Island (medium display), the "required" class |

`../export/contact-sheet.png` shows all ten at 300 px wide. `../export/contact-sheet-search.png` shows frames 1–3 at 230 px wide, the size they appear at in search results.

All PNGs are 8-bit RGB with no alpha channel and carry an sRGB chunk. Both sizes are rendered natively from the same layout, so neither one is a resampled copy of the other.

## Edit and re-render

```
cd design/app-store-screenshots/src
node render.mjs              # all ten frames, both sizes, then the contact sheets
node render.mjs 03 07        # just these frames (the contact sheets are rebuilt from whatever is in ../export/)
node render.mjs --size 6.9   # one size only
```

You need Playwright with Chromium (`require('playwright')`). There are no other dependencies. The script starts a small local web server, because the frame page reads its iframes and `file://` would make them cross-origin. For each frame it waits until every iframe has finished rendering and the fonts have loaded, and it fails if Bricolage Grotesque or DM Sans didn't load.

| File | What it is |
|---|---|
| `frames.js` | **Edit here.** The ten frames as data (headline, subhead, fine print, ground, which app screen, the status-bar time, phone position, breakout), plus the builder and the art for frames 1–3 and 10 |
| `frames.css` | The shared stylesheet: grounds, caption type, the hand-drawn mark, the CSS iPhone, breakout cards |
| `frame.html` | The one templated page. To preview a frame, open `frame.html?f=05` at 440 × 956 |
| `render.mjs` | Renders the frames, writes RGB PNGs without alpha, and builds the contact sheets |
| `app/kit/` | A copy of the v5 UI kit from `cook/site/kit/`. It has two patches: bundled fonts, and `?time=` for the status bar |
| `app/screens/*.html` | The app screens shown in the phones (390 × 844), adapted to the persona. Each file says where it came from |
| `fonts/` | Bricolage Grotesque and DM Sans as variable woff2 files (SIL OFL, from `@fontsource-variable` 5.3.0), so renders never depend on Google Fonts |

Headline syntax: `<br>` forces a line break. `<mk>word</mk>` adds the hand-drawn underline: coral on light grounds, sun yellow on ocean and night (decision 32). Put the mark on the **last** line, where it can't collide with the line below it.

There are two kinds of breakout. **`zoom: { sel, scale, pad, dy }`** lifts a real element out of the screen: the builder measures the element inside the phone, magnifies it, and centres it over where it sits. **`card: { … html }`** is a card in the app's own style. Frame 6's card uses `cover` to size itself over named elements.

## What the phones show, and why it isn't F01–F18 verbatim

The brief pointed at the v4 F-screens. The shipped SwiftUI app has since moved to the **v5 restyle** of those screens. The v5 screens are the cook mockups in `cook/site/screens/`, built on the same v4 kit, characters and fonts. For example:

- The code cites the v5 screens by number, such as `CravingSOSView` "(019)", `HealthTimelineView` "(037)" and `TodayHero` "(016)/(017)".
- `DayXeroCore/DesignSystem/V4/Ground.swift` now holds the v5 values: ocean #1F3C8C, mint #D3F0DF, and night #0F1B33 in place of violet.

Guideline 2.3.3 requires the app in use, so each phone shows the v5 screen that the code renders. Every string was checked against the Swift source. The design system still supplies the persona (§7), the voice (§8), the characters, the type and the token family. Where v4 and the code disagree, the code wins (decision 17):

| Topic | v4 F-screen | What the code shows (used here) |
|---|---|---|
| Today greeting | "Morning, Sam." | "Good morning, Sam" |
| Today on Day 3 | Lesson and tiles | "3-day badge earned", "$15 kept • 25 cigarettes not smoked", "4 days to your 7-day badge" (`TodayView.swift`) |
| Lesson on Sun 8 Nov | "Lower the bar", Day 3 | W1D2 "The noisy passengers", labelled **Day 3** in `program.json` (labels now match days clear). "Lower the bar" is Day 4 and opens Mon 9 Nov |
| SOS | "Breathe in… 4", "Still strong" | "Breathe in", "Riding it · 0:52", "It passed", "Text a friend · I slipped" (`CravingSOSView.swift`) |
| Slip | Plan picker | "Thanks for telling me." / "Nothing resets. Here's what you still have." with the Since Quit Day and Xero's sky tiles (`SlipFlow.swift`) |
| Check-in | Violet ground | The night ground, "Sunday check-in, Day 3", "3 waves today. How was the rest of the day?" (`CheckInView.swift`) |
| Live Activity | Not drawn | `CravingLiveActivity`: "Riding it out with Jelli", "Breathe in for 4, out for 6", the time ridden counting up, "It passed" and "Open" |

Dates are in en_US format ("Sun, Nov 8"), because that is how the app formats them on a US device.

## Persona and numbers (design system §7, code-true)

Sam uses cigarettes (12 a day) and a vape. The reason is "To keep up with Maya at the park." Quit Day is Fri, Nov 6. "Today" is Sun, Nov 8, which is Day 3, stage 1, and sky clarity 28. Each screen shows its time in the status bar and uses the §7 row for that time:

| Frame | Time | Numbers |
|---|---|---|
| 1 Today | 7:30 | 3-day badge, $15 kept (the hero rounds to whole dollars), 25 cigarettes not smoked |
| 2 Quit Day | onboarding, Fri, Oct 30 | Prep Fri 30 – Thu 5, Quit Day Fri, Nov 6 |
| 3 SOS, 9 Lock Screen | 9:39 | Coffee wave, ridden 0:52 ("You've ridden 0:52", §8). The Lock Screen shows "Day 3 · $15 kept" (widgets round down) |
| 4 Slip | 9:39 | Since Quit Day 3 days, Xero's sky 28% |
| 5 Lesson | 2:00 PM | Day 3 lesson · 3 min (`readMinutes` for W1D2) |
| 6 Progress, 7 Health | 9:40 | $15.65 kept, 26 cigarettes not smoked, 15 waves ridden out, 2 check-ins, $7 a day, about $2,555 a year |
| 8 Check-in | 9:30 PM | 3 waves today, 3 ridden out |
| 10 Finale | — | The Week 4 row: 28 days, 61 waves, 26 check-ins, $196.00 kept, 336 cigarettes not smoked |

Frame 4 is the alternative branch of the Day 3 SOS, as in F15: Sam taps "I slipped" instead of "It passed". On the main branch the persona rides all 3 waves out.

## The ten frames

Frames 1–3 are the search-result set: promise, mechanic, help. The order follows the coordinator's update of 20 Nov, which built on `reports/App Store screenshot benchmark.md`.

| # | Headline | Subhead | UI shown | Rationale (research) | App Review notes |
|---|---|---|---|---|---|
| 1 | Quit nicotine on a day you **choose** | Cigarettes · Vapes · Pouches | Today, Day 3 at 7:30: the 3-day badge, $15 kept, 25 cigarettes not smoked. Outside the phone, Xero rises over a dawn horizon that runs on into frame 2 | Frame 1 carries the promise plus the hero counter (specs §4, group A). "Cigarettes · Vapes · Pouches" claims the unowned gap of all three products in one app (quit_apps Q3 gap 3) | Fine print: "Requires a DayXero Pro subscription." (2.3.2). No price, "free" or trial text |
| 2 | Prep for 7 days. Then **quit.** | Keep using as normal while you get ready for Quit Day. | Quit Day picker (onboarding 010): "Pick your Quit Day, Sam", the prep week Fri 30 – Thu 5 and Fri, Nov 6 "Quit Day set". The prep week card is lifted out | A visible prep → Quit Day timeline is the clearest open gap in the category (quit_apps gap 1, refresh: still open). Pairs with frame 1 as a flat, continuous horizon, not a tilted-phone panorama, which is overused in quit apps (report) | None |
| 3 | A craving? Ride it **out** with Jelli. | Most cravings pass within a few minutes. | Craving SOS: Jelli in the breathing ring, "Breathe in", "Riding it · 0:52", the reason card, "It passed". Jelli also floats in the swell outside the phone | A Craving SOS hero in the top 3 is open ground (quit_apps gap 5; Exhale buries it in slot 5). The subhead is §8's approved line | The subhead is guidance, not an efficacy claim. No countdown and no prediction (§8) |
| 4 | Slipped? Nothing **resets.** | Your days clear stay. You get a plan for next time. | Slip, step 1: "Thanks for telling me." and "Nothing resets." The Since Quit Day "3 days" and Xero's sky "28%" tiles are lifted out | The most original message in the category: every rival counter is a streak (quit_apps gap 2; the refresh says the gap is narrower but still open). The short form beats "A slip never resets your days" at 230 px | Calm, neutral surface per the seriousness tiers. No guilt language |
| 5 | 3 minutes a **day** | One short lesson a day, in order. No rush. | Lesson intro: "Day 3 lesson · 3 min", "The noisy passengers", "Let them talk. Keep driving." A Week 1 card is lifted out with the real titles and unlock days | The time-boxed session answers the effort objection. Kwit now leads with "5 minutes a day", so it is kept out of the top 3 (refresh) | Sessions are paid, as is everything (see the note under this table) |
| 6 | See what you've **kept** | Money, cigarettes not smoked and waves ridden out. | Progress at 9:40: the header and badges (1, 3 earned; 7 next; 14 locked). A card shows Xero's sky at 28%, $15.65 kept so far, 26 / 15 / 2 check-ins, and "$7 a day, about $2,555 a year." | Money kept is table stakes (11 of 11 quit sets); waves ridden out is DayXero's own metric | In-app stats, not pricing (specs §2) |
| 7 | What's changing in your **body** | Timings quoted from the American Cancer Society. | What's changing, Day 3, Smoking: heart rate (done), carbon monoxide (under way), taste, fresher breath, circulation. Lifted card: "Happening now · A few days / Carbon monoxide in your blood drops to normal / More oxygen reaches your body. / Source: American Cancer Society" | Health recovery appears in 6 of 11 quit sets, but none cite a source. Honest, sourced proof replaces laurels (quit_apps gap 6; report: "honest proof only") | Copy quoted verbatim from `health-timeline.json` (`carbon-monoxide`, source `acs`). No numeric efficacy (1.4.1) |
| 8 | Hard evening? Glim checks **in.** | A one-minute check-in, then rest. | Check-in at 9:30 PM: Glim under the night sky, "Sunday check-in, Day 3", "3 waves today. How was the rest of the day?", Clear day. The mood faces (Good picked) are lifted out | The dark-mode shot Apple suggests, and a character voice in the Stardust vein (group A). "Evenings are hardest" was cut to fit two lines and to avoid a general claim | None |
| 9 | SOS on your **Lock Screen** | Start from a widget. Ride it out from the Live Activity. | Lock Screen at 9:39: inline widget "Day 3 · $15 kept", the SOS circular widget, and the SOS Live Activity (lifted out) | None of the 30+ benchmarked sets shows a Live Activity, and only NRC shows widgets (group A and B, refresh) | The wallpaper is DayXero's own dawn art. The clock is DM Sans, because SF can't be bundled; no Apple UI is imitated beyond the system layout |
| 10 | 28 days. Clear **skies.** | Private on this phone. No guilt, ever. | Finale: the clear dawn, Xero, Jelli and Glim, "Week 4 · program complete · Thu, Dec 3", tiles 28 / 61 / 26, "$196.00 kept and 336 cigarettes not smoked. Your reason: …", and the health card with its source | The payoff closer, with privacy as the trust close (Flo, group A). Confetti only here (§4.1) | Fine print repeated: "Requires a DayXero Pro subscription." |

**2.3.2 (paid features).** `docs/MONETISATION_TIERS.md` was superseded on 16 Nov: DayXero now has a **hard paywall**. Nothing in the app is free, and S33.5 locks Craving SOS too. The report's "prep week, counter and SOS are free" no longer holds. Every frame therefore shows a paid feature. A "Pro" tag on the session frame alone would imply the other frames are free, which is less honest. The set says it once, at each end: frames 1 and 10 carry "Requires a DayXero Pro subscription." (the in-app product name, `PaywallOffer.swift`). The App Store's own "In-App Purchases" label and the description should say the same. To label every frame instead, add `fine: '…'` to each entry in `frames.js`.

**Hard rules check:**
- No "#1", laurels, Apple badges, press logos, ratings or user counts.
- No prices, and no "free" or trial text.
- No efficacy claims, and no exclamation marks in captions.
- No cigarettes, vapes or pouches are pictured; the products appear as words only.
- The app's "N days free" labels (Progress hero, Today's slim header, milestones) are kept out of frame. Frame 6's card covers the Progress hero; it was not edited away.

## What to test first in Product Page Optimization

1. **Slot 3: the slip rule vs SOS.** Move frame 4 ("Slipped? Nothing resets.") into slot 3. It is the category's most original message, and slot 3 is the last search-visible frame (report, PPO test 2).
2. **Frame 1 headline:** "Quit nicotine on a day you choose" against a keyword-led variant, "Quit vaping, smoking or pouches", on the same UI (report, PPO test 1). Both are one `title` edit.
3. **Character-forward vs character-light** frames 1–3: drop the outside Xero and Jelli and keep the UI. This tests the risk the design system flags for older, heavy smokers (§4.3).

## Open items

- **Finale numbers.** `FinaleView` actually opens with the graduation session (W4S3, label "Day 31", Sun, Dec 6, 31 days clear, $211.45, 362 at 09:00). The frame uses the Week 4 row of §7 (28 days, Thu, Dec 3), as briefed. §7 still doesn't define waves or check-ins for Dec 6. Once it does, change the finale screen and the frame-10 headline together.
- **"days free" vs "days clear".** The app labels the count "N days free" in Progress, Today and milestones. §7's one-label rule says "days clear". In a screenshot, "days free" can read as a free trial. Renaming it in the app would let frame 6 show the real Progress hero.
- **The Lock Screen** is drawn from the widget code, not captured from a device. Replace it with a device capture before submission if possible.
- Before submission, check every frame against a current build. The v5 restyle is still moving, for example the SOS break menu that appears from Day 9.
