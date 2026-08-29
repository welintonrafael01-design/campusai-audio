# External Account Deletion Page Requirements

Status: `SPECIFICATION READY - HUMAN HOSTING ACTION REQUIRED`

Google Play requires a public, discoverable web resource where a person can
request deletion without reinstalling the application. No final URL is
invented by this repository.

The proposed public copy is maintained in
`docs/privacy/ACCOUNT_DELETION_PUBLIC_PAGE_DRAFT.md`. It must not be presented
as operational until the verified Web request flow is deployed.

## Public Page Contract

- Public HTTPS page, reachable without an existing app session.
- Clearly identify StudyBook AI and state that the request deletes the account
  and associated product data.
- Verify control of the account through a time-limited email link or another
  approved identity challenge. Never accept a bare `user_id` or email as
  authority to delete data.
- Require explicit confirmation and give a human description of the destructive
  effect. Avoid retention or cancellation promises that infrastructure cannot
  satisfy.
- Submit the verified request to a backend-only deletion workflow. Supabase
  `service_role` must never be present in the page or browser application.
- Return `accepted`, `completed`, or `retry required`; do not report success
  after a partial purge.

## Data Categories

The request must cover Supabase Auth identity, account/subscription mapping,
documents and Storage objects, extracted/RAG data, generated StudyResults,
chats, AudioBooks and MP3 files, Teacher records, usage events, certificates,
and user-scoped application caches where the user still has a device session.

## Retention And Billing

The published page must disclose any legally required billing/security
retention after legal review. Deleting StudyBook AI does not itself cancel a
subscription managed by Stripe or Google Play. The user must receive accurate
provider-specific cancellation instructions without implying that deletion
stops external billing.

## Operations

- Publish a monitored privacy/support contact.
- Record request state and retry safely without logging document contents,
  passwords, bearer tokens, or complete purchase tokens.
- Add the final HTTPS URL to Play Console Data Safety and the published privacy
  policy.

Official requirement:
<https://support.google.com/googleplay/android-developer/answer/13327111>
