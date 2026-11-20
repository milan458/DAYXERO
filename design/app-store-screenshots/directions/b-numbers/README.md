# DayXero App Store screenshots, Direction B: "Proof in numbers"

An alternative 10-frame iPhone set that leads with outcomes and counters instead of the crew. It sits beside Direction A (the original set in `../../src/`, character-led and colour-per-character) for comparison and PPO testing.

| Folder | Size | Device class in App Store Connect |
|---|---|---|
| `export/iphone-6.9/01.png … 10.png` | 1320 × 2868 | iPhone with Dynamic Island (large display) |
| `export/iphone-6.3/01.png … 10.png` | 1206 × 2622 | iPhone with Dynamic Island (medium display), the "required" class |
| `export/contact-sheet.png` | all ten at 300 px wide | |
| `export/contact-sheet-search.png` | frames 1–3 at 230 px wide (search-result size) | |

All PNGs are 8-bit RGB with no alpha channel and carry an sRGB chunk. Both sizes are rendered natively from the same layout. The render fails if Bricolage Grotesque or DM Sans doesn't load.

## The direction

Archetype: the outcome-first sets that lead with a hard, personal number. Cal AI says the whole idea in a few words, Quit Vaping uses two-tone two-line headlines with a grey subhead and one floating chip per frame, Noom uses a dated personal prediction, and Smoke Free and I Am Sober make the counter the hero.

