# StudyBook AI Privacy Policy - Public Draft

Status: `DRAFT ONLY - LEGAL/HUMAN REVIEW REQUIRED - DO NOT PUBLISH`

Effective date: `<EFFECTIVE_DATE_REQUIRED>`

Data controller/operator: `<LEGAL_ENTITY_REQUIRED>`

Privacy contact: `<PRIVACY_CONTACT_REQUIRED>`

This draft translates the current technical inventory into public-facing
language. Bracketed fields and legal decisions must be completed before it is
published at `https://studybookai.com/privacy`.

## 1. Data We Process

StudyBook AI may process account identifiers such as email address, Supabase
user ID, role and subscription status. Depending on the features selected, it
may also process uploaded documents, extracted text, prompts, chats, generated
learning resources, quizzes, flashcards, AudioBooks, voice-derived transcripts,
and Teacher academic records such as courses, rosters, attendance and grades.
Private document files, generated audio and retrieval chunks are stored in
owner-scoped Supabase database or private Storage records in production.

The app also processes limited operational and usage information needed for
authentication, security, limits and reliability. The final policy must list
any production analytics or monitoring tools after deployment review.

## 2. How Data Is Used

Data is used to provide document learning, AI generation, voice and AudioBook
features, Teacher workflows, account security, subscription entitlements,
support and service reliability. StudyBook AI must not claim unrelated uses
without a new product and privacy review.

## 3. AI, Documents, Voice And Audio

Document excerpts, prompts, transcript text and requested output may be sent by
the backend to OpenAI for generation, embeddings or text-to-speech. The current
Voice Tutor flow uses platform speech recognition and does not intentionally
save a raw microphone recording as account history. Platform speech behavior
can vary by device and provider.

Users and institutions must have authority to upload and process the content
they provide. The final policy requires approved language for educational and
institutional data responsibilities.

## 4. Service Providers

Current technical processors include:

- Supabase for authentication, database records and private object storage.
- OpenAI for selected AI, embeddings and text-to-speech processing.
- Stripe for Web subscription checkout and management.
- Google Play for Android purchases and subscription management.
- Device/platform speech services when speech recognition is used.

Processor roles, locations, contractual safeguards and international transfer
language require legal review before publication.

## 5. Payments

StudyBook AI stores subscription status and provider identifiers needed to
apply entitlements. Stripe handles Web billing and Google Play handles Android
Play-distributed purchases. Deleting a StudyBook AI account does not itself
claim to cancel a subscription managed by an external provider.

## 6. Retention

No universal retention period is approved in the repository. The public policy
must define periods or criteria for account data, documents, generated content,
operational logs, billing records and legal/security exceptions after the
production deployment and legal review are complete.

Required decision: `<RETENTION_SCHEDULE_AND_EXCEPTIONS_REQUIRED>`.

## 7. Account And Data Deletion

An authenticated user can open Settings, choose "Eliminar mi cuenta",
reauthenticate and confirm the request. The backend deletes known owner-scoped
Storage objects, documents, RAG chunks, generated results, chats,
AudioBooks, certificates, Teacher records, usage/subscription mappings and
finally the Auth identity. A partial failure is reported for retry rather than
presented as a completed deletion.

A public alternative will be documented at
`https://studybookai.com/account-deletion`. It is not available until the verified Web
request workflow is deployed. External subscriptions must be managed with the
provider where they were purchased.

## 8. User Rights

The final policy must describe applicable access, correction, deletion,
objection, restriction, portability and complaint rights for the approved
jurisdictions, along with identity-verification and response procedures.

Required decision: `<JURISDICTIONS_AND_RIGHTS_REQUIRED>`.

## 9. Children And Educational Use

The repository does not establish a final minimum age, Families designation or
parental-consent model. Do not publish a children-directed claim or select a
Play target audience until product and legal owners approve the age scope,
school responsibilities and consent requirements.

Required decision: `<AGE_SCOPE_AND_CONSENT_MODEL_REQUIRED>`.

## 10. Security

StudyBook AI uses authenticated owner scoping, private storage paths, HTTPS in
production configuration and server-side entitlement checks. No service can
promise absolute security. Incident, notification and support language require
approval against the deployed environment.

## 11. Contact And Changes

Public privacy and support contacts, postal details if legally required,
effective date and policy-change notice procedure remain pending.

Required fields:

- `<PRIVACY_CONTACT_REQUIRED>`
- `<SUPPORT_CONTACT_REQUIRED>`
- `<LEGAL_ADDRESS_IF_REQUIRED>`
- `<EFFECTIVE_DATE_REQUIRED>`
