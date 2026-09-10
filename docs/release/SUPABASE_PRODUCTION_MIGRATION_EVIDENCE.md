# Supabase Production Migration Evidence

Status: `W6-M1 CORE ROLLBACK VERIFIED - REMOTE RETRY NOT AUTHORIZED`

Captured at: `2026-09-08T04:54:59Z`

W6-P0.1 updated at: `2026-09-10`

Repository commit: `5d5704293808d05f7a320bb60081eb13290bfcf2`

W6-P0.1 base commit: `1ab27211ad58d574331069c82fd78f0dc3277a44`

W6-M1 base commit: `71e47bc8b04544a6de0a5be690427a0523aa0de8`

Target project ref: `olegevhncmblxngurclt`

## W6-M1 Failed Remote Migration Reconciliation

The authorized W6-M `db push` applied and recorded the bridge
`20260827000100_remote_legacy_reconciliation`, then lost its database
connection while reporting Core CLI statement index 12
(`CREATE TABLE IF NOT EXISTS public.educator_students`). No automatic retry,
migration repair, reset, manual SQL or later migration followed.

W6-M1 performed only catalog/aggregate queries through Supabase's Management
read-only endpoint plus anonymous GET/list/read probes. It made no remote schema,
data, Auth, Storage or migration-history mutation.

The installed CLI's `db query --linked` path still received `403` while
initializing its temporary login role. The dedicated Management
`database/query/read-only` endpoint returned `201` and was used instead. No
Security Advisor automatic fix was requested or applied.

### Remote History And Physical State

Remote migration history contains exactly:

| Version | Name | State |
| --- | --- | --- |
| `20260827000100` | `remote_legacy_reconciliation` | Applied and recorded |

Core and all four later versions are absent from history. The following
Core-exclusive markers are also absent remotely:

- `public.studybook_set_updated_at()`
- all 14 Core-named indexes
- all 12 `studybook_set_updated_at` triggers

Later-only `document_chunks`, `certificates`, `quota_reservations`, pgvector,
RAG RPC and quota RPCs are absent. Core is therefore physically **ROLLED BACK**,
not partially applied or applied-but-unrecorded.

### Core Statement Reconciliation

Supabase CLI statement indices include `BEGIN` at index 0:

