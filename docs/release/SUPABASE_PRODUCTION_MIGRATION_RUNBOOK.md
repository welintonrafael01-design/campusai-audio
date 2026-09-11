# Supabase Production Migration Runbook

Status: `W6-B POST-MIGRATION RECOVERY POINT READY`

## W6-M3 Canonical Production State

The remote project `olegevhncmblxngurclt` now contains all six reviewed
migrations from `20260827000100` through `20260907000100`. W6-M3 verified the
final schema, 609 active plus 359 quarantined rows, 37 unchanged private
document objects, 17 of 17 product tables under RLS, private artifact Storage,
pgvector/RAG, atomic quota, QA multiuser isolation and service-role viability.
P0 remains closed and no P1 is open.

The migration window is closed. Do not rerun the bridge or any later migration,
do not use migration repair, and never run `db reset --linked`. The W6-M1 retry
instructions below are retained only as incident history and are no longer an
operator sequence for the current remote state.

Two non-blocking P2 items remain tracked: foreign/nonexistent chat requests can
map to `500` without exposing messages, and Supabase Auth leaked-password
protection is disabled. Address them in separate, reviewed remediations.

### Post-Migration Recovery Point - Completed

W6-B created and verified the canonical post-migration recovery point at:

`$HOME/StudyBookAI_Backups/supabase_2026-09-11_post_migration_20260911T040141Z`

It contains protected `schema.sql`, `data.sql`, `roles.sql`, a private physical
copy of both Storage buckets, a private object manifest, a six-version
migration-history capture and a local hash inventory. Directory permissions are
`700` and file permissions are `600`. None of these artifacts is tracked by
Git.

The recovery point restores to 17 product tables, 609 active plus 359
quarantine rows and 37 document-object metadata rows. All 37 physical document
objects match their pre-migration path, size and content hashes; the private
artifacts bucket was empty at capture. A disposable local restore passed and
was removed.

The prior `$HOME/StudyBookAI_Backups/supabase_2026-09-08` directory remains the
verified **pre-migration legacy recovery point** and must not be overwritten or
confused with this canonical post-migration backup. Keep both recovery points
private, preserve their current permissions and periodically repeat a
disposable restore-readiness test under an approved backup window.

## W6-M1 Incident And Safe Resume Boundary

The first authorized W6-M `db push` applied and recorded only
`20260827000100_remote_legacy_reconciliation`. The connection failed while the
CLI reported Core statement index 12 (`educator_students`). Core was not added
to migration history and no automatic retry, repair, reset or later migration
was run.

Read-only remote reconciliation proves Core physically rolled back: its update
function, all 14 named indexes and all 12 update triggers are absent. Only the
bridge is recorded; all later-only persistence, RAG and quota objects are
absent. Data remains exactly 609 active plus 359 private quarantined rows, and
Storage remains 37 private objects. P0 containment remains effective.

The exact state was reconstructed from backup in a disposable stack. Applying
the normal pending chain from Core through atomic quota passed without rerunning
the bridge. This selects recovery branch A: normal retry is technically safe,
but is **not authorized by W6-M1**.

For a separately approved retry:

1. Reverify remote history contains only `20260827000100`.
2. Reverify 609 active + 359 quarantine = 968 and 37 private objects.
3. Run a dry-run without `--include-all`; it must list exactly the five pending
   versions `20260828000100` through `20260907000100`.
4. Stop on any drift. Do not rerun the bridge and do not use migration repair.

Use `docs/release/sql/W6_M1_REMOTE_READ_ONLY_AUDIT.sql` for catalog-only
reconciliation and `SUPABASE_W6_M_EXECUTION_CHECKLIST.md` for the current gate.

The authorized W6 preflight on 2026-09-08 identified the intended project as
`olegevhncmblxngurclt` and completed read-only REST, Storage and QA identity
checks. The migration stopped before any schema mutation because the operator
environment had no Supabase Management session, database credential or
provider-backup evidence. See `SUPABASE_PRODUCTION_MIGRATION_EVIDENCE.md`.

W6-R2 subsequently verified a complete manual logical backup and a private
physical copy of every Storage object, but proved that the empty remote
migration history does not represent an empty database. At that snapshot, the
remote legacy schema conflicted with the repository baseline and had a P0 RLS
exposure. W6-P0R later closed that exposure. The pre-baseline reconciliation
migration is now created and locally proven, but `migration repair` and remote
`db push` remain prohibited until the separately approved W6-M retry window.

W6-P0 completed that disposable restore rehearsal. Recovery artifacts,
emergency containment, the pre-baseline bridge, the five-migration chain and
all SQL contracts pass locally. The first remote SQL Editor transaction then
failed closed on an obsolete Storage-grant assertion and rolled back. W6-P0.1
corrected and revalidated that assertion locally. An authorized owner then
applied the corrected containment artifact, and W6-P0R verified all 14 private
tables, private Storage, QA isolation, Teacher authorization, service-role
viability and unchanged 968-row/37-object counts. Do not substitute a
service-role key for database/Management authority.

