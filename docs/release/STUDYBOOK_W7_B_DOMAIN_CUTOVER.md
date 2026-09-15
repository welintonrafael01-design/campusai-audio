# StudyBook AI W7-B Domain Cutover

Status: `W7-B CONTROLLED CUTOVER COMPLETE - PUBLIC LAUNCH STILL BLOCKED`

Date: `2026-09-15`

This document preserves the W7-B0.2 provider-issued requirements and records
the controlled W7-B execution for `studybookai.com`. DNS changes were limited
to the four explicitly authorized records. Public indexing remains disabled;
domain availability is not public-launch approval.

## W7-B Execution Result

The cutover completed without rollback. Authoritative GoDaddy DNS and public
Cloudflare/Google resolvers returned the same final values with TTL 3600:

| Host | Type | Final value |
| --- | --- | --- |
| `@` | A | `216.198.79.1` |
| `www` | CNAME | `0bcd2772ba0ac548.vercel-dns-017.com.` |
| `app` | CNAME | `2573f2cae2890ca0.vercel-dns-017.com.` |
| `api` | CNAME | `studybook-ai-api.onrender.com.` |

Nameservers remain `ns53.domaincontrol.com` and
`ns54.domaincontrol.com`. `_domainconnect` and the existing DMARC quarantine
policy remain present. No MX record existed in the authoritative snapshot, and
no mail, verification or unrelated TXT record was changed. The SOA serial
advanced normally after the authorized DNS updates.

### Provider And TLS Evidence

- Vercel reports `studybookai.com`, `www.studybookai.com` and
  `app.studybookai.com` as valid Production domains.
- Render reports `api.studybookai.com` as the live custom domain for service
  `studybook-ai-api`.
- All four HTTPS hosts have valid provider-managed certificates with hostname
  matches. HTTP redirects to HTTPS for root, `www`, app and API.
- `www.studybookai.com` is configured in Vercel as a permanent `308` redirect
  to `https://studybookai.com`; following it reaches one root `200` with no
  loop.

### API And Render Transition

Render now uses:

```text
APP_WEB_URL=https://app.studybookai.com
BACKEND_CORS_ORIGINS=https://studybook-ai-app.vercel.app,https://app.studybookai.com
```

`GET https://api.studybookai.com/health` returns HTTP 200 for service
`StudyBook AI API`, version `1.0.0`, build
`ca8d49b2bad7268844fc695776d6d068a5df2d4f`. The native Render hostname
returns the same build identity. API docs remain unavailable in production,
unauthenticated billing returns 401, and an unknown route returns 404.

CORS preflight returns 200 with the exact requesting origin for both the
provider-native Flutter host and `https://app.studybookai.com`; an unknown
origin returns 400. Credentials remain enabled without a wildcard origin.

### Supabase Auth Transition

Supabase Auth Site URL is `https://app.studybookai.com`. The custom callbacks
for `/#/auth` and `/#/reset-password` are present, and the equivalent two
provider-native callbacks remain present. All seven previous localhost QA
callbacks were retained, for 11 allowed redirect URLs total. No other Auth
setting changed. A real password-reset email round trip remains a human gate.

### Flutter Production Transition

Vercel Production deployment `3APwHVb4x31ZqzcCzsbEB7kFjQyp` completed in
2m40s from source commit `ca8d49b2bad7268844fc695776d6d068a5df2d4f`.
The served `main.dart.js` contains the canonical API origin and contains no
reference to the old Render native API or local port 8000. Root and hash routes
return 200; an unauthenticated browser reaches `/#/auth` without console
errors. The provider-native app hostname remains available during transition.

The authenticated lifecycle probe against `https://app.studybookai.com`
passed hard reload, tab reopen, back/forward, Dashboard, Library, Learning,
Account, responsive 390 px and Student A to Student B browser-session switch,
with zero unexpected browser errors. Student A/B subscriptions are active
Student plans, their Cloud libraries return 200, and both are denied Educator
access with 403. Teacher is active on the Teacher plan and receives Educator
200. Student B access to a Student A document returns the privacy-safe 404.
Supabase logout returned 204 for all three disposable QA sessions.

### Marketing Production Transition