| CLI index | Executable statement | Post-bridge | Remote observation | Classification / replay |
| ---: | --- | --- | --- | --- |
| 0 | `BEGIN` | No open Core transaction | No persisted Core effects | Rolled back / transaction control |
| 1 | Create `pgcrypto` if absent | Extension already existed | Present in `extensions` | Pre-existing / safe idempotent |
| 2 | Create/replace `studybook_set_updated_at()` | Absent | Absent | Not executed persistently / safe idempotent |
| 3 | Create `workspaces` if absent | Present | Present | Pre-existing / safe with proven bridge shape |
| 4 | Create `documents` if absent | Present | Present | Pre-existing / safe with proven bridge shape |
| 5 | Create `study_results` if absent | Present | Present | Pre-existing / safe with proven bridge shape |
| 6 | Create `audiobooks` if absent | Present | Present | Pre-existing / safe with proven bridge shape |
| 7 | Create `chats` if absent | Present | Present | Pre-existing / safe with proven bridge shape |
| 8 | Create `messages` if absent | Present | Present | Pre-existing / safe with proven bridge shape |
| 9 | Create `user_subscriptions` if absent | Present/reconciled | Present/reconciled | Pre-existing / safe with proven bridge shape |
| 10 | Create `user_usage_events` if absent | Present/reconciled | Present/reconciled | Pre-existing / safe with proven bridge shape |
| 11 | Create `educator_courses` if absent | Present | Present | Pre-existing / safe with proven bridge shape |
| 12 | Create `educator_students` if absent | Present | Present | Pre-existing; no observable effect / safe with precondition |
| 13 | Create `educator_attendance` if absent | Present | Present | Pre-existing / safe with proven bridge shape |
| 14 | Create `educator_gradebook` if absent | Present | Present | Pre-existing / safe with proven bridge shape |
| 15 | Create `educator_question_banks` if absent | Present | Present | Pre-existing / safe with proven bridge shape |
| 16 | Create `educator_rubrics` if absent | Present | Present | Pre-existing / safe with proven bridge shape |
| 17 | Create `workspaces_owner_created_idx` | Absent | Absent | Not executed / safe idempotent |
| 18 | Create `documents_owner_uploaded_idx` | Absent | Absent | Not executed / safe idempotent |
| 19 | Create `documents_workspace_idx` | Absent | Absent | Not executed / safe idempotent |
| 20 | Create `study_results_owner_updated_idx` | Absent | Absent | Not executed / safe idempotent |
| 21 | Create `audiobooks_owner_updated_idx` | Absent | Absent | Not executed / safe idempotent |
| 22 | Create `chats_owner_created_idx` | Absent | Absent | Not executed / safe idempotent |
| 23 | Create `messages_chat_created_idx` | Absent | Absent | Not executed / safe idempotent |
| 24 | Create `usage_events_owner_type_created_idx` | Absent | Absent | Not executed / safe idempotent |
| 25 | Create `educator_courses_owner_idx` | Absent | Absent | Not executed / safe idempotent |
| 26 | Create `educator_students_owner_idx` | Absent | Absent | Not executed / safe idempotent |
| 27 | Create `educator_attendance_owner_idx` | Absent | Absent | Not executed / safe idempotent |
| 28 | Create `educator_gradebook_owner_idx` | Absent | Absent | Not executed / safe idempotent |
| 29 | Create `educator_question_banks_owner_idx` | Absent | Absent | Not executed / safe idempotent |
| 30 | Create `educator_rubrics_owner_idx` | Absent | Absent | Not executed / safe idempotent |
| 31 | Drop/recreate 12 update triggers | No Core triggers | Zero Core triggers | Not executed / safe with function/table preconditions |
| 32 | `COMMIT` | Not applicable | No Core effect committed | Not reached persistently |

`educator_students` retains its post-bridge legacy shape: text primary key,
non-null UUID owner with Auth cascade FK, non-null course/name, nullable
student ID/email/phone/payload/timestamps, legacy owner-course index and no Core
trigger. Because the table pre-existed, statement 12 was a PostgreSQL no-op
whether or not the server received it.

Core itself contains explicit `BEGIN`/`COMMIT`. Supabase CLI `2.116.0` parses
the file and pipelines all statements on one `pgx` connection; it appends the
migration-history insert after the file statements. Consequently the Core DDL
is transactional, while an explicit file `COMMIT` precedes the separate history
insert. Missing history alone would not prove rollback, but the absent function,
indexes and triggers prove that Core did not commit in this incident.

### Data, Storage And P0

- Active public rows: 609
- Private quarantine rows: 359
- Preserved total: 968
- Duplicate owner/resource groups: 0
- Quarantine duplicate groups: 0
- Active Auth-owner or relation orphans: 0
- `studybook-documents` objects: 37
- `studybook-documents` public: false
- Public tables with RLS: 14 of 14
- Anonymous table CRUD privileges: zero
- Anonymous REST access: denied (`401`) on all 14 tables
- Anonymous Storage list: `200`, zero visible objects
- Anonymous read of a known private object: denied (`400`)
- Public and Storage policies at this post-bridge point: zero
- Service role retains RLS bypass authority

The bridge transformed the original 968 rows exactly as rehearsed. It did not
regress containment. With zero authenticated policies, direct authenticated
database/Storage access also remains fail-closed until the pending RLS migration
is successfully applied; the backend service-role owner-filter path remains the
current application boundary.

### Recovery Simulation And Decision

