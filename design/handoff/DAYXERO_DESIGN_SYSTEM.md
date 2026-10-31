# DayXero Design System · v4 "The Crew, alive"

**Status:** final direction agreed in design review, 31 Oct 2026. Not yet built in SwiftUI.
**Owner:** Milan (repo `milan458/dayxero`).
**What this file is:** the complete handoff of a long design session: every decision, rule, token, story beat, screen spec, critique finding and open question, plus the **full source of the final screens** (Appendix C). A new Claude session with no other context should be able to read this file, rebuild the canvas and keep going.

> **Next Claude session, start here.** Read §0, then §2 (decision log) and §14 (open questions) before changing anything. All source files are also committed as plain files under `design/handoff/canvas/project/` (every page from the session) and `design/handoff/critique/project/` (the critique boards). Appendix C embeds the final v4 set so this one file is enough on its own.

---

## Contents

0. How to use this file
1. Product context
2. Decision log (what was decided, what changed, what was rejected)
3. The story: Xero, Jelli and Glim
4. Design principles
5. Tokens: colour, type, size, space, motion
6. Components
7. Persona and data rules (one user, one calendar)
8. Voice and copy
9. Accessibility rules
10. Screen-by-screen spec, F01–F18
11. Personalisation: signals in, what changes
12. Critique of pages 6 and 7, and the 15 fixes (with status)
13. Conflicts with the current repo, and a migration plan
14. Open questions and what to design next
15. File inventory and links
16. Appendix A: the `.dc.html` authoring format
17. Appendix B: canvas index for the v4 page
18. Appendix C: full source of the v4 set

---

## 0. How to use this file

### 0.1 What exists

The session produced one large **Design canvas** (a claude.ai "Design" Artifact) with 8 pages, plus a separate **critique canvas**:

| Page | Name | What it is | Status |
|---|---|---|---|
| 1 | App screens | First colourful pass at every app section | Superseded |
| 2 | Character exploration | 8 candidate mascots (Sprout, Xero, Pebble, Wren, Jelli, Kip, Pace, Glim), each with sheet, Home and SOS mocks, all animated | Reference. Xero, Jelli and Glim chosen |
| 3 | DayXero Night (polished) | Headspace-level polish study: 9 illustrated scenes (`Art`), night UI | Reference |
| 4 | v3 · Light + dark | Onboarding in light and dark following the phone setting, `Horizon` paper-cut art with `clarity` | Reference |
| 5 | Story · Glim × Xero + Jelli | A merged Glim/Xero hybrid ("GlimX") | **Rejected** (the hybrid looked scary) |
| 6 | The Crew · full set | 18 screens, three characters with separate roles, cream backgrounds | Content spec for v4 |
| 7 | Alive · colour, motion, personal | 9 screens: full colour per screen, motion everywhere, adaptive Today | Look-and-feel spec for v4 |
| **8** | **v4 · Final direction** | **18 screens = page 6 content + page 7 feel + critique fixes, plus a dark row** | **FINAL** |

The critique canvas scores pages 6 and 7, lists every issue per screen, and ranks 15 fixes (§12).

### 0.2 Recreating the canvas in a new account

The artifacts are tied to the original claude.ai account, so a new account must recreate them:

1. Ask Claude to create a new Design canvas (`/design`, or the Artifact tool's `quickstart` with intent `design`).
2. Give it the files under `design/handoff/canvas/project/` and its `canvas.json`. Every `*.dc.html` is one artboard, and `canvas.json` holds positions, pages and titles.
3. For only the final set, use the files listed in Appendix B (v4 page + components). Their full source is in Appendix C.
4. `support.js` is supplied by the Design artifact type at publish time. It is not in the repo, and every file keeps the line `<script src="./support.js"></script>` exactly.

### 0.3 Honesty notes

- **Nothing in this session was rendered or screenshot-verified.** All screens were written as source. Contrast ratios were computed from hex values with WCAG 2.x maths, and numbers and dates were checked by script. Anything purely visual (crops, overlaps) still needs a look on a device.
- Facts about the app (prices, lesson titles, slip rules, health copy, trigger list) were checked against the repo and are cited where used.

---

## 1. Product context

- **DayXero** is a native iOS (SwiftUI) quit program for nicotine: cigarettes, vapes and pouches, with NRT support. Website: dayxero.in.
- **Program shape** (from `DayXeroCore/Resources/program.json`): a prep phase (days from sign-up to Quit Day, normally 7), **Quit Day** (also called **Day Xero** in code), then Week 1 daily sessions and Weeks 2–4. Each session is about 3 minutes, unlocks by days since quit, and sessions go strictly in order.
- **Week 1 lesson titles (real):** Day 1 Look after the basics · Day 2 The noisy passengers · Day 3 Lower the bar · Day 4 If things feel flat · Day 5 Nights out · Day 6 "Just one" · Day 7 One week.
- **Day 3 "Lower the bar"** (real beats): (1) note "Your reasons" from the user's reasons; (2) plan builder "If today gets hard, then I will…" with suggestions *Walk for 5 minutes, Text or call someone, Open Craving SOS, Have a shower, Go to bed early, Eat something proper*, saved as `rough_day_plan`; (3) slider "How are you doing, honestly?" from *Really struggling* to *Surprisingly okay*. Mission: "Do one thing that moves your body today, even for five minutes." Completion: "You're through the hump. It gets lighter from here."
- **Day 2 "The noisy passengers"** (real): bus metaphor, "Let it talk, and keep driving". Completion: "They can shout. They can't drive."
- **Pricing** (from `DayXeroTests/PaywallModelTests.swift`): annual **$39.99** ($3.33 a month) with a **3-day trial**, preselected; monthly **$9.99**; lifetime **$79.99**. The trial reminder fires **2 days before** the trial ends. Currency is **USD**.
- **Free forever:** counter, Craving SOS and Day 1.
- **Slip rules** (code comments): "A slip never changes days clear, the Home hero or milestones; it only adds to insights." "Sessions go strictly in order. Nothing here looks at slips: a slip never locks, delays or resets anything." Days clear counts Quit Day itself as day 1.
- **Trigger list** (`DayXeroCore/Model/Enums.swift`, in this order): Waking up, Coffee, After meals, Stress, Drinking, Boredom, With friends, Driving, Work breaks, On my phone, Something else.
- **Approved "then I'll…" suggestions per trigger** (slip talk-through, code): coffee: *take a short walk / switch to tea for a week / have it somewhere new / open Craving SOS*; morning: *drink water before anything else / shower first / step outside for fresh air / open Craving SOS*; meals: *get up from the table straight away / brush my teeth / chew sugar-free gum / take a short walk*; stress: *open Craving SOS / breathe slowly for one minute / step away for five minutes / text a friend*; alcohol: *alternate with water / stand away from smokers / leave a little earlier / keep gum in my pocket*; boredom: *do something with my hands / go for a walk / play a quick game / open Craving SOS*; social: *tell a friend I'm quitting / stand with non-smokers / have gum ready / step away and breathe*.
- **Health timeline** (`DayXeroCore/Resources/health-timeline.json`, source ACS = American Cancer Society): e.g. *Carbon monoxide in your blood drops to normal* · when "A few days" (12–72 h) · "More oxygen reaches your body." / *Circulation and lung function improve* · "2 weeks to 3 months" / *Coughing and shortness of breath ease* · "1 to 12 months" / *Lung cancer risk is about half that of someone who still smokes* · "10 years". **Always quote this file and cite the source.** Never paraphrase timings.
- **App sections in the codebase** (`DayXero/`): App, Calm, Daily, Gallery, Health, Home, Log, Milestones, NRT, Onboarding, Orb, Paywall, Program, ProgramV2, Progress, Resources, SOS, Services, Settings, Toolkit, Water, Widgets. Plus Intents, WidgetViews and DayXeroWidgets (a Live Activity exists).
- **Age gate:** 18+, confirmed at Welcome.

---

## 2. Decision log

In order. "→" marks the final state.

1. **Style brief:** colourful flat illustration of humans, growth, nature and playfulness; full-colour backgrounds; neat screens. → Kept.
2. **Headspace study** (screenshots plus two screen recordings, onboarding and light mode). What we took from it is in §4.2. Illustrations must be **unique to DayXero**, not Headspace-like assets. Light mode must look as good as dark, and the app **follows the phone's appearance setting**. → Kept.
3. **Character exploration:** 8 candidates, all animated. → Three chosen: **Xero, Jelli, Glim**.
4. **Hybrid Glim × Xero ("GlimX")** with Jelli for SOS was tried. → **Rejected**: the user found the hybrid scary. Replaced by **three separate characters, each owning one part of the day**, with a story (§3).
5. **The Crew (page 6):** full 18-screen set with all messaging in place. Moved to cream backgrounds. → The cream move was **my choice, not the user's**, and the user asked why colour was lost. **Colour came back** in page 7.
6. **Alive (page 7):** full colour per screen, motion on every screen, deeper personalisation (adaptive Today). → Kept as the look and feel.
7. **"Will people take a colourful app seriously?"** → Yes, if **the higher the stakes, the quieter the screen** (seriousness tiers, §4.1). Health facts, slips, NRT, paywall and privacy are calm and sourced.
8. **"Why does Headspace work?" / "Aren't characters childish?"** → Characters can work for adults when they are **metaphors with a job**, speak like a calm adult, step back at serious moments, are drawn simply and grow with the user. Main risk: three named characters plus expressive motion pushes the app younger. Mitigations are in §4.3. **Recommended test:** character-led versus character-light onboarding with 8–10 smokers, half aged 40+.
9. **Critique of pages 6 and 7** (separate canvas): Crew 29/50, Alive 31/50. Verdict: "Page 6 is the better product, page 7 is the better feeling. Neither ships as is." 15 ranked fixes (§12).
10. **Merge → v4 (page 8) = FINAL:** page 6's content and flows + page 7's colour and motion + fixes 1–10, 11, 13 and 14 applied. Fix 5 (trial timing) is shown as a **proposal**. Fix 12 is partly done. Fix 15 is applied as Option B (plum dark grounds).
11. **Correction made during the merge:** the critique wrongly said carbon monoxide should read "about 12 hours". `health-timeline.json` says "A few days" (12–72 h), so the original Crew copy was right. → Always use the JSON.
12. **Onboarding crew intro changed:** instead of introducing all three characters at once (too many illustrations, reads young), O5 is now **"Your plan, built around you"** with Xero, and Jelli and Glim are previewed as small avatars that "join later": **Jelli at the first craving, Glim on the first evening**.
13. **Trial proposal:** prep week free; the 3-day trial **starts on Quit Day** (Fri 6 Nov), so the first charge lands **Mon 9 Nov** after three days clear. **Not decided**: the current code starts the trial at sign-up (§14).

### Rejected or superseded

- The GlimX hybrid (scary).
- All-cream screens (lost the brand).
- The Alive-era £ currency, "Mia" name and Sat 14 Nov Quit Day (persona drift).
- The SOS countdown "1:48 left in this wave" (the app can't know when a craving ends).
- Four actions on SOS (too many in a crisis).
- "It's 9:41, right on time for your coffee wave" on SOS (reads as surveillance and frames cravings as scheduled).
- Emoji mood buttons.
- Spring or bouncy motion in onboarding.
- Using the user's name on every screen.

---

## 3. The story: Xero, Jelli and Glim

**Premise:** "Three keepers of a clearing sky." Your world starts hazy. Every day you stay clear, the sky lifts a little. Each keeper looks after one part of the day, and they hand you to each other.

| Character | Realm | Owns | Colour | Voice sample |
|---|---|---|---|---|
| **Xero** | The land · your days | Onboarding, Today (morning and afternoon), pledge, program and lessons, progress. The sun of Day Zero; rises a little every day clear; **also the logo** | Apricot #FFC38A | "Morning. One more day, one more notch of sun." |
| **Jelli** | The sea · your waves | Craving SOS, breathing, after a slip, the Live Activity. Cravings come in waves; Jelli rides each one with you, pulsing with your breath. Never judges | Ocean #2A52DB | "Waves rise, waves pass. Breathe with me." |
| **Glim** | The night · your evenings | Evening check-in, wind down, calm tools, night reminders. Evenings are when people slip most, so Glim stays close | Violet #4A3596 | "Rest well. I'll keep the light on." |

**A day with the crew:**
- 7:30 Xero takes your pledge and hands you today's lesson.
- A craving: tap SOS and Xero passes you to Jelli for three slow minutes.
- It passed: Jelli sends you back with +1 ridden out, and Xero rises a notch.
- If you slip: Jelli stays calm. Nothing resets. One plan for next time.
- 21:30: Xero sets and Glim lights up for a one-minute check-in.
- Week 4 finale: all three show up and the sky is fully clear.

**Hand-over rule:** when one character passes you to another, the first fades or slides out and the next settles in (Settle motion). In SOS a chip reads "Xero passed you to Jelli" and fades after about 3 s. After a wave: "Back to Xero. I rose a little while you were out."

**Introductions (v4):** onboarding shows only Xero at full size. Jelli is introduced at the first craving and Glim on the first evening. During onboarding they only appear as 40px avatars ("Two friends join later").

**Growth:** each character has `stage` 1–4. Stage follows days clear: < 7 → 1, < 14 → 2, < 28 → 3, 28+ → 4.

**Character components** (`Xero.dc.html`, `Jelli.dc.html`, `Glim2.dc.html`): props `mood` (hello | calm | breathe | cheer | sleepy), `stage` (1–4), `animate` (boolean; idle motion in SMIL), `size` (px). `Glim2` is the brighter-headed Glim (head #6B4FD8, shade #5638C4, highlight #9A84F0). The original `Glim.dc.html` is kept for reference.

---

## 4. Design principles

### 4.1 Seriousness tiers: the higher the stakes, the quieter the screen

| Moment | How playful | Rules |
|---|---|---|
| Onboarding, milestones, finale | **Full** | Full colour ground, characters, motion. Celebrate motion allowed only on milestones and the finale |
| Today, program, check-in | **Medium** | Colour ground, smaller character, gentle motion |
| SOS | **Calm** | Colour stays (ocean). Motion slows to breathing pace. No jokes, no predictions, no countdowns |
| Slip, health info, NRT, paywall, privacy | **Serious** | Neutral (cream or navy) surface, sources cited, plain language, character small (88) or absent |

### 4.2 What we took from Headspace

Headspace works because the art is playful while everything around it is calm, adult and credible:

1. A trustworthy guide came first (the voice is the product).
2. The characters are abstract shapes with no age, gender or clothes.
3. The drawings carry mood, not jokes.
4. There is restraint: one colour per screen, plain type, space, slow motion, almost no gamification.
5. It is consistent everywhere.
6. Evidence is part of the brand.
7. Its stakes are lower than ours, so DayXero must be serious at the right moments.

**Applied to DayXero:**
- Keep the characters simple shapes.
- Keep motion at breathing pace.
- Add a human anchor (a named clinical advisor or a real ex-smoker voice) when available.
- Show evidence.
- Pick one signature colour. **Coral** is the brand candidate; Xero apricot is the day colour.

### 4.3 Why characters can work for adults (and the conditions)

**Why it fits quitting:**
- Cravings are lonely and arrive at known times, and a companion fills that gap.
- Jelli maps to **urge surfing** (mindfulness-based relapse prevention).
- Visible progress (Xero rising, the sky clearing) gives the "absence of smoking" a shape.
- A gentle character takes blame out of a slip.

**Conditions:**
- Characters are metaphors, not mascots.
- They speak like a calm adult.
- They step back at serious moments.
- They're drawn simply.
- They grow with the user.
- Two illustrations per screen at most.
- No springs outside celebrations.

**Risk to test:** older, heavy smokers may read cartoons as "not for me". If the character-light variant wins with 40+ users, keep the colour and pull characters back to SOS and milestones.

### 4.4 Colour follows the character, not the clock

- One ground colour per screen, plus at most one other owned colour.
- Reading screens (Program, Lesson, Progress, Slip) are cream in light mode and navy in dark mode.
- Sun is only for celebrations.
- Lilac is only for talking with Xero (chat).

### 4.5 Personal data comes back as help, never as proof of watching

- Predictions ("your coffee wave usually comes around 9:40") live on **Today**, not on SOS.
- Use the user's name **once per session** (Today greeting, or the first chat line).
- Quote the user's reason back at pledge, SOS, lesson and finale.

### 4.6 One rule-set for everything

- 7 type sizes.
- 4 character sizes.
- 3 motion tokens.
- 1 persona.
- 1 date function.
- 1 trigger list.
- 1 label per metric.

---

## 5. Tokens

A machine-readable copy is in `design/handoff/tokens.json`.

### 5.1 Colour: screen grounds (light | dark)

| Token | Light | Dark | Use |
|---|---|---|---|
| coral | #FF7A55 | #241433 (plum) | First breath, beginnings. Brand candidate |
| apricot | #FFC38A | #241433 (plum) | Xero: Today morning and afternoon, pledge, Quit Day, welcome, reminders |
| lilac | #D9CCFF | #1C1640 | Talking with Xero (chat) only |
| mint | #9FE3BC | #0F2A22 | Your plan |
| ocean | **#2A52DB** | #0B1A4A | Jelli: SOS, cravings. Was #3D6BFF, changed for contrast |
| sky | #9CCBFF | #0F2550 | Relief after a wave |
| violet | #4A3596 | #140E3A | Glim: evening and night Today, check-in, wind down |
| sun | #FFD966 | #241433 (plum) | Celebrations only (milestones, finale) |
| cream (reading) | #FBF7F1 | #0E0B2B | Program, lesson, progress, slip |

**Why plum in dark mode:** warm hues near black turn brown or olive (#2B1A10 apricot-dark, #2E2508 sun-dark) and read as dirty. Warm screens use plum #241433 in dark mode and keep their hue in the art and the button (e.g. an apricot #FFC38A button with plum text). This is critique Option B. Option A (keep the warm darks and test on OLED) was not chosen.

### 5.2 Colour: ink and supporting tokens

| Token | Value | Notes |
|---|---|---|
| ink (light) | #1E1A3A | Text on light grounds. 16.6:1 on white |
| ink (dark) / cream | #FFF8EE | Text on dark and saturated grounds |
| muted per ground | coral #3B1A24 · apricot #4A2A1A · lilac #4A3E7A · mint #24493A · sky #24406E · sun #5A4A10 · cream #5E5975 · ocean #E3EAFF · violet #D2C8FF · plum #E0C8E8 · dark-lilac #C9BFF2 · dark-mint #A9D9C0 · dark-ocean #B9C9FF · dark-sky #B9D6FF · navy #B8B3D9 | All ≥ 4.5:1 on their ground |
| surf (cream page) | #F1EBE2 · dark #1B1747 | Chips, quiet surfaces |
| raised | #FFFFFF · dark #2A255F (or #1B1747 on reading screens) | Cards |
| card on colour | rgba(255,248,238,0.66–0.72) light · rgba(255,255,255,0.07–0.12) dark | Translucent cards on colour grounds |
| ocean secondary | **#1D3A9E** solid (dark #1B2C66) | Secondary buttons and cards on ocean. Never translucent white |
| green | **#0F6E43** (dark #2FD08A) | Ticks, progress bars, "+1", lesson card. Replaces #1FA971 (failed contrast) |
| tick on dark chips | #2FD08A | Check marks in selected chips |
| Glim card | #2A1C6E | Check-in card on violet |
| night card | #0E0B2B | Wind-down card |
| shadow (cream) | 0 1px 0 rgba(30,26,58,0.05), 0 8px 22px rgba(30,26,58,0.07) | Raised cards |
| button lip | 0 6px 0 rgba(0,0,0,0.2–0.25) | Primary buttons on colour |
| confetti | #FF7A55 #2A52DB #4A3596 #0F6E43 #FF8FB8 #FFF8EE | Finale only |

**Buttons:**
- On a light colour ground, the primary is ink #1E1A3A with cream text.
- In dark mode, it is cream #FFF8EE with ground-coloured text, or the screen's own hue on plum.
- On ocean and violet, the primary is cream with ocean or violet text.

### 5.3 Measured contrast (WCAG 2.x, computed from hex)

| Pair | Ratio | Result |
|---|---|---|
| Cream on old ocean #3D6BFF | 4.20 | Fail, replaced |
| Cream on ocean #2A52DB | 5.98 | Pass |
| Muted #E3EAFF on #2A52DB | 5.25 | Pass |
| Cream on 16% cream over old ocean (old "Still strong") | 3.29 | Fail, replaced by solid #1D3A9E (9.26) |
| Cream on #1FA971 (old lesson card) | 2.86 | Fail, replaced by #0F6E43 (5.98) |
| #1FA971 "+1" on card over sky | 2.48 | Fail, replaced by #0F6E43 (5.18) |
| Lilac muted #4A3E7A on #D9CCFF | 6.21 | Pass |
| Plum muted #E0C8E8 on #241433 | 11.12 | Pass |
| Apricot #FFC38A button with plum #241433 text | 10.98 | Pass |
| Ocean text on cream | 5.91 | Pass |
| Green #0F6E43 on cream | 5.91 | Pass |
| Coral ink #1E1A3A on #FF7A55 | 6.46 | Pass |
| Cream on violet | 8.89 | Pass |
| Cream on Glim card #2A1C6E | 13.37 | Pass |

### 5.4 Typography

- **Display and headings:** Bricolage Grotesque (opsz 12..96; weights 500/700/800).
- **Body:** DM Sans (400/500/600/700). Google Fonts link: `https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&family=DM+Sans:wght@400;500;600;700&display=swap`.

**Seven-step scale** (map to iOS text styles so Dynamic Type works):

| Step | px | Font | iOS style |
|---|---|---|---|
| Display | 40 | Bricolage 800, −1.2 tracking | .largeTitle (scaled) |
| Large | 32 | Bricolage 800, −1 | .largeTitle |
| Title | 24 | Bricolage 800, −0.6 | .title2 |
| Headline | 19 | Bricolage 700 | .headline |
| Body | 16 | DM Sans 400–600 | .body |
| Footnote | 14 | DM Sans | .footnote |
| Caption | 12 | DM Sans 700, +0.8 tracking (caps for kickers) | .caption — **the floor**; nothing smaller |

**Rules:**
- No half-pixel sizes.
- Kickers are 12px caps with +0.8 tracking.
- Breathing words are real text, not SVG text, so they scale.

### 5.5 Character sizes

| Size | px | Use |
|---|---|---|
| Avatar | 40 | Header, notification previews, hand-back rows, "joins later" (32 in the SOS chip) |
| Card | 88 | Slip screen, finale side characters |
| Scene | 140 | Today, Quit Day, check-in, wind down, plan building, finale centre |
| Hero | 200 | Breathe, Welcome, Pledge, SOS, Passed |

**Max two illustrations per screen** (a scene plus one character). The finale is the only exception.

### 5.6 Space, radius, layout

- Phone frame is 390×844.
- Side gutters are 20–24px; button gutters 22px.
- Top inset is about 50px for the first control row and about 62–70px for page titles.
- Touch targets are ≥ 44px. Primary buttons are 58px tall and fully rounded.
- Chips are 44–48px tall. Answer chips are 14px radius, rounded rectangles distinct from reply pills. Reply pills are 99px radius and right-aligned, like messages.
- Cards are 18–24px radius; phone frames in rows are 44px radius.
- Grids use `repeat(N, minmax(0, 1fr))`.

### 5.7 Motion: three tokens plus breathing

| Token | Spec | Use |
|---|---|---|
| **Arrive** | opacity 0→1 plus 18px rise, 600ms, `cubic-bezier(.2,.7,.2,1)`, 90ms stagger | All text and cards. Order: art, then title, cards, button |
| **Settle** | 900ms `cubic-bezier(.2,.8,.2,1)`, no overshoot, 40–60px travel | Characters entering, hand-overs, plan rows, notification previews |
| **Celebrate** | one spring `cubic-bezier(.3,1.4,.5,1)`, 600–800ms | Only Passed (+1 pop, Jelli), milestones and the finale (characters enter in sequence) |
| **Breathe** | 4 s in, 6 s out (10 s loop; SVG `keyTimes 0;0.4;1`) | SOS, intro, Jelli's pulse, rings |
| **Count** | numbers count up over 0.8–0.9 s, ease-out cubic | Days, units, money, waves, sky % |
| **Ambient** | clouds 20–26 s, waves 5–8 s, stars and fireflies twinkle 1.5–3 s, bubbles rise 5–8 s | Always slow |
| **Hold** | button fills left→right, linear, 1.5 s (Quit Day) or 1.0 s (pledge), then a check label and a haptic | Quit Day, pledge |

**Reduce Motion:** every screen renders its final state. Breathing switches to a gentle colour fade, and haptics carry the rhythm.

**Canvas demos:** each screen replays every 10–20 s for review. **The real app plays arrival once** and never replays while VoiceOver is reading.

**Implementation constraint on the canvas:** imported components cannot use CSS `@keyframes`, so motion is SVG SMIL (`<animate>`) plus state-driven inline CSS transitions (`componentDidMount` → `play()` with `setTimeout` steps).

---

## 6. Components

| Component | File | Props | Notes |
|---|---|---|---|
| Xero | `Xero.dc.html` | mood, stage, animate, size | Sun-like character, day owner, logo |
| Jelli | `Jelli.dc.html` | mood, stage, animate, size | Jellyfish, breathes in SMIL |
| Glim | `Glim2.dc.html` | mood, stage, animate, size | Firefly or night-light character, brighter head |
| Horizon2 | `Horizon2.dc.html` | scene (dawn, dusk, path, sea, night), clarity 0–100, animate, w, h, fit | Paper-cut horizon layers with feDropShadow lift, blurred far clouds, feTurbulence grain. `clarity` controls haze ("the sky clears as you do"). SMIL: sun rise, pulse, cloud drift, waves, bubbles, birds, twinkle |
| Hero2 | `Hero2.dc.html` | scene, clarity, h, edge (colour), animate, fit | Horizon2 plus a curved paper edge in the screen's ground colour: path `M0 h-30 C110 h-54 280 h-54 390 h-30 L390 h L0 h Z` |
| Nav2 | `Nav2.dc.html` | active (today, program, sos, evening, me), theme | Floating pill tab bar, 5 tabs; SOS tab always ocean (#2A52DB light, #7FB0FF dark); 12px labels; links to F screens |
| Rules sheet | `FinalSheet.dc.html` | none | Persona, colours, type, sizes, motion, trial proposal |
| Dark rows | `FDarkA.dc.html`, `FDarkB.dc.html` | none | Import all 18 screens with `theme="dark"` |

**Patterns used across screens** (build these as SwiftUI components):

1. **Primary button:** 58px, pill, a lip shadow on colour grounds, full-width with a 22px gutter.
2. **Hold button:** the primary button with an inner fill layer animating width over 1.0–1.5 s, a label change on completion ("Quit Day set · Fri 6 Nov ✓"), and an `aria-label` describing the double-tap alternative.
3. **Answer tray:** a white (or #2A255F dark) sheet at the bottom of chat with a "YOUR ANSWER" caption, a 2-column grid of 48px chips, a "More…" chip and "Next · n of 3".
4. **Reply bubble:** right-aligned, radius 20 20 4 20, ink fill, with an **Edit** link under it.
5. **Typing dots:** three 8px dots at 0.6, 0.4 and 0.25 opacity.
6. **Plan row:** tick circle, caption kicker, body value. Rows settle in one by one.
7. **Notification preview:** a cream card with a 40px character avatar on its colour, app and character name, time, one-line message.
8. **Top card (Today):** a coloured action card with kicker, 19px title, 14px body and a chevron in a 44px circle.
9. **Stat tile:** 24px Bricolage number with a 12px label, counting up.
10. **Day row:** a 22px status dot (green when done) with label and meta, hairline separators.
11. **Program day card:** a 40px icon box (done, play, lock, star), kicker and title. Today's card is apricot with a lip.
12. **Breathing words:** two stacked real-text layers cross-fading on the 4/6 s clock, `aria-live="polite"`.
13. **Hand-over chip:** an avatar plus "Xero passed you to Jelli". It fades after about 3 s.
14. **Drawn mood faces:** a 32px circle face with eyes and four mouths (Rough, Okay, Good, Proud), used as a radiogroup. **No emoji.**
15. **Prefilled count row:** "From today's SOS: 3 of 3 waves ridden out" with an Edit link.
16. **Recommended tool card:** a cream card on violet with kicker "FOR TONIGHT · 3 MIN", title and a play button.
17. **Health fact card:** a status kicker (HAPPENING NOW / NEXT / STARTING NOW, plus the JSON's `when`), the title, the JSON's `line`, and "Source: American Cancer Society".

---

## 7. Persona and data rules (one user, one calendar)

Every mock reads from this persona. Never invent per-screen numbers.

| Field | Value |
|---|---|
| Name | **Sam** (asked in the chat before it is used) |
| Uses | Cigarettes (12 a day) **and** a vape |
| Triggers | **Coffee, Stress** (in this order) |
| Reason | "To keep up with **Maya** at the park." |
| Joined | **Fri 30 Oct 2026** = prep day 1 |
| Quit Day | **Fri 6 Nov 2026** = Day 1 (days clear counts Quit Day) |
| "Today" in the mocks | **Sun 8 Nov 2026** = Week 1, Day 3 |
| Coffee wave | usually around **9:40** |
| Money | **$7 a day** (about $2,555 a year), USD |
| Cigarettes not smoked | 12 × days clear (Day 3 = 36) |
| Waves ridden out | 14 before the morning craving on Day 3, **15** after |
| Evening check-ins | 2 by Day 3 evening (Day 1, Day 2) |
| Day 3 cravings | 3 logged, 3 ridden out |
| Week 4 finale | **Thu 3 Dec 2026** · 28 days clear · **61** waves · **26** check-ins · **$196** kept · **336** cigarettes not smoked |

**Formulas:**
- **Sky clarity** = 20 during prep, then `min(100, round(20 + 2.8 × daysClear))`. Day 3 = 28, Day 28 = 100. Clarity is driven by days clear only. Waves don't change it.
- **Character stage** = days clear < 7 → 1, < 14 → 2, < 28 → 3, else 4.
- **Date for day N** = Quit Day + (N − 1). Day 3 = Sun 8 Nov. Never hard-code weekdays.
- **Week** = ceil(day / 7).
- **Trial (proposal):** offered on Quit Day Fri 6 Nov, ends Mon 9 Nov, reminder Sat 7 Nov (2 days before end).
- **Trial (current code):** starts at sign-up, so it would end Mon 2 Nov, four days before Quit Day. This is the problem the proposal fixes.

**One label per metric:** "days clear", "waves ridden out" (all time), "cigarettes not smoked", "kept" (money), "check-ins". Show weekly numbers only in Insights.

**Naming:** "Quit Day" is the date you pick. "Day Xero" is the celebration on the day itself and the code's phase name. The UI says Quit Day in onboarding and Program.

---

## 8. Voice and copy

- **Characters speak in the first person** ("I'll plan for each", "Thanks for telling me"). The app never says "us" on character screens.
- **Calm, specific, adult.** No exclamation marks except "Hi! I'm Xero." No "Yay", "buddy" or "You got this!!".
- **No guilt, ever.** Quiet hours are on by default.
- **No false precision.** No craving countdowns. "Most cravings pass within a few minutes." Count the time ridden instead.
- **No surveillance lines.** Predictions go on Today, framed as help: "Your coffee wave usually comes around 9:40. Try having it somewhere new today."
- **The user's name once per session.**
- **Health copy is quoted from `health-timeline.json` with its source.**

**Approved strings (v4):**
- Welcome: "Don't quit today. Quit on your Quit Day." / "Prep for 7 days while you still use as normal, then quit on the day you choose." / "Takes 2 minutes and stays private on this phone. By continuing you confirm you're 18+ and agree to the Terms and Privacy Policy."
- Chat: "Nice to meet you, Sam. What do you use? Pick all that apply." → reply "Cigarettes and a vape" (Edit) → "Using both is common. I'll plan for each, so neither sneaks back in." → "When do cravings usually hit? Pick up to three."
- Quit Day: "I recommend Fri 6 Nov. It gives you the full 7-day prep window. Keep using as normal until then." / "Hold to set Fri 6 Nov" / "Hold for 1.5 seconds. You can change the date later."
- Plan building: "Your plan, built around you" / rows PREP WEEK, QUIT DAY, WAVES TO WATCH, WHY / "Two friends join later. Jelli at your first craving, Glim on your first evening."
- Plan + trial: "Your plan is ready" / "Prep week is on us. Nothing is charged today." / "ON YOUR QUIT DAY · FRI 6 NOV — 3 days free, then $39.99 a year. That's $3.33 a month. We'll ask you on Quit Day, not before."
- Reminders: "Two small nudges a day" / "Xero says good morning, Glim checks in at night. That's it. No guilt, ever, and quiet hours by default." / "Good morning. Ten seconds for today's pledge?" (8:00) / "How did today go? One minute, if you have it." (21:30)
- Pledge: "Today, I won't use nicotine." (alternative: "One wave at a time") / "Because · To keep up with Maya at the park." / "Glim will check in tonight at 21:30. No pressure."
- SOS: "Breathe in… 4" / "…and out, 6" / "Most cravings pass within a few minutes. Ride it with me. You've ridden 0:52." / "It passed" · "Still strong" · "Text a friend" · "I slipped"
- Passed: "You rode it out." / "That wave lasted 2 minutes 10 seconds. Each one you ride makes the next a little quieter." / "Back to Xero. I rose a little while you were out."
- Slip: "Thanks for telling me." / "Waves come and go. Nothing resets: your days clear and Xero's sky stay just as they are. Let's make a plan for next time." / "If it's coffee, then I'll…"
- Check-in headlines:
  - 0 cravings: "A quiet day. Those count too."
  - All ridden out: "3 of 3 waves. All yours." / "Including your coffee wave this morning. You breathed slower each time."
  - Some not ridden out: "Today was hard. You're still here." / "Want one small plan for tomorrow's coffee wave?"
- Wind down: "Rest well." / "Tomorrow's pledge will be here in the morning. If tonight feels restless, breathe with me." / helpline line: "These tools aren't a substitute for professional help. If things feel like too much, find a helpline near you."
- Finale: "28 days. Clear skies." / "$196 kept and 336 cigarettes not smoked. For Maya and the park."

---

## 9. Accessibility rules

- Text ≥ 4.5:1 (≥ 3:1 at 24px+ and for UI parts). Use the token pairs in §5; never translucent white text on ocean.
- Nothing under 12px. Map sizes to Dynamic Type.
- Real `<button>`, `<a href>` and form controls. `aria-pressed` on toggle chips, `role="radio"` and `aria-checked` on single choice, `aria-label` on icon buttons, `role="progressbar"` with values.
- Hold gestures need a visible fill, a haptic, and an accessibility action that doesn't require holding (VoiceOver double-tap).
- Decorative SVG is `aria-hidden`. Breathing words are real text with `aria-live="polite"`.
- Mood faces are drawn SVG with a text label as the accessible name. No emoji.
- Colours that must be told apart also differ in lightness.
- Reduce Motion means the final state, with no loops.

---

## 10. Screen-by-screen spec (v4, page 8)

All screens are 390×844 with props `theme` (light | dark), `motion` (bool) and `replay` (bool, canvas only). Links connect the flow.

### Onboarding (Xero guides; nothing is charged before Quit Day)

**F01 Breathe** · coral
- One breath before any question. Three concentric rings swell on the 10 s breathing clock.
- "Breathe in" and "…and out" cross-fade as real text (in 4 s, out 6 s), with the subline "One slow breath before we begin. In for 4, out for 6."
- Xero hero 200 (`breathe`) settles up from below.
- Skip fades in only after one full cycle (10 s).
- Next: F02.

**F02 Welcome** · apricot
- Hero2 dawn, clarity 20, h 420. Xero 200 settles in, then switches to cheer.
- The "Hi! I'm Xero." bubble pops right after the rise (~1.3 s).
- Title, body and CTA arrive. "Get started" → F03.
- "I already have an account".
- Small print with **Terms and Privacy links** and the 18+ line.

**F03 Questions** · lilac (chat)
- Header: Xero avatar 40, a progress bar (green #0F6E43, 3/6 → 50%), close.
- Messages arrive in sequence with typing dots.
- The reply bubble "Cigarettes and a vape" has an **Edit** link.
- The answer tray slides up: Waking up, Coffee, After meals, Stress, Drinking, Boredom, With friends, More…
- The demo picks Coffee and Stress. The CTA reads "Next · 2 of 3".
- Name asked on the previous step. → F04.

**F04 Quit Day** · apricot
- Hero2 dawn h 270 with Xero 140, and a back button.
- The recommendation copy.
- An 8-cell date strip (Fri 30 … Fri 6). Each cell has a 12px weekday plus a 19px date. Prep cells are tinted, the Quit Day cell is ink. Below: "Prep week · 7 days" and "Quit Day".
- "Pick another date".
- **Hold button** with a 1.5 s fill → "Quit Day set · Fri 6 Nov ✓", plus an accessible label. → F05.

**F05 Your plan builds** · mint
- Progress 5/6. Xero 140 next to the title "Your plan, built around you".
- Four plan rows settle in with ticks: prep dates, Quit Day with both products, waves to watch (coffee and stress), and the reason.
- Then the "Two friends join later" card with Jelli and Glim avatars (40).
- The CTA "See my plan" enables at the end. → F06.

**F06 Plan + trial (PROPOSAL)** · mint
- Xero avatar 40, "Step 6 of 6", "Your plan is ready", "Prep week is on us. Nothing is charged today."
- An includes card: *Free now:* prep week, counter, SOS, Day 1. *With the full program:* four weeks of lessons, evening check-ins, an NRT plan, insights.
- A dark trial card: "ON YOUR QUIT DAY · FRI 6 NOV — 3 days free, then $39.99 a year".
- CTA "Start my prep week". A plans link: "$9.99 a month · $79.99 lifetime".
- Small print: the trial runs to Mon 9 Nov, reminder Sat 7 Nov, the cancel path, Restore purchases.
- **No cheering character on the paywall.**

**F07 Reminders** · apricot
- "Two small nudges a day".
- Two notification previews drop in (Xero 8:00 on an apricot avatar, Glim 21:30 on violet).
- "Change the times". "Yes, remind me" / "Not right now" → F08.

### Your days (Sun 8 Nov, Day 3)

**F08 Today** · adaptive
- **Tweaks:** time (morning, afternoon, evening, night) and day (1–28).
- Morning and afternoon: apricot ground with Xero. Evening and night: violet ground with Glim (plum or #140E3A in dark mode).
- Scene by time: dawn, path, dusk, night. Clarity and stage come from the day.
- Date line e.g. "Sun 8 Nov · Week 1, Day 3". Greeting with the name: "Morning, Sam." / "Afternoon, Sam." / "Evening, Sam." / "Still up, Sam?"
- **Top card by time:**
  - morning: ocean "YOUR COFFEE WAVE · Usually comes around 9:40 · Try having it somewhere new today. Jelli is ready if the wave comes." → SOS
  - afternoon: green lesson card "TODAY · DAY 3 · 3 MIN · Lower the bar"
  - evening: Glim card "How was today, really?"
  - night: navy "Can't sleep? Breathe with Glim"
- Three stat tiles count up: days clear, cigarettes not smoked, $ kept.
- A "Your day" list: pledge (done), today's lesson, evening check-in 21:30.
- Nav2 (today). Max two illustrations.

**F09 Pledge** · apricot
- Hero2 dawn clarity 28 with Xero 200. "Sunday · Day 3".
- "Today, I won't use nicotine." with a wording choice (Won't use nicotine / One wave at a time).
- A "Because" reason card.
- **Hold button** with a 1.0 s fill → "Pledged for today ✓" (Xero cheers).
- "Glim will check in tonight at 21:30. No pressure."

**F10 Program** · cream (reading)
- No hero. "Prep, Quit Day, then four weeks" / "Your program".
- Phase pills with icon ticks: Prep, Quit Day (done), Week 1 (now), Weeks 2–4.
- Day cards 1–7 with the real titles: done (green tick), today (apricot, play icon, "TODAY · DAY 3 · 3 MIN"), locked (lock, "OPENS ON DAY n"), milestone (star).
- "Day 4 opens tomorrow. No rush." Nav2 (program).

**F11 Lesson** · cream (reading)
- Back, a 3-step progress bar (2/3), Xero avatar 40, "Week 1 · Day 3 · 3 min".
- "Lower the bar" / "Getting through the toughest stretch". A reason recap strip.
- The plan-builder card "If today gets hard, then I will…" with the six real suggestions (demo picks Walk for 5 minutes and Open Craving SOS). "Saved as your rough-day plan. It shows up on hard days."
- An audio row ("Prefer to listen? 3:00"). Next.

**F12 Progress** · cream (reading)
- "Since Quit Day · Fri 6 Nov" / "Your progress".
- A Horizon2 path strip (clarity 28) with the pill "Sky 28% clear · clears a little each day".
- A 2×2 stat grid counting up: 3 days clear, 15 waves ridden out, 36 cigarettes not smoked, $21 kept. Below: "$7 a day, about $2,555 a year. 2 evening check-ins with Glim."
- WHAT'S CHANGING: "HAPPENING NOW · A FEW DAYS · Carbon monoxide in your blood drops to normal · More oxygen reaches your body." and "NEXT · 2 WEEKS TO 3 MONTHS · Circulation and lung function improve". "Source: American Cancer Society".
- Nav2 (me).

### Waves, nights, finale

**F13 SOS** · ocean #2A52DB
- A glow ring breathes. Two SMIL waves at the bottom.
- The hand-over chip fades after 3 s. Jelli 200 (`breathe`) settles in from the right.
- Breathing words "Breathe in… 4" / "…and out, 6". The ridden timer counts up.
- A reason card on solid #1D3A9E.
- Actions: cream "It passed" → F14, solid "Still strong". A quiet row: "Text a friend · I slipped" → F15.
- **No countdown, no prediction line.**

**F14 Passed** · sky
- Bubbles rise. Jelli 200 cheers with the **Celebrate** spring.
- "You rode it out." The waves tile ticks 14 → 15 with a "+1" pop (#0F6E43).
- Optional "What set it off?" with the user's triggers first (Coffee, Stress, More…); the demo picks Coffee.
- The hand-back row with a Xero avatar. "Back to my day".

**F15 Slip** · cream (quiet tier)
- Back, 3-step progress (2/3). A Jelli 88 card on an ocean tile, "With Jelli" / "Thanks for telling me."
- The nothing-resets copy.
- "What set it off?" (Coffee selected, Stress, More…).
- "If it's coffee, then I'll…" with the four approved suggestions as a radiogroup ("have it somewhere new" selected).
- "Save my plan". No bounce.

**F16 Check-in** · violet
- Hero2 night (clarity 28) with Glim 140 settling down. "Sunday check-in · Day 3".
- The adaptive headline and line (**tweaks:** cravings, rode).
- The prefilled row "From today's SOS: 3 of 3 waves ridden out · Edit".
- Drawn mood faces (Rough, Okay, Good, Proud); the demo picks Good and Glim cheers.
- The CTA changes with the outcome ("Save and rest" / "Make a plan for tomorrow").
- "Your day ends at 3:00 am · change".

**F17 Wind down** · violet
- Hero2 night with sleepy Glim 140. "Check-in saved" / "Rest well."
- The recommended tool for tonight (slow breathing 4/6, the same rhythm as SOS).
- A list: Box breathing, 5-4-3-2-1, Notice and name, Longer out-breath (4-7-8, last).
- The helpline line. Nav2 (evening, dark).

**F18 Finale** · sun (celebration)
- Hero2 dawn clarity 100 with confetti.
- Xero 140, then Jelli 88, then Glim 88 enter in sequence (Celebrate).
- "Week 4 · program complete · Thu 3 Dec" / "28 days. Clear skies." (Display 40).
- Three tiles count up: 28 days clear · Xero, 61 waves ridden · Jelli, 26 check-ins · Glim.
- "$196 kept and 336 cigarettes not smoked. For Maya and the park."
- The health card "STARTING NOW · 2 WEEKS TO 3 MONTHS · Circulation and lung function improve · Source: American Cancer Society".
- "Keep going" / "Share my card".

### Dark mode

`FDarkA` (F01–F09) and `FDarkB` (F10–F18) show every screen with `theme="dark"`:
- Warm grounds become plum.
- Mint #0F2A22, lilac #1C1640, ocean #0B1A4A, sky #0F2550, violet #140E3A, and the reading screens navy #0E0B2B.

---

## 11. Personalisation: signals in, what changes

| Signal (from onboarding and logs) | What changes |
|---|---|
| Time of day | Host (Xero or Glim), ground colour, scene (dawn, path, dusk, night), greeting, Today's top card |
| Days clear | Sky clarity, character stage, lesson unlocked, date line, counters |
| Product(s) | Units everywhere ("cigarettes not smoked", puffs or pouches for other products), plan copy ("both products") |
| Triggers plus logged cravings | Predicted wave time on Today ("around 9:40") with a matching tip from the approved list; trigger chips always lead with the user's own triggers |
| Reason (and photo, future) | Quoted on pledge, SOS, lesson recap, finale |
| Today's SOS sessions | Check-in prefill and Glim's headline (quiet, all ridden, or hard day) |
| Slip plans (if-then) | Resurface as a tip the next time that trigger is near |
| Rough-day plan (Day 3 lesson) | Shown on hard days |
| Day-end time (default 3:00 am) | When "today" rolls over, for night owls and shift workers |

**Today top-card logic (v4):** morning → predicted wave card (ocean) · afternoon → today's lesson (green) · evening → check-in (Glim card) · night → wind down (navy).

---

## 12. Critique of pages 6 and 7, and the 15 fixes

**Scores (out of 5):**

| Criterion | Crew (6) | Alive (7) |
|---|---|---|
| Story and roles | 4 | 4 |
| Colour and identity | 2 | 4 |
| Typography | 2 | 3 |
| Characters | 3 | 3 |
| Motion | 2 | 4 |
| Personalisation | 3 | 4 |
| Copy and voice | 4 | 3 |
| Trust and safety | 4 | 2 |
| Accessibility | 3 | 2 |
| Data continuity | 2 | 2 |
| **Total** | **29** | **31** |

**Key findings:**
- Crew: 22 font sizes (10 on Plan alone). Xero at 15 sizes. Dawn on 7 of 15 hero screens. Clarity contradictions (60% before quitting, 100% on Day 3). "Fri · Day 3" bug (Day 3 is Sunday). Three different trigger lists. Trial ending 4 days before Quit Day. A "1:48 left" countdown. Four SOS actions. "Thanks for telling us".
- Alive: SOS contrast failures (4.20 / 3.68 / 3.29 / 3.39:1). Lesson green 2.86:1. Six regressions from Crew (Terms and Privacy, Edit response, slip and friend routes, trigger tagging, check-in counts, cited health fact). Colour collisions (lilac = chat and evening, sun = afternoon and finale, mint vs #1FA971). Nine motion curves. £ instead of $, Mia vs Maya, Sat 14 Nov. Emoji mood buttons. Surveillance line on SOS. Name overuse.
- Kept from Crew: all flows, calm copy, sources, legal, slip flow, trigger tagging, day-end setting, drawn faces, Edit response. Kept from Alive: colour per character, arrival, count-up and hand-over motion, adaptive Today, two-action SOS, Glim's adaptive line, Reduce Motion end states, Xero's speech bubble.

**The 15 fixes, with status in v4:**

| # | Fix | Effort | Status in v4 |
|---|---|---|---|
| 1 | SOS contrast: ocean → #2A52DB, solid #1D3A9E secondaries, full-opacity body; green → #0F6E43 | S | **Done** |
| 2 | Put back what Alive dropped (Terms and Privacy, Edit response, slip and friend routes, trigger tagging, check-in counts, cited fact) | M | **Done** |
| 3 | Drop the craving countdown; count time ridden | S | **Done** |
| 4 | One persona, one date function, $, one label per metric | S | **Done** |
| 5 | Trial timing | Product | **Proposal shown** (trial starts on Quit Day). Needs a decision |
| 6 | Sky clarity from days clear | S | **Done** |
| 7 | 7-step type scale, nothing under 12px | M | **Done** on the canvas |
| 8 | 4 character sizes, max 2 illustrations | M | **Done** (finale is the exception) |
| 9 | Colour follows the character | S | **Done** |
| 10 | Three motion tokens, no springs in onboarding | S | **Done** |
| 11 | User's own triggers first | S | **Done** |
| 12 | Accessible hold gestures | M | **Done in design** (fill, label, aria). The haptic is a build task |
| 13 | Drawn faces, not emoji | S | **Done** |
| 14 | Voice pass ("me", name once, no surveillance line) | S | **Done** |
| 15 | Dark mode for warm screens | Product | **Option B applied** (plum). Test on OLED |

---

## 13. Conflicts with the current repo, and a migration plan

**The shipping code follows a different direction.** `docs/DESIGN_METHODOLOGY.md` ("Biophilic OLED Minimalist UI / Dark Luxury Wellness") currently **overrides the plan on visual questions** (per `README.md`). `DayXeroCore/DesignSystem/Colors.swift` uses sage #BCC388, moss #43511C, amber #E5A93C, terracotta #C85A54, canvas #F3F4EE / black #000000, primary #11140A. Fonts are **Inter** and JetBrains Mono.

**v4 replaces that direction.** Before any SwiftUI work, Milan must explicitly decide to:

1. Update or replace `docs/DESIGN_METHODOLOGY.md` with this file's principles (or mark it superseded).
2. Replace `Colors.swift` tokens with §5 (adaptive light and dark pairs; Colour assets per ground).
3. Add Bricolage Grotesque and DM Sans (both Google Fonts, OFL) to `DayXeroCore/Resources/Fonts` and map the 7-step scale in `Typography.swift` to Dynamic Type styles.
4. Encode the motion tokens in `Motion.swift`: Arrive, Settle, Celebrate, Breathe (4/6), Count, with Reduce Motion fallbacks.
5. Rebuild characters and scenes as SwiftUI `Canvas` / `Shape` drawings, or export them as vector assets (PDF or SVG) from the `.dc.html` SVG. Idle motion becomes `TimelineView` or SwiftUI animations.

**Suggested SwiftUI token names:**
- `Ground.coral/apricot/lilac/mint/ocean/sky/violet/sun/reading`, each with light and dark.
- `Ink.primary/muted(ground)`, `Fill.oceanSecondary`, `Fill.green`.
- `Type.display/large/title/headline/body/footnote/caption`.
- `CharacterSize.avatar/card/scene/hero`.
- `Motion.arrive/settle/celebrate/breathe`.

---

## 14. Open questions and what to design next

**Decisions needed (Milan):**
1. **Trial timing:** start the 3-day trial on Quit Day (proposal) or keep it at sign-up? If on Quit Day, design the **Quit Day offer screen** (the paywall shown on Fri 6 Nov) and the prep-week "free" state.
2. **Adopt v4 over the Biophilic OLED direction** in the repo (§13)?
3. **Brand colour:** coral as the signature (icon, website, marketing) while apricot stays Xero's day colour?
4. **Dark-mode warm screens:** confirm plum after testing on an OLED phone.
5. **Inactivity reset:** an open product decision. Never claim "nothing resets if you miss a day" until it's decided. Slips never reset; that is decided in code.
6. **Character-led vs character-light:** run the 5-second test and preference test with 8–10 smokers, half aged 40+.

**Screens still to design in v4:**
- Quit Day offer / paywall
- Quit Day celebration ("Day Xero")
- Milestones (Day 1, 3, 7, …)
- NRT plan and NRT info (serious tier)
- Insights (weekly numbers live here)
- Health timeline detail
- Settings (reminders, day-end time, quiet hours, appearance follows the phone)
- Reasons and photo editor
- Calm library
- Lock screen / Live Activity (Jelli during SOS)
- Widgets
- Empty, error and offline states

---

## 15. File inventory and links

**Artifact links** (owned by the original account):
- Main design canvas (8 pages): https://claude.ai/artifact/STfRGW2CvRRY7VWDPNwFRy (shared "anyone with the link")
- Critique canvas: https://claude.ai/artifact/SxCGkACEXpYWBcwKe4574b (private to the original account unless shared)

**In the repo:**
- `design/handoff/DAYXERO_DESIGN_SYSTEM.md`: this file
- `design/handoff/tokens.json`: tokens
- `design/handoff/canvas/project/`: every artboard from the main canvas plus `canvas.json`
- `design/handoff/critique/project/`: critique boards plus `canvas.json`. The critique boards import screens by name, so copy the screen and component files next to them to render.

### Every artboard on the main canvas, by page

**App screens** (`screens`, 20 artboards)

| File | Title | Size |
|---|---|---|
| `Main.dc.html` | 01 · Welcome (onboarding) | 390×844 |
| `Home.dc.html` | 02 · Today (home) | 390×844 |
| `SOS.dc.html` | 03 · Craving SOS | 390×844 |
| `Milestone.dc.html` | 04 · Milestone + health | 390×844 |
| `Products.dc.html` | 05 · Onboarding: what you use | 390×844 |
| `Reasons.dc.html` | 06 · Onboarding: your why | 390×844 |
| `QuitDay.dc.html` | 07 · Onboarding: Quit Day | 390×844 |
| `Plan.dc.html` | 08 · Plan reveal | 390×844 |
| `Paywall.dc.html` | 09 · Paywall | 390×844 |
| `Program.dc.html` | 10 · Program map | 390×844 |
| `Lesson.dc.html` | 11 · Lesson player | 390×844 |
| `Insights.dc.html` | 12 · Insights | 390×844 |
| `Slip.dc.html` | 13 · Slip debrief | 390×844 |
| `NRT.dc.html` | 14 · NRT co-pilot | 390×844 |
| `Timeline.dc.html` | 15 · Health timeline | 390×844 |
| `Pledge.dc.html` | 16 · Morning pledge | 390×844 |
| `CheckIn.dc.html` | 17 · Evening check-in | 390×844 |
| `Calm.dc.html` | 18 · Calm toolkit | 390×844 |
| `Settings.dc.html` | 19 · Settings + privacy | 390×844 |
| `LockScreen.dc.html` | 20 · Notifications + widgets | 390×844 |

**Character exploration** (`characters`, 32 artboards)

| File | Title | Size |
|---|---|---|
| `Sprout.dc.html` | A · Sprout (component) | 240×240 |
| `SproutSheet.dc.html` | A · Sprout sheet | 900×560 |
| `SproutHome.dc.html` | A · Sprout on Home | 390×844 |
| `SproutSOS.dc.html` | A · Sprout on SOS | 390×844 |
| `Xero.dc.html` | B · Xero (component) | 240×240 |
| `XeroSheet.dc.html` | B · Xero sheet | 900×560 |
| `XeroHome.dc.html` | B · Xero on Home | 390×844 |
| `XeroSOS.dc.html` | B · Xero on SOS | 390×844 |
| `Pebble.dc.html` | C · Pebble (component) | 240×240 |
| `PebbleSheet.dc.html` | C · Pebble sheet | 900×560 |
| `PebbleHome.dc.html` | C · Pebble on Home | 390×844 |
| `PebbleSOS.dc.html` | C · Pebble on SOS | 390×844 |
| `Wren.dc.html` | D · Wren (component) | 240×240 |
| `WrenSheet.dc.html` | D · Wren sheet | 900×560 |
| `WrenHome.dc.html` | D · Wren on Home | 390×844 |
| `WrenSOS.dc.html` | D · Wren on SOS | 390×844 |
| `Jelli.dc.html` | E · Jelli (component) | 240×240 |
| `JelliSheet.dc.html` | E · Jelli sheet | 900×560 |
| `JelliHome.dc.html` | E · Jelli on Home | 390×844 |
| `JelliSOS.dc.html` | E · Jelli on SOS | 390×844 |
| `Kip.dc.html` | F · Kip (component) | 240×240 |
| `KipSheet.dc.html` | F · Kip sheet | 900×560 |
| `KipHome.dc.html` | F · Kip on Home | 390×844 |
| `KipSOS.dc.html` | F · Kip on SOS | 390×844 |
| `Pace.dc.html` | G · Pace (component) | 240×240 |
| `PaceSheet.dc.html` | G · Pace sheet | 900×560 |
| `PaceHome.dc.html` | G · Pace on Home | 390×844 |
| `PaceSOS.dc.html` | G · Pace on SOS | 390×844 |
| `Glim.dc.html` | H · Glim (component) | 240×240 |
| `GlimSheet.dc.html` | H · Glim sheet | 900×560 |
| `GlimHome.dc.html` | H · Glim on Home | 390×844 |
| `GlimSOS.dc.html` | H · Glim on SOS | 390×844 |

**DayXero Night (polished)** (`night`, 8 artboards)

| File | Title | Size |
|---|---|---|
| `NightSystem.dc.html` | N0 · System sheet | 1100×760 |
| `Art.dc.html` | N · Art tile (component) | 320×240 |
| `NightWelcome.dc.html` | N1 · Welcome | 390×844 |
| `NightToday.dc.html` | N2 · Today | 390×844 |
| `NightExplore.dc.html` | N3 · Explore / toolkit | 390×844 |
| `NightSOS.dc.html` | N4 · Craving SOS | 390×844 |
| `NightProgress.dc.html` | N5 · Progress | 390×844 |
| `NightMilestone.dc.html` | N6 · Milestone | 390×844 |

**v3 · Light + dark (follows phone)** (`v3`, 10 artboards)

| File | Title | Size |
|---|---|---|
| `V3System.dc.html` | v3 · System: light + dark | 1300×820 |
| `Horizon.dc.html` | v3 · Horizon art (component) | 400×300 |
| `OB1Breathe.dc.html` | 1 · Breathe intro | 390×844 |
| `OB2Welcome.dc.html` | 2 · Welcome | 390×844 |
| `OB3Chat.dc.html` | 3 · Chat questions | 390×844 |
| `OB4Building.dc.html` | 4 · Building your plan | 390×844 |
| `OB5Plan.dc.html` | 5 · Plan + trial | 390×844 |
| `OB6Notify.dc.html` | 6 · Reminders | 390×844 |
| `V3Today.dc.html` | 7 · Today | 390×844 |
| `V3DarkRow.dc.html` | Same screens, phone in dark mode | 3210×844 |

**Story · Glim × Xero + Jelli** (`story`, 8 artboards)

| File | Title | Size |
|---|---|---|
| `StorySheet.dc.html` | Story · Glim × Xero, with Jelli | 1300×760 |
| `GlimX.dc.html` | Glim × Xero (component) | 240×240 |
| `StBreathe.dc.html` | 1 · Glim breathes with you | 390×844 |
| `StWelcome.dc.html` | 2 · Welcome | 390×844 |
| `StSOS.dc.html` | 3 · SOS hands over to Jelli | 390×844 |
| `StNight.dc.html` | 4 · Evening check-in | 390×844 |
| `StMilestone.dc.html` | 5 · Milestone | 390×844 |
| `StDarkRow.dc.html` | Story screens, phone in dark mode | 2270×844 |

**The Crew · Xero, Jelli, Glim (full set)** (`trio`, 25 artboards)

| File | Title | Size |
|---|---|---|
| `CrewSheet.dc.html` | The Crew · story + roles | 1500×900 |
| `Glim2.dc.html` | Glim, night tone (component) | 240×240 |
| `Hero.dc.html` | Hero art + paper edge (component) | 390×300 |
| `Nav.dc.html` | Tab bar (component) | 390×100 |
| `C01Breathe.dc.html` | O1 · Breathe | 390×844 |
| `C02Welcome.dc.html` | O2 · Welcome | 390×844 |
| `C03Chat.dc.html` | O3 · Questions | 390×844 |
| `C04QuitDay.dc.html` | O4 · Quit Day | 390×844 |
| `C05Crew.dc.html` | O5 · Meet your crew | 390×844 |
| `C06Plan.dc.html` | O6 · Plan + trial | 390×844 |
| `C07Remind.dc.html` | O7 · Reminders | 390×844 |
| `C08Today.dc.html` | D1 · Today (Xero) | 390×844 |
| `C09Pledge.dc.html` | D2 · Morning pledge | 390×844 |
| `C10Program.dc.html` | D3 · Program map | 390×844 |
| `C11Lesson.dc.html` | D4 · Lesson | 390×844 |
| `C12Progress.dc.html` | D5 · Progress | 390×844 |
| `C13SOS.dc.html` | W1 · Craving SOS (Jelli) | 390×844 |
| `C14Passed.dc.html` | W2 · The wave passed | 390×844 |
| `C15Slip.dc.html` | W3 · After a slip | 390×844 |
| `C16CheckIn.dc.html` | N1 · Evening check-in (Glim) | 390×844 |
| `C17WindDown.dc.html` | N2 · Wind down | 390×844 |
| `C18Finale.dc.html` | T1 · Week 4, all three | 390×844 |
| `CDarkA.dc.html` | Onboarding · dark | 3210×844 |
| `CDarkB.dc.html` | Your days · dark | 2270×844 |
| `CDarkC.dc.html` | Waves, nights, finale · dark | 2740×844 |

**Alive · colour, motion, personal** (`alive`, 13 artboards)

| File | Title | Size |
|---|---|---|
| `AliveSheet.dc.html` | Colour, motion + personalisation rules | 1500×820 |
| `Horizon2.dc.html` | Horizon, alive (component) | 400×300 |
| `Hero2.dc.html` | Hero, alive (component) | 390×300 |
| `A01Breathe.dc.html` | 1 · Breathe · coral | 390×844 |
| `A02Welcome.dc.html` | 2 · Welcome · apricot | 390×844 |
| `A03Chat.dc.html` | 3 · Chat with Xero · lilac | 390×844 |
| `A04Crew.dc.html` | 4 · Your plan, your crew · mint | 390×844 |
| `A05Today.dc.html` | 5 · Today · adapts to you (try Tweaks) | 390×844 |
| `A06SOS.dc.html` | 6 · SOS with Jelli · ocean | 390×844 |
| `A07Passed.dc.html` | 7 · The wave passed · sky | 390×844 |
| `A08CheckIn.dc.html` | 8 · Evening with Glim · violet | 390×844 |
| `A09Finale.dc.html` | 9 · Week 4 finale · sun | 390×844 |
| `ADark.dc.html` | Same screens · phone in dark mode | 4150×844 |

**v4 · Final direction (Crew content × Alive feel)** (`final`, 22 artboards)

| File | Title | Size |
|---|---|---|
| `FinalSheet.dc.html` | Final rules · persona, colour, type, size, motion | 1500×820 |
| `Nav2.dc.html` | Tab bar v4 (component) | 390×100 |
| `F01Breathe.dc.html` | O1 · Breathe · coral | 390×844 |
| `F02Welcome.dc.html` | O2 · Welcome · apricot | 390×844 |
| `F03Chat.dc.html` | O3 · Questions · lilac | 390×844 |
| `F04QuitDay.dc.html` | O4 · Quit Day · apricot | 390×844 |
| `F05Crew.dc.html` | O5 · Your plan builds · mint | 390×844 |
| `F06Plan.dc.html` | O6 · Plan + trial proposal · mint | 390×844 |
| `F07Remind.dc.html` | O7 · Reminders · apricot | 390×844 |
| `F08Today.dc.html` | D1 · Today · adapts (try Tweaks) | 390×844 |
| `F09Pledge.dc.html` | D2 · Pledge · apricot | 390×844 |
| `F10Program.dc.html` | D3 · Program · reading | 390×844 |
| `F11Lesson.dc.html` | D4 · Lesson · reading | 390×844 |
| `F12Progress.dc.html` | D5 · Progress · reading | 390×844 |
| `F13SOS.dc.html` | W1 · SOS · ocean | 390×844 |
| `F14Passed.dc.html` | W2 · Passed · sky | 390×844 |
| `F15Slip.dc.html` | W3 · Slip · quiet tier | 390×844 |
| `F16CheckIn.dc.html` | N1 · Check-in · violet | 390×844 |
| `F17WindDown.dc.html` | N2 · Wind down · violet | 390×844 |
| `F18Finale.dc.html` | T1 · Week 4 · sun | 390×844 |
| `FDarkA.dc.html` | Dark mode · O1–D2 | 4150×844 |
| `FDarkB.dc.html` | Dark mode · D3–T1 | 4150×844 |

**Critique canvas** (separate artifact)

| File | Title | Page |
|---|---|---|
| `Main.dc.html` | Verdict · both pages scored | summary |
| `Fixes.dc.html` | Fix order · what to merge | summary |
| `CrewSystem.dc.html` | Crew · system-level issues | p6 |
| `CrewStory.dc.html` | Crew · story + data continuity | p6 |
| `CrewOnboarding.dc.html` | Crew · O1–O7 screen by screen | p6 |
| `CrewDays.dc.html` | Crew · D1–D5 screen by screen | p6 |
| `CrewWaves.dc.html` | Crew · W1–T1 screen by screen | p6 |
| `AliveSystem.dc.html` | Alive · system-level issues | p7 |
| `AliveContrast.dc.html` | Alive · contrast + dark mode, measured | p7 |
| `AliveFlowA.dc.html` | Alive · 1–5 screen by screen | p7 |
| `AliveFlowB.dc.html` | Alive · 6–9 screen by screen | p7 |

The critique canvas also lists, on its "Source screens" page, copies of C01–C18, A01–A09 and the components (identical to the main canvas files).

---

## 16. Appendix A: the `.dc.html` authoring format (Design canvas)

Each artboard is one self-contained file:

```html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Screen name</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=...&amp;display=swap">
<style>body{margin:0}</style>
</helmet>
<div style="width: 390px; height: 844px; background: {{t.bg}}"> … </div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"theme":{"editor":"enum","options":["light","dark"],"default":"light"},"$preview":{"width":390,"height":844}}'>
class Component extends DCLogic {
  renderVals() { return { t: { bg: '#FFC38A' } }; }
}
</script>
</body>
</html>
```

**Rules that bite:**
- Keep the `support.js` line exactly.
- `{{hole}}` is a dotted lookup into `renderVals()` only, never an expression.
- `<sc-for list="{{items}}" as="x" hint-placeholder-count="N">` repeats; `<sc-if value="{{cond}}">` branches.
- `<dc-import name="Xero" mood="…" hint-size="Wpx,Hpx"></dc-import>` mounts a sibling file. The `name` must be literal (no holes), and you never self-close it.
- Links between artboards are `<a href="F02Welcome.dc.html">`.
- Classic JS only (`class Component extends DCLogic`), with React lifecycle (`componentDidMount`, `setState`).
- `data-props` is single-quoted JSON (escape `&` as `&amp;`, `'` as `&#39;`).
- Avoid apostrophes inside single-quoted JS strings (use `’`).
- No CSS `@keyframes` in imported components: use SVG SMIL plus state-driven transitions.
- Don't put `sc-for` inside `<svg>`; unroll SVG repeats instead.
- No emoji in the UI. No external network except Google Fonts and uploaded assets.
- `canvas.json` (v3) has `boards` keyed by file path with x, y, w, h, page, title and `is_interactive`, plus `order`, `notes` (kind `title1` for row titles) and `pages`.

**Motion pattern used on every screen:**

```js
componentDidMount() { this.play(); }
componentWillUnmount() { (this.timers || []).forEach(clearTimeout); }
play() {
  (this.timers || []).forEach(clearTimeout); this.timers = [];
  this.setState({ on: false });
  this.timers.push(setTimeout(() => this.setState({ on: true }), 300));
  if (String(this.props.replay ?? true) !== 'false') this.timers.push(setTimeout(() => this.play(), 10000));
}
// in renderVals():
const motion = String(this.props.motion ?? true) !== 'false';
const on = !motion || Boolean(this.state && this.state.on);
const ease = 'cubic-bezier(.2,.7,.2,1)';
const a = (i) => `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 18}px); transition: opacity 600ms ${ease} ${i * 90}ms, transform 600ms ${ease} ${i * 90}ms`;
```

## 17. Appendix B: canvas index for the v4 page

A minimal `canvas.json` for a fresh canvas holding only the final set and its components. Add `createdOnFiles` and `launch` as the new canvas type requires. Component positions are new; everything else is copied from the original.

```json
{
 "v": 3,
 "title": "DayXero Illustrated Screens",
 "pages": [
  {
   "id": "final",
   "name": "v4 · Final direction (Crew content × Alive feel)"
  }
 ],
 "boards": {
  "FinalSheet.dc.html": {
   "x": 0,
   "y": 0,
   "w": 1500,
   "h": 820,
   "page": "final",
   "title": "Final rules · persona, colour, type, size, motion"
  },
  "Nav2.dc.html": {
   "x": 1580,
   "y": 0,
   "w": 390,
   "h": 100,
   "page": "final",
   "title": "Tab bar v4 (component)"
  },
  "F01Breathe.dc.html": {
   "x": 0,
   "y": 1200,
   "w": 390,
   "h": 844,
   "page": "final",
   "title": "O1 · Breathe · coral",
   "is_interactive": true
  },
  "F02Welcome.dc.html": {
   "x": 470,
   "y": 1200,
   "w": 390,
   "h": 844,
   "page": "final",
   "title": "O2 · Welcome · apricot",
   "is_interactive": true
  },
  "F03Chat.dc.html": {
   "x": 940,
   "y": 1200,
   "w": 390,
   "h": 844,
   "page": "final",
   "title": "O3 · Questions · lilac",
   "is_interactive": true
  },
  "F04QuitDay.dc.html": {
   "x": 1410,
   "y": 1200,
   "w": 390,
   "h": 844,
   "page": "final",
   "title": "O4 · Quit Day · apricot",
   "is_interactive": true
  },
  "F05Crew.dc.html": {
   "x": 1880,
   "y": 1200,
   "w": 390,
   "h": 844,
   "page": "final",
   "title": "O5 · Your plan builds · mint",
   "is_interactive": true
  },
  "F06Plan.dc.html": {
   "x": 2350,
   "y": 1200,
   "w": 390,
   "h": 844,
   "page": "final",
   "title": "O6 · Plan + trial proposal · mint",
   "is_interactive": true
  },
  "F07Remind.dc.html": {
   "x": 2820,
   "y": 1200,
   "w": 390,
   "h": 844,
   "page": "final",
   "title": "O7 · Reminders · apricot",
   "is_interactive": true
  },
  "F08Today.dc.html": {
   "x": 0,
   "y": 2460,
   "w": 390,
   "h": 844,
   "page": "final",
   "title": "D1 · Today · adapts (try Tweaks)",
   "is_interactive": true
  },
  "F09Pledge.dc.html": {
   "x": 470,
   "y": 2460,
   "w": 390,
   "h": 844,
   "page": "final",
   "title": "D2 · Pledge · apricot",
   "is_interactive": true
  },
  "F10Program.dc.html": {
   "x": 940,
   "y": 2460,
   "w": 390,
   "h": 844,
   "page": "final",
   "title": "D3 · Program · reading",
   "is_interactive": true
  },
  "F11Lesson.dc.html": {
   "x": 1410,
   "y": 2460,
   "w": 390,
   "h": 844,
   "page": "final",
   "title": "D4 · Lesson · reading",
   "is_interactive": true
  },
  "F12Progress.dc.html": {
   "x": 1880,
   "y": 2460,
   "w": 390,
   "h": 844,
   "page": "final",
   "title": "D5 · Progress · reading",
   "is_interactive": true
  },
  "F13SOS.dc.html": {
   "x": 0,
   "y": 3720,
   "w": 390,
   "h": 844,
   "page": "final",
   "title": "W1 · SOS · ocean",
   "is_interactive": true
  },
  "F14Passed.dc.html": {
   "x": 470,
   "y": 3720,
   "w": 390,
   "h": 844,
   "page": "final",
   "title": "W2 · Passed · sky",
   "is_interactive": true
  },
  "F15Slip.dc.html": {
   "x": 940,
   "y": 3720,
   "w": 390,
   "h": 844,
   "page": "final",
   "title": "W3 · Slip · quiet tier",
   "is_interactive": true
  },
  "F16CheckIn.dc.html": {
   "x": 1410,
   "y": 3720,
   "w": 390,
   "h": 844,
   "page": "final",
   "title": "N1 · Check-in · violet",
   "is_interactive": true
  },
  "F17WindDown.dc.html": {
   "x": 1880,
   "y": 3720,
   "w": 390,
   "h": 844,
   "page": "final",
   "title": "N2 · Wind down · violet",
   "is_interactive": true
  },
  "F18Finale.dc.html": {
   "x": 2350,
   "y": 3720,
   "w": 390,
   "h": 844,
   "page": "final",
   "title": "T1 · Week 4 · sun",
   "is_interactive": true
  },
  "FDarkA.dc.html": {
   "x": 0,
   "y": 4980,
   "w": 4150,
   "h": 844,
   "page": "final",
   "title": "Dark mode · O1–D2"
  },
  "FDarkB.dc.html": {
   "x": 0,
   "y": 6240,
   "w": 4150,
   "h": 844,
   "page": "final",
   "title": "Dark mode · D3–T1"
  },
  "Xero.dc.html": {
   "x": 2100,
   "y": 0,
   "w": 240,
   "h": 240,
   "title": "B · Xero (component)",
   "page": "final"
  },
  "Jelli.dc.html": {
   "x": 2580,
   "y": 0,
   "w": 240,
   "h": 240,
   "title": "E · Jelli (component)",
   "page": "final"
  },
  "Glim2.dc.html": {
   "x": 3060,
   "y": 0,
   "w": 240,
   "h": 240,
   "title": "Glim, night tone (component)",
   "page": "final"
  },
  "Horizon2.dc.html": {
   "x": 3540,
   "y": 0,
   "w": 400,
   "h": 300,
   "title": "Horizon, alive (component)",
   "page": "final",
   "radius": 24
  },
  "Hero2.dc.html": {
   "x": 4020,
   "y": 0,
   "w": 390,
   "h": 300,
   "title": "Hero, alive (component)",
   "page": "final"
  }
 },
 "notes": {
  "fnTitle": {
   "x": 0,
   "y": -300,
   "text": "v4 · The Crew’s content, Alive’s feel, the critique’s fixes",
   "kind": "title1",
   "maxW": 1500,
   "page": "final"
  },
  "fnA": {
   "x": 0,
   "y": 940,
   "text": "Onboarding · Xero guides, nothing is charged before Quit Day",
   "kind": "title1",
   "maxW": 3200,
   "page": "final"
  },
  "fnB": {
   "x": 0,
   "y": 2200,
   "text": "Your days · Sun 8 Nov, Day 3",
   "kind": "title1",
   "maxW": 2700,
   "page": "final"
  },
  "fnC": {
   "x": 0,
   "y": 3460,
   "text": "Waves, nights, finale",
   "kind": "title1",
   "maxW": 2700,
   "page": "final"
  },
  "fnD": {
   "x": 0,
   "y": 4720,
   "text": "Phone in dark mode · warm screens on plum",
   "kind": "title1",
   "maxW": 2700,
   "page": "final"
  },
  "fnE": {
   "x": 0,
   "y": 5980,
   "text": "Phone in dark mode · continued",
   "kind": "title1",
   "maxW": 2700,
   "page": "final"
  }
 },
 "order": [
  "FinalSheet.dc.html",
  "Nav2.dc.html",
  "F01Breathe.dc.html",
  "F02Welcome.dc.html",
  "F03Chat.dc.html",
  "F04QuitDay.dc.html",
  "F05Crew.dc.html",
  "F06Plan.dc.html",
  "F07Remind.dc.html",
  "F08Today.dc.html",
  "F09Pledge.dc.html",
  "F10Program.dc.html",
  "F11Lesson.dc.html",
  "F12Progress.dc.html",
  "F13SOS.dc.html",
  "F14Passed.dc.html",
  "F15Slip.dc.html",
  "F16CheckIn.dc.html",
  "F17WindDown.dc.html",
  "F18Finale.dc.html",
  "FDarkA.dc.html",
  "FDarkB.dc.html",
  "Xero.dc.html",
  "Jelli.dc.html",
  "Glim2.dc.html",
  "Horizon2.dc.html",
  "Hero2.dc.html"
 ]
}
```


## 18. Appendix C: full source of the v4 set

Every file below is byte-for-byte the published artboard. Save each block as `project/<filename>`, keep `support.js` as provided by the Design type, and publish with the Appendix B index.

### `FinalSheet.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Final direction rules</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&amp;family=DM+Sans:wght@400;500;600;700&amp;display=swap">
<style>
body{margin:0}
</style>
</helmet>
<div style="width: 1500px; height: 820px; box-sizing: border-box; background: #FBF7F1; color: #1E1A3A; font-family: 'DM Sans', system-ui, sans-serif; padding: 34px 40px; display: grid; grid-template-columns: 1fr 1.1fr 0.9fr 1fr; gap: 24px">
  <div style="display: flex; flex-direction: column; gap: 12px">
    <div style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 24px; letter-spacing: -0.6px">One user, one calendar</div>
    <div style="font-size: 14px; line-height: 1.5; color: #5E5975">Every screen reads from this persona, so dates and numbers agree everywhere.</div>
    <div style="display: flex; flex-direction: column; gap: 6px; font-size: 14px">
      <sc-for list="{{persona}}" as="p" hint-placeholder-count="10">
        <div style="display: grid; grid-template-columns: 112px minmax(0, 1fr); gap: 10px; padding: 7px 12px; background: #F1EBE2; border-radius: 10px"><span style="color: #5E5975">{{p.k}}</span><b>{{p.v}}</b></div>
      </sc-for>
    </div>
  </div>

  <div style="display: flex; flex-direction: column; gap: 12px">
    <div style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 24px; letter-spacing: -0.6px">Colour follows the character</div>
    <div style="font-size: 14px; line-height: 1.5; color: #5E5975">One ground per screen, plus at most one other owned colour. Reading screens stay cream. Warm screens go plum in dark mode and keep their colour in the art and the button.</div>
    <div style="display: grid; grid-template-columns: 62px 62px minmax(0, 1fr); gap: 7px 10px; align-items: center; font-size: 13.5px">
      <span style="font-size: 12px; font-weight: 800; color: #5E5975">LIGHT</span><span style="font-size: 12px; font-weight: 800; color: #5E5975">DARK</span><span></span>
      <sc-for list="{{colours}}" as="c" hint-placeholder-count="9">
        <span style="height: 32px; border-radius: 10px; {{c.l}}"></span><span style="height: 32px; border-radius: 10px; {{c.d}}"></span><span><b>{{c.name}}</b> · {{c.use}}</span>
      </sc-for>
    </div>
  </div>

  <div style="display: flex; flex-direction: column; gap: 12px">
    <div style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 24px; letter-spacing: -0.6px">Seven sizes of type</div>
    <div style="display: flex; flex-direction: column; gap: 4px">
      <div style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 40px; line-height: 1.05; letter-spacing: -1.2px">Display 40</div>
      <div style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 32px; line-height: 1.1; letter-spacing: -1px">Large 32</div>
      <div style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 24px; letter-spacing: -0.6px">Title 24</div>
      <div style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 700; font-size: 19px">Headline 19</div>
      <div style="font-size: 16px">Body 16 · DM Sans</div>
      <div style="font-size: 14px">Footnote 14</div>
      <div style="font-size: 12px; font-weight: 700; letter-spacing: 0.8px">CAPTION 12 · THE FLOOR</div>
    </div>
    <div style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 24px; letter-spacing: -0.6px; margin-top: 8px">Four character sizes</div>
    <div style="display: flex; align-items: flex-end; gap: 10px; font-size: 12px; color: #5E5975">
      <div style="display: flex; flex-direction: column; align-items: center; gap: 4px"><span style="width: 40px; height: 40px; border-radius: 99px; background: #FFC38A"></span>Avatar 40</div>
      <div style="display: flex; flex-direction: column; align-items: center; gap: 4px"><span style="width: 66px; height: 66px; border-radius: 99px; background: #FFC38A"></span>Card 88</div>
      <div style="display: flex; flex-direction: column; align-items: center; gap: 4px"><span style="width: 90px; height: 90px; border-radius: 99px; background: #FFC38A"></span>Scene 140</div>
      <div style="display: flex; flex-direction: column; align-items: center; gap: 4px"><span style="width: 112px; height: 112px; border-radius: 99px; background: #FFC38A"></span>Hero 200</div>
    </div>
    <div style="font-size: 13.5px; line-height: 1.45; color: #5E5975">Two illustrations per screen at most: a scene and one character. The finale is the one exception.</div>
  </div>

  <div style="display: flex; flex-direction: column; gap: 12px">
    <div style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 24px; letter-spacing: -0.6px">Three ways to move</div>
    <div style="display: flex; flex-direction: column; gap: 8px; font-size: 14px; line-height: 1.45">
      <div style="background: #F1EBE2; border-radius: 14px; padding: 10px 12px"><b>Arrive</b> · 600ms ease-out, 18px rise, 90ms apart. All text and cards.</div>
      <div style="background: #F1EBE2; border-radius: 14px; padding: 10px 12px"><b>Settle</b> · 900ms, no overshoot. Characters entering, and hand-overs.</div>
      <div style="background: #F1EBE2; border-radius: 14px; padding: 10px 12px"><b>Celebrate</b> · one spring. Only on Passed, milestones and the finale.</div>
      <div style="background: #F1EBE2; border-radius: 14px; padding: 10px 12px"><b>Breathe</b> · 4s in, 6s out, shared by SOS and the intro.</div>
      <div style="background: #1E1A3A; color: #FFF8EE; border-radius: 14px; padding: 10px 12px"><b>Reduce Motion</b> · every screen shows its final state. On canvas, the Motion tweak turns motion off.</div>
    </div>
    <div style="margin-top: auto; background: #FFD966; border-radius: 16px; padding: 12px 14px; font-size: 13.5px; line-height: 1.45"><b>Proposal, your call:</b> prep week is free. The 3-day trial starts on Quit Day (Fri 6 Nov), so the first charge lands on Mon 9 Nov, after three days clear. The code today starts it at sign-up.</div>
  </div>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"$preview":{"width":1500,"height":820}}'>
class Component extends DCLogic {
  renderVals() {
    const persona = [
      ['Name', 'Sam (asked in the chat)'], ['Uses', 'Cigarettes (12 a day) + a vape'], ['Triggers', 'Coffee, Stress'],
      ['Reason', 'To keep up with Maya at the park'], ['Joined', 'Fri 30 Oct · prep starts'], ['Quit Day', 'Fri 6 Nov = Day 1'],
      ['Today', 'Sun 8 Nov · Day 3'], ['Coffee wave', 'usually around 9:40'], ['Money', '$7 a day, in USD'],
      ['Sky clarity', '20 in prep, then 20 + 2.8 × days clear'], ['Week 4', '28 days · 61 waves · 26 check-ins · $196']
    ].map(([k, v]) => ({ k, v }));
    const colours = [
      ['#FF7A55', '#241433', 'Coral', 'first breath'],
      ['#FFC38A', '#241433', 'Apricot', 'Xero: days, pledge, Quit Day'],
      ['#D9CCFF', '#1C1640', 'Lilac', 'talking with Xero'],
      ['#9FE3BC', '#0F2A22', 'Mint', 'your plan, the crew'],
      ['#2A52DB', '#0B1A4A', 'Ocean', 'Jelli: cravings'],
      ['#9CCBFF', '#0F2550', 'Sky', 'relief after a wave'],
      ['#4A3596', '#140E3A', 'Violet', 'Glim: evenings, nights'],
      ['#FFD966', '#241433', 'Sun', 'celebrations only'],
      ['#FBF7F1', '#0E0B2B', 'Cream', 'reading: program, lesson, progress, slip']
    ].map(([l, d, name, use]) => ({ l: `background: ${l}; box-shadow: inset 0 0 0 1px rgba(30,26,58,0.1)`, d: `background: ${d}`, name, use }));
    return { persona, colours };
  }
}
</script>
</body>
</html>
````

### `Nav2.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Tab bar v4</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&amp;display=swap">
<style>
body{margin:0}
</style>
</helmet>
<div style="position: relative; width: 390px; height: 100px; font-family: 'DM Sans', system-ui, sans-serif">
  <nav aria-label="Main" style="position: absolute; left: 12px; right: 12px; bottom: 24px; height: 70px; border-radius: 99px; background: {{t.nav}}; box-shadow: {{t.shadow}}; display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); align-items: center; padding: 0 6px">
    <sc-for list="{{tabs}}" as="tab" hint-placeholder-count="5">
      <a href="{{tab.href}}" aria-current="{{tab.current}}" style="height: 58px; border-radius: 99px; background: {{tab.bg}}; color: {{tab.color}}; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 3px; text-decoration: none; font-size: 12px; font-weight: {{tab.weight}}">
        <svg width="22" height="22" viewBox="0 0 24 24" aria-hidden="true"><path d="{{tab.icon}}" fill="{{tab.fill}}" stroke="{{tab.stroke}}" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"></path></svg>
        {{tab.label}}
      </a>
    </sc-for>
  </nav>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"active":{"editor":"enum","options":["today","program","sos","evening","me"],"default":"today"},"theme":{"editor":"enum","options":["light","dark"],"default":"light"},"$preview":{"width":390,"height":100}}'>
class Component extends DCLogic {
  renderVals() {
    const dark = (this.props.theme ?? 'light') === 'dark';
    const active = this.props.active ?? 'today';
    const t = dark
      ? { nav: 'rgba(27,23,71,0.96)', shadow: '0 0 0 1px rgba(255,255,255,0.08), 0 12px 30px rgba(0,0,0,0.5)', on: '#2A255F', ink: '#FFF8EE', muted: '#B8B3D9', sos: '#7FB0FF' }
      : { nav: 'rgba(255,255,255,0.96)', shadow: '0 0 0 1px rgba(30,26,58,0.06), 0 12px 30px rgba(30,26,58,0.14)', on: '#F1EBE2', ink: '#1E1A3A', muted: '#5E5975', sos: '#2A52DB' };
    const defs = [
      { id: 'today', label: 'Today', href: 'F08Today.dc.html', icon: 'M3 11.5 12 4l9 7.5V20a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1z', filled: true },
      { id: 'program', label: 'Program', href: 'F10Program.dc.html', icon: 'M12 21V11 M12 13C6 13 4 9 4 5c5 0 8 3 8 8Z M12 11c0-4 3-7 8-7 0 4-3 7-8 7Z', filled: false },
      { id: 'sos', label: 'SOS', href: 'F13SOS.dc.html', icon: 'M3 12c3-4 6-4 9 0s6 4 9 0', filled: false },
      { id: 'evening', label: 'Evening', href: 'F16CheckIn.dc.html', icon: 'M15 3a8.5 8.5 0 1 0 6 13.5A7 7 0 0 1 15 3Z', filled: true },
      { id: 'me', label: 'Me', href: 'F12Progress.dc.html', icon: 'M12 3.5a4.5 4.5 0 1 1 0 9 4.5 4.5 0 0 1 0-9Z M3.5 21c1.2-4.6 4.6-7 8.5-7s7.3 2.4 8.5 7z', filled: true }
    ];
    const tabs = defs.map((d) => {
      const on = d.id === active;
      const color = d.id === 'sos' ? t.sos : (on ? t.ink : t.muted);
      return {
        href: d.href, label: d.label, icon: d.icon,
        current: on ? 'page' : 'false',
        bg: on ? t.on : 'transparent',
        color, weight: on ? 700 : 600,
        fill: d.filled ? color : 'none',
        stroke: d.filled ? 'none' : color
      };
    });
    return { t, tabs };
  }
}
</script>
</body>
</html>
````

### `F01Breathe.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Breathe</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&amp;family=DM+Sans:wght@400;500;600;700&amp;display=swap">
<style>
body{margin:0}
</style>
</helmet>
<div style="width: 390px; height: 844px; box-sizing: border-box; background: {{t.bg}}; color: {{t.ink}}; position: relative; overflow: hidden; font-family: 'DM Sans', system-ui, sans-serif">
  <svg width="390" height="844" viewBox="0 0 390 844" aria-hidden="true" style="position: absolute; left: 0; top: 0">
    <circle cx="195" cy="640" r="300" fill="{{t.ring1}}"><animate attributeName="r" values="{{ringA}}" keyTimes="0;0.4;1" calcMode="spline" keySplines="0.45 0 0.55 1;0.45 0 0.55 1" dur="10s" repeatCount="indefinite"></animate></circle>
    <circle cx="195" cy="640" r="220" fill="{{t.ring2}}"><animate attributeName="r" values="{{ringB}}" keyTimes="0;0.4;1" calcMode="spline" keySplines="0.45 0 0.55 1;0.45 0 0.55 1" dur="10s" repeatCount="indefinite"></animate></circle>
    <circle cx="195" cy="640" r="140" fill="{{t.ring3}}"><animate attributeName="r" values="{{ringC}}" keyTimes="0;0.4;1" calcMode="spline" keySplines="0.45 0 0.55 1;0.45 0 0.55 1" dur="10s" repeatCount="indefinite"></animate></circle>
  </svg>
  <a href="F02Welcome.dc.html" style="position: absolute; right: 14px; top: 50px; min-width: 44px; height: 44px; display: flex; align-items: center; justify-content: center; padding: 0 10px; color: {{t.ink}}; font-weight: 600; font-size: 16px; text-decoration: none; {{skip}}">Skip</a>

  <div style="position: absolute; left: 24px; right: 24px; top: 150px; height: 92px" aria-live="polite">
    <div style="position: absolute; inset: 0; text-align: center; font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 40px; letter-spacing: -1.2px; line-height: 1.05; {{inStyle}}">Breathe in</div>
    <div style="position: absolute; inset: 0; text-align: center; font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 40px; letter-spacing: -1.2px; line-height: 1.05; {{outStyle}}">…and out</div>
  </div>
  <p style="position: absolute; left: 40px; right: 40px; top: 222px; margin: 0; text-align: center; font-size: 16px; line-height: 1.5; color: {{t.muted}}; {{a1}}">One slow breath before we begin. In for 4, out for 6.</p>

  <div style="position: absolute; left: 95px; top: 470px; {{rise}}"><dc-import name="Xero" mood="breathe" stage="1" animate="{{motionStr}}" size="200" hint-size="200px,200px"></dc-import></div>
  <p style="position: absolute; left: 0; right: 0; bottom: 44px; margin: 0; text-align: center; font-size: 14px; color: {{t.muted}}; {{a2}}">Breathe with the circles</p>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"theme":{"editor":"enum","options":["light","dark"],"default":"light"},"motion":{"editor":"boolean","default":true},"replay":{"editor":"boolean","default":true},"$preview":{"width":390,"height":844}}'>
class Component extends DCLogic {
  componentDidMount() { this.play(); }
  componentWillUnmount() { (this.timers || []).forEach(clearTimeout); }
  play() {
    (this.timers || []).forEach(clearTimeout);
    this.timers = [];
    this.setState({ on: false, phase: 'in', skip: false });
    this.timers.push(setTimeout(() => this.setState({ on: true }), 300));
    [4000, 10000].forEach((ms, i) => this.timers.push(setTimeout(() => this.setState({ phase: i === 0 ? 'out' : 'in', skip: i === 1 }), ms)));
    this.timers.push(setTimeout(() => this.setState({ phase: 'out' }), 14000));
    if (String(this.props.replay ?? true) !== 'false') this.timers.push(setTimeout(() => this.play(), 20000));
  }
  renderVals() {
    const dark = (this.props.theme ?? 'light') === 'dark';
    const motion = String(this.props.motion ?? true) !== 'false';
    const s = this.state || {};
    const on = !motion || Boolean(s.on);
    const ease = 'cubic-bezier(.2,.7,.2,1)';
    const a = (i) => `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 18}px); transition: opacity 600ms ${ease} ${i * 90}ms, transform 600ms ${ease} ${i * 90}ms`;
    const t = dark
      ? { bg: '#241433', ink: '#FFF8EE', muted: '#E0C8E8', ring1: 'rgba(255,122,85,0.12)', ring2: 'rgba(255,122,85,0.14)', ring3: 'rgba(255,195,138,0.14)' }
      : { bg: '#FF7A55', ink: '#1E1A3A', muted: '#3B1A24', ring1: 'rgba(255,248,238,0.16)', ring2: 'rgba(255,248,238,0.2)', ring3: 'rgba(255,217,102,0.45)' };
    const phase = motion ? (s.phase || 'in') : 'in';
    const fade = (show) => `opacity: ${on && show ? 1 : 0}; transition: opacity 500ms ${ease}`;
    const m = (x, y) => motion ? x : y;
    return {
      t, motionStr: String(motion),
      inStyle: fade(phase === 'in'), outStyle: fade(phase === 'out'),
      a1: a(2), a2: a(6),
      skip: `opacity: ${!motion || s.skip ? 1 : 0}; transition: opacity 600ms ${ease}`,
      rise: `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 60}px); transition: opacity 900ms ${ease}, transform 900ms cubic-bezier(.2,.8,.2,1)`,
      ringA: m('280;330;280', '300;300;300'), ringB: m('205;250;205', '220;220;220'), ringC: m('130;165;130', '140;140;140')
    };
  }
}
</script>
</body>
</html>
````

### `F02Welcome.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Welcome</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&amp;family=DM+Sans:wght@400;500;600;700&amp;display=swap">
<style>
body{margin:0}
</style>
</helmet>
<div style="width: 390px; height: 844px; box-sizing: border-box; background: {{t.bg}}; color: {{t.ink}}; position: relative; overflow: hidden; font-family: 'DM Sans', system-ui, sans-serif; display: flex; flex-direction: column">
  <div style="position: relative; height: 420px; flex: none">
    <div style="position: absolute; left: 0; top: 0; {{a0}}"><dc-import name="Hero2" scene="dawn" clarity="20" h="420" edge="{{t.bg}}" animate="{{motionStr}}" hint-size="390px,420px"></dc-import></div>
    <div style="position: absolute; left: 95px; top: 150px; {{rise}}"><dc-import name="Xero" mood="{{mood}}" stage="1" animate="{{motionStr}}" size="200" hint-size="200px,200px"></dc-import></div>
    <div style="position: absolute; left: 230px; top: 112px; background: #FFF8EE; color: #1E1A3A; border-radius: 18px 18px 18px 4px; padding: 8px 14px; font-size: 16px; font-weight: 700; {{bubble}}">Hi! I'm Xero.</div>
  </div>

  <div style="padding: 4px 28px 0 28px; text-align: center; display: flex; flex-direction: column; gap: 12px">
    <h1 style="margin: 0; font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 32px; line-height: 1.08; letter-spacing: -1px; {{a1}}">Don't quit today.<br>Quit on your Quit Day.</h1>
    <p style="margin: 0; font-size: 16px; line-height: 1.5; color: {{t.muted}}; {{a2}}">Prep for 7 days while you still use as normal, then quit on the day you choose.</p>
  </div>

  <div style="margin-top: auto; padding: 0 22px 22px 22px; display: flex; flex-direction: column; gap: 4px; {{a3}}">
    <a href="F03Chat.dc.html" style="height: 58px; border-radius: 99px; background: {{t.btn}}; color: {{t.btnInk}}; font-weight: 700; font-size: 17px; text-decoration: none; display: flex; align-items: center; justify-content: center; box-shadow: 0 6px 0 rgba(0,0,0,0.22)">Get started</a>
    <a href="#" style="align-self: center; height: 44px; display: flex; align-items: center; padding: 0 10px; color: {{t.ink}}; font-weight: 600; font-size: 16px; text-decoration: none">I already have an account</a>
    <p style="margin: 0; font-size: 12px; line-height: 1.5; color: {{t.muted}}; text-align: center">Takes 2 minutes and stays private on this phone. By continuing you confirm you're 18+ and agree to the <a href="#" style="color: {{t.ink}}; font-weight: 700">Terms</a> and <a href="#" style="color: {{t.ink}}; font-weight: 700">Privacy Policy</a>.</p>
  </div>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"theme":{"editor":"enum","options":["light","dark"],"default":"light"},"motion":{"editor":"boolean","default":true},"replay":{"editor":"boolean","default":true},"$preview":{"width":390,"height":844}}'>
class Component extends DCLogic {
  componentDidMount() { this.play(); }
  componentWillUnmount() { (this.timers || []).forEach(clearTimeout); }
  play() {
    (this.timers || []).forEach(clearTimeout);
    this.timers = [];
    this.setState({ on: false, wave: false });
    this.timers.push(setTimeout(() => this.setState({ on: true }), 300));
    this.timers.push(setTimeout(() => this.setState({ wave: true }), 1300));
    if (String(this.props.replay ?? true) !== 'false') this.timers.push(setTimeout(() => this.play(), 10000));
  }
  renderVals() {
    const dark = (this.props.theme ?? 'light') === 'dark';
    const motion = String(this.props.motion ?? true) !== 'false';
    const s = this.state || {};
    const on = !motion || Boolean(s.on);
    const wave = !motion || Boolean(s.wave);
    const ease = 'cubic-bezier(.2,.7,.2,1)';
    const a = (i) => `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 18}px); transition: opacity 600ms ${ease} ${i * 90}ms, transform 600ms ${ease} ${i * 90}ms`;
    const t = dark
      ? { bg: '#241433', ink: '#FFF8EE', muted: '#E0C8E8', btn: '#FFC38A', btnInk: '#241433' }
      : { bg: '#FFC38A', ink: '#1E1A3A', muted: '#4A2A1A', btn: '#1E1A3A', btnInk: '#FFF8EE' };
    return {
      t, motionStr: String(motion),
      mood: motion && s.wave ? 'cheer' : 'hello',
      a0: `opacity: ${on ? 1 : 0}; transition: opacity 600ms ${ease}`,
      rise: `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 60}px); transition: opacity 900ms ${ease} 100ms, transform 900ms cubic-bezier(.2,.8,.2,1) 100ms`,
      bubble: `opacity: ${wave ? 1 : 0}; transform: translateY(${wave ? 0 : 8}px) scale(${wave ? 1 : 0.9}); transform-origin: 0 100%; transition: opacity 400ms ${ease}, transform 600ms ${ease}`,
      a1: a(6), a2: a(7), a3: a(9)
    };
  }
}
</script>
</body>
</html>
````

### `F03Chat.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Questions with Xero</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&amp;family=DM+Sans:wght@400;500;600;700&amp;display=swap">
<style>
body{margin:0}
</style>
</helmet>
<div style="width: 390px; height: 844px; box-sizing: border-box; background: {{t.bg}}; color: {{t.ink}}; position: relative; overflow: hidden; font-family: 'DM Sans', system-ui, sans-serif; display: flex; flex-direction: column">
  <div style="display: flex; align-items: center; gap: 12px; padding: 50px 10px 0 16px">
    <dc-import name="Xero" mood="{{xMood}}" stage="1" animate="{{motionStr}}" size="40" hint-size="40px,40px"></dc-import>
    <div style="flex: 1; height: 8px; border-radius: 99px; background: {{t.track}}" role="progressbar" aria-label="Setup progress" aria-valuenow="3" aria-valuemin="1" aria-valuemax="6"><div style="height: 8px; border-radius: 99px; background: {{t.bar}}; {{barW}}"></div></div>
    <button aria-label="Close" style="width: 44px; height: 44px; border: 0; border-radius: 99px; background: transparent; color: {{t.ink}}; display: flex; align-items: center; justify-content: center; cursor: pointer"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" aria-hidden="true"><path d="M6 6l12 12M18 6L6 18"></path></svg></button>
  </div>

  <div style="padding: 18px 22px 0 22px; display: flex; flex-direction: column; gap: 12px">
    <p style="margin: 0; font-size: 16px; line-height: 1.5; max-width: 300px; {{m1}}">Nice to meet you, Sam. What do you use? Pick all that apply.</p>
    <div style="align-self: flex-end; display: flex; flex-direction: column; align-items: flex-end; gap: 2px; {{r1}}">
      <span style="padding: 10px 16px; border-radius: 20px 20px 4px 20px; background: {{t.reply}}; color: {{t.replyInk}}; font-weight: 600; font-size: 16px">Cigarettes and a vape</span>
      <a href="#" style="height: 32px; display: flex; align-items: center; padding: 0 6px; font-size: 14px; font-weight: 700; color: {{t.ink}}">Edit</a>
    </div>
    <p style="margin: 0; font-size: 16px; line-height: 1.5; max-width: 310px; {{m2}}">Using both is common. I'll plan for each, so neither sneaks back in.</p>
    <div style="display: flex; gap: 5px; padding: 4px 0; height: 8px; {{dots}}" aria-hidden="true"><span style="width: 8px; height: 8px; border-radius: 99px; background: {{t.ink}}; opacity: 0.6"></span><span style="width: 8px; height: 8px; border-radius: 99px; background: {{t.ink}}; opacity: 0.4"></span><span style="width: 8px; height: 8px; border-radius: 99px; background: {{t.ink}}; opacity: 0.25"></span></div>
    <p style="margin: -20px 0 0 0; font-family: 'Bricolage Grotesque', sans-serif; font-weight: 700; font-size: 19px; line-height: 1.3; max-width: 320px; {{m3}}">When do cravings usually hit? Pick up to three.</p>
  </div>

  <div style="margin-top: auto; margin-bottom: 12px; margin-left: 12px; margin-right: 12px; background: {{t.tray}}; border-radius: 26px; padding: 16px; display: flex; flex-direction: column; gap: 10px; {{tray}}">
    <div style="font-size: 12px; font-weight: 700; letter-spacing: 0.8px; color: {{t.muted}}">YOUR ANSWER</div>
    <div style="display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 8px" role="group" aria-label="Craving triggers">
      <sc-for list="{{chips}}" as="c" hint-placeholder-count="8">
        <button aria-pressed="{{c.pressed}}" style="height: 48px; border: 0; border-radius: 14px; padding: 0 12px; font-family: 'DM Sans', sans-serif; font-weight: 600; font-size: 16px; display: flex; align-items: center; justify-content: space-between; gap: 6px; cursor: pointer; text-align: left; {{c.style}}">{{c.label}}<span style="width: 22px; height: 22px; border-radius: 99px; display: flex; align-items: center; justify-content: center; flex: none; {{c.tick}}"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#0E0B2B" stroke-width="4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12l5 5 9-10"></path></svg></span></button>
      </sc-for>
    </div>
    <a href="F04QuitDay.dc.html" style="height: 56px; border-radius: 99px; background: {{t.btn}}; color: {{t.btnInk}}; font-weight: 700; font-size: 17px; text-decoration: none; display: flex; align-items: center; justify-content: center; gap: 8px">Next <span style="font-weight: 600; opacity: 0.8">· {{picked}} of 3</span></a>
  </div>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"theme":{"editor":"enum","options":["light","dark"],"default":"light"},"motion":{"editor":"boolean","default":true},"replay":{"editor":"boolean","default":true},"$preview":{"width":390,"height":844}}'>
class Component extends DCLogic {
  componentDidMount() { this.play(); }
  componentWillUnmount() { (this.timers || []).forEach(clearTimeout); }
  play() {
    (this.timers || []).forEach(clearTimeout);
    this.timers = [];
    this.setState({ step: 0 });
    [300, 1000, 1700, 2300, 3200, 3700, 4900, 5600].forEach((ms, i) => this.timers.push(setTimeout(() => this.setState({ step: i + 1 }), ms)));
    if (String(this.props.replay ?? true) !== 'false') this.timers.push(setTimeout(() => this.play(), 12000));
  }
  renderVals() {
    const dark = (this.props.theme ?? 'light') === 'dark';
    const motion = String(this.props.motion ?? true) !== 'false';
    const step = motion ? ((this.state && this.state.step) || 0) : 99;
    const ease = 'cubic-bezier(.2,.7,.2,1)';
    const v = (k) => `opacity: ${step >= k ? 1 : 0}; transform: translateY(${step >= k ? 0 : 12}px); transition: opacity 450ms ${ease}, transform 600ms ${ease}`;
    const t = dark
      ? { bg: '#1C1640', ink: '#FFF8EE', muted: '#C9BFF2', track: 'rgba(255,255,255,0.12)', bar: '#2FD08A', reply: '#FFF8EE', replyInk: '#1C1640', tray: '#2A255F', chip: 'rgba(255,255,255,0.08)', sel: '#FFF8EE', selInk: '#1C1640', btn: '#FFF8EE', btnInk: '#1C1640' }
      : { bg: '#D9CCFF', ink: '#1E1A3A', muted: '#4A3E7A', track: 'rgba(30,26,58,0.12)', bar: '#0F6E43', reply: '#1E1A3A', replyInk: '#FFF8EE', tray: '#FFFFFF', chip: '#F1EBE2', sel: '#1E1A3A', selInk: '#FFF8EE', btn: '#1E1A3A', btnInk: '#FFF8EE' };
    const labels = ['Waking up', 'Coffee', 'After meals', 'Stress', 'Drinking', 'Boredom', 'With friends', 'More…'];
    const chips = labels.map((label, i) => {
      const picked = (i === 1 && step >= 7) || (i === 3 && step >= 8);
      return {
        label, pressed: picked ? 'true' : 'false',
        style: `background: ${picked ? t.sel : t.chip}; color: ${picked ? t.selInk : t.ink}; transition: background 250ms, color 250ms`,
        tick: `background: #2FD08A; opacity: ${picked ? 1 : 0}; transform: scale(${picked ? 1 : 0.4}); transition: opacity 250ms, transform 300ms ${ease}`
      };
    });
    const picked = (step >= 7 ? 1 : 0) + (step >= 8 ? 1 : 0);
    return {
      t, chips, picked: String(picked), motionStr: String(motion),
      xMood: step >= 4 && step < 5 ? 'cheer' : 'hello',
      barW: `width: ${step >= 8 ? 50 : 34}%; transition: width 800ms ${ease}`,
      m1: v(1), r1: v(2), m2: v(4), m3: v(5),
      dots: `opacity: ${step === 3 || step === 4 ? 1 : 0}; transition: opacity 250ms`,
      tray: `opacity: ${step >= 6 ? 1 : 0}; transform: translateY(${step >= 6 ? 0 : 40}px); transition: opacity 500ms ${ease}, transform 600ms ${ease}`
    };
  }
}
</script>
</body>
</html>
````

### `F04QuitDay.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Pick your Quit Day</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&amp;family=DM+Sans:wght@400;500;600;700&amp;display=swap">
<style>
body{margin:0}
</style>
</helmet>
<div style="width: 390px; height: 844px; box-sizing: border-box; background: {{t.bg}}; color: {{t.ink}}; position: relative; overflow: hidden; font-family: 'DM Sans', system-ui, sans-serif; display: flex; flex-direction: column">
  <div style="position: relative; height: 270px; flex: none">
    <div style="position: absolute; left: 0; top: 0; {{a0}}"><dc-import name="Hero2" scene="dawn" clarity="20" h="270" edge="{{t.bg}}" animate="{{motionStr}}" hint-size="390px,270px"></dc-import></div>
    <div style="position: absolute; left: 125px; top: 96px; {{rise}}"><dc-import name="Xero" mood="hello" stage="1" animate="{{motionStr}}" size="140" hint-size="140px,140px"></dc-import></div>
    <a href="F03Chat.dc.html" aria-label="Back" style="position: absolute; left: 10px; top: 46px; width: 44px; height: 44px; border-radius: 99px; background: rgba(255,248,238,0.85); color: #1E1A3A; display: flex; align-items: center; justify-content: center"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 5l-7 7 7 7"></path></svg></a>
  </div>

  <div style="padding: 8px 24px 0 24px; display: flex; flex-direction: column; gap: 10px">
    <h1 style="margin: 0; font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 32px; line-height: 1.08; letter-spacing: -1px; {{a1}}">Pick your Quit Day</h1>
    <p style="margin: 0; font-size: 16px; line-height: 1.5; color: {{t.muted}}; {{a2}}">I recommend <b style="color: {{t.ink}}">Fri 6 Nov</b>. It gives you the full 7-day prep window. Keep using as normal until then.</p>
  </div>

  <div style="padding: 18px 16px 0 16px; {{a3}}">
    <div style="display: grid; grid-template-columns: repeat(8, minmax(0, 1fr)); gap: 5px" role="list" aria-label="Prep week and Quit Day">
      <sc-for list="{{days}}" as="d" hint-placeholder-count="8">
        <div role="listitem" aria-label="{{d.aria}}" style="height: 72px; border-radius: 14px; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 2px; {{d.style}}"><span style="font-size: 12px; font-weight: 700">{{d.dow}}</span><span style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 19px">{{d.n}}</span></div>
      </sc-for>
    </div>
    <div style="display: flex; justify-content: space-between; padding: 8px 2px 0 2px; font-size: 12px; font-weight: 700; color: {{t.muted}}"><span>Prep week · 7 days</span><span style="color: {{t.ink}}">Quit Day</span></div>
  </div>

  <div style="margin-top: auto; padding: 0 22px 22px 22px; display: flex; flex-direction: column; gap: 6px; {{a4}}">
    <a href="#" style="align-self: center; height: 44px; display: flex; align-items: center; padding: 0 10px; color: {{t.ink}}; font-weight: 600; font-size: 16px">Pick another date</a>
    <a href="F05Crew.dc.html" aria-label="Set Quit Day to Friday 6 November. Hold for one and a half seconds, or double-tap with VoiceOver." style="position: relative; overflow: hidden; height: 58px; border-radius: 99px; background: {{t.btn}}; color: {{t.btnInk}}; font-weight: 700; font-size: 17px; text-decoration: none; display: flex; align-items: center; justify-content: center; gap: 8px; box-shadow: 0 6px 0 rgba(0,0,0,0.22)">
      <span style="position: absolute; left: 0; top: 0; bottom: 0; background: {{t.fill}}; {{fill}}"></span>
      <span style="position: relative">{{btnLabel}}</span>
    </a>
    <p style="margin: 0; text-align: center; font-size: 14px; color: {{t.muted}}">Hold for 1.5 seconds. You can change the date later.</p>
  </div>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"theme":{"editor":"enum","options":["light","dark"],"default":"light"},"motion":{"editor":"boolean","default":true},"replay":{"editor":"boolean","default":true},"$preview":{"width":390,"height":844}}'>
class Component extends DCLogic {
  componentDidMount() { this.play(); }
  componentWillUnmount() { (this.timers || []).forEach(clearTimeout); }
  play() {
    (this.timers || []).forEach(clearTimeout);
    this.timers = [];
    this.setState({ on: false, hold: 0 });
    this.timers.push(setTimeout(() => this.setState({ on: true }), 300));
    this.timers.push(setTimeout(() => this.setState({ hold: 1 }), 2600));
    this.timers.push(setTimeout(() => this.setState({ hold: 2 }), 4100));
    if (String(this.props.replay ?? true) !== 'false') this.timers.push(setTimeout(() => this.play(), 10000));
  }
  renderVals() {
    const dark = (this.props.theme ?? 'light') === 'dark';
    const motion = String(this.props.motion ?? true) !== 'false';
    const s = this.state || {};
    const on = !motion || Boolean(s.on);
    const hold = motion ? (s.hold || 0) : 0;
    const ease = 'cubic-bezier(.2,.7,.2,1)';
    const a = (i) => `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 18}px); transition: opacity 600ms ${ease} ${i * 90}ms, transform 600ms ${ease} ${i * 90}ms`;
    const t = dark
      ? { bg: '#241433', ink: '#FFF8EE', muted: '#E0C8E8', prep: 'rgba(255,195,138,0.16)', quit: '#FFC38A', quitInk: '#241433', btn: '#FFC38A', btnInk: '#241433', fill: '#FFD9B0' }
      : { bg: '#FFC38A', ink: '#1E1A3A', muted: '#4A2A1A', prep: 'rgba(255,248,238,0.6)', quit: '#1E1A3A', quitInk: '#FFF8EE', btn: '#1E1A3A', btnInk: '#FFF8EE', fill: '#3A3460' };
    const raw = [['Fri', 30, 'Friday 30 October'], ['Sat', 31, 'Saturday 31 October'], ['Sun', 1, 'Sunday 1 November'], ['Mon', 2, 'Monday 2 November'], ['Tue', 3, 'Tuesday 3 November'], ['Wed', 4, 'Wednesday 4 November'], ['Thu', 5, 'Thursday 5 November'], ['Fri', 6, 'Friday 6 November, Quit Day']];
    const days = raw.map(([dow, n, aria], i) => {
      const q = i === 7;
      return { dow, n: String(n), aria: q ? aria : `${aria}, prep day ${i + 1}`, style: q ? `background: ${t.quit}; color: ${t.quitInk}` : `background: ${t.prep}; color: ${t.ink}` };
    });
    return {
      t, days, motionStr: String(motion),
      a0: `opacity: ${on ? 1 : 0}; transition: opacity 600ms ${ease}`,
      rise: `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 40}px); transition: opacity 900ms ${ease}, transform 900ms cubic-bezier(.2,.8,.2,1)`,
      a1: a(4), a2: a(5), a3: a(6), a4: a(8),
      fill: `width: ${hold >= 1 ? 100 : 0}%; transition: width ${hold >= 1 ? 1500 : 200}ms linear`,
      btnLabel: hold >= 2 ? 'Quit Day set · Fri 6 Nov ✓' : 'Hold to set Fri 6 Nov'
    };
  }
}
</script>
</body>
</html>
````

### `F05Crew.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Your plan builds</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&amp;family=DM+Sans:wght@400;500;600;700&amp;display=swap">
<style>
body{margin:0}
</style>
</helmet>
<div style="width: 390px; height: 844px; box-sizing: border-box; background: {{t.bg}}; color: {{t.ink}}; position: relative; overflow: hidden; font-family: 'DM Sans', system-ui, sans-serif; display: flex; flex-direction: column">
  <div style="display: flex; align-items: center; gap: 12px; padding: 50px 10px 0 16px">
    <div style="flex: 1; height: 8px; border-radius: 99px; background: {{t.track}}" role="progressbar" aria-label="Setup progress" aria-valuenow="5" aria-valuemin="1" aria-valuemax="6"><div style="height: 8px; width: 80%; border-radius: 99px; background: {{t.bar}}"></div></div>
    <button aria-label="Close" style="width: 44px; height: 44px; border: 0; border-radius: 99px; background: transparent; color: {{t.ink}}; display: flex; align-items: center; justify-content: center; cursor: pointer"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" aria-hidden="true"><path d="M6 6l12 12M18 6L6 18"></path></svg></button>
  </div>

  <div style="display: flex; align-items: flex-end; gap: 6px; padding: 8px 24px 0 18px">
    <div style="flex: none; {{rise}}"><dc-import name="Xero" mood="{{mood}}" stage="1" animate="{{motionStr}}" size="140" hint-size="140px,140px"></dc-import></div>
    <h1 style="margin: 0 0 18px 0; font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 32px; line-height: 1.06; letter-spacing: -1px; {{a1}}">Your plan, built around you</h1>
  </div>

  <div style="padding: 8px 18px 0 18px; display: flex; flex-direction: column; gap: 8px" role="list" aria-label="Plan">
    <sc-for list="{{rows}}" as="r" hint-placeholder-count="4">
      <div role="listitem" style="min-height: 64px; box-sizing: border-box; border-radius: 18px; background: {{t.card}}; padding: 10px 14px; display: flex; align-items: center; gap: 12px; {{r.style}}">
        <span style="width: 28px; height: 28px; border-radius: 99px; flex: none; display: flex; align-items: center; justify-content: center; {{r.tickStyle}}"><svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#FFF8EE" stroke-width="3.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12l5 5 9-10"></path></svg></span>
        <span style="display: flex; flex-direction: column; gap: 2px"><span style="font-size: 12px; font-weight: 700; letter-spacing: 0.8px; color: {{t.muted}}">{{r.k}}</span><span style="font-size: 16px; font-weight: 600; line-height: 1.35">{{r.v}}</span></span>
      </div>
    </sc-for>
  </div>

  <div style="margin: 12px 18px 0 18px; border-radius: 18px; padding: 12px 14px; background: {{t.card}}; display: flex; align-items: center; gap: 10px; {{later}}">
    <span style="display: flex; flex: none">
      <span style="width: 40px; height: 40px; border-radius: 99px; background: {{t.jelliBg}}; overflow: hidden; display: flex; align-items: center; justify-content: center"><dc-import name="Jelli" mood="calm" stage="1" animate="false" size="40" hint-size="40px,40px"></dc-import></span>
      <span style="width: 40px; height: 40px; margin-left: -8px; border-radius: 99px; background: {{t.glimBg}}; overflow: hidden; display: flex; align-items: center; justify-content: center; box-shadow: 0 0 0 3px {{t.cardSolid}}"><dc-import name="Glim2" mood="sleepy" stage="1" animate="false" size="40" hint-size="40px,40px"></dc-import></span>
    </span>
    <span style="font-size: 14px; line-height: 1.45">Two friends join later. <b>Jelli</b> at your first craving, <b>Glim</b> on your first evening.</span>
  </div>

  <div style="margin-top: auto; padding: 0 22px 22px 22px; {{a5}}">
    <a href="F06Plan.dc.html" style="height: 58px; border-radius: 99px; background: {{t.btn}}; color: {{t.btnInk}}; font-weight: 700; font-size: 17px; text-decoration: none; display: flex; align-items: center; justify-content: center; box-shadow: 0 6px 0 rgba(0,0,0,0.2); {{btnOn}}">See my plan</a>
  </div>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"theme":{"editor":"enum","options":["light","dark"],"default":"light"},"motion":{"editor":"boolean","default":true},"replay":{"editor":"boolean","default":true},"$preview":{"width":390,"height":844}}'>
class Component extends DCLogic {
  componentDidMount() { this.play(); }
  componentWillUnmount() { (this.timers || []).forEach(clearTimeout); }
  play() {
    (this.timers || []).forEach(clearTimeout);
    this.timers = [];
    this.setState({ on: false, step: 0 });
    this.timers.push(setTimeout(() => this.setState({ on: true }), 300));
    [1200, 1900, 2600, 3300, 4200].forEach((ms, i) => this.timers.push(setTimeout(() => this.setState({ step: i + 1 }), ms)));
    if (String(this.props.replay ?? true) !== 'false') this.timers.push(setTimeout(() => this.play(), 10000));
  }
  renderVals() {
    const dark = (this.props.theme ?? 'light') === 'dark';
    const motion = String(this.props.motion ?? true) !== 'false';
    const s = this.state || {};
    const on = !motion || Boolean(s.on);
    const step = motion ? (s.step || 0) : 9;
    const ease = 'cubic-bezier(.2,.7,.2,1)';
    const a = (i) => `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 18}px); transition: opacity 600ms ${ease} ${i * 90}ms, transform 600ms ${ease} ${i * 90}ms`;
    const t = dark
      ? { bg: '#0F2A22', ink: '#FFF8EE', muted: '#A9D9C0', track: 'rgba(255,255,255,0.12)', bar: '#2FD08A', card: 'rgba(255,255,255,0.07)', cardSolid: '#1C362E', tick: '#2FD08A', tickOff: 'rgba(255,255,255,0.12)', jelliBg: '#0B1A4A', glimBg: '#140E3A', btn: '#FFF8EE', btnInk: '#0F2A22' }
      : { bg: '#9FE3BC', ink: '#1E1A3A', muted: '#24493A', track: 'rgba(30,26,58,0.12)', bar: '#0F6E43', card: 'rgba(255,248,238,0.72)', cardSolid: '#EEF6EE', tick: '#0F6E43', tickOff: 'rgba(30,26,58,0.14)', jelliBg: '#2A52DB', glimBg: '#4A3596', btn: '#1E1A3A', btnInk: '#FFF8EE' };
    const settle = 'cubic-bezier(.2,.8,.2,1)';
    const data = [
      ['PREP WEEK', 'Fri 30 Oct to Thu 5 Nov. Use as normal.'],
      ['QUIT DAY', 'Fri 6 Nov, cigarettes and the vape together'],
      ['WAVES TO WATCH', 'Coffee, usually mornings, and stress'],
      ['WHY', 'To keep up with Maya at the park']
    ];
    const rows = data.map(([k, v], i) => {
      const shown = step >= i + 1;
      return {
        k, v,
        style: `opacity: ${shown ? 1 : 0}; transform: translateY(${shown ? 0 : 24}px); transition: opacity 600ms ${ease}, transform 900ms ${settle}`,
        tickStyle: `background: ${shown ? t.tick : t.tickOff}; transition: background 300ms 300ms`
      };
    });
    return {
      t, rows, motionStr: String(motion),
      mood: step >= 4 ? 'cheer' : 'hello',
      rise: `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 40}px); transition: opacity 900ms ${ease}, transform 900ms ${settle}`,
      a1: a(2), a5: a(4),
      later: `opacity: ${step >= 5 ? 1 : 0}; transform: translateY(${step >= 5 ? 0 : 18}px); transition: opacity 600ms ${ease}, transform 600ms ${ease}`,
      btnOn: `opacity: ${step >= 5 ? 1 : 0.45}; transition: opacity 400ms`
    };
  }
}
</script>
</body>
</html>
````

### `F06Plan.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Your plan and trial</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&amp;family=DM+Sans:wght@400;500;600;700&amp;display=swap">
<style>
body{margin:0}
</style>
</helmet>
<div style="width: 390px; height: 844px; box-sizing: border-box; background: {{t.bg}}; color: {{t.ink}}; position: relative; overflow: hidden; font-family: 'DM Sans', system-ui, sans-serif; display: flex; flex-direction: column">
  <div style="padding: 58px 24px 0 24px; display: flex; align-items: center; gap: 12px; {{a0}}">
    <span style="width: 40px; height: 40px; border-radius: 99px; background: {{t.avatar}}; overflow: hidden; display: flex; align-items: center; justify-content: center; flex: none"><dc-import name="Xero" mood="calm" stage="1" animate="{{motionStr}}" size="40" hint-size="40px,40px"></dc-import></span>
    <span style="font-size: 14px; font-weight: 700; color: {{t.muted}}">Step 6 of 6</span>
  </div>
  <div style="padding: 14px 24px 0 24px; display: flex; flex-direction: column; gap: 8px">
    <h1 style="margin: 0; font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 32px; line-height: 1.08; letter-spacing: -1px; {{a1}}">Your plan is ready</h1>
    <p style="margin: 0; font-size: 16px; line-height: 1.5; color: {{t.muted}}; {{a2}}">Prep week is on us. Nothing is charged today.</p>
  </div>

  <div style="margin: 18px 18px 0 18px; background: {{t.card}}; border-radius: 22px; padding: 16px; display: flex; flex-direction: column; gap: 12px; {{a3}}">
    <div style="display: flex; gap: 10px; align-items: flex-start; font-size: 16px; line-height: 1.4"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="{{t.green}}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" style="flex: none; margin-top: 1px"><path d="M5 12l5 5 9-10"></path></svg><span><b>Free now:</b> prep week, your counter, Craving SOS and Day 1</span></div>
    <div style="display: flex; gap: 10px; align-items: flex-start; font-size: 16px; line-height: 1.4"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="{{t.green}}" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" style="flex: none; margin-top: 1px"><path d="M5 12l5 5 9-10"></path></svg><span><b>With the full program:</b> four weeks of lessons, evening check-ins, an NRT plan, insights</span></div>
  </div>

  <div style="margin: 10px 18px 0 18px; background: {{t.trial}}; color: {{t.trialInk}}; border-radius: 22px; padding: 16px; display: flex; flex-direction: column; gap: 6px; {{a4}}">
    <div style="font-size: 12px; font-weight: 700; letter-spacing: 0.8px; opacity: 0.85">ON YOUR QUIT DAY · FRI 6 NOV</div>
    <div style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 24px; line-height: 1.15">3 days free, then $39.99 a year</div>
    <div style="font-size: 14px; line-height: 1.45; opacity: 0.9">That's $3.33 a month. We'll ask you on Quit Day, not before.</div>
  </div>

  <div style="margin-top: auto; padding: 0 22px 18px 22px; display: flex; flex-direction: column; gap: 4px; {{a5}}">
    <a href="F07Remind.dc.html" style="height: 58px; border-radius: 99px; background: {{t.btn}}; color: {{t.btnInk}}; font-weight: 700; font-size: 17px; text-decoration: none; display: flex; align-items: center; justify-content: center; box-shadow: 0 6px 0 rgba(0,0,0,0.2)">Start my prep week</a>
    <a href="#" style="align-self: center; height: 44px; display: flex; align-items: center; padding: 0 10px; color: {{t.ink}}; font-weight: 600; font-size: 14px">See all plans · $9.99 a month · $79.99 lifetime</a>
    <p style="margin: 0; font-size: 12px; line-height: 1.5; color: {{t.muted}}; text-align: center">If you start the trial on Fri 6 Nov it runs to Mon 9 Nov, and we'll remind you on Sat 7 Nov. Cancel any time in Settings › Apple ID › Subscriptions. <a href="#" style="color: {{t.ink}}; font-weight: 700">Restore purchases</a></p>
  </div>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"theme":{"editor":"enum","options":["light","dark"],"default":"light"},"motion":{"editor":"boolean","default":true},"replay":{"editor":"boolean","default":true},"$preview":{"width":390,"height":844}}'>
class Component extends DCLogic {
  componentDidMount() { this.play(); }
  componentWillUnmount() { (this.timers || []).forEach(clearTimeout); }
  play() {
    (this.timers || []).forEach(clearTimeout);
    this.timers = [];
    this.setState({ on: false });
    this.timers.push(setTimeout(() => this.setState({ on: true }), 300));
    if (String(this.props.replay ?? true) !== 'false') this.timers.push(setTimeout(() => this.play(), 10000));
  }
  renderVals() {
    const dark = (this.props.theme ?? 'light') === 'dark';
    const motion = String(this.props.motion ?? true) !== 'false';
    const on = !motion || Boolean(this.state && this.state.on);
    const ease = 'cubic-bezier(.2,.7,.2,1)';
    const a = (i) => `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 18}px); transition: opacity 600ms ${ease} ${i * 90}ms, transform 600ms ${ease} ${i * 90}ms`;
    const t = dark
      ? { bg: '#0F2A22', ink: '#FFF8EE', muted: '#A9D9C0', card: 'rgba(255,255,255,0.07)', green: '#2FD08A', avatar: '#241433', trial: '#FFF8EE', trialInk: '#0F2A22', btn: '#FFF8EE', btnInk: '#0F2A22' }
      : { bg: '#9FE3BC', ink: '#1E1A3A', muted: '#24493A', card: 'rgba(255,248,238,0.72)', green: '#0F6E43', avatar: '#FFC38A', trial: '#1E1A3A', trialInk: '#FFF8EE', btn: '#1E1A3A', btnInk: '#FFF8EE' };
    return { t, motionStr: String(motion), a0: a(0), a1: a(1), a2: a(2), a3: a(3), a4: a(4), a5: a(6) };
  }
}
</script>
</body>
</html>
````

### `F07Remind.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Reminders</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&amp;family=DM+Sans:wght@400;500;600;700&amp;display=swap">
<style>
body{margin:0}
</style>
</helmet>
<div style="width: 390px; height: 844px; box-sizing: border-box; background: {{t.bg}}; color: {{t.ink}}; position: relative; overflow: hidden; font-family: 'DM Sans', system-ui, sans-serif; display: flex; flex-direction: column">
  <div style="padding: 70px 24px 0 24px; display: flex; flex-direction: column; gap: 10px">
    <h1 style="margin: 0; font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 32px; line-height: 1.08; letter-spacing: -1px; {{a1}}">Two small nudges a day</h1>
    <p style="margin: 0; font-size: 16px; line-height: 1.5; color: {{t.muted}}; {{a2}}">Xero says good morning, Glim checks in at night. That's it. No guilt, ever, and quiet hours by default.</p>
  </div>

  <div style="padding: 28px 16px 0 16px; display: flex; flex-direction: column; gap: 12px">
    <div style="background: {{t.note}}; border-radius: 22px; padding: 14px; display: flex; gap: 12px; align-items: center; box-shadow: 0 10px 24px rgba(30,26,58,0.12); {{n1}}">
      <span style="width: 40px; height: 40px; border-radius: 12px; background: #FFC38A; overflow: hidden; display: flex; align-items: center; justify-content: center; flex: none"><dc-import name="Xero" mood="hello" stage="1" animate="false" size="40" hint-size="40px,40px"></dc-import></span>
      <span style="flex: 1; display: flex; flex-direction: column; gap: 2px"><span style="display: flex; justify-content: space-between; font-size: 14px"><b>DayXero · Xero</b><span style="color: {{t.noteMuted}}">8:00</span></span><span style="font-size: 16px; line-height: 1.35">Good morning. Ten seconds for today's pledge?</span></span>
    </div>
    <div style="background: {{t.note}}; border-radius: 22px; padding: 14px; display: flex; gap: 12px; align-items: center; box-shadow: 0 10px 24px rgba(30,26,58,0.12); {{n2}}">
      <span style="width: 40px; height: 40px; border-radius: 12px; background: #4A3596; overflow: hidden; display: flex; align-items: center; justify-content: center; flex: none"><dc-import name="Glim2" mood="hello" stage="1" animate="false" size="40" hint-size="40px,40px"></dc-import></span>
      <span style="flex: 1; display: flex; flex-direction: column; gap: 2px"><span style="display: flex; justify-content: space-between; font-size: 14px"><b>DayXero · Glim</b><span style="color: {{t.noteMuted}}">21:30</span></span><span style="font-size: 16px; line-height: 1.35">How did today go? One minute, if you have it.</span></span>
    </div>
    <a href="#" style="align-self: flex-start; height: 44px; display: flex; align-items: center; padding: 0 8px; color: {{t.ink}}; font-weight: 600; font-size: 14px; {{a5}}">Change the times</a>
  </div>

  <div style="margin-top: auto; padding: 0 22px 22px 22px; display: flex; flex-direction: column; gap: 4px; {{a6}}">
    <a href="F08Today.dc.html" style="height: 58px; border-radius: 99px; background: {{t.btn}}; color: {{t.btnInk}}; font-weight: 700; font-size: 17px; text-decoration: none; display: flex; align-items: center; justify-content: center; box-shadow: 0 6px 0 rgba(0,0,0,0.22)">Yes, remind me</a>
    <a href="F08Today.dc.html" style="align-self: center; height: 44px; display: flex; align-items: center; padding: 0 10px; color: {{t.ink}}; font-weight: 600; font-size: 16px; text-decoration: none">Not right now</a>
  </div>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"theme":{"editor":"enum","options":["light","dark"],"default":"light"},"motion":{"editor":"boolean","default":true},"replay":{"editor":"boolean","default":true},"$preview":{"width":390,"height":844}}'>
class Component extends DCLogic {
  componentDidMount() { this.play(); }
  componentWillUnmount() { (this.timers || []).forEach(clearTimeout); }
  play() {
    (this.timers || []).forEach(clearTimeout);
    this.timers = [];
    this.setState({ on: false, n: 0 });
    this.timers.push(setTimeout(() => this.setState({ on: true }), 300));
    this.timers.push(setTimeout(() => this.setState({ n: 1 }), 1000));
    this.timers.push(setTimeout(() => this.setState({ n: 2 }), 1800));
    if (String(this.props.replay ?? true) !== 'false') this.timers.push(setTimeout(() => this.play(), 10000));
  }
  renderVals() {
    const dark = (this.props.theme ?? 'light') === 'dark';
    const motion = String(this.props.motion ?? true) !== 'false';
    const s = this.state || {};
    const on = !motion || Boolean(s.on);
    const n = motion ? (s.n || 0) : 2;
    const ease = 'cubic-bezier(.2,.7,.2,1)';
    const a = (i) => `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 18}px); transition: opacity 600ms ${ease} ${i * 90}ms, transform 600ms ${ease} ${i * 90}ms`;
    const drop = (k) => `opacity: ${n >= k ? 1 : 0}; transform: translateY(${n >= k ? 0 : -24}px); transition: opacity 500ms ${ease}, transform 900ms cubic-bezier(.2,.8,.2,1)`;
    const t = dark
      ? { bg: '#241433', ink: '#FFF8EE', muted: '#E0C8E8', note: '#33204A', noteMuted: '#E0C8E8', btn: '#FFC38A', btnInk: '#241433' }
      : { bg: '#FFC38A', ink: '#1E1A3A', muted: '#4A2A1A', note: '#FFF8EE', noteMuted: '#5E5975', btn: '#1E1A3A', btnInk: '#FFF8EE' };
    return { t, a1: a(1), a2: a(2), a5: a(6), a6: a(7), n1: drop(1), n2: drop(2) };
  }
}
</script>
</body>
</html>
````

### `F08Today.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Today</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&amp;family=DM+Sans:wght@400;500;600;700&amp;display=swap">
<style>
body{margin:0}
</style>
</helmet>
<div style="width: 390px; height: 844px; box-sizing: border-box; background: {{t.bg}}; color: {{t.ink}}; position: relative; overflow: hidden; font-family: 'DM Sans', system-ui, sans-serif">
  <div style="position: absolute; left: 0; top: 0; {{a0}}"><dc-import name="Hero2" scene="{{scene}}" clarity="{{clarity}}" h="250" edge="{{t.bg}}" animate="{{motionStr}}" hint-size="390px,250px"></dc-import></div>
  <div style="position: absolute; left: 125px; top: 70px; {{showX}}"><dc-import name="Xero" mood="{{mood}}" stage="{{stage}}" animate="{{motionStr}}" size="140" hint-size="140px,140px"></dc-import></div>
  <div style="position: absolute; left: 125px; top: 70px; {{showG}}"><dc-import name="Glim2" mood="{{mood}}" stage="{{stage}}" animate="{{motionStr}}" size="140" hint-size="140px,140px"></dc-import></div>

  <div style="position: absolute; left: 0; right: 0; top: 238px; padding: 0 20px; display: flex; flex-direction: column; gap: 12px">
    <div style="{{a1}}">
      <div style="font-size: 14px; font-weight: 700; color: {{t.muted}}">{{dateLine}}</div>
      <h1 style="margin: 2px 0 0 0; font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 32px; line-height: 1.06; letter-spacing: -1px">{{greeting}}</h1>
    </div>

    <a href="{{top.href}}" style="text-decoration: none; color: #FFF8EE; background: {{top.bg}}; border-radius: 24px; padding: 16px; display: flex; gap: 12px; align-items: center; box-shadow: 0 5px 0 rgba(0,0,0,0.14); {{a2}}">
      <span style="flex: 1; display: flex; flex-direction: column; gap: 4px">
        <span style="font-size: 12px; font-weight: 700; letter-spacing: 0.8px">{{top.kicker}}</span>
        <span style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 700; font-size: 19px; line-height: 1.2">{{top.title}}</span>
        <span style="font-size: 14px; line-height: 1.45">{{top.body}}</span>
      </span>
      <span style="width: 44px; height: 44px; border-radius: 99px; background: rgba(255,248,238,0.2); display: flex; align-items: center; justify-content: center; flex: none"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M9 5l7 7-7 7"></path></svg></span>
    </a>

    <div style="display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 8px; {{a3}}">
      <div style="background: {{t.card}}; border-radius: 18px; padding: 12px"><div style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 24px">{{nDays}}</div><div style="font-size: 12px; font-weight: 600; color: {{t.muted}}">days clear</div></div>
      <div style="background: {{t.card}}; border-radius: 18px; padding: 12px"><div style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 24px">{{nCigs}}</div><div style="font-size: 12px; font-weight: 600; color: {{t.muted}}">cigarettes not smoked</div></div>
      <div style="background: {{t.card}}; border-radius: 18px; padding: 12px"><div style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 24px">${{nMoney}}</div><div style="font-size: 12px; font-weight: 600; color: {{t.muted}}">kept</div></div>
    </div>

    <div style="background: {{t.card}}; border-radius: 18px; padding: 4px 14px; display: flex; flex-direction: column; {{a4}}">
      <sc-for list="{{rows}}" as="r" hint-placeholder-count="3">
        <a href="{{r.href}}" style="min-height: 48px; display: flex; align-items: center; gap: 10px; text-decoration: none; color: {{t.ink}}; font-size: 16px; {{r.line}}">
          <span style="width: 22px; height: 22px; border-radius: 99px; flex: none; display: flex; align-items: center; justify-content: center; {{r.dot}}"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="#FFF8EE" stroke-width="4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12l5 5 9-10"></path></svg></span>
          <span style="flex: 1">{{r.label}}</span><span style="font-size: 14px; color: {{t.muted}}">{{r.meta}}</span>
        </a>
      </sc-for>
    </div>
  </div>

  <div style="position: absolute; left: 0; bottom: 0; {{a5}}"><dc-import name="Nav2" active="today" theme="{{navTheme}}" hint-size="390px,100px"></dc-import></div>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"theme":{"editor":"enum","options":["light","dark"],"default":"light"},"time":{"editor":"enum","options":["morning","afternoon","evening","night"],"default":"morning"},"day":{"editor":"int","min":1,"max":28,"default":3},"motion":{"editor":"boolean","default":true},"replay":{"editor":"boolean","default":true},"$preview":{"width":390,"height":844}}'>
