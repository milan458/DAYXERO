# DayXero v1 — Claude Code Handoff Plan

Owner: Milan · Prepared: 23 Oct 2026 · Platform: iOS, SwiftUI (native)

This is the build plan for DayXero v1. Read it end to end before writing any code. A separate file, **DESIGN_METHODOLOGY.md**, will be shared by Milan; it governs every visual and interaction decision and overrides anything visual in this plan where the two disagree.

---

## 0. How you work on this project (read first)

### 0.1 First task: build the localhost task tracker

Before any app work, build a small local web tool that tracks every task in this plan.

**What it is**
- A single local web app served at `http://localhost:4321` (pick another port only if 4321 is taken, and tell Milan).
- One source of truth: `planning/tasks.json` in the repo. The page reads it; you write to it. No database.
- Keep it simple: a tiny Node or Python server plus one HTML page. No build step, no auth. Start command documented in `planning/README.md` (one line, e.g. `npm run tracker` or `python3 planning/server.py`).

**What it shows**
- Every section from part 2 of this plan, in order, with its tasks.
- Per task: ID, title, section, status, notes, date created, date completed.
- Statuses: `pending`, `in_progress`, `blocked`, `awaiting_signoff`, `done`.
- A clear **"Now"** panel at the top: the current section, the current task, and what is waiting on Milan.
- Per section: the mockup sign-off state (`not_started`, `mockups_ready`, `changes_requested`, `signed_off`), with the mockups themselves viewable on the page (images or HTML exported from SwiftUI previews).
- Two buttons per section for Milan: **Approve mockups** and **Request changes** (with a text box). Both write back to `tasks.json` with a timestamp.
- A change log at the bottom (newest first): every status change, task added, and sign-off, with time.
- Auto-refresh every few seconds so Milan sees updates without reloading.

**Rules for keeping it current (non-negotiable)**
- Load every task from this plan into `tasks.json` before starting section 1.
- Mark a task `in_progress` when you start it, and `done` **the moment** it is finished and verified (builds, runs, tests pass). Never batch updates.
- The moment you discover new work (a bug, a missing piece, a follow-up, something Milan asks for in chat), **add it as a task** in the right section with a one-line note saying where it came from.
- If something blocks you, set `blocked` and write why in the notes.
- Never mark a task `done` that you haven't verified.

### 0.2 Section gates: mockups first, then sign-off, then build

Work strictly **one section at a time, in the order in part 2**. For each section:

1. **Mockups.** Design every screen and state in the section (empty, loading, error, dark mode where relevant) following DESIGN_METHODOLOGY.md. Put them in the tracker and set the section to `mockups_ready`.
2. **Stop and ask for sign-off.** Tell Milan in chat that the section's mockups are ready in the tracker. Do not write implementation code for that section, and do not start the next section, until the tracker shows `signed_off`.
3. **Changes requested?** Revise, re-post, ask again. Loop until signed off.
4. **Build** the signed-off section, matching the approved mockups.
5. **Verify**: builds clean, runs on simulator, tests for logic pass, VoiceOver and Dynamic Type checked on the new screens.
6. **Close the section**, mark all its tasks `done`, then move to the next section's mockups.

Section 1 (Foundations) has no user-facing screens except the design-system preview; its "mockup" is the token and component sheet.

### 0.3 Ground rules

- **Native SwiftUI only.** No Flutter, React Native or webviews for app UI.
- **Original design only.** Other apps and design galleries are references for mood, never something to replicate.
- **Port, don't guess.** The previous Flutter build holds the program content and logic (7-day program, 4-week maintenance arc, product variants). Find it, ask Milan for the path if you can't, and port content and rules from it. Where the Flutter code and this plan disagree, this plan wins; flag the conflict as a task.
- **Ask, don't invent,** for anything product-shaped that isn't specified (copy, numbers, health claims, prices). Add it as a `blocked` task with the question.
- **Tone:** progress, not guilt. No fear imagery, no shaming copy, no "you failed".
- **Commits:** small, one task per commit where possible, message references the task ID.

---