A disposable stack restored the exact W6-R2 backup, applied current P0
containment, then applied and recorded only the bridge through the normal local
migration mechanism. That reconstructed state matched production: bridge-only
history, 609 active, 359 quarantined, absent Core function and zero Core indexes.

The normal migration mechanism then applied only these pending versions:

1. `20260828000100`
2. `20260829000100`
3. `20260831000100`
4. `20260901000100`
5. `20260907000100`

Result: pass. Final history contained all six versions; active/quarantine counts
remained 609/359; 17 of 17 product tables had RLS; all 14 Core indexes and 12
triggers existed; both buckets were private; pgvector/RAG and all three quota
RPCs existed. Four SQL contracts, DB lint and all 10 atomic-quota integration
tests passed.

Recovery branch: **A - Core fully rolled back**. A normal `db push` retry is a
technically proven candidate and should list only the five pending migrations.
W6-M1 does not authorize that retry. No migration repair or reconciliation
migration is required before a separately approved retry.

The known P2 foreign/nonexistent-chat response mapping remains outside this
reconciliation: it returns `500` instead of a human `403/404`, with no foreign
message disclosure demonstrated. W6-M1 did not modify or retest that endpoint.

### W6-M1 Regression

- Backend full suite: 177 passed, 10 skipped
- Security-focused backend suite: 65 passed
- Atomic-quota disposable integration: 10 passed
- Flutter: 144 passed
- Flutter analyze: no issues
- Python compile check: pass
- RLS, persistence, ownership-backfill and atomic-quota SQL contracts: pass
- Supabase DB lint on the recovered disposable stack: no schema errors
- W6-M1 read-only audit SQL syntax: pass
- First-party secret scan and `git diff --check`: pass

The repeatable read-only catalog checks are in
`docs/release/sql/W6_M1_REMOTE_READ_ONLY_AUDIT.sql`.

## W6-M0 Post-Containment Migration Rehearsal

W6-M0 used only disposable local Supabase projects. It performed no remote SQL,
`db push`, migration repair, reset, Auth change, Storage change, deployment or
DNS operation. Rehearsal base commit:
`0b24f37133fb837b83c1c8a2d553cc3ba948244c`.

### Recovery Inputs

The proven private backup at
`$HOME/StudyBookAI_Backups/supabase_2026-09-08` was revalidated before use:

| Artifact | SHA-256 |
| --- | --- |
| `schema.sql` | `604f03d383cb2dcb8a1e43c9d4b1c0dadabdbe143bbada4181792a0aea486c3f` |
| `data.sql` | `16bc8ca49af3d5d3e2770790f32e6b725296501551ea3d5f0d19801a82586d99` |
| `roles.sql` | `4350a72b5ec109888e740c17f3eb4da2fcd95ab73af26499538ed0bf615db543` |
| Storage manifest | `cc230b0f66d188e71d4271f352b48e00a32b4273ca60ee84c93f0f0800f8a21e` |

The Storage backup contains 37 files, 42,288,843 bytes and 37 manifest entries.
No private object name or content was added to this evidence.

### Migration Set

Exactly six migration files were present, in timestamp order:

| Version | Migration | SHA-256 |
| --- | --- | --- |
| `20260827000100` | `remote_legacy_reconciliation` | `b8e0b9da76aff256367643d13900a38eb8b8545b2cb83d41f3f1733f3b340158` |
| `20260828000100` | `studybook_core_schema` | `e0b09288bea5524ae9395b6009e969bf3d39940f8b9f99320e3e93721ced5b8c` |
| `20260829000100` | `studybook_rls_security` | `8cb4115415525e5bd923a03182ee8ad4dbbfd72b4814b5d54df815a3e14e4bd4` |
| `20260831000100` | `production_persistence` | `4ade8f29920851b70654144d9331e2f9dd5c9412a1556fa5b8247bd03debea15` |
| `20260901000100` | `document_ownership_hardening` | `1021c10b23c9cdea868acda3de8cb149a6d24f7d39378f434641b072c0ea6cad` |
| `20260907000100` | `atomic_free_quota` | `5c6f26220a4d4da1af826775869cccec6f33b1b11388c8ff46a6b5d2f0679ccb` |

