#!/usr/bin/env python3
"""Generate standalone DayXero pre-launch mockups that reuse the live site's markup and site.css.

Every page links ../../../website/assets/site.css plus the inline <style> block copied verbatim
from website/index.html. Tailwind classes the mockups need that are NOT in the compiled site.css
are generated afterwards (inject_missing.py) and inlined into <style id="mockup-utilities">.
"""
import os, re

SCRATCH = os.path.dirname(os.path.abspath(__file__))
OUT = "/home/user/DAYXERO/research_notes/DayXero prelaunch waitlist marketing/mockups"
os.makedirs(OUT, exist_ok=True)

INDEX_STYLE = open(os.path.join(SCRATCH, "index_style.css")).read()
SHOWCASE = open(os.path.join(SCRATCH, "showcase.html")).read()

ARROW = '<svg class="w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M5 12h14"/><path d="m12 5 7 7-7 7"/></svg>'
ARROW_SM = ARROW.replace('w-4 h-4', 'w-3.5 h-3.5')
CHECK = '<svg class="w-4 h-4 text-[#BCC388]" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 6 9 17l-5-5"/></svg>'
CHECK_BLACK = CHECK.replace('text-[#BCC388]', 'text-black')
MONO = '<svg class="w-4 h-4 text-black" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M6 3v18"/><circle cx="13" cy="14" r="7"/></svg>'


def head(title, desc):
    return f'''<!DOCTYPE html>
<html lang="en" class="scroll-smooth">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{title}</title>
  <meta name="description" content="{desc}">
  <meta name="robots" content="noindex">
  <meta name="theme-color" content="#000000">
  <!-- MOCKUP: same fonts and compiled stylesheet as the live site -->
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="../../../website/assets/site.css">
  <!-- Copied verbatim from website/index.html <style> -->
  <style>
{INDEX_STYLE}
  </style>
  <!-- Tailwind utilities used by this mockup that are not yet in the compiled site.css.
       Generated with tailwindcss@3.4.17 + website/tailwind.config.js. They disappear once the
       markup ships and `npm run website:css` is re-run. -->
  <style id="mockup-utilities">
/*MOCKUP-UTILITIES*/
  </style>
</head>
'''


def home_nav(cta_label="Join the beta", cta_href="#waitlist"):
    return f'''  <div class="fixed top-0 left-1/2 -translate-x-1/2 w-[1000px] h-[380px] bg-gradient-to-b from-[#43511C]/25 via-[#BCC388]/10 to-transparent blur-[140px] pointer-events-none z-0"></div>
  <header class="fixed top-6 inset-x-0 z-50 flex justify-center px-4 pointer-events-none">
    <nav class="pointer-events-auto flex items-center justify-between gap-4 md:gap-8 px-5 py-3 rounded-full bg-black/85 backdrop-blur-2xl border border-white/15 shadow-2xl shadow-black max-w-5xl w-full">
      <a href="#hero" class="flex items-center gap-3 group">
        <div class="w-8 h-8 rounded-full bg-white text-black flex items-center justify-center font-extrabold text-sm shadow-md group-hover:scale-105 spring-trans">{MONO}</div>
        <div class="flex flex-col whitespace-nowrap">
          <span class="font-bold text-sm tracking-tight text-white group-hover:text-[#BCC388] spring-trans">DayXero</span>
          <span class="text-[9px] text-white/40 tracking-widest uppercase font-mono -mt-0.5">Nicotine Protocol</span>
        </div>
      </a>
      <div class="hidden xl:flex items-center gap-1 text-xs font-medium text-white/70 whitespace-nowrap">
        <a href="#showcase" class="px-3 py-1.5 rounded-full hover:text-white hover:bg-white/10 spring-trans">Showcase</a>
        <a href="#methodology" class="px-3 py-1.5 rounded-full hover:text-white hover:bg-white/10 spring-trans">Methodology</a>
        <a href="#interactive-preview" class="px-3 py-1.5 rounded-full hover:text-white hover:bg-white/10 spring-trans">App Preview</a>
        <a href="#breath-chamber" class="px-3 py-1.5 rounded-full hover:text-white hover:bg-white/10 spring-trans">Urge Surfing</a>
        <a href="#recovery-timeline" class="px-3 py-1.5 rounded-full hover:text-white hover:bg-white/10 spring-trans">Timeline</a>
        <a href="#calculator" class="px-3 py-1.5 rounded-full hover:text-white hover:bg-white/10 spring-trans">Calculator</a>
        <a href="#pricing" class="px-3 py-1.5 rounded-full hover:text-white hover:bg-white/10 spring-trans">Founding Offer</a>
      </div>
      <div class="flex items-center gap-2.5">
        <a href="{cta_href}" class="shrink-0 whitespace-nowrap px-4 py-2 rounded-full bg-[#BCC388] text-black font-semibold text-xs tracking-tight hover:bg-white active:scale-95 spring-trans flex items-center gap-1.5 shadow-lg shadow-[#BCC388]/20">
          <span>{cta_label}</span>
          {ARROW_SM}
        </a>
      </div>
    </nav>
  </header>
'''


def guide_nav(active=None, cta_href="/beta/"):
    return f'''  <div class="fixed top-0 left-1/2 -translate-x-1/2 w-[1000px] max-w-full h-[300px] bg-gradient-to-b from-[#43511C]/25 via-[#BCC388]/10 to-transparent blur-[140px] pointer-events-none z-0"></div>
  <header class="sticky top-4 z-50 flex justify-center px-4 pt-4">
    <nav class="flex items-center justify-between gap-4 px-5 py-3 rounded-full bg-black/85 backdrop-blur-2xl border border-white/15 shadow-2xl shadow-black max-w-5xl w-full" aria-label="Main">
      <a href="/" class="flex items-center gap-3 group">
        <span class="w-8 h-8 rounded-full bg-white text-black flex items-center justify-center shadow-md">{MONO}</span>
        <span class="flex flex-col">
          <span class="font-bold text-sm tracking-tight text-white group-hover:text-[#BCC388]">DayXero</span>
          <span class="text-[9px] text-white/40 tracking-widest uppercase font-mono -mt-0.5">Nicotine Protocol</span>
        </span>
      </a>
      <div class="hidden md:flex items-center gap-1 text-xs font-medium text-white/70">
        <a href="/quit-vaping/" class="px-3.5 py-1.5 rounded-full {'text-white bg-white/10' if active=='vaping' else 'hover:text-white hover:bg-white/10'}">Quit Vaping</a>
        <a href="/quit-smoking/" class="px-3.5 py-1.5 rounded-full hover:text-white hover:bg-white/10">Quit Smoking</a>
        <a href="/quit-nicotine-pouches/" class="px-3.5 py-1.5 rounded-full hover:text-white hover:bg-white/10">Quit Pouches</a>
        <a href="/nicotine-withdrawal-timeline/" class="px-3.5 py-1.5 rounded-full hover:text-white hover:bg-white/10">Withdrawal</a>
        <a href="/guides/" class="px-3.5 py-1.5 rounded-full hover:text-white hover:bg-white/10">All Guides</a>
      </div>
      <a href="{cta_href}" class="shrink-0 whitespace-nowrap px-4 py-2 rounded-full bg-[#BCC388] text-black font-semibold text-xs tracking-tight hover:bg-white">Join the beta</a>
    </nav>
  </header>
'''


