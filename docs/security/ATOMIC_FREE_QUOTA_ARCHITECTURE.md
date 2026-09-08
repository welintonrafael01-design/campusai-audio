# Atomic Free Quota Architecture

Status: `IMPLEMENTED AND VERIFIED LOCALLY - REMOTE MIGRATION NOT EXECUTED`

## Scope

The backend is the authority for the five monthly Free allowances:

| Event | UTC monthly limit |
|---|---:|
| `pdf_upload` | 3 |
| `chat_message` | 10 |
| `summary_generated` | 3 |
| `flashcards_generated` | 1 |
| `quiz_generated` | 1 |

AudioBook, Voice Tutor, Question Bank, Exam Generator and Teacher Core remain
entitlement-gated and are not converted into Free quotas. Paid plans keep their
existing fair-use controls.

## Transaction Model

Migration `20260907000100_atomic_free_quota.sql` adds private
`quota_reservations` state and three service-role-only PostgreSQL RPCs. Each
reservation decision runs in PostgreSQL and takes a transaction advisory lock
over `(user_id, event_type, UTC month)`. Consumed `user_usage_events` and active
reservations are counted while that lock is held, so multiple FastAPI workers,
processes or containers cannot acquire the same final slot.

The lifecycle is:

```text
authenticated request
  -> server derives user and operation scope
  -> atomic reservation
  -> provider/document operation
  -> success: usage event + consumed state in one transaction
  -> failure/cancellation: release reservation
```

PDF upload reserves both its PDF and generated-summary allowances and commits
the two usage records in one database transaction. A failed batch commit writes
neither event. Streaming chat commits only after normal stream completion and
releases on cancellation.

## Failure And Recovery

- Provider, persistence and response-preparation failures release uncommitted
  reservations in `finally` blocks.
- Reservations expire after 30 minutes. The next reservation in the same
  user/event scope marks stale rows released while holding the advisory lock.
- A worker death can temporarily reserve capacity only until that TTL.
- If reservation RPCs are unavailable or malformed, Free generation fails
  closed with a safe `quota_service_unavailable` response.
- Account deletion removes quota reservations before usage history and Auth.

## Idempotency

Flutter sends an opaque `Idempotency-Key` for quota-bearing operations. Callers
may create one with `ApiService.createOperationId()` and reuse it for a retry of
the same logical action. The backend validates the header, combines it with the
route scope, hashes it, and PostgreSQL scopes uniqueness by authenticated user
and event. The raw client key is never persisted or logged.

Concurrent use of one operation ID returns one acquired reservation and the
same reservation identity to duplicate callers. A consumed reservation cannot
create a second usage event. A duplicate still in progress receives a retryable
409 from the backend service layer.

## Period Rule

All five periods use PostgreSQL UTC boundaries:

- start: `date_trunc('month', clock_timestamp() at time zone 'UTC')`
- end: start plus one calendar month
- comparison: inclusive start, exclusive end

Committed usage keeps the reservation timestamp, so work finishing after a UTC
month boundary cannot be charged to or race with the next month's allowance.

Client locale and timezone cannot move the reset boundary.

## Security

- Authenticated identity is resolved by FastAPI; request bodies cannot select a
  quota owner.
- `quota_reservations` has RLS enabled and no grants or policies for `anon` or
  `authenticated`.
- Mutation RPCs are `SECURITY INVOKER`, have an empty `search_path`, and are
  executable only by `service_role`.
- The Flutter client never receives the service-role credential.
- Telemetry contains event/status, a short one-way user hash and reservation ID;
  it excludes documents, prompts, answers, access tokens and secrets.

## Local Evidence

The disposable local Supabase gate verifies a fresh migration, DB lint, SQL
contracts and real parallel REST/RPC requests. Boundary tests launch eight
simultaneous reservations for each event and prove exactly one receives the
last slot. Additional tests cover release, stale recovery, duplicate retry,
atomic batch failure, client privilege denial and cross-user isolation.

No remote Supabase operation was performed in W5.

## Historical Virtual Environment Audit

W5.1 removed 8,445 `backend/.venv` files from the current Git index while
preserving the 509 MB local environment used by QA. A high-confidence scan of
the tracked dependency snapshot found no private key, provider secret, service
JWT or live payment credential. The environment remains ignored and can be
recreated from `backend/requirements.txt`. Repository history was not rewritten.
