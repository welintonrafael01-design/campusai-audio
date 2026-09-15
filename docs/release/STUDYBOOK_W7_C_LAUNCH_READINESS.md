# StudyBook AI W7-C Launch Readiness

Status: `NO-GO - HUMAN LAUNCH BLOCKERS REMAIN`

Date: `2026-09-15`

Deployed runtime commit: `ca8d49b2bad7268844fc695776d6d068a5df2d4f`

W7-C2 local runtime commits (not pushed or deployed):

- `be47aa5c8afeb250296ad67d8cd6486e393f147c` - deterministic subscription cache synchronization.
- `27f69d2` - explicit Web PKCE recovery exchange and guarded password update.

Local evidence commit before W7-C: `f7df56519afe479822d62702ed6bf3d561340314`

W7-C validates the public production topology without changing DNS, Supabase
schema/data, provider secrets, public indexing or deployed runtime code. The
technical baseline is healthy, but the strict public-launch gate remains
`NO-GO` until every required human and legal item below is closed.

## Production Baseline

| Check | Result | Evidence |
| --- | --- | --- |
| Marketing | PASS | `https://studybookai.com` and all 11 required public routes return HTTP 200 |
| Canonical redirect | PASS | `https://www.studybookai.com` returns 308 to the root without a loop |
| Flutter Web | PASS | `https://app.studybookai.com` returns 200 and unauthenticated users reach `/#/auth` |
| API | PASS | `/health` returns 200 and build SHA `ca8d49b...` |
| TLS | PASS | Current certificates validate for root, `www`, `app` and `api` |
| CORS | PASS | Custom app origin receives 200; an unknown origin receives 400 |
| Authenticated upload | PASS | Student A uploaded one harmless QA PDF through the visible UI; Library and Cloud state survived reload |
| Visible logout | PASS | The Account control returned to `/#/auth`; direct access to `/#/library` redirected back to Auth |
| Indexing | DISABLED | `X-Robots-Tag` is `noindex`; `robots.txt` disallows all crawling |
| Runtime source | CURRENT | API and both Vercel deployments use runtime commit `ca8d49b...`; later local commits are documentation only |

The served Flutter artifact contains the canonical API origin 66 times, no old
Render API origin, no local port 8000 origin and no service-role marker.
Provider-native URLs remain operational fallbacks and are not advertised.

## Security Final Smoke

Production checks performed with disposable QA identities and redacted output:

- Student A and Student B resolve to active Student subscriptions.
- QA Teacher resolves to an active Teacher subscription.
- Student A and Student B receive 403 from `/educator/snapshot`.
- QA Teacher receives 200 from `/educator/snapshot`.
- Attempting to spoof Teacher role or plan through request headers remains 403.
- Missing documents and Student B access to a Student A document return the
  same privacy-safe 404.
- The W7-C upload fixture returns 200 for Student A and privacy-safe 404 for
  Student B when its exact resource ID is requested directly.
- Student B has no owned document fixture, so the inverse live document probe
  was not fabricated. Existing remote RLS evidence covers bidirectional owner
  isolation; a fresh inverse live fixture remains optional supporting evidence.
- Anonymous API access to subscription, library and Educator endpoints returns
  401.
- Anonymous PostgREST access to private product data is denied.
- Anonymous Storage listing exposes zero buckets and zero objects from both
  private bucket names.
- The tracked first-party secret scan checked 942 files and matched none of the
  eight private local values or high-confidence secret patterns. The Supabase
  anon key embedded in the client remains public configuration, not a
  service-role credential.
- Public routes contain no active mixed-content references and no forbidden
  fabricated social-proof claims.

No P0 or P1 security defect was found in W7-C.

## Automated Quality Evidence

| Suite | Result |
| --- | --- |
| Python compile | PASS |
| Backend full suite | `184 passed, 10 skipped` |
| Security-focused backend selection | `89 passed, 1 skipped, 104 deselected` |
| Flutter analyze | `No issues found` |
| Flutter deployed-baseline tests | `144 passed` |
| Flutter W7-C2 local tests | `149 passed` |
| Flutter W7-C2 local Web build | PASS |
| W7-C2 private secret scan | PASS across 947 tracked files; seven private local values checked |
| Marketing lint | PASS |
| Marketing tests | `41 passed` |
| Marketing route/link smoke | 11 routes and 12 internal links pass |
| Marketing responsive support | No horizontal overflow or broken images at 390, 768, 1024 and 1440 px on Home, Students, Teachers, Pricing and Contact |
| Flutter unauthenticated shell support | No document-level horizontal overflow at 390, 768, 1024 and 1440 px |
| `git diff --check` before documentation | PASS |

