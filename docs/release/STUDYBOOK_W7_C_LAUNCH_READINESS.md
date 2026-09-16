# StudyBook AI W7-C Launch Readiness

Status: `NO-GO - HUMAN LAUNCH BLOCKERS REMAIN`

Date: `2026-09-16`

Deployed frontend QA source: `9a6515a2333cd1eadf65c47dce9d974f9d20964b`

Deployed API build: `39a43aadeecd37fb6d6797bd0bce6b609905098d`

W7-C2 runtime commits included in the deployed baseline:

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
| API | PASS | `/health` returns 200 and build SHA `39a43aa...` |
| TLS | PASS | Current certificates validate for root, `www`, `app` and `api` |
| CORS | PASS | Custom app origin receives 200; an unknown origin receives 400 |
| Authenticated upload | PASS | Student A uploaded one harmless QA PDF through the visible UI; Library and Cloud state survived reload |
| Visible logout | PASS | The Account control returned to `/#/auth`; direct access to `/#/library` redirected back to Auth |
| Indexing | DISABLED | `X-Robots-Tag` is `noindex`; `robots.txt` disallows all crawling |
| Runtime source | CURRENT | The API and validated Flutter recovery runtime use commit `39a43aa...`; the later local commit is documentation only |

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

Automated responsive and accessibility checks support the release decision.
They are supplemented by retained physical TalkBack/text-scale evidence and
the W7-C4.1 production keyboard, dialog and multi-width visual spot checks;
none of this is represented as formal WCAG certification.

## Release Blocker Register

| Issue | Severity | Status | Launch blocker | Evidence | Required action |
| --- | --- | --- | --- | --- | --- |
| OpenAI production key rotation | P1 | CLOSED | NO | The new StudyBook AI project key is active in Render, the restart and minimal document-chat request passed, and the previous production key is inactive | Preserve server-side storage and repeat the controlled rotation procedure for future key changes |
| Visible Flutter logout | P1 gate | CLOSED | NO | The visible Account action returned to `/#/auth`; a subsequent `/#/library` navigation was redirected to Auth | Preserve this flow in future browser regression coverage |
| Production document upload | P1 gate | CLOSED | NO | A harmless one-page QA PDF uploaded successfully, produced a truthful summary, persisted in Library/Cloud after reload and remained inaccessible to Student B | The private fixture is intentionally retained under Student A as QA evidence; remove it later only through an explicitly authorized delete action |
| Responsive human QA | P1 gate | CLOSED | NO | Marketing, Student/Auth and Teacher production views passed the required 390, 768, 1024 and 1440 px samples | Preserve the matrix in future release smoke tests |
| Accessibility human QA | P1 gate | CLOSED AS PRACTICAL QA | NO | Named controls, visible keyboard focus, dialog semantics, reduced motion, deployed contrast checks and retained physical TalkBack evidence pass | Formal WCAG certification remains outside this release gate |
| Password reset E2E | P1 gate | CLOSED | NO | A fresh same-browser recovery completed callback, PKCE exchange, password update, post-reset logout, old-password rejection, new-password login and session restore without URL token leakage | Preserve the same-browser PKCE flow in future authentication regression coverage |
| Contact channel | P1 gate | HUMAN ACTION | YES | Contact provider remains `disabled`; the form fails honestly | Approve a monitored provider or monitored support/privacy contact and validate delivery |
| Legal finalization | P1 | DRAFT | YES | Privacy and account-deletion content still contains unresolved placeholders | Legal/product owner approves entity, contacts, address, jurisdiction, date, retention, age, subscription, cancellation and refund terms |
| Leaked-password protection | P2 | HUMAN ACTION / PLAN LIMITED | NO with explicit acceptance | Project dashboard reports Free; Supabase limits this feature to Pro and above | Upgrade deliberately and enable it, or record explicit pre-launch P2 risk acceptance |
| Distributed rate limiting | P2 | ACCEPTED FOR CONTROLLED SINGLE INSTANCE | NO with explicit acceptance | Backend uses per-instance 120 requests/60 seconds per client; disabled contact route uses per-instance 5 attempts/10 minutes | Add shared/distributed enforcement before horizontal scale or meaningful abuse exposure |
| Initial plan presentation refresh | P2 | CLOSED | NO | Fresh production login immediately displayed Student Pro with active, synchronized state; reload preserved Student Pro and manual sync confirmed the same Supabase-backed plan | Preserve fresh-login and reload coverage in future production smoke tests |

