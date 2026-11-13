# Round 3 fix list (round 2 critic median 8.2; bar 9.2). Deadline 18:08 UTC.

## Kit changes already made (check your screens against them)
- Dark mode now uses ONE dark neutral (#0E1322) for apricot, mint, sun, table and reading grounds. Section colour lives only in
  art and accents. Remove any local dark colours that fight it (brown/plum/green dark fills, brown scrims). SOS ocean and the
  night sky keep their own deep blues.
- One success green (#1F9D63) in both modes. Hold/done buttons keep the primary colour and gain a green check (no colour switch).
- Waiting badges: dashed ring in the family colour, faint face, readable numeral (Day Xero gets a faint sun). Not grey.
- Caption 13px, footnote 15px in the kit now. Re-check wraps.

## App-wide rules (still)
12px floor (13 preferred); no bands of empty space over ~120px between content and the dock (pull content down to an even
rhythm, or add a meaningful context card / character); toasts only where the button has no done state, never touching the
button (>= 16px clear) or covering list rows; locked items >= 3:1; text on coloured grounds >= 4.5:1; Xero never jammed against
a gutter or floating apart from what it belongs to; nothing within 16px of the screen edge unless full-bleed art.

## Per screen
000-app-icon: tinted variant loses the sunrise: keep the window readable (lighter grey sky, white sun); it is a presentation
  screen, make it feel like a designed board (title, icon on a soft stage).
000-launch: Xero larger and less buried; less empty orange at the top (bring the wordmark down / hills up).
001: close the gap between rings and the headline; In/Out meter visible in dark.
002: Get started button runs to the right edge: fix the gutter (both sides 22px); speech bubble clear of the sun and head.
003: put Xero's "2 picked" note in a container (card) or attach it to the list.
005: stat captions shorter (one line).
006: four-chip wake-time row cramped: use two rows of two, or 3 + 1.
007: ~200px gap between chips and Save; chips wrap unevenly.
009: "Spray or inhaler" alone on a row: rebalance chips.
010: Xero up under the week strip; week-tile labels >= 12px.
011: Xero crowds the title end.
013: bottom 40% empty above the CTA.
014: paywall breaks the onboarding palette: use the apricot ground (light) like onboarding; Yearly pre-selected and dominant,
  Monthly and Lifetime collapsed under "Other plans"; Lifetime row same height as the others if shown.
015: the heavy navy progress arc fights the sunrise art: lighter, warmer arc (cream/apricot with ink only for the progress).
016: empty band above the tab bar.
017: dashed future spine and evening row low contrast.
018: Glim slightly smaller so the check-in card sits higher.
019 / 020: helper copy, timer and chips on blue to 4.5:1 (cream text, cream-filled chips); 020 move the optional trigger form
  behind a "What set it off?" link so the completion stays clean.
021: the sea scene's sun sits behind the status bar and close button: move it; reuse 043's inset sea card look.
022: locked Prep 5-7 nodes nearly invisible (>= 3:1); program mint reads off-palette: keep mint but softer, or cream ground
  with mint road; bigger today node.
023: card fan 16px off the right edge; label each card at least with its type word under the icon.
024: card pips larger and clearer.
025: ~150px gap between up-next and CTA.
026: picked-row dots and remove X faint.
029: yellow ring weak on cream (use apricot/coral ring in light); badge reads as waiting, not placeholder.
030: two competing colour fields (dawn art over blue player): one field.
031: three dense cards: one hero (mission card), the others lighter.
032 / 039: overlap Xero on the medal's lower-right with a shared ground shadow, not floating at the gutter.
034: stack edges visible (deck).
035: add a "Done listening" primary; fill the bottom third.
036: badge card collides with the tab bar (bottom inset); locked badges >= 3:1; one hero (the sky card).
037: thumbnails too alike: vary them per change.
038: countdown "2" needs a unit ("2 days").
040: unselected chips and dark outlines faint.
041: heavy blur turns Today into mud: lighter blur (4px) and a cleaner scrim; fill the lower third of the sheet (e.g. today's log summary).
042 / 051: drop the toast (the button's done state is enough) or place it under the nav with 16px clearance.
043: sea art crude: use DX.char('horizon',{scene:'sea'}) art.
045: gap above Save; segmented chips equal widths.
047: add a character; make the bars show the real gap.
050: 7 mg bar and its label crowd.
052: "Move Quit Day to Mon, Nov 23" is the primary while the taper doesn't fit; "Save my taper" secondary.
053 dark: the bright dawn fades to muddy brown behind the title: dark version of the scene (night-to-dawn) and a clean ground
  behind the title.
056: thumbnails too busy at small size: simpler, larger art per tool.
057: thin frame and rotated side labels faint; fill the empty areas.
058: chips inside the card pale and small.
059: wave chart cut flat at the screen edges; labels on the curve.
061: more brand (profile card larger with the sky/clarity, Xero).
064: arc must start at 10 PM with a start handle.
066: the Day Xero medallion next to "7 days" reads contradictory: show the earned 7-day badge instead.
067: toast covers rows: inset the list or drop the toast.
068: bottom third empty: add what you get as a calm illustrated card.
