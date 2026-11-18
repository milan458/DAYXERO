# Round 2 fix list (merged from 3 critics, round 1 median 8.2; bar 9.2)

## App-wide rules (apply on every screen you touch)
1. TYPE FLOOR: no text under 12px anywhere (labels, legends, ticks, sources, chart labels, pills). Body 15-16px. Captions >= 4.5:1 contrast.
2. NO VOIDS: no large empty band between content and the dock. Either size/space the content to fill the screen with intent
   (bigger hero art or character, more breathing room spread evenly), or move the dock content up. Bottom third must not be empty.
3. MARK (hand-drawn underline): only on hero moments: 002, 012, 020, 032, 039, 046, 053, 055, 060. Remove it everywhere else.
4. Options and chips in sentence case. Unselected rows must stay readable (>= 4.5:1); never dim them to look disabled.
5. Selected option rows in light mode: thinner, calmer selected outline (2px) plus the filled radio; not a heavy black frame.
6. Toasts now sit above the dock (kit .toast bottom:118px). Remove any local top toasts; never cover the header.
7. Characters over icons: where a screen is a plain list or form, bring in the right character small (88px card size) or a
   paper-cut spot illustration in the horizon style, so no screen feels like a default iOS list.
8. Kit changes already made: ocean is now a deeper calm blue; the session `table` ground is warm cream in light mode and a deep
   card table in dark (check every session screen in light: text must use tokens, no hardcoded cream text); `next` badges are a
   ghost face with a dashed ring (the "muddy olive disc" is gone); scrim is a neutral navy blur.

## Per screen
000 tagline: larger (16px), higher contrast, both modes.
001 the two-line Breathe in / and out reads as two headlines and the faded line fails contrast: one breathing word at a time
    (swap), full contrast; meter labels >= 12px.
002 legal text crowds the CTA: one line of terms, smaller block; bubble text >= 14px; keep mark.
003 the "2 picked" note looks like a fourth option: make it a plain caption line, not a card; fill the dead band.
004 group labels tiny/grey: proper 14px section labels; minus button must not look disabled.
005 split bar 8px tall, readable legend (12px+), vape segment coloured not grey.
006 + 008 chip clouds with empty bottom thirds: give the chips structure (two clear groups with section labels), add a small
    Xero reacting card or a "your plan so far" summary card to fill the space; make 008 visibly a different step.
007 field edges weak on apricot: white fields with a hairline; hint >= 12px.
009 sub-chips must sit INSIDE the selected option card.
010 the waiting Day Xero badge must sit inside the Fri 6 tile (under the date), not overhang the card; close the gap above the CTA.
011 + 012 move back to the apricot ground (no mint mid-onboarding). 011: Xero must not touch the progress bar. 012: stamps >= 32px
    with readable numerals; fewer, calmer cards.
013 content stops mid-screen: spread the day line and notifications to fill; notification text >= 13px.
014 timeline labels >= 12px; reduce density (shorter checklist); Xero not clipped; Lifetime row quieter.
015 the prep-stamp strip is illegible: 7 stamps max at >= 32px with one "Today" label; one primary action only (no duplicate Start).
016 add 16px between status bar and ring; lighter ring weight in light mode; "14 days, 7 to go" readable.
017 five different row formats on one spine: one row format; "Happening now" leads; spine visible.
018 empty sky: fill the hero (Glim larger, closer); the 6 of 7 nights progress readable, not a tiny ring.
019 four exits is too many in a crisis: It passed (primary) + Still strong (ghost), then Text a friend · I slipped in one quiet
    row; Jelli ~30% larger; pacer ring stronger. Uses the new calm ocean.
020 fill the void; the 25-wave badge bigger (>= 72px) with readable "2 to go".
021 Jelli shown in full (not a tile); make it distinct from 044.
022 road labels >= 13px and never on the path; week chips as one clear segmented control away from the tab bar; up-next card
    anchored beside today's node.
023 fan labels overlap/clip: label only the lifted card; others show colour edge + icon; no clipped icons.
024 transcript must end with room above the dock (fade or shorter).
025 the played card is a flat yellow slab: give it the sun back face with a pattern/illustration and a proper label.
026 generic form: add a focal element (reason cards with Xero), readable rows.
027 helper note readable; remove the mark.
028 tick labels >= 12px; place Xero's bubble so the middle isn't dead space.
029 waiting badge now a ghost face + dashed ring (kit); check it reads as aspirational.
030 section heads clearly heavier than body; shorter paragraphs.
031 three unrelated card styles: one card language; don't repeat $2,555 (it appears on 3 screens): show something new
    (e.g. "this week: $28 still spent") or drop the money card; no void.
032 Xero must not collide with the sun rays (16px clearance); close the gap above the CTA.
033 art style must match the paper-cut horizon layers (use DX.char horizon or the launch's layered hills).
034 remove the duplicate "Tap the card to turn it over" line.
035 transport controls higher contrast and >= 12px; transcript card needs bottom room.
036 stats as a 2x2 grid; badge shelf: show earned + the next 3 per family plus "See all", not 10 locked placeholders; prep coins >= 32px.
037 characters back: spot illustrations in the paper-cut style or Jelli/Xero small art in the cards; status lines readable.
038 hero illustration (not a clip-art icon); "What you might notice" uses neutral bullets, not done ticks.
039 Xero clear of the rays; rays contrast on apricot in light.
040 share card is the most shareable thing: put Xero and the paper hills on it, badge, "7 days free"; Story / Square format chips.
041 the Today behind the sheet must be the current 016 design (hero ring), under the neutral navy blur scrim.
042 toast above the dock (kit); copy "Craving logged. 4 noted today."
043 Jelli larger (88-120px, not in a small disc); fill the void.
044 unselected rows readable; sentence case.
045 "Yesterday" must not wrap alone; fill the empty half (e.g. Jelli card or a short "why we ask" note).
046 close the void between cards and the CTA.
047 three equal cards: give one hero (the 50 to 60% stat); sources >= 12px; remove mark.
048 half empty: add the product art or a tip card with illustration.
049 step glyphs bigger and readable; sublines less dense.
050 + 052 the solid slab bars glare (cream in dark): tint bars with apricot at ~60%, lighter weight; 052's Move Quit Day as a
    text link, not a competing button.
051 toast above the dock.
053 the selected chip repeats the headline: replace the two chips with a single quiet line or remove.
054 mood faces larger and more characterful; Edit link readable.
055 the newly earned night-7 badge is the hero: >= 120px, not inside a small card.
056 abstract tiles: one paper-cut illustration style for all four tools (characters: Jelli for breathing/urge, Xero for
    grounding, Glim for wind down).
057 wireframe feel: Jelli breathing inside the box, side labels 13px at 4.5:1, End as a ghost button.
059 looks unfinished: a large cross-fading prompt (24-28px), Jelli riding the wave on a tinted sea band, labels readable.
060 replace the plain green disc with Jelli cheering beside a smaller check.
061 use the large left-aligned title like every subpage.
062 time rows readable (not tiny nested rows); toast above dock.
063 timeline explainer labels >= 12px.
064 dial track thicker, clock labels >= 12px, fill the bottom half (e.g. a "what's quiet" list).
065 calmer selected outlines; totals readable.
066 bottom 45% empty: fill (e.g. first-week strip bigger, Xero, what changing it keeps).
067 list must not stop and go blank: more currencies or a fade into the scroll.
068 Manage in the App Store as the primary button.
069 Delete everything with a destructive coral treatment.
070 Apple Health identity (heart in a proper app-style tile), larger.
