# App Store screenshot benchmark: top 10 US "quit" apps (fetched 2026-11-20)

Library root: `/home/user/DAYXERO/reference/app-store-screenshots/quit/`. Each `{slug}/` folder holds `01.jpg…NN.jpg` (600px wide, in store order), `_sheet.jpg` (contact sheet at 300px per screen) and `app.json` (id, name, seller, rating, ratingCount, version, original screenshotUrls, fetched date). Everything comes from `itunes.apple.com/lookup?id=…&country=us` on 2026-11-20, iPhone screenshots only. All headline quotes below were read off the images. The image files and the lookup JSON are the primary sources. For each app the cited source is its US App Store listing.

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
| 10 | Sober SideKick: Quit Addiction `sober-sidekick/` | alcohol/AA-NA | 8,136 | 4.83 | 8 | 2019 | [App Store](https://apps.apple.com/us/app/id1448251580) |
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
  - Kwit: "5+ million people" (description).
  - Puff Count: "over 800,000 users" (description).
  - Quit Vaping: "Join over a million" (screenshot 04).
  - Reframe: "Trusted by 2 million + users" (screenshot 10).
- The Sensor Tower Q4 2025 US Health & Fitness top-5 lists contain no quit apps ([Sensor Tower](https://sensortower.com/blog/2025-q4-ios-top-5-health-and-fitness-units-us-600af518241bc16eb8dce802)). Public Appfigures profile pages show no numbers ([Appfigures](https://appfigures.com/reports/app-profile/319978592229/downloads)).

### Inferences
- Rating count is a lifetime total, so it favours old apps: QuitNow dates from 2011 and Smoke Free and Kwit from 2012. Exhale's 313 ratings in about 8 months suggests it is growing faster now than EasyQuit or Kwit. The current download leaders could differ from this table, especially among 2025–26 vape apps.
- The nicotine leaders split into **cigarette apps** (Smoke Free, QuitNow, Kwit, EasyQuit, QuitSure) and **vape apps** (Quit Vaping, Puff Count, Exhale). No top app positions itself on cigarettes, vapes and pouches together. QuitSure's title says "Smoking & Vaping", but its screenshots are about cigarettes only.

### Gaps
- I could not get real download estimates. Sensor Tower, Appfigures and AppMagic are paywalled, and no article published current US download ranks.
- I could not get App Store search-result order for "quit smoking" or "quit vaping": `/search` returns 403 and web search does not reproduce in-store ranking.
- App subtitles are not in the lookup API, so they were not captured.

## Q2. Per-app screenshot analysis (verbatim headlines, design, sequencing, claims)

### Takeaway
The category runs on a fixed formula: one headline (2–8 words) over a framed UI screen, with a live counter, money saved, health rings and badges in the first 2–5 slots. The apps differ mainly in **slot 1**:
- Social-proof numbers: Smoke Free.
- Authority badges: QuitNow, Kwit, Reframe.
- A question to the reader: Quit Vaping, Puff Count, QuitSure.
- A feature: EasyQuit, I Am Sober.

They also differ in how far they go on **evidence claims**. QuitSure and Reframe make the strongest numerical claims.

### Cited Findings

#### 1. Smoke Free (`smoke-free/`, 10 shots, 600×1299, i.e. a 6.5"/6.7" set) — [listing](https://apps.apple.com/us/app/id577767592)
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

#### 2. QuitNow (`quitnow/`, 7 shots, 600×1300) — [listing](https://apps.apple.com/us/app/id483994930)
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

#### 3. Quit Vaping (`quit-vaping/`, 10 shots, 600×1067, an older 5.5" set) — [listing](https://apps.apple.com/us/app/id1479615245)
- **Headlines and subheads in order:**
  1. "Ready to Quit?"
  2. (no caption; the tilted phone continues from slide 1 as a panorama)
  3. "Buddy System" / "Quit with a friend and track eachother's progress"
  4. "Community" / "Join over a million helping eachother become vape free" (caption at the bottom)
  5. "Vape Tracker" / "Easily view all info about your current progress"
  6. "Take the Pledge" / "Track your cravings, triggers and journal entries" (bottom)
  7. "Leaderboard" / "Compete against your friends to stay vape free!"
  8. "Calm" / "Stop cravings with a session of guided breathing & meditation" (bottom)
  9. "Goals" / "Complete goals and earn badges!"
  10. "Streak Tracker" / "Keep track of past vape free streaks" (bottom)
- **Design:**
  - Purple-violet gradient. Captions alternate between top and bottom.
  - Heavy white sans title with a lighter subhead.
  - Old iPhone 8-style bezels.
  - The app UI is dark mode with bright green cards and gets busy.
  - Typos: "eachother".
  - The caption and screen on slide 6 don't match: "Pledge" sits over a mood pie chart and craving journal.
- **Slot 1:** a question ("Ready to Quit?") over a counter accurate to the second: "You've been vape free for 30 Days 2 Hours 6 Minutes and 41 Seconds". Also shown: money saved $85.97, completed goals 12/23, longest streak, and a "Remember why you quit" quote.
- **Slots 1–3:** counter, then health rings (Lungs 70%, Heart 45%, Brain 50%, with a health achievement "It's been a heartfelt month!"), then a social buddy.
- **Vape-specific metrics (slot 5):**
  - "$75.36 money saved"
  - "15 pods not vaped"
  - "Puffs not taken: 27253"
  - "Nicotine avoided: 5450mg"
- **Relapse:** the slot-10 Streak Tracker shows a "Break your streak?" button and a "Past streaks" list. The model is reset-and-archive.
- **Tone:** peer, gamified, competitive (leaderboard), with raw community voice. A shown post is titled "F*ck vaping".
- **Evidence:** none in the screenshots. Social proof is "over a million" (slot 4).

#### 4. Kwit (`kwit/`, 10 shots, 600×1067) — [listing](https://apps.apple.com/us/app/id525441365)
- **Headlines in order:**
  1. Speech bubble "Quit smoking with Kwit!" under a top banner "Application recommended by WHO". Slides 1–2 form one panorama.
  2. "App of the day" laurel over a tilted phone.
  3. "[Identify] your cravings"
  4. "[Understand] how you feel"
  5. "[Develop] the best strategies"
  6. "[Check] your progress"
  7. "[Share] your experience"
  8. "[Feel] the benefits of quitting"
  9. "[Enjoy] your new life"
  10. No headline: two 5-star user reviews.
- The verb in brackets sits in a green box.
- **Design:**
  - Pale sky-blue background with green hills and sparkles.
  - Kwit's toast-like block mascot.
  - Dark-grey rounded sans, centred, 3–4 words, with the verb highlighted in a green box.
  - Modern iPhone frames, mostly upright.
  - Pastel and playful, with the most coherent "world" in the set.
- **Slot 1:** authority (WHO) plus brand promise plus mascot holding a no-smoking sign. Slot 2 adds the Apple "App of the day" laurel and the home screen ("How are you today?", daily mood check-in, "Kwitter for 10 days 01 h 25").
- **Sequencing:** a CBT story arc in imperative verbs: identify → understand → develop → check → share → feel → enjoy.
- **Craving flow (slots 3–5):**
  - "I feel like smoking" strength slider.
  - Emotion grid: Stressed, Lonely, Happy, Bored, Excited, Down, Angry, Anxious.
  - "I choose an alternative" cards: let the craving go, get motivated, breathe, drink water.
- **Slot 8:** a health timeline ("Health 2/22", e.g. "You have not inhaled 2 g of carbon monoxide").
- **Slot 9:** stats "$4 508 saved", "17 556 liters of water saved" (an environmental angle unique to Kwit), "4745 cigarettes not smoked".
- **Tone:** gentle, playful, emotion-first. Relapse is not shown.
- **Evidence:** WHO badge and App of the Day. The description says "first WHO-validated smoking cessation app", "evidence-based cognitive behavioral therapy" and "5+ million people" ([listing](https://apps.apple.com/us/app/id525441365)).

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

#### 6. QuitSure (`quitsure/`, 10 shots, 600×1067) — [listing](https://apps.apple.com/us/app/id1523992725)
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

#### 7. EasyQuit (`easyquit/`, 10 shots, 600×1067) — [listing](https://apps.apple.com/us/app/id1508110799)
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

#### 8. I Am Sober (`i-am-sober/`, 9 shots, 600×1067) — [listing](https://apps.apple.com/us/app/id672904239)
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

#### 10. Sober Sidekick (`sober-sidekick/`, 8 shots, 600×1067) — [listing](https://apps.apple.com/us/app/id1448251580)
- **Headlines and subheads in order:**
  1. "Track Sobriety" / "One Day At A Time"
  2. "Sober Social Community" / "You're Never Alone"
  3. "Quit Drinking Today"
  4. "24/7 AA & NA Meetings"
  5. "Recovery Resources" / "Instant Support When You Need It"
  6. "Take The First Step!" / "Get Sober & Stay Motivated"
  7. "Feel The Love" / "Gratitude-Based Community"
  8. "Judgement Free" / "We Are In This Together!"
- **Design:**
  - Alternating teal and periwinkle with a wave.
  - Chunky rounded white Title Case plus a lighter subhead.
  - iPhone X frames, some tilted.
  - Floating chat-chip stickers: "Struggling In Recovery?", "Send Support", "Talk To Someone Now", "We're in this together!".
  - Real user photos in feed posts.
- **Slot 1:** counter chips ("487 Days / 16 Months / 1 Years") over a community post. Recovery-program language is used throughout.
- **Features:** 24/7 Zoom meetings ("Join 24/7 Zoom Meeting"), "Today's Top Users", unlockable motivations, and a "Talk To Someone Now" crisis support entry.
- **Tone:** the most explicitly **shame-free**. A shown comment says to leave guilt and shame behind and focus on the long game. The final slide reads "Judgement Free".
- **Evidence:** none.

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
- Screenshot 1 strategies:
  - **Proof number:** Smoke Free (8M downloads).
  - **Authority badge:** QuitNow (WHO + App of the Day), Kwit (WHO + App of the Day), Reframe (press + award).
  - **Question/hook:** Quit Vaping and Puff Count (both "Ready to Quit?"), QuitSure ("Addicted to smoking?").
  - **Scope/feature:** I Am Sober, EasyQuit, Sober Sidekick, Exhale.
  - Only QuitSure puts an outcome-rate claim in the first 3 slides ("81% quit completely"). No app uses "quit in X days" in the screenshots, even QuitSure with its 6-day program.
- Showing a real counter in slot 1 or 2 is near-universal (9 of 11). The counter is the category's hero visual.
- Relapse is almost invisible:
  - Only Quit Vaping ("Break your streak?" with past streaks, a reset model) and Exhale ("I relapsed" button, "Not quite" check-in) show it.
  - QuitSure lists "Relapse Prevention" as a coach specialty and shows ongoing smoking as normal.
  - Nobody says "a slip doesn't reset your count".

### Gaps
- I did not check whether the US listings use Custom Product Pages or A/B tests (Product Page Optimization). The lookup returns only the default set.
- I don't know whether the 600×1067 sets mean these apps upload only a 5.5" set, or whether the lookup returned a particular device class. The pixel ratios are as observed.
- I could not find the "UCSF study" behind QuitSure's 81%, or the method behind Reframe's 91%/82% (self-reported). Neither was verified.

## Q3. Cross-app patterns: table stakes, overused moves, gaps DayXero could own, strongest sets

### Takeaway
Table stakes are a live counter, money saved, health recovery, badges, community and a craving tool. The overused moves are tilted-phone panoramas, laurel badges, WHO logos, mascots and "Ready to Quit?". Nobody owns three things DayXero is built on: a **visible prep-then-Quit-Day structure**, **slips that don't reset**, and **cigarettes + vapes + pouches in one app**. The strongest sets are **Reframe** (proof stacking), **QuitNow** (clarity at thumbnail size), **Smoke Free** (warm benefit headlines) and **Exhale** (modern UI with relapse and panic shown in slot 1).

### Cited Findings
Each count comes from the per-app evidence in Q2 (images in the library; listings linked above).
- **Table stakes, counted across 11 sets:**
  - Live time counter: 9 of 11 (all except EasyQuit and Reframe as a hero).
  - Money saved: 10 of 11 (not Sober Sidekick).
  - Health recovery rings or timeline: 6 (Smoke Free, QuitNow, Quit Vaping, Kwit, EasyQuit, Exhale).
  - Badges, achievements or XP: 7 (Smoke Free "90", QuitNow "80", Quit Vaping, Puff Count, EasyQuit "+100", Exhale, Kwit's coins).
  - Community or social: 8.
  - Craving tool: 7 (Smoke Free, QuitNow, Quit Vaping "Calm", Kwit, EasyQuit, Reframe, Exhale's panic button).
  - Human or AI coaching: 3 (Smoke Free advisors, chatbot and clinics; QuitSure 1-on-1; Reframe coach meetings).
  - Structured lessons or program: 4 (QuitSure, Reframe, Exhale, Smoke Free "plan").
  - Widgets or Watch: 2 (EasyQuit widgets, QuitNow Watch).
  - NRT: 1 tolerant (Smoke Free) and 1 opposed (QuitSure).
- **Big numbers on counters:**
  - Seconds-level precision is common (Quit Vaping, I Am Sober, Exhale).
  - Vape apps add vape units: pods not vaped, puffs not taken, mg nicotine avoided (Quit Vaping); puffs against a limit (Puff Count).
- **Overused moves:**
  - A tilted phone spanning slides 1–2: Quit Vaping, Kwit, QuitSure, I Am Sober, Reframe.
  - Laurel badges: QuitSure ×2, Kwit, Reframe ×2.
  - WHO logo: QuitNow, Kwit.
  - Mascots: QuitSure fox, Kwit block character, Exhale lung. Smoke Free uses cartoon people.
  - "Ready to Quit?" verbatim: Quit Vaping and Puff Count.
  - Generic "Track your progress" or "Celebrate your achievements" headlines in most sets.
  - Saturated blue or purple gradients: 7 of 11.
- **Localisation misses on US listings:** £ (Smoke Free), € (EasyQuit, Exhale).
- **Evidence-claim spectrum:**
  - No claims: Quit Vaping, Puff Count, EasyQuit, I Am Sober, Sober Sidekick, Exhale.
  - Authority badges: QuitNow and Kwit (WHO), Smoke Free ("real experts").
  - University logos plus self-reported percentages: Reframe.
  - Outcome rate plus absolute promises: QuitSure ("81% quit completely*", "No withdrawal symptoms", "No weight gain").
  - None of the 11 sets mentions FDA, NHS, CDC or a named RCT in the screenshots.
- **Tone:**
  - Shame-free language is explicit in QuitSure ("No Guilt"), Sober Sidekick ("Judgement Free") and Exhale (check-in microcopy).
  - Playful or gamified: Kwit, Quit Vaping, EasyQuit, Puff Count.
  - Clinical or scientific: Reframe, QuitSure (claims), Smoke Free (clinics).
  - Tough-love or fear: absent apart from QuitSure's marionette metaphor and Quit Vaping's raw community post.

### Inferences
**Gaps DayXero could own:**
1. **A visible prep-to-Quit-Day arc.** QuitSure has a 6-day prep program but never shows it as a timeline in screenshots; it shows "at your own pace" and a bar chart instead. Puff Count's "Day 12 of 54" plan card is the closest thing. A slot-1 or slot-2 visual such as "7 days of prep → Quit Day → days clear" would be unique in the category.
2. **"Slips don't reset your counter."** Every counter shown is a streak. Quit Vaping makes reset explicit ("Break your streak?"), and Exhale has an "I relapsed" button. A screenshot that shows a slip logged while the days-clear count holds would be a first-of-kind, shame-free differentiator. It also delivers the "no guilt" promise in UI form rather than as a claim.
3. **All three nicotine forms.** Cigarette apps ignore vapes and pouches in their visuals, vape apps ignore cigarettes, and no pouch app has scale (21 ratings at best). "Cigarettes, vapes, pouches" as one headline, with a product picker in UI, is open ground. It also captures the Zyn audience that the US top 10 does not serve.
4. **Time-boxed daily session.** Only Exhale ("3 min read") and Reframe ("5 min read") show lesson length, and both bury it. Leading with "about 3 minutes a day" answers the effort objection that QuitSure answers with overclaims ("No self-control needed", "Quit Effortlessly").
5. **Craving SOS as a hero.** Only Exhale shows a persistent panic button, and it names "Panic button" only in slot 5's list. Quit Vaping's "Calm" is slot 8. A dedicated "Craving SOS" slide in the first 3 would be distinctive.
6. **Honest proof.** The category either has no proof or has inflated or unsourced numbers. If DayXero has no outcome data, specific mechanism proof (what the program does each day) plus real rating counts beats laurels, which are now wallpaper.
7. **Craft and localisation.** Several leaders ship dated 5.5" bezels (Quit Vaping, I Am Sober, Sober Sidekick), low-contrast serif (EasyQuit) or wrong currency. A crisp, dark or premium, correctly localised US set would stand out at the thumbnail level.

**Strongest sets and why:**
- **Reframe:** the most disciplined proof sequence (press, then universities, then data, then UI, then a "2M users" close), one consistent visual system, and an accent word in each headline. Its weakness is that 4 of 10 slides contain no product.
- **QuitNow:** every headline is readable at thumbnail size, the green highlight pill guides the eye to the benefit, slot 1 combines "easy" with WHO and Apple badges, and it closes on Apple Watch. Its weakness is a generic blue look.
- **Smoke Free:** clear benefit headlines with concrete numbers ("90 quitting achievements", "clinics held 4x a day", "8 million"), warm diverse illustration and real breadth of support. Its weaknesses are £ on the US page and busy layouts.
- **Exhale:** the newest and most modern. It shows the relapse button, a panic button and guilt-free check-in copy, which is the closest in spirit to DayXero. Its headlines are generic and it has only 5 slides.
- **Weakest:** EasyQuit (low-contrast serif, a feature catalogue, Pro labels) and Quit Vaping (dated frames, a caption that doesn't match its screen, typos), although Quit Vaping's 11.7k ratings show that screenshots aren't everything.

### Gaps
- There is no conversion data (Product Page Optimization results) to show which slot-1 strategy actually converts in this category. The judgements above are qualitative.
- I did not check iPad sets, Custom Product Pages, or listings in other storefronts.