class Component extends DCLogic {
  componentDidMount() { this.play(); }
  componentWillUnmount() { (this.timers || []).forEach(clearTimeout); clearInterval(this.iv); }
  play() {
    (this.timers || []).forEach(clearTimeout); clearInterval(this.iv);
    this.timers = [];
    this.setState({ on: false, k: 0 });
    this.timers.push(setTimeout(() => this.setState({ on: true }), 300));
    this.timers.push(setTimeout(() => {
      const t0 = Date.now();
      this.iv = setInterval(() => {
        const p = Math.min(1, (Date.now() - t0) / 800);
        this.setState({ k: 1 - Math.pow(1 - p, 3) });
        if (p >= 1) clearInterval(this.iv);
      }, 30);
    }, 900));
    if (String(this.props.replay ?? true) !== 'false') this.timers.push(setTimeout(() => this.play(), 10000));
  }
  renderVals() {
    const dark = (this.props.theme ?? 'light') === 'dark';
    const motion = String(this.props.motion ?? true) !== 'false';
    const s = this.state || {};
    const on = !motion || Boolean(s.on);
    const k = motion ? (s.k || 0) : 1;
    const ease = 'cubic-bezier(.2,.7,.2,1)';
    const a = (i) => `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 18}px); transition: opacity 600ms ${ease} ${i * 90}ms, transform 600ms ${ease} ${i * 90}ms`;
    const time = this.props.time ?? 'morning';
    const day = Math.max(1, Math.min(28, Number(this.props.day ?? 3)));
    const glim = time === 'evening' || time === 'night';
    const t = glim
      ? (dark ? { bg: '#140E3A', ink: '#FFF8EE', muted: '#B8B3D9', card: 'rgba(255,255,255,0.07)', line: 'rgba(255,255,255,0.1)', off: 'rgba(255,255,255,0.16)' } : { bg: '#4A3596', ink: '#FFF8EE', muted: '#D2C8FF', card: 'rgba(255,255,255,0.12)', line: 'rgba(255,255,255,0.14)', off: 'rgba(255,255,255,0.22)' })
      : (dark ? { bg: '#241433', ink: '#FFF8EE', muted: '#E0C8E8', card: 'rgba(255,255,255,0.07)', line: 'rgba(255,255,255,0.1)', off: 'rgba(255,255,255,0.16)' } : { bg: '#FFC38A', ink: '#1E1A3A', muted: '#4A2A1A', card: 'rgba(255,248,238,0.66)', line: 'rgba(30,26,58,0.1)', off: 'rgba(30,26,58,0.16)' });
    const date = new Date(2026, 10, 6 + day - 1);
    const dows = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const mons = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const week = Math.ceil(day / 7);
    const titles = ['Look after the basics', 'The noisy passengers', 'Lower the bar', 'If things feel flat', 'Nights out', '“Just one”', 'One week'];
    const lesson = day <= 7 ? titles[day - 1] : `Week ${week} · Day ${day}`;
    const cards = {
      morning: { href: 'F13SOS.dc.html', kicker: 'YOUR COFFEE WAVE', title: 'Usually comes around 9:40', body: 'Try having it somewhere new today. Jelli is ready if the wave comes.', bg: '#2A52DB' },
      afternoon: { href: 'F11Lesson.dc.html', kicker: `TODAY · DAY ${day} · 3 MIN`, title: lesson, body: 'Xero saved your place.', bg: '#0F6E43' },
      evening: { href: 'F16CheckIn.dc.html', kicker: 'WITH GLIM · 1 MIN', title: 'How was today, really?', body: 'One question, then rest.', bg: '#2A1C6E' },
      night: { href: 'F17WindDown.dc.html', kicker: 'WIND DOWN · 6 MIN', title: 'Can’t sleep? Breathe with Glim', body: 'Night cravings pass faster when you lie still.', bg: '#0E0B2B' }
    };
    const greet = { morning: 'Morning, Sam.', afternoon: 'Afternoon, Sam.', evening: 'Evening, Sam.', night: 'Still up, Sam?' }[time];
    const late = time !== 'morning';
    const rows = [
      { label: 'Morning pledge', meta: 'done', done: true, href: 'F09Pledge.dc.html' },
      { label: lesson, meta: '3 min', done: late, href: 'F11Lesson.dc.html' },
      { label: 'Evening check-in', meta: '21:30', done: time === 'night', href: 'F16CheckIn.dc.html' }
    ].map((r, i) => Object.assign(r, {
      dot: `background: ${r.done ? '#0F6E43' : t.off}`,
      line: i ? `border-top: 1px solid ${t.line}` : ''
    }));
    const fade = (show) => `opacity: ${on && show ? 1 : 0}; transform: translateY(${on && show ? 0 : 30}px); transition: opacity 900ms ${ease} 150ms, transform 900ms cubic-bezier(.2,.8,.2,1) 150ms`;
    return {
      t, rows, top: cards[time], greeting: greet,
      dateLine: `${dows[date.getDay()]} ${date.getDate()} ${mons[date.getMonth()]} · Week ${week}, Day ${day}`,
      scene: { morning: 'dawn', afternoon: 'path', evening: 'dusk', night: 'night' }[time],
      clarity: String(Math.min(100, Math.round(20 + 2.8 * day))),
      stage: String(day < 7 ? 1 : day < 14 ? 2 : day < 28 ? 3 : 4),
      mood: time === 'night' ? 'sleepy' : 'hello',
      showX: fade(!glim), showG: fade(glim), motionStr: String(motion),
      navTheme: dark ? 'dark' : 'light',
      nDays: String(Math.round(day * k)), nCigs: String(Math.round(day * 12 * k)), nMoney: String(Math.round(day * 7 * k)),
      a0: `opacity: ${on ? 1 : 0}; transition: opacity 600ms ${ease}`,
      a1: a(3), a2: a(4), a3: a(5), a4: a(6), a5: a(7)
    };
  }
}
</script>
</body>
</html>
````