def waitlist_form(source, form_id="waitlist", button="Join the beta", tone="dark", plan=None, compact=False, stacked=False):
    """Pill email form. tone=dark sits on black/#121212, tone=light sits inside a porcelain-card."""
    plan_input = f'\n      <input type="hidden" name="plan_interest" value="{plan}">' if plan else ''
    h = 'h-11' if compact else 'h-12'
    if tone == "dark":
        shell = 'flex flex-col sm:flex-row gap-2 p-2 rounded-[28px] sm:rounded-full bg-[#121212] border border-white/15 shadow-2xl'
        inp = f'w-full sm:flex-1 min-w-0 {h} px-5 rounded-full bg-[#161616] border border-white/10 text-sm text-white placeholder:text-white/30 focus:outline-none focus:border-[#BCC388]/60 spring-trans'
        btn = f'{h} px-6 rounded-full bg-white text-black font-semibold text-sm tracking-tight hover:bg-[#BCC388] active:scale-95 spring-trans flex items-center justify-center gap-2 shadow-xl whitespace-nowrap'
    else:
        shell = 'flex flex-col sm:flex-row gap-2 p-1.5 rounded-[28px] sm:rounded-full bg-black/5 border border-black/10'
        inp = f'w-full sm:flex-1 min-w-0 {h} px-5 rounded-full bg-white border border-black/10 text-sm text-black placeholder:text-black/40 focus:outline-none focus:border-[#43511C]/60 spring-trans'
        btn = f'{h} px-6 rounded-full bg-black text-white font-semibold text-sm tracking-tight hover:bg-[#202020] active:scale-95 spring-trans flex items-center justify-center gap-2 shadow-xl whitespace-nowrap'
    if stacked:
        shell = shell.replace(' sm:flex-row', '').replace(' sm:rounded-full', '')
        inp = inp.replace(' sm:flex-1', '')
    return f'''<form id="{form_id}" class="waitlist-form w-full" action="/api/waitlist" method="post" novalidate>
      <div class="{shell}">
        <label for="{form_id}-email" class="sr-only">Email address</label>
        <input id="{form_id}-email" type="email" name="email" required autocomplete="email" inputmode="email" placeholder="you@example.com" class="{inp}">
        <button type="submit" class="{btn}">
          <span>{button}</span>
          {ARROW}
        </button>
      </div>
      <!-- Honeypot: hidden from people, bots fill it. Server silently drops any submission that has it. -->
      <div class="hidden" aria-hidden="true"><label>Company <input type="text" name="company" tabindex="-1" autocomplete="off"></label></div>
      <input type="hidden" name="source" value="{source}">{plan_input}
      <!-- Cloudflare Turnstile (managed, interaction-only: invisible for most visitors). Script:
           https://challenges.cloudflare.com/turnstile/v0/api.js — not loaded in this mockup. -->
      <div class="cf-turnstile" data-sitekey="TURNSTILE_SITE_KEY" data-appearance="interaction-only" data-size="flexible"></div>
    </form>'''


def microcopy(tone="dark", align="center"):
    if tone == "dark":
        return f'''<p class="text-[11px] text-white/40 text-{align} leading-relaxed mt-3">Free to join. We'll email your TestFlight invite and the App Store link at launch, nothing else. Unsubscribe anytime. <a href="/privacy/#waitlist" class="underline underline-offset-4 decoration-white/30 hover:text-white">Privacy</a></p>'''
    return f'''<p class="text-[11px] text-black/50 text-{align} leading-relaxed mt-3">No payment now. One confirmation email, then your invite and launch link. Unsubscribe anytime. <a href="/privacy/#waitlist" class="underline underline-offset-4 decoration-black/30 hover:text-black">Privacy</a></p>'''


FORM_JS = '''  <div id="toast-container" class="fixed bottom-6 right-6 z-50 pointer-events-none flex flex-col gap-2"></div>
  <script>
    // MOCKUP behaviour only: progressive enhancement over a plain <form method="post">.
    // In production this POSTs to /api/waitlist (see website_changes_and_mockups.md, Backend).
    function showToast(message) {
      const container = document.getElementById('toast-container');
      if (!container) return;
      const toast = document.createElement('div');
      toast.className = 'pointer-events-auto flex items-center gap-2.5 px-4 py-2.5 rounded-full bg-[#181818] border border-[#BCC388]/40 shadow-2xl text-xs font-medium text-white transition-all duration-300 transform translate-y-4 opacity-0';
      toast.innerHTML = `<span class="w-2 h-2 rounded-full bg-[#BCC388]"></span><span>${message}</span>`;
      container.appendChild(toast);
      requestAnimationFrame(() => toast.classList.remove('translate-y-4', 'opacity-0'));
      setTimeout(() => { toast.classList.add('opacity-0', 'translate-y-2'); setTimeout(() => toast.remove(), 300); }, 3500);
    }
    document.querySelectorAll('.waitlist-form').forEach((form) => {
      form.addEventListener('submit', (e) => {
        e.preventDefault();
        const email = form.querySelector('input[type=email]');
        if (!email.value || !email.checkValidity()) { email.focus(); showToast('Enter a valid email to join the beta'); return; }
        window.location.href = 'c-success-referral.html';
      });
    });
    document.querySelectorAll('[data-notify-plan]').forEach((btn) => {
      btn.addEventListener('click', () => {
        const slot = document.getElementById(btn.dataset.target);
        if (slot) { btn.classList.add('hidden'); slot.classList.remove('hidden'); slot.querySelector('input[type=email]').focus(); }
      });
    });
  </script>
'''


def home_footer():
    return '''  <footer class="border-t border-white/10 bg-black py-16 px-4 relative z-10 text-white/60">
    <div class="max-w-5xl mx-auto flex flex-col md:flex-row justify-between items-start md:items-center gap-8">
      <div class="flex flex-col gap-2">
        <div class="flex items-center gap-3">
          <div class="w-7 h-7 rounded-full bg-white text-black flex items-center justify-center font-bold text-xs">b</div>
          <span class="font-bold text-white tracking-tight">DayXero</span>
        </div>
        <p class="text-xs text-white/40 max-w-sm">Quit on your Quit Day. An iPhone app in development for quitting cigarettes, vapes and pouches.</p>
      </div>
      <div class="flex flex-wrap gap-6 text-xs text-white/60 font-medium">
        <a href="#hero" class="hover:text-white spring-trans">Back to top</a>
        <a href="/beta/" class="hover:text-white spring-trans">Join the beta</a>
        <a href="#pricing" class="hover:text-white spring-trans">Founding offer</a>
        <a href="#faq" class="hover:text-white spring-trans">FAQ</a>
        <a href="/guides/" class="hover:text-white spring-trans">Quit Guides</a>
        <a href="/about/" class="hover:text-white spring-trans">About</a>
        <a href="/contact/" class="hover:text-white spring-trans">Contact</a>
        <a href="/privacy/" class="hover:text-white spring-trans">Privacy</a>
        <a href="/terms/" class="hover:text-white spring-trans">Terms</a>
      </div>
    </div>
    <div class="max-w-5xl mx-auto mt-12 pt-6 border-t border-white/5 text-[11px] text-white/30 flex flex-col sm:flex-row justify-between gap-4">
      <div>Medical Disclaimer: DayXero provides educational habit and wellness support, not diagnostic medical treatment. Always consult a healthcare professional regarding NRT dosing and smoking cessation.</div>
      <div class="shrink-0">© 2026 DayXero. Local-first &amp; Private.</div>
    </div>
  </footer>
'''


