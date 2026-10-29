# DayXero pre-launch website changes: waitlist and beta signups, with mockups

Scope: what to change on dayxero.in so visitors join a pre-launch waitlist or beta instead of hitting dead-end "buy" buttons. Covers an audit of the current site, best-practice evidence, a change table with HTML mockups and screenshots, and a $0 backend spec. Nothing under `website/` or `scripts/` was modified. All output is under `research_notes/DayXero prelaunch waitlist marketing/`.

## Q1. What does the current site say, where does each CTA go, and what implies the app is already live?

### Takeaway
The site has no email capture anywhere. Every buy-intent click (nav "Get DayXero", the three plan buttons, the guide-page CTAs) ends at `#pricing` or at a toast reading "Ready for App Store Checkout". A lot of the copy, plus the JSON-LD `offers`, talks about the app as if it were already downloadable. Several lines also make medical or efficacy claims that a pre-launch app can't back up.

### Cited Findings
**Structure of the homepage** ([website/index.html](../../website/index.html), 1,939 lines): fixed pill nav, then Hero (`#hero`), Showcase dual-pane plus moss pedestal (`#showcase`), phone simulator (`#interactive-preview`), Methodology with 4 pillars (`#methodology`), Breath chamber (`#breath-chamber`), Recovery timeline (`#recovery-timeline`), Calculator (`#calculator`), Pricing (`#pricing`), FAQ (`#faq`), Guides (`#guides`) and the footer.

**Every CTA and where it goes** (source: `website/index.html` line numbers):

| # | Location | Label | Destination / behaviour today |
|---|---|---|---|
| 1 | Nav, L256 | "Get DayXero →" (sage pill) | `#pricing` |
| 2 | Nav links, L239-245 | Showcase, Methodology, **"Live App"**, Urge Surfing, Timeline, Calculator, Pricing | in-page anchors ("Live App" means the simulator, but it reads as "the app is live") |
| 3 | Nav, L251 | Sound toggle | 432 Hz synth plus toast |
| 4 | Showcase white pane, L340 | "Explore Program" (black pill) | `#interactive-preview` |
| 5 | Moss pedestal, L465-476 | 4 white icon buttons | no action (decorative) |
| 6 | Phone simulator, L499-839 | product chips, "Start Today's Lesson", "It Passed", "I Slipped", dock tabs | demo toasts ("Victory Logged! (+1 Smoke-Free Day Recorded)") |
| 7 | Breath chamber, L962-966 | "Start Surfing Session", "Reset" | working demo |
| 8 | Calculator, L1107 | "Pledge to Keep This Capital" | toast "Capital Pledge Recorded! Vault Updated." (L1903). Nothing is recorded: a dead end at a high-intent moment |
| 9 | Pricing, L1149/1174/1193 | "Select Monthly", "Start 3-Day Free Trial", "Get Lifetime" | toast `Selected ${plan} Plan. Ready for App Store Checkout.` (L1911) |
| 10 | Guides grid, L1251-1277 | 5 guide cards plus "All guides →" | guide pages |
| 11 | Footer, L1299-1313 | Back to top, Showcase, Philosophy, Live App, Breath Pacer, **"Subscription Plans"**, FAQ, guides, About, Contact, Privacy, Terms | anchors and pages |
| 12 | Guide pages nav ([build_guides.py](../../scripts/website/build_guides.py) L452; e.g. [quit-vaping](../../website/quit-vaping/index.html)) | "Get DayXero" | `/#pricing` |
| 13 | Guide pages end aside ("The DayXero app") | "See plans, free tier included →" | `/#pricing` |

**Hero copy today** (L271-287): pill "2026 Native iOS Protocol | Don't quit today. Quit on your Quit Day."; H1 "Quit Nicotine on Your Quit Day."; subhead "The iPhone app to quit vaping, smoking and nicotine pouches. A five-day prep phase…". Below that sits a colour-palette strip (White / White Green / Dark Green / Black hex chips), which is where the hero CTA should go.

