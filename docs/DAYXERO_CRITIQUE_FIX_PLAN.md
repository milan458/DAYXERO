# DayXero critique fix plan (tracker section S27)

Source: `reports/DayXero app design critique.md`, §7 "What to do first: a ranked list by screen" (1 Nov 2026). Research notes and screenshots of all 69 screens / 275 states: `research_notes/DayXero app design critique/`.

## How the work flows

1. **Lab first.** Every visible change is made in the Screen Lab (artifact `6X6VzPwebt8BMZYRPSeRKy`, files `screens/*.js`, `elements.js`, `art.js`, `lab.js`) and recorded as a change doc there, so Milan signs off the words and the look before Swift.
2. **Then Swift, one wave per PR.** Logic lives in `DayXeroCore/Logic` with tests; screens in `DayXero/<Area>`. Claude's cloud machine is Linux and cannot build or run the app, so `ios.yml` (macOS, Xcode 27.1) on the PR is the proof it compiles, and TestFlight (manual start in Xcode Cloud) is where the look is checked.
3. **App Store Connect changes** (trial length, prices, win-back, grace period) are Milan's; the plan lists them next to the code they pair with.
4. Tracker: `node planning/task.js status S27.n in_progress|awaiting_signoff|done`, notes with `node planning/task.js note S27.n "..."`.

## Decisions Milan makes before the wave that needs them

| # | Decision | Recommended default | Needed by |
|---|---|---|---|
| D1 | Privacy policy URL | `https://dayxero.in/privacy/` now; re-point if the domain moves (D7) | S27.1 |
| D2 | Paywall after onboarding | Drop it (decision 15). Keep: Quit Day offer, Upgrade sheet from Me | S27.2 |
| D3 | Trial length | 7 days starting on Quit Day, so the first charge lands after "One week clear" | S27.8 |
| D4 | Lifetime price | $99.99 (2.5× annual); annual stays $39.99, monthly $9.99 | S27.8 |
| D5 | Evening check-in | Free for everyone (it is ungated in code and promised in onboarding) | S27.2, S27.8 |
| D6 | Tabs | Four: Today · Program · SOS · Progress. Evening folds into Today's evening state; Settings opens from Progress | S27.11 |
| D7 | Mascot name and domain | Rename the sun character (shortlist of 5 from Claude), keep "DayXero", trademark search, plan a move off `.in` | S27.19 |
| D8 | Water | One row on Today ("Water · 3 of 6"), delete the goal calculator and the streak pill | S27.12 |
| D9 | Grounds | Six: apricot, mint, ocean, sky, violet, reading. Sun stays for celebrations only. Coral → apricot, lilac/mist/periwinkle → sky, lime → mint | S27.13 |

## Wave 1: honesty and launch blockers (ranks 1–5, plus the D7 decision)

Mostly copy and one URL. Lab and Swift in the same week. One PR.

| Task | Rank | Screens | Lab | Swift | Done when |
|---|---|---|---|---|---|
| S27.1 Privacy link | 1 | `onb-welcome`, `settings-privacy`, `paywall`, `paywall-plans`, `offer` | `onboarding.js`, `me.js`, `paywall.js` legal rows | `AppLinks.privacy` in `DayXero/Paywall/PaywallView.swift`; links in `OnboardingV4Screens.swift` (Welcome), `SettingsView.swift` (Privacy), `QuitDayOffer.swift`; App Store Connect privacy URL | Every paywall and the welcome legal line show Terms · Privacy; link opens |
| S27.2 Reconcile the paywall | 2 | `paywall` (first run), `onb-reveal`, `upgrade` | Remove the first-run paywall screen or redraw it as the Quit Day offer; fix "Day 1" copy; add "Always free: your counter and Craving SOS." to every paywall | Remove the post-onboarding trigger; `PaywallModel.swift` ~L104–108 trial hold-back stays only for the Quit Day offer; delete the 3 s hidden Close; `UpgradeSheet.swift` copy | Onboarding ends on `onb-reveal` → `onb-trial` → Today with no paywall; code and lab agree |
| S27.3 Baseline summary | 3 | `onb-baseline-summary` | `onboarding.js` ~L320: delete "Good news… steps down"; "Yearly drain / $7 gone" → keep-frame ("$2,555 a year back"); relabel "Time back"; hide the "YOUR ANSWER" tray label | `DetailScreens.swift` BaselineSummaryScreen; `OnboardingEstimates.swift`: add the Benowitz source for the cigarette-equivalence constants or drop the number | No unsourced health claim on the screen; three states drawn (cigarettes, vape, pouch) |
| S27.4 Two nudges, truthfully | 4 | `onb-trial`, `notifications` | Copy: "Two a day to start. You set the cap." | `NotificationPlan.swift`: two defaults on (pledge 08:00, check-in 21:00), lesson and water off until opted in; one global daily cap; one time source for 21:00 | A fresh install schedules exactly two daily notifications; copy matches |
| S27.5 One day count | 5 | `today` (`day3`), `program`, `pledge` (`prep`), `progress` (`early`) | `today.js`, `program.js`, `evening.js`, `me.js` | `TodayHeaderV4.swift` and `ProgramTodayCard.swift` read one `dayNumber`; `PledgeView.swift` prep wording ("Today I keep to my plan") or hidden until Quit Day; `ProgressTab.swift` hides "0 waves" in prep; fix the prep-done counter in `ProgramStore.swift` / `ProgramState.swift` (v2 completions not counted); plural strings | Screenshots show one number per screen; `ProgramUnlockTests` cover prep-done |
| S27.19a Mascot decision | 19 | — | — | Shortlist five names, note the trademark reasons in `design/handoff/DAYXERO_DESIGN_SYSTEM.md` §2; Milan runs the search | Name chosen; rename scheduled in Wave 4 |

