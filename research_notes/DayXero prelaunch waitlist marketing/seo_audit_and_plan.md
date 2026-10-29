# SEO Audit and 3-6 Month SEO Plan for dayxero.in (pre-launch quit-nicotine iOS app)

Research date: 2026-10-29. The audit comes from reading the files in /home/user/DAYXERO/website/ and from live HTTP checks against https://dayxero.in. Local-file findings are cited as [file](path). External findings are cited with URLs. Note: several web sources are vendor or SEO blogs and are flagged where that matters.

## 1. Current site SEO audit: what is right and what is broken

### Takeaway
The on-page basics are good for a 12-page site: unique titles and meta descriptions, self-referencing canonicals, OG tags, BreadcrumbList and Article schema on guides, cited sources, and dense internal linking. The serious problems are elsewhere. (1) The homepage shows the app as if it can be bought today: live-looking pricing, "Start 3-Day Free Trial" buttons that fire a fake toast, and MobileApplication plus Offer schema. There is also no waitlist or email capture anywhere. (2) E-E-A-T is weak: the author is the "DayXero team" (an Organization), with no named person and no medical reviewer. (3) The homepage weighs 112 KB, mostly inline JS and Tailwind classes. Its H1 is "Quit Nicotine on Your Quit Day." and contains no target terms. (4) Trailing-slash redirects use 307, not a permanent code. (5) The site has only 5 content pages.

