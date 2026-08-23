# Physical Production Retest

## Scope

- Date: 2026-08-23
- Baseline commit: `fbf21781d7601684b9b76fb2471ceec4154fef35`
- Branch: `qa/studybook-ai-rc1`
- Device: Samsung SM-N975U (`RF8M735ZA3R`)
- Android: 12 / API 31
- Backend health build SHA: `fbf21781d7601684b9b76fb2471ceec4154fef35`
- API transport: `adb reverse tcp:8000 tcp:8000`
- QA secrets: validated by the repository helper; no credential values were logged.

This report records evidence gathered on the physical Samsung. It does not
promote the build to RC2, create a tag, push changes, or publish to Google Play.

## Automated Evidence

| Check | Result | Evidence |
| --- | --- | --- |
| Backend compile | PASS | `python3 -m py_compile` completed without error. |
| Backend tests | PASS | 66 passed; only five existing SWIG deprecation warnings. |
| Flutter tests | PASS | 86 passed. |
| Flutter analyze | PASS | No issues found. |
| Release APK | PASS | Built successfully, 69.7 MB configured physical-test artifact. |
| Release AAB | PASS | Built successfully, 53.3 MB. |
| Web release | PASS | Built successfully; Wasm dry run also succeeded. |
| Android real E2E | PASS | Student A, Student B, Teacher, guest guards, ownership denial and cloud isolation completed on the Samsung. |

## Backend Version Safety

The previous process on port 8000 was stopped. A clean backend was started
from the baseline commit with an explicit `APP_BUILD_SHA`. `/health` returned:

- status: `ok`
- service: `StudyBook AI API`
- build SHA: `fbf21781d7601684b9b76fb2471ceec4154fef35`

The backend was stopped during the controlled offline test and then restarted
with the same build SHA.

## Student A Journey

| Scenario | Result | Observation |
| --- | --- | --- |
| Login, Home, Library, Learning, Account, logout | PASS | Real QA identity and real backend. |
| Native PDF picker | PASS | Android native picker opened and accepted a real PDF. |
| Document detail | PASS | Fresh CIAG document opened and remained available after restart. |
| Summary | PASS | Fresh summary described CIAG, CNC, accessibility, disability rights, inclusion and employment. |
| Chat | PASS | Physical Samsung keyboard used for a CIAG question; response was semantically correct. |
| Chat with IME | PASS | No RenderFlex stripe or inaccessible submit control observed. |
| RAG sources | PASS | UI showed `Fuentes (5)`, a real page and legible excerpts; no chunk, score, embedding or confidence labels. |
| Flashcards and quiz | PASS | Generated and persisted in the real E2E. |
| Voice Tutor text flow | PASS | Tutor route, contextual text flow and permission request remained stable. |
| Voice Tutor microphone | NOT CERTIFIED | Android opened the real permission flow and started the system recognizer, but spoken capture was not human-confirmed. The original denied permission state was restored. |

## CIAG Semantic Evidence

The fresh physical upload used Resolution 0006-2025 concerning the Commission
for Government Inclusion and Accessibility (CIAG). Its summary and chat answer
were about the actual resolution, not research methodology. Source fragments
matched the document.

A legacy CIAG record remains in the QA account with stale methodology artifacts
and a failing old download reference. It was not deleted or rewritten because
this retest forbids destructive migration. This is a P2 data-migration issue,
not a failure of the fresh upload pipeline.

## AudioBook Physical Evidence

### Remediation

Physical TTS generation initially failed before its backend request. The root
cause was a runtime covariance mismatch: normalized chapter literals were
created as `Map<String, Object>` while `firstWhere` required
`Map<String, dynamic>`. The service now emits an explicitly typed map, derives
a stable restored AudioBook ID, and returns safe failure markers that never
persist. A regression test exercises the restored chapter runtime type.

### Validation