Automated responsive and accessibility checks support the release decision but
do not replace the required human keyboard, screen-reader, text-scale and visual
review on the custom domains.

## Release Blocker Register

| Issue | Severity | Status | Launch blocker | Evidence | Required action |
| --- | --- | --- | --- | --- | --- |
| OpenAI production key rotation | P1 | HUMAN ACTION | YES | Rotation has not been attested in W7-C | Human creates a new production key, enters it directly in Render, redeploys, performs one minimal AI request, then revokes the old key |
| Visible Flutter logout | P1 gate | CLOSED | NO | The visible Account action returned to `/#/auth`; a subsequent `/#/library` navigation was redirected to Auth | Preserve this flow in future browser regression coverage |
| Production document upload | P1 gate | CLOSED | NO | A harmless one-page QA PDF uploaded successfully, produced a truthful summary, persisted in Library/Cloud after reload and remained inaccessible to Student B | The private fixture is intentionally retained under Student A as QA evidence; remove it later only through an explicitly authorized delete action |
| Responsive human QA | P1 gate | PARTIAL / HUMAN ACTION | YES | Marketing routes and representative authenticated Flutter views were inspected at mobile and desktop widths without document overflow; the complete tablet visual pass is not evidenced | Finish the human tablet and mobile-keyboard matrix |
| Accessibility human QA | P1 gate | PARTIAL / HUMAN ACTION | YES | Named controls and representative Enter activation passed; full keyboard order, modal focus and screen-reader evidence are incomplete | Complete human keyboard, focus, labels, contrast and screen-reader review |
| Password reset E2E | P1 gate | FIX READY / RETEST REQUIRED | YES | Production reached the correct route with a PKCE callback, but the deployed app did not establish the recovery session before `updateUser`; no password or token was retained | Authorize push/redeploy of local commit `27f69d2`, request one fresh QA reset and verify old/new password behavior |
| Contact channel | P1 gate | HUMAN ACTION | YES | Contact provider remains `disabled`; the form fails honestly | Approve a monitored provider or monitored support/privacy contact and validate delivery |
| Legal finalization | P1 | DRAFT | YES | Privacy and account-deletion content still contains unresolved placeholders | Legal/product owner approves entity, contacts, address, jurisdiction, date, retention, age, subscription, cancellation and refund terms |
| Leaked-password protection | P2 | HUMAN ACTION / PLAN LIMITED | NO with explicit acceptance | Project dashboard reports Free; Supabase limits this feature to Pro and above | Upgrade deliberately and enable it, or record explicit pre-launch P2 risk acceptance |
| Distributed rate limiting | P2 | ACCEPTED FOR CONTROLLED SINGLE INSTANCE | NO with explicit acceptance | Backend uses per-instance 120 requests/60 seconds per client; disabled contact route uses per-instance 5 attempts/10 minutes | Add shared/distributed enforcement before horizontal scale or meaningful abuse exposure |
| Initial plan presentation refresh | P2 | FIX READY / RETEST REQUIRED | NO | Local commit `be47aa5c8afeb250296ad67d8cd6486e393f147c` serializes cache writes and rebuilds Account after sync; 149 Flutter tests pass with the regression | Authorize push/redeploy and repeat fresh-login Account verification |

## Human Gate Details

### OpenAI Rotation

No key value was inspected, printed, copied or changed. Rotation remains a
human action. The old key must not be revoked until the new Render secret is
deployed and one minimal production AI request succeeds.

### Visible Logout And Upload

After explicit human authorization, Student A signed in through the custom Auth
screen and uploaded `studybook-w7c-upload-validation.pdf`, a one-page synthetic
QA document without personal data or secrets. Processing completed, the active
document and generated summary matched the fixture, and Library showed four
documents with the QA resource marked Cloud. Reloading `/#/library` preserved
the same counts and resource.

An authenticated API probe found exactly one matching QA document. Its owner
received 200 from `/documents/info/{id}` and Student B received the same
privacy-safe 404 used for absent documents. The fixture remains private and is
retained intentionally as evidence; no destructive delete was authorized.

