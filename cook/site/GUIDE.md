# DayXero redesign: screen builder guide

You are redesigning DayXero (a quit smoking and vaping iOS app) screens as HTML mockups. Every screen is one file in
`cook/site/screens/NNN-name.html`, 390x844, built ONLY from the shared kit. The bar is 9.2/10 against Headspace, Calm and Kwit:
consistent, calm, adult, warm, with real motion and satisfying completion moments. The current app scores 6.5: too many colours,
clipped content above buttons, mixed controls, flat completions. Read `cook/site/kit/kit.css` and `cook/site/kit/kit.js` fully first.

## File template (copy exactly, change the parts in caps)
```html
<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=390">
<title>NNN Screen name</title>
<meta name="motion" content="ONE OR TWO SENTENCES: what moves, in what order, durations, the haptic. This is the spec for the SwiftUI build.">
<link rel="stylesheet" href="../kit/kit.css">
<script src="../kit/chars.js"></script><script src="../kit/kit.js"></script>
<style>/* screen-only layout. Use kit variables (--g --fg --muted --card --card-2 --line --btn --tick). Never hardcode UI colours. */</style>
</head><body>
<div class="screen" data-ground="GROUND"> ... </div>
<script>/* fill art: el.innerHTML = DX.char('xero',{mood:'hello',size:140}); DX.after(ms, fn) for scripted motion */</script>
</body></html>
```
Status bar is injected automatically (use `data-status="on-art"` on .screen when the top is full-bleed art). Content lives in
`.scroll` (padding-top 54) or absolutely positioned blocks. Primary action goes in `.dock` at the bottom (it has a fade, so
content never looks clipped). Leave >= 150px of bottom space for the dock, or 120px for the tab bar.