### `F09Pledge.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Morning pledge</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&amp;family=DM+Sans:wght@400;500;600;700&amp;display=swap">
<style>
body{margin:0}
</style>
</helmet>
<div style="width: 390px; height: 844px; box-sizing: border-box; background: {{t.bg}}; color: {{t.ink}}; position: relative; overflow: hidden; font-family: 'DM Sans', system-ui, sans-serif; display: flex; flex-direction: column">
  <div style="position: relative; height: 330px; flex: none">
    <div style="position: absolute; left: 0; top: 0; {{a0}}"><dc-import name="Hero2" scene="dawn" clarity="28" h="330" edge="{{t.bg}}" animate="{{motionStr}}" hint-size="390px,330px"></dc-import></div>
    <div style="position: absolute; left: 95px; top: 100px; {{rise}}"><dc-import name="Xero" mood="{{mood}}" stage="1" animate="{{motionStr}}" size="200" hint-size="200px,200px"></dc-import></div>
    <a href="F08Today.dc.html" aria-label="Close" style="position: absolute; right: 10px; top: 46px; width: 44px; height: 44px; border-radius: 99px; background: rgba(255,248,238,0.85); color: #1E1A3A; display: flex; align-items: center; justify-content: center"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" aria-hidden="true"><path d="M6 6l12 12M18 6L6 18"></path></svg></a>
  </div>

  <div style="padding: 6px 24px 0 24px; display: flex; flex-direction: column; gap: 10px; text-align: center">
    <div style="font-size: 14px; font-weight: 700; color: {{t.muted}}; {{a1}}">Sunday · Day 3</div>
    <h1 style="margin: 0; font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 32px; line-height: 1.08; letter-spacing: -1px; {{a2}}">Today, I won't use nicotine.</h1>
    <div style="display: flex; justify-content: center; gap: 6px; flex-wrap: wrap; {{a3}}" role="radiogroup" aria-label="Pledge wording">
      <button role="radio" aria-checked="true" style="height: 44px; border: 0; border-radius: 99px; padding: 0 14px; background: {{t.sel}}; color: {{t.selInk}}; font-family: 'DM Sans', sans-serif; font-size: 14px; font-weight: 700; cursor: pointer">Won't use nicotine</button>
      <button role="radio" aria-checked="false" style="height: 44px; border: 0; border-radius: 99px; padding: 0 14px; background: {{t.chip}}; color: {{t.ink}}; font-family: 'DM Sans', sans-serif; font-size: 14px; font-weight: 600; cursor: pointer">One wave at a time</button>
    </div>
  </div>

  <div style="margin: 16px 20px 0 20px; background: {{t.card}}; border-radius: 22px; padding: 14px 16px; display: flex; flex-direction: column; gap: 4px; {{a4}}">
    <div style="font-size: 12px; font-weight: 700; letter-spacing: 0.8px; color: {{t.muted}}">BECAUSE</div>
    <div style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 700; font-size: 19px; line-height: 1.3">To keep up with Maya at the park.</div>
  </div>

  <div style="margin-top: auto; padding: 0 22px 22px 22px; display: flex; flex-direction: column; gap: 8px; {{a5}}">
    <a href="F08Today.dc.html" aria-label="Pledge for today. Hold for one second, or double-tap with VoiceOver." style="position: relative; overflow: hidden; height: 58px; border-radius: 99px; background: {{t.btn}}; color: {{t.btnInk}}; font-weight: 700; font-size: 17px; text-decoration: none; display: flex; align-items: center; justify-content: center; box-shadow: 0 6px 0 rgba(0,0,0,0.22)">
      <span style="position: absolute; left: 0; top: 0; bottom: 0; background: {{t.fill}}; {{fill}}"></span>
      <span style="position: relative">{{btnLabel}}</span>
    </a>
    <p style="margin: 0; text-align: center; font-size: 14px; color: {{t.muted}}">Glim will check in tonight at 21:30. No pressure.</p>
  </div>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"theme":{"editor":"enum","options":["light","dark"],"default":"light"},"motion":{"editor":"boolean","default":true},"replay":{"editor":"boolean","default":true},"$preview":{"width":390,"height":844}}'>
