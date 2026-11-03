# Bigger bets: plan (3 Nov 2026)

There are seven bets from the review of the onboarding recording. For each one this plan sets out what the code
already does, what is left to build, and the order to build in. Milan answered the first round of questions on
3 Nov; the second round (Day-0 close, renewal, India offer price) the same evening. Tracker section **S32** in `planning/tasks.json`. Every visible change goes through the Screen Lab first
(`docs/DAYXERO_CRITIQUE_FIX_PLAN.md`, "Lab first"), using the v4 tokens as amended by S27.13; the old design canvas
(`design/handoff/canvas`) predates those changes and isn't the reference.

## Milan's answers (3 Nov 2026)

| Question | Answer |
| --- | --- |
| Paywall model | A hard paywall and a **7-day trial from download**. It replaces MON-01's "Prep 1 to 3 free, trial sold at Prep 4". |
| Prices | Kept: $39.99 a year, $9.99 a month, $99.99 lifetime (D4, S27.8); ₹2,999 a year in India. |
| Prep days for free users | **Each prep day: the first 2 of its 4 cards are free**, then the paywall with a ✕ top right. The activities, cards 3–4, the audio and the mission are paid. |
| Yearly offer | **$29.99 (25% off) on days 4 and 6 after download**, with the same 7-day trial; $39.99 on every other day. |
| Day-0 paywall: can it be closed? | **Yes, with a ✕ that appears after a few seconds** (3 s, as S22.9). The daily prep paywall shows its ✕ straight away. |
| The $29.99 renewal | **Renews at $29.99** every year: a separate product, `dayxero.annual.offer`, with its own 7-day trial. |
| India offer price | **₹2,249.** |
| Tab bar | Keep the custom glass bar. |
| Superwall | Later. DayXero's own paywall everywhere for now. |
| Speech bubbles | **Screens 1, 3, 4, 6 and 7** (Welcome, plan building, slip flow, wave passed, daily prep paywall). Mockups with the lines go in the **Screen Lab** for sign-off (S32.14). |

## The short version

| Bet | Status | Estimate |
| --- | --- | --- |
| 1 · Paywall model | Decided. Day-0 paywall with a delayed ✕, daily prep paywall, the price by day, and a $29.99 offer product. | 3–4 days of code + store setup |
| 2 · Hold-to-set as the pledge | Ready to build | 1–2 days |
| 3 · Mascot motion pass | Idle life ready to build. Bubbles on five screens: mockups with lines in the Screen Lab (S32.14). | 2–3 days |
| 4 · Program path progression | Ready to build | 1.5–2 days |
| 5 · Hero continuity | Ready. Keep the custom glass bar. | 1 day |
| 6 · Instrument and A/B | Events ready to build. Experiments wait for Superwall. | 0.5 day |
| 7 · After Quit Day and slips | A review of what's built | 0.5 day + fixes |

---

## Bet 1 · The paywall model

### What a free user gets

| | Free | Paid (7-day trial, then yearly; or monthly, or lifetime) |
| --- | --- | --- |
| Each prep day | The session intro, then **cards 1 and 2** | The day's activities, cards 3 and 4, "Listen instead" (the audio), the mission |
| Day Xero, Weeks 1–4, boosters | Nothing (the paywall on tap) | Everything |
| Always | The counter, Craving SOS (silent, with subtitles and haptics), the 60-second breathing timer, evening check-ins | Jelli's voice, the if-then planner, the NRT scheduler, trigger heatmaps (as MON-01) |

**Defaults I've assumed (say if any is wrong):**

- **The next prep day opens tomorrow** once a free user has read cards 1 and 2. Without that, a free user would be
  stuck on Prep 1, because days open when the previous one is done. Their free part is stored separately from a
  finished session, so after they subscribe every prep session is open in full as catch-up.
- **Day Xero and the weeks after are paid in full.** That's what "hard paywall" implies. The counter and SOS stay
  free.
- **The "Always free" line changes.** It currently reads "Always free: Prep 1 to 3, your counter, Craving SOS and a
  60-second breathing timer." Proposed: "Always free: your counter, Craving SOS, a 60-second breathing timer and two
  cards from each prep day."

### The daily prep paywall

1. For a free user, the session runs: intro → card 1 → card 2 → **the paywall**, full screen with a ✕ top right.
2. Closing it ends the session on a short screen: "That's today's free part. Two more cards tomorrow." with Done.
   Prep 7 says "Day Xero is part of the full program" instead.
3. Opening the same session again that day goes straight to card 2's end and the paywall. It shows each time
   they reach that point; it never opens on its own anywhere else.
4. Today and the Program path show the day as "2 cards free" for free users, and the rest of the session as locked.

### The price by day since download

