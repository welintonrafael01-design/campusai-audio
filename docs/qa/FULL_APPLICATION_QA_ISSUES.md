# StudyBook AI - Full Application QA Issues

Date: 2026-09-05

Baseline before final Voice Tutor closure: `87546e517a5c024b07de11ebe79e051a14151705`

## Fixed

| ID | Severity | Area | Reproduction | Root cause | Resolution | Regression |
|---|---|---|---|---|---|---|
| QA-001 | P1 | Auth/Web | Authenticate, close the tab, reopen the app | Router guard did not refresh after asynchronous Supabase recovery | Auth stream notifier refreshes `GoRouter` | Unit notifier tests plus real tab-reopen probe |
| QA-002 | P1 | Booky onboarding | Request welcome audio in Web or during a slow/failing response | 180-second wait, transient-only error and an HTML media request that omitted the bearer header | 45-second timeout, persistent live-region error and authenticated same-origin Web audio fetch before playback | Timeout/success widget tests, authenticated MP3 browser probe and Web audio loader tests |
| QA-003 | P2 | Student/Teacher boundary | Save a Student question bank | Shared repository attempted educator sync for Student | Capability check before educator reads/writes | Access-control suite and clean browser probe |
| QA-004 | P3 | QA infrastructure | Serve local profile build on affected macOS host | `http.server` blocked in reverse DNS; runner mixed release with loopback | Deterministic static server, profile build and explicit IPv4 | Browser lifecycle probe PASS |
| QA-006 | P2 | Human/physical QA | Certify real microphone, audible response, AudioBook output and TalkBack | Physical I/O and screen-reader behavior cannot be proven by unit tests alone | Samsung evidence covers Voice Tutor microphone/audio, AudioBook audible output and TalkBack; final Chrome mic/response/audio retest also passed | Voice lifecycle tests, authenticated local API probe and human confirmation on 2026-09-05 |

## Open Or Conditional

| ID | Severity | Area | Impact | Current evidence | Required closure |
|---|---|---|---|---|---|
| QA-005 | P2 | External AI latency | A provider call was observed at 187 seconds once | Subsequent full journey passed; QA timeout now classifies the dependency honestly | Monitor production latency and define server-side request budgets before broad launch |
| QA-007 | P1 | Production Supabase | Local RLS/persistence evidence does not prove deployed remote policy state | Disposable local migration, restart, isolation and deletion all pass | Approved controlled migration, backup and two-user verification on the intended remote project |
| QA-008 | P1 | Google Play billing | Public product IDs and Play Console server credentials are still human configuration | Billing contracts and signed AAB pass | Configure approved product IDs and verification credentials, then run internal-track billing QA |

## Priority Summary

- P0 open: 0
- P1 fixed: 2
- P1 open/conditional: 2 (`QA-007`, `QA-008`)
- P2 fixed: 2
- P2 open: 1 (`QA-005`)
- P3 fixed: 1
- P3 open: 0

No open issue justifies weakening RLS, using a client-side privileged key,
falling back to local production persistence or bypassing Play verification.
`QA-007` and `QA-008` are external deployment gates, not application bugs.