- **One ground, one accent.** Every frame sits on the app's night navy (#0F1B33 down to #0B1428), with a faint chart-grid back plate and a low coral glow behind the phone. Coral #FF7A55 is the only accent. It colours the second line of every headline and every number outside the phone.
- **Two-tone, two-line, left-aligned headlines** in Bricolage Grotesque 800 at 50 px on the 440 px stage (56 px on frame 1, 48 px on frame 7). The accent line carries the number. Subheads are DM Sans 18 px in #AEB8D3.
- **The app in its own Dark Mode** (`?theme=dark`, the kit's v5 "midnight" values, which `Ground.swift` ships). SOS stays on its lit ocean, the check-in is on the night ground in both modes, and the Lock Screen uses the dawn wallpaper. These three are the only colour in the set besides coral, and each one belongs to the app.
- **Flat phones, bigger and bleeding off the bottom edge** (k = 0.80, top 300 px on the stage), with a lighter titanium rim so the dark UI separates from the dark ground. There is no tilt and no panorama.
- **One breakout per frame.** It is either a *proof bar* or a *lifted element*. A proof bar is a navy card that crosses the phone edge to edge, with a big coral number, a dated kicker such as "DAY 3 · 9:39 AM" and a short label. A lifted element is a real element of the screen, magnified out of the phone (frames 4, 6 and 9). Every proof-bar number is also on the screen in the same frame.
- **Characters only at avatar size** outside the phone (Jelli on frame 3, Glim on frame 8). The crew appear only inside the app UI.

How it differs from Direction A: dark across all ten frames instead of seven colour grounds; left-aligned two-tone type with no hand-drawn underline; numbers as the headline instead of a promise; dark-mode UI; bleeding phones with crossing proof bars instead of framed phones over illustrated horizons, sea and confetti.

## The ten frames

Persona and numbers follow design system §7 (code-true values from decision 17) and the persona block at the top of `src/frames.js`. Sam uses cigarettes (12 a day) and a vape. Quit Day is Fri, Nov 6, and "today" is Sun, Nov 8, which is Day 3. Each screen shows its time in the status bar, and every number in the frame comes from that time's row.

| # | Headline (coral line in **bold**) | Subhead | UI shown | Breakout | Numbers and source | Rationale |
|---|---|---|---|---|---|---|
| 1 | 28 days clear. **$196 kept.** | Quit cigarettes, vapes and pouches. *Fine print: Requires a DayXero Pro subscription.* | Finale, dark, 9:41. "Week 4 · program complete · Thu, Dec 3", "28 days. Clear skies.", tiles 28 / 61 / 26, "$196.00 kept and 336 cigarettes not smoked. Your reason: …" | Proof bar over the health card: **336** · "Week 4 · Thu, Dec 3" · cigarettes not smoked | §7 Week 4 finale row: 28 days clear, $196, 336, 61 waves, 26 check-ins. All of them are on the screen | Cal AI-style outcome-first claim in about six words. The products appear as words only, to claim the gap of all three in one app. Works at 230 px (search sheet) |
| 2 | 7 days of prep. **Then Day 1.** | Keep using as normal while you get ready. Then quit on the day you chose. | Quit Day picker (onboarding), dark: "Pick your Quit Day, Sam", prep week Today 30 – Thu 5, "7 short sessions", "Fri, Nov 6 · Quit Day set" | Proof bar over Xero's hill: **Nov 6** · "Your Quit Day" · Friday, after 7 short prep sessions | §7: joined Fri, Oct 30 (prep day 1), Quit Day Fri, Nov 6 = Day 1 ("days clear counts Quit Day"). "7 short sessions" is on screen | The prep-to-Quit-Day mechanic as a countdown in numbers, Noom's dated-plan pattern. The subhead is the approved "keep using as normal" line |
| 3 | A craving? **Ride it out.** | Most cravings pass within a few minutes. Breathe with Jelli while it does. | Craving SOS (ocean), 9:39: Jelli in the breathing ring, "Breathe in", "Riding it · 0:52", "It passed", "Text a friend · I slipped" | Proof bar over the reason line: **0:52** · "Day 3 · 9:39 AM" · ridden so far, with a Jelli avatar | §8: "You've ridden 0:52" is time ridden, counted up, not a countdown. The coffee wave comes around 9:40 (§7) | SOS in the top three is open ground. The subhead is §8's approved guidance, not an efficacy claim |
| 4 | Slipped? **Still 3 days clear.** | Nothing resets. Your days clear and Xero's sky stay just as they are. | Slip step 1, dark, 9:39: "Thanks for telling me.", "Nothing resets. Here's what you still have." | Lifted: the "Since Quit Day 3 days" and "Xero's sky 28% clear" tiles (×1.18) | Day 3. Sky clarity = round(20 + 2.8 × 3) = 28 (§7) | The category's most original message, stated as a number. The subhead paraphrases the approved slip string |
| 5 | 26 cigarettes **not smoked.** | Money kept, cigarettes not smoked and waves ridden out, counted for you. | Progress, dark, 9:40: the stats row "26 cigarettes not smoked · 15 waves ridden", badges 1 and 3 (earned), 7 (next), 14 (locked) | Proof card over the Progress hero: "3 days clear · Sun, Nov 8 · 9:40 AM", **$15.65** kept so far, and the since-Quit-Day strip (Quit Day, Sat, Today, then Mon–Fri) | §7 09:40 row: 26 not smoked, $15.65 kept, 15 waves | Money and cigarettes are table stakes (11 of 11 quit sets). The card **covers the app's "3 days free" hero and its "Each day free…" note**, so no "free" label shows (see open items) |
| 6 | 3 minutes. **One lesson a day.** | A short read, a few taps and one small thing to try today. | Lesson intro, dark, 2:00: "Day 3 lesson · 3 min", "The noisy passengers", "Let them talk. Keep driving." | Lifted: the three-row list "A short read · Four cards, about 2 min / A few activities · Quick taps, about 1 min / Today's mission" (×1.16) | `readMinutes` 3 for W1D2, labelled Day 3 in `program.json` (as in A) | The time-boxed session answers the effort objection. The lifted list shows where the 3 minutes go (2 + 1) |
| 7 | What's changing **on Day 3.** | Timings quoted from the American Cancer Society. | What's changing, dark, 9:40: "Day 3 · your body since Quit Day", Smoking tab, heart rate (done), carbon monoxide (under way), taste, breath, circulation | Quote card lifted over the CO row: "Happening now · Day 3", **A few days**, "Carbon monoxide in your blood drops to normal", "Source: American Cancer Society" | `health-timeline.json` → `smoking` / `carbon-monoxide` (`when` "A few days", 12–72 h, source `acs`). At 09:40 on Day 3, about 53 h after the Quit Day boundary, it is under way | Sourced, honest proof instead of laurels. The health copy is quoted verbatim, with no numeric efficacy |
| 8 | 3 waves today. **3 ridden out.** | Glim checks in each evening. One minute, then rest. | Check-in (night), 9:30 PM: Glim, "Sunday check-in, Day 3", "3 waves today. How was the rest of the day?", Clear day, the mood faces (Good) | Proof bar over the waves row: **3 of 3** · "Day 3 · 9:30 PM" · waves ridden out today, with a Glim avatar | §7: Day 3 cravings, 3 logged and 3 ridden out. The check-in reminder is at 21:30 (§8) | The dark shot doubles as the day's tally. The subhead echoes the approved reminder "One minute, if you have it." |
| 9 | SOS on your **Lock Screen.** | Start from a widget. Ride it out in the Live Activity, timer running. | Lock Screen, Sun 8, 9:39: inline widget "Day 3 · $15 kept", the SOS circular widget, the Live Activity | Lifted: the `CravingLiveActivity` card, "Riding it out with Jelli", "Breathe in for 4, out for 6", **0:52**, "It passed" / "Open" (×1.15) | 9:39 and 0:52 (§8). Widgets round $15.02 down to $15 | No benchmarked set shows a Live Activity. The 9:39 clock face reads as a number at thumbnail size |
| 10 | You pick the day. **We keep count.** | Private on this phone. No guilt, ever. *Fine print: Requires a DayXero Pro subscription.* | Today, dark, 7:30: the Day 3 ring, "Sun, Nov 8", "Good morning, Sam", "3-day badge earned", "$15 kept • 25 cigarettes not smoked", "4 days to your 7-day badge" | Proof bar over the "Now" card: **3** · "Sun, Nov 8 · 7:30 AM" · days clear. 3-day badge earned. | §7 07:30 row: 25 not smoked, $15.02 ($15 in the hero). Day 3 milestone | A counter-as-hero closer, the Smoke Free and I Am Sober pattern. Privacy and no guilt make the trust close, using approved phrases ("stays private on this phone", "No guilt, ever") |

Search set (frames 1–3): outcome → mechanic → help. Each one reads alone at 230 px. The coral line and the big number are legible in `export/contact-sheet-search.png`.

## Rule check

- Every frame shows real app UI (2.3.3): the persona-true v5 screens from Direction A in the app's own Dark Mode, or their light ground where the screen has no dark variant (SOS, check-in, Lock Screen). Breakouts are either lifted pieces of the same screen, or cards that restate numbers already on the screen.
- No "#1", awards, laurels, Apple badges, press logos, ratings, user counts, prices, "free" or trial text, and no efficacy or success-rate claims. No exclamation marks. The dollar figures are money kept (in-app stats), never prices. "$7 a day" was left out because it could read as a price.
- No cigarettes, vapes or pouches are pictured; the products appear as words only.
- Health copy is quoted from `DayXeroCore/Resources/health-timeline.json` with its source label.
- The hard paywall is stated once at each end: frames 1 and 10 carry "Requires a DayXero Pro subscription.", as in Direction A.
- "days free" is not visible in any frame. The Progress hero and its note in frame 5 are covered by the proof card, not edited. The captions say "days clear".

## Edit and re-render

```
cd design/app-store-screenshots/directions/b-numbers/src
node render.mjs              # all ten frames, both sizes, then the contact sheets
node render.mjs 03 07        # just these frames (the contact sheets are rebuilt from whatever is in ../export/)
node render.mjs --size 6.9   # one size only
```

You need Playwright with Chromium (`require('playwright')`), the same as Direction A. The script serves `src/` locally and waits for every iframe and font. It writes RGB PNGs with an sRGB chunk to `../export/`.

| File | What it is |
|---|---|
| `src/frames.js` | **Edit here.** The ten frames as data: `title` (`<em>` = coral line), `sub`, `fine`, `screen`, `time`, `theme`, `phone`, and one breakout (`proof` bar or `zoom`). Plus the builder |
| `src/frames.css` | Ground, caption type, phone, the proof bar (and its `stack`, `cover` and `tall` variants), lifted elements |
| `src/frame.html` | The templated page: `frame.html?f=05` at 440 × 956 |
| `src/render.mjs` | Renderer and contact sheets (same pipeline as Direction A) |
| `src/app/` | The kit and the ten persona-true screens, copied unchanged from Direction A. `?theme=dark` is the kit's own Dark Mode |
| `src/fonts/` | Bricolage Grotesque and DM Sans (SIL OFL), bundled |

Proof bar placement: `proof: { top }` places it at a fixed stage y. `proof: { anchor: { sel, dy } }` places it over an element of the screen. `proof: { cover: sel, pad }` sizes a card over an element (frame 5). Zooms work as in A: `zoom: { sel, scale, dx, dy }`.

## What to test first in PPO

1. **Direction B vs Direction A as a whole** (frames 1–3 swapped together): is outcome-first stronger than character-first for older, heavier users?
2. **Frame 1's number.** "28 days clear. $196 kept." against a Day 3 version ("3 days clear. $15 kept."), which is closer to what a new user sees soon after Quit Day.
3. **Slot 3:** frame 4 ("Slipped? Still 3 days clear.") in place of SOS.

## Open items and limits

- **Finale numbers** carry over Direction A's note: `FinaleView` opens with graduation (Day 31, Sun, Dec 6). The set uses §7's Week 4 row (Thu, Dec 3), as briefed. Once §7 defines waves and check-ins for Dec 6, update frame 1's screen and headline together.
- **"days free" in the app.** The Progress hero and note say "days free". Frame 5 covers them. Renaming the label to "days clear" in the app would let the hero show.
- **The finale in Dark Mode** is the kit's dark rendering of `FinaleView` (night dawn scene). Confirm it against a current build in Dark Mode, as for every frame.
- **The Lock Screen** is drawn from the widget code, not captured from a device (same as A). Its dark variant in the kit is unfinished, so frame 9 uses the dawn wallpaper.
- Frame 6's lifted list leaves a sliver of the "Begin" button visible beneath it. That is the real button behind the card, not a rendering fault.
