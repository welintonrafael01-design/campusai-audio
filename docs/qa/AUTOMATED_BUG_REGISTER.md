# Automated Bug Register - StudyBook AI RC1

Updated: 2026-08-20

| ID | Severity | Module | Finding | Root cause | Status | Retest |
| --- | --- | --- | --- | --- | --- | --- |
| AUTO-P1-004 | P1 HIGH | Cloud Library | Real upload returned success but could be absent from Cloud Library. | Deployed legacy `documents` schema lacks `user_id`; insert error was swallowed by upload. | FIXED | Full Real Android `UPLOAD_PIPELINE=PASS` |
| AUTO-P1-005 | P1 HIGH | Document ownership/RAG | Identical PDFs uploaded by different users could receive the same document ID and overwrite the local ownership registry. | ID was a content-only hash. | FIXED | User-scoped ID test plus Student B direct attack PASS |
| AUTO-P2-006 | P2 MEDIUM | Cloud StudyResults | Missing foreign StudyResult produced HTTP 500. | Supabase `maybe_single()` can return `None`; service assumed `.data`. | FIXED | Student B foreign result returns null |
| AUTO-P2-007 | P2 MEDIUM | Cloud StudyResults | App resource types such as quiz, question bank and teaching plan were rejected. | Backend allowlist only contained flashcards and exam. | FIXED | Real artifacts and Teacher plan persisted |
| AUTO-P2-008 | P2 MEDIUM | Local privacy | Courses and roster used global SharedPreferences keys. | Services did not use `UserScopedStorage`. | FIXED | `user_scoped_teacher_data_test.dart` |
| AUTO-P2-009 | P2 MEDIUM | Chat persistence | All document chats resolved to a literal interpolation key. | Raw string prevented Dart interpolation. | FIXED | Distinct per-document chat key test |
| AUTO-P2-010 | P2 MEDIUM | Native/audio QA | Picker visuals, acoustic quality and physical microphone cannot be fully asserted in `integration_test`. | Native UI and physical I/O require human/device evidence. | MANUAL_GATE | Run physical Android QA |
| AUTO-P1-011 | P1 HIGH | Flutter Web / CORS | Full Real Web requests from Flutter's ephemeral localhost port failed preflight. | Backend allowed only a fixed set of local ports. | FIXED | Dynamic loopback preflight 200; external untrusted origin 400; canonical Web run CORS PASS |
| AUTO-P2-012 | P2 MEDIUM | Dashboard responsive | AI tool cards overflowed vertically at the real desktop shell width and at 390 px. | Grid aspect ratios left less height than the two-line card content required. | FIXED | Desktop and 390 px widget tests plus Web responsive smoke PASS |
| AUTO-P2-013 | P2 MEDIUM | Web QA runner | Flutter 3.41's legacy Web driver hung after app-side `All tests passed`. | SDK teardown did not return cleanly after Chrome lifecycle disposal. | FIXED | Supervised teardown requires `CORE` and `All tests passed` before controlled cleanup |

## Current Severity Summary

- Open P0: 0
- Open P1: 0
- Open P2 product defects from this run: 0
- Manual gates: picker visuals, audio quality, physical microphone and final
  human accessibility/responsive review

## Automation Gaps

The previous Core `AUTOMATION_GAP` items are closed by
`full_real_user_journey_e2e_test.dart`. The older granular tests remain for
targeted coverage, while the canonical runner executes the orchestrated journey
once to control AI cost.

Android and Web Full Real Core gates are now automated and closed. The remaining
gates are physical audio/microphone quality, picker visual behavior and final
human accessibility/device QA.
