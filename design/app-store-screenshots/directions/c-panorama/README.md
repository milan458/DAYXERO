# DayXero App Store screenshots, Direction C: "The sky clears"

All ten frames are slices of **one continuous landscape**: 4400 × 956 CSS px, or 13200 × 2868 at 3x. Read left to right, it travels through the crew's realms and a full day. It starts in a hazy dawn where Xero rises, follows the prep path to the Quit Day flag, crosses Jelli's sea and the day's meadow, reaches dusk where Xero sets, then night where Glim lights the dark, and ends at the next dawn, fully clear. The haze follows design system §3, "the sky clears as you do": clarity is 20 at the centre of frame 1 and rises evenly to 100 at frame 10. Haze is heavier on far layers than near ones, so the clearing also reads as depth.

How it differs from Direction A ("the crew"):

| | Direction A | Direction C |
|---|---|---|
| Ground | One flat colour per character, per frame | One painted landscape that runs across all ten frames |
| Phones | Large (0.82–0.84), the hero | Smaller (0.62), flat, centred, the same in every frame. The landscape is the hero |
| Characters | Inside each frame | They straddle the seams to pull the eye to the next frame (Stardust style): Xero at 1/2, Jelli at 3/4, Xero setting at 7/8, Glim at 8/9, Xero risen at 9/10 |
| Captions | Hand-drawn underline on one word | One plain type style. Ink, or cream at night, with every pixel behind the text measured |
| Frames 1–3 | Three separate cards | One billboard in search: dawn, path and sea run through all three (Sleep Cycle and Ladder style). Frame 1 still carries the whole promise on its own |

## Exports

| File | What it is |
|---|---|
| `export/iphone-6.9/01.png … 10.png` | 1320 × 2868, the iPhone 6.9" class |
| `export/iphone-6.3/01.png … 10.png` | 1206 × 2622, the iPhone 6.3" class. Rendered natively, not resampled |
| `export/contact-sheet.png` | All ten at 300 px, butted edge to edge with no gaps, so the panorama reads as one strip |
| `export/contact-sheet-gapped.png` | All ten with 14 px gaps and rounded corners, the way the product page spaces them |
| `export/contact-sheet-search.png` | Frames 1–3 at 230 px, the size of a search result |
| `export/panorama-art.png` | The art alone, 6600 × 1434 (half size), for review only. Not an App Store asset |

Every frame PNG and contact sheet is 8-bit RGB with no alpha channel and carries an sRGB chunk. The pipeline is the same as Direction A's `render.mjs`, which also fails the render if Bricolage Grotesque or DM Sans didn't load.

## The ten frames

Every phone shows the real app screen, reused unchanged from Direction A. Those screens were checked against the Swift source and use the persona values of design system §7: Sam, Quit Day Fri, Nov 6, "today" Sun, Nov 8 (Day 3).

| # | Realm and time | Clarity | Headline | Subhead | Screen (status-bar time) | Lifted piece |
|---|---|---|---|---|---|---|
| 1 | Hazy dawn. Xero rises at the seam with frame 2 | 20 | Quit nicotine on a day you choose | Cigarettes · Vapes · Pouches. Fine print: "Requires a DayXero Pro subscription." | Today (7:30): 3-day badge, $15 kept, 25 cigarettes not smoked | none |
| 2 | Morning. Seven stones, one per prep day, lead along the foreground to the Quit Day flag on the headland | 29 | Prep for 7 days. Then quit. | Keep using as normal while you get ready for Quit Day. | Quit Day picker: the prep week Fri 30 – Thu 5, Fri, Nov 6 | The prep-week card, zoomed over itself |
| 3 | The sea. Jelli rides the swell at the seam with frame 4 | 38 | A craving? Ride the wave. | Breathe with Jelli. Most cravings pass within a few minutes. | Craving SOS (9:39): "Breathe in", "Riding it · 0:52", the reason card | none |
| 4 | Calm water, with the day's sun at the seam with frame 5 | 47 | Slipped? Nothing resets. | Your sky stays clearer. You get a plan for next time. | Slip (9:39): "Thanks for telling me.", "Slips don't cloud it." | The Since Quit Day "3 days" and Xero's sky "28%" tiles |
| 5 | Back on land. The program road starts across the meadow | 56 | 3 minutes a day | One short lesson a day, in order. No rush. | Lesson (2:00): "Day 3 lesson · 3 min", "The noisy passengers" | none |
| 6 | Meadow, trees | 64 | See what you've kept | Money, cigarettes not smoked and waves ridden out. | Progress (9:40) | The kept card: $15.65, 26 / 15 / 2, "$7 a day, about $2,555 a year." It covers the Progress hero, which says "days free" |
| 7 | Late afternoon. The light turns gold toward dusk | 73 | What's changing in your body | Timings quoted from the American Cancer Society. | What's changing (9:40): the Carbon monoxide row under way | "Carbon monoxide in your blood drops to normal / More oxygen reaches your body. / Source: American Cancer Society", quoted from `health-timeline.json` (`carbon-monoxide`, source `acs`) |
| 8 | Dusk into night. Xero sets at the 7/8 seam, Glim lights up at the 8/9 seam, and the moon rises | 82 | Hard evening? Glim checks in. | A one-minute check-in, then rest. | Check-in (9:30 PM): "3 waves today. How was the rest of the day?" | none |
| 9 | Night, fireflies | 91 | SOS on your Lock Screen | Start from a widget. Ride it out from the Live Activity. | Lock Screen: "Day 3 · $15 kept", the SOS widget | The SOS Live Activity, "Riding it out with Jelli · 0:52" |
| 10 | The next dawn, fully clear. Xero is risen (stage 4), Jelli and Glim join, and confetti appears (finale only, §4.1) | 100 | 28 days. Clear skies. | Private on this phone. No guilt, ever. Fine print: "Requires a DayXero Pro subscription." | Finale: Week 4, Thu, Dec 3, 28 / 61 / 26, $196.00 and 336 cigarettes | none |

