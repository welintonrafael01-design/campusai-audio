# RC1 Execution Matrix - StudyBook AI v1.0

Branch: `qa/studybook-ai-rc1`
Base tag: `studybook-v1-rc1`
Base commit: `7837a72`
Generated: 2026-08-13

## Status Legend

- `PASS`: verified by automated command or direct local evidence.
- `FAIL`: reproduced failure.
- `BLOCKED`: cannot proceed due missing external config or unavailable dependency.
- `MANUAL_REQUIRED`: requires human/device/browser verification.
- `NOT_TESTED`: not executed in this pass.

## Automatic Baseline

| Area | Command | Result | Notes |
| --- | --- | --- | --- |
| Git base | `git tag --list "studybook-v1-rc1"` | PASS | Tag exists. |
| QA branch | `git switch -c qa/studybook-ai-rc1 studybook-v1-rc1` | PASS | RC1 branch protected. |
| Dart format check | `dart format --output=none --set-exit-if-changed .` | FAIL | 33 files would be formatted; no diff was written. Classified P2 because runtime is unaffected. |
| Flutter analyze | `flutter analyze` | PASS | 0 errors, 0 warnings, 4 historical infos in `courses_screen.dart`. |
| Flutter tests | `flutter test` | PASS | 9 tests passed. |
| Web build | `flutter build web` | PASS | `build/web` generated. |
| Backend tests | `python -m pytest` | PASS | 2 tests passed. |
| Backend compile | `python -m compileall app` | PASS | Completed. |
| Android debug APK | `flutter build apk --debug` | PASS | `build/app/outputs/flutter-apk/app-debug.apk` generated. |
| Android release APK | `flutter build apk --release` | PASS | `build/app/outputs/flutter-apk/app-release.apk` generated. |
| Device detection | `adb devices` | MANUAL_REQUIRED | No connected device reported. |

## AUTH

| Flow | Status | Evidence | Notes |
| --- | --- | --- | --- |
| Login | MANUAL_REQUIRED | Browser/device session required. | Validate with Usuario A and Usuario B. |
| Logout | MANUAL_REQUIRED | Browser/device session required. | Must clear active user scope. |
| Session restore | MANUAL_REQUIRED | Browser/device restart required. | Verify dashboard loads correct account. |
| Reset password | MANUAL_REQUIRED | Email provider/config required. | Validate only in test mode. |

## HOME

| Flow | Status | Evidence | Notes |
| --- | --- | --- | --- |
| Initial load | MANUAL_REQUIRED | Visual QA required. | Use web and Android debug APK. |
| Upload PDF | MANUAL_REQUIRED | Backend and browser/device required. | Must verify document ownership. |
| Cancel picker | PASS | `document_upload_controller_test.dart`. | Automated controller coverage exists. |
| Successful upload | MANUAL_REQUIRED | Real PDF upload required. | Must verify active document and library sync. |
| Upload error | MANUAL_REQUIRED | Simulated backend error required. | Check human-readable message. |
| Active document | MANUAL_REQUIRED | Real session required. | Must persist per user scope. |
| Change document | MANUAL_REQUIRED | Real library data required. | Must update dashboard metrics. |
| Recent documents | MANUAL_REQUIRED | Real user data required. | Must not leak other users. |

## AI TOOLS

| Flow | Status | Evidence | Notes |
| --- | --- | --- | --- |
| Chat | MANUAL_REQUIRED | API key/backend runtime required. | Validate no cross-user history. |
| Summary | MANUAL_REQUIRED | API key/backend runtime required. | Validate active document context. |
| AudioBook | MANUAL_REQUIRED | TTS/browser/device audio required. | Basic flow can be P2 if audio provider limitations occur. |
| Voice Tutor | MANUAL_REQUIRED | Microphone permission required. | Validate permission messaging. |
| Flashcards | MANUAL_REQUIRED | Active document required. | Verify persistence under current user. |
| Quiz | MANUAL_REQUIRED | Active document required. | Verify persistence under current user. |
| Question bank | MANUAL_REQUIRED | Teacher context required. | Verify unit/document source metadata. |
| Generate exam | MANUAL_REQUIRED | Teacher context required. | Verify generated exam opens. |

## LIBRARY

