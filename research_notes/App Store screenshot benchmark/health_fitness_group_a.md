# US App Store screenshot benchmark: top Health & Fitness apps, group A (fetched 2026-11-20)

Library root: `/home/user/DAYXERO/reference/app-store-screenshots/health-fitness/{slug}/`
- `01.jpg … NN.jpg` is the iPhone set shown on the apps.apple.com/us product page (largest display class: 6.5", 6.7" or 6.9"), downloaded at 600 px wide. **This set is the one analysed below.**
- `_sheet.jpg` is a contact sheet of that set.
- `app.json` holds the id, name, seller, rating, rating count, subtitle, version, the original lookup `screenshotUrls`, the web-page screenshot templates and the fetch date.
- `api-lookup-set/` holds the images (and `_sheet.jpg`) from the `itunes.apple.com/lookup` `screenshotUrls`. These are often an older or smaller-device (5.5") set. See "Method note" below.
- `00_video-poster.jpg` (Planet Fitness and Strava only) is the poster frame of the App Preview video that plays first in the gallery.

Final app list (2 substitutions): MyFitnessPal, Planet Fitness, Strava, Flo, Calm, **Oura (replaces Headspace)**, Cal AI, Fitbit (now listed as "Google Health (Fitbit)"), Nike Run Club, **Stardust (replaces Peloton)**.

## Q1. Are the provisional apps among the top ~20 US Health & Fitness apps by downloads? (ranking evidence and substitutions)

### Takeaway
Six of the ten provisional apps rank clearly high on the current US iPhone Top Free Health & Fitness chart: Flo #2, Planet Fitness #3, Strava #6, Cal AI #15 and MyFitnessPal #16. Headspace and Peloton are absent from the top 100 free apps, so they were swapped for Oura (#4) and Stardust (#52), the best-ranked apps in the allowed pool. Fitbit (#45), Calm (#64) and Nike Run Club (#75) are outside today's top 20 but stay in. They are large, long-standing brands, and Calm and Fitbit are top-10 by grossing. None of the pool apps outranks them except Oura, which was already used.

### Cited Findings
- **US iPhone Top Free, Health & Fitness, RSS feed updated 2026-11-19T23:07 PT:** 1 AHEALTH, **2 Flo**, **3 Planet Fitness**, **4 Oura**, 5 Sweatcoin, **6 Strava**, 7 LADDER, 8 EōS Fitness, 9 WeWard, 10 RISE, 11 Crunch Fitness, 12 Yuka, 13 MenuFit, 14 Scrambly, **15 Cal AI**, **16 MyFitnessPal**, 17 Garmin Connect, 18 Tolan, 19 Exposr, 20 Finch … **45 Google Health (Fitbit)**, **52 Stardust**, **64 Calm**, **75 Nike Run Club**. Headspace, Peloton, Fastic and Google Fit do not appear in the top 100 the feed returns. — [Apple iTunes RSS top free H&F US](https://itunes.apple.com/us/rss/topfreeapplications/limit=200/genre=6013/json); the same top 25 appears on [apps.apple.com US Health & Fitness charts](https://apps.apple.com/us/charts/iphone/health-fitness-apps/6013)
- **US iPhone Top Grossing, Health & Fitness (same day):** 1 MyFitnessPal, 2 LADDER, 3 Flo, 4 Strava, 5 Calm, 6 Hatch Sleep, **7 Peloton**, 8 Google Health (Fitbit), 9 AllTrails, 10 Hume Health, 11 Cal AI, 12 MacroFactor, **13 Headspace** … (Oura, Planet Fitness, Nike Run Club and Stardust are not in the top 40 by grossing.) — [Apple iTunes RSS top grossing H&F US](https://itunes.apple.com/us/rss/topgrossingapplications/limit=100/genre=6013/json)
- Sensor Tower's quarterly US H&F posts (seen as search snippets only, because sensortower.com is blocked by this session's network):
  - Q2 2025: Planet Fitness weekly US downloads peaked around 613K in early June.
  - Q4 2025: Flo's US iOS weekly downloads reached 124K.
  - Q1 2025: Peloton's US iOS weekly downloads fell from 27K to 13K.
  — [Sensor Tower Q2 2025 unified US units](https://sensortower.com/blog/2025-q2-unified-top-5-health%20and%20fitness-units-us-600af518241bc16eb8dce802), [Sensor Tower Q4 2025 iOS US units](https://sensortower.com/blog/2025-q4-ios-top-5-health-and-fitness-units-us-600af518241bc16eb8dce802), [Sensor Tower Q1 2025 iOS US revenue](https://sensortower.com/blog/2025-q1-ios-top-5-health%20and%20fitness-revenue-us-600af518241bc16eb8dce802). These are unverified snippets.
- AppTweak, worldwide Jan–Nov 2025 (not US): Flo #1 with 55.6M downloads and MyFitnessPal #6 with 23.3M (search snippet). — [AppTweak most downloaded H&F apps](https://www.apptweak.com/en/reports/most-downloaded-health-fitness-apps)
- Appfigures (April 2024, global): Calm downloads down 61% and Headspace down 74% since 2018 (search snippet). — [Appfigures insights](https://appfigures.com/resources/insights/20240510/amp?f=3)
- Fitbit's App Store listing is now titled "Google Health (Fitbit)" with the subtitle "Your personalized health coach", and the in-app UI in its screenshots is branded "Google Health". — [App Store: Google Health (Fitbit)](https://apps.apple.com/us/app/id462638897)

### Inferences
- Headspace and Peloton are monetisation leaders (top-13 grossing) but not download leaders on today's chart. Because they are absent from the top 100 free, they "clearly" fail a top-~20-by-downloads test. Oura (#4) is an obvious replacement. Stardust (#52) is the next-best pool app; Fastic and Google Fit are not in the top 100. Stardust is weaker on downloads than the brief intended, but it ranks above both removed apps.
- A single-day chart is noisy. Fitbit, Calm and NRC were kept because the brief only asked to drop apps that clearly fail, and no pool app beats them.

### Gaps
- I found no full-year 2025 or 2026 US download ranking (Sensor Tower, Appfigures, AppMagic or data.ai). The full Sensor Tower posts could not be fetched (host blocked) and the other sources were paywalled or global only. The ranking evidence is therefore a single-day Apple chart snapshot plus partial snippets.

## Q2. Per-app screenshot analysis (what is on each frame, design, sequencing)

### Takeaway
All ten sets are portrait-only. Most use 2–5-word benefit captions at the top over a single consistent background system, and they split into three schools:
- **Trust-first:** Calm, Strava, MyFitnessPal and Stardust put #1 claims, awards, user counts or press logos on frame 1.
- **Brand-attitude-first:** Nike Run Club and Planet Fitness open with full-bleed lifestyle photos and big type.
- **Product-first:** Flo, Oura, Cal AI and Fitbit open on core UI under a plain benefit line.

### Cited Findings
Every image below was viewed directly. Captions are verbatim, with a slash marking line or sub-line breaks. Each app's listing (source) is linked in its heading line.

#### MyFitnessPal: [App Store](https://apps.apple.com/us/app/id341232718)
- Library: `/home/user/DAYXERO/reference/app-store-screenshots/health-fitness/myfitnesspal/`
- Listing: rating 4.71 from 2,395,689 ratings. Subtitle "AI Coach & Nutrition Tracker". 10 screenshots, 1242×2688 (6.5"), portrait.
- **Format:**
  - The background is one photographic grey marble countertop running across all 10 frames.
  - Captions are white, bold, geometric sans (Inter or SF-like), centred at the top on 2 lines of 2–5 words. Cap height is about 4% of frame height.
  - Frame 1 is left-aligned with much larger type (about 9% per line) and the lowercase "myfitnesspal" wordmark above it.
  - Frames 3–10 use a realistic black iPhone with Dynamic Island, cropped at the bottom edge. One oversized UI card per frame breaks out past the bezel.
- **Captions and content:**
  1. "The #1 Food & Nutrition Tracking App". Top-down photo of a salad bowl held by a hand, with AI scan-corner brackets and blue pill chips "9 G CARBS" and "4 G PROTEIN". The photo continues into frame 2, which carries a "4 G FAT" chip (a **panoramic 1→2 pair**).
  2. "Know What You're Eating". No phone; floating result cards: "Mixed salad greens 7 cal, 1 cup", "Cherry tomatoes 14 cal, 4 tomato", "Edamame 27 cal, 0.12 cup", "Cucumber 8 cal, 5 slice", each with a green check.
  3. "Make Every Meal Count." Nutrition bar chart card wider than the phone (Carbohydrates 45%/50%, Fat, Protein).
  4. "Scan Your Food". Meal scan of avocado toast, then items logged (Avocado 240 cal, Whole Grain Bread 91 cal, Eggs boiled 63 cal) and a "Log breakfast" button.
  5. "Use Voice Logging". Mic sheet: "Go for it! Talk when you're ready to log your meal."
  6. "Personalized Nutrition Guidance". AI coach screen: "How can I help, Benito?" with the chip "How am I doing on protein today?"
  7. "Custom Reminders For GLP-1 Medication". Modal: "Want a reminder for your weekly dose?" Wednesdays, 12 PM, "Turn on weekly reminder".
  8. "Plan Your Meals". Meal planner recipes with a popped-out food photo card (Shawarma Chickpeas).
  9. "Scan Barcodes". Barcode scan returning a Protein Bar at 211 cal.
  10. "Reach Your Daily Goals". Today dashboard (976 cal / 2,074; Carbs, Fat, Protein), with an Ozempic entry in the diary.
- **Frames 1–3 together:** a #1 claim, AI photo-scan "magic", then the data payoff.
- **Arc:** claim, then logging methods (photo, voice, barcode), AI coach, GLP-1 personalisation, planning, and goals.
- **Not shown:** ratings, awards, people (only a hand), Apple Watch, widgets, Premium or paywall.
- The lookup API set has the same design.

#### Planet Fitness: [App Store](https://apps.apple.com/us/app/id399857015)
- Library: `/home/user/DAYXERO/reference/app-store-screenshots/health-fitness/planet-fitness/` (plus `00_video-poster.jpg`)
- Listing: rating 4.87 from 816,119 ratings. Subtitle "Workouts for everyone". **App Preview video first**, then 8 screenshots at 1260×2736 (6.9").
- **Video poster:** "Seamless check-in at the club, / and an app experience that MOVES WITH YOU." It shows a member handing over a phone at the front desk above a phone showing "HELLO, MARK!", "You are 2 check-ins away from meeting your monthly goal. You got this!", a Crowd Meter and a "Check in" button.
- **Format:**
  - Brand purple (from lavender to saturated purple) and brand yellow highlights throughout.
  - Captions mix placements (top, bottom, and sentences split across frames) and weights, from huge condensed black caps to medium sentence case.
  - Real-member lifestyle photos appear on 4 of 8 frames. Phones are realistic white frames, often two overlapping.
- **Captions and content:**
  1. "PROGRESS STARTS HERE". About 12% of frame height per line, purple caps with "HERE" in yellow, over a photo of smiling women on spin bikes. No UI.
  2. "Log your activities . . ." Two phones (Log Activity; Plate Loaded Incline Bench). A stats strip ("3 Active days · 35 Avg. active min · 1,430 Calories · 8,467 Avg. daily steps") spans into frame 3.
  3. ". . . and celebrate your progress!" Caption at the bottom; Fitness Profile with check-ins 3/4 and 12 Activities. This is a **panoramic 2→3 sentence**.
  4. "Workout Routines and Videos" / "For in the club and at home!"
  5. "Pick the best workout time with the CROWD METER". Photo of a member with a phone in the club, plus a Crowd History chart card.
  6. "POWER UP WITH PERKS" / "Members save BIG on your favorite brands." Category pills (Apparel & Footwear, Trending, Travel & Experiences…) over purple 3D objects.
  7. "Refer a friend and earn up to THREE FREE MONTHS". Photo of two men outside a club, with a tilted phone showing "REFER & EARN" and "Free months earned this year".
  8. "Get the PF BLACK CARD® membership". Benefit pills ("Use of any Planet Fitness worldwide!", "Use of the Black Card Spa®", "Bring a guest anytime!", "Access to Premium Perks") and the closer "Join or upgrade in the app!"
- **Arc:** emotional promise, tracking, content, utility (crowd meter), perks, referral, then an **upsell as the final frame**. This is the only set in the group that ends on the paid tier.
- **Not shown:** ratings, awards, Apple Watch.

#### Strava: [App Store](https://apps.apple.com/us/app/id426826309)
- Library: `/home/user/DAYXERO/reference/app-store-screenshots/health-fitness/strava/` (plus `00_video-poster.jpg`)
- Listing: rating 4.81 from 381,820 ratings. Subtitle "Track & share with friends". **App Preview video first** (poster: solid orange, "Track your workouts", Strava logo), then 9 screenshots at 1242×2688.
- **Format:**
  - Every frame has the same near-black background warming into deep orange-red at the bottom.
  - Captions are white, bold, geometric sans, top-centred, 2 lines of 2–5 words, cap height about 3%.
  - Phones have an **orange brand-coloured bezel** and show dark-mode UI, cropped at the bottom. Map, trail and route cards pop out of the frame.
- **Captions and content:**
  1. Apple logo, "Apple Watch / App of the Year", a laurel around "Winner", the STRAVA wordmark, then a phone with a "Squad Run" feed photo and an Apple Watch Ultra showing a live segment ("Coastal Trail Climb ▲2s ahead").
  2. "Get motivated by the community". Comments thread: "Let's gooooo!!", "Absolutely crushed it", "Appreciate you captain!"
  3. "Track your workouts". Record screen with sport picker.
  4. "Lift it. Log it. See your gains." Muscle map, Night Weight Training, 4,115 lbs.
  5. "Hit the trails with hiking tools". Trail card "Gerbode Valley Loop 5.27 mi · 880 ft · 1h 44m".
  6. "Share with friends".
  7. "Improve with personalized data". Progress chart, "384.6 mi ▲12%", "You've logged 12% more distance than in the previous time period."
  8. "Discover new routes".
  9. "Sync with your devices". A Garmin Forerunner overlaps the phone.
- The lookup set has a 10th frame, "Compete against millions" (leaderboard), which was dropped from the web set.
- **Frames 1–3:** an Apple award plus Watch hardware, then community, then tracking.
- **Arc:** social, tracking, sport breadth (strength, hiking), sharing, analytics (the subscription feature, not labelled), routes, devices.
- **Shown / not shown:** watch hardware appears on frames 1 and 9. No ratings count and no paywall.

#### Flo: [App Store](https://apps.apple.com/us/app/id1038369065)
- Library: `/home/user/DAYXERO/reference/app-store-screenshots/health-fitness/flo/`
- Listing: rating 4.74 from 2,026,424 ratings. Subtitle "Ovulation & Pregnancy Calendar". 10 screenshots at 1242×2688. The lookup API set has only 8 and is older.
- **Format:**
  - Solid lavender background on every frame.
  - Two-tier caption at the top: a small regular dark-plum lead-in, then 1–2 larger words in a pale-pink highlight box (a "label" device).
  - A soft rounded lavender pseudo-device frame (not a realistic iPhone), cropped at the bottom.
  - Flat illustrated people and hands; cards break out of the frame.
- **Captions and content:**
  1. "Predict your / next period". UI "Period in: 2 days", "Log period", and a green peel-sticker "**FSA/HSA eligible**", footnoted "*Applies only in the U.S."
  2. "Understand your / fertile days". Calendar with "Prediction: Day of ovulation".
  3. "Log and track / symptoms". Illustrated hand tapping Cramps, Mood swings and Fatigue.
  4. "Maximize your / connection". "Flo for Partners", an illustrated couple, "Her day today".
  5. "Got symptoms? / Get answers". Symptom Checker (PCOS "Significant match", Endometriosis, Uterine Fibroids, Perimenopause) and "Pay attention".
  6. "Manage symptoms of / perimenopause".
  7. "Discover your sleep-cycle / connection". Dark card, "Good" sleep score, 8h 10m.
  8. "Follow your / baby's growth". 7 weeks, 5 days; blueberry size comparison.
  9. "Learn from / 100+ experts". "Vaginal Discharge Color Guide — Jennifer Boyle, MD OB-GYN".
  10. "Keep your data / even safer". Illustrated woman covering her face; Secure access (Fingerprint, Face ID, Access code) and an **Anonymous Mode** toggle.
- **Arc:** follows the life stages (cycle, fertility, symptoms, partner, diagnosis-style checker, perimenopause, sleep, pregnancy) before **expert authority (frame 9) and privacy (frame 10)** as trust closers.
- **Not shown:** ratings, awards, photos.
- The older 8-frame API set lacks the FSA/HSA sticker, perimenopause, sleep, experts and privacy frames.

#### Calm: [App Store](https://apps.apple.com/us/app/id571800810)
- Library: `/home/user/DAYXERO/reference/app-store-screenshots/health-fitness/calm/`
- Listing: rating 4.77 from 1,995,414 ratings. Subtitle "Sleep, Meditation, Relaxation". Only **6** screenshots, at 1320×2868 (6.9").
- **Format:**
  - Sky-blue to violet gradient. Frames 1–2 share **one continuous sky and mountain-lake photo (panoramic)**, and frame 3's tilted phone and cover art bleed into frame 4.
  - Captions are light or regular weight, centred, top, 2–3 lines of 4–8 words.
  - Dark realistic phones (frame 3 tilted, surrounded by Sleep Story cover tiles).
- **Captions and content:**
  1. The Calm script logo, "The #1 App for / Sleep & Meditation", a laurel with 5 stars "3M 5-Star Reviews", a laurel with the Apple logo "App Store Awards WINNER", and the footer "Sleep more. Stress less. Live better."
  2. "Trusted by millions. Recommended by experts.", a laurel "Most Trusted Brand U.S. 2026 Newsweek", a laurel "Editor's Choice", and "FEATURED IN" with The New York Times, TIME, Forbes, The Guardian and Fast Company.
  3. "Fall asleep to Sleep Stories™ with your favorite voices". Celebrity Sleep Story "Dream With Me", Harry Styles.
  4. "Guided meditations for everyday life". Daily Calm, Daily Jay, Daily Move and Daily Trip with teacher portraits.
  5. "Soundscapes and music for focus, calm & sleep".
  6. "Immersive nervous system support". "Bilateral Stimulation for Nervous System Reset".
- **Frames 1–3:** two full frames of pure trust (#1 claim, 3M reviews, Apple award, Editor's Choice, Newsweek, five press logos), then the celebrity hook. Product UI does not appear until frame 3.
- **Not shown:** watch, widgets, paywall.

#### Oura (substitute for Headspace): [App Store](https://apps.apple.com/us/app/id1043837948)
- Library: `/home/user/DAYXERO/reference/app-store-screenshots/health-fitness/oura/`
- Listing: rating 4.86 from 326,732 ratings. The product page shows no marketing subtitle (the lockup returns the category, "Health & Fitness"). 9 screenshots at 1284×2778. The web and API sets are identical.
- **Format:**
  - Pure black background.
  - Captions are small (cap height about 2.5%), light or regular weight, white, Title Case, top-centred, 2 lines of 3–5 words.
  - **Frameless** rounded UI screens (no bezel), cropped at the bottom. Dark, atmospheric UI with photographic headers (mountain, hills).
  - Very restrained and premium. **No ring hardware, no people, no social proof.**
- **Captions and content:**
  1. "Your Personal / Health Companion". Readiness 88, "Go get 'em!"
  2. "Get in Tune / with Your Body". Vitals.
  3. "Invest in Your / Health Future". "Rising heart health, with a dip in stress management".
  4. "Accurate / Sleep Monitoring". 7h 16m with hypnogram.
  5. "Heart Health / Guidance". "Your cardiovascular age is below your actual age", "8 years younger".
  6. "Cycle Tracking / and Insights".
  7. "Daytime Stress / and Recovery".
  8. "Automatic / Activity Detection". "Running" auto-detected; Steps 5,203, "Almost there".
  9. "Go deeper with / Oura Advisor". AI chat: "Hey! What's on your mind?"
- **Arc:** companion framing, then the metric pillars, with AI last.

#### Cal AI: [App Store](https://apps.apple.com/us/app/id6480417616)
- Library: `/home/user/DAYXERO/reference/app-store-screenshots/health-fitness/cal-ai/`
- Listing: rating 4.80 from 376,540 ratings. Subtitle "Food & Macro Counter". **6** screenshots at 1284×2778.
- **Format:**
  - Pure white background.
  - Black bold sans captions, **single line of 2–3 words**, top-centred, cap height about 3.5%.
  - A full, realistic silver iPhone (whole device visible) with callout cards and labels breaking out. Ultra-minimal.
- **Captions and content:**
  1. The "Cal AI" logo (apple glyph plus wordmark) as the headline. Home screen with an oversized "1250 / 2500 Calories eaten" ring card popping out.
  2. "Just snap a pic". Camera on a Caesar salad, with ingredient labels (Lettuce, Parmesan, Cherry Tomatoes, Croutons).
  3. "See the calories". "Caesar Salad with Cherry Tomatoes", Calories 330, macros, "Fix Results".
  4. "Track progress". Weight 132.1 lbs, **"21 Day Streak"** flame, weight chart.
  5. "Grow with friends". Group "Shred Squad" feed.
  6. "Watch the change". **Before/after photos: 355 lbs (Sep 20, 2023) to 182 lbs (Jul 7, 2025)**, with a Share button.
- **Frames 1–3:** a complete how-it-works loop (app, snap, result).
- **Arc:** then progress, social, and transformation proof.
- The lookup API set is an **older, different design**: 4 frames on a dark charcoal background with 2-line captions: "Make calorie tracking easy with AI", "Just snap a picture of your food", "Then let us do the rest", "Track your progress as you go".

#### Fitbit, now "Google Health (Fitbit)": [App Store](https://apps.apple.com/us/app/id462638897)
- Library: `/home/user/DAYXERO/reference/app-store-screenshots/health-fitness/fitbit/`
- Listing: rating 4.46 from 713,115 ratings. Subtitle "Your personalized health coach". Only **5** screenshots at 1242×2688.
- **Format:**
  - Off-white or light grey background.
  - Black bold Google Sans-style captions, top-centred, 2–3 lines of 5–6 words, cap height about 3.5%.
  - Realistic black iPhone cropped at the bottom; pastel Material UI.
  - **No wearable hardware, no people, no social proof.**
- **Captions and content:**
  1. "Track your progress with personalized insights". Google Health Today (Weekly cardio 58%, Steps 8,532, Readiness 89, 7h 54m sleep), "Great intensity!" coach note, "Say more about my workout".
  2. "Build fitness plans that fit your goals".
  3. "Get in-depth sleep quality analysis". "A fragmented and restless night".
  4. "See your whole health journey". Resting heart rate "above your personal range", "Ask about resting heart rate".
  5. "Guidance you can count on". AI Coach chat about HRV, with the disclaimer "AI responses may contain mistakes, not for medical advice."
- **Arc:** AI coaching threads through every frame.
- The lookup API set is still the **old Fitbit-branded set**: "See your top stats, at a glance", "Focus on what matters most", "Stay motivated with fun, fresh workouts", "Explore workouts for your body & mind", "Adjust goals, track achievements & more".

#### Nike Run Club: [App Store](https://apps.apple.com/us/app/id387771637)
- Library: `/home/user/DAYXERO/reference/app-store-screenshots/health-fitness/nike-run-club/`
- Listing: rating 4.77 from 420,706 ratings. Subtitle "Workout App & Distance Tracker". 10 screenshots at 1284×2778.
- **Format:**
  - Black background.
  - Captions are huge, heavy, condensed, ALL CAPS (Nike Futura style), white, top-centred, 2–3 lines of 3–6 words, cap height about 3.5%.
  - Light-UI phones cropped at the bottom, plus rendered Apple Watch hardware.
  - **Photo bookends:** frames 1 and 10 are full-bleed motion photos of runners with the RUN + swoosh logo.
- **Captions and content:**
  1. "LEAVE YOURSELF IN THE DUST". Bottom-anchored, about 8% per line; no UI.
  2. "TRACK YOUR PROGRESS". Activity: 20.6 miles this week.
  3. "RUN WITH A COACH IN YOUR EAR". Guided run "GRATEFUL 5K RUN", START.
  4. "TRAINING PLANS THAT MATCH YOUR GOALS". "Run Beyond Plan".
  5. "WORLD-CLASS COACH SUPPORT". Coach portrait, 10K plan.
  6. "RUN HANDS FREE". Three Apple Watches, "3-WEEK STREAK", START.
  7. "JOIN COMMUNITY CHALLENGES". "Million Mile Global Running Day Challenge".
  8. "TAG YOUR SHOES TO TRACK THEIR MILEAGE". "300 MILES … CONGRATS!"
  9. "QUICK ACCESS WITH WIDGETS". Home-screen widgets: START, 32.68 mi, 1.326 total miles.
  10. "LOVE IT OR HATE IT, WE'LL RUN WITH YOU".
- **Frames 1–3:** brand attitude, then progress, then audio coaching.
- **Not shown:** ratings, awards, paywall. NRC is free.
- Widgets appear only in this set, and the Watch only here and in Strava.

#### Stardust (substitute for Peloton): [App Store](https://apps.apple.com/us/app/id1495829322)
- Library: `/home/user/DAYXERO/reference/app-store-screenshots/health-fitness/stardust/`
- Listing: rating 4.76 from 121,334 ratings. Subtitle "Track your cycle or pregnancy". 10 screenshots at 1242×2688.
- **Format:**
  - Cosmic deep-indigo star field with a rainbow glow rising from the bottom.
  - Playful **3D objects (planets, pizza slice, fries, watermelon, heart, lipstick, cake) float and straddle frame edges**, so the strip reads as continuous.
  - Captions are top-left aligned, light humanist sans in cream, sentence case, 2–3 lines of 4–6 words.
  - **Frameless** dark UI cards.
- **Captions and content:**
  1. "Period Tracker Built by Women" (large quirky display face, about 8% per line), a laurel "**2 million** MONTHLY USERS", and "Featured in ELLE, GLAMOUR, Bustle, THE CUT, The New York Times".
  2. "Predict your next period". "11 Days"; "Hormone-wise, this is a day of formidable power…"
  3. "Track all the fun symptoms".
  4. "Sync with your close friends". "Your Orbit": friends' phases, e.g. "Tired but Inspired".
  5. "See how hormones affect your mood".
  6. "Align your cycle with the moon".
  7. "Notifications that keep it real". Sample push copy: "Schwing! Your testosterone is increasing.", "Estrogen is THE party drug… Live it up."
  8. "Add a partner into your orbit". "Greg has not seen your forecast for the day", "Nudge them", "Cast a magic spell".
  9. "Uncover sleep & energy patterns". "Peak Energy".
  10. "Discover your archetype and element". "Sara", "Beyoncé Off Duty".
- **Arc:** proof, core prediction, then personality-led social, astrology and voice features.
- The API set's frame 1 is an alternate hero: "Your Hormonal Health Universe Awaits".

### Inferences
- Product-first sets (Oura, Fitbit) are the least differentiated: small type, no hook, no proof, and the hardware is not shown. They read as feature lists.
- Cal AI makes its whole proposition legible in the first three frames using only about 9 words of caption. It is the clearest "how it works" model in the group.

### Gaps
- Screenshot sets can vary by A/B test (Product Page Optimization) or custom product pages. Each listing was captured once, from a logged-out US web request, so variants were not observed.
- Exact font families are judged by eye.

## Q3. Cross-app patterns (format, captions, colour, frame 1, story arc, recurring elements)

### Takeaway
The common pattern is a consistent single-system background, top captions of 2–6 words, realistic phones cropped at the bottom with breakout cards, and social proof only on frames 1–2. The distinctive moves are:
- Panoramic pairs (MyFitnessPal, Planet Fitness, Calm, Stardust)
- Leading with video (Planet Fitness, Strava)
- Photo bookends (Nike Run Club)
- Before/after proof (Cal AI)
- Privacy as the closer (Flo)
- Ending on the upsell (Planet Fitness)

### Cited Findings
All findings in this section come from the downloaded sets. Sources: the listings linked in Q2, e.g. [MyFitnessPal](https://apps.apple.com/us/app/id341232718), [Calm](https://apps.apple.com/us/app/id571800810), [Cal AI](https://apps.apple.com/us/app/id6480417616).
- **Count and orientation:**
  - Full 10 frames: MyFitnessPal, Flo, NRC, Stardust.
  - Fewer frames: Strava (9 plus a video), Oura 9, Planet Fitness (8 plus a video), Calm 6, Cal AI 6, Fitbit 5.
  - All portrait. None use landscape.
  - Two lead with an autoplay App Preview video (Planet Fitness, Strava).
- **Caption placement and size:**
  - Top-centred in 8 of 10 sets. Stardust is top-left. Planet Fitness varies (top, bottom, split across frames). NRC's photo bookends are bottom or centre.
  - Typical length is 2–5 words; Calm and Fitbit run to 6–8.
  - Most sets use a cap height of about 3–4% of frame height. Frame 1 often doubles it (MFP, PF, NRC, Stardust at about 8–12%).
  - Weight splits into bold or heavy (MFP, Strava, Cal AI, Fitbit, NRC, PF) and light or regular (Calm, Oura, Stardust; Flo mixes the two).
- **Device treatment:**
  - Realistic iPhone: MyFitnessPal, Cal AI, Fitbit, NRC, Planet Fitness, Calm. Strava's has an orange brand bezel.
  - Stylised pseudo-frame: Flo.
  - Frameless rounded screens: Oura, Stardust.
  - Breakout or oversized UI cards: MyFitnessPal, Cal AI, Strava, Flo, Planet Fitness.
- **Background:**
  - One system per set, never changed mid-set.
  - Dark: Strava (black to orange), Oura (black), NRC (black), Stardust (cosmic).
  - Light: MyFitnessPal (marble photo), Flo (lavender), Cal AI (white), Fitbit (grey).
  - Saturated brand colour: Planet Fitness (purple and yellow), Calm (blue to violet gradient).
- **Frame 1 approaches:**
  - #1 claim: MyFitnessPal "The #1 Food & Nutrition Tracking App", Calm "The #1 App for Sleep & Meditation".
  - Apple award: Calm "App Store Awards Winner", Strava "Apple Watch App of the Year Winner". Editor's Choice appears on Calm frame 2.
  - User or review counts: Calm "3M 5-Star Reviews", Stardust "2 million monthly users".
  - Press logos: Calm (frame 2), Stardust (frame 1).
  - Brand manifesto plus photo: NRC, Planet Fitness.
  - Benefit plus UI: Flo (with the FSA/HSA badge), Oura, Fitbit, Cal AI (logo plus UI).
  - **Nobody puts proof after frame 2.**
- **AI:**
  - Prominent in MyFitnessPal (scan visuals on frames 1–2 and 4; coach on frame 6), Cal AI (frame 2), Fitbit (frames 1 and 5) and Oura (frame 9).
  - AI coaching is usually mid-to-late in the set, while AI capture (snap or scan) leads when it is the core mechanic.
- **Paywall or premium:** almost never shown. Only Planet Fitness ends on its paid tier (Black Card). Subscription features (Strava analytics, Calm content) appear unlabelled.
- **Apple Watch, widgets, Health:**
  - Watch: Strava frame 1 and NRC frame 6. A Garmin appears on Strava frame 9.
  - Widgets: NRC frame 9 only.
  - Live Activities and the Apple Health logo or integration: in no set.
- **People:**
  - Lifestyle photos: PF, NRC, Calm (landscape only), Cal AI (before/after body photos), Strava (in-feed photos).
  - Illustration: Flo.
  - None: Oura, Fitbit.
  - No set uses written user testimonial quotes.
- **Streaks, progress, outcomes:**
  - "21 Day Streak" (Cal AI), "3-WEEK STREAK" (NRC Watch), check-ins "3/4" and "2 check-ins away from meeting your monthly goal" (PF), "300 MILES … CONGRATS!" (NRC), "▲12%" (Strava), "8 years younger" (Oura), 355 to 182 lbs (Cal AI).
- **Trust and safety:** Flo closes on privacy and anonymous mode and uses a named MD (frame 9). Fitbit shows an AI medical disclaimer. Flo footnotes the FSA claim.
- **Social:**
  - Community, friends or partner frames: Strava (2, 6), Cal AI (5), NRC (7), Stardust (4, 8), Flo (4, partner).
  - Referral: Planet Fitness (7).
- **Web set vs API set:** 4 of 10 apps show materially different or older sets via the lookup API: Cal AI (old dark set, 4 frames), Fitbit (pre-rebrand), Flo (8 older frames), and Stardust (different hero). Strava's API set has one extra frame.

### Inferences
- The visible-in-search triad (frames 1–3, or video plus 2) splits into three jobs: **claim or proof**, the **core mechanic**, and the **payoff**. The clearest examples:
  - Cal AI: logo/UI, snap, calories.
  - MyFitnessPal: #1 with a scan visual, the result chips, then the data.
  - Calm: #1 with an award, then press, then the celebrity hook.
- **Strongest sets, in my judgement:**
  1. **Calm.** Maximum trust density in the first two frames, plus a continuous panorama and a celebrity hook, although the set covers few features.
  2. **Cal AI.** Instantly legible with very few words, and ends on transformation proof.
  3. **Strava.** Award plus Watch on frame 1, and a rigorously consistent brand system (orange bezel, gradient).
  4. **Nike Run Club.** A distinct brand voice and photo bookends make it memorable, and it also covers Watch and widgets.
  5. **Flo.** The highlight-box captions scan well, the breadth matches each user's life stage, and it closes with the FSA/HSA and privacy trust signals.
- **Weakest:**
  - Fitbit/Google Health: generic captions, only 5 frames, no hardware or proof.
  - Oura: beautiful, but the type is small, there is no hook or proof, and the product (the ring) is never shown.
- **Implications for DayXero (a quit-nicotine app):**
  - Put proof on frames 1–2 (a #1-style claim is only usable if true; otherwise user count, ratings or press).
  - Make frames 1–3 a how-it-works loop (Cal AI model). The "outcome" frame maps naturally to days nicotine-free, money saved and health recovery (the Cal AI before/after and Oura "8 years younger" analogues).
  - Use a streak or day counter as a hero visual, since streak UIs recur across the category.
  - Put AI coaching mid-set.
  - Close with privacy or trust (Flo).
  - A distinctive voice (Stardust's cheeky push notifications, NRC's manifesto) can differentiate.
  - **Widgets and Live Activities are nearly absent in this group, which makes them an open differentiator** (for example a lock-screen craving timer or a days-free widget).
  - Keep one background system and 2–5-word captions at the top.

### Gaps
- No conversion data (tap-through or install rates) is available for any of these sets, so "strongest" is a design and messaging judgement, not a measured result.
- I did not verify how many screenshots the US iOS search-results card shows for each app (normally the first three portrait images, or a video plus two). Video-first sets (Planet Fitness, Strava) may show differently in search than on the product page.

## Method note (for reproducibility)
- **Primary capture:** apps.apple.com/us product pages, parsed from the embedded `serialized-server-data` JSON (`shelfMapping.product_media_phone_`). Image templates were resized to `600x0w.jpg` and served from is1-ssl.mzstatic.com. A lookup via `https://itunes.apple.com/lookup?id={ID}&country=us` supplied the metadata and the alternate set.
- **Why the web page instead of the lookup set:** the lookup endpoint returned older or smaller-device sets for several apps (for example Calm's files are named "[5.5in]" while the web page serves "[6.9in]", and Cal AI's API set is a completely different, older design). The web page set is therefore what current iPhone users see.
- **Scripts:** kept in the scratchpad at `/tmp/claude-0/-home-user-DAYXERO/baee34b4-0d61-5647-bafc-b1eff344fe4b/scratchpad/groupA/` (`fetch.py`, `fetch2.py`), not in the library. Python was run with `-I`.
