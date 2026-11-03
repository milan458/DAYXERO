# Bigger bets: plan (3 Nov 2026)

There are seven bets from the review of the onboarding recording. For each one this plan sets out what the code
already does, what is left to build, what Milan needs to decide, and the order to build in. Tracker section **S32**
in `planning/tasks.json`.

## The short version

| Bet | Already in the code | What's left | Estimate (review said) | Decision |
| --- | --- | --- | --- | --- |
| 1 · Soft paywall after "Your plan is ready" | RevenueCat, Superwall, monthly/annual/lifetime with annual highlighted, ✕ always visible, the "Always free" line, charge date, trial reminder, price anchor, the Prep 4 upgrade sheet | Show the paywall between the reveal and the reminders screen. Register `onboarding_complete`. Add a first-run version of the copy. Set up India's ₹2,999 (S30.4) | 1.5–2 days (3–4) | **Yes**, and it reverses part of MON-01 |
| 2 · Hold-to-set as the pledge | `HoldButton` with the Core Haptics crescendo (CHAR-04) | A radial fill from the thumb, drain-back on release, and a mint flood that turns into the plan-building screen | 1–2 days | No |
| 3 · Mascot motion pass | `CrewCanvas` timeline, with a blink on `hello`/`cheer` only | The Xero → Jelli hand-off into SOS, idle blink and breathing on every avatar, speech bubbles that arrive in order | 2–3 days | Bubble copy |
| 4 · Program path as a living progression | A static `ProgramPathMap` | Draw in the segment, pop the node, Xero steps to the next stop, a "Tomorrow" line on Today | 1.5–2 days (2–3) | No |
| 5 · Hero continuity + glass | Glass tab bar on iOS 26 already (`DockBackground`, S27.11). iOS 18 target, so `.zoom` is available | Zoom from the reveal into the paywall (needs bet 1). A matched transition from onboarding to Home. Zoom from the dock into SOS | 1 day (1–2) | Mostly settled: keep the custom glass dock |
| 6 · Instrument + A/B | PostHog chosen and wired (S1.5, US cloud). Every onboarding step tracked. Superwall events go to PostHog | Time per step, hold aborts, which surface a paywall came from, trial length. Run the experiments as Superwall campaigns. A 14-day product | 0.5 day of code + dashboard (1 day) | **Vendor already chosen.** The experiment design still needs a yes |
| 7 · After Quit Day + slips | Today State B (UX-09), the recovery card (wording approved 3 Nov), the session back on Today, the slip flow with "nothing resets" and the if-then planner (S8, CLIN-10) | Record the post-Quit-Day states from the debug scenarios, review them the same way, and check that dual users get a counter per product | 0.5 day review, then whatever it finds | After the review |

Total: about 8–11 days of build, against the review's 11–16. Bets 1, 5 and 6 cost less than estimated because the
plumbing is already there.

---

## Bet 1 · Soft paywall after "Your plan is ready"

**Today.** `RootView` says "There's no paywall after onboarding" (decisions 15, 23 and S27.2). The flow is
`… quitDay → building → reveal → trial` (the reminders screen) → Home. `Paywalls.Placement.onboardingComplete` is
defined but marked "No longer registered". `PaywallView` already has nearly everything the bet asks for:

- **Three plans with annual highlighted.** `selected = .annual` by default.
- **A ✕ that's always visible**, labelled "Close and continue with the free version".
- **The "Always free" line**: "Always free: Prep 1 to 3, your counter, Craving SOS and a 60-second breathing timer."
  This is the line the bet wants verbatim.
- **A charge line** that shows the trial end date, and where the trial ends against the Quit Day.
- **The trial reminder** two days before the end, and **the price anchor** (MON-03).

**The conflict.** MON-01 (Milan, 2 Nov) sells the 7-day trial at Prep 4 so it ends 3 days *after* Quit Day.
App Store trials start when someone buys. So a trial bought on Day 0 with the usual week of prep **ends, and charges,
on Quit Day itself**: the most fragile day, and the day the trial reminder would land 2 days before. Three ways to
handle it:

| Option | Trial bought on Day 0 ends | Notes |
| --- | --- | --- |
| A. 7-day trial on Day 0 | Quit Day (usual week) | Simplest. The charge lands on the hardest day. The paywall already says where it ends against the Quit Day. |
| **B. 14-day trial on Day 0, 7-day at Prep 4 (recommended)** | 7 days after Quit Day | Covers prep and the first quit week. Needs a second annual product (an intro offer belongs to its product). Bet 6's 7-vs-14 test is built in. |
| C. Day 0 shows the plans with no trial, and the trial stays at Prep 4 | n/a | Keeps MON-01 whole. A weaker offer at the moment that decides most trial starts. |

**Build.**

1. `OnboardingFlow`: after `reveal`, present the paywall (Superwall `onboarding_complete` first, then DayXero's
   `PaywallView` as the fallback). Order: **reveal → paywall → reminders**. After a purchase, the reminders screen
   doubles as the permission ask for the trial reminder.
