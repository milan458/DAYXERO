# Rounds

Stills are local renders of the canvas HTML (Chromium, DM Sans and Bricolage from Google Fonts), next to the CI screenshots. They are not iOS renders.

## Round 1: build
- Zero-context critic on the current screens: 5–7/10 each. Biggest issues: tracked uppercase eyebrows everywhere; content clipped under CTA or tab bar on 8 screens; dark-mode contrast bugs (R11 card label, R13 markers); colliding labels on the Program path; illegible card fan.
- Motion audit from code: DX.Move tokens are solid and Reduce Motion is respected almost everywhere. Today ring, Program path, hand and plan reveal don't move. DXButton release uses settle (0.9 s) instead of press (0.12 s).
- Built all 17 proposed screens. Self-check of the renders found: Triggers CTA pushed off screen (dock made absolute); Welcome headline wrapping to 3 lines; seam above the Quit Day hero (recropped); Program path labels on the stroke (path moved left, labels in one column); fan too wide (narrowed).

## Round 2: critic on proposed vs current
- Scores current → proposed: R01 6→8, R02 6→7.5, R03 5→7.5, R04 5→8, R05 6→8, R06 5→8.5, R07 6→7.5, R08 6→7, R09 6→7.5, R10 5→7.5, R11 4→7.5, R12 5→7.5, R13 5→7.5, R14 4→7.5, R15 6→7.5, R16 5→7, R17 5→8 (eyeballed by critic, not measured).
- Fixed in round 3: Welcome bubble clipped at the right edge; paywall lost the $9.99 price and the cancel path; Baseline cost line floating; resting hold button looked half-filled; Day 3 cards unbalanced; played-card check low contrast; "For the rest of today" lost emphasis; QD milestone glyph; Progress pill over the road; chore chip copy restored.

## Decisions
- Selected fill stays cream in dark and navy in light (the app's chip rule), though the critic preferred one treatment.
- The Program tab's "Vaping program" note moves to Settings › Products so nothing sits under the tab bar.
- Mock data is kept as captured, so amounts and dates still disagree between screens. That comes from the CI scenarios.

## Still below the bar (not fixed)
- Dead space above the CTA on R02, R06, R15 (short questions).
- Content under the floating tab bar is faded, not inset, on R08 and R16.
- The R16 "From your logs" card was dropped; restore it or decide to cut it.
