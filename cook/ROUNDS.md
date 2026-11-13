# Rounds (run 2)

## Decisions
- 09:37 Scope: 14 onboarding screens + trial paywall + Home (prep, Day 3) + Program tab (prep, Day 3) = 19 screens, dark and light.
- 09:45 Direction "night to Day Xero" (dx2.css). Xero and the fonts are unchanged.
- 09:50 Onboarding is split across three parallel builder agents with a shared brief (S01, S03–S06 / S07–S11 / S12–S15). I build S02, Home and Program. Every screen is scored by separate zero-context critics.
- Found in today's build: the Breathe screen renders "Breathe in" and "Breathe out" on top of each other.

## Round A (09:46): critic on S02, S16–S19
Dark/light: S02 7.8/7.4, S16 7.9/7.6, S17 7.9/7.6, S18 8.0/7.7, S19 8.0/7.7 (eyeballed, strict critic).
Fixes: original sunrise ground instead of regrounding (light seams); accent text token for contrast; hairline and stronger shadow on light cards; raised SOS tab restored; one hero per screen.

## Round B (09:53): same five
S02 8.0/7.6, S16 7.8/7.4, S17 7.9/7.5, S18 8.2/7.8, S19 8.2/7.8.
Finding about the test itself: the critic misjudged text sizes from 1x four-up images. From round C on, critic images are 2x with the proposed phones at full size.

