# 15 — Rebuild Recommendation

## Module-by-module decision

| Module | Decision | Concrete files |
|---|---|---|
| Auth | REUSE WITH FIX | `auth_screen.dart`, `auth_service.dart` |
| Router | REBUILD | `app_router.dart` |
| Inicio Dashboard | REFACTOR | `dashboard_screen.dart`, `dashboard_tools.dart` |
| Upload | REUSE WITH FIX | `dashboard_screen.dart`, `api_service.dart`, `documents.py` |
| Biblioteca | REBUILD UI, REUSE SERVICES | `library_screen.dart`, `cloud_api_service.dart`, `history_service.dart` |
| Chat | REUSE WITH FIX | `chat_screen.dart`, `api_service.dart`, `documents.py` |
| AudioBook | REFACTOR | `audiobook_studio_screen.dart`, `audiobook_service.dart` |
| Voice Tutor | REUSE WITH QA | `voice_tutor_screen.dart`, `voice_intelligence/*`, `voice.py` |
| Flashcards | REUSE | `flashcards_screen.dart` |
| Exam | REUSE WITH UX FIX | `exam_screen.dart`, `saved_exams_screen.dart` |
| Teacher Studio | REBUILD HUB, REUSE FEATURES | `courses_screen.dart`, teacher screens |
| Academic Engine | REUSE | `services/academic_engine/*`, `teaching_plan_screen.dart` |
| Gradebook | REUSE WITH CLOUD PLAN | `gradebook_screen.dart`, `gradebook_service.dart` |
| Billing | REUSE WITH HARDENING | `billing.py`, `billing_service.dart`, `plans_screen.dart` |
| Admin | HIDE THEN REBUILD | `admin_analytics_screen.dart`, `financial_dashboard_screen.dart` |
| Enterprise/RC | HIDE | `services/ai_agents`, `campus_intelligence`, `release_candidate`, `qa` |
| Backend documents | REFACTOR LATER | `routes/documents.py` |

## Implementation order

1. Upload UX hotfix.
2. API env/base URL cross-platform fix.
3. Auth/role/plan route guard.
4. Remove frontend admin secret usage.
5. Dashboard controller.
6. Biblioteca v2.
7. Teacher Studio hub.
8. Student Learning v1 simplification.
9. Backend tests and ownership tests.
10. Cleanup backups/env/generated artifacts.