class Component extends DCLogic {
  componentDidMount() { this.play(); }
  componentWillUnmount() { (this.timers || []).forEach(clearTimeout); }
  play() {
    (this.timers || []).forEach(clearTimeout);
    this.timers = [];
    this.setState({ on: false, hold: 0 });
    this.timers.push(setTimeout(() => this.setState({ on: true }), 300));
    this.timers.push(setTimeout(() => this.setState({ hold: 1 }), 2600));
    this.timers.push(setTimeout(() => this.setState({ hold: 2 }), 3600));
    if (String(this.props.replay ?? true) !== 'false') this.timers.push(setTimeout(() => this.play(), 10000));
  }
  renderVals() {
    const dark = (this.props.theme ?? 'light') === 'dark';
    const motion = String(this.props.motion ?? true) !== 'false';
    const s = this.state || {};
    const on = !motion || Boolean(s.on);
    const hold = motion ? (s.hold || 0) : 0;
    const ease = 'cubic-bezier(.2,.7,.2,1)';
    const a = (i) => `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 18}px); transition: opacity 600ms ${ease} ${i * 90}ms, transform 600ms ${ease} ${i * 90}ms`;
    const t = dark
      ? { bg: '#241433', ink: '#FFF8EE', muted: '#E0C8E8', card: 'rgba(255,255,255,0.07)', chip: 'rgba(255,255,255,0.08)', sel: '#FFC38A', selInk: '#241433', btn: '#FFC38A', btnInk: '#241433', fill: '#FFD9B0' }
      : { bg: '#FFC38A', ink: '#1E1A3A', muted: '#4A2A1A', card: 'rgba(255,248,238,0.66)', chip: 'rgba(255,248,238,0.6)', sel: '#1E1A3A', selInk: '#FFF8EE', btn: '#1E1A3A', btnInk: '#FFF8EE', fill: '#3A3460' };
    return {
      t, motionStr: String(motion),
      mood: hold >= 2 ? 'cheer' : 'hello',
      a0: `opacity: ${on ? 1 : 0}; transition: opacity 600ms ${ease}`,
      rise: `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 50}px); transition: opacity 900ms ${ease}, transform 900ms cubic-bezier(.2,.8,.2,1)`,
      a1: a(4), a2: a(5), a3: a(6), a4: a(7), a5: a(8),
      fill: `width: ${hold >= 1 ? 100 : 0}%; transition: width ${hold >= 1 ? 1000 : 200}ms linear`,
      btnLabel: hold >= 2 ? 'Pledged for today ✓' : 'Press and hold to pledge'
    };
  }
}
</script>
</body>
</html>
````

### `F10Program.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Your program</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&amp;family=DM+Sans:wght@400;500;600;700&amp;display=swap">
<style>
body{margin:0}
</style>
</helmet>
<div style="width: 390px; height: 844px; box-sizing: border-box; background: {{t.bg}}; color: {{t.ink}}; position: relative; overflow: hidden; font-family: 'DM Sans', system-ui, sans-serif">
  <div style="padding: 62px 20px 0 20px; display: flex; flex-direction: column; gap: 6px; {{a1}}">
    <div style="font-size: 14px; font-weight: 700; color: {{t.muted}}">Prep, Quit Day, then four weeks</div>
    <h1 style="margin: 0; font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 32px; letter-spacing: -1px">Your program</h1>
  </div>

  <div style="padding: 14px 20px 0 20px; display: flex; gap: 6px; {{a2}}" role="list" aria-label="Phases">
    <sc-for list="{{phases}}" as="p" hint-placeholder-count="4">
      <span role="listitem" style="height: 36px; padding: 0 12px; border-radius: 99px; display: flex; align-items: center; gap: 6px; font-size: 14px; font-weight: 700; white-space: nowrap; {{p.style}}"><svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="4" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true" style="{{p.tick}}"><path d="M5 12l5 5 9-10"></path></svg>{{p.label}}</span>
    </sc-for>
  </div>

  <div style="padding: 16px 20px 0 20px; display: flex; flex-direction: column; gap: 8px" role="list" aria-label="Week 1">
    <sc-for list="{{days}}" as="d" hint-placeholder-count="7">
      <a role="listitem" href="{{d.href}}" style="min-height: 64px; box-sizing: border-box; border-radius: 18px; padding: 10px 12px 10px 10px; display: flex; align-items: center; gap: 12px; text-decoration: none; {{d.style}}">
        <span style="width: 40px; height: 40px; border-radius: 12px; flex: none; display: flex; align-items: center; justify-content: center; {{d.iconBox}}"><svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="{{d.icon}}"></path></svg></span>
        <span style="flex: 1; display: flex; flex-direction: column; gap: 2px"><span style="font-size: 12px; font-weight: 700; letter-spacing: 0.8px; {{d.kickerStyle}}">{{d.kicker}}</span><span style="font-size: 16px; font-weight: 700">{{d.title}}</span></span>
      </a>
    </sc-for>
  </div>
  <p style="margin: 10px 20px 0 20px; font-size: 14px; color: {{t.muted}}; {{a4}}">Day 4 opens tomorrow. No rush.</p>

  <div style="position: absolute; left: 0; bottom: 0"><dc-import name="Nav2" active="program" theme="{{navTheme}}" hint-size="390px,100px"></dc-import></div>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"theme":{"editor":"enum","options":["light","dark"],"default":"light"},"motion":{"editor":"boolean","default":true},"replay":{"editor":"boolean","default":true},"$preview":{"width":390,"height":844}}'>
class Component extends DCLogic {
  componentDidMount() { this.play(); }
  componentWillUnmount() { (this.timers || []).forEach(clearTimeout); }
  play() {
    (this.timers || []).forEach(clearTimeout);
    this.timers = [];
    this.setState({ on: false });
    this.timers.push(setTimeout(() => this.setState({ on: true }), 300));
    if (String(this.props.replay ?? true) !== 'false') this.timers.push(setTimeout(() => this.play(), 10000));
  }
  renderVals() {
    const dark = (this.props.theme ?? 'light') === 'dark';
    const motion = String(this.props.motion ?? true) !== 'false';
    const on = !motion || Boolean(this.state && this.state.on);
    const ease = 'cubic-bezier(.2,.7,.2,1)';
    const a = (i) => `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 18}px); transition: opacity 600ms ${ease} ${i * 90}ms, transform 600ms ${ease} ${i * 90}ms`;
    const t = dark
      ? { bg: '#0E0B2B', ink: '#FFF8EE', muted: '#B8B3D9', surf: '#1B1747', raised: '#2A255F', today: '#FFC38A', todayInk: '#241433', green: '#2FD08A' }
      : { bg: '#FBF7F1', ink: '#1E1A3A', muted: '#5E5975', surf: '#F1EBE2', raised: '#FFFFFF', today: '#FFC38A', todayInk: '#1E1A3A', green: '#0F6E43' };
    const phases = [['Prep', 'done'], ['Quit Day', 'done'], ['Week 1', 'now'], ['Weeks 2–4', 'later']].map(([label, st]) => ({
      label,
      style: st === 'now' ? `background: ${t.ink}; color: ${t.bg}` : st === 'done' ? `background: ${t.surf}; color: ${t.ink}` : `background: transparent; color: ${t.muted}; box-shadow: inset 0 0 0 1.5px ${t.surf}`,
      tick: st === 'done' ? `color: ${t.green}` : 'display: none'
    }));
    const icons = { done: 'M5 12l5 5 9-10', today: 'M8 5v14l11-7z', locked: 'M7 11V8a5 5 0 0 1 10 0v3 M5 11h14v9H5z', star: 'M12 3l2.6 5.6 6 .7-4.5 4.1 1.2 6L12 16.6 6.7 19.4l1.2-6L3.4 9.3l6-.7z' };
    const list = [
      [1, 'Look after the basics', 'done'], [2, 'The noisy passengers', 'done'], [3, 'Lower the bar', 'today'],
      [4, 'If things feel flat', 'locked'], [5, 'Nights out', 'locked'], [6, '“Just one”', 'locked'], [7, 'One week', 'milestone']
    ];
    const days = list.map(([n, title, st], i) => {
      const today = st === 'today';
      const muted = st === 'locked' || st === 'milestone';
      return {
        title, href: today ? 'F11Lesson.dc.html' : '#',
        kicker: today ? `TODAY · DAY ${n} · 3 MIN` : st === 'done' ? `DAY ${n} · DONE` : st === 'milestone' ? `DAY ${n} · MILESTONE` : `DAY ${n} · OPENS ON DAY ${n}`,
        icon: icons[st === 'milestone' ? 'star' : st],
        style: (today ? `background: ${t.today}; color: ${t.todayInk}; box-shadow: 0 4px 0 rgba(0,0,0,0.12)` : `background: ${muted ? 'transparent' : t.raised}; color: ${muted ? t.muted : t.ink}; box-shadow: ${muted ? `inset 0 0 0 1.5px ${t.surf}` : 'none'}`) + `; opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 18}px); transition: opacity 600ms ${ease} ${(3 + i) * 70}ms, transform 600ms ${ease} ${(3 + i) * 70}ms`,
        iconBox: today ? 'background: #1E1A3A; color: #FFF8EE' : st === 'done' ? `background: ${t.surf}; color: ${t.green}` : `background: ${t.surf}; color: ${t.muted}`,
        kickerStyle: today ? 'opacity: 0.85' : `color: ${t.muted}`
      };
    });
    return { t, phases, days, navTheme: dark ? 'dark' : 'light', a1: a(0), a2: a(1), a4: a(11) };
  }
}
</script>
</body>
</html>
````

### `F11Lesson.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Lesson · Lower the bar</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&amp;family=DM+Sans:wght@400;500;600;700&amp;display=swap">
<style>
body{margin:0}
</style>
</helmet>
<div style="width: 390px; height: 844px; box-sizing: border-box; background: {{t.bg}}; color: {{t.ink}}; position: relative; overflow: hidden; font-family: 'DM Sans', system-ui, sans-serif; display: flex; flex-direction: column">
  <div style="display: flex; align-items: center; gap: 10px; padding: 50px 10px 0 10px">
    <a href="F10Program.dc.html" aria-label="Back to program" style="width: 44px; height: 44px; border-radius: 99px; color: {{t.ink}}; display: flex; align-items: center; justify-content: center"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 5l-7 7 7 7"></path></svg></a>
    <div style="flex: 1; display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 6px" role="progressbar" aria-label="Lesson step" aria-valuenow="2" aria-valuemin="1" aria-valuemax="3">
      <span style="height: 6px; border-radius: 99px; background: {{t.ink}}"></span><span style="height: 6px; border-radius: 99px; background: {{t.ink}}"></span><span style="height: 6px; border-radius: 99px; background: {{t.surf}}"></span>
    </div>
    <span style="width: 44px"></span>
  </div>

  <div style="padding: 16px 22px 0 22px; display: flex; flex-direction: column; gap: 6px; {{a1}}">
    <div style="display: flex; align-items: center; gap: 10px">
      <span style="width: 40px; height: 40px; border-radius: 99px; background: #FFC38A; overflow: hidden; display: flex; align-items: center; justify-content: center; flex: none"><dc-import name="Xero" mood="calm" stage="1" animate="{{motionStr}}" size="40" hint-size="40px,40px"></dc-import></span>
      <span style="font-size: 14px; font-weight: 700; color: {{t.muted}}">Week 1 · Day 3 · 3 min</span>
    </div>
    <h1 style="margin: 4px 0 0 0; font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 32px; line-height: 1.08; letter-spacing: -1px">Lower the bar</h1>
    <p style="margin: 0; font-size: 16px; color: {{t.muted}}">Getting through the toughest stretch</p>
  </div>

  <div style="margin: 14px 20px 0 20px; background: {{t.surf}}; border-radius: 18px; padding: 8px 8px 8px 14px; display: flex; align-items: center; gap: 12px; {{a2}}">
    <span style="flex: 1; font-size: 14px; font-weight: 600">Your reason · To keep up with Maya at the park</span>
  </div>

  <div style="margin: 12px 20px 0 20px; background: {{t.raised}}; border-radius: 24px; padding: 18px 16px; display: flex; flex-direction: column; gap: 12px; box-shadow: {{t.shadow}}; {{a3}}">
    <div style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 700; font-size: 19px; line-height: 1.3">If today gets hard, then I will…</div>
    <div style="display: flex; flex-wrap: wrap; gap: 8px" role="group" aria-label="Plan options">
      <sc-for list="{{opts}}" as="o" hint-placeholder-count="6">
        <button aria-pressed="{{o.pressed}}" style="min-height: 44px; border: 0; border-radius: 14px; padding: 0 14px; font-family: 'DM Sans', sans-serif; font-size: 16px; font-weight: 600; cursor: pointer; display: flex; align-items: center; gap: 6px; {{o.style}}">{{o.label}}</button>
      </sc-for>
    </div>
    <div style="font-size: 14px; color: {{t.muted}}">Saved as your rough-day plan. It shows up on hard days.</div>
  </div>

  <div style="margin-top: auto; padding: 0 22px 22px 22px; display: flex; flex-direction: column; gap: 10px; {{a5}}">
    <div style="display: flex; align-items: center; gap: 12px; background: {{t.surf}}; border-radius: 18px; padding: 8px 14px 8px 8px">
      <button aria-label="Play audio, 3 minutes" style="width: 44px; height: 44px; border: 0; border-radius: 99px; background: {{t.ink}}; color: {{t.bg}}; display: flex; align-items: center; justify-content: center; cursor: pointer; flex: none"><svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M8 5v14l11-7z"></path></svg></button>
      <span style="flex: 1; font-size: 14px; font-weight: 600">Prefer to listen? 3:00</span>
    </div>
    <a href="F08Today.dc.html" style="height: 58px; border-radius: 99px; background: {{t.ink}}; color: {{t.bg}}; font-weight: 700; font-size: 17px; text-decoration: none; display: flex; align-items: center; justify-content: center">Next</a>
  </div>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"theme":{"editor":"enum","options":["light","dark"],"default":"light"},"motion":{"editor":"boolean","default":true},"replay":{"editor":"boolean","default":true},"$preview":{"width":390,"height":844}}'>
class Component extends DCLogic {
  componentDidMount() { this.play(); }
  componentWillUnmount() { (this.timers || []).forEach(clearTimeout); }
  play() {
    (this.timers || []).forEach(clearTimeout);
    this.timers = [];
    this.setState({ on: false, pick: 0 });
    this.timers.push(setTimeout(() => this.setState({ on: true }), 300));
    this.timers.push(setTimeout(() => this.setState({ pick: 1 }), 2000));
    this.timers.push(setTimeout(() => this.setState({ pick: 2 }), 2700));
    if (String(this.props.replay ?? true) !== 'false') this.timers.push(setTimeout(() => this.play(), 10000));
  }
  renderVals() {
    const dark = (this.props.theme ?? 'light') === 'dark';
    const motion = String(this.props.motion ?? true) !== 'false';
    const s = this.state || {};
    const on = !motion || Boolean(s.on);
    const pick = motion ? (s.pick || 0) : 2;
    const ease = 'cubic-bezier(.2,.7,.2,1)';
    const a = (i) => `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 18}px); transition: opacity 600ms ${ease} ${i * 90}ms, transform 600ms ${ease} ${i * 90}ms`;
    const t = dark
      ? { bg: '#0E0B2B', ink: '#FFF8EE', muted: '#B8B3D9', surf: '#1B1747', raised: '#2A255F', shadow: 'none', sel: '#FFF8EE', selInk: '#0E0B2B' }
      : { bg: '#FBF7F1', ink: '#1E1A3A', muted: '#5E5975', surf: '#F1EBE2', raised: '#FFFFFF', shadow: '0 1px 0 rgba(30,26,58,0.05), 0 8px 22px rgba(30,26,58,0.07)', sel: '#1E1A3A', selInk: '#FFF8EE' };
    const labels = ['Walk for 5 minutes', 'Text or call someone', 'Open Craving SOS', 'Have a shower', 'Go to bed early', 'Eat something proper'];
    const opts = labels.map((label, i) => {
      const p = (i === 0 && pick >= 1) || (i === 2 && pick >= 2);
      return { label, pressed: p ? 'true' : 'false', style: `background: ${p ? t.sel : t.surf}; color: ${p ? t.selInk : t.ink}; transition: background 250ms, color 250ms` };
    });
    return { t, opts, motionStr: String(motion), a1: a(1), a2: a(2), a3: a(3), a5: a(5) };
  }
}
</script>
</body>
</html>
````

### `F12Progress.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Your progress</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&amp;family=DM+Sans:wght@400;500;600;700&amp;display=swap">
<style>
body{margin:0}
</style>
</helmet>
<div style="width: 390px; height: 844px; box-sizing: border-box; background: {{t.bg}}; color: {{t.ink}}; position: relative; overflow: hidden; font-family: 'DM Sans', system-ui, sans-serif">
  <div style="padding: 62px 20px 0 20px; display: flex; flex-direction: column; gap: 4px; {{a1}}">
    <div style="font-size: 14px; font-weight: 700; color: {{t.muted}}">Since Quit Day · Fri 6 Nov</div>
    <h1 style="margin: 0; font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 32px; letter-spacing: -1px">Your progress</h1>
  </div>

  <div style="margin: 14px 20px 0 20px; border-radius: 22px; overflow: hidden; position: relative; height: 110px; {{a2}}">
    <dc-import name="Horizon2" scene="path" clarity="28" animate="{{motionStr}}" w="350" h="110" hint-size="350px,110px"></dc-import>
    <div style="position: absolute; left: 12px; bottom: 10px; background: rgba(255,248,238,0.92); color: #1E1A3A; border-radius: 99px; padding: 6px 12px; font-size: 14px; font-weight: 700">Sky {{sky}}% clear · clears a little each day</div>
  </div>

  <div style="margin: 10px 20px 0 20px; display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 8px; {{a3}}">
    <sc-for list="{{stats}}" as="s" hint-placeholder-count="4">
      <div style="background: {{t.raised}}; border-radius: 18px; padding: 12px 14px; box-shadow: {{t.shadow}}"><div style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 24px">{{s.v}}</div><div style="font-size: 14px; color: {{t.muted}}">{{s.k}}</div></div>
    </sc-for>
  </div>
  <p style="margin: 8px 20px 0 20px; font-size: 14px; color: {{t.muted}}; {{a3}}">$7 a day, about $2,555 a year. 2 evening check-ins with Glim.</p>

  <div style="margin: 14px 20px 0 20px; background: {{t.raised}}; border-radius: 22px; padding: 14px 16px; display: flex; flex-direction: column; gap: 10px; box-shadow: {{t.shadow}}; {{a4}}">
    <div style="font-size: 12px; font-weight: 700; letter-spacing: 0.8px; color: {{t.muted}}">WHAT'S CHANGING</div>
    <div style="display: flex; gap: 10px; align-items: flex-start">
      <span style="width: 10px; height: 10px; margin-top: 6px; border-radius: 99px; background: {{t.green}}; flex: none"></span>
      <span style="display: flex; flex-direction: column; gap: 2px"><span style="font-size: 12px; font-weight: 700; color: {{t.green}}">HAPPENING NOW · A FEW DAYS</span><span style="font-size: 16px; font-weight: 700; line-height: 1.35">Carbon monoxide in your blood drops to normal</span><span style="font-size: 14px; color: {{t.muted}}">More oxygen reaches your body.</span></span>
    </div>
    <div style="display: flex; gap: 10px; align-items: flex-start">
      <span style="width: 10px; height: 10px; margin-top: 6px; border-radius: 99px; box-shadow: inset 0 0 0 2px {{t.muted}}; flex: none"></span>
      <span style="display: flex; flex-direction: column; gap: 2px"><span style="font-size: 12px; font-weight: 700; color: {{t.muted}}">NEXT · 2 WEEKS TO 3 MONTHS</span><span style="font-size: 16px; font-weight: 700; line-height: 1.35">Circulation and lung function improve</span></span>
    </div>
    <div style="font-size: 12px; color: {{t.muted}}">Source: American Cancer Society</div>
  </div>

  <div style="position: absolute; left: 0; bottom: 0"><dc-import name="Nav2" active="me" theme="{{navTheme}}" hint-size="390px,100px"></dc-import></div>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"theme":{"editor":"enum","options":["light","dark"],"default":"light"},"motion":{"editor":"boolean","default":true},"replay":{"editor":"boolean","default":true},"$preview":{"width":390,"height":844}}'>
class Component extends DCLogic {
  componentDidMount() { this.play(); }
  componentWillUnmount() { (this.timers || []).forEach(clearTimeout); clearInterval(this.iv); }
  play() {
    (this.timers || []).forEach(clearTimeout); clearInterval(this.iv);
    this.timers = [];
    this.setState({ on: false, k: 0 });
    this.timers.push(setTimeout(() => this.setState({ on: true }), 300));
    this.timers.push(setTimeout(() => {
      const t0 = Date.now();
      this.iv = setInterval(() => {
        const p = Math.min(1, (Date.now() - t0) / 800);
        this.setState({ k: 1 - Math.pow(1 - p, 3) });
        if (p >= 1) clearInterval(this.iv);
      }, 30);
    }, 700));
    if (String(this.props.replay ?? true) !== 'false') this.timers.push(setTimeout(() => this.play(), 10000));
  }
  renderVals() {
    const dark = (this.props.theme ?? 'light') === 'dark';
    const motion = String(this.props.motion ?? true) !== 'false';
    const s = this.state || {};
    const on = !motion || Boolean(s.on);
    const k = motion ? (s.k || 0) : 1;
    const ease = 'cubic-bezier(.2,.7,.2,1)';
    const a = (i) => `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 18}px); transition: opacity 600ms ${ease} ${i * 90}ms, transform 600ms ${ease} ${i * 90}ms`;
    const t = dark
      ? { bg: '#0E0B2B', ink: '#FFF8EE', muted: '#B8B3D9', raised: '#1B1747', shadow: 'none', green: '#2FD08A' }
      : { bg: '#FBF7F1', ink: '#1E1A3A', muted: '#5E5975', raised: '#FFFFFF', shadow: '0 1px 0 rgba(30,26,58,0.05), 0 8px 22px rgba(30,26,58,0.07)', green: '#0F6E43' };
    const n = (v) => String(Math.round(v * k));
    const stats = [
      { v: n(3), k: 'days clear' }, { v: n(15), k: 'waves ridden out' },
      { v: n(36), k: 'cigarettes not smoked' }, { v: '$' + n(21), k: 'kept' }
    ];
    return { t, stats, sky: n(28), motionStr: String(motion), navTheme: dark ? 'dark' : 'light', a1: a(0), a2: a(1), a3: a(2), a4: a(3) };
  }
}
</script>
</body>
</html>
````

