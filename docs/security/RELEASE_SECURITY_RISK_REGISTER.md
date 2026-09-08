# Release Security Risk Register

## W2.1 Entitlement And Cost-Control Update

Free premium generation is now denied by the backend capability resolver, and
the five allowed Free AI actions use user-scoped monthly counts from
`user_usage_events`. Direct exam, AudioBook, Voice Tutor, and Question Bank
requests cannot rely on Flutter visibility to gain access. Structured denial
payloads expose only plan guidance, never subscription or credential data.

W5 replaces the application-level count-then-generate race with service-only
PostgreSQL reservations, transaction advisory locks, atomic commit/release,
30-minute stale recovery and user-scoped idempotency. Local disposable Supabase
concurrency tests pass for every Free limit. Production remains gated until the
new migration is applied and verified through the controlled runbook.

## 7F-S2 Durable Persistence Update

Production persistence no longer uses Chroma SQLite, local registry JSON,
local certificate JSON or local audio as source of truth. The code requires
private Supabase Storage plus owner-scoped Postgres/pgvector configuration and
fails startup when it is absent. Deployment remains blocked until migration
`20260831000100_production_persistence.sql`, private-bucket posture and any
required legacy backfill are verified against the target Supabase project.

| ID | Severity | Description | Affected area | Mitigation / next action | Release blocker? | Status |
|---|---|---|---|---|---|---|
| SEC-7D-001 | P2 | Deployed Supabase RLS/storage policy state remains unverified. Service-role calls bypass RLS. | Supabase | 7F-S1 versions least-privilege RLS and private Storage policy contracts. Deployment owner must review/apply them and verify the live catalog before external production. | Conditional yes | Repository mitigation complete; deployment gate open |
| SEC-7D-002 | P2 | Account erasure must remain consistent across backend PDF, Chroma, Supabase Storage/rows, MP3s and Auth. | Privacy/deletion | 7E-R added an owner-scoped retry-safe orchestrator with Auth last; verify deployed Supabase schema/storage and retention policy. | Conditional deployment gate | Mitigated in code; deployment evidence open |
| SEC-7D-003 | P2 | Three unowned legacy certificate records were tracked in recent Git history and are not clearly marked synthetic. | Repository/privacy | Removed from tracked HEAD and runtime file ignored. Confirm synthetic status; if real, authorize restricted history cleanup and privacy response. | Conditional yes | Mitigated in HEAD; verification open |
| SEC-7D-004 | P2 | Rate limiting is per-IP, in-memory, and per process. | Costly AI/API endpoints | Move to distributed/user-aware limits at production scale; retain subscription usage gates. | No for controlled RC | Accepted for RC |
| SEC-7D-005 | P2 | CSP/HSTS and final web headers are not represented in Flutter build output. | Web hosting | Configure and verify on production CDN/reverse proxy without blocking Flutter assets. | Yes at deployment | Open deployment gate |
| SEC-7D-006 | P2 | CIAG QA legacy deduplication/migration remains incomplete. No cross-user bypass was observed. | QA legacy data | Perform separately with backup and owner verification; no destructive change in 7D. | No | Inherited open |
| SEC-7D-007 | P3 | User-scoped SharedPreferences/browser cache is not app-encrypted and may remain after logout. | Compromised/shared device | Rely on OS/browser sandbox for v1; document device-data clearing and evaluate secure storage for selected fields. | No | Accepted |
| SEC-7D-008 | P3 | `backend/.venv` remains tracked despite ignore rules. | Repository hygiene | Remove in a dedicated reviewed commit; recreate from requirements. | No | Open |
| SEC-7D-009 | P3 | `flutter_markdown` is deprecated; no executable-link or raw HTML exploit was demonstrated and chat links have no launcher callback. | Web/content rendering | Pin/audit replacement during dependency maintenance; retain safe URL policy for launch surfaces. | No | Open |
| SEC-W5-001 | P2 | Concurrent Free requests could previously consume beyond the final monthly slot. | Cost control | PostgreSQL reservation RPC, advisory lock, idempotent usage commit, release and TTL recovery implemented and concurrency-tested locally. Apply migration before backend rollout. | Conditional deployment gate | Mitigated in code; remote migration evidence open |
| REL-7E-001 | P1 | Android application identity was provisional. | Google Play identity | Migrated production Android namespace/application ID/activity to authorized `com.studybookai.app`; static regression test rejects `com.example`. | No | Closed in 7E-R |
| REL-7E-002 | P1 | Productive upload signing required verification. | Android signing | Existing external upload key signed AAB verified with certificate SHA-256 `CD:33:79:B9:43:54:34:31:2C:20:87:DA:53:95:5E:AF:2D:AD:C7:AC:88:AF:02:9B:43:2F:69:58:44:D1:1E:36`; secrets remain ignored. Enroll in Play App Signing and rebuild after final config. | No technical blocker; Play Console action remains | Closed in code/signing evidence |
| REL-7E-003 | P1 | No approved production HTTPS API/privacy URL exists. | Android release runtime | Central validation and release-config scanner reject local/HTTP/placeholder values. Provision approved HTTPS URLs externally. | Yes for usable Play build | Technical guard ready; deployment gate open |
| POL-7E-004 | P1 | Android digital purchases previously opened Stripe Checkout. | Google Play Payments | Android now uses Google Play Billing and server verification contract; Stripe remains Web-only. Configure Play products and live verifier externally. | Yes until Play configuration | Technical architecture ready; external Play gate open |
| POL-7E-005 | P1 | Account deletion and complete erasure were absent. | Google Play User Data | In-app reauthentication and owner-scoped retry-safe backend deletion are implemented; publish the specified external request page. | Yes until public page exists | Technical lifecycle closed; human hosting gate open |
| REL-7E-006 | P2 | Privacy URL, final Data Safety answers, store copy, feature graphic and screenshots are not approved. | Play listing/app content | Complete human/legal/brand review using 7E drafts before track promotion. | No for artifact build; yes by required track | Open human gate |
| REL-7F-001 | P1 | Certificate, badge and transcript exports embedded a localhost verification URL. | Public verification QR codes | Verification URLs now derive from the validated `APP_WEB_URL`; production fails closed when the public origin is missing. Regression tests cover development and production behavior. | No | Closed in 7F |

P0 open: 0. Plan Master 7E-R closes the five P1 technical implementation gaps.
Plan Master 7F closes the remaining export verification URL defect.
Upload remains blocked by external signing, HTTPS deployment, Google Play
product/verifier configuration, privacy/deletion hosting and Play Console
actions. Conditional deployment gates must be completed before production.