Vercel Production deployment `Fe9B4VZdA5ZkbNPiE8MU7D1ygmy6` completed in
41s from source commit `ca8d49b2bad7268844fc695776d6d068a5df2d4f`
with:

```text
NEXT_PUBLIC_WEB_URL=https://studybookai.com
NEXT_PUBLIC_APP_URL=https://app.studybookai.com
NEXT_PUBLIC_API_URL=https://api.studybookai.com
ENABLE_PUBLIC_INDEXING=false
```

Home, Features, Students, Teachers, Pricing, FAQ, Contact, Security, Privacy,
Terms and Account Deletion return 200. The official Booky asset loads. Account
CTAs point only to `app.studybookai.com`; route HTML contains no stale native
app URL. The root metadata remains `noindex, nofollow`, and `robots.txt`
continues to disallow all crawling.

### Remaining Gates

- **Launch blocker:** rotate the previously exposed OpenAI production key in
  Render and revoke the old key without disclosing either value.
- **Launch blocker:** approve final legal content and effective product policy.
- **Human action:** select and validate a real contact delivery provider if a
  working public contact channel is required.
- **Human action:** complete one password-reset email flow and broader
  desktop/mobile responsive, keyboard, focus and screen-reader checks on the
  custom domain. Visible UI logout and a private production QA document upload
  now pass in W7-C.
- **P2:** leaked-password protection remains plan-dependent and distributed
  rate limiting remains pending before horizontal scale.

Rollback was not required. Provider-native URLs and callbacks remain in place
for controlled transition safety.

## W7-C Follow-Up

The unchanged W7-B runtime passed the W7-C technical recheck. Visible logout,
private QA upload persistence and direct Student A to Student B ownership
denial now pass. Public launch is still `NO-GO`: key rotation, password reset,
human responsive/accessibility checks, monitored contact and legal approval
remain open. Public indexing remains disabled. See
`docs/release/STUDYBOOK_W7_C_LAUNCH_READINESS.md` for the evidence and explicit
release blocker table.

## W7-B0.2 Safety Boundary (Historical)

- Authoritative DNS remains at GoDaddy.
- No DNS record, nameserver, Supabase Auth setting, CORS variable, public URL,
  runtime build or indexing setting changed in W7-B0.2.
- Do not modify `NS`, `SOA`, `_domainconnect`, `_dmarc`, `MX`, SPF, DKIM or any
  unrelated validation record.
- Public indexing stays disabled until DNS, TLS, legal, contact, Auth and final
  functional gates pass.

## Runtime And Deployment State

| Surface | Project / service | Native URL | Deployed commit |
| --- | --- | --- | --- |
| API | Render `studybook-ai-api` | `https://studybook-ai-api.onrender.com` | `ca8d49b2bad7268844fc695776d6d068a5df2d4f` |
| Marketing | Vercel `studybook-ai-marketing` | `https://studybook-ai-marketing.vercel.app` | `ca8d49b2bad7268844fc695776d6d068a5df2d4f` |
| Flutter | Vercel `studybook-ai-app` | `https://studybook-ai-app.vercel.app` | `ca8d49b2bad7268844fc695776d6d068a5df2d4f` |

Provider-native health, HTTPS, SPA routing, login, subscription, Library Cloud,
Student-to-Teacher denial, privacy-safe document 404 and exact-origin CORS pass.

## Provider Domain Assignments

| Domain | Provider target | Assignment | Provider status before DNS |
| --- | --- | --- | --- |
| `studybookai.com` | Vercel `studybook-ai-marketing` Production | Correct | Invalid Configuration |
| `www.studybookai.com` | Vercel `studybook-ai-marketing` Production | Correct | Invalid Configuration |
| `app.studybookai.com` | Vercel `studybook-ai-app` Production | Correct | Invalid Configuration |
| `api.studybookai.com` | Render `studybook-ai-api` | Correct | Waiting for DNS / certificate verification |

No domain is attached to a temporary deployment or the wrong project. Render's
native `onrender.com` hostname remains enabled for rollback and transition.

## Authoritative DNS Snapshot

The snapshot was queried directly from `ns53.domaincontrol.com` with TTL 3600.

