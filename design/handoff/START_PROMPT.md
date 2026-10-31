# Start prompt for a new Claude session

Paste the block below as the first message in a new session, with the repo `milan458/dayxero` connected (or attach `dayxero-design-archive.zip` and `DAYXERO_DESIGN_SYSTEM.md`).

```text
You are picking up the DayXero redesign from a previous design session. Everything that session decided is in the repo milan458/dayxero, on branch claude/vigilant-newton-erhqkg, under design/handoff/. If the repo isn't connected, the same files are in the attached dayxero-design-archive.zip and DAYXERO_DESIGN_SYSTEM.md.

STEP 0: Load the context. Do not design anything yet.
1. Read design/handoff/DAYXERO_DESIGN_SYSTEM.md in full. It is the source of truth: decisions, story, tokens, screen specs, critique and open questions. Read §0, §2 (decision log), §13 (conflicts with the repo) and §14 (open questions) twice.
2. Read design/handoff/tokens.json.
3. Skim the repo files the doc cites, to check they still match:
   - DayXeroCore/Resources/program.json
   - DayXeroCore/Resources/health-timeline.json
   - DayXeroCore/Model/Enums.swift (trigger list)
   - DayXeroTests/PaywallModelTests.swift (pricing)
   - docs/DESIGN_METHODOLOGY.md
   - DayXeroCore/DesignSystem/{Colors,Typography,Motion,Metrics}.swift
4. Reply with a 10-line summary of what you understood, and list anything in the repo that now contradicts the doc.

STEP 1: Recreate the design canvas.
1. Create a new Design canvas (Artifact tool: quickstart with intent "design", then create from the Design type) titled "DayXero · v4 design system".
2. Page 1, "v4 · Final direction": build it from Appendix B (canvas index) and Appendix C (full source) of the doc. Equivalently, use these files from design/handoff/canvas/project/:
   - FinalSheet, Nav2, F01Breathe … F18Finale, FDarkA, FDarkB
   - components: Xero, Jelli, Glim2, Hero2, Horizon2
   Publish each file byte for byte. Keep the line <script src="./support.js"></script> exactly; the Design type supplies support.js.
3. Then add the reference pages from design/handoff/canvas/canvas.json, keeping their page ids, names, positions and titles: "The Crew" (trio), "Alive", "v3", "night", "characters", "screens", "story". Add page by page. Every .dc.html that a board imports must also be on the canvas.
4. Follow the authoring rules in Appendix A of the doc:
   - holes are dotted lookups only
   - no CSS @keyframes in imported components
   - no sc-for inside <svg>
   - no emoji
   - escape apostrophes in single-quoted JS strings
5. Nothing from the previous session was rendered. After publishing, tell me the canvas link and list anything that failed to publish. Do not change any design while recreating it.

STEP 2: Ask me the open decisions before any UI/UX change.
Ask these in one message, using the doc's §14 wording:
(a) Trial timing: start the 3-day trial on Quit Day (the proposal shown on F06), or keep it at sign-up?
(b) Adopt v4 over the "Biophilic OLED Minimalism" direction in docs/DESIGN_METHODOLOGY.md and Colors.swift?
(c) Coral as the brand signature colour?
(d) Plum dark-mode grounds for the warm screens: confirm, or test on an OLED phone first?
Also remind me that the inactivity-reset rule is still undecided.

STEP 3: Start the UI/UX change process, once I've answered.
1. Design the missing v4 screens on the canvas, using the same rules (doc §4–§9) and the same persona (§7):
   - the Quit Day offer/paywall (if (a) = Quit Day) and the Day Xero celebration
   - milestones
   - NRT plan and NRT info (serious tier)
   - Insights
   - health timeline detail
   - Settings (reminders, day-end time, quiet hours, appearance follows the phone)
   - reasons and photo editor
   - Calm library
   - Live Activity and widgets
   - empty, error and offline states
   Add a dark-mode row for them.
2. Then write a SwiftUI migration plan as a doc in the repo (docs/), following §13: tokens → Colors.swift, fonts (add Bricolage Grotesque + DM Sans) → Typography.swift, motion tokens → Motion.swift, characters and scenes as SwiftUI drawings or vector assets, then screen-by-screen order (SOS and Today first). Wait for my OK before touching Swift code.

Rules for the whole session:
- Never invent product facts. Use real lesson titles, health copy (quote health-timeline.json with its source), prices, trigger lists and slip rules from the repo.
- Keep one persona and one calendar: Sam, Quit Day Fri 6 Nov 2026, mock "today" Sun 8 Nov (Day 3), USD.
- Keep the decided rules:
  - colour follows the character
  - 7 type sizes (12px minimum)
  - 4 character sizes, at most 2 illustrations per screen
  - Arrive / Settle / Celebrate motion, with Celebrate only on Passed, milestones and the finale
  - contrast ≥ 4.5:1
  - no craving countdowns, no surveillance lines on SOS
  - the user's name once per session
  - characters speak as "I"
- If a request conflicts with a recorded decision, point to the decision in the doc and ask before changing it. Log every new decision by updating DAYXERO_DESIGN_SYSTEM.md (decision log plus the affected section) and tokens.json, then commit to a branch.
- Be honest about verification: say when something hasn't been rendered or checked.
```
