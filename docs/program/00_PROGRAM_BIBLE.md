# DayXero Program v3 · Prep week and Day Xero

**Status:** draft for Milan's review, 6 Nov 2026. This file is the source of truth for anyone writing program content. Every day file (`P1.md` … `P7.md`, `DX.md`) follows it.

**What this covers:** the 7 prep days (P1–P7) and Quit Day (DX, "Day Xero"). Week 1 and the maintenance weeks come after this is approved.

**Product promise:** a paid program ($30–40). It must feel substantial, informed and kind. People should come out of every step knowing something they didn't know, having done something they hadn't done, and feeling more able to quit. It isn't a pamphlet, and it isn't a wall of text either.

---

## 1. The method in one paragraph

You keep using nicotine as normal for seven days. Day by day you take apart the beliefs that keep you using: that it gives you pleasure, calm, focus and comfort, and that quitting means giving something up. You learn to see the **gap**: the restless, empty feeling nicotine creates between doses and then briefly fills. You learn skills for the moments that will come (notice, name, allow, ride the wave). You set up your space, your support and, if you want it, nicotine replacement. On Day Xero you stop. You're not losing a friend; you're stepping out of a trap you can now see.

Four influences, blended:

| Influence | What we take | What we leave |
|---|---|---|
| **Allen Carr-style reframing** | Keep using while you learn. The relief is the trap refilling itself. Non-users aren't missing anything. You're not giving anything up. Fear of quitting is part of the addiction. A conscious last cigarette. | His copyrighted phrases and coinages (never "the little monster", "the big monster", "Easyway"). Absolute promises ("no withdrawal", "easy for everyone"). Anti-NRT stance. |
| **ACT (Acceptance and Commitment Therapy)** | Notice, name, allow. Thoughts are not orders ("I'm having the thought that…"). Urge surfing. Values and reasons as direction. Willingness over white-knuckling. | Jargon. No "defusion", "experiential avoidance" or "psychological flexibility" on screen. |
| **Evidence-based quitting (CBT and clinical)** | Triggers and if-then plans. Changing the environment. Support. Honest withdrawal facts. NRT and prescription options. | Fear campaigns, graphic harm. |
| **Empathy (motivational interviewing)** | It makes sense that you smoke. Mixed feelings are normal. You are not weak. Affirm effort, not outcome. | Pity, cheerleading, exclamation marks. |

**The DayXero line on NRT:** understanding removes the *wanting*. NRT can take the edge off the *physical* side for the first weeks. They work together. Using NRT is not cheating, and not using it is fine too. (Cochrane: NRT raises quit rates by 50–60%; a patch plus a fast-acting form works better than one alone.)

## 2. Core metaphors (use these, consistently)

