# Waitlist and Beta Signups for a Pre-Launch iOS Quit-Nicotine App (DayXero)

Research date: 2026-10-29. Many benchmarks come from waitlist and email vendors that sell the products they describe, and the numbers are flagged where that applies. About 16 tool calls were used. Several areas, including nurture cadence and health-app case studies, rely on inference and are noted as gaps.

## 1. Waitlist vs TestFlight public beta vs App Store pre-order

### Takeaway
Use all three in sequence. Run an email waitlist now, because it is the only one you can start today with no build. Open a TestFlight public link once a build passes Beta App Review, to grow an engaged group of up to 10,000 testers. Switch on an App Store pre-order 2–180 days before launch so pre-orderers get the app auto-installed on release day. A pre-order only works if you already have an audience to send to the listing, and moving the release date later cancels every pre-order.

### Cited Findings
- **TestFlight limits:** up to 10,000 external testers and 100 internal testers (internal testers need an Account Holder, Admin, App Manager, Developer or Marketing role). You can share up to 100 builds, and each tester can install on up to 30 devices. — [Apple TestFlight](https://developer.apple.com/testflight/)
- **TestFlight public link:** you can set criteria such as device type and OS version, and disable the link once you hit your tester limit. App Store Connect shows how many people viewed the link, installed, and met your criteria. — [Apple TestFlight](https://developer.apple.com/testflight/)
- **TestFlight requirements:** external testing needs a beta app description, beta review information and a feedback email. The first build must be approved by App Review for TestFlight, and builds added to external groups go to review automatically. — [Apple TestFlight](https://developer.apple.com/testflight/)
- **Guideline 2.2:** "Demos, betas, and trial versions of your app don't belong on the App Store – use TestFlight instead… apps using TestFlight cannot be distributed to testers in exchange for compensation of any kind." This matters for beta perks. — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **Pre-order guidelines:** "Submissions to App Review, including apps you make available for pre-order, should be final versions with all necessary metadata and fully functional URLs" (2.1a). "Apps you submit for pre-order… must be complete and deliverable as submitted… If you make material changes to the app (such as changing business models), you should restart your pre-order sales" (2.3.11). — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **Pre-order mechanics** (secondary source):
  - The window runs 2–180 days, and the product page is live and searchable during it.
  - Customers are charged, and the app downloads automatically, on release day.
  - The final binary must be approved at least 24 hours before release.
  - Moving the release date earlier is allowed. Moving it later forces a cancellation, and all orders are lost.
  — [AppsOps blog](https://appsops.store/blog/app-store-preorder-pricing-strategy)
- **Pre-orders for free apps** (secondary source): a free app with a subscription can run a pre-order, with no charge at pre-order time, so you build an install base that meets the paywall on day one. The source rates "Free + introductory offer (trial)" as "strong", and the intro offer must be configured before the pre-order goes live. — [AppsOps blog](https://appsops.store/blog/app-store-preorder-pricing-strategy)
- **Pre-order downsides:** the page can sit empty if you have no audience, the release date cannot slip, metadata edits during the window can cause review delays, and metadata must be final and localized. — [AppsOps blog](https://appsops.store/blog/app-store-preorder-pricing-strategy)
- **Pre-order analytics:** App Store Connect Analytics reports net pre-orders (pre-orders minus cancellations), pre-order conversion rate, and downloads that came from pre-orders. — [App Store Connect Analytics Help: Pre-orders](https://developer.apple.com/help/app-store-connect-analytics/acquisition/pre-orders)
- **Ranking effect:** concentrating installs on release day creates download velocity, which ranking algorithms are said to weight heavily. Appfigures estimated almost half a million launch-day downloads for Apple Music Classical, which hit #1, and attributed that to pre-orders. All Appfigures numbers are estimates and come from a big-brand case. Another guide calls the keyword-ranking boost an "unproven hypothesis". — [Appfigures](https://appfigures.com/resources/insights/20230421/2-apple-music-classical-hit-a-milestone-but-is-there-real-demand); [AppsOps blog](https://appsops.store/blog/app-store-preorder-pricing-strategy)
- **Pre-order window history:** when pre-orders launched in 2017 the window was up to 90 days. It is now up to 180 days. — [TechCrunch 2017](https://techcrunch.com/?p=1577084); [AppsOps](https://appsops.store/blog/app-store-preorder-pricing-strategy)

### Inferences
- **How each path converts on launch day:**
  - Pre-order converts best, because the app installs itself.
  - TestFlight testers are already installed, but they move to the App Store build by hand. You need an in-app or TestFlight "What to Test" note plus an email with the App Store link. TestFlight installs do not count as App Store downloads for ranking.
  - Email waitlist converts worst, because each person must open the email, click and install.
- **Recommended sequence for DayXero:**
  1. Waitlist on dayxero.in now.
  2. At launch minus 6–8 weeks, open a TestFlight public link for a capped cohort, for example 200–1,000 testers. Offer it to waitlist members first, and frame it as a privilege.
  3. At launch minus 2–4 weeks, start the pre-order once the binary is final. Email the list a "pre-order now: it installs automatically on day X" message. This turns email clicks into installs before launch day and moves the installs onto release day for velocity.
  4. Pick a pre-order release date with slack, because moving it later kills all orders.
- **Pricing caution:** DayXero is free with in-app purchases ($9.99/mo, $39.99/yr, $79.99 lifetime), so a pre-order does not charge anyone. Founding-member pricing would need to be delivered through App Store intro or promotional offers, or offer codes, not through the pre-order price.

### Gaps
- I could not fetch Apple's own pre-order help page (the URL returned 404), so the 180-day and 24-hour details come from a secondary source.
- I found no indie-scale data on what share of pre-orderers become active users.
- The current TestFlight build expiry was not confirmed on the page fetched. It is 90 days per Apple docs from background knowledge, but this was not verified here.

## 2. Free email-capture tools for a static site on Cloudflare (as of 2026)

### Takeaway
Free email-marketing tiers were cut sharply in 2026. MailerLite dropped to 250 subscribers, and Kit reportedly removed automations from its free plan. The most robust $0 setup is to store signups yourself in Cloudflare D1 (or KV) through a Worker, so you own the list with no subscriber cap. Then send through a tool with a generous free tier: Kit for a large list with broadcasts only, or Brevo, Sender, EmailOctopus or Loops for automations. Hosted waitlist tools like LaunchList, Waitlister, GetWaitlist and Prefinery give you only about 100–250 contacts free, or nothing at all.

### Cited Findings
- **Cloudflare D1 free plan:**
  - 100,000 rows written per day, 5 million rows read per day, and 5 GB storage. Limits reset at 00:00 UTC.
  - Since 1 Sep 2026, queries fail once you exceed these limits on Workers Free.
  - The common 100,000 requests/day figure applies to Workers requests, not D1.
  — [Cloudflare D1 pricing](https://developers.cloudflare.com/d1/platform/pricing/); [Cloudflare changelog 2026-09-01](https://developers.cloudflare.com/changelog/post/2026-09-01-d1-free-tier-limit-enforcement/)
- **Free tiers verified September 2026**, from [Sequenzy (updated 2026-09-03)](https://www.sequenzy.com/blog/best-email-tools-with-free-tier). This is a third-party comparison, so check vendor pages before relying on it.

  | Tool | Free contacts | Free sends | Automations | Notes |
  |---|---|---|---|---|
  | Kit (ConvertKit) | 10,000 | Unlimited broadcasts | Conflicting: one automation vs none | Kit branding |
  | MailerLite | 250 (cut 16 Jun 2026 from 1,000) | 2,500/month | 3 (from 13 Aug 2026) | 3 forms, 1 landing page cap |
  | Buttondown | 100 | Not stated | None | |
  | Loops | 1,000 | Not stated (another page says 2,000/month) | Basic | |
  | Beehiiv | 2,500 | Unlimited | Not stated | Branding; custom domain is paid |
  | Brevo | Unlimited | 300/day (about 9,000/month) | Basic workflows | Brevo branding |
  | Sender | 2,500 | 15,000/month | Full | |
  | EmailOctopus | 2,500 | 10,000/month | Basic | |
  | Resend | Transactional only | 3,000/month, 100/day | None for marketing | No branding |

- **MailerLite cut:** sending stops once a free list goes over 250. — [Dreamlit](https://dreamlit.ai/blog/best-mailerlite-alternatives)
- **Kit automations:** reportedly removed from the free plan in September 2026, which leaves broadcasts only. An earlier source said one automation was allowed. — [EmailToolTester](https://www.emailtooltester.com/en/blog/free-email-marketing-services/); [Mailsoftly](https://mailsoftly.com/blog/kit-free-plan/)
- **Waitlister:** free plan capped at 100 subscribers, paid from $19/month. — [Waitlister pricing](https://waitlister.me/pricing)
- **GetWaitlist:** no free tier for new accounts. Basic is $15/month with a 7-day trial. — [GetWaitlist pricing](https://getwaitlist.com/pricing); [Lighthouse](https://lighthouse.build/blog/best-waitlist-tools)
- **LaunchList:** free for the first 100 contacts per its own pages. KickoffLabs reports a 250-contact v2 free tier, and legacy one-time pricing was about $19. — [LaunchList](https://getlaunchlist.com/); [KickoffLabs](https://kickofflabs.com/blog/prelaunch-waitlist-software/); [GetWaitly comparison](https://getwaitly.com/blog/launchlist-vs-getwaitly)
- **Prefinery:** no free plan, only a 14-day trial. Paid is about $39–49/month. — [LaunchList comparison](https://getlaunchlist.com/blog/best-prefinery-alternatives-2026); [Convika](https://convika.com/compare/best-free-waitlist-tools/)

### Inferences
- **Recommended $0 stack for dayxero.in:**
  1. Put a `POST /api/subscribe` route on the existing Worker that validates the email, adds a honeypot field plus Cloudflare Turnstile (free), and inserts into a D1 table: email, created_at, source/UTM, referrer code, consent flag, confirmed_at. A KV `put` keyed by email is a simpler alternative.
  2. Send the double-opt-in confirmation through Resend's free tier (3,000/month, 100/day). Confirm the domain with SPF, DKIM and DMARC on dayxero.in.
  3. Periodically sync confirmed contacts to Kit (10k free, broadcasts) or Brevo (unlimited contacts, 300/day) for nurture broadcasts.
- **Daily cap:** Resend's 100/day limit and Brevo's 300/day limit will bottleneck a launch-day blast to a list of several thousand. You would need to stagger the send across days, upgrade for one month, or use Kit (unlimited broadcasts) for the launch email.
- **Avoid MailerLite and Buttondown free plans:** at 250 and 100 contacts they are too small for a launch list.
- **Avoid hosted waitlist tools:** their 100-contact caps mean you outgrow them almost immediately. You can build the referral "move up the line" logic yourself in the Worker and D1.

### Gaps
- No Formspree free-tier figure was found in these sources. From background knowledge it is roughly 50 submissions/month, which was not verified.
- Kit's automation status is conflicting, so verify it at kit.com/pricing.
- Loops' free send limit is unclear.

## 3. Referral / viral waitlists (Robinhood, Dropbox, Harry's, Superhuman style)

### Takeaway
Referral waitlists usually amplify a list modestly: a K-factor of 0.2–0.6, meaning 20–60 extra signups per 100. Big successes like Robinhood's roughly 1M came from products with inherent social or financial hype. For a quit-nicotine app, referral is plausible because quitting with a buddy is a known motivator. But stigma and privacy reduce public sharing, so frame referrals as "quit with a friend" rather than "move up the line" alone.

### Cited Findings
- **Referral benchmarks** (vendor source, LaunchList, unverified):
  - "Most pre-launch waitlists land somewhere between K=0.2 and K=0.6." A K above 1.0 is rare.
  - A share rate under 20% means the confirmation experience needs work.
  - Fewer than 0.3 average referrals per subscriber means the reward tiers are weak.
  - A 10-point gain in share rate moves growth more than a 10-point gain in conversion rate.
  — [LaunchList referral guide](https://getlaunchlist.com/blog/waitlist-referral-program-guide)
- **Reward ladder pattern:** start with rewards that cost nothing to deliver (queue jumps, early access), add digital rewards at 3–5 referrals, and save costly rewards for top tiers. The example SaaS ladder has tiers at 1, 3, 5, 10, 25 and 50 referrals. — [LaunchList referral guide](https://getlaunchlist.com/blog/waitlist-referral-program-guide)
- **Fraud controls** (LaunchList defaults): cap credited referrals at 3 per IP and 20 per hour, flag 3 or more signups per device fingerprint, and credit a referral only after the friend verifies their email. — [LaunchList referral guide](https://getlaunchlist.com/blog/waitlist-referral-program-guide)
- **Robinhood:** close to 1M pre-launch waitlist signups through a position-based queue, where sharing moved you up the list, with no monetary reward. The commonly reported curve is 10,000 on day 1, 50,000 in week 1 and about 1M in year 1. All of this comes from secondary or vendor write-ups, not a primary disclosure. — [Viral Loops](https://viral-loops.com/blog/how-robinhood-got-1-million-users/); [Prefinery](https://www.prefinery.com/blog/referral-programs/prelaunch-campaign/robinhood/)
- **Harry's:** "reportedly" about 100k emails in one week through tiered physical rewards (5 referrals for shaving cream, 50 for a year of blades). Unverified. — [LaunchList referral guide](https://getlaunchlist.com/blog/waitlist-referral-program-guide)
- **Dropbox:** referrals gave about a 60% lift in signups, and users grew from about 100k to 4M in 15 months. The reward was 500 MB for both sides, capped at 16 GB. — [LaunchList referral guide](https://getlaunchlist.com/blog/waitlist-referral-program-guide)
- **Counterpoint:** a Medium essay argues startups should "think twice" about referral-priority waitlists. — [Laurens de Bo, Medium](https://medium.com/@laurensdebo/why-startups-should-think-twice-about-referral-priority-waitlists-f4dca1e1a1a2)

### Inferences
- **"Move up the line" is weak for DayXero:** access order means nothing when the App Store release is open to everyone on day one. Better rewards cost nothing to deliver:
  - Earlier TestFlight access.
  - Extra founding-member months.
  - A "Quit Buddy" pairing feature at launch.
  - A badge or founding-member status in the app.
- **Two-sided "quit together" invite:** this fits the health category. Many quitters want accountability, and both sides get the perk.
- **Apple constraints:**
  - Referral rewards must not be TestFlight access sold for compensation (Guideline 2.2).
  - In-app referral mechanics must not force store actions (3.2.2(x)).
  - Digital unlocks inside the app must go through in-app purchase or offer codes (3.1.1).
  — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **Realistic expectation:** for a no-budget health app, treat referrals as a +10–30% list multiplier, below the vendor K range because of stigma. Do not plan around virality.

### Gaps
- No health, habit or quit-app-specific referral waitlist case study with numbers was found.
- No Monzo or Superhuman figures were found in the fetched sources.

## 4. Landing-page conversion benchmarks and form design

### Takeaway
The median landing page converts about 6.6% of visitors (Unbounce, 2024, all industries). Waitlist pages with warm traffic report 15–45% and cold traffic 10–20% in vendor sources. A single email field, a CTA above the fold that is repeated, and one clear goal are the standard conversion patterns.

### Cited Findings
- **Unbounce median:** 6.6% across about 57M conversions on about 41,000 landing pages (2024 report). The figure is a median, not an average. Financial services sits at 8.4% and SaaS at 3.8%. — [Search Engine Land](https://searchengineland.com/how-does-your-landing-page-performance-compare-453224); [MarketingProfs 2024](https://marketingprofs.com/charts/2024/52374/landing-page-conversion-benchmarks)
- **Unbounce 2020:** median 3.2%, with a top-quartile median of 25%. This is older data. — [Unbounce 2020](https://unbounce.com/conversion-benchmark-report-2020/)
- **Waitlist signup benchmarks** (vendor sources that conflict):
  - Warm traffic 15–35%, or warm 25–45% / cold 10–20% / paid ads 3–10%.
  - Another source gives an "average waitlist conversion 2–5%, top 10–15%".
  - Consumer apps convert 4–8% (attributed to GetWaitlist).
  — [LaunchList blog](https://app.getlaunchlist.com/blog/why-is-my-waitlist-not-converting); [Flowjam calculator](https://www.flowjam.com/blog/waitlist-conversion-calculator); [Medium, Zamudio](https://medium.com/@soyzamudio/maximizing-waitlist-conversion-rates-data-driven-strategies-6856cb91f83b); [Mean CEO](https://blog.mean.ceo/?p=11219)
- **Cautionary data point:** one Indie Hackers founder reported 4,500 waitlist signups and converted only 5 into paying customers. — [Indie Hackers](https://www.indiehackers.com/post/does-wait-lists-still-work-in-2024-06c78d5754)

### Inferences
- **Form design for dayxero.in:**
  - One email field plus a button, with no name field. Put an optional "What are you quitting?" picker (cigarettes / vape / pouches) on the thank-you step, which lets you segment the nurture emails without adding friction.
  - CTA copy that states the outcome ("Get early access + founding price"), not "Submit".
  - Place the form in the hero and repeat it after features, pricing and FAQ. Add a sticky bottom CTA on mobile.
  - Show the prices ($9.99 / $39.99 / $79.99) next to the founding-member discount, so the incentive is concrete.
  - Put a privacy microcopy line under the field ("No spam. No selling your data. Unsubscribe anytime.").
  - Use exit intent on desktop only. It barely applies on mobile.
- **Targets:** benchmark against a 6.6% median. Aim for 15%+ from warm or organic-community traffic (Reddit r/QuitVaping, r/stopsmoking, TikTok). Track signups by source with UTM parameters stored in D1.

### Gaps
- No health or wellness industry-specific Unbounce median was found in the results.
- No controlled A/B data was found for sticky CTA or exit intent on waitlist pages specifically.

## 5. Incentives appropriate for a quit app

### Takeaway
The best incentives cost nothing to deliver and match the app's job:
- Founding-member pricing, delivered through App Store intro or promotional offers or offer codes.
- Early TestFlight access, offered free and not as compensation.
- A lead magnet that starts the quit journey before the app exists, such as a 7-day quit-prep email course or a craving toolkit PDF.

### Cited Findings
- **TestFlight access cannot be exchanged for compensation**, so perks should be framed as invitations, not payment. — [App Review Guidelines 2.2](https://developer.apple.com/app-store/review/guidelines/)
- **Digital unlocks must use in-app purchase** ("If you want to unlock features or functionality within your app… you must use in-app purchase"). Founding discounts therefore need Apple's own offer mechanisms. — [App Review Guidelines 3.1.1](https://developer.apple.com/app-store/review/guidelines/)
- **Pre-order with a free intro offer is "strong"**, and the intro offer must be configured before the pre-order goes live. — [AppsOps blog](https://appsops.store/blog/app-store-preorder-pricing-strategy)
- **Discount cohorts:** Phiture research, as cited by AppsOps, suggests discounted launch cohorts show weaker second-month retention than full-price cohorts. This is secondary. — [AppsOps blog](https://appsops.store/blog/app-store-preorder-pricing-strategy)

### Inferences
- **Incentive menu, in priority order:**
  1. **Founding member offer:** for example, 50% off the first year ($19.99 instead of $39.99) via an intro offer or offer codes. For a lifetime-for-founders deal, offer codes can only grant subscription durations or free in-app purchases. Cap it, for example "first 500", for scarcity.
  2. **Lead magnet:** a "7-Day Quit Prep Plan" as an email course delivered by the nurture sequence. It doubles as warm-list content and creates habit and trust before launch. Alternative: a one-page "Craving SOS toolkit" PDF (urge-surfing, the 4 Ds, trigger log).
  3. **Early TestFlight access** for the first N signups.
  4. **Founder badge or name** in the app credits.
- **Lead magnet compliance:** keep it behavioral and educational, avoid efficacy claims (see section 7), and recommend talking to a doctor about nicotine replacement therapy (NRT).
- **Retention risk:** given the Phiture finding, prefer a free trial or a bonus month over a deep permanent discount, or keep the discount limited to the first year.

### Gaps
- No quit-app-specific A/B evidence on which incentive converts best was found.
- The exact offer-code constraints for lifetime purchases were not verified in this session, so check App Store Connect offer-code docs.

## 6. Nurture sequence, deliverability, compliance, and waitlist-to-install conversion

### Takeaway
Plan for only about 25–60% of engaged or qualified waitlist members to install at launch. For a raw, unconfirmed email list, expect far less. A double opt-in, a short welcome sequence, then roughly biweekly progress emails keep the list warm. Gmail and Yahoo require SPF, DKIM and DMARC, one-click unsubscribe, and a spam rate under 0.3%.

### Cited Findings
- **Install rate:** one vendor estimate puts "qualified responder → installed at launch" at 25–60%. Its "qualified" means people who passed a survey-style filter, so it is not a plain email list. — [Semnexus](https://semnexus.com/the-pre-launch-waitlist-playbook-for-mobile-apps/)
- **Low-end example:** 4,500 signups produced 5 paying customers. — [Indie Hackers](https://www.indiehackers.com/post/does-wait-lists-still-work-in-2024-06c78d5754)
- **Critical take:** Stormy.ai argues that app waitlists are poor validation signals on their own. — [Stormy.ai](https://stormy.ai/blog/why-app-waitlists-are-useless-app-validation-framework)
- **Gmail/Yahoo sender rules:**
  - SPF, DKIM and DMARC for bulk senders, commonly defined as 5,000+ messages per day to Gmail.
  - One-click unsubscribe (RFC 8058) on marketing mail, with opt-outs honored within 2 days.
  - Spam complaint rate under 0.3%, ideally about 0.1%. Monitor it in Google Postmaster Tools.
  — [Customer.io](https://customer.io/learn/deliverability/email-sending-requirements-gmail-yahoo); [Resend](https://www.resend.com/blog/gmail-and-yahoo-bulk-sending-requirements-for-2024); [Bird](https://bird.com/docs/knowledge-base/deliverability/gmail-yahoo-requirements)
- **Health data marketing limit:** "Apps may not use or disclose to third parties data gathered in the health, fitness, and medical research context… for advertising, marketing…" (5.1.3(i)). This applies to in-app data, so do not later feed in-app quit data into marketing email targeting without care. — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### Inferences
- **Suggested sequence:**
  1. Day 0: confirmation email (double opt-in).
  2. Day 0: welcome, plus "what are you quitting?" and a referral link.
  3. Days 1–7: the 7-day quit-prep course, one email a day, only for people who opt into the course.
  4. Then every 2–3 weeks: build-in-public updates such as screenshots, a TestFlight invite, a founder story or a craving tip.
  5. Launch minus 14 days: pre-order link.
  6. Launch day: "It's live" with the App Store link and the founding-offer code.
  7. Launch +2 days: reminder to people who did not click.
  8. Launch +7 days: last call for the founding price.
- **Why double opt-in:** it shrinks the list but raises install conversion and protects deliverability. It matters especially when signups come from Reddit or TikTok bursts, where typos and bots are common.
- **Keeping the list warm:**
  - Send at least monthly, because a list left silent for 3+ months spikes complaints at launch.
  - Send from a real person ("Founder at DayXero"), plain-text style, and ask for replies. Replies improve inbox placement.
  - Use a sending subdomain (for example, mail.dayxero.in) with SPF, DKIM and DMARC.
- **CAN-SPAM basics** (US, background knowledge; not fetched this session, so verify against the FTC CAN-SPAM compliance guide):
  - Use accurate From and Subject lines.
  - Include a physical postal address. A PO box or virtual mailbox is acceptable.
  - Include a clear opt-out and honor it within 10 business days.
- **GDPR basics** (EU/UK, background knowledge):
  - Get explicit consent with an unticked checkbox or clear statement.
  - Record when and how consent was given (store it in D1).
  - Link a privacy policy at the point of capture.
  - Delete data on request.
- **Planning numbers:** for 1,000 confirmed subscribers, a realistic launch-week install estimate is about 150–400 (15–40%), between the Semnexus qualified range and the cautionary Indie Hackers anecdote. This is an inference, not a sourced benchmark.

### Gaps
- No rigorous, independent benchmark for email-waitlist-to-App-Store-install conversion was found. All figures are vendor estimates or anecdotes.
- No sourced data on optimal pre-launch email cadence was found.
- The CAN-SPAM and GDPR specifics were not fetched from primary sources this session.

## 7. Health-specific considerations (privacy, medical claims, Apple guidelines)

### Takeaway
DayXero's marketing and listing must:
- Avoid unsubstantiated efficacy claims. The FTC requires "competent and reliable scientific evidence" for smoking-cessation claims.
- Include a "consult your doctor" reminder, especially around NRT tapering (Guideline 1.4.1).
- Never appear to encourage nicotine use or sell nicotine products (1.4.3).
- Lead with privacy, because health data cannot be used for marketing (5.1.3).

### Cited Findings
- **Guideline 1.4.1:** "Medical apps that could provide inaccurate data or information, or that could be used for diagnosing or treating patients may be reviewed with greater scrutiny… Apps should remind users to check with a doctor in addition to using the app and before making medical decisions." — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **Guideline 1.4.3:** "Apps that encourage consumption of tobacco and vape products… are not permitted… Facilitating the sale of… tobacco is not allowed." — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **Guideline 2.3.8:** metadata, including icons and screenshots, must suit a 4+ age rating. Avoid cigarette or vape imagery that glamorizes use. — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **Guideline 2.3.1(a):** misleading marketing about features the app does not offer is grounds for removal. — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **Privacy guidelines:**
  - A privacy policy link is required in metadata and in the app (5.1.1(i)).
  - Accounts require in-app account deletion (5.1.1(v)).
  - Third-party AI data sharing needs explicit disclosure and permission (5.1.2(i)).
  — [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- **FTC precedent:**
  - Smoking-cessation orders (Emerson Direct / De Blasio, PhaseOut) bar efficacy claims for "any smoking cessation product or program" without competent and reliable scientific evidence.
  - The FTC applied the same standard to apps in its 2015 melanoma-app settlements.
  - A more recent STI-detection app case ended with the app terminated and refunds.
  — [FTC Emerson Direct order](https://www.ftc.gov/sites/default/files/documents/cases/2005/08/050823stipdeblasioemerson.pdf); [FTC PhaseOut](https://www.ftc.gov/sites/default/files/documents/federal_register_notices/phaseout-america-inc.products-patents-ltd.analysis-aid-public-comment/961205phaseoutofamerica.pdf); [Mintz 2017](https://www.mintz.com/2017/10/10/building-health-app-part-4-avoiding-ftc-enforcement-action/); [Mondaq](https://www.mondaq.com/unitedstates/advertising-marketing-branding/1495088/ai-powered-detection-app-gets-ftc-scrutiny)

### Inferences
- **Copy to avoid:** "X times more likely to quit", "clinically proven", and "cures addiction", unless DayXero has its own study.
- **Copy that is safe:** cite established public-health facts with attribution, such as CDC or NHS facts on the health benefits of quitting. Use descriptive feature claims like "track your nicotine taper", "craving tools", and "money saved counter".
- **NRT tapering wording:** describe it as "helps you follow a taper plan you set with your doctor or pharmacist", not as dosing advice. Add a disclaimer on the site and in the app.
- **Privacy as a conversion lever:** quitters often hide their use, so a privacy promise near the form ("We never sell or share your data. No ads.") can lift signups. Keep the promise true and consistent with the App Store privacy label.
- **No commerce links:** do not link to NRT or nicotine product retailers or affiliates from the app (1.4.3 risk). On the website, keep it educational.
- **Age gating:** consider a 17+/18+ statement in the waitlist form. Nicotine topics and a marketing list aimed at adults avoid COPPA issues with under-13s.

### Gaps
- I found no FTC action against a quit-smoking app specifically. The precedents are older product cases and general health-app cases.
- I did not determine whether NRT-tapering features would trigger FDA "device" or clinical-decision-support considerations, which need a separate regulatory check.