The visible `Cerrar sesion` control returned the browser to `/#/auth`. A direct
navigation to `/#/library` after logout was redirected to Auth, closing the
interactive logout gate.

The first Account render after login presented Free even though the backend
subscription was already active Student. `Sincronizar plan` followed by a route
rebuild corrected the presentation to Student Pro and updated usage limits. No
authorization bypass was observed. Local commit `be47aa5c...` removes the
write-order race and rebuilds Account after manual synchronization; production
retest remains pending because this commit has not been pushed or deployed.

### Password Reset

The reset callback is configured for `https://app.studybookai.com/#/reset-password`.
The real production email reached that route with the expected PKCE callback,
but the deployed Flutter app rendered the password form without first proving
that code exchange had established a recovery session. `updateUser` therefore
failed. No password or reset code was copied into the repository, logs or this
evidence.

Local commit `27f69d2` disables duplicate automatic Web callback handling,
exchanges the initial code before the router starts, removes auth callback
parameters from browser history, exposes the form only for a valid recovery
session, signs out after a successful update and gives an honest expired or
wrong-browser state. Four callback regression tests pass, the full Flutter
suite reports 149 passes, analyze reports no issues and the Web build passes.
Production remains `FAIL / RETEST REQUIRED` until this commit is explicitly
pushed, redeployed and verified with a fresh one-time link. Password entry and
final submission remain human actions.

### Contact

The current contact UI states that it will not transmit until a reviewed secure
endpoint is enabled. This is honest but not a launch-ready monitored channel.
No mail DNS records were added or changed.

### Legal

Legal status remains `DRAFT`. Required approvals include:

- legal entity/person and address where required;
- support and privacy contacts;
- jurisdiction and effective date;
- retention schedule and exceptions;
- minimum age, minors and educational consent treatment;
- subscription, cancellation and refund terms;
- account-deletion alternative, verification and response timing.

The public legal routes may remain available for QA while indexing is disabled,
but their draft content is not approved for public launch.

### Legal Decision Register

| Field | Current status | Required human decision | Document affected |
| --- | --- | --- | --- |
| Legal operator/entity/person | Unresolved | Approve the contracting and data-controlling legal name | Privacy, Terms, Account deletion |
| Business/contact address | Unresolved | Approve whether an address is legally required and the publishable value | Privacy, Terms |
| Support contact | Unresolved | Approve a monitored public support channel | Contact, Terms, Account deletion |
| Privacy contact | Unresolved | Approve a monitored privacy/data-rights channel | Privacy, Account deletion |
| Governing law/jurisdiction | Unresolved | Obtain legal approval for governing law and venue | Terms |
| Effective date | Unresolved | Select only after final legal text approval | Privacy, Terms |
| Data retention | Draft only | Approve periods, deletion triggers and lawful exceptions by data category | Privacy, Account deletion |
| Minors/age handling | Draft only | Approve minimum age and educational/guardian consent treatment | Privacy, Terms |
| Subscription/cancellation | Draft only | Approve renewal, cancellation timing and access-after-cancellation language | Terms, Pricing |
| Refunds and taxes | Draft only | Approve refund eligibility, statutory exceptions and tax treatment | Terms |
| Account-deletion process | Technical flow exists; public SLA unresolved | Approve alternative verification, response timing and retained-data exceptions | Account deletion, Privacy |

## P2 Risk Position

The Supabase dashboard identifies the current organization plan as Free.
Leaked-password protection is therefore unavailable without a human-approved
upgrade. This is a documented P2 launch risk, not an enabled control.

The API currently runs as one Render instance. Per-instance rate limiting is
acceptable only for a controlled initial launch with monitoring and no
horizontal scale. It must be replaced by shared enforcement before scaling or
when abuse evidence appears. Contact delivery remains disabled, so its local
limiter does not create a false delivery guarantee.

## Decision

```text
P0: NONE
P1 TECHNICAL DEFECTS: PASSWORD RESET FIX NOT YET DEPLOYED
PUBLIC INDEXING: DISABLED
FINAL DECISION: NO-GO
READY FOR W7-D PUBLIC LAUNCH: NO
```

W7-D may begin only after every launch-blocking row is evidenced as complete
and an explicit human GO is issued. W7-C performs no indexing activation,
release tag, public announcement, DNS change, Supabase migration or runtime
push.
