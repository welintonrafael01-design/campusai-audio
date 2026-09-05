# Release Readiness

Current status: RELEASE CANDIDATE IMPLEMENTATION UNDER LOCAL QA.

## W2.1 Free Cost Control

- FastAPI is the entitlement and quota authority.
- Free quotas are monthly: 3 documents, 10 chat messages, 3 summaries, one
  flashcard set, and one quiz.
- Free AudioBook, Voice Tutor, Question Bank, Exam Generator, and Teacher Core
  are rejected server-side with structured upgrade guidance.
- Student Pro retains learning capabilities; Teacher Pro adds Teacher Core and
  still requires a server-authorized Teacher role.
- `user_usage_events` remains the single usage ledger with user-scoped RLS and
  service-side writes.
- Marketing copy reflects the enforceable contract and does not promise
  unlimited generation.

Release still requires a production migration/configuration verification and
human concurrency/load review of quota enforcement before broad public scale.

The rebuilt StudyBook AI v1 core is now coherent across Inicio, Biblioteca, Aprendizaje, Teacher Studio and Cuenta.

## Automated validation

- Backend `py_compile`: OK.
- Backend `pytest backend/tests`: 2 passed.
- `flutter analyze`: 0 errors, 4 historical infos in `courses_screen.dart`.
- `flutter test`: all tests passed.
- `flutter build web`: OK.

## Required before public release

- Android smoke test on a real device.
- Web smoke test with two real users.
- Stripe checkout/portal smoke with real test-mode accounts.
- Manual accessibility pass.
- Final review of historical secret exposure and rotation needs.