### Cited Findings
**Inventory and indexing**
- sitemap.xml lists 11 URLs (home, /guides/, 5 guides, about, contact, privacy, terms), all with `lastmod` 2026-10-29. robots.txt is `User-agent: * / Allow: /` plus a Sitemap line. The 404 page has `noindex`. — [sitemap.xml](/home/user/DAYXERO/website/sitemap.xml), [robots.txt](/home/user/DAYXERO/website/robots.txt), [404.html](/home/user/DAYXERO/website/404.html)
- Every page has a self-referencing `<link rel="canonical">` with a trailing slash, `<html lang="en">` and a viewport meta tag. — [quit-vaping/index.html](/home/user/DAYXERO/website/quit-vaping/index.html) (same pattern on all pages)
- Live check: `https://dayxero.in/` returns HTTP/2 200 from Cloudflare with `cache-control: public, max-age=0, must-revalidate`. `https://dayxero.in/quit-vaping` (no slash) returns **307** to `/quit-vaping/`. A request to `https://www.dayxero.in/` failed through the research proxy (502), so www resolution and redirect could not be verified. — curl -I, 2026-10-29
- Cloudflare Workers static assets use 307 for trailing-slash redirects under the default `auto-trailing-slash` html_handling. The other options are `force-trailing-slash`, `drop-trailing-slash` and `none`. — [Cloudflare docs](https://developers.cloudflare.com/workers/static-assets/routing/advanced/html-handling/)
- wrangler.jsonc sets `workers_dev: true` and `preview_urls: true`. The same content is therefore probably reachable on a *.workers.dev hostname, which creates a duplicate-content risk. The canonicals mitigate it. — [wrangler.jsonc](/home/user/DAYXERO/website/wrangler.jsonc)

**Titles and meta descriptions (all unique, all within sensible length)**
- Home: "Quit Vaping, Smoking & Pouches App for iPhone | DayXero". Description: "The iPhone app to quit vaping, smoking and nicotine pouches. Prepare for your Quit Day, beat cravings in 3 minutes and taper NRT. Slips never reset progress." — [index.html](/home/user/DAYXERO/website/index.html)
- /quit-vaping/: "How to Quit Vaping: A Step-by-Step Plan | DayXero"
- /quit-smoking/: "How to Quit Smoking: Plan Your Quit Day | DayXero"
- /quit-nicotine-pouches/: "How to Quit Nicotine Pouches (Zyn, Velo & More) | DayXero"
- /nicotine-withdrawal-timeline/: "Nicotine Withdrawal Timeline: Symptoms Day by Day | DayXero"
- /nicotine-cravings/: "How to Handle Nicotine Cravings: Urge Surfing Guide | DayXero"
- /guides/: "Quit Nicotine Guides: Vaping, Smoking & Pouches | DayXero"
- About: "About DayXero: A Quit Nicotine App Built Around Quit Day". Contact, Privacy and Terms have plain titles.
- (All from the respective index.html files under /home/user/DAYXERO/website/.)
- The pouch guide's H1 is "How to Quit Nicotine Pouches". "Zyn" appears in the title tag but not in the H1 or URL. — [quit-nicotine-pouches/index.html](/home/user/DAYXERO/website/quit-nicotine-pouches/index.html)

**Headings**
- Home H1: "Quit Nicotine on Your Quit Day." It does not contain vape, smoking, pouch or app. Home H2s are brand or marketing phrases: "Engineered For Strength, Focus And Longevity", "Experience DayXero Native in Hand", "Why DayXero Succeeds Where Trackers Fail", "The 3-Minute Urge Surfer", "What Happens in Your Body", "Calculate Your Freedom", "Transparent, Fair Pricing. No Billing Traps.", "Questions, Answered", "Quit Nicotine Guides". The H3s include "The Non-Punitive Slip Law" and "NRT & Pouch Taper Co-Pilot". — [index.html](/home/user/DAYXERO/website/index.html)
- Guides have clean, query-shaped H2s ("Step 1: Pick a Quit Day…", "What withdrawal will feel like", "How long nicotine stays in your body", "When to talk to a doctor", "Frequently asked questions", "Sources"). — guide HTML files

**Content depth (approx. visible words, excluding scripts)**
- Home about 4,155. /quit-vaping/ about 1,660. /quit-smoking/ about 1,600. /nicotine-withdrawal-timeline/ about 1,310. /quit-nicotine-pouches/ about 1,300. /nicotine-cravings/ about 1,236. /guides/ about 451. About about 527. Contact about 324. — word counts computed locally
- /quit-vaping/ and /quit-smoking/ contain an H2 "A note for readers in India" and link to India's NTCP (ntcp.mohfw.gov.in). Combined with the .in ccTLD, this is an India-relevance signal. — [quit-vaping/index.html](/home/user/DAYXERO/website/quit-vaping/index.html)

**Structured data**
- Home @graph: Organization (name, url, logo), WebSite, **MobileApplication** (operatingSystem iOS, applicationCategory HealthApplication, 4 Offers: Free $0, Monthly $9.99, Annual $39.99, Lifetime $79.99 USD; no aggregateRating or review; no App Store URL), and FAQPage with 6 Q&As. — [index.html](/home/user/DAYXERO/website/index.html)
- Guides: Organization (with email hello@dayxero.in), **Article** with `author: {"@id": ".../#organization"}`, datePublished = dateModified = 2026-10-29, `image` = the shared og-image.png, BreadcrumbList, and FAQPage (4-5 Q&As). There is no Person author, no `reviewedBy`, no MedicalWebPage and no `lastReviewed`. — [quit-vaping/index.html](/home/user/DAYXERO/website/quit-vaping/index.html); generator at [build_guides.py](/home/user/DAYXERO/scripts/website/build_guides.py) lines ~598-600
- About uses AboutPage, Contact uses ContactPage, Privacy and Terms use WebPage, and /guides/ uses CollectionPage with 5 Article items. — respective HTML files
- Google's software-app rich result **requires** `name`, `offers.price` and **either `aggregateRating` or `review`**. The current MobileApplication markup has neither, so it is not eligible for a rich result anyway. — [Google: Software App structured data](https://developers.google.com/search/docs/appearance/structured-data/software-app)
- Google policy: "Don't mark up content that is not visible to readers" and "Don't mark up irrelevant or misleading content". Structured-data spam can trigger a manual action that removes rich-result eligibility but "doesn't affect how the page ranks". — [Google structured data policies](https://developers.google.com/search/docs/appearance/structured-data/sd-policies)
- FAQ rich results: since August 2023 they are limited to "authoritative government and health websites", and HowTo results are deprecated. — [Google Search Central blog, Aug 2023](https://developers.google.com/search/blog/2023/08/howto-faq-changes?hl=ko). Secondary coverage reports that FAQ rich results were later dropped for all sites in 2026 ([SEJ](https://www.searchenginejournal.com/google-drops-faq-rich-results-from-search/574429/)). I did not confirm the exact date in Google's own docs. Either way, FAQPage markup on dayxero.in yields no SERP feature. It is harmless if kept (per the same 2023 post).

**Pre-launch honesty and conversion (also an SEO and trust issue)**
- The homepage has 0 occurrences of "waitlist", "coming soon", "pre-order", "TestFlight" or "beta", and no `<form>` or `mailto:`. It has no link to apps.apple.com and no download link. Pricing buttons run JS that shows `"Selected ${plan} Plan. Ready for App Store Checkout."`. Another button shows "Capital Pledge Recorded! Vault Updated." — [index.html](/home/user/DAYXERO/website/index.html) inline script
- The pricing section shows "RECOMMENDED · 3-DAY TRIAL", "Start 3-Day Free Trial" and "Billing trickery was the #1 theme in competitor complaints". — [index.html](/home/user/DAYXERO/website/index.html)
- The site nav label "Get DayXero" points to `/#pricing`, and every guide's CTA ("Turn this plan into a daily routine") points to `/#pricing`. — guide HTML files

**E-E-A-T signals on site**
- The About page says: "The DayXero guides are written by the DayXero team". Guides are "Based on public health guidance" (WHO, NHS, CDC, NCI Smokefree.gov, India NTCP). Each guide is "Dated and updated", and corrections go to hello@dayxero.in. No named founder, writer, credentials or medical reviewer appear. — [about/index.html](/home/user/DAYXERO/website/about/index.html)
- Each guide has a "Sources" list linking to top-level homepages (e.g. smokefree.gov/, cdc.gov/tobacco/, nhs.uk/better-health/quit-smoking/, who.int fact sheet), not specific pages or studies. Each guide also has a medical disclaimer. — guide HTML files

**Internal linking**
- Each guide links to every other guide (2-4 times each via nav, body, "Keep reading" and footer), to /about/#editorial, and to /#pricing. The homepage links to all 5 guides and /guides/. Anchor text is descriptive ("Nicotine Withdrawal Timeline: What to Expect and When"). — link counts extracted from HTML
- The homepage nav is mostly in-page anchors (#showcase, #methodology, #interactive-preview, #breath-chamber, #recovery-timeline, #calculator, #pricing). — [index.html](/home/user/DAYXERO/website/index.html)

**Page weight and performance**
- index.html is 112,126 bytes. The inline `<script>` is about 25 KB (Lucide icon strings, toasts, interactions). 47 inline `<svg>` elements total about 12.5 KB. `class="…"` attributes total about 33 KB, which is Tailwind utility bloat. The JSON-LD is about 4.3 KB. Inline `<style>` is about 1.9 KB. There are no `<img>` tags. — computed locally from [index.html](/home/user/DAYXERO/website/index.html)
- The external CSS is /assets/site.css (32.5 KB, minified Tailwind). Google Fonts are loaded from fonts.googleapis.com and fonts.gstatic.com, with Inter at 6 weights plus JetBrains Mono at 3 weights on the home page. Every page carries this render-blocking third-party font request. — [index.html](/home/user/DAYXERO/website/index.html), [assets/](/home/user/DAYXERO/website/assets/site.css)
- logo.png (used in Organization schema) is 221 KB. og-image.png (96 KB) is shared by all pages. — `ls -la` of website/

**OG and social**
- og:title, og:description, og:url, og:image (1200x630) and twitter:card=summary_large_image are on every page. There is no twitter:title or description; X falls back to OG. Every page uses the same OG image. — HTML files

**Analytics**
- The privacy page says the website uses "cookie-free analytics", but no analytics script was found in index.html. It may be injected by Cloudflare Web Analytics at the edge (not verified). — [privacy/index.html](/home/user/DAYXERO/website/privacy/index.html), [index.html](/home/user/DAYXERO/website/index.html)

### Inferences
- **Fix first:** the MobileApplication schema with four live-priced Offers, the live-looking pricing and the fake "Ready for App Store Checkout" toast. Together they misrepresent an unreleased product on a YMYL topic. That is a trust problem for users, quality raters and possibly Apple review. Replace the pricing CTAs with a waitlist form ("Join the waitlist / Get notified at launch") and either remove the Offer blocks or keep MobileApplication without offers until there is an App Store URL. Even after launch, the rich result needs real ratings from the App Store page, not self-asserted ones.
- The H1 and H2s on the homepage carry little topical relevance. Change the H1 to something like "The iPhone app to quit vaping, smoking and Zyn, on your Quit Day" and keep the brand line as a subhead.
- Switch html_handling to `force-trailing-slash` or handle redirects with a 301 in a Worker, so that linkers who omit the slash pass a permanent signal. Google generally treats 307 as temporary. Practical impact is small, but the fix is a one-line config change.
- Disable `workers_dev` and `preview_urls` for production, or confirm those hosts are noindexed, to avoid duplicate hosts.
- Page weight: 112 KB of HTML is not fatal; compressed it is probably about 25-30 KB. Main-thread JS and two font origins with 9 weights matter more for LCP and INP on mobile. Self-host one variable Inter file, preload it, and cut weights. Move the icon map to a deferred external JS file. Lab measurement (PageSpeed Insights or Lighthouse) is still needed.
- The five guides are a solid seed cluster, but each is a single page for an entire head topic. Ranking will come from long-tail spokes (see section 3).
- The guide CTAs all point to /#pricing. They should point to a waitlist anchor and later to the App Store with a Smart App Banner.

### Gaps
- I did not run PageSpeed Insights or CrUX. Field CWV data likely does not exist yet for a new low-traffic site.
- I could not confirm whether www.dayxero.in resolves or redirects, or whether the *.workers.dev host is publicly reachable.
- I did not check whether the site is already indexed (no `site:` query result was obtained).

## 2. The .in ccTLD: does it hurt US ranking, and what to do

### Takeaway
.in is a true country-code TLD. Google does not list it among the ccTLDs it treats as generic (.tv, .me, .io, .co, .ws, etc.), so Google geotargets dayxero.in to India by default. Search Console no longer has a country-targeting override (the International Targeting report and its setting were retired in September 2022), and hreflang cannot change it. Mueller has said ccTLD sites can still get US traffic, and the site's on-page India signals add to the pull toward India. For a US-first YMYL brand at $0, the clean fix is to buy a gTLD (.com, .app or .health) **now, before launch and before links accrue**, then 301 the .in to it with a Search Console Change of Address. Waiting until after launch makes the move costlier.

### Cited Findings
- Google: ccTLDs are "tied to a specific country" and are a strong country signal. gTLDs "aren't associated with specific locations". Google treats some ccTLDs as generic, listing examples such as .tv, .me, .io, .co and .ws, and says the list "may change". .in is not on the list. — [Google: Managing multi-regional sites](https://developers.google.com/search/docs/specialty/international/managing-multi-regional-sites)
- The International Targeting report was deprecated and stopped working on 22 Sept 2022. Google said country targeting via Search Console "was determined to have little value for the ecosystem, and is no longer supported". Hreflang is still supported. — [Google Search Console Help](https://support.google.com/webmasters/answer/12474899?hl=en); [Search Engine Land](https://searchengineland.com/google-search-console-to-remove-international-targeting-report-387477)
- Mueller (as reported) says ccTLD sites can still get US traffic. He has also said that for a basically global site you don't need to switch to a gTLD, and he called site moves a "big deal" whose outcome is "impossible to know fully ahead of time". — [SERoundtable: ccTLDs can get US traffic](https://www.seroundtable.com/google-cctld-us-traffic-20040.html); [SERoundtable: site move outcomes](https://www.seroundtable.com/google-site-move-outcomes-impossible-know-41543.html)
- An anecdote: a UK publisher reportedly lost about 98% of Google News visibility after moving from .co.uk to .com. — [Relevant Audience](https://www.relevantaudience.com/seo/uk-publisher-lost-news-visibility-after-com-move/) (single case, not controlled)
- On-site India signals: "A note for readers in India" sections and NTCP links. — [quit-vaping/index.html](/home/user/DAYXERO/website/quit-vaping/index.html), [quit-smoking/index.html](/home/user/DAYXERO/website/quit-smoking/index.html)

### Inferences
- Hreflang does not solve this. The site has one English version, and hreflang tells Google which language or region variant to show. It does not override ccTLD geotargeting. Using `hreflang="en-us"` on a .in page could even look inconsistent.
- Mueller's comfort applies to established sites, where moving risks losing equity. dayxero.in is days old with no links, so the cost of moving is close to zero now and grows every month. Mueller's caution argues for moving early, not for staying.
- **Recommendation:** register dayxero.com, dayxero.app (HSTS-preloaded, app-brand-appropriate) or getdayxero.com. A domain costs about $10-20/year, so it breaks the strict $0 budget slightly; flag this to the user. Deploy the same Worker on the new domain. 301 every .in path to the same path (Cloudflare Bulk Redirects or a Worker). Verify both domain properties in Search Console and run Change of Address. Update canonicals, sitemap, schema @id, robots Sitemap line and the email domain. Do this before any PR, directory or App Store listing links to dayxero.in. Keep the .in for India-specific content later if wanted.
- If the user must stay at $0 or on .in: remove India-specific sections from the main guides (move them to /in/ pages), build US authority links (US quitlines, US universities, US press), and accept slower US ranking. Google may still rank strong .in pages in the US for global queries, but it is a headwind.
- Also align the App Store "Marketing URL" and "Support URL" with the final domain before submission.

### Gaps
- I found no study that quantifies the US ranking penalty of a .in domain. The evidence is Google's documented ccTLD behaviour plus Mueller's qualitative statements.
- Whether .app versus .com changes CTR or trust for health queries is unknown; I found no data.

## 3. Keyword landscape (quit vaping, smoking, Zyn/pouches, withdrawal, cravings, NRT, "best app")

### Takeaway
I had no access to paid volume tools. Google autocomplete (US, hl=en) shows dense long-tail demand around **Zyn/pouch quitting and withdrawal symptoms** ("zyn withdrawal timeline", "quit zyn cold turkey or taper", "nicotine withdrawal timeline zyn", "what happens when you quit nicotine pouches"). It also shows **symptom-specific withdrawal queries** (headache, nausea, insomnia, brain fog, anxiety, chest pain, dizzy) and many "reddit" modifiers, which signal a demand for peer, experience-based answers. Pouch SERPs are dominated by Truth Initiative/EX Program plus low-quality commercial and spam pages. That is the most realistic opening for a new site. Head terms ("how to quit smoking", "quit vaping") are owned by .gov, NHS and major health publishers and heavily covered by AI Overviews.

### Cited Findings
**Google autocomplete (gl=us, hl=en), pulled 2026-10-29 via suggestqueries.google.com:**
- "quit zyn": quit zyn reddit | **quit zyn app** | **quit zyn timeline** | quit zyn cold turkey reddit | **quit zyn cold turkey or taper** | quit zyn help | quit zyn gained weight | is it hard to quit zyn | is zyn a good way to quit smoking
- "how to quit zyn": …zyns reddit | …zyn pouches | …zyns cold turkey | …zyns for good | …zyn nicotine pouches | …zyns easily
- "zyn withdrawal": symptoms | **timeline** | symptoms reddit | symptoms timeline | symptoms heart | nausea | anxiety reddit | headache
- "nicotine withdrawal timeline": reddit | **day by day** | **zyn** | **by hour** | **vaping** | cold turkey | symptoms | **pouches** | **with patches**
- "how long does nicotine withdrawal": last | symptoms last | take | last from vaping | headache last | **insomnia last** | take to start | **brain fog last** | last cold turkey | **depression last**
- "nicotine withdrawal": symptoms | symptoms timeline | headache | nausea | physical symptoms | tiredness | reddit | insomnia | medication
- "vape withdrawal": symptoms | timeline | symptoms timeline | physical symptoms | reddit | headache | **dizzy** | **chest pain**
- "how to quit vaping": cold turkey | **while pregnant** / when pregnant | reddit | **without withdrawal** | nicotine | fast | for good | book
- "quit vaping": products | device | reddit | cold turkey | app | timeline | necklace | aids | tools
- "quit vaping app": free | tracker | reddit | uk | uk free | free reddit | android | australia | nhs
- "quit smoking app": free | reddit | tracker | reviews | free reddit | android | free download | **money saved** | australia
- "best app to quit": drinking | smoking | **vaping** | weed | gambling | … | smoking reddit | smoking free
- "nicotine cravings": timeline | symptoms | **years after quitting** | reddit | after quitting | help | months after quitting | after a year | never go away
- "what happens when you quit": smoking | … | vaping | **nicotine** | smoking and start vaping | … | **nicotine pouches**
- "zyn vs": velo | **vape** | zyn ultra | **cigarettes** | on | alp | chewing tobacco | **nicotine gum** | dip | snus
- "how much nicotine in": a cigarette | one cigarette | a cigar | **a geek bar** | a pack of cigarettes | a marlboro red | **a vape** | black and mild | **zyn** | copenhagen pouches
- "vape calculator": **nicotine** | ohm | app | coil | online | watts | diy | juice (mostly hardware intent)
- "quitting vaping": timeline | cold turkey | reddit | side effects | while pregnant | **benefits** | symptoms | cold turkey reddit | cold turkey timeline
- (All lines above come from `https://suggestqueries.google.com/complete/search?client=firefox&hl=en&gl=us&q=…`, run locally.)

**Volume datapoints (weak):**
- A third-party study (Direct365) reports about 48,000 global monthly Google searches for "how to quit vaping"-type queries. The date and method are unclear. — [London Loves Business](https://londonlovesbusiness.com/60-of-vaping-related-google-searches-focus-on-health-concerns)
- A Snusboss state study scored "quit vaping" 73/100 and "popcorn lung" 69/100 on relative interest among anti-vaping terms. — reported via [WBCK](https://wbckfm.com/michigan-indiana-ohio-among-top-10-states-looking-to-quit-vaping-in-2024/)

**Who ranks for "how to quit zyn" (US web search, 2026-10-29):**
- Results: Truth Initiative EX Program (exprogram.com, becomeanex.org; with Mayo Clinic), Birches Health, Ubie Health, truthinitiative.org, and commercial pouch-alternative sellers (nectr.energy, takeroon.com). There are also many spam or parasite pages on hijacked domains (e.g. "6+ Easy Ways How to Quit Zyns" on wyzant.com subdomain and atameken.kz) and thin pages.dev sites (quell-site.pages.dev, 247quitsmoking-com.pages.dev). — [WebSearch results](https://www.exprogram.com/about-quitting/how-to-quit/zyn-and-other-oral-nicotine-pouches), [Birches Health](https://bircheshealth.com/resources/zyn-addiction-nicotine-pouches), [Truth Initiative](https://truthinitiative.org/research-resources/emerging-tobacco-products/can-oral-nicotine-pouches-zyn-help-people-quit-vaping)
- EX Program's advice is to step 6 mg or 9 mg pouches down to 3 mg, wait longer between pouches, and use NRT, noting that pouches are not NRT. The quitline is 1-800-QUIT-NOW. — [EX Program](https://www.exprogram.com/about-quitting/how-to-quit/zyn-and-other-oral-nicotine-pouches)

**Demand context for pouches:**
- 2025 NYTS: about 1.7% current youth pouch use (about 460,000 students), flat versus 2024 (secondary summary of a NEJM Evidence paper). A 2026 *Addiction* survey reports 11.5% have tried a pouch and 9.3% have tried Zyn. — [Takeroon (secondary, commercial)](https://www.takeroon.com/blog/nicotine-pouch-statistics-2026-youth-survey)
- In a University of Michigan MyVoice poll, 86% of 14-24-year-olds think doctors should ask young people about Zyn use. — [Michigan Medicine](https://www.michiganmedicine.org/health-lab/nicotine-pouches-youth-survey-shows-opportunity-prevention)

### Inferences
- **Underserved niches (priority order):**
  1. **Zyn/pouch quitting long-tail.** Candidate pages: "Zyn withdrawal timeline", "quit Zyn cold turkey vs taper", "Zyn 6mg to 3mg taper plan", "Zyn vs nicotine gum / lozenge (switching to NRT)", "what happens when you quit nicotine pouches", "Zyn withdrawal headache/anxiety/nausea", "quit Zyn weight gain", "Zyn vs vape vs cigarettes nicotine". The SERP has one authoritative nonprofit plus spam, and DayXero's pouch taper feature is a genuine differentiator.
  2. **Symptom-by-symptom withdrawal pages** (headache, insomnia, brain fog, anxiety, depression, dizziness, chest tightness, constipation, hunger): "how long does X last after quitting nicotine/vaping". Each needs a clear "when to see a doctor" box.
  3. **Timeline variants:** by hour, day by day, for vaping, Zyn, cold turkey and with patches. Build these as sections or anchors of a strong hub, or as a few separate pages where intent truly differs (vaping vs pouch).
  4. **"Cravings years after quitting" / "cravings never go away".** These are relapse-prevention content and fit the app's slip-not-reset philosophy.
  5. **Commercial-investigation terms:** "best app to quit vaping", "quit zyn app", "quit vaping app free", "quit smoking app money saved". Write an honest comparison page ("Best apps to quit vaping in 2026, including free government ones"), disclose that DayXero is ours, and include This Is Quitting and quitSTART.
  6. **Pregnancy queries** ("how to quit vaping while pregnant"). These are high-YMYL and should only be written with a clinician reviewer, or deferred.
- "reddit" modifiers on almost every seed show that searchers want lived experience. That supports first-person "Experience" content: anonymised user stories post-launch, founder quit diary, and quoted Reddit-style FAQs answered with sources.
- Avoid "vape calculator" as a target; its autocomplete is hardware intent (ohm, coil, watts). Use "vape nicotine calculator" or "how many cigarettes is a Geek Bar / 5000 puffs" instead.

### Gaps
- I have no absolute search volumes or keyword difficulty scores. Free next steps: Google Keyword Planner (free with an Ads account, ranges only), Ahrefs free Keyword Generator, Semrush free tier (10 lookups/day), Google Trends comparisons (e.g. "quit zyn" vs "quit vaping"), and Search Console impressions once indexed.
- I did not capture People Also Ask boxes directly; the search tool does not return them.

## 4. Competitors: who ranks, their content formats, and where a new site can compete

### Takeaway
SERPs for quit-nicotine queries split into (a) government and nonprofit authorities (smokefree.gov, CDC, NHS, Truth Initiative's This Is Quitting and EX Program, Mayo Clinic), which own head and medical terms, and (b) app-store aggregators and app comparison posts for "best app" queries. App competitors (QuitSure, Smoke Free, Quit Genius, Kwit, Flamy, Puff Count, Quit Vaping by Jonathan Kopp) win mainly through App Store visibility and ratings, not deep editorial SEO. A new site can compete on pouch and symptom long-tail, on tools, and on honest app-comparison content, not on "how to quit smoking".

### Cited Findings
- "Best app to quit vaping 2026" results are dominated by app-aggregator pages (appshunter.io topic pages, appfollow, appgoblin) and a pages.dev "best quit vaping apps" list. Recurring names: This Is Quitting (Truth Initiative), quitSTART (NCI), My QuitBuddy (Australian Dept. of Health), Quit Vaping (Jonathan Kopp; about 4.9 stars from about 11K ratings), Exhale, Puff Count, Escape the Vape, Puffless. — [appshunter](https://appshunter.io/ios/topics/app-for-quitting-vape-addiction), [247quitsmoking pages.dev](https://247quitsmoking-com.pages.dev/article/best-quit-vaping-apps-resources/), [appfollow](https://apps.appfollow.io/ios/quit-vaping/1479615245?country=br)
- QuitSure's App Store listing claims "Trusted by 2 million+" with a "95% success" claim and no source. It runs a 6-day program. — [App Store: QuitSure](https://apps.apple.com/us/app/quitsure-quit-smoking-vaping/id1523992725)
- Quit Genius's CEO claims a 36% cessation rate (company-sourced). — [Benefit News](https://www.benefitnews.com/advisers/opinion/mobile-app-helps-smokers-and-vapers-kick-the-habit)
- A competitor app blog (heycravo, on pages.dev) publishes "vaping withdrawal" articles and "Smoke Free vs Kwit vs QuitSure vs Cravo" comparisons. This shows that small apps already target comparison keywords. — [heycravo blog](https://heycravo-web.pages.dev/blog/)
- Pouch SERP: see section 3 (EX Program, Truth Initiative, Birches Health, Ubie, commercial sellers, spam). — [EX Program](https://www.exprogram.com/about-quitting/how-to-quit/zyn-and-other-oral-nicotine-pouches)

### Inferences
- Content formats that rank in this space:
  - **.gov/NHS:** short, scannable symptom and benefit lists, plus quitlines and free apps (smokefree.gov also offers texting programs and quitSTART).
  - **Truth/EX:** program-style step guides co-branded with Mayo Clinic, plus a research library.
  - **Telehealth (Birches, Quit Genius):** clinician-attributed articles.
  - **Apps:** comparison listicles, "X vs Y" pages, and App Store listing optimisation.
- DayXero's differentiators to turn into content: Quit Day prep (5 days), slip-not-reset, urge surfing (ACT), and NRT/pouch taper plans. These map to "cold turkey or taper", "relapse after quitting", "urge surfing" and "taper Zyn" queries, where competitors are thin.
- Do not use QuitSure-style unsourced success-rate claims. They are a liability under E-E-A-T and FTC health-claim scrutiny, and they are the opposite of DayXero's "honest" positioning.
- Link out to and recommend free government tools (This Is Quitting, quitSTART, 1-800-QUIT-NOW). This builds trust, and these organisations are a source of resource-page links.

### Gaps
- I did not directly fetch smokefree.gov, CDC, NHS, Kwit, Flamy, Puff Count or Smoke Free sites, so their exact tool inventories are unverified. No backlink or traffic data was available for competitors (Ahrefs and Semrush free tiers would show top pages).

## 5. YMYL / E-E-A-T requirements and $0 ways to meet them

### Takeaway
Google says trust is the most important part of E-E-A-T. It "strongly encourage[s]" accurate bylines, and it warns against fake authors and AI headshots. For a quit-nicotine health site, the current "DayXero team" Organization authorship and homepage-level citations are the weakest point. At $0, use a real named founder byline with a "why I built this" experience story, recruit a volunteer or reciprocal medical reviewer (pharmacist, tobacco treatment specialist, or nurse), cite specific primary sources, add a visible review date, and publish an editorial policy.

### Cited Findings
- "Of these aspects, trust is most important." E-E-A-T is not itself a ranking factor; it is assessed through a mix of signals. Content on YMYL topics (health and well-being) gets extra weight for strong E-E-A-T. — [Google: Creating helpful content](https://developers.google.com/search/docs/fundamentals/creating-helpful-content)
- "We strongly encourage adding accurate authorship information, such as bylines to content where readers might expect it." Google warns against made-up names or AI-generated headshots used to fake expertise. It recommends disclosing How content was made (including AI use) and Why. — [Google: Creating helpful content](https://developers.google.com/search/docs/fundamentals/creating-helpful-content)
- Current site: guides are "written by the DayXero team". Article.author is the Organization. Sources are homepage links. — [about/index.html](/home/user/DAYXERO/website/about/index.html), [build_guides.py](/home/user/DAYXERO/scripts/website/build_guides.py)
- The EX Program presents itself as co-developed with Mayo Clinic. That kind of clinical-partner signal is what ranks on pouch queries. — [EX Program](https://www.exprogram.com/about-quitting/how-to-quit/zyn-and-other-oral-nicotine-pouches)

### Inferences
Practical $0 checklist:
1. **Named author pages** (/authors/name/) with a real photo, role, LinkedIn, and personal nicotine history if true. Use Person schema linked via `author` and `sameAs`. Do not invent personas.
2. **Medical reviewer.** Ask a pharmacist, a Certified Tobacco Treatment Specialist (CTTS), a respiratory therapist or a nurse. Possible sources: LinkedIn, university tobacco-treatment programs, or r/pharmacy contacts. Offer a byline, a backlink and early app access in exchange for review. Mark reviewed pages with "Medically reviewed by X, credential, on date". Use `reviewedBy` and `lastReviewed` on a WebPage/MedicalWebPage. Only claim what is true.
3. **Deep-link citations** to specific pages: CDC withdrawal pages, the NCI/Smokefree.gov page, Cochrane reviews on NRT and cytisine, the USPSTF recommendation, and NEJM/JAMA papers on pouches. Use inline numbered references, not just a footer list.
4. **Editorial and medical review policy page** covering sources hierarchy, update cadence, AI-use disclosure, corrections log and conflicts of interest ("we make a paid app").
5. **Visible "Last reviewed" plus a changelog** per guide. Make `dateModified` real; today the generator stamps a single DATE on all pages.
6. **Experience layer:** a founder quit log and (post-launch) consented user stories. This matches the "reddit" intent.
7. **Safety boxes** on every symptom page ("call 911 / see a doctor if chest pain…") and teen and pregnancy notes linking to official resources.
8. Keep the "not medical advice" disclaimer, but don't rely on it as an E-E-A-T signal.

### Gaps
- I did not quote the Search Quality Rater Guidelines (the current 2025 edition) directly. The guidance on YMYL "harm" and reputation research should be checked there.
- I have no data on how much a medical reviewer byline improves rankings. It is widely recommended, but there is no controlled evidence.

## 6. Free tools and interactive pages for links and traffic; programmatic SEO

### Takeaway
Calculator and converter pages fit DayXero best. They earn links from schools, quitlines and journalists, and they rank on long-tail. The homepage already has a "Calculate Your Freedom" calculator (#calculator), but it is buried in a 112 KB landing page and cannot rank on its own. Break it out into standalone tool URLs. Existing vape-to-cigarette calculators are mostly spammy or commercial and use inconsistent numbers, so a transparent, sourced methodology is the differentiator. Programmatic SEO should stay small and data-backed (per product or brand nicotine pages, per-symptom pages). Mass-generated YMYL pages are a scaled-content-abuse risk.

### Cited Findings
- The homepage has an H2 "Calculate Your Freedom" and a nav anchor #calculator. — [index.html](/home/user/DAYXERO/website/index.html)
- The SERP for "vape nicotine to cigarettes calculator" is dominated by spam on hijacked domains ("Vape to Cigarette Calculator | Equivalence Tool" on unrelated .br/.go.id domains), vape retailers (headshop.com, vaporauthority.com, vapekit.co.uk) and a pages.dev "Nicotine Calculator". Sources disagree on absorbed nicotine per cigarette (about 1 mg vs 1.0-1.8 mg) and on puff equivalence (about 10 puffs vs 15-30 puffs per cigarette). — [healthcalculatoronline pages.dev](https://healthcalculatoronline.pages.dev/nicotine-calculator/), [headshop.com](https://www.headshop.com/blogs/vapes/how-many-puffs-of-vape-is-equal-to-a-cigarette), [vaporauthority](https://www.vaporauthority.com/blogs/vaping-tips/how-many-cigarettes-are-equivalent-to-a-disposable-vape)
- An NHS-attributed comparison of how many cigarettes one disposable vape equals made national news in 2023. This shows journalist appetite for equivalence numbers. — [LADbible](https://www.ladbible.com/news/health/nhs-how-many-cigarettes-disposable-vape-equivalent-to-975974-20231121)
- Autocomplete demand: "how much nicotine in a geek bar / a vape / zyn / copenhagen pouches", "quit smoking app money saved", "nicotine withdrawal timeline by hour". — suggestqueries (section 3)

### Inferences
Tool roadmap (each on its own URL, server-rendered explanatory text, methodology and sources, embeddable via iframe snippet with attribution link):
1. **/tools/quit-vaping-money-calculator/** (also smoking and pouches): annual and 5-year savings plus "what that buys". Uses state average prices; cite sources or let the user input their price.
2. **/tools/vape-to-cigarette-nicotine-calculator/**: mg/mL × mL or pod count → mg nicotine → cigarette range. Show a range, not a point estimate, and explain bioavailability uncertainty. This is the honest-methodology angle.
3. **/tools/zyn-nicotine-equivalent/**: pouch mg × count/day vs cigarettes, vape and NRT gum/lozenge. Feeds "switch to NRT" content and the app's taper feature.
4. **/tools/zyn-taper-plan-generator/**: current strength and count → week-by-week step-down (6 → 3 mg, fewer pouches). Generate a printable plan, and collect the waitlist email here ("get this plan in the app at launch"). Add a "talk to a pharmacist" caveat.
5. **/tools/nicotine-withdrawal-timeline/** (interactive): enter your quit date and time, see where you are now (hours, days) and what to expect. Captures "by hour" and "day by day" intent and makes a natural app hook.
6. **/tools/quit-date-planner/**: pick a Quit Day 5-14 days out and get a prep checklist plus .ics calendar file. This mirrors the app's core concept.

Programmatic, but bounded:
- **Product nicotine pages:** "How much nicotine is in a Geek Bar Pulse / Elf Bar / Zyn 6 mg / Velo / On!". About 20-40 pages built from manufacturer-stated specs, each with a "how many cigarettes" range and links to the quit guide. Cite spec sources and date them. Brand names in titles are fine for informational use; avoid logos.
- **Symptom × product pages:** e.g. "Zyn withdrawal headache", "vape withdrawal insomnia". Only publish where you can write distinct, reviewed content. Ten great pages beat 200 thin ones.
- **"Days since quitting" milestones:** "What happens 3 days / 1 week / 1 month after quitting vaping". This is common competitor content; aggregate into one strong page with anchors rather than 30 thin URLs.
- **US state quitline pages** (50 pages: free NRT eligibility per state quitline). These are useful and linkable from state programs, but require verified, maintained data. This is a later-phase item.

### Gaps
- I did not verify which competitor sites host savings calculators (smokefree.gov, NHS and app sites). Nicotine absorption figures need primary pharmacology sources (e.g. Benowitz reviews) before any tool ships. Searches returned only commercial sources.

## 7. Pre-launch technical SEO (Search Console, Bing, IndexNow, schema for an unreleased app, CWV)

### Takeaway
Verify Google Search Console (Domain property via Cloudflare DNS) and Bing Webmaster Tools (import from GSC) now, and submit the sitemap. Turn on Cloudflare Crawler Hints, a free one-click option that sends IndexNow pings to Bing, Yandex and others; Google does not use IndexNow. Remove or strip the MobileApplication Offers until the app is live. Fix the 307s and the duplicate hosts. Measure CWV and slim the homepage.

### Cited Findings
- Cloudflare Crawler Hints is free for all Cloudflare customers and integrates IndexNow, which notifies search engines when content is created, updated or deleted. Bing and Yandex were launch partners. As of the 2021-22 sources, Google had not adopted IndexNow. — [Cloudflare blog](https://blog.cloudflare.com/cloudflare-now-supports-indexnow/), [Bing Webmaster blog](https://blogs.bing.com/webmaster/november-2021/Cloudflare-Supports-IndexNow-via-one-click-Integration), [Search Engine Land](https://searchengineland.com/60000-websites-using-cloudflare-turned-on-indexnow-376579)
- Software-app rich result requirements (name, offers.price, aggregateRating or review) and structured-data policies (no non-visible or misleading markup) are in section 1. — [Google software app](https://developers.google.com/search/docs/appearance/structured-data/software-app), [Google SD policies](https://developers.google.com/search/docs/appearance/structured-data/sd-policies)
- Trailing-slash 307 behaviour and options are in section 1. — [Cloudflare html-handling](https://developers.cloudflare.com/workers/static-assets/routing/advanced/html-handling/)
- The International Targeting report has been removed, so geotargeting cannot be set in Search Console. — [Google Help](https://support.google.com/webmasters/answer/12474899?hl=en)

### Inferences
Pre-launch technical checklist:
1. Decide the domain (section 2) **before** verifying and submitting, or verify both and use Change of Address.
2. GSC Domain property; submit sitemap.xml; URL-inspect and request indexing for the 5 guides plus home.
3. Bing Webmaster Tools via GSC import, which also feeds ChatGPT search and Copilot (Bing-index based). Turn on Cloudflare Crawler Hints. Note: Crawler Hints is a zone-level setting; confirm it fires for Worker static-asset responses (unverified).
4. **Schema changes:**
   - Keep Organization (add `sameAs` for social profiles and `contactPoint`) and WebSite.
   - Change MobileApplication to drop `offers` (or set a single `Offer` with `availability: https://schema.org/PreOrder` only once an App Store pre-order exists, with `url` to apps.apple.com).
   - Never add self-made aggregateRating.
   - Change guide Article to MedicalWebPage or Article with Person `author`, `reviewedBy` and `lastReviewed` once real.
   - FAQPage is harmless but gives no rich result.
   - Per-page `dateModified` should be real.
5. Redirects: force-trailing-slash or a 301 Worker rule. Canonicalise www to apex with 301. Disable workers.dev and preview URLs in production.
6. CWV: self-host and subset fonts (1 variable Inter plus JetBrains Mono 1 weight, `font-display: swap`, preload). Defer and externalise the 25 KB inline script. Compress logo.png (221 KB) to WebP or SVG. Give each guide its own OG image (also good for social CTR). Run PageSpeed Insights for mobile LCP, INP and CLS.
7. Add a real waitlist form (Cloudflare Worker plus D1/KV, or a free tier of Buttondown/Kit/Formspree). Add a `/launch` or `/waitlist` page that can rank for "DayXero" brand queries and be linked from PR.
8. Post-launch: add `<meta name="apple-itunes-app" content="app-id=…">` (Smart App Banner) and App Store links on all CTAs.
9. Add an `llms.txt` (optional and unproven) and make sure Cloudflare's AI-bot blocking settings don't block OAI-SearchBot or PerplexityBot if AI citation visibility is wanted.

### Gaps
- I did not confirm Google's 2026 stance on IndexNow; my sources are 2021-22. Re-check before relying on it for Google.
- I did not verify whether Cloudflare's default AI-crawler blocking is enabled on this zone.

## 8. AI Overviews / AI Mode impact on health queries (late 2026)

### Takeaway
Health informational queries are among the most AI-Overview-heavy categories, and AIO presence substantially cuts organic CTR. Plan for fewer clicks on "what are nicotine withdrawal symptoms"-type pages, and aim to be cited inside AIOs (clear, sourced, structured answers; strong E-E-A-T). Tools, plans and experience content are less replaceable by an AI summary and convert to waitlist sign-ups better.

### Cited Findings
- Seer Interactive data (as reported): organic CTR on AIO queries fell from 1.76% (June 2024) to 0.61% (September 2025), partially recovering to 2.4% by February 2026, versus 3.8% on non-AIO queries (5.47M queries). — reported via [Keywords Everywhere AIO tracker](https://keywordseverywhere.com/news/ai-overviews/) (secondary)
- Ahrefs: an AIO correlates with about 58% lower CTR for position 1. Pew: an 8% click rate with an AI summary versus 15% without. — reported via [Keywords Everywhere](https://keywordseverywhere.com/news/ai-overviews/) (secondary)
- Estimates of AIO prevalence on healthcare queries vary widely (30-50%, 51% and about 88%) across vendor blogs. — [thinkbasis](https://thinkbasis.com/articles/healthcare-seo-2026/), [210 Digital](https://www.210digitalmarketing.com/healthcare-ai-overviews-optimization/), [upgrowth](https://upgrowth.in/google-ai-overviews-healthcare-traffic-data/) (vendor sources, low reliability)
- Academic work found AIOs on 84% of baby care and pregnancy queries, with inconsistent information and missing safeguards. — [arXiv 2609.06798](https://arxiv.org/pdf/2609.06798), [arXiv 2608.04831](https://arxiv.org/pdf/2608.04831)

### Inferences
- Expect "nicotine withdrawal symptoms" style pages to earn impressions and AIO citations rather than many clicks. Measure success by GSC impressions, AIO citations (check manually) and waitlist conversions, not only sessions.
- Formats that resist AIO: interactive tools, personalised plans, printable taper schedules, comparison tables with original testing, and first-person stories.
- Structure answers for extraction: a one-sentence answer under each question-shaped H2, tables for timelines, and cited figures.

### Gaps
- I found no study isolating quit-smoking or vaping queries' AIO rate. Google AI Mode's specific traffic share for health was not found.

## 9. App Store Optimization groundwork tied to web SEO

### Takeaway
Use the same keyword research for the App Store title, subtitle and keyword field (100 chars) as for the web. Lead with "quit vaping", "quit Zyn" and "nicotine pouches", where app competitors cluster on "quit vaping tracker". Use App Store pre-orders (available 2-180 days before release) to get a real apps.apple.com URL early. That URL enables honest PreOrder schema, a Smart App Banner, and links from PR, while the website waitlist captures emails.

### Cited Findings
- App Store pre-orders: release date 2-180 days out. Free and paid apps are eligible. Paid pre-orders are charged on release. For a first release, rescheduling must stay within 180 days of initial pre-order publication in that region. — [Apple App Store Connect Help](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/publish-for-pre-order); [AppleInsider (2020)](https://appleinsider.com/articles/20/10/15/developers-can-now-offer-app-store-pre-orders-180-days-ahead-of-release)
- Competitor app names cluster on "Quit Vaping", "Quit Vaping Tracker", "Stop Vaping", "Quit Vaping & Smoking Tracker", "NoPuff", "Puff Count". Appgoblin exposes per-app keyword rankings for free. — [appgoblin keyword pages](https://appgoblin.info/apps/com.frostrabbitcompany.puff_count/keywords/ranking), [appshunter topics](https://appshunter.io/ios/topics/quit-vaping-tracker)
- Autocomplete shows "quit zyn app" and "quit vaping app free" as live queries. — suggestqueries (section 3)

### Inferences
- The App Store name/subtitle could be something like "DayXero: Quit Vaping & Zyn" with subtitle "Quit Day plan, cravings, NRT taper", within Apple's character limits and rules. In the keyword field, avoid repeating words already in the title. Candidates: smoking, nicotine, pouches, cigarettes, cravings, withdrawal, tracker, NRT, patch, gum, snus, juul.
- Mirror App Store keywords in web landing pages: /quit-zyn-app/ or a "Quit Zyn app" section, and a comparison page.
- Start pre-orders only when the release date is reasonably firm. Missing the date damages trust and causes pre-order cancellations (Apple's rescheduling limits apply).
- Make the website's Marketing URL and Support URL in App Store Connect the final gTLD domain.
- Later, consider Custom Product Pages targeted at vaping, smoking and pouch audiences, with matching web landing pages.

### Gaps
- I did not obtain App Store search popularity scores; Apple Search Ads data needs an account. I did not verify current App Store title and subtitle character limits (30/30 historically).

## 10. $0 backlink acquisition

### Takeaway
At $0, the realistic link sources are: (1) journalist-request platforms (Source of Sources is free; Qwoted has a free tier; Help a B2B Writer; #journorequest on X and Bluesky). Featured.com, which now owns the HARO brand, is paid. (2) Original-data digital PR, e.g. an anonymous survey of pouch users' quitting attempts, or analysis of Reddit r/QuitVaping and r/QuitZyn posts. (3) Linkable tools embedded by schools and health educators. (4) Resource-page and directory listings (university wellness pages, state and teen quit resources, app directories, Product Hunt at launch). Honest, sourced content is a prerequisite, because health resource pages vet what they link to.

### Cited Findings
- HARO shut down (as Connectively) in December 2024. Featured.com acquired the HARO brand in April 2025 and relaunched it as paid (about $49-50/month per vendor blogs). Source of Sources (Peter Shankman) is free and donation-supported. Qwoted has a free tier (Pro about $99/month). Help a B2B Writer, SourceBottle and ProfNet are also cited. AI-generated pitches have flooded these platforms, so original-data pitches stand out. — [Siege Media](https://www.siegemedia.com/marketing/haro-alternatives), [Stork.ai](https://www.stork.ai/blog/haro-alternatives-2026), [blckalpaca](https://blckalpaca.at/en/knowledge-base/seo-geo/off-page-seo-link-building/haro-alternatives-2026-featured-qwoted-and-source-of-sources.md) (vendor blogs; verify current pricing)
- Journalists covered NHS vape-to-cigarette equivalence numbers widely. — [LADbible](https://www.ladbible.com/news/health/nhs-how-many-cigarettes-disposable-vape-equivalent-to-975974-20231121)
- Snusboss and Direct365 earned coverage in local US news with simple Google-search-data "state rankings" for quitting vaping. This is a replicable $0 PR format. — [WBCK](https://wbckfm.com/michigan-indiana-ohio-among-top-10-states-looking-to-quit-vaping-in-2024/), [Fox59 digital release](https://digital-release.fox59.com/news/indiana-is-the-6th-most-eager-state-to-stop-vaping), [London Loves Business](https://londonlovesbusiness.com/60-of-vaping-related-google-searches-focus-on-health-concerns)

### Inferences
Prioritised $0 link tactics:
1. **Data PR.** Candidates: "Which US states are searching most to quit Zyn" (Google Trends, free), "Zyn withdrawal: what 1,000 Reddit posts say about how long it lasts" (manual or NLP analysis of public posts; respect Reddit ToS and anonymise), and "Nicotine content of the 25 best-selling disposable vapes, in cigarette equivalents". Pitch to local TV and digital desks, health reporters and college newspapers.
2. **Expert sourcing.** Join SOS (free), Qwoted free and Help a B2B Writer. Answer quit-nicotine, Zyn, behaviour-change and app-founder queries daily. A medical reviewer can answer clinical ones.
3. **Embeddable tools** with a "Powered by DayXero" link, offered to school health teachers, college wellness centres and quit coaches.
4. **Resource pages.** Search operators: `"quit vaping" "resources" site:.edu`, `"nicotine pouches" inurl:resources`, `"quit smoking apps" inurl:links`. Pitch the free tools and guides, not the paid app.
5. **Founder/maker channels:** Indie Hackers, Product Hunt (launch day), BetaList (pre-launch, free tier), and r/SideProject. Low SEO value individually, but brand mentions and referral traffic.
6. **Podcasts:** recovery, health and indie-app podcasts.
7. **Avoid:** paid links, PBNs and guest-post farms (YMYL risk), and spammy "quit smoking directories".

### Gaps
- I did not verify a current list of reputable quit-smoking app directories or of .edu resource pages that accept submissions. I could not confirm 2026 pricing or terms for Qwoted, Featured or SOS from the platforms themselves.

## 11. Prioritised 3-6 month SEO plan

### Takeaway
Month 0-1: fix the foundations (domain decision, honest pre-launch markup and waitlist, Search Console/Bing, redirects, E-E-A-T scaffolding). Months 1-3: build the Zyn/pouch and withdrawal-symptom cluster plus 2-3 tools. Months 3-6: data-PR and journalist sourcing for links, a comparison page, product-nicotine pages, and launch-day App Store integration. Measure impressions, AIO citations and waitlist sign-ups.

### Cited Findings
- Basis for the priorities: site audit (section 1, local files), ccTLD behaviour ([Google](https://developers.google.com/search/docs/specialty/international/managing-multi-regional-sites)), structured-data policy ([Google](https://developers.google.com/search/docs/appearance/structured-data/sd-policies)), E-E-A-T ([Google](https://developers.google.com/search/docs/fundamentals/creating-helpful-content)), autocomplete demand (section 3), and AIO CTR effects ([Keywords Everywhere](https://keywordseverywhere.com/news/ai-overviews/)).

### Inferences
**P0, weeks 0-2 (highest leverage, mostly config and copy):**
1. Domain: buy a .com or .app and 301 dayxero.in to it before any outreach. If staying on .in, move the India sections to /in/.
2. Replace pricing CTAs and fake checkout toasts with a waitlist form. Add a /waitlist page. Point guide CTAs there.
3. Schema: remove the Offer array (or MobileApplication entirely) until an App Store URL exists. Add Organization `sameAs`.
4. Verify GSC and Bing; submit the sitemap; enable Crawler Hints. Disable workers.dev and preview hosts; switch to force-trailing-slash or a 301; canonicalise www.
5. Homepage H1 and H2s: include "quit vaping, smoking and nicotine pouches (Zyn)" wording.
6. E-E-A-T: named founder byline and author page, editorial policy, deep-linked citations, real dateModified. Start recruiting a medical reviewer.

**P1, weeks 2-8 (content and tools):**
7. Pouch cluster (4-6 pages): Zyn withdrawal timeline; quit Zyn cold turkey vs taper; Zyn taper plan (6 → 3 mg); Zyn vs nicotine gum/lozenge (switching to NRT); what happens when you quit nicotine pouches. Rename or expand /quit-nicotine-pouches/ to put "Zyn" in the H1.
8. Symptom pages (6-8): headache, insomnia, anxiety, brain fog, depression or low mood, dizziness, hunger/weight gain, and "cravings years after quitting". Each gets a reviewed safety box.
9. Tools: money-saved calculator (break it out from the homepage), Zyn/vape nicotine equivalence calculator with a methodology page, and an interactive "where am I in withdrawal" timeline. Every tool has a waitlist hook.
10. Upgrade the withdrawal timeline hub with by-hour, day-by-day, vaping, pouch and patch sections and a table.
11. Self-host fonts, defer JS, compress logo, per-page OG images. Measure with PSI.

**P2, months 2-4 (authority):**
12. One data-PR study (Google Trends by state for "quit zyn" and "quit vaping", or a Reddit analysis), pitched to health and local reporters.
13. Daily SOS, Qwoted free and Help a B2B Writer responses. Founder posts on Indie Hackers. BetaList pre-launch listing.
14. Resource-page outreach to .edu wellness and teen quit pages with the tools.
15. An honest "Best apps to quit vaping (2026)" comparison including free government options, with DayXero disclosed.

**P3, months 4-6 (launch integration and scale):**
16. App Store pre-order (2-180 days before release). Then PreOrder Offer schema with the apps.apple.com URL, Smart App Banner, and App Store links in CTAs. Mirror ASO keywords on landing pages.
17. Product nicotine pages (20-40 brands and strengths), only with sourced specs.
18. Post-launch: consented user stories, and aggregateRating only via genuine App Store ratings (and not self-served markup). Product Hunt launch.
19. Iterate from GSC queries: expand pages earning impressions at positions 8-20, and prune or merge thin pages.

**KPIs:** indexed pages; GSC impressions and clicks on the pouch and symptom clusters; number of referring domains (target 10-20 genuine ones by month 6 is plausible but unverified); AIO and ChatGPT citations (manual checks); waitlist sign-ups per tool page.

### Gaps
- Timelines and KPI targets are judgement, not sourced benchmarks. The domain purchase (about $10-20/year) is the one cost that conflicts with the $0 budget, and the user needs to decide on it.