| Host | Type | Current value |
| --- | --- | --- |
| `@` | A | `76.223.105.230` |
| `@` | A | `13.248.243.5` |
| `www` | CNAME | `studybookai.com.` |
| `app` | none | No record |
| `api` | none | No record |
| `@` | NS | `ns53.domaincontrol.com.` |
| `@` | NS | `ns54.domaincontrol.com.` |
| `_domainconnect` | CNAME | `_domainconnect.gd.domaincontrol.com.` |
| `_dmarc` | TXT | Existing quarantine policy; preserve unchanged |

The current root responds with GoDaddy `Server: DPS`, confirming that its two A
records serve the existing Website Builder. `www` currently redirects through
that root to `https://studybookai.com/`.

## Exact DNS Cutover Table

Provider UIs did not prescribe a TTL. The current authoritative TTL is 3600;
retaining it is the documented default unless the human operator approves a
temporary lower TTL before cutover.

| Provider | Purpose | Domain | DNS type | Host | Current value | Required value | Action | TTL | Verification needed | Provider status | Safe to apply |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Vercel | Marketing root | `studybookai.com` | A | `@` | `76.223.105.230` and `13.248.243.5` | `216.198.79.1` | Replace both current A records with this single A record | Not specified; current 3600 | Vercel DNS configuration check; no extra TXT shown | Invalid Configuration | Only after explicit W7-B authorization |
| Vercel | Marketing www | `www.studybookai.com` | CNAME | `www` | `studybookai.com.` | `0bcd2772ba0ac548.vercel-dns-017.com.` | Replace current CNAME | Not specified; current 3600 | Vercel DNS configuration check; no extra TXT shown | Invalid Configuration | Only after explicit W7-B authorization |
| Vercel | Flutter app | `app.studybookai.com` | CNAME | `app` | No record | `2573f2cae2890ca0.vercel-dns-017.com.` | Create CNAME | Not specified; default 3600 | Vercel DNS configuration check; no extra TXT shown | Invalid Configuration | Only after explicit W7-B authorization |
| Render | FastAPI | `api.studybookai.com` | CNAME | `api` | No record | `studybook-ai-api.onrender.com` | Create CNAME | Not specified; default 3600 | Click Render Verify after propagation; no extra record shown | Waiting for DNS | Only after explicit W7-B authorization |

## Rollback Table

| Host | Original type | Original value | New type | New value | Rollback action |
| --- | --- | --- | --- | --- | --- |
| `@` | A | `76.223.105.230` | A | `216.198.79.1` | Remove the Vercel A and restore this GoDaddy A |
| `@` | A | `13.248.243.5` | A | `216.198.79.1` | Restore this second GoDaddy A alongside the first |
| `www` | CNAME | `studybookai.com.` | CNAME | `0bcd2772ba0ac548.vercel-dns-017.com.` | Restore CNAME `www -> studybookai.com.` |
| `app` | none | No record | CNAME | `2573f2cae2890ca0.vercel-dns-017.com.` | Delete only the newly created `app` CNAME |
| `api` | none | No record | CNAME | `studybook-ai-api.onrender.com` | Delete only the newly created `api` CNAME |

Rollback changes only these rows. Provider-native Vercel and Render URLs remain
available throughout propagation. DNS caches can continue serving either state
for up to the authoritative TTL and resolver-specific cache duration.

## Canonical Marketing Behavior

- Canonical host: `https://studybookai.com`.
- After DNS and both certificates are valid, configure Vercel
  `www.studybookai.com` as a permanent redirect to `https://studybookai.com`.
- Do not configure the current Vercel dialog's opposite apex-to-www redirect.
- Keep indexing disabled after domain connection; canonical availability is not
  launch approval.

## Supabase Auth Transition

The Flutter client builds signup and recovery callbacks from `Uri.base.origin`.
Keep the provider-native callbacks while adding final callbacks:

```text
https://studybook-ai-app.vercel.app/#/auth
https://studybook-ai-app.vercel.app/#/reset-password
https://app.studybookai.com/#/auth
https://app.studybookai.com/#/reset-password
```