## Round C (10:00): all 18 built screens, 2x images
S01 8.0/7.8, S02 8.3/8.0, S03 8.2/8.2, S04 8.0/8.0, S05 7.4/7.4, S06 8.3/8.1, S07 7.6/7.6, S08 8.2/8.2, S09 7.8/7.8, S10 8.3/8.4, S11 8.0/7.8, S12 8.4/8.5, S13 7.9/8.0, S14 8.1/8.3, S16 8.3/8.1, S17 7.8/7.7, S18 8.2/8.3, S19 8.2/8.2. S15 not yet scored.
System fixes: dark elevation (surface #262052, a 1 px top highlight); a single light card recipe; --muted raised; progress bar with a minimum fill and Xero clamped inside it; eyebrow rule; the page dune drawn parallel to the measured sunrise curve, so Xero's feet stay visible.
Per-screen notes went back to the three builder agents.

## Rounds D–G (10:01–10:14)
Critic noise: a single critic varied by about ±1 point between runs on unchanged screens, so from round F on each batch gets two independent critics, and scores are their average.
- D, my 5 (1 critic): S02 8.4/8.6, S16 8.2/8.3, S17 8.5/8.6, S18 8.0/8.2, S19 8.1/8.2.
- E (1 critic): S12 7.6/7.4, S13 8.0/7.8, S14 7.4/7.2, S15 8.3/8.0; my 5: S02 8.3/8.1, S16 7.6/7.4, S17 7.9/7.7, S18 7.2/7.0, S19 7.0/6.7. The drop on S18/S19 was partly real: a nowrap title pushed the Play button out of its card. Fixed by folding the Up next card into the rail.
- F (2 critics, averaged): S01 8.1/8.0, S03 8.0/8.1, S04 8.3/8.3, S05 8.0/8.05, S06 8.5/8.45, S07 8.1/8.15, S08 8.1/8.2, S09 8.25/8.3, S10 8.0/8.1, S11 8.5/8.3; S02 8.3/8.0, S16 7.7/7.4, S17 7.85/7.55, S18 7.85/7.6, S19 8.0/7.75.
- G (2 critics): S02 8.4/8.6, S12 7.95/8.1, S13 8.25/8.4, S14 8.0/8.15, S15 8.1/8.15, S16 7.5/7.7, S17 7.65/7.85, S18 8.0/8.2, S19 7.8/8.0. The S16/S17 drop came from my own regression: I pulled the scene under the header, which cut off Xero. Reverted.
System changes in these rounds: slimmer tab bar (60 px) and an ink SOS button with a lungs glyph; one glyph per action; a slightly deeper light ground (#FCF0E3) for card separation; --muted/--line one step stronger; progress bar minimum 48 px with Xero at the fill's end.

## Round H (10:15), 2 critics on 15 screens
S01 8.3/8.25, S02 8.6/8.45, S03 8.4/8.35, S04 8.0/8.0, S05 8.0/8.0, S06 8.65/8.6, S07 8.2/8.15, S08 8.3/8.3, S09 8.2/8.15, S10 8.5/8.45, S11 8.5/8.45, S16 8.3/7.95, S17 8.45/8.05, S18 8.2/7.95, S19 8.2/7.95.
Real bug found: on S02 a `.hz>img` rule overrode the hero width (strip at the right edge), and the light crop caught the Dynamic Island. Fixed.
System: light --line raised to .22; all small coral text must use --accent-text.
10:17: the asset store returned store_unavailable twice; uploads for hero-welcome3, reveal3 and xero-sun are pending.

## Rounds I–K (10:20–10:46), 2 critics each, averaged
- I: S02 8.3/8.45, S12 8.0/8.2, S13 8.4/8.45, S14 8.3/8.35, S15 8.25/8.4, S16 8.3/8.4, S17 8.5/8.6, S18 8.35/8.5, S19 8.35/8.5.
- J: S01 8.15/8.2, S02 8.5/8.6, S03 8.1/8.05, S04 8.1/8.05, S05 7.8/7.75, S06 8.4/8.4, S07 8.1/8.05, S08 8.15/8.15, S09 8.05/8.05, S10 8.25/8.25, S11 8.35/8.4; S16 8.0/8.25, S17 7.95/8.15, S18 8.05/8.2, S19 7.9/8.1.
- K: S12 8.0/8.2, S13 8.3/8.4, S14 7.9/8.05, S15 8.3/8.4, S16 8.45/8.5, S17 8.6/8.65, S18 8.05/8.2, S19 8.05/8.2.
Observation: since about round H, scores have plateaued at 8.0–8.7. Each critic pass finds new and sometimes contradictory nits (e.g. add vs remove Xero on Program, card vs row for Quit Day). The strict rubric ("most good work scores 7–8.5") may cap what these critics award. From round J, builders fix only points both critics raised.
10:30 container restart; two builders were resumed from their transcripts and no files were lost.

## Round L (10:46), 2 critics, averaged
S01 8.3/8.05, S02 8.6/8.45, S03 8.3/8.1, S04 8.25/8.05, S05 7.95/7.8, S06 8.8/8.65, S07 7.95/7.8, S08 8.35/8.25, S09 8.2/8.05, S10 8.45/8.3, S11 8.65/8.45; S16 8.15/7.9, S17 8.35/8.1, S18 8.35/8.15, S19 8.25/8.05.
Last consensus fixes: Week 2 node size on S19, green rail reaching today's node on S18, amber "$17 kept" chip contrast on S17. An evening Glim row on S17 was tried and removed again because it sat under the tab bar.
10:52: canvas published (version 26). Final scoring: three fresh critics on all 19 screens, median per screen.

## Final scoring (10:55), 3 fresh critics, median
S01 8.4/8.3, S02 8.6/8.5, S03 8.2/8.4, S04 8.0/8.2, S05 8.3/8.4, S06 8.6/8.6, S07 8.2/8.2, S08 8.4/8.4, S09 8.0/8.1, S10 8.4/8.5, S11 8.2/8.3, S12 8.3/8.4, S13 8.4/8.5, S14 8.5/8.5, S15 8.5/8.6, S16 8.3/8.4, S17 8.2/8.3, S18 8.5/8.6, S19 8.4/8.5.
Bar 9.2 not met. Run paused by the user, who will supply fresh screenshots and references for a new run.
Consensus for next run (all three critics): muddy plum dark selected fill (system); S04 form wall, so collapse price/size/years like S05; S09 asks three questions at once; S13 "Nothing is charged today" set larger than the terms; S14 double affordance on quiet hours; step counter inconsistent on S12–S14; S17 hero identical to S16, so no payoff for being vape-free; S16 prep-day numbers read as dates; S01 ring and count disagree; S17/S19 lesson subtitle mismatch.