| Scenario | Result | Observation |
| --- | --- | --- |
| Correct source document | PASS | Five CIAG chapters contained the correct source semantics. |
| TTS generation | PASS | Backend generated chapter 1 MP3 and returned HTTP 200. |
| Local state | PASS | UI changed to `Regenerar audio`; generated URL remained in the local result. |
| Cloud save | PASS | StudyResult cloud save and subsequent cloud reads returned HTTP 200. |
| Cloud restore | PASS | Force-stop/reopen restored the same CIAG AudioBook and chapter progress. |
| Real player pipeline | PASS | Progress advanced from 0:00; ExoPlayer initialized and Android reported `AudioTrack state: started`. |
| Completion/chapter transition | PASS | Chapter 1 reached its end and selected the next chapter without crash. |
| Speed | PASS | 1.25x was selected in the installed release. |
| Player controls | PARTIAL | Play, progress, restart, speed, completion and next-chapter behavior were observed. Pause, seek -10/+10 and every chapter button were not all independently human-confirmed. |
| Audible speaker output | NOT CERTIFIED | The OS media path was active, but an on-site listener did not confirm physical speaker sound. |
| Offline fallback | PASS | With port 8000 stopped, persisted content stayed visible and playback changed to a human `modo lectura guiada` message without crash. |
| Retry after network restore | PASS | After `/health` recovered, the same chapter returned to real playback and `AudioTrack state: started` without regeneration. |
| Duplicate after retry | PASS | Offline playback did not create another StudyResult. |

## Multiuser and Authorization

| Scenario | Result | Observation |
| --- | --- | --- |
| Student A to Student B cloud isolation | PASS | B could not read A documents, StudyResults, chats or AudioBooks. |
| Local cache isolation | PASS | User-scoped history and active resources did not expose A to B in the E2E. |
| Direct ownership attack | PASS | A resource ID requested as B returned denied/absent. |
| Student teacher-route denial | PASS | UI guards and backend educator denial both passed. |
| Admin denial | PASS | Student A, Student B and QA Teacher are not admins. |

## Teacher Evidence

Teacher login, Teacher Studio visibility, course creation, student roster,
teacher document upload, teaching-plan generation and persistence passed in the
real physical E2E. Attendance, grades, weights, rubrics, question bank and
exams were not each completed manually on the physical device in this retest,
so the complete Teacher physical gate remains open.

## Accessibility, Responsive and Performance

- Automated 320/360/390/411 px and text-scale 1.3 tests passed.
- Physical text scale 1.3 was checked on Home, Library, document content, Chat
  with IME and AudioBook. No critical overflow appeared. System scale was
  restored to 1.0.
- A minor truncation of `Más reciente` was observed at large text (P3).
- Touch targets and semantic labels were present on the core screens inspected.
- TalkBack was disabled and no complete human TalkBack traversal was performed;
  the accessibility gate is therefore not fully certified.
- Profile cold launch samples were approximately 0.7-1.7 seconds. A short
  profile frame sample showed no jank but is too small for a percentile claim.
- Installed release cold launch was 838 ms, with approximately 130 MB total PSS
  and 253 MB RSS after startup.
- A short release Library interaction rendered two sampled frames with zero
  janky frames at 10 ms. This is supporting evidence, not a load benchmark.

## Crash and Privacy Review

No StudyBook `FATAL EXCEPTION`, ANR, SIGSEGV, OOM, unhandled Flutter exception,
or RenderFlex event was found in the captured release log. Count-only scans
found no QA password, full authorization value, JWT-like bearer value, full
Supabase anon key, OpenAI secret, backend host filesystem path, document body or
full AI summary in logcat.

## Open Issues

### P0

None.

### P1

None confirmed after the AudioBook chapter-map remediation.

### P2

1. Human confirmation of physical speaker audibility is still required.
2. Human spoken-input capture and response are still required for Voice Tutor.
3. Complete physical Teacher subflows remain to be executed.
4. Human TalkBack traversal remains to be executed.
5. Legacy CIAG QA artifacts need a non-destructive migration/deduplication plan.

### P3

1. Fresh filenames may lose accents inherited from source filename encoding.
2. `Más reciente` truncates at physical text scale 1.3.

## Gate Decision

The automated production baseline, real multiuser isolation, CIAG semantics,
AudioBook generation/cloud restore and technical player path pass. The overall
Physical Production Gate remains **FAIL / NOT CERTIFIED** because speaker
audibility, spoken microphone capture, complete Teacher physical coverage and
TalkBack still need direct human evidence. No P0 or confirmed P1 is open.
