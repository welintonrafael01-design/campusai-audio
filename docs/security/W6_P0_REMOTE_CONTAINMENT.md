# W6-P0 Remote Security Containment

Status: `W6-P0R CONFIDENTIALITY P0 CLOSED - W6-M3 REVALIDATED`

Date: `2026-09-10`

Target project: `olegevhncmblxngurclt`

## W6-M3 Final Security Revalidation

After the separately authorized production migration completed, W6-M3 verified
the final remote state without applying migrations, repair, reset or schema
changes:

- Remote history contains exactly all six reviewed migration versions.
- All 17 StudyBook product tables have RLS enabled, with 49 public policies.
- Anonymous database access is denied across every product table.
- Both Storage buckets are private and protected by four policies.
- The 37 original document objects remain byte-for-byte consistent with the
  private backup manifest; private artifacts and final disposable objects are
  zero.
- Student A and Student B are isolated in both directions across all tested
  product domains and private object paths.
- Direct authenticated RAG and quota authority is denied; server-authorized RAG,
  atomic quota and representative service-role operations pass.
- Client-controlled metadata cannot grant Teacher or Admin access. Student
  Teacher-endpoint access is denied and the trusted QA Teacher passes.
- Active/quarantine counts remain 609/359, preserving all 968 legacy rows with
  zero unexpected duplicates or active ownership/relation orphans.

Security Advisor confirms the former critical `workspaces`, `chats` and
`messages` RLS warnings are cleared. Its three server-only
`rls_enabled_no_policy` notices are informational. Disabled Auth
leaked-password protection remains P2, as does the known foreign/nonexistent
chat `500` status mapping; neither finding exposed private data during W6-M3.
P0 remains closed and no P1 was found.

## W6-M1 Post-Bridge Revalidation

The first authorized W6-M push applied and recorded the pre-baseline bridge,
then lost its connection during the Core migration. W6-M1 used only Management
read-only catalog/aggregate queries and anonymous read probes. It confirmed:

- Remote history contains only bridge version `20260827000100`.
- Core physically rolled back; its function, indexes and triggers are absent.
- Active rows are 609 and private quarantine rows are 359, preserving all 968.
- All 14 public product tables retain RLS and zero anonymous CRUD privileges.
- Anonymous REST access returns `401` for all 14 product tables.
- Anonymous Storage listing exposes zero objects and a known private object read
  is denied.
- `studybook-documents` remains private with all 37 objects.
- No later persistence, ownership or atomic-quota migration object appeared.
- Active owner/relation orphans and duplicate owner/resource groups remain zero.

P0 remains closed. No remote mutation occurred during W6-M1. A disposable
reconstruction proved a normal Core-through-quota retry, without rerunning the
bridge, reaches the expected final security model. That retry requires a
separate authorization.

## Incident

Before containment, the legacy remote schema exposed private StudyBook records
anonymously because `workspaces`, `chats` and `messages` had RLS disabled while
`anon` had broad table privileges. Read-only count probes confirmed anonymous
visibility of 36 workspaces, 46 chats and 118 messages. No private row body was
retrieved.

The corrected containment artifact was subsequently applied by an authorized
project owner through Supabase SQL Editor. W6-P0R verified the resulting state
without applying any additional remote SQL, migration, repair or schema change.

The emergency artifact is:

`docs/release/sql/W6_P0_REMOTE_CONTAINMENT.sql`

It enables RLS on all 14 observed product tables, revokes all product-table
privileges from `anon` and keeps `studybook-documents` private. It deliberately
preserves Supabase Storage's baseline grants: Storage API roles require those
SQL grants, while effective object authorization is enforced by RLS, policies
and bucket visibility. It neither changes authenticated privileges nor
modifies service-role privileges. It contains no destructive DDL or
application-row mutation.

## W6-P0R Remote Verification

Post-application effective-access verification on 2026-09-10 established:

- All 14 private product tables deny `anon` REST access (`401`, zero visible
  rows).
- The private `studybook-documents` bucket exposes zero objects to anonymous
  listing (`200`, empty result).
- Anonymous private object read, insert, update and delete are denied (`400`).
- A disposable service-role object passed upload, read, update and delete; it
  was removed and the bucket returned to exactly 37 objects.
- Service-role reads remain viable for all 14 tables and account for exactly
  968 rows.
