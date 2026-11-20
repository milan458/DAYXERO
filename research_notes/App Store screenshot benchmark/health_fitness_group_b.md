# US App Store screenshot benchmark: Health & Fitness, group B (Lose It!, BetterMe, Noom, Sleep Cycle, Clue, WeightWatchers, Hevy, Ladder, AllTrails, Yuka)

**Capture method (refreshed 2026-11-20).** The images analysed are the iPhone set shown on each app's US product page today, not the Lookup API set. I fetched `https://apps.apple.com/us/app/id{ID}` with plain curl, read the `product_media_phone_` shelf from the page's embedded JSON (the largest display class the app uploaded) and downloaded each frame at 600px wide. The iTunes Lookup API `screenshotUrls` used at first often return an older or smaller set (5.5"). Result: 6 of 10 sets are byte-identical (Lose It!, BetterMe, Sleep Cycle, Clue, AllTrails, Yuka). 4 changed: **Noom** and **WeightWatchers** (new creative sets), **Ladder** (revised set), **Hevy** (same captions, new UI and frames). For those 4, the older Lookup images are kept in `{app}/api-lookup-set/`, and `app.json` gains `productPageScreenshotUrls`, `productPageDeviceClass`, `productPageFetched` and `productPageCheck`. None of the 10 has an App Preview video on the iPhone product page. Product-page subtitles (`lockup.subtitle` in the page JSON): Lose It! "Food Tracker for Weight Loss"; BetterMe "Pilates, calisthenics, yoga"; Noom "Healthy Habits, Meals & GLP-1s"; Sleep Cycle "Alarm Clock and Tracking App"; Clue "Ovulation & Fertility Calendar"; WW "Weight Loss and Better Health"; Hevy "Weight Lifting Routine Planner"; Ladder "Fitness Workouts at Home & Gym"; AllTrails "GPS Hiking & Biking Trail Maps"; Yuka "Check What's in Your Products". Change summary: `refresh_current_sets.md` in this folder.

Originally fetched 2026-11-20 (US storefront, iPhone `screenshotUrls` from the iTunes Lookup API, downloaded at 600px wide); per-app analysis below has been updated to the product-page sets.
Library root: `/home/user/DAYXERO/reference/app-store-screenshots/health-fitness/`. Each app folder has `01.jpg…NN.jpg`, `app.json` (id, name, seller, rating, ratingCount, version, original screenshotUrls, fetch date) and `_sheet.jpg` (contact sheet). Chart evidence snapshot: `/home/user/DAYXERO/reference/app-store-screenshots/health-fitness/_us_health_fitness_charts_2026-11-20_group_b.txt`.
All headline text and visual descriptions below come from viewing the downloaded images, not from memory. Source for each app = its Lookup API record plus its US App Store page.

## Q0. Are these 10 apps top US Health & Fitness apps? (ranking evidence and substitutions)

### Takeaway
All 10 are in the Health & Fitness primary genre on the US store, including AllTrails and Yuka, and all 10 are in Apple's current US top-100 *grossing* H&F chart. On *free downloads*, Ladder (#7) and Yuka (#12) are clearly top-20. Hevy, AllTrails, Clue, BetterMe and Lose It! are in the top 100, while Noom, Sleep Cycle and WeightWatchers are not. None of the allowed substitutes ranks higher, so I made no substitutions.

### Cited Findings
- The Lookup API returns `primaryGenreName: "Health & Fitness"` for all 10 IDs: Lose It! 297368629, BetterMe 1264546236, Noom 634598719, Sleep Cycle 320606217, Clue 657189652, WeightWatchers 331308914, Hevy 1458862350, Ladder 1502936453, AllTrails 405075943, Yuka 1092799236. AllTrails and Yuka are therefore H&F apps, not apps from another category — [iTunes Lookup](https://itunes.apple.com/lookup?id=405075943&country=us), [iTunes Lookup](https://itunes.apple.com/lookup?id=1092799236&country=us)
- Apple US **Top Free** H&F chart (genre 6013, top 100, feed updated 2026-11-19T23:07 -07:00): **Ladder #7, Yuka #12, Hevy #30, AllTrails #32, Clue #39, BetterMe #63, Lose It! #84**. Noom, Sleep Cycle and WeightWatchers are not in the top 100. Simple, ShutEye, Hinge Health and Fitness AI are not in the top 100 either. Top 5 for context: AHEALTH, Flo, Planet Fitness, Oura, Sweatcoin — [Apple RSS top free H&F](https://itunes.apple.com/us/rss/topfreeapplications/limit=200/genre=6013/json)
- Apple US **Top Grossing** H&F chart, same date: **Ladder #2, AllTrails #9, Lose It! #20, WeightWatchers #24, Yuka #25, BetterMe #26, Hevy #34, Clue #35, Sleep Cycle #38, Noom #47**. ShutEye is #53. Simple, Hinge Health and Fitness AI are not in the top 100 — [Apple RSS top grossing H&F](https://itunes.apple.com/us/rss/topgrossingapplications/limit=200/genre=6013/json)
- A search snippet attributed to Sensor Tower's Q4 2025 US iOS H&F downloads top-5 post says LADDER was among the leaders, with weekly downloads surging to 72.7K. I could not open the page because the host is blocked in this session, so this is unverified — [Sensor Tower (snippet only)](https://sensortower.com/blog/2025-q4-ios-top-5-health-and-fitness-units-us-600af518241bc16eb8dce802)
- The AppTweak 2025 ranking is worldwide across both stores, not US-only. Flo is #1 (~55.6M) and MyFitnessPal #6 (~23.3M). I could not open the page itself (host blocked), only search snippets — [AppTweak (snippet only)](https://www.apptweak.com/en/reports/most-downloaded-health-fitness-apps?lang=en-US)
- Rating counts from the Lookup API, as a proxy for scale: WW 2,367,043; AllTrails 1,043,416; Noom 874,455; Lose It! 785,128; BetterMe 714,938; Clue 408,217; Ladder 224,608; Hevy 104,475; Yuka 102,533; Sleep Cycle 32,437 — [Lookup API records, saved in each app.json](https://itunes.apple.com/lookup?id=331308914&country=us)

### Inferences
- The group is better described as "top-50 US H&F apps by revenue/scale", with 7 of the 10 currently in the top-100 free chart. Noom, WW and Sleep Cycle are legacy heavyweights that are strong on revenue but no longer chart high on free downloads.
- I kept all 10 because none of the permitted substitutes (Simple, ShutEye, Hinge Health, Fitness AI) out-ranks them on either chart.

### Gaps
- I found no US full-year 2025–26 download ranking that I could open. Sensor Tower and AppTweak are both blocked from this session (hosts not in the allowlist), and Appfigures and AppMagic returned nothing usable. The Apple chart is a one-day, velocity-weighted snapshot, not cumulative downloads.
- Sleep Cycle's low US rating count (32k) next to its age suggests a past ratings reset. This is unconfirmed.

## Q1. Per-app screenshot analysis (count, format, captions, visual treatment, story arc)

### Takeaway
The 10 sets split into three archetypes:
- **Brand-colour + device-frame feature list:** Lose It!, WW, AllTrails, Hevy, Ladder, and now Noom (its current set puts framed phones on slots 2–7).
- **Frameless floating UI cards on a brand colour:** Clue, Yuka.
- **Atmospheric / continuous background:** Sleep Cycle, plus the Noom dotted-line motif.

The strongest sets put a claim or proof point on screenshot 1, often as a panorama that spans 1→2. They then run one benefit per screen and close with community, coach or trust content.

### Cited Findings

**Format for all apps (product-page sets).** Every set is portrait at about 600×1300. Device classes uploaded: 6.9" for Lose It! (1320×2868), BetterMe (1290×2796), Sleep Cycle and AllTrails (1260×2736). 6.5" for Clue, Yuka, Hevy, Ladder (1242×2688) and WW (1284×2778). 6.3" for Noom (1206×2622). The Lookup API had returned the older 5.5" 9:16 set (600×1067) for Noom, WW, Hevy and Ladder; those images are now in each app's `api-lookup-set/` — [product pages, e.g. Noom](https://apps.apple.com/us/app/id634598719)

#### 1. Lose It! – Calorie Counter (id 297368629; FitNow, Inc.; 4.77★, 785,128 ratings). Library: `/home/user/DAYXERO/reference/app-store-screenshots/health-fitness/lose-it/` — [Lookup](https://itunes.apple.com/lookup?id=297368629&country=us) · [App Store](https://apps.apple.com/us/app/id297368629)
- **Format:** 10 portrait screenshots, no panorama.
- **Background:** solid dark navy brand background on every screen, with orange (the app-icon colour) as the accent.
- **Captions:** white bold rounded sans, centred at the top, 2 lines of 2–3 words each, about 7–8% of frame height per line.
- **Device:** iPhone frame (Dynamic Island) cropped at the bottom edge. UI cards break out of the frame: a barcode nutrition card, a voice-quote bubble, a recipe calorie card, community posts, and integration icons.
- **Headlines in order:**
  1. "The #1 Weight Loss Tracker", subhead "EASILY TRACK YOUR CALORIES & NUTRITION". Includes the logo, a triptych of food photos, and the strip "AS SEEN ON CNN · TODAY · People · Good Morning America · Women's Health".
  2. "Log Every Meal"
  3. "Snap Your Food" — camera view with food labels Egg / Avocado / Sweet Potato.
  4. "Lose Weight" — 174 lbs, ↓21 lbs since…, 20 lbs milestone.
  5. "Voice Logging" — orange bubble: "I had one apple with two tablespoons of peanut butter".
  6. "Scan Barcodes" — "Oat & Honey Granola Bar, 95 Calories".
  7. "Learn About Macros"
  8. "Sync Fitness Apps" — Apple Health, Apple Watch, Steps, Fitbit icons pop out of the frame.
  9. "Support Groups" — posts such as "We're all in this together!" and "today is my 500 day of tracking…".
  10. "Customized Recipes" — "292 Calories".
- **Arc:** #1 claim + press → logging methods (manual, photo, voice, barcode), with the outcome ("Lose Weight") placed at #4 → insights → integrations → community → recipes.
- **Not shown:** star ratings, Premium/price, the word "AI", widgets.

#### 2. BetterMe Well-Being Coach (id 1264546236; 4.67★, 714,938 ratings). Library: `/home/user/DAYXERO/reference/app-store-screenshots/health-fitness/betterme/` — [Lookup](https://itunes.apple.com/lookup?id=1264546236&country=us) · [App Store](https://apps.apple.com/us/app/id1264546236)
- **Format:** 6 portrait screenshots, no panorama.
- **Background:** uniform warm cream/beige.
- **Captions:** centred at the top, 2 lines, two-tone (dark brown + lighter taupe on alternating phrases), medium-weight sans, 4–6 words.
- **Device:** screenshot 1 is frameless — three stacked rounded lifestyle-photo tiles labelled "Pilates", "Calisthenics", "Chair Yoga" with fit models. Screenshots 2–6 use a thin white iPhone frame cropped at the bottom.
- **Headlines in order:**
  1. "Get fit with home workouts"
  2. "Personalized plan for your goal" — Day 1–15 check grid; "Perfect Legs Day, 10 Min, 43 Cal".
  3. "Easy-to-follow workouts" — video player with a 0:20 timer.
  4. "Meal plan for any diet type" — Mediterranean Quinoa Salad, 404 cal, LOG MEAL.
  5. "Daily routines to achieve your goals" — "My Plan" checklist: Home Pilates, Snap Your Meal, Update Measurements, Be Active, Drink Water, Walk.
  6. "Keep track of your results" — steps 9,570, stress level 84, heart rate 74 BPM, sleep score 91%, nutrition, chest/waist/hips.
- **Proof and extras:** no social proof, awards, ratings, Premium, or watch/widget content anywhere. The listing name says "Well-Being Coach", but the screenshots are fitness-led.

#### 3. Noom Weight Loss, Food Tracker (id 634598719; 4.70★, 874,455 ratings). Library: `/home/user/DAYXERO/reference/app-store-screenshots/health-fitness/noom/` — [Lookup](https://itunes.apple.com/lookup?id=634598719&country=us) · [App Store](https://apps.apple.com/us/app/id634598719)
- **Older set:** the Lookup API's 9-frame 5.5" set (salmon background, all-serif, frameless cards, with a coach frame and a "78% of Noomers lost weight in a six-month study" closer) is no longer on the product page. It is kept in `noom/api-lookup-set/`.
- **Format (current product page):** 8 portrait screenshots, 6.3" class (1206×2622). Screenshots 1→2 form a panorama: a tilted phone showing "Course Map" crosses the seam. A red-dotted path motif appears on 1 and 8 only.
- **Background:** uniform pale lavender-grey. Screenshot 8 is a full-bleed lifestyle photo.
- **Captions:** two typefaces. Screenshots 1 and 8 use large left-aligned dark-plum serif. Screenshots 2–7 use centred 2–3-line geometric sans at the top.
- **Device:** dark-outline phone frames on 2–7, with cards breaking out (prediction chart, "Check in with your doctor" chip, a Wegovy pen). Screenshot 1 is the tilted panorama phone.
- **Headlines in order:**
  1. "Noom uses psychology to help you lose weight and keep it off" (11 words), with the tag "BUILD NEW HABITS".
  2. "Understand your food choices with psychology" — weight-prediction chart "We predict you'll be 150 lbs by May 8", milestones "Lower risk (171 lbs)" and "Wedding (165 lbs)", goal 150 lbs, rows "Reduce stress" and "Age with confidence", plan summary "Awesome! By May 8th, we project you'll lose 9 lbs or 5% of your body weight."
  3. "A personalized program for healthier habits" — Today's Plan: "Get your steps in", "Track your meals", "Learn with Noom".
  4. "Stay on track with simple food logging" — camera capture: "Take a photo of your meal or upload one from your camera roll".
  5. "Get tailored insights along your journey" — Noomcoins, treat days, steps, weight "-0.5 lbs in last 7 days", lessons.
  6. "Kickstart your health with medication" — "Welcome to Noom", "Check in with your doctor UNDER 3 MINUTES", "New message from your doctor", and a Wegovy HD 7.2 mg (semaglutide) pen. Footnote: "Wegovy is a registered trademark of Novo Nordisk, A/S".
  7. "Keep the muscle, lose the fat" — Muscle Defense™ videos and programs, "Specially created for weight loss medication", attributed to Jeffrey Egler, MD, Chief Medical Officer at Noom.
  8. "8 out of 10 members say Noom is a life-changing program" plus a "POWERED BY SCIENCE" tag over a woman eating an orange. Footnote: "63 of 82 Noom members taking an FDA-approved GLP-1 RA who answered Program Satisfaction questions at Month 6 agreed that Noom is a life changing program".
- **Arc:** mechanism (psychology) → personalised predicted outcome → daily plan → photo logging → insights → **GLP-1 medication** → muscle preservation on medication → satisfaction stat.
- **What changed versus the older set:** the colour-coded food frame, "Celebrate your progress" and the one-on-one coach frame are gone. Two GLP-1 frames (6, 7) replace them. The closing proof changed from a weight-loss outcome ("78% … lost weight") to a satisfaction rate among GLP-1 users (n = 82). The subtitle is now "Healthy Habits, Meals & GLP-1s".
- **Placement of proof:** the stat still comes *last*.

#### 4. Sleep Cycle – Tracker & Sounds (id 320606217; 4.68★, 32,437 ratings). Library: `/home/user/DAYXERO/reference/app-store-screenshots/health-fitness/sleep-cycle/` — [Lookup](https://itunes.apple.com/lookup?id=320606217&country=us) · [App Store](https://apps.apple.com/us/app/id320606217)
- **Format:** 10 portrait screenshots. Every screen shares one background — white sky fading through a cloud layer into dark teal — which reads as a continuous panorama. Screenshots 1→2 are a literal panorama: a large tilted phone crosses the seam, and screenshot 2 has *no caption*.
- **Captions:** large high-contrast black serif, top-left aligned, 2–3 lines, 2–4 words.
- **Device:** dark-mode UI in iPhone frames that are cropped by the clouds, with glowing cards breaking out.
- **Headlines in order:**
  1. "Sleep Better Tonight" + app icon + three orange-bullet benefits: "Decode Your Sleep / Monitor Your Sleep Health / Smart Alarm for Better Sleep". Phone shows "Sleep score 88, Very Good".
  2. (continuation of screenshot 1, no caption)
  3. "Superior Sleep Tracker"
  4. "AI Sleep Coach" — card: "You're getting enough deep sleep to give your body the boost it needs." with a glowing pink mascot.
  5. "Unparalleled Accuracy" — score 84.
  6. "Track your Sleep Stages"
  7. "Learn how you Sleep"
  8. "Record your Sleep Sounds" — "Sleep Talking".
  9. "Smart Alarm Great Start" — 07:30, "Set Smart Alarm".
  10. "Relaxing Sleep Aid"
- **Notable:** the only set in group B that uses the word "AI" in a headline, placed at screenshot 4 (visible position 3 after the panorama).
- **Not shown:** awards, ratings, press, people.

#### 5. Clue Period & Cycle Tracker (id 657189652; 4.76★, 408,217 ratings). Library: `/home/user/DAYXERO/reference/app-store-screenshots/health-fitness/clue/` — [Lookup](https://itunes.apple.com/lookup?id=657189652&country=us) · [App Store](https://apps.apple.com/us/app/id657189652)
- **Format:** 9 portrait screenshots, no panorama.
- **Background:** consistent deep red brand gradient with a radial glow.
- **Captions:** white light-weight sans, centred at the top, 2 lines, 3–4 words. Screenshot 1 mixes sans with an italic serif ("Know your *next period*") and ends "*with* ❀ Clue" at the bottom.
- **Device:** mostly frameless rounded UI cards with pop-out elements (an "Ovulation predicted" bubble, a magnified "Feelings: Mood swings" row). Screenshots 5–6 use lifestyle photos as the background: a woman in a red dress with lock-screen notifications, and a runner on a beach with a heart-rate chart.
- **Headlines in order:**
  1. "Know your next period with Clue" — "2 weeks until your next period".
  2. "See when you're ovulating"
  3. "Track how you feel" — pill badges "Strict data privacy" and "Chosen by 100M".
  4. "Discover your cycle insights" — "28 days Typical / 11 days Atypical / Report for doctor".
  5. "Set custom reminders" — lock-screen notifications such as "It's time to take your birth control"; badges "Women-led" and "Science-backed".
  6. "Connect a wearable" — 8 platform icons, including Apple Health, Fitbit and Oura.
  7. "Explore 300+ articles"
  8. "Add your birth control" — "IUD: inserted".
  9. "Follow your pregnancy" — "31 weeks + 0 days".
- **Trust signals:** woven in as small pill chips at the bottom of screenshots 3 and 5, not as a dedicated screen.
- **Notifications:** the only set that shows lock-screen notifications.

#### 6. WeightWatchers Program (id 331308914; 4.84★, 2,367,043 ratings). Library: `/home/user/DAYXERO/reference/app-store-screenshots/health-fitness/weightwatchers/` — [Lookup](https://itunes.apple.com/lookup?id=331308914&country=us) · [App Store](https://apps.apple.com/us/app/id331308914)
- **Older set:** the Lookup API's 7-frame 5.5" set (violet background, slot 1 "#1 doctor-recommended weight-loss program" with a lifestyle photo, no medication content) is no longer on the product page. It is kept in `weightwatchers/api-lookup-set/`.
- **Format (current product page):** 10 portrait screenshots, 6.5" class (1284×2778), no panorama.
- **Background:** solid saturated royal/electric blue on every frame.
- **Captions:** white centred bold condensed sans, 2–4 lines, 4–12 words. A lavender "NEW!" prefix sits on 4 of 10 frames (4–7).
- **Device:** light-blue rounded phone frames with Dynamic Island, cropped at the bottom. Screenshot 1 has a tilted phone with a burger tile and pill-bottle tile breaking out.
- **Headlines in order:**
  1. "THE NEW WEIGHT WATCHERS APP" (condensed wordmark) + "Weight-loss programs, support, and medications in one place".
  2. "Points®, macros, and progress—all in one spot" — Nutrition: 22 Points® left, daily summary by meal.
  3. "Access to weight loss medications through expert Clinicians (if you qualify)" — Medical visit with "Melissa Lang, MD, Your Clinician", Join visit / Reschedule, medication tracker "Next dose is due on Sat Nov 22, 2025", 5 days left.
  4. "NEW! GLP-1 Success Program Expert support, better results" — medication tracker, side effects, refill reminder.
  5. "NEW! Modes Flexible settings let you choose how you lose" — "Choose your MODE": ALL-IN / LOSE / MAINTAIN.
  6. "NEW! Weight Watchers for Menopause" — home with protein/fiber/water rings, "Weight Health Score 50 – In the groove".
  7. "NEW! AI Body Scanner shows your progress beyond pounds" — body scan, body fat 27 lbs, lean mass 15.9 lbs.
  8. "Simple, fast meal tracking: See it, snap it, log it" — food scanner.
  9. "350+ ZeroPoint® foods to keep you full and make healthy eating easier"
  10. "Barcode scanning for effortless tracking"
- **Arc:** "new app" + medications promise → core Points tracking → **medication access via clinicians** → GLP-1 program → new modes → menopause → AI body scan → the classic tracking features (photo, ZeroPoint, barcode) at the end.
- **Proof:** none. The "#1 doctor-recommended" claim and its survey footnote are gone. There are no ratings, press or awards. The only authority cue is the named MD clinician in the UI.
- **Not shown:** lifestyle photography (the older set had a woman on slot 1), widgets and price.

#### 7. Hevy – Workout Tracker Gym Log (id 1458862350; 4.92★, 104,475 ratings). Library: `/home/user/DAYXERO/reference/app-store-screenshots/health-fitness/hevy/` — [Lookup](https://itunes.apple.com/lookup?id=1458862350&country=us) · [App Store](https://apps.apple.com/us/app/id1458862350)
- **Older set:** the Lookup API's 5.5" set had the same captions in the same order, but older iPhone frames (one with a home button), a gold "PR" medal on 3 and a "Nice work man! Keep it up!" bubble on 5. It is kept in `hevy/api-lookup-set/`.
- **Format (current product page):** 10 portrait screenshots, 6.5" class (1242×2688). Screenshots 1→2 form a panorama: a tilted phone mostly in screenshot 2. Screenshot 2 has no caption, only the "HEVY" wordmark top right.
- **Background:** light grey on the top two-thirds and a royal-blue band on the bottom third, consistent across the set. Screenshot 10 inverts to dark.
- **Captions:** heavy black ALL-CAPS sans, centred at the top, 2 lines, 3–4 words. Screenshot 1 is a left-aligned stack in black and blue: "LOG **WORKOUTS** / GET **STRONGER** / STAY **MOTIVATED**", with an "Apps We Love" laurel and ★★★★★ in the blue band.
- **Device:** modern black iPhone frames with a notch, cropped at the bottom. The green completed-set rows pop out of the frame on 1→2. The UI is refreshed: an exercise summary for Squat (Barbell) with a progress chart and a "Personal Records" link on 3, progress photos on 6, and a Routines grid on 8.
- **Headlines in order:**
  1. "LOG WORKOUTS / GET STRONGER / STAY MOTIVATED"
  2. (panorama continuation, no caption; HEVY wordmark)
  3. "ANALYZE YOUR WORKOUTS" — Squat (Barbell) heaviest-weight chart.
  4. "PLAN YOUR ROUTINES"
  5. "JOIN A GROWING COMMUNITY" — feed post "Chest Day" plus Suggested Athletes.
  6. "TRACK MEASUREMENTS"
  7. "COMPARE YOUR STRENGTH" — head-to-head users, "STRONGER" tag.
  8. "FOLLOW FRIENDS' PROGRESS"
  9. "LIBRARY WITH HQ VIDEOS"
  10. "SLEEK DARK MODE"
- **Social emphasis:** social features take 3 of 10 slots.

#### 8. LADDER Strength Training Plans (id 1502936453; 4.95★, 224,608 ratings). Library: `/home/user/DAYXERO/reference/app-store-screenshots/health-fitness/ladder/` — [Lookup](https://itunes.apple.com/lookup?id=1502936453&country=us) · [App Store](https://apps.apple.com/us/app/id1502936453)
- **Older set:** the Lookup API's 5.5" set had 2024 awards (Women's Health, CNET), a "PREVIEW EVERY MOVEMENT" frame and no nutrition frame. It is kept in `ladder/api-lookup-set/`.
- **Format (current product page):** 10 portrait screenshots, 6.5" class (1242×2688). Screenshots 1→2 are a panorama on a neon-yellow gradient fading to white: three tilted dark-UI phones. Screenshot 2 has no caption.
- **Proof on the hero:** screenshot 1 has the LADDER logo, a huge black extended ALL-CAPS headline "GET STRONGER, WITH A PLAN." and an Apple laurel "App Store App of the Year 2025 Finalist". Screenshot 2 adds two laurels: "2026 Women's Health – Best Overall Workout App" and "2026 CNET – Best Strength Training App". Screenshots 3–10 are plain white.
- **Captions:** heavy extended black ALL-CAPS, centred at the top, 2 lines, 2–5 words.
- **Device:** dark-mode UI with neon-yellow accents in current iPhone frames (Dynamic Island). Real coaches and athletes are prominent inside the UI.
- **Headlines in order:**
  1. "GET STRONGER, WITH A PLAN."
  2. (panorama continuation, no caption; two 2026 award laurels)
  3. "A PLAN FOR EVERY WORKOUT" — "LIMITLESS" team home, "PEACH PALACE" workout.
  4. "TRACK MACROS" — **new**: photo meal capture plus a Nutrition screen (520 calories left, 22 g protein left, Macro Journal).
  5. "FIND THE PERFECT PLAN FOR YOU" — "Coach Kelly, LIMITLESS" plus a grid of programs (FORGED, TRANSFORM, CREWS CONTROL…).
  6. "GET COACHED THROUGH IT ALL" — a coach's face fills the screen ("PYTHON PUMP").
  7. "LEARN CORRECT FORM" — an athlete mid-squat with a 0:28 timer.
  8. "TRACK YOUR PROGRESS" — Romanian Deadlift, 186 lbs estimated 1RM, ↑12%, with an **Apple Watch** (Ultra-style) workout screen overlapping the phone.
  9. "LISTEN TO YOUR OWN MUSIC" — Spotify, Apple Music, YouTube Music, Amazon Music, Podcasts.
  10. "GET ANSWERS TO YOUR QUESTIONS" — team chat with a pinned video message from "Coach Lauren".
- **What changed versus the older set:** the awards were updated to an App Store App of the Year 2025 finalist laurel plus two 2026 awards. Nutrition ("TRACK MACROS") replaced "PREVIEW EVERY MOVEMENT". The Apple Watch moved to the progress frame.

#### 9. AllTrails: Hike, Bike & Run (id 405075943; 4.89★, 1,043,416 ratings). Library: `/home/user/DAYXERO/reference/app-store-screenshots/health-fitness/alltrails/` — [Lookup](https://itunes.apple.com/lookup?id=405075943&country=us) · [App Store](https://apps.apple.com/us/app/id405075943)
- **Format:** 10 portrait screenshots.
- **Screenshot 1:** near-black forest green, a huge white sans headline "Discover 500,000+ trails", and a neon-green "trail" swoosh that continues into screenshot 2 as a linking device.
- **Screenshots 2–9:** pale sage-grey solid background; black centred regular-weight sans in 2 lines (a verb phrase + a qualifier, 5–6 words); full iPhone frames showing photos and maps.
- **Headlines in order:**
  1. "Discover 500,000+ trails"
  2. "Discover trails that inspire you"
  3. "See trail details before going" — Lake Blanche Trail, 6.4 mi, 2,726 ft.
  4. "Tour the trail with recent photos"
  5. "Check conditions by the hour" — 75% chance of precipitation.
  6. "Explore offline with map downloads"
  7. "See the terrain before you go" — 3D satellite.
  8. "Check reviews for real insights" — user reviews with photos.
  9. "Navigate on the trail and track your stats"
  10. Full-bleed lifestyle photo (adult and child on a boardwalk) with press quote: "Think of AllTrails as your friend who used to be a park ranger." — The Cut, New York Magazine.
- **Arc:** scale number → plan → prepare → navigate → press-endorsement close.
- **Not shown:** Premium is not labelled even though offline maps is a paid feature.

#### 10. Yuka – Food & Cosmetic Scanner (id 1092799236; 4.82★, 102,533 ratings). Library: `/home/user/DAYXERO/reference/app-store-screenshots/health-fitness/yuka/` — [Lookup](https://itunes.apple.com/lookup?id=1092799236&country=us) · [App Store](https://apps.apple.com/us/app/id1092799236)
- **Format:** 6 portrait screenshots, no panorama.
- **Background:** solid Yuka green.
- **Captions:** white, centred at the top, two tiers — a bold ALL-CAPS keyword plus a sentence-case line, 4–5 words.
- **Device:** frameless white UI cards cropped at the bottom, with one row enlarged and lifted as a pop-out.
- **Headlines in order:**
  1. "ANALYZE products in a single scan" — real product "Honey Nut Cheerios 8/100 Bad" with Negatives (additives, sugar, calories, sodium) and Positives (protein).
  2. "AVOID harmful ingredients" — Vanicream 10/100, "BHT High-Risk".
  3. "DISCOVER healthier alternatives" — bad → excellent product swaps.
  4. "EXPLORE top-rated products" — ranked list with 90/100 etc.
  5. "Hold brands ACCOUNTABLE" — "Ask Powerade to remove high-risk additives", "2,549 consumers have already called out Powerade, Goal 5,000", pre-written email/Instagram.
  6. "SUPPORT A 100% independent project" — "No funding from brands or manufacturers / Rigorous, impartial scientific analyses / Entirely funded by user contributions", with an illustration of diverse raised fists.
- **Arc:** utility → protection → alternatives → discovery → activism → mission/values close.
- **Not shown:** ratings, press, awards.

### Inferences
- The "headline is the screenshot" convention holds everywhere. Every set captions at the top, and nearly every caption is short. Only Noom 1 (11 words), Noom 8 (11) and WW 9 (12) exceed 10 words.
- Where a panorama is used (Sleep Cycle, Hevy, Ladder), screenshot 2 is a no-caption hero continuation. Noom's panorama keeps a caption on 2. In search results this produces one very wide hero image built from slots 1–2, which leaves slot 3 as the only "feature" frame visible.

### Gaps
- Product-page check (2026-11-20): none of the 10 has an iPhone App Preview video, so all lead with screenshot 1. Subtitles are now recorded in the capture note above. I still did not analyse promotional text, Custom Product Pages or in-app event cards.
- Resolved: the 5.5" Lookup sets for Noom, WW, Hevy and Ladder were not what current iPhones see. The product-page sets are analysed above.
- I could not confidently identify 4 of Clue's 8 wearable logos.

## Q2. Cross-app patterns, distinctive moves, and strongest sets

### Takeaway
The common pattern is short 2-line top captions on a single consistent brand colour, with a cropped phone frame or floating UI cards, one benefit per screen, and outcome or proof on screenshot 1. What sets the leaders apart is a panoramic 1→2 hero, a quantified or third-party proof point on screenshot 1, a human (coach or community) near the end, and trust or science as the closing argument. The strongest sets are Ladder, Noom, Lose It!, Clue and AllTrails.

The product-page refresh adds one new cross-app pattern. The two legacy weight-loss programs, Noom and WW, now sell **GLP-1 medication access** in their screenshots (Noom 6–7, WW 1/3/4) and in Noom's subtitle.

### Cited Findings (each from the product-page screenshots in the library; app pages linked in Q1)
- **Set size:** average 8.9 screenshots (10, 6, 8, 10, 9, 10, 10, 10, 10, 6). Six apps use the full 10: Lose It!, Sleep Cycle, WW, Hevy, Ladder, AllTrails. All are portrait — [product pages, e.g. WW](https://apps.apple.com/us/app/id331308914)
- **Panorama / continuity:** 5 of 10. True 1→2 panoramas with an uncaptioned screenshot 2: Sleep Cycle, Hevy, Ladder. Noom has a 1→2 panorama (captioned 2) plus a dotted-path motif on 1 and 8. AllTrails uses a swoosh from 1 into 2. Sleep Cycle also has a continuous sky background across all 10 — [Sleep Cycle](https://apps.apple.com/us/app/id320606217), [Ladder](https://apps.apple.com/us/app/id1502936453)
- **Proof on screenshot 1:** 4 of 10 (down from 5 in the Lookup sets, because WW dropped its claim).
  - Lose It!: "#1 Weight Loss Tracker" + "As seen on" CNN / TODAY / People / GMA / Women's Health.
  - Ladder: "App Store App of the Year 2025 Finalist" on 1, plus 2026 Women's Health and CNET awards on 2.
  - Hevy: "Apps We Love" laurel + 5 stars.
  - AllTrails: a scale number, "500,000+ trails".

  WW's slot 1 is now a "new app" promise ("Weight-loss programs, support, and medications in one place") with no proof. The older "#1 doctor-recommended" claim is gone. Placed elsewhere: Clue's "Chosen by 100M" sits on screenshot 3. Noom's "8 out of 10 members say Noom is a life-changing program" (footnoted to 63 of 82 GLP-1 users at month 6) is the *last* frame. No app shows its star rating or rating count as text — [Lose It!](https://apps.apple.com/us/app/id297368629), [WW](https://apps.apple.com/us/app/id331308914), [Noom](https://apps.apple.com/us/app/id634598719)
- **Visual treatment:**
  - Device frames on most or all slides: Lose It!, BetterMe (2–6), Noom (2–7), Sleep Cycle, WW, Hevy, Ladder, AllTrails.
  - Frameless floating cards: Clue, Yuka.
  - Lifestyle photos with people: BetterMe 1, Clue 5–6, AllTrails 10, Noom 8 (woman eating an orange). WW no longer uses one.
  - In-UI people: Ladder coaches, WW's MD clinician (3), Noom's chief medical officer avatar (7), community avatars in Lose It! and Hevy.
- **Colour:** every set holds one background treatment across the set. Only Hevy 10 (dark mode), AllTrails 1 (dark hero), Ladder 1–2 (neon hero) and Noom 8 (photo closer) break it, and all four are deliberate hero or closer frames.
  - Light/neutral: BetterMe cream, AllTrails sage, Hevy grey/blue, Ladder white, Noom pale lavender-grey.
  - Saturated brand colour: Lose It! navy, Clue red, WW royal blue, Yuka green.
  - Atmospheric: Sleep Cycle.
- **Typography:** sans dominates. Serif is used by Sleep Cycle (entire set), Noom (bookend frames 1 and 8 only; 2–7 are now sans) and Clue 1 (italic accent) to signal "science / calm / premium". Heavy ALL-CAPS is used by Hevy and Ladder (gym tone) and by Yuka (keyword only). WW uses a condensed bold sans.
- **Features and surfaces:**
  - Apple Health: Lose It! 8, Clue 6.
  - Apple Watch: Ladder 8 (hardware render), Lose It! 8 (icon).
  - Lock-screen notifications: Clue 5.
  - Home-screen widgets and Live Activities: none.
  - "AI" in a headline: Sleep Cycle ("AI Sleep Coach") and WW ("NEW! AI Body Scanner…", slot 7).
  - Photo food logging: Lose It! 3, WW 8 ("See it, snap it, log it"), Noom 4, Ladder 4 ("TRACK MACROS").
  - **GLP-1 / weight-loss medication:** Noom 6 (Wegovy pen, "Check in with your doctor UNDER 3 MINUTES") and 7 (Muscle Defense™ "for weight loss medication"). WW 1 ("…and medications in one place"), 3 ("Access to weight loss medications through expert Clinicians (if you qualify)") and 4 ("NEW! GLP-1 Success Program"). No other group B app mentions medication.
  - "NEW!" labels: WW 4–7 only.
- **Premium, price and community:** no set shows price, a "Premium" label or a trial. Community/social appears in Lose It! 9, Hevy 5/7/8, Ladder 10 and Yuka 5. A human coach or clinician appears in Ladder 6/10 and WW 3 (MD). Noom no longer shows its coach chat.
- **Personalised outcome:** Noom 2 ("We predict you'll be 150 lbs by May 8… lose 9 lbs or 5% of your body weight") and Lose It! 4 ("↓21 lbs since…") are still the only frames that show a quantified personal future or past result.

### Inferences
- **Strongest sets, in my judgement:**
  1. **Ladder.** It has the highest-contrast hero (neon + extended caps), now with the strongest proof stack in the group (an App Store App of the Year 2025 finalist laurel on 1 plus two 2026 awards on 2). Its panorama reads as one billboard in search, with real coaching faces and Apple Watch.
  2. **Noom.** It still sells the *mechanism* ("psychology") on 1–2, and its predicted-outcome chart makes the benefit personal and dated. The current set is less pure, though: the coach frame is gone, two GLP-1 frames take over 6–7, and the closing stat is now satisfaction among 82 GLP-1 users, not weight loss. Its first three frames (mechanism → prediction → daily plan) are still the best behaviour-change template for a quit app.
  3. **Lose It!.** It makes a dense credibility stack on screenshot 1 (#1 + 5 press logos) and then gives a very legible one-verb-per-screen feature run.
  4. **Clue.** It uses an emotional brand colour and puts trust chips ("Strict data privacy", "Science-backed", "Women-led", "Chosen by 100M") inside feature frames — relevant to a sensitive-health app.
  5. **AllTrails.** One giant number on 1 and a press-quote lifestyle closer on 10.
- **Weakest:** BetterMe, which has generic captions and no proof, differentiation or outcome. Hevy's frames are no longer dated on the product page, but its captions are generic ("TRACK MEASUREMENTS"). WW's current set is a feature-and-announcement list ("NEW!" ×4) that lost its slot-1 proof. Its medication pivot is strategically clear but carries no evidence.
- **Medication pivot (inference):** Noom and WW, the two legacy diet programs in the group (874k and 2.37M ratings), now put GLP-1 access mid-set or on slot 1. Neither of their older 5.5" sets mentioned medication. I don't know when the switch happened. For DayXero it suggests that pharmacological help is a mainstream screenshot message in adjacent health categories. The quit category's treatment of NRT (see `quit_apps.md`) is the analogue.
- **Implications for DayXero (inference):**
  - Lead with an outcome or mechanism claim plus proof on 1, ideally as a panorama 1→2.
  - Make the visible trio (1–3) carry claim, personal outcome (e.g. a days-nicotine-free counter, money saved, health recovery timeline — the analogue of Noom's prediction chart) and the core daily mechanic.
  - Use a single saturated brand background for the set.
  - Keep captions to 2 lines of ≤6 words.
  - Show one human or community frame.
  - Weave trust and privacy chips into frames rather than spending a slot on them.
  - Close with a science-backed stat or press quote.
  - Widgets and Live Activities, which no group B app shows, are an open differentiator for a streak/counter app.

### Gaps
- I did not measure conversion: these are qualitative judgements, and none of the apps' A/B or Product Page Optimization results are public.
- The analysis covers only the default product page. Custom Product Pages tied to ads may tell a different story.
- Product Page Optimization tests could mean another visitor sees a different default set. I fetched each page once (2026-11-20) and cannot rule this out.
