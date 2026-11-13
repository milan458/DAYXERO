# Cook ledger: DayXero UI/UX redesign

Started: 2026-11-13 16:50 UTC
Time: cap 2h lifted at 17:57 by the user ("keep going till it hits 9.2"); run continues until the bar is met
Bar: every screen >= 9.2 overall (light and dark), critic median after calibration
Calibration offset: anchored critics (see BRIEF); residual measured in round 1
Gate: stills approved [no]
Best so far: none yet

## Decisions
- 17:57 Plateau plan: rounds 1-3 moved 8.2 -> 8.3 with fixes; next lever is reduction (Headspace-style: one art, one headline, few elements per screen), per-section critics with full-size (390px) tiles so type is judged at real size, and a fixer-critic loop per section.
- 17:08 Night ground for Glim: Midnight meadow (direction A of cook/night-directions.png) replaces teal after user rejected the flat swatches; full sky art makes night read rich without glare.
- 17:04 (superseded) Night ground for Glim: deep teal night #152733 / #0C1A23 chosen from 6 candidates (scratchpad night.png): dimmest comfortable option that still separates from reading navy and ocean; Glim's purple and yellow glow read best on it. Glim's own design unchanged.
- 16:55 Deliverable is a multi-file Artifact: kit (tokens, components, motion, characters) + one HTML file per screen + gallery index, because 70 screens x 2 modes need one shared system to stay consistent.
- 16:58 Characters and horizon scenes converted from design/handoff/canvas/project/*.dc.html by cook/tools/dc2js.mjs, because identity must stay intact.
- 17:00 Grounds cut from 7 in use to 5 with one rule each: apricot = Xero/days, ocean = Jelli/SOS, violet = Glim/evening, mint = plan/program, reading (cream | navy) = reading, settings, slips, health, NRT, paywall. Sun only inside celebrations. Sky retired as a ground.
- 17:00 One primary button: ink pill on light grounds, cream pill on dark grounds. Never green, purple, yellow or peach.
- 17:00 One leading control (back or close) top-left; one selection chip and one option row style; CTA dock with a fade so nothing is clipped.
- 17:00 No XP or levels. Badges instead: prep stamps (Prep 1-7), Day Xero, after-quit milestones, wave badges, shown everywhere progress appears. Reason: user asked 30-40% of Kwit and "points only if everywhere"; badges fit the design system's restraint.
- 17:00 "reduce ... from 1.5 seconds to 2 to 3 seconds" read as: launch/intro animation runs 2.4 s (longer, more polished), since 2-3 s > 1.5 s.
- 17:00 Onboarding becomes one continuous ground: the horizon rises from dawn to day as answers are given (surprise), instead of orange/blue/green switching.
- 17:00 The prep session "hand" sits on a deep ink card table in both modes; cards carry the colour, replacing the violet ground (violet stays Glim's).

- 17:14 Dark mode primary button is cream on every ground (was the ground hue on apricot/mint), because button colour drift was the baseline critics' top consistency complaint.
- 17:14 Kit: DX.beat (scripted steps also land in stills), autohold buttons render held in stills, next badges get a track ring, tinted tiles on colour grounds (builder report).

- 17:26 App icon redesigned (user allowed it): the 0 of DayXero is Xero's body with the sunrise window; light, dark, tinted and a with-face alternative (cook/site/icon/, screen 000-app-icon).
- 17:22 Prep week aligned to the real program: today is Mon Nov 2, Prep 4 The stress loop (program.json), session cards use the real Prep 4 card titles.

## User feedback inbox
- 17:57 "keep going till it hits 9.2" | open: cap lifted, rounds continue until critic median >= 9.2
- 17:03 "the dark navy purple ... background, even when the evening glim comes in, it seems very shiny for anybody's eyes ... explore ... some other color" | round 1 | teal rejected ("No, they all look bad" 17:06, about flat swatches); 4 full-screen directions rendered (cook/night-directions.png); A Midnight meadow applied: ground #0F1B33 / #0A1326, DX.nightSky art
- 16:50 "keep dayxero's identity, but tighten it ... so many colors" | open
- 16:50 "finishing actions and completion animations" missing | open
- 16:50 milestones prep days to Day Xero and after quit, with animations | open
- 16:50 polish launch wordmark animation, 2-3 s | open

---

## Round 01

Time: 16:50 to 17:19 | total elapsed 0.5h
Focus: build all 71 screens on one kit (7 parallel builders), because nothing existed yet.
Changes: kit (tokens, components, motion, badges, night sky), 71 screens light + dark, gallery artifact https://claude.ai/artifact/Rr6N6a8AJjTMecrzUZBXXp
Stills: cook/stills/r01/ | Critic sheets: scratchpad crit1/
Scores, eyeballed: anchored critics (rubric anchors: before app 6.5, Kwit 7.5, Calm 8.0, Headspace 8.5-9), 3 critics (2 Opus, 1 Sonnet)
Overall per critic: 8.2 / 8.2 / 8.0, median 8.2. Lowest screens: 041 (7.5-7.8), 059 (7.4-7.7), 057 (7.5-7.8), 023 (7.7-7.8), 010 (7.7-8.2).
Calibration: anchors carry the user's scale; residual offset not measurable without a new user score (none yet).
Own score (not decisive): 8.0
Measured: render problems 0 (render.mjs: no page errors, no missing .screen). Motion strips for 14 screens captured.
Not checked: real-device performance; VoiceOver.
Next focus: type floor, voids, waiting badge, ocean, session light mode, generic utility screens, collisions (cook/critic/r02-fixes.md).

---

## Round 02

Time: 17:19 to 17:38 | total elapsed 0.8h
Focus: type floor, voids, waiting badge, calmer ocean, session light mode, characters on utility screens, collisions; Prep 4 content.
Changes: 6 fixer groups over all screens; kit: ocean #1F3C8C, table cream in light, toast above dock, scrim blur, 2px selection, tab labels 12px; app icon screen added.
Scores, eyeballed (anchored, 3 critics; tiles enlarged to 300px): overall 8.2 / 8.2 / 8.3. Median 8.2 (flat vs round 1).
Read: fixes landed (critics now flag second-order issues), but the bar moved with them; systemic items remain: two dark neutrals,
two success greens, grey waiting badge, density on choice screens, toasts near buttons, voids.
Own score (not decisive): 8.4.
Next focus (round 3, cook/critic/r03-fixes.md): one dark neutral, one success green, waiting badge redesign, per-screen layout bugs.
- 17:38 Kit: dark mode uses one neutral #0E1322 for every ground except ocean and night; success green #1F9D63 in both modes; done buttons keep the primary colour plus a green check; waiting badges are a dashed family-colour ring with a readable numeral.

---

## Round 03

Time: 17:38 to 17:52 | total elapsed 1.0h
Focus: one dark neutral, one success green, waiting badge, per-screen layout bugs, dates and copy contradictions.
Scores, eyeballed (anchored, 3 critics, 300px tiles): 8.3 / 8.2 / 8.3, median 8.3 (round 2: 8.2).
Screens at 9.0 by at least one critic: 000-launch, 039, 055. Weakest: 036 (7.8-8.0), 022 (8.0-8.1), 023 (7.9-8.3), 041 (7.9-8.3).
Own score (not decisive): 8.5.
Kit after round 3: dark horizon art repainted as the midnight-meadow night (no brown overlays); toggles use the brand ink/cream;
dark selection is cream everywhere; SOS tab button raised with a label on the shared baseline.
Next focus (round 4, cook/critic/r04-fixes.md): one idea per screen, badge sizes, session pips, list hierarchy, dead bands.

---

## Round 04

Time: 17:52 to 18:08 | total elapsed 1.3h
Focus: one idea per screen, badge sizes, session pips, list hierarchy, dead bands; then a switch to section critics at real size.
Critic method change: per-section critics (2 per section: Opus + Sonnet) on full-size 390px [light | dark] tiles, rubric RUBRIC-S
(9.2 = Apple Design Award submission). Scores are not directly comparable with rounds 1-3 (smaller tiles, whole app).
Section scores (Opus / Sonnet): onboarding 8.3 / 8.5; Today-SOS-Program 8.5 / 8.7; session 8.4 / 8.5; lesson-log 8.2 / 8.8;
slips-checkin (Sonnet) 8.5; calm-settings (Sonnet) 8.6. Median of section medians: 8.5.
Screens at or above 9.0 by a critic: 039 (9.2), 018, 019, 034, 038, 046, 032 (9.0).
Kit after round 4: Day Xero badge is the brand mark; 5-slot tab bar with SOS centred and a Calm tab; night badge moon motif;
dark mornings use a pre-dawn sky; chips fill-only; toggles brand ink.

---

## Round 05 (section loop)

Time: 18:08 to 18:27 | total elapsed 1.6h
Section scores at real size (Opus / Sonnet): Today-SOS-Program 8.3 / 8.7 (r4 8.5 / 8.7); session 8.4 / 8.7 (r4 8.4 / 8.5).
Onboarding, slips-checkin: being scored. Lesson-log, calm-settings: fixers running.
Read: plateau around 8.5; each round fixes the named items and the stricter critic finds a new layer. Systemic repeats are moved
into the kit as they appear (button lip, "+" sparkles, tab fade, selection style, Day Xero mark, tab bar).
Kit after round 5: soft button shadow (no grey lip); star sparkles; 170px tab fade; selected chips white + 2px outline; radio
rings 3:1; waiting Day Xero on a cream coin.

Round 05 complete (all sections, real-size critics, Opus / Sonnet):
onboarding 8.5 / 8.6; Today-SOS-Program 8.3 / 8.7; session 8.4 / 8.7; lesson-log 8.4 / 8.5; slips-checkin 8.5 / 8.7;
calm-settings 8.7 / 8.8. Section medians 8.55, 8.5, 8.55, 8.45, 8.6, 8.75 -> app median 8.55 (round 4: 8.5).
Screens at >= 9.0 by a critic: 018, 019, 024, 029, 032, 035, 039, 046, 053, 054, 055, 059, 060, 064, 066 (9.0-9.1).
Kit after round 5: warm selection tint, `.opt.multi` checkboxes, coral toggles, brighter pre-dawn sun.
Round 06: all six sections are in fixers.

Round 06 partial (real-size critics, Opus / Sonnet): Today-SOS-Program 8.4 / 8.6; session 8.5 / 8.7; slips-checkin (Sonnet) 8.4.
Plateau 8.5-8.7 (+/- 0.2 per round). 18 screens at >= 9.0 by a critic. Asked the user (non-blocking) for their own score of the
current gallery to recalibrate against their eye, since rounds 1-6 fix named items and the stricter critic finds a new layer.
Kit in round 6: night waiting ring visible, lit-sea ocean ground, light-mode dusk sky.
