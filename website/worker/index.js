// The "dayxero" Worker: serves the static site and the beta waitlist API.
// Only /api/* reaches this code (run_worker_first in wrangler.jsonc); every other path is a static asset.
// Setup (D1 database, email and Turnstile keys) is in worker/README.md.

const CONSENT_VERSION = '2026-10-29';
const CONSENT_TEXT = "Email me a confirmation link, my TestFlight invite, the App Store link at launch and occasional beta updates. Unsubscribe anytime.";
const CONFIRM_TTL_MS = 48 * 3600 * 1000;
const RESEND_COOLDOWN_MS = 60 * 1000;
const MAX_SENDS_PER_EMAIL = 5;
const MAX_SIGNUPS_PER_IP_PER_HOUR = 5;
const REFERRAL_BOOST = 10; // queue spots gained per confirmed friend
const REFERRAL_GOAL = 3;

const SCHEMA = [
  `CREATE TABLE IF NOT EXISTS waitlist (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'pending',
    ref_code TEXT NOT NULL UNIQUE,
    referred_by TEXT,
    plan_interest TEXT,
    source TEXT,
    page TEXT,
    country TEXT,
    consent_text TEXT NOT NULL,
    consent_version TEXT NOT NULL,
    confirm_token_hash TEXT,
    confirm_sent_at INTEGER,
    send_count INTEGER NOT NULL DEFAULT 0,
    unsub_token TEXT NOT NULL,
    ip_hash TEXT,
    created_at INTEGER NOT NULL,
    confirmed_at INTEGER,
    unsubscribed_at INTEGER
  )`,
  'CREATE INDEX IF NOT EXISTS waitlist_ip ON waitlist (ip_hash, created_at)',
  'CREATE INDEX IF NOT EXISTS waitlist_referred_by ON waitlist (referred_by, status)',
  'CREATE INDEX IF NOT EXISTS waitlist_token ON waitlist (confirm_token_hash)',
];

let schemaReady = null;
function ensureSchema(db) {
  if (!schemaReady) {
    schemaReady = db.batch(SCHEMA.map((sql) => db.prepare(sql))).catch((err) => {
      schemaReady = null;
      throw err;
    });
  }
  return schemaReady;
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (!url.pathname.startsWith('/api/')) return env.ASSETS.fetch(request);
    try {
      return await handleApi(request, env, url);
    } catch (err) {
      console.error('api error', err);
      return json({ ok: false, error: 'server_error' }, 500);
    }
  },

  // Cron: deletes unconfirmed signups after 30 days (the privacy policy promises this), then sends
  // confirmation emails that were held back (no email key yet, daily send cap, provider error).
  async scheduled(event, env) {
    if (!env.DB) return;
    await ensureSchema(env.DB);
    await env.DB.prepare(`DELETE FROM waitlist WHERE status = 'pending' AND created_at < ?`)
      .bind(Date.now() - 30 * 24 * 3600 * 1000).run();
    if (!mailConfigured(env)) return;
    const since = Date.now() - 7 * 24 * 3600 * 1000;
    const { results } = await env.DB.prepare(
      `SELECT id, email, unsub_token FROM waitlist
       WHERE status = 'pending' AND confirm_sent_at IS NULL AND created_at > ? ORDER BY id LIMIT 50`,
    ).bind(since).all();
    for (const row of results) {
      const sent = await issueConfirmation(env, siteOrigin(env), row);
      if (!sent) break; // provider refused (likely the daily cap): try again next run
    }
  },
};

async function handleApi(request, env, url) {
  const route = `${request.method} ${url.pathname.replace(/\/+$/, '')}`;
  if (!env.DB) return json({ ok: false, error: 'not_configured' }, 503);
  await ensureSchema(env.DB);

  switch (route) {
    case 'POST /api/waitlist': return signup(request, env, url);
    case 'GET /api/waitlist/confirm': return confirm(env, url);
    case 'GET /api/waitlist/status': return status(env, url);
    case 'GET /api/waitlist/unsubscribe': return unsubscribePage(url);
    case 'POST /api/waitlist/unsubscribe': return unsubscribe(env, url);
    case 'GET /api/waitlist/export': return exportCsv(request, env);
    default: return json({ ok: false, error: 'not_found' }, 404);
  }
}