def guide_footer():
    return '''  <footer class="border-t border-white/10 bg-black py-14 px-4 relative z-10 text-white/60 mt-auto">
    <div class="max-w-5xl mx-auto grid grid-cols-1 sm:grid-cols-3 gap-8 text-xs">
      <div class="flex flex-col gap-2">
        <span class="font-bold text-white tracking-tight text-sm">DayXero</span>
        <p class="text-white/40 max-w-xs">Quit on your Quit Day. An iPhone app in development to quit vaping, smoking and nicotine pouches.</p>
      </div>
      <div class="flex flex-col gap-2">
        <span class="font-mono uppercase tracking-widest text-[10px] text-white/40">Guides</span>
        <a href="/quit-vaping/" class="hover:text-white">How to Quit Vaping</a>
        <a href="/quit-smoking/" class="hover:text-white">How to Quit Smoking</a>
        <a href="/quit-nicotine-pouches/" class="hover:text-white">How to Quit Nicotine Pouches</a>
        <a href="/nicotine-withdrawal-timeline/" class="hover:text-white">Nicotine Withdrawal Timeline</a>
        <a href="/nicotine-cravings/" class="hover:text-white">How to Handle Nicotine Cravings</a>
      </div>
      <div class="flex flex-col gap-2">
        <span class="font-mono uppercase tracking-widest text-[10px] text-white/40">DayXero</span>
        <a href="/" class="hover:text-white">Home</a>
        <a href="/beta/" class="hover:text-white">Join the beta</a>
        <a href="/#pricing" class="hover:text-white">Founding offer</a>
        <a href="/#faq" class="hover:text-white">FAQ</a>
        <a href="/about/" class="hover:text-white">About</a>
        <a href="/privacy/" class="hover:text-white">Privacy</a>
      </div>
    </div>
    <div class="max-w-5xl mx-auto mt-10 pt-6 border-t border-white/5 text-[11px] text-white/30 flex flex-col sm:flex-row justify-between gap-4">
      <div>Medical Disclaimer: DayXero provides educational habit and wellness support, not diagnostic medical treatment. Always consult a healthcare professional regarding NRT dosing and smoking cessation.</div>
      <div class="shrink-0">© 2026 DayXero.</div>
    </div>
  </footer>
'''


def section_badge(text):
    return f'''<div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#161616] border border-white/10 text-xs font-mono text-[#BCC388] mb-3">
          <span>{text}</span>
        </div>'''


# ---------------------------------------------------------------------------------------------
# (a) HERO WITH INLINE WAITLIST
# ---------------------------------------------------------------------------------------------
showcase = SHOWCASE
for old, new in [
    ('CLINICALLY FORMULATED', 'PREP BEFORE YOU QUIT'),
    ('''Engineered <span class="text-black/40 font-normal">For</span> <br/>
                  Strength, Focus <br/>
                  And Longevity''', '''Prepared, <span class="text-black/40 font-normal">Not</span> <br/>
                  Pressured Into <br/>
                  Your Quit Day'''),
    ('Premature quitting leads to 95% relapse. DayXero prepares your neurochemistry during an active prep phase before your Quit Day.',
     'Quitting on impulse is hard. DayXero is being built around five days of practice before your Quit Day, so the day itself feels familiar.'),
    ('<span>Explore Program</span>', '<span>Join the beta</span>'),
    ('href="#interactive-preview" class="inline-flex', 'href="#waitlist" class="inline-flex'),
    ('100% Offline', 'Data on your iPhone'),
    ('Engineered to support neurochemical stabilization, focus, cardiovascular health, and long-term nicotine independence for modern high performers.',
     'Designed for people quitting cigarettes, vapes or pouches who want a plan, not just a counter. In development for iPhone.'),
    ('4 min audio exercise · Unlocked', '4 min audio exercise · Preview'),
]:
    assert old in showcase, old[:40]
    showcase = showcase.replace(old, new)

hero_a = head("Mockup (a): Hero waitlist | DayXero", "Pre-launch hero with inline email waitlist form.") + '''<body class="bg-black text-white antialiased min-h-screen relative flex flex-col justify-between">
''' + home_nav() + '''
  <main class="relative z-10 flex-1">
    <section id="hero" class="relative pt-32 pb-16 md:pt-40 md:pb-24 px-4 flex flex-col items-center">

      <!-- CHANGED: status pill says the app is in beta, not a live "2026 Native iOS Protocol" -->
      <div class="inline-flex flex-wrap justify-center items-center gap-x-2 gap-y-1 px-4 py-1.5 rounded-full bg-[#161616] border border-white/15 text-xs font-medium text-white/80 mb-8 backdrop-blur-md shadow-lg text-center">
        <span class="w-2 h-2 rounded-full bg-[#BCC388] animate-ping"></span>
        <span class="text-[#BCC388] font-bold">iOS beta · Now enrolling</span>
        <span class="text-white/20 hidden sm:inline">|</span>
        <span class="text-white/80 hidden sm:inline">Don't quit today. Quit on your Quit Day.</span>
      </div>

      <!-- UNCHANGED headline -->
      <h1 class="text-4xl sm:text-6xl md:text-7xl lg:text-8xl font-extrabold tracking-tight text-center text-white max-w-5xl leading-[1.05] mb-6">
        Quit Nicotine <br class="hidden sm:inline" />
        <span class="text-white/40">on Your</span> <br class="hidden sm:inline" />
        <span class="text-transparent bg-clip-text bg-gradient-to-r from-white via-white to-[#BCC388]">Quit Day.</span>
      </h1>

      <!-- CHANGED: subhead states it's in development and what joining gets you -->
      <p class="text-base sm:text-lg md:text-xl text-white/60 text-center max-w-2xl font-normal leading-relaxed mb-10">
        DayXero is an iPhone app in development for quitting vaping, smoking and nicotine pouches: five days of prep before your Quit Day, slips that never reset your progress, and 3-minute urge surfing for cravings. Join the beta to test it first.
      </p>

      <!-- NEW: inline waitlist form replaces the colour-palette strip in this slot -->
      <div class="w-full max-w-xl flex flex-col items-center mb-8">
        ''' + waitlist_form("home-hero") + '''
        ''' + microcopy() + '''
      </div>

      <!-- NEW: honest proof chips (no fabricated counter; see notes for when to add a live count) -->
      <div class="flex flex-wrap items-center justify-center gap-2 mb-16 text-[11px] font-mono text-white/60">
        <span class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[#121212] border border-white/10"><span class="w-1.5 h-1.5 rounded-full bg-[#BCC388]"></span>First 500 get founding pricing</span>
        <span class="px-3 py-1.5 rounded-full bg-[#121212] border border-white/10">Vapes · Cigarettes · Pouches</span>
        <span class="px-3 py-1.5 rounded-full bg-[#121212] border border-white/10">No account needed</span>
      </div>

      <!-- UNCHANGED layout; copy de-medicalised (see notes table) -->
''' + showcase + '''
    </section>
  </main>
''' + home_footer() + FORM_JS + '''</body>
</html>
'''
open(os.path.join(OUT, "a-hero-waitlist.html"), "w").write(hero_a)


# ---------------------------------------------------------------------------------------------
# (b) FOUNDING-MEMBER PRICING
# ---------------------------------------------------------------------------------------------
def li(text, black=False):
    return f'<li class="flex items-center gap-2">{CHECK_BLACK if black else CHECK} {text}</li>'

