"""Generates the DayXero guide pages, the guides hub and sitemap.xml.

Run from the repo root: python3 scripts/website/build_guides.py website
Then rebuild the CSS: npm run website:css
"""
import html
import json
import pathlib
import sys

SITE = pathlib.Path(sys.argv[1])
BASE = "https://dayxero.in"
DATE = "2026-10-29"
CONTACT_EMAIL = "hello@dayxero.in"

SOURCES = {
    "who": ("World Health Organization: Tobacco fact sheet", "https://www.who.int/news-room/fact-sheets/detail/tobacco"),
    "nhs": ("NHS Better Health: Quit smoking", "https://www.nhs.uk/better-health/quit-smoking/"),
    "cdc": ("CDC: Smoking and tobacco use", "https://www.cdc.gov/tobacco/"),
    "sf": ("Smokefree.gov (US National Cancer Institute)", "https://smokefree.gov/"),
    "teen": ("Smokefree Teen: Quit vaping", "https://teen.smokefree.gov/"),
    "ntcp": ("India National Tobacco Control Programme (MoHFW)", "https://ntcp.mohfw.gov.in/"),
}

HELPLINES = """
<h2 id="help">Free help, wherever you are</h2>
<p>Quitlines put you in touch with a trained coach, and they work well alongside an app like DayXero. These services are free:</p>
<ul>
  <li><strong>India:</strong> National Tobacco Quitline, <a href="tel:18001122356">1800-11-2356</a> (toll-free)</li>
  <li><strong>United States:</strong> <a href="tel:18007848669">1-800-QUIT-NOW</a> (1-800-784-8669)</li>
  <li><strong>United Kingdom:</strong> NHS Smokefree National Helpline, <a href="tel:03001231044">0300 123 1044</a></li>
</ul>
"""

DISCLAIMER = ("This guide is general information, not medical advice. If you are pregnant, have a heart condition, "
              "take regular medicine or are under 18, talk to a doctor or pharmacist before using nicotine "
              "replacement or stop-smoking medicines.")

GUIDES = []


def guide(slug, title, meta, h1, kicker, intro, body, faqs, sources, related):
    GUIDES.append(dict(slug=slug, title=title, meta=meta, h1=h1, kicker=kicker, intro=intro,
                       body=body, faqs=faqs, sources=sources, related=related))


guide(
    slug="quit-vaping",
    title="How to Quit Vaping: A Step-by-Step Plan | DayXero",
    meta="A practical plan to quit vaping: pick a Quit Day, prepare for it, ride out cravings in minutes, "
         "handle withdrawal and use nicotine replacement safely.",
    h1="How to Quit Vaping: A Step-by-Step Plan",
    kicker="Quit vaping",
    intro="Vaping is easy to start and hard to stop, because you can do it almost anywhere. The habit ends up "
          "attached to waking up, driving, studying, stress and boredom all at once. Willpower alone rarely "
          "beats that. A plan does. Here is the one DayXero is built around.",
    body="""
<h2 id="why">Why quitting vaping feels so hard</h2>
<p>Most vapes deliver nicotine, and nicotine is highly addictive. Two things make vaping especially sticky:</p>
<ul>
  <li><strong>No natural stopping point.</strong> A cigarette ends. A vape doesn't, so many people take small puffs all day long.</li>
  <li><strong>Strong nicotine salts.</strong> Many disposables and pods use high-strength nicotine salts, which feel smooth and deliver a lot of nicotine quickly.</li>
</ul>
<p>The upside: the same thing that makes vaping constant (lots of small, cue-driven puffs) also gives you lots of chances to break the pattern.</p>

<h2 id="step-1">Step 1: Pick a Quit Day, not "today"</h2>
<p>Choose a date one to two weeks away. A fixed Quit Day gives you time to prepare, and stop-smoking services such as the NHS build their programmes around one. Pick a day that's normal for you, not your most stressful week or a big night out.</p>

<h2 id="step-2">Step 2: Learn your triggers before you quit</h2>
<p>For three to five days, keep vaping as usual but note when you reach for it: what you were doing, where you were and how you felt. Most people find the same handful of triggers:</p>
<ul>
  <li>Waking up and the first coffee</li>
  <li>After meals</li>
  <li>Driving, commuting or walking between places</li>
  <li>Stress, boredom or a hard moment at work or study</li>
  <li>Alcohol and being around other people who vape</li>
</ul>
<p>For each trigger, decide now what you'll do instead on Quit Day. A plan made in advance is much easier to follow than one made mid-craving.</p>

<h2 id="step-3">Step 3: Decide how you'll stop</h2>
<p>There are two common approaches, and both can work:</p>
<ul>
  <li><strong>Stop completely on Quit Day.</strong> Simple and clear. Best paired with a strong plan for cravings and, if you're very dependent, nicotine replacement.</li>
  <li><strong>Cut down first, then stop.</strong> Lower your e-liquid strength step by step, delay your first vape of the day, and set vape-free places (bedroom, car) before Quit Day.</li>
</ul>
<p>A useful rule of thumb: if you vape within 30 minutes of waking up, you're likely quite dependent, and nicotine replacement can make the first weeks much easier.</p>

<h2 id="step-4">Step 4: Ask about nicotine replacement</h2>
<p>Licensed nicotine replacement therapy (NRT) such as patches, gum, lozenges and mouth spray gives you controlled doses of nicotine without the vape, and is designed to be stepped down. Combining a patch with a fast-acting product for breakthrough cravings works better than either one alone for smokers. Research on NRT specifically for quitting vaping is newer, but clinicians commonly use it. A pharmacist can help you pick a starting dose.</p>

<h2 id="step-5">Step 5: Clear out and tell people</h2>
<p>The night before your Quit Day, get rid of devices, pods, spare disposables and chargers. Tell a few people you trust, and ask friends not to offer you a vape. Removing easy access matters most in the first week.</p>

<h2 id="step-6">Step 6: Ride out cravings, don't fight them</h2>
<p>A craving rises, peaks and fades, usually within a few minutes. Trying to push it away tends to make it louder. <a href="/nicotine-cravings/">Urge surfing</a> works the other way: notice where you feel it, breathe slowly, and watch it pass like a wave. DayXero's Craving SOS walks you through this in three minutes.</p>

<h2 id="step-7">Step 7: Treat a slip as information</h2>
<p>One puff isn't a relapse, and it doesn't erase your progress. The danger is the "I've blown it anyway" thinking that turns one slip into a week of vaping. Note what triggered it, adjust your plan, and carry on. That's why DayXero never resets your streak for a slip.</p>

<h2 id="withdrawal">What withdrawal will feel like</h2>
<p>Expect irritability, restlessness, poor concentration, trouble sleeping and stronger appetite. Symptoms usually start within hours, are strongest in the first few days, and ease over two to four weeks. See the full <a href="/nicotine-withdrawal-timeline/">nicotine withdrawal timeline</a>.</p>

<h2 id="india">A note for readers in India</h2>
<p>E-cigarettes have been banned in India since 2019 under the Prohibition of Electronic Cigarettes Act. If you vape in India, quitting also takes you out of a market where products aren't legally sold or checked.</p>
""" + HELPLINES,
    faqs=[
        ("How long does it take to quit vaping?",
         "Most physical withdrawal symptoms ease within two to four weeks of your last vape. Cravings can still "
         "show up for a few months, especially around old triggers, but they become weaker and less frequent."),
        ("Is it better to quit vaping cold turkey or gradually?",
         "Both can work. Stopping completely on a planned Quit Day is simple and clear. Cutting down first, by "
         "lowering nicotine strength and adding vape-free times, can help if you're very dependent. What matters "
         "most is having a plan for cravings either way."),
        ("Can I use nicotine patches to quit vaping?",
         "Yes, many people do. Patches, gum, lozenges and mouth spray give controlled doses of nicotine that you "
         "step down over time. Ask a pharmacist or doctor which strength to start with."),
        ("What helps with vape cravings?",
         "Cravings usually pass within a few minutes. Slow breathing, urge surfing, drinking water, moving your "
         "body and changing your surroundings all help you ride one out without vaping."),
        ("Will I gain weight after quitting vaping?",
         "Nicotine suppresses appetite, so many people feel hungrier after quitting. Planning regular meals, "
         "keeping healthy snacks around and staying active helps keep this in check."),
    ],
    sources=["nhs", "teen", "sf", "ntcp"],
    related=["nicotine-withdrawal-timeline", "nicotine-cravings", "quit-nicotine-pouches"],
)

