# SB-SOL-002 — Student Dashboard session isolation

## Finding

A01 allowed a process-global Student Dashboard cache to be reused without
proving that its owner matched the currently authenticated user. A dashboard
request that completed after logout could also repopulate transient state from
the previous session.

## Resolution

- Dashboard cache entries are bound to the authenticated Supabase user ID and
  a local session generation.
- Logout, account deletion and observed authentication identity changes
  invalidate the generation and cache.
- Dashboard work runs in a user-bound asynchronous storage scope. A late task
  keeps the original user's local key namespace and cannot write into the next
  user's namespace.
- Results and errors are applied only while their captured session remains
  current. The existing five-minute cache remains available within the same
  authenticated session.

## Regression coverage

`student_dashboard_session_isolation_test.dart` covers same-process A-to-B
switching, logout during a load, late completion, late failure, same-user cache
reuse, refresh after switching and asynchronous storage scope ownership.

The backend ownership and authorization model was not changed by this mission.