pricing_b = head("Mockup (b): Founding pricing | DayXero", "Pricing reframed as pre-launch founding-member offer.") + '''<body class="bg-black text-white antialiased min-h-screen relative flex flex-col justify-between">
''' + home_nav() + '''
  <main class="relative z-10 flex-1 pt-24">
    <section id="pricing" class="py-20 md:py-32 max-w-5xl mx-auto px-4">
      <div class="text-center max-w-2xl mx-auto mb-16">
        ''' + section_badge("FOUNDING MEMBER PRICING") + '''
        <h2 class="text-3xl md:text-5xl font-extrabold tracking-tight text-white mb-4">
          Planned Pricing. Founding Members Pay Less.
        </h2>
        <p class="text-sm md:text-base text-white/60">
          DayXero isn't on the App Store yet. Join the list now and the first 500 members get the Annual plan at half price for their first year, applied with an App Store offer code at launch. No payment today, and still no billing traps.
        </p>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 items-stretch">

        <!-- Tier 1: Monthly (button now registers launch interest instead of checkout) -->
        <div class="dark-card p-6 rounded-card flex flex-col justify-between">
          <div>
            <div class="text-xs font-mono uppercase text-white/40 mb-2">MONTHLY PROGRAM · PLANNED</div>
            <div class="text-3xl font-extrabold text-white mb-1">$9.99<span class="text-sm font-normal text-white/40">/mo</span></div>
            <p class="text-xs text-white/60 mb-6">Flexibility to pay as you progress through maintenance.</p>
            <ul class="space-y-3 text-xs text-white/70 mb-6">
              ''' + li("Full 7-Day Protocol &amp; Audio") + '''
              ''' + li("Unlimited Urge-Surfing SOS") + '''
              ''' + li("NRT &amp; Pouch Step-Down Plans") + '''
            </ul>
          </div>
          <div>
            <button type="button" data-notify-plan="Monthly" data-target="notify-monthly" class="w-full py-3 rounded-full bg-[#1A1A1A] text-white/90 border border-white/10 font-semibold text-xs hover:bg-[#222222] spring-trans">
              Notify me at launch
            </button>
            <div id="notify-monthly" class="hidden">''' + waitlist_form("pricing-monthly", "notify-monthly-form", "Notify me", plan="Monthly", compact=True, stacked=True) + '''</div>
          </div>
        </div>

        <!-- Tier 2: Annual, founding offer with the email form embedded -->
        <div class="porcelain-card p-6 md:p-8 rounded-card flex flex-col justify-between relative shadow-2xl md:scale-105 border-4 border-[#BCC388] z-20">
          <div class="absolute -top-3.5 left-1/2 -translate-x-1/2 px-3.5 py-1 rounded-full bg-black text-[#BCC388] text-[10px] font-mono font-bold uppercase tracking-wider shadow whitespace-nowrap">
            FOUNDING OFFER · FIRST 500
          </div>
          <div>
            <div class="text-xs font-mono uppercase text-black/50 mb-2 mt-2">ANNUAL MASTERY</div>
            <div class="flex items-baseline gap-2 mb-1">
              <span class="text-4xl font-extrabold text-black">$19.99</span>
              <span class="text-sm font-normal text-black/40 line-through">$39.99</span>
              <span class="text-sm font-normal text-black/50">/first yr</span>
            </div>
            <div class="text-xs text-black font-mono font-bold mb-6">Founding price · then $39.99/yr</div>
            <ul class="space-y-3 text-xs text-black/80 font-medium mb-6">
              ''' + li("Early TestFlight beta access", True) + '''
              ''' + li("3-Day Free Trial at launch", True) + '''
              ''' + li("Full 4-Week Maintenance Arc", True) + '''
              ''' + li("Advanced Craving Heatmaps", True) + '''
              ''' + li("Live Activity &amp; Dynamic Island", True) + '''
            </ul>
          </div>
          <div>
            ''' + waitlist_form("pricing-annual", "founding-form", "Reserve", tone="light", plan="Annual-founding", compact=True, stacked=True) + '''
            ''' + microcopy("light") + '''
          </div>
        </div>

        <!-- Tier 3: Lifetime, shown in its expanded "after tap" state -->
        <div class="dark-card p-6 rounded-card flex flex-col justify-between">
          <div>
            <div class="text-xs font-mono uppercase text-white/40 mb-2">LIFETIME ACCESS · PLANNED</div>
            <div class="text-3xl font-extrabold text-white mb-1">$79.99<span class="text-sm font-normal text-white/40"> once</span></div>
            <p class="text-xs text-white/60 mb-6">Pay once, own forever. Zero recurring charges.</p>
            <ul class="space-y-3 text-xs text-white/70 mb-6">
              ''' + li("Permanent Unrestricted Access") + '''
              ''' + li("All Future Program Additions") + '''
              ''' + li("Family Sharing Capable") + '''
            </ul>
          </div>
          <div>
            <div class="text-[10px] font-mono uppercase tracking-widest text-[#BCC388] mb-2">STATE AFTER TAPPING "NOTIFY ME"</div>
            ''' + waitlist_form("pricing-lifetime", "notify-lifetime-form", "Notify me", plan="Lifetime", compact=True, stacked=True) + '''
          </div>
        </div>
      </div>

      <div class="mt-10 text-center text-xs text-white/40 max-w-2xl mx-auto leading-relaxed">
        Prices are planned and may change before launch. At launch, payments and cancellation are handled by Apple. The free tier will include the core counter, emergency Craving SOS and Day 1 of the prep program.
      </div>
    </section>

    <!-- FAQ: rewritten for pre-launch -->
    <section id="faq" class="py-20 md:py-28 max-w-3xl mx-auto px-4">
      <div class="text-center mb-12">
        ''' + section_badge("FAQ") + '''
        <h2 class="text-3xl md:text-5xl font-extrabold tracking-tight text-white">Questions, Answered</h2>
      </div>
      <div class="flex flex-col gap-3">
        <details class="faq-item" open>
          <summary>When can I download DayXero?</summary>
          <p>DayXero is in development and not on the App Store yet. Join the beta list and we'll email you a TestFlight invite as beta spots open, then the App Store link on launch day.</p>
        </details>
        <details class="faq-item">
          <summary>What is the founding-member offer?</summary>
          <p>The first 500 people who join and confirm their email get the Annual plan at half price for their first year. We'll send a personal App Store offer code at launch. You don't pay anything now.</p>
        </details>
        <details class="faq-item">
          <summary>Will DayXero be free?</summary>
          <p>Yes, there will be a free version with the core counter, the Craving SOS urge surfer and Day 1 of the prep program. The full program is planned at $9.99 a month, $39.99 a year with a 3-day free trial, or $79.99 once.</p>
        </details>
        <details class="faq-item">
          <summary>What will you do with my email?</summary>
          <p>Send a confirmation, your TestFlight invite, the launch link and rare beta updates. We don't sell or share it, and every email has a one-click unsubscribe.</p>
        </details>
      </div>
    </section>
  </main>
''' + home_footer() + FORM_JS + '''</body>
</html>
'''
open(os.path.join(OUT, "b-pricing-founding.html"), "w").write(pricing_b)


