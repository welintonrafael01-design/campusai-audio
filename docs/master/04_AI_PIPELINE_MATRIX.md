# 04 — AI Pipeline Matrix

| AI Feature | UI -> Service -> API -> Backend -> Storage | Classification |
|---|---|---|
| Chat | `ChatScreen` -> `ApiService.chatWithDocumentId` -> `POST /documents/chat/{document_id}` -> `rag_service.chat_with_document_id` -> `ChatHistoryService`/Cloud messages | WORKING |
| Resumir | Upload flow -> `generate_ai_summary` inside `/documents/upload` -> `HistoryService` summary | WORKING but not independent |
| AudioBook | `AudioBookStudioScreen`/Library -> `AudiobookService`/`ApiService.generateAudioBookFromText` -> `/documents/audiobook` and `/audiobook/generate` -> `audiobook_service` -> StudyResult/cloud | WORKING, DUPLICATED PIPELINE |
| Voice Tutor | `VoiceTutorScreen` -> `VoiceTtsService`/`AiCoachService` -> `/voice/tts`, `/voice/coach` -> OpenAI/voice services -> StudyResult sessions | PARTIAL |
| Flashcards | `FlashcardsScreen` -> `ApiService.generateFlashcardsByDocumentId` -> `/documents/flashcards/{id}` -> AI service -> StudyResult/cloud | WORKING |
| Quiz | `ExamScreen` -> `generateExamByDocumentId` -> `/documents/exam/{id}` -> AI service -> StudyResult/cloud | WORKING |
| Exámenes docentes | `CoursesScreen`, `TeachingPlanScreen` -> same exam API or bank-derived local exam -> StudyResult `exam` | WORKING |
| Banco preguntas | `DashboardScreen`, `QuestionBankScreen`, `CoursesScreen`, `TeachingPlanScreen` -> `/documents/question-bank/{id}` -> StudyResult `question_bank` | WORKING |
| Rúbricas | `RubricScreen`, `CoursesScreen`, `TeachingPlanScreen` -> `/documents/rubric/{id}` -> StudyResult `rubric` | WORKING |
| Planificación | `CoursesScreen`, `TeachingPlanScreen` -> `/documents/teaching-plan/{id}` -> StudyResult `teaching_plan` | WORKING |
| Study Guide | `TeachingPlanScreen` -> `/documents/study-guide/{id}` -> StudyResult `study_guide` | WORKING but hidden |
| Semantic Search | `SemanticSearchService` -> `/documents/semantic-search` -> RAG query | PARTIAL/ADVANCED |
| Workspace | Dashboard hidden functions -> `/documents/chat-workspace`, `/workspace-flashcards`, `/workspace-question-bank`, `/workspace-exam` -> StudyResult workspace ids | EXPERIMENTAL |
| Campus Intelligence | Student dashboard services -> local StudyResult analysis | EXPERIMENTAL |
| Agents/Autonomous AI | services only | mostly local deterministic | StudyResult/repositories | EXPERIMENTAL/UI NOT READY |

## Target v1 AI tools

Keep visible in main UI: Chat, Resumir, AudioBook, Voice Tutor, Flashcards, Quiz, Banco de preguntas, Generar examen.

Move to Teacher Studio: Rúbricas, Planificación, Study Guide, Assessment Report, Unit Workspace.

Hide for v1: Semantic Search, Workspace AI, autonomous agents, enterprise intelligence.

