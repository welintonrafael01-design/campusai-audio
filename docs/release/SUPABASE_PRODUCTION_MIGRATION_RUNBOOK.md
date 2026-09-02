# Supabase Production Migration Runbook

Status: `FUTURE CONTROLLED OPERATION - NOT EXECUTED`

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

## 2. Preflight And Comparison

Compare the remote catalogs with the expected chain, in order:

```text
20260828000100_studybook_core_schema.sql
20260829000100_studybook_rls_security.sql
20260831000100_production_persistence.sql
20260901000100_document_ownership_hardening.sql
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
