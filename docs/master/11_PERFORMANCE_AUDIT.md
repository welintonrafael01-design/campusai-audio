# 11 — Performance Audit

## Hotspots

| Area | Files | Issue | Recommendation |
|---|---|---|---|
| Dashboard | `dashboard_screen.dart` | Stateful monolith, hidden but retained functions, streams and many async loaders | Extract controller |
| Student Dashboard | `student_dashboard_screen.dart`, `student_dashboard_controller.dart` | Loads learning, enterprise, marketplace, RC data | Split v1 core from experimental |
| Library | `library_screen.dart` | 2456 lines, loads local/cloud and derived artifacts | Biblioteca v2 with paginated model |
| AudioBook | `audiobook_studio_screen.dart` | 2695 lines, chapter/audio/progress in one screen | Controller + smaller widgets |
| Teaching Plan | `teaching_plan_screen.dart` | 3016 lines, many unit generation flows | Already has services; continue extraction |
| ApiService | `api_service.dart` | 1302 lines, all HTTP mixed with file picker | Split clients by domain |

## Rebuild risks

- Multiple FutureBuilders/services can duplicate network calls.
- SharedPreferences reads occur across many services.
- Audio player streams update dashboard state even when audio UI hidden.
- Backend upload does synchronous extraction, RAG indexing and AI summary in one request; slow PDFs block UI.

## Recommendations

1. Use controllers for Dashboard, Library, AudioBook, Teacher Studio.
2. Move upload to job/progress model later.
3. Cache user/session/plan once and expose provider.
4. Defer enterprise/RC services until visited.