guide(
    slug="quit-smoking",
    title="How to Quit Smoking: Plan Your Quit Day | DayXero",
    meta="How to quit smoking for good: set a Quit Day, plan for your triggers, choose stop-smoking aids and "
         "see what happens to your body after you quit.",
    h1="How to Quit Smoking: A Quit Day Plan That Works",
    kicker="Quit smoking",
    intro="Quitting smoking is one of the best things you can do for your health, and it's rarely a matter of "
          "willpower alone. People who prepare, use stop-smoking aids and get support have the best odds. "
          "This guide walks you through each step, from choosing your Quit Day to the months after.",
    body="""
<h2 id="plan">Why a plan beats willpower</h2>
<p>Smoking is two things at once: a nicotine addiction and a set of habits tied to your day. Nicotine withdrawal makes the first weeks uncomfortable, and habits (the cigarette with coffee, after meals, on a break) set off cravings automatically. A good quit plan deals with both.</p>

<h2 id="quit-day">Step 1: Set your Quit Day</h2>
<p>Pick a date one to two weeks away and write it down. This gives you time to prepare without losing momentum. Avoid a day you already know will be stressful.</p>

<h2 id="prepare">Step 2: Prepare in the days before</h2>
<ul>
  <li><strong>Map your triggers.</strong> Note each cigarette for a few days: time, place, mood. Most people smoke at the same moments every day.</li>
  <li><strong>Plan a swap for each trigger.</strong> A walk after lunch, gum in the car, a different route on your break.</li>
  <li><strong>Tell people.</strong> Ask friends and family for support, and ask smokers around you not to offer you one.</li>
  <li><strong>Clear out.</strong> The night before Quit Day, get rid of cigarettes, lighters and ashtrays.</li>
</ul>
<p>DayXero builds this into a five-day prep phase so that by Quit Day you've already practised getting through your hardest moments.</p>

<h2 id="aids">Step 3: Choose your stop-smoking aids</h2>
<p>Using a stop-smoking aid makes quitting much more likely to succeed than willpower alone. The main options are:</p>
<ul>
  <li><strong>Nicotine replacement therapy (NRT):</strong> patches, gum, lozenges, inhalators and mouth spray. Combining a patch with a fast-acting product works better than a single product.</li>
  <li><strong>Prescription medicines:</strong> such as varenicline, cytisine or bupropion, depending on what's available where you live. A doctor can tell you whether one suits you.</li>
  <li><strong>Behavioural support:</strong> a quitline, a local stop-smoking service or an app. Support combined with medicine gives the best results.</li>
</ul>
<p>In some countries, such as the UK, health services also recommend vapes as a quit aid for adults who smoke. Vapes are banned in India, and in any case the end goal is to be free of nicotine altogether.</p>

<h2 id="first-weeks">Step 4: Get through the first two weeks</h2>
<p>The first few days are usually the hardest. Withdrawal symptoms such as irritability, anxiety, poor concentration and trouble sleeping tend to peak in the first week and ease over two to four weeks. Individual cravings are short, usually a few minutes. Have a plan for them: <a href="/nicotine-cravings/">urge surfing</a>, slow breathing, a glass of water, a short walk.</p>
<p>Not even one puff is the safest rule early on. But if you do slip, don't treat it as failure. Work out what triggered it and keep going. Most people who quit for good made more than one attempt.</p>

<h2 id="body">What happens to your body when you quit</h2>
<p>According to the World Health Organization, the benefits begin almost immediately:</p>
<div class="table-wrap"><table>
  <thead><tr><th>Time after quitting</th><th>What changes</th></tr></thead>
  <tbody>
    <tr><td>20 minutes</td><td>Heart rate and blood pressure drop.</td></tr>
    <tr><td>12 hours</td><td>Carbon monoxide in your blood drops to normal.</td></tr>
    <tr><td>2 to 12 weeks</td><td>Circulation improves and lung function increases.</td></tr>
    <tr><td>1 to 9 months</td><td>Coughing and shortness of breath decrease.</td></tr>
    <tr><td>1 year</td><td>Risk of coronary heart disease is about half that of a smoker.</td></tr>
    <tr><td>5 to 15 years</td><td>Stroke risk falls to that of a non-smoker.</td></tr>
    <tr><td>10 years</td><td>Lung cancer death rate is about half that of a smoker.</td></tr>
    <tr><td>15 years</td><td>Risk of coronary heart disease is that of a non-smoker.</td></tr>
  </tbody>
</table></div>
<p>If you take regular medicine, tell your doctor you've stopped smoking. Tobacco smoke changes how the body processes some medicines, so doses sometimes need adjusting.</p>
""" + HELPLINES,
    faqs=[
        ("What is the most effective way to quit smoking?",
         "Combining a stop-smoking aid, such as nicotine replacement or a prescription medicine, with "
         "behavioural support gives the best chance of quitting for good. Setting a Quit Day and preparing for "
         "your triggers in advance also helps."),
        ("Is quitting cold turkey a bad idea?",
         "It isn't bad, and some people succeed that way. But going cold turkey without any aids or support has "
         "lower success rates than quitting with nicotine replacement or medicine and support."),
        ("What happens after one week without smoking?",
         "By the end of the first week, nicotine has left your body, carbon monoxide levels are back to normal, "
         "and many people notice better taste and smell. Withdrawal is often still noticeable but starting to ease."),
        ("Does smoking just one cigarette matter?",
         "Early on, one cigarette makes it much easier to have another, so aim for not even a puff. If you do "
         "slip, though, it doesn't undo your progress. Learn from the trigger and continue."),
        ("How many attempts does it take to quit smoking?",
         "It varies a lot, and many people need more than one attempt. Each attempt teaches you more about your "
         "triggers, which makes the next one more likely to stick."),
    ],
    sources=["who", "nhs", "cdc", "sf", "ntcp"],
    related=["nicotine-withdrawal-timeline", "nicotine-cravings", "quit-vaping"],
)

