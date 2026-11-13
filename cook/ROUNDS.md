# Cook ledger: DayXero UI/UX redesign

Started: 2026-11-13 16:50 UTC
Time: cap 2h (ends 18:50 UTC)
Bar: every screen >= 9.2 overall (light and dark), critic median after calibration
Calibration offset: anchored critics (see BRIEF); residual measured in round 1
Gate: stills approved [no]
Best so far: none yet

## Decisions
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

## User feedback inbox
- 17:03 "the dark navy purple ... background, even when the evening glim comes in, it seems very shiny for anybody's eyes ... explore ... some other color" | round 1 | teal rejected ("No, they all look bad" 17:06, about flat swatches); 4 full-screen directions rendered (cook/night-directions.png); A Midnight meadow applied: ground #0F1B33 / #0A1326, DX.nightSky art
- 16:50 "keep dayxero's identity, but tighten it ... so many colors" | open
- 16:50 "finishing actions and completion animations" missing | open
- 16:50 milestones prep days to Day Xero and after quit, with animations | open
- 16:50 polish launch wordmark animation, 2-3 s | open