## Wave 2: program and money (ranks 6–9)

Logic with tests, plus App Store Connect. One PR.

| Task | Rank | Screens | Lab | Swift | Done when |
|---|---|---|---|---|---|
| S27.6 NRT framing | 6 | `nrt-setup`, `onb-nrt`, `log-slip-saved` (`tough`) | `me.js`, `onboarding.js`, `sos.js`/`sessions.js` slip copy | `NRTSetupView.swift`, `NRTCards.swift`, `DetailScreens.swift` NRTScreen: combination NRT as the best-evidenced option (Cochrane RR 1.25), "ask a pharmacist about prescription options" row, label sources from DailyMed / EMC / TGA not retailers; pregnancy question in onboarding routing to behavioural support only | Copy reviewed against the cited Cochrane wording; pregnancy branch tested |
| S27.7 Quit Day fires on the date | 7 | `onb-quit-day` | Allow a shorter prep (3–7 days) in the picker copy | `ProgramUnlock.swift` `dayXeroDate`: Day Xero = chosen Quit Day; unfinished prep becomes catch-up; `OnboardingModel.swift` minimum prep 3 days; `ProgramUnlockTests` updated | A user who skips prep still gets Day Xero on the chosen date |
| S27.8 Trial, prices, gating | 8 | `paywall-plans`, `offer`, `settings-subscription` | Copy to "7-day free trial from Quit Day"; price strings from the store | `PaywallModel.swift` trial copy; Milan in App Store Connect: 7-day intro offer, lifetime $99.99, win-back offer, Billing Grace Period; `FreeTier` keeps check-in free (D5) | Store sandbox shows 7-day trial; first charge after Day 7 |
| S27.9 Honest counter | 9 | `today`, `progress`, `milestone`, `milestone-share`, `finale`, `log-slip-saved` | Rename "days clear" → "days since Quit Day"; "not smoked" subtracts slips; remove "streak" and the water streak pill; Jelli "fresh Quit Day?" card in `log-slip-saved` `tough` | `ProgressStats.swift`, `Slips.swift`, `MilestoneMoments.swift`, `WidgetSnapshot.swift`, `Water.swift`; relapse threshold (e.g. 3 slips in 2 days or 5 in a week) offers a new Quit Day without wiping history | Tests: slips reduce "not smoked", never reset days since Quit Day; threshold offer fires |

## Wave 3: subtraction (ranks 10–15)

Lab first, signed off per flow, then Swift inside the v4 migration phases (`docs/DAYXERO_V4_MIGRATION_PLAN.md`). Several PRs.

