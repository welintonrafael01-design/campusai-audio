# StudyBook AI Data Inventory

This is an implementation inventory, not an approved legal retention policy.

| Category | Source and purpose | Storage/processor | Deletion behavior | Sensitivity |
|---|---|---|---|---|
| Account identity | Email, Supabase user ID, server `app_metadata`; login and authorization | Supabase Auth; SDK session storage on device/browser | Authenticated account deletion removes Auth last and clears the local session | High |
| Subscription/billing | Plan/status, Stripe/Google Play identifiers and usage counts | Backend/Supabase; Stripe; Google Play | Internal mapping is removed; external subscription cancellation remains a separate provider action | High |
| Uploaded documents | User PDF for learning and Teacher workflows | Production: private Supabase Storage and durable registry; local development adapter only outside production | Account deletion purges known owner-scoped objects and rows before Auth | High |
| Extracted text/embeddings | PDF text for search and AI context | Production: Supabase `document_chunks`; OpenAI embeddings; local Chroma only outside production | Account deletion removes owner/document-scoped chunks; local collections are cleaned in non-production | High |
| Generated AI content | Summaries, chats, flashcards, quizzes, exams, plans, guides | Flutter user-scoped cache, Supabase `study_results`, OpenAI during generation | Per-result/local cleanup exists; cascade varies | High |
| Chat history | User/assistant messages and source references | User-scoped local cache, Supabase chats/messages | Chat/document cleanup routes are owner-scoped | High |
| Voice transcript/session | Platform-recognized text for Voice Tutor and memory | App state, optional user-scoped `voice_session`, OpenAI | Session/result deletion mechanisms; no raw app audio file observed | High |
| AudioBook/MP3 | Source text, chapters, learning packs, generated speech | Production: private Supabase artifact bucket and durable rows; OpenAI TTS; user-scoped app cache | Account deletion removes owner rows, scoped caches and private artifact objects | High |
| Teacher academic data | Courses, students, attendance, grades, weights, question banks | User-scoped Flutter cache and educator Supabase tables | Snapshot sync can delete stale owner rows; no legal retention schedule | Very high |
| Certificates/recognitions | Teacher-issued student achievement data | Production: Supabase `certificates`; local JSON adapter outside production; public verification by certificate ID | Account deletion removes certificates issued by the owner before Auth deletion | Very high |
| Accessibility preferences | User-selected reading/audio/motion preferences | User-scoped local StudyResult | Reset/delete through local result lifecycle | Medium |
| Diagnostics/usage | Request ID, method/path/status/timing, event type and bounded metadata | Backend logs and `user_usage_events` | Deployment log retention not defined in repo | Medium |
| UI preferences | Theme, locale, onboarding flags | SharedPreferences/browser storage | Device/app data clearing; some keys user-scoped | Low/Medium |

## Data Minimization Notes

- Request ownership fields are rejected or ignored; owner identity comes from
  the token.
- Document info/rehydration responses no longer return local filesystem paths,
  storage paths, or full registry records.
- Client IP is used transiently for the in-process limiter but is no longer
  written to request logs/usage events.
- Flutter release diagnostics are disabled; backend errors expose generic
  messages.
- Legacy certificate runtime data is no longer tracked in the repository.

## Local Storage Behavior

Most learning and Teacher keys include the current Supabase user scope, which
prevents A-to-B display after account switching. Successful account deletion
removes all SharedPreferences keys ending in the authenticated user scope and
clears plan/session state. Ordinary logout does not perform account erasure and
continues to rely on Android/browser sandboxing. Supabase Auth token persistence
is delegated to its SDK.

## Production Persistence Boundary

Production startup validates the required Supabase database and private Storage
configuration and fails closed when it is absent. Container disk, repository
paths and `/tmp` are not production sources of truth for user documents, RAG
chunks, generated audio or certificates. Temporary processing files may exist
only for bounded work and must be cleaned by their owning flow.
