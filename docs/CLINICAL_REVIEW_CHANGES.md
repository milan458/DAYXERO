# Clinical review changes (CLIN-01 to CLIN-11)

Built 2 Nov 2026 on `claude/elegant-fermat-8bg8iv`. Tracked as S29 in `planning/tasks.json`. All copy is a draft for Milan.

| ID | Where it lives | What changed |
|---|---|---|
| CLIN-01 | `health-timeline.json` (group `recovery`, kind `felt`), `HealthTimelineView`, Today's recovery card, Progress | Three items for every product, roughly Days 10–45: flat, foggy days; head clearing; small pleasures feel good again. Every title starts "Many people notice". They show a rough window ("Often weeks 2 to 3"), with no countdown, no progress bar and no source. The detail sheet says the research on timing is thin. |
| CLIN-02 | `CaffeineAlert`, Today | From Quit Day through Day 7, people who smoke and picked coffee as a trigger see Xero's note "Coffee hits harder this week… I'd halve your coffee this week." "Why?" links Benowitz et al., BMJ 1989. People who only vape or use pouches don't see it, and nor do NRT users. "Got it" hides it for that Quit Day. |
| CLIN-03 | `NRTUseGuide`, `NRTSetupView`, `NRTCard`, `NRTReminderPlan` | Gum: a "chew and park" card in setup, plus a sheet from the NRT card. Patch: an "At night" choice between 24 hours and 16 hours (off at bedtime), also a toggle on the NRT card. The UK 16-hour presets start on off-at-bedtime. A 16-hour patch gets "Patch off for the night" 16 hours after the fresh-patch time. |
| CLIN-04 | `RewardDefusion`, `CalmToolsView` | "Just finished something?" sits at the top of the calm tools. It has three steps: notice the thought, accept that you do deserve a reward, then pick a real reward. |
| CLIN-05 | `SwapTrap`, Today (prep) | Xero flags cigarettes or puffs that drop to 75% of baseline or less while pouches rise by at least 25% and by 2 or more a day. It looks at the last 2–3 full days. |
| CLIN-06 | `NotificationPlan.GraduationStage`, Settings › Notifications | Quiet graduation is on by default. Weeks 1–2 stay as now. Weeks 3–4 drop the pledge note and send at most 2 a day. From Week 5 it's at most 1 a day, and the check-in comes every other day. |
| CLIN-07 | `Resilience.Days`, Today's post-quit hero | "45 of 46 days smoke-free · 98%" (or vape-free / pouch-free). It rounds to the nearest whole number but never shows 100% when there's been a slip. It never resets. |
| CLIN-08 | `program.json` session `W2S4` | "The flat days" opens on Day 13, between "Sleep and strange dreams" and "Two weeks". It has a tap-reveal, a quiz, a pick of two fog-friendly habits, a clarity slider, and an "If the low stays" helpline note. |
| CLIN-09 | `Trigger.finishedTask` | "Finished a task / chore" comes with four next-time ideas. |
| CLIN-10 | `LogRouter.Page.slipPlan`, `SlipPlanRequest` | The log sheet, SOS and the check-in already opened the planner. Two paths now do too: Today's use buttons from Quit Day on open it, and a slip from Siri or the widget opens it the next time the app opens (only within 12 hours, and only if the slip has no plan yet). |
| CLIN-11 | `PrepChallenge`, Today (prep) | Eight one-minute challenges, one per prep day, each ticked with a single tap. |

## For Milan

1. **CLIN-07 wording.** I used "smoke-free" instead of "clean". It matches the hero, and "clean" reads as stigmatising in addiction care. Switching it is a one-line change.
2. **CLIN-07 conflict.** The inactivity rule is already pause-and-replay (S5.7): after 3 idle days the next lesson waits for a replay, and the day count is untouched. So nothing resets there. The one path that does restart the count is Jelli's **fresh Quit Day** offer after slips on 4 of the last 7 days. Should resilience carry across a fresh Quit Day, or should the offer go?
3. **CLIN-08 id.** The new session is `W2S4` even though it comes before `W2S3`. Session ids are saved in people's records, so the existing ones stay put, and order comes from the list. Testers who already finished Week 2 will see it open as a catch-up.
4. **CLIN-11 content** needs review, along with the CLIN-04 rewards and all CLIN-01 / CLIN-08 copy.
5. **CLIN-02 source.** Benowitz NL, Hall SM, Modin G. BMJ 1989;298:1075–6. Please check it before launch, as with the NRT label sources.
