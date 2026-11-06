# DX · Day Xero: build notes for DX.json

Built from `docs/program/DX.md`, following `docs/program/DECK_SCHEMA.md`. Kept from the current `program.json` DX: `id`, `phaseId` (`dayxero`), `label`, `unlock` (`"rule": "day_xero"`), `audio`, `title`, `subtitle`, the mission (text and `logType: craving_outcome`) and `completionText`. `listenHint` and the old `cards` stack are gone; `beats` is `[]`.

## Cards

| Card | Format | Title | Min | Ground |
|---|---|---|---|---|
| DX.1 | listen | Day Xero | 6 | apricot |
| DX.2 | reveal | Your body today | 5 | (deck) |
| DX.3 | breathe | Your first breaths of Day Xero | 5 | sky |
| DX.4 | try | Your first hours | 7 | mint |
| DX.5 | listen | One day | 7 | violet |

`durationMinutes` is 30.

## Old beats, new places

- Old `DX.1` (note "From you, last night", `textFrom: note_to_dayxero`, `skipIfEmpty`) is now `DX.1a`, in card DX.1's `before`. `position: before_audio` is dropped because `before` already says where it goes.
- Old `DX.2` (commit "Hold to start Day Xero.", 3 s, `sets: quit_timestamp`) is now `DX.1c`, the first beat after the morning track. **This hold starts the counter.** The draft says it must be reachable when the track is skipped or paused, so the deck player has to offer the card's `beats` even if the listen isn't finished.
- Old `DX.3` (tap_reveal "What today might bring") is replaced by the DX.2 reveal. Its copy is in reveal card 3.
- Old `DX.4` (breathe `box`, 2 cycles) is now `DX.3b`, with 4 cycles as the draft asks.
- `CommitBeat` picks the Day Xero hold by `sets == "quit_timestamp"`, not by id, so the new id is safe. `NoteBeat` tints notes whose id starts with "DX", and `DX.1a` still does.

## Substitutions (things the app can't show yet)

1. **Patch line under the note** (`DX.1b`). The draft shows it when `nrt_plan` is `setup` or `have`. The closest condition is `showIf: nrt_active`, which means an NRT plan is running in the app. People who chose "have" without setting up a plan won't see it.
2. **"Your reason: {primary_reason}" above the hold.** There is no separate beat for it. The Day Xero hold view (`CommitBeat.dayXero`) already shows "BECAUSE" with a reason, but it takes the person's first reason, not `primary_reason`. It should use `primary_reason`, as P1 promised.
3. **The line after the hold** ("Day Xero has started. Your counter is running.") is an `info` beat (`DX.1d`) after the commit.
4. **Reveal timeline chips.** A reveal card has no chip field, so each quoted chip (when · title · line, exactly as in `health-timeline.json`) starts the `answer`. The smoking-only chip on card 3 goes at the end of the smoking answer, after a blank line. Cards 1 and 2 differ by product, so `answer`, `deeper` and `source` are product objects. Source lines are short forms with the internal group and item ids taken out.
5. **Round 2 breathing: no 4-in, 6-out pattern.** The orb only has `box`, `478`, `wave` and `sigh`. `DX.3d` uses `wave` (5 in, 2 hold, 5 out, 2 rest), 4 cycles, about 56 s, with the label "Wave riding · slow in, slow out, like riding a wave". It doesn't claim to be the SOS rhythm. The after-screen (`DX.3e`) says that Craving SOS breathes in for 4 and out for 6. To build it as drafted, add a pattern (for example `sos46`: Inhale 4, Exhale 6, no hold or rest) to `breathing_orb_data.json`, the validator's `PATTERNS` and the schema, then switch `DX.3d` to it with 6 cycles and the label "This is the rhythm Craving SOS uses."
6. **Craving SOS practice run** (draft screens 5–8). Practice mode is decided but not built yet, so I used two `info` beats. `DX.3f` ("How Craving SOS works") covers the three sighs, the 4-in, 6-out breathing, the clock counting up, the reason card, the hands pad and break ideas, and what "It passed" (one wave ridden), "Still strong" (more calm tools) and "I slipped" (a short, kind talk-through, and the count is never reset) do. `DX.3g` ("Where to find it") covers the tab bar and the Home Screen widget. Once practice mode exists, put a practice launch between `DX.3e` and `DX.3g`, opened with source `program_dx_practice`, logging nothing, with no Live Activity and no slip flow. The draft's sky-then-ocean grounds become `sky` only.
7. **NRT branch** (draft screens 2A–2F). There are only two conditions, `nrt_active` and `nrt_not_active`:
   - `nrt_active` (a plan is set up): `DX.4b` is an info beat with the dose line and the safety line, and `DX.4c` is the "First dose check" checklist (`dx_nrt_check`). All three items show; the checklist can't filter them to the forms in the plan. It doesn't sync "Patch on today" with the NRT card, and there's no "How to chew and park" link.
   - `nrt_not_active` (`have` with no plan, `setup` not finished, `no`, `taper`, or P6 skipped): `DX.4d` is one choice, "Your NRT", saved as `dx_nrt_ready`. Options: "Yes, it's here", "Not yet", "Not this time", and for pouches only, "I stepped down my pouch strength instead". Each option's `feedback` carries the 2C, 2D, 2E or 2F text, written out per product because option feedback isn't run through placeholders. Someone who picks "Yes, it's here" gets the dose guidance as feedback but not the checklist.