# ---------------------------------------------------------------------------------------------
# (c) POST-SIGNUP SUCCESS + REFERRAL
# ---------------------------------------------------------------------------------------------
ICON = lambda paths, cls="w-4 h-4": f'<svg class="{cls}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">{paths}</svg>'
MAIL = '<rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/>'
MSG = '<path d="M7.9 20A9 9 0 1 0 4 16.1L2 22Z"/>'
SEND = '<path d="M14.536 21.686a.5.5 0 0 0 .937-.024l6.5-19a.496.496 0 0 0-.635-.635l-19 6.5a.5.5 0 0 0-.024.937l7.93 3.18a2 2 0 0 1 1.112 1.11z"/><path d="m21.854 2.147-10.94 10.939"/>'
XICON = '<path d="M4 4l16 16"/><path d="M20 4 4 20"/>'
COPY = '<rect width="14" height="14" x="8" y="8" rx="2" ry="2"/><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2"/>'
SHARE = '<path d="M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8"/><polyline points="16 6 12 2 8 6"/><line x1="12" x2="12" y1="2" y2="15"/>'
CHECKBIG = '<path d="M20 6 9 17l-5-5"/>'

share_btn = lambda paths, label: f'<button type="button" title="{label}" aria-label="{label}" class="w-11 h-11 rounded-full bg-black text-white flex items-center justify-center shadow hover:scale-110 spring-trans">{ICON(paths)}</button>'

success_c = head("Mockup (c): After signup | DayXero", "Post-signup confirm-email and referral states.") + '''<body class="bg-black text-white antialiased min-h-screen relative flex flex-col justify-between">
''' + home_nav("Beta list", "#") + '''
  <main class="relative z-10 flex-1">
    <section id="hero" class="relative pt-32 pb-16 md:pt-40 md:pb-24 px-4 flex flex-col items-center">
      <div class="text-center max-w-2xl mb-12">
        ''' + section_badge("AFTER YOU JOIN") + '''
        <h1 class="text-4xl md:text-6xl font-extrabold tracking-tight text-white leading-[1.05] mb-4">You're Almost <span class="text-white/40">on the</span> List.</h1>
        <p class="text-sm md:text-base text-white/60">Two states: the inline card that replaces the form right after submit, and the page people land on after tapping the link in the confirmation email.</p>
      </div>

      <div class="w-full max-w-5xl grid grid-cols-1 lg:grid-cols-2 gap-6 items-start">

        <!-- STATE 1: replaces the form inline (no page load) -->
        <div>
          <div class="text-[10px] font-mono uppercase tracking-widest text-white/40 mb-3 text-center lg:text-left">State 1 · Inline, right after submit</div>
          <div class="glass-card-green rounded-card p-6 md:p-8" role="status" aria-live="polite">
            <div class="w-12 h-12 rounded-full bg-[#161616] border border-[#BCC388]/30 flex items-center justify-center text-[#BCC388] mb-6 shadow">''' + ICON(MAIL, "w-6 h-6") + '''</div>
            <div class="text-[11px] font-mono uppercase tracking-widest text-[#BCC388] mb-2">STEP 1 OF 2 · CHECK YOUR INBOX</div>
            <h2 class="text-2xl font-extrabold text-white mb-3">Confirm your email to save your spot.</h2>
            <p class="text-sm text-white/70 leading-relaxed mb-6">We sent a link to <span class="text-white font-semibold">m•••@gmail.com</span>. Tap it within 24 hours. Can't see it? Check Promotions or Spam.</p>
            <div class="flex flex-wrap items-center gap-3">
              <button type="button" class="px-5 py-3 rounded-full bg-white text-black font-semibold text-xs tracking-tight hover:bg-[#BCC388] active:scale-95 spring-trans shadow-xl">Resend email</button>
              <button type="button" class="px-5 py-3 rounded-full bg-[#161616] text-white/60 hover:text-white border border-white/10 text-xs font-medium active:scale-95 spring-trans">Use a different email</button>
            </div>
          </div>
        </div>

        <!-- STATE 2: /beta/confirmed?r=CODE after double opt-in -->
        <div>
          <div class="text-[10px] font-mono uppercase tracking-widest text-white/40 mb-3 text-center lg:text-left">State 2 · /beta/confirmed after the email link</div>
          <div class="porcelain-card rounded-card p-6 md:p-8">
            <div class="flex items-center justify-between mb-6">
              <div class="w-12 h-12 rounded-full bg-[#BCC388] text-black flex items-center justify-center shadow">''' + ICON(CHECKBIG, "w-6 h-6") + '''</div>
              <span class="px-3 py-1 rounded-full bg-black text-[#BCC388] text-[10px] font-mono font-bold uppercase tracking-wider">FOUNDING MEMBER</span>
            </div>
            <div class="text-[11px] font-mono uppercase tracking-widest text-black/50 mb-2">STEP 2 OF 2 · CONFIRMED</div>
            <h2 class="text-2xl font-extrabold text-black mb-2">You're on the DayXero beta list.</h2>
            <div class="flex items-baseline gap-1 mb-4">
              <span class="text-3xl font-extrabold text-black tracking-tight">#128</span>
              <span class="text-sm font-normal text-black/40">in the TestFlight queue</span>
            </div>
            <p class="text-sm text-black/70 leading-relaxed mb-5">Know someone who wants to quit too? Each friend who joins and confirms moves you 10 spots closer to the first TestFlight wave. Sharing is optional, and your link never says why you joined.</p>

            <label for="ref-link" class="block text-[10px] font-mono uppercase tracking-widest text-black/50 mb-2">YOUR INVITE LINK</label>
            <div class="flex items-center gap-2 p-1.5 rounded-full bg-black/5 border border-black/10 mb-4">
              <input id="ref-link" readonly value="dayxero.in/beta?r=K7F2Q" class="flex-1 min-w-0 h-10 px-4 rounded-full bg-white border border-black/10 text-xs sm:text-sm font-mono text-black focus:outline-none">
              <button type="button" class="h-10 px-5 rounded-full bg-black text-white font-semibold text-xs hover:bg-[#202020] active:scale-95 spring-trans flex items-center gap-2 whitespace-nowrap">''' + ICON(COPY, "w-3.5 h-3.5") + '''<span>Copy</span></button>
            </div>

            <div class="flex items-center gap-2.5 mb-6">
              ''' + share_btn(SHARE, "Share (iOS share sheet)") + '''
              ''' + share_btn(MSG, "Messages / WhatsApp") + '''
              ''' + share_btn(XICON, "Post on X") + '''
              ''' + share_btn(MAIL, "Email a friend") + '''
            </div>

            <div class="pt-5 border-t border-black/10">
              <div class="flex justify-between items-center text-[11px] font-medium tracking-[0.08em] uppercase text-black/50 mb-2">
                <span>Friends joined</span>
                <span class="font-mono text-black">1 / 3 · first-wave access</span>
              </div>
              <div class="h-1.5 w-full bg-black/10 rounded-full overflow-hidden">
                <div class="h-full bg-[#43511C] rounded-full w-1/3"></div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- What happens next -->
      <div class="w-full max-w-5xl mt-6 dark-card rounded-card p-6 md:p-8">
        <div class="text-[11px] font-mono uppercase tracking-widest text-white/50 mb-4">WHAT HAPPENS NEXT</div>
        <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 text-sm">
          <div class="flex items-start gap-3"><span class="w-8 h-8 shrink-0 rounded-full bg-[#BCC388] text-black font-bold text-xs flex items-center justify-center">1</span><span class="text-white/70">TestFlight invites go out in waves, highest in the queue first.</span></div>
          <div class="flex items-start gap-3"><span class="w-8 h-8 shrink-0 rounded-full bg-white text-black font-bold text-xs flex items-center justify-center">2</span><span class="text-white/70">On launch day you get the App Store link and your founding offer code.</span></div>
          <div class="flex items-start gap-3"><span class="w-8 h-8 shrink-0 rounded-full bg-[#161616] border border-white/10 text-white/60 font-bold text-xs flex items-center justify-center">3</span><span class="text-white/70">That's it. No newsletter unless you ask. Unsubscribe in one tap.</span></div>
        </div>
      </div>
    </section>
  </main>
''' + home_footer() + '''</body>
</html>
'''
open(os.path.join(OUT, "c-success-referral.html"), "w").write(success_c)