async function signup(request, env, url) {
  const origin = request.headers.get('Origin');
  if (origin && new URL(origin).host !== url.host) return json({ ok: false, error: 'forbidden' }, 403);

  let body;
  try {
    body = await request.json();
  } catch (e) {
    return json({ ok: false, error: 'bad_request' }, 400);
  }

  // Honeypot: people never see this field, so anything in it is a bot. Pretend it worked.
  if (body.company) return json({ ok: true });

  const email = String(body.email || '').trim().toLowerCase();
  if (!isEmail(email)) return json({ ok: false, error: 'invalid_email' }, 400);

  const ip = request.headers.get('CF-Connecting-IP') || '';
  if (env.TURNSTILE_SECRET) {
    const passed = await verifyTurnstile(env.TURNSTILE_SECRET, String(body.turnstile_token || ''), ip);
    if (!passed) return json({ ok: false, error: 'challenge_failed' }, 400);
  }

  const now = Date.now();
  const ipHash = await sha256(`${env.IP_SALT || 'dayxero-waitlist'}:${ip}`);
  const existing = await env.DB.prepare('SELECT * FROM waitlist WHERE email = ?').bind(email).first();

  if (!existing) {
    const recent = await env.DB.prepare('SELECT COUNT(*) AS n FROM waitlist WHERE ip_hash = ? AND created_at > ?')
      .bind(ipHash, now - 3600 * 1000).first();
    if (recent.n >= MAX_SIGNUPS_PER_IP_PER_HOUR) return json({ ok: false, error: 'rate_limited' }, 429);

    const referredBy = cleanCode(body.ref);
    const row = {
      email,
      ref_code: await uniqueRefCode(env.DB),
      unsub_token: randomToken(),
    };
    await env.DB.prepare(
      `INSERT INTO waitlist (email, ref_code, referred_by, plan_interest, source, page, country,
         consent_text, consent_version, unsub_token, ip_hash, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?) ON CONFLICT(email) DO NOTHING`,
    ).bind(
      email, row.ref_code, referredBy, clean(body.plan_interest), clean(body.source), clean(body.page, 128),
      request.cf?.country || null, CONSENT_TEXT, CONSENT_VERSION, row.unsub_token, ipHash, now,
    ).run();
    const inserted = await env.DB.prepare('SELECT id, email, unsub_token FROM waitlist WHERE email = ?').bind(email).first();
    if (inserted) await issueConfirmation(env, url.origin, inserted);
    return signedUp(env);
  }

  // Known email. The response is the same either way, so the list can't be probed.
  if (existing.status === 'confirmed') return signedUp(env);

  if (existing.status === 'unsubscribed') {
    await env.DB.prepare(
      `UPDATE waitlist SET status = 'pending', unsubscribed_at = NULL, send_count = 0,
         consent_text = ?, consent_version = ? WHERE id = ?`,
    ).bind(CONSENT_TEXT, CONSENT_VERSION, existing.id).run();
    existing.send_count = 0;
    existing.confirm_sent_at = null;
  }
  const cooledDown = !existing.confirm_sent_at || now - existing.confirm_sent_at > RESEND_COOLDOWN_MS;
  if (cooledDown && existing.send_count < MAX_SENDS_PER_EMAIL) await issueConfirmation(env, url.origin, existing);
  return signedUp(env);
}

// "sent": a confirmation email went out (or would have). "later": email isn't set up yet, so the cron sends it once it is.
function signedUp(env) {
  return json({ ok: true, confirmation: mailConfigured(env) ? 'sent' : 'later' });
}

// Creates a fresh confirmation token and emails it. Returns false if the email wasn't sent.
async function issueConfirmation(env, origin, row) {
  if (!mailConfigured(env)) return false;
  const token = randomToken();
  const confirmUrl = `${origin}/api/waitlist/confirm?t=${token}`;
  const unsubUrl = `${origin}/api/waitlist/unsubscribe?t=${row.unsub_token}`;
  const sent = await sendConfirmationEmail(env, row.email, confirmUrl, unsubUrl);
  if (!sent) return false;
  await env.DB.prepare(
    'UPDATE waitlist SET confirm_token_hash = ?, confirm_sent_at = ?, send_count = send_count + 1 WHERE id = ?',
  ).bind(await sha256(token), Date.now(), row.id).run();
  return true;
}

async function confirm(env, url) {
  const token = url.searchParams.get('t') || '';
  if (!/^[a-f0-9]{64}$/.test(token)) return redirect(url, '/beta/confirmed/?error=expired');
  const row = await env.DB.prepare('SELECT id, ref_code, confirm_sent_at FROM waitlist WHERE confirm_token_hash = ?')
    .bind(await sha256(token)).first();
  if (!row || Date.now() - row.confirm_sent_at > CONFIRM_TTL_MS) return redirect(url, '/beta/confirmed/?error=expired');
  await env.DB.prepare(
    `UPDATE waitlist SET status = 'confirmed', confirmed_at = ?, confirm_token_hash = NULL WHERE id = ?`,
  ).bind(Date.now(), row.id).run();
  return redirect(url, `/beta/confirmed/?r=${row.ref_code}`);
}