2. `PaywallView` first-run copy: "Your plan is ready" in the header, with the reveal's Quit Day and plan length.
   The ✕ is visible from the start (no 3-second delay, unlike S22.9), and closing it goes on to reminders and then
   Prep 1, free. Update the type's doc comment ("nothing here is a first run").
3. **One contextual re-ask at Prep 4.** This is the existing `unlock_program_day` upgrade sheet. Add a guard so
   someone who closed the Day-0 paywall sees exactly one Prep 4 ask (the sheet). It doesn't open on its own again:
   after that, it only appears when they tap a locked day.
4. Remove the stale "no paywall after onboarding" comments in `RootView` and `PaywallView`, and the "No longer
   registered" note on the placement.
5. **India pricing:** S30.4 is still blocked on App Store Connect (₹2,999 set by hand, annual trial set to 7 days).
   For option B, also create `dayxero.annual14` (14-day trial) and add it to RevenueCat's `pro` entitlement and an
   offering.
6. Tests: model tests for the Day-0 → Prep 4 re-ask rule. The journey UI test goes through the Day-0 paywall
   (✕ path and purchase path with `MockStore`). Add a screenshot step.
7. Update `docs/MONETISATION_TIERS.md` (the "When is the trial sold?" row) and `docs/SUPERWALL.md` (placement table).

**Decisions for Milan:** option A / B / C; the prices (keep $39.99 / $9.99 / $79.99 and ₹2,999?); the trial length;
and whether the re-ask stays at Prep 4.

## Bet 2 · Hold-to-set rebuilt as the pledge

**Today.** `HoldButton` (`DayXeroCore/DesignSystem/V4/Buttons4.swift`) fills a capsule left to right with a linear
1 s animation. Releasing early snaps it back in 0.2 s. `HapticPlayer.crescendo` already builds a soft-to-firm hum
(CHAR-04, awaiting sign-off). The recording's dwell and aborted sliver at 39.3–41.9 s is the linear sweep plus the
snap-back.

**Build.**

1. Track the press with `DragGesture(minimumDistance: 0)` and a `TimelineView`, so the touch point is known.
   `onLongPressGesture` doesn't give a location.
2. **Radial fill** clipped to the capsule, growing from the touch point. Its colour runs from the button's fill to
   mint.
