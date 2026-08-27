# StudyBook AI API Authorization Matrix

## Legend

- **Auth:** valid Supabase bearer identity via `require_current_user`.
- **Owner:** resource access is constrained to the authenticated `user_id` or
  document registry owner.
- **Plan:** effective server subscription includes the named capability.
- **Teacher:** server `app_metadata.role` is Teacher and the server subscription
  is active/trialing Teacher Pro or Institution.
- **Admin:** authenticated email is in backend `ADMIN_EMAILS`, or the endpoint
  uses its documented server-side secret mechanism.

Flutter checks are UX guards only. Request payloads, query parameters,
SharedPreferences, and `user_metadata` never grant sensitive access.

## Documents and learning

| Endpoint group | Auth | Owner | Plan/limit | Role | Expected denial |
|---|---:|---:|---|---|---|
| `POST /documents/upload` | Yes | Created for caller | PDF daily limit | Any | 401/403 |
| `POST /documents/chat/{id}` and stream | Yes | Document | Chat daily limit | Any | 401/403 |
| Workspace chat/stream | Yes | Workspace documents filtered | Chat daily limit | Any | 401/403 |
| `POST /documents/flashcards/{id}` | Yes | Document | Flashcard limit | Any | 401/403 |
| Workspace flashcards | Yes | Workspace documents filtered | Flashcard limit | Any | 401/403 |
| `POST /documents/exam/{id}` | Yes | Document | Exam limit | Any | 401/403 |
| Workspace exam | Yes | Workspace documents filtered | Exam limit | Any | 401/403 |
| `POST /documents/question-bank/{id}` | Yes | Document | Student Pro + exam limit | Any | 401/403 |
| Workspace question bank | Yes | Workspace documents filtered | Student Pro + exam limit | Any | 401/403 |
| File token/info/source chunk | Yes | Document | None | Any | 401/403/404 |
| Secure file URL | Signed short-lived token | Token binds document/user | None | Any | 401 |
| Legacy `GET /documents/file/{id}` | Disabled | N/A | N/A | N/A | 410 |
| Semantic search | Yes | Results filtered by owner | None | Any | 401 |

## AudioBook and voice

| Endpoint group | Auth | Owner | Plan | Notes |
|---|---:|---:|---:|---|
| `POST /audiobook/generate` | Yes | Input context | Student Pro | New structure generation |
| `POST /audiobook/generate-chapter-audio` | Yes | Input context | Student Pro | New TTS generation |
| `POST /audiobook/generate-learning-pack` | Yes | Input context | Student Pro | New pack generation |
| `POST /documents/audio` | Yes | Input context | Student Pro | Legacy endpoint, now gated |
| `POST /documents/audiobook` | Yes | Input context | Student Pro | Legacy endpoint, now gated |
| `GET /audio/{filename}` | Yes | Owner-scoped TTS filename or verified legacy record | None | Former public static route is disabled |
| `GET /audiobook/audio/{filename}` | Yes | Server-generated filename contract | None | Playback is not destructively blocked after downgrade |
| `POST /voice/coach`, `/voice/tts` | Yes | Caller session | Student Pro | Server plan gate |

Owned cloud AudioBooks can be restored on Free. This preserves already-created
user data while preventing new paid-cost generation.

## Teacher Core

| Endpoint group | Auth | Owner | Plan | Role |
|---|---:|---:|---:|---:|
| Import students/grades | Yes | Teacher dataset | Teacher Pro/Institution | Teacher |
| Teaching plan, rubric, study guide | Yes | Source document | Teacher Pro/Institution | Teacher |
| Teaching resources and assessment analysis | Yes | Source/payload | Teacher Pro/Institution | Teacher |
| `GET/POST /educator/snapshot|sync` | Yes | User-scoped educator store | Teacher Pro/Institution | Teacher |
| Certificate stats/list/create | Yes | Teacher registry | Teacher Pro/Institution | Teacher |
| Student transcript/rubric/plan/final-report exports | Yes | Caller payload | Teacher export policy | Teacher |