guide(
    slug="quit-nicotine-pouches",
    title="How to Quit Nicotine Pouches (Zyn, Velo & More) | DayXero",
    meta="How to quit nicotine pouches like Zyn and Velo: track your use, taper strength and count, switch to "
         "licensed NRT if you need it, and get through withdrawal.",
    h1="How to Quit Nicotine Pouches",
    kicker="Quit pouches",
    intro="Nicotine pouches are discreet, smoke-free and easy to use all day, which is exactly why they're hard "
          "to give up. Whether you use Zyn, Velo, On! or another brand, the plan is the same: understand your "
          "use, step down on purpose, and have a plan for cravings.",
    body="""
<h2 id="why">Why pouches are hard to quit</h2>
<ul>
  <li><strong>Constant use.</strong> Because no one can see them, it's easy to have a pouch in almost all day.</li>
  <li><strong>High strengths.</strong> Pouch strengths vary widely, and some deliver a lot of nicotine.</li>
  <li><strong>Habit loops.</strong> A pouch after meals, at your desk or during a workout quickly becomes automatic.</li>
</ul>

<h2 id="track">Step 1: Track your real use</h2>
<p>For a few days, note how many pouches you use, the strength in milligrams (mg), and how long you keep each one in. Many people are surprised by the total. These numbers become the starting point for your taper.</p>

<h2 id="taper">Step 2: Taper strength and count</h2>
<p>Stepping down gradually gives your body time to adjust. A simple four-week example:</p>
<div class="table-wrap"><table>
  <thead><tr><th>Week</th><th>What to change</th></tr></thead>
  <tbody>
    <tr><td>Week 1</td><td>Keep your usual strength, cut the number of pouches by about a quarter. Add pouch-free windows, such as the first hour after waking.</td></tr>
    <tr><td>Week 2</td><td>Drop to the next lower strength and keep the lower count.</td></tr>
    <tr><td>Week 3</td><td>Halve your count again, or drop to the lowest strength. Shorten how long each pouch stays in.</td></tr>
    <tr><td>Week 4</td><td>Quit Day. Stop completely, with a plan for cravings in place.</td></tr>
  </tbody>
</table></div>
<p>This is an example, not a prescription. If you use a very high strength or a lot of pouches, a slower taper or nicotine replacement may suit you better. DayXero builds a step-down schedule from your own numbers.</p>

<h2 id="nrt">Step 3: Consider switching to licensed NRT</h2>
<p>Nicotine gum and lozenges are used in a similar way to pouches, but they are licensed medicines with clear dosing and step-down instructions. Some people switch from pouches to NRT, then taper the NRT. A pharmacist can help you choose a strength.</p>

<h2 id="cold-turkey">Step 4: Or stop on a set Quit Day</h2>
<p>Stopping all at once also works for many people, especially if your use is moderate. Set a Quit Day one to two weeks away, prepare a swap for each trigger (sugar-free gum, a mint, a drink of water), and remove every pouch from your bag, car and desk the night before.</p>

<h2 id="cravings">Step 5: Plan for cravings and withdrawal</h2>
<p>Pouch withdrawal is nicotine withdrawal: irritability, restlessness, poor focus, stronger appetite and cravings. It's usually strongest in the first few days and eases over two to four weeks. Each craving typically passes within a few minutes. See <a href="/nicotine-cravings/">how to handle nicotine cravings</a> and the <a href="/nicotine-withdrawal-timeline/">withdrawal timeline</a>.</p>
""" + HELPLINES,
    faqs=[
        ("Are nicotine pouches safer than smoking?",
         "Pouches don't involve smoke, so they avoid the tar and carbon monoxide of cigarettes. But nicotine is "
         "highly addictive, and the long-term health effects of pouches are still being studied. Being "
         "nicotine-free is the healthiest option."),
        ("How long does withdrawal from nicotine pouches last?",
         "Symptoms usually peak in the first few days and ease over two to four weeks. Occasional cravings can "
         "continue for a few months but get weaker over time."),
        ("Can I quit Zyn cold turkey?",
         "Yes. Many people stop all at once on a planned Quit Day. If you use high strengths or many pouches a "
         "day, tapering first or using nicotine gum or lozenges can make it more comfortable."),
        ("Is nicotine gum better than pouches for quitting?",
         "Nicotine gum is a licensed stop-smoking medicine with set doses and instructions for stepping down, "
         "which makes it a useful tool for tapering off nicotine. Pouches aren't designed for that."),
    ],
    sources=["nhs", "sf", "cdc"],
    related=["nicotine-withdrawal-timeline", "nicotine-cravings", "quit-vaping"],
)

