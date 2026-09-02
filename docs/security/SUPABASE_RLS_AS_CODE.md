# Supabase RLS As Code

Status: `LOCAL INTEGRATION VERIFIED - DEPLOYED PROJECT UNVERIFIED`

The versioned contract is:

- `supabase/migrations/20260828000100_studybook_core_schema.sql`
- `supabase/migrations/20260829000100_studybook_rls_security.sql`
- `supabase/migrations/20260831000100_production_persistence.sql`
- `supabase/migrations/20260901000100_document_ownership_hardening.sql`
- `supabase/tests/rls_policy_contract.sql`
- `supabase/tests/production_persistence_contract.sql`
- `supabase/tests/document_ownership_backfill_contract.sql`
- `backend/tests/test_supabase_rls_as_code.py`

On 2026-09-01 the complete chain was reset and tested in disposable local
Supabase CLI `2.116.0`. No remote Supabase project was linked or modified.

## Architecture And Authority

Flutter uses the Supabase public/anon key for Auth and session management. It
does not query application tables or Storage directly. Authenticated product
requests go to FastAPI with the bearer token. FastAPI validates the token with
the public client, derives the user ID from the verified identity, and performs
database/Storage operations through a backend-only service-role client.

The authority contract is:

- `auth.uid()` is the RLS user identity.
- `auth.jwt()->app_metadata.role` may establish Teacher identity.
- `user_metadata` is never privilege authority.
- `user_subscriptions` is server-managed plan/status authority.
- Teacher data requires both Teacher `app_metadata` and an active/trialing
  Teacher or Institution subscription.
- Client metadata never establishes Admin. Admin remains a backend allowlist
  decision; service role is the only privileged database boundary.
- Flutter plan/role caches are UX state, not authorization.

## Inventory And Policy Matrix

| Resource | Owner field/rule | Select | Insert | Update | Delete | Teacher/Admin boundary |
| --- | --- | --- | --- | --- | --- | --- |
| `workspaces` | `user_id = auth.uid()` | Owner | Owner; `WITH CHECK` owner | Existing and resulting owner | Owner | No cross-user or privileged client path |
| `documents` | Own `user_id`, workspace and/or `<uid>/documents/...` path | Owner, including legacy rows | Requires current `user_id`; every anchor must match | Result must retain current `user_id` and owned anchors | Owner | Adds the backend-expected `user_id` when absent; rejects owner/bucket spoof |
| `study_results` | `user_id = auth.uid()` | Owner | Owner | Existing and resulting owner | Owner | No cross-user resource sharing in current model |
| `audiobooks` | `user_id = auth.uid()` | Owner | Owner | Existing and resulting owner | Owner | Chapter audio is stored in the private artifacts bucket |
| `chats` | `user_id = auth.uid()` | Owner | Owner | Existing and resulting owner | Owner | Parent authority for messages |
| `messages` | Parent chat belongs to `auth.uid()` | Owner chat | Owner chat; direct client role limited to `user` | Denied | Owner chat | Assistant/system writes remain backend-only |
| `user_subscriptions` | `user_id = auth.uid()` | Owner | Denied | Denied | Denied | Plan/status and provider IDs remain server-managed |
| `user_usage_events` | `user_id = auth.uid()` | Owner | Denied | Denied | Denied | Usage accounting remains server-managed |
| `educator_courses` | `user_id = auth.uid()` | Authorized Teacher owner | Authorized Teacher owner | Authorized Teacher owner | Authorized Teacher owner | Requires `app_metadata` Teacher plus entitled subscription |
| `educator_students` | `user_id = auth.uid()` | Authorized Teacher owner | Authorized Teacher owner | Authorized Teacher owner | Authorized Teacher owner | Same dual Teacher gate |
| `educator_attendance` | `user_id = auth.uid()` | Authorized Teacher owner | Authorized Teacher owner | Authorized Teacher owner | Authorized Teacher owner | Same dual Teacher gate |
| `educator_gradebook` | `user_id = auth.uid()` | Authorized Teacher owner | Authorized Teacher owner | Authorized Teacher owner | Authorized Teacher owner | Same dual Teacher gate |
| `educator_question_banks` | `user_id = auth.uid()` | Authorized Teacher owner | Authorized Teacher owner | Authorized Teacher owner | Authorized Teacher owner | Same dual Teacher gate |
| `document_chunks` | `user_id`, server RPC parameter | Denied | Denied | Denied | Denied | Service-role-only pgvector persistence and retrieval |
| `certificates` | `user_id` | Denied | Denied | Denied | Denied | Backend-only persistence; public verification returns a reduced record by opaque ID |

