# Privacy Policy Requirements - StudyBook AI

Status: `BLOCKER FOR CLOSED/PRODUCTION - HUMAN LEGAL REVIEW REQUIRED`

No approved privacy-policy URL or in-app privacy link was found in the current
repository. This document contains implementation facts, not legal language.

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

## Known Deletion Limitation

The app does not currently expose an in-app account-deletion request. Complete
erasure across Supabase Auth/database/storage, backend PDFs, Chroma vectors,
generated MP3s and local caches is not proven. The policy must not promise a
complete deletion SLA until an owner-scoped, tested lifecycle exists.

## Publication Checklist

- `MISSING`: approved policy text.
- `MISSING`: public HTTPS URL, stable and reachable without login.
- `MISSING`: in-app privacy link.
- `MISSING`: account-deletion web request URL.
- `HUMAN ACTION`: legal/privacy review of processors, retention and age scope.
- `HUMAN ACTION`: confirm that Play Console Data Safety answers match the
  published policy and the final production build.

Official references:
<https://support.google.com/googleplay/android-developer/answer/10144311>
and
<https://support.google.com/googleplay/android-developer/answer/13327111>
