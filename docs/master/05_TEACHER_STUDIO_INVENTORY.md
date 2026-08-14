# 05 — Teacher Studio Inventory

## Teacher Studio Core

| Feature | Files | Storage/API | Estado | Decisión |
|---|---|---|---|---|
| Cursos | `courses_screen.dart`, `course_service.dart` | SharedPreferences, upload API | Working | Core |
| Estudiantes | `students_screen.dart`, `student_roster_service.dart` | SharedPreferences/import students | Working | Core |
| Planificación | `teaching_plan_screen.dart`, Academic Engine services | StudyResult/cloud | Working but huge | Core refactor |
| Rúbricas | `rubric_screen.dart`, `academic_resource_repository.dart` | StudyResult/cloud/export | Working | Core |
| Banco preguntas | `question_bank_screen.dart` | StudyResult/cloud/export | Working | Core |
| Exámenes | `exam_screen.dart`, `saved_exams_screen.dart` | StudyResult/cloud | Working | Core |
| Asistencia | `attendance_screen.dart`, `attendance_service.dart` | SharedPreferences | Working | Core |
| Calificaciones | `gradebook_screen.dart`, `gradebook_service.dart` | SharedPreferences | Working | Core |
| Acta final | `final_report_screen.dart` | StudyResult/export | Partial | Advanced |

## Teacher Advanced

- `assessment_weights_screen.dart`
- `academic_dashboard_screen.dart`
- `academic_recognition_screen.dart`
- `student_profile_screen.dart`
- `student_transcript_screen.dart`
- `unit_workspace_screen.dart`
- Assessment Report por unidad
- Curriculum Intelligence

## Background services

- `EducatorSyncService`
- `AcademicMetadataBuilder`
- `AcademicResourceRepository`
- `AcademicUnitResourceManager`
- `CurriculumIntelligenceEngine`
- `CourseDocumentService`

## Legacy/experimental

- Dashboard educator center as main dashboard block.
- Academic Recognition certificates before role/admin guard.
- Workspace-based AI in generic dashboard.

## Dependency map

`CoursesScreen` is the current de facto Teacher hub. It launches teaching plan, rubric, exam and question bank flows. `TeachingPlanScreen` is the unit resource hub. `GradebookScreen` and `FinalReportScreen` form the evaluation/report chain.

Recommendation: build a single `TeacherStudioScreen` route later and keep `/courses` as the first tab/section.