1. **The gap.** Every hour or two the nicotine level drops and leaves a restless, empty, slightly-on-edge feeling. Using closes it. That closing *is* most of the "pleasure", "calm" and "focus". Non-users never have the gap. We say "the gap", not "the battery" (P1's old copy used battery; retire it).
2. **The story.** The beliefs that keep you using: "I enjoy it", "it calms me", "it helps me focus", "it's my reward", "it's who I am", "I'll miss it". We look at each one with our eyes open.
3. **The wave.** A craving rises, peaks and falls, usually within minutes. You can ride it without doing what it says. Every wave you ride makes the next one smaller. (Jelli's realm in the app; SOS.)
4. **The autopilot.** Most uses are triggered by cues (coffee, meals, stress, phone, car), not decisions. Seeing the cue switches off the autopilot.
5. **Free, not deprived.** On Day Xero you're not a smoker who can't smoke. You're someone who doesn't need to.

## 3. Voice

- **One narrator** for all audio. Warm, calm, adult, unhurried, quietly confident; never preachy. First person ("I'll walk you through…"). Speaks like a good counsellor who also happens to be straight with you. No character names in audio; Xero, Jelli and Glim are visual only.
- On screen: short sentences, second person, plain words. British or US neutral spelling: **US spelling** (the app's currency is USD).
- **Never shame.** Never "you're lying to yourself", "denial", "junkie", "addict" as a label, "weak". We can say "nicotine is addictive", "the addiction".
- **Never promise** that it'll be easy for everyone, that there'll be no withdrawal, or a success rate.
- **Honest about hard parts**, then practical: "The first three days are usually the hardest. Here's what helps."
- Validate the experience: "The relief is real. What it relieves is the catch."
- **No exclamation marks** (except none). No emoji. No "journey" clichés, no "you've got this, champ".
- Product variants: everything must work for cigarettes, vapes and pouches (see §7).

## 4. Shape of a day

Every day has **5 steps**, each **5–7 minutes**, about **30 minutes** in all. Steps open in order. The evening step opens from 6 pm (local); everything else is available at once. People can stop between steps; their place is saved.

Step formats (these match the final mockup, row F on the design canvas):

| Format | Screen | Length target |
|---|---|---|
| **Listen** | Full-colour audio with live word-by-word captions, chapter segments at the top (mockup C's audio). Morning tracks on apricot, evening on violet. | 5–7 min, **700–950 words** of script. 3–5 chapters. |
| **Reveal** | A 2×2 grid of face-down cards (mockup D). Each shows a question; tap to reveal a short answer; "Go deeper" opens a sheet with more. All four must be revealed to go on. | 4 cards. Front ≤ 12 words. Answer 20–40 words. Go deeper 80–130 words. |
| **Myth or fact** | One statement card at a time; tap Myth or Fact (mockup D). The card turns to the verdict, an explanation and a source. | 5 statements. Explanation 50–90 words. A source on every claim of fact. |
| **Try** | An interactive exercise: a guided practice, a plan, a tracker, a checklist, a journal. Several short screens. | 5–7 min of doing. Exact UI copy for every screen. |
| **Breathe** | A guided breathing practice with an animated ring (used on P4 and DX). | 3–5 min. |

Each day has **1 or 2 Listen steps**. Every day has at least one Reveal or Myth-or-fact step and at least one Try step.

**Every step ends with a commitment button written in the user's voice** (borrowed from QuitSure, it works): "I've lived this", "That makes sense", "I'll try it today", "I'm ready for tomorrow". 2–5 words. Never "Next" or "Continue" on a step's last screen. After it, a one-tap rating (four faces, optional, skippable).

**End of the day** (after step 5): a recap screen with
- **What you learned today:** 3 bullets, one line each.
- **Your mission for the rest of today:** one concrete thing, tied to logging (`logType`).
- **Tomorrow:** one-line teaser.
- **Completion line** (the existing `completionText`).

## 5. The plan, day by day

Titles keep the existing session ids and the spirit of the existing titles. Writers flesh these out; they may adjust a step's title but not its format or purpose without a note.

### P1 · You don't have to quit today — *The gap*
Big idea: keep using as normal; most of what feels like pleasure is the gap closing.
1. **Listen · "Keep using. Just watch."** (6 min, morning) How the 7 days work and why you don't quit yet. You're not weak; nicotine is built to be hard to quit, and willpower-only attempts usually fail (Hughes 2004: 3–5% of unaided attempts last 6–12 months). The gap. Today's only job.
2. **Reveal · "Why the first one feels so good"** The gap overnight; how a non-user wakes up; why it feels like it helps; do I have to stop believing it today.
3. **Myth or fact · "What you've been told"** I enjoy it (partly); it's just a habit (myth: it's a habit plus a drug); I could stop any time I wanted (myth); most people who use want to quit (fact: Babb 2017, 68%); it hasn't harmed me yet (myth, calm, no graphic copy).
4. **Try · "Your reasons, and three honest check-ins"** Up to 5 reasons (prefilled from onboarding), choose the main one; set up today's check-in: before 3 uses, rate "how much is this the gap?" and where you feel it. Quit Day commit hold ({quit_date}).
5. **Listen · "Tonight: what you noticed"** (7 min, evening) Reflection on the check-ins; mixed feelings are normal; your main reason; sleep.

### P2 · The first one of the day — *Autopilot*
Big idea: most uses are set off by cues, not choices. See the cue and the autopilot loosens.
1. **Listen · "The autopilot"** (6 min) How cues get wired (pairing, repetition); why the first one of the day feels strongest; mornings.
2. **Reveal · "Your triggers, decoded"** Coffee, after meals, the phone, driving (and Drinking or Stress if chosen in onboarding; writers give 6 cards, the app shows the person's top 4).
3. **Myth or fact · "Habits and helpers"** Coffee and cigarettes just go together (myth: learned pairing); it helps me concentrate (myth: it fixes the poor focus the gap causes); it helps digestion after a meal (myth); coffee will hit harder after you quit (fact, for smokers: Benowitz, Hall & Modin 1989; vapes and pouches: not applicable, give the variant); you can't break a habit you've had for years (myth).
4. **Try · "Map your autopilot"** Pick your top 3 triggers (onboarding list), and for each: when, where, what you feel just before. Choose tomorrow morning's gap (5 or 15 minutes after waking or first coffee).
5. **Listen · "Tonight: one small gap"** (5 min, evening) Why a short delay matters (you learn the urge passes); plan the morning.

### P3 · Use with your eyes open — *Curiosity*
Big idea: look at the actual experience with curiosity, not the story about it.
1. **Listen · "Curiosity beats craving"** (6 min) What happens when people pay full attention to smoking (Brewer 2011); the story vs the experience.
2. **Reveal · "The stories we tell"** Taste and enjoyment; my reward; my break; it's who I am.
3. **Listen · "One with full attention"** (6 min, to play during a use) A guided, eyes-open use: before, during, after. No judgement, just notice. Can be saved for later in the day. (Variants matter a lot here: cigarette, vape, pouch.)
4. **Try · "Expected vs actual"** Before the guided use: how good do you expect it to feel? After: how good was it? What did you notice (chips + free text)? Stored for the evening recap.
5. **Myth or fact · "Pleasure"** Nicotine makes you feel good (partly: it relieves the gap it caused); non-users are missing out (myth); the first puff of a session is the best (fact, and why); I'll never enjoy a party again (myth); rewards need nicotine (myth).

### P4 · The stress loop — *Calm without it*
Big idea: nicotine doesn't relieve stress; it relieves the withdrawal that adds to stress. Quitting usually lowers stress. (P4 is the first paid day; nothing on screen sells.)
1. **Listen · "Why it feels like it calms you"** (6 min) The loop (Parrott 1999); stress and the gap feel alike; after quitting, people tend to feel less anxious (Taylor 2014).
2. **Breathe · "A breath that works in the moment"** Cyclic sighing: two inhales through the nose, one long exhale (Balban 2023). Tension slider before and after.
3. **Reveal · "What stress actually is"** Stress vs the gap; why the hard days feel harder with nicotine; what really helps in 2 minutes; when stress is more than stress (helpline line).
4. **Myth or fact · "Stress and mood"** Smoking relaxes me (myth); quitting will make me more anxious forever (myth: Taylor 2014; short-term restlessness, then better); I need it when things go wrong (myth); people who quit end up happier on average (fact, Taylor 2014, careful wording); withdrawal irritability is temporary (fact, Hughes 2007).
5. **Try · "Your stress plan"** If-then plans (Gollwitzer & Sheeran 2006): "When [stressor], I will [sigh twice / step outside / text someone]". Pick two stressors, one plan each.

### P5 · Riding the wave — *The skill that matters most*
Big idea: a craving is a wave. Notice it, name it, let it peak and pass. Thoughts are not orders.
1. **Listen · "Surfing the urge"** (7 min) A guided urge-surfing practice (Bowen & Marlatt 2009): body, breath, watching it rise and fall.
2. **Reveal · "Anatomy of a craving"** What sets it off; how long it lasts; why it shrinks each time you ride it; what the voice says.
3. **Try · "The control test"** Imagine throwing your {product} away right now. Notice what shows up (body map, thoughts), rate it 0–10, name it ("I'm having the thought that…"), breathe with the ring for 60 seconds, rate again. Debrief: the panic is the addiction talking, and it passed.
4. **Myth or fact · "Cravings"** A craving keeps growing until you give in (myth); cravings last for hours (myth); one won't hurt after you quit (myth: Kenford 1994, a slip in the first two weeks predicts relapse); thinking about smoking means I'm failing (myth: ACT); cravings become less frequent over the first weeks (fact, Hughes 2007).
5. **Listen · "Thoughts are not orders"** (5 min, evening) Short ACT practice: label thoughts, let them be, keep doing what matters.

### P6 · Make it easy on yourself — *Set up*
Big idea: don't rely on willpower; arrange your space, your support and (if you want) NRT.
1. **Listen · "You don't have to white-knuckle it"** (6 min) Willpower as a muscle that tires; design the environment; why NRT helps some people and how it differs from smoking; prescription options exist (talk to a doctor or pharmacist).
2. **Reveal · "Nicotine replacement, explained"** What it is; patch vs fast-acting (gum, lozenge, spray, inhaler); using two together; is it safe, and who should check first (pregnant, recent heart attack or stroke, under 18 — check with a doctor or pharmacist; follow the pack).
3. **Myth or fact · "NRT"** NRT just swaps one addiction for another (myth); patches don't really work (myth, Cochrane 2018); nicotine is what causes cancer (myth: the smoke does most of the harm; RCP 2016; careful wording); using two kinds of NRT at once is safe and works better (fact, Cochrane 2019, following the pack); I should keep smoking while using a patch (myth: stop when you start).
4. **Try · "Set up your space"** Friction checklist (existing `friction_checklist`), quit kit (existing `quit_kit_checklist`), the NRT choice (existing `nrt_choice`).
5. **Try · "Your people"** Tell someone (existing support message share) and plan if-then for the top 3 triggers from P2.

### P7 · The night before — *Nothing to give up*
Big idea: you're not losing anything; the fears are part of the trap. Know honestly what the first week can feel like. A conscious last one.
1. **Listen · "What you're actually giving up"** (7 min) The fears (I'll miss it, I'll be miserable, I'll gain weight, I'll lose my break) and what's actually true; free, not deprived.
2. **Reveal · "What the first week can feel like"** Honest timeline: first 3 days often the hardest; cravings, irritability, poor focus, hunger, sleep; easing over 2–4 weeks (Hughes 2007; smokefree.gov); what helps each.
3. **Myth or fact · "Fears"** I'll definitely gain loads of weight (myth: average gain about 4–5 kg at 12 months, wide range, some lose weight: Aubin 2012); withdrawal lasts for months (myth: most symptoms ease within 2–4 weeks); I'll never enjoy coffee or a drink again (myth); I'll always miss it (myth); quitting at any age adds years (fact: Doll 2004).
4. **Try · "Clear out and get ready"** Last clear-out checklist (existing `clearout_checklist`), a line to tomorrow-you (existing `note_to_dayxero`), and tomorrow's first hour (what you'll do instead at your top trigger).
5. **Listen · "The last one"** (6 min, evening) A guided, conscious last use, then the commit hold (existing P7.3, 3 seconds).

### DX · Day Xero — *Your first day*
Big idea: you've already done the hard part, which was seeing it. Today you ride the waves and let your body start healing. Quit Day is free.
1. **Listen · "Day Xero"** (6 min, morning) Shown after last night's note. You're not giving anything up. What today holds. What to do with the first craving. Ends on the commit hold "Hold to start Day Xero" (existing DX.2, 3 s, sets `quit_timestamp`).
2. **Reveal · "Your body today"** Quote `DayXeroCore/Resources/health-timeline.json` exactly for the timings and titles (heart rate within minutes; carbon monoxide "A few days"; etc.), cite its source label. Plus what you might feel today.
3. **Breathe · "Your first breaths of Day Xero"** Box or 4-in-6-out with the ring; then a practice run of Craving SOS so they know where it is.
4. **Try · "Your first hours"** If NRT chosen: first dose check (put the patch on now; fast-acting form ready). The plan for the top trigger today. Who to text. Water and food.
5. **Listen · "One day"** (7 min, evening) You did it. What today was. Sleep tonight. Tomorrow (Week 1 Day 1, "Look after the basics").

## 6. Myth-or-fact rules

- Answer is **Myth**, **Fact** or **Partly true** (show "Partly true" as a third outcome; the user still picks Myth or Fact, and either choice gets the same "Partly true" verdict with the nuance).
- Verdict line ≤ 10 words. Explanation 50–90 words, warm, never mocking the belief.
- **Every factual claim has a source** from §9, or from `health-timeline.json`. If a writer wants a source not on the list, they add it to the day file's "Claims to verify" list instead of the screen.
- Never a percentage or number without its source.

## 7. Product variants and tokens

- People use cigarettes, vapes or pouches (some use more than one; the primary product decides).
- On screen and in scripts, mark wording that differs with **`{s: … | v: … | p: …}`** (smoking, vaping, pouches). Example: "Before you {s: light up | v: take a hit | p: put one in}, pause for one breath." Keep the variants as parallel as possible.
- Where the content itself differs (coffee and caffeine; carbon monoxide; smoke), write a short variant note instead.
- App tokens usable **on screen only** (never in audio, which is pre-recorded): `{name}`, `{quit_date}`, `{product}` (cigarette / vape / pouch), `{product_plural}`, `{yearly_units}`, `{unit_plural}`, `{currency}`, `{yearly_cost}`, `{primary_reason}`.
- Audio is rendered three times (one per variant), file `vo_{sessionId}_{stepNo}_{variant}.m4a`.

## 8. ElevenLabs scripts (Eleven v4)

- Write **plain spoken English**, as if talking to one person. Contractions. Short sentences. Questions the listener answers in their head.
- **Pauses:** use `[pause]` (a beat) and `[long pause]` (a few seconds, for the listener to do something). v4 does not take SSML `<break>` tags. Use punctuation for rhythm; ellipses sparingly.
- **Delivery tags** at the start of a chapter or before a line, sparingly: `[warmly]`, `[calmly]`, `[softly]`, `[gently]`, `[slowly]`, `[reassuring]`, `[light laugh]`. No more than one every few paragraphs. Never stack tags.
- **Chapters:** mark each with a heading line `## Chapter N · Title (m:ss approx)`. The app shows them as segments. Chapter headings are not read aloud.
- **Numbers and sources:** say numbers as words where it helps ("about three in a hundred"). Name the source lightly when it adds trust ("a review of studies published in the BMJ"). No URLs, no author lists in audio.
- **No tokens, no names** in audio.
- **Length:** 700–950 spoken words for 6–7 minutes (calm pace, about 130–140 words a minute plus pauses). Give the word count at the end of each script (count spoken words only, not tags or headings).
- **Pronunciation:** if a word might be misread (cytisine, varenicline), add IPA in slashes the first time, e.g. "varenicline /vəˈrɛnɪkliːn/".
- Under each script, a one-line **voice direction** for the whole track (pace, warmth, energy).

## 9. Approved sources

Cite like: *Source: Cochrane, 2018*. Full references go in the day file's Sources section.

| Key | Reference | Use for |
|---|---|---|
| Cochrane2018 | Hartmann-Boyce J et al. Nicotine replacement therapy versus control for smoking cessation. Cochrane Database Syst Rev 2018;5:CD000146 (133 trials). | NRT raises quit rates by 50–60%. |
| Cochrane2019 | Lindson N et al. Different doses, durations and modes of delivery of NRT. Cochrane Database Syst Rev 2019;4:CD013308. | A patch plus a fast-acting form works better than one alone. |
| Hughes2004 | Hughes JR, Keely J, Naud S. Shape of the relapse curve and long-term abstinence among untreated smokers. Addiction 2004;99:29–38. | About 3–5% of unaided quit attempts last 6–12 months. |
| Hughes2007 | Hughes JR. Effects of abstinence from tobacco: valid symptoms and time course. Nicotine Tob Res 2007;9(3):315–327. | Withdrawal symptoms peak in the first week and mostly ease within 2–4 weeks. |
| Babb2017 | Babb S et al. Quitting smoking among adults — United States, 2000–2015. MMWR 2017;65(52):1457–1464. | 68% of adult smokers want to quit; most attempts are unaided. |
| Benowitz2010 | Benowitz NL. Nicotine addiction. N Engl J Med 2010;362:2295–2303. | How nicotine dependence works; half-life about two hours; withdrawal between doses. |
| Benowitz1989 | Benowitz NL, Hall SM, Modin G. Persistent increase in caffeine concentrations in people who stop smoking. BMJ 1989;298:1075–1076. | Caffeine hits harder after quitting smoking (smokers only). |
| Parrott1999 | Parrott AC. Does cigarette smoking cause stress? Am Psychol 1999;54(10):817–820. | Smokers' stress rises between cigarettes; smoking relieves withdrawal, not stress. |
| Taylor2014 | Taylor G et al. Change in mental health after smoking cessation: systematic review and meta-analysis. BMJ 2014;348:g1151. | Anxiety, depression and stress go down after quitting; mood and quality of life go up. |
| Balban2023 | Balban MY et al. Brief structured respiration practices enhance mood and reduce physiological arousal. Cell Rep Med 2023;4(1):100895. | Cyclic sighing (two inhales, long exhale) improves mood and lowers arousal. |
| Brewer2011 | Brewer JA et al. Mindfulness training for smoking cessation: results from a randomized controlled trial. Drug Alcohol Depend 2011;119(1–2):72–80. | Paying attention with curiosity helped people quit (mindfulness training outperformed a standard program). |
| Bowen2009 | Bowen S, Marlatt A. Surfing the urge: brief mindfulness-based intervention for college student smokers. Psychol Addict Behav 2009;23(4):666–671. | Urge surfing reduced cigarettes smoked. |
| Bricker2020 | Bricker JB et al. Efficacy of smartphone applications for smoking cessation: a randomized clinical trial (iCanQuit vs QuitGuide). JAMA Intern Med 2020;180(11):1472–1480. | An ACT-based app helped more people quit than a standard app. |
| Gollwitzer2006 | Gollwitzer PM, Sheeran P. Implementation intentions and goal achievement: a meta-analysis. Adv Exp Soc Psychol 2006;38:69–119. | If-then plans make follow-through more likely. |
| Kenford1994 | Kenford SL et al. Predicting smoking cessation: who will quit with and without the nicotine patch. JAMA 1994;271(8):589–594. | Smoking at all in the first two weeks strongly predicts relapse. |
| Aubin2012 | Aubin HJ et al. Weight gain in smokers after quitting cigarettes: meta-analysis. BMJ 2012;345:e4439. | Average gain 4–5 kg at 12 months, wide range; about 16% lose weight. |
| Doll2004 | Doll R et al. Mortality in relation to smoking: 50 years' observations on male British doctors. BMJ 2004;328:1519. | Quitting at 30, 40, 50 or 60 gains about 10, 9, 6 or 3 years of life. |
| RCP2016 | Royal College of Physicians. Nicotine without smoke: tobacco harm reduction. London: RCP, 2016. | Most harm comes from smoke, not nicotine. |
| HealthTimeline | `DayXeroCore/Resources/health-timeline.json` (ACS, smokefree.gov, CDC). | Body changes after quitting and withdrawal: quote exactly, never paraphrase timings. |

Any claim not covered: put it in "Claims to verify", not on screen. All of this goes through the clinical review in `docs/CLINICAL_REVIEW_CHANGES.md` before launch.

## 10. Day file template

Each `docs/program/<ID>.md` uses this structure:

```
# <ID> · <Title>
**Theme:** … · **Big idea:** one sentence · **By the end of today:** 2–3 outcomes
| Step | Format | Title | Min | Ground |   (day at a glance)

## Step 1 · Listen · <Title> (<n> min)
Screen: ground, chapters (titles), what shows before/after.
Commit button: "…"
### Script (Eleven v4)
Voice direction: …
## Chapter 1 · … (0:00)
…
Word count: N spoken words (≈ m:ss)

## Step 2 · Reveal · <Title> (<n> min)
Intro line: …
### Card 1
Front: … · Answer: … · Go deeper: … · (Source if any)
… ×4
Commit button: "…"

## Step 3 · Myth or fact · <Title> (<n> min)
### Statement 1
"…" · Answer: Myth|Fact|Partly true · Verdict: … · Explanation: … · Source: …
… ×5
Commit button: "…"

## Step 4 · Try · <Title> (<n> min)
Purpose. Then each screen: Screen N · title · exact copy · input (type, options, saveAs) · button.
Completion message. Commit button.

## Step 5 …

## End of day
What you learned today (3) · Mission (text + logType) · Tomorrow · Completion line

## Sources
## Claims to verify
## Notes for the build (new saveAs keys, new logTypes, data the step needs)
```

## 11. What we learned from QuitSure (summary)

See `research_notes/quitsure_day1_teardown.md`. In short: borrow the commitment buttons in the user's voice, named and timed steps, permission to keep using, naming the mind-tricks, the control test, the reasons journal, honest expectations and the day recap. Do differently: far less reading, warmer tone, a source on every claim, positive on NRT, no selling in lessons, no graphic health scares, no promise of zero withdrawal. Never copy their wording, pictures or numbers.