## Human Gate Details

### OpenAI Rotation

The human created a new project-scoped StudyBook AI production key and entered
it directly into Render without exposing its value. The resulting Render
restart reached `Live`, `/health` returned HTTP 200, the custom app-origin CORS
preflight returned HTTP 200, and one short document-chat request returned a
valid AI response. Only after those checks passed was the previous production
key revoked; OpenAI now reports the previous key inactive and the new key
active. No key value, prefix or fingerprint is recorded here.

The post-rotation scan checked 947 tracked files and 43 available Web/marketing
bundle files against nine local private values and high-confidence secret
patterns. It found no tracked or bundled secret exposure.

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
authorization bypass was observed. Commit `be47aa5c...` removes the write-order
race and rebuilds Account after manual synchronization. It is included in the
deployed QA source. Current Student production evidence shows active Student
Pro on first observation and after reload.

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
Commit `27f69d2` is now included in deployed QA commit `39a43aa`. Vercel
deployment `dpl_7DZzmwNHT6oVMoMnPSge97JwfpDh` is READY on the custom app
domain. A post-deploy reset request was attempted only from the production Auth
screen, but Supabase returned its email security cooldown response. One
controlled retry after waiting was also rejected, so no fresh recovery email
or link was created and no earlier link was reused. Direct access to the reset
route without a code keeps the form disabled and presents the expected human
invalid/expired-link guidance without exposing auth parameters. The successful
PKCE exchange and password change remain a human retest after the provider
cooldown expires.

## W7-C2.1 QA Deployment Evidence

This section is the historical state captured before the successful W7-C2.3
human reset closure. The W7-C4 addendum below is authoritative for the current
password-reset and UX/accessibility status.

- Local and remote QA HEAD: `39a43aadeecd37fb6d6797bd0bce6b609905098d`.
- Normal QA branch push passed without force or tag operations.
- Vercel deployment `dpl_7DZzmwNHT6oVMoMnPSge97JwfpDh` is READY and reports
  the same Git commit.
- `https://app.studybookai.com` and direct SPA routes return HTTP 200; the
  deployed bundle uses `https://api.studybookai.com` and contains no localhost
  API fallback.
- Student A login, dashboard, session restore after reload, private Cloud
  Library and Student-to-Teacher route denial pass.
- Account displayed Student Pro, active and synchronized on its first
  observation. Reload preserved the plan; manual sync was not required to
  correct presentation and independently confirmed Student Pro from Supabase.
- The reset request remains blocked by Supabase email cooldown. Password update,
  post-reset logout and old/new password checks were not performed.
- Flutter analyze reports no issues and all 149 Flutter tests pass, including
  the recovery callback contract.
