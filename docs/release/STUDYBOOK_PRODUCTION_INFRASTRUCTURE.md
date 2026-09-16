# StudyBook AI Production Infrastructure

Status: `W7-C4.1 FRONTEND DEPLOYED - PUBLIC LAUNCH NO-GO`

Date: `2026-09-16`

QA branch deployed frontend commit: `9a6515a2333cd1eadf65c47dce9d974f9d20964b`

The authorized QA branch is deployed to persistent Render and Vercel projects.
The controlled production-domain cutover is complete for Marketing, Flutter
and API. Public indexing remains disabled and launch is still blocked by key
contact-channel approval and legal decisions.

The W7-C2 Auth fixes and W7-C4 UX/accessibility corrections are deployed on the
custom Flutter and Marketing domains. The backend remains on its unchanged
validated build because W7-C4.1 contains no backend runtime change.

## Deployment Topology

| Surface | Repository root | Provider | Provider project / URL |
| --- | --- | --- | --- |
| API | `backend` | Render | `studybook-ai-api` / `https://studybook-ai-api.onrender.com` |
| Marketing | `web/marketing` | Vercel | `studybook-ai-marketing` / `https://studybook-ai-marketing.vercel.app` |
| Flutter Web | `mobile/campusai_mobile` | Vercel | `studybook-ai-app` / `https://studybook-ai-app.vercel.app` |

Active custom domains are:

- Marketing: `https://studybookai.com` and `https://www.studybookai.com`
- Flutter application: `https://app.studybookai.com`
- FastAPI: `https://api.studybookai.com`

Provider-native URLs remain verified as transition/rollback surfaces. The
custom-domain DNS records use the exact targets collected from the authenticated
provider dashboards and are recorded in
`docs/release/STUDYBOOK_W7_B_DOMAIN_CUTOVER.md`.

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
Before the first deployment, enter the actual provider origins. In Render,
`APP_WEB_URL` is the Flutter application origin because backend billing returns
and public verification links use hash routes inside that application. During
the transition it remains the persistent Flutter Vercel origin. CORS contains
the persistent Flutter origin and later both Flutter origins; Marketing is not
included because it does not call FastAPI directly. Production rejects HTTP,
local and `.invalid` origins and rejects `BACKEND_CORS_ORIGIN_REGEX`.

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
- The initial missing-chat HTTP 500 found during W7-B0 was corrected and
  verified live in W7-B0.1 below.
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
- Real Student A login passed. Home, Library, Learning and Account loaded, and
  the session survived a direct Library refresh. A harmless QA PDF uploaded,
  persisted in private Cloud state after reload and returned a privacy-safe 404
  to Student B. The visible logout action returned to Auth and protected Library
  navigation redirected back to Auth.
- Account initially presented Free despite an active Student backend
  subscription; manual plan sync plus a route rebuild corrected Student Pro.
  This remains a P2 state-refresh issue, not an observed authorization bypass.

### Supabase Auth Redirects

Supabase Auth now uses the custom Flutter origin as Site URL:

```text
https://app.studybookai.com
```

The allowed redirect list contains the custom and provider-native callbacks:

```text
https://app.studybookai.com/#/auth
https://app.studybookai.com/#/reset-password
https://studybook-ai-app.vercel.app/#/auth
https://studybook-ai-app.vercel.app/#/reset-password
```

All seven previous localhost QA callbacks were retained. Password login and
authenticated custom-domain lifecycle probes pass. The Web PKCE ordering defect
found by a real password-reset callback was corrected by commit `27f69d2` and
is deployed. A fresh same-browser recovery subsequently passed callback, code
exchange, password update, forced logout, old-password rejection, new-password
login and session restore without token or open-redirect leakage.

### W7-B Custom Domain State

The exact provider-issued records were applied at authoritative GoDaddy DNS
with TTL 3600. Provider verification and managed TLS pass:

| Host | Provider | Exact record |
| --- | --- | --- |
| `studybookai.com` | Vercel marketing | `A 216.198.79.1` |
| `www.studybookai.com` | Vercel marketing | `CNAME 0bcd2772ba0ac548.vercel-dns-017.com.` |
| `app.studybookai.com` | Vercel Flutter | `CNAME 2573f2cae2890ca0.vercel-dns-017.com.` |
| `api.studybookai.com` | Render API | `CNAME studybook-ai-api.onrender.com.` |

The `www` host returns a permanent 308 redirect to the canonical root. Render
uses the custom Flutter origin for `APP_WEB_URL`, CORS retains both custom and
provider-native Flutter origins, and the Flutter production artifact uses
`https://api.studybookai.com`. Marketing CTAs use the custom app domain while
public indexing remains disabled. Full evidence and rollback instructions are
in `docs/release/STUDYBOOK_W7_B_DOMAIN_CUTOVER.md`.

## W7-B0.1 Document Chat 404 Hotfix

