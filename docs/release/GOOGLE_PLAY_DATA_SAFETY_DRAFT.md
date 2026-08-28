# Google Play Data Safety Draft - StudyBook AI

Status: `TECHNICAL DRAFT - HUMAN REVIEW REQUIRED`

This draft is based on `docs/privacy/DATA_INVENTORY.md`,
`docs/privacy/AI_DATA_FLOW.md`, source code and the current dependency set. It
must not be submitted without product, legal and infrastructure confirmation.

## Collection Summary

| Play-oriented data category | Collected off device? | Shared? | Purpose | Optional? | Deletion available? |
| --- | --- | --- | --- | --- | --- |
| Email address | Yes | Processor review required | Account management, authentication, support | Required for account | In-app deletion implemented; external page pending |
| User ID | Yes | Processor review required | Authentication, ownership, security, analytics | Required | Owner-scoped deletion implemented |
| Purchase/subscription data | Yes | Stripe/Google Play/Supabase processing | Subscription and entitlement management | Optional paid plan | Internal mapping deleted; provider retention reviewed separately |
| User files/documents | Yes | OpenAI/Supabase processing review required | Core learning and teacher features | Optional feature use | Owner-scoped account purge implemented |
| Academic/teacher data | Yes | Supabase/OpenAI processing review required | Courses, evaluation, planning and reports | Feature-dependent | Partial |
| Chat and generated content | Yes | OpenAI/Supabase processing review required | AI learning assistance | Feature-dependent | Account purge covers chats, messages and StudyResults |
| Voice transcript | Yes when Voice Tutor is used | Platform speech/OpenAI review required | Speech recognition and tutor response | Optional | Partial; no raw app recording observed |
| AudioBook text/audio | Yes | OpenAI/Supabase processing review required | Chapter generation and TTS | Optional | Account purge covers rows, caches and owner-prefixed MP3 files |
| App interactions/usage | Yes | No external sharing proven; confirm processors | Limits, operations, product quality | Required during use | Retention undefined |
| Diagnostics | Limited request metadata | Unknown deployment processors | Reliability and security | Required during use | Retention undefined |
| UI preferences | Primarily local | No evidence of third-party sharing | Personalization/accessibility | Optional | Device-data clearing/local reset |

`Shared?` uses Google Play's policy definition, not the everyday meaning. Legal
and processor-contract review must decide whether service-provider exceptions
apply to Supabase, Stripe, OpenAI and platform speech services.

## Security Answers

- Encryption in transit: `YES` only for the final production build using an
  approved HTTPS API and HTTPS third-party endpoints. Local QA HTTP is not a
  distributed release configuration.
- User can request deletion: `YES IN APP`; the required public external request
  page remains a hosting and Play Console action.
- Independent security review: `UNKNOWN`.
- Data is processed ephemerally: only where specifically proven; do not apply
  this claim globally.

## Third Parties / SDKs

- Supabase Flutter SDK: authentication/session; backend also uses Supabase
  database and private Storage.
- Stripe: Web Checkout, portal and webhook processing; Android purchase UI does
  not open Stripe.
- Google Play Billing: Android product query, purchase and restore. Entitlements
  require backend verification; live Developer API credentials remain external.
- OpenAI: backend AI, embeddings and TTS processor.
- Android/platform speech service: may process speech according to device and
  provider behavior.
- No Firebase, crash-reporting, analytics or advertising SDK was found in the
  current Android dependency set.

## Submission Gate

Before closed or production testing, reconcile this draft against the deployed
database/storage policies, production logging/retention, deployed Play purchase
verification, external deletion page, processor agreements and the published
privacy policy.

Official reference:
<https://support.google.com/googleplay/android-developer/answer/10787469>
