# Refresh: current US iPhone product-page screenshot sets for 21 apps (health-fitness group B + quit), 2026-11-20

**Method.** For each app I fetched `https://apps.apple.com/us/app/id{ID}` with plain curl (no User-Agent spoofing) and parsed the `serialized-server-data` JSON. I took the `shelfMapping.product_media_phone_` items, which are the largest iPhone display class the app uploaded, and downloaded each screenshot at 600px wide (`…/600x0w.jpg`). I compared the asset IDs with the Lookup API `screenshotUrls` already in each `app.json`. Where the IDs differed, I compared the images visually.

**Replaced sets.** The old images were moved to `{app}/api-lookup-set/` (including the old `_sheet.jpg`). The product-page set is now saved as `01.jpg…`, with a new `_sheet.jpg` (300px per frame). `app.json` gained `productPageScreenshotUrls`, `productPageDeviceClass`, `productPageFetched` and `productPageCheck`.

**Unchanged apps.** These got only a `productPageCheck` entry, with the result, device class, video count and subtitle.

Scripts: `/tmp/claude-0/-home-user-DAYXERO/baee34b4-0d61-5647-bafc-b1eff344fe4b/scratchpad/groupB/` (compare.py, stage.py, review.py, apply.py). The group A health-fitness folders were not touched.

## Which of the 21 apps show a different set on the product page, and how does each differ?

### Takeaway
10 of 21 apps now have different files on the product page:
- **Entirely new creative sets (6):** Noom, WeightWatchers, Quit Vaping, Kwit and Sober Sidekick, plus a materially revised **Ladder**.
- **Same captions with refreshed UI and frames (1):** Hevy.
- **Same creative re-rendered at 6.5" instead of 5.5" (3):** QuitSure, EasyQuit and I Am Sober.

The other 11 are unchanged:
- Byte-identical (9): Lose It!, BetterMe, Sleep Cycle, Clue, AllTrails, Yuka, Smoke Free, Reframe, Exhale.
- New file URLs but visually identical creatives (2): QuitNow, Puff Count. Their images were kept.

Smoke Free and QuitNow also lead their product-page media with an App Preview video, which the Lookup API never exposed.

### Cited Findings

**Status table** (device class from the product-page artwork size):

| App | Result | Product-page set | Lookup set (now `api-lookup-set/`) |
|---|---|---|---|
| Lose It! | unchanged (identical) | 10, 6.9" 1320×2868 | same |
| BetterMe | unchanged (identical) | 6, 6.9" 1290×2796 | same |
| Noom | **new set** | 8, 6.3" 1206×2622 | 9, 5.5" |
| Sleep Cycle | unchanged (identical) | 10, 6.9" 1260×2736 | same |
| Clue | unchanged (identical) | 9, 6.5" 1242×2688 | same |
| WeightWatchers | **new set** | 10, 6.5" 1284×2778 | 7, 5.5" |
| Hevy | **same captions, refreshed UI/frames** | 10, 6.5" 1242×2688 | 10, 5.5" |
| Ladder | **revised set** | 10, 6.5" 1242×2688 | 10, 5.5" |
| AllTrails | unchanged (identical) | 10, 6.9" 1260×2736 | same |
| Yuka | unchanged (identical) | 6, 6.5" 1242×2688 | same |
| Smoke Free | unchanged (identical); **video first** | 10, 6.5" | same |
| QuitNow | unchanged (same creatives, new URLs); **video first** | 7, 6.5" | same images |
| Quit Vaping | **new set** | 10, 6.9" 1290×2796 | 10, 5.5" |
| Kwit | **new set** | 10, 6.5" 1242×2688 | 10, 5.5" |
| Puff Count | unchanged (same creatives, new URLs) | 5, 6.5" | same images |
| QuitSure | device class only | 10, 6.5" | 10, 5.5" |
| EasyQuit | device class only | 10, 6.5" | 10, 5.5" |
| I Am Sober | device class only | 9, 6.5" | 9, 5.5" |
| Reframe | unchanged (identical) | 10, 6.9" 1320×2868 | same |
| Sober Sidekick | **new set** | 10, 6.5" 1284×2778 | 8, 5.5" |
| Exhale | unchanged (identical) | 5, 6.5" | same |

Sources: each app's [US product page](https://apps.apple.com/us/app/id634598719) (pattern `apps.apple.com/us/app/id{ID}`) and the [Lookup API](https://itunes.apple.com/lookup?id=634598719&country=us).

