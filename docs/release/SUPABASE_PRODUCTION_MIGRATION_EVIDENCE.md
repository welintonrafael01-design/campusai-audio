# Supabase Production Migration Evidence

Status: `BLOCKED BEFORE MIGRATION`

Captured at: `2026-09-08T04:54:59Z`

Repository commit: `5d5704293808d05f7a320bb60081eb13290bfcf2`

Target project ref: `olegevhncmblxngurclt`

## Safety Decision

The W6 operation was explicitly authorized for the target project. Only
read-only preflight requests were performed. No SQL migration, backfill,
Storage mutation, Auth mutation, quota reservation, deployment, DNS change,
push or tag was performed.

The migration did not proceed because a usable recovery point could not be
verified. Supabase CLI `2.116.0` had no Management access token, the repository
was not linked to a remote project, and no approved database credential was
available. The locally configured backend service-role key can inspect product
data through supported APIs, but it cannot verify provider backups or produce a
complete database/Auth/RLS/Storage recovery point.

Recovery point: `FAIL - HUMAN OPERATOR ACTION REQUIRED`

## Remote Identity

- Expected project ref: `olegevhncmblxngurclt`
- Backend Supabase URL project ref: match
- QA configuration Supabase URL project ref: match
- REST catalog response: HTTP 200
- Supabase Management session: unavailable
- Supabase CLI remote link: absent

No credential values, tokens, passwords or private content were recorded.

## Read-Only Pre-Migration Inventory

The service-role REST catalog exposed the following aggregate counts:

| Table | Present | Rows |
| --- | ---: | ---: |
| `workspaces` | Yes | 36 |
| `documents` | Yes | 43 |
| `study_results` | Yes | 27 |
| `audiobooks` | Yes | 2 |
| `chats` | Yes | 46 |
| `messages` | Yes | 118 |
| `user_subscriptions` | Yes | 7 |
| `user_usage_events` | Yes | 604 |
| `educator_courses` | Yes | 2 |
| `educator_students` | Yes | 36 |
| `educator_attendance` | Yes | 36 |
| `educator_gradebook` | Yes | 6 |
| `educator_question_banks` | Yes | 5 |
| `document_chunks` | No | Not available |
| `certificates` | No | Not available |
| `quota_reservations` | No | Not available |

The PostgREST catalog did not expose these expected RPCs:

- `match_studybook_document_chunks`
- `reserve_studybook_free_quota`
- `commit_studybook_free_quotas`
- `release_studybook_free_quota`

This schema evidence is consistent with the production-persistence and atomic
quota migrations not yet being deployed. It is not a substitute for migration
history. The actual pending migration set remains unconfirmed until the remote
`supabase_migrations.schema_migrations` catalog is inspected through an approved
database or Management connection.

## Storage

- `studybook-documents`: present and private
- `studybook-documents` aggregate object count: 5
- `studybook-private-artifacts`: not returned by the bucket catalog
- `studybook-private-artifacts` list response contained no objects

No object names, paths, URLs or contents were recorded. The missing private
artifacts bucket is consistent with the persistence migration being pending.

## QA Identity Evidence

All three configured QA identities existed, were email-confirmed and
authenticated successfully without logging credentials or tokens:

| Identity | Trusted app role | Subscription plan | Status |
| --- | --- | --- | --- |
| Student A | `student` | `student` | `active` |
| Student B | `student` | `student` | `active` |
| Teacher | `teacher` | `teacher` | `active` |

The inspected QA users had no role override in user metadata. A representative
RLS probe confirmed Student A could read its own subscription row while Student
B could not read Student A's row. Student A had no fixtures in the inspected
document, result, chat or audiobook tables, so those cross-user probes were not
claimed as completed.

The quota RPC permission probe returned `PGRST202` because the RPC is absent. It
did not reserve or consume quota.

## Migration Comparison

Repository migration chain:

1. `20260828000100_studybook_core_schema.sql`
2. `20260829000100_studybook_rls_security.sql`
3. `20260831000100_production_persistence.sql`
4. `20260901000100_document_ownership_hardening.sql`
5. `20260907000100_atomic_free_quota.sql`

Remote applied versions: `UNAVAILABLE - MANAGEMENT/DATABASE ACCESS REQUIRED`

Local pending versions: `UNCONFIRMED`

No migration was marked applied and no migration-history row was changed.

## Required Human Recovery Action

Before resuming W6, an authorized Supabase project owner must:

1. Verify a current provider-managed database backup and the corresponding
   Storage recovery procedure for `olegevhncmblxngurclt`.
2. Record the backup timestamp/identifier and recovery status in the approved
   private operator channel without placing secrets in this repository.
3. Authenticate the local Supabase CLI with an operator access token or provide
   an approved ephemeral database connection through the secure local
   environment. Do not paste it into chat or commit it.
4. Re-run the read-only migration-history and policy inventory before any SQL.
5. Stop again if schema reality and migration history disagree.

## Gate Result

- Recovery point: FAIL
- Remote migration: NOT RUN
- Backfill: NOT RUN
- Data loss: NONE OBSERVED
- Remote schema mutation: NONE
- Remote Storage mutation: NONE
- Backend regression: 175 passed, 10 conditional tests skipped
- Security regression: 83 passed
- Atomic quota local integration: 10 passed
- Flutter tests: 144 passed
- Flutter analyze: no issues found
- Python compile: PASS
- QA secret configuration validator: PASS
- Ready for Render production: NO
- Ready to resume W6 after operator recovery evidence: YES
