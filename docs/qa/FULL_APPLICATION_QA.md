# StudyBook AI - Full Application QA

Date: 2026-09-04

Branch: `qa/studybook-ai-rc1`

Baseline: `4a8a17b7268b972c7424112bd209f03962fadadb`

Environment: disposable local Supabase, local FastAPI, Chrome 152, Flutter 3.41.9

## Scope And Safety

The audit used synthetic content and three disposable local identities mapped to
the canonical Student A, Student B and Teacher QA identifiers. No remote
Supabase project, deployment, tag, Play Console artifact or production record
was modified. Passwords, tokens and privileged keys were redacted and were not
written to tracked files.

## Automated Evidence

- Backend: `152 passed`, `0 failed`, 5 dependency deprecation warnings.
- Flutter: `130 passed`, `0 failed`.
- Flutter analyze: `No issues found`.
- Web release build: PASS with `https://api.studybookai.com`.
- Signed Android APK: PASS, 70.7 MB.
- Signed Android AAB: PASS, 54.3 MB.
- Release artifact credential scan: PASS.
- Tracked privileged-value scan: PASS.
- Browser lifecycle: hard reload, tab close/reopen, back/forward, `/learning`,
  390 px responsive smoke and Student A to Student B switch: PASS.
- Full local journey: auth, PDF upload, summary, chat, flashcards, quiz,
  question bank, exam, AudioBook, Voice Tutor text, Library, account,
  logout/login restore, Student B isolation, direct ownership denial, Teacher
  course/student/plan and guest route denial: PASS.
- Booky welcome pipeline: authenticated MP3 generation, authenticated Web fetch
  and player handoff: PASS. Human audibility remains the final physical check.
- 7F-S3 inherited at the tested baseline: local RLS, private Storage, pgvector,
  restart persistence, deterministic backfill and disposable account deletion:
  PASS.

## Result Matrix

| Module | Automated result | Human result | Final result | Issue | Severity |
|---|---|---|---|---|---|
| Login | PASS | Not required | PASS | - | - |
| Logout | PASS | Not required | PASS | - | - |
| Session restore | PASS: hard reload, app restart and tab reopen | Not required | PASS | QA-001 fixed | P1 |
| Auth guards | PASS: guest, Student, Teacher and Admin boundaries | Not required | PASS | - | - |
| Booky welcome generation | PASS: valid MP3 and authenticated Web playback request | Pending audible welcome check | PARTIAL | QA-002 fixed technically | P1 |
| Booky timeout/error UX | PASS: loading exits, inline error, retry and skip remain available | Not required | PASS | QA-002 fixed | P1 |
| Library | PASS: empty/data render, persistence and ownership | Native picker visual gate pending | PASS automated | - | - |
| Document upload | PASS: synthetic PDF, summary and cloud row | Native picker pending | PASS automated | - | - |
| Invalid/corrupt upload | PASS by PDF signature, MIME and size contracts | Not required | PASS | - | - |
| DOCX upload | Rejected by the current PDF-only product contract | Not required | N/A | - | - |
| Document detail | PASS in responsive/widget suite | Not required | PASS | - | - |
| Summary | PASS: generated for selected document and restored | Not required | PASS | - | - |
| Chat/RAG | PASS: contextual answer, history, source and ownership contracts | Not required | PASS | - | - |
| Flashcards | PASS: generation and persistence | Not required | PASS | - | - |
| Quiz | PASS: generation, payload and persistence | Not required | PASS | - | - |
| Question bank | PASS: generation and persistence | Not required | PASS | QA-003 fixed | P2 |
| Exam generator | PASS: generation and persistence | Not required | PASS | - | - |
| AudioBook | PASS: generation, local/cloud state, restore and owner-scoped audio contracts | Prior physical audible evidence exists; current run not physical | PASS automated | - | - |
| Voice Tutor | PASS: text/AI/TTS authorization contracts | Real microphone pending | PARTIAL | - | - |
| Free/Student Pro | PASS: capabilities, limits, spoof denial and legacy mappings | Not required | PASS | - | - |
| Teacher Pro | PASS: server role plus active plan required | Not required | PASS | - | - |
| Teacher core | PASS: course, student and teaching plan journey; service persistence tests for remaining core | Physical UX not rerun | PASS automated | - | - |
| Multiuser | PASS: cloud, local cache and direct resource attack | Not required | PASS | - | - |
| Account | PASS: plan, route and logout | Not required | PASS | - | - |
| Account deletion | PASS: local disposable lifecycle and 7 backend regression tests | Not required | PASS | - | - |
| Responsive Web | PASS: 320/390/411/430 and text scale coverage across suites | Visual review optional | PASS | - | - |
| Accessibility | PASS: semantics/error live region, text scale and compact layouts | Prior TalkBack evidence exists; current run not physical | PASS automated | - | - |
| Android | APK/AAB build PASS; regression tests PASS | No device connected | PARTIAL | QA-006 | P2 |
| Web | Release build and lifecycle probe PASS | Not required | PASS | - | - |
| Security | PASS: RLS, IDOR/BOLA, role/plan spoof, private audio and secret scans | Production deployment state not tested | PASS local | QA-007 | P1 |

## Root Cause And Remediation

### QA-001 Session restore

Supabase session recovery is asynchronous. `GoRouter` evaluated the guard at
startup but did not listen to `onAuthStateChange`, so a recovered session could
arrive after the app had already settled on `/auth`. A route refresh notifier is
now bound after Supabase initialization. The browser probe closes the tab,
opens a new one in the same browser context and confirms the same authenticated
identity and protected route.

### QA-002 Booky welcome

The welcome action inherited a 180-second API timeout and only emitted a brief
SnackBar on failure. It could therefore appear stuck and leave no useful error.
The dialog now applies a 45-second welcome timeout, keeps Skip/Continue
available, exposes a persistent accessible error and changes the action to
Retry. A second browser-level defect was found during the audible gate: the
HTML media request could not attach the bearer header required by `/audio`, so
the generated MP3 returned `401` during playback. Web playback now fetches
same-origin API audio with the authenticated HTTP client and passes a local
data URL to the player. Android and other IO targets retain direct URL playback
with request headers. Unit coverage verifies authenticated fetch, external URL
passthrough and authorization failure behavior.

### QA-003 Student-to-Educator noise

Student question-bank persistence reused the educator repository and attempted
`/educator/sync`, producing expected 403 responses and noisy browser errors.
`EducatorSyncService` now checks the verified Teacher capability before any
snapshot read or write. Backend authorization remains enforced independently.

### QA harness hardening

Local release builds correctly reject loopback API URLs. The local browser gate
now uses a profile build, explicit IPv4 and a static server that does not depend
on reverse DNS. `/learning` is verified in Playwright because ChromeDriver can
intermittently stall while frame-pumping that large dashboard despite the real
browser remaining responsive. AI calls in the journey have a 90-second QA
budget and report provider latency as an external block instead of a product
assertion failure.

## Release Decision

Local application quality gate: PASS with human/remote conditions. Controlled
production Supabase migration remains blocked until an approved window applies
and verifies the already-tested migrations against the intended remote project.
Google Play internal release also remains blocked until final Play Console
product IDs and physical-device gates are confirmed.