## W6-M0 Rehearsal Result

The exact post-containment legacy snapshot was recreated locally from the
verified W6-R2 backup: 968 public rows, 37 Storage metadata objects, 14 of 14
product tables under RLS and effective anonymous DB/Storage access denied. The
normal local migration mechanism then applied the bridge and five migrations in
timestamp order without intermediate SQL.

The migration history contains exactly all six expected versions. Transformation
preserved 609 active plus 359 quarantined rows, with no unexpected loss,
duplicates or active orphans. The final schema, RLS, Storage, owner isolation,
pgvector/RAG, atomic quota and clean-install gates pass. This evidence permits
planning a separately authorized W6-M production window; it does not authorize
the remote command itself.

Use `SUPABASE_W6_M_EXECUTION_CHECKLIST.md` as the operator checklist. Never use
`supabase db reset --linked`. Do not use migration repair before the six SQL
files have actually executed and their recorded history has been verified.

## Emergency P0 Containment Window - Completed

The authorized owner applied only
`docs/release/sql/W6_P0_REMOTE_CONTAINMENT.sql`. W6-P0R verified all anonymous
product-table access and effective private Storage list/read/write/update/delete
access are denied; QA A/B remain isolated; Student cannot call Teacher
endpoints; trusted Teacher can; service-role operations pass; rows remain 968;
and Storage remains 37. Baseline Storage grants alone are not an access failure
when the effective API gate passes.

Do not reapply containment or the bridge. Do not run `db push` or
`migration repair` until a separately approved W6-M retry window.

This runbook is for a separately approved production window. The 7F-S3 sprint
used only the disposable local project `studybook-ai-7f-s3-local`; it did not
link, inspect or modify remote Supabase.

## Stop Conditions

Stop before any write when the project reference is ambiguous, backup is not
verified, unknown policies exist, ownership cannot be resolved, a bucket is
public, pgvector is unavailable, or Student A/B evidence cannot be captured.
Never place service-role credentials in Flutter, shell history, logs or this
repository.

## 1. Approval And Backup

1. Obtain named release, security and data-owner approval.
2. Freeze schema-changing deploys and record current backend build SHA.
3. Create and verify provider-managed database and Storage backups.
4. Export sanitized catalogs for tables, columns, constraints, indexes, grants,
   policies, extensions and bucket privacy. Do not export user content into the
   repository.
5. Record per-user row/object counts through an approved private audit channel.

The provider backup status must be verified through an authenticated Supabase
Management session or another approved operator channel. A service-role API key
is not a database backup credential and a PostgREST export is not an acceptable
schema, Auth, policy and Storage recovery point.

For W6-R2, `supabase backups list` reported WAL-G enabled but no listed physical
backup. The approved fallback recovery point consists of the Supabase CLI
logical schema/data/roles dumps plus a byte-for-byte private Storage download.
The public-table and Storage metadata counts in the logical dump match the
remote aggregate counts, and the physical object manifest records every object
size and SHA-256 outside the repository.

## W6-R2 Reconciliation Stop

At the W6-R2 snapshot, the remote database had all 13 original core table names
plus the legacy rubric table, but it was not materially equivalent to
`20260828000100`:

- `documents.user_id` and `workspaces.updated_at` are absent.
- Owner foreign keys and the update trigger/function are absent.
- `user_usage_events.id` is UUID remotely but bigint in the repository.
- `user_subscriptions` has a different primary-key shape and an extra `id`.
- Multiple nullability, default, constraint and index definitions differ.
- `educator_rubrics` exists remotely. W6-P0 added it to the reviewed bridge,
  core migration and RLS source of truth; those changes remain local only.

The historical RLS baseline was also conflicting. Only one legacy public policy
existed, there were no Storage policies, and `workspaces`, `chats` and
`messages` had RLS disabled while `anon` and `authenticated` retained broad
table grants. Read-only anonymous count probes confirmed visibility of all 36
workspaces, 46 chats and 118 messages. The W6-P0R containment verification now
supersedes that exposure; no row contents were read.

The legacy policy `Users can read their own subscription` is not accepted by
the RLS migration's unknown-policy guard. The current migration chain therefore
must not be pushed blindly.

## Historical Pre-Baseline Requirements - Completed Locally

W6-M required a reviewed migration ordered before
`20260828000100_studybook_core_schema.sql`, for example
`20260827000100_remote_legacy_reconciliation.sql`. It must be a no-op on a fresh
database and must, on the legacy schema:

1. Contain anonymous access immediately by enabling fail-closed RLS and
   revoking unintended grants before broader reconciliation.
2. Add and safely backfill missing ownership columns without guessing owners.
3. Move unresolved, duplicate or Auth-orphaned rows into the private versioned
   quarantine without guessing ownership or discarding record JSON.
4. Reconcile keys, foreign keys, nullability, defaults and index compatibility
   while accounting for active plus quarantined legacy rows.
