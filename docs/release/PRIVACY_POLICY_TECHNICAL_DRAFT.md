# StudyBook AI Privacy Policy Technical Draft

Status: `TECHNICAL FACTS ONLY - LEGAL/HUMAN REVIEW REQUIRED`

This is not an approved privacy policy. It summarizes implementation facts for
legal drafting and must not be published without processor, deployment,
retention, age-scope and jurisdiction review.

## Accounts And Identity

StudyBook AI uses Supabase Auth for account identity and sessions. The backend
derives the owner from the authenticated bearer token. It does not accept a
privileged `user_id` from account-deletion requests.

## Learning And Academic Data

Users may upload documents and generate summaries, chats, quizzes, flashcards,
AudioBooks, plans, exams, rubrics and related academic resources. Teacher use
may include course, roster, attendance and grade information. These categories
can contain personal or educational data and require appropriate institutional
authorization.

## AI, Voice And Audio

Document text and prompts may be sent by the backend to OpenAI for generation,
embeddings or text-to-speech. Voice Tutor can process speech-derived text.
Generated MP3 files are owner-scoped. The implementation does not intentionally
store a raw microphone recording as account history.

## Billing

Web checkout uses Stripe. Android Play-distributed purchases use the Google Play
Billing client and require server verification before an entitlement is
activated. Billing identifiers and status may be processed by the relevant
provider and Supabase. Deleting the app account does not silently cancel an
external subscription.

## Logs And Security

Operational logs may contain request method/path/status, bounded event metadata
and usage counts. Production Flutter diagnostics are disabled. Passwords,
bearer tokens, document bodies and complete AI outputs must not be logged.

## Account Deletion

The in-app flow requires a current-password reauthentication and explicit
confirmation. The backend inventories and purges owner-scoped Storage, local
runtime files, RAG collections, cloud rows and Supabase Auth in that order.
Auth is deleted last. A partial failure returns `retry_required` and does not
claim completion. A separate public deletion-request page remains a human
hosting action.

## Third-Party Processors Requiring Legal Review

- Supabase: authentication, database and private object storage.
- OpenAI: AI, embeddings and speech generation where invoked.
- Stripe: web subscription checkout and management.
- Google Play: Android subscriptions and purchase verification.
- Device/platform speech services: speech recognition behavior can vary by
  platform configuration.

## Required Legal Decisions

Approve retention schedules and exceptions, controller/processor roles,
international transfers, age/education scope, support contact, user rights,
subscription cancellation language, deployment analytics and the final public
privacy/deletion URLs.