The provider-native W7-B0 smoke found that an authenticated request for an
unavailable document reached the chat route's generic exception handler and
returned HTTP 500. `get_document_info` used a broad `ValueError` for a missing
document, while the route translated only ownership `PermissionError` values.

QA commit `ca8d49b2bad7268844fc695776d6d068a5df2d4f` introduces the typed
`DocumentNotFoundError`. Only this missing-resource exception and ownership
denial map to the same generic HTTP 404 response. Unrelated `ValueError` and
other unexpected failures retain the redacted HTTP 500 contract.

Local validation:

- Focused document/security tests: `21 passed`.
- Full backend suite: `184 passed, 10 skipped`.
- Security and isolation selection: `162 passed`.
- Flutter API error-redaction tests: `4 passed`.
- Flutter analyze: no issues.
- Python compile, tracked secret scan and `git diff --check`: pass.

Render redeployed the exact QA commit above. Authenticated live smoke verified:

- Owner-scoped document lookup reaches the normal downstream validation path.
- A valid unavailable document returns HTTP 404.
- A document owned by another QA user returns the same HTTP 404 body.
- The response is `Documento no encontrado.` and includes no owner, document
  identifier or private metadata.
- Health, build SHA, subscription, cloud library, Student-to-Teacher denial,
  Supabase login/logout and exact-origin CORS remain passing.
- Marketing and Flutter provider-native HTTPS routes remain HTTP 200.

No DNS, provider custom-domain, Auth callback or indexing setting changed in
this hotfix. W7-B0 may resume from provider custom-domain preparation.

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

1. Approve and operationally validate a monitored support/privacy channel.
2. Approve legal entity/contact/address/jurisdiction/effective-date/retention/
   minors/subscription/refund decisions. Legal pages remain drafts.
3. Record explicit acceptance of the plan-dependent leaked-password protection
   limitation and controlled single-instance rate limiting, or remediate them
   before launch. Replace per-instance enforcement before horizontal scale.

Completed technical/human gates include OpenAI key rotation, password-reset
E2E, visible logout, document upload, responsive visual sampling, keyboard/focus
spot checks and retained practical TalkBack evidence.

All custom and provider-native deployment surfaces pass their current technical
smoke tests. W7-B is complete without rollback, but public launch remains
prohibited until the launch blockers and human gates above are closed. Public
indexing stays disabled until legal and explicit launch approval.

## W7-C Public Launch Readiness

W7-C revalidated the unchanged runtime on all custom domains. TLS, canonical
redirect, health/build identity, exact-origin CORS, Auth roles, Student-to-
Teacher denial, privacy-safe document access, anonymous database/Storage
denial, public routes, internal links and current automated suites pass.

The strict launch decision remains `NO-GO`. Visible UI logout, production
document upload, OpenAI key rotation, password-reset E2E and practical
responsive/accessibility review are closed. A monitored contact channel and
legal approval remain open. Supabase
leaked-password protection is unavailable on the current Free plan and is
documented as a P2 requiring upgrade or explicit acceptance.
Per-instance rate limiting is accepted only for controlled single-instance use
and must become shared before horizontal scale.

Detailed evidence and the blocker register are in
`docs/release/STUDYBOOK_W7_C_LAUNCH_READINESS.md`. No DNS, Supabase schema,
runtime deployment, provider secret or indexing setting changed during W7-C.

## W7-C2.1 Flutter QA Deployment

The QA branch was pushed normally at
`39a43aadeecd37fb6d6797bd0bce6b609905098d`. Vercel production deployment
`dpl_7DZzmwNHT6oVMoMnPSge97JwfpDh` is READY and reports the same source commit.
No DNS, backend, marketing, Supabase schema, provider secret or indexing change
was made.

Production verification passed for HTTPS and direct SPA routing, Student A
login, session restore, private Cloud Library, Student-to-Teacher route denial,
and first-render Account subscription state. Account displayed Student Pro as
active and synchronized before any manual sync; reload preserved it. A later
manual sync independently confirmed the same Supabase plan.

The deployed reset callback fix is present, but the fresh E2E could not advance
past email issuance because Supabase enforced its password-reset email cooldown.
No old recovery link was reused. The no-code reset route keeps the password form
disabled and displays human invalid/expired-link guidance. PKCE exchange,
password update, automatic logout and old/new password validation remain pending
one fresh same-browser link after the cooldown expires.

Local regression validation remains clean: Flutter analyze reports no issues,
all 149 Flutter tests pass, and `git diff --check` passes. Public indexing and
public launch remain disabled.

## W7-C4 UX, Accessibility, Contact And Legal

The custom-domain technical baseline remains healthy. Marketing, Flutter and
API return HTTP 200; TLS and custom-origin CORS pass; public indexing remains
disabled at the header, robots and route-metadata layers.