### `F13SOS.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Craving SOS with Jelli</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&amp;family=DM+Sans:wght@400;500;600;700&amp;display=swap">
<style>
body{margin:0}
</style>
</helmet>
<div style="width: 390px; height: 844px; box-sizing: border-box; background: {{t.bg}}; color: #FFF8EE; position: relative; overflow: hidden; font-family: 'DM Sans', system-ui, sans-serif">
  <svg width="390" height="844" viewBox="0 0 390 844" aria-hidden="true" style="position: absolute; left: 0; top: 0">
    <circle cx="195" cy="300" r="140" fill="{{t.glow}}"><animate attributeName="r" values="{{glowR}}" keyTimes="0;0.4;1" calcMode="spline" keySplines="0.45 0 0.55 1;0.45 0 0.55 1" dur="10s" repeatCount="indefinite"></animate></circle>
    <path fill="{{t.w1}}"><animate attributeName="d" values="{{waveA}}" dur="7s" repeatCount="indefinite"></animate></path>
    <path fill="{{t.w2}}"><animate attributeName="d" values="{{waveB}}" dur="5.5s" repeatCount="indefinite"></animate></path>
  </svg>

  <div style="position: absolute; left: 14px; right: 10px; top: 48px; display: flex; align-items: center; justify-content: space-between">
    <div style="height: 40px; display: flex; align-items: center; gap: 8px; background: {{t.sec}}; border-radius: 99px; padding: 0 14px 0 4px; font-size: 14px; font-weight: 600; {{hand}}">
      <span style="width: 32px; height: 32px; border-radius: 99px; background: #FFC38A; overflow: hidden; display: flex; align-items: center; justify-content: center"><dc-import name="Xero" mood="calm" stage="1" animate="false" size="32" hint-size="32px,32px"></dc-import></span>
      Xero passed you to Jelli
    </div>
    <a href="F08Today.dc.html" aria-label="Close" style="width: 44px; height: 44px; border-radius: 99px; color: #FFF8EE; display: flex; align-items: center; justify-content: center"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" aria-hidden="true"><path d="M6 6l12 12M18 6L6 18"></path></svg></a>
  </div>

  <div style="position: absolute; left: 95px; top: 160px; {{jIn}}"><dc-import name="Jelli" mood="breathe" stage="2" animate="{{motionStr}}" size="200" hint-size="200px,200px"></dc-import></div>

  <div style="position: absolute; left: 24px; right: 24px; top: 392px; height: 48px" aria-live="polite">
    <div style="position: absolute; inset: 0; text-align: center; font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 40px; letter-spacing: -1.2px; {{inStyle}}">Breathe in… 4</div>
    <div style="position: absolute; inset: 0; text-align: center; font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 40px; letter-spacing: -1.2px; {{outStyle}}">…and out, 6</div>
  </div>
  <p style="position: absolute; left: 32px; right: 32px; top: 452px; margin: 0; text-align: center; font-size: 16px; line-height: 1.5; color: {{t.muted}}; {{a1}}">Most cravings pass within a few minutes. Ride it with me. <b style="color: #FFF8EE">You've ridden {{clock}}.</b></p>

  <div style="position: absolute; left: 20px; right: 20px; top: 534px; background: {{t.sec}}; border-radius: 22px; padding: 14px 16px; display: flex; flex-direction: column; gap: 4px; {{a2}}">
    <div style="font-size: 12px; font-weight: 700; letter-spacing: 0.8px; color: {{t.muted}}">YOUR REASON</div>
    <div style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 700; font-size: 19px; line-height: 1.3">To keep up with Maya at the park.</div>
  </div>

  <div style="position: absolute; left: 20px; right: 20px; bottom: 22px; display: flex; flex-direction: column; gap: 8px; {{a3}}">
    <div style="display: flex; gap: 8px">
      <a href="F14Passed.dc.html" style="flex: 1; height: 58px; border-radius: 99px; background: #FFF8EE; color: {{t.bg}}; font-weight: 700; font-size: 17px; text-decoration: none; display: flex; align-items: center; justify-content: center; box-shadow: 0 6px 0 rgba(0,0,0,0.22)">It passed</a>
      <a href="#" style="height: 58px; padding: 0 18px; border-radius: 99px; background: {{t.sec}}; color: #FFF8EE; font-weight: 600; font-size: 16px; text-decoration: none; display: flex; align-items: center">Still strong</a>
    </div>
    <div style="display: flex; justify-content: center; gap: 6px; font-size: 14px">
      <a href="#" style="height: 44px; display: flex; align-items: center; padding: 0 10px; color: #FFF8EE; font-weight: 600">Text a friend</a>
      <span style="display: flex; align-items: center; color: {{t.muted}}" aria-hidden="true">·</span>
      <a href="F15Slip.dc.html" style="height: 44px; display: flex; align-items: center; padding: 0 10px; color: #FFF8EE; font-weight: 600">I slipped</a>
    </div>
  </div>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"theme":{"editor":"enum","options":["light","dark"],"default":"light"},"motion":{"editor":"boolean","default":true},"replay":{"editor":"boolean","default":true},"$preview":{"width":390,"height":844}}'>
class Component extends DCLogic {
  componentDidMount() { this.play(); }
  componentWillUnmount() { (this.timers || []).forEach(clearTimeout); clearInterval(this.iv); }
  play() {
    (this.timers || []).forEach(clearTimeout); clearInterval(this.iv);
    this.timers = [];
    this.setState({ on: false, handed: false, phase: 'in', sec: 40 });
    this.timers.push(setTimeout(() => this.setState({ on: true }), 300));
    this.timers.push(setTimeout(() => this.setState({ handed: true }), 3000));
    this.timers.push(setTimeout(() => this.setState({ phase: 'out' }), 4300));
    this.timers.push(setTimeout(() => this.setState({ phase: 'in' }), 10300));
    this.iv = setInterval(() => this.setState({ sec: ((this.state && this.state.sec) || 40) + 1 }), 1000);
    if (String(this.props.replay ?? true) !== 'false') this.timers.push(setTimeout(() => this.play(), 12000));
  }
  renderVals() {
    const dark = (this.props.theme ?? 'light') === 'dark';
    const motion = String(this.props.motion ?? true) !== 'false';
    const s = this.state || {};
    const on = !motion || Boolean(s.on);
    const ease = 'cubic-bezier(.2,.7,.2,1)';
    const a = (i) => `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 18}px); transition: opacity 600ms ${ease} ${i * 90}ms, transform 600ms ${ease} ${i * 90}ms`;
    const t = dark
      ? { bg: '#0B1A4A', muted: '#B9C9FF', sec: '#1B2C66', glow: 'rgba(42,82,219,0.25)', w1: '#13286A', w2: '#1A3384' }
      : { bg: '#2A52DB', muted: '#E3EAFF', sec: '#1D3A9E', glow: 'rgba(156,203,255,0.3)', w1: '#2449CC', w2: '#1F40B8' };
    const sec = motion ? (s.sec || 40) : 52;
    const phase = motion ? (s.phase || 'in') : 'in';
    const fade = (show) => `opacity: ${on && show ? 1 : 0}; transition: opacity 500ms ${ease}`;
    const m = (x, y) => motion ? x : y;
    const w = (y, d) => `M0 ${y} C 100 ${y - d} 290 ${y + d} 390 ${y} L390 844 L0 844 Z`;
    return {
      t, motionStr: String(motion),
      clock: `${Math.floor(sec / 60)}:${String(sec % 60).padStart(2, '0')}`,
      inStyle: fade(phase === 'in'), outStyle: fade(phase === 'out'),
      hand: `opacity: ${on && !(motion && s.handed) ? 1 : 0}; transform: translateX(${on ? 0 : -30}px); transition: opacity 600ms ${ease}, transform 600ms ${ease}`,
      jIn: `opacity: ${on ? 1 : 0}; transform: translateX(${on ? 0 : 90}px); transition: opacity 900ms ${ease} 200ms, transform 900ms cubic-bezier(.2,.8,.2,1) 200ms`,
      a1: a(5), a2: a(6), a3: a(7),
      glowR: m('125;165;125', '140;140;140'),
      waveA: m([w(730, 16), w(730, -16), w(730, 16)].join(';'), [w(730, 0), w(730, 0)].join(';')),
      waveB: m([w(774, -12), w(774, 12), w(774, -12)].join(';'), [w(774, 0), w(774, 0)].join(';'))
    };
  }
}
</script>
</body>
</html>
````

### `F14Passed.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>The wave passed</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&amp;family=DM+Sans:wght@400;500;600;700&amp;display=swap">
<style>
body{margin:0}
</style>
</helmet>
<div style="width: 390px; height: 844px; box-sizing: border-box; background: {{t.bg}}; color: {{t.ink}}; position: relative; overflow: hidden; font-family: 'DM Sans', system-ui, sans-serif; display: flex; flex-direction: column">
  <svg width="390" height="844" viewBox="0 0 390 844" aria-hidden="true" style="position: absolute; left: 0; top: 0">
    <circle cx="44" cy="900" r="5" fill="none" stroke="{{t.bub}}" stroke-width="2.5"><animate attributeName="cy" values="{{b1}}" dur="6s" repeatCount="indefinite"></animate></circle>
    <circle cx="120" cy="900" r="8" fill="none" stroke="{{t.bub}}" stroke-width="2.5"><animate attributeName="cy" values="{{b2}}" dur="8s" begin="1.2s" repeatCount="indefinite"></animate></circle>
    <circle cx="262" cy="900" r="6" fill="none" stroke="{{t.bub}}" stroke-width="2.5"><animate attributeName="cy" values="{{b3}}" dur="7s" begin="0.6s" repeatCount="indefinite"></animate></circle>
    <circle cx="346" cy="900" r="4" fill="none" stroke="{{t.bub}}" stroke-width="2.5"><animate attributeName="cy" values="{{b4}}" dur="5s" begin="2s" repeatCount="indefinite"></animate></circle>
  </svg>

  <div style="position: relative; height: 320px; flex: none; display: flex; align-items: flex-end; justify-content: center">
    <div style="{{jIn}}"><dc-import name="Jelli" mood="cheer" stage="2" animate="{{motionStr}}" size="200" hint-size="200px,200px"></dc-import></div>
  </div>

  <div style="position: relative; padding: 8px 28px 0 28px; text-align: center; display: flex; flex-direction: column; gap: 10px">
    <h1 style="margin: 0; font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 32px; line-height: 1.08; letter-spacing: -1px; {{a1}}">You rode it out.</h1>
    <p style="margin: 0; font-size: 16px; line-height: 1.5; color: {{t.muted}}; {{a2}}">That wave lasted 2 minutes 10 seconds. Each one you ride makes the next a little quieter.</p>
  </div>

  <div style="position: relative; margin: 16px 20px 0 20px; background: {{t.card}}; border-radius: 22px; padding: 14px 16px; display: flex; align-items: center; justify-content: space-between; {{a3}}">
    <span style="display: flex; flex-direction: column"><span style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 32px; display: flex; align-items: baseline; gap: 8px">{{waves}} <span style="font-family: 'DM Sans', sans-serif; font-size: 16px; font-weight: 700; color: {{t.green}}; display: inline-block; {{plus}}">+1</span></span><span style="font-size: 14px; color: {{t.muted}}">waves ridden out</span></span>
  </div>

  <div style="position: relative; margin: 10px 20px 0 20px; background: {{t.card}}; border-radius: 22px; padding: 14px 16px; display: flex; flex-direction: column; gap: 10px; {{a4}}">
    <div style="font-size: 16px; font-weight: 700">What set it off? <span style="font-weight: 500; color: {{t.muted}}">· optional</span></div>
    <div style="display: flex; gap: 8px; flex-wrap: wrap" role="group" aria-label="Trigger">
      <sc-for list="{{chips}}" as="c" hint-placeholder-count="3">
        <button aria-pressed="{{c.pressed}}" style="height: 44px; border: 0; border-radius: 14px; padding: 0 14px; font-family: 'DM Sans', sans-serif; font-size: 16px; font-weight: 600; cursor: pointer; {{c.style}}">{{c.label}}</button>
      </sc-for>
    </div>
  </div>

  <div style="position: relative; margin: 10px 20px 0 20px; display: flex; gap: 10px; align-items: center; font-size: 14px; line-height: 1.45; {{a5}}">
    <span style="width: 40px; height: 40px; border-radius: 99px; background: #FFC38A; overflow: hidden; flex: none; display: flex; align-items: center; justify-content: center"><dc-import name="Xero" mood="cheer" stage="1" animate="false" size="40" hint-size="40px,40px"></dc-import></span>
    <span>Back to Xero. I rose a little while you were out.</span>
  </div>

  <div style="margin-top: auto; padding: 0 22px 22px 22px; position: relative; {{a6}}">
    <a href="F08Today.dc.html" style="height: 58px; border-radius: 99px; background: {{t.btn}}; color: {{t.btnInk}}; font-weight: 700; font-size: 17px; text-decoration: none; display: flex; align-items: center; justify-content: center; box-shadow: 0 6px 0 rgba(0,0,0,0.2)">Back to my day</a>
  </div>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"theme":{"editor":"enum","options":["light","dark"],"default":"light"},"motion":{"editor":"boolean","default":true},"replay":{"editor":"boolean","default":true},"$preview":{"width":390,"height":844}}'>
class Component extends DCLogic {
  componentDidMount() { this.play(); }
  componentWillUnmount() { (this.timers || []).forEach(clearTimeout); }
  play() {
    (this.timers || []).forEach(clearTimeout);
    this.timers = [];
    this.setState({ on: false, bump: false, pick: false });
    this.timers.push(setTimeout(() => this.setState({ on: true }), 300));
    this.timers.push(setTimeout(() => this.setState({ bump: true }), 1500));
    this.timers.push(setTimeout(() => this.setState({ pick: true }), 3200));
    if (String(this.props.replay ?? true) !== 'false') this.timers.push(setTimeout(() => this.play(), 10000));
  }
  renderVals() {
    const dark = (this.props.theme ?? 'light') === 'dark';
    const motion = String(this.props.motion ?? true) !== 'false';
    const s = this.state || {};
    const on = !motion || Boolean(s.on);
    const bump = !motion || Boolean(s.bump);
    const pick = !motion || Boolean(s.pick);
    const ease = 'cubic-bezier(.2,.7,.2,1)';
    const spring = 'cubic-bezier(.3,1.4,.5,1)';
    const a = (i) => `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 18}px); transition: opacity 600ms ${ease} ${i * 90}ms, transform 600ms ${ease} ${i * 90}ms`;
    const t = dark
      ? { bg: '#0F2550', ink: '#FFF8EE', muted: '#B9D6FF', card: 'rgba(255,255,255,0.08)', chip: 'rgba(255,255,255,0.08)', sel: '#FFF8EE', selInk: '#0F2550', green: '#2FD08A', bub: 'rgba(156,203,255,0.45)', btn: '#FFF8EE', btnInk: '#0F2550' }
      : { bg: '#9CCBFF', ink: '#1E1A3A', muted: '#24406E', card: 'rgba(255,248,238,0.72)', chip: '#FFFFFF', sel: '#1E1A3A', selInk: '#FFF8EE', green: '#0F6E43', bub: 'rgba(255,248,238,0.85)', btn: '#1E1A3A', btnInk: '#FFF8EE' };
    const chips = ['Coffee', 'Stress', 'More…'].map((label, i) => {
      const p = i === 0 && pick;
      return { label, pressed: p ? 'true' : 'false', style: `background: ${p ? t.sel : t.chip}; color: ${p ? t.selInk : t.ink}; transition: background 250ms, color 250ms` };
    });
    const m = (x, y) => motion ? x : y;
    return {
      t, chips, motionStr: String(motion),
      waves: bump ? '15' : '14',
      plus: `opacity: ${bump ? 1 : 0}; transform: translateY(${bump ? 0 : 8}px) scale(${bump ? 1 : 0.5}); transition: opacity 300ms, transform 600ms ${spring}`,
      jIn: `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 60}px) scale(${on ? 1 : 0.85}); transition: opacity 600ms ${ease}, transform 700ms ${spring}`,
      a1: a(3), a2: a(4), a3: a(5), a4: a(7), a5: a(8), a6: a(9),
      b1: m('900;-20', '300;300'), b2: m('900;-20', '180;180'), b3: m('900;-20', '420;420'), b4: m('900;-20', '250;250')
    };
  }
}
</script>
</body>
</html>
````

### `F15Slip.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>After a slip</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&amp;family=DM+Sans:wght@400;500;600;700&amp;display=swap">
<style>
body{margin:0}
</style>
</helmet>
<div style="width: 390px; height: 844px; box-sizing: border-box; background: {{t.bg}}; color: {{t.ink}}; position: relative; overflow: hidden; font-family: 'DM Sans', system-ui, sans-serif; display: flex; flex-direction: column">
  <div style="display: flex; align-items: center; gap: 10px; padding: 50px 10px 0 10px">
    <a href="F13SOS.dc.html" aria-label="Back" style="width: 44px; height: 44px; border-radius: 99px; color: {{t.ink}}; display: flex; align-items: center; justify-content: center"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M15 5l-7 7 7 7"></path></svg></a>
    <div style="flex: 1; display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 6px" role="progressbar" aria-label="Step" aria-valuenow="2" aria-valuemin="1" aria-valuemax="3">
      <span style="height: 6px; border-radius: 99px; background: {{t.ink}}"></span><span style="height: 6px; border-radius: 99px; background: {{t.ink}}"></span><span style="height: 6px; border-radius: 99px; background: {{t.surf}}"></span>
    </div>
    <span style="width: 44px"></span>
  </div>

  <div style="padding: 14px 22px 0 22px; display: flex; gap: 14px; align-items: center; {{a1}}">
    <span style="width: 88px; height: 88px; border-radius: 26px; background: {{t.jelliBg}}; flex: none; display: flex; align-items: center; justify-content: center; overflow: hidden"><dc-import name="Jelli" mood="calm" stage="2" animate="{{motionStr}}" size="88" hint-size="88px,88px"></dc-import></span>
    <span style="display: flex; flex-direction: column; gap: 2px"><span style="font-size: 14px; font-weight: 700; color: {{t.muted}}">With Jelli</span><h1 style="margin: 0; font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 32px; line-height: 1.08; letter-spacing: -1px">Thanks for telling me.</h1></span>
  </div>
  <p style="margin: 14px 22px 0 22px; font-size: 16px; line-height: 1.5; color: {{t.muted}}; {{a2}}">Waves come and go. Nothing resets: your days clear and Xero's sky stay just as they are. Let's make a plan for next time.</p>

  <div style="margin: 16px 20px 0 20px; background: {{t.raised}}; border-radius: 22px; padding: 16px; display: flex; flex-direction: column; gap: 12px; box-shadow: {{t.shadow}}; {{a3}}">
    <div style="font-size: 16px; font-weight: 700">What set it off?</div>
    <div style="display: flex; gap: 8px; flex-wrap: wrap" role="group" aria-label="Trigger">
      <sc-for list="{{trig}}" as="c" hint-placeholder-count="3"><button aria-pressed="{{c.pressed}}" style="height: 44px; border: 0; border-radius: 14px; padding: 0 14px; font-family: 'DM Sans', sans-serif; font-size: 16px; font-weight: 600; cursor: pointer; {{c.style}}">{{c.label}}</button></sc-for>
    </div>
    <div style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 700; font-size: 19px; padding-top: 4px">If it's coffee, then I'll…</div>
    <div style="display: flex; flex-direction: column; gap: 8px" role="radiogroup" aria-label="Then I will">
      <sc-for list="{{plans}}" as="p" hint-placeholder-count="4"><button role="radio" aria-checked="{{p.pressed}}" style="min-height: 48px; border: 0; border-radius: 14px; padding: 0 14px; font-family: 'DM Sans', sans-serif; font-size: 16px; font-weight: 600; cursor: pointer; text-align: left; display: flex; align-items: center; justify-content: space-between; {{p.style}}">{{p.label}}<span style="width: 22px; height: 22px; border-radius: 99px; flex: none; {{p.ring}}"></span></button></sc-for>
    </div>
  </div>

  <div style="margin-top: auto; padding: 0 22px 22px 22px; {{a5}}">
    <a href="F08Today.dc.html" style="height: 58px; border-radius: 99px; background: {{t.ink}}; color: {{t.bg}}; font-weight: 700; font-size: 17px; text-decoration: none; display: flex; align-items: center; justify-content: center">Save my plan</a>
  </div>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"theme":{"editor":"enum","options":["light","dark"],"default":"light"},"motion":{"editor":"boolean","default":true},"replay":{"editor":"boolean","default":true},"$preview":{"width":390,"height":844}}'>
class Component extends DCLogic {
  componentDidMount() { this.play(); }
  componentWillUnmount() { (this.timers || []).forEach(clearTimeout); }
  play() {
    (this.timers || []).forEach(clearTimeout);
    this.timers = [];
    this.setState({ on: false });
    this.timers.push(setTimeout(() => this.setState({ on: true }), 300));
    if (String(this.props.replay ?? true) !== 'false') this.timers.push(setTimeout(() => this.play(), 10000));
  }
  renderVals() {
    const dark = (this.props.theme ?? 'light') === 'dark';
    const motion = String(this.props.motion ?? true) !== 'false';
    const on = !motion || Boolean(this.state && this.state.on);
    const ease = 'cubic-bezier(.2,.7,.2,1)';
    const a = (i) => `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 12}px); transition: opacity 600ms ${ease} ${i * 90}ms, transform 600ms ${ease} ${i * 90}ms`;
    const t = dark
      ? { bg: '#0E0B2B', ink: '#FFF8EE', muted: '#B8B3D9', surf: '#1B1747', raised: '#1B1747', shadow: 'none', jelliBg: '#0B1A4A', sel: '#FFF8EE', selInk: '#0E0B2B', chip: '#2A255F' }
      : { bg: '#FBF7F1', ink: '#1E1A3A', muted: '#5E5975', surf: '#F1EBE2', raised: '#FFFFFF', shadow: '0 1px 0 rgba(30,26,58,0.05), 0 8px 22px rgba(30,26,58,0.07)', jelliBg: '#2A52DB', sel: '#1E1A3A', selInk: '#FFF8EE', chip: '#F1EBE2' };
    const trig = ['Coffee', 'Stress', 'More…'].map((label, i) => ({ label, pressed: i === 0 ? 'true' : 'false', style: i === 0 ? `background: ${t.sel}; color: ${t.selInk}` : `background: ${t.chip}; color: ${t.ink}` }));
    const plans = ['take a short walk', 'switch to tea for a week', 'have it somewhere new', 'open Craving SOS'].map((label, i) => ({
      label, pressed: i === 2 ? 'true' : 'false',
      style: i === 2 ? `background: ${t.sel}; color: ${t.selInk}` : `background: ${t.chip}; color: ${t.ink}`,
      ring: i === 2 ? 'background: #2FD08A; box-shadow: inset 0 0 0 6px #2FD08A' : `box-shadow: inset 0 0 0 2px ${t.muted}`
    }));
    return { t, trig, plans, motionStr: String(motion), a1: a(0), a2: a(1), a3: a(2), a5: a(4) };
  }
}
</script>
</body>
</html>
````

### `F16CheckIn.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Evening check-in</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&amp;family=DM+Sans:wght@400;500;600;700&amp;display=swap">
<style>
body{margin:0}
</style>
</helmet>
<div style="width: 390px; height: 844px; box-sizing: border-box; background: {{t.bg}}; color: #FFF8EE; position: relative; overflow: hidden; font-family: 'DM Sans', system-ui, sans-serif; display: flex; flex-direction: column">
  <div style="position: relative; height: 250px; flex: none">
    <div style="position: absolute; left: 0; top: 0; {{a0}}"><dc-import name="Hero2" scene="night" clarity="28" h="250" edge="{{t.bg}}" animate="{{motionStr}}" hint-size="390px,250px"></dc-import></div>
    <div style="position: absolute; left: 125px; top: 70px; {{gIn}}"><dc-import name="Glim2" mood="{{gMood}}" stage="1" animate="{{motionStr}}" size="140" hint-size="140px,140px"></dc-import></div>
    <a href="F08Today.dc.html" aria-label="Close" style="position: absolute; right: 10px; top: 46px; width: 44px; height: 44px; border-radius: 99px; background: rgba(14,11,43,0.5); color: #FFF8EE; display: flex; align-items: center; justify-content: center"><svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" aria-hidden="true"><path d="M6 6l12 12M18 6L6 18"></path></svg></a>
  </div>

  <div style="padding: 4px 24px 0 24px; display: flex; flex-direction: column; gap: 8px">
    <div style="font-size: 14px; font-weight: 700; color: {{t.muted}}; {{a1}}">Sunday check-in · Day 3</div>
    <h1 style="margin: 0; font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 32px; line-height: 1.08; letter-spacing: -1px; {{a2}}">{{headline}}</h1>
    <p style="margin: 0; font-size: 16px; line-height: 1.5; color: {{t.muted}}; {{a3}}">{{line}}</p>
  </div>

  <div style="margin: 14px 20px 0 20px; height: 52px; box-sizing: border-box; background: {{t.card}}; border-radius: 16px; padding: 0 6px 0 14px; display: flex; align-items: center; gap: 8px; font-size: 14px; {{a4}}">
    <span style="flex: 1">From today's SOS: <b>{{rode}} of {{cravings}} waves ridden out</b></span>
    <a href="#" style="height: 44px; display: flex; align-items: center; padding: 0 10px; color: #FFF8EE; font-weight: 700">Edit</a>
  </div>

  <div style="padding: 16px 20px 0 20px; display: flex; flex-direction: column; gap: 10px; {{a5}}">
    <div style="font-size: 16px; font-weight: 700">How are you feeling tonight?</div>
    <div style="display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 8px" role="radiogroup" aria-label="Mood">
      <sc-for list="{{moods}}" as="m" hint-placeholder-count="4">
        <button role="radio" aria-checked="{{m.on}}" style="height: 84px; border: 0; border-radius: 20px; font-family: 'DM Sans', sans-serif; font-size: 14px; font-weight: 700; cursor: pointer; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 6px; {{m.style}}">
          <svg width="32" height="32" viewBox="0 0 32 32" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" aria-hidden="true"><circle cx="16" cy="16" r="13"></circle><circle cx="11.5" cy="13" r="1.4" fill="currentColor" stroke="none"></circle><circle cx="20.5" cy="13" r="1.4" fill="currentColor" stroke="none"></circle><path d="{{m.mouth}}"></path></svg>
          {{m.label}}
        </button>
      </sc-for>
    </div>
  </div>

  <div style="margin-top: auto; padding: 0 22px 18px 22px; display: flex; flex-direction: column; gap: 4px; {{a6}}">
    <a href="F17WindDown.dc.html" style="height: 58px; border-radius: 99px; background: #FFF8EE; color: {{t.btnInk}}; font-weight: 700; font-size: 17px; text-decoration: none; display: flex; align-items: center; justify-content: center; box-shadow: 0 6px 0 rgba(0,0,0,0.25)">{{cta}}</a>
    <p style="margin: 0; text-align: center; font-size: 12px; color: {{t.muted}}">Your day ends at 3:00 am · <a href="#" style="color: #FFF8EE; font-weight: 700">change</a></p>
  </div>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"theme":{"editor":"enum","options":["light","dark"],"default":"light"},"cravings":{"editor":"int","min":0,"max":12,"default":3},"rode":{"editor":"int","min":0,"max":12,"default":3},"motion":{"editor":"boolean","default":true},"replay":{"editor":"boolean","default":true},"$preview":{"width":390,"height":844}}'>
class Component extends DCLogic {
  componentDidMount() { this.play(); }
  componentWillUnmount() { (this.timers || []).forEach(clearTimeout); }
  play() {
    (this.timers || []).forEach(clearTimeout);
    this.timers = [];
    this.setState({ on: false, pick: -1 });
    this.timers.push(setTimeout(() => this.setState({ on: true }), 300));
    this.timers.push(setTimeout(() => this.setState({ pick: 2 }), 2800));
    if (String(this.props.replay ?? true) !== 'false') this.timers.push(setTimeout(() => this.play(), 10000));
  }
  renderVals() {
    const dark = (this.props.theme ?? 'light') === 'dark';
    const motion = String(this.props.motion ?? true) !== 'false';
    const s = this.state || {};
    const on = !motion || Boolean(s.on);
    const pick = motion ? (s.pick ?? -1) : 2;
    const ease = 'cubic-bezier(.2,.7,.2,1)';
    const a = (i) => `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 18}px); transition: opacity 600ms ${ease} ${i * 90}ms, transform 600ms ${ease} ${i * 90}ms`;
    const t = dark
      ? { bg: '#140E3A', muted: '#B8B3D9', card: 'rgba(255,255,255,0.08)', chip: 'rgba(255,255,255,0.08)', btnInk: '#140E3A' }
      : { bg: '#4A3596', muted: '#D2C8FF', card: 'rgba(255,255,255,0.12)', chip: 'rgba(255,255,255,0.12)', btnInk: '#4A3596' };
    const cr = Math.max(0, Number(this.props.cravings ?? 3));
    const rode = Math.min(cr, Math.max(0, Number(this.props.rode ?? 3)));
    let headline, line, cta;
    if (cr === 0) { headline = 'A quiet day. Those count too.'; line = 'No waves today. Your brain is learning that nothing is missing.'; cta = 'Save and rest'; }
    else if (rode === cr) { headline = `${rode} of ${cr} waves. All yours.`; line = 'Including your coffee wave this morning. You breathed slower each time.'; cta = 'Save and rest'; }
    else { headline = 'Today was hard. You’re still here.'; line = `You rode ${rode} of ${cr}. Want one small plan for tomorrow’s coffee wave?`; cta = 'Make a plan for tomorrow'; }
    const mouths = ['M10.5 22.5c3-3 8-3 11 0', 'M11 21h10', 'M10.5 19.5c3 3 8 3 11 0', 'M9.5 18.5c3 5 10 5 13 0'];
    const moods = ['Rough', 'Okay', 'Good', 'Proud'].map((label, i) => {
      const sel = pick === i;
      return { label, mouth: mouths[i], on: sel ? 'true' : 'false', style: `background: ${sel ? '#FFF8EE' : t.chip}; color: ${sel ? t.btnInk : '#FFF8EE'}; transition: background 250ms, color 250ms` };
    });
    return {
      t, moods, headline, line, cta, cravings: String(cr), rode: String(rode), motionStr: String(motion),
      gMood: pick === 2 ? 'cheer' : 'calm',
      a0: `opacity: ${on ? 1 : 0}; transition: opacity 600ms ${ease}`,
      gIn: `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : -40}px); transition: opacity 900ms ${ease}, transform 900ms cubic-bezier(.2,.8,.2,1)`,
      a1: a(3), a2: a(4), a3: a(5), a4: a(6), a5: a(7), a6: a(8)
    };
  }
}
</script>
</body>
</html>
````

### `F17WindDown.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Wind down</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&amp;family=DM+Sans:wght@400;500;600;700&amp;display=swap">
<style>
body{margin:0}
</style>
</helmet>
<div style="width: 390px; height: 844px; box-sizing: border-box; background: {{t.bg}}; color: #FFF8EE; position: relative; overflow: hidden; font-family: 'DM Sans', system-ui, sans-serif">
  <div style="position: absolute; left: 0; top: 0; {{a0}}"><dc-import name="Hero2" scene="night" clarity="28" h="230" edge="{{t.bg}}" animate="{{motionStr}}" hint-size="390px,230px"></dc-import></div>
  <div style="position: absolute; left: 125px; top: 60px; {{gIn}}"><dc-import name="Glim2" mood="sleepy" stage="1" animate="{{motionStr}}" size="140" hint-size="140px,140px"></dc-import></div>

  <div style="position: absolute; left: 0; right: 0; top: 222px; padding: 0 22px; display: flex; flex-direction: column; gap: 8px">
    <div style="font-size: 14px; font-weight: 700; color: {{t.muted}}; {{a1}}">Check-in saved</div>
    <h1 style="margin: 0; font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 32px; letter-spacing: -1px; {{a2}}">Rest well.</h1>
    <p style="margin: 0; font-size: 16px; line-height: 1.5; color: {{t.muted}}; {{a3}}">Tomorrow's pledge will be here in the morning. If tonight feels restless, breathe with me.</p>

    <a href="#" style="margin-top: 6px; text-decoration: none; color: {{t.recInk}}; background: #FFF8EE; border-radius: 22px; padding: 14px 16px; display: flex; align-items: center; gap: 12px; {{a4}}">
      <span style="flex: 1; display: flex; flex-direction: column; gap: 2px"><span style="font-size: 12px; font-weight: 700; letter-spacing: 0.8px">FOR TONIGHT · 3 MIN</span><span style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 700; font-size: 19px">Slow breathing with Glim</span><span style="font-size: 14px">In for 4, out for 6. The same rhythm as SOS.</span></span>
      <span style="width: 44px; height: 44px; border-radius: 99px; background: {{t.recInk}}; color: #FFF8EE; display: flex; align-items: center; justify-content: center; flex: none"><svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true"><path d="M8 5v14l11-7z"></path></svg></span>
    </a>

    <div style="background: {{t.card}}; border-radius: 18px; padding: 2px 14px; display: flex; flex-direction: column; {{a5}}">
      <sc-for list="{{tools}}" as="x" hint-placeholder-count="4">
        <a href="#" style="min-height: 56px; display: flex; flex-direction: column; justify-content: center; gap: 2px; text-decoration: none; color: #FFF8EE; {{x.line}}"><span style="font-size: 16px; font-weight: 700">{{x.title}}</span><span style="font-size: 14px; color: {{t.muted}}">{{x.body}}</span></a>
      </sc-for>
    </div>
    <p style="margin: 2px 0 0 0; font-size: 12px; line-height: 1.5; color: {{t.muted}}; {{a6}}">These tools aren't a substitute for professional help. If things feel like too much, <a href="#" style="color: #FFF8EE; font-weight: 700">find a helpline near you</a>.</p>
  </div>

  <div style="position: absolute; left: 0; bottom: 0"><dc-import name="Nav2" active="evening" theme="dark" hint-size="390px,100px"></dc-import></div>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"theme":{"editor":"enum","options":["light","dark"],"default":"light"},"motion":{"editor":"boolean","default":true},"replay":{"editor":"boolean","default":true},"$preview":{"width":390,"height":844}}'>
