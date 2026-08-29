# Delete Your StudyBook AI Account - Public Page Draft

Status: `DRAFT ONLY - VERIFIED WEB FLOW AND HUMAN REVIEW REQUIRED`

Planned public path: `https://<DOMAIN>/account-deletion`

Do not publish this page as an active deletion mechanism until the Web identity
verification and backend request workflow are deployed and tested.

## Delete From The App

1. Sign in to StudyBook AI.
2. Open Settings.
3. Select "Eliminar mi cuenta".
4. Enter the current password and the requested confirmation phrase.
5. Confirm permanent deletion.

The app reports completion only after the backend deletion workflow succeeds.
If a step fails, the account remains available for a safe retry.

## Request Deletion Without App Access

Planned alternative: `<VERIFIED_WEB_REQUEST_FLOW_REQUIRED>`.

The public workflow must verify control of the account using a time-limited
email challenge or another approved method. A plain email address, user ID or
support message is not sufficient authority to delete an account. The browser
must never receive Supabase service-role or Google service-account credentials.

Until that workflow is deployed, the page must clearly direct the person to
`<MONITORED_PRIVACY_CONTACT_REQUIRED>` without claiming that an unverified
message automatically deletes data.

## Data Covered By The Request

The current backend deletion workflow is designed to remove known owner-scoped:

- Supabase Auth identity and internal subscription mapping.
- Uploaded documents, private Storage objects and backend document files.
- Extracted/RAG collections associated with inventoried documents.
- Chats, messages, StudyResults and generated learning resources.
- AudioBook records and owner-scoped generated MP3 files.
- Teacher courses, students, attendance, grades and question banks.
- Usage events, certificates and user-scoped local references where an active
  app session can clear them.

## Possible Retention

The final page may describe only retention that is legally required or
technically verified. Exact categories, reasons and periods are pending:

`<LEGAL_RETENTION_CATEGORIES_PERIODS_AND_BASIS_REQUIRED>`

Do not imply that account deletion cancels Stripe or Google Play billing.
External subscriptions must be canceled or managed with the original provider.

## Process And Timing

The authenticated in-app request is processed synchronously by the current
backend. The public alternative may require request acceptance, identity
verification, processing and completion notification. No public response or
completion deadline is approved yet.

Required decision: `<VERIFIED_PROCESS_AND_RESPONSE_TIME_REQUIRED>`.

## Contact

Privacy contact: `<MONITORED_PRIVACY_CONTACT_REQUIRED>`

Support contact: `<MONITORED_SUPPORT_CONTACT_REQUIRED>`

These contacts must be monitored and approved before publication.
