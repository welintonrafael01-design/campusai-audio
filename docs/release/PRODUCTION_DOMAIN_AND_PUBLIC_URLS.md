# Production Domain And Public URLs

Status: `DOMAIN CONFIRMED - DEPLOYMENT AND DNS PENDING`

The registered production domain is `studybookai.com`. This document fixes the
public URL contract but does not claim that DNS, TLS, Vercel, Render, Supabase
redirects, Stripe redirects or the legal pages are already deployed.

## Canonical Public URLs

| Purpose | Required value | Consumer |
| --- | --- | --- |
| Public Web app | `APP_WEB_URL=https://studybookai.com` | Backend CORS, billing and QR links |
| Web alias | `https://www.studybookai.com` | Redirect to canonical apex |
| Public API | `API_BASE_URL=https://api.studybookai.com` | Flutter Web and Android release |
| Privacy policy | `PRIVACY_URL=https://studybookai.com/privacy` | Flutter, public Web and Play Console |
| Account deletion | `ACCOUNT_DELETION_URL=https://studybookai.com/account-deletion` | Public Web and Play Console |
| Verification | `https://studybookai.com/#/verify/<RECORD_ID>` | Certificate, badge and transcript QR codes |

`PRIVACY_POLICY_URL` remains accepted by Flutter and the Android release
scanner as a legacy alias. New configuration must use `PRIVACY_URL`.

## Flutter Release Contract

The checked-in public template is
`mobile/campusai_mobile/config/release.example.json`. The four registered URLs
are now concrete. Supabase public values and Play product IDs remain human
inputs and must not be replaced with guessed values.

Android production must compile with:

```text
API_BASE_URL=https://api.studybookai.com
APP_WEB_URL=https://studybookai.com
PRIVACY_URL=https://studybookai.com/privacy
ACCOUNT_DELETION_URL=https://studybookai.com/account-deletion
```

Release validation rejects HTTP, loopback, URL credentials, `.invalid` hosts,
missing values and server-side secrets.

## Vercel Web Contract

Create the Vercel project with:

```text
Root Directory: mobile/campusai_mobile
Framework Preset: Other
Build Command: bash tool/build_vercel_web.sh
Output Directory: build/web
```

`vercel.json` supplies the build/output contract, direct rewrites for
`/privacy` and `/account-deletion`, and the Flutter SPA fallback. The build
script requires these environment values:

```text
API_BASE_URL=https://api.studybookai.com
APP_WEB_URL=https://studybookai.com
PRIVACY_URL=https://studybookai.com/privacy
ACCOUNT_DELETION_URL=https://studybookai.com/account-deletion
SUPABASE_URL=<AUTHORIZED_PUBLIC_PROJECT_ORIGIN>
SUPABASE_ANON_KEY=<AUTHORIZED_PUBLIC_PUBLISHABLE_OR_ANON_KEY>
```

The Supabase service role, OpenAI, Stripe and Google credentials are forbidden
in Vercel's Flutter build environment.

## Render API Contract

The repository-root `render.yaml` defines a manual FastAPI service:

```text
Root Directory: backend
Build Command: python -m pip install --upgrade pip && python -m pip install -r requirements.txt
Start Command: python -m uvicorn app.main:app --host 0.0.0.0 --port $PORT
Health Check: /health
Auto Deploy: off
```

Production CORS is exact:

```text
APP_ENV=production
APP_WEB_URL=https://studybookai.com
BACKEND_CORS_ORIGINS=https://studybookai.com,https://www.studybookai.com
```

`BACKEND_CORS_ORIGIN_REGEX` must remain unset. API docs remain disabled in
production. Secret values are prompted by Render through `sync: false`; no
secret value is committed.

## Billing And Identity Redirects

The backend derives these Stripe destinations from `APP_WEB_URL` unless an
exact approved override is supplied:

```text
https://studybookai.com/#/plans?checkout=success
https://studybookai.com/#/plans?checkout=cancel
https://studybookai.com/#/settings
```

The Stripe webhook destination is:

```text
https://api.studybookai.com/billing/webhook
```

Supabase production settings must be updated manually after the Vercel domain
is active:

- Site URL: `https://studybookai.com`.
- Password-reset redirect: `https://studybookai.com/#/reset-password`.
- No wildcard redirect domain.

## Remaining Deployment Gates

1. Create Vercel and Render projects without promoting production traffic.
2. Supply authorized environment values through each provider dashboard.
3. Resolve the backend local-state/persistent-storage decision before Render
   receives production traffic.
4. Copy provider-issued DNS targets exactly; do not guess targets.
5. Complete legal fields and remove `noindex` only after approval.
6. Verify TLS, CORS, Supabase redirects, Stripe webhook and two-user isolation.
7. Rebuild and scan the final Android AAB with the registered URLs and real
   Play product IDs.
