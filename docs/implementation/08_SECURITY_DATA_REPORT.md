# Phase 8 — Security / Data Report

Status: COMPLETE.

## Scope completed

- Added deterministic test support for `UserScopedStorage` without changing production scope resolution.
- Fixed `StudyResultService` key construction so new results use real `documentId/type/user` scoped keys.
- Added compatibility fallback for legacy literal keys.
- Hardened `StudyResultService.getResult` so legacy reads must match the requested `documentId` and `type`.
- Updated `deleteResult` to remove both current and legacy scoped keys.
- Added tests proving StudyResult isolation between user scopes and safe legacy-key validation.

## Bug fixed

Older key construction used escaped interpolation, producing literal keys instead of discoverable scoped keys. Direct `getResult` could still read the same literal key, but list APIs such as `getResultsByType` could not reliably discover resources. The fix restores proper scoped keys and keeps a safe fallback for old local data.

## Secret hygiene

- No `ADMIN_API_KEY`, `dart:html` import or `sk-` pattern appears in real Flutter `.dart` files.
- `OPENAI_API_KEY` remains server-side only; a frontend scanner string is allowed as a detection pattern, not a secret.

## Validation

- `flutter analyze`: 0 errors, 4 historical infos in `courses_screen.dart`.
- `flutter test`: all tests passed.
- Backend `py_compile`: OK.
- Backend `pytest backend/tests`: 2 passed.
- `git diff --check`: OK.
