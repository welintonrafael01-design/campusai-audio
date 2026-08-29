# AI Data Flow

## PDF and Document Learning

1. Flutter uploads a PDF to authenticated FastAPI.
2. FastAPI reads at most 25 MB, validates MIME/extension and `%PDF`, and writes
   a generated local filename under `backend/uploads`.
3. PyMuPDF extracts text locally. Pages without embedded text are rendered in
   memory and processed locally by Tesseract OCR (`eng+spa`).
4. Extracted chunks are sent to OpenAI for embeddings and stored in local
   Chroma. Up to bounded context is sent to OpenAI for summaries, chat,
   flashcards, quizzes, plans, rubrics, exams, and other requested AI results.
5. The PDF may be copied to the private Supabase bucket. Metadata and generated
   results may be saved in Supabase and user-scoped local Flutter storage.

OpenAI is therefore an external processor for document excerpts, questions,
transcripts, generated prompts, embeddings, and TTS text. Tesseract OCR runs in
the backend process and is not a remote OCR provider in the current code.

## RAG and Prompt Boundaries

Document text, retrieved chunks, prior messages, and transcripts are inserted
as untrusted data. System prompts explicitly prohibit following instructions
inside that content, changing authorization, or revealing credentials/internal
configuration. AI output is parsed as content/JSON and is not executed as SQL,
shell, or filesystem commands.

## Voice Tutor

- Flutter requests microphone permission and uses the platform
  `speech_to_text` implementation. StudyBook does not write a raw microphone
  recording file in this flow.
- Recognized transcript text is held in app state and may be saved as a
  user-scoped `voice_session` StudyResult.
- The transcript/context is sent through authenticated FastAPI to OpenAI for the
  coach response.
- Optional TTS sends response text to OpenAI and stores an owner-scoped MP3 on
  the backend. Playback requires the bearer token.

The OS/browser speech service may have its own processing behavior; StudyBook's
code cannot promise that recognition is entirely on-device.

## AudioBook

- Source text and metadata are sent to OpenAI to generate chapters/learning
  packs and to TTS for MP3 creation.
- Structured AudioBook data may exist in local user-scoped storage,
  `study_results`, and the legacy `audiobooks` table.
- Generated MP3 files currently live under backend application storage. They
  are not public static files; owner-scoped authenticated routes serve them.

## Logging and Responses

Backend operational logs retain method/path/status/timing and selected event
metadata, not bearer tokens or full document/AI bodies. Production Flutter
suppresses `debugPrint`. Generic 5xx responses avoid provider errors and local
paths. QA redaction is defense in depth, not a substitute for safe logging.

## Deletion and Retention Reality

The authenticated account-deletion orchestrator inventories owner documents
and removes known Supabase Storage objects, backend PDFs, Chroma collections,
cloud rows, generated results and owner-prefixed MP3 files before deleting Auth.
Partial completion is reported for retry. Deployment schema/storage evidence
and legally approved retention exceptions remain required; no legal retention
period is asserted by this document.
