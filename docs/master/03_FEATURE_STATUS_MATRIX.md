# 03 — Feature Status Matrix

| Feature | UI | Service | Backend | Storage | Estado | Decisión |
|---|---|---|---|---|---|---|
| Upload PDF | `DashboardScreen`, `CoursesScreen` | `ApiService.uploadPdf` | `POST /documents/upload` | backend uploads, RAG, local history, cloud docs | Partial UX regression | Reuse with fix |
| Chat documento | `ChatScreen` | `ApiService.chatWithDocumentId` | `POST /documents/chat/{id}` | local/cloud chat | Working | Reuse |
| Resumen | upload response + sheet | backend summary | upload endpoint | local history | Working but coupled to upload | Refactor |
| Audio resumen | `DashboardScreen`, `ChatScreen` | `generateAudioFromText` | `POST /documents/audio` | backend audio dir | Working | Reuse |
| AudioBook | `AudioBookStudioScreen`, Library | `AudiobookService`, `ApiService` | `/documents/audiobook`, `/audiobook/*` | StudyResult/cloud/audiobooks | Working/complex | Refactor |
| Voice Tutor | `VoiceTutorScreen` | voice intelligence services | `/voice/coach`, `/voice/tts` | StudyResult voice_session | Partial | Reuse with QA |
| Flashcards | `FlashcardsScreen` | `ApiService.generateFlashcardsByDocumentId` | `/documents/flashcards/{id}` | StudyResult/cloud | Working | Reuse |
| Quiz/Exam | `ExamScreen`, Courses, TeachingPlan | `generateExamByDocumentId` | `/documents/exam/{id}` | StudyResult/cloud | Working | Reuse with UX fix |
| Banco preguntas | `QuestionBankScreen`, Dashboard, Courses, TeachingPlan | `generateQuestionBankByDocumentId` | `/documents/question-bank/{id}` | StudyResult/cloud | Working | Reuse |
| Rúbricas | `RubricScreen`, Courses, TeachingPlan | `generateRubricByDocumentId` | `/documents/rubric/{id}` | StudyResult/cloud | Working | Teacher Core |
| Planificación | `TeachingPlanScreen`, Courses | `generateTeachingPlanByDocumentId` | `/documents/teaching-plan/{id}` | StudyResult/cloud | Working, large | Refactor |
| Study Guide | TeachingPlan unit | `generateStudyGuideByDocumentId` | `/documents/study-guide/{id}` | StudyResult/cloud | Working/hidden | Teacher Advanced |
| Semantic Search | hidden dashboard panel, service | `SemanticSearchService` | `/documents/semantic-search` | RAG | Partial UI hidden | Advanced |
| Workspace chat | hidden Dashboard workspaces | `WorkspaceService`, `ApiService` | `/documents/chat-workspace` | UserScopedStorage/cloud | Experimental | Hide |
| Gradebook | `GradebookScreen` | `GradebookService` | imports via documents | SharedPreferences | Working local | Teacher Core |
| Final Report | `FinalReportScreen` | `GradebookService` | export endpoint | StudyResult/local | Partial | Teacher Advanced |
| Billing | `PlansScreen`, Settings | `BillingService`, `SubscriptionService` | `/billing/*` | Supabase subscriptions + local plan | Working with risk | Reuse with guard |
| Admin analytics | `AdminAnalyticsScreen` | `AnalyticsService` | `/analytics/summary` | backend admin | Security risk | Hide/Rebuild |

