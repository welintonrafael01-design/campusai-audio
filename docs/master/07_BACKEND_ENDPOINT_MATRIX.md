# 07 — Backend Endpoint Matrix

Backend app: `backend/app/main.py`.

## Core endpoints

| Method | Path | File | Auth | Used by Flutter | Status | Risk |
|---|---|---|---|---|---|---|
| GET | `/` | `main.py` | none | health/manual | Working | Low |
| GET | `/health` | `routes/health.py` | none | manual | Working | Low |
| POST | `/documents/upload` | `routes/documents.py` | Supabase token | yes | Working | Medium UX |
| POST | `/documents/chat/{document_id}` | `routes/documents.py` | token | yes | Working | ownership must hold |
| POST | `/documents/chat-stream/{document_id}` | `routes/documents.py` | token | maybe | Partial | streaming QA |
| POST | `/documents/flashcards/{document_id}` | `routes/documents.py` | token | yes | Working | Low |
| POST | `/documents/exam/{document_id}` | `routes/documents.py` | token | yes | Working | Low |
| POST | `/documents/question-bank/{document_id}` | `routes/documents.py` | token | yes | Working | Low |
| POST | `/documents/rubric/{document_id}` | `routes/documents.py` | token | yes | Working | Low |
| POST | `/documents/teaching-plan/{document_id}` | `routes/documents.py` | token | yes | Working | Medium |
| POST | `/documents/study-guide/{document_id}` | `routes/documents.py` | token | yes | Working | Low |
| POST | `/documents/teaching-resources/{document_id}` | `routes/documents.py` | token | yes | Partial | hidden |
| POST | `/documents/analyze-assessment` | `routes/documents.py` | token | yes | Working | hidden |
| GET | `/documents/file-token/{document_id}` | `routes/documents.py` | token | unclear | Advanced | security-sensitive |
| GET | `/documents/file-secure/{document_id}` | `routes/documents.py` | token/token param | unclear | Advanced | security-sensitive |
| GET | `/documents/file/{document_id}` | `routes/documents.py` | likely legacy | unclear | Legacy risk | High |
| GET | `/documents/info/{document_id}` | `routes/documents.py` | token | maybe | Partial | Low |
| GET | `/documents/source-chunk` | `routes/documents.py` | token | yes | Working | Low |
| GET | `/documents/semantic-search` | `routes/documents.py` | token | yes | Partial | Advanced |
| POST | `/documents/audio` | `routes/documents.py` | token | yes | Working | audio storage |
| POST | `/documents/audiobook` | `routes/documents.py` | token | yes | Working | duplicate pipeline |

## Cloud endpoints

`/cloud/workspaces`, `/cloud/library-documents`, `/cloud/documents`, `/cloud/chats`, `/cloud/messages`, `/cloud/study-results`, `/cloud/audiobooks` are user-scoped through `require_current_user`. They are production-useful and should be retained with tests.

## Billing endpoints

| Path | Auth | Status | Decision |
|---|---|---|---|
| `/billing/create-checkout-session` | token | Working | Reuse |
| `/billing/create-customer-portal-session` | token | Working | Reuse |
| `/billing/subscription/me` | token | Working | Reuse |
| `/billing/usage/me` | token | Working | Reuse |
| `/billing/webhook` | Stripe signature | Working | Reuse |
| `/billing/admin/financial-dashboard` | token + billing admin | Working | Hide UI |

## Advanced/duplicate endpoints

- Workspace AI endpoints are experimental for v1.
- `/audiobook/*` and `/documents/audiobook` overlap; choose one service boundary.
- Export endpoints are useful but should be called from typed service only.

