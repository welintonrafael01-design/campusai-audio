# StudyBook AI 1.0.1 Security Hotfix

## Status

- Finding: A01, Student Dashboard session/cache isolation.
- Implementation commit: `357d701f55be6bfc368d030a8c3fd07ab279b141`.
- Production deployment time: `2026-09-20T07:11:17Z`.
- Final production validation time: `2026-09-20T16:41:18Z`.
- Release tag: `v1.0.1`, annotated and pushed against the implementation
  commit.

## Root Cause And Resolution

The Student Dashboard used a process-global five-minute cache without proving
that its owner matched the authenticated user. A request started by one user
could also complete after logout and attempt to repopulate transient state.

The fix binds cached data to the authenticated user ID and a local session
generation. Logout, account deletion and observed identity changes invalidate
that generation. Late results are discarded, and asynchronous local storage
work remains bound to the user scope that started it.

## Test Evidence

- Focused session, storage and access-control tests: 30 passed.
- Full Flutter suite: 159 passed.
- `flutter analyze --no-pub`: no issues found.
- `flutter build web --no-pub`: passed.
- Commit secret review: passed.
- `git diff --check`: passed.

The deterministic coverage includes A-to-B switching, logout during load, late
success, late failure, same-user cache reuse, refresh after switching and
asynchronous storage scope ownership.

## Deployment Evidence

- Remote QA head: `357d701f55be6bfc368d030a8c3fd07ab279b141`.
- GitHub production deployment: `6550176587`.
- Vercel deployment reference: `3kAsbaLG6uEjiHNJ38LVoTEgMcJM`.
- Vercel deployment URL:
  `https://studybook-ai-psdkildg9-welintonrafael01-1070.vercel.app`.
- Production application: `https://app.studybookai.com`.

The GitHub/Vercel integration deployed the exact implementation commit. The
production `main.dart.js` contains the new stale-session guard and no longer
contains the previous `student_dashboard_latest` cache key. The same push also
triggered the linked Marketing project automatically; no Marketing source file
or configuration was changed by this hotfix.

## Production Validation

- Application load and unauthenticated redirect to `/#/auth`: passed.
- Student B login: passed.
- Dashboard, Library and Account routes: passed.
- Same-user session restore after reload: passed.
- Visible logout and protected Dashboard redirect after logout: passed.
- Student B login again in the same browser process: passed.
- Application console-breaking errors: none observed.
- Late-result race: covered by deterministic automated regression tests; no
  intrusive production network manipulation was performed.
- QA User A loaded `/learning`, which executes the affected Student Dashboard
  controller, populated its cache, navigated away and returned within the TTL.
- QA User A logged out normally. QA User B then logged in without closing,
  restarting or clearing the browser/application process.
- QA User B loaded the same `/learning` path. Its visual state was distinct
  from QA User A. A private OCR comparison found five A-specific markers and
  zero of them in B's initial, refreshed or navigate-and-return states. No
  private values or account content were recorded.
- QA User B refresh and navigate-and-return produced the same B-owned visual
  fingerprint, confirming stable same-user cache behavior.
- QA User B logout returned to Auth, and direct protected `/learning`
  navigation remained at Auth with no authenticated dashboard resurrection.

## Release Decision

A01 is closed in production. The live same-process QA User A to QA User B
isolation test passed, the production bundle contains the session-generation
guard, and no P0 or P1 regression was observed.

Annotated tag `v1.0.1` points exactly to
`357d701f55be6bfc368d030a8c3fd07ab279b141` and was pushed without modifying
or moving `v1.0.0`.

Other Astra findings were not modified or reclassified by this isolated
hotfix. The next planned mission is SB-SOL-003, Stripe lifecycle integrity; it
was not executed here.
