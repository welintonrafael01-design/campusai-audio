# W6-P0 Remote Security Containment

Status: `W6-P0.1 LOCAL STORAGE RECONCILIATION PASS - REMOTE RETRY PENDING`

Date: `2026-09-10`

Target project: `olegevhncmblxngurclt`

## Incident

The legacy remote schema exposes private StudyBook records anonymously because
`workspaces`, `chats` and `messages` have RLS disabled while `anon` has broad
table privileges. Read-only count probes confirmed anonymous visibility of 36
workspaces, 46 chats and 118 messages. No private row body was retrieved.

The emergency artifact is:

`docs/release/sql/W6_P0_REMOTE_CONTAINMENT.sql`

It enables RLS on all 14 observed product tables, revokes all product-table
privileges from `anon` and keeps `studybook-documents` private. It deliberately
preserves Supabase Storage's baseline grants: Storage API roles require those
SQL grants, while effective object authorization is enforced by RLS, policies
and bucket visibility. It neither changes authenticated privileges nor
modifies service-role privileges. It contains no destructive DDL or
application-row mutation.

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

The bridge has **not** been applied remotely in W6-P0.

## Remote State

Immediately before the intended containment window, service-role read-only
counts still matched the backup:

- Product rows: 968
- Storage objects: 37
- Storage bytes: 42,288,843
- Anonymous workspaces/chats/messages: 36 / 46 / 118

The first remote SQL Editor attempt failed closed on the obsolete Storage grant
assertion. The unchanged disabled RLS state of `workspaces`, `chats` and
`messages` confirms rollback. W6-P0.1 performed no remote mutation. The P0
remains open until an authorized operator retries the corrected artifact and
completes the effective post-apply probes.

## Apply Gate

An authorized project owner must use a Supabase SQL session. From the corrected
reviewed commit and only after repeating pre-counts, execute the complete SQL
artifact as one transaction. A CLI example, only when owner database access is
available, is:

```bash
cd /Users/welintonmejia/Desktop/campusai-audio

supabase db query --linked \
  --file docs/release/sql/W6_P0_REMOTE_CONTAINMENT.sql
```

Do not run `migration repair`, `db push`, the bridge or any of the five normal
migrations during the emergency containment window.

Immediately after the transaction, repeat anonymous probes for all 14 tables;
anonymous Storage enumerate/list/read/insert/update/delete probes; QA A/B owner
isolation; Teacher authorization; service-role Storage and backend smoke tests;
aggregate row counts; and the 37-object Storage count. Baseline Storage grants
may remain and are not a failure when RLS, policy, bucket and effective API
checks all pass.

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