5. Resolve the UUID/bigint usage-event key conflict through an explicitly
   reviewed compatibility strategy.
6. Version the existing `educator_rubrics` table and its security policy.
7. Remove or replace the legacy subscription policy only after its behavior is
   represented by the repository policy.

That bridge was tested first against a disposable restore of the W6-R2 logical
and Storage backup. No migration may be marked as applied before its SQL has
actually executed through the normal migration mechanism.

The bridge now exists, passes both a restored post-containment rehearsal and a
clean migration stack, and is the only version recorded remotely after the
failed W6-M attempt. Its rehearsal preserved 609 active plus 359 private
quarantined rows, exactly matching the original 968. The post-incident retry
remains separately gated and is not authorized by W6-M1. The concise operator
sequence is in `SUPABASE_W6_M_EXECUTION_CHECKLIST.md`.

For reference, the required migration operations are:

```bash
cd /Users/welintonmejia/Desktop/campusai-audio

test -f supabase/migrations/20260828000100_studybook_core_schema.sql
git diff --check

# History must contain only the already applied bridge.
supabase migration list --linked
supabase db push --linked --dry-run

# Stop unless dry-run lists exactly the five pending migrations from Core
# through atomic quota. This command still requires separate retry approval.
supabase db push --linked
```

Installed CLI `2.116.0` supports database-password authentication for
`migration list` and `db push`; `db query` does not expose a password flag. Do
not place a password in this file, Git, shell history or command output. Do not
run any `supabase migration repair` command for the current remote schema. The
remote commands above remain prohibited until the W6-M retry is separately
authorized.

## 2. Preflight And Comparison

Compare the remote catalogs with the expected chain, in order:

```text
20260827000100_remote_legacy_reconciliation.sql
20260828000100_studybook_core_schema.sql
20260829000100_studybook_rls_security.sql
20260831000100_production_persistence.sql
20260901000100_document_ownership_hardening.sql
20260907000100_atomic_free_quota.sql
```

Review every existing policy before migration. The RLS migration deliberately
aborts on unknown public or Storage policies. Confirm `vector` support,
`storage.objects` RLS, and the private bucket IDs `studybook-documents` and
`studybook-private-artifacts`.

## 3. Ownership And Content Backfill

Run the owner backfill only with a reviewed server-side database role and a
single transaction:

```bash
psql "$APPROVED_DATABASE_URL" \
  -v ON_ERROR_STOP=1 \
  --single-transaction \
  -f supabase/backfills/document_ownership_backfill.sql
```

The URL above is an operator-supplied secret and must never be committed or
printed. Quarantine unresolved/conflicting document rows; do not guess owners.
For Chroma, local audio or certificate legacy data, follow the owner-verified
inventory procedure in `PRODUCTION_PERSISTENCE_REMEDIATION.md`. Re-embed from
private source documents where possible. Upsert chunks by
`(user_id, document_id, chunk_index)` and compare source/target counts. Run the
backfill twice in staging to prove idempotence before production.

## 4. Migration

Apply migrations only through the approved CI/operator workflow after reviewing
its target project. Do not use an unreviewed local shell session. Capture each
migration version and sanitized result. Any ownership-hardening exception is a
stop condition, not permission to weaken `NOT NULL` or RLS.

## 5. Verification

Verify all required tables, constraints, triggers and HNSW index. Confirm both
buckets have `public = false`. Run the SQL contracts against a disposable clone
of production data, not directly against production fixtures.

In production, use dedicated QA identities to verify:

1. Student A can create/read/delete its document and result.
2. Student B cannot list, retrieve, overwrite or delete A data or object paths.
3. `user_metadata` Teacher/Admin spoof has no effect.
4. Teacher access requires both trusted app metadata and active entitlement.
5. RAG retrieval returns only the authenticated owner's chunks.
6. Private audio restores after backend restart and has no public URL.
7. Account deletion removes DB rows and Storage objects before Auth identity.
8. Missing durable configuration makes production startup fail closed.
9. Free quota RPCs allow exactly one final concurrent slot, release failed
   operations and deny direct authenticated-client execution.

Before deploying a backend that calls the quota RPCs, apply and verify
`20260907000100_atomic_free_quota.sql`. Deploying the backend first intentionally
fails Free quota-bearing operations closed with `quota_service_unavailable`.
Do not temporarily restore count-then-insert behavior to bypass that gate.

## 6. Rollback

Stop application writes first. Preserve failure evidence and do not disable RLS
or make a bucket public. If rollback is approved, restore the verified backup
and prior backend release together, then re-run owner-isolation smoke tests.
Remove a policy only through a reviewed rollback migration that proves it was
created by this repository. Reconcile partial Storage/database writes before
reopening traffic.

## 7. Exit Evidence

The gate closes only with backup verification, schema diff, applied versions,
private bucket catalog, pgvector query evidence, backfill counts, Student A/B
denials, Teacher authorization, restart restoration, account deletion and a
named GO decision. Until then Render production remains blocked.
