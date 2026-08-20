# Full Real Android E2E Report - StudyBook AI RC1

Generated: 2026-08-17

Branch: `qa/studybook-ai-rc1`

Runner: `tools/qa/run_full_android_e2e.sh`

Run: `QA/automated/runs/20260817_233509_android`

## Decision

`FULL REAL ANDROID CORE E2E: PASS`

The canonical Android journey finished with `All tests passed` and
`E2E_RESULT CORE=PASS`. Supabase Auth, FastAPI, Supabase persistence,
subscriptions, ownership checks and AI providers were real. No mock response
was used for authentication, backend, ownership, subscription or cloud data.

## Automated Evidence

| Area | Result | Evidence |
| --- | --- | --- |
| Student A auth, role, plan and subscription | PASS | `STUDENT_A_AUTH=PASS` |
| Home and real PDF upload pipeline | PASS | `HOME=PASS`, `UPLOAD_PIPELINE=PASS` |
| Summary | PASS | Non-empty summary persisted on the Cloud document |
| Chat | PASS | Real RAG response plus Cloud chat/messages |
| Flashcards | PASS | Real generation and user-scoped StudyResult |
| Quiz | PASS | Real generation and user-scoped StudyResult |
| Question Bank | PASS | Real generation and user-scoped StudyResult |
| Exam | PASS | Real generation and user-scoped StudyResult |
| AudioBook metadata | PASS | Real generation plus Cloud/local repositories |
| Voice Tutor textual path | PASS | Real `/voice/coach` response |
| Library and Learning | PASS | Generated document/resources visible and persisted |
| Account and session restore | PASS | Active Student plan and logout/login restoration |
| Student B isolation | PASS | No A documents, results, chats, AudioBooks or local history |
| Direct ownership attack | PASS | A document denied with 403; A StudyResult returned null |
| Teacher auth and Teacher Studio | PASS | Real course, roster, upload and one-week teaching plan |
| Student to Teacher route/backend | PASS | UI denied and `/educator/snapshot` returned 403 |
| Admin access | PASS | Student A, Student B and Teacher denied |
| Guest private route | PASS | Redirected to Auth |

Non-sensitive artifact identifiers are stored only in the run's
`artifact-manifest.txt`. Passwords, tokens and authorization headers are not
included.

## Manual Gates

| Gate | Status | Reason |
| --- | --- | --- |
| Native Android picker visual behavior | MANUAL_GATE | The integration seam supplies the real PDF after picker selection; upload and processing remain real. |
| AudioBook acoustic quality | MANUAL_GATE | Requires human listening on target hardware. |
| Voice Tutor physical microphone quality | MANUAL_GATE | Requires physical input and permission QA. |
| Samsung/device UX and final human accessibility | MANUAL_GATE | Requires physical-device evidence. |

## Fixes Proven By The Run

- User-scoped document IDs prevent two users uploading identical content from
  sharing a registry/RAG identifier.
- Cloud library persistence supports both the current `user_id` schema and the
  deployed legacy schema, using the user-scoped storage path as ownership
  authority in the latter.
- Missing StudyResults return null instead of a backend 500.
- Product StudyResult types used by Teacher/Student flows are accepted by the
  Cloud allowlist.
- Courses, roster and chat history use user-scoped local keys.

## Release Position

Core Android automated gate: `PASS`

Open P0: `0`

Open P1: `0`

Web Full Real E2E: not executed in this sprint.

RC2 review: ready after the listed manual gates and Web Full Real E2E.