Notes on the copy:
- **Frame 2** keeps a short caption rather than going uncaptioned. The benchmark report warns that an empty slot 2 wastes a search frame, and continuity already comes from the art.
- **Frame 3**'s subhead reuses §8's approved line.
- **Frame 4**'s "Your sky stays clearer" is what the slip screen shows: Xero's sky stays at 28% and "Slips don't cloud it."

## Hard rules check

- Every frame shows the real app UI (2.3.3). All numbers are the §7 persona values already in the screens; nothing is new.
- None of the following appear: "#1", awards, laurels, Apple badges, press logos, ratings, user counts, prices, "free" or trial text, or efficacy claims.
- No cigarettes, vapes or pouches are pictured.
- No exclamation marks. "days free" never appears in frame: frame 6's card covers the Progress hero, as in Direction A.
- The health copy is quoted verbatim from `DayXeroCore/Resources/health-timeline.json`, with its source.
- Frames 1 and 10 carry "Requires a DayXero Pro subscription." (hard paywall).

## Checks (`node check.mjs`)

1. **Seams.** The script renders the whole panorama once at 13200 × 2868 (`src/pano.html`) and compares each 1320 px slice with that frame's art rendered on its own. The mean difference is at most 0.1 of 255, and at most 0.006% of pixels differ by more than 16. Those few pixels are anti-aliasing at a character's edge, because Chromium tiles a 13200 px layer differently from a 1320 px one; a shifted slice would differ along every edge. In both exports, the step across each seam is smaller than the step between two neighbouring columns inside a frame: worst seam 0.51 against 0.83 inside a frame at 6.9", and 0.55 against 0.88 at 6.3".
2. **Caption contrast.** For every caption line box, the script measures the WCAG ratio of the caption colour against every pixel behind it, with the frame rendered without its caption. The lowest values are 5.73 (frame 8, cream on dusk violet) and 6.53 (frame 10, ink on coral). Frames 1–7 are 8.6 or higher, and frame 9 is 13.9. Every frame passes 4.5:1.

## Edit and re-render

```
cd design/app-store-screenshots/directions/c-panorama/src
node render.mjs              # all ten frames, both sizes, then the three contact sheets
node render.mjs 03 07        # just these frames (contact sheets are rebuilt from whatever is in ../export/)
node render.mjs --size 6.9   # one size only
node check.mjs               # seams + caption contrast; also writes ../export/panorama-art.png
```

You need Playwright with Chromium. There are no other dependencies.

| File | What it is |
|---|---|
| `src/pano.js` | **The landscape.** One generator for the whole 4400 px scene, in two layers. `back` holds the sky, glows, clouds, stars, far hills, sea, mid and near hills, and the rising and setting Xero. `front` holds the foreground ridge, the near waves, the paths, Jelli, Glim, the finale crew and the confetti. Colours ramp along x in OKLab, and every layer is hazed by `clarity(x)`. Character positions are in panorama coordinates. |
| `src/frames.js` | **The frames as data:** caption, tone (ink or cream), screen, time and the lifted piece, plus the builder. Each frame draws the panorama shifted left by 440 px × its index, so the art meets exactly at every seam. `PHONE` sets the phone size and position for all frames. |
| `src/frames.css` | The caption style, the CSS iPhone, and the breakout cards |
| `src/frame.html` | `frame.html?f=05` previews a frame at 440 × 956. `&art=1` shows the art only, `&nocap=1` hides the caption |
| `src/pano.html` | The whole panorama, art only, at 4400 × 956 |
| `src/render.mjs`, `src/check.mjs` | The render and the checks |
| `src/app/`, `src/fonts/` | Unchanged copies of Direction A's app screens, kit and bundled fonts |

To change the sky, edit the `zen` (top) and `hor` (horizon) ramps in `pano.js`. The caption band keeps the `zen` colour. If you move where the sky turns dark (around x 3010–3160) or light again (around x 3868–4036), run `check.mjs`. Those switches have to fall between the captions of frames 7/8 and 9/10.

## Known limits and open items

- **The sky changes at two seams.** The caption flips from ink to cream between frames 7 and 8, and back between 9 and 10. The sky has to cross from light to dark between the two captions, so the sky changes quickly near those seams. The 9→10 change reads as sunrise, because the horizon turns pink first and Xero's glow sits on the seam. In the butted contact sheet it is still visible as a soft vertical band.
- **Frame 9 sits in the night art, but the Lock Screen shows 9:39** (the morning coffee wave) and its own dawn wallpaper. These are the persona-true Live Activity state and time. The landscape is the journey's metaphor, not the clock. If that reads as a contradiction, swap frames 8 and 9, or re-time the night art.
- The **Lock Screen** is still drawn from the widget code, not captured from a device. The **finale** numbers keep the §7 Week 4 row. The open items from Direction A's README apply here too.
- **At 0.62 scale, the small text inside the phones is not legible** on the product page. Each frame's key fact is carried by the caption, by a lifted piece (frames 2, 4, 6, 7, 9), or by a screen's large type (the 3, "Breathe in", the lesson title, 28 days).
- **Worth testing in Product Page Optimization:** this set against Direction A for frames 1–3, since panorama billboard and character colour are the cleanest split. Also test a version where the half-Xero at the 1/2 seam moves fully into frame 1, for listings where only frame 1 shows.