8. **"This morning's plan"** (`DX.4e`, `DX.4f`). The plan is a `note` reading `dx_first_hour_plan` with `skipIfEmpty`, so it hides when empty, but it shows the action only, not "If it's {dx_first_trigger}". The question after it, `DX.4f` (`dx_first_hour_used`, optional), still shows when there's no plan. It needs a skip-if-empty rule keyed to `dx_first_hour_plan`.
9. **Biggest trigger** (`DX.4g`). It uses `optionsFrom: autopilot_triggers` with `allowOther`. When that list is empty, the onboarding triggers aren't offered; only "Something else" shows. The saved lines are whatever P2 stored. If those are raw `Trigger` ids, the app has to map them to titles.
10. **"Then I'll…" prefilled from Prep 6** (`DX.4h`, `DX.4i`). A choice can't prefill one entry from `trigger_plans`. `DX.4h` shows the Prep 6 plans as a `plan_card`, then `DX.4i` is a choice from a general list of suggestions (from P6's plan_builder and `nextTimeSuggestions`) with `allowOther`, saved as plain text in `dx_today_plan`. There's no live sentence "If it's {situation}, then I'll …".
11. **Your people** (`DX.4j`, `DX.4k`). The choice can't open the share sheet, so `DX.4k` is an optional `share` beat (`support_message`) with the draft's message. It shows to everyone, not only after "Send a message now". The "On Prep 6 you picked {support_person}." opening isn't possible, because a saved answer can't be a placeholder.
12. **The basics** (`DX.4l`). Checklist items are a product object; smokers get the extra "Coffee at half strength today". The draft's "Why?" sheet becomes the smoking-only `footer`, with the source in brackets. The body line is in `body`, which `ChecklistBeat` doesn't render yet (the same gap as P7).
13. **Summary card** (`DX.4m`). This is a `plan_card` with `fields: [dx_nrt_check, dx_nrt_ready, dx_today_trigger, dx_today_plan, dx_told_someone, dx_basics]`. The draft's sentence lines ("Patch on. Fast-acting form with me.", "{n} of {m} basics sorted.") need `PlanCardBeat` headings and formatting for these keys. As it stands, it shows default headings and the raw saved texts. The completion message is `DX.4n` (info).
14. **"Waves ridden today: {n}"** before the evening track. There's no field for it, and `{cravings_ridden}` is the all-time count, so it's left out. "Opens from 6 pm" for DX.5 needs app logic too, as on P7.
15. **Hold length.** `holdSeconds: 3` is kept. `CommitBeat` now uses `DX.Move.hold` for every hold, while the DX.1 script says "press and hold … for three seconds". One of them needs to change.

## saveAs keys

**New:** `dx_nrt_check` (checklist), `dx_nrt_ready` (here, not_yet, no, taper, saved as option text), `dx_first_hour_used` (helped, hard, not_yet), `dx_today_trigger` (text), `dx_today_plan` (text), `dx_told_someone` (send, done, not_today), `dx_basics` (checklist). The commit sets `quit_timestamp`.

## Reads from earlier days

`note_to_dayxero` and `dx_first_hour_plan` (P7), `autopilot_triggers` (P2.4a) and `trigger_plans` (P6.5f). All of them are saved in `docs/program/json/P1–P7`, so the validator reports nothing. `primary_reason` comes through the hold view (see substitution 2), and `nrt_plan` only through `nrt_active` (see 1 and 7).

## Other

- `FullProgram.swift` still lists Day Xero as paid, as decided (README "Decided"). Nothing in this file sells.
- Variant wording follows the coordinator's rule: there's no inline markup in option texts or checklist items. Those use product objects, as do the reveal cards that differ by product.
