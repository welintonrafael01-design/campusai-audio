# Supabase Production Migration Evidence

Status: `W6-R2 RECONCILIATION COMPLETE - REMOTE MIGRATION BLOCKED`

Captured at: `2026-09-08T04:54:59Z`

Repository commit: `5d5704293808d05f7a320bb60081eb13290bfcf2`

Target project ref: `olegevhncmblxngurclt`

## W6-R2 Reconciliation

W6-R2 used authenticated read-only catalog access and fresh schema dumps. It
performed no remote schema, data, Auth, Storage, migration-history or policy
mutation.

### Recovery Evidence

Secure backup directory:

`$HOME/StudyBookAI_Backups/supabase_2026-09-08`

| File | Bytes | Permissions | SHA-256 |
| --- | ---: | ---: | --- |
| `schema.sql` | 17,163 | `600` | `604f03d383cb2dcb8a1e43c9d4b1c0dadabdbe143bbada4181792a0aea486c3f` |
| `data.sql` | 783,017 | `600` | `16bc8ca49af3d5d3e2770790f32e6b725296501551ea3d5f0d19801a82586d99` |
| `roles.sql` | 358 | `600` | `4350a72b5ec109888e740c17f3eb4da2fcd95ab73af26499538ed0bf615db543` |
| `catalog_w6_r2.sql` | 77,003 | `600` | `ea2dc77a51f4d74398792439d22b90de47ec06454d1676a07fef59f1a7070baf` |

The logical data dump contains 41 COPY targets. Its 14 public-table row counts,
five Auth users and 37 Storage metadata rows are internally coherent with the
fresh remote inventory. No row or private record content is included here.

`supabase backups list` reported `walg_enabled=true`, `pitr_enabled=false` and
no listed physical backups. The complete manual logical backup is therefore the
database recovery artifact for this gate.

The recursive Storage inventory corrected the earlier count of five. Five was
the number of top-level owner prefixes; the actual bucket contains 37 objects.
All 37 objects were downloaded from private bucket `studybook-documents`:

- Remote objects: 37
- Downloaded objects: 37
- Downloaded bytes: 42,288,843
- Backup directories: `700`
- Backup files: `600`
- Private manifest: `storage/studybook-documents-manifest.tsv`
- Manifest SHA-256: `cc230b0f66d188e71d4271f352b48e00a32b4273ca60ee84c93f0f0800f8a21e`

The private manifest records every relative object identifier, size, SHA-256
and permission. It is outside Git and must remain private. Database plus Storage
recovery point: `PASS`.

### Remote Catalog

- Project: `olegevhncmblxngurclt`
- Name: `studybook-ai`
- Region: `us-east-2`
- Status: `ACTIVE_HEALTHY`
- PostgreSQL: `17.6.1.127`
- Migration history: empty
- Remote public tables: 14
- Remote rows across those tables: 968
- Remote public policies: 1
- Remote Storage policies: 0
- Expected migrated public policies: 45
- Expected migrated Storage policies: 4

Remote-only schema drift includes `educator_rubrics` and its index. Material
legacy drift includes different indexes, missing ownership foreign keys,
missing update triggers, nullable owner columns and incompatible key shapes.

### Migration Decision Table

| Migration | Remote reality | Future action |
| --- | --- | --- |
| `20260828000100` core | **CONFLICTING**. All 13 table names exist, but `documents.user_id` and `workspaces.updated_at` are absent; owner FKs/triggers are absent; defaults/nullability/indexes differ; `user_usage_events.id` and `user_subscriptions` keys conflict. | RECONCILIATION REQUIRED |
| `20260829000100` RLS | **CONFLICTING**. One legacy policy exists instead of 45; three core tables have RLS disabled; no Storage policies exist; the legacy policy trips the migration stop guard. | STOP / RECONCILIATION REQUIRED |
| `20260831000100` persistence | **ABSENT**. `document_chunks`, `certificates`, RAG function/indexes and `studybook-private-artifacts` are absent. | APPLY AFTER BASELINE RECONCILIATION |
| `20260901000100` ownership | **CONFLICTING**. The required `documents.user_id` column does not exist, so the migration cannot execute against the current schema. | RECONCILIATION REQUIRED |
| `20260907000100` atomic quota | **ABSENT**. Reservation table, usage-event FK/indexes and all three quota RPCs are absent. | APPLY AFTER BASELINE RECONCILIATION |

No migration is safe to repair as applied. A blind `supabase db push --linked`
would fail or leave material drift and must not run.

### P0 Security-Relevant Drift

Catalog evidence shows RLS disabled on `workspaces`, `chats` and `messages`
while `anon` and `authenticated` have broad table grants. Read-only anonymous
`HEAD` probes confirmed:

| Table | Anonymous visible rows |
| --- | ---: |
| `workspaces` | 36 |
| `chats` | 46 |
| `messages` | 118 |

No row body was downloaded and no write probe was attempted. The grants imply a
potential mutation risk, but only anonymous SELECT visibility was directly
verified. Treat this as an open P0 confidentiality incident until a separately
authorized fail-closed RLS remediation is applied and reverified.

### Data Safety

Pre/post aggregate checks remained identical:

- Public tables: 14
- Aggregate rows: 968
- Storage objects: 37
- Data loss: none detected
- Remote mutations: none

### W6-M Decision

- Migrations safe to repair as applied: none
- Migrations safe to push now: none
- Pre-baseline reconciliation migration required: yes
- Disposable restore rehearsal required: yes
- Safe to repair migration history: no
- Safe to apply remaining migrations: no
- Ready for W6-M: no

The exact future command sequence and bridge requirements are recorded in
`SUPABASE_PRODUCTION_MIGRATION_RUNBOOK.md`. W6-R2 did not execute those
commands.

## Original W6 Safety Decision

This section preserves the original W6 stop evidence. Its recovery, CLI-link
and migration-history status is superseded by the W6-R2 evidence above.

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
- `studybook-documents` top-level owner-prefix count: 5; this was not an object
  count and is corrected by the recursive 37-object inventory above
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

## Original Human Recovery Action

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

## Original W6 Gate Result

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