Production visual QA covered all required Marketing routes and authenticated
Student/Auth views at 390, 768, 1024 and 1440 px. W7-C4 prepared local fixes for
mobile-menu Escape behavior, localized Auth semantics, AA action-color
contrast, and the factual `Cuenta` account-deletion navigation wording. The
Marketing suite reports 42 tests, lint and build passing. Flutter reports 151
tests, no analyze issues and a successful Web build.

The monitored contact channel, final legal text and an authorized production
Teacher multi-width visual sample remain human gates. No support/privacy email
was invented. The disabled contact provider continues to fail explicitly
rather than discard messages. Full evidence and the human legal decision
register are in
`docs/release/STUDYBOOK_W7_C4_UX_ACCESSIBILITY_LEGAL.md`.

No DNS, database, provider configuration, indexing, deployment, release tag or
remote branch changed during W7-C4.

## W7-C4.1 Frontend Deployment Evidence

The authorized normal QA push advanced the remote branch to
`9a6515a2333cd1eadf65c47dce9d974f9d20964b`. No force push, tag or other branch
push was used.

| Surface | Deployment | Source | Result |
| --- | --- | --- | --- |
| Flutter Web | `dpl_yjRtT1oMLssvp66NVbDEdxLM866U` | `9a6515a2333cd1eadf65c47dce9d974f9d20964b` | READY |
| Marketing | `dpl_7N5DXfTSn3c1TbDjUeYeguZYUjLi` | `9a6515a2333cd1eadf65c47dce9d974f9d20964b` | READY |
| API | unchanged | `39a43aadeecd37fb6d6797bd0bce6b609905098d` | HEALTHY |

Production checks passed for the three custom HTTPS origins, the `www` 308,
exact-origin CORS, rejected unknown-origin preflight, canonical API references
and absence of localhost/service-role markers in the Flutter artifact. Public
indexing remains disabled.

Live accessibility checks passed for localized Auth semantics, deployed AA
action colors, Marketing Escape/focus restoration and representative Teacher
keyboard/dialog semantics. Authorized Teacher visual QA passed at 390, 768,
1024 and 1440 px across the core Teacher areas. Backend entitlement authority
continued to allow Teacher and deny Student. A transient first-render Teacher
plan propagation observation remains P2 and did not change authorization.

Contact delivery remains honestly disabled pending an approved monitored
channel. Legal pages remain drafts pending the decisions recorded in
`docs/release/STUDYBOOK_W7_C4_UX_ACCESSIBILITY_LEGAL.md`. These human gates keep
the launch decision at `NO-GO`; there is no additional runtime push required.

## W7-C5 Contact And Legal Content State

The Product Owner approved `studybookaiapp@gmail.com` as the initial monitored
support, privacy, deletion, refund, legal and IP channel. Automated contact
delivery remains disabled and fail-closed; the public Contact page directs
users to the monitored mailbox instead of presenting the form as operational.

The final legal drafts now include the approved operator, age/minors policy,
retention/deletion targets, billing/cancellation/refund terms, AI and user
content language, provider disclosures and accepted P2 risks. No production
infrastructure or environment value changed.

The approved professional contact domicile is integrated and does not change
the legal operator. The final jurisdiction clause uses competent Dominican
courts under applicable competence rules and preserves non-waivable consumer
rights.

## W7-C6 Final Legal Content Deployment Authorization

The Product Owner authorized Marketing-only legal-content deployment on
16 September 2026. Privacy, Terms and Account Deletion use the effective date
`16 de septiembre de 2026`. Marketing is the only surface authorized for
deployment in this gate; API, Flutter, DNS, Supabase and provider configuration
remain unchanged.

Pro Consumidor review/registration is `DEFERRED BY PRODUCT OWNER`, classified
as `POST-LAUNCH / COMPLIANCE FOLLOW-UP`. It is not filed, registered, resolved
or determined inapplicable, and no registration number is claimed. It does not
block W7-C6 technical/legal-content deployment and remains in internal risk
tracking.

Public indexing remains disabled. W7-C6 does not authorize a release tag,
indexing activation or W7-D launch actions.

The controlled Marketing deployment completed successfully:

| Field | Evidence |
| --- | --- |
| Source commit | `b5f094544ee1170ec5ce51b603642cd886f6bf7f` |
| Vercel deployment | `dpl_DW3y83VhZUJwVVBpTGYvrfokZZyn` |
| Environment/status | Production / READY |
| Canonical domain | `https://studybookai.com` |
| Public legal routes | Privacy, Terms, Contact, Security, Account Deletion and Pricing returned HTTP 200 |
| Indexing controls | Global `X-Robots-Tag: noindex, nofollow, noarchive`; `robots.txt` disallows `/`; legal page metadata remains noindex |
| Supporting services | Flutter Web and API returned HTTP 200 with valid TLS; API health reported `status: ok` |

No Flutter, API, DNS, Supabase, OpenAI/provider or indexing configuration was
changed by this deployment. `www.studybookai.com` continues to redirect to the
canonical domain with HTTP 308.
