# 06 — Student Learning Inventory

## Product-real learning modules

| Module | Files | Estado | Decisión |
|---|---|---|---|
| Aprendizaje dashboard | `student_dashboard_screen.dart`, `student_dashboard_controller.dart` | Too broad but functional | Refactor |
| Learning Engine | `services/learning_engine/*` | Deterministic core exists | Reuse |
| AudioBook progress | `audiobook_progress_service.dart` | Connected to StudyResult | Reuse |
| Learning sessions | `learning_session_service.dart` | Base exists | Reuse |
| Recommendations | `recommendation_engine.dart`, smart services | Mixed core/enterprise | Simplify |
| Achievements/Streak | learning engine services | Local deterministic | Reuse |
| Transcript | `student_transcript_screen.dart` | Teacher-facing | Teacher advanced |

## Experimental learning modules

- `campus_intelligence/*`
- digital twin
- predictive success
- smart goals
- smart notification engine
- marketplace recommendations
- autonomous actions
- RC readiness services

These should not be in the v1 learner main path.

## Product target

`Aprendizaje` should show:

1. Continuar.
2. Progreso simple.
3. Flashcards.
4. Quiz.
5. Voice Tutor.
6. Recent AudioBook.

Everything else becomes future/advanced.