class Component extends DCLogic {
  componentDidMount() { this.play(); }
  componentWillUnmount() { (this.timers || []).forEach(clearTimeout); }
  play() {
    (this.timers || []).forEach(clearTimeout);
    this.timers = [];
    this.setState({ on: false });
    this.timers.push(setTimeout(() => this.setState({ on: true }), 300));
    if (String(this.props.replay ?? true) !== 'false') this.timers.push(setTimeout(() => this.play(), 10000));
  }
  renderVals() {
    const dark = (this.props.theme ?? 'light') === 'dark';
    const motion = String(this.props.motion ?? true) !== 'false';
    const on = !motion || Boolean(this.state && this.state.on);
    const ease = 'cubic-bezier(.2,.7,.2,1)';
    const a = (i) => `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 18}px); transition: opacity 600ms ${ease} ${i * 90}ms, transform 600ms ${ease} ${i * 90}ms`;
    const t = dark
      ? { bg: '#140E3A', muted: '#B8B3D9', card: 'rgba(255,255,255,0.07)', line: 'rgba(255,255,255,0.1)', recInk: '#140E3A' }
      : { bg: '#4A3596', muted: '#D2C8FF', card: 'rgba(255,255,255,0.12)', line: 'rgba(255,255,255,0.14)', recInk: '#4A3596' };
    const tools = [
      ['Box breathing', 'In, hold, out, hold. Four counts each.'],
      ['5-4-3-2-1', 'Name what you can see, feel, hear, smell and taste.'],
      ['Notice and name', 'Spot the thought, give it a label, let it be.'],
      ['Longer out-breath', 'In for 4, hold for 7, out for 8.']
    ].map(([title, body], i) => ({ title, body, line: i ? `border-top: 1px solid ${t.line}` : '' }));
    return {
      t, tools, motionStr: String(motion),
      a0: `opacity: ${on ? 1 : 0}; transition: opacity 600ms ${ease}`,
      gIn: `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : -30}px); transition: opacity 900ms ${ease}, transform 900ms cubic-bezier(.2,.8,.2,1)`,
      a1: a(3), a2: a(4), a3: a(5), a4: a(6), a5: a(7), a6: a(8)
    };
  }
}
</script>
</body>
</html>
````

### `F18Finale.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Week 4 complete</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&amp;family=DM+Sans:wght@400;500;600;700&amp;display=swap">
<style>
body{margin:0}
</style>
</helmet>
<div style="width: 390px; height: 844px; box-sizing: border-box; background: {{t.bg}}; color: {{t.ink}}; position: relative; overflow: hidden; font-family: 'DM Sans', system-ui, sans-serif; display: flex; flex-direction: column">
  <div style="position: relative; height: 340px; flex: none">
    <div style="position: absolute; left: 0; top: 0; {{a0}}"><dc-import name="Hero2" scene="dawn" clarity="100" h="340" edge="{{t.bg}}" animate="{{motionStr}}" hint-size="390px,340px"></dc-import></div>
    <svg width="390" height="340" viewBox="0 0 390 340" aria-hidden="true" style="position: absolute; left: 0; top: 0">
      <rect x="40" y="-20" width="8" height="14" rx="2" fill="#FF7A55"><animate attributeName="y" values="{{c1}}" dur="3.2s" repeatCount="indefinite"></animate></rect>
      <rect x="96" y="-20" width="7" height="12" rx="2" fill="#2A52DB"><animate attributeName="y" values="{{c1}}" dur="4s" begin="0.6s" repeatCount="indefinite"></animate></rect>
      <rect x="150" y="-20" width="8" height="8" rx="4" fill="#4A3596"><animate attributeName="y" values="{{c1}}" dur="3.6s" begin="1.1s" repeatCount="indefinite"></animate></rect>
      <rect x="214" y="-20" width="7" height="13" rx="2" fill="#0F6E43"><animate attributeName="y" values="{{c1}}" dur="3.4s" begin="0.3s" repeatCount="indefinite"></animate></rect>
      <rect x="270" y="-20" width="8" height="8" rx="4" fill="#FF8FB8"><animate attributeName="y" values="{{c1}}" dur="4.2s" begin="1.6s" repeatCount="indefinite"></animate></rect>
      <rect x="330" y="-20" width="7" height="12" rx="2" fill="#FFF8EE"><animate attributeName="y" values="{{c1}}" dur="3.8s" begin="0.9s" repeatCount="indefinite"></animate></rect>
    </svg>
    <div style="position: absolute; left: 125px; top: 70px; {{x}}"><dc-import name="Xero" mood="cheer" stage="4" animate="{{motionStr}}" size="140" hint-size="140px,140px"></dc-import></div>
    <div style="position: absolute; left: 22px; top: 196px; {{j}}"><dc-import name="Jelli" mood="cheer" stage="4" animate="{{motionStr}}" size="88" hint-size="88px,88px"></dc-import></div>
    <div style="position: absolute; right: 22px; top: 190px; {{g}}"><dc-import name="Glim2" mood="cheer" stage="4" animate="{{motionStr}}" size="88" hint-size="88px,88px"></dc-import></div>
  </div>

  <div style="padding: 4px 26px 0 26px; text-align: center; display: flex; flex-direction: column; gap: 8px">
    <div style="font-size: 14px; font-weight: 700; color: {{t.muted}}; {{a1}}">Week 4 · program complete · Thu 3 Dec</div>
    <h1 style="margin: 0; font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 40px; line-height: 1.02; letter-spacing: -1.2px; {{a2}}">28 days.<br>Clear skies.</h1>
  </div>

  <div style="margin: 16px 20px 0 20px; display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 8px; {{a3}}">
    <div style="background: {{t.card}}; border-radius: 18px; padding: 12px 8px; text-align: center"><div style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 24px">{{n1}}</div><div style="font-size: 12px; font-weight: 600; color: {{t.muted}}">days clear · Xero</div></div>
    <div style="background: {{t.card}}; border-radius: 18px; padding: 12px 8px; text-align: center"><div style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 24px">{{n2}}</div><div style="font-size: 12px; font-weight: 600; color: {{t.muted}}">waves ridden · Jelli</div></div>
    <div style="background: {{t.card}}; border-radius: 18px; padding: 12px 8px; text-align: center"><div style="font-family: 'Bricolage Grotesque', sans-serif; font-weight: 800; font-size: 24px">{{n3}}</div><div style="font-size: 12px; font-weight: 600; color: {{t.muted}}">check-ins · Glim</div></div>
  </div>
  <p style="margin: 10px 26px 0 26px; text-align: center; font-size: 16px; line-height: 1.5; {{a4}}"><b>${{n4}} kept</b> and <b>{{n5}} cigarettes</b> not smoked. For Maya and the park.</p>

  <div style="margin: 12px 20px 0 20px; background: {{t.card}}; border-radius: 18px; padding: 12px 14px; display: flex; flex-direction: column; gap: 2px; {{a5}}">
    <span style="font-size: 12px; font-weight: 700; color: {{t.green}}">STARTING NOW · 2 WEEKS TO 3 MONTHS</span>
    <span style="font-size: 16px; font-weight: 700">Circulation and lung function improve</span>
    <span style="font-size: 12px; color: {{t.muted}}">Source: American Cancer Society</span>
  </div>

  <div style="margin-top: auto; padding: 0 22px 22px 22px; display: flex; gap: 10px; {{a6}}">
    <a href="F08Today.dc.html" style="flex: 1; height: 58px; border-radius: 99px; background: {{t.btn}}; color: {{t.btnInk}}; font-weight: 700; font-size: 17px; text-decoration: none; display: flex; align-items: center; justify-content: center; box-shadow: 0 6px 0 rgba(0,0,0,0.2)">Keep going</a>
    <a href="#" style="height: 58px; padding: 0 20px; border-radius: 99px; background: {{t.card}}; color: {{t.ink}}; font-weight: 700; font-size: 16px; text-decoration: none; display: flex; align-items: center">Share my card</a>
  </div>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"theme":{"editor":"enum","options":["light","dark"],"default":"light"},"motion":{"editor":"boolean","default":true},"replay":{"editor":"boolean","default":true},"$preview":{"width":390,"height":844}}'>
class Component extends DCLogic {
  componentDidMount() { this.play(); }
  componentWillUnmount() { (this.timers || []).forEach(clearTimeout); clearInterval(this.iv); }
  play() {
    (this.timers || []).forEach(clearTimeout); clearInterval(this.iv);
    this.timers = [];
    this.setState({ on: false, crew: 0, k: 0 });
    this.timers.push(setTimeout(() => this.setState({ on: true, crew: 1 }), 300));
    this.timers.push(setTimeout(() => this.setState({ crew: 2 }), 900));
    this.timers.push(setTimeout(() => this.setState({ crew: 3 }), 1400));
    this.timers.push(setTimeout(() => {
      const t0 = Date.now();
      this.iv = setInterval(() => {
        const p = Math.min(1, (Date.now() - t0) / 900);
        this.setState({ k: 1 - Math.pow(1 - p, 3) });
        if (p >= 1) clearInterval(this.iv);
      }, 30);
    }, 1800));
    if (String(this.props.replay ?? true) !== 'false') this.timers.push(setTimeout(() => this.play(), 11000));
  }
  renderVals() {
    const dark = (this.props.theme ?? 'light') === 'dark';
    const motion = String(this.props.motion ?? true) !== 'false';
    const s = this.state || {};
    const on = !motion || Boolean(s.on);
    const crew = motion ? (s.crew || 0) : 3;
    const k = motion ? (s.k || 0) : 1;
    const ease = 'cubic-bezier(.2,.7,.2,1)';
    const spring = 'cubic-bezier(.3,1.4,.5,1)';
    const a = (i) => `opacity: ${on ? 1 : 0}; transform: translateY(${on ? 0 : 18}px); transition: opacity 600ms ${ease} ${i * 90}ms, transform 600ms ${ease} ${i * 90}ms`;
    const enter = (show, dx, dy) => `opacity: ${show ? 1 : 0}; transform: translate(${show ? 0 : dx}px, ${show ? 0 : dy}px) scale(${show ? 1 : 0.7}); transition: opacity 500ms ${ease}, transform 800ms ${spring}`;
    const t = dark
      ? { bg: '#241433', ink: '#FFF8EE', muted: '#E0C8E8', card: 'rgba(255,255,255,0.08)', green: '#2FD08A', btn: '#FFD966', btnInk: '#241433' }
      : { bg: '#FFD966', ink: '#1E1A3A', muted: '#5A4A10', card: 'rgba(255,248,238,0.7)', green: '#0F6E43', btn: '#1E1A3A', btnInk: '#FFF8EE' };
    const n = (v) => Math.round(v * k).toLocaleString('en-US');
    return {
      t, motionStr: String(motion),
      x: enter(crew >= 1, 0, 80), j: enter(crew >= 2, -80, 30), g: enter(crew >= 3, 80, 30),
      n1: n(28), n2: n(61), n3: n(26), n4: n(196), n5: n(336),
      c1: motion ? '-20;360' : '-40;-40',
      a0: `opacity: ${on ? 1 : 0}; transition: opacity 600ms ${ease}`,
      a1: a(8), a2: a(9), a3: a(10), a4: a(11), a5: a(12), a6: a(13)
    };
  }
}
</script>
</body>
</html>
````

### `FDarkA.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>v4 in dark mode · part 1</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&amp;family=DM+Sans:wght@400;500;600;700&amp;display=swap">
<style>
body{margin:0}
</style>
</helmet>
<div style="width: 4150px; height: 844px; display: flex; gap: 80px">
  <div style="width: 390px; height: 844px; border-radius: 44px; overflow: hidden; flex: none"><dc-import name="F01Breathe" theme="dark" hint-size="390px,844px"></dc-import></div>
  <div style="width: 390px; height: 844px; border-radius: 44px; overflow: hidden; flex: none"><dc-import name="F02Welcome" theme="dark" hint-size="390px,844px"></dc-import></div>
  <div style="width: 390px; height: 844px; border-radius: 44px; overflow: hidden; flex: none"><dc-import name="F03Chat" theme="dark" hint-size="390px,844px"></dc-import></div>
  <div style="width: 390px; height: 844px; border-radius: 44px; overflow: hidden; flex: none"><dc-import name="F04QuitDay" theme="dark" hint-size="390px,844px"></dc-import></div>
  <div style="width: 390px; height: 844px; border-radius: 44px; overflow: hidden; flex: none"><dc-import name="F05Crew" theme="dark" hint-size="390px,844px"></dc-import></div>
  <div style="width: 390px; height: 844px; border-radius: 44px; overflow: hidden; flex: none"><dc-import name="F06Plan" theme="dark" hint-size="390px,844px"></dc-import></div>
  <div style="width: 390px; height: 844px; border-radius: 44px; overflow: hidden; flex: none"><dc-import name="F07Remind" theme="dark" hint-size="390px,844px"></dc-import></div>
  <div style="width: 390px; height: 844px; border-radius: 44px; overflow: hidden; flex: none"><dc-import name="F08Today" theme="dark" hint-size="390px,844px"></dc-import></div>
  <div style="width: 390px; height: 844px; border-radius: 44px; overflow: hidden; flex: none"><dc-import name="F09Pledge" theme="dark" hint-size="390px,844px"></dc-import></div>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"$preview":{"width":4150,"height":844}}'>
class Component extends DCLogic {
  renderVals() {
    return {};
  }
}
</script>
</body>
</html>
````

### `FDarkB.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>v4 in dark mode · part 2</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,500;12..96,700;12..96,800&amp;family=DM+Sans:wght@400;500;600;700&amp;display=swap">
<style>
body{margin:0}
</style>
</helmet>
<div style="width: 4150px; height: 844px; display: flex; gap: 80px">
  <div style="width: 390px; height: 844px; border-radius: 44px; overflow: hidden; flex: none"><dc-import name="F10Program" theme="dark" hint-size="390px,844px"></dc-import></div>
  <div style="width: 390px; height: 844px; border-radius: 44px; overflow: hidden; flex: none"><dc-import name="F11Lesson" theme="dark" hint-size="390px,844px"></dc-import></div>
  <div style="width: 390px; height: 844px; border-radius: 44px; overflow: hidden; flex: none"><dc-import name="F12Progress" theme="dark" hint-size="390px,844px"></dc-import></div>
  <div style="width: 390px; height: 844px; border-radius: 44px; overflow: hidden; flex: none"><dc-import name="F13SOS" theme="dark" hint-size="390px,844px"></dc-import></div>
  <div style="width: 390px; height: 844px; border-radius: 44px; overflow: hidden; flex: none"><dc-import name="F14Passed" theme="dark" hint-size="390px,844px"></dc-import></div>
  <div style="width: 390px; height: 844px; border-radius: 44px; overflow: hidden; flex: none"><dc-import name="F15Slip" theme="dark" hint-size="390px,844px"></dc-import></div>
  <div style="width: 390px; height: 844px; border-radius: 44px; overflow: hidden; flex: none"><dc-import name="F16CheckIn" theme="dark" hint-size="390px,844px"></dc-import></div>
  <div style="width: 390px; height: 844px; border-radius: 44px; overflow: hidden; flex: none"><dc-import name="F17WindDown" theme="dark" hint-size="390px,844px"></dc-import></div>
  <div style="width: 390px; height: 844px; border-radius: 44px; overflow: hidden; flex: none"><dc-import name="F18Finale" theme="dark" hint-size="390px,844px"></dc-import></div>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"$preview":{"width":4150,"height":844}}'>
class Component extends DCLogic {
  renderVals() {
    return {};
  }
}
</script>
</body>
</html>
````

### `Xero.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Xero character</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<style>
body{margin:0}
</style>
</helmet>
<svg width="{{size}}" height="{{size}}" viewBox="0 0 200 200" role="img" aria-label="Xero, {{mood}}" style="display: block">
  <defs><clipPath id="xeroHole"><ellipse cx="100" cy="138" rx="21" ry="29"></ellipse></clipPath></defs>
  <ellipse cx="100" cy="192" rx="48" ry="6" fill="#000000" opacity="0.12"></ellipse>
  <g>
    <animateTransform attributeName="transform" type="translate" values="{{hopV}}" keyTimes="{{hopKT}}" keySplines="{{hopKS}}" calcMode="spline" dur="{{hopDur}}" repeatCount="indefinite"></animateTransform>
    <g transform="translate(100 190)">
      <g>
        <animateTransform attributeName="transform" type="scale" values="{{bodyV}}" keyTimes="{{bodyKT}}" keySplines="{{bodyKS}}" calcMode="spline" dur="{{bodyDur}}" repeatCount="indefinite"></animateTransform>
        <g>
          <animateTransform attributeName="transform" type="rotate" values="{{swayV}}" keyTimes="{{swayKT}}" keySplines="{{swayKS}}" calcMode="spline" dur="{{swayDur}}" repeatCount="indefinite"></animateTransform>
          <g transform="translate(-100 -190)">
            <ellipse cx="100" cy="138" rx="21" ry="29" fill="#BFD7FF"></ellipse>
            <g clip-path="url(#xeroHole)">
              <circle cx="100" cy="{{sunY}}" r="11" fill="#FFC93C"><animate attributeName="cy" values="{{sunV}}" keyTimes="{{sunKT}}" keySplines="{{sunKS}}" calcMode="spline" dur="{{sunDur}}" repeatCount="indefinite"></animate></circle>
              <path d="M76 160 C90 152 110 156 124 150 L124 172 L76 172 Z" fill="#3FB37F"></path>
            </g>
            <ellipse cx="84" cy="188" rx="12" ry="7" fill="#C9542F"></ellipse>
            <ellipse cx="116" cy="188" rx="12" ry="7" fill="#C9542F"></ellipse>
            <path d="{{armL}}" fill="none" stroke="#FF7155" stroke-width="12" stroke-linecap="round"></path>
            <path d="{{armR}}" fill="none" stroke="#FF7155" stroke-width="12" stroke-linecap="round"></path>
            <path fill-rule="evenodd" d="M100 34 C138 34 166 68 166 112 C166 156 138 188 100 188 C62 188 34 156 34 112 C34 68 62 34 100 34 Z M100 109 C112 109 121 121 121 138 C121 155 112 167 100 167 C88 167 79 155 79 138 C79 121 88 109 100 109 Z" fill="#FF7155"></path>
            <path d="M136 52 C156 70 166 92 166 112 C166 156 138 188 100 188 C126 178 146 150 146 112 C146 88 142 68 136 52 Z" fill="#E85A3E"></path>
            <path d="M58 82 C62 66 74 52 90 46" fill="none" stroke="#FFB09C" stroke-width="6" stroke-linecap="round"></path>
            <g opacity="{{rays}}" stroke="#FFC93C" stroke-width="3" stroke-linecap="round"><path d="M100 24 l0 -10"></path><path d="M146 40 l7 -7"></path><path d="M54 40 l-7 -7"></path></g>
            <circle cx="72" cy="92" r="7" fill="#FFB09C" opacity="0.8"></circle>
            <circle cx="128" cy="92" r="7" fill="#FFB09C" opacity="0.8"></circle>
            <g transform="{{eyeIn}}"><g><animateTransform attributeName="transform" type="scale" values="{{blink}}" keyTimes="0;0.92;0.96;1" dur="4.5s" repeatCount="indefinite"></animateTransform><g transform="{{eyeOut}}">
              <path d="{{eyeL}}" fill="none" stroke="#24163A" stroke-width="{{eyeW}}" stroke-linecap="round"></path>
              <path d="{{eyeR}}" fill="none" stroke="#24163A" stroke-width="{{eyeW}}" stroke-linecap="round"></path>
            </g></g></g>
            <path d="{{mouth}}" fill="{{mouthFill}}" stroke="#24163A" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"></path>
          </g>
        </g>
      </g>
    </g>
  </g>
  <g opacity="{{sparkle}}" stroke="#24163A" stroke-width="3" stroke-linecap="round"><path d="M26 64 l0 12 M20 70 l12 0"></path><path d="M174 70 l0 10 M169 75 l10 0"></path></g>
  <g opacity="{{zzz}}" fill="none" stroke="#24163A" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><animateTransform attributeName="transform" type="translate" values="{{floatV}}" dur="3s" repeatCount="indefinite"></animateTransform><path d="M150 40 h12 l-12 12 h12"></path><path d="M170 20 h8 l-8 8 h8"></path></g>
  <g opacity="{{breeze}}" fill="none" stroke="#24163A" stroke-width="3" stroke-linecap="round"><animateTransform attributeName="transform" type="translate" values="{{driftV}}" dur="5s" repeatCount="indefinite"></animateTransform><path d="M172 100 q8 -5 16 0"></path><path d="M176 112 q6 -4 12 0"></path></g>
</svg>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"mood":{"editor":"enum","options":["hello","calm","breathe","cheer","sleepy"],"default":"hello"},"stage":{"editor":"int","min":1,"max":4,"default":2},"animate":{"editor":"boolean","default":true},"size":{"editor":"int","min":60,"max":400,"default":240},"$preview":{"width":240,"height":240}}'>
class Component extends DCLogic {
  renderVals() {
    const mood = this.props.mood ?? 'hello';
    const stage = Number(this.props.stage ?? 2);
    const size = Number(this.props.size ?? 240);
    const on = String(this.props.animate ?? true) !== 'false';
    const C = 100, L = 86, R = 114, y = 78, ink = '#24163A';
    const closed = { eyeL: `M${L-6} ${y} Q${L} ${y+5} ${L+6} ${y}`, eyeR: `M${R-6} ${y} Q${R} ${y+5} ${R+6} ${y}`, eyeW: 3.5 };
    const faces = {
      hello: { eyeL: `M${L} ${y-3} L${L} ${y+3}`, eyeR: `M${R} ${y-3} L${R} ${y+3}`, eyeW: 8, mouth: `M${C-8} ${y+14} Q${C} ${y+22} ${C+8} ${y+14}`, mouthFill: 'none' },
      calm: { ...closed, mouth: `M${C-5} ${y+15} Q${C} ${y+19} ${C+5} ${y+15}`, mouthFill: 'none' },
      breathe: { ...closed, mouth: `M${C} ${y+12} C${C+6} ${y+12} ${C+6} ${y+23} ${C} ${y+23} C${C-6} ${y+23} ${C-6} ${y+12} ${C} ${y+12} Z`, mouthFill: ink },
      cheer: { eyeL: `M${L-6} ${y+2} Q${L} ${y-5} ${L+6} ${y+2}`, eyeR: `M${R-6} ${y+2} Q${R} ${y-5} ${R+6} ${y+2}`, eyeW: 3.5, mouth: `M${C-10} ${y+12} L${C+10} ${y+12} Q${C} ${y+28} ${C-10} ${y+12} Z`, mouthFill: ink },
      sleepy: { eyeL: `M${L-6} ${y+1} L${L+6} ${y+1}`, eyeR: `M${R-6} ${y+1} L${R+6} ${y+1}`, eyeW: 3.5, mouth: `M${C-3} ${y+16} Q${C} ${y+18} ${C+3} ${y+16}`, mouthFill: 'none' }
    };
    const f = faces[mood] ?? faces.hello;
    const ks = (n) => Array(n).fill('0.45 0 0.55 1').join(';');
    const A = (vals, kt, dur) => ({ v: (on ? vals : vals.map(() => vals[0])).join(';'), kt: kt.join(';'), ks: ks(kt.length - 1), dur: dur + 's' });
    const body = ({
      hello: A(['1 1', '1.025 0.985', '1 1'], [0, 0.5, 1], 5),
      calm: A(['1 1', '1.02 0.99', '1 1'], [0, 0.5, 1], 6),
      breathe: A(['1 1', '1.07 1.07', '1 1'], [0, 0.4, 1], 10),
      cheer: A(['1 1', '1.08 0.9', '0.96 1.06', '1 1', '1 1'], [0, 0.15, 0.35, 0.55, 1], 1.4),
      sleepy: A(['1 1', '1.015 0.99', '1 1'], [0, 0.5, 1], 7)
    })[mood] ?? A(['1 1', '1 1'], [0, 1], 1);
    const hop = mood === 'cheer' ? A(['0 0', '0 0', '0 -18', '0 0', '0 0'], [0, 0.15, 0.35, 0.55, 1], 1.4) : A(['0 0', '0 0'], [0, 1], 1);
    const sway = mood === 'sleepy' ? A(['-3', '3', '-3'], [0, 0.5, 1], 7) : A(['0', '0'], [0, 1], 1);
    const sunY = { 1: 168, 2: 156, 3: 142, 4: 128 }[stage] ?? 156;
    const sun = mood === 'breathe' ? A([`${sunY}`, `${sunY - 16}`, `${sunY}`], [0, 0.4, 1], 10) : A([`${sunY}`, `${sunY - 3}`, `${sunY}`], [0, 0.5, 1], 4);
    const up = mood === 'cheer';
    return {
      ...f, mood, size, sunY,
      bodyV: body.v, bodyKT: body.kt, bodyKS: body.ks, bodyDur: body.dur,
      hopV: hop.v, hopKT: hop.kt, hopKS: hop.ks, hopDur: hop.dur,
      swayV: sway.v, swayKT: sway.kt, swayKS: sway.ks, swayDur: sway.dur,
      sunV: sun.v, sunKT: sun.kt, sunKS: sun.ks, sunDur: sun.dur,
      eyeIn: `translate(${C} ${y})`, eyeOut: `translate(${-C} ${-y})`,
      blink: on && (mood === 'hello' || up) ? '1 1;1 1;1 0.1;1 1' : '1 1;1 1;1 1;1 1',
      floatV: on ? '0 0;5 -8;0 0' : '0 0;0 0;0 0',
      driftV: on ? '0 0;8 0;0 0' : '0 0;0 0;0 0',
      armL: up ? 'M38 112 C28 98 24 86 26 74' : 'M36 124 C26 132 22 142 24 152',
      armR: up ? 'M162 112 C172 98 176 86 174 74' : 'M164 124 C174 132 178 142 176 152',
      rays: stage >= 4 ? 1 : 0,
      sparkle: up ? 1 : 0,
      zzz: mood === 'sleepy' ? 1 : 0,
      breeze: mood === 'breathe' ? 1 : 0
    };
  }
}
</script>
</body>
</html>
````

### `Jelli.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Jelli character</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<style>
body{margin:0}
</style>
</helmet>
<svg width="{{size}}" height="{{size}}" viewBox="0 0 200 200" role="img" aria-label="Jelli, {{mood}}" style="display: block">
  <ellipse cx="100" cy="194" rx="34" ry="4" fill="#000000" opacity="0.08"></ellipse>
  <g opacity="{{bubbles}}" fill="none" stroke="#FFFFFF" stroke-width="2.5">
    <circle cx="160" cy="150" r="5"><animate attributeName="cy" values="{{bubV1}}" dur="4s" repeatCount="indefinite"></animate></circle>
    <circle cx="44" cy="130" r="3.5"><animate attributeName="cy" values="{{bubV2}}" dur="5s" begin="1s" repeatCount="indefinite"></animate></circle>
  </g>
  <g>
    <animateTransform attributeName="transform" type="translate" values="{{hopV}}" keyTimes="{{hopKT}}" keySplines="{{hopKS}}" calcMode="spline" dur="{{hopDur}}" repeatCount="indefinite"></animateTransform>
    <g opacity="{{crown}}">
      <path d="M100 18 l4 9 l9 1 l-7 6 l2 9 l-8 -5 l-8 5 l2 -9 l-7 -6 l9 -1 Z" fill="#FFC93C"></path>
    </g>
    <path d="{{tA1}}" fill="none" stroke="#F07188" stroke-width="5" stroke-linecap="round"><animate attributeName="d" values="{{tV1}}" dur="2.4s" repeatCount="indefinite"></animate></path>
    <path d="{{tA2}}" fill="none" stroke="#FF8FA3" stroke-width="5" stroke-linecap="round"><animate attributeName="d" values="{{tV2}}" dur="2.4s" begin="0.3s" repeatCount="indefinite"></animate></path>
    <path d="{{tA3}}" fill="none" stroke="#F07188" stroke-width="5" stroke-linecap="round"><animate attributeName="d" values="{{tV3}}" dur="2.4s" begin="0.6s" repeatCount="indefinite"></animate></path>
    <path d="{{tA4}}" fill="none" stroke="#FF8FA3" stroke-width="5" stroke-linecap="round"><animate attributeName="d" values="{{tV4}}" dur="2.4s" begin="0.9s" repeatCount="indefinite"></animate></path>
    <path d="{{armL}}" fill="none" stroke="#FFC2CD" stroke-width="10" stroke-linecap="round"></path>
    <path d="{{armR}}" fill="none" stroke="#FFC2CD" stroke-width="10" stroke-linecap="round"></path>
    <g transform="translate(100 44)">
      <g>
        <animateTransform attributeName="transform" type="scale" values="{{bodyV}}" keyTimes="{{bodyKT}}" keySplines="{{bodyKS}}" calcMode="spline" dur="{{bodyDur}}" repeatCount="indefinite"></animateTransform>
        <g>
          <animateTransform attributeName="transform" type="rotate" values="{{swayV}}" keyTimes="{{swayKT}}" keySplines="{{swayKS}}" calcMode="spline" dur="{{swayDur}}" repeatCount="indefinite"></animateTransform>
          <g transform="translate(-100 -44)">
            <path d="M42 112 C40 68 66 44 100 44 C134 44 160 68 158 112 C158 120 152 124 144 121 C136 128 126 128 118 121 C110 128 90 128 82 121 C74 128 64 128 56 121 C48 124 42 120 42 112 Z" fill="#FF8FA3"></path>
            <path d="M120 48 C146 58 160 82 158 112 C158 120 152 124 144 121 C148 94 140 68 120 48 Z" fill="#F07188"></path>
            <path d="M48 110 C70 116 130 116 152 110 C152 114 150 116 146 116 C120 122 80 122 54 116 C50 116 48 114 48 110 Z" fill="#FFB3C1"></path>
            <path d="M62 78 C66 62 78 52 94 48" fill="none" stroke="#FFD6DE" stroke-width="7" stroke-linecap="round"></path>
            <circle cx="62" cy="96" r="4" fill="#FFF1B8" opacity="{{g1}}"></circle>
            <circle cx="140" cy="88" r="4" fill="#FFF1B8" opacity="{{g2}}"></circle>
            <circle cx="132" cy="66" r="3" fill="#FFF1B8" opacity="{{g2}}"></circle>
            <circle cx="74" cy="64" r="3" fill="#FFF1B8" opacity="{{g3}}"></circle>
            <circle cx="148" cy="104" r="3" fill="#FFF1B8" opacity="{{g3}}"></circle>
            <circle cx="72" cy="104" r="7" fill="#FF6F8E" opacity="0.6"></circle>
            <circle cx="128" cy="104" r="7" fill="#FF6F8E" opacity="0.6"></circle>
            <g transform="{{eyeIn}}"><g><animateTransform attributeName="transform" type="scale" values="{{blink}}" keyTimes="0;0.92;0.96;1" dur="4.2s" repeatCount="indefinite"></animateTransform><g transform="{{eyeOut}}">
              <path d="{{eyeL}}" fill="none" stroke="#24163A" stroke-width="{{eyeW}}" stroke-linecap="round"></path>
              <path d="{{eyeR}}" fill="none" stroke="#24163A" stroke-width="{{eyeW}}" stroke-linecap="round"></path>
            </g></g></g>
            <path d="{{mouth}}" fill="{{mouthFill}}" stroke="#24163A" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"></path>
          </g>
        </g>
      </g>
    </g>
  </g>
  <g opacity="{{sparkle}}" stroke="#24163A" stroke-width="3" stroke-linecap="round"><path d="M24 60 l0 12 M18 66 l12 0"></path><path d="M176 56 l0 10 M171 61 l10 0"></path></g>
  <g opacity="{{zzz}}" fill="none" stroke="#24163A" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><animateTransform attributeName="transform" type="translate" values="{{floatV}}" dur="3s" repeatCount="indefinite"></animateTransform><path d="M154 30 h12 l-12 12 h12"></path><path d="M174 12 h8 l-8 8 h8"></path></g>