- QA Student A and Student B each see only their own active subscription; both
  cross-user subscription probes return zero rows.
- Student B cannot retrieve Student A's study result. Student A owns three
  chats and ten study results; Student B's lists remain empty.
- Both Student identities receive `403` from `/educator/snapshot`; the trusted
  Teacher identity receives `200`.
- Local authorization contracts confirm that untrusted `user_metadata` cannot
  grant Teacher/Admin privilege.
- Backend regression: 177 passed, 10 skipped.
- Security-focused backend regression: 125 passed.
- Flutter regression: 144 passed; `flutter analyze` reports no issues.
- Tracked privileged-value and high-confidence secret-pattern scans: pass.

Neither QA Student had document metadata available during this closure, so a
foreign-document ID probe was not fabricated. Document isolation remains
covered by the backend/security regression suite and the fail-closed anonymous
table gate.

The known foreign-chat response defect remains separate: Student B receives
`500` when requesting messages for a Student A chat. No foreign messages are
returned, so confidentiality remains closed; the status mapping must be fixed
locally to return `403` or `404` in a later P2 remediation.

Direct read-only catalog, migration-history and Security Advisor access through
the installed Supabase CLI was unavailable to the current operator profile
(`403`). The project owner confirmed only the containment SQL was applied. No
bridge, normal migration, `db push` or migration repair was run, so the
previously empty remote migration history is operationally unchanged. Advisor
state is recorded as not independently verified rather than inferred.

## Recovery Integrity

The private recovery directory remains outside Git at:

`$HOME/StudyBookAI_Backups/supabase_2026-09-08`

Database dump and Storage-manifest hashes match the W6-R2 evidence. Directory
permissions are `700`; every backup file is `600`. All 37 physical Storage
objects were rehashed successfully, totaling 42,288,843 bytes.

## Disposable Restore Drill

A dedicated Supabase CLI stack named `studybook-w6-p0-restore` was started on
isolated local ports. The remote logical artifacts restored without content
inspection:

- Public StudyBook tables: 14
- Public StudyBook rows: 968
- Supabase Auth users: 5
- Storage metadata objects: 37
- QA subscriptions: two active Student and one active Teacher
- Physical Storage backup: 37 objects / 42,288,843 bytes

The restore reproduced every material legacy conflict recorded by W6-R2,
including `educator_rubrics`, the UUID usage-event key, the legacy subscription
primary key, missing ownership objects, disabled RLS and broad grants.

Restore drill: `PASS`.

## Local Emergency Containment

The emergency artifact was applied twice to the restored snapshot to prove
idempotence. Results:

- RLS-enabled product tables: 14 of 14
- Anonymous CRUD grants on product tables: 0
- Anonymous REST access to all 14 product tables: denied (`401`)
- Storage RLS: enabled on `storage.buckets` and `storage.objects`
- Storage policies applicable to `anon` or `public`: 0
- `studybook-documents`: private
- Anonymous bucket enumeration: no visible buckets (`200`, empty result)
- Anonymous object listing: no visible objects (`200`, empty result)
- Anonymous private object read/insert/update/delete: denied (`400`)
- Service-role Storage upload/read/update/delete: pass (`200`)
- Service-role aggregate access: 968 rows
- Rows before/after: 968 / 968
- Storage metadata before/after: 37 / 37
- QA Student A/B own subscription: visible
- QA Student A -> Student B subscription: denied
- QA Student B -> Student A subscription: denied
- Backend document, own-chat, subscription and usage paths: pass
- Student -> Teacher endpoint: denied
- Trusted Teacher -> Teacher endpoint: pass
- `user_metadata` Teacher/Admin spoof: denied

Direct authenticated product access other than the existing own-subscription
policy intentionally fails closed until the final RLS migration is deployed.
The Flutter application remains viable because product operations go through
FastAPI, which verifies the bearer identity and uses the backend-only
service-role client with explicit owner filters.

### W6-P0.1 Storage Privilege Reconciliation

The first remote SQL Editor execution aborted with
`W6-P0 anonymous Storage privilege remains`. Post-failure inspection showed
`workspaces`, `chats` and `messages` still had RLS disabled, confirming that the
transaction rolled back. No remote containment change was retained.

