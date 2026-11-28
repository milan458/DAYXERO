# dayxero.app SEO

How the website's search work runs, and the pace it keeps. Written 27 November 2026.

## The pace rule (read this first)

Noxium's site (getnoxium.app) went from 19 to 44 English pages plus 80 translations in one week (10-17 Nov 2026) and lost all Google visibility, even for its own name. dayxero.app is a health site, where Google is strictest on fast, thin content, so:

- **2 new pages a week.** Each one covers a topic no existing page covers. No near-duplicates, no "2026" title formula.
- **Gate before going faster:** the site is on page 1 for "dayxero", and at least 80% of pages that have been in the sitemap for 14+ days are indexed. The daily report checks both (Pace gate, under Indexing).
- **Stop rule:** if "dayxero" leaves page 1, or impressions fall by half week on week, pause new pages and find out why before adding more.
- **No translations** until English pages have had impressions for 4 weeks. Then one language at a time (German first), a few pages, not the whole site.

## The daily Search Console report

`scripts/seo/seo-daily.py` pulls Search Console data through gum and writes a report. It runs on the Mac Mini, the only machine where gum is signed in to Google. It is a copy of the Noxium site's tools/seo-daily.py, set to dayxero.app.

Search Console properties: `https://dayxero.app/` (URL prefix, the live site) and `sc-domain:dayxero.in` (the old domain).

```
cd ~/DAYXERO && git pull
python3 scripts/seo/seo-daily.py                       # today's report for dayxero.app
cat ~/seo-data/dayxero-app/reports/latest.md
python3 scripts/seo/seo-daily.py --install             # run it every day at 09:07
python3 scripts/seo/seo-daily.py --site sc-domain:dayxero.in --no-inspect   # the old domain, once
```

Add `--sheet` to `--install`, or run `--sheet-only` once, to also keep the numbers in a Google Sheet ("Search Console: dayxero.app") that any Claude session can read. `--publish` pushes the summary to the private repo that `~/seo-data` is a clone of; that is the Noxium data repo today, so its dayxero-app folder would sit next to getnoxium-app.

What to do with each section:
- **Striking distance (positions 4-20):** improve the page that ranks. Put the query in the title, answer it in the first sentence, link to it from related guides. Do this before writing new pages.
- **Pages competing for the same query:** pick one page to rank and link to it from the other.
- **Indexing:** a page that stays unindexed for 2+ weeks is too thin or too close to another page. Improve or merge it; don't add more like it.
- **Pace gate:** follows the rule above.

## Plan

Week 1, fixes only, no new pages (built 28 Nov 2026 unless marked):
1. Done: the homepage H1 opens with "Quit vaping, smoking and nicotine pouches"; the brand line stays as the big headline.
2. Done: guides carry a named byline (`AUTHOR_NAME` in scripts/website/build_guides.py, Person in the structured data), About has a "Who makes DayXero" section (#author) and a fuller editorial policy (#editorial), including that no clinician has reviewed the guides yet.
3. Done: each page has its own "last updated" date (`UPDATED` in build_guides.py, also used for the sitemap's lastmod). Each guide links specific source pages and studies inline and in its Sources list.
4. Done: website/_redirects sends /about to /about/ (and every other page folder) with a 301. website/_headers adds `X-Robots-Tag: noindex` on workers.dev and preview hosts. Left as is: hello@dayxero.in in the structured data, because it is the address the whole site and the privacy policy use.
5. Yours: submit https://dayxero.app/sitemap.xml in Search Console (Sitemaps), and add the site to Bing Webmaster Tools (import from Search Console).
6. On App Store launch: App Store link and Smart App Banner on every page, App Store URL in the structured data.

Every new page from week 2 on: add it to build_guides.py (or the sitemap), give it a date in `UPDATED`, and add its folder to website/_redirects.

Weeks 2-9, about 16 new pages at 2 a week:
- Pouches: Zyn withdrawal timeline; quit Zyn cold turkey or taper; Zyn taper plan (6 mg to 3 mg); Zyn vs nicotine gum or lozenge.
- Symptoms, each with a "when to see a doctor" box: headache, sleep, anxiety, brain fog, hunger and weight, cravings years after quitting.
- Tools: money-saved calculator (out of the homepage) and a "where am I in withdrawal" timeline from your quit date.
- One honest "best apps to quit vaping" page that includes free government options and says DayXero is ours.
- Withdrawal timeline hub gains by-hour and day-by-day sections instead of separate thin pages.

Background research: research_notes/DayXero prelaunch waitlist marketing/seo_audit_and_plan.md (keywords, tool ideas, competitors).
