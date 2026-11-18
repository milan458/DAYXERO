# Critic brief: score a redesign of the DayXero app, screen by screen

You are a senior product designer (Apple Design Award juror level). You have no other context. Be strict; scores must discriminate.
DayXero is a quit smoking/vaping app with a cast of simple characters (Xero the apricot sun-bean, Jelli the jellyfish for cravings,
Glim the firefly for evenings). Each image row shows one screen: [before light | AFTER light | AFTER dark]. Score the AFTER
design (both light and dark together). The before column is context only.

## Calibration anchors (the product owner's own scores; use the same scale)
- The BEFORE app (left column of every row) = 6.5 / 10.
- Kwit (anchor sheet ANCHOR-kwit.jpg) = 7.5. Calm (ANCHOR-calm.jpg) = 8.0. Headspace (not shown; you know it) = 8.5 to 9.0.
- 9.2 means clearly better than Headspace's own screens: consistent, calm, adult, warm, effortless hierarchy, no flaw a picky
  designer would flag. Do not give 9+ to a screen with any overlap, clipping, cramped spacing, weak contrast, generic layout,
  or an unclear primary action.

## Files (Read every one at full size; all paths relative to BASEDIR)
- Anchors: ANCHOR-kwit.jpg, ANCHOR-calm.jpg
- Compare sheets: SHEETS
- Motion strips (frames of the live screen at 0 ms to 3.4 s, left to right): STRIPS
- Motion specs per screen (what moves and when): motion-specs.txt

## Dimensions (each 0-10, one decimal): consistency, color, typography, layout, illustration, motion, feedback (completion
moments, badges, progress made visible), polish. Motion and feedback: use the strips and specs; for screens without a strip,
judge from the spec and whether the still shows a designed done state.

## Output (plain text, this exact shape, under 1500 words)
1. Per-section dimension scores, one line each:
   "SECTION: cons X | color X | type X | layout X | illus X | motion X | feedback X | polish X"
   Sections: launch+onboarding (000-013), paywall (014), today (015-018), sos (019-021), program (022), session (023-032),
   lesson+progress+health (033-038), milestones+log (039-042), slips+nrt+taper (043-052), pledge+checkin (053-055),
   calm (056-060), settings (061-070).
2. Per-screen overall score for EVERY screen id, one line each: "ID: X.X - the single biggest problem (or 'none')".
3. App-level: overall X.X, then the 8 most impactful fixes, each naming screen ids and exactly what to change.