guide(
    slug="nicotine-withdrawal-timeline",
    title="Nicotine Withdrawal Timeline: Symptoms Day by Day | DayXero",
    meta="When nicotine withdrawal starts, when it peaks and how long it lasts, with symptoms by stage and what "
         "helps. Applies to cigarettes, vapes and nicotine pouches.",
    h1="Nicotine Withdrawal Timeline: What to Expect and When",
    kicker="Withdrawal",
    intro="Nicotine withdrawal usually starts within a few hours of your last cigarette, vape or pouch, is "
          "strongest in the first few days, and eases over two to four weeks. Cravings can still appear for a few "
          "months, but they get weaker and less frequent. Here is what each stage tends to look like.",
    body="""
<h2 id="timeline">The timeline at a glance</h2>
<div class="table-wrap"><table>
  <thead><tr><th>When</th><th>What you might notice</th></tr></thead>
  <tbody>
    <tr><td>First hours</td><td>First cravings, restlessness and irritability as nicotine levels fall.</td></tr>
    <tr><td>Days 1 to 3</td><td>Often the hardest stretch: strong cravings, irritability, anxiety, trouble concentrating, headaches and poor sleep.</td></tr>
    <tr><td>Days 4 to 7</td><td>Symptoms are still noticeable but start to ease. Appetite often increases.</td></tr>
    <tr><td>Weeks 2 to 4</td><td>Most physical symptoms fade. Mood, focus and sleep settle. People who smoked may cough more for a while as their lungs clear.</td></tr>
    <tr><td>1 to 3 months</td><td>Occasional cravings, mostly tied to old triggers like coffee, alcohol or stress.</td></tr>
    <tr><td>After 3 months</td><td>Cravings become rare and much easier to ignore.</td></tr>
  </tbody>
</table></div>
<p>Everyone is different. How much nicotine you used, and how constantly, affects how strong withdrawal feels.</p>

<h2 id="symptoms">Common symptoms and what helps</h2>
<ul>
  <li><strong>Cravings:</strong> each one usually passes within a few minutes. Ride it out with <a href="/nicotine-cravings/">urge surfing</a> or a short distraction.</li>
  <li><strong>Irritability and anxiety:</strong> slow breathing, exercise and telling people around you what you're going through.</li>
  <li><strong>Trouble concentrating:</strong> break tasks into smaller pieces and plan lighter days for your first week.</li>
  <li><strong>Poor sleep:</strong> cut back on caffeine, which can feel stronger after you quit, and keep a regular bedtime.</li>
  <li><strong>Increased appetite:</strong> regular meals, filling snacks and plenty of water.</li>
  <li><strong>Low mood:</strong> usually temporary. Keep in touch with people and stay active.</li>
</ul>
<p>Nicotine replacement therapy eases most of these symptoms by giving you controlled, reducing doses of nicotine. Ask a pharmacist which product suits you.</p>

<h2 id="types">Is it different for vapes, cigarettes and pouches?</h2>
<p>The withdrawal itself is the same, because it comes from nicotine. What differs is the habit around it. Vapes and pouches are often used constantly through the day, so people may notice cravings in more situations at first.</p>

<h2 id="body">How long nicotine stays in your body</h2>
<p>Nicotine itself clears from the blood within a few days of stopping. Its by-product, cotinine, can be detected for longer. Physical withdrawal mostly follows the same pattern: worst early on, then fading as your brain adjusts.</p>

<h2 id="doctor">When to talk to a doctor</h2>
<p>Speak to a doctor if your mood becomes very low or you have thoughts of harming yourself, if you're pregnant, or if you have a heart condition. If you take regular medicine and you've stopped smoking, tell your doctor, because tobacco smoke changes how some medicines are processed.</p>
""" + HELPLINES,
    faqs=[
        ("How long does nicotine withdrawal last?",
         "For most people, physical withdrawal symptoms ease within two to four weeks. Occasional cravings can "
         "continue for a few months, mostly around old triggers, but they become weaker over time."),
        ("What day of nicotine withdrawal is the worst?",
         "Symptoms are usually strongest in the first three days after quitting, and often still noticeable through "
         "the first week."),
        ("How long does nicotine stay in your body?",
         "Nicotine clears from the blood within a few days of stopping. Its by-product cotinine can be detected "
         "for longer."),
        ("Can nicotine withdrawal cause anxiety?",
         "Yes. Anxiety, irritability and restlessness are common in the first weeks. They usually ease as "
         "withdrawal passes. Many people find their anxiety ends up lower than before they quit."),
        ("Why am I so hungry after quitting nicotine?",
         "Nicotine suppresses appetite and changes how you taste food, so appetite often rises after quitting. "
         "Regular meals and filling snacks help."),
    ],
    sources=["nhs", "sf", "cdc", "who"],
    related=["nicotine-cravings", "quit-vaping", "quit-smoking"],
)

guide(
    slug="nicotine-cravings",
    title="How to Handle Nicotine Cravings: Urge Surfing Guide | DayXero",
    meta="Nicotine cravings usually pass within minutes. Learn urge surfing, quick techniques that work and "
         "a plan for your biggest triggers.",
    h1="How to Handle Nicotine Cravings",
    kicker="Cravings",
    intro="A nicotine craving can feel like it will last forever, but it doesn't. Most cravings rise, peak and "
          "fade within a few minutes. The goal isn't to fight them with willpower. It's to get through those "
          "minutes without reaching for a cigarette, vape or pouch.",
    body="""
<h2 id="wave">Cravings behave like waves</h2>
<p>A craving builds, peaks and then falls away on its own, whether or not you give in. Every time you ride one out, the link between the trigger and nicotine gets a little weaker. Over the weeks after quitting, cravings come less often and feel less intense.</p>

<h2 id="urge-surfing">Urge surfing, step by step</h2>
<p>Urge surfing is a mindfulness technique used in addiction treatment. Instead of fighting the craving, you watch it pass:</p>
<ol>
  <li><strong>Notice it.</strong> Say to yourself, "This is a craving. It will pass."</li>
  <li><strong>Find it in your body.</strong> Tight chest, restless hands, a pull in your throat. Just notice where it is.</li>
  <li><strong>Breathe slowly.</strong> Breathe in for about four seconds and out for about six. A longer out-breath helps you calm down.</li>
  <li><strong>Ride the wave.</strong> Notice the craving getting stronger, peaking, and then starting to fade.</li>
  <li><strong>Choose what's next.</strong> Once it's passed, carry on with what you were doing.</li>
</ol>
<p>DayXero's Craving SOS guides you through this in three minutes, with a breathing pacer you can follow.</p>

<h2 id="quick">Quick techniques that work</h2>
<ul>
  <li><strong>Delay:</strong> tell yourself you'll wait ten minutes. The craving often passes first.</li>
  <li><strong>Move:</strong> a short walk or a few minutes of activity can reduce cravings.</li>
  <li><strong>Drink water</strong> or chew sugar-free gum to keep your mouth busy.</li>
  <li><strong>Change your surroundings:</strong> leave the room or step outside somewhere new.</li>
  <li><strong>Text someone</strong> who knows you're quitting.</li>
</ul>

<h2 id="triggers">A plan for your biggest triggers</h2>
<div class="table-wrap"><table>
  <thead><tr><th>Trigger</th><th>Try this instead</th></tr></thead>
  <tbody>
    <tr><td>Waking up</td><td>Get up straight away, drink a glass of water and change your morning order.</td></tr>
    <tr><td>Coffee</td><td>Switch the place or the cup, or have tea for the first weeks.</td></tr>
    <tr><td>After meals</td><td>Get up from the table, brush your teeth or go for a short walk.</td></tr>
    <tr><td>Stress</td><td>Three slow breaths with a long out-breath, then urge surf.</td></tr>
    <tr><td>Alcohol</td><td>Drink less in the first weeks and plan what you'll say if offered one.</td></tr>
    <tr><td>Driving</td><td>Keep gum or water in the car and change your playlist.</td></tr>
  </tbody>
</table></div>

<h2 id="nrt">Fast-acting nicotine replacement</h2>
<p>If you use nicotine replacement, gum, lozenges or mouth spray can take the edge off breakthrough cravings, especially combined with a patch. Follow the product instructions or ask a pharmacist.</p>

<h2 id="slip">If you give in</h2>
<p>A slip doesn't mean you've failed. Note what set it off, plan for that trigger next time, and carry on. Thinking "I've ruined it" is what turns a slip into a full relapse, not the slip itself.</p>
""" + HELPLINES,
    faqs=[
        ("How long do nicotine cravings last?",
         "A single craving usually peaks and passes within a few minutes. Over the weeks after quitting, cravings "
         "become less frequent and less intense."),
        ("Do nicotine cravings ever go away completely?",
         "For most people, yes. After a few months cravings become rare. Occasional ones can appear around old "
         "triggers, but they're much weaker and easier to let pass."),
        ("Does exercise help with nicotine cravings?",
         "Yes. Even a short burst of activity, like a brisk walk, can reduce cravings and withdrawal symptoms."),
        ("What is urge surfing?",
         "Urge surfing is a mindfulness technique where you notice a craving, feel where it is in your body and "
         "breathe through it as it rises and falls, instead of fighting it or giving in."),
    ],
    sources=["nhs", "sf", "teen"],
    related=["nicotine-withdrawal-timeline", "quit-vaping", "quit-smoking"],
)