async function status(env, url) {
  const code = cleanCode(url.searchParams.get('r'));
  if (!code) return json({ ok: false, error: 'not_found' }, 404);
  const row = await env.DB.prepare(`SELECT id FROM waitlist WHERE ref_code = ? AND status = 'confirmed'`).bind(code).first();
  if (!row) return json({ ok: false, error: 'not_found' }, 404);
  const ahead = await env.DB.prepare(`SELECT COUNT(*) AS n FROM waitlist WHERE status = 'confirmed' AND id < ?`)
    .bind(row.id).first();
  const referrals = await env.DB.prepare(`SELECT COUNT(*) AS n FROM waitlist WHERE referred_by = ? AND status = 'confirmed'`)
    .bind(code).first();
  const position = Math.max(1, ahead.n + 1 - referrals.n * REFERRAL_BOOST);
  return json({ ok: true, position, referrals: referrals.n, referral_goal: REFERRAL_GOAL });
}

// GET shows a button rather than unsubscribing, so link scanners can't unsubscribe people.
// Mail clients' one-click unsubscribe (RFC 8058) POSTs to the same URL.
function unsubscribePage(url) {
  const token = url.searchParams.get('t') || '';
  return page('Unsubscribe', `
    <div style="display: flex; justify-content: center"><span data-crew="xero" data-mood="calm" data-stage="2" data-size="160"></span></div>
    <h1 class="d">Leave the DayXero beta list?</h1>
    <p>You won't get your TestFlight invite or the launch email.</p>
    <form method="post" action="/api/waitlist/unsubscribe?t=${encodeURIComponent(token)}">
      <button type="submit" class="btn btn-apricot">Unsubscribe</button>
    </form>`);
}

async function unsubscribe(env, url) {
  const token = url.searchParams.get('t') || '';
  if (/^[a-f0-9]{64}$/.test(token)) {
    await env.DB.prepare(
      `UPDATE waitlist SET status = 'unsubscribed', unsubscribed_at = ?, confirm_token_hash = NULL WHERE unsub_token = ?`,
    ).bind(Date.now(), token).run();
  }
  return page('Unsubscribed', `
    <div style="display: flex; justify-content: center"><span data-crew="glim" data-mood="sleepy" data-stage="2" data-size="160"></span></div>
    <h1 class="d">You're unsubscribed.</h1>
    <p>We won't email you again. Changed your mind? Join again any time.</p>
    <a href="/beta/" class="btn btn-apricot">Back to DayXero</a>`);
}

// For the launch email: confirmed members as CSV, for import into Kit or Brevo.
// curl -H "Authorization: Bearer $ADMIN_TOKEN" https://dayxero.in/api/waitlist/export > waitlist.csv
async function exportCsv(request, env) {
  const auth = request.headers.get('Authorization') || '';
  if (!env.ADMIN_TOKEN || auth !== `Bearer ${env.ADMIN_TOKEN}`) return json({ ok: false, error: 'unauthorized' }, 401);
  const { results } = await env.DB.prepare(
    `SELECT email, ref_code, referred_by, plan_interest, source, country, consent_version, created_at, confirmed_at
     FROM waitlist WHERE status = 'confirmed' ORDER BY id`,
  ).all();
  const cols = ['email', 'ref_code', 'referred_by', 'plan_interest', 'source', 'country', 'consent_version', 'created_at', 'confirmed_at'];
  const esc = (v) => (v == null ? '' : /[",\n]/.test(String(v)) ? `"${String(v).replace(/"/g, '""')}"` : String(v));
  const csv = [cols.join(','), ...results.map((r) => cols.map((c) => esc(r[c])).join(','))].join('\n');
  return new Response(csv + '\n', {
    headers: { 'Content-Type': 'text/csv; charset=utf-8', 'Cache-Control': 'no-store' },
  });
}

// --- Email (Resend) ---

function mailConfigured(env) {
  return Boolean(env.RESEND_API_KEY && env.MAIL_FROM);
}

async function sendConfirmationEmail(env, to, confirmUrl, unsubUrl) {
  const text = [
    'Confirm your spot on the DayXero beta:',
    confirmUrl,
    '',
    "Once you confirm, we'll email your TestFlight invite as beta spots open, then the App Store link at launch.",
    "If you didn't sign up, ignore this email and you won't hear from us again.",
    '',
    `Unsubscribe: ${unsubUrl}`,
  ].join('\n');
  const html = `<!doctype html><html><body style="margin:0;background:#000;color:#fff;font-family:Inter,-apple-system,Segoe UI,sans-serif">
  <div style="max-width:480px;margin:0 auto;padding:40px 24px">
    <div style="font-weight:700;font-size:15px;margin-bottom:32px">DayXero</div>
    <h1 style="font-size:24px;line-height:1.2;margin:0 0 16px">Confirm your spot on the DayXero beta</h1>
    <p style="font-size:15px;line-height:1.6;color:rgba(255,255,255,.7);margin:0 0 28px">Tap the button to save your place. Then we'll email your TestFlight invite as beta spots open, and the App Store link at launch.</p>
    <a href="${confirmUrl}" style="display:inline-block;background:#BCC388;color:#000;text-decoration:none;font-weight:600;font-size:14px;padding:14px 26px;border-radius:999px">Confirm my email</a>
    <p style="font-size:13px;line-height:1.6;color:rgba(255,255,255,.45);margin:32px 0 0">The link works for 48 hours. If you didn't sign up, ignore this email and you won't hear from us again.</p>
    <p style="font-size:12px;line-height:1.6;color:rgba(255,255,255,.35);margin:24px 0 0"><a href="${unsubUrl}" style="color:rgba(255,255,255,.5)">Unsubscribe</a></p>
  </div></body></html>`;
  try {
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: { Authorization: `Bearer ${env.RESEND_API_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        from: env.MAIL_FROM,
        to: [to],
        subject: 'Confirm your spot on the DayXero beta',
        text,
        html,
        headers: { 'List-Unsubscribe': `<${unsubUrl}>`, 'List-Unsubscribe-Post': 'List-Unsubscribe=One-Click' },
      }),
    });
    if (!res.ok) console.error('resend error', res.status, await res.text());
    return res.ok;
  } catch (err) {
    console.error('resend fetch failed', err);
    return false;
  }
}