### Restored Post-P0 Rehearsal

The logical backup was restored into a dedicated local stack with migrations
disabled. The current containment artifact was then applied once, reproducing
the remote post-P0 state:

- Public legacy rows: 968
- `studybook-documents` Storage metadata objects: 37
- Product tables with RLS: 14 of 14
- Critical `workspaces`, `chats` and `messages` RLS: enabled
- Anonymous product-table privileges: zero
- Anonymous REST access to all 14 tables: denied (`401`)
- Anonymous Storage listing: `200`, zero visible objects
- Anonymous Storage read/insert/update/delete: denied (`400`)
- Service-role database and disposable Storage CRUD: pass
- Post-probe Storage objects: 37
- Migration history before the chain: absent/empty

The normal local migration mechanism then applied all six files in one command,
without manual SQL between migrations. The resulting history contains exactly
the six expected versions in order.

Data transformation matched the prior rehearsal exactly:

- Active legacy rows: 609
- Private quarantine rows: 359
- Total preserved: 968
- Unexpected dropped rows: 0
- Unexpected duplicate groups: 0
- Unexpected active orphan rows: 0

`educator_rubrics` remains present in the final schema, is owner-scoped, has an
Auth owner FK and is protected by the versioned RLS policy set.

### Final Schema And Security

The final schema contains all 17 required product tables. Verification found:

- RLS enabled: 17 of 17 tables
- Public StudyBook policies: 49
- StudyBook Storage policies: 4
- Auth owner foreign keys: 16
- Updated-at triggers: 12
- `documents.user_id`: present and non-null
- `workspaces.updated_at`: present and non-null
- `vector` extension and HNSW chunk index: present
- Server-only RAG RPC: present
- Quota reservation table and three privileged quota RPCs: present
- `studybook-documents` and `studybook-private-artifacts`: private
- RLS, persistence/multiuser, quota and ownership-backfill SQL contracts: pass
- Student A/B synthetic API isolation for workspaces, documents, chats, study
  results and Storage: pass in both directions
- `user_metadata` Teacher spoof: denied (`403`)
- Service-role database authority: pass

The atomic quota integration suite passed all 10 tests, including concurrent
last-slot acquisition, idempotency, failed-batch atomicity, reservation release,
stale recovery, cross-user isolation, UTC period accounting and denial of
authenticated-client quota mutation.

### Clean Installation

A second disposable stack applied the same six files from zero through the
normal Supabase startup migration mechanism. Its history contains exactly the
same six versions; all 17 required tables have RLS; all four SQL contracts and
`supabase db lint` passed. Both disposable stacks are removed after evidence
capture.

### Regression

- Backend: 177 passed, 10 skipped
- Security-focused backend suite: 125 passed
- Atomic quota local integration: 10 passed
- Flutter: 144 passed
- Flutter analyze: no issues
- Supabase DB lint: no schema errors on restored and clean stacks
- Tracked privileged-value and high-confidence secret-pattern scans: pass

W6-M0 proves the migration chain locally. It does not authorize W6-M remote
execution. The exact separately approved command, stop and recovery sequence is
maintained in `SUPABASE_W6_M_EXECUTION_CHECKLIST.md`.

## W6-P0R Remote Security Closure

The authorized project owner applied the corrected emergency containment SQL
through Supabase SQL Editor. W6-P0R performed verification only; it did not run
the bridge, normal migrations, `db push`, migration repair or any additional
remote SQL.

Effective remote evidence:

