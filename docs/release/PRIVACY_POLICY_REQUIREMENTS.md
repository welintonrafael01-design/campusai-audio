# Privacy Policy Requirements - StudyBook AI

Status: `BLOCKER FOR CLOSED/PRODUCTION - HUMAN LEGAL REVIEW REQUIRED`

The app now exposes a visible configurable privacy action and an authenticated
account-deletion flow. No approved public privacy-policy URL exists yet. This
document contains implementation facts, not legal language.

The public-facing working draft is
`docs/privacy/PRIVACY_POLICY_PUBLIC_DRAFT.md`; it remains explicitly blocked on
legal entity, contact, effective date, retention, jurisdiction and age-scope
decisions.

## Facts The Policy Must Cover

- Supabase account identity, authentication session, email, user ID, role and
  subscription state.
- Uploaded PDFs, extracted text, OCR output, embeddings, source references and
  generated learning resources.
- Student learning activity, chats, quizzes, flashcards, AudioBooks and voice
  transcripts.
- Teacher courses, rosters, attendance, grades, assessments and reports.
- Stripe customer/subscription identifiers and backend billing events.
- Operational request metadata and usage events.
- Local device/browser storage and user-scoped caches.
- Processing by Supabase, Stripe, OpenAI and platform speech services where
  applicable.
- Security controls, retention rules, user rights, contact channel and age/
  educational-context decisions approved by the product owner.

## Deletion Implementation

The in-app flow reauthenticates, requires explicit destructive confirmation and
calls `DELETE /account/me`. The backend inventories and purges owner-scoped
Storage, runtime files, Chroma collections, database rows and Auth in that
order. Auth remains available for retry after a partial failure. External
subscription cancellation and any legally required provider retention must be
described separately.

## Publication Checklist

- `MISSING`: approved policy text.
- `MISSING`: public HTTPS URL, stable and reachable without login.
- `READY`: in-app privacy action; it fails safely until a URL is configured.
- `SPEC READY / HUMAN ACTION`: account-deletion web request page.
- `HUMAN ACTION`: legal/privacy review of processors, retention and age scope.
- `HUMAN ACTION`: confirm that Play Console Data Safety answers match the
  published policy and the final production build.

Official references:
<https://support.google.com/googleplay/android-developer/answer/10144311>
and
<https://support.google.com/googleplay/android-developer/answer/13327111>