async function verifyTurnstile(secret, token, ip) {
  if (!token) return false;
  const form = new FormData();
  form.append('secret', secret);
  form.append('response', token);
  if (ip) form.append('remoteip', ip);
  const res = await fetch('https://challenges.cloudflare.com/turnstile/v0/siteverify', { method: 'POST', body: form });
  const data = await res.json().catch(() => ({}));
  return data.success === true;
}

// --- Helpers ---

function siteOrigin(env) {
  return env.SITE_URL || 'https://dayxero.in';
}

function isEmail(s) {
  return s.length <= 254 && /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/.test(s);
}

function clean(value, max = 64) {
  const s = String(value || '').trim().slice(0, max);
  return /^[\w\-./]*$/.test(s) && s ? s : null;
}

function cleanCode(value) {
  const s = String(value || '').trim().toUpperCase();
  return /^[A-Z0-9]{4,12}$/.test(s) ? s : null;
}

const CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no 0/O or 1/I
async function uniqueRefCode(db) {
  for (;;) {
    const bytes = crypto.getRandomValues(new Uint8Array(5));
    const code = Array.from(bytes, (b) => CODE_ALPHABET[b % CODE_ALPHABET.length]).join('');
    const taken = await db.prepare('SELECT 1 FROM waitlist WHERE ref_code = ?').bind(code).first();
    if (!taken) return code;
  }
}

function randomToken() {
  return Array.from(crypto.getRandomValues(new Uint8Array(32)), (b) => b.toString(16).padStart(2, '0')).join('');
}

async function sha256(s) {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(s));
  return Array.from(new Uint8Array(digest), (b) => b.toString(16).padStart(2, '0')).join('');
}

function json(data, status = 200) {
  return new Response(JSON.stringify(data), {
    status,
    headers: { 'Content-Type': 'application/json', 'Cache-Control': 'no-store' },
  });
}

function redirect(url, path) {
  return Response.redirect(new URL(path, url.origin).toString(), 303);
}

function page(title, inner) {
  return new Response(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${title} | DayXero</title>
  <meta name="robots" content="noindex">
  <link rel="icon" type="image/svg+xml" href="/favicon.svg">
  <meta name="theme-color" content="#241433">
  <link href="https://fonts.googleapis.com/css2?family=Bricolage+Grotesque:opsz,wght@12..96,800&family=DM+Sans:wght@500;700&display=swap" rel="stylesheet">
  <link rel="stylesheet" href="/assets/v4.css">
</head>
<body class="dk">
  <main class="nf"><div style="max-width: 560px">${inner}</div></main>
  <script src="/assets/crew.js" defer></script>
</body>
</html>`, { headers: { 'Content-Type': 'text/html; charset=utf-8', 'Cache-Control': 'no-store' } });
}
