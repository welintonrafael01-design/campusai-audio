# StudyBook AI - Full Application QA

Date: 2026-09-05

Branch: `qa/studybook-ai-rc1`

Baseline before final Voice Tutor closure: `87546e517a5c024b07de11ebe79e051a14151705`

Environment: disposable local Supabase, local FastAPI, Chrome 152, Flutter 3.41.9

## Scope And Safety

The audit used synthetic content and three disposable local identities mapped to
the canonical Student A, Student B and Teacher QA identifiers. No remote
Supabase project, deployment, tag, Play Console artifact or production record
was modified. Passwords, tokens and privileged keys were redacted and were not
written to tracked files.

## Automated Evidence

- Backend: `152 passed`, `0 failed`, 5 dependency deprecation warnings.
- Flutter: `141 passed`, `0 failed`.
- Flutter analyze: `No issues found`.
- Voice Tutor service coverage: `16 passed`, including permission, start,
  partial/final transcript, stop, cancel, cleanup, retryable failures, AI/TTS
  integration and owner-scoped session isolation.
- Backend security-focused suite: `88 passed`, `0 failed`, 5 known dependency
  deprecation warnings.
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
  and player handoff: PASS. Human audibility confirmed in Chrome on 2026-09-04.
- Voice Tutor local API pipeline: authenticated coach response, authenticated
  TTS generation/fetch and cross-user audio denial: PASS. Human Web microphone,
  response and audible playback confirmed on 2026-09-05.
- Physical evidence retained from the unaffected Android paths: Samsung
  microphone recognition/response/audio, AudioBook audible playback and
  TalkBack traversal: PASS.
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
| Booky welcome generation | PASS: valid MP3 and authenticated Web playback request | PASS: audible welcome confirmed in Chrome | PASS | QA-002 fixed | P1 |
| Booky timeout/error UX | PASS: loading exits, inline error, retry and skip remain available | Not required | PASS | QA-002 fixed | P1 |
| Library | PASS: empty/data render, persistence and ownership | Physical Android library and native picker previously passed | PASS | - | - |
| Document upload | PASS: synthetic PDF, summary and cloud row | Physical native picker and real PDF previously passed | PASS | - | - |
| Invalid/corrupt upload | PASS by PDF signature, MIME and size contracts | Not required | PASS | - | - |
| DOCX upload | Rejected by the current PDF-only product contract | Not required | N/A | - | - |
| Document detail | PASS in responsive/widget suite | Not required | PASS | - | - |
| Summary | PASS: generated for selected document and restored | Not required | PASS | - | - |
| Chat/RAG | PASS: contextual answer, history, source and ownership contracts | Not required | PASS | - | - |
| Flashcards | PASS: generation and persistence | Not required | PASS | - | - |
| Quiz | PASS: generation, payload and persistence | Not required | PASS | - | - |
| Question bank | PASS: generation and persistence | Not required | PASS | QA-003 fixed | P2 |
| Exam generator | PASS: generation and persistence | Not required | PASS | - | - |
| AudioBook | PASS: generation, local/cloud state, restore and owner-scoped audio contracts | Physical Samsung audible/player/cloud restore evidence remains valid; current changes do not alter IO playback | PASS | - | - |
| Voice Tutor | PASS: permission/listen/stop/cancel/transcript/error/cleanup plus authenticated AI/TTS and ownership | PASS: Web real mic heard the user, returned a response and played audible audio; prior Samsung physical mic evidence remains valid | PASS | QA-006 closed | P2 |
| Free/Student Pro | PASS: capabilities, limits, spoof denial and legacy mappings | Not required | PASS | - | - |
| Teacher Pro | PASS: server role plus active plan required | Not required | PASS | - | - |
| Teacher core | PASS: course, student and teaching plan journey; service persistence tests for remaining core | Prior physical Teacher closure remains valid | PASS | - | - |
| Multiuser | PASS: cloud, local cache and direct resource attack | Not required | PASS | - | - |
| Account | PASS: plan, route and logout | Not required | PASS | - | - |
| Account deletion | PASS: local disposable lifecycle and 7 backend regression tests | Not required | PASS | - | - |
| Responsive Web | PASS: 320/390/411/430 and text scale coverage across suites | Visual review optional | PASS | - | - |
| Accessibility | PASS: semantics/error live region, text scale and compact layouts | PASS: prior physical TalkBack traversal covered core Student, Voice Tutor, AudioBook, Teacher and Account flows | PASS | QA-006 closed | P2 |
| Android | APK/AAB build PASS; regression tests PASS | PASS: retained Samsung Android 12 evidence covers login, upload, microphone, AudioBook, Teacher, TalkBack and isolation; affected current changes are service seams/Web audio only | PASS | QA-006 closed | P2 |
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

### QA-006 physical and human closure

The earlier Samsung production retest already certified real microphone input,
Voice Tutor processing and audible response, AudioBook audible playback and a
TalkBack traversal across the critical routes. The final local closure added
deterministic service tests for the Voice Tutor lifecycle and repeated the real
microphone, response and audible TTS interaction in Chrome on 2026-09-05. The
tester reported all three checks working correctly. No current change altered
the Android audio or accessibility UI paths, so the physical evidence remains
applicable and `QA-006` is closed.

## Release Decision

Local application quality gate: PASS. Controlled production Supabase migration
remains an external release gate until an approved window applies and verifies
the already-tested migrations against the intended remote project. Google Play
internal release also remains an external gate until final Play Console product
IDs and verification configuration are supplied. Neither is an open product
bug in the locally tested application.
