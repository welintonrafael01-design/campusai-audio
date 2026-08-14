# 12 — Tech Debt And Duplication

## Duplications

- `AudioBook`, `Audio Libro`, `Audiolibro` naming across older widgets.
- `/documents/audiobook` and `/audiobook/generate` overlap.
- Dashboard and Student Dashboard both act as home surfaces.
- Teacher tools appear in Courses, Dashboard Educator Center and Teaching Plan.
- Local storage wrappers: raw SharedPreferences, `LocalStorageService`, `UserScopedStorage`.
- Academic resources save patterns repeated despite new Academic Engine repository.

## Monoliths

- `teaching_plan_screen.dart` — 3016 lines.
- `audiobook_studio_screen.dart` — 2695 lines.
- `dashboard_screen.dart` — 2689 lines after visual simplification.
- `library_screen.dart` — 2456 lines.
- `courses_screen.dart` — 1913 lines.
- `api_service.dart` — 1302 lines.

## Dead/legacy candidates

- `.bak` files in `backups/**`.
- `backend/tests/__pycache__` without source tests.
- RC/launch/readiness services in production UI.
- `DashboardEducatorCenter` as main dashboard surface.
- Admin analytics UI until admin role guard exists.

## Experimental candidates

- `services/ai_agents/*`
- `services/autonomous_ai/*`
- `services/campus_intelligence/*`
- `services/marketplace/*`
- `services/release_candidate/*`
- `services/performance_readiness/*`
- `services/qa/*`

