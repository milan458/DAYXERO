# DayXero redesign: final summary

Gallery (private Artifact, version 9): https://claude.ai/artifact/Rr6N6a8AJjTMecrzUZBXXp
Source: `cook/site/` (kit + 72 screen files), stills in `cook/stills/now/`, full round log in `cook/ROUNDS.md`.

## Where it landed
- Calibration from the brief: DayXero before 6.5, Kwit 7.5, Calm 8.0, Headspace 8.5-9.0. Target 9.2 (Apple Design Award level).
- Final critic median across the app: about 8.7 (two to three independent critics per section, real-size light and dark).
- Best kept per section (Opus / Sonnet): Today-SOS-Program 8.8 / 8.8; lesson-to-log 8.7 / 8.8; onboarding 8.6 / 8.7;
  calm and settings 8.6 / 8.8; prep session 8.6 / 8.8; slips to check-in 8.6 / 8.6.
- Hero screens (three critics, median): pledge 8.8, SOS 8.9 (baseline), launch 8.7, quiet hours 8.7, milestone 8.8 (baseline).
  Screens a single critic put at 9.0-9.2: 039 milestone (9.2), 032, 059 (9.1), 018, 019, 028, 031, 046, 053, 057, 064 (9.0).
- 9.2 was not reached. From round 8 on, sections moved +/-0.2 per round and about half of all passes regressed and were
  reverted (keep-best rule). The user stopped the loop after the hero pass.

## What changed (the system)
- **One ground per meaning**: apricot (Xero, your days), ocean (Jelli, SOS only), night (Glim, evenings), mint (plan),
  reading (cream / deep navy for lessons, settings, logs), table (prep session). Dark mode uses one neutral navy (#0E1322)
  except ocean and night. Purple gradients removed; the purple night ground replaced by the midnight-meadow sky.
- **Cast**: Xero, Jelli and Glim drawn as JS generators (`kit/chars.js`), paper-cut horizon scenes, night sky with pre-dawn
  glow (`DX.nightSky`).
- **Components**: one button, one chip, one option row, coral toggles, warm selection (tint + 2px edge, coral in light and
  apricot in dark), 5-tab bar with a raised SOS, eased tab fade, sheets, toasts, progress with the sun dot.
- **Type**: Bricolage Grotesque display + DM Sans body, seven steps (40/32/24/19/16/15/13), 13px floor.
- **Motion**: arrive, settle, pop, stamp, draw, count-up, ring sweep, hold-to-fill, breathe; every screen carries a
  `<meta name="motion">` spec (the SwiftUI build spec).
- **Gamification (about 30-40% of Kwit)**: badges, no XP. Families: prep 1-7 (scalloped stamps), Day Xero (the zero with a
  sunrise), days 1/3/7/14/30/60/90/180/365, waves 1/10/25/50/100, nights 3/7/14/30. Earned / next (with progress) / locked.
- **Completion moments** on every finishing action: done-state button, character reaction, count-up, badge stamp.
- **Launch**: 2.4 s paper-cut sunrise with the wordmark assembling; new app icon (the zero is Xero, sunrise in the window).

## Known open items (from the last critic notes)
- Form-style onboarding screens (003-011) still carry 60-120pt bands above Continue.
- Dark-mode selection fill is a compromise between "brown" (orange tint) and "cool grey" (neutral lift).
- A few art details: airbrushed sun glows inside crisp paper scenes, small characters on some screens, Program road (022).
- Content decisions left to the product owner: paywall charge date on Quit Day, "Continue free" path, merging 011 into 012.