## 1. Product context

**What DayXero is:** a quit program for nicotine — cigarettes, vapes, nicotine pouches — with NRT support. Nicotine only in v1 (no other addictions).

**What wins:** completion of the program and word of mouth. Research showed standalone tracker apps barely change quit rates; what works is high adherence, pairing with NRT, ACT-style craving skills, and slip handling that never shames. Every v1 feature serves completion or sharing.

**Who it's for at launch:** 18–35 vapers, pouch users and smokers in the US, UK, Australia and Canada first. India later with its own program. Users must be 18+.

**Locked product decisions (carry these over exactly):**
- Everyone starts at Day 1; no choosing a start day.
- Users keep using nicotine during the prep phase and quit on a set **Quit Day**.
- A program day unlocks only after the previous day is completed.
- A logged slip has **no effect** on the streak or progress visual. Slip messages are supportive.
- Each product (smoking, vaping, pouches) has its own program variant; the smoking program does not apply to vapes or pouches.
- The home counter changes by product: cigarettes for smoking, puffs for vaping, pouches for pouches. Dual users see each product they use.
- Health facts: sourced from the best available public sources for now, each with a visible citation. Keep claims conservative.

**Open product decision (add as a `blocked` task, don't build until Milan answers):**
- Inactivity reset. The earlier spec said 3 idle days in Days 1–5 sends users back to Day 1, with reminders at 24h and 48h. Research flagged full resets as a top complaint in competitor reviews. Ask Milan: keep the reset, or pause and replay the last day instead?

---

## 2. Sections, in build order

Task IDs are `S<section>.<n>`. Load them all into the tracker.

### Section 1 · Foundations

- S1.1 Create the Xcode project: SwiftUI app target, iOS 18 deployment target, Liquid Glass on iOS 26 behind `if #available(iOS 26, *)` with solid fallbacks.
- S1.2 Add extension targets: Widget extension (home and lock screen widgets, Live Activities), and an App Group shared by the app and extensions.
- S1.3 Data layer: SwiftData models for user profile, products used, usage baselines, program progress, logs (cravings, slips, uses), pledges and check-ins, NRT plan. Local-first; no account in v1.
- S1.4 Design system in code from DESIGN_METHODOLOGY.md: colour, type, spacing, radius, glass, motion and haptic tokens, plus core components. Build a preview gallery screen; this is Section 1's mockup for sign-off.
- S1.5 Analytics: wire PostHog or Mixpanel (ask Milan which). Define the event list for the onboarding funnel, paywall, program day starts and completions, craving sessions, slips and shares.
- S1.6 Subscriptions plumbing: RevenueCat (and Superwall if Milan wants paywall tests). Products: monthly, annual, lifetime. Restore purchases.
- S1.7 Localisation setup (String Catalogs), even though v1 ships in English.
- S1.8 Unit-test target; basic CI build check if feasible.

### Section 2 · Onboarding

Goal: build commitment and personalise the plan before the paywall. Target 60%+ of installs completing it.

- S2.1 Welcome and promise: "Don't quit today. Quit on your Quit Day."
- S2.2 Age confirmation (18+). Under 18: friendly exit with a pointer to free youth resources.
- S2.3 Product selection, multi-select: cigarettes, vape, pouches, NRT already in use. Dual use supported.
- S2.4 Usage baseline per product: amount per day (cigarettes, puffs or sessions, pouches with strength in mg), cost per unit or per pack and currency, years of use.
- S2.5 Triggers and when cravings usually hit (multi-select).
- S2.6 Reasons to quit, in the user's own words, with an optional photo. Reused in pledge and SOS.
- S2.7 Past quit attempts and what happened (short, optional).
- S2.8 Choose Quit Day: the date the prep phase ends, with a recommended default.
- S2.9 NRT interest: using it, want it, not interested.
- S2.10 Plan reveal: personal summary of their program, Quit Day, money they'll keep, what the next 7 days look like. This comes **before** the paywall.
- S2.11 Notification permission, asked after the plan reveal with a clear reason.
- S2.12 Optional App Store review prompt placement (ask Milan).
- S2.13 Funnel analytics on every screen; one-tap skip where a question is optional.

### Section 3 · Paywall

Goal: honest, high-converting. Billing traps were the top one-star theme across competitors.

- S3.1 Paywall screen after plan reveal, addressed by name, showing what's included.
- S3.2 Plans: monthly, annual (highlighted), lifetime. Prices from RevenueCat; placeholder starting point $9.99/mo, $39.99/yr, $79.99 lifetime — confirm with Milan.
- S3.3 Free trial on annual (3 days unless Milan says otherwise), with the exact charge date stated on screen.
- S3.4 Plain-language terms: how to cancel in two taps, link to Apple subscription management, refund note.
- S3.5 Free tier that's genuinely useful: counter, craving SOS, Day 1 of the program. Clear upgrade points elsewhere.
- S3.6 Restore purchases; entitlement checks; paywall dismiss path.
- S3.7 No ads anywhere in the app.
- S3.8 Regional pricing hook for India (configured in App Store Connect later).

### Section 4 · Home / Today

- S4.1 Hero progress visual (direction set by DESIGN_METHODOLOGY.md) showing days clear and progress; slips do not reset it.
- S4.2 Per-product counters: cigarettes, puffs or pouches not used; money kept; time regained.
- S4.3 Prep-phase state: countdown to Quit Day, "you can still use during prep", today's prep lesson.
- S4.4 Today's program card: day N of 7, lesson title, duration, start or continue.
- S4.5 Craving button always reachable from Home (thumb zone).
- S4.6 Upcoming milestone hint.
- S4.7 Glass navigation (tab bar: Today, Program, Progress) with iOS 26 Liquid Glass and fallback.

### Section 5 · Program

- S5.1 Port program content from the Flutter build: prep phase, 7-day program, 4-week maintenance arc.
- S5.2 Product variants: smoking, vaping, pouches; dual users get the variant for their main product plus notes for the others (confirm rule with Milan).
- S5.3 Day locking: a day unlocks only after the previous day is completed.
- S5.4 Lesson player: text, audio or short exercises as content requires; completion tracking.
- S5.5 Prep phase until Quit Day, then the quit days.
- S5.6 Maintenance arc (weeks 2–5) changes format, not just content, to avoid the week 3–4 drop-off.
- S5.7 Inactivity behaviour per Milan's answer to the open decision in part 1.
- S5.8 Program overview screen: past, current and locked days.

### Section 6 · Craving SOS

Goal: opens in under a second, from anywhere.

- S6.1 SOS screen: urge-surfing timer (about 3 minutes), guided breathing, the user's reasons and photo.
- S6.2 Core Haptics pattern that slows as the session progresses; Reduce Motion and haptics-off fallbacks.
- S6.3 Outcomes: "It passed" (logs a craving resisted), "I slipped" (goes to slip debrief), "Ping a friend" (share sheet in v1; buddy system comes later).
- S6.4 Live Activity and Dynamic Island showing the countdown with an "It passed" action.
- S6.5 Entry points: Home button, home screen widget, lock screen widget, Control Center control, App Intent / Siri ("I'm having a craving").
- S6.6 Log every SOS session with time and trigger for insights.

### Section 7 · Logging and insights

- S7.1 One-tap logging per product (cigarette, puff session, pouch) from the app, an interactive widget and an App Intent.
- S7.2 Trigger and craving log with optional mood and context.
- S7.3 Insights screen: time-of-day heat map of cravings and uses, top triggers, trend over time. Shows "needs a week of data" until there's enough.
- S7.4 Progress screen: money kept, units avoided, time regained, cravings ridden out.

### Section 8 · Slip handling

- S8.1 Slip logging from SOS, Home and the widget.
- S8.2 Sixty-second slip debrief: what happened, what triggered it, one thing to try next time.
- S8.3 Supportive messages (copy from Milan; placeholders until then). Streak and progress visual unchanged.
- S8.4 Slips feed the insights screen.

### Section 9 · NRT and taper co-pilot

- S9.1 NRT setup: patch, gum, lozenge, inhaler; strength.
- S9.2 Step-down schedules that follow standard product-label guidance only; every screen says to follow the label and ask a pharmacist or doctor. No dosing advice beyond the label.
- S9.3 Pouch-strength taper plan for pouch users (e.g. stepping down mg over weeks), with reminders.
- S9.4 Reminders for patch changes and step-down dates.
- S9.5 NRT shown on Home and Progress.

### Section 10 · Health timeline

- S10.1 Per-product timeline (smoking, vaping, pouches) of what changes in the body over time.
- S10.2 Every item carries a source citation the user can open. Best public sources for now; keep wording conservative.
- S10.3 Store timeline content as data (JSON) so it can be corrected without code changes.

### Section 11 · Daily pledge and evening check-in

- S11.1 Morning pledge with the user's own reason and photo.
- S11.2 Evening check-in: how today went, cravings, mood.
- S11.3 User-set day boundary (when "today" ends) so late-night check-ins count for the right day.
- S11.4 Gentle reminders for both, user-controllable.

### Section 12 · Stress and anxiety toolkit

Scope: short, practical tools for the moments people use nicotine to cope. Not a mental-health app.

- S12.1 Three to five short exercises: breathing patterns, grounding, a brief ACT-style "notice and name" exercise.
- S12.2 Reachable from SOS and the Program tab.
- S12.3 A plain line pointing to professional help and local helplines; no diagnosis or clinical claims.

### Section 13 · Milestones and share cards

- S13.1 Milestone schedule (confirm with Milan; suggested: Quit Day, day 1, 3, 7, 14, 30, 60, 90, 100, 180, 365).
- S13.2 Milestone celebration moment in-app, with haptics and motion; respects Reduce Motion.
- S13.3 Share cards rendered with `ImageRenderer` for Instagram Stories (9:16) and WhatsApp; opt-in, user picks what to show (days, money, cravings ridden out).
- S13.4 Wordmark on every card; no personal data shown by default.

### Section 14 · Notifications

- S14.1 Notification plan: pledge, check-in, lesson available, milestone, NRT reminders, inactivity nudges per the open decision.
- S14.2 Quiet hours and per-type toggles in Settings.
- S14.3 No guilt copy in any notification.

### Section 15 · Settings, privacy and accessibility

- S15.1 Settings: products and baselines, Quit Day, day boundary, notifications, haptics, appearance.
- S15.2 Subscription management link, restore purchases.
- S15.3 Data export and delete-all-data.
- S15.4 Privacy: local-first; analytics disclosure; privacy policy and terms links (ask Milan for URLs).
- S15.5 Accessibility pass across the whole app: VoiceOver labels on every control and the hero visual, full Dynamic Type, Reduce Motion, Reduce Transparency, contrast.
- S15.6 Health disclaimer: educational support, not medical treatment.

### Section 16 · QA and launch prep

- S16.1 End-to-end test of the full journey: onboarding → paywall → prep → Quit Day → day 7 → maintenance.
- S16.2 Test on small and large iPhones, iOS 18 and iOS 26, light and dark, largest text size.
- S16.3 App Store assets: screenshots, preview video, description (ask Milan for copy).
- S16.4 TestFlight build for Milan.
- S16.5 Prepare an App Store featuring nomination (App Store Connect → Featuring → Nominations → App Launch), at least 3 weeks before launch.
- S16.6 Launch checklist in the tracker.

---

## 3. Out of scope for v1 (do not build)

Quit buddy / pacts, AI coach, India program (bidi, gutka, khaini, Hindi), moderated cohorts, human coach tier, open community chat, CO sensor hardware, hypnosis audio, deep level/rank systems, app blockers, fear imagery, medication prescribing, Android. If Milan asks for one, add it as a task in a new "Post-v1" section.

---

## 4. Definition of done for v1

- Every section signed off in the tracker and every task `done`.
- No open `blocked` tasks without Milan's acknowledgement.
- Full journey works offline after onboarding.
- Accessibility pass complete.
- TestFlight build delivered to Milan.
