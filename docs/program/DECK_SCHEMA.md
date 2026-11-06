# Deck sessions in program.json

How a prep day or Day Xero (P1–P7, DX) is written in `DayXeroCore/Resources/program.json` once it uses the card deck (mockups F1–F9 in `design/program-deck/`). Other sessions (W1D1 onward) keep the old shape.

## Session

All the old session keys stay, with these values:

```json
{
  "id": "P1", "phaseId": "prep", "label": "Prep 1",
  "title": "You don't have to quit today", "subtitle": "How the prep week works", "durationMinutes": 30,
  "unlock": { "rule": "first" },
  "audio": { "variants": ["smoking", "vaping", "pouches"] },
  "beats": [],
  "deck": [ /* 5 cards, in order */ ],
  "recap": { "learned": ["…", "…", "…"], "statLines": ["…"], "tomorrow": "…" },
  "mission": { "text": "…", "logType": "use" },
  "completionText": "…"
}
```

- Keep `id`, `phaseId`, `label` and `unlock` exactly as they are now. `durationMinutes` is the day's total (sum of card minutes).
- `beats` is always `[]` for a deck session (the beats live inside the cards). No `cards` key (the old 90-second stack), no `listenHint`.
- `recap.learned`: exactly 3 lines (the day file's "What you learned today"). `recap.statLines`: optional, P1 only (the money reveal, using the old P1.1 lines). `recap.tomorrow`: the day file's "Tomorrow" line.
- `mission`: the day file's mission. `logType` must be one of `use`, `morning_buffer`, `mindful_use`, `stress_sigh`, `surf_practice`, `craving_outcome`, or left out. A mission may keep `followUp` beats (P3 keeps P3.F1/P3.F2 if the day file uses them).
- `completionText`: the day file's completion line.

## Card

```json
{
  "id": "P1.1", "format": "listen", "title": "Keep using. Just watch.", "minutes": 6,
  "ground": "apricot", "commit": "I'll just watch today",
  "intro": "One line under the title.", "after": "Optional line shown when the track ends.",
  "script": { "voice": "…", "chapters": [ { "title": "You don't have to quit today", "text": "…" } ] },
  "before": [ /* beats before the main view, optional */ ],
  "beats": [ /* beats after the main view, optional */ ]
}
```

- `id`: `<session>.<n>`, n = 1…5 in order. Beat ids inside a card: `<card id><letter>`, e.g. `P1.4a`, `P1.4b`. Every id is unique in the whole file.
- `format`: `listen`, `reveal`, `myth`, `try` or `breathe`. Every card of a day: exactly 5.
- `title`, `commit` (2–5 words, the user's own words, from the day file), `minutes` (int).
- `ground`: optional. Listen: `apricot` (morning) or `violet` (evening). Try: `mint`, or `ocean` when it's about cravings. Breathe: `sky`. Reveal and myth leave it out (they're on the deck's violet).
- `intro`: optional one line shown under the title before the card starts.
- `before` / `beats`: lists of ordinary beats (see below), shown before / after the card's main view. A `try` or `breathe` card has its content only in `beats` (at least one). Listen, reveal and myth may add beats after (Day Xero's hold, Prep 7's hold).
- `canSaveForLater` + `laterTakes`: only P3.3 (`"canSaveForLater": true, "laterTakes": ["P3.4"]`).

### Listen

`script.chapters`: every chapter of the day file's script, `title` = the chapter heading without "Chapter N ·" and without the time, `text` = the chapter's spoken text exactly as written (keep `[pause]`, `[long pause]`, delivery tags and `{s: … | v: … | p: …}` markup; paragraphs separated by a blank line, `\n\n`). `script.voice` = the voice direction line. The app shows the script to read until the recordings exist, then plays `vo_P1_1_<variant>.m4a`.

### Reveal

```json
"cards": [ { "front": "Why does the first one feel so good?", "answer": "…", "deeper": "…", "keep": "…", "source": "Benowitz, NEJM 2010" } ]
```

4 to 6 cards, each `front`, `answer`, `deeper` (the "Go deeper" text), optional `keep` ("Keep in mind" line) and optional `source` (short form, no "Source:" prefix).

### Myth or fact

```json
"statements": [ { "text": "I use it because I enjoy it.", "answer": "partly", "verdict": "…", "explanation": "…", "source": "Benowitz, NEJM 2010" } ]
```

5 statements. `answer`: `myth`, `fact` or `partly`, or an object by product when it differs (`{"smoking": "fact", "vaping": "myth", "pouches": "myth"}`). `text` without surrounding quote marks (the app adds them).

### Try and Breathe

Only `beats`, built from the app's existing beat kinds. Read `DayXeroCore/Resources/program.json` for working examples of every kind and `DayXero/ProgramV2/BeatsA.swift` / `BeatsB.swift` for what each renders. The kinds and their main fields:

| kind | use it for | key fields |
|---|---|---|
| `info` | an instruction or explanation screen | `title`, `body` |
| `note` | showing a saved answer | `title`, `textFrom`, `skipIfEmpty` |
| `choice` | pick one or several | `prompt`, `options` [{id, text, feedback?}], `multi`, `allowOther`, `saveAs`, `optionsFrom`, `pick` |
| `quiz` | one right answer | `prompt`, `options`, `correctId`, `feedback` |
| `slider` | a 0–10 style rating | `prompt`, `minLabel`, `maxLabel`, `saveAs`, `compareWith`, `compareLabels` |
| `slider_group` | several sliders | `prompt`, `items` [{id, label, minLabel, maxLabel, saveAs}] |
| `reflect` | free text | `prompt`, `placeholder`, `saveAs`, `prefillFrom`, `length` (short/long), `maxEntries`, `guidePrompts` |
| `checklist` | tick items | `title`, `items` (list, or object by product), `saveAs`, `carryOverFrom` |
| `plan_builder` | if-then plan | see P1–W1 examples (`prompt`, `fields`, `suggestions`, `saveAs`) |
| `plan_card` | show a saved plan | see examples |
| `breathe` | guided breathing | `pattern` (`box`, `478`, `wave` or `sigh` only), `cycles`, `label` |
| `commit` | press-and-hold | `text`, `holdSeconds`, `sets` (only `quit_timestamp`, `dayxero_ready`, `graduated_at`) |
| `nrt_choice` | the NRT set-up choice | copy the existing P6.3 beat exactly |
| `share` | the support message | copy the existing P6.4 beat |
| `tap_reveal` | flip cards | `cards` [{front, back}] |
| `stat_reveal` | lines with numbers | `lines` |

Rules: keep existing `saveAs` keys where the day file says so (reasons, primary_reason, morning_anchor, first_use_automatic, mindful_expected, tension_before/after, urge_signals, friction_checklist, quit_kit_checklist, nrt_plan via nrt_choice, note_to_dayxero, clearout_checklist…). A beat may only read (`optionsFrom`, `prefillFrom`, `textFrom`, `compareWith`, `carryOverFrom`…) a key that an earlier beat (in this or an earlier session, in order) saves, or `reasons` / `primary_reason`. When the day file asks for a UI piece that doesn't exist (body map, 0–10 stepper, timed hold, repeating sheet), use the closest kind (a multi `choice`, a `slider`, an `info` screen) and list the substitution in the session's notes file.

Where the day file has a commit hold, keep it as a `commit` beat: P1's Quit Day hold (old `P1.5`, `holdSeconds` 2, text "Hold to commit to your Quit Day: {quit_date}"), P7's (old `P7.3`, `sets: dayxero_ready`), Day Xero's (old `DX.2`, `sets: quit_timestamp`, at the end of card DX.1). Day Xero's "From you, last night" note (old `DX.1`) goes in card DX.1's `before`.

## Text

Any on-screen string may be plain, or an object by product (`{"smoking": "…", "vaping": "…", "pouches": "…"}`, or with `"default"`), or carry inline `{s: … | v: … | p: …}` markup (all three parts, no braces or `|` inside a part). Placeholders allowed on screen: `{unit_singular}`, `{unit_plural}`, `{daily_units}`, `{yearly_units}`, `{currency}`, `{yearly_cost}`, `{quit_date}`, `{primary_reason}`, `{days_free}`, `{money_kept}`, `{cravings_ridden}`, `{product}`, `{product_plural}`. No `{name}` (the app has no first name) and no placeholder inside variant markup. No exclamation marks, US spelling.