BY_SLUG = {g["slug"]: g for g in GUIDES}

HEAD = """<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{title}</title>
  <meta name="description" content="{meta}">
  <link rel="canonical" href="{url}">
  <link rel="icon" type="image/svg+xml" href="/favicon.svg">
  <link rel="apple-touch-icon" href="/apple-touch-icon.png">
  <meta name="theme-color" content="#000000">
  <meta property="og:type" content="{og_type}">
  <meta property="og:site_name" content="DayXero">
  <meta property="og:url" content="{url}">
  <meta property="og:title" content="{og_title}">
  <meta property="og:description" content="{meta}">
  <meta property="og:image" content="{base}/og-image.png">
  <meta property="og:image:width" content="1200">
  <meta property="og:image:height" content="630">
  <meta name="twitter:card" content="summary_large_image">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@500;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/assets/site.css">
  <script type="application/ld+json">
{ld}
  </script>
</head>
"""

NAV = """<body class="bg-black text-white antialiased font-sans min-h-screen flex flex-col">
  <div class="fixed top-0 left-1/2 -translate-x-1/2 w-[1000px] max-w-full h-[300px] bg-gradient-to-b from-[#43511C]/25 via-[#BCC388]/10 to-transparent blur-[140px] pointer-events-none z-0"></div>
  <header class="sticky top-4 z-50 flex justify-center px-4 pt-4">
    <nav class="flex items-center justify-between gap-4 px-5 py-3 rounded-full bg-black/85 backdrop-blur-2xl border border-white/15 shadow-2xl shadow-black max-w-5xl w-full" aria-label="Main">
      <a href="/" class="flex items-center gap-3 group">
        <span class="w-8 h-8 rounded-full bg-white text-black flex items-center justify-center shadow-md">
          <svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M6 3v18"/><circle cx="13" cy="14" r="7"/></svg>
        </span>
        <span class="flex flex-col">
          <span class="font-bold text-sm tracking-tight text-white group-hover:text-[#BCC388]">DayXero</span>
          <span class="text-[9px] text-white/40 tracking-widest uppercase font-mono -mt-0.5">Nicotine Protocol</span>
        </span>
      </a>
      <div class="hidden md:flex items-center gap-1 text-xs font-medium text-white/70">
{navlinks}
      </div>
      <a href="/#pricing" class="px-4 py-2 rounded-full bg-[#BCC388] text-black font-semibold text-xs tracking-tight hover:bg-white">Get DayXero</a>
    </nav>
  </header>
"""

FOOTER = """  <footer class="border-t border-white/10 bg-black py-14 px-4 relative z-10 text-white/60 mt-auto">
    <div class="max-w-5xl mx-auto grid grid-cols-1 sm:grid-cols-3 gap-8 text-xs">
      <div class="flex flex-col gap-2">
        <span class="font-bold text-white tracking-tight text-sm">DayXero</span>
        <p class="text-white/40 max-w-xs">Quit on your Quit Day. An iPhone app to quit vaping, smoking and nicotine pouches.</p>
      </div>
      <div class="flex flex-col gap-2">
        <span class="font-mono uppercase tracking-widest text-[10px] text-white/40">Guides</span>
{footerlinks}
      </div>
      <div class="flex flex-col gap-2">
        <span class="font-mono uppercase tracking-widest text-[10px] text-white/40">DayXero</span>
        <a href="/" class="hover:text-white">Home</a>
        <a href="/#methodology" class="hover:text-white">How it works</a>
        <a href="/#pricing" class="hover:text-white">Pricing</a>
        <a href="/#faq" class="hover:text-white">FAQ</a>
        <a href="/about/" class="hover:text-white">About</a>
        <a href="/contact/" class="hover:text-white">Contact</a>
        <a href="/privacy/" class="hover:text-white">Privacy</a>
        <a href="/terms/" class="hover:text-white">Terms</a>
      </div>
    </div>
    <div class="max-w-5xl mx-auto mt-10 pt-6 border-t border-white/5 text-[11px] text-white/30 flex flex-col sm:flex-row justify-between gap-4">
      <div>Medical Disclaimer: DayXero provides educational habit and wellness support, not diagnostic medical treatment. Always consult a healthcare professional regarding NRT dosing and smoking cessation.</div>
      <div class="shrink-0">© 2026 DayXero.</div>
    </div>
  </footer>
</body>
</html>
"""

