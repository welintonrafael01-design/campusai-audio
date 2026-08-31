# Plan Master 7F - Final Release Gate

Date: `2026-08-29`

Status: `TECHNICAL CODE READY - PUBLIC DEPLOYMENT BLOCKED`

This gate audits commit `1a0cf0bff80c6777e79f5d5528776f8839824f11`
plus the local 7F remediation. It does not publish, deploy, tag, push or mutate
an external service.

## Baseline

| Item | Evidence | Result |
| --- | --- | --- |
| Branch | `qa/studybook-ai-rc1` | Pass |
| Starting commit | `1a0cf0bff80c6777e79f5d5528776f8839824f11` | Pass |
| Known untracked files | `open_studybook_all.sh`, `open_studybook_mobile_test.sh` | Excluded |
| Signed AAB SHA-256 | `7d127a533944eb3f4f4e3258bb777af37e6c9411462b54eaca0926eda8062d76` | Pass |
| Upload certificate SHA-256 | `CD:33:79:B9:43:54:34:31:2C:20:87:DA:53:95:5E:AF:2D:AD:C7:AC:88:AF:02:9B:43:2F:69:58:44:D1:1E:36` | Pass |

The existing AAB is signing evidence only. A new AAB must be generated after
the approved public URLs and Play products are configured.

## Automated Evidence

| Gate | Result | Evidence |
| --- | --- | --- |
| Backend compile | Pass | `python -m compileall -q app` |
| Backend tests | Pass | 134 passed, 0 failed, 0 skipped |
| Dart formatting | Pass | 346 files checked, 0 changed |
| Flutter analyze | Pass | No issues found |
| Flutter tests | Pass | 125 passed, 0 failed |
| Flutter Web release build | Pass | `flutter build web --release` |
| Web artifact secret/QA scan | Pass | No high-confidence credential or QA identity pattern |
| AAB secret/QA scan | Pass | No high-confidence credential or QA identity pattern |
| Placeholder release config | Pass | Scanner rejected `release.example.json` |
| Git diff whitespace check | Pass | No whitespace errors before documentation |

Flutter tests cover the critical responsive widths `320`, `360`, `390`,
`411` and `430`, text scale `1.3`, chat/IME, Teacher empty states, AudioBook,
account and billing behavior. Default widget coverage uses text scale `1.0`.
This is automated evidence, not a replacement for final device and assistive
technology review.

## Security And Authorization

Automated regression covers token validation, invalid/expired tokens, role and
plan spoof denial, `user_metadata` spoof denial, Student/Teacher/Admin gates,
owner-scoped documents, StudyResults and AudioBooks, private audio, account
deletion, Play purchase spoof denial, prompt-injection boundaries and error
redaction. The result is:

- P0 technical findings: 0.
- P1 technical findings: 0 after the 7F export URL remediation.
- Multiuser isolation: pass in repository tests.
- Teacher and Admin authorization: pass in repository tests.
- Account deletion orchestration: pass in repository tests.
- No service-role, OpenAI, Stripe, Play credential or signing secret was found
  in Flutter, the Web artifact or the AAB.

## Production Configuration Classification

| Occurrence | Classification | Reason |
| --- | --- | --- |
| Backend local CORS and billing defaults | Dev only | `APP_ENV=production` validates exact HTTPS public configuration |
| Flutter local API defaults | Dev only | Release-mode environment validation rejects local, HTTP and `.invalid` hosts |
| QA runner local hosts | Test only | Used only by local E2E scripts |
| `<DOMAIN>` and `REQUIRED_*` values | Documentation/config placeholder | Release scanner rejects them |
| URL-policy local-host strings | Validation rule | They identify and reject unsafe release URLs |
| Product feature TODOs | Post-launch backlog | No production deployment contract depends on them |

7F found one production blocker: exported certificate, badge and transcript QR
codes used a hardcoded local verification host. They now derive from the
validated `APP_WEB_URL`; production fails closed if that origin is absent.

## Android Release

| Check | Result |
| --- | --- |
| Application ID `com.studybookai.app` | Pass |
| Version `1.0.0+1` | Pass |
| Compile/target SDK `36`; minimum SDK `24` | Pass |
| Release not debuggable | Pass |
| Cleartext disabled | Pass |
| Backup disabled | Pass |
| Exported components constrained | Pass |
| Permissions limited to app/network, billing and justified microphone use | Pass |
| No legacy storage permission | Pass |
| `arm64-v8a` and 64-bit compatibility | Pass |
| Productive signer; no debug fallback | Pass |

## AI, Documents And Deletion

Repository tests and code review verify upload limits/type validation, safe
filenames and paths, authenticated private document/audio access, RAG owner
scoping, untrusted AI output boundaries, external URL validation, redacted
errors and temporary-file cleanup. Account deletion removes inventoried
owner-scoped resources and deletes Auth last; partial failure remains retryable.
Deployed Storage/schema and legal retention behavior still require external
verification.

## Google Play Billing

The Android client uses `in_app_purchase` for digital subscriptions and never
grants an entitlement locally. The backend remains authoritative, rejects
unknown product mappings and purchase spoofing, and exposes the server
verification integration point. Live products, Play Console setup and Google
Play Developer API credentials are external human actions. Stripe remains a
Web billing path and must not be used for Android digital goods.

## Web Gate

The release Web compilation passed without a production URL. This validates
compilation and artifact hygiene only. It is not deployable evidence: runtime
production configuration, public privacy/deletion pages, CDN security headers
and final Student/Teacher/Admin smoke tests depend on an approved domain and
deployed API.

## Supabase Gate

Repository-side app metadata authority, user-metadata denial, owner filters and
service-role boundaries are verified. Plan 7F-S1 versions RLS, privileges and
private document Storage policies for all 13 observed tables and the confirmed
document bucket, with negative owner/metadata/path tests. Repository security
is therefore complete for the observed schema. The migration was not applied;
the deployed environment remains unverified and requires a catalog/policy
review plus real two-user tests before external production.

## Public Documents

Privacy and account-deletion drafts do not claim a real domain, legal entity,
contact, retention period, age policy or completion deadline. They remain
drafts and require legal/human approval plus deployment before Play Console use.

## Decision

| Decision | Status |
| --- | --- |
| Technical code readiness | Pass |
| Android internal testing readiness | Blocked by external Play/public configuration |
| Production publication readiness | Blocked |
| Web production readiness | Blocked |
| Backend production readiness | Blocked |

The remaining gates are listed in `FINAL_RELEASE_BLOCKERS.md`. None authorizes
an upload or production deployment.