# ---------------------------------------------------------------------------------------------
# (d) GUIDE PAGE
STICKY_JS = "  <script>\n    // Sticky bar: visible after the reader passes the intro, hidden while a CTA block with a form is on screen,\n    // dismissal remembered for 7 days (wrapped in try/catch: storage can be blocked).\n    (function () {\n      const bar = document.getElementById('sticky-cta');\n      let dismissed = false;\n      try { dismissed = Date.now() < Number(localStorage.getItem('dx_sticky_dismissed_until') || 0); } catch (e) {}\n      const forms = new Set();\n      const io = new IntersectionObserver((entries) => {\n        entries.forEach((en) => en.isIntersecting ? forms.add(en.target) : forms.delete(en.target));\n        update();\n      });\n      document.querySelectorAll('#guide-cta-inline, #beta-cta').forEach((f) => io.observe(f));\n      function update() {\n        const show = !dismissed && window.scrollY > 300 && forms.size === 0;\n        bar.style.transform = show ? 'translateY(0)' : 'translateY(160%)';\n      }\n      bar.style.transition = 'transform 0.38s cubic-bezier(0.16, 1, 0.3, 1)';\n      bar.querySelector('button').addEventListener('click', () => {\n        dismissed = true; update();\n        try { localStorage.setItem('dx_sticky_dismissed_until', String(Date.now() + 7 * 864e5)); } catch (e) {}\n      });\n      window.addEventListener('scroll', update, { passive: true });\n      update();\n    })();\n  </script>\n"
#: in-content CTA + end CTA + sticky mobile bar
# ---------------------------------------------------------------------------------------------
inline_cta = '''<!-- NEW: mid-article CTA (inserted by build_guides.py after the 3rd <h2> section) -->
<aside id="guide-cta-inline" class="glass-card-green rounded-card p-6 md:p-8 my-10" aria-label="Join the DayXero beta">
  <div class="flex items-center gap-2 text-[10px] font-mono uppercase tracking-widest text-[#BCC388] mb-2"><span class="w-1.5 h-1.5 rounded-full bg-[#BCC388]"></span>DAYXERO iOS BETA</div>
  <div class="text-xl md:text-2xl font-extrabold tracking-tight text-white leading-snug mb-2">Want this plan on your iPhone?</div>
  <div class="text-sm text-white/65 leading-relaxed mb-5">DayXero is being built around exactly this: a Quit Day, five days of prep and a 3-minute craving tool. Join the beta for an early TestFlight invite.</div>
  ''' + waitlist_form("guide-quit-vaping-inline", "guide-inline-form", "Join the beta", compact=True) + '''
</aside>
'''

guide_d = head("Mockup (d): Guide CTAs | DayXero", "Guide page with in-content waitlist CTA and sticky mobile bar.") + '''<body class="bg-black text-white antialiased font-sans min-h-screen flex flex-col">
''' + guide_nav("vaping") + '''
  <main class="relative z-10 flex-1 px-4">
    <article class="max-w-3xl mx-auto pt-16 md:pt-24 pb-16">
      <nav class="text-xs text-white/40 font-mono mb-6" aria-label="Breadcrumb">
        <a href="/" class="hover:text-white">Home</a> <span aria-hidden="true">/</span>
        <a href="/guides/" class="hover:text-white">Guides</a> <span aria-hidden="true">/</span>
        <span class="text-white/70">Quit vaping</span>
      </nav>
      <h1 class="text-4xl md:text-6xl font-extrabold tracking-tight leading-[1.05] mb-6">How to Quit Vaping: A Step-by-Step Plan</h1>
      <p class="text-lg md:text-xl text-white/70 leading-relaxed mb-6">Vaping is easy to start and hard to stop, because you can do it almost anywhere. The habit ends up attached to waking up, driving, studying, stress and boredom all at once. Willpower alone rarely beats that. A plan does. Here is the one DayXero is built around.</p>
      <p class="text-xs text-white/40 font-mono mb-12">By <a href="/about/#editorial" class="underline underline-offset-4 decoration-white/30 hover:text-white">the DayXero team</a> · Updated <time datetime="2026-10-29">29 October 2026</time></p>
      <div class="prose-dx">
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
''' + inline_cta + '''
<h2 id="step-3">Step 3: Decide how you'll stop</h2>
<p>There are two common approaches, and both can work:</p>
<ul>
  <li><strong>Stop completely on Quit Day.</strong> Simple and clear. Best paired with a strong plan for cravings and, if you're very dependent, nicotine replacement.</li>
  <li><strong>Cut down first, then stop.</strong> Lower your e-liquid strength step by step, delay your first vape of the day, and set vape-free places (bedroom, car) before Quit Day.</li>
</ul>
<h2 id="step-6">Step 6: Ride out cravings, don't fight them</h2>
<p>A craving rises, peaks and fades, usually within a few minutes. Trying to push it away tends to make it louder. <a href="/nicotine-cravings/">Urge surfing</a> works the other way: notice where you feel it, breathe slowly, and watch it pass like a wave. DayXero's Craving SOS is being built to walk you through this in three minutes.</p>
<h2 id="step-7">Step 7: Treat a slip as information</h2>
<p>One puff isn't a relapse, and it doesn't erase your progress. The danger is the "I've blown it anyway" thinking that turns one slip into a week of vaping. Note what triggered it, adjust your plan, and carry on. That's why DayXero never resets your streak for a slip.</p>
      </div>

      <!-- CHANGED: end-of-article aside keeps its porcelain card, swaps "See plans" link for the form -->
      <aside id="beta-cta" class="porcelain-card rounded-card p-8 my-14 text-black">
        <div class="text-[10px] font-mono uppercase tracking-widest text-black/50 mb-2">The DayXero app · iOS beta</div>
        <h2 class="text-2xl md:text-3xl font-extrabold tracking-tight mb-3">Turn this plan into a daily routine</h2>
        <p class="text-sm text-black/70 leading-relaxed mb-6">DayXero is an iPhone app in development that walks you through five days of prep before your Quit Day, gets you through cravings in three minutes, and never resets your progress for a slip. Join the beta and we'll send your TestFlight invite, then the App Store link at launch.</p>
        ''' + waitlist_form("guide-quit-vaping-end", "guide-end-form", "Join the beta", tone="light") + '''
        ''' + microcopy("light", "left") + '''
      </aside>
    </article>
  </main>

  <!-- NEW: sticky mobile CTA bar (md:hidden). Appears after 25% scroll; hides while a form is on screen;
       dismiss is remembered in localStorage for 7 days. Matches the floating nav pill. -->
  <div id="sticky-cta" class="fixed bottom-4 inset-x-0 z-50 px-4 md:hidden">
    <div class="flex items-center justify-between gap-3 pl-4 pr-1.5 py-1.5 rounded-full bg-black/85 backdrop-blur-2xl border border-white/15 shadow-2xl shadow-black">
      <div class="flex items-center gap-2.5 min-w-0">
        <span class="w-2 h-2 shrink-0 rounded-full bg-[#BCC388] animate-ping"></span>
        <div class="flex flex-col min-w-0">
          <span class="text-xs font-bold text-white tracking-tight truncate">DayXero iOS beta</span>
          <span class="text-[9px] text-white/40 tracking-widest uppercase font-mono -mt-0.5 truncate">Free · Founding spots</span>
        </div>
      </div>
      <div class="flex items-center gap-1.5 shrink-0">
        <a href="#beta-cta" class="px-4 py-2.5 rounded-full bg-[#BCC388] text-black font-semibold text-xs tracking-tight hover:bg-white active:scale-95 spring-trans flex items-center gap-1.5">Join the beta ''' + ARROW_SM + '''</a>
        <button type="button" aria-label="Dismiss" class="w-8 h-8 rounded-full bg-[#161616] border border-white/15 text-white/60 hover:text-white flex items-center justify-center spring-trans">''' + ICON(XICON, "w-3.5 h-3.5") + '''</button>
      </div>
    </div>
  </div>
''' + guide_footer() + FORM_JS + '''</body>
</html>
'''
guide_d = guide_d.replace("</body>", STICKY_JS + "</body>")
open(os.path.join(OUT, "d-guide-cta-sticky.html"), "w").write(guide_d)