After the final app domain and TLS pass, set the recommended Supabase Site URL
to `https://app.studybookai.com`. Do not remove native callbacks until signup,
confirmation, reset, logout and fresh login pass on the custom domain. Test one
controlled password-reset round trip and verify there is no open redirect or
token in logs, screenshots or analytics.

## Render URL And CORS Transition

Render `APP_WEB_URL` means the Flutter application origin. Its final value is:

```text
APP_WEB_URL=https://app.studybookai.com
```

During transition, configure this exact CORS allowlist before the Flutter
custom-domain functional test:

```text
BACKEND_CORS_ORIGINS=https://studybook-ai-app.vercel.app,https://app.studybookai.com
```

Marketing does not call FastAPI directly and is not included. Never use `*`
with credentials. Keep the native Flutter origin until custom-domain Auth and
API calls pass.

The Flutter build uses a separate build-time meaning for `APP_WEB_URL`: its
public Marketing/legal origin remains `https://studybookai.com`. After API DNS,
Render TLS and `/health` pass, rebuild Flutter with:

```text
API_BASE_URL=https://api.studybookai.com
APP_WEB_URL=https://studybookai.com
PRIVACY_URL=https://studybookai.com/privacy
ACCOUNT_DELETION_URL=https://studybookai.com/account-deletion
REQUIRE_CANONICAL_PRODUCTION_URLS=true
```

Supabase public URL and anon key remain unchanged and must never be recorded in
this document. The Render native URL remains the rollback API reference.

## Marketing Environment Transition

The native Marketing deployment currently sends login and signup CTAs to
`https://studybook-ai-app.vercel.app`. After `app.studybookai.com` resolves with
valid TLS, set:

```text
NEXT_PUBLIC_WEB_URL=https://studybookai.com
NEXT_PUBLIC_APP_URL=https://app.studybookai.com
NEXT_PUBLIC_API_URL=https://api.studybookai.com
ENABLE_PUBLIC_INDEXING=false
```

Redeploy Marketing and verify all account CTAs before considering indexing.

## TLS Validation Plan

Vercel and Render issue managed certificates only after DNS verification. For
each host verify the certificate hostname, chain, expiry, HTTPS response and
HTTP-to-HTTPS behavior. Verify root/www redirects have no loop and API `/health`
returns the expected deployed build SHA. Do not disable provider-managed TLS.

## Authorized W7-B Execution Order

1. Reconfirm this table against provider dashboards and save a fresh GoDaddy
   snapshot.
2. With separate authorization, replace only the two root A records and the
   `www` CNAME, then create only the `app` and `api` CNAME records above.
3. Wait for Vercel and Render ownership verification; do not alter nameservers.
4. Verify Marketing root/www TLS, then configure `www` to redirect permanently
   to the canonical root.
5. Verify Render API TLS and `/health` through `api.studybookai.com`.
6. Add the final app origin to Render CORS while retaining the native origin;
   set Render `APP_WEB_URL` to the final Flutter origin at the approved point.
7. Rebuild Flutter with the canonical API and public legal URLs, then verify
   direct SPA routes on `app.studybookai.com`.
8. Add final Supabase redirects and set Site URL; test login, logout and one
   password-reset flow.
9. Switch Marketing CTA environment values and verify every account link.
10. Complete upload, responsive, keyboard, focus and basic accessibility checks.
11. Keep indexing disabled until contact and legal approval are complete.

## Remaining Human And P2 Gates

- Visible logout, document upload, desktop/mobile responsive, keyboard, focus
  and basic screen-reader checks remain human actions.
- Password reset remains a human action after final callback configuration.
- A full OpenAI secret appeared in prior operator evidence. Treat that value as
  compromised and confirm it was rotated before public launch; do not expose or
  compare secret values in evidence.
- Contact delivery remains disabled pending a provider decision; do not modify
  mail DNS.
- Privacy, Terms and Account Deletion remain non-indexed legal drafts.
- Supabase leaked-password protection remains a plan-dependent human action.
- Per-instance rate limiting remains P2; distributed enforcement is required
  before horizontal scale or material public abuse exposure.

## Stop Condition

W7-B0.2 stops here. The exact DNS table requires human review and a separate
authorization before any GoDaddy mutation.
