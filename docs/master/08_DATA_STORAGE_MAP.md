# 08 — Data Storage Map

| Data | Current location | Source of truth today | Target source of truth |
|---|---|---|---|
| Auth/session | Supabase Auth | Supabase | Supabase |
| Plan/subscription | Supabase backend + local `PlanGuardService` | mixed | backend/Supabase |
| PDF upload file | backend filesystem + Supabase storage attempt | backend registry | Supabase storage + registry |
| RAG index | `backend/chroma_db` | backend local | managed vector store or scoped Chroma |
| Active document | SharedPreferences via `HistoryService` and Riverpod provider | local | user-scoped local cache + cloud document |
| Recent documents | `RecentDocumentsService` + UserScopedStorage | local | cloud-backed with local cache |
| Study results | `StudyResultService` user-scoped SharedPreferences + `/cloud/study-results` | mixed | cloud primary, local cache |
| Chats | `ChatHistoryService` + cloud chats/messages | mixed | cloud primary |
| Audio files | `backend/app/audio` static | backend filesystem | object storage |
| AudioBooks | StudyResult + CloudApi `/cloud/audiobooks` | mixed | cloud primary |
| Courses | SharedPreferences | local | cloud table |
| Students | SharedPreferences | local | cloud table |
| Attendance | SharedPreferences | local | cloud table |
| Gradebook | SharedPreferences | local | cloud table |
| Final reports | StudyResult/local/export | mixed | cloud + export artifacts |
| Preferences | SharedPreferences | local | local + profile sync |

## Inconsistencies

- Some services use `UserScopedStorage`; others use raw `SharedPreferences`.
- Plan is synchronized but still locally authoritative in multiple UI decisions.
- Audio and uploads live in backend app directories, not production storage.
- Backend tests source files are missing while pycache remains.

