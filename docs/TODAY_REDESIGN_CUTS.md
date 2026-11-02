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

## Open questions for Milan

1. **Daily sessions after Quit Day.** In State B the recovery card takes the lesson's slot, as specced, so quit-week
   sessions are reachable only from the Program tab. Do we want a session prompt back on Today (for example as the
   focus card while a session is open, recovery once it's done)?
2. **Recovery card wording** is a placeholder ("Your body is recovering" / the change's title / "Next: …, in 2 days").
   Pending approval.
3. **Resilience %** is defined as the share of days since Quit Day with no slip logged, rounded down, so 100% means no
   slips at all (`Resilience.percent` in `DayXeroCore/Logic/TodayFocus.swift`). Confirm or redefine.
4. **Batch sizes** for cigarettes and pouches (+1 / +5) were my call; the spec only named +5 / +10 for puffs.
5. **UX-03** (SOS opening Calm tools) couldn't be reproduced: the SOS tab already opened Jelli's session in code. If
   it still happens, note the build and the path taken.
