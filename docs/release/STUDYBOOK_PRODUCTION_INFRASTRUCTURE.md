# StudyBook AI Production Infrastructure

Status: `W7-A LOCAL GATE PASS - PROVIDER DEPLOYMENT REQUIRES HUMAN AUTHENTICATION`

Date: `2026-09-11`

Base commit: `6133c4593d54e469c015219d6249b59ac6f54d2d`

No DNS, push, tag, deployment, remote Supabase mutation or public indexing was
performed during this local closure.

## Deployment Topology

| Surface | Repository root | Provider | Provider project / URL |
| --- | --- | --- | --- |
| API | `backend` | Render | Pending authenticated project creation |
| Marketing | `web/marketing` | Vercel | Pending authenticated persistent project creation |
| Flutter Web | `mobile/campusai_mobile` | Vercel | Pending separate authenticated project creation |

Future custom domains remain:

- Marketing: `https://studybookai.com` and `https://www.studybookai.com`
- Flutter application: `https://app.studybookai.com`
- FastAPI: `https://api.studybookai.com`

Provider-native URLs and DNS targets must be copied from authenticated provider
dashboards. They must not be inferred from a project name.

## Render Contract

`render.yaml` defines one persistent Render Web Service:

```text
Name: studybook-ai-api
Runtime: Python
Root: backend
Build: python -m pip install --upgrade pip && python -m pip install -r requirements.txt
Start: python -m uvicorn app.main:app --host 0.0.0.0 --port $PORT
Health: /health
Auto deploy: off
```

`APP_WEB_URL` and `BACKEND_CORS_ORIGINS` are intentionally `sync: false`.
Before the first deployment, enter the actual provider origins. During the
pre-DNS phase, `APP_WEB_URL` is the persistent marketing Vercel origin and CORS
contains only the persistent Flutter Vercel origin plus any marketing origin
that actually calls the API. Production rejects HTTP, local and `.invalid`
origins and rejects `BACKEND_CORS_ORIGIN_REGEX`.

### Backend Environment Classification

| Classification | Variables |
| --- | --- |
| Server secret | `FILE_ACCESS_SECRET`, `OPENAI_API_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `ADMIN_API_KEY` |
| Runtime sensitive configuration | `ADMIN_EMAILS` |
| Runtime public/non-secret configuration | `APP_ENV`, `APP_WEB_URL`, `BACKEND_CORS_ORIGINS`, `ENABLE_API_DOCS`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_STORAGE_BUCKET`, `SUPABASE_PRIVATE_ARTIFACTS_BUCKET`, `STRIPE_STUDENT_PRICE_ID`, `STRIPE_TEACHER_PRICE_ID`, `STRIPE_ACCESSIBILITY_PRICE_ID`, `STRIPE_ULTRA_PRICE_ID`, `GOOGLE_PLAY_STUDENT_PRODUCT_ID`, `GOOGLE_PLAY_TEACHER_PRODUCT_ID` |
| Provider metadata | `PORT`, `RENDER_GIT_COMMIT`; optional `APP_BUILD_SHA` override |

Public Supabase URL/anon values are not privileged, but authorization still
depends on Auth and RLS. `SUPABASE_SERVICE_ROLE_KEY` remains server-only.

Production startup fails closed unless both private Storage buckets and all
three Supabase credentials are configured. OpenAPI docs default to disabled in
production. Production uses Supabase/Postgres/pgvector and private Storage as
the source of truth; local Chroma, JSON and audio adapters are development-only.

## Vercel Contracts

### Marketing

```text
Root: web/marketing
Framework: Next.js
Install: pnpm install --frozen-lockfile
Build: pnpm build
Output: Vercel-managed Next.js output
Node: >=20.9.0
```

Build-time public values:

```text
NEXT_PUBLIC_WEB_URL=<actual persistent marketing Vercel origin>
NEXT_PUBLIC_APP_URL=<actual persistent Flutter Vercel origin>
NEXT_PUBLIC_API_URL=<actual Render origin>
ENABLE_PUBLIC_INDEXING=false
```

Server runtime contact values:

```text
CONTACT_DELIVERY_PROVIDER=disabled
CONTACT_DELIVERY_WEBHOOK_URL=<server-only after provider approval>
CONTACT_DELIVERY_WEBHOOK_SECRET=<server-only after provider approval>
```

