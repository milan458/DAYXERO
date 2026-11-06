# Program v3 · Prep week and Day Xero (draft)

Status: full first draft, 6 Nov 2026. For Milan's review, then clinical review (`docs/CLINICAL_REVIEW_CHANGES.md`), then conversion to `program.json`.

| File | What it is |
|---|---|
| `00_PROGRAM_BIBLE.md` | Method, voice, day shape, day-by-day plan, approved sources, ElevenLabs v4 rules, file template. Read first. |
| `P1.md` … `P7.md` | The seven prep days. |
| `DX.md` | Day Xero (Quit Day). |
| `../../design/program-deck/` | The final mockups (F1–F9): D's hand of cards and reveal grid, C's live-caption audio, D's myth-or-fact deck. |
| `../../research_notes/quitsure_day1_teardown.md` | What we took from QuitSure's Day 1, and what we do differently. |

Each day: 5 cards (Listen, Reveal, Myth or fact, Try, Breathe), 5–7 minutes each, about 30 minutes. Every card ends on a button in the user's own words. Each day file ends with a recap, the mission, **Sources**, **Claims to verify** and **Notes for the build**.

## The 14 audio tracks (ElevenLabs v4)

Each track is rendered three times (smoking, vaping, pouches) from the `{s: … | v: … | p: …}` markup, so **42 renders**. Strip chapter headings before rendering; keep `[pause]`, `[long pause]` and the delivery tags. File name: `vo_{sessionId}_{step}_{variant}.m4a`.

| Session · step | Track | Length | Spoken words (s / v / p) |
|---|---|---|---|
| P1 · 1 | Keep using. Just watch. | ≈ 6:30 | 849 / 851 / 854 |
| P1 · 5 | Tonight: what you noticed (evening) | ≈ 7:00 | 828 / 829 / 829 |
| P2 · 1 | The autopilot | ≈ 6:20 | 794 / 796 / 798 |
| P2 · 5 | Tonight: one small wait (evening) | ≈ 5:00 | 631 / 633 / 632 |
| P3 · 1 | Curiosity beats craving | ≈ 6:15 | 804 / 807 / 803 |
| P3 · 3 | One with full attention (played during a use) | ≈ 6:30 | 750 / 742 / 770 |
| P4 · 1 | Why it feels like it calms you | ≈ 6:10 | 765 / 775 / 766 |
| P5 · 1 | Surfing the urge (guided practice) | ≈ 7:10 | 835 / 837 / 834 |
| P5 · 5 | Thoughts are not orders (evening) | ≈ 5:30 | 632 (one render) |
| P6 · 1 | You don't have to white-knuckle it | ≈ 6:10 | 753 / 753 / 782 |
| P7 · 1 | What you're actually giving up | ≈ 7:15 | 843 / 844 / 844 |
| P7 · 5 | The last one (guided, ends on the hold) | ≈ 6:45 | 714 / 710 / 717 |
| DX · 1 | Day Xero (morning, ends on the hold) | ≈ 6:30 | 760 / 748 / 749 |
| DX · 5 | One day (evening) | ≈ 7:15 | 797 / 797 / 799 |

## Decided (Milan, 6 Nov 2026)

- **Free or paid:** leave the current setup as it is (Day Xero stays listed as paid in `FullProgram.swift`). Milan decides what is free or paid once the program is built into the app.
- **Wording:** "the gap" only. Retire "battery"; the P2 morning delay is "a short wait".
- **P1 money reveal:** moves to the Prep 1 day recap.
- **P3 "Save for later":** card 4 waits for the saved guided use; card 5 opens anyway (this one day breaks strict order).
- **SOS practice mode:** build it (logs nothing, no Live Activity, no slip flow, clearly marked "Practice").
- **Narrator:** one warm female voice for all 14 tracks.
- **Audio:** 3 renders per track (smoking, vaping, pouches), 42 files.
- **Next build:** content into the app first: P1–P7 and Day Xero into `program.json`, plus the new deck screens in SwiftUI.

## Open items (from the drafts)

1. **Day Xero free or paid.** The bible and decision 23 say free; `FullProgram.swift` lists it as paid. The copy sells nothing either way.
2. **"Gap" means one thing only.** P2 calls the morning delay "a short wait" (step 5 is "Tonight: one small wait"). The old P2 prompt, cards and `completionText` ("one small gap") should change to match.
3. **"Battery" is retired** in favor of "the gap". The old P1 cards, quiz feedback and mission use it.
4. **P1's money reveal** (`stat_reveal`, yearly units and cost) has no slot in the new P1. Keep it in onboarding or the day recap?
5. **P3 "Save for later".** The guided-use track can be saved for later; the draft lets step 5 open while step 4 waits. That breaks "steps open strictly in order".
6. **Breathing patterns.** P4 uses the existing `sigh` pattern; DX adds 4-in, 6-out, which isn't in `breathing_orb_data.json` yet.
7. **SOS practice mode** (DX step 3) is new: it must log nothing, start no Live Activity and open no slip flow.
8. **New UI pieces:** a repeating check-in sheet (P1), per-trigger repeat screens (P2), a timed hold, a body map and 0–10 sliders (P5), a ratings-based debrief (P5), the "Go deeper" sheet (all Reveal cards) and the per-card rating.
9. **Copy fixes outside the program:** the pregnancy caution string uses UK "behavioural"; the `note_to_dayxero` placeholder "You've got this." should become "Remember why you're doing this."; the W1D1 label says "Day 2".

## Before launch

- **Claims to verify:** every day file lists its own. The recurring ones are how long a craving lasts (only the smokefree.gov wording in `health-timeline.json` backs it), whether studies done on smokers can be shown to vape and pouch users (Babb, Parrott, Taylor, Aubin, Doll), the varenicline and cytisine lines (no approved source yet), and the Brewer and Balban study summaries.
- **Clinical review** of everything on NRT (P6, DX step 4), withdrawal (P7, DX) and mental health (P4).
- **Voice casting:** one narrator for all 14 tracks. Generate each track twice or more and pick the best take (ElevenLabs' own advice for v4).
