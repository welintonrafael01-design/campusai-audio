# AI Data Flow

## PDF and Document Learning

1. Flutter uploads a PDF to authenticated FastAPI.
2. FastAPI reads at most 25 MB and validates MIME/extension and `%PDF`. Local
   files are a development adapter; production persists private source objects
   in the configured Supabase Storage bucket and fails closed when durable
   storage is not configured.
3. PyMuPDF extracts text locally. Pages without embedded text are rendered in
   memory and processed locally by Tesseract OCR (`eng+spa`).
4. Extracted chunks are sent to OpenAI for embeddings. Production stores the
   owner-scoped chunks in Supabase `document_chunks`; local Chroma is available
   only as a non-production adapter. Up to bounded context is sent to OpenAI for
   summaries, chat, flashcards, quizzes, plans, rubrics, exams, and other
   requested AI results.
5. Production document metadata and generated results are stored in durable,
   owner-scoped Supabase records. Flutter may also keep user-scoped local cache.

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
- Optional TTS sends response text to OpenAI. Production stores generated audio
  in the configured private artifact bucket; authenticated routes enforce
  owner access for playback.

The OS/browser speech service may have its own processing behavior; StudyBook's
code cannot promise that recognition is entirely on-device.

## AudioBook

- Source text and metadata are sent to OpenAI to generate chapters/learning
  packs and to TTS for MP3 creation.
- Structured AudioBook data may exist in local user-scoped storage,
  `study_results`, and the legacy `audiobooks` table.
- Production MP3 artifacts live in a private Supabase Storage bucket and are
  served only through authenticated, owner-scoped access. Local filesystem
  artifacts are a development adapter and are not the production source of
  truth.

## Logging and Responses

Backend operational logs retain method/path/status/timing and selected event
metadata, not bearer tokens or full document/AI bodies. Production Flutter
suppresses `debugPrint`. Generic 5xx responses avoid provider errors and local
paths. QA redaction is defense in depth, not a substitute for safe logging.

## Deletion and Retention Reality

The authenticated account-deletion orchestrator inventories owner documents
and removes known private Storage objects, durable document chunks, registry
rows, generated results, certificates, academic data and AudioBook artifacts
before deleting Auth. Non-production adapters receive equivalent cleanup.
Partial completion is reported for retry. Legally approved retention exceptions
remain required; no legal retention period is asserted by this document.
