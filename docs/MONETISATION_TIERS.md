# Free vs full program, price anchor, 90-second read (MON-01, MON-03, MON-04; 2 Nov 2026)

The proposal: v1's paywall came too early (Prep Day 2) and v2 gave too much away. The fix is a free taste of prep,
then a 7-day trial. This replaces **decision 15** (whole prep week free, trial sold only from Quit Day) and most of
**decision 23** (Day Xero free, offer after it). S30 in `planning/tasks.json`.

## Decisions (Milan, 2 Nov 2026)

| Question | Answer |
| --- | --- |
| When is the trial sold? | At the Prep 4 paywall, **whatever the Quit Day is**. 7 days. With the usual week of prep it ends 3 days after Quit Day; the paywall says where it ends against the Quit Day either way. |
| Craving SOS | **Stays free.** Only Jelli's voice in it is paid; free users get the same sighs with subtitles and haptics. |
| MON-04 vs the audio lessons | **Card stacks next to the audio.** The card stack is the default; "Listen instead" plays the recording when there is one, and the choice sticks. |

## Tiers

| Free forever | Full program (7-day trial, then ₹2,999 / $39.99 a year) |
| --- | --- |
| Prep 1–3, the counter, Craving SOS, the 60-second breathing timer (box breathing in Calm tools), evening check-ins | Prep 4–7, the Day Xero session, Weeks 1–4 (and the boosters), Jelli's voice coaching, the if-then slip planner, the 12-week NRT scheduler, trigger heatmaps |

The rule lives in one place, `DayXeroCore/Logic/FullProgram.swift`. `ProgramV2Access` and the old `FreeTier` both
read it.

## What changed in the app

| Where | Free user sees |
| --- | --- |
| **Today / Program** | Prep 4 onwards shows **Unlock**: Superwall's `unlock_program_day` placement, or DayXero's upgrade sheet. |
| **Prep 3 done** | "Prep 4 starts the full program. You can try it free for 7 days." under the next-session line. |
| **Upgrade sheet (Prep 4)** | "Prep 1 to 3 were the free taste…", the price anchor, the yearly plan with its trial, and "That's 3 days after your Quit Day, so Day Xero is covered." when it is. |
| **Paywall** | New included list (Prep 4–7 and the Day Xero launch kit, Weeks 1–4, voice coaching, if-then planner and NRT schedule, trigger heatmaps), the price anchor, and one line on where the trial ends against the Quit Day. Every plan is sold any day; the hold until Quit Day is gone. |
| **Onboarding plan screen** | "Prep 1 to 3 are on us." The trial card is "At Prep 4 · Thu 5 Nov" (onboarding on Mon 2 Nov), with the end date and how it falls against the Quit Day. |
| **Every paywall** | "Always free: Prep 1 to 3, your counter, Craving SOS and a 60-second breathing timer." |
| **Slip flow** | The thanks and "nothing resets" as before, then a locked "Plan for next time" card, Done, and "Add what happened". The fresh-Quit-Day offer still shows. The Day 28 practice always has the planner. |
| **NRT setup** | The intro and its facts are free; the button is "Unlock the full program". Plans made while subscribed keep their reminders. |
| **Progress › Your patterns** | Before a week of logs, the same early view as everyone. Once ready, their own heat map blurred under a locked card. The weekly trend and recent logs stay free. |
| **Voice** | Craving SOS sighs and the breathing coach are silent (VoiceOver still announces the cue). Settings › Voice guidance says it comes with the full program. |
| **Settings › Unlock** | Superwall's `upgrade_from_settings` any day; the prep-only fallback to DayXero's paywall is gone. |

The Quit Day offer after Day Xero (decision 23) stays in the code: Day Xero is paid now, so it only reaches someone
whose subscription ended part-way.

## MON-03 price anchor

"Costs 8 days of smoking": the yearly price divided by the person's own daily spend (onboarding's baselines,
`ProgressStats.moneyPerYear / 365`), **rounded up** so it never understates the price. "Smoking", "vaping" or
"pouches" for one product; "nicotine" for more than one. It's hidden when:

- the store price and their spend are in different currencies (an Indian App Store account with a USD spend),
- there's no spend, or
- it would be more than **90 days** (a light user's year can cost months of spend, which argues against buying).

Shown on the paywall and the Prep 4 upgrade sheet. `PriceAnchor` in `FullProgram.swift`.

## MON-04 90-second read

Each of the 27 sessions has 4 cards in `program.json` (`cards`, front and back, variants allowed; P7's battery note
is vaping only). They replace the audio step; the session runs intro, activities before the lesson, **the cards**,
the rest, mission, done. Tap a card or "Turn it over" to see the idea, then "Next card"; swipe works too. Under Reduce
Motion they cross-fade. Replays can skip through.

- **Content is a draft.** Every card is written from the session's own copy (titles, tap-reveals, feedback, missions);
  no new health claims. Needs Milan's read, ideally against the spoken scripts doc.
- `program.json` is now **2.1.0**, so a session left half-done restarts at its first activity after the lesson,
  keeping answers.
- The content checker fails a session with fewer than 3 or more than 5 cards, or a card missing a product's wording.

### Session lengths (Milan, 2 Nov 2026: shorten them for the card version)

Today, the Program path and its sheet, the session intro, the Day Xero commit screen, the widget and the "lesson
ready" notification show `ProgramStore.minutes(of:)`: the read version's length, or `durationMinutes` for someone who
chose "Listen instead" and has a recording. The read length (`Session.readMinutes()`) is worked out from the content:
90 s of cards, each activity at a typical pace (`Beat.typicalSeconds`: a breathing beat is its cycles of its pattern,
flip cards 8 s each, sliders 10 s, choices and quizzes 15 s, writing 30 s), plus 30 s for the intro, mission and
completion. Rounded to the nearest minute, at least 2, never more than the listening length.

P1 5→3 · P2 5→3 · P3 6→2 · P4 6→3 · P5 6→3 · P6 6→3 · P7 5→3 · DX 5→4 · W1D1 3→3 · W1D2 3→3 · W1D3 3→3 ·
W1D4 3→2 · W1D5 4→3 · W1D6 4→3 · W1D7 3→3 · W2S1 4→2 · W2S2 4→3 · W2S3 4→3 · W3S1 5→4 · W3S2 4→3 · W3S3 4→3 ·
W4S1 4→3 · W4S2 4→4 · W4S3 5→3 · B45 4→3 · B60 4→3 · B90 4→3

## Open questions

1. **Per-activity timings** behind the lengths above are estimates; adjust `Beat.typicalSeconds` if testing shows
   people take longer.
2. **Card copy**: review all 108 cards (see `program.json`), especially the week sessions.
3. **India price**: ₹2,999 is set by hand in App Store Connect (the setup script sets a US price and Apple's
   equivalents). The setup script's trial is now one week, but it only applies where no trial exists yet; the live
   trial length is also an App Store Connect change.
4. **Price anchor cap** of 90 days, and rounding up: confirm.
5. **Weekly trend and recent logs** on Progress stayed free (only the heat map and triggers are "trigger heatmaps").
6. **Pouch taper** ("Step down your pouches", before Quit Day) stayed free; it isn't NRT.
7. **Superwall campaigns** need their paywall copy updated to the new tiers in the dashboard (S20.4).
