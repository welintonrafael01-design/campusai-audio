# Supabase Security Model

## Observed Architecture

Flutter initializes `supabase_flutter` with `SUPABASE_URL` and the anon/public
key and uses the SDK for Auth/session management. No direct Flutter database
table or Storage query was found in the production Dart source. Application
data access is sent to FastAPI with the bearer token.

FastAPI validates the token with the Supabase anon client. Database and Storage
operations use `SUPABASE_SERVICE_ROLE_KEY` from the backend environment through
`get_supabase_admin_client()`. The service-role key was not found in Flutter,
tracked environment files, tests, or build configuration. A dart-define is
public configuration and must never carry this key.

## Data Surfaces Observed

- Core: `user_subscriptions`, `user_usage_events`.
- User cloud data: `workspaces`, `documents`, `chats`, `messages`,
  `study_results`, `audiobooks`.
- Teacher data selected dynamically by the educator router:
  `educator_courses`, `educator_students`, `educator_attendance`,
  `educator_gradebook`, `educator_question_banks`.
- Storage: configurable bucket, default `studybook-documents`, with paths
  `<user_id>/documents/<document_id>/<safe_filename>`.

This list is code-derived, not a declaration of the complete production schema.

## Ownership Enforcement

- The backend derives `user_id` from the validated token.
- CRUD queries filter by that `user_id`; legacy document rows without a
  `user_id` are constrained by the user-prefixed `storage_path`.
- Chats validate their parent workspace/document before message operations.
- StudyResults and AudioBooks filter by user plus resource identifiers.
- Teacher snapshot/sync uses only the token user ID. Email-based identity
  expansion is prohibited.
- Signed document downloads first resolve an owner-scoped database record and
  verify its storage prefix.

## RLS Status

Plan 7F-S1 adds a versioned repository contract at
`supabase/migrations/20260829000100_studybook_rls_security.sql`, with SQL and
Python contract tests. It covers every application table and Storage bucket
observed in production code. Because server operations use service role, RLS
does not replace backend owner filters for those calls.

The migration has not been applied to the deployed Supabase project. This
document therefore claims repository coverage, not deployed policy state.

Before an external production release, the deployed project owner must verify:

1. RLS is enabled on sensitive tables where anon/authenticated access is
   possible.
2. No broad anon/authenticated policies expose rows or the documents bucket.
3. The storage bucket is private and signed URL lifetime is appropriate.
4. Service-role credentials exist only in the backend secret manager/runtime.
5. Backups, logs, and dashboard access follow least privilege.

## Client Authority

The Flutter plan cache, query parameters, payload `role`/`plan`,
`user_metadata`, and client-generated capabilities are UX state only. They do
not authorize backend access. Subscription and Teacher/Admin decisions are made
server-side.