NAV_ITEMS = [("/quit-vaping/", "Quit Vaping"), ("/quit-smoking/", "Quit Smoking"),
             ("/quit-nicotine-pouches/", "Quit Pouches"), ("/nicotine-withdrawal-timeline/", "Withdrawal"),
             ("/guides/", "All Guides")]


def navlinks(current):
    out = []
    for href, label in NAV_ITEMS:
        on = href == current
        cls = "px-3.5 py-1.5 rounded-full " + ("text-white bg-white/10" if on else "hover:text-white hover:bg-white/10")
        aria = ' aria-current="page"' if on else ""
        out.append(f'        <a href="{href}" class="{cls}"{aria}>{label}</a>')
    return "\n".join(out)


def footerlinks():
    return "\n".join(f'        <a href="/{g["slug"]}/" class="hover:text-white">{html.escape(g["h1"].split(":")[0])}</a>'
                     for g in GUIDES)


def ld_json(obj):
    return "\n".join("  " + line for line in json.dumps(obj, indent=2, ensure_ascii=False).splitlines())


ORG = {"@type": "Organization", "@id": f"{BASE}/#organization", "name": "DayXero", "url": f"{BASE}/",
       "logo": f"{BASE}/logo.png", "email": CONTACT_EMAIL}


def page(path, title, meta, og_type, og_title, ld, main, current):
    url = f"{BASE}{path}"
    out = HEAD.format(title=html.escape(title), meta=html.escape(meta), url=url, og_type=og_type,
                      og_title=html.escape(og_title), base=BASE, ld=ld_json(ld))
    out += NAV.format(navlinks=navlinks(current))
    out += main
    out += FOOTER.format(footerlinks=footerlinks())
    dest = SITE / path.strip("/") / "index.html"
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text(out)


def card(g):
    return f"""        <a href="/{g['slug']}/" class="dark-card rounded-card p-6 flex flex-col gap-3 hover:border-[#BCC388]/40 spring-trans group">
          <span class="text-[10px] font-mono uppercase tracking-widest text-[#BCC388]">{html.escape(g['kicker'])}</span>
          <span class="text-lg font-extrabold tracking-tight text-white group-hover:text-[#BCC388] spring-trans">{html.escape(g['h1'])}</span>
          <span class="text-sm text-white/60 leading-relaxed">{html.escape(g['meta'])}</span>
          <span class="text-xs font-semibold text-white mt-auto pt-2">Read the guide →</span>
        </a>"""


for g in GUIDES:
    path = f"/{g['slug']}/"
    url = f"{BASE}{path}"
    faq_html = "\n".join(
        f"""      <details class="faq-item">
        <summary>{html.escape(q)}</summary>
        <p>{html.escape(a)}</p>
      </details>""" for q, a in g["faqs"])
    src_html = "\n".join(
        f'        <li><a href="{SOURCES[s][1]}" rel="noopener" target="_blank">{html.escape(SOURCES[s][0])}</a></li>'
        for s in g["sources"])
    related_html = "\n".join(card(BY_SLUG[s]) for s in g["related"])
    main = f"""  <main class="relative z-10 flex-1 px-4">
    <article class="max-w-3xl mx-auto pt-16 md:pt-24 pb-16">
      <nav class="text-xs text-white/40 font-mono mb-6" aria-label="Breadcrumb">
        <a href="/" class="hover:text-white">Home</a> <span aria-hidden="true">/</span>
        <a href="/guides/" class="hover:text-white">Guides</a> <span aria-hidden="true">/</span>
        <span class="text-white/70">{html.escape(g['kicker'])}</span>
      </nav>
      <h1 class="text-4xl md:text-6xl font-extrabold tracking-tight leading-[1.05] mb-6">{html.escape(g['h1'])}</h1>
      <p class="text-lg md:text-xl text-white/70 leading-relaxed mb-6">{html.escape(g['intro'])}</p>
      <p class="text-xs text-white/40 font-mono mb-12">By <a href="/about/#editorial" class="underline underline-offset-4 decoration-white/30 hover:text-white">the DayXero team</a> · Updated <time datetime="{DATE}">29 October 2026</time></p>

      <div class="prose-dx">
{g['body']}
      </div>

      <aside class="porcelain-card rounded-card p-8 my-14 text-black">
        <div class="text-[10px] font-mono uppercase tracking-widest text-black/50 mb-2">The DayXero app</div>
        <h2 class="text-2xl md:text-3xl font-extrabold tracking-tight mb-3">Turn this plan into a daily routine</h2>
        <p class="text-sm text-black/70 leading-relaxed mb-6">DayXero guides you through a five-day prep phase before your Quit Day, gets you through cravings in three minutes, and never resets your progress for a slip. Built for iPhone, for vapes, cigarettes and pouches.</p>
        <a href="/#pricing" class="inline-flex items-center gap-2 px-6 py-3 rounded-full bg-black text-white font-semibold text-xs hover:bg-[#202020]">See plans, free tier included →</a>
      </aside>

      <section class="prose-dx" aria-labelledby="faq-heading">
        <h2 id="faq-heading">Frequently asked questions</h2>
      </section>
      <div class="flex flex-col gap-3 mt-6">
{faq_html}
      </div>

      <section class="prose-dx mt-14">
        <h2>Sources</h2>
        <ul>
{src_html}
        </ul>
        <p class="disclaimer">{html.escape(DISCLAIMER)}</p>
      </section>
    </article>

    <section class="max-w-5xl mx-auto pb-24" aria-labelledby="related-heading">
      <h2 id="related-heading" class="text-2xl font-extrabold tracking-tight mb-6">Keep reading</h2>
      <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
{related_html}
      </div>
    </section>
  </main>
"""
    ld = {"@context": "https://schema.org", "@graph": [
        ORG,
        {"@type": "Article", "headline": g["h1"], "description": g["meta"], "url": url,
         "mainEntityOfPage": url, "datePublished": DATE, "dateModified": DATE,
         "image": f"{BASE}/og-image.png", "inLanguage": "en",
         "author": {"@id": f"{BASE}/#organization"}, "publisher": {"@id": f"{BASE}/#organization"}},
        {"@type": "BreadcrumbList", "itemListElement": [
            {"@type": "ListItem", "position": 1, "name": "Home", "item": f"{BASE}/"},
            {"@type": "ListItem", "position": 2, "name": "Guides", "item": f"{BASE}/guides/"},
            {"@type": "ListItem", "position": 3, "name": g["kicker"], "item": url}]},
        {"@type": "FAQPage", "mainEntity": [
            {"@type": "Question", "name": q, "acceptedAnswer": {"@type": "Answer", "text": a}}
            for q, a in g["faqs"]]},
    ]}
    page(path, g["title"], g["meta"], "article", g["h1"], ld, main, path)