3. **Drain-back:** on early release, progress runs back down at about twice the fill rate, from wherever it reached,
   so a second press picks it up mid-way. The haptic fades with it (reverse the intensity curve, don't cut it).
   Add a "Keep holding" hint after an abort.
4. **Green flood (onboarding only):** on commit, the mint circle grows from the thumb to fill the screen, then
   cross-fades into `BuildingScreen` (already the `.mint` ground). Add a `flood: Bool` parameter. The pledge, Day
   Xero and session commits keep the fill inside the button.
5. Reduce Motion: a straight fill and a cross-fade, no flood. VoiceOver: the default action still completes it.
6. Check on a real device (the simulator has no Core Haptics).

## Bet 3 · Mascot motion pass

**Today.** `CrewCanvas` runs a `TimelineView` and stops under Reduce Motion. Blinks are on only for the `hello` and
`cheer` moods. Many avatars pass `animate: false` (the notification previews, for example). SOS opens as a
`fullScreenCover` from `RootView`, and Jelli is already in it.

**Build.**

1. **Idle life:** a blink every 4–6 s with jitter, so the crew don't blink together, on every mood except sleep.
   Add a ±1.5% breathe on the shared 0.1 Hz clock that SOS and the dock use. Switch on `animate` for avatars that
   are on screen. Pause when the app goes to the background and in Low Power Mode.
2. **Xero → Jelli hand-off (0.7 s)** on SOS entry: Xero waves off at the dock button and Jelli rises in the cover.
   **It overlaps the start of the first sigh rather than going before it.** SOS has to stay one step and immediate
   (S6.5, CHAR-01), so the breathing clock starts at 0 either way. Skipped under Reduce Motion.
3. **Sequenced speech bubbles:** `XeroBubble` and `ReplyBubble` arrive one after another (typing dots, then the
   line, using `dxArrive`). VoiceOver reads the whole exchange at once.
4. Performance check: Instruments on the oldest supported phone with several avatars on screen.

**Decision:** copy for the bubbles (which screens, and the lines).

## Bet 4 · Program path as a living progression

**Today.** `ProgramPathMap` draws a done road, today's play button with Xero beside it, and locked stops. It's
static, so finishing a session changes it with no motion.

**Build.**

1. Store the last path state shown (`dx.pathSeen`: the last session ID drawn as done).
2. Coming back to Program after finishing a session: the new green segment draws in (`trim`, about 0.6 s), the node
   pops (a spring scale with a light haptic), and Xero steps to the next stop. This plays once per session.
3. **"Tomorrow" line on Today:** once today's session is done, the focus card's footer reads "Tomorrow: \<title> ·
   3 min" (`ProgramStore.minutes(of:)`). For a locked Prep 4 the line still names the session, with no paywall
   wording.
4. No XP, points or ranks, as the bet says.
5. Reduce Motion: the final state, no draw-in. Tests: the logic that picks which segment to animate.

## Bet 5 · Hero continuity and glass

**Today.** No `navigationTransition` or `matchedGeometryEffect` anywhere. Deployment target is iOS 18, so
`.navigationTransition(.zoom(sourceID:in:))` works for sheets and full-screen covers. **The tab bar is already
glass on iOS 26**: `DockBackground` uses `glassEffect(.regular.interactive())` and falls back when Reduce
Transparency is on. It stays a custom bar on purpose (the raised SOS button, iPhone Duo's side dock).

**Build.**

1. **Reveal → paywall:** zoom from the reveal's plan card into the paywall. Depends on bet 1.
2. **Onboarding → Home:** `RootView` swaps views; nothing is pushed, so `.zoom` doesn't apply. Use a
   `matchedGeometryEffect` on the Quit Day countdown (the reveal's hero → Today's State A hero) inside a shared
   namespace in `RootView`.
3. **Dock SOS → Craving SOS:** zoom from the raised button. It pairs with bet 3's hand-off.
4. iOS 26 QA pass: the glass dock over each ground, Reduce Transparency, Increase Contrast, dark mode.

**Decision:** confirm we keep the custom glass dock rather than moving to the system `TabView`. Recommendation:
keep it, because the system bar can't raise SOS or stand on Duo's side edge.

## Bet 6 · Instrument and A/B

**Today.** **PostHog was chosen (S1.5, US cloud)**, so no vendor decision is needed. `onboardingStepViewed` fires
for every step (`OnboardingFlow`), and Superwall's paywall and transaction events reach PostHog as
`superwall_event`. Superwall is the A/B tool already in the app.

**Build.**

1. Events: `onboarding_step_completed` with a seconds bucket, `hold_aborted` and `hold_completed`
   (`surface`, `attempt`), and `plan_building_seen` with a seconds bucket. Add a `surface` property to
   `paywall_viewed` and `paywall_purchased` (`onboarding`, `prep4`, `program_day`, `settings`, `slip`) and a
   `trial_days` property. IDs and buckets only, as today.
2. PostHog funnels: onboarding step by step → paywall → trial start → Prep 4 → Day Xero → first renewal.
3. **Experiments in Superwall** (no app release needed once the placements exist):
   - **Position:** the `onboarding_complete` campaign with a 50% holdout (no Day-0 paywall), against
     `unlock_program_day` at Prep 4.
   - **Trial length:** 7 vs 14 days, two paywall variants on `dayxero.annual` and `dayxero.annual14`.
4. **Sample size:** before launch, traffic is TestFlight-sized. At about 5% trial start and a 20% relative lift, each
   arm needs several thousand people who finish onboarding. Run the position test first and keep trial length for
   after launch volume.

**Decision:** run the experiments in Superwall (recommended) or with PostHog flags, and which experiment goes first.

## Bet 7 · After Quit Day and slips

**Today.** Much more is built than the recording shows:

- **Today State B** (UX-09): time free, resilience %, money, the recovery card, urges surfed.
- **The recovery card's wording**, approved 3 Nov.
- **The day's session back on Today** while it's open (`TodayFocus.pick(sessionOpen:)`).
- **The slip flow** (S8): thanks, "nothing resets", the if-then planner (paid), the fresh-Quit-Day offer.
- **A slip logged from Siri or a widget** opens the planner (CLIN-10).

**Build.**

1. Record the simulator walking through each debug scenario: `-dx.homeScenario quitday | day3 | day12 | returning`,
   plus `-dx.seedSlip` and `-dx.seedPouches` for dual use. Review it the same way the onboarding recording was
   reviewed, with timestamps.
2. Check **counters for each product** for dual users. State B's resilience line names one product
   ("smoke-free", "vape-free" or "pouch-free"). Confirm what someone who uses two products sees.
3. Turn what the review finds into tasks in S32.

---

## Order

Bets 1 and 5 depend on decisions, so the code with no open questions goes first.

1. **Now, no decisions needed:** bet 6 events (so bets 1 and 2 are measured from their first build), bet 2 (hold),
   and bet 7's recording and review.
2. **Once Milan answers the bet 1 questions:** bet 1 (paywall), then bet 5's reveal → paywall zoom and onboarding →
   Home transition.
3. **Polish:** bet 4 (path) and bet 3 (mascots), once the bubble copy is in.
4. **Once the build is on TestFlight:** turn on the Superwall position experiment.

## Questions for Milan

1. **Day-0 trial:** option A (7 days, charges on Quit Day), **B (14 days on Day 0, 7 at Prep 4; recommended)**, or
   C (plans only on Day 0, trial stays at Prep 4)?
2. **Prices:** keep $39.99/yr, $9.99/mo and $79.99 lifetime, with ₹2,999/yr in India? (S30.4 still needs the ₹ price
   and the 7-day trial set in App Store Connect.)
3. **Re-ask at Prep 4:** once, as the upgrade sheet, only for people who closed the Day-0 paywall: OK?
4. **Glass dock:** keep the custom glass bar on iOS 26 (recommended) rather than the system tab bar?
5. **Experiments:** run them in Superwall (recommended), with the position test first and trial length after launch?
6. **Bubble copy:** which screens get Xero's sequenced bubbles, and who writes the lines?
