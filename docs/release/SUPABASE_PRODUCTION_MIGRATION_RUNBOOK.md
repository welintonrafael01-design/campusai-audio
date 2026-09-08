# Supabase Production Migration Runbook

Status: `W6-P0 LOCAL VERIFIED - REMOTE CONTAINMENT REQUIRES PROJECT OWNER SESSION`

The authorized W6 preflight on 2026-09-08 identified the intended project as
`olegevhncmblxngurclt` and completed read-only REST, Storage and QA identity
checks. The migration stopped before any schema mutation because the operator
environment had no Supabase Management session, database credential or
provider-backup evidence. See `SUPABASE_PRODUCTION_MIGRATION_EVIDENCE.md`.

W6-R2 subsequently verified a complete manual logical backup and a private
physical copy of every Storage object, but proved that the empty remote
migration history does not represent an empty database. The remote legacy
schema conflicts with the repository baseline and has a P0 RLS exposure. Do
not use `migration repair` or `db push` until a reviewed pre-baseline
reconciliation migration has been created and tested against a disposable
restore of the backup.

W6-P0 completed that disposable restore rehearsal. Recovery artifacts,
emergency containment, the pre-baseline bridge, the five-migration chain and
all SQL contracts pass locally. The remote P0 transaction is still unapplied
because the current CLI Management identity receives HTTP 403 and the available
dashboard session is not authenticated. Do not substitute a service-role key
for database/Management authority.

## Emergency P0 Containment Window

Before the full migration window, an authorized project owner should apply only
`docs/release/sql/W6_P0_REMOTE_CONTAINMENT.sql` after repeating the 968-row and
37-object pre-counts. The transaction enables RLS on all observed product
tables, revokes `anon` product/Storage catalog access and asserts service-role
viability. It is minimal, idempotent and data-preserving.

```bash
cd /Users/welintonmejia/Desktop/campusai-audio

supabase db query --linked \
  --file docs/release/sql/W6_P0_REMOTE_CONTAINMENT.sql
```

Immediately verify all anonymous product tables and private Storage are denied,
QA A/B remain isolated, Student cannot call Teacher endpoints, trusted Teacher
can, backend service-role paths pass, rows remain 968 and Storage remains 37.
Do not run the bridge, `db push` or `migration repair` in this emergency window.

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

The remote database has all 13 original core table names plus the legacy rubric
table, but it is not materially equivalent to `20260828000100`:

- `documents.user_id` and `workspaces.updated_at` are absent.
- Owner foreign keys and the update trigger/function are absent.
- `user_usage_events.id` is UUID remotely but bigint in the repository.
- `user_subscriptions` has a different primary-key shape and an extra `id`.
- Multiple nullability, default, constraint and index definitions differ.
- `educator_rubrics` exists remotely. W6-P0 added it to the reviewed bridge,
  core migration and RLS source of truth; those changes remain local only.

The RLS baseline is also conflicting. Only one legacy public policy exists,
there are no Storage policies, and `workspaces`, `chats` and `messages` have RLS
disabled while `anon` and `authenticated` retain broad table grants. Read-only
anonymous count probes confirmed visibility of all 36 workspaces, 46 chats and
118 messages. This is a P0 confidentiality defect; no row contents were read.

The legacy policy `Users can read their own subscription` is not accepted by
the RLS migration's unknown-policy guard. The current migration chain therefore
must not be pushed blindly.

## Required Pre-Baseline Work

Before W6-M, create and review a migration ordered before
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

Test the bridge first against a disposable restore of the W6-R2 logical and
Storage backup. No existing migration is currently safe to mark as applied.

The bridge now exists and passes both a restored legacy rehearsal and a clean
migration stack. Its rehearsal preserved 609 active plus 359 private
quarantined rows, exactly matching the original 968. The future **full remote**
sequence remains separately gated and is not authorized by W6-P0:

```bash
cd /Users/welintonmejia/Desktop/campusai-audio

test -f supabase/migrations/20260827000100_remote_legacy_reconciliation.sql
git diff --check

# Local/disposable restore gate must pass before these remote checks.
supabase migration list --linked
supabase db push --linked --dry-run

# Stop unless dry-run orders the reviewed bridge first and then all five
# repository migrations. Re-capture aggregate counts and recovery evidence.
supabase db push --linked
```

Do not run any `supabase migration repair` command for the current remote
schema. The two remote commands above remain prohibited until W6-M is separately
authorized and the bridge is reviewed.

## 2. Preflight And Comparison

Compare the remote catalogs with the expected chain, in order:

```text
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
