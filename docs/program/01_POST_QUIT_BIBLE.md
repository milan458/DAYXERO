# DayXero Program v3 · After Day Xero (Week 1 to Week 4 and boosters)

**Status:** draft for Milan's review, 15 Nov 2026. Extends `00_PROGRAM_BIBLE.md`; everything there still applies (method, voice, tokens, ElevenLabs rules, approved sources). This file adds only what is different after Quit Day.

**Decided (Milan, 15 Nov 2026):** post-quit sessions are 3 cards and 10 to 12 minutes (20 new tracks, 60 renders). P1 to P7 and DX get continuity edits only. Session ids, days and count stay as they are in `program.json`.

---

## 1. The story after Quit Day

One story, one narrator: **the gap closing**. Prep showed the gap. Day Xero stopped refilling it. From here the user feels it fade and learns to live in the quiet it leaves.

| Chapter | Sessions | The narrator's line | Reads back from earlier |
|---|---|---|---|
| The loudest days | W1D1 to W1D3 (Days 1 to 3) | The gap is loud because nothing is refilling it. Basics first. Getting through is enough. | P1 "where do I feel it", P5 control test, `primary_reason` |
| The voice gets clever | W1D4 to W1D6 (Days 4 to 6) | Flat mood, nights out, "just one". Thoughts are passengers. You're driving. | P4 sigh, `support_person`, P3 `mindful_expected` / `mindful_actual` |
| One week | W1D7 (Day 7) | The faucet has stopped dripping. Listen to the quiet. | P1 faucet, `note_to_dayxero`, `reasons` |
| The empty minutes | W2S1 to W2S3 | Where the gap was, there is time. | `autopilot_map`, `morning_anchor` |
| Echoes | W3S1 to W3S3 | Old cues and heavy days are echoes, not the gap coming back. | `stress_plan_1`, `stress_plan_2`, `trigger_plans` |
| Who you are now | W4S1 to W4S3 | "I don't use nicotine." The quiet is yours. | Everything; the first P1 check-in |
| Staying | B45, B60, B90 | Three short visits while the last of it settles. | Graduation |

## 2. Shape of a post-quit session

Three cards, in order, 10 to 11 minutes:

| # | Format | Length | Purpose |
|---|---|---|---|
| 1 | **Listen** | about 4 to 4:30, **450 to 550 spoken words**, 4 chapters | Names the day, one idea, one short body-based practice, hands over to card 2 |
| 2 | **Try** | 3 to 4 min | One activity that produces something saved (`saveAs`) and reused later |
| 3 | **Myth or fact** | 2 to 3 min, **3 statements** | The quiz. Same rules as bible §6 |

Then the recap: 3 lines learned, one mission, tomorrow's teaser, completion line. Commit buttons in the user's words, as in prep. Listen grounds: apricot. No evening card after Day Xero.

## 3. Rules that keep it one story

1. **Name the day, then name what's next.** Every track opens with where the user is ("Day three.") and closes on tomorrow.
2. **Honest first, then practical.** What this day often feels like, then one thing to do.
3. **Read something back.** Every session shows at least one answer the user saved earlier. On screen, use the saved value. In audio, point to it without saying it ("the reason you chose on your first day").
4. **Body before thoughts.** Each practice starts with where the urge sits in the body and letting it be there, then the thought. (In the iCanQuit trial, accepting sensations and emotions carried the effect; accepting thoughts did not.)
5. **Only these images:** the gap, the wave, the autopilot, the story, the faucet. One new image is allowed, on Day 2 only: passengers on a bus, introduced as another way to see the voice from Prep 5.
6. **Practice, not lessons.** One idea a session. If a paragraph teaches without asking the listener to do or notice something, cut it.
7. **A reward at each week mark** (Days 7, 14, 21, 30), paid from money kept.

## 4. Claims and wording (stricter than prep)

Audio after Quit Day uses the approved spoken wordings in the project's `DAYXERO_AUDIO_STYLE_GUIDE.md` §6 (C1 to C21, X7) and its do-not-say list. In particular, narration never gives:

- a statistic, percentage or success rate
- a fixed length for a craving
- a brain or receptor timeline ("rewiring" is fine; "rewired by day 21" is not)
- dosing, strengths, or starting nicotine replacement before Quit Day
- a promise that today will be easier than yesterday

**The one line on slips, used everywhere:** "A slip doesn't undo anything. The most useful thing is to get straight back to your plan, right now, not tomorrow." Where honesty needs more, add: "A slip does make the next one more likely, which is why the next hour matters."

**Low mood (W1D4, W2S4, W3S1):** always carry the X7 safety line and the on-screen helpline link.

Words to avoid in audio (style guide §5): should, must, need to, failed, relapse as a verdict, clean, streak, reset, start over, give in, weak.

## 5. Variants

Most post-quit tracks are written product-neutral ("use", "your next one", "nicotine") with `{s: … | v: … | p: …}` only where the habit differs. Every track is still rendered three times so file naming stays uniform: `vo_{sessionId}_1_{variant}.m4a`.

## 6. Notes for the build

- Post-quit sessions move from the old `cards` + `beats` shape to a 3-card `deck`. `DECK_SCHEMA.md` needs two relaxations: a deck may have 3 cards, and a `myth` card may have 3 statements.
- Labels: W1D1 is "Day 1" through W1D7 "Day 7" (the current "Day 2" to "Day 8" labels are the bug already listed in the README).
- Existing `saveAs` keys from the stubs are kept so testers' records stay valid. New keys are listed in each day file.