The migration revokes application-table privileges from `anon`. It grants only
the operations represented above to `authenticated`. RLS remains defense in
depth even though the current Flutter application uses the backend API.

## Durable Server-Only Resources

- No `profiles` application table is referenced by production code.
- User identities live in Supabase Auth; no policy is created on `auth.users`.
- Certificates use owner-scoped `public.certificates`.
- RAG uses `public.document_chunks` with pgvector and a service-role-only RPC.
- Voice and AudioBook bytes use `studybook-private-artifacts` under
  `<user_id>/audio/` and `<user_id>/audiobook/`.
- Chroma, JSON and local audio remain development adapters only and are not a
  production source of truth.

## Storage

Both production buckets are private:

- `studybook-documents` permits direct authenticated access only to:

```text
<auth.uid()>/documents/<document_id>/<filename>
```

- `studybook-private-artifacts` has no `authenticated` policy or grant. FastAPI
  uses the server-side service role after checking the authenticated owner.

The row and object policies require the confirmed bucket. The object policy
also validates the authenticated prefix, `documents` namespace, non-empty
document/file segments, no dot segments and no backslash separator. Student A
therefore cannot read, insert, move or delete Student B objects or redirect a
document row to an arbitrary bucket.

If production sets `SUPABASE_STORAGE_BUCKET` to another value, do not apply the
migration unchanged. Review and version the real bucket ID first.

## Mass Assignment Controls

`WITH CHECK` applies ownership to inserted and resulting updated rows. Changing
`user_id`, moving a document to another user's workspace/path, or moving a
Storage object across prefixes is denied. Subscription, usage and Auth metadata
writes are not exposed to authenticated clients. Teacher policies combine row
ownership with the server-controlled Teacher entitlement predicate.

## Safe Apply Procedure

1. Use a disposable/local Supabase stack and a sanitized schema snapshot.
2. Compare deployed tables, columns, grants and policies with the inventory.
3. Review every existing policy. The migration aborts when it finds an unknown
   policy instead of deleting or silently coexisting with it.
4. Run the migration locally using the normal Supabase migration workflow.
5. Run all SQL contracts under `supabase/tests/` against that disposable stack.
6. Run backend authorization and two-user E2E tests.
7. Have the deployment owner approve a separate production apply window.
8. After production apply, repeat policy catalog inspection, Storage privacy,
   Student A/B, Student/Teacher and denied Admin tests.

Do not run `supabase db push`, migration up, reset, DROP or DELETE against the
deployed project as part of repository review.

## Deployment Differences And Assumptions

- The core schema migration makes clean environments reproducible, but the
  deployed catalog still must be compared before any remote apply.
- `documents` validates every non-empty ownership anchor. Legacy null owners are
  filled only from an owned workspace or a valid private Storage path whose UUID
  exists in Auth. Conflicts or unresolved rows stop hardening for quarantine.
- Existing policy definitions are unknown until the deployed catalog is
  inspected. Unknown policy names stop the migration for manual review.
- Service role bypasses RLS by design, so backend owner filters remain required
  and are independently tested.
- Public legal/retention and backup behavior are outside this SQL contract.

## Local Gate Evidence

- Clean migration reset: pass, including pgvector `0.8.2` and HNSW index.
- RLS catalog contract: pass, 45 public and 4 document Storage policies.
- Row-level Student A/B, Teacher entitlement and metadata spoof tests: pass.
- Both buckets private; direct private-artifact client access denied.
- Postgres, REST, Storage and Auth restart retained document, StudyResult,
  AudioBook, vector, certificate and both private objects.
- Account deletion removed database rows, Storage objects and Auth identity.
- Ownership backfill ran twice without duplication or corruption.

## Rollback Strategy

Before apply, export a policy/grant/bucket metadata snapshot and retain the
previous backend/Web release. If verification fails, stop traffic to the
affected path and restore the reviewed prior grants/policies in a dedicated
rollback migration. Remove only the versioned `studybook_*` policies after
confirming they were created by this migration. Never disable RLS broadly,
make the bucket public, grant `anon`, or expose service role as a rollback.