## Grounds: one per screen, by meaning (this is the core fix: the app had 7 colours "all over")
- `apricot`: Xero, your days: Launch, Welcome, onboarding, Quit Day, Today (morning/day), Pledge, Milestones.
- `ocean`: Jelli: Craving SOS and its outcomes only.
- `violet` (now a deep teal NIGHT colour, #152733; `night` is an alias): Glim: evening only (evening Today variant, check-in, wind-down). Kept dim on purpose: easy on the eyes at night. Never use purple fills on these screens; Glim's own purple body is the only purple.
- `mint`: your plan: Program tab, plan reveal / plan built.
- `reading` (cream light, deep navy dark): reading and serious screens: lessons, slips, health, NRT, taper, log sheets, progress, settings, paywall, calm tools list.
- `table` (deep ink in both modes): the prep session "hand" and its cards (cards carry the colour).
- `sun`: never a whole screen. Sun yellow appears only inside celebrations (badges, rays).
Dark mode is automatic from tokens; never write separate dark colours except art. Check both modes.

## Hard rules
- ONE primary button per screen: `.btn` (ink on light grounds, cream on dark: automatic). Never green, purple, yellow, peach buttons.
  Secondary: `.link` or `.btn.ghost`. Hold actions: `<button class="btn" data-hold="1500" data-done="Quit Day set" data-autohold="1400">`.
- Leading control top-left only (`.nav` > `.icon-btn` back or close). Never top-right close. Avatar or a small label may sit right.
- One choice chip (`.chip`, `.chip.on`) and one option row (`.opt` with `.radio`, `.opt.on`). No other selection styles.
- Type: only `.t-display .t-large .t-title .t-head .t-body .t-foot .t-cap`. Caption 12px is the floor.
- NO uppercase eyebrow labels ("YOUR ANSWER", "CARD 1 OF 5 · LISTEN"). Use a sentence-case `.t-foot.muted` line if a label is needed.
- No monospace, no emoji, no purple gradients, no decorative particles, no glow orbs, no 01/02/03 counters, no em dashes in copy.
- At most two illustrations per screen (a scene plus one character). Characters: `DX.char('xero'|'jelli'|'glim', {mood:'hello'|'calm'|'breathe'|'cheer'|'sleepy', size, stage})`.
  Sizes: 40 avatar, 88 card, 140 scene, 200 hero. Scenes: `DX.char('horizon', {scene:'dawn'|'dusk'|'path'|'sea'|'night', w, h, clarity})`.
- `.mark` (hand-drawn underline) at most once per screen, on the key word of the headline.
- Copy: keep the meaning and the program words; shorten anything long. Walls of text become short paragraphs or cards.
- Nothing may overlap or be cut off. Render and look at both modes.

## Motion (every screen has motion; it plays once on load)
- Arrive: put `data-a style="--i:N"` on text and cards in reading order (art first, title, cards, button). 600ms, 90ms stagger.
- Settle: `data-settle` for characters entering and rows of a plan. Pop: `data-pop` (spring) only for celebrations and badges.
- Stamp: `data-stamp` for a badge or stamp landing. Draw: SVG paths with `class="draw" style="--len:L"` (lines, checks, paths).
- Count-up: `<span data-count="49" data-prefix="$" data-dec="2">` for every number that changed or matters.
- Rings: `DX.ring({size, stroke, p, color, track, dot:true})` sweeps from 0. Shine: class `shine` on a newly earned item.
- Ambient: `.bob` characters, `.drift` clouds, `.breathe` (4s in, 6s out) for SOS and calm.
- `DX.after(ms, fn)` for scripted beats (e.g. flip a card, switch a label). Write the `<meta name="motion">` spec for every screen.

## Completion moments (the app's biggest gap; every finishing action gets one)
Whenever the user finishes something (hold to commit, save a plan, finish a card, finish a session, pass a craving, check in,
log, set reminders, save settings), show a done beat built from these, in order:
1. the button turns into its done state (hold buttons do this automatically) or a `DX.check({size})` pops and draws;
2. the character reacts (`mood:'cheer'` with `data-settle`, or a `.bump`);
3. the number that changed counts up, with a small `.float-up` "+1" where it fits;
4. if a badge is earned, `DX.badge({...})` stamps in (`data-stamp`) with `.shine`.
Springs (`data-pop`, `data-stamp`) only on celebrations. SOS stays calm: slow fades, no springs except the final "+1".

## Badges (gamification at about 30-40% of Kwit: milestones, no XP, no levels, no points)
One medallion family via `DX.badge({kind, n, state:'earned'|'next'|'locked', label, size, p})`:
- `prep` 1-7: one stamp per finished prep session (Prep 1 to Prep 7).
- `xero` n:'0': Day Xero, earned when the Quit Day commit is held.
- `day` 1, 3, 7, 14, 30, 60, 90, 180, 365: days free after Quit Day.
- `wave` 1, 10, 25, 50, 100: cravings ridden out with SOS.
- `night` 3, 7, 14, 30: evening check-ins.
Show them wherever progress shows: Program path nodes (prep stamps), session completion (stamp earned), Today (next badge with
`state:'next'` and `p`), SOS passed (wave count toward the next wave badge), check-in done (night count), Progress (the shelf),
Milestone screen (the earned badge celebrated).

## The one persona and calendar (use these numbers, nothing else)
- Sam. Uses cigarettes (12 a day) and a vape. Triggers: Coffee, Stress. Reason: "Run with Aria without stopping to catch my breath".
- Joined Fri, Oct 30. Prep week Fri, Oct 30 to Thu, Nov 5 (Prep 1 to 7). Quit Day = Day Xero = Fri, Nov 6.
- Prep-week screens: today is Tue, Nov 3, Prep 5, "3 days to Quit Day", Prep 1-4 stamped, $7 a day still spent.
- After-quit screens: today is Fri, Nov 13, Day 7, "7 days free", $49.00 kept, 84 cigarettes not smoked, 1,400 puffs not taken,
  23 waves ridden (3 today), 6 evening check-ins, sky 40% clear, next badge 14 days (7 to go), next wave badge 25 (2 to go).
- Money: $7 a day, $2,555 a year. Pack $8, 20 cigarettes. Pricing: Yearly $39.99 ($3.33 a month), Monthly $9.99, Lifetime $99.99, 7-day free trial.
- Status bar time is 9:41 (evening screens may show 9:12 PM context in copy but the bar stays 9:41).

## Process
1. Look at the current screenshots for your screens (paths in your task) to get the content and purpose. Redesign, do not copy.
2. Write the files. 3. Render: `node cook/tools/render.mjs cook/stills/r01 ID ID ...` (light and dark PNGs, final state).
4. Read the PNGs, fix overlap, clipping, contrast, alignment and anything that looks generic. Repeat until each screen is
   something you would ship next to Headspace. 5. Do not edit kit files; if the kit lacks something, add screen-local CSS and
   report it. Do not touch other builders' screens.
