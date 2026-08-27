# StudyBook AI Threat Model v1

## Scope

This model describes the Flutter client, FastAPI backend, Supabase Auth,
Supabase database/storage, local backend files, OpenAI services, Stripe, and
local client caches as implemented at Plan Master 7D. Flutter is treated as a
hostile client and is never an authorization authority.

## Assets

- Supabase accounts, access/refresh tokens, and server-trusted `app_metadata`.
- Uploaded documents, extracted text, embeddings, summaries, chats, AI results,
  AudioBooks, and generated MP3 files.
- Teacher records: courses, student lists, attendance, grades, question banks,
  certificates, and final reports.
- Subscription state, Stripe customer/subscription identifiers, and usage data.
- Backend-only OpenAI, Supabase service-role, Stripe, Admin, and file-token
  secrets.

## Actors

- Anonymous visitor.
- Authenticated Student or Teacher.
- Malicious Student or Teacher manipulating requests and object IDs.
- Backend-authorized Admin.
- External attacker.
- User operating a compromised, shared, or rooted device/browser.

## Trust Boundaries

1. Device/browser to FastAPI over HTTPS in production.
2. Flutter to Supabase Auth using the public anon configuration.
3. FastAPI to Supabase using server environment credentials.
4. FastAPI to OpenAI for embeddings, chat generation, and TTS.
5. FastAPI to Stripe for checkout, portal, subscription, and webhook handling.
6. FastAPI process to local `uploads`, Chroma, audio, registry, and certificate
   stores.

## Authority Model

- Identity comes from a Supabase bearer token validated server-side.
- Student/Teacher role comes only from server-returned `app_metadata`.
- Paid plan/status comes from `user_subscriptions`; only `active` and `trialing`
  enable paid capabilities.
- Teacher access requires both Teacher role and an eligible subscription.
- Admin access is an independent backend `ADMIN_EMAILS` allowlist and fails
  closed when empty.
- Object ownership is derived from the authenticated `user_id`, never a payload
  owner field.

## Attack Surfaces and Controls

| Surface | Primary threat | Implemented control |
|---|---|---|
| Auth endpoints | Missing, invalid, or expired token | Supabase `get_user(token)`; consistent 401 response |
| Teacher/Admin routes | Role, plan, or metadata spoofing | Backend role/capability resolution and explicit dependencies |
| Cloud CRUD | BOLA/IDOR and mass assignment | `user_id` from token; owner filters; strict request models |
| Documents/RAG | Cross-user reads and prompt injection | Owner registry checks, user-scoped IDs, untrusted-content system boundary |
| PDF access | Path traversal and arbitrary file read | Short signed token, document binding, registry path only, legacy route disabled |
| MP3 access | Public or cross-user playback | Authenticated routes, owner-scoped filenames, legacy ownership lookup |
| Uploads/imports | Traversal, fake files, memory exhaustion | Generated names, PDF signature/MIME checks, XLSX signature, 25 MB bounded read |
| Certificates | Cross-teacher listing and false public issuance | Teacher-only issuance, owner-scoped store/listing, collision denial |
| External URLs | `javascript:`, `file:`, or `intent:` launch | HTTPS policy; HTTP only for explicit loopback QA |
| API errors/logs | Internal paths, provider errors, or private content | Generic 5xx responses, bounded 4xx detail, release debug suppression |
| Stripe webhook | Forged commercial entitlement | Stripe signature verification; checkout query never grants access |
| Android release | Cleartext traffic and backup extraction | Cleartext disabled and app backup disabled in release manifest |

## Critical Data Flows

- PDF upload: authenticated client -> FastAPI -> local PDF/extraction -> OpenAI
  embeddings and generation -> Chroma/Supabase -> user-scoped response.
- Voice Tutor: OS speech recognition -> transcript in Flutter -> authenticated
  FastAPI/OpenAI -> text and optional owner-scoped TTS MP3.
- Teacher sync: local user-scoped Teacher cache -> authenticated Teacher endpoint
  -> owner-scoped educator tables.
- Billing: authenticated user -> backend -> Stripe; signed webhook -> backend
  subscription record.

## Residual Risk

- RLS policy state is not represented by SQL/migrations in this repository and
  must be verified in the deployed Supabase project. Backend service-role calls
  bypass RLS by design.
- Document deletion does not yet prove complete deletion of local PDFs, Chroma
  chunks, Supabase objects, and generated MP3 files.
- API rate limiting is in-memory and per backend process, not distributed.
- CSP/HSTS depend on the production hosting/reverse-proxy layer.
- Local caches and Supabase SDK session storage rely on OS/browser protection;
  StudyBook does not add application-level encryption.
- Legacy academic certificate data was removed from the tracked HEAD, but recent
  Git history requires confirmation that the records were synthetic or a
  separately authorized history-cleanup process.