# ---------------------------------------------------------------------------------------------
# (e) DEDICATED /beta PAGE
# ---------------------------------------------------------------------------------------------
GIFT = '<rect x="3" y="8" width="18" height="4" rx="1"/><path d="M12 8v13"/><path d="M19 12v7a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2v-7"/><path d="M7.5 8a2.5 2.5 0 0 1 0-5A4.8 8 0 0 1 12 8a4.8 8 0 0 1 4.5-5 2.5 2.5 0 0 1 0 5"/>'
FLASK = '<path d="M10 2v7.31"/><path d="M14 9.3V1.99"/><path d="M8.5 2h7"/><path d="M14 9.3a6.5 6.5 0 1 1-4 0"/>'
CHAT = '<path d="M7.9 20A9 9 0 1 0 4 16.1L2 22Z"/><path d="M8 12h.01"/><path d="M12 12h.01"/><path d="M16 12h.01"/>'

beta_e = head("Join the DayXero iOS Beta", "Join the DayXero iOS beta: early TestFlight access and founding-member pricing.") + '''<body class="bg-black text-white antialiased font-sans min-h-screen flex flex-col">
''' + guide_nav(None, "#join") + '''
  <main class="relative z-10 flex-1 px-4">
    <section id="join" class="max-w-3xl mx-auto pt-16 md:pt-24 pb-16 flex flex-col items-center text-center">
      <!-- Shown only when ?r= is present (referral landing) -->
      <div class="inline-flex items-center gap-2 px-4 py-1.5 rounded-full bg-[#161616] border border-[#BCC388]/30 text-xs font-medium text-white/80 mb-4">
        <span class="w-2 h-2 rounded-full bg-[#BCC388]"></span>
        <span>A friend invited you. Join and you both move up the queue.</span>
      </div>
      <div class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#161616] border border-white/10 text-xs font-mono text-[#BCC388] mb-6">
        <span>DAYXERO iOS BETA · NOW ENROLLING</span>
      </div>
      <h1 class="text-4xl sm:text-6xl md:text-7xl font-extrabold tracking-tight leading-[1.05] mb-6">
        Be First <span class="text-white/40">to Quit on</span> <span class="text-transparent bg-clip-text bg-gradient-to-r from-white via-white to-[#BCC388]">Your Quit Day.</span>
      </h1>
      <p class="text-base sm:text-lg text-white/60 leading-relaxed max-w-2xl mb-10">DayXero is an iPhone app in development for quitting vaping, smoking and nicotine pouches. Beta members test it on TestFlight before anyone else and get founding-member pricing at launch.</p>
      <div class="w-full max-w-xl">
        ''' + waitlist_form("beta-page", "beta-form") + '''
        ''' + microcopy() + '''
      </div>
    </section>

    <section class="max-w-5xl mx-auto pb-16" aria-label="What beta members get">
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div class="porcelain-card p-8 rounded-card">
          <div class="w-12 h-12 rounded-full bg-black text-white flex items-center justify-center mb-6 shadow">''' + ICON(FLASK, "w-6 h-6") + '''</div>
          <div class="text-[11px] font-mono uppercase tracking-widest text-black/50 mb-2">EARLY ACCESS</div>
          <h3 class="text-2xl font-extrabold text-black mb-3">TestFlight before launch</h3>
          <p class="text-sm text-black/70 leading-relaxed">Invites go out in waves. Try the five-day prep program, Craving SOS and slip debriefs while they're still being shaped.</p>
        </div>
        <div class="glass-card-green p-8 rounded-card">
          <div class="w-12 h-12 rounded-full bg-[#161616] border border-[#BCC388]/30 flex items-center justify-center text-[#BCC388] mb-6 shadow">''' + ICON(GIFT, "w-6 h-6") + '''</div>
          <div class="text-[11px] font-mono uppercase tracking-widest text-[#BCC388] mb-2">FOUNDING PRICE</div>
          <h3 class="text-2xl font-extrabold text-white mb-3">Half off your first year</h3>
          <p class="text-sm text-white/70 leading-relaxed">The first 500 confirmed members get Annual at $19.99 for year one (planned $39.99), via an App Store offer code at launch.</p>
        </div>
        <div class="dark-card p-8 rounded-card">
          <div class="w-12 h-12 rounded-full bg-white text-black flex items-center justify-center mb-6 shadow">''' + ICON(CHAT, "w-6 h-6") + '''</div>
          <div class="text-[11px] font-mono uppercase tracking-widest text-white/50 mb-2">SHAPE IT</div>
          <h3 class="text-2xl font-extrabold text-white mb-3">Tell us what helps</h3>
          <p class="text-sm text-white/60 leading-relaxed">Beta feedback goes straight to the people building it. Vapes, cigarettes and pouches are all in scope.</p>
        </div>
      </div>
    </section>

    <section class="max-w-5xl mx-auto pb-16" aria-labelledby="how-heading">
      <div class="bg-[#121212] border border-white/10 rounded-card p-6 md:p-8 shadow-2xl">
        <div class="flex justify-between items-center mb-6">
          <h2 id="how-heading" class="text-xs font-mono text-white/40 uppercase tracking-wider">HOW THE BETA WORKS</h2>
          <div class="px-3.5 py-1.5 rounded-full bg-[#BCC388] text-black text-xs font-mono font-bold shadow">4 steps</div>
        </div>
        <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
          <div class="bg-[#141414] border border-white/5 p-4 rounded-2xl"><div class="w-8 h-8 rounded-full bg-[#BCC388] text-black font-bold text-xs flex items-center justify-center mb-3">1</div><div class="text-sm font-semibold text-white">Join with your email</div><div class="text-xs text-white/50 mt-1">One field. No account, no payment.</div></div>
          <div class="bg-[#141414] border border-white/5 p-4 rounded-2xl"><div class="w-8 h-8 rounded-full bg-[#BCC388] text-black font-bold text-xs flex items-center justify-center mb-3">2</div><div class="text-sm font-semibold text-white">Confirm the link</div><div class="text-xs text-white/50 mt-1">Saves your spot and founding price.</div></div>
          <div class="porcelain-card p-4 rounded-2xl"><div class="w-8 h-8 rounded-full bg-black text-white font-bold text-xs flex items-center justify-center mb-3">3</div><div class="text-sm font-extrabold text-black">Get a TestFlight invite</div><div class="text-xs text-black/60 mt-1">Sent in waves as spots open.</div></div>
          <div class="bg-[#101010] border border-white/5 p-4 rounded-2xl"><div class="w-8 h-8 rounded-full bg-[#1A1A1A] text-white/40 font-bold text-xs flex items-center justify-center mb-3">4</div><div class="text-sm font-semibold text-white/70">App Store link at launch</div><div class="text-xs text-white/40 mt-1">Plus your offer code.</div></div>
        </div>
      </div>
    </section>

    <section class="max-w-3xl mx-auto pb-24" aria-labelledby="beta-faq">
      <h2 id="beta-faq" class="text-2xl md:text-3xl font-extrabold tracking-tight mb-6 text-center">Beta questions</h2>
      <div class="flex flex-col gap-3">
        <details class="faq-item" open><summary>Is the beta free?</summary><p>Yes. TestFlight builds are free to install. You only pay if you choose a paid plan after launch.</p></details>
        <details class="faq-item"><summary>Do I need an iPhone?</summary><p>Yes. DayXero is a native iPhone app. TestFlight is Apple's official beta app, and we'll send instructions with your invite.</p></details>
        <details class="faq-item"><summary>When does DayXero launch?</summary><p>We haven't set a date yet. Beta members hear first, and the launch email includes the App Store link.</p></details>
        <details class="faq-item"><summary>Is DayXero medical treatment?</summary><p>No. DayXero is a habit and wellness tool, not a medical device or treatment. Talk to a doctor or pharmacist about nicotine replacement or stop-smoking medicines.</p></details>
      </div>
    </section>
  </main>
''' + guide_footer() + FORM_JS + '''</body>
</html>
'''
open(os.path.join(OUT, "e-beta-page.html"), "w").write(beta_e)
print("written")

