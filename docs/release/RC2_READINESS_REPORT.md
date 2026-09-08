# RC2 Readiness Report - StudyBook AI v1.0

Branch: `qa/studybook-ai-rc1`
Base: `studybook-v1-rc1`
Base commit: `7837a72`
Generated: 2026-08-13

## Executive Decision

RC2 status: `NOT_CREATED`

Android Beta ready: `NO`

Reason: automated build/test baseline is healthy, but required manual gates are still missing: Android real device install/open, web two-user isolation, role/route guard verification, Stripe test-mode checkout, and accessibility device/browser review.

## Automated Evidence

| Check | Result |
| --- | --- |
| Flutter analyze | PASS with 4 historical infos, 0 errors, 0 warnings |
| Flutter test | PASS, 9 tests |
| Flutter build web | PASS |
| Backend pytest | PASS, 2 tests |
| Backend compileall | PASS |
| Android debug APK | PASS |
| Android release APK | PASS |
| Integration tests | PARTIAL, 3 passed and 6 blocked by missing QA credentials / fixture harness |
| Secret review | PASS for current tree; no `.env` or virtualenv dependencies tracked |

## Release Gates

| Gate | Required for Android Beta | Current Status |
| --- | --- | --- |
| 0 P0 | Yes | PASS |
| 0 P1 | Yes | PASS |
| Auth works | Yes | MANUAL_REQUIRED |
| Upload works | Yes | MANUAL_REQUIRED |
| Active document works | Yes | MANUAL_REQUIRED |
| Chat works | Yes | MANUAL_REQUIRED |
| Library works | Yes | MANUAL_REQUIRED |
| Logout/login works | Yes | MANUAL_REQUIRED |
| User isolation works | Yes | MANUAL_REQUIRED |
| Route guards work | Yes | MANUAL_REQUIRED |
| No admin secret in client | Yes | PASS by code scan; scanner pattern string remains intentionally |
| Backend tests pass | Yes | PASS |
| Flutter tests pass | Yes | PASS |
| APK installs and opens | Yes | MANUAL_REQUIRED |
| No main-flow crashes | Yes | MANUAL_REQUIRED |

## Required Manual Actions Before RC2

1. Execute Android real device report on a Samsung/Android phone.
2. Execute web two-user isolation with Usuario A and Usuario B.
3. Validate Stripe test-mode checkout and webhook using backend test credentials.
4. Capture accessibility evidence for text scaling, screen reader and keyboard navigation.
5. Run performance smoke on startup, Home, Library with 20+ documents, AudioBook and Teacher Studio.
6. Provide QA credentials via `dart-define` and run the full authenticated integration suite.

Repository hygiene note: W5.1 completed the previously required
`backend/.venv` index cleanup without deleting the local environment or
rewriting history.

## Tag Decision

`studybook-v1-rc2` was not created in this pass.