- Anonymous REST access to all 14 private product tables: denied (`401`)
- Anonymous Storage listing: `200` with zero visible objects
- Anonymous Storage read/insert/update/delete: denied (`400`)
- Service-role database access: pass, 968 aggregate rows
- Service-role Storage upload/read/update/delete: pass
- Storage before/after disposable probe: 37 / 37 objects
- Remaining disposable security-probe objects: 0
- Student A/B own subscriptions: one each
- Student A -> Student B subscription: zero rows
- Student B -> Student A subscription: zero rows
- Student B -> Student A study result: absent
- Student identities -> educator snapshot: `403`
- Trusted Teacher -> educator snapshot: `200`
- Data loss or count drift: none detected
- Backend regression: 177 passed, 10 skipped
- Security-focused backend regression: 125 passed
- Flutter regression: 144 passed
- Flutter analysis: no issues
- Tracked privileged-value and high-confidence secret-pattern scans: pass

The foreign-chat status defect is independently reproducible: an owner receives
`200`, while another authenticated user receives `500` for the same chat
messages URL. No private messages are returned. This remains a P2 response
mapping issue, not an open confidentiality P0.

All current migrations and the ownership backfill were also revalidated in a
new disposable local Supabase stack. RLS, durable persistence/multiuser,
atomic-quota and ownership-backfill contracts passed; `db lint` reported no
schema errors. The stack was stopped and deleted afterward.

Supabase CLI read-only catalog, Security Advisor and migration-history requests
were denied by Management RBAC (`403`). The owner confirmed that only the
containment artifact was applied. The previously empty remote migration history
is therefore operationally unchanged, while Advisor status remains explicitly
not independently verified.

## W6-P0.1 Storage Privilege Reconciliation

The first authorized remote SQL Editor attempt aborted safely with
`W6-P0 anonymous Storage privilege remains`. Inspection after the error found
RLS still disabled on `workspaces`, `chats` and `messages`, zero Storage
policies and the private document bucket unchanged. This confirms transaction
rollback; no containment mutation persisted remotely.

A new disposable restore reproduced the exact state: 968 product rows, 37
Storage metadata objects, RLS enabled on `storage.buckets` and
`storage.objects`, zero Storage policies, a private `studybook-documents`
bucket and Supabase baseline grants for API roles. The Storage owner/grantor is
`supabase_storage_admin`; the SQL Editor's `postgres` role cannot reliably
revoke grants issued by that owner. The former `has_table_privilege()` assertion
therefore measured a platform prerequisite, not effective anonymous object
access.

Effective local Storage API probes showed:

- Bucket enumeration: HTTP 200 with zero visible buckets
- Object listing: HTTP 200 with zero visible objects
- Private object read/insert/update/delete: denied with HTTP 400
- Service-role upload/read/update/delete: HTTP 200

The corrected emergency artifact retains baseline Storage grants and asserts
RLS on both Storage tables, no `anon` RLS bypass, no policy applicable to
`anon`/`public`, private bucket state and service-role viability. It passed
twice locally. All 14 private product tables denied anonymous REST access with
HTTP 401. Student A/B subscription ownership, backend library isolation,
Student/Teacher authorization and metadata-spoof denial passed. Rows remained
968 and Storage returned to 37 objects after the temporary probe.

W6-P0.1 itself made no remote mutation. This paragraph records the historical
state before the later successful owner-operated application documented in
W6-P0R above.

## W6-P0 Restore And Containment Gate

W6-P0 restored the complete W6-R2 database backup into an isolated disposable
Supabase stack. The restore reproduced 14 StudyBook tables, all 968 rows, five
Auth users and 37 Storage metadata records. Every one of the 37 physical
Storage objects revalidated against the private manifest, totaling 42,288,843
bytes. Recovery integrity and restore drill: `PASS`.

The reviewed emergency artifact
`docs/release/sql/W6_P0_REMOTE_CONTAINMENT.sql` was applied twice locally. It
enabled RLS on all 14 legacy product tables and removed anonymous product-table
privileges. Storage baseline grants remain intentionally protected by existing
Storage RLS, zero anonymous policies and a private bucket. Anonymous REST
probes were denied for all product tables; effective private Storage access was
denied; service-role access retained all 968 rows. Row and Storage counts were
unchanged. QA Student A/B subscriptions were owner-isolated, Teacher
authorization remained server-controlled and a `user_metadata` privilege
spoof was denied.

