# Automated User Journey Report - StudyBook AI RC1

Branch: `qa/studybook-ai-rc1`

Generated: 2026-08-17

Canonical run: `QA/automated/runs/20260817_233509_android`

## Execution Summary

| Category | Count |
| --- | ---: |
| Core journeys failed | 0 |
| Core journeys blocked by external config | 0 |
| Core automation gaps | 0 |
| Explicit manual gates | 3 |

Runner result: `All tests passed` / `CORE=PASS`.

## Canonical Journey

```text
Student A
  Auth -> Home -> real PDF upload -> AI resources -> Library -> Learning
  -> Account -> Logout -> Login -> persisted data

Student B
  Auth -> Cloud/local isolation -> direct document attack -> direct result check

Teacher
  Auth -> course/roster fixture -> Teacher Studio -> real PDF upload
  -> real teaching plan -> Logout

Guest
  Private route denied
```

## Result Matrix

| Journey | Result | Persistence/authorization evidence |
| --- | --- | --- |
| Student A Auth | PASS | Real Supabase user, Student role, Student plan, active subscription |
| Home | PASS | Authenticated dashboard route |
| Upload | PASS | Real PDF bytes through production upload controller and FastAPI pipeline |
| Summary | PASS | Non-empty summary on owned Cloud document |
| Chat | PASS | RAG backend plus Cloud chat and messages |
| Flashcards | PASS | Cloud/local StudyResult |
| Quiz | PASS | Cloud/local StudyResult |
| Question Bank | PASS | Cloud/local StudyResult |
| Exam | PASS | Cloud/local StudyResult |
| AudioBook | PASS | Real metadata, Cloud audiobook and local library entry |
| Voice Tutor text | PASS | Real coach endpoint response |
| Library | PASS | Owned document visible |
| Learning | PASS | Generated resources available |
| Account | PASS | Plan/subscription synchronized |
| Logout/Login restore | PASS | Session cleared; document and summary restored after login |
| Student B Auth | PASS | Real Supabase user, Student role/plan, active subscription |
| Multiuser isolation | PASS | No Student A Cloud or local artifacts visible |
| Ownership attack | PASS | Document 403; foreign StudyResult absent |
| Teacher Auth | PASS | Teacher role/plan, active subscription, Admin denied |
| Teacher Studio | PASS | Course and roster visible; owned teaching plan generated/persisted |
| Student -> Teacher | PASS | Route denied and backend 403 |
| Admin | PASS | Denied for all three QA identities |
| Guest | PASS | Private route redirects to Auth |

## Test Architecture

- `full_real_user_journey_e2e_test.dart` is the canonical cost-controlled run.
- `full_real_e2e_support.dart` orchestrates real services and records sanitized
  `E2E_RESULT`, `E2E_ARTIFACT` and `E2E_MANUAL_GATE` markers.
- `e2e_real_fixture.dart` embeds the existing small QA PDF only in integration
  test code. It bypasses native picker UI but does not bypass upload, backend,
  AI, ownership or persistence.
- `E2E_JOURNEY_SCOPE=teacher` is a diagnostic-only mode. The official runner
  does not set it and always executes the complete sequence.
- Credentials remain in ignored local JSON and are supplied with
  `--dart-define-from-file`; logs are passed through `redact_qa_output.py`.

## Manual Gates

- Native Android picker visual behavior.
- AudioBook acoustic quality.
- Voice Tutor physical microphone quality.

Physical Samsung UX and final human accessibility remain release-level manual
checks outside the automated Core journey.

## Gate Decision

Android Full Real Core: `PASS`

Ready for Web Full Real E2E: `YES`

Ready for RC2 review: `YES`, after Web and manual device gates are recorded.