Teacher authority is evaluated in FastAPI. A Student cannot obtain Teacher
access by sending `role`, `plan`, or `capabilities` in a request. Legacy Ultra
does not satisfy the Teacher plan requirement.

Teacher certificate/academic-badge issuance also requires Teacher access.
Certificate lists and statistics are scoped to the token user ID; a Teacher
cannot list or overwrite another Teacher's records. Public verification accepts
only a certificate ID and returns the established verification fields.

## Cloud resources

All `/cloud` workspace, document, chat, message, StudyResult, AudioBook, and
library operations require Auth and pass `current_user.user_id` to the storage
service. Read, update, and delete operations are owner-scoped. Permission
failures are translated to human 403 responses.

| Endpoint group | Auth | Owner | Plan |
|---|---:|---:|---:|
| Workspaces CRUD | Yes | Yes | None |
| Documents/list/library/rehydrate/download URL | Yes | Yes | None |
| Chats/messages CRUD | Yes | Yes | None |
| StudyResults CRUD | Yes | Yes | None |
| AudioBooks CRUD | Yes | Yes | None |

Cloud persistence is a data-access capability, not a grant to regenerate paid
content.

## Exports

| Format | Free | Student Pro | Teacher Pro | Institution | Additional role gate |
|---|---:|---:|---:|---:|---|
| PDF | Yes | Yes | Yes | Yes | Teacher documents require Teacher |
| DOCX | No | Yes | Yes | Yes | None for generic export |
| PPTX | No | No | Yes | Yes | None for generic export |
| XLSX | No | No | Yes | Yes | None for generic export |

All export routes authenticate and call server export policy. Specialized
Teacher artifacts also require Teacher authorization.

## Billing and administration

| Endpoint | Authority | Security contract |
|---|---|---|
| `POST /billing/create-checkout-session` | Auth + Stripe server config | Requested plan selects a product; it does not grant access |
| `POST /billing/create-customer-portal-session` | Auth + caller subscription/customer | Caller can open only their associated portal |
| `GET /billing/subscription/me` | Auth | Returns server plan, status, role, commercial plan, capabilities |
| `GET /billing/usage/me` | Auth | Reads caller usage only |
| `POST /billing/webhook` | Stripe signature | Webhook/upsert is the commercial entitlement authority |
| `GET /billing/admin/financial-dashboard` | Backend Admin allowlist | Student/Teacher denied |
| `GET /analytics/summary` | Backend Admin allowlist | Student/Teacher denied |
| Public certificate verification | Public certificate ID | Returns verification fields only |

Institution has no checkout endpoint or public Stripe price. Existing QA users
without Stripe IDs remain valid when intentionally provisioned in the server
subscription table.

## Authority and status behavior

1. Supabase Auth establishes identity.
2. Server `app_metadata.role` establishes Student/Teacher identity.
3. Backend `ADMIN_EMAILS` independently establishes Admin.
4. The `user_subscriptions` record establishes stored plan and status.
5. Only `active` and `trialing` enable paid capabilities.
6. Missing, unknown, inactive, expired, past-due, or canceled paid states fail
   closed to Free.
7. The billing webhook or controlled server provisioning changes commercial
   entitlement; checkout success query parameters and Flutter cache do not.

## Regression evidence

Automated contracts cover plan aliases, status fail-closed behavior, Free and
Student boundaries, Teacher role-plus-plan authorization, Ultra denial,
metadata-only Admin denial, spoofed payload denial, export policies, AudioBook
generation gates, user-scoped cache replacement, and canonical plan UX at
360/430 px with text scale 1.3. Plan Master 7D adds authenticated MP3 access,
path traversal denial, upload bounds, strict owner-field rejection, prompt
injection boundaries, redacted errors, external URL policy, standalone document
delete ownership, educator identity isolation, and certificate issuer isolation.