hub_main = f"""  <main class="relative z-10 flex-1 px-4">
    <section class="max-w-5xl mx-auto pt-16 md:pt-24 pb-24">
      <h1 class="text-4xl md:text-6xl font-extrabold tracking-tight leading-[1.05] mb-6 max-w-3xl">Quit Nicotine Guides</h1>
      <p class="text-lg text-white/70 leading-relaxed mb-12 max-w-2xl">Practical, evidence-based guides to quitting vaping, smoking and nicotine pouches, getting through withdrawal and handling cravings. Written by the DayXero team, based on guidance from the WHO, NHS and CDC.</p>
      <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
{chr(10).join(card(g) for g in GUIDES)}
      </div>
    </section>
  </main>
"""
hub_ld = {"@context": "https://schema.org", "@graph": [
    ORG,
    {"@type": "CollectionPage", "name": "Quit Nicotine Guides", "url": f"{BASE}/guides/",
     "publisher": {"@id": f"{BASE}/#organization"},
     "hasPart": [{"@type": "Article", "headline": g["h1"], "url": f"{BASE}/{g['slug']}/"} for g in GUIDES]},
    {"@type": "BreadcrumbList", "itemListElement": [
        {"@type": "ListItem", "position": 1, "name": "Home", "item": f"{BASE}/"},
        {"@type": "ListItem", "position": 2, "name": "Guides", "item": f"{BASE}/guides/"}]},
]}
page("/guides/", "Quit Nicotine Guides: Vaping, Smoking & Pouches | DayXero",
     "Free guides to quitting vaping, smoking and nicotine pouches: step-by-step plans, the nicotine "
     "withdrawal timeline and how to handle cravings.",
     "website", "Quit Nicotine Guides", hub_ld, hub_main, "/guides/")

INFO_PAGES = []


def info_page(slug, title, meta, h1, intro, body, ld_type):
    INFO_PAGES.append(dict(slug=slug, title=title, meta=meta, h1=h1, intro=intro, body=body, ld_type=ld_type))


MAIL = f'<a href="mailto:{CONTACT_EMAIL}">{CONTACT_EMAIL}</a>'

info_page(
    slug="about",
    title="About DayXero: A Quit Nicotine App Built Around Quit Day",
    meta="Who makes DayXero, why it plans around a Quit Day, and how we research, write and update our "
         "quit-nicotine guides.",
    h1="About DayXero",
    intro="DayXero is an iPhone app that helps people quit vaping, smoking and nicotine pouches. It plans "
          "everything around one date: your Quit Day.",
    ld_type="AboutPage",
    body=f"""
<h2 id="why">Why we built it</h2>
<p>Most quit apps start counting the moment you install them. That suits people who have already stopped, but most people aren't there yet. They want to quit, and they need a plan for getting to the day they stop.</p>
<p>DayXero starts earlier. A five-day prep phase helps you learn your triggers, plan what you'll do instead and decide whether to use nicotine replacement. Then it supports you on Quit Day and the weeks after.</p>

<h2 id="principles">What DayXero stands for</h2>
<ul>
  <li><strong>A slip is not a reset.</strong> One puff, pouch or cigarette doesn't erase your progress, so the app never resets your count for a slip. It helps you learn from it instead.</li>
  <li><strong>Cravings pass.</strong> Craving SOS walks you through a three-minute urge-surfing session, because a craving peaks and fades within minutes.</li>
  <li><strong>Every kind of nicotine.</strong> Cigarettes, vapes and pouches all work in the app, and so does stepping down nicotine replacement.</li>
  <li><strong>Private by default.</strong> Your quit data stays on your phone. See our <a href="/privacy/">privacy policy</a>.</li>
</ul>

<h2 id="editorial">How we write our guides</h2>
<p>The <a href="/guides/">DayXero guides</a> are written by the DayXero team. Every guide follows the same rules:</p>
<ul>
  <li><strong>Based on public health guidance.</strong> We work from the World Health Organization, the NHS, the US CDC and National Cancer Institute (Smokefree.gov), and India's National Tobacco Control Programme. Each guide lists its sources.</li>
  <li><strong>Plain and practical.</strong> We write for someone who wants to quit this week, not for a textbook.</li>
  <li><strong>Dated and updated.</strong> Each guide shows the date it was last updated. We review guides when health guidance changes.</li>
  <li><strong>Information, not medical advice.</strong> Our guides don't replace a doctor or pharmacist, especially for nicotine replacement doses, pregnancy, heart conditions or anyone under 18.</li>
</ul>
<p>Spotted a mistake or an out-of-date fact? Email {MAIL} and we'll check it and correct the guide.</p>

<h2 id="contact">Get in touch</h2>
<p>For support, press or partnerships, see our <a href="/contact/">contact page</a>.</p>
""",
)

info_page(
    slug="contact",
    title="Contact DayXero",
    meta="Contact DayXero for app support, guide corrections, press and partnerships, plus free quitlines "
         "if you want to talk to a quit coach.",
    h1="Contact DayXero",
    intro="We read every message. Email is the fastest way to reach us.",
    ld_type="ContactPage",
    body=f"""
<h2 id="email">Email</h2>
<p>{MAIL}</p>
<p>Use this address for:</p>
<ul>
  <li>Help with the app, subscriptions or restoring purchases</li>
  <li>Corrections to one of our <a href="/guides/">guides</a></li>
  <li>Privacy requests, such as questions about your data</li>
  <li>Press and partnerships</li>
</ul>
<p>To cancel a subscription or ask for a refund, use your Apple ID settings, because Apple handles all App Store payments. There's more on this in our <a href="/terms/#subscriptions">terms</a>.</p>
""" + HELPLINES + """
<p><strong>In an emergency,</strong> call your local emergency number (112 in India, 911 in the US, 999 in the UK).</p>
""",
)