The exact failure was reproduced against a fresh restore. Supabase owns
`storage.buckets` and `storage.objects` through `supabase_storage_admin`, which
is also the grantor of the baseline `anon`, `authenticated` and `service_role`
table privileges. A `REVOKE` issued by the SQL Editor's `postgres` role did not
remove grants made by that owner; the old assertion then raised and rolled back
the transaction.

More importantly, `has_table_privilege()` was not an effective Storage access
test. On the uncontained legacy restore, both Storage tables already had RLS
enabled, the document bucket was private and there were zero Storage policies.
Although the baseline grants were present, an anonymous Storage API client
could enumerate no buckets or objects and could not download, upload, update or
delete a service-created private probe.

The corrected transaction preserves the platform grants and fails closed when:

- either Storage table lacks RLS;
- `anon` can bypass RLS;
- a Storage policy applies to `anon` or `public`;
- the document bucket is public; or
- `service_role` lacks required Storage access.

The corrected artifact was applied twice locally. All effective API denials,
service-role operations, A/B isolation, backend owner filtering and data counts
passed. Rows remained 968 and Storage metadata returned to 37 after the probe.

## Pre-Baseline Bridge

The reviewed bridge is:

`supabase/migrations/20260827000100_remote_legacy_reconciliation.sql`

It is a no-op for absent legacy product tables and precedes the five existing
migrations on a clean environment. On the restored legacy snapshot it:

- deterministically backfills document ownership from workspace or private
  Storage path;
- moves unresolved, duplicate and Auth-orphaned legacy rows to
  `private.studybook_legacy_quarantine` without discarding their JSON record;
- preserves one deterministic current document per owner/document key;
- reconciles the subscription primary key while retaining the legacy ID;
- converts active usage-event IDs to bigint identity while retaining their
  legacy UUIDs;
- creates and validates owner foreign keys for active records;
- replaces the known legacy subscription policy through the versioned RLS
  migration;
- versions and secures `educator_rubrics`.

Migration rehearsal data accounting:

- Active legacy rows after bridge: 609
- Private quarantined legacy rows: 359
- Preserved total: 968
- Unexpected dropped rows: 0
- Storage metadata objects: 37
- Active owner nulls/orphans: 0

The bridge plus all five migrations succeeded in order with no manual step.
The resulting database has 17 RLS-enabled product tables, 49 public StudyBook
policies, four document Storage policies, pgvector, durable RAG, certificates,
quota reservations and all required service-role RPCs. All three SQL contracts
passed against both the migrated restore and a clean migration stack.

W6-P0 did not apply the bridge. The later W6-M attempt applied and recorded it;
W6-M1 confirmed Core and all subsequent migrations remain unapplied.

## Remote State

After the bridge and failed Core attempt, effective verification shows:

- Active product rows: 609
- Private quarantine rows: 359
- Preserved total: 968
- Storage objects: 37
- Anonymous access across all 14 private tables: denied
- Anonymous Storage list/read/insert/update/delete: denied
- QA subscriptions and representative study results: owner-isolated
- Backend Student/Teacher authorization: enforced
- Unexpected data loss: none detected

The first failed SQL Editor attempt and its rollback remain documented above as
incident history. The later corrected transaction and W6-P0R effective probes
supersede that pre-containment state. Confidentiality P0 is closed.

## Completed Apply Gate

The authorized owner first applied only
`docs/release/sql/W6_P0_REMOTE_CONTAINMENT.sql`; W6-P0R completed the required
post-apply probes. W6-M later applied and recorded the bridge before Core rolled
back on connection loss. Do not reapply containment or the bridge. Do not run
`migration repair` or retry `db push` until a separately approved window.
Baseline Storage grants may remain and are not a failure when RLS, policy,
bucket privacy and effective API checks all pass.

## Rollback

The SQL artifact is transactional and its assertions abort the transaction if
an expected table is missing, public-table anonymous access remains, Storage
RLS or policy safety fails, the bucket is public, or service-role access is
lost. This is the primary rollback boundary.

After commit, do not restore anonymous grants, disable RLS or make a bucket
public. If an unexpected severe regression appears, freeze writes, retain the
containment, roll back the application path where possible and invoke the
approved database recovery procedure using the verified W6-R2 artifacts. Any
security-weakening SQL requires a separate incident-owner approval.