| Task | Rank | Screens | Lab | Swift | Done when |
|---|---|---|---|---|---|
| S27.10 Onboarding voice and skips | 10 | `onb-products` … `onb-nrt`, `onb-breathe`, `onb-building` | `onboarding.js`: first-person Xero on all bubbles; "Using both is common. I'll plan for each."; define "wave"; one progress bar (12 steps, never shrinks); Skip on name, past attempts, breathe | `IntroScreens.swift`, `DetailScreens.swift`, `OnboardingV4Screens.swift`, `OnboardingModel.swift`; feed years/obstacles/confidence into `TodayPlan` or drop the questions | No "we/us" from Xero; every optional question skippable; unused answers gone |
| S27.11 Tabs and routes | 11 | Tab bar, `progress`, `evening` | `today.js` gains the evening state; `me.js` progress gets a Settings gear | `Nav4.swift` → native `TabView` with monochrome SF Symbols (iOS 26 glass); `ProgressTab.swift` → Settings route; `EveningView.swift` folded into Today's evening slot (`TodayPlan.swift` `TodaySlot`) | Four tabs; Export and Delete reachable in two taps |
| S27.12 Water and black screens | 12 | `water`, `water-goal`, `calm-box`, `calm-478`, `session-kit` breathe | `me.js` water → one row; delete `water-goal`; `calm.js` and `sessions.js` breathe on reading tokens | Delete `WaterGoalSheet.swift`, `WaterTrackerView.swift`; `WaterHomeCard.swift` → row; `CalmToolsView.swift`, `OrbBreathingPanel.swift`, breathe beat in `BeatsA/B.swift` on `DX.Ground.reading` | No pure-black screen remains in light mode |
| S27.13 Six grounds | 13 | All grounds; `program`, `changing` kickers; cards on lime/sun/violet | `lab.js` `Lab.grounds` → six; `tokens.json`; coral never as text; card alpha or hairline ≥ 1.3:1 | `Ground.swift` cases and `V4TokenTests` (contrast for every pair, card separation); kickers in `ProgramView.swift`, `HealthTimelineView.swift` use `muted`, green only for done/CTA | Token tests pass with six grounds; no 12 px coral text |
| S27.14 Task-screen layout | 14 | `session`, `session-kit`, `session-mission`, `calm-*`, `log-slip-what`, `checkin-dayend` | `sessions.js`, `calm.js`, `evening.js`: top-anchored content, 88 px character, Continue under the last option, grabber on sheets, mission restated on follow-ups, hide "Audio coming soon", fix "Right." on wrong answers | `SessionFlowView.swift`, `BeatKit.swift`, `BeatsA/B.swift`, `MissionPrompts.swift`, `CalmToolsView.swift`, `SlipFlow.swift`, `CheckInView.swift` | No beat with a >200 px void above Continue at iPhone 17 Pro height |
| S27.15 One illustration language | 15 | `program`, `changing`, `calm` | `art.js`: remove the human figure; kit tiles limited to warm and deep families; marked word rationed to welcome, Quit Day, milestones, finale; no twinkle on forms | Delete `PersonFigure.swift` and its uses in `CalmToolsView.swift`, `ProgramPathMap.swift`; `KitArt.swift` palette; `Emphasis.swift` call sites | `PersonFigure` gone; mark on ≤ 6 screens |

## Wave 4: addition (ranks 16–20)

Only after Wave 3, because character growth pays off inside a system the user already trusts.

| Task | Rank | Screens | Lab | Swift | Done when |
|---|---|---|---|---|---|
| S27.16 Xero grows | 16 | `milestone` (11 states), `today` hero | `art.js` Xero stages 1–4; sky clarity by days; distinct art and one fact per milestone; stage sheet | `CrewGrowth.swift` stages, `XeroView.swift`, `HorizonScene.swift` clarity, `MilestoneViews.swift`, `MilestoneMoments.swift` | Day 1, 14, 30, 365 render visibly different Xero and sky |
| S27.17 Dark heroes and real sheets | 17 | `onb-welcome`, `onb-quit-day`, `pledge`, `milestone`, `finale` dark; 14 sheet screens | Dusk variant of the dawn hero; lab renders sheets over their parent screen (`lab.js`) | `HorizonScene.swift` dusk palette | Dark screenshots show no full-brightness dawn art on plum |
| S27.18 SOS menu and life after Day 31 | 18 | `sos`, `session-mission`, post-Day-31 | `sos.js`: saved break menu, lifts, "use your gum now" row; mission data shown back ("peaks 8 → 6 → 4") | `CravingSOSView.swift` / `SOSV4.swift`; `MissionPrompts.swift` feedback; `program.json` sessions at days 45, 60, 90; weekly Glim check-in in `NotificationPlan.swift` | SOS shows the menu the program promised; a Day 45 session exists |
| S27.19 Rename the mascot | 19 | All Xero copy, art, docs, website | Rename in `art.js`, `screens/*.js` | String catalogs, `XeroView.swift` naming, design system doc, `website/` | Zero remaining references to the old name; trademark search filed |
| S27.20 Accessibility and convention debt | 20 | Lab infrastructure; `program` tabs, `milestone-share`, source pills, footer links, disabled CTAs, destructive buttons, day-end picker | `lab.js`: Dynamic Type (AX3) state, Arrive/Count/Celebrate motion tokens; 44 pt targets | `Move.swift` one hold duration; `Buttons4.swift` destructive style and disabled reasons; merge `DayEndSettings` pickers; targets in `ProgramView.swift`, `MilestoneViews.swift` | AX3 screenshots readable; every control ≥ 44 pt |

## Order of the first week

1. D1–D5 and D7 decisions (one message from Milan).
2. S27.1, S27.3, S27.4, S27.5 in the lab, republished for sign-off (half a day).
3. Same four plus S27.2 in Swift on branch `claude/critique-wave1`, PR, CI green, TestFlight.
4. Wave 2 starts in the lab while Wave 1 is in TestFlight.
