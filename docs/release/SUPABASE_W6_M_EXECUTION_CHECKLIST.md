# Supabase W6-M Execution Checklist

Status: `W6-M1 CORE ROLLBACK VERIFIED - REMOTE RETRY NOT AUTHORIZED`

Target project: `olegevhncmblxngurclt`

The first authorized W6-M push applied and recorded the bridge, then failed on a
connection error while reporting Core statement index 12. W6-M1 proved through
read-only catalog evidence that Core rolled back physically and that no later
migration ran. This checklist now governs a separately approved retry; W6-M1
itself executed no remote mutation.

Current required remote history:

```text
20260827000100 remote_legacy_reconciliation
```

Do not rerun or repair that bridge entry.

## 1. Approval And Freeze

- Record named release, security and data-owner approval.
- Freeze application writes and schema-changing deployments.
- Confirm the linked project ref is exactly `olegevhncmblxngurclt`.
- Confirm the reviewed repository commit and clean working tree.
- Create or verify a current provider recovery point immediately before the
  migration. The W6-R2 logical/Storage backup remains a proven fallback, but it
  must not silently replace a current recovery point.
- Record pre-mutation counts: 609 active rows, 359 private quarantine rows and
  37 `studybook-documents` objects. Stop unless active plus quarantine is 968.

## 2. Artifact Integrity

Verify the six migration files and hashes recorded in
`SUPABASE_PRODUCTION_MIGRATION_EVIDENCE.md`. Stop if any file, order or hash is
different from the reviewed W6-M0 evidence.

Revalidate the private W6-R2 backup without printing private content. Expected
hashes:

- `schema.sql`: `604f03d383cb2dcb8a1e43c9d4b1c0dadabdbe143bbada4181792a0aea486c3f`
- `data.sql`: `16bc8ca49af3d5d3e2770790f32e6b725296501551ea3d5f0d19801a82586d99`
- `roles.sql`: `4350a72b5ec109888e740c17f3eb4da2fcd95ab73af26499538ed0bf615db543`
- Storage manifest: `cc230b0f66d188e71d4271f352b48e00a32b4273ca60ee84c93f0f0800f8a21e`

## 3. Password Handling

Supabase CLI `2.116.0` recognizes `SUPABASE_DB_PASSWORD`; both `migration list`
and `db push` support database-password authentication. Read the password into a
temporary environment variable without echoing it:

```bash
cd /Users/welintonmejia/Desktop/campusai-audio

read -s "SUPABASE_DB_PASSWORD?Database Password: "
echo
export SUPABASE_DB_PASSWORD
```

Never commit, log or paste the password. Clear it immediately after the window:

```bash
unset SUPABASE_DB_PASSWORD
```

## 4. Read-Only Preflight And Dry Run

Only after approval and recovery verification:

```bash
supabase migration list --linked
supabase db push --linked --dry-run
```

The dry run must show exactly these five pending versions in order:

```text
20260828000100
20260829000100
20260831000100
20260901000100
20260907000100
```

Stop unless history contains exactly the bridge, a pending migration is missing,
an extra migration appears, the bridge is offered again, or the CLI cannot
authenticate through the approved database-password path.

## 5. Remote Execution

This command remains forbidden until a W6-M retry is explicitly approved:

```bash
supabase db push --linked
```

The prior failed command must not be rerun automatically. After approval, do not
use `--include-all`, run manual SQL between migrations, or mark any version as
applied before its SQL executes. Do not use migration repair as a shortcut.

## 6. Immediate Verification

After a successful push, before reopening writes:

- `supabase migration list --linked` contains exactly all six versions.
- Active legacy rows are 609 and private quarantine rows are 359.
- Active plus quarantined remains 968, with zero unexpected loss.
- `studybook-documents` remains at 37 objects.
- All 17 required product tables and both private buckets exist.
- RLS, 49 public policies and four Storage policies match the reviewed source.
- Student A/B database and Storage isolation pass in both directions.
- Student metadata spoof is denied; Teacher authorization remains server-owned.
- Service-role database and private Storage operations pass.
- RAG, private artifacts, account deletion lifecycle and atomic quota gates pass.
- Backend and Flutter smoke/regression tests pass.

## 7. Stop Conditions

Stop and keep application writes frozen if any of the following occurs:

- Backup, commit, project ref, migration order or pre-count mismatch.
- Dry-run output differs from the six reviewed files.
- Any migration fails or history omits a successfully executed migration.
- Active plus quarantined rows differs from 968.
- Storage object count differs from 37 unexpectedly.
- Any active owner is null/orphaned or `educator_rubrics` is missing.
- RLS, policy, pgvector/RAG, quota or private-bucket validation fails.
- Anonymous or cross-user access succeeds.

Do not improvise SQL, weaken RLS, make a bucket public or run migration repair
while investigating.

## 8. Recovery

Never run:

```bash
supabase db reset --linked
```

On a failed migration, preserve logs and migration history, keep writes frozen
and obtain incident-owner approval. Prefer an approved forward correction when
data and containment remain intact. If restoration is required, restore the
current pre-window database and Storage recovery point together.

The W6-R2 backup predates remote containment. If it is used as the authorized
fallback, restore its database and all 37 private objects, immediately reapply
the reviewed P0 containment artifact before traffic resumes, and re-run the
968-row/37-object and effective anonymous-denial gates. Never reopen traffic on
the uncontained legacy snapshot.
