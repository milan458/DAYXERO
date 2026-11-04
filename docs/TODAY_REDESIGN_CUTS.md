# Today, take two: the sky, the ring and the day path (S32, 4 Nov 2026)

Built from Milan's sketch and the Final page of https://claude.ai/artifact/LCcigLTDyDK99cR6ECxbJE. Code:
`DayXero/Home/TodayView.swift`, `TodayHero.swift`, `TodayTimeline.swift`; `DayXeroCore/Logic/TodayWeek.swift`;
the icons in `DayXero/Shared/LogIcon.swift`.

## What changed on Today

| What | Was (UX-01 to UX-11) | Now |
| --- | --- | --- |
| **Top of the screen** | Kicker line ("PREP DAY 3 OF 7 · HI, MILAN") and an apricot hero card | A sunrise sky (a violet night after 6 PM) with the week, "Good morning, Milan", the countdown or "Day 4 · 4 of 4 days smoke-free", the why, and a ring with Xero (Glim at night). |
| **Prep progress** | A dot per prep session in the hero | The ring: one segment per prep session, today's highlighted. "Prep: 2 of 7 sessions done" is still its VoiceOver label. |
| **Time free and money** | In the hero after Quit Day | Inside the ring ("3d 14h free"); the ring fills to the next counted body change, and a pill under it says which one and the money kept. |
| **The week** | Not shown | Seven days: ticks for a finished session during prep, and for a day with no slip from Quit Day on (the same rule as the resilience count, so the two always agree). |
| **Water and use cells (bento)** | Two cells side by side | Rows in "Through the day", each with its log icon. Same batch buttons, same identifiers. |
| **Morning pledge** | A slim row | The first row of "Morning"; a ticked line once made. |
| **Prep challenge** | A row under the bento | A row in "Through the day"; a ticked line once done. |
| **Zero scroll** | Everything on one screen | The day scrolls under a pinned slim card. The focus card sits right under the sky, so the one thing to do now is still on the first screen. |
| **Night** | Violet hero only | The whole screen goes dark from 6 PM to 6 AM, even in light mode (Milan, 4 Nov 2026), tab bar included. Other tabs keep the phone's setting. |

## Different from the mockups

- **The focus card isn't repeated in the timeline.** On the scrolled mockups the session card sat inside "Morning". In the
  build the focus card stays right under the sky (as on the opening mockups) and the timeline lists the rest of the
  day, so the same card never shows twice and the evening check-in is on the first screen at night.

## Left out for now

- **Xero's notes** (the coffee note, CLIN-02, and the swap trap, CLIN-05) and **today's plan** after a slip (S8.3):
  not on the new Today yet (Milan, 4 Nov 2026: "leave it out, let's work on other parts first"). `XeroNoteCard`,
  `CaffeineAlert`, `SwapTrap` and their tests are kept, ready to slot in between the sky and the timeline.
- **Settings › Products and the water widget** still use SF Symbols. Siri Shortcuts must (system symbols only).

---

# Today redesign: what was cut or moved (UX-01 to UX-11, 2 Nov 2026)

Today became a zero-scroll screen with two states (S28 in `planning/tasks.json`). To make it fit, several things
left Today. This file records each one, where it went (if anywhere), and the open questions, so any of them can be
brought back later.

## Removed from Today

