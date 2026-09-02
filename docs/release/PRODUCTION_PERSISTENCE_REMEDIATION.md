# Production Persistence Remediation

Status: `LOCAL INTEGRATION PASS - REMOTE MIGRATION AND BACKFILL NOT APPLIED`

This document is the 7F-S2 filesystem-write inventory and deployment gate. No
remote Supabase project was changed during this sprint.

## Write Inventory And Classification

| Previous write | Classification | Production disposition |
| --- | --- | --- |
| `backend/chroma_db` (`chroma.sqlite3` and indexes) | Persistent user data, security sensitive | Replaced by owner-scoped `public.document_chunks` with pgvector |
| `backend/app/database/document_registry.json` | Persistent user data, security sensitive | Replaced by owner-scoped `public.documents` queries |
| `backend/app/audio/*.mp3` | Persistent user data, private | Replaced by private Storage objects under `<user_id>/audio/` |
| `backend/storage/audiobook_audio/*.mp3` | Persistent user data, private | Replaced by private Storage objects under `<user_id>/audiobook/` |
| `backend/data/certificates.json` | Persistent user data, security sensitive | Replaced by `public.certificates` |
| `backend/uploads` and import files | Temporary processing data | OS temporary directory in production, deleted in `finally` |
| temporary TTS files | Temporary processing data | OS temporary file, uploaded privately, deleted in `finally` |
| `backend/logs/usage_events.jsonl` | Operational telemetry, regenerable | Structured process logging in production; local JSONL remains development-only |
| PDF/DOCX/PPTX exports | Regenerable generated artifact | In-memory response; no production filesystem source of truth |

Chroma, local JSON and local audio remain explicit development/test adapters.
Production branches do not create their directories and cannot use them as a
fallback.

## Durable Production Contract

Production startup fails closed unless all of these values exist:

```text
SUPABASE_URL
SUPABASE_ANON_KEY
SUPABASE_SERVICE_ROLE_KEY
SUPABASE_STORAGE_BUCKET=studybook-documents
SUPABASE_PRIVATE_ARTIFACTS_BUCKET=studybook-private-artifacts
```

The private artifacts bucket is created with `public=false`. The backend uses
the service role server-side and serves bytes only after authenticated owner
checks. Object paths reject separators, traversal segments and unsupported
categories. No Render persistent disk is part of the design.

## Database Migration

The reproducible migration chain is:

```text
supabase/migrations/20260828000100_studybook_core_schema.sql
supabase/migrations/20260829000100_studybook_rls_security.sql
supabase/migrations/20260831000100_production_persistence.sql
supabase/migrations/20260901000100_document_ownership_hardening.sql
```

It creates `public.document_chunks`, service-role-only vector retrieval,
`public.certificates`, and the private `studybook-private-artifacts` bucket.
The Flutter client receives no direct grants to these resources.

## Backfill Plan

Do not copy repository or container files blindly. Before production cutover:

1. Export a read-only inventory of local registry, Chroma collections, audio,
   AudioBook rows and certificates.
2. Resolve every item to one verified Supabase Auth `user_id`. Quarantine any
   item without deterministic ownership; never assign it heuristically.
3. Confirm each document exists in private document Storage and
   `public.documents` before inserting its chunks.
4. Re-extract and re-embed from the private source document where possible,
   instead of importing Chroma SQLite internals.
5. Upload voice audio to `<user_id>/audio/<filename>` and chapter audio to
   `<user_id>/audiobook/<filename>`, then verify authenticated playback.
6. Insert certificates using their existing ID and verified owner.
7. Compare source/target counts per user and run retrieval, playback and
   Student A versus Student B ownership checks.
8. Keep the source snapshot read-only until retention is approved. Delete it
   only through an authorized migration procedure.

The deterministic document-owner backfill is versioned at
`supabase/backfills/document_ownership_backfill.sql`. Run it transactionally
and audit unresolved/conflicting rows before ownership hardening. It never
deletes records and infers ownership only from an owned workspace or a valid
Auth UUID at the private Storage path prefix.

Backfill must be idempotent. `document_chunks` upserts on
`(user_id, document_id, chunk_index)`. A failed item must not mark the overall
migration complete.

## Failure And Deletion Lifecycle

- Production upload fails if Storage or its database row fails.
- If the database row fails after object upload, object and RAG chunks roll back.
- Audio generation fails rather than returning a URL when durable upload fails.
- Account deletion inventories document and private artifact objects first,
  deletes owner-scoped RAG/certificate rows, and deletes Auth last.
- Temporary files are removed on success and failure.

## Deployment Gate

Render deployment remains blocked until the migration is applied, the bucket
is verified non-public, required owned legacy data is backfilled, and restart
plus multiuser tests pass against the real production project.

## 7F-S3 Local Evidence

On 2026-09-01, Supabase CLI `2.116.0` applied the complete chain to an empty
disposable local stack. The RLS, Storage, pgvector, ownership-spoof and Teacher
entitlement contracts passed. A real local document object, private audio
object, document row, StudyResult, AudioBook, vector and certificate survived
a restart of Postgres, REST, Storage and Auth. Student B could not read Student
A data. The account-deletion service then removed rows, objects and identities.
The document ownership backfill was run twice against synthetic legacy rows and
remained idempotent. Remote readiness remains conditional on the runbook.
