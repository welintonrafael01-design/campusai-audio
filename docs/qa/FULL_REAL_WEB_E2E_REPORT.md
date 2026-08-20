# Full Real Web E2E Report - StudyBook AI RC1

Branch: `qa/studybook-ai-rc1`

Executed: 2026-08-20

Canonical run: `QA/automated/runs/20260820_173702_web`

## Decision

`FULL REAL WEB CORE E2E = PASS`

The canonical Chrome run exited with code `0`. It used real Supabase Auth,
FastAPI, Cloud persistence and AI services. No QA identity, role, plan or Stripe
record was modified.

## Automated Evidence

| Gate | Result | Evidence |
| --- | --- | --- |
| Student A Auth and subscription | PASS | Student role/plan, active subscription |
| Home and real PDF upload | PASS | Owned Cloud document and non-empty summary |
| Chat, Flashcards, Quiz | PASS | Real AI output persisted by type |
| Question Bank and Exam | PASS | Real AI output persisted by type |
| AudioBook and Voice Tutor text | PASS | Metadata/artifact and coach response |
| Library and Learning | PASS | Owned document/resources visible after remount |
| Account and logout/login restore | PASS | Identity, plan and artifacts restored |
| Hard reload | PASS | Private Library route and Student A identity preserved |
| Browser back/forward | PASS | Dashboard/Library history remained authorized and usable |
| Student B isolation | PASS | No Student A Cloud/local data visible |
| Direct ownership attack | PASS | Foreign document denied; foreign StudyResult absent |
| Browser cache isolation | PASS | Session switched from A to B without stale identity |
| Teacher Auth and Teacher Studio | PASS | Course, roster, upload and teaching plan persisted |
| Student to Teacher | PASS | UI route denied and backend returned HTTP 403 |
| Admin | PASS | Denied for Student A, Student B and Teacher |
| CORS | PASS | Exact and ephemeral loopback origins accepted only locally |
| Responsive | PASS | Flutter smoke plus browser routes at 390 x 844 |
| Console errors | PASS | `console-errors.log` is empty |
| Web build | PASS | Release build completed |
| Secrets review | PASS | No QA credential or privileged backend value in Web build |

The sanitized marker source is
`QA/automated/runs/20260820_173702_web/artifact-manifest.txt`. Browser evidence
includes before/after reload and 390 px screenshots under the run's `browser/`
directory.

## Fixes Validated

1. FastAPI CORS now accepts dynamic Flutter Web ports only for `localhost` and
   `127.0.0.1`; an untrusted external origin remains rejected.
2. Dashboard AI cards received enough vertical space at the real desktop shell
   width and at 390 px. Focused widget tests cover both constraints.
3. The Web runner uses the shared Full Real journey through `flutter drive`,
   supervises the known post-test SDK teardown hang, closes child processes and
   preserves the application test result.
4. The release browser probe automates hard reload, back/forward, responsive
   routing and the Student A to Student B storage transition.

## Manual Gates

- `WEB_FILE_PICKER`: visual behavior only. The automated seam still sends a
  real PDF through the production upload/backend pipeline.
- `AUDIOBOOK_SOUND`: human acoustic quality.
- `VOICE_TUTOR_MICROPHONE`: physical microphone and permission quality.
- Final human accessibility and responsive visual review remain release gates,
  not Core automation gaps.

## Regression

- Backend: `23 passed`; `python -m compileall app` passed.
- Flutter format: no changes required.
- Flutter analyze: 0 errors, 0 warnings, 4 historical async-context infos.
- Flutter unit/widget tests: `25 passed`.
- Flutter Web build: passed.
- QA shell syntax, Python compile and `git diff --check`: passed.

## Severity

- Open P0: 0
- Open P1: 0
- Open P2 Core Web defects: 0
- Blocked external configuration: none
- Core automation gaps: 0
