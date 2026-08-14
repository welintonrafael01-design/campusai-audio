# Release Readiness

Current status: RELEASE CANDIDATE READY FOR MANUAL QA.

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