| Day since download (download day = day 1) | Yearly price on every paywall that day |
| --- | --- |
| 1–3 | $39.99 · ₹2,999 |
| **4** | **$29.99 · "Today only: 25% off"** |
| 5 | $39.99 |
| **6** | **$29.99 · "Today only: 25% off"** |
| 7 onwards | $39.99 |

- **Download day = the first launch** (`dx.firstLaunchDay`, set once). Days are counted on the app's own day clock
  (`DayClock` with the person's day boundary), so "today only" ends when their day ends. Existing TestFlight installs
  get the date of their first launch after the update.
- The offer is on the yearly plan only. Monthly ($9.99) and lifetime ($99.99) don't change. The yearly card shows
  $39.99 struck through next to $29.99, and the yearly plan stays selected by default.
- The price anchor (MON-03), the charge line and the trial reminder all read the selected product's price, so they
  show $29.99 on offer days without changes.
- Analytics: `paywall_viewed` gains `surface` (`onboarding`, `prep_day`, `program_day`, `settings`, `slip`),
  `price` (`regular` or `offer`) and `day_since_install`.

### Store setup

- **A second yearly product, `dayxero.annual.offer`**, at $29.99 with its own 7-day free trial, in the same
  subscription group (DayXero Pro) and on the `pro` entitlement, in a RevenueCat offering `day_offer`. A product can
  have only one introductory offer, so a separate product is the straightforward way to keep the trial *and* the
  lower price. Trial eligibility is per subscription group, so someone who already used a trial on the $39.99 plan
  won't get a second one.
- **The renewal price:** $29.99 every year (Milan, 3 Nov), which is what a separate product does.
- India: ₹2,999 on the main product (S30.4) and **₹2,249** on the offer (Milan, 3 Nov).
- Superwall: since it's later, the daily paywall goes straight to DayXero's own paywall. Make sure no Superwall
  campaign is live on `unlock_program_day`, or it would show the old prices there.

### The Day-0 paywall

It sits after "Your plan is ready" (reveal → paywall → reminders) and offers the 7-day trial from download. The ✕
fades in after 3 seconds (Milan, 3 Nov); closing it goes on to the reminders screen and then Prep 1's free cards.
VoiceOver users get the close button straight away, since a delayed control they can't see coming is a trap.

### Code changes

- `FullProgram`: replace the Prep 1–3 rule with the per-day free part (cards 1–2) and the "next day opens" rule.
- `ProgramStore` / `SessionFlowView`: the free flow (intro → 2 cards → paywall), stored separately from a finished
  session.
- `PaywallModel`: pick the regular or offer product by day since download, plus "today only" and the struck-through
  price.
- `Subscriptions` / `RCPurchaseController`: load `day_offer` on offer days.
- Today, Program path, upgrade sheet, Settings: "2 cards free" states, and the new "Always free" line.
- Docs: `MONETISATION_TIERS.md` (MON-01 is replaced), `SUPERWALL.md`.
- Tests: the free-flow rule, price by day (days 1–8, a day boundary at 4 am, offer days on a short prep), the
  journey UI test through a prep-day paywall on a stand-in store.

## Bet 2 · Hold-to-set rebuilt as the pledge

`HoldButton` fills a capsule left to right and snaps back in 0.2 s if released early. The Core Haptics crescendo is
already built (CHAR-04). To build:

- **Radial fill from the thumb.** Track the press with `DragGesture(minimumDistance: 0)` and a `TimelineView`.
- **Drain-back** at 2× the fill rate, with the haptic fading rather than cutting out, and "Keep holding" after an
  abort.
- **A mint flood into `BuildingScreen`**, on the onboarding hold only.
- **Fallbacks:** Reduce Motion and VoiceOver paths, and a check on a real device.

## Bet 3 · Mascot motion pass

**Idle life.** Today only the `hello` and `cheer` moods blink, and many avatars pass `animate: false`. To build: a
jittered blink on every mood but sleep, a ±1.5% breathe on the shared 0.1 Hz clock, motion on for avatars that are
on screen, and a pause in the background and in Low Power Mode.

**The Xero → Jelli hand-off into SOS.** About 0.7 s, overlapping the first sigh so it never delays it. The
"Xero passed you to Jelli" chip is already there.

### Speech-bubble candidates

Today only the onboarding question screens (`OnboardingScaffold`) use a real bubble (`XeroBubble`, which already
arrives in order with `dxArrive`). These are the screens where a character already speaks in the first person, or
where a line would sit naturally next to one.

**Strong fits (the character is already talking):**

| # | Screen | Who | What it says now | As bubbles |
| --- | --- | --- | --- | --- |
| 1 | Welcome (`WelcomeScreen`) | Xero | "Hi! I'm Xero." · "Don't quit today." · "Quit on your Quit Day." | Three bubbles in turn. The best showcase. |
| 2 | Quit Day picker (`QuitDayScreen`) | Xero | "I recommend Thu 12 Nov for a full 7-day prep…" | One bubble above the calendar |
| 3 | Plan building (`BuildingScreen`) | Xero, Jelli, Glim | Rows: Prep week, Quit Day, and Jelli and Glim as avatars | Each crew member introduces their job as their row lands ("I'm Jelli. Cravings are my thing.") |
| 4 | Slip flow (`SlipFlow`) | Jelli | "With Jelli" · "Thanks for telling me." | Jelli's bubble, then "Nothing resets." |
| 5 | Craving SOS start (`CravingSOSView`) | Xero → Jelli | The hand-off chip | Pairs with the hand-off: one short line from Jelli. No more text than that during SOS. |
| 6 | Wave passed (`PassedView`) | Jelli | "You rode it out." · "That wave lasted 4 min…" | Two bubbles |
| 7 | Daily prep paywall (new, bet 1) | Xero | none yet | "That's today's free part." Sets up the paywall without a hard sell. |

**Possible fits:**

| # | Screen | Who | Notes |
| --- | --- | --- | --- |
| 8 | Session intro (`SessionIntro`) | Xero | Xero introduces the day's session in one line |
| 9 | Session completion (`SessionCompletion`) | Xero | A cheer line before the stats |
| 10 | Mission card (`MissionCard`) | Xero | "Today's mission" as Xero's ask |
| 11 | Reminders screen (`TrialScreen`) | Xero, Glim | Already notification previews; could arrive one after the other instead |
| 12 | Evening check-in (`CheckInView`, `WindDownView`) | Glim | "How was today, really?" |
| 13 | Quit Day offer (`QuitDayOffer`) | Xero | A Xero avatar with an offer: risky to make a sales line chatty |

**Leave as they are:** Today's cards (the zero-scroll layout has no room), the morning pledge (the words are the
person's own pledge, not Xero's), Progress, the health timeline, milestones and share cards, and Calm tools.