**Copy that implies the app is available now** (source: `website/index.html` unless noted):
- Toast "Ready for App Store Checkout" (L1911). The plan buttons "Start 3-Day Free Trial" and "Get Lifetime" (L1175, L1194).
- "The base DayXero download includes the core counter…" (L1201).
- FAQ "Is DayXero free?" ("The free version includes…") and "Can I cancel my DayXero subscription easily?" (L1231-1237), duplicated in the FAQPage JSON-LD (L124-139).
- JSON-LD `MobileApplication` with four `Offer`s and prices (L51-88). This tells search engines there's a purchasable app.
- Nav and footer labels "Live App" and "Subscription Plans". Footer "© 2026 DayXero. Local-first & Private."
- Phone-simulator toasts such as "Victory Logged!". These are fine as an interactive demo, but the section heading "Experience DayXero Native in Hand" (L491) should say it's a preview.
- Guide pages: "DayXero's Craving SOS walks you through this in three minutes", plus the "See plans, free tier included" CTA ([quit-vaping/index.html](../../website/quit-vaping/index.html)).
- Privacy policy describes a live app: "Apple processes all payments… RevenueCat…". It also says "The website sets no cookies" and has no section on email collection ([privacy/index.html](../../website/privacy/index.html) L100-111). It will need a waitlist section.

**Medical or efficacy claims to soften before driving traffic** (source: `website/index.html`):
- L329-336 "CLINICALLY FORMULATED" and "Premature quitting leads to 95% relapse. DayXero prepares your neurochemistry…"
- L412 "Engineered to support neurochemical stabilization, focus, cardiovascular health, and long-term nicotine independence…"
- L438-439 bottle "Daily Formula / Nicotine Recovery". This looks like a supplement product and could confuse visitors.
- L855-861 "CLINICAL ARCHITECTURE" and "Stand-alone counter apps barely alter long-term quit rates".
- L876 "Abrupt cold-turkey quit attempts create immediate anxiety and executive dysfunction"
- L933 "down-regulate your sympathetic nervous system"; L985 "witness how your… systems heal"; L1019 "Nicotine is 100% eliminated from bodily tissues"; L794 "Verified clinical milestones".
- The FTC's Health Products Compliance Guidance (Dec 2022) explicitly covers "health-related apps". It expects efficacy claims to be backed by "competent and reliable scientific evidence", generally RCTs. — [Jones Day summary](https://jonesday.com/pt/insights/2023/01/ftc-overhauls-and-expands-25yearold-health-products-advertising-compliance-guide); [Covington / Inside Privacy](https://www.insideprivacy.com/health-privacy/ftc-issues-new-guidance-regarding-health-products/)

**Design system the mockups had to reuse** ([docs/DESIGN_METHODOLOGY.md](../../docs/DESIGN_METHODOLOGY.md), [website/tailwind.css](../../website/tailwind.css), [website/tailwind.config.js](../../website/tailwind.config.js)):
- Black canvas, sage `#BCC388`, moss `#43511C`, surfaces `#121212` / `#161616`.
- Pill buttons; cards with 28-36px radius (`rounded-card` = 32px).
- Components `.porcelain-card` and `.dark-card`. `.glass-card-green` and `.moss-pedestal` are defined only in index.html's inline `<style>`.
- Inputs per spec 4.6: `#161616`, hairline border, sage focus `rgba(188,195,136,0.6)`, placeholder at 30% white.
- Inter plus JetBrains Mono.

### Inferences
- The highest-intent click on the site (a plan button) currently converts at zero. Turning those clicks into email capture is the biggest single change.
- The calculator "Pledge" button is a second high-intent dead end. It's a good place for "Email me when DayXero launches" (same form component; table row 8).
- Removing or softening the medical claims matters more once paid or social traffic arrives. This is a compliance and trust issue, not a conversion tweak, but it lives in the same hero and showcase blocks being edited.

### Gaps
- I didn't confirm whether the FTC guidance would treat specific lines (e.g. "95% relapse") as actionable. It's non-binding guidance, so this needs legal review, not a researcher's judgment.
- I found no analytics data for the site, so I can't say which section gets the most clicks.

## Q2. What do pre-launch landing pages that worked actually do, and does it justify each change?

