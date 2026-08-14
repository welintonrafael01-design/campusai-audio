# 02 — Screen Route Matrix

| Route | Screen | Público/Privado | Rol/Plan esperado | Entry point actual | Guard actual | Guard necesario | Decisión |
|---|---|---|---|---|---|---|---|
| `/auth` | `AuthScreen` | Público | Todos | inicial | ninguno | si logged -> dashboard | Reuse |
| `/reset-password` | `ResetPasswordScreen` | Público | Todos | auth/email | ninguno | público | Reuse |
| `/verify/:certificateId` | `CertificateVerifyScreen` | Público | Todos | link externo | ninguno | público | Reuse |
| `/dashboard` | `DashboardScreen` | Privado | Todos | login/sidebar | ninguno | auth required | Refactor |
| `/library` | `LibraryScreen` | Privado | Todos | sidebar/dashboard | ninguno | auth required | Rebuild v2 |
| `/student-dashboard` | `StudentDashboardScreen` | Privado | Student | sidebar/flows | ninguno | auth + student/accessibility | Refactor |
| `/audiobook-studio` | `AudioBookStudioScreen` | Privado | Student/Accessibility/Teacher | dashboard/library | ninguno | auth + entitlement | Refactor |
| `/voice-tutor` | `VoiceTutorScreen` | Privado | Student/Accessibility | dashboard/audiobook | ninguno | auth + voice entitlement | Reuse with fix |
| `/chat/:documentId` | `ChatScreen` | Privado | Todos | dashboard/library | backend token only | route ownership check | Reuse with fix |
| `/flashcards/:documentId` | `FlashcardsScreen` | Privado | Student/Teacher | dashboard/library | backend token only | route ownership + plan | Reuse |
| `/exam/:documentId` | `ExamScreen` | Privado | Student/Teacher | dashboard/library/courses | backend token only | route ownership + plan | Reuse with fix |
| `/question-bank/:documentId` | `QuestionBankScreen` | Privado | Teacher/Student Pro | dashboard/courses | none | plan entitlement | Reuse |
| `/rubric/:documentId` | `RubricScreen` | Privado | Teacher | courses/dashboard legacy | none | teacher only | Reuse |
| `/teaching-plan/:documentId` | `TeachingPlanScreen` | Privado | Teacher | courses | none | teacher only | Refactor |
| `/unit-workspace` | `UnitWorkspaceScreen` | Privado | Teacher | teaching plan | none | teacher only | Advanced |
| `/courses` | `CoursesScreen` | Privado | Teacher | sidebar | none | teacher/admin | Teacher Core |
| `/students` | `StudentsScreen` | Privado | Teacher | educator center/courses | none | teacher/admin | Teacher Core |
| `/attendance` | `AttendanceScreen` | Privado | Teacher | educator center | none | teacher/admin | Teacher Core |
| `/gradebook` | `GradebookScreen` | Privado | Teacher | educator center/exam | none | teacher/admin | Teacher Core |
| `/assessment-weights` | `AssessmentWeightsScreen` | Privado | Teacher | educator center | none | teacher/admin | Teacher Advanced |
| `/final-report` | `FinalReportScreen` | Privado | Teacher | gradebook/exam | none | teacher/admin | Teacher Advanced |
| `/saved-exams` | `SavedExamsScreen` | Privado | Teacher | educator center | none | teacher/admin | Teacher Core |
| `/academic-dashboard` | `AcademicDashboardScreen` | Privado | Teacher | educator center | none | teacher/admin | Hide advanced |
| `/academic-recognition` | `AcademicRecognitionScreen` | Privado | Teacher/Admin | academic dashboard | none | teacher/admin | Hide advanced |
| `/student-profile` | `StudentProfileScreen` | Privado | Teacher | students/academic dashboard | none | teacher/admin | Merge later |
| `/student-transcript` | `StudentTranscriptScreen` | Privado | Teacher | student profile | none | teacher/admin | Teacher Advanced |
| `/plans` | `PlansScreen` | Privado/Public upgrade | Todos | settings/legacy | none | auth optional | Move to Cuenta |
| `/settings` | `SettingsScreen` | Privado | Todos | sidebar | none | auth required | Cuenta Core |
| `/admin` | `AdminAnalyticsScreen` | Privado | Admin | direct only | none | admin role | Hide |
| `/admin/financial-dashboard` | `FinancialDashboardScreen` | Privado | Billing admin | old sidebar/direct | backend role | frontend admin guard | Hide |

## Pantallas inaccesibles o casi huérfanas

- `AdminAnalyticsScreen`: ruta directa, sin entrada principal tras simplificación.
- `FinancialDashboardScreen`: ruta directa, no debe estar visible a usuario normal.
- `AcademicRecognitionScreen`: entrada desde Academic Dashboard; debe ocultarse para v1.
- `StudentTranscriptScreen`: requiere extra; ruta directa puede abrir vacía.