#### Noom (new set)
— [App Store](https://apps.apple.com/us/app/id634598719)

**Count:** 8 (was 9).

**Headlines in order:**
1. "Noom uses psychology to help you lose weight and keep it off"
2. "Understand your food choices with psychology"
3. "A personalized program for healthier habits"
4. "Stay on track with simple food logging"
5. "Get tailored insights along your journey"
6. "Kickstart your health with medication"
7. "Keep the muscle, lose the fat"
8. "8 out of 10 members say Noom is a life-changing program"

**Slot 1:** the same mechanism claim and 1→2 Course Map panorama as before.

**Style:** salmon and all-serif became a pale lavender-grey background, with serif only on frames 1 and 8 and sans on 2–7. Framed phones now appear on 2–7.

**Proof:** the closer moved from "78% of Noomers lost weight in a six-month study" to a satisfaction stat. Its footnote reads "63 of 82 Noom members taking an FDA-approved GLP-1 RA … agreed that Noom is a life changing program".

**Features:** dropped the coach chat, the colour-coded foods and "Celebrate your progress". Added a Wegovy HD pen with "Check in with your doctor UNDER 3 MINUTES" and "Muscle Defense™" for medication users.

**Subtitle:** "Healthy Habits, Meals & GLP-1s".

#### WeightWatchers (new set)
— [App Store](https://apps.apple.com/us/app/id331308914)

**Count:** 10 (was 7).

**Headlines in order:**
1. "THE NEW WEIGHT WATCHERS APP – Weight-loss programs, support, and medications in one place"
2. "Points®, macros, and progress—all in one spot"
3. "Access to weight loss medications through expert Clinicians (if you qualify)"
4. "NEW! GLP-1 Success Program Expert support, better results"
5. "NEW! Modes Flexible settings let you choose how you lose"
6. "NEW! Weight Watchers for Menopause"
7. "NEW! AI Body Scanner shows your progress beyond pounds"
8. "Simple, fast meal tracking: See it, snap it, log it"
9. "350+ ZeroPoint® foods to keep you full and make healthy eating easier"
10. "Barcode scanning for effortless tracking"

**Slot 1:** a "new app" plus medication promise. The old "#1 doctor-recommended" survey claim and lifestyle photo are gone.

**Style:** solid royal blue, condensed bold sans, Dynamic Island frames.

**Proof:** none, apart from a named MD clinician in the UI.

**Features:** medication access, GLP-1 program, ALL-IN / LOSE / MAINTAIN modes, menopause, and an AI body scanner.

#### Hevy (same captions, refreshed)
— [App Store](https://apps.apple.com/us/app/id1458862350)

The same 10 captions run in the same order, from "LOG WORKOUTS / GET STRONGER / STAY MOTIVATED" to "SLEEK DARK MODE", with the same "Apps We Love" laurel and grey/blue layout. Modern notch frames replace the home-button-era frames. Slot 2 now carries the HEVY wordmark. The UI screens are new: a squat chart without the PR medal, and progress photos in measurements.

#### Ladder (revised)
— [App Store](https://apps.apple.com/us/app/id1502936453)

**Count:** 10.

**Headlines in order:**
1. "GET STRONGER, WITH A PLAN."
2. (no caption)
3. "A PLAN FOR EVERY WORKOUT"
4. "TRACK MACROS"
5. "FIND THE PERFECT PLAN FOR YOU"
6. "GET COACHED THROUGH IT ALL"
7. "LEARN CORRECT FORM"
8. "TRACK YOUR PROGRESS"
9. "LISTEN TO YOUR OWN MUSIC"
10. "GET ANSWERS TO YOUR QUESTIONS"

**Proof:** slot 1 now has "App Store App of the Year 2025 Finalist", and slot 2 has the "2026 Women's Health – Best Overall Workout App" and "2026 CNET – Best Strength Training App" laurels. The older set had 2024 Women's Health and CNET awards.

**Features:** "TRACK MACROS" (nutrition with photo meal capture) replaced "PREVIEW EVERY MOVEMENT". The Apple Watch moved to "TRACK YOUR PROGRESS".

**Style:** unchanged — a neon-yellow panorama hero, then white, with dark UI.

#### Quit Vaping (new set)
— [App Store](https://apps.apple.com/us/app/id1479615245)

**Count:** 10.

**Headlines / subheads in order:**
1. "Quit vaping. For real this time."
2. "Don't quit alone." / "Team up with a friend and track each other's progress."
3. "Cut down your way." / "Log every puff and watch your nicotine intake drop."
4. "Watch your body heal." / "See your lungs, heart and brain recover."
5. "Join the community." / "Get support from people quitting right alongside you."
6. "Every day counts." / "Keep your current and past vape-free streaks in view."
7. "Breathe through it." / "Guided breathing and meditation to ease cravings."
8. "Quit together. Win together." / "Climb the leaderboard with your friends."
9. "Beat your cravings." / "Track moods and triggers, and journal your way through."
10. "Hit goals. Earn badges." / "Celebrate every milestone on your way to vape-free."

**Slot 1:** a question hook ("Ready to Quit?") became a promise plus trust marks: "#1 APP To quit Vaping" and "4.9 Rating Global Ranking" laurels and a "DOCTOR APPROVED" seal.

**Style:** purple gradient with iPhone 8 bezels became per-frame pastel gradients, heavy two-tone headlines and Dynamic Island frames, with floating chips ("75% less nicotine in just 7 days", "1M+ members quitting together", "Personal best 44 days vape free").

**Features:** a new nicotine-mg taper tracker. It logs "Nicotine Lozenge 4mg" under "Devices & Replacements" while the header still says "You've been vape free for 35D 1H 9M & 9S". "Break your streak?" with past streaks is still shown.

**Craft:** the old "eachother" typos and the mismatched "Pledge" caption are gone. There is a new UI typo, "consumed less nicotine then yesterday".

#### Kwit (new set)
— [App Store](https://apps.apple.com/us/app/id525441365)

**Count:** 10.

**Headlines in order:**
1. "Quit smoking successfully!"
2. "5 minutes a day that can change everything"
3. "A real monitoring, not just a counter"
4. "Understand your triggers"
5. "Customize your experience"
6. "Celebrate every victory"
7. "See how far you have come"
8. "Engage with a supportive community"
9. "Learn every day"
10. "Your success starts now!"

**Slot 1:** "+5M users" laurel plus the WHO emblem over a progress screen. The "App of the day" laurel and the "recommended by WHO" banner text are gone.

**Style:** sky-blue hills with a green verb box became shifting pastel gradients with a white path ribbon through all 10 frames, left-aligned grey captions alternating top and bottom, and cat-like mood characters.

**Features:** a daily task home ("5 minutes a day"); an "I feel like smoking" action grid with **"I smoked"** next to "I overcame a craving"; triggers; a personal strategy; trophies 10/36; a community SOS thread; tips. The old set's reviews closer and health timeline are gone.

#### Sober Sidekick (new set)
— [App Store](https://apps.apple.com/us/app/id1448251580)

**Count:** 10 (was 8).

**Headlines in order:**
1. (none — panorama)
2. "Your Path to Sobriety Starts Here."
3. "Access Support Whenever You Need It."
4. "Join a Trusted Community of Change."
5. "Take the First Step Toward a Better Life."
6. "Commit to Your Sobriety Journey Today."
7. "Celebrate Every Milestone."
8. "Everything You Need in One Place."
9. "Stay Inspired, Stay Strong."
10. "You're Not Alone Join Thousands on the Recovery Journey."

**Slot 1:** an uncaptioned 1→2 panorama phone with the share card "My life is worth the work – 2 Years / 28 Mon… / 874 Days" and "USD 8740 Money Saved".

**Style:** a teal→violet gradient with dashed connectors, light white sans with an orange or magenta accent phrase, and Dynamic Island frames.

**Proof:** a new card with ★★★★★, "2M Sobriety Goals Completed." and a testimonial from "Jeff. K".

**Features:** 24/7 AA/NA meetings, Reads/Listens, "My Comeback Story – Progress not perfection", and supportive-member rankings. "Judgement Free" is gone.

**Craft:** slot 7's caption sits over a screen that repeats slot 3.

**Subtitle:** "Reframe: Drink Less Alcohol" (a competitor's name).

#### QuitSure, EasyQuit, I Am Sober (device class only)
Each keeps the same captions and order, re-rendered at 6.5". The taller QuitSure slot 3 shows a third toolkit item, "Immersive exercises". QuitSure's subtitle is "Clinically proven. 81% success" — [QuitSure](https://apps.apple.com/us/app/id1523992725), [EasyQuit](https://apps.apple.com/us/app/id1508110799), [I Am Sober](https://apps.apple.com/us/app/id672904239)

#### App Preview videos
The product-page phone media for Smoke Free and QuitNow starts with a video item before screenshot 1:
- Smoke Free's poster frame shows "Time smoke free 5m 25d 20h" plus health rings.
- QuitNow's poster frame is its "Track your quit journey at a glance" screen.

Posters are saved as `_video_poster.jpg`. None of the other 19 apps has a phone video — [Smoke Free](https://apps.apple.com/us/app/id577767592), [QuitNow](https://apps.apple.com/us/app/id483994930)

### Inferences
- The Lookup API returned the smallest or oldest set for every app whose largest upload differed. Apps that only refreshed their large-device upload (Noom, WW, Ladder, Quit Vaping, Kwit, Sober Sidekick) left a stale 5.5" set behind in the API. Any analysis built on `/lookup` alone risks describing creatives that current iPhone users never see.
- Noom's largest class is 6.3" (1206×2622), not 6.9". The product page shows the largest class each developer uploaded, which is not always 6.9".

### Gaps
- I fetched each page once. Product Page Optimization tests or Custom Product Pages could show other visitors different sets.
- I did not play either App Preview video, so I only know their poster frames.
- I could not date when each new set went live.

## Do the differences change the cross-app conclusions in the existing notes?

### Takeaway
Yes, in several specific places, though not in the overall formula.

**Health-fitness group B:**
- Proof on slot 1 drops from 5 to 4 of 10 (WW lost "#1 doctor-recommended").
- "AI" now appears in two headlines (Sleep Cycle and WW), not one.
- Noom moves from the "frameless cards / all-serif" archetype to framed phones with serif bookends.
- A new pattern appears: the **GLP-1 medication pivot** at Noom and WW.
- Ladder strengthens and now ranks first.

**Quit:**
- The "time-boxed daily session" gap is now taken: Kwit's slot 2 says "5 minutes a day that can change everything".
- The "slips don't reset" gap is narrower: Kwit logs "I smoked" neutrally, and Quit Vaping logs NRT while its counter runs.
- "Ready to Quit?" is now used only by Puff Count.
- Money saved is 11 of 11.
- NRT-tolerant sets go from 1 to 2.
- The "dated 5.5" bezels" craft gap mostly disappears.
- Quit Vaping moves from weakest to among the strongest.
- Unsourced trust marks ("#1 APP", "Doctor Approved", "2M goals") spread to sets that had no claims.

### Cited Findings
- **Group B, proof on slot 1:** Lose It!, Ladder, Hevy and AllTrails. WW's slot 1 is now "Weight-loss programs, support, and medications in one place", with no proof — [WW](https://apps.apple.com/us/app/id331308914)
- **Group B, medication:** Noom 6–7 (Wegovy pen, Muscle Defense™) and its subtitle "Healthy Habits, Meals & GLP-1s". WW 1, 3 and 4 ("Access to weight loss medications through expert Clinicians (if you qualify)", "NEW! GLP-1 Success Program") — [Noom](https://apps.apple.com/us/app/id634598719), [WW](https://apps.apple.com/us/app/id331308914)
- **Group B, "AI" in a headline:** Sleep Cycle "AI Sleep Coach" and WW "NEW! AI Body Scanner shows your progress beyond pounds" — [WW](https://apps.apple.com/us/app/id331308914)
- **Group B, set size:** average 8.9 (was 8.7); six sets use 10 frames — [product pages](https://apps.apple.com/us/app/id297368629)
- **Quit, daily-time framing:** Kwit slot 2 reads "5 minutes a day that can change everything" — [Kwit](https://apps.apple.com/us/app/id525441365)
- **Quit, slip logging:** Kwit slot 3's action grid includes "I smoked". Quit Vaping slot 3 logs "Nicotine Lozenge 4mg" while "You've been vape free for 35D 1H 9M & 9S" — [Kwit](https://apps.apple.com/us/app/id525441365), [Quit Vaping](https://apps.apple.com/us/app/id1479615245)
- **Quit, trust marks:** Quit Vaping slot 1 ("#1 APP To quit Vaping", "4.9 Rating Global Ranking", "DOCTOR APPROVED"). Sober Sidekick slot 4 ("2M Sobriety Goals Completed.") — [Quit Vaping](https://apps.apple.com/us/app/id1479615245), [Sober Sidekick](https://apps.apple.com/us/app/id1448251580)
- **Quit, money saved:** Sober Sidekick slot 1, "USD 8740 Money Saved" — [Sober Sidekick](https://apps.apple.com/us/app/id1448251580)

### Inferences
- For DayXero, three gaps in `quit_apps.md` still hold: a visible prep → Quit Day timeline, an explicit caption that "a slip doesn't reset your days", and cigarettes + vapes + pouches in one app. The "about 3–5 minutes a day" message is no longer unique, so it should be paired with the prep-to-Quit-Day mechanic rather than lead on its own.
- Kwit is now the most directly comparable competitor set (routine + "not just a counter" + slip log). Quit Vaping is the craft benchmark for a vape-first audience.
- The GLP-1 shift in weight loss parallels NRT in quitting. Two leading quit sets now show NRT neutrally (Smoke Free, Quit Vaping), so DayXero showing NRT-friendly support would not be out of place.

### Gaps
- No conversion data exists to say whether the new sets outperform the old ones.
- I did not verify any of the new trust claims ("#1 APP", "4.9 Rating – Global Ranking", "Doctor Approved", "2M Sobriety Goals Completed", Noom's 63-of-82 satisfaction figure) beyond reading them off the images.