info_page(
    slug="privacy",
    title="Privacy Policy | DayXero",
    meta="How DayXero handles your data: quit data stays on your iPhone, there is no account, and the website "
         "uses cookie-free analytics.",
    h1="Privacy Policy",
    intro="Short version: your quit data stays on your iPhone. We don't ask you to create an account, we don't sell "
          "data, and we never send what you log about cravings, slips or your health to our analytics.",
    ld_type="WebPage",
    body=f"""
<h2 id="app">The DayXero app</h2>
<p><strong>Stored on your device.</strong> Your Quit Day, nicotine use, cravings, slips, notes, program progress and any health details you enter (such as height and weight) are stored on your iPhone. Home Screen and Lock Screen widgets read the same data on your device. We don't run a server that receives this data, and you don't need an account.</p>
<p><strong>Purchases.</strong> Apple processes all payments. We use RevenueCat to check which plan you have. RevenueCat receives an anonymous app user ID and your purchase details from Apple, not your name, email or payment card.</p>
<p><strong>Usage analytics.</strong> To improve the app, it sends anonymous usage events to a product analytics service, such as which screens you open, when you start a program day and whether a craving session was completed. These events never include what you write or log, or your health details.</p>
<p><strong>Notifications.</strong> Reminders are scheduled on your device and you can turn them off at any time in iOS Settings.</p>

<h2 id="website">This website</h2>
<ul>
  <li><strong>Hosting.</strong> dayxero.in is served by Cloudflare, which processes technical data such as IP addresses to deliver the site and protect it from abuse.</li>
  <li><strong>Analytics.</strong> We use Cloudflare Web Analytics, which counts visits without cookies and without tracking you across other sites.</li>
  <li><strong>Fonts.</strong> Pages load fonts from Google Fonts, so your browser connects to Google's servers.</li>
  <li><strong>No cookies, no ads.</strong> The website sets no cookies and shows no advertising.</li>
</ul>

<h2 id="sharing">Who we share data with</h2>
<p>Only the service providers named above, and only so they can do their job for us. We don't sell your data or share it with advertisers, and we don't share it with tobacco or nicotine companies.</p>

<h2 id="choices">Your choices</h2>
<ul>
  <li><strong>Delete your data</strong> by deleting the app. Because your quit data lives on your phone, this removes it.</li>
  <li><strong>Ask us anything</strong> about your data, or ask us to delete analytics data linked to your anonymous ID, by emailing {MAIL}.</li>
</ul>

<h2 id="children">Children</h2>
<p>DayXero isn't directed at children under 13, and we don't knowingly collect data from them.</p>

<h2 id="changes">Changes to this policy</h2>
<p>If we change this policy, we'll update the date at the top of this page. For significant changes, we'll also tell you in the app.</p>

<h2 id="contact">Contact</h2>
<p>Questions about privacy: {MAIL}</p>
""",
)

info_page(
    slug="terms",
    title="Terms of Use | DayXero",
    meta="The terms for using the DayXero app and website, including subscriptions, free trials, cancellation "
         "and our medical disclaimer.",
    h1="Terms of Use",
    intro="These terms cover your use of the DayXero iPhone app and this website. By using either one, you agree "
          "to them.",
    ld_type="WebPage",
    body=f"""
<h2 id="medical">Not medical advice</h2>
<p>DayXero provides educational habit and wellness support. It doesn't diagnose or treat any condition, and it doesn't replace a doctor, pharmacist or stop-smoking service. Talk to a healthcare professional before using nicotine replacement or stop-smoking medicines, especially if you are pregnant, have a heart condition, take regular medicine or are under 18. In an emergency, call your local emergency number.</p>

<h2 id="subscriptions">Subscriptions and payments</h2>
<ul>
  <li>DayXero has a free tier and paid plans: monthly, annual and a one-time lifetime purchase. Current prices are shown in the app and on our <a href="/#pricing">pricing section</a>.</li>
  <li>Apple handles all payments through your Apple ID. Monthly and annual plans renew automatically unless you cancel at least 24 hours before the end of the current period.</li>
  <li>If a plan includes a free trial, it converts to a paid subscription when the trial ends unless you cancel before then.</li>
  <li>You can manage or cancel a subscription in your Apple ID settings. Refunds are handled by Apple under its policies.</li>
</ul>

<h2 id="use">Using DayXero</h2>
<p>You may use the app and website for your own personal, non-commercial use. Don't copy, resell or reverse-engineer the app, or use the website in a way that harms it or other people.</p>
<p>If you're under 18, use DayXero with the permission of a parent or guardian.</p>

<h2 id="content">Our content</h2>
<p>The app, its programs and this website, including the guides, belong to DayXero. You're welcome to link to and quote short parts of our guides with credit.</p>

<h2 id="liability">No guarantees</h2>
<p>We work hard to make DayXero helpful and accurate, but we provide it "as is". We can't promise that it will help you quit, that it will always be available, or that it is free of errors. To the extent the law allows, DayXero isn't liable for indirect or consequential losses arising from your use of the app or website.</p>

<h2 id="changes">Changes</h2>
<p>We may update these terms as DayXero changes. We'll update the date at the top of this page, and for significant changes we'll tell you in the app.</p>

<h2 id="contact">Contact</h2>
<p>Questions about these terms: {MAIL}</p>
""",
)

for ip in INFO_PAGES:
    path = f"/{ip['slug']}/"
    url = f"{BASE}{path}"
    main = f"""  <main class="relative z-10 flex-1 px-4">
    <article class="max-w-3xl mx-auto pt-16 md:pt-24 pb-24">
      <h1 class="text-4xl md:text-6xl font-extrabold tracking-tight leading-[1.05] mb-6">{html.escape(ip['h1'])}</h1>
      <p class="text-lg md:text-xl text-white/70 leading-relaxed mb-6">{html.escape(ip['intro'])}</p>
      <p class="text-xs text-white/40 font-mono mb-12">Updated <time datetime="{DATE}">29 October 2026</time></p>

      <div class="prose-dx">
{ip['body']}
      </div>
    </article>
  </main>
"""
    ld = {"@context": "https://schema.org", "@graph": [
        ORG,
        {"@type": ip["ld_type"], "name": ip["h1"], "description": ip["meta"], "url": url,
         "dateModified": DATE, "inLanguage": "en", "publisher": {"@id": f"{BASE}/#organization"}},
        {"@type": "BreadcrumbList", "itemListElement": [
            {"@type": "ListItem", "position": 1, "name": "Home", "item": f"{BASE}/"},
            {"@type": "ListItem", "position": 2, "name": ip["h1"], "item": url}]},
    ]}
    page(path, ip["title"], ip["meta"], "website", ip["h1"], ld, main, path)

sitemap = ['<?xml version="1.0" encoding="UTF-8"?>',
           '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">']
for path in (["/", "/guides/"] + [f"/{g['slug']}/" for g in GUIDES]
             + [f"/{ip['slug']}/" for ip in INFO_PAGES]):
    sitemap += ["  <url>", f"    <loc>{BASE}{path}</loc>", f"    <lastmod>{DATE}</lastmod>", "  </url>"]
sitemap.append("</urlset>")
(SITE / "sitemap.xml").write_text("\n".join(sitemap) + "\n")
print("wrote", len(GUIDES) + len(INFO_PAGES) + 1, "pages")
