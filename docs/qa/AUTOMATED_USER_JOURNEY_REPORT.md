# Automated User Journey Report - StudyBook AI RC1

Branch: `qa/studybook-ai-rc1`
Base tag: `studybook-v1-rc1`
Generated: 2026-08-17

## Execution Summary

| Metric | Count |
| --- | ---: |
| Total journeys tracked | 18 |
| PASS | 4 |
| FAIL | 0 |
| BLOCKED | 11 |
| MANUAL_REQUIRED | 3 |

## Commands Executed

```bash
cd /Users/welintonmejia/Desktop/campusai-audio/mobile/campusai_mobile
flutter test integration_test
```

Result:

- `app_boot_e2e_test.dart`: PASS
- `route_guard_e2e_test.dart`: PASS
- `multiuser_isolation_e2e_test.dart`: PASS
- `auth_journey_e2e_test.dart`: BLOCKED_EXTERNAL_CONFIG via justified `markTestSkipped`
- `home_upload_e2e_test.dart`: BLOCKED_EXTERNAL_CONFIG or AUTOMATION_GAP via justified `markTestSkipped`
- `ai_tools_e2e_test.dart`: BLOCKED_EXTERNAL_CONFIG or AUTOMATION_GAP via justified `markTestSkipped`
- `library_learning_e2e_test.dart`: BLOCKED_EXTERNAL_CONFIG or AUTOMATION_GAP via justified `markTestSkipped`
- `teacher_studio_e2e_test.dart`: BLOCKED_EXTERNAL_CONFIG or AUTOMATION_GAP via justified `markTestSkipped`
- `account_session_e2e_test.dart`: BLOCKED_EXTERNAL_CONFIG or AUTOMATION_GAP via justified `markTestSkipped`

Integration result: 3 passed, 6 skipped with explicit `BLOCKED_EXTERNAL_CONFIG` or `AUTOMATION_GAP` reason.

Backend ownership regression:

```bash
cd /Users/welintonmejia/Desktop/campusai-audio
PYTHONPATH=/Users/welintonmejia/Desktop/campusai-audio/backend backend/.venv/bin/python -m pytest backend/tests -q
```

Result: PASS, 4 tests.

## Journey Matrix

| Journey | Status | Evidence | Notes |
| --- | --- | --- | --- |
| AUTH | PASS | `app_boot_e2e_test.dart` | Auth surface loads and empty submit returns a human validation state. |
| HOME | BLOCKED | Requires authenticated QA user. | Needs `QA_STUDENT_A_EMAIL`, `QA_STUDENT_A_PASSWORD`, `SUPABASE_URL`, `SUPABASE_ANON_KEY`. |
| UPLOAD | BLOCKED | Requires authenticated QA user and file picker automation. | Fixture PDF is available at `QA/fixtures/studybook_qa_fixture.pdf`. |
| CHAT | BLOCKED | Requires uploaded document and backend AI config. | Must run against QA backend with test credentials. |
| SUMMARY | BLOCKED | Requires uploaded document and backend AI config. | No PASS declared. |
| FLASHCARDS | BLOCKED | Requires uploaded document and backend AI config. | No PASS declared. |
| QUIZ | BLOCKED | Requires uploaded document and backend AI config. | No PASS declared. |
| QUESTION BANK | BLOCKED | Requires uploaded document and backend AI config. | No PASS declared. |
| EXAM | BLOCKED | Requires uploaded document and backend AI config. | No PASS declared. |
| AUDIOBOOK | MANUAL_REQUIRED | Audio output quality cannot be asserted automatically. | UI/request can be automated after authenticated fixture upload. |
| VOICE TUTOR | MANUAL_REQUIRED | Physical microphone/audio permissions require device/browser QA. | Do not mark FAIL for environment-only limitations. |
| LIBRARY | BLOCKED | Requires authenticated fixture-generated data. | Must verify tabs, search, refresh, favorite and delete. |
| LEARNING | BLOCKED | Requires generated progress data. | No Enterprise-only features included. |
| TEACHER | BLOCKED | Requires QA teacher credentials and teacher plan entitlement. | Needs `QA_TEACHER_EMAIL`, `QA_TEACHER_PASSWORD`. |
| ACCOUNT | BLOCKED | Requires authenticated QA user. | Plan/usage/billing must be verified in QA mode. |
| ROUTE GUARDS | PASS | `route_guard_e2e_test.dart` + backend admin tests. | Guest auth surface verified; role-specific student/teacher/admin guards still require QA users. |
| MULTIUSER | PASS | `multiuser_isolation_e2e_test.dart` and `test_cloud_study_result_isolation.py`. | Local StudyResult scope and cloud query filters verified. Full Supabase two-user UI run is still required. |
| SESSION ISOLATION | PASS | `multiuser_isolation_e2e_test.dart`. | Local session data separation verified. Full logout/login data restore requires QA credentials. |

## Required Dart Defines for Full E2E

```bash
flutter test integration_test \
  --dart-define=API_BASE_URL=http://10.0.2.2:8000 \
  --dart-define=SUPABASE_URL=<qa_supabase_url> \
  --dart-define=SUPABASE_ANON_KEY=<qa_supabase_anon_key> \
  --dart-define=QA_STUDENT_A_EMAIL=<qa_student_a_email> \
  --dart-define=QA_STUDENT_A_PASSWORD=<qa_student_a_password> \
  --dart-define=QA_STUDENT_B_EMAIL=<qa_student_b_email> \
  --dart-define=QA_STUDENT_B_PASSWORD=<qa_student_b_password> \
  --dart-define=QA_TEACHER_EMAIL=<qa_teacher_email> \
  --dart-define=QA_TEACHER_PASSWORD=<qa_teacher_password>
```

Do not commit these values.

## Android Automated

`flutter test integration_test` built and installed debug APKs while executing the integration suite. The environment accepted install/run, but no real Samsung/physical-device manual evidence was captured in this pass.

Status: `PARTIAL`

## Web Automated

Web build validation is covered separately by `flutter build web`. Browser click-through with Usuario A/B remains blocked by missing QA credentials.

Status: `BLOCKED_EXTERNAL_CONFIG`

## Gate Decision

Android Beta automated gate: `FAIL`

Reason: required automatic PASS for authenticated Auth, Upload, Home, Chat, Library, full Route Guards, full Multiuser Isolation and Logout/Login is not yet available without QA credentials and fixture data execution.
