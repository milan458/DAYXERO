# DayXero App Store screenshots: Direction D, "Calm and credible"

This is an alternative ten-frame iPhone set in the editorial, character-light school of Flo, Clue, Oura and Noom. It is the store version of the character-light variant that the design system proposes in §4.3. That section flags the risk that older, heavy smokers read cartoons as "not for me".

| Folder | Size | App Store Connect class |
|---|---|---|
| `export/iphone-6.9/01.png … 10.png` | 1320 × 2868 | iPhone with Dynamic Island (large display) |
| `export/iphone-6.3/01.png … 10.png` | 1206 × 2622 | iPhone with Dynamic Island (medium display), the required class |

`export/contact-sheet.png` shows all ten at 300 px. `export/contact-sheet-search.png` shows frames 1–3 at 230 px, the search-result size. Every PNG is 8-bit RGB with no alpha and carries an sRGB chunk. Both sizes are rendered natively from one layout.

## How it differs from Direction A ("the crew")

| | A, the crew | D, calm and credible |
|---|---|---|
| Ground | A colour per character: apricot, ocean, mint, night, sun | One cream reading ground (#FBF7F1) that fades to surf (#F1EBE2) at the foot of every frame |
| Type | Bricolage 800, centred, a hand-drawn coral underline | Bricolage **700**, set left, with one accent phrase in the good green **#0F6E43** (6:1 on cream). DM Sans 500 for the subheads |
| UI | A framed CSS iPhone in every frame, plus a zoom breakout | **Frameless**: crops of the real screens, floated as sheets and cards with soft shadows. Callouts are magnified in place (a "lens"). The only phone is on frame 9, because the Lock Screen needs a device to read as one |
| Characters | Xero, Jelli and Glim outside the phones, at 130–180 px | None in frame. Crops are chosen to leave the characters out. What remains is the 30–34 px avatar the UI itself carries: Jelli in the Live Activity and Xero in the privacy tile |
| Trust | Implied by tone | Stated in small trust chips with the app's own words: "Cigarettes · Vapes · Pouches", "No guilt, ever", "Private on this phone", "Your reason stays on this phone", and "Source: American Cancer Society" on the health frame. The user's own reason appears on frames 3 and 10 |

## Re-render

```
cd design/app-store-screenshots/directions/d-editorial/src
node render.mjs              # all ten frames, both sizes, then the contact sheets
node render.mjs 03 07        # just these frames (the contact sheets are rebuilt from whatever is in ../export/)
node render.mjs --size 6.9   # one size only
```

You need Playwright with Chromium. The pipeline is Direction A's `render.mjs`. It runs a local server, waits until every iframe has finished its still render, and fails if Bricolage Grotesque (700) or DM Sans hasn't loaded. It writes RGB PNGs with an sRGB chunk. Preview a frame by serving `src/` and opening `frame.html?f=05` at 440 × 956.

| File | What it is |
|---|---|
| `src/frames.js` | **Edit here.** The ten frames as data (headline, subhead, chips, fine print, pieces), followed by the builder |
| `src/frames.css` | The ground, the caption type, trust chips, the lifted-piece shadows, the slim phone for frame 9 and the Week 1 card |
| `src/frame.html` | The one templated page |
| `src/render.mjs` | The renderer. It is Direction A's, with the font check moved to weight 700 |
| `src/app/screens/*.html` | Direction A's persona-true v5 screens, unchanged, plus **`privacy.html`** (new; see below) |
| `src/app/kit/`, `src/fonts/` | Unchanged copies |

**Piece syntax** (in `frames.js`): `{ s: 'health', t: '9:40', rect: [x, y, w, h] | sel: '.card.item.now', pad, k: scale, x: left | 'c', y: top, r: radius, cls: 'sm', z }`. A piece is an iframe of the real screen, cropped to `rect` or to the element `sel`, and scaled by `k`. Add `of: <piece index>` or `of: 'phone'` to make it a lens. A lens is magnified in place, centred on where the element sits in that base piece, and nudged by `dx`/`dy`. Headline syntax: `<g>…</g>` sets the green accent phrase and `<br>` forces a break. `size:` overrides the 51 px headline (frame 1 uses 54, frame 6 uses 50).

## The ten frames

Frames 1–3 are the search set: the promise, the mechanic, then help. The order is the same as Direction A's, so the two directions can be tested against each other in PPO.

| # | Headline (green phrase in **bold**) | Subhead · chips | UI shown (all crops of real screens) | Notes |
|---|---|---|---|---|
| 1 | A calmer way to quit **nicotine** | Prepare for a week, then quit on a day you choose. · *Cigarettes · Vapes · Pouches* · fine print | Today at 7:30, cropped below the hero: "Good morning, Sam", "3-day badge earned", "$15 kept · 25 cigarettes not smoked", "4 days to your 7-day badge", Now, the tab bar. The 3-day badge disc is lifted out as a circle (Xero, who stands beside it, stays out) | 54 px headline for thumbnail legibility. Fine print: "Requires a DayXero Pro subscription." |
| 2 | Choose your **Quit Day** | Prep for 7 days first. Keep using as normal until then. · *You can change it later* | Onboarding 010 in three parts: the title "Pick your Quit Day, Sam" and the lead; the prep-week card (Fri 30 – Thu 5, "Fri, Nov 6 · Quit Day set") lifted at 1.1×; the dock with Continue and "Quit Day comes on this date, even if prep runs short. You can change it later." | Xero, below the card, is out of frame. The chip quotes the dock |
| 3 | When a craving hits, **breathe.** | Breathe in for 4, out for 6. Most cravings pass in a few minutes. · *Your reason stays on this phone* | Craving SOS at 9:39, cropped just below Jelli. It shows the lower arc of the breathing ring, "Breathe in", the reason card ("To keep up with Maya at the park."), It passed, and Text a friend · I slipped. "Riding it · 0:52" is docked on the top edge | The subhead quotes the Live Activity ("Breathe in for 4, out for 6") and the SOS lead ("Most cravings pass in a few minutes."). It is guidance, not an efficacy claim. The chip is the onboarding line "It stays on this phone". At 0:52 the lead has faded, as the code does after 10 s |
| 4 | A slip doesn't **reset your days** | Nothing resets. Make a one-minute plan for next time. · *No guilt, ever* | SlipFlow step 1, below its Jelli art: "Thanks for telling me.", "Nothing resets. Here's what you still have.", Since Quit Day 3 days and Xero's sky 28% (magnified in place), "Slips don't cloud it.", Make a one-minute plan, Not now | This is the alternative branch of the Day 3 SOS, as in Direction A |
| 5 | Three minutes **a day** | One short lesson a day, in order. No rush. | The Day 3 lesson intro below its illustration: "Day 3 lesson · 3 min", "The noisy passengers", the short read, the activities and the mission. A Week 1 card overlaps it | The Week 1 card is Direction A's card in the app's own style (titles and unlock days from `program.json`), not a crop |
| 6 | Your progress, **in plain numbers** | Money kept, cigarettes not smoked and waves ridden out. | Progress at 9:40: "26 cigarettes not smoked", "15 waves ridden", Badges (1, 3 Today, 7 Nov 12, 14 locked) and the tab bar. "$15.65 kept so far · Sky 28% clear" is lifted from the hero card at 1.5× | The crop starts below the hero card, and the money crop stops above its count, so **"days free" is never in frame**. Xero is cropped out |
| 7 | What's changing in your **body** | Typical times, each with its source. Everyone is different. · *Source: American Cancer Society* | What's changing, Day 3, Smoking: the five cards and the in-app footnote "Typical times, everyone is different. Source: American Cancer Society". The card under way ("Carbon monoxide in your blood drops to normal · A few days") is magnified in place | Copy as rendered from `health-timeline.json` (`acs`). No numbers, no efficacy |
| 8 | One minute **each evening** | Count the day's waves, say how you feel, then rest. | Check-in at 9:30 PM below Glim: "Sunday check-in, Day 3", "3 waves today. How was the rest of the day?", Clear day, "3 waves today · 3 ridden out", the four faces (Good picked, magnified in place), Save and rest | The set's dark shot, as a sheet on cream |
| 9 | Help on your **Lock Screen** | Start SOS from a widget. Ride it out from the Live Activity. | Lock Screen in a slim, cropped phone: "Sun 8 · Day 3 · $15 kept", 9:39, the SOS widget. The SOS Live Activity ("Riding it out with Jelli", "Breathe in for 4, out for 6", 0:52, It passed, Open) is magnified in place | Jelli appears only as the Live Activity's ~30 px avatar |
| 10 | Private, and **on your side** | No account, no ads, no selling. Your plan and notes never leave this iPhone. · *Private on this phone* · *No guilt, ever* · fine print | Privacy and your data (new `privacy.html`): the lead, "It stays on this phone", and "Share anonymous usage" with its detail "Never your words." Below it, the finale's tiles 28 / 61 / 26 and "$196.00 kept and 336 cigarettes not smoked. Your reason: To keep up with Maya at the park." | The subhead quotes `PrivacySettingsView`'s lead and its card. Fine print: "Requires a DayXero Pro subscription." The finale crop starts below its three-character hero |

### `privacy.html` (new screen)

`privacy.html` is drawn from `DayXero/Settings/SettingsPages.swift`, `PrivacySettingsView` (v5, 069), with the kit and the reading ground. All of its strings are verbatim from the Swift. The usage switch is drawn **on**, because `AnalyticsConsent.defaultValue` is true outside the EU/EEA, so a US device shows it on. Showing it on is the honest default, and its line "Never your words." supports the privacy claim. The tile is `SettingsDawn` with Xero at 34 pt, drawn simply. The tile's exact Canvas art and the list's row spacing are approximations of the SwiftUI. Check them against a build.

## Rules check

- Every frame shows real app UI (2.3.3). The numbers are the §7 persona's, at each screen's own time, and none were invented.
- No "#1", awards, laurels, Apple badges, press logos, ratings, user counts, prices, "free" or trial text, and no efficacy or success-rate claims. No cigarettes, vapes or pouches are pictured; the products appear as words in the frame-1 chip only.
- The only health copy is the app's own rendering of `health-timeline.json`, and its source is visible twice on frame 7.
- Hard paywall: frames 1 and 10 carry "Requires a DayXero Pro subscription." (2.3.2), as Direction A does.
- There are no exclamation marks and no guilt language. "days free" is never in frame (frame 6 is cropped around it).
- Characters: none at illustration size. The only ones left are the avatars the UI carries: Jelli at about 30 px in the Live Activity (frame 9) and Xero at 34 px in the privacy tile (frame 10).

## Review passes done

1. **First render.** Compositions sat too high, and several callouts collided or duplicated their UI: the frame-1 badge sat on "earned", the frame-4 card covered the title, the frame-6 money card covered the stats, and the frame-8 and frame-9 callouts sat away from their originals. Moved to in-place lenses and bottom-anchored sheets.
2. **Both sizes, all frames.** Fixed the back-button sliver on frame 2, a hero-card edge under frame 6, the "skies." underline tail on frame 10, and lens widths spilling past their sheets. Then reworked frame 3: the crop now shows the ring's lower arc with the timer docked on it. An intermediate crop showed Jelli's tentacle tips, so the crop now starts at y 416.
3. **Contact sheets.** All three headlines read at 230 px, the fonts are loaded, margins are consistent, and nothing is clipped.

## Open items

- **Frame 10 mixes two moments**, Settings (any day) and the Week 4 finale (Thu, Dec 3). They are separate cards, but if App Review or the team prefers one screen per frame, drop the finale card and lift the privacy page's "Export my data" row instead.
- **The frame-5 Week 1 card is a styled card, not a crop.** No Program screen exists in `app/screens/` yet. Swap in a crop of the real Program list when one is drawn.
- **The PPO test this set enables:** A's frames 1–3 against D's frames 1–3 (character-forward versus character-light). This is test 3 in Direction A's README and the §4.3 risk. Run it with the same order and headline intent.
- As with A, check every frame against a current build before submission. That matters most for the Lock Screen, which is drawn, not captured, and for `privacy.html`.
