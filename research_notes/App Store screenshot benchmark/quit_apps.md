# App Store screenshot benchmark: top 10 US "quit" apps (fetched 2026-11-20)

**Capture method (refreshed 2026-11-20).** The images analysed are the iPhone set shown on each app's US product page today. I fetched `https://apps.apple.com/us/app/id{ID}` with plain curl, read the `product_media_phone_` shelf from the page's embedded JSON (the largest display class the app uploaded) and downloaded each frame at 600px wide. The Lookup API sets described below as "original" were often an older or smaller (5.5") upload. Per app:
- **Byte-identical** (5): Smoke Free, Reframe, Exhale; QuitNow and Puff Count have new file URLs but visually identical creatives, so their root images were kept.
- **New creative sets** (3): **Quit Vaping**, **Kwit**, **Sober Sidekick** (8 → 10 frames).
- **Same creative, larger device class only** (3): QuitSure, EasyQuit, I Am Sober.

For the 6 replaced sets, the older Lookup images are in `{slug}/api-lookup-set/`, and `app.json` gains `productPageScreenshotUrls`, `productPageDeviceClass`, `productPageFetched` and `productPageCheck`. **Smoke Free and QuitNow lead their product-page media with an App Preview video** before screenshot 1; poster frames are saved as `_video_poster.jpg`. Smoke Free's poster shows the dashboard "Time smoke free 5m 25d 20h" with health rings. QuitNow's poster is its "Track your quit journey at a glance" frame.

Product-page subtitles (`lockup.subtitle` in the page JSON):
- Smoke Free: "We can help you stop for good"
- QuitNow: "Quit smoking for good"
- Quit Vaping: "#1 App to Quit Vaping/E-Cigs"
- Kwit: "A life without cigarettes!"
- Puff Count: "Track Puffs and Quit Vaping"
- QuitSure: "Clinically proven. 81% success"
- EasyQuit: "Stop Smoking Now + Slow Mode"
- I Am Sober: "Sobriety tracker for recovery"
- Reframe: "Cut Back or Quit Alcohol Habit"
- Sober Sidekick: "Reframe: Drink Less Alcohol" (a competitor's name, rendered 3 times on its own page)
- Exhale: "Best App to Quit Vaping/E-Cigs"

Change summary: `refresh_current_sets.md` in this folder.

Library root: `/home/user/DAYXERO/reference/app-store-screenshots/quit/`. Each `{slug}/` folder holds `01.jpg…NN.jpg` (600px wide, in store order), `_sheet.jpg` (contact sheet at 300px per screen) and `app.json` (id, name, seller, rating, ratingCount, version, original screenshotUrls, fetched date). Rating counts and metadata come from `itunes.apple.com/lookup?id=…&country=us` on 2026-11-20. Screenshots are the iPhone product-page sets described in the capture note above. All headline quotes below were read off the images. The image files, the product-page JSON and the lookup JSON are the primary sources. For each app the cited source is its US App Store listing.

## Q1. Which apps are the top 10, and how confident is the ranking?

### Takeaway
No public Sensor Tower, Appfigures or AppMagic download figures exist for this niche, so I ranked apps by **US lifetime rating count** from the lookup API. That proxy gives 7 nicotine apps: **Smoke Free, QuitNow, Quit Vaping, Kwit, Puff Count, QuitSure, EasyQuit**. It gives 3 category-setting sobriety apps: **I Am Sober, Reframe, Sober Sidekick**. I also added **Exhale (quit vaping)** as a bonus 11th because it is the fastest-growing new vape app. Confidence is high that the top 4 nicotine apps are right, medium for slots 5–7, and medium for the order overall.

### Cited Findings
Ranking table, US storefront, lookup API on 2026-11-20 (rating count / average / number of screenshots / first release):

| # | App (slug) | Nicotine? | US ratings | Avg | Shots | Released | Listing |
|---|---|---|---|---|---|---|---|
| 1 | Smoke Free - Quit Smoking Now (23 Ltd) `smoke-free/` | cigs | 57,288 | 4.77 | 10 | 2012 | [App Store](https://apps.apple.com/us/app/id577767592) |
| 2 | QuitNow (Fewlaps SL) `quitnow/` | cigs | 13,644 | 4.69 | 7 | 2011 | [App Store](https://apps.apple.com/us/app/id483994930) |
| 3 | Quit Vaping (Jonathan Kopp) `quit-vaping/` | vape | 11,680 | 4.89 | 10 | 2019 | [App Store](https://apps.apple.com/us/app/id1479615245) |
| 4 | Quit smoking for good - Kwit `kwit/` | cigs | 2,837 | 4.66 | 10 | 2012 | [App Store](https://apps.apple.com/us/app/id525441365) |
| 5 | Puff Count: Quit Vaping Now (Rodger Studio) `puff-count/` | vape | 2,687 | 4.35 | 5 | 2019 | [App Store](https://apps.apple.com/us/app/id1488580640) |
| 6 | QuitSure Quit Smoking & Vaping (Rapidkart Online Pvt Ltd) `quitsure/` | cigs+vape | 1,590 | 4.79 | 10 | 2020 | [App Store](https://apps.apple.com/us/app/id1523992725) |
| 7 | EasyQuit - Stop Smoking (Mario Herzberg) `easyquit/` | cigs | 1,155 | 4.66 | 10 | 2020 | [App Store](https://apps.apple.com/us/app/id1508110799) |
| 8 | I Am Sober `i-am-sober/` | multi-addiction | 191,610 | 4.88 | 9 | 2013 | [App Store](https://apps.apple.com/us/app/id672904239) |
| 9 | Reframe: Drink Less & Thrive (Glucobit) `reframe/` | alcohol | 45,738 | 4.73 | 10 | 2020 | [App Store](https://apps.apple.com/us/app/id1485756576) |
| 10 | Sober SideKick: Quit Addiction `sober-sidekick/` | alcohol/AA-NA | 8,136 | 4.83 | 10 (Lookup: 8) | 2019 | [App Store](https://apps.apple.com/us/app/id1448251580) |
| bonus | Exhale - Quit Vaping Now `exhale-quit-vaping/` | vape | 313 (in about 8.5 months) | 4.63 | 5 | 2026-03-01 | [App Store](https://apps.apple.com/us/app/id6756926563) |

- Candidates checked and left out, with US rating counts from the same lookup:
  - Sunnyside: 2,338 ([listing](https://apps.apple.com/us/app/id1593489083)).
  - Quitzilla: 1,571. It is a multi-habit tracker ([listing](https://apps.apple.com/us/app/id1533076568)).
  - Quit Guru: 177 ([listing](https://apps.apple.com/us/app/id1542180365)).
  - Easy Quit Smoking & Vaping (hypnosis): 133 ([listing](https://apps.apple.com/us/app/id348429176)).
  - Flamy: 59 ([listing](https://apps.apple.com/us/app/id1462887052)).
  - Quitory: 37.
  - Snusless: Quit Zyn: 21 ([listing](https://apps.apple.com/us/app/id6740810702)).
  - Quit Nicotine Pouches: 16 ([listing](https://apps.apple.com/us/app/id6759302442)).
  - PouchLess: 6. Pace: 4.
- **No nicotine-pouch app has meaningful scale.** The biggest pouch-specific app I found has 21 US ratings ([Snusless](https://apps.apple.com/us/app/id6740810702)), and there are many pouch apps launched in 2025–26 ([search results](https://apps.apple.com/us/app/id6759302442)).
- **QUITTR** (id 6532588521) returns `resultCount: 0` from the lookup, for the US and with no country set. It looks unavailable or removed right now, although third-party trackers listed it with about 35k ratings ([AppGoblin](https://appgoblin.info/apps/6532588521)).
- **Quit Genius**: I found no consumer App Store listing. The product is described as an employer- or insurer-sponsored "digital clinic" ([c4tbh review](https://www.c4tbh.org/program-review/quit-genius/)).
- Download claims made in the listings themselves:
  - Smoke Free: "Eight million downloads worldwide" (screenshot 01).
  - QuitSure: "Over 3 MILLION downloads" (screenshot 02). This conflicts with "Trusted by 2 million+ smokers" quoted from the iOS listing by [search snippet sources](https://appgoblin.info/apps/1523992725).
  - Kwit: "5+ million people" (description), and "+5M users" laurel (product-page screenshot 01).
  - Puff Count: "over 800,000 users" (description).
  - Quit Vaping: "1M+ members quitting together" (product-page screenshot 05), plus "#1 APP To quit Vaping" and "4.9 Rating Global Ranking" laurels (screenshot 01). The older Lookup set said "Join over a million".
  - Sober Sidekick: "2M Sobriety Goals Completed" (product-page screenshot 04).
  - Reframe: "Trusted by 2 million + users" (screenshot 10).
- The Sensor Tower Q4 2025 US Health & Fitness top-5 lists contain no quit apps ([Sensor Tower](https://sensortower.com/blog/2025-q4-ios-top-5-health-and-fitness-units-us-600af518241bc16eb8dce802)). Public Appfigures profile pages show no numbers ([Appfigures](https://appfigures.com/reports/app-profile/319978592229/downloads)).

### Inferences
- Rating count is a lifetime total, so it favours old apps: QuitNow dates from 2011 and Smoke Free and Kwit from 2012. Exhale's 313 ratings in about 8 months suggests it is growing faster now than EasyQuit or Kwit. The current download leaders could differ from this table, especially among 2025–26 vape apps.
- The nicotine leaders split into **cigarette apps** (Smoke Free, QuitNow, Kwit, EasyQuit, QuitSure) and **vape apps** (Quit Vaping, Puff Count, Exhale). No top app positions itself on cigarettes, vapes and pouches together. QuitSure's title says "Smoking & Vaping", but its screenshots are about cigarettes only.

### Gaps
- I could not get real download estimates. Sensor Tower, Appfigures and AppMagic are paywalled, and no article published current US download ranks.
- I could not get App Store search-result order for "quit smoking" or "quit vaping": `/search` returns 403 and web search does not reproduce in-store ranking.
- App subtitles are not in the lookup API. They have since been captured from the product pages (see the capture note at the top).

## Q2. Per-app screenshot analysis (verbatim headlines, design, sequencing, claims)

### Takeaway
The category runs on a fixed formula: one headline (2–8 words) over a framed UI screen, with a live counter, money saved, health rings and badges in the first 2–5 slots. The apps differ mainly in **slot 1** (product-page sets):
- Social-proof numbers: Smoke Free, Quit Vaping ("#1 APP", "4.9 Rating", plus a "Doctor Approved" seal), Kwit ("+5M users" plus the WHO emblem).
- Authority badges: QuitNow, Reframe.
- A question to the reader: Puff Count, QuitSure.
- A feature or counter: EasyQuit, I Am Sober, Sober Sidekick (an uncaptioned panorama counter card), Exhale.

On the product page, Smoke Free and QuitNow show an App Preview video *before* slot 1.

They also differ in how far they go on **evidence claims**. QuitSure and Reframe make the strongest numerical claims.

### Cited Findings

#### 1. Smoke Free (`smoke-free/`, 10 shots, 600×1299, 6.5" class 1242×2688; product page unchanged) — [listing](https://apps.apple.com/us/app/id577767592)
- **App Preview video first:** the product page plays a video before screenshot 1. Its poster (`_video_poster.jpg`) is the dashboard, "Time smoke free 5m 25d 20h", with health rings (Immunity and lung function 100%, Reduced risk of heart disease 48%, Decreased risk of lung cancer 4%).
- **Headlines in order:**
  1. "Eight million downloads worldwide"
  2. "A stop smoking plan that works"
  3. "Real experts, great advice, 24/7"
  4. "Super helpful chatbot, tons of tips"
  5. "Whole body health improvements"
  6. "Badges for 90 quitting achievements"
  7. "Stop smoking clinics held 4x a day"
  8. "Crush cravings, understand triggers"
  9. "The motivation you need to succeed"
  10. "Your name on our Wall of Fame"
- No subheads.
- **Design:**
  - Green bold humanist sans, centred at the top, 2 lines, 4–6 words.
  - Pure white background.
  - Tilted or cropped iPhone frames overlapping, with large flat cartoon people (diverse adults, a robot, an older man celebrating).
  - Every slide carries an illustration as well as UI.
- **Slot 1:** a social-proof number ("Eight million downloads") over a tilted dashboard counter reading "1y 3m 24d", plus the heart logo and three diverse cartoon friends. It reads as "lots of people, friendly, long-term success".
- **Slots 1–3 together:** social proof, then "plan that works", then human experts. Smoke Free leads with credibility and support, not features.
- **Features shown, in order:**
  1. Counter.
  2. Health-improvement rings (decreased lung-cancer and heart-attack risk %) with "Today's mission".
  3. Advisor chat.
  4. AI/chatbot "Quit Coach".
  5. Health % (pulse, oxygen, CO).
  6. Badges, including a "money saved" badge.
  7. Live clinic schedule with sessions such as "Dealing with cravings and withdrawal".
  8. Craving log and diary with severity.
  9. Money saved with a wishlist ("Save up for something") and "Why are you stopping smoking?" motivation.
  10. Global Wall of Fame leaderboard.
- **NRT:** it is the only set to show NRT, as a "Spent on NRT/E-cigs" line in money saved (slot 9). This is NRT-tolerant.
- **Localisation miss:** money is shown in **£** (£719.74) on the US listing.
- **Tone:** warm, inclusive, supportive, with human experts. Relapse is not shown.
- **Evidence:** screenshots claim only "a plan that works" and "real experts". The description claims "over 40 different, evidence-based techniques" and an AI Quit Coach "proven to further increase your chances of success" ([listing](https://apps.apple.com/us/app/id577767592)).

#### 2. QuitNow (`quitnow/`, 7 shots, 600×1300, 6.5" class; product page shows the same creatives) — [listing](https://apps.apple.com/us/app/id483994930)
- **App Preview video first:** the product page plays a video before screenshot 1. Its poster (`_video_poster.jpg`) is the "Track your quit journey at a glance" frame. The first thing a visitor sees is therefore likely the tracking screen, not the WHO/App of the Day slide. This is an inference: I did not play the video.
- **Headlines in order** (the green highlight-pill words are given in brackets):
  1. "The easy way to quit smoking"
  2. "Track your [quit journey] at a glance"
  3. "[Overcome your cravings] one step at a time"
  4. "Stay motivated and unlock more than [80 achievements]"
  5. "See how your health improves [with facts] from the WHO"
  6. "Get support from your [quit buddies]"
  7. "Sync your progress with your [Apple Watch]"
- **Design:**
  - Flat saturated blue on every slide.
  - White semibold sans, centred, 6–9 words. The key phrase sits in a green rounded highlight pill.
  - Simple black device frame. The app's flat illustration style lives inside the UI.
  - A floating card pops out of the frame on slides 2, 4 and 6.
- **Slot 1:** no phone. Left-aligned big headline, an Apple logo with "APP OF THE DAY / APP STORE", "Recommended by World Health Organization" with the WHO emblem, and a photo of a raised open hand ("release").
- **Slots 1–3:** easy plus authority, then tracking, then cravings.
- **Features shown, in order:**
  1. Counter: "17 days 04 hours 23 minutes".
  2. Overall Progress: days quit, cigarettes avoided, dollars saved, "1d won back" (time regained).
  3. Community and a Reading nook.
  4. Craving tips: "Tip of the day", quit lines.
  5. Achievements: "3/82".
  6. WHO health milestones: CO level 100%.
  7. Community chat with Buddies.
  8. Apple Watch complication-style card.
- **Tone:** calm, friendly, shame-free, factual. No relapse shown.
- **Evidence:** WHO recommendation badge and "facts from the WHO". The description says its indicators "are the same ones published by the World Health Organization" ([listing](https://apps.apple.com/us/app/id483994930)). This is the only set besides EasyQuit to show a watch or widget surface.

#### 3. Quit Vaping (`quit-vaping/`, 10 shots, 600×1300, 6.9" class 1290×2796; **new creative set**) — [listing](https://apps.apple.com/us/app/id1479615245)
- **Older set:** the Lookup API's 5.5" set ("Ready to Quit?" over a purple gradient with iPhone 8 bezels, "eachother" typos and a mismatched "Take the Pledge" caption) is kept in `quit-vaping/api-lookup-set/`.
- **Headlines / subheads in order** (second headline line in a colour accent):
  1. "Quit vaping. For real this time." — no subhead; laurels "#1 APP To quit Vaping" and "4.9 Rating Global Ranking", plus a teal "DOCTOR APPROVED" seal.
  2. "Don't quit alone." / "Team up with a friend and track each other's progress."
  3. "Cut down your way." / "Log every puff and watch your nicotine intake drop."
  4. "Watch your body heal." / "See your lungs, heart and brain recover."
  5. "Join the community." / "Get support from people quitting right alongside you."
  6. "Every day counts." / "Keep your current and past vape-free streaks in view."
  7. "Breathe through it." / "Guided breathing and meditation to ease cravings."
  8. "Quit together. Win together." / "Climb the leaderboard with your friends."
  9. "Beat your cravings." / "Track moods and triggers, and journal your way through."
  10. "Hit goals. Earn badges." / "Celebrate every milestone on your way to vape-free."
- **Design:**
  - Each frame has its own soft pastel gradient (mint, lavender, sky, green, peach, purple).
  - Very heavy black rounded sans headline in two short lines, with the second line in green, blue, red or purple. A small grey subhead sits under it.
  - Current iPhone frames (Dynamic Island) over the dark-mode/green app UI.
  - Floating chips: "75% less nicotine in just 7 days", "1M+ members quitting together", "Personal best 44 days vape free", "Goal unlocked! 1 day vape free".
  - Small 3D/flat illustrations (money bag, meditating figure, people group, trophies).
  - Captions are always at the top. Captions and screens match.
- **Slot 1:** the brand promise plus three trust marks over the home screen: "You've been vape free for 35 Days 1 Hour 5 Minutes and 15 Seconds", money saved $119.88, completed goals 12/35, longest streak, "Remember why you quit: 'I quit to save money and improve my health'", and health rings 70/45/50%. The "Doctor Approved" seal names no doctor or body.
- **Slot 3 (new, reduction + NRT):**
  - Nicotine Tracker bar chart (16 mg → 4 mg over 7 days) and "You've consumed less nicotine then yesterday!" (sic).
  - A "Devices & Replacements" section logging "Nicotine Lozenge 4mg, Nicotine consumed: 4mg".
  - The header still reads "You've been vape free for 35D 1H 9M & 9S".
  - So the set shows a **taper model where nicotine-replacement use does not break the vape-free counter**.
- **Relapse:** slot 6 still shows the reset model: "Break your streak?" plus a "Past streaks" list (Recent / Oldest / Best) and a "Personal best" chip.
- **Other features:** buddy profile with a "Why Jonathan quit" quote (2), health improvements with Lungs/Heart/Brain and money saved weekly/monthly/total (4), community posts such as "Reasons to Never Vape Again" (5), guided breathing and meditations (7), buddy leaderboard (8), mood donut and craving log with triggers such as "Drinking" (9), and a goals grid (10).
- **Tone:** confident, upbeat, peer and gamified. The raw "F*ck vaping" post from the older set is gone.
- **Evidence:** trust marks only: "#1 APP", "4.9 Rating – Global Ranking", "Doctor Approved" and "1M+ members". None is sourced. The subtitle repeats "#1 App to Quit Vaping/E-Cigs".

#### 4. Kwit (`kwit/`, 10 shots, 600×1299, 6.5" class 1242×2688; **new creative set**) — [listing](https://apps.apple.com/us/app/id525441365)
- **Older set:** the Lookup API's 5.5" set (a sky-blue hills world, a "WHO" banner, an "App of the day" laurel, a green-boxed verb arc "Identify / Understand / Develop…" and a reviews closer) is kept in `kwit/api-lookup-set/`.
- **Headlines in order:**
  1. "Quit smoking successfully!"
  2. "5 minutes a day that can change everything"
  3. "A real monitoring, not just a counter"
  4. "Understand your triggers" (caption at the bottom)
  5. "Customize your experience"
  6. "Celebrate every victory" (bottom)
  7. "See how far you have come"
  8. "Engage with a supportive community" (bottom)
  9. "Learn every day"
  10. "Your success starts now!" (bottom)
- **Design:**
  - Soft pastel gradients that shift frame to frame (mint, lilac, pink, peach, cream).
  - A wide white "path" ribbon winds through all 10 frames as a continuity motif.
  - Dark-grey rounded sans, left-aligned, 2–3 lines, 3–8 words. Captions alternate top and bottom.
  - Modern iPhone frames (Dynamic Island), some tilted or cropped.
  - Pastel cat-like mood characters, and Kwit's green block mascot on 1 and 10.
- **Slot 1:** promise plus proof. A "+5M users" laurel and the WHO emblem (no text) sit over a tilted "My progress" screen ("Kwitter for 10 days 01 hours", money 65, cigarettes 10, time 10 days, life 3 days). The mascot in glasses snaps a cigarette. The older set's "App of the day" laurel is gone.
- **Slot 2, time-boxed daily routine:** "5 minutes a day that can change everything" over the home screen ("Hello, Marie", a My week streak, Today 2:18:29, task cards: My positive…, Mood tracking "How are you?", Read an article…, "What was important today?").
- **Slot 3, slips logged without a reset:** "A real monitoring, not just a counter". The "I feel like smoking" action grid offers **"I overcame a craving" / "I smoked" / "I write a memory" / "I breathe" / "I get motivated" / "I set up my substitutes"**. A smoked cigarette is a normal log entry next to a resisted craving.
- **Slots 4–5:** craving intensity slider, emotion grid (Stressed, Alone, Happy, Bored, Excited, Depressed, Angry, Anxious) and situation chips ("I am on the phone", "I am taking a break"). Then a personal strategy builder ("I take a walk").
- **Slots 6–10:** trophies 10/36 ("Perfect Month", "A New Beginning", "The Statistician", "Inner Peace"…); stats (Kwitter for 10 d 01 h 25 min, money 65, cigarettes 130, time 10 days, life 3 days); a community thread ("SOS! Day 5 and I'm feeling overwhelmed… How do you handle cravings when it gets too tough?" with replies such as "Hang in there! Day 5 is one of the hardest."); "Our best tips" articles; and a mascot-only closer.
- **Tone:** gentle, playful, emotion-first. A slip ("I smoked") is shown as data, not failure, although no caption says so.
- **Evidence:** "+5M users" and the WHO emblem on slot 1. Money is shown without a currency symbol. The description says "first WHO-validated smoking cessation app", "evidence-based cognitive behavioral therapy" and "5+ million people" ([listing](https://apps.apple.com/us/app/id525441365)).

#### 5. Puff Count (`puff-count/`, 5 shots, 600×1300) — [listing](https://apps.apple.com/us/app/id1488580640)
- **Headlines in order:**
  1. "Ready to QUIT?" (with "QUIT?" huge)
  2. "Track your puffs"
  3. "Custom Quit Plan"
  4. "Progress at your own pace"
  5. "Celebrate your achievements"
- **Design:**
  - Electric blue-violet gradient with white cartoon clouds.
  - Heavy rounded white sans, 2–4 words, centred at the top.
  - Upright modern frame. Floating cards break out of the frame ("Set Your Daily Check-ins" toggle, "PUFF TRACKER Day 12 of 54 complete 34% / Change my plan").
- **Slot 1:** no phone. Question headline, a fake CTA button "Add your vape", and an illustration of a hand gripping a vape inside a prohibition circle.
- **Approach:** a **taper/reduction** quit model, not cold turkey:
  - "Today's Puff 139/200", "You've hit 56% of your limit", with +/− puff buttons.
  - The plan shows money saved $200, "Days within limit 10 days", "Vape free days 3 days".
  - A progress-vs-plan line chart, and hourly analytics ("Most active period 14:00", "Average break 15 min").
- **Slot 5:** a grid of more than 15 badges (Begun, First Day, Week Strong, 14-Day Win, a 30 badge…).
- **Tone:** neutral and data-driven, "at your own pace". No shame and no relapse framing; reduction makes slips implicit.
- **Evidence:** none in the screenshots. The description says "over 800,000 users". It is listed under Lifestyle, not Health & Fitness ([listing](https://apps.apple.com/us/app/id1488580640)).

#### 6. QuitSure (`quitsure/`, 10 shots, 600×1299, 6.5" class 1242×2688; same creative as the 5.5" Lookup set, now in `api-lookup-set/`) — [listing](https://apps.apple.com/us/app/id1523992725)
- **Product-page notes:** the taller frame shows a third slot-3 toolkit item that the earlier notes did not list, "Immersive exercises – Mental exercises to transform how you think and feel about smoking". The product-page subtitle is "Clinically proven. 81% success", so the 81% claim is now also in the subtitle.
- **Headlines in order:**
  1. "Addicted to smoking?" with subhead "Quit smoking at your own pace"
  2. "Rewire your brain with neuroscience" with laurel "Over 3 MILLION downloads"
  3. "81% quit completely*" with laurel "*UCSF study"
  4. "No self-control needed"
  5. "Start now and celebrate your progress"
  6. "Get support from your quit buddies"
  7. "Quit Effortlessly"
  8. "1-on-1 coaching at your fingertips"
  9. "Personalized to your triggers"
  10. "Take the Quiz"
- **Design:**
  - A different saturated flat colour on each slide: coral, petrol blue, periwinkle, mustard, lavender, teal, sky, violet, green, red.
  - White bold sans, centred at the top, 2–6 words.
  - A 3D-rendered fox mascot (plus a puppy "buddy") on 9 of 10 slides.
  - Slides 1 and 2 share a diagonal panorama phone.
  - Rounded light frames, sometimes no frame (slot 7 is a pure list).
- **Slot 1:** asks the problem ("Addicted to smoking?") and lowers the barrier ("at your own pace"). The fox stamps out a cigarette.
- **Slots 1–3:** problem, then mechanism plus scale (neuroscience, 3M downloads, a phone reading "Congratulations! You are a non-smoker now. You are free."), then **outcome statistic** ("81% quit completely*", footnoted to a UCSF study). Slot 3's screen claims the plan is built "based on millions of data points from millions of successful QuitSure clients". Its toolkit lists "A step-by-step plan to remove your desire to smoke" and "Daily text/video lessons in a simple story-telling style".
- **Slot 4:** a marionette illustration (a man on strings), the "you're being controlled" metaphor.
- **Slot 5:** "Track and crack". "You last smoked: 23 mins ago" and a falling cigarettes-per-day bar chart (20→7) show that **smoking continues during the program**. Also "681 smoke-free days" and a money figure.
- **Slot 7, a list of absence claims:**
  - "No withdrawal symptoms"
  - "No chewing gums/vapes"
  - "No weight gain"
  - "No Lifestyle change"
  - "No Guilt"
- **Anti-NRT stance:** "No chewing gums/vapes".
- **Slot 8:** a stock-photo coach card "Sarah – Recommended Coach" with specialties including "Relapse Prevention".
- **Slot 9:** a trigger checklist (waking up, break at work, alcohol, after a meal, coffee/tea, seeing someone smoke…).
- **Slot 10:** a quiz preview ("When you think about not being able to smoke anymore, what do you feel?").
- **Tone:** empathetic, "not your fault", "no guilt", combined with the biggest promises in the category.
- **Evidence:** "81% quit completely*" with UCSF, "Over 3 MILLION downloads", and the effortlessness claims. The description adds "96% of quit attempts fail" and "Grounded in principles of psychology, neuroscience" ([listing](https://apps.apple.com/us/app/id1523992725)).
- **Conflicting numbers:** an in-app lesson cites "95% success" and "100,000+ clients" (local note `/home/user/DAYXERO/research_notes/quitsure_day1_teardown.md`). The 81%/95% and 3M/2M figures disagree across QuitSure's own surfaces.

#### 7. EasyQuit (`easyquit/`, 10 shots, 600×1299, 6.5" class 1242×2688; same creative as the 5.5" Lookup set, now in `api-lookup-set/`, re-framed in iPhone X-style notch frames) — [listing](https://apps.apple.com/us/app/id1508110799)
- **Headlines in order:**
  1. "All Statistics On One Page"
  2. "Motivational Health Section"
  3. "+100 Beautiful Badges"
  4. "Play Matching Pairs Game"
  5. "Quit Slowly Mode"
  6. "Colorful Widgets (Pro Version)"
  7. "Track & Eliminate Your Cravings (Pro Version)"
  8. "Set & Reach Personal Treats"
  9. "Plenty Of Helpful Tips"
  10. "Your Personal Diary (Pro Version)"
- **Design:**
  - The purple→pink gradient fills both the background and the app screens, so the device nearly disappears.
  - Lavender **serif** Title-Case headline (Times-like), 2–4 words, low contrast.
  - Small frames with drop shadows. UI text is unreadable at store size.
  - "(Pro Version)" labels appear on 3 slides.
- **Slot 1:** a plain feature label with no promise or proof, over a stats dashboard. The money tile shows **€** (731 €) on the US listing.
- **Features:**
  - Stats grid (money, health, time).
  - Health organ circles.
  - 100+ badges.
  - **Memory mini-game for cravings**, the only game in the set.
  - "Quit Slowly" taper grid (cigarettes allowed per day).
  - **Home-screen widgets**, the only widget slide among the 10 apps.
  - Trigger donut chart.
  - Treat goals ("Time to reach your goal").
  - Tips and a diary.
- **Tone:** neutral and utilitarian. No relapse, social proof or evidence.

#### 8. I Am Sober (`i-am-sober/`, 9 shots, 600×1299, 6.5" class 1242×2688; same creative as the 5.5" Lookup set, now in `api-lookup-set/`) — [listing](https://apps.apple.com/us/app/id672904239)
- **Headlines in order:**
  1. "Quit Any Addiction"
  2. "Track Your Sobriety"
  3. "Monitor Your Progress"
  4. "Reach Your Recovery Goals"
  5. "Build Better Habits"
  6. "Get Community Support"
  7. "Learn From Others"
  8. "Stay Motivated"
  9. "Grow Your Savings"
- **Design:**
  - Dark teal-navy with a purple wave.
  - Heavy white Title-Case sans, 2–3 words, top.
  - Logo on slot 1.
  - Slides 1 and 2 form a panorama: the tilted phone shows a stacked gradient counter "23 days / 8 hours / 29 minutes / 51 seconds" plus "Last milestone".
  - Frameless upright screens after that.
- **Slot 1:** a broad scope promise (any addiction) with a big counter.
- **Features:**
  - Multiple simultaneous counters: Alcohol 23 days, $184, 3,450 calories saved; Caffeine; Pills.
  - **Daily pledge**: "Today, I will stay sober", with a "Why I'm doing this" photo wall of user photos and reasons such as "I want my family to respect me" and "No more hangovers!".
  - Pledge challenge, "Pledge for seven days", and a Workbook.
  - Community pledges ("30% pledged"), milestone posts with real user photos, a Stoic quote card, and savings projection ($184 now, $243.33 a month, $2,920 a year).
- **Tone:** calm, earnest, community-and-ritual. Relapse is not shown.
- **Evidence:** no claims and no press. The rating count (191k) is the implied proof and is not shown.

#### 9. Reframe (`reframe/`, 10 shots, 600×1304, i.e. a 6.7" set) — [listing](https://apps.apple.com/us/app/id1485756576)
- **Headlines and subheads in order:**
  1. "Manage Drinking with Neuroscience" ("Neuroscience" in cream-yellow)
  2. "Jumpstart your journey towards a better life" (in a white circle)
  3. "Programs developed by leading experts in Psychology & Neuroscience"
  4. "Backed by data and results"
  5. "Track and celebrate your goals" / "Your progress at a glance"
  6. "Customized programs" / "Catered to your own needs and pace"
  7. "You're not alone" / "A community that cares and encourages"
  8. "Manage drinking one milestone at a time"
  9. "Take control of your habits"
  10. "Trusted by 2 million + users worldwide"
- **Design:**
  - Deep blue gradient with a soft wave.
  - White semibold sans with a yellow accent word, 4–8 words.
  - A tilted white phone straddles slides 1 and 2.
  - Clean, premium, consistent.
- **Slots 1, 3, 4 and 10 are pure credibility with no UI:**
  - Slot 1: a laurel ('"Life Changing" ★★★★★'), a press logo row (FORTUNE, TechCrunch, Forbes, TED), and a laurel "2023 Global Excellence winner".
  - Slot 3: university logos: Stanford, Georgia Tech, Emory School of Medicine, Harvard.
  - Slot 4: "91% of Reframe users noted a substantial decrease in alcohol use within 3 months" and "82% of Reframers noted a substantial decrease in alcohol use within 2 months". These are self-reported user outcomes with no study named.
  - Slot 10: "Trusted by 2 million + users" plus two short user quotes.
- **UI slides:**
  - Day-streak strip and daily tasks: a "5 min read" neuroscience lesson, Daily Motivation, Log your drink.
  - Toolkit with an "I Have a Craving" card, coping strategies and mindfulness.
  - Forum.
  - Drink tracker against a target, with $400 saved.
  - Discover: live community meetings with coaches, daily check-ins.
- **Tone:** science-y, aspirational, non-judgemental ("manage", "drink less", not "quit").
- **Evidence:** the heaviest proof stack in the benchmark. The description says "#1 alcohol reduction app" and "core 160-day, evidence-based, education program" ([listing](https://apps.apple.com/us/app/id1485756576)).

#### 10. Sober Sidekick (`sober-sidekick/`, 10 shots, 600×1298, 6.5" class 1284×2778; **new creative set**) — [listing](https://apps.apple.com/us/app/id1448251580)
- **Older set:** the Lookup API's 8-frame 5.5" set ("Track Sobriety / One Day At A Time" … "Judgement Free / We Are In This Together!", alternating teal and periwinkle, iPhone X frames) is kept in `sober-sidekick/api-lookup-set/`.
- **Headlines in order** (accent words in brackets, in bold orange or magenta):
  1. (no caption) The left half of a 1→2 panorama phone.
  2. "Your Path to Sobriety Starts [Here.]"
  3. "Access Support Whenever [You Need It.]"
  4. "Join a [Trusted Community] of Change."
  5. "Take the First Step Toward a [Better Life.]"
  6. "Commit to Your Sobriety Journey [Today.]"
  7. "Celebrate [Every] Milestone."
  8. "Everything You Need in [One Place.]"
  9. "Stay Inspired, [Stay Strong.]"
  10. "[You're Not Alone] Join Thousands on the Recovery Journey."
- **Design:**
  - The same vertical teal → violet gradient on every frame, joined by thin dashed connector lines across frame edges.
  - Light-weight white sans headlines, 3–4 lines, with one bold coloured phrase. Captions sit at the top, left-aligned on 2 and centred elsewhere.
  - Current iPhone frames (Dynamic Island). Cards break out of the frame (Meetings, Reads).
  - Real user photos (landscapes, a sunset pier, a hiker) in feed posts.
- **Slots 1–2:** an oversized tilted phone with a floating share card: "My life is worth the work", 2 Years / 28 Mon… / 874 Days, #SoberSidekick. The screen below shows "USD 8740 Money Saved", members supported, and milestone bars ("2 Year – 221 days until next Year milestone", "29 Month"). Slot 2 adds the "Never Alone" app icon.
- **Slot 4, a social-proof card with no UI:** ★★★★★, "2M Sobriety Goals Completed.", and the testimonial "Being in recovery has given me everything of value that I have in my life. – Jeff. K".
- **Features:** 24/7 AA and NA meetings ("Join Meeting"), Reads ("Just For Today Meditation", "Why I started Sober Sidekick"), Listens (YouTube "The Day You Want To Quit"), a "Getting Started" journey card, "My Comeback Story" ("One Day At A Time – Progress not perfection") and "Today's most supportive members" ("Gave support 43X today").
- **Slot 10:** encouragement bubbles: "Your best days are ahead of you!", "You don't have to see the whole staircase.", "I chose sober because I wanted a better life!"
- **Craft issue:** slot 7's caption "Celebrate Every Milestone." sits over the Meetings/Reads/Listens screen, which repeats slot 3.
- **Tone:** warm, recovery-program, shame-free in spirit ("Progress not perfection", "You can only judge yourself by the person you choose to be today"). The explicit "Judgement Free" headline of the older set is gone.
- **Evidence:** "2M Sobriety Goals Completed" with 5 stars and one named testimonial, all unsourced. Its product-page subtitle is the competitor phrase "Reframe: Drink Less Alcohol".

#### Bonus. Exhale (`exhale-quit-vaping/`, 5 shots, 600×1299) — [listing](https://apps.apple.com/us/app/id6756926563)
- **Headlines in order:**
  1. "Quit vaping for good" / "With Exhale"
  2. "Track your progress"
  3. "Understand your addiction"
  4. "Stay accountable of your choices" (sic)
  5. "And much more!"
- Slot 5 is a pill list: Personalized plan, Panic button, Progress tracking, Health recovery, Savings tracker.
- **Design:** light-blue gradient, heavy rounded white sans, current iPhone Pro frame, and a cute blue **lung mascot**.
- **Slot 1 home screen:**
  - "You've been vape-free for 16 Days 15 hrs 42 mins 23 secs".
  - Quick actions **Check-ins / I relapsed / Progress / Learn**.
  - A **red panic button (warning triangle) centred in the tab bar** on every UI shot.
- **Slot 2:** days vape-free 23, money saved (€65; another € on a US listing), 350 XP Level 4, milestones, a 23/30-day goal, daily puff count.
- **Slot 3:** a learn track with "3 min read" lessons (Lung repair timeline, Oxygen rebound, Urge surfing, Rewrite the story, Micro-celebrations).
- **Slot 4:** daily check-in.
  - "Vape-free today?" with options "Yes! I stayed strong" / "Not quite".
  - Cravings 1–5, mood, self-control.
  - Supportive microcopy: "Some urges — you managed them" and "Shaky moments — you're still trying".
- **Tone:** explicitly guilt-free. The description says "Built for people who want real progress, not guilt" ([listing](https://apps.apple.com/us/app/id6756926563)).

### Inferences
- Screenshot 1 strategies (product-page sets):
  - **Proof number / trust marks:** Smoke Free (8M downloads), Quit Vaping ("#1 APP", "4.9 Rating", "Doctor Approved"), Kwit ("+5M users" + WHO emblem).
  - **Authority badge:** QuitNow (WHO + App of the Day), Reframe (press + award).
  - **Question/hook:** Puff Count ("Ready to QUIT?"), QuitSure ("Addicted to smoking?"). Quit Vaping dropped "Ready to Quit?" for "Quit vaping. For real this time."
  - **Scope/feature/counter:** I Am Sober, EasyQuit, Sober Sidekick (uncaptioned counter panorama), Exhale.
  - **Video before slot 1:** Smoke Free and QuitNow.
  - Only QuitSure puts an outcome-rate claim in the first 3 slides ("81% quit completely", now also its subtitle). Quit Vaping's slot-3 chip "75% less nicotine in just 7 days" is a personal UI result, not a population rate. No app uses "quit in X days" in the screenshots, even QuitSure with its 6-day program.
- Showing a real counter in slot 1 or 2 is near-universal (9 of 11). The counter is the category's hero visual.
- Relapse and slips are still rare:
  - Quit Vaping ("Break your streak?" with past streaks and a personal best, a reset model) and Exhale ("I relapsed" button, "Not quite" check-in) show relapse.
  - **Kwit's new slot 3 lists "I smoked" as an ordinary log option** next to "I overcame a craving", under "A real monitoring, not just a counter". It does not show what happens to the counter.
  - **Quit Vaping's slot 3 logs a nicotine lozenge while the "vape free" counter keeps running.** NRT use does not count as a lapse.
  - QuitSure lists "Relapse Prevention" as a coach specialty and shows ongoing smoking as normal.
  - Nobody says "a slip doesn't reset your count" in a caption.

### Gaps
- I did not check whether the US listings use Custom Product Pages or A/B tests (Product Page Optimization). I fetched each product page once.
- Resolved: the 600×1067 sets came from the Lookup API returning an older 5.5" upload. For QuitSure, EasyQuit and I Am Sober the product page shows the same creatives at 6.5". For Quit Vaping, Kwit and Sober Sidekick it shows entirely new sets.
- I could not find the "UCSF study" behind QuitSure's 81%, or the method behind Reframe's 91%/82% (self-reported). Neither was verified.

## Q3. Cross-app patterns: table stakes, overused moves, gaps DayXero could own, strongest sets

### Takeaway
Table stakes are a live counter, money saved, health recovery, badges, community and a craving tool. The overused moves are tilted-phone panoramas, laurel badges, WHO logos, mascots and unsourced "#1 / doctor approved" trust marks.

Nobody fully owns three things DayXero is built on:
- A **visible prep-then-Quit-Day structure**.
- **Slips that don't reset**. Kwit now edges toward this with an "I smoked" log option.
- **Cigarettes + vapes + pouches in one app**.

The product-page refresh closed one gap: **Kwit now leads slot 2 with "5 minutes a day that can change everything"**, which takes the time-boxed daily routine angle.

The strongest sets are:
- **Reframe:** proof stacking.
- **Quit Vaping:** its new set is crisp and modern, with two-tone headlines and trust marks on slot 1.
- **QuitNow:** clarity at thumbnail size.
- **Kwit:** daily routine, "not just a counter" and a slip log.
- **Smoke Free:** warm benefit headlines.
- **Exhale:** relapse and panic shown in slot 1.

### Cited Findings
Each count comes from the per-app evidence in Q2 (images in the library; listings linked above).
- **Table stakes, counted across 11 sets:**
  - Live time counter: 9 of 11 (all except EasyQuit and Reframe as a hero).
  - Money saved: 11 of 11 (Sober Sidekick's new set shows "USD 8740 Money Saved").
  - Health recovery rings or timeline: 5 shown in screenshots (Smoke Free, QuitNow, Quit Vaping, EasyQuit, Exhale). Kwit's new set shows a "Life 3 days" regained stat but no health timeline.
  - Badges, achievements or XP: 7 (Smoke Free "90", QuitNow "80", Quit Vaping, Puff Count, EasyQuit "+100", Exhale, Kwit trophies 10/36).
  - Community or social: 8.
  - Craving tool: 7 (Smoke Free, QuitNow, Quit Vaping "Breathe through it", Kwit's "I feel like smoking" flow on slots 3–4, EasyQuit, Reframe, Exhale's panic button).
  - Human or AI coaching: 3 (Smoke Free advisors, chatbot and clinics; QuitSure 1-on-1; Reframe coach meetings).
  - Structured lessons or program: 5 (QuitSure, Reframe, Exhale, Kwit "Learn every day" + "5 minutes a day", Smoke Free "plan").
  - Widgets or Watch: 2 (EasyQuit widgets, QuitNow Watch).
  - NRT: 2 tolerant (Smoke Free's "Spent on NRT/E-cigs" line; Quit Vaping's "Devices & Replacements" lozenge log alongside a running vape-free counter) and 1 opposed (QuitSure).
  - App Preview video ahead of the screenshots: 2 (Smoke Free, QuitNow).
- **Big numbers on counters:**
  - Seconds-level precision is common (Quit Vaping, I Am Sober, Exhale).
  - Vape apps add vape units: a daily mg nicotine-consumed chart and "Log every puff" (Quit Vaping; the older set's "pods not vaped / puffs not taken" is gone), and puffs against a limit (Puff Count).
- **Overused moves:**
  - A tilted phone spanning slides 1–2: QuitSure, I Am Sober, Reframe, Sober Sidekick (new set). Quit Vaping and Kwit no longer use one; Kwit uses a winding path ribbon across all 10.
  - Laurel badges: QuitSure ×2, Kwit ("+5M users"), Reframe ×2, Quit Vaping ×2 ("#1 APP", "4.9 Rating") plus a "Doctor Approved" seal.
  - WHO logo: QuitNow, Kwit (emblem only).
  - Mascots: QuitSure fox, Kwit block character, Exhale lung. Smoke Free uses cartoon people.
  - "Ready to Quit?" verbatim: now only Puff Count.
  - Generic "Track your progress" or "Celebrate your achievements" headlines in most sets ("Celebrate every victory" for Kwit, "Celebrate Every Milestone." for Sober Sidekick).
  - Saturated blue or purple gradients: still about 7 of 11. Quit Vaping has moved to multi-colour pastels, and Sober Sidekick's teal→violet gradient is in the group.
- **Localisation misses on US listings:** £ (Smoke Free), € (EasyQuit, Exhale). Kwit's new set omits the currency symbol.
- **Evidence-claim spectrum:**
  - No claims: Puff Count, EasyQuit, I Am Sober, Exhale.
  - Unsourced trust marks: Quit Vaping ("#1 APP", "4.9 Rating – Global Ranking", "Doctor Approved", "1M+ members"), Sober Sidekick ("2M Sobriety Goals Completed", 5 stars, a testimonial).
  - Authority badges: QuitNow and Kwit (WHO), Smoke Free ("real experts").
  - University logos plus self-reported percentages: Reframe.
  - Outcome rate plus absolute promises: QuitSure ("81% quit completely*", "No withdrawal symptoms", "No weight gain").
  - None of the 11 sets mentions FDA, NHS, CDC or a named RCT in the screenshots.
- **Tone:**
  - Shame-free language is explicit in QuitSure ("No Guilt") and Exhale (check-in microcopy). Sober Sidekick's new set drops "Judgement Free" but keeps the spirit in UI copy ("Progress not perfection"). Kwit shows it by treating "I smoked" as a neutral log entry.
  - Playful or gamified: Kwit, Quit Vaping, EasyQuit, Puff Count.
  - Clinical or scientific: Reframe, QuitSure (claims), Smoke Free (clinics).
  - Tough-love or fear: absent apart from QuitSure's marionette metaphor and Quit Vaping's raw community post.

### Inferences
**Gaps DayXero could own:**
1. **A visible prep-to-Quit-Day arc.** QuitSure has a 6-day prep program but never shows it as a timeline in screenshots; it shows "at your own pace" and a bar chart instead. Puff Count's "Day 12 of 54" plan card is the closest thing. A slot-1 or slot-2 visual such as "7 days of prep → Quit Day → days clear" would be unique in the category.
2. **"Slips don't reset your counter."** Most counters shown are streaks. Quit Vaping makes reset explicit ("Break your streak?"), and Exhale has an "I relapsed" button. The gap is narrower than it first looked: Kwit's slot 3 now offers "I smoked" as a neutral log option under "A real monitoring, not just a counter", and Quit Vaping's counter keeps running while a nicotine lozenge is logged. Neither *states* that a slip keeps your days. A screenshot that shows a slip logged while the days-clear count holds, captioned to say so, would still be first-of-kind. It delivers the "no guilt" promise in UI form rather than as a claim.
3. **All three nicotine forms.** Cigarette apps ignore vapes and pouches in their visuals. Vape apps ignore cigarettes; Quit Vaping now logs "Devices & Replacements" (a lozenge) but still sells vaping only. No pouch app has scale (21 ratings at best). "Cigarettes, vapes, pouches" as one headline, with a product picker in UI, is open ground. It also captures the Zyn audience that the US top 10 does not serve.
4. **Time-boxed daily session — no longer open.** Kwit's current product page leads slot 2 with "5 minutes a day that can change everything" over a daily task list. Exhale ("3 min read") and Reframe ("5 min read") show lesson length but bury it. DayXero can still use the angle, but must differentiate it, e.g. with a concrete daily mechanic and a visible prep → Quit Day timeline, rather than claim it as unique.
5. **Craving SOS as a hero.** Only Exhale shows a persistent panic button, and it names "Panic button" only in slot 5's list. Kwit puts its "I feel like smoking" flow on slots 3–4, and Quit Vaping's "Breathe through it" is slot 7. A dedicated "Craving SOS" slide in the first 3 would still be distinctive.
6. **Honest proof.** The category either has no proof or has inflated or unsourced numbers. The refresh made this worse: Quit Vaping now carries "#1 APP", "4.9 Rating – Global Ranking" and an unattributed "Doctor Approved" seal, and Sober Sidekick claims "2M Sobriety Goals Completed". If DayXero has no outcome data, specific mechanism proof (what the program does each day) plus real rating counts beats laurels, which are now wallpaper.
7. **Craft and localisation.** On the product pages the dated 5.5" bezels are mostly gone: Quit Vaping, Kwit and Sober Sidekick now use current Dynamic Island frames. The craft gap is narrower. It remains for EasyQuit (low-contrast serif, notch frames, €), Smoke Free (£) and Exhale (€). A crisp, correctly localised US set is now table stakes rather than a differentiator.

**Strongest sets and why:**
- **Reframe:** the most disciplined proof sequence (press, then universities, then data, then UI, then a "2M users" close), one consistent visual system, and an accent word in each headline. Its weakness is that 4 of 10 slides contain no product.
- **QuitNow:** every headline is readable at thumbnail size, the green highlight pill guides the eye to the benefit, slot 1 combines "easy" with WHO and Apple badges, and it closes on Apple Watch. Its weakness is a generic blue look.
- **Smoke Free:** clear benefit headlines with concrete numbers ("90 quitting achievements", "clinics held 4x a day", "8 million"), warm diverse illustration and real breadth of support. Its weaknesses are £ on the US page and busy layouts.
- **Exhale:** modern. It shows the relapse button, a panic button and guilt-free check-in copy, which is the closest in spirit to DayXero. Its headlines are generic and it has only 5 slides.
- **Quit Vaping (new set):** the biggest upgrade in the refresh. It has punchy two-line two-tone headlines ("Cut down your way.", "Watch your body heal."), one benefit and one floating proof chip per frame, current frames, and trust marks on slot 1. Its weaknesses are that the trust marks are unsourced ("Doctor Approved" names no doctor), there is a "then" typo in the UI, and it still uses a reset-streak model.
- **Kwit (new set):** the closest competitor positioning to DayXero. It pairs "5 minutes a day" with "A real monitoring, not just a counter", an "I smoked" log option, triggers and a personal strategy, all in the first 5 frames. Its weaknesses are low-contrast thin grey captions on pastel and a mascot-only closer.
- **Weakest:** EasyQuit (low-contrast serif, a feature catalogue, Pro labels). Sober Sidekick's new set is warmer and adds proof, but its captions are generic ("Everything You Need in One Place.") and slot 7's caption repeats slot 3's screen. Quit Vaping is no longer among the weakest.

### Gaps
- There is no conversion data (Product Page Optimization results) to show which slot-1 strategy actually converts in this category. The judgements above are qualitative.
- I did not check iPad sets, Custom Product Pages, or listings in other storefronts.