**Chosen (Milan, 3 Nov):** 1, 3, 4, 6 and 7. The mockups are in the Screen Lab, version 9 (What's new › Bigger bets; S32.14), built with the Lab's own
grounds and crew art (the S27.13 six-ground system), and listed as a wave under What's new. Lines that are already
approved are reused word for word, so only the new ones need a yes.

## Bet 4 · Program path as a living progression

When someone comes back after finishing a session:

- The new segment draws in and the node pops, with a light haptic.
- Xero steps to the next stop. This plays once per session (`dx.pathSeen`).
- Today shows "Tomorrow: \<title> · n min" once today's session is done. For free users it reads "Tomorrow: 2 cards
  from \<title>".

No XP, points or ranks. Under Reduce Motion it shows the final state.

## Bet 5 · Hero continuity

- **Onboarding → Today:** a matched countdown hero. `RootView` swaps views rather than pushing one, so
  `matchedGeometryEffect` rather than `.zoom`.
- **Dock SOS → Craving SOS:** a zoom from the raised button, paired with bet 3's hand-off.
- **Reveal → paywall:** a zoom, once the Day-0 paywall is decided.
- **The glass dock stays custom** (Milan, 3 Nov). iOS 26 QA: each ground, Reduce Transparency, Increase Contrast,
  dark mode.

## Bet 6 · Instrument; A/B later

PostHog is already wired. To build:

- **New events:** step completion time, hold aborted and completed, plan-building seen.
- **New paywall properties:** `surface`, `price` and `day_since_install` (from bet 1).
- **Funnels:** onboarding → prep-day paywall → trial start → Day Xero → first renewal. Add a "price on the day they
  bought" split, so the day-4/day-6 offer can be judged without an experiment.

Experiments (paywall position, trial length) wait for Superwall.

## Bet 7 · After Quit Day and slips

Most of it is built: Today State B, the recovery card, the session back on Today, the slip flow and the planner.
Record each post-Quit-Day debug scenario (`quitday`, `day3`, `day12`, `returning`, `-dx.seedSlip`,
`-dx.seedPouches`), review it with timestamps, and check that people who use two products get a counter for each.
Bet 1 changes what a free user sees after Quit Day (it's all paid now), so the review covers both a free user and a
subscriber.

---

## Order

1. **Now:** bet 1's daily prep paywall, price by day and free-tier changes; bet 6's events alongside, so they're
   measured from day one; bet 2.
2. **Milan / store:** create `dayxero.annual.offer`, set the ₹ prices and the 7-day trial (S30.4), and check no
   Superwall campaign is live.
3. **Then:** bet 7's review, bet 4, bet 3 (idle life first, bubbles once the screens and copy are picked), and bet 5.
4. **Bubbles:** build once the Screen Lab mockups are approved (S32.15).

## Still open

1. **The bet 1 defaults:** the next prep day opens after the 2 free cards; Day Xero and the weeks are fully paid;
   the new "Always free" line.
2. **The bubble lines** in the Screen Lab.