- Public indexing remains disabled and the overall launch decision remains
  NO-GO.

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
P1 TECHNICAL DEFECTS: NONE OBSERVED; PASSWORD RESET E2E BLOCKED BY EMAIL COOLDOWN
PUBLIC INDEXING: DISABLED
FINAL DECISION: NO-GO
READY FOR W7-D PUBLIC LAUNCH: NO
```

W7-D may begin only after every launch-blocking row is evidenced as complete
and an explicit human GO is issued. W7-C performs no indexing activation,
release tag, public announcement, DNS change, Supabase migration or runtime
push.

## W7-C4 UX, Accessibility, Contact And Legal Addendum

W7-C4 completed the production Marketing matrix for all 11 public routes at
390, 768, 1024 and 1440 px, plus authenticated Student views and isolated Auth
at the same representative breakpoints. No document-level horizontal overflow,
hidden primary CTA or unreachable Student control was found. At 390 px, Cuenta
scrolls through plan, preferences, privacy, deletion and the visible logout
action.

The successful W7-C2.3 human recovery supersedes the cooldown snapshot above:
a fresh same-browser PKCE link established the recovery session, password
update passed, post-reset logout passed, the old password was rejected, the new
password logged in and the session restored without token, auth-code or open-
redirect leakage.

Three low-risk runtime corrections are deployed and validated:

- the Marketing mobile menu closes with Escape and restores focus;
- Auth fields and the primary submit control expose localized semantics;
- Flutter action colors now meet 4.5:1 contrast with white text.

Marketing lint, 42 tests and production build pass. Flutter analyze reports no
issues, all 151 tests pass and the Web build succeeds. The authorized QA
Teacher sample subsequently passed the required multi-width production matrix.

Contact remains safe but not launch-ready: disabled delivery returns an honest
HTTP 503 and does not silently discard messages, but no monitored support or
privacy address/provider has been approved. Legal pages remain explicit,
non-indexed drafts. The complete decision package is
`docs/release/STUDYBOOK_W7_C4_UX_ACCESSIBILITY_LEGAL.md`.

Current strict decision:

```text
P0: NONE
P1 TECHNICAL: NONE
P1 HUMAN: CONTACT CHANNEL AND LEGAL APPROVAL REMAIN OPEN
RESPONSIVE MARKETING: PASS
RESPONSIVE FLUTTER STUDENT: PASS
RESPONSIVE FLUTTER TEACHER: PASS
ACCESSIBILITY PRACTICAL SPOT CHECK: PASS
PUBLIC INDEXING: DISABLED
FINAL DECISION: NO-GO
READY FOR W7-D PUBLIC LAUNCH: NO
```

## W7-C4.1 Production UX And Teacher Validation

The QA branch was pushed normally at
`9a6515a2333cd1eadf65c47dce9d974f9d20964b`. Flutter deployment
`dpl_yjRtT1oMLssvp66NVbDEdxLM866U` and Marketing deployment
`dpl_7N5DXfTSn3c1TbDjUeYeguZYUjLi` are READY from that exact source. The
custom domains, canonical API origin and disabled-indexing controls remain
intact.

The production Auth form exposes localized names for email, password and the
primary action. The deployed contrast corrections retain tested AA ratios of
4.59:1 and 4.66:1 with white. At mobile width the Marketing menu closes with
Escape, visibly restores focus and does not trap keyboard navigation. Privacy
and account-deletion routes contain the corrected `Cuenta` navigation wording.

An authorized QA Teacher login resolved server-side to the active Teacher plan.
`/educator/snapshot` returned 200 for Teacher, while an authenticated Student B
probe returned 403. Teacher Studio was sampled at 390, 768, 1024 and 1440 px.
Cursos, Estudiantes, Asistencia, Ponderaciones, Calificaciones, Exámenes,
Planificación, Rúbricas and Banco de preguntas loaded with reachable actions,
named controls and no layout-breaking overflow. Visible focus and a semantic
date-dialog spot check passed. A brief stale Free/local state appeared on the
first Teacher render before backend entitlement propagation; it self-corrected
and is tracked as P2 because backend authorization remained correct.

The Contact page remains safe but delivery is intentionally disabled. No
monitored support/privacy channel has been approved. Legal content remains a
non-indexed draft and the decision register remains ready for human/legal
closure.

```text
P0: NONE
P1 TECHNICAL: NONE
P1 HUMAN: MONITORED CONTACT CHANNEL AND LEGAL APPROVAL REMAIN OPEN
RESPONSIVE MARKETING: PASS
RESPONSIVE FLUTTER STUDENT: PASS
RESPONSIVE FLUTTER TEACHER: PASS
ACCESSIBILITY PRACTICAL SPOT CHECK: PASS
PUBLIC INDEXING: DISABLED
FINAL DECISION: NO-GO
READY FOR FINAL HUMAN LAUNCH DECISIONS: YES
READY FOR W7-D PUBLIC LAUNCH: NO
```

## W7-C5 Contact And Legal Final Draft

The Product Owner decisions recorded in
`docs/legal/STUDYBOOKAI_FINAL_HUMAN_APPROVAL_SHEET.md` were integrated into
Privacy, Terms, Contact, Account Deletion, Security and Pricing. The approved
monitored channel is `studybookaiapp@gmail.com`; the automated contact provider
remains disabled and is not presented as operational.

Operator, age/minors, 30/90-day deletion targets, subscription pricing,
no-trial position, cancellation, first-payment refund, AI limitations, user
content, IP, provider and P2 decisions are aligned across the public pages.
Publishable address remains blocked pending counsel. Effective date is added
only after final publication approval. Specific venue/court wording remains
under legal consistency review.

Marketing lint, 47 tests, production build, 11-route smoke and 16-link internal
check pass. Public indexing remains disabled. No push or deployment occurred.
The strict decision remains `NO-GO` pending final text/publication approval.
