# StudyBook AI Production Infrastructure

Status: `W7-A2 PROVIDER-NATIVE DEPLOYMENT PASS - DNS UNCHANGED`

Date: `2026-09-11`

QA branch deployed commit: `848865c8d72ad0d7dd0aee6038e6f17b94f3260e`

The authorized QA branch was pushed and deployed to persistent provider-native
Render and Vercel projects. No DNS, tag, custom-domain assignment, remote
Supabase schema mutation or public indexing change was performed.

## Deployment Topology

| Surface | Repository root | Provider | Provider project / URL |
| --- | --- | --- | --- |
| API | `backend` | Render | `studybook-ai-api` / `https://studybook-ai-api.onrender.com` |
| Marketing | `web/marketing` | Vercel | `studybook-ai-marketing` / `https://studybook-ai-marketing.vercel.app` |
| Flutter Web | `mobile/campusai_mobile` | Vercel | `studybook-ai-app` / `https://studybook-ai-app.vercel.app` |

Future custom domains remain:

- Marketing: `https://studybookai.com` and `https://www.studybookai.com`
- Flutter application: `https://app.studybookai.com`
- FastAPI: `https://api.studybookai.com`

Provider-native URLs above are verified. Exact custom-domain DNS records remain
pending W7-B provider assignment and must be copied from the authenticated
provider dashboards; they must not be inferred from project names.

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

## W7-A2 Provider Evidence

### Git

- Remote QA branch: `origin/qa/studybook-ai-rc1` at
  `848865c8d72ad0d7dd0aee6038e6f17b94f3260e`.
- `origin/development` remains
  `838084d43647d739a9e7de9dc034e56687a76278`.
- `origin/main` remains
  `8f3e5dc2bdf505090451bf0f9a89b8d9879e2a19`.
- No force push or tag was used.

### Render API

- Native HTTPS URL: `https://studybook-ai-api.onrender.com`.
- `/health`: HTTP 200; service `StudyBook AI API`; build SHA matches the QA
  commit.
- `/docs` and `/openapi.json`: HTTP 404 in production.
- Unauthenticated billing: HTTP 401.
- Authenticated QA subscriptions: Student A/B resolve to `student_pro` and
  Teacher resolves to `teacher_pro` with active status.
- Student access to `/educator/snapshot`: HTTP 403; Teacher access: HTTP 200.
- Cloud library reads: HTTP 200 for Student A, Student B and Teacher.
- Missing chat lookup: privacy-safe HTTP 404.
- CORS allows exactly `https://studybook-ai-app.vercel.app`; an unknown origin
  is rejected and no wildcard credential origin is configured.
- Security headers are present and no secret value was emitted in evidence.

### Vercel Marketing

- Native HTTPS URL: `https://studybook-ai-marketing.vercel.app`.
- Required public routes return HTTP 200.
- Official Booky asset returns HTTP 200.
- CSP and security headers are present.
- Public indexing remains disabled through `robots.txt`, route metadata and
  `X-Robots-Tag`.
- Contact delivery remains explicitly disabled pending a human provider choice.

### Vercel Flutter

- Native HTTPS URL: `https://studybook-ai-app.vercel.app`.
- Vercel project root: `mobile/campusai_mobile`.
- Build command: `bash tool/build_vercel_web.sh`; output: `build/web`.
- Production build completed from QA commit in 2m39s after validating public
  HTTPS URLs and Supabase configuration.
- Root plus direct `/login`, `/dashboard`, `/privacy` and
  `/account-deletion` requests return HTTP 200; hash-route refresh preserves
  the authenticated route.
- Real Student A login passed. Plan sync showed Student Pro/active, Home,
  Library, Learning and Account loaded, and the session survived a direct
  Library refresh.
- The same QA identities passed API logout; final interactive logout remains a
  small human UI confirmation.

### Supabase Auth Redirects

Password login does not require a redirect and passed. Before signup and
password-reset email flows are tested on the native Vercel origin, add these
exact allowed redirect URLs without removing existing entries:

```text
https://studybook-ai-app.vercel.app/#/auth
https://studybook-ai-app.vercel.app/#/reset-password
```

The final custom-domain callbacks will be added separately during W7-B.

### DNS Target Collection

Custom domains were intentionally not assigned in W7-A2, so provider-specific
verification records were not generated and no target is guessed here.

| Future host | Provider | Exact record |
| --- | --- | --- |
| `studybookai.com` | Vercel marketing | Pending provider assignment in W7-B |
| `www.studybookai.com` | Vercel marketing | Pending provider assignment in W7-B |
| `app.studybookai.com` | Vercel Flutter | Pending provider assignment in W7-B |
| `api.studybookai.com` | Render API | Pending provider assignment in W7-B |

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

1. Add the two provider-native Supabase Auth callback URLs listed above, then
   manually confirm signup email and password-reset email round trips.
2. Manually confirm the visible Flutter logout control and a fresh login after
   logout.
3. Validate upload, responsive behavior and accessibility against the Vercel
   Flutter URL without unnecessary paid AI calls.
4. During W7-B, assign future custom domains in provider dashboards and copy
   the exact provider-generated DNS and verification records before changing
   DNS.
5. Select a contact delivery provider and distributed spam control, or retain
   the explicit unavailable state.
6. Approve legal entity/contact/address/jurisdiction/effective-date/retention/
   minors/subscription/refund decisions. Legal pages remain drafts.
7. Do not modify GoDaddy `NS`, `SOA`, `_domainconnect` or `_dmarc` records.

All three provider-native deployments and URLs now pass their technical smoke
tests. W7-B may begin only as a separate, explicitly authorized DNS/custom-domain
phase. Public indexing must remain disabled until legal and launch approval.
