// Waitlist forms, the post-signup confirm card, the /beta/confirmed/ page and the guide sticky bar.
// Shared by the homepage, guide pages and /beta/. Forms POST to the Worker route /api/waitlist (worker/index.js).
(function () {
  'use strict';

  // Cloudflare Turnstile site key. Leave empty to skip the widget (the Worker then skips verification too,
  // unless TURNSTILE_SECRET is set). See worker/README.md.
  const TURNSTILE_SITE_KEY = '';
  const CONTACT_EMAIL = 'hello@dayxero.in';

  const ICON_MAIL = '<svg class="w-6 h-6" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect width="20" height="16" x="2" y="4" rx="2"/><path d="m22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7"/></svg>';

  // --- Referral code: carried from ?r= on any page into every signup in this tab ---
  function readRef() {
    const fromUrl = new URLSearchParams(location.search).get('r');
    if (fromUrl && /^[A-Z0-9]{4,12}$/i.test(fromUrl)) {
      try { sessionStorage.setItem('dx_ref', fromUrl.toUpperCase()); } catch (e) {}
      return fromUrl.toUpperCase();
    }
    try { return sessionStorage.getItem('dx_ref') || ''; } catch (e) { return ''; }
  }
  const REF = readRef();
  if (REF) document.querySelectorAll('[data-ref-only]').forEach((el) => { el.hidden = false; });

  function escapeHtml(s) {
    return String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  }

  function maskEmail(email) {
    const [user, domain] = email.split('@');
    return `${user.slice(0, 1)}•••@${domain}`;
  }

  // --- Turnstile (optional) ---
  let turnstileReady = null;
  function loadTurnstile() {
    if (!TURNSTILE_SITE_KEY) return Promise.resolve(null);
    if (!turnstileReady) {
      turnstileReady = new Promise((resolve) => {
        window.dxTurnstileLoaded = () => resolve(window.turnstile);
        const s = document.createElement('script');
        s.src = 'https://challenges.cloudflare.com/turnstile/v0/api.js?onload=dxTurnstileLoaded&render=explicit';
        s.async = true;
        s.onerror = () => resolve(null);
        document.head.appendChild(s);
      });
    }
    return turnstileReady;
  }
  function renderTurnstile(form) {
    if (!TURNSTILE_SITE_KEY) return;
    const slot = document.createElement('div');
    slot.className = 'mt-3';
    form.appendChild(slot);
    loadTurnstile().then((ts) => {
      if (!ts) return;
      form.dataset.turnstileId = ts.render(slot, {
        sitekey: TURNSTILE_SITE_KEY, appearance: 'interaction-only', size: 'flexible',
      });
    });
  }
  function turnstileToken(form) {
    if (!TURNSTILE_SITE_KEY || !window.turnstile || !form.dataset.turnstileId) return '';
    return window.turnstile.getResponse(form.dataset.turnstileId) || '';
  }
  function resetTurnstile(form) {
    if (window.turnstile && form.dataset.turnstileId) window.turnstile.reset(form.dataset.turnstileId);
  }

  // --- Submitting ---
  async function postSignup(form, email) {
    const body = {
      email,
      source: form.querySelector('[name=source]')?.value || '',
      plan_interest: form.querySelector('[name=plan_interest]')?.value || '',
      company: form.querySelector('[name=company]')?.value || '',
      ref: REF,
      turnstile_token: turnstileToken(form),
      page: location.pathname,
    };
    const res = await fetch('/api/waitlist', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    let data = {};
    try { data = await res.json(); } catch (e) {}
    return { status: res.status, data };
  }

  function messageFor(status, data) {
    if (status === 503 || data.error === 'not_configured') {
      return `Signups open in a few days. Email <a href="mailto:${CONTACT_EMAIL}" class="underline underline-offset-4">${CONTACT_EMAIL}</a> and we'll add you now.`;
    }
    if (status === 429) return 'Too many tries from this connection. Wait a few minutes and try again.';
    if (data.error === 'invalid_email') return 'That email address doesn’t look right. Check it and try again.';
    if (data.error === 'challenge_failed') return 'We couldn’t confirm you’re not a bot. Reload the page and try again.';
    return 'We couldn’t add you just now. Check your connection and try again.';
  }

  function msgEl(form) {
    let el = form.parentNode.querySelector(`[data-waitlist-msg="${form.id}"]`);
    if (!el) {
      el = document.createElement('p');
      el.dataset.waitlistMsg = form.id;
      el.setAttribute('role', 'status');
      el.setAttribute('aria-live', 'polite');
      el.className = 'text-xs leading-relaxed mt-3 ' + (form.dataset.theme === 'light' ? 'text-black/70' : 'text-white/70');
      form.insertAdjacentElement('afterend', el);
    }
    return el;
  }

  // State 1 card: replaces the form (and its microcopy) until the person confirms by email.
  function confirmCard(email, light, sent) {
    const card = document.createElement('div');
    card.setAttribute('role', 'status');
    card.setAttribute('aria-live', 'polite');
    card.className = light
      ? 'rounded-card p-6 bg-black/5 border border-black/10 text-left'
      : 'glass-card-green rounded-card p-6 text-left';
    const t = light
      ? { icon: 'bg-white border border-black/10 text-black', kicker: 'text-black/50', h: 'text-black', p: 'text-black/70', strong: 'text-black',
          primary: 'bg-black text-white hover:bg-[#202020]', secondary: 'bg-white text-black/60 hover:text-black border border-black/10' }
      : { icon: 'bg-[#161616] border border-[#BCC388]/30 text-[#BCC388]', kicker: 'text-[#BCC388]', h: 'text-white', p: 'text-white/70', strong: 'text-white',
          primary: 'bg-white text-black hover:bg-[#BCC388]', secondary: 'bg-[#161616] text-white/60 hover:text-white border border-white/10' };
    card.innerHTML = `
      <div class="w-12 h-12 rounded-full ${t.icon} flex items-center justify-center mb-5 shadow">${ICON_MAIL}</div>
      <div class="text-[11px] font-mono uppercase tracking-widest ${t.kicker} mb-2">Step 1 of 2 · ${sent ? 'Check your inbox' : 'You’re on the list'}</div>
      <div class="text-2xl font-extrabold tracking-tight ${t.h} mb-3">${sent ? 'Confirm your email to save your spot.' : 'We’ll email you a link to confirm.'}</div>
      <p class="text-sm ${t.p} leading-relaxed mb-6">${sent
        ? `We sent a link to <span class="${t.strong} font-semibold">${escapeHtml(maskEmail(email))}</span>. Tap it within 24 hours. Can't see it? Check Promotions or Spam.`
        : `We saved <span class="${t.strong} font-semibold">${escapeHtml(maskEmail(email))}</span>. A confirmation link is on its way soon. Tap it to keep your spot.`}</p>
      <div class="flex flex-wrap items-center gap-3">
        ${sent ? `<button type="button" data-action="resend" class="px-5 py-3 rounded-full ${t.primary} font-semibold text-xs tracking-tight active:scale-95 spring-trans shadow-xl">Resend email</button>` : ''}
        <button type="button" data-action="change" class="px-5 py-3 rounded-full ${t.secondary} text-xs font-medium active:scale-95 spring-trans">Use a different email</button>
      </div>
      <p data-card-msg class="text-xs ${t.p} mt-4" hidden></p>`;
    return card;
  }

  function wireForm(form) {
    renderTurnstile(form);
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      const input = form.querySelector('input[type=email]');
      const button = form.querySelector('button[type=submit]');
      const msg = msgEl(form);
      const email = input.value.trim();
      if (!email || !input.checkValidity()) {
        msg.textContent = 'Enter your email address to join the beta.';
        input.focus();
        return;
      }
      button.disabled = true;
      button.classList.add('opacity-50');
      msg.textContent = '';
      try {
        const { status, data } = await postSignup(form, email);
        if (status === 200 && data.ok) {
          showConfirm(form, email, data.confirmation !== 'later');
        } else {
          msg.innerHTML = messageFor(status, data);
          resetTurnstile(form);
        }
      } catch (err) {
        msg.innerHTML = messageFor(0, {});
      } finally {
        button.disabled = false;
        button.classList.remove('opacity-50');
      }
    });
  }

  function showConfirm(form, email, sent) {
    // The block to swap: the form plus its microcopy sit in [data-waitlist-block] when there is one.
    const block = form.closest('[data-waitlist-block]') || form;
    const card = confirmCard(email, form.dataset.theme === 'light', sent);
    block.hidden = true;
    block.insertAdjacentElement('afterend', card);
    const cardMsg = card.querySelector('[data-card-msg]');
    card.querySelector('[data-action=change]').addEventListener('click', () => {
      card.remove();
      block.hidden = false;
      const input = form.querySelector('input[type=email]');
      input.value = '';
      input.focus();
    });
    card.querySelector('[data-action=resend]')?.addEventListener('click', async (e) => {
      const btn = e.currentTarget;
      btn.disabled = true;
      try {
        const { status, data } = await postSignup(form, email);
        cardMsg.innerHTML = status === 200 && data.ok ? 'Sent again. It can take a minute to arrive.' : messageFor(status, data);
      } catch (err) {
        cardMsg.innerHTML = messageFor(0, {});
      }
      cardMsg.hidden = false;
      setTimeout(() => { btn.disabled = false; }, 30000);
    });
    card.querySelector('button').focus({ preventScroll: true });
  }

  document.querySelectorAll('form.waitlist-form').forEach(wireForm);

  // --- Pricing: "Notify me at launch" reveals that plan's form ---
  document.querySelectorAll('[data-notify-plan]').forEach((btn) => {
    btn.addEventListener('click', () => {
      const slot = document.getElementById(btn.dataset.target);
      if (!slot) return;
      btn.hidden = true;
      slot.hidden = false;
      slot.querySelector('input[type=email]')?.focus();
    });
  });

  // --- Guide pages: sticky mobile bar. Shows after the intro, hides while a signup block is on screen,
  // and remembers a dismissal for 7 days. ---
  const bar = document.getElementById('sticky-cta');
  if (bar) {
    let dismissed = false;
    try { dismissed = Date.now() < Number(localStorage.getItem('dx_sticky_dismissed_until') || 0); } catch (e) {}
    const visibleBlocks = new Set();
    const update = () => {
      const show = !dismissed && window.scrollY > 300 && visibleBlocks.size === 0;
      bar.style.transform = show ? 'translateY(0)' : 'translateY(160%)';
      bar.setAttribute('aria-hidden', show ? 'false' : 'true');
    };
    if ('IntersectionObserver' in window) {
      const io = new IntersectionObserver((entries) => {
        entries.forEach((en) => (en.isIntersecting ? visibleBlocks.add(en.target) : visibleBlocks.delete(en.target)));
        update();
      });
      document.querySelectorAll('[data-hide-sticky]').forEach((el) => io.observe(el));
    }
    bar.style.transition = 'transform 0.38s cubic-bezier(0.16, 1, 0.3, 1)';
    bar.querySelector('[data-action=dismiss]').addEventListener('click', () => {
      dismissed = true;
      update();
      try { localStorage.setItem('dx_sticky_dismissed_until', String(Date.now() + 7 * 864e5)); } catch (e) {}
    });
    window.addEventListener('scroll', update, { passive: true });
    update();
  }

  // --- /beta/confirmed/: queue position, invite link and sharing ---
  const confirmed = document.getElementById('beta-confirmed');
  if (confirmed) {
    const params = new URLSearchParams(location.search);
    const code = (params.get('r') || '').toUpperCase();
    const link = `${location.origin}/beta/?r=${encodeURIComponent(code)}`;
    const shareText = 'Join me on the DayXero iOS beta';
    const linkInput = document.getElementById('ref-link');
    const copyBtn = document.getElementById('btn-copy-ref');
    const status = document.getElementById('confirmed-status');

    if (params.get('error') === 'expired') {
      status.hidden = false;
      status.textContent = 'That confirmation link has expired or was already used. If you confirmed before, you’re still on the list. Otherwise, join again from the form.';
    }

    if (/^[A-Z0-9]{4,12}$/.test(code)) {
      linkInput.value = link.replace(/^https?:\/\//, '');
      document.querySelectorAll('[data-needs-code]').forEach((el) => { el.hidden = false; });

      fetch(`/api/waitlist/status?r=${encodeURIComponent(code)}`)
        .then((r) => (r.ok ? r.json() : null))
        .then((d) => {
          if (!d || !d.ok) return;
          document.getElementById('queue-position').textContent = `#${d.position.toLocaleString('en-US')}`;
          document.getElementById('queue-row').hidden = false;
          const goal = d.referral_goal || 3;
          const joined = Math.min(d.referrals, goal);
          document.getElementById('friends-count').textContent = `${joined} / ${goal} · first-wave access`;
          document.getElementById('friends-bar').style.width = `${Math.round((joined / goal) * 100)}%`;
        })
        .catch(() => {});

      copyBtn.addEventListener('click', async () => {
        try {
          await navigator.clipboard.writeText(link);
          copyBtn.querySelector('span').textContent = 'Copied';
        } catch (e) {
          linkInput.select();
        }
        setTimeout(() => { copyBtn.querySelector('span').textContent = 'Copy'; }, 2000);
      });

      const shareBtn = document.getElementById('btn-share');
      if (navigator.share) {
        shareBtn.addEventListener('click', () => navigator.share({ title: 'DayXero beta', text: shareText, url: link }).catch(() => {}));
      } else {
        shareBtn.hidden = true;
      }
      document.getElementById('btn-share-sms').href = `sms:?&body=${encodeURIComponent(`${shareText}: ${link}`)}`;
      document.getElementById('btn-share-x').href = `https://x.com/intent/post?text=${encodeURIComponent(shareText)}&url=${encodeURIComponent(link)}`;
      document.getElementById('btn-share-email').href = `mailto:?subject=${encodeURIComponent('DayXero beta')}&body=${encodeURIComponent(`${shareText}: ${link}`)}`;
    }
  }
})();
