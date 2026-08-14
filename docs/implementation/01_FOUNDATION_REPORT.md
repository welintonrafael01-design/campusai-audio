# Phase 1 — Foundation / P0 Report

## Implemented

- Added `AppEnvironment` and moved `ApiService.baseUrl` away from hardcoded `http://localhost:8000`.
- Added `DocumentUploadController` with explicit states: idle, picking, selected, uploading, processing, success, cancelled, unsupported, network error, auth error, server error and processing error.
- Updated dashboard upload flow so `FilePicker` runs before any blocking progress dialog.
- Added retry path for retryable upload failures.
- Removed frontend use of `ADMIN_API_KEY` in `AnalyticsService`.
- Added backend admin-session guard for analytics based on authenticated user and `ADMIN_EMAILS`.
- Added first global GoRouter redirect for public/auth/teacher/admin paths.
- Added canonical route aliases: `/learning`, `/teacher`, `/account`.
- Updated sidebar to use canonical route aliases.

## Reused

- Existing `ApiService`, `HistoryService`, `RecentDocumentsService`, `CloudApiService`, Supabase Auth and existing screens.

## Known compatibility notes

- `/teacher` currently aliases to `CoursesScreen` until the dedicated `TeacherStudioScreen` phase.
- Role/capability authority is a compatibility layer using Supabase user metadata plus legacy local plan cache. Full backend entitlement model remains pending.
- Historical routes are preserved.

## Tests added

- `test/document_upload_controller_test.dart`

## Pending for later phases

- App shell with mobile bottom navigation.
- Dedicated Teacher Studio home.
- Account unification.
- Full backend route ownership test suite.