The pre-baseline bridge now exists at
`supabase/migrations/20260827000100_remote_legacy_reconciliation.sql`. Against
another restored snapshot, the bridge followed by all five normal migrations
completed in order without manual intervention. It preserved all 968 legacy
records as 609 active owner-valid rows plus 359 private quarantined legacy
records. Unexpected loss was zero. The final local schema has 17 RLS-enabled
product tables, 49 public policies, four Storage policies, validated ownership
FKs, `educator_rubrics`, pgvector persistence and atomic quota RPCs. The RLS,
persistence and quota SQL contracts passed against both restored and clean
migration stacks.

Historical pre-containment counts matched 968 rows and 37 Storage objects.
Anonymous visibility was 36 workspaces, 46 chats and 118 messages. The
first remote containment transaction aborted and rolled back on its obsolete
Storage-grant assertion; W6-P0.1 performed no remote mutation. No bridge,
normal migration or history repair completed. This state is superseded by the
successful containment and W6-P0R verification above. Full evidence and the
safe apply/rollback boundary are in
`docs/security/W6_P0_REMOTE_CONTAINMENT.md`.

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
- Expected migrated public policies: 49
- Expected migrated Storage policies: 4

Remote-only schema drift includes `educator_rubrics` and its index. The table is
now incorporated into the reviewed bridge, core schema and RLS source of truth,
but remains unapplied remotely. Material legacy drift includes different
indexes, missing ownership foreign keys, missing update triggers, nullable
owner columns and incompatible key shapes.

### Migration Decision Table

| Migration | Remote reality | Future action |
| --- | --- | --- |
| `20260828000100` core | **CONFLICTING**. All 13 table names exist, but `documents.user_id` and `workspaces.updated_at` are absent; owner FKs/triggers are absent; defaults/nullability/indexes differ; `user_usage_events.id` and `user_subscriptions` keys conflict. | RECONCILIATION REQUIRED |
| `20260829000100` RLS | **CONFLICTING**. One legacy policy exists instead of 49; three core tables have RLS disabled; no Storage policies exist; the legacy policy trips the migration stop guard. | STOP / RECONCILIATION REQUIRED |
| `20260831000100` persistence | **ABSENT**. `document_chunks`, `certificates`, RAG function/indexes and `studybook-private-artifacts` are absent. | APPLY AFTER BASELINE RECONCILIATION |
| `20260901000100` ownership | **CONFLICTING**. The required `documents.user_id` column does not exist, so the migration cannot execute against the current schema. | RECONCILIATION REQUIRED |
| `20260907000100` atomic quota | **ABSENT**. Reservation table, usage-event FK/indexes and all three quota RPCs are absent. | APPLY AFTER BASELINE RECONCILIATION |

No migration is safe to repair as applied. A blind `supabase db push --linked`
would fail or leave material drift and must not run.

### Historical P0 Security-Relevant Drift

The W6-R2 catalog snapshot showed RLS disabled on `workspaces`, `chats` and
`messages` while `anon` and `authenticated` had broad table grants. Read-only
anonymous `HEAD` probes confirmed:

| Table | Anonymous visible rows |
| --- | ---: |
| `workspaces` | 36 |
| `chats` | 46 |
| `messages` | 118 |

No row body was downloaded and no write probe was attempted. The grants imply a
potential mutation risk, but only anonymous SELECT visibility was directly
verified. The later authorized containment and W6-P0R effective-access gate
closed this confidentiality P0 without applying the full migration chain.

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
- Pre-baseline reconciliation migration: created and locally verified
- Disposable restore rehearsal: completed and passed
- Safe to repair migration history: no
- Safe to apply remaining migrations: no
- Ready for W6-M planning: yes; execution still requires separate approval

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