| Flow | Status | Evidence | Notes |
| --- | --- | --- | --- |
| Documents | MANUAL_REQUIRED | Two-user browser QA required. | Isolation is required for beta. |
| Generated | MANUAL_REQUIRED | Generated resources required. | Verify user-scoped StudyResults. |
| AudioBooks | MANUAL_REQUIRED | AudioBook data required. | Verify user-scoped storage. |
| Chats | MANUAL_REQUIRED | Chat history required. | Verify logout/login separation. |
| Favorites | MANUAL_REQUIRED | Favorite actions required. | Verify local/cloud sync. |
| Search | MANUAL_REQUIRED | Library data required. | Check empty/no-results states. |
| Refresh | MANUAL_REQUIRED | Cloud/local state required. | Check no duplicate cards. |
| Delete | MANUAL_REQUIRED | Document fixture required. | Card should disappear immediately. |
| User isolation | MANUAL_REQUIRED | Usuario A/B required. | Release gate. |

## LEARNING

| Flow | Status | Evidence | Notes |
| --- | --- | --- | --- |
| Continue learning | MANUAL_REQUIRED | Student progress required. | Validate empty state. |
| Progress | MANUAL_REQUIRED | Learning data required. | Verify scoped metrics. |
| Recent flashcards | MANUAL_REQUIRED | Generated data required. | Verify list and empty state. |
| Recent quiz | MANUAL_REQUIRED | Generated data required. | Verify scores. |
| Voice Tutor | MANUAL_REQUIRED | Device permission required. | Validate permission fallback. |
| Recent AudioBook | MANUAL_REQUIRED | AudioBook required. | Validate resume CTA. |

## TEACHER

| Flow | Status | Evidence | Notes |
| --- | --- | --- | --- |
| Teacher Studio entry | MANUAL_REQUIRED | Teacher plan/session required. | Student must be blocked. |
| Courses | MANUAL_REQUIRED | Teacher data required. | Verify course list and empty state. |
| Students | MANUAL_REQUIRED | Course roster required. | Verify scoped roster. |
| Planning | MANUAL_REQUIRED | Course document required. | Verify teaching plan persistence. |
| Rubric | MANUAL_REQUIRED | Unit resource required. | Verify generated resource state. |
| Question bank | MANUAL_REQUIRED | Unit source document required. | Verify generation and repository. |
| Exam | MANUAL_REQUIRED | Question bank required. | Verify import/opening. |
| Attendance | MANUAL_REQUIRED | Roster/date required. | Verify date persistence. |
| Gradebook | MANUAL_REQUIRED | Activities required. | Verify Academic Engine imports. |
| Final report | MANUAL_REQUIRED | Grades required. | Verify consolidated report. |

## ACCOUNT

| Flow | Status | Evidence | Notes |
| --- | --- | --- | --- |
| Profile | MANUAL_REQUIRED | Authenticated user required. | Validate plan and account data. |
| Plan | MANUAL_REQUIRED | Billing backend/config required. | See Stripe report. |
| Usage | MANUAL_REQUIRED | `/billing/usage/me` runtime required. | Validate no admin key. |
| Accessibility | MANUAL_REQUIRED | UI/browser settings required. | See accessibility review. |
| Language | MANUAL_REQUIRED | UI session required. | Validate ES/EN/PT/FR/IT/DE if exposed. |
| Appearance | MANUAL_REQUIRED | UI session required. | Validate dark/light/high contrast. |
| Logout | MANUAL_REQUIRED | Auth session required. | Must clear user scoped caches. |

## SECURITY

| Flow | Status | Evidence | Notes |
| --- | --- | --- | --- |
| Student cannot access Teacher by URL | MANUAL_REQUIRED | Auth role session required. | Release gate. |
| Non-admin cannot access Admin | PARTIAL | Backend admin tests pass. | UI route still requires manual verification. |
| Guest cannot access private routes | MANUAL_REQUIRED | Browser direct URL QA required. | Release gate. |
| Usuario A document invisible to Usuario B | MANUAL_REQUIRED | Two-user QA required. | Release gate. |

## PERFORMANCE SMOKE

| Area | Status | Evidence | Notes |
| --- | --- | --- | --- |
| Startup | MANUAL_REQUIRED | Device/browser profiling required. | No runtime session was launched in this pass. |
| Home | MANUAL_REQUIRED | Visual/browser QA required. | Check repeated HTTP calls and rebuild loops. |
| Library | MANUAL_REQUIRED | Library fixture with 20+ documents required. | Check search, refresh and delete latency. |
| AudioBook | MANUAL_REQUIRED | Audio generation/playback required. | Check fallback and audible output. |
| Teacher Studio | MANUAL_REQUIRED | Teacher data required. | Check course-to-classroom workflow. |

No performance optimizations were made because no reproducible runtime performance bug was captured during this automated pass.