# ---------------------------------------------------------------------------------------------
# INDEX
# ---------------------------------------------------------------------------------------------
ITEMS = [
    ("a-hero-waitlist", "(a) Hero waitlist", "porcelain", "Homepage hero: status pill becomes \"iOS beta · Now enrolling\", subhead says the app is in development, the palette strip slot becomes a one-field email form with honeypot + Turnstile, honest proof chips, nav CTA \"Get DayXero\" becomes \"Join the beta\". Showcase copy de-medicalised (removes \"Clinically formulated\", \"95% relapse\", \"neurochemical stabilization\")."),
    ("b-pricing-founding", "(b) Founding-member pricing", "glass", "Pricing keeps the three-card rhythm but labels prices as planned. Plan buttons no longer fire the \"Ready for App Store Checkout\" toast: Monthly/Lifetime expand into a \"Notify me\" form (plan interest captured), Annual carries the founding offer and its own form. FAQ rewritten for pre-launch."),
    ("c-success-referral", "(c) After signup", "dark", "State 1 replaces the form inline: confirm-your-email card (double opt-in). State 2 is /beta/confirmed: queue position, founding badge, copyable referral link, share buttons, friends-joined progress bar and what happens next."),
    ("d-guide-cta-sticky", "(d) Guide CTAs + sticky bar", "dark", "Guide pages (build_guides.py): nav CTA to /beta/, a glass mid-article CTA after the 3rd section, the end porcelain aside becomes a form, and a sticky mobile pill bar that hides while a form is visible and can be dismissed."),
    ("e-beta-page", "(e) /beta page", "glass", "Dedicated waitlist URL for social bios, Reddit/TikTok links and referral links (?r=CODE shows the \"A friend invited you\" pill). Form, three benefit cards, how-the-beta-works steps, beta FAQ."),
]
cards = []
for slug, title, kind, note in ITEMS:
    cls = {"porcelain": "porcelain-card", "glass": "glass-card-green", "dark": "dark-card"}[kind]
    tone_t = "text-black" if kind == "porcelain" else "text-white"
    tone_m = "text-black/60" if kind == "porcelain" else "text-white/60"
    tone_l = "text-black/50" if kind == "porcelain" else "text-[#BCC388]"
    cards.append(f'''      <a href="{slug}.html" class="{cls} rounded-card p-6 flex flex-col gap-3 hover:scale-[1.02] spring-trans">
        <span class="text-[10px] font-mono uppercase tracking-widest {tone_l}">{slug}.html</span>
        <span class="text-xl font-extrabold tracking-tight {tone_t}">{title}</span>
        <span class="text-sm {tone_m} leading-relaxed">{note}</span>
        <span class="grid grid-cols-3 gap-2 mt-2 items-start">
          <img src="{slug}-desktop.png" alt="{title} at 1440px" loading="lazy" class="col-span-2 w-full h-40 object-cover object-top rounded-2xl border border-white/10">
          <img src="{slug}-mobile.png" alt="{title} at 390px" loading="lazy" class="w-full h-40 object-cover object-top rounded-2xl border border-white/10">
        </span>
      </a>''')
index = head("DayXero pre-launch mockups", "Index of DayXero pre-launch waitlist mockups.") + '''<body class="bg-black text-white antialiased font-sans min-h-screen flex flex-col">
  <div class="fixed top-0 left-1/2 -translate-x-1/2 w-[1000px] max-w-full h-[300px] bg-gradient-to-b from-[#43511C]/25 via-[#BCC388]/10 to-transparent blur-[140px] pointer-events-none z-0"></div>
  <main class="relative z-10 flex-1 px-4">
    <section class="max-w-5xl mx-auto pt-16 md:pt-24 pb-10 text-center">
      ''' + section_badge("PRE-LAUNCH MOCKUPS") + '''
      <h1 class="text-4xl md:text-6xl font-extrabold tracking-tight leading-[1.05] mb-4">Waitlist <span class="text-white/40">&amp;</span> Beta Signups</h1>
      <p class="text-sm md:text-base text-white/60 max-w-2xl mx-auto">Each mockup links the live <span class="font-mono text-white/80">website/assets/site.css</span> and reuses markup from index.html and the guide template. Utilities not yet in the compiled CSS are inlined per page. Full rationale, change table and backend spec: <span class="font-mono text-white/80">../website_changes_and_mockups.md</span>.</p>
    </section>
    <section class="max-w-5xl mx-auto pb-24 grid grid-cols-1 md:grid-cols-2 gap-6">
''' + "\n".join(cards) + '''
      <div class="dark-card rounded-card p-6 flex flex-col gap-3">
        <span class="text-[10px] font-mono uppercase tracking-widest text-white/50">Extra screenshots</span>
        <span class="text-xl font-extrabold tracking-tight text-white">Sticky bar in context (390px)</span>
        <span class="grid grid-cols-2 gap-2 mt-2">
          <img src="d-guide-cta-sticky-mobile-viewport-sticky.png" alt="Sticky bar visible while reading" class="w-full rounded-2xl border border-white/10">
          <img src="d-guide-cta-sticky-mobile-viewport-inline.png" alt="Sticky bar hidden while the inline form is visible" class="w-full rounded-2xl border border-white/10">
        </span>
        <span class="text-sm text-white/60">Left: bar visible mid-article. Right: bar hidden because the inline form is on screen.</span>
      </div>
    </section>
  </main>
</body>
</html>
'''
open(os.path.join(OUT, "index.html"), "w").write(index)
print("index written")