The contact endpoint fails honestly while delivery is disabled. A delivery
provider and distributed abuse control remain human architecture decisions.

### Flutter Web

```text
Root: mobile/campusai_mobile
Framework: Other
Build: bash tool/build_vercel_web.sh
Output: build/web
```

Build-time public values:

```text
API_BASE_URL=<actual Render origin>
APP_WEB_URL=<actual persistent marketing Vercel origin>
PRIVACY_URL=<APP_WEB_URL>/privacy
ACCOUNT_DELETION_URL=<APP_WEB_URL>/account-deletion
SUPABASE_URL=<approved public project URL>
SUPABASE_ANON_KEY=<approved public anon key>
```

The build contract rejects local, HTTP, credential-bearing, query-bearing and
`.invalid` URLs. `REQUIRE_CANONICAL_PRODUCTION_URLS=true` is reserved for the
later custom-domain build. Never place OpenAI, service-role, Stripe secret,
admin or Google service-account credentials in Flutter.

## Local W7-A Evidence

- Backend full suite: `180 passed, 10 skipped`.
- Backend security-focused suite: `101 passed`.
- Python compile: pass.
- Production-like API smoke: `/health` 200 with expected build SHA; `/docs`
  404; unauthenticated billing 401; unknown route 404; allowed CORS preflight
  200; untrusted origin rejected 400; security headers present.
- Flutter analyze: no issues.
- Flutter tests: `144 passed`.
- Flutter canonical production Web build: pass. The provider-native build must
  be repeated with the actual Render and persistent marketing Vercel origins.
- Marketing lint: pass.
- Marketing tests: `41 passed` across seven files.
- Marketing production build: pass, 17 generated routes.
- Marketing local production smoke: all required public routes returned 200;
  CSP/security headers present; root `X-Robots-Tag` is `noindex`; `robots.txt`
  denies all crawling; legal routes retain noindex metadata.
- Tracked first-party secret scan: pass across 939 files.
- `git diff --check`: pass before documentation closure.

## Supabase Security State

W6 production evidence remains authoritative: six migrations aligned, 17
StudyBook tables, 609 active rows, 359 private quarantined rows, 968 preserved
rows, 37 private Storage objects, RLS on 17/17 tables, pgvector/RAG pass and
atomic quota pass.

Security Advisor findings for `certificates`, `document_chunks` and
`quota_reservations` are accepted informational warnings. Those tables are
intentionally service-role-only: `anon` and `authenticated` have no direct
table privileges or policies. Permissive client policies must not be added to
silence the advisor.

Leaked-password protection remains a pre-launch human action. In the Supabase
project dashboard, open Auth settings, review Password Security, enable leaked
password protection and save; then test new signup and password-change behavior
without changing unrelated Auth settings. Supabase documents that this uses
HaveIBeenPwned and is available on Pro plans and above:
`https://supabase.com/docs/guides/auth/password-security`.

## W7-A Code Closure

The foreign/nonexistent chat P2 is fixed locally. Owner-filtered lookup no
longer relies on a zero-row `maybe_single` response, and absent or foreign
resources return the same privacy-safe generic 404. Regression coverage checks
foreign denial, missing-resource denial and owner access.

## Human Gates

1. Sign in to Render and Vercel in an operator-controlled browser.
2. Create the three persistent projects without attaching custom domains.
3. Enter secret values directly in provider dashboards; never relay them in
   chat or commit them.
4. Record exact provider-native URLs, then configure the cross-project public
   URLs and exact CORS origins before deploying.
5. Validate HTTPS, health/build SHA, Supabase access, auth, 404, CORS and
   security headers against Render.
6. Validate marketing routes, Booky asset, links, responsive behavior, console,
   CSP and indexing protection against Vercel.
7. Validate Flutter login/logout/session, library, upload, authorization,
   responsive behavior and accessibility against its separate Vercel URL.
8. Select a contact delivery provider and distributed spam control, or retain
   the explicit unavailable state.
9. Approve legal entity/contact/address/jurisdiction/effective-date/retention/
   minors/subscription/refund decisions. Legal pages remain drafts.
10. Collect provider-issued DNS targets for W7-B. Do not modify GoDaddy `NS`,
    `SOA`, `_domainconnect` or `_dmarc` records.

W7-B remains blocked until all three provider deployments and their exact
native URLs pass validation. Public indexing must remain disabled throughout
this phase.
