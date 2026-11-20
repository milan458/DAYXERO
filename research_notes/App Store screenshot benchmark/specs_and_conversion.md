# App Store (and Google Play) Screenshot Specs, Rules and Conversion Evidence: DayXero (as of Nov 2026)

Research date: 2026-11-20. Network note: this session could reach developer.apple.com, but not support.google.com, play.google.com, splitmetrics.com, phiture.com or consultmyapp.squarespace.com (DNS blocked). For those sources, findings come from search-result snippets and secondary write-ups and are flagged as such. To verify them directly, those hosts must be allowed in the session's network settings.

## 1. Apple's current required screenshot sizes, counts and formats

### Takeaway
Upload 10 portrait PNG/JPEG screenshots at **1320 x 2868** (the "iPhone with Dynamic Island (large display)" class: 6.9"/iPhone 17 Pro Max). Also upload a **1206 x 2622** set (the "Dynamic Island (medium display)" class: 6.3"/iPhone 17), because Apple's "Required device sizes" line names the medium class. Use 1 to 10 images per size, no alpha or transparency. Apple's page no longer uses inch labels; it uses device-class names.

### Cited Findings
- Count and format: "You must include at least one screenshot and can upload up to 10 screenshots per device size in .jpeg, .jpg, or .png formats." — [Apple, Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- Alpha: "Images can't include alpha channels or transparencies." Apple's page specifies **no colour profile or colour-space requirement** and no DPI requirement. — [Apple, Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- Scaling: "If your app's user interface is consistent across multiple device sizes and localizations, you only need to provide screenshots for the highest required resolution. App Store Connect automatically scales them down for smaller device sizes." — [Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- **iPhone with Dynamic Island (large display)**: iPhone Air, iPhone 18 Pro Max, 17 Pro Max, 16 Pro Max, 16 Plus, 15 Pro Max, 15 Plus, 14 Pro Max. Accepted portrait sizes: **1260 x 2736, 1290 x 2796, 1320 x 2868** (landscape: the same sizes swapped). Note: "If screenshots with the accepted sizes aren't provided, scaled screenshots for iPhone with Face ID (large display) are used." Apple lists no Requirement row for this class. — [Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- **iPhone with Dynamic Island (medium display)**: iPhone 18 Pro, 17 Pro, 17, 16 Pro, 16, 15 Pro, 15, 14 Pro. Portrait sizes: **1179 x 2556, 1206 x 2622**. Falls back to scaled Face ID (large) screenshots. — [Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- "Required device sizes" section, verbatim: "**iPhone:** At least one screenshot for iPhone with Dynamic Island (medium display)." — [Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- **iPhone with Face ID (large display)** (6.5"): iPhone 14 Plus, 13 Pro Max, 12 Pro Max, 11 Pro Max, 11, XS Max, XR. Sizes: 1284 x 2778, 1242 x 2688. Requirement: "Required if app runs on iPhone and screenshots for iPhone with Dynamic Island (large display) aren't provided." Falls back to scaled Dynamic Island (large) screenshots. — [Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- Smaller classes are optional and fall back to the next larger size: Face ID medium (1170 x 2532 / 1125 x 2436 / 1080 x 2340), Home Button 5.5" (1242 x 2208), 4.7" (750 x 1334), 4" and 3.5". — [Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- **New: iPhone Duo** (foldable class): 1398 x 2034 portrait (outer screen) and 2007 x 2853 portrait (inner screen). "Starting in April 2027, screenshots will be required for any app using the iOS 27.1 SDK or later." Submitting them adds a "made for iPhone Duo" badge to the product page. — [Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- iPad (only if DayXero runs on iPad): 13" at 2064 x 2752 or 2048 x 2732 is required. — [Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
- Third-party guides still use the inch labels: 6.9" = 1320 x 2868 (also accepts 1290 x 2796 and 1260 x 2736; the latter is the iPhone Air). They conflict on the fallback rules. — [Adalo](https://studio.adalo.com/blog/app-store-screenshot-sizes-2026), [aso.dev](https://aso.dev/app-store-connect/screenshots/), [AppDrift](https://appdrift.co/blog/how-to-create-perfect-app-store-screenshot-sizes)
- **App previews (video):** 15 to 30 s; up to 3 per device size and language; .mov/.m4v/.mp4 (H.264) or ProRes 422 HQ; at most 30 fps; at most 500 MB. Accepted resolution for all Dynamic Island, Face ID and Duo classes is **886 x 1920** (portrait). The poster frame is selectable (defaults to 5 s). Processing takes up to 24 h. — [Apple, App preview specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications/)

### Inferences
- Apple's page is internally inconsistent. The "Required device sizes" line names the **medium** Dynamic Island class, while the Face ID large row implies the **large** Dynamic Island set is the primary one. 1320 x 2868 (ratio 0.4603) and 1206 x 2622 (0.4600) are effectively the same aspect ratio. The safe approach is to design once at 1320 x 2868, export a 1206 x 2622 copy, and upload both.
- Colour: Apple sets no requirement. Exporting flattened 8-bit sRGB PNG (no alpha) is the safe default. This is an inference and not an Apple rule.
- For a portrait iPhone-only app, the iPhone Duo set can wait until DayXero builds with the iOS 27.1 SDK. After April 2027, plan for it.

### Gaps
- Apple publishes no colour-space, DPI or file-size limit for screenshots on this page.
- I could not confirm when Apple changed the "required" wording from 6.9"/6.5" to the medium class.

## 2. App Review Guideline rules relevant to screenshots (and health apps)

### Takeaway
Screenshots must show the real app in use. They must not contain prices, "free" or discount text, unverifiable claims, or Apple-endorsement implications. They must suit a 4+ audience, show only Apple platforms, and disclose when a featured item needs a subscription. A health-adjacent app gets extra scrutiny on accuracy claims, so avoid clinical-efficacy numbers you cannot substantiate.

### Cited Findings
- **2.3.3 Screenshots:** "Screenshots should show the app in use, and not merely the title art, login page, or splash screen. They may also include text and image overlays (for example, to demonstrate input mechanisms…)". — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **2.3.4 Previews:** "previews may only use video screen captures of the app itself… You can add narration and video or textual overlays". — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **2.3.7 Pricing in metadata:** "Metadata such as app names, subtitles, screenshots, and previews should not include prices, terms, or descriptions that are not specific to the metadata type." Subtitles must not "make unverifiable product claims." — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **2.3.14 Creative assets** must not include "references to other apps with an intent to mislead, unverifiable product claims, or specific or discounted pricing information." — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **2.3.1(a):** marketing "in a misleading way, such as by promoting content or services that it does not actually offer… or promoting a false price" is grounds for removal. — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **2.3.2 IAP disclosure:** "make sure your app description, screenshots, and previews clearly indicate whether any featured items, levels, subscriptions, etc. require additional purchases." — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **2.3.8:** screenshots and previews must "adhere to a 4+ age rating even if your app is rated higher." — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **2.3.10:** do not include "names, icons, or imagery of other mobile platforms" in metadata. — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **5.2.4:** "Don't suggest or imply that Apple is a source or supplier of the App, or that Apple endorses any particular representation…" and "If your app is selected as an 'Editor's Choice,' Apple will apply the badge automatically." — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **Section 3 intro:** manipulating reviews or chart rankings ("paid, incentivized, filtered, or fake feedback") can lead to expulsion. — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- The guidelines contain no explicit ban on "#1", "award" or ranking text in screenshots. The relevant limits are "unverifiable product claims" (2.3.7, 2.3.14) and misleading marketing (2.3.1). — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **1.4.1 Medical:** medical apps "may be reviewed with greater scrutiny." Apps "must clearly disclose data and methodology to support accuracy claims relating to health measurements" and "should remind users to check with a doctor". — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **1.4.3:** "Apps that encourage consumption of tobacco and vape products… are not permitted." This matters for imagery: never make vaping or smoking look appealing. — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **5.1.3** HealthKit or health data may not be used for marketing. Write HealthKit data accurately. — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### Inferences
- For DayXero:
  - Allowed: in-app stats such as "$1,240 saved" or "Day 47 nicotine-free", shown as app UI. These are app content, not pricing.
  - Not allowed: "Free", "$4.99/mo", "50% off", "Start free trial" price text.
  - If a showcased feature is Pro-only, label it, for example a small "Pro" tag, to satisfy 2.3.2.
- Avoid efficacy claims such as "Quit in 30 days", "3x more likely to quit" or "clinically proven" unless the evidence is citable. These risk 2.3.7/2.3.14 ("unverifiable") and 1.4.1 scrutiny. Phrase claims as features or benefits ("Track cravings", "See your body recover"). Health-recovery timelines shown in-app should cite sources inside the app.
- Device frames are not prohibited. 2.3.3 allows overlays, and 5.2.4/5.2.5 warn only against implying Apple endorsement or mimicking Apple UI. Using generic or official Apple device frames is common practice, but this is an inference with no explicit Apple rule found.
- Ratings or review quotes: there is no explicit ban, but they must be genuine and verifiable (2.3.1, Section 3). Do not fake an "Editor's Choice" or "App of the Day" badge.
- Keep cigarettes and vapes out of the screenshots, or show them only as crossed-out or negative imagery, to stay 4+ (2.3.8) and clear of 1.4.3.

### Gaps
- I found no Apple guidance specific to quit-smoking apps, and no Apple text listing "#1" or award claims as prohibited outright.

## 3. Search-result display, captions as a ranking signal, CPPs, PPO and In-App Events

### Takeaway
Portrait screenshots show the first 3 in search results when no preview video exists, so frames 1 to 3 do most of the work. The claim that screenshot captions are indexed (June 2025) is **disputed and unconfirmed by Apple**. Custom Product Pages (up to 70) can now take keywords and appear in organic search. PPO allows 3 treatments for up to 90 days.

### Cited Findings
- "Depending on the orientation of your screenshots, the first one to three images will appear in search results when no app preview is available, so make sure these highlight the essence of your app." Also: "Focus each subsequent screenshot on a main benefit or feature." And: "If your app supports Dark Mode, consider including at least one screenshot that showcases" it. — [Apple, Product Page](https://developer.apple.com/app-store/product-page/)
- App previews "autoplay with muted audio… make sure the first few seconds of your video are visually compelling." Up to 3 previews. Poster frames show when video doesn't autoplay. — [Apple, Product Page](https://developer.apple.com/app-store/product-page/)
- Localize screenshots and previews per market. — [Apple, Product Page](https://developer.apple.com/app-store/product-page/)
- **Caption indexing, claimed:** AppTweak's anomaly tracking spiked around 7–8 June 2025, and several ASO blogs say captions are now read (OCR) for ranking. — search summary of [AppTweak ranking factors](https://www.apptweak.com/en/aso-blog/app-store-ranking-factors?format=md), [Appfigures](https://analytics.appfigures.com/resources/guides/app-store-algorithm-update-2025), [AppDrift](https://appdrift.co/blog/app-store-screenshot-text-indexing). These are vendor or blog sources.
- **Caption indexing, disputed:**
  - ConsultMyApp with APPlyzer tested 64 screenshot-derived phrases across 8 category-leading US iOS apps. 36 did not rank, 27 were explained by existing metadata, and 1 anomaly (Audible) remained. The verdict was "no strong evidence Apple is broadly indexing screenshot titles." — [ConsultMyApp](https://consultmyapp.squarespace.com/blog/-is-apple-now-indexing-screenshot-titles-on-the-app-store) (seen via search snippet; the vendor ran the test with its own tool)
  - A Phiture piece reportedly says Apple has denied caption indexing, and AppTweak echoed this in a seminar. — [Phiture, ASO trends 2026](https://phiture.com/blog/aso-trends-in-2026/) (seen via search snippet; could not fetch)
- **Custom Product Pages:**
  - "You can publish up to 70 additional versions of your product page". You can "assign keywords to your custom product page… This lets your custom product page appear in search results for those selected keywords, rather than your default product page", and "each keyword combination is unique to a single product page".
  - Screenshots, promotional text and previews can vary. Deep links work on iOS 18+. Pages are reviewed independently of app updates.
  - Apple's claim: "Developers see a 2.5 percentage point increase on average when referring people to a custom product page… a 156% increase compared to the 1.6% average conversion rate on default product pages."
  - — [Apple, Custom Product Pages](https://developer.apple.com/app-store/custom-product-pages/)
- Dates per vendors: keyword assignment for organic search arrived **July 2025**, and the cap doubled from 35 to 70 on **29 Oct 2025**. Keywords already in the title or subtitle can't be assigned to a CPP. — [MobileAction](https://www.mobileaction.co/blog/apple-doubles-the-custom-product-page-limit/), [AppTweak CPP guide](https://www.apptweak.com/en/aso-tools/custom-product-pages-cpp?lang=en-US)
- **Product Page Optimization:**
  - Test icons, screenshots and previews with "up to three treatments". A test "runs for 90 days or until you manually stop it", and only one test runs at a time.
  - You set a traffic percentage, and new metadata needs App Review. Shown on iOS/iPadOS 15+.
  - Apple recommends waiting for "at least 90% confidence."
  - — [Apple, PPO](https://developer.apple.com/app-store/product-page-optimization/)
- **In-App Events (2.3.13):** "must fall within an event type provided in App Store Connect. All event metadata must be accurate and pertain to the event itself". — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### Inferences
- Writing captions in the vocabulary users search ("quit vaping", "nicotine tracker", "cravings") costs nothing and may help if indexing is real. Do not rely on captions for ranking; keep the keyword field, title and subtitle as the primary levers.
- For DayXero, CPPs could map keyword clusters ("quit vaping", "quit Zyn/pouches", "quit smoking") to tailored screenshot sets. The "10 screenshots" default set should lead with the broadest promise.
- Run PPO on screenshot 1 first, because it affects both search (first 3) and the product page.
- A preview video replaces screenshots in search results, because it autoplays. Adding one changes what users see first.

### Gaps
- No Apple primary statement on caption indexing (neither confirmation nor denial) was found on developer.apple.com.
- I did not retrieve In-App Event card image specs from Apple; check App Store Connect Help, "In-app event" reference.

## 4. Evidence on what converts

### Takeaway
The best-supported data says few users scroll deep: roughly 11% see all 5 portrait screenshots (SplitMetrics, 2018), so frames 1 to 3 carry the decision. Most other effect sizes (benefit captions +18–31%, video +15–35%) are vendor claims with weak provenance. Video effects vary by category and can be negative. Treat these as hypotheses to test with PPO.

### Cited Findings
- **Scroll depth (SplitMetrics, Mar 2018, about 1,800 A/B tests):** only 15% (landscape) and 11% (portrait) of users scroll through all 5 screenshots. Caveat: most tests used already-optimized sets. — [SplitMetrics, scroll depth](https://splitmetrics.com/blog/apple-screenshots-scroll-depth/) (via search snippet; could not fetch). The data is from 2018, before the 10-screenshot and Dynamic Island era, so treat it as older.
- SplitMetrics 2024 benchmarks (finance): about 50% of users scroll through the first visible screenshots, and only about 7% see the 5th. — [SplitMetrics ASO Benchmarks 2024, finance screenshot trends](https://splitmetrics.com/aso-benchmarks-2024/2-3-finance-apps-screenshot-trends) (via snippet; finance category, not H&F)
- The widely repeated "70% never scroll past the first screenshot" has **no traceable study**. — search finding across [explore.picc.co](https://explore.picc.co/app-store-screenshots-costing-downloads/) and others. A critic says the "five-words-or-fewer" caption rule and "60/40 top-weighted" figures also trace to no test. — [blakecrosley.com](https://blakecrosley.com/blog/app-store-screenshots-sell-the-why)
- **Caption length and boldness:** in a SplitMetrics case, FreshPlanet's SongPop2 got about 10% better CVR from "Shorter Captions and Bolder Graphics in iOS Screenshots" (older case, games). — [SplitMetrics case](https://splitmetrics.com/?p=4944)
- **Screenshot redesigns:** OLBG saw a 61% conversion boost from iOS screenshot optimization, and ZiMAD a 32% lift from a redesign. These are vendor case studies, single apps, older. — [SplitMetrics OLBG](https://splitmetrics.com/cases/olbg-ios-screenshots-optimization/), [SplitMetrics ZiMAD](https://splitmetrics.com/?p=4976)
- **Benefit vs feature:** one vendor report claims an 18–31% lift across 4 tests from switching to benefit-driven captions. One case shows a benefit-led first screenshot about 18% better. These are vendor claims with no sample sizes. — [trysonar.app captions](https://trysonar.app/blog/app-store-screenshot-captions), [appwispr](https://www.appwispr.com/blog/screenshot-conversion-lab-6-a-b-tests-to-turn-app-store-screenshots-into-installs)
- **Social proof:** in one cited case, the winner put "CBT" in the first caption and used an (authentic) Editor's Choice badge, giving a +30% download lift. Single case, confounded. — [airbridge](https://www.airbridge.io/en/blog/app-store-listing-conversion-screenshots-icons-ratings) / [blakecrosley.com](https://blakecrosley.com/blog/app-store-screenshots-sell-the-why) (search summary)
- **Video previews, conflicting:**
  - SplitMetrics is reported at about +16% and StoreMaven at +20–35%.
  - A StoreMaven finance test found video **lowered** CVR by 3–7%.
  - Apple's own PPO example: "The original product page without an app preview video outperformed the treatment, contrary to the developer's hypothesis."
  - — [appboard.dev](https://appboard.dev/blog/app-preview-video-vs-screenshots), [strataigize](https://www.strataigize.com/blog/app-store-conversion-rate-optimization), [Apple PPO](https://developer.apple.com/app-store/product-page-optimization)
- **Apple guidance:** make the first 1 to 3 shots "highlight the essence", give one benefit or feature per subsequent shot, and include a Dark Mode shot if supported. — [Apple Product Page](https://developer.apple.com/app-store/product-page/)
- Apple CPP data shows tailored creative to intent lifts CVR (+2.5 pp average vs a 1.6% default-page baseline, in Apple's framing). — [Apple CPP](https://developer.apple.com/app-store/custom-product-pages/)

### Inferences (design rules for the 10-shot set)
- **Frame 1** carries the most weight. Put the core outcome promise and the hero UI (for example the day counter or money saved) in it, with a large caption readable at search-result thumbnail size. Keep it to about 3 to 6 words; this is heuristic, not proven.
- **Frames 1 to 3** should work as a standalone mini-story in search results. They could be panoramic or connected, but each must also read on its own, since the product page shows them individually.
- **Frames 4 to 10** are seen by few users. Use them for depth (features, privacy, widgets, Pro), and for keyword-bearing captions in case indexing is real.
- Use benefit-led headlines with feature subcopy. This is directionally supported, but the magnitudes are unreliable.
- Use only genuine social proof (real rating once you have one, real press). No fake badges.
- Light vs dark: there is no rigorous comparative study. Apple only suggests including a dark-mode shot. Choose for contrast against the App Store's own light and dark backgrounds, and test with PPO.
- Video: test it, don't assume. It replaces screenshots in search results and can reduce CVR in some categories.

### Gaps
- No rigorous, independent, recent (2025–26) study on caption length, dark vs light backgrounds, showing people or faces, or panoramic sets was found. Most numbers are vendor marketing.
- StoreMaven/Phiture primary reports could not be fetched (DNS blocked).

## 5. Health & Fitness / quit-habit category specifics

### Takeaway
There is little category-specific screenshot evidence. Health & Fitness conversion benchmarks vary widely by vendor and methodology, and I found no quit-smoking screenshot study.

### Cited Findings
- SplitMetrics reports a Health & Fitness median page-view-to-install CVR of 18.52%, ranging from 0.94% to 57.68% (older dataset). An aggregator reports AppTweak's panel at 30.8% for H&F. Methodologies differ. — [SplitMetrics benchmarks](https://splitmetrics.com/blog/whats-a-good-app-store-page-conversion-rate/), [appscreenshotstudio benchmarks](https://appscreenshotstudio.com/app-store-conversion-benchmarks)
- One third-party source says that in H&F "video is expected". This is an unsupported assertion. — [search summary](https://splitmetrics.com/?p=19564)
- AppTweak publishes an ASO Trends & Benchmarks Report 2025, including CPP and screenshot testing benchmarks; it was not retrieved. — [AppTweak](https://www.apptweak.com/aso-blog/aso-trends-benchmarks-report-2025)

### Inferences
- In the absence of category data, use PPO on DayXero's own traffic. Benchmark against competitor sets (QuitSure, Smoke Free, Quit Vaping, etc.), which another workstream may cover.

### Gaps
- No quit-nicotine or habit-category screenshot A/B data was found.

## 6. Google Play phone-screenshot specs and policy (brief)

### Takeaway
Play phone screenshots: 2 to 8 images, JPEG or 24-bit PNG (no alpha), each side between 320 and 3840 px, aspect ratio no more extreme than 2:1. Use 1080 x 1920 (9:16) or larger for featuring eligibility. The feature graphic is 1024 x 500. Play policy forbids ranking or performance claims, price or promo text and CTAs in listing graphics. Official pages could not be fetched; the specs below come from consistent secondary sources.

### Cited Findings
- **Phone screenshots:** minimum 2, maximum 8. Short side at least 320 px, long side at most 3840 px, aspect ratio between 1:2 and 2:1. 1080 x 1920 is recommended. — [Adalo](https://studio.adalo.com/blog/google-play-screenshot-sizes), [AppStills](https://www.appstills.com/guides/google-play-screenshot-sizes), [CatDoes](https://catdoes.com/blog/play-store-screenshot-size) (secondary; official source is Play Console Help answer 9866151, not fetchable here)
- **Featuring:** at least 4 screenshots at a minimum of 1080 px on the short side are recommended for featured or promotional placements. — [secondary summary](https://screenhance.com/blog/google-play-screenshot-dimensions-2026)
- **Feature graphic:** exactly 1024 x 500, JPEG or 24-bit PNG, no alpha. Required to publish. Transparency is a common rejection reason. — [Adalo](https://studio.adalo.com/blog/google-play-screenshot-sizes), [LaunchShots](https://www.launchshots.com/blog/google-play-feature-graphic)
- **Icon** is 512 x 512. **Video** is a YouTube URL (optional). — [Adalo](https://studio.adalo.com/blog/google-play-screenshot-sizes)
- **Policy:**
  - Listing text, icon and screenshots must accurately reflect app functionality. — [Google Play, Deceptive Behavior policy](https://play.google.com/about/privacy-security-deception/deceptive-behavior/deceptive-settings/)
  - Graphics and screenshots should not include store-performance or ranking claims ("top", "#1", "best"), accolades, price or promotional info, or calls to action ("Download now", "Install now", "Try now"). — [ScreenshotBro](https://screenshotbro.app/blog/google-play-screenshot-rejected-fix), [AppSubmitter](https://www.appsubmitter.io/app-rejection-guides/google-play-metadata-policy/), [ASOWorld](https://asoworld.com/blog/how-to-prepare-for-new-google-play-metadata-policy-changes/) (secondary)
  - Each custom store listing and experiment variant is reviewed separately. — [secondary summary](https://playaudit.app/blog/google-play-listing-requirements)

### Inferences
- Re-crop the iOS designs to 1080 x 1920 or 1242 x 2208-class 9:16 canvases. iOS 1320 x 2868 is about 1:2.17, which **exceeds Play's 2:1 limit**, so the iOS files cannot be reused as-is. Choose the 8 strongest of the 10 and drop the iOS device frames and Apple-specific UI per platform-focus norms.
- Use Play Store Listing Experiments (Google's A/B tool) as the PPO equivalent.

### Gaps
- Could not fetch official Play Console Help (answer 9866151) or the Play Metadata policy page to quote verbatim; dimensions and policy wording should be checked there before upload.