| What | Was | Now | To bring it back |
| --- | --- | --- | --- |
| **Your day card** (pledge, today's session, evening check-in rows) | `YourDayList` in `DayXero/Home/TodayCardsV4.swift` | The lesson is the focus card; the check-in takes the focus card after 6 PM; only a slim **Morning pledge** row remains, until noon and until it's made. | Restore `YourDayList` from git history (commit before UX-01) and the `yourDay(now:)` builder in `HomeView.swift`. |
| **Streak / prep progress card** ("Prep · 3 of 7 done", "Since Quit Day · n days", next-milestone bar) | `streakCard` in `HomeView.swift` | Prep: the hero's dot per prep day. After Day Xero: the hero's time free. The next-milestone bar is gone. | Restore `streakCard(_:)` from history. |
| **Body-change row** (next change in the body, opens the health timeline) | `milestoneRow(now:)` in `HomeView.swift` | After Day Xero it is the **recovery card** in the focus slot (`RecoveryCard` in `TodayV4.swift`). During prep it no longer shows ("Starts on Quit Day" preview is gone). | Show `RecoveryCard` during prep too, or restore `milestoneRow`. |
| **Usual craving wave card** ("Your coffee wave · Usually comes around 9:40", opens SOS) | `TodayTopCardV4` `.wave` case | Nowhere. The logic (`CravingPattern.usualWave`, `TodayTopCard`) is still in DayXeroCore with its tests. | Add a `.wave` case to `TodayFocus`, e.g. in the morning when today's lesson is already done. |
| **Quit Day SOS tip** ("Craving? Tap SOS any time. It takes 3 minutes.") | `sosHint` in `HomeView.swift` | Nowhere. The raised, pulsing "SOS / Breathe" button is meant to do its job. | Restore `sosHint` (it used `@AppStorage("dx.sosHintSeen")`). |
| **Big illustrated header** (210 pt scene, greeting with the hand-drawn loop, three stat tiles) | `TodayHeaderV4.swift` (deleted) | The kicker line and the compact hero. Xero or Glim sits small in the hero's corner. The "to keep a year" tile is gone. | Restore the file from history. |
| **Per-product log cards** (one card per product, "+1 Puff" and "+ Urge" for vapes) | `quickLog` / `productCard` in `HomeView.swift` | One use cell for the main product with batch buttons (vape +5/+10, others +1/+5). Other products, and a craving, are logged from the log sheet, which opens when you tap the cell's label. "+ Urge" is gone from Today. | Restore `quickLog`; or add a product switcher to the use cell. |
| **Water row** ("Water · 3 of 8 glasses") | `DayXero/Water/WaterRow.swift` (deleted) | The left bento cell (`WaterBentoCell` in `TodayV4.swift`), same logging. | — |
| **ALL-CAPS card kickers** ("TODAY · PREP 3 · 6 MIN") | `ColourCard` | Sentence case everywhere; the Today kicker is the only caps line. Also affects `ColourCard` on the Evening screen. | Re-add `.uppercased()` in `ColourCard`. |

## Moved elsewhere

| What | From | To |
| --- | --- | --- |
| **NRT invitations** ("Set up your NRT", "Step down your pouches") | Today (`nrtSection`) | Program tab, in the NRT group under the path (`nrtGroup(now:)` in `ProgramView.swift`). |
| **Session list** (a card per session under the winding path) | Program tab | Removed (UX-02). Tapping a path stop opens a bottom sheet with its art, timing and one button. The phase summary ("Prep · 3 of 7 done") stays as one line under the path. |
| **Your reason in SOS** | Below the break menu, rotating each session | First, above the break menu; always the onboarding Why first, a tap steps through the rest (UX-06). |

## Open questions for Milan (answered 3 Nov 2026)

1. **Daily sessions after Quit Day:** yes, for now. After Day Xero the focus card shows the day's session while it is
   open and free to start, then the recovery card once it is done (`TodayFocus.pick(sessionOpen:)`). A session that
   needs Pro stays on the Program tab.
2. **Recovery card wording:** approved (Milan, 3 Nov 2026). "Happening now" / the change / "Next: … · in 2 days";
   "Coming up" / the change / "Starts in 2 days" when nothing is under way; "Many people notice" / the change / its own
   line, never counted down and skipped by "Next"; at the end "Your body has come a long way" / "Every change on the
   timeline has started" / "See them all" (`RecoveryCopy` in `DayXero/Home/TodayV4.swift`).
3. **Resilience %** (share of days since Quit Day with no slip logged, rounded down): confirmed.
4. **Batch sizes** (+1 / +5 for cigarettes and pouches, +5 / +10 for puffs): confirmed.
5. **UX-03:** closed; the SOS tab opens Jelli's session.

---

# Copy pass, SOS and body screens (UX-12, CHAR-01 to CHAR-05, UX-04; 2 Nov 2026)

## Changed or removed

| What | Was | Now |
| --- | --- | --- |
| **Water cell** | "7 / 9 glasses" | "7 / 9 glasses" and "2.25 L daily goal" under it (litres or fl oz, from the water settings). |
| **Prep card** | "Today · Prep 1 · 5 min" / title / chevron | "Prep 1" / "[title] · 5 min" / a **Start** pill (Continue, Unlock). The kicker is the program's own session label ("Prep 1"), not "Prep day 1": a session isn't tied to a calendar day. |
| **Program sheet** | "Prep 1 · 5 min" for the open session | "Today · 5 min". Done sessions still show their label. |
| **Savings tile** (Progress, prep) | "to keep a year" | "you'll keep / year". Never "saved" before Quit Day. |
| **Patterns card** (Progress, no logs yet) | "Your first log starts the map" over the blurred map | "Unlock your trigger map" / "Log cravings this week to see your patterns." over the blurred map. |
| **Log sheet** | "I used" heading; rows "Cigarette", "Vaped", "Pouch" with "n today" | No heading; rows "Cigarette", "Puff", "Pouch" with "n logged today". "Vaped" became "Puff" so the row reads as a thing, like the others. Recent logs on Progress say "Puff" too. |
| **"What's changing" sources** (Progress) | A "Source: …" line on each card | One footer: "Source: American Cancer Society" or "Sources: A · B". The full timeline already cited once at the bottom. Milestones' own detail sheets keep their source. |
| **"What's changing" cards** | Text-only cards | Each shows its milestone illustration (the existing kit badges). |

## Craving SOS, new order

1. **Three physiological sighs** (about 30 s): Jelli swells and settles, one subtitle line, the on-device voice and Core Haptics in step. "Skip to riding it out" is under it; "It passed", "Still strong", "Text a friend" and "I slipped" stay on screen throughout. Leaving the app mid-sigh skips to riding it out.
2. **Riding it out**: Jelli on 4 in, 6 out, the time ridden, their why.
3. **Hold to feel**: the fidget pad.
4. **Break menu**, as before.
5. **Sensory tricks**: a row that opens the drawer.

The sigh's voice is the on-device speech voice, like the breathing orb's coach. A recorded voice can replace it later. It follows **Settings › Voice guidance**, and the haptics follow the SOS haptics setting.

## Open questions


## Decided

- **Prep card label: "Prep 1"** (Milan, 2 Nov 2026). The card keeps the program's session label, not "Prep day 1", so it never disagrees with the kicker's calendar day.
- **Sigh voice: the built-in on-device voice for now** (Milan, 2 Nov 2026). A recorded voice can replace it later in `CueVoice` (`DayXero/SOS/SOSTools.swift`).
- **Milestone illustrations: the crew collage** (Milan, 3 Nov 2026, round 4 on https://claude.ai/artifact/NfDttfeWAT5qM1ijPr5fjw). Earlier rounds (an earthy recolour of the old icons, scenes without the crew, the crew on one repeated backdrop) were rejected. Each of the 20 changes now has its own composition: two or three gradient windows from the crew's worlds (arch, disc, rounded window), one hero object, one crew member (Xero for the body, Jelli for withdrawal and cravings, Glim for the night), composed to the bottom right. In the app: `MilestoneCollage` (`DayXero/Health/MilestoneCollage.swift`); "Your body" rows are cards with the art bleeding off the right edge; badges crop it to a circle.
- **Earthy restyle of the app chrome: not for now** (Milan, 3 Nov 2026). Mockups are kept for later at
  https://claude.ai/artifact/MHhcjmDzBdfuu7vKP1z5Qe (oat and linen surfaces, terracotta action, one colour per realm,
  the crew and collages unchanged).
