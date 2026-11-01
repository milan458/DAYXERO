# Beta waitlist Worker

`index.js` runs on the existing `dayxero` Worker. Only `/api/*` reaches it; every other path is a static file.

| Route | What it does |
|---|---|
| `POST /api/waitlist` | Adds an email (JSON body from `assets/waitlist.js`) and sends a confirmation link |
| `GET /api/waitlist/confirm?t=…` | Confirms the email, then redirects to `/beta/confirmed/?r=CODE` |
| `GET /api/waitlist/status?r=CODE` | Queue position and confirmed referrals for the confirmed page |
| `GET`/`POST /api/waitlist/unsubscribe?t=…` | Unsubscribe page and one-click unsubscribe |
| `GET /api/waitlist/export` | Confirmed members as CSV (needs `ADMIN_TOKEN`) |

Signups are stored in Cloudflare D1. The table is created on first use, so there are no migrations to run.

## Turning it on

Until step 1 is done, the forms tell visitors that signups open soon and give the contact email.

1. **Storage (required).** From the repo root:
   ```
   npx wrangler d1 create dayxero-waitlist
   ```
   Paste the printed `database_id` into the `d1_databases` block in `wrangler.jsonc` (repo root) and uncomment it.
2. **Confirmation email (needed for double opt-in).** Create a Resend account, verify a sending domain
   (for example `mail.dayxero.in`, with SPF, DKIM and DMARC), then:
   ```
   npx wrangler secret put RESEND_API_KEY
   npx wrangler secret put MAIL_FROM        # e.g. DayXero <beta@mail.dayxero.in>
   ```
   Without these, signups are saved as pending and the cron sends their links once the keys exist.
   Resend's free tier sends 100 emails a day; the cron catches up on anything over that.
3. **Bot protection (recommended once traffic arrives).** Create a Turnstile widget in the Cloudflare
   dashboard, put its site key in `TURNSTILE_SITE_KEY` at the top of `assets/waitlist.js`, then:
   ```
   npx wrangler secret put TURNSTILE_SECRET
   ```
   The honeypot field and the 5-signups-per-IP-per-hour limit work without it.
4. **Export (optional).** `npx wrangler secret put ADMIN_TOKEN`, then
   `curl -H "Authorization: Bearer $TOKEN" https://dayxero.in/api/waitlist/export > waitlist.csv`
   to import confirmed members into Kit or Brevo for the launch email.

Optional variables: `SITE_URL` (origin used in links sent by the cron, default `https://dayxero.in`) and
`IP_SALT` (salt for the hashed IP used for rate limiting).

## Local testing

From the repo root, copy `wrangler.jsonc` to `wrangler.dev.jsonc` (git ignores that name), uncomment
`d1_databases` in the copy with any placeholder id, then:
```
npx wrangler dev -c wrangler.dev.jsonc
```
`wrangler dev` uses a local D1 database, so nothing touches production.

## Deploying

The Worker config is `wrangler.jsonc` at the repo root (`main` and `assets.directory` point into `website/`),
so `npx wrangler deploy` works from the root with no flags. Two things can run it:

- **The `Website` GitHub workflow** (`.github/workflows/website.yml`): on every push to `main` that touches the
  site, it regenerates the guide pages and deploys with the `CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID`
  secrets. This is what ships dayxero.in today.
- **Cloudflare Workers Builds** (the Git integration on the `dayxero` Worker). It needs these settings in the
  Cloudflare dashboard, under the Worker's *Settings → Build*:

  | Setting | Value |
  |---|---|
  | Git repository | `milan458/DAYXERO` |
  | Production branch | `main` |
  | Root directory | `/` (the repo root, where `wrangler.jsonc` is) |
  | Build command | `npm run website:guides` |
  | Deploy command | `npx wrangler deploy` |
  | Non-production branch deploy command | `npx wrangler versions upload` (the default; gives every PR a preview URL) |
  | Build watch paths (include) | `website/**`, `scripts/website/**`, `wrangler.jsonc`, `package.json` |

  With the production branch set to anything other than `main`, Workers Builds only uploads previews for `main`
  and the live site never updates. That is why the workflow exists. Once Workers Builds deploys `main` correctly,
  the workflow can go, so the site isn't deployed twice per push.