### Takeaway
Two evidence-backed patterns are worth copying. One is a one-field email form above the fold. The other is a post-signup screen that turns each signup into a referral with a visible reward (queue position, tiered perks), as Robinhood and Harry's did. The iOS-specific paths are a TestFlight public link (up to 10,000 external testers) and, later, an App Store pre-order (up to 180 days before release). I found no rigorous sources for sticky mobile bars or in-content CTAs, so those are practitioner inferences.

### Cited Findings
- **Robinhood:** the co-founder said the waitlist reached about 10,000 sign-ups on day one, over 50,000 in the first week and nearly 1 million within a year, well before the March 2015 launch. — [Business Insider](https://www.businessinsider.in/how-two-founders-got-nearly-1-million-users-for-their-app-before-it-even-existed/articleshow/59552253.cms). Growth blogs describe the mechanism as showing each user their queue position and letting referrals move them up. The "1,000 spots per referral" figure appears only in secondary sources and is unverified. — [Viral Loops](https://viral-loops.com/blog/how-robinhood-got-1-million-users/); [Prefinery](https://www.prefinery.com/blog/referral-programs/robinhood/)
- **Harry's:** about 100,000 emails in one week from a two-page microsite, where page 2 was a referral page with tiered rewards. Roughly 77% of emails came via referrals, and roughly 20,000 people referred at least one friend. — [Tim Ferriss, "How to Gather 100,000 Emails in One Week"](https://tim.blog/2014/07/21/harrys-prelaunchr-email/). Figures come via search snippets and secondary coverage ([Prefinery](https://www.prefinery.com/blog/referral-programs/prelaunch-campaign/harrys/)). Secondary sources also report about 15% of emails were invalid, and one Medium figure (850,000) conflicts with everything else and looks unreliable.
- **Form length:** evidence is mixed. Unbounce's well-known test cut 9 fields to 6 and conversions fell 14%; clarifying the field labels instead raised conversions 19%. CXL warns the "fewer fields always wins" rule is overgeneralised. HubSpot's analysis of about 40,000 landing pages found conversion declines only slightly as fields increase. — [CXL](https://cxl.com/blog/reduce-form-fields/); [HubSpot](https://blog.hubspot.com/blog/tabid/6307/bid/6746/which-landing-page-elements-to-test.aspx)
- **TestFlight:** up to 10,000 external testers per app, invited by email or by a public link with an optional tester cap. The first build needs Beta App Review. — [App Store Connect Help: Invite external testers](https://developer-rno.apple.com/help/app-store-connect/test-a-beta-version/invite-external-testers); [Apple TestFlight](https://developer.apple.com/testflight/)
- **App Store pre-orders:** a new app can go on pre-order up to 180 days before release (previously 90). Customers aren't charged until release day. — [App Store Connect Help: Publish for pre-order](https://www.developer.apple.com/help/app-store-connect/manage-your-apps-availability/publish-for-pre-order); [MacRumors](https://www.macrumors.com/2020/10/15/app-developers-preorders-180-days-before-launch)
- **Double opt-in:** GDPR doesn't strictly require it (Germany is often cited as the exception). It's recommended because it produces provable consent: store the wording shown, the page and source, and the confirmation timestamp and token. — [iubenda](https://www.iubenda.com/en/help/22127/); [Suped](https://www.suped.com/learn/email-deliverability/which-countries-require-double-opt-in-for-email-marketing-according-to-gdpr-and-best-practices)

### Inferences
How each mockup maps to the evidence:
- **One email field in the hero (mockup a, e).** For a "notify me" offer with no payment, one field is the lowest-friction ask. The Unbounce result is a reason not to strip helpful microcopy ("what we'll email you"), not a reason to add fields.
- **Founding-member pricing (b).** A concrete reason to join today, unlike Robinhood's "commission-free trading access". It turns plan clicks into sign-ups and tags plan interest, which is useful pricing research before launch.
- **Confirm screen plus referral (c).** Harry's and Robinhood both got most of their growth from the screen after signup: a link, a visible reward and progress. DayXero's version needs to be gentler. Quitting nicotine is personal, so sharing is optional, the share text never says the person is quitting, and the reward is queue position for TestFlight waves.
- **TestFlight waves as the "early access" reward (c, e).** The 10,000-tester cap and Beta App Review make waves natural. The public-link cap lets you control each wave.
- **Pre-order as phase 2.** Once a build is ready and a date is set, swap the hero button to "Pre-order on the App Store". Apple then notifies and auto-downloads for buyers, and the email list becomes the launch-day blast.
- **In-content guide CTAs and a sticky mobile bar (d).** The guides are the main SEO entry point, so many visitors never see the homepage hero. Placing one mid-article CTA after the third section, plus the existing end aside, gives two contextual asks without a pop-up. The sticky bar hides while a form is on screen, so the two never overlap.
- **Live signup counter: not in the mockups.** The hero uses honest chips ("First 500 get founding pricing") instead. Add a real `GET /api/waitlist/count` pill only once the number is persuasive. Showing "37 people" is worse than showing nothing.

### Gaps
- I found no first-party or controlled data on sticky mobile CTA bars or mid-article CTAs. Treat them as A/B candidates, not proven wins.
- I didn't verify the mechanics for delivering the founding discount: App Store offer codes for a discounted first year of an auto-renewing subscription, versus a temporary launch price. Check App Store Connect "Offer codes" docs before promising "$19.99 first year". The mockups label prices "planned" for this reason.
- I couldn't verify Robinhood's exact referral rule. Harry's stats come from secondary write-ups of the Ferriss post.

## Q3. What exactly should change, and what do the mockups look like?

### Takeaway
Fifteen changes, all built from existing classes, colours and components: the white pill CTA, `#161616` pill input with a sage focus state, `porcelain-card`, `glass-card-green`, `dark-card`, `faq-item`, mono micro-labels and sage status dots. Five mockups plus an index were rendered at 1440px and 390px, checked visually, and verified to have no horizontal overflow at 390px.

### Cited Findings
- Mockups link `../../../website/assets/site.css` and the same Google Fonts URL as [website/index.html](../../website/index.html) L25. They copy index.html's inline `<style>` block verbatim (L147-209) for `.glass-card-green`, `.moss-pedestal` and the rest.
- Some utilities the mockups use aren't in the compiled `site.css` yet: `sr-only`, `placeholder:text-white/30`, `focus:border-[#BCC388]/60`, `sm:flex-row`, `rounded-[28px]`, `line-through`, and others. For each page these were generated with `tailwindcss@3.4.17` and the site's own `tailwind.config.js`, then inlined in `<style id="mockup-utilities">`. Only rules missing from `site.css` are included, plus responsive variants to keep cascade order. Nothing new was invented. These rules disappear once the markup ships and `npm run website:css` is re-run (the config scans `./**/*.html`).

### Inferences

#### Change table

| # | Location | Current | Proposed | Rationale | Mockup |
|---|---|---|---|---|---|
| 1 | Nav CTA (index L256; build_guides.py L452) | "Get DayXero →" to `#pricing` | "Join the beta →" to `#waitlist` (home) or `/beta/` (guides) | No dead end; consistent ask everywhere | a, d, e |
| 2 | Nav label (L241) and footer | "Live App", "Subscription Plans" | "App Preview", "Founding offer", plus a "Join the beta" footer link | Stops implying the app is live | a |
| 3 | Hero status pill (L271-276) | "2026 Native iOS Protocol" | "iOS beta · Now enrolling", second half hidden below `sm` | States the pre-launch status up front | a |
| 4 | Hero subhead (L285) | "The iPhone app to quit…" | "…an iPhone app in development… Join the beta to test it first." | Honest; gives a reason to act | a |
| 5 | Hero palette strip (L290-299) | Brand hex-colour strip | Inline one-field form (`#121212` shell, `#161616` input, white pill button) + microcopy + privacy link + 3 honest proof chips | Above-the-fold capture; same slot and visual weight | a |
| 6 | Showcase copy (L329-353, L412) | "CLINICALLY FORMULATED", "95% relapse", "neurochemistry", "100% Offline", "neurochemical stabilization… cardiovascular health" | "PREP BEFORE YOU QUIT", "Prepared, Not Pressured Into Your Quit Day", plain-language benefit, "Data on your iPhone", "Explore Program" becomes "Join the beta" | Removes unsupported health claims (FTC guidance); adds a second CTA | a |
| 7 | Pricing header (L1121-1129) | "HONEST MONETIZATION… Transparent, Fair Pricing" | "FOUNDING MEMBER PRICING · Planned Pricing. Founding Members Pay Less." + "isn't on the App Store yet… No payment today" | Turns buy intent into signups | b |
| 8 | Plan buttons (L1149/1174/1193) + JS L1906-1912 | Toast "Ready for App Store Checkout" | Monthly/Lifetime: "Notify me at launch", which expands into a compact form with hidden `plan_interest`. Annual: founding offer card with its own form "Reserve" | Captures email plus plan-interest data; no fake checkout | b |
| 9 | Pricing footnote (L1201) | "The base DayXero download includes…" | "Prices are planned… The free tier will include…" | Future tense | b |
| 10 | FAQ + FAQPage JSON-LD (L90-140, L1214-1237) | Present-tense pricing/cancel Qs | Add "When can I download DayXero?", "What is the founding-member offer?", "What will you do with my email?"; "Will DayXero be free?" in future tense. Remove `offers` from the `MobileApplication` JSON-LD until launch | Accurate rich results; answers pre-launch objections | b |
| 11 | Calculator "Pledge to Keep This Capital" (L1107, L1901) | Fake "Vault Updated" toast | Swap the button for the dark form variant: "Email me at launch" with `source=calculator` | Second high-intent moment | (reuses the a/b form component) |
| 12 | Post-submit | n/a | State 1 inline "Confirm your email" (glass card, resend / change email). State 2 `/beta/confirmed?r=CODE`: queue #, founding badge, copyable referral link, 4 circular share buttons, "Friends joined 1/3" metric bar, "What happens next" | Double opt-in plus a referral loop (Harry's/Robinhood), done discreetly | c |
| 13 | Guide template (build_guides.py) | End aside "See plans, free tier included →"; no mid-article CTA | Glass mid-article CTA after the 3rd `<h2>`; end porcelain aside gets the light form; sticky mobile pill bar (`md:hidden`, shows after 300px of scroll, hides while a CTA block is visible, dismiss remembered 7 days via try/catch localStorage). Present-tense feature lines become "is being built to…" | Guides are the SEO entry point and most visitors never see the hero | d |
| 14 | New page `/beta/` | n/a | Dedicated waitlist page: referral pill (`?r=`), hero form, 3 benefit cards (porcelain/glass/dark rhythm), 4-step "How the beta works", beta FAQ incl. "Is DayXero medical treatment? No." | One clean URL for bios, Reddit/TikTok and referral links | e |
| 15 | Privacy page | "website sets no cookies"; no email section | Add a `#waitlist` section (see Q4) | Legal requirement and trust | (text in Q4) |

#### Copy guardrails used in every mockup
- Always "in development", "beta", "planned", "will include" or "is being built to". Never "download", "available", "start trial" or "checkout".
- No outcome or health claims. The microcopy promises only what will be emailed: confirmation, TestFlight invite, launch link, rare beta updates.
- "First 500" and the founding price are business decisions written as offers, not statistics. Queue "#128", "m•••@gmail.com" and "1 / 3" in mockup c are sample values.

#### Files
Mockups (`research_notes/DayXero prelaunch waitlist marketing/mockups/`):
- `index.html`: links every mockup, with a note and desktop/mobile thumbnails
- `a-hero-waitlist.html`: (a) hero form plus de-medicalised showcase
- `b-pricing-founding.html`: (b) founding-member pricing plus pre-launch FAQ
- `c-success-referral.html`: (c) confirm-email state plus confirmed/referral state
- `d-guide-cta-sticky.html`: (d) guide page with mid-article CTA, end CTA form and sticky mobile bar
- `e-beta-page.html`: (e) dedicated `/beta/` page
- `_build/`: generator (`build_mockups.py`), missing-utility inliner (`inject_missing.py`) and Playwright renderer (`shoot.js`, which fetches Google Fonts via curl so Inter renders)

Screenshots (same folder):
- `a-hero-waitlist-desktop.png`, `a-hero-waitlist-mobile.png`
- `b-pricing-founding-desktop.png`, `b-pricing-founding-mobile.png`
- `c-success-referral-desktop.png`, `c-success-referral-mobile.png`
- `d-guide-cta-sticky-desktop.png`, `d-guide-cta-sticky-mobile.png`, `d-guide-cta-sticky-mobile-viewport-sticky.png` (bar visible mid-article), `d-guide-cta-sticky-mobile-viewport-inline.png` (bar hidden while the inline CTA is on screen)
- `e-beta-page-desktop.png`, `e-beta-page-mobile.png`
- `index-desktop.png`, `index-mobile.png`

Visual fixes made after reviewing the screenshots:
1. At 390px the email input collapsed. `flex-1` in a column flex layout overrode `h-12`; fixed with `w-full sm:flex-1`.
2. In the narrow pricing cards at 1440px the input was squeezed to "you@ex"; added a `stacked` form variant for in-card forms.
3. The sticky bar overlapped the inline CTA; it now hides while a CTA block is visible.
4. The referral link truncated on mobile; now `text-xs sm:text-sm`.

### Gaps
- I didn't mock the calculator change (row 11) or the methodology/timeline copy softening separately. Both reuse components already shown.
- The mockups don't load Turnstile. A `cf-turnstile` placeholder div with `data-appearance="interaction-only"` is in the markup.

## Q4. What is the minimal $0 backend, and what spam protection, double opt-in and privacy changes are needed?

### Takeaway
Use the existing `dayxero` Worker. Add a `main` script that runs only for `/api/*` (`run_worker_first: ["/api/*"]`), store signups in a D1 table (free: 100,000 rows written per day), verify Cloudflare Turnstile server-side plus a honeypot, and send one double-opt-in email through Resend's free tier (100/day, 3,000/month). Queue anything over the daily cap. Then update the privacy policy, which currently promises no data collection on the website.

### Cited Findings
- **Worker setup:** `assets.run_worker_first` accepts an array of route patterns, so the Worker runs only for matching routes and every other path stays a static asset. The `ASSETS` binding lets unhandled requests fall through with `env.ASSETS.fetch(request)`. A `.assetsignore` file (gitignore syntax) keeps files out of the upload. — [Cloudflare Workers: Static assets binding](https://developers.cloudflare.com/workers/static-assets/binding/)
- The site already has `website/.assetsignore`, which excludes `wrangler.jsonc` and the Tailwind sources. A live check returned 404 for `/tailwind.config.js` and `/wrangler.jsonc`. Because `assets.directory` is `"."` ([website/wrangler.jsonc](../../website/wrangler.jsonc)), any Worker source placed under `website/` must be added to `.assetsignore`, or it will be published.
- **D1 free plan:** 100,000 rows written per day, resetting at 00:00 UTC. Queries fail for the rest of the day once the limit is hit. Cloudflare's changelog says free-tier daily limits are enforced as of 2026-09-01. — [D1 pricing](https://developers.cloudflare.com/d1/platform/pricing/); [changelog](https://developers.cloudflare.com/changelog/post/2026-09-01-d1-free-tier-limit-enforcement/)
- **Turnstile:** free plan available. Server-side validation is mandatory: `POST https://challenges.cloudflare.com/turnstile/v0/siteverify` with `secret`, `response` and optional `remoteip`. Tokens expire after 300 s and are single-use. — [Turnstile server-side validation](https://developers.cloudflare.com/turnstile/get-started/server-side-validation/). Sources disagree on the free widget cap (Cloudflare's plan table shows 20, an older page says 10). — [Turnstile plans](https://developers.cloudflare.com/turnstile/plans/)
- **Resend free:** 100 emails/day and 3,000/month. — [Resend account quotas](https://resend.com/docs/knowledge-base/account-quotas-and-limits). **Brevo free** is reported as 300 emails/day; sources conflict on the contact cap. — [Sender.net review](https://www.sender.net/reviews/brevo/pricing/free-plan); [Moosend](https://moosend.com/blog/brevo-pricing/)
- **Double opt-in records:** store the consent wording, the source page and the confirmation timestamp and token. Only email confirmed addresses. — [Suped](https://www.suped.com/learn/email-deliverability/which-countries-require-double-opt-in-for-email-marketing-according-to-gdpr-and-best-practices); [iubenda](https://www.iubenda.com/en/help/22127/)
- **Current privacy policy:** "The website sets no cookies and shows no advertising"; analytics via Cloudflare Web Analytics; no mention of email collection ([website/privacy/index.html](../../website/privacy/index.html) L106-112).

### Inferences

#### Config (proposed `website/wrangler.jsonc` additions)
```jsonc
{
  "name": "dayxero",
  "main": "worker/index.js",                 // add "worker/" to website/.assetsignore
  "compatibility_date": "2026-10-01",
  "assets": {
    "directory": ".",
    "binding": "ASSETS",
    "not_found_handling": "404-page",
    "run_worker_first": ["/api/*"]          // all other paths stay pure static
  },
  "d1_databases": [{ "binding": "DB", "database_name": "dayxero-waitlist", "database_id": "<from wrangler d1 create>" }],
  "vars": { "SITE_URL": "https://dayxero.in", "CONSENT_VERSION": "2026-11-01" }
  // secrets: wrangler secret put TURNSTILE_SECRET ; wrangler secret put RESEND_API_KEY ; IP_SALT
}
```
If you'd rather keep `website/` purely static, the same code can live in `workers/waitlist/` with a route `dayxero.in/api/*`.

#### D1 schema
```sql
CREATE TABLE waitlist (
  id               INTEGER PRIMARY KEY,
  email            TEXT NOT NULL UNIQUE COLLATE NOCASE,
  status           TEXT NOT NULL DEFAULT 'pending',   -- pending | confirmed | unsubscribed
  confirm_hash     TEXT,                              -- sha256 of the emailed token (never store the raw token)
  ref_code         TEXT UNIQUE NOT NULL,              -- e.g. K7F2Q, shown on /beta/confirmed
  referred_by      TEXT,                              -- ref_code of the inviter
  plan_interest    TEXT,                              -- Monthly | Annual-founding | Lifetime | NULL
  source           TEXT,                              -- home-hero | pricing-annual | guide-quit-vaping-inline | beta-page | calculator
  consent_text     TEXT NOT NULL, consent_version TEXT NOT NULL,
  country          TEXT,                              -- request.cf.country (for launch-email timing, US vs IN)
  ip_hash          TEXT,                              -- sha256(ip + IP_SALT), abuse throttling only
  created_at       TEXT NOT NULL DEFAULT (datetime('now')),
  confirmed_at     TEXT, unsubscribed_at TEXT, email_sent_at TEXT
);
CREATE INDEX idx_waitlist_status ON waitlist(status);
CREATE INDEX idx_waitlist_ref ON waitlist(referred_by);
```

#### Routes (Worker sketch)
- `POST /api/waitlist` (form-encoded or JSON):
  1. If the honeypot `company` field is non-empty, return a fake 200 so bots learn nothing.
  2. Validate the email: length up to 254, a simple regex, lower-cased.
  3. Verify Turnstile via siteverify (`remoteip` = `CF-Connecting-IP`); reject if `success` is false.
  4. Throttle: more than 5 inserts from the same `ip_hash` in the last hour returns 429. This is one D1 count query, so no paid rate-limit product is needed.
  5. `INSERT … ON CONFLICT(email) DO NOTHING`. For an existing pending row, re-send the email at most once per 10 minutes.
  6. Generate a 32-byte random token, store `sha256(token)`, then send the confirmation email via Resend (`https://api.resend.com/emails`).
  7. Respond `{ok:true, state:"pending"}` to JS clients, or a `303` redirect to `/beta/thanks/` for no-JS posts (progressive enhancement; the mockup form has `action="/api/waitlist" method="post"`). Always return the same response whether the email is new or existing, so the list can't be probed.
- `GET /api/waitlist/confirm?t=TOKEN`: hash the token and look it up. If it's pending and under 48 h old, set `confirmed` and `confirmed_at`, credit `referred_by`, then `303` to `/beta/confirmed/?r=<ref_code>`. An expired token goes to a "link expired, re-enter email" page.
- `GET /api/waitlist/unsubscribe?t=…`: one-click (also `List-Unsubscribe` + `List-Unsubscribe-Post` headers on every email).
- `GET /api/waitlist/me?r=CODE`: queue position and friends-joined count for the confirmed page. Position = confirmed rows created before you, minus 10 × confirmed referrals.
- `GET /api/waitlist/count` (optional): confirmed count, edge-cached 10 minutes. Only show it in the UI once the number helps.

#### Email volume plan ($0)
- Resend free allows 100 sends a day. A Reddit or TikTok spike can exceed that. Keep `email_sent_at` NULL for overflow and add a Workers Cron Trigger (`"triggers": {"crons": ["*/30 * * * *"]}`) that drains the backlog within the cap. The inline success state already says "check your inbox"; the copy could add "can take up to a few hours during busy periods".
- For the launch blast, 3,000/month on Resend means a list over 3,000 needs either sending over several days (TestFlight waves fit this naturally) or Brevo's free tier (reported 300/day) as a second sender. Export a CSV with `wrangler d1 execute dayxero-waitlist --command "SELECT email FROM waitlist WHERE status='confirmed'" --json`.
- Sending domain: verify `dayxero.in` in Resend (SPF/DKIM records in Cloudflare DNS, free). Send from `beta@dayxero.in`; replies route to `hello@dayxero.in` with Cloudflare Email Routing (free).

#### Spam protection summary
In order of cost to a real visitor: honeypot (zero), Turnstile managed / interaction-only (invisible for most people), per-IP-hash throttle, and double opt-in, which stops fake addresses from ever being emailed twice.

#### Privacy policy additions (`/privacy/#waitlist`)
- **What:** email address, which form and page you used, the plan you said you're interested in, referral code and who referred you, country (from Cloudflare's request data), a salted hash of your IP address for abuse prevention, and timestamps of signup, confirmation and unsubscribe.
- **Why:** to send a confirmation, your TestFlight invite, the App Store link at launch, your founding offer code and occasional beta updates. No marketing for other products, and never sold or shared with tobacco or nicotine companies (this mirrors the existing promise).
- **Basis:** your consent, which you can withdraw any time via the unsubscribe link or by emailing hello@dayxero.in.
- **Processors:** Cloudflare (hosting, D1 database, Turnstile bot check), Resend (email delivery) and Brevo if used.
- **Retention:** deleted 12 months after launch, or immediately on unsubscribe or request.
- **Update the existing bullets:**
  - "No cookies" stays true for DayXero itself. Add a note that the Turnstile check loads a script from challenges.cloudflare.com on pages with the form.
  - The app section's statement that the app has no account stays true. The waitlist is separate from the app.
  - "Children": the beta is for people 18+ (TestFlight and nicotine content). Consider an "I'm 18 or older" line in the microcopy rather than a checkbox, to keep it one field.
- Update `Updated <time>` on the privacy page and note the change on the Terms page if it references the website.

### Gaps
- I didn't verify US CAN-SPAM requirements (a physical postal address in commercial email) or India's DPDP Act 2023 obligations for the India audience the guides already address. Both are commonly cited and need checking before the launch email is sent. A postal address may not be $0 (PO box or registered agent).
- I didn't verify whether Turnstile sets any cookies or local storage. That determines the exact privacy-policy wording.
- The Turnstile free widget and siteverify caps conflict across sources (10 vs 20 widgets; one third-party source claims 1M siteverify calls a month). Irrelevant at DayXero's scale, but check the [plans page](https://developers.cloudflare.com/turnstile/plans/).
- I didn't confirm Cloudflare's own transactional email service for Workers (it would replace Resend), so it's not recommended here.