</svg>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"mood":{"editor":"enum","options":["hello","calm","breathe","cheer","sleepy"],"default":"hello"},"stage":{"editor":"int","min":1,"max":4,"default":2},"animate":{"editor":"boolean","default":true},"size":{"editor":"int","min":60,"max":400,"default":240},"$preview":{"width":240,"height":240}}'>
class Component extends DCLogic {
  renderVals() {
    const mood = this.props.mood ?? 'hello';
    const stage = Number(this.props.stage ?? 2);
    const size = Number(this.props.size ?? 240);
    const on = String(this.props.animate ?? true) !== 'false';
    const C = 100, L = 86, R = 114, y = 92, ink = '#24163A';
    const closed = { eyeL: `M${L-6} ${y} Q${L} ${y+5} ${L+6} ${y}`, eyeR: `M${R-6} ${y} Q${R} ${y+5} ${R+6} ${y}`, eyeW: 3.5 };
    const faces = {
      hello: { eyeL: `M${L} ${y-3} L${L} ${y+3}`, eyeR: `M${R} ${y-3} L${R} ${y+3}`, eyeW: 8, mouth: `M${C-8} ${y+14} Q${C} ${y+22} ${C+8} ${y+14}`, mouthFill: 'none' },
      calm: { ...closed, mouth: `M${C-5} ${y+15} Q${C} ${y+19} ${C+5} ${y+15}`, mouthFill: 'none' },
      breathe: { ...closed, mouth: `M${C} ${y+12} C${C+6} ${y+12} ${C+6} ${y+23} ${C} ${y+23} C${C-6} ${y+23} ${C-6} ${y+12} ${C} ${y+12} Z`, mouthFill: ink },
      cheer: { eyeL: `M${L-6} ${y+2} Q${L} ${y-5} ${L+6} ${y+2}`, eyeR: `M${R-6} ${y+2} Q${R} ${y-5} ${R+6} ${y+2}`, eyeW: 3.5, mouth: `M${C-10} ${y+12} L${C+10} ${y+12} Q${C} ${y+28} ${C-10} ${y+12} Z`, mouthFill: ink },
      sleepy: { eyeL: `M${L-6} ${y+1} L${L+6} ${y+1}`, eyeR: `M${R-6} ${y+1} L${R+6} ${y+1}`, eyeW: 3.5, mouth: `M${C-3} ${y+16} Q${C} ${y+18} ${C+3} ${y+16}`, mouthFill: 'none' }
    };
    const f = faces[mood] ?? faces.hello;
    const ks = (n) => Array(n).fill('0.45 0 0.55 1').join(';');
    const A = (vals, kt, dur) => ({ v: (on ? vals : vals.map(() => vals[0])).join(';'), kt: kt.join(';'), ks: ks(kt.length - 1), dur: dur + 's' });
    const body = ({
      hello: A(['1 1', '1.06 0.95', '1 1'], [0, 0.35, 1], 3),
      calm: A(['1 1', '1.04 0.97', '1 1'], [0, 0.4, 1], 5),
      breathe: A(['1 1', '1.12 1.05', '1 1'], [0, 0.4, 1], 10),
      cheer: A(['1 1', '1.12 0.88', '0.95 1.06', '1 1', '1 1'], [0, 0.15, 0.35, 0.55, 1], 1.2),
      sleepy: A(['1 1', '1.03 0.98', '1 1'], [0, 0.5, 1], 7)
    })[mood] ?? A(['1 1', '1 1'], [0, 1], 1);
    const hop = mood === 'cheer' ? A(['0 0', '0 0', '0 -18', '0 0', '0 0'], [0, 0.15, 0.35, 0.55, 1], 1.2) : A(['0 0', '0 -7', '0 0'], [0, 0.5, 1], mood === 'sleepy' ? 7 : 4);
    const sway = mood === 'sleepy' ? A(['-4', '4', '-4'], [0, 0.5, 1], 7) : A(['0', '0'], [0, 1], 1);
    const tent = (x) => {
      const a = `M${x} 122 C${x-6} 138 ${x+6} 152 ${x} 166 C${x-4} 174 ${x+2} 180 ${x-2} 186`;
      const b = `M${x} 122 C${x+6} 138 ${x-6} 152 ${x} 166 C${x+4} 174 ${x-2} 180 ${x+2} 186`;
      return { a, v: on ? `${a};${b};${a}` : `${a};${a};${a}` };
    };
    const t1 = tent(78), t2 = tent(93), t3 = tent(108), t4 = tent(123);
    const up = mood === 'cheer';
    return {
      ...f, mood, size,
      bodyV: body.v, bodyKT: body.kt, bodyKS: body.ks, bodyDur: body.dur,
      hopV: hop.v, hopKT: hop.kt, hopKS: hop.ks, hopDur: hop.dur,
      swayV: sway.v, swayKT: sway.kt, swayKS: sway.ks, swayDur: sway.dur,
      eyeIn: `translate(${C} ${y})`, eyeOut: `translate(${-C} ${-y})`,
      blink: on && (mood === 'hello' || up) ? '1 1;1 1;1 0.1;1 1' : '1 1;1 1;1 1;1 1',
      tA1: t1.a, tV1: t1.v, tA2: t2.a, tV2: t2.v, tA3: t3.a, tV3: t3.v, tA4: t4.a, tV4: t4.v,
      armL: up ? 'M56 118 C42 106 38 92 44 78' : 'M58 120 C50 136 60 150 52 166',
      armR: up ? 'M144 118 C158 106 162 92 156 78' : 'M142 120 C150 136 140 150 148 166',
      bubbles: mood === 'breathe' || mood === 'calm' ? 1 : 0,
      bubV1: on ? '160;60' : '150;150', bubV2: on ? '130;40' : '130;130',
      floatV: on ? '0 0;5 -8;0 0' : '0 0;0 0;0 0',
      g1: 1, g2: stage >= 2 ? 1 : 0, g3: stage >= 3 ? 1 : 0, crown: stage >= 4 ? 1 : 0,
      sparkle: up ? 1 : 0,
      zzz: mood === 'sleepy' ? 1 : 0
    };
  }
}
</script>
</body>
</html>
````

### `Glim2.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Glim, night tone</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<style>
body{margin:0}
</style>
</helmet>
<svg width="{{size}}" height="{{size}}" viewBox="0 0 200 200" role="img" aria-label="Glim, {{mood}}" style="display: block">
  <ellipse cx="100" cy="194" rx="34" ry="4" fill="#000000" opacity="0.1"></ellipse>
  <g opacity="{{stars}}" fill="#FFE27A">
    <path d="M30 60 l3 7 l7 3 l-7 3 l-3 7 l-3 -7 l-7 -3 l7 -3 Z"><animate attributeName="opacity" values="{{twinkle}}" dur="1.8s" repeatCount="indefinite"></animate></path>
    <path d="M168 120 l2.5 5 l5 2.5 l-5 2.5 l-2.5 5 l-2.5 -5 l-5 -2.5 l5 -2.5 Z"><animate attributeName="opacity" values="{{twinkle}}" dur="2.3s" begin="0.6s" repeatCount="indefinite"></animate></path>
    <path d="M40 160 l2 4 l4 2 l-4 2 l-2 4 l-2 -4 l-4 -2 l4 -2 Z"><animate attributeName="opacity" values="{{twinkle}}" dur="2s" begin="1.1s" repeatCount="indefinite"></animate></path>
  </g>
  <g>
    <animateTransform attributeName="transform" type="translate" values="{{hopV}}" keyTimes="{{hopKT}}" keySplines="{{hopKS}}" calcMode="spline" dur="{{hopDur}}" repeatCount="indefinite"></animateTransform>
    <circle cx="100" cy="150" r="{{glowR}}" fill="#FFE27A" opacity="0.3"><animate attributeName="r" values="{{glowV}}" dur="{{glowDur}}" repeatCount="indefinite"></animate><animate attributeName="opacity" values="{{glowO}}" dur="{{glowDur}}" repeatCount="indefinite"></animate></circle>
    <g transform="translate(100 120)">
      <g>
        <animateTransform attributeName="transform" type="scale" values="{{bodyV}}" keyTimes="{{bodyKT}}" keySplines="{{bodyKS}}" calcMode="spline" dur="{{bodyDur}}" repeatCount="indefinite"></animateTransform>
        <g>
          <animateTransform attributeName="transform" type="rotate" values="{{swayV}}" keyTimes="{{swayKT}}" keySplines="{{swayKS}}" calcMode="spline" dur="{{swayDur}}" repeatCount="indefinite"></animateTransform>
          <g transform="translate(-100 -120)">
            <g transform="translate(84 82)"><g><animateTransform attributeName="transform" type="rotate" values="{{wingL}}" dur="{{wingDur}}" repeatCount="indefinite"></animateTransform><g transform="translate(-84 -82)">
              <ellipse cx="58" cy="66" rx="30" ry="17" transform="rotate(-28 58 66)" fill="#E9F1FF" opacity="0.92" stroke="#B9C6F2" stroke-width="2"></ellipse>
              <path d="M40 74 C52 66 66 62 80 64" fill="none" stroke="#B9C6F2" stroke-width="1.5" stroke-linecap="round"></path>
            </g></g></g>
            <g transform="translate(116 82)"><g><animateTransform attributeName="transform" type="rotate" values="{{wingR}}" dur="{{wingDur}}" repeatCount="indefinite"></animateTransform><g transform="translate(-116 -82)">
              <ellipse cx="142" cy="66" rx="30" ry="17" transform="rotate(28 142 66)" fill="#E9F1FF" opacity="0.92" stroke="#B9C6F2" stroke-width="2"></ellipse>
              <path d="M160 74 C148 66 134 62 120 64" fill="none" stroke="#B9C6F2" stroke-width="1.5" stroke-linecap="round"></path>
            </g></g></g>
            <path d="M90 62 C84 50 78 40 74 32" fill="none" stroke="#5638C4" stroke-width="3.5" stroke-linecap="round"></path>
            <path d="M110 62 C116 50 122 40 126 32" fill="none" stroke="#5638C4" stroke-width="3.5" stroke-linecap="round"></path>
            <circle cx="73" cy="29" r="6" fill="#FFE27A"></circle>
            <circle cx="127" cy="29" r="6" fill="#FFE27A"></circle>
            <ellipse cx="100" cy="150" rx="33" ry="31" fill="#FFE27A"></ellipse>
            <path d="M70 146 C84 154 116 154 130 146 M72 160 C86 168 114 168 128 160" fill="none" stroke="#F2C94C" stroke-width="3.5" stroke-linecap="round"></path>
            <path d="M80 132 C86 126 94 124 100 124" fill="none" stroke="#FFF6C8" stroke-width="4" stroke-linecap="round"></path>
            <path d="{{armL}}" fill="none" stroke="#6B4FD8" stroke-width="9" stroke-linecap="round"></path>
            <path d="{{armR}}" fill="none" stroke="#6B4FD8" stroke-width="9" stroke-linecap="round"></path>
            <circle cx="100" cy="96" r="40" fill="#6B4FD8"></circle>
            <path d="M124 64 C136 74 142 88 140 102 C138 118 126 132 108 136 C124 124 132 108 130 94 C129 82 126 72 124 64 Z" fill="#5638C4"></path>
            <path d="M70 84 C72 72 80 64 90 60" fill="none" stroke="#9A84F0" stroke-width="5" stroke-linecap="round"></path>
            <circle cx="74" cy="106" r="6" fill="#FF8FA3" opacity="0.8"></circle>
            <circle cx="126" cy="106" r="6" fill="#FF8FA3" opacity="0.8"></circle>
            <g transform="{{eyeIn}}"><g><animateTransform attributeName="transform" type="scale" values="{{blink}}" keyTimes="0;0.92;0.96;1" dur="4.4s" repeatCount="indefinite"></animateTransform><g transform="{{eyeOut}}">
              <path d="{{eyeL}}" fill="none" stroke="#FFF8EE" stroke-width="{{eyeW}}" stroke-linecap="round"></path>
              <path d="{{eyeR}}" fill="none" stroke="#FFF8EE" stroke-width="{{eyeW}}" stroke-linecap="round"></path>
            </g></g></g>
            <path d="{{mouth}}" fill="{{mouthFill}}" stroke="#FFF8EE" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"></path>
          </g>
        </g>
      </g>
    </g>
  </g>
  <g opacity="{{zzz}}" fill="none" stroke="#9A84F0" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><animateTransform attributeName="transform" type="translate" values="{{floatV}}" dur="3s" repeatCount="indefinite"></animateTransform><path d="M150 34 h12 l-12 12 h12"></path><path d="M170 16 h8 l-8 8 h8"></path></g>
</svg>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"mood":{"editor":"enum","options":["hello","calm","breathe","cheer","sleepy"],"default":"hello"},"stage":{"editor":"int","min":1,"max":4,"default":2},"animate":{"editor":"boolean","default":true},"size":{"editor":"int","min":40,"max":800,"default":240},"$preview":{"width":240,"height":240}}'>
class Component extends DCLogic {
  renderVals() {
    const mood = this.props.mood ?? 'hello';
    const stage = Math.min(4, Math.max(1, Number(this.props.stage ?? 2)));
    const size = Number(this.props.size ?? 240);
    const on = String(this.props.animate ?? true) !== 'false';
    const C = 100, L = 86, R = 114, y = 94, fc = '#FFF8EE';
    const closed = { eyeL: `M${L-6} ${y} Q${L} ${y+5} ${L+6} ${y}`, eyeR: `M${R-6} ${y} Q${R} ${y+5} ${R+6} ${y}`, eyeW: 3.5 };
    const faces = {
      hello: { eyeL: `M${L} ${y-3} L${L} ${y+3}`, eyeR: `M${R} ${y-3} L${R} ${y+3}`, eyeW: 8, mouth: `M${C-8} ${y+14} Q${C} ${y+22} ${C+8} ${y+14}`, mouthFill: 'none' },
      calm: { ...closed, mouth: `M${C-5} ${y+15} Q${C} ${y+19} ${C+5} ${y+15}`, mouthFill: 'none' },
      breathe: { ...closed, mouth: `M${C} ${y+12} C${C+6} ${y+12} ${C+6} ${y+23} ${C} ${y+23} C${C-6} ${y+23} ${C-6} ${y+12} ${C} ${y+12} Z`, mouthFill: fc },
      cheer: { eyeL: `M${L-6} ${y+2} Q${L} ${y-5} ${L+6} ${y+2}`, eyeR: `M${R-6} ${y+2} Q${R} ${y-5} ${R+6} ${y+2}`, eyeW: 3.5, mouth: `M${C-10} ${y+12} L${C+10} ${y+12} Q${C} ${y+28} ${C-10} ${y+12} Z`, mouthFill: fc },
      sleepy: { eyeL: `M${L-6} ${y+1} L${L+6} ${y+1}`, eyeR: `M${R-6} ${y+1} L${R+6} ${y+1}`, eyeW: 3.5, mouth: `M${C-3} ${y+16} Q${C} ${y+18} ${C+3} ${y+16}`, mouthFill: 'none' }
    };
    const f = faces[mood] ?? faces.hello;
    const ks = (n) => Array(n).fill('0.45 0 0.55 1').join(';');
    const A = (vals, kt, dur) => ({ v: (on ? vals : vals.map(() => vals[0])).join(';'), kt: kt.join(';'), ks: ks(kt.length - 1), dur: dur + 's' });
    const body = ({
      hello: A(['1 1', '1.025 0.985', '1 1'], [0, 0.5, 1], 4),
      calm: A(['1 1', '1.02 0.99', '1 1'], [0, 0.5, 1], 6),
      breathe: A(['1 1', '1.07 1.07', '1 1'], [0, 0.4, 1], 10),
      cheer: A(['1 1', '1.08 0.9', '0.96 1.06', '1 1', '1 1'], [0, 0.15, 0.35, 0.55, 1], 1.3),
      sleepy: A(['1 1', '1.015 0.99', '1 1'], [0, 0.5, 1], 7)
    })[mood] ?? A(['1 1', '1 1'], [0, 1], 1);
    const hop = mood === 'cheer' ? A(['0 0', '0 0', '0 -18', '0 0', '0 0'], [0, 0.15, 0.35, 0.55, 1], 1.3) : A(['0 0', '0 -7', '0 0'], [0, 0.5, 1], mood === 'sleepy' ? 7 : 3);
    const sway = mood === 'sleepy' ? A(['-4', '4', '-4'], [0, 0.5, 1], 7) : A(['0', '0'], [0, 1], 1);
    const up = mood === 'cheer';
    const base = [30, 38, 48, 58][stage - 1];
    const flap = mood === 'sleepy' ? null : (mood === 'breathe' || mood === 'calm' ? '1.2s' : '0.3s');
    const glowDur = mood === 'breathe' ? '10s' : '2.6s';
    return {
      ...f, mood, size,
      bodyV: body.v, bodyKT: body.kt, bodyKS: body.ks, bodyDur: body.dur,
      hopV: hop.v, hopKT: hop.kt, hopKS: hop.ks, hopDur: hop.dur,
      swayV: sway.v, swayKT: sway.kt, swayKS: sway.ks, swayDur: sway.dur,
      eyeIn: `translate(${C} ${y})`, eyeOut: `translate(${-C} ${-y})`,
      blink: on && (mood === 'hello' || up) ? '1 1;1 1;1 0.1;1 1' : '1 1;1 1;1 1;1 1',
      wingL: on && flap ? '0;-14;0' : '0;0;0', wingR: on && flap ? '0;14;0' : '0;0;0', wingDur: flap ?? '1s',
      glowR: base,
      glowV: on ? `${base};${base + 10};${base}` : `${base};${base};${base}`,
      glowO: on ? '0.22;0.45;0.22' : '0.3;0.3;0.3',
      glowDur,
      twinkle: on ? '0.2;1;0.2' : '1;1;1',
      stars: stage >= 4 ? 1 : 0,
      floatV: on ? '0 0;5 -8;0 0' : '0 0;0 0;0 0',
      armL: up ? 'M66 108 C54 98 50 86 52 74' : 'M64 114 C54 120 50 128 52 136',
      armR: up ? 'M134 108 C146 98 150 86 148 74' : 'M136 114 C146 120 150 128 148 136',
      zzz: mood === 'sleepy' ? 1 : 0
    };
  }
}
</script>
</body>
</html>
````

### `Horizon2.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Horizon art, alive</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<style>
body{margin:0}
</style>
</helmet>
<svg width="{{w}}" height="{{h}}" viewBox="0 0 400 300" preserveAspectRatio="{{fit}}" aria-hidden="true" style="display: block">
  <defs>
    <linearGradient id="h2Dawn" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FF7E5A"></stop><stop offset="0.55" stop-color="#FFB877"></stop><stop offset="1" stop-color="#FFE6BF"></stop></linearGradient>
    <linearGradient id="h2Day" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#5AA9FF"></stop><stop offset="1" stop-color="#D3EEFF"></stop></linearGradient>
    <linearGradient id="h2Dusk" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7A5CE0"></stop><stop offset="0.6" stop-color="#E58BB8"></stop><stop offset="1" stop-color="#FFC59A"></stop></linearGradient>
    <linearGradient id="h2Night" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#180F52"></stop><stop offset="1" stop-color="#5A3CC4"></stop></linearGradient>
    <radialGradient id="h2Sun" cx="0.38" cy="0.32" r="0.75"><stop offset="0" stop-color="#FFF6C8"></stop><stop offset="1" stop-color="#FFC23A"></stop></radialGradient>
    <radialGradient id="h2Glow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.75"></stop><stop offset="1" stop-color="#FFFFFF" stop-opacity="0"></stop></radialGradient>
    <linearGradient id="h2Sheen" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.22"></stop><stop offset="0.35" stop-color="#FFFFFF" stop-opacity="0"></stop></linearGradient>
    <filter id="h2Lift" x="-5%" y="-20%" width="110%" height="140%"><feDropShadow dx="0" dy="-3" stdDeviation="4" flood-color="#1A0B2E" flood-opacity="0.22"></feDropShadow></filter>
    <filter id="h2Soft" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="4"></feGaussianBlur></filter>
    <filter id="h2Grain" x="0" y="0" width="100%" height="100%"><feTurbulence type="fractalNoise" baseFrequency="0.85" numOctaves="2" stitchTiles="stitch"></feTurbulence><feColorMatrix values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0.09 0"></feColorMatrix></filter>
  </defs>

  <g display="{{d.dawn}}">
    <rect width="400" height="300" fill="url(#h2Dawn)"></rect>
    <circle cx="200" cy="168" r="130" fill="url(#h2Glow)" opacity="0.6"><animate attributeName="r" values="{{pulseR}}" dur="6s" repeatCount="indefinite"></animate></circle>
    <circle cx="200" cy="{{sunY}}" r="70" fill="url(#h2Sun)"><animate attributeName="cy" values="{{sunRise}}" dur="2.6s" fill="freeze" calcMode="spline" keySplines="0.2 0.7 0.2 1" keyTimes="0;1"></animate></circle>
    <g filter="url(#h2Soft)" opacity="0.85" fill="#FFF4E6"><animateTransform attributeName="transform" type="translate" values="{{drift}}" dur="24s" repeatCount="indefinite"></animateTransform><ellipse cx="70" cy="86" rx="46" ry="14"></ellipse><ellipse cx="98" cy="74" rx="28" ry="14"></ellipse><ellipse cx="330" cy="62" rx="40" ry="12"></ellipse></g>
    <rect width="400" height="300" fill="{{haze}}" opacity="{{hazeO}}"></rect>
    <path filter="url(#h2Lift)" d="M0 192 C60 162 120 172 180 187 C250 204 320 172 400 166 L400 300 L0 300 Z" fill="#FF9D6E"></path>
    <path filter="url(#h2Lift)" d="M0 222 C80 196 150 206 220 224 C290 240 350 216 400 206 L400 300 L0 300 Z" fill="#FF7A55"></path>
    <path filter="url(#h2Lift)" d="M0 252 C70 233 140 241 210 256 C280 271 340 251 400 243 L400 300 L0 300 Z" fill="#E85A3E"></path>
    <path filter="url(#h2Lift)" d="M0 282 C90 267 180 273 260 283 C320 291 360 285 400 279 L400 300 L0 300 Z" fill="#C2402A"></path>
    <path d="M0 222 C80 196 150 206 220 224 C290 240 350 216 400 206 L400 300 L0 300 Z" fill="url(#h2Sheen)"></path>
    <path d="M330 34 Q330 46 342 46 Q330 46 330 58 Q330 46 318 46 Q330 46 330 34 Z" fill="#FFF8EE"><animate attributeName="opacity" values="{{twinkle}}" dur="2.2s" repeatCount="indefinite"></animate></path>
  </g>

  <g display="{{d.dusk}}">
    <rect width="400" height="300" fill="url(#h2Dusk)"></rect>
    <circle cx="300" cy="190" r="110" fill="url(#h2Glow)" opacity="0.45"></circle>
    <circle cx="300" cy="196" r="44" fill="#FFB86B"></circle>
    <g filter="url(#h2Soft)" opacity="0.8" fill="#FFE0EE"><animateTransform attributeName="transform" type="translate" values="{{drift}}" dur="26s" repeatCount="indefinite"></animateTransform><ellipse cx="90" cy="80" rx="52" ry="14"></ellipse><ellipse cx="120" cy="68" rx="30" ry="14"></ellipse></g>
    <circle cx="70" cy="40" r="1.6" fill="#FFF8EE"><animate attributeName="opacity" values="{{twinkle}}" dur="1.9s" repeatCount="indefinite"></animate></circle><circle cx="200" cy="30" r="1.4" fill="#FFF8EE"><animate attributeName="opacity" values="{{twinkle}}" dur="2.6s" begin="0.7s" repeatCount="indefinite"></animate></circle>
    <rect width="400" height="300" fill="{{haze}}" opacity="{{hazeO}}"></rect>
    <path filter="url(#h2Lift)" d="M0 196 C70 170 140 178 200 192 C270 208 330 180 400 172 L400 300 L0 300 Z" fill="#B572C9"></path>
    <path filter="url(#h2Lift)" d="M0 228 C90 202 160 212 230 230 C300 246 350 222 400 214 L400 300 L0 300 Z" fill="#8E55BF"></path>
    <path filter="url(#h2Lift)" d="M0 258 C80 238 150 246 220 262 C290 278 350 258 400 250 L400 300 L0 300 Z" fill="#6A3AA8"></path>
    <path filter="url(#h2Lift)" d="M0 286 C90 272 160 278 240 288 C310 296 360 290 400 284 L400 300 L0 300 Z" fill="#4A2588"></path>
  </g>

  <g display="{{d.path}}">
    <rect width="400" height="300" fill="url(#h2Day)"></rect>
    <circle cx="300" cy="78" r="70" fill="url(#h2Glow)" opacity="0.6"></circle>
    <circle cx="300" cy="78" r="30" fill="url(#h2Sun)"></circle>
    <g filter="url(#h2Soft)" opacity="0.9" fill="#FFFFFF"><animateTransform attributeName="transform" type="translate" values="{{drift}}" dur="22s" repeatCount="indefinite"></animateTransform><ellipse cx="80" cy="70" rx="50" ry="15"></ellipse><ellipse cx="110" cy="58" rx="30" ry="15"></ellipse><ellipse cx="370" cy="130" rx="40" ry="12"></ellipse></g>
    <rect width="400" height="300" fill="{{haze}}" opacity="{{hazeO}}"></rect>
    <path filter="url(#h2Lift)" d="M0 176 C70 150 140 158 200 172 C270 188 330 160 400 150 L400 300 L0 300 Z" fill="#9FE3AE"></path>
    <path d="M70 168 L78 146 L86 168 Z M92 166 L98 150 L104 166 Z" fill="#3FA868"></path>
    <path filter="url(#h2Lift)" d="M0 210 C90 184 160 194 230 212 C300 228 350 204 400 196 L400 300 L0 300 Z" fill="#5CC984"></path>
    <path filter="url(#h2Lift)" d="M0 246 C80 226 150 234 220 250 C290 266 350 246 400 238 L400 300 L0 300 Z" fill="#2FA262"></path>
    <path d="M176 300 C188 282 236 272 228 256 C222 244 202 236 206 224 L212 224 C212 236 236 244 242 258 C252 278 216 288 224 300 Z" fill="#FFF1D2"></path>
    <path filter="url(#h2Lift)" d="M0 284 C90 270 160 276 240 286 C310 294 360 288 400 282 L400 300 L0 300 Z" fill="#1E7A4B"></path>
    <path d="M0 210 C90 184 160 194 230 212 C300 228 350 204 400 196 L400 300 L0 300 Z" fill="url(#h2Sheen)"></path>
  </g>

  <g display="{{d.sea}}">
    <rect width="400" height="300" fill="url(#h2Day)"></rect>
    <circle cx="110" cy="96" r="80" fill="url(#h2Glow)" opacity="0.6"><animate attributeName="r" values="{{pulseR}}" dur="10s" repeatCount="indefinite"></animate></circle>
    <circle cx="110" cy="96" r="34" fill="url(#h2Sun)"></circle>
    <g filter="url(#h2Soft)" opacity="0.9" fill="#FFFFFF"><animateTransform attributeName="transform" type="translate" values="{{drift}}" dur="20s" repeatCount="indefinite"></animateTransform><ellipse cx="300" cy="64" rx="56" ry="15"></ellipse><ellipse cx="330" cy="52" rx="30" ry="14"></ellipse></g>
    <rect width="400" height="300" fill="{{haze}}" opacity="{{hazeO}}"></rect>
    <g><animateTransform attributeName="transform" type="translate" values="{{waveA}}" dur="7s" repeatCount="indefinite"></animateTransform><path filter="url(#h2Lift)" d="M-40 176 C10 166 60 172 110 168 C180 162 260 170 440 164 L440 300 L-40 300 Z" fill="#9CCBFF"></path></g>
    <g><animateTransform attributeName="transform" type="translate" values="{{waveB}}" dur="5s" repeatCount="indefinite"></animateTransform><path filter="url(#h2Lift)" d="M-40 206 C20 190 70 196 120 208 C180 222 240 196 300 194 C350 193 400 198 440 202 L440 300 L-40 300 Z" fill="#5A9DFF"></path></g>
    <g><animateTransform attributeName="transform" type="translate" values="{{waveC}}" dur="6s" repeatCount="indefinite"></animateTransform><path filter="url(#h2Lift)" d="M-40 240 C10 222 60 226 110 240 C160 254 210 230 260 228 C320 226 380 234 440 240 L440 300 L-40 300 Z" fill="#2F72F2"></path><path d="M90 236 C102 222 122 220 132 232 C120 230 110 234 104 242 Z" fill="#FFF8EE"></path></g>
    <g><animateTransform attributeName="transform" type="translate" values="{{waveB}}" dur="8s" repeatCount="indefinite"></animateTransform><path filter="url(#h2Lift)" d="M-40 276 C20 262 80 266 140 276 C200 286 260 268 440 272 L440 300 L-40 300 Z" fill="#1C4FCC"></path></g>
    <circle cx="300" cy="260" r="3" fill="#FFFFFF" opacity="0.7"><animate attributeName="cy" values="{{bubble}}" dur="5s" repeatCount="indefinite"></animate></circle>
  </g>

  <g display="{{d.night}}">
    <rect width="400" height="300" fill="url(#h2Night)"></rect>
    <circle cx="60" cy="40" r="1.8" fill="#FFF8EE"><animate attributeName="opacity" values="{{twinkle}}" dur="2s" repeatCount="indefinite"></animate></circle><circle cx="150" cy="24" r="1.4" fill="#FFF8EE"><animate attributeName="opacity" values="{{twinkle}}" dur="2.7s" begin="0.4s" repeatCount="indefinite"></animate></circle><circle cx="230" cy="60" r="1.6" fill="#FFF8EE"><animate attributeName="opacity" values="{{twinkle}}" dur="1.8s" begin="1s" repeatCount="indefinite"></animate></circle><circle cx="360" cy="110" r="1.4" fill="#FFF8EE"><animate attributeName="opacity" values="{{twinkle}}" dur="2.4s" begin="0.2s" repeatCount="indefinite"></animate></circle><circle cx="30" cy="120" r="1.2" fill="#FFF8EE"><animate attributeName="opacity" values="{{twinkle}}" dur="3s" begin="0.9s" repeatCount="indefinite"></animate></circle>
    <circle cx="290" cy="80" r="70" fill="url(#h2Glow)" opacity="0.35"></circle>
    <path d="M290 46 A34 34 0 1 0 322 98 A28 28 0 1 1 290 46 Z" fill="#FFF1C2"></path>
    <rect width="400" height="300" fill="{{haze}}" opacity="{{hazeO}}"></rect>
    <path filter="url(#h2Lift)" d="M0 184 C70 158 140 166 200 180 C270 196 330 168 400 160 L400 300 L0 300 Z" fill="#5A3CC4"></path>
    <path filter="url(#h2Lift)" d="M0 218 C90 192 160 202 230 220 C300 236 350 212 400 204 L400 300 L0 300 Z" fill="#432AA6"></path>
    <path filter="url(#h2Lift)" d="M0 252 C80 232 150 240 220 256 C290 272 350 252 400 244 L400 300 L0 300 Z" fill="#2F1C84"></path>
    <path filter="url(#h2Lift)" d="M0 284 C90 270 160 276 240 286 C310 294 360 288 400 282 L400 300 L0 300 Z" fill="#1C1160"></path>
    <g fill="#FFE27A"><animateTransform attributeName="transform" type="translate" values="{{fly}}" dur="9s" repeatCount="indefinite"></animateTransform><circle cx="96" cy="230" r="3"><animate attributeName="opacity" values="{{twinkle}}" dur="1.6s" repeatCount="indefinite"></animate></circle><circle cx="96" cy="230" r="8" opacity="0.25"></circle><circle cx="300" cy="250" r="2.5"><animate attributeName="opacity" values="{{twinkle}}" dur="2.1s" begin="0.5s" repeatCount="indefinite"></animate></circle><circle cx="300" cy="250" r="7" opacity="0.25"></circle><circle cx="190" cy="214" r="2"><animate attributeName="opacity" values="{{twinkle}}" dur="1.3s" begin="0.2s" repeatCount="indefinite"></animate></circle></g>
  </g>

  <rect width="400" height="300" fill="{{haze}}" opacity="{{hazeTop}}"></rect>
  <rect width="400" height="300" filter="url(#h2Grain)"></rect>
</svg>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"scene":{"editor":"enum","options":["dawn","dusk","path","sea","night"],"default":"dawn"},"clarity":{"editor":"range","min":0,"max":100,"step":5,"default":100},"animate":{"editor":"boolean","default":true},"w":{"editor":"int","min":40,"max":1200,"default":400},"h":{"editor":"int","min":40,"max":1200,"default":300},"fit":{"editor":"enum","options":["xMidYMid slice","xMidYMax slice","xMidYMin slice"],"default":"xMidYMid slice"},"$preview":{"width":400,"height":300}}'>
class Component extends DCLogic {
  renderVals() {
    const scene = this.props.scene ?? 'dawn';
    const names = ['dawn', 'dusk', 'path', 'sea', 'night'];
    const d = {};
    names.forEach((n) => { d[n] = n === scene ? 'inline' : 'none'; });
    if (!names.includes(scene)) d.dawn = 'inline';
    const on = String(this.props.animate ?? true) !== 'false';
    const clarity = Math.min(100, Math.max(0, Number(this.props.clarity ?? 100)));
    const fog = 1 - clarity / 100;
    const sunY = 168 + Math.round(fog * 20);
    const S = (a, b) => on ? a : b;
    return {
      d,
      w: Number(this.props.w ?? 400), h: Number(this.props.h ?? 300),
      fit: this.props.fit ?? 'xMidYMid slice',
      haze: scene === 'night' ? '#8E80C9' : (scene === 'dusk' ? '#E9D6F0' : '#F3ECE3'),
      hazeO: (fog * 0.7).toFixed(2),
      hazeTop: (fog * 0.35).toFixed(2),
      sunY,
      sunRise: S(`${sunY + 60};${sunY}`, `${sunY};${sunY}`),
      pulseR: S('120;140;120', '130;130;130'),
      drift: S('0 0;22 0;0 0', '0 0;0 0;0 0'),
      waveA: S('0 0;-18 2;0 0', '0 0;0 0;0 0'),
      waveB: S('0 0;20 -3;0 0', '0 0;0 0;0 0'),
      waveC: S('0 0;-26 3;0 0', '0 0;0 0;0 0'),
      bubble: S('270;170', '260;260'),
      fly: S('0 0;14 -10;-8 -4;0 0', '0 0;0 0;0 0;0 0'),
      twinkle: S('0.25;1;0.25', '1;1;1')
    };
  }
}
</script>
</body>
</html>
````

### `Hero2.dc.html`

````html
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>Hero art, alive</title>
<script src="./support.js"></script>
</head>
<body>
<x-dc>
<helmet>
<style>
body{margin:0}
</style>
</helmet>
<div style="position: relative; width: 390px; height: {{h}}px; overflow: hidden">
  <dc-import name="Horizon2" scene="{{scene}}" clarity="{{clarity}}" animate="{{animate}}" w="390" h="{{h}}" fit="{{fit}}" hint-size="390px,300px"></dc-import>
  <svg width="390" height="{{h}}" viewBox="{{vb}}" aria-hidden="true" style="position: absolute; left: 0; top: 0">
    <defs><filter id="hero2Lift" x="-5%" y="-50%" width="110%" height="200%"><feDropShadow dx="0" dy="-4" stdDeviation="6" flood-color="#1A0B2E" flood-opacity="0.26"></feDropShadow></filter></defs>
    <path filter="url(#hero2Lift)" d="{{edgePath}}" fill="{{edge}}"></path>
  </svg>
</div>
</x-dc>
<script type="text/x-dc" data-dc-script data-props='{"scene":{"editor":"enum","options":["dawn","dusk","path","sea","night"],"default":"dawn"},"clarity":{"editor":"range","min":0,"max":100,"step":5,"default":100},"h":{"editor":"int","min":120,"max":844,"default":300},"edge":{"editor":"color","default":"#FFC38A"},"animate":{"editor":"boolean","default":true},"fit":{"editor":"enum","options":["xMidYMid slice","xMidYMax slice","xMidYMin slice"],"default":"xMidYMax slice"},"$preview":{"width":390,"height":300}}'>
class Component extends DCLogic {
  renderVals() {
    const h = Number(this.props.h ?? 300);
    return {
      h,
      scene: this.props.scene ?? 'dawn',
      clarity: Number(this.props.clarity ?? 100),
      animate: String(this.props.animate ?? true),
      fit: this.props.fit ?? 'xMidYMax slice',
      vb: `0 0 390 ${h}`,
      edgePath: `M0 ${h - 30} C110 ${h - 54} 280 ${h - 54} 390 ${h - 30} L390 ${h} L0 ${h} Z`,
      edge: this.props.edge ?? '#FFC38A'
    };
  }
}
</script>
</body>
</html>
````

