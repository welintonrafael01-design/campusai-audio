# Google Play Data Safety Draft - StudyBook AI

Status: `TECHNICAL DRAFT - HUMAN REVIEW REQUIRED`

This draft is based on `docs/privacy/DATA_INVENTORY.md`,
`docs/privacy/AI_DATA_FLOW.md`, source code and the current dependency set. It
must not be submitted without product, legal and infrastructure confirmation.

## Collection Summary

| Play-oriented data category | Collected off device? | Shared? | Purpose | Optional? | Deletion available? |
| --- | --- | --- | --- | --- | --- |
| Email address | Yes | Processor review required | Account management, authentication, support | Required for account | Account deletion missing |
| User ID | Yes | Processor review required | Authentication, ownership, security, analytics | Required | Partial only |
| Purchase/subscription data | Yes | Stripe/Supabase processing | Subscription and entitlement management | Optional paid plan | Provider lifecycle; no account cascade |
| User files/documents | Yes | OpenAI/Supabase processing review required | Core learning and teacher features | Optional feature use | Partial; complete purge not proven |
| Academic/teacher data | Yes | Supabase/OpenAI processing review required | Courses, evaluation, planning and reports | Feature-dependent | Partial |
| Chat and generated content | Yes | OpenAI/Supabase processing review required | AI learning assistance | Feature-dependent | Per-record paths exist; cascade varies |
| Voice transcript | Yes when Voice Tutor is used | Platform speech/OpenAI review required | Speech recognition and tutor response | Optional | Partial; no raw app recording observed |
| AudioBook text/audio | Yes | OpenAI/Supabase processing review required | Chapter generation and TTS | Optional | Partial; MP3 purge not proven |
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
- User can request deletion: `NO / BLOCKER` in the current product.
- Independent security review: `UNKNOWN`.
- Data is processed ephemerally: only where specifically proven; do not apply
  this claim globally.

## Third Parties / SDKs

- Supabase Flutter SDK: authentication/session; backend also uses Supabase
  database and private Storage.
- Stripe: backend Checkout, portal and webhook processing; no native Android
  Stripe SDK.
- OpenAI: backend AI, embeddings and TTS processor.
- Android/platform speech service: may process speech according to device and
  provider behavior.
- No Firebase, crash-reporting, analytics or advertising SDK was found in the
  current Android dependency set.

## Submission Gate

Before closed or production testing, reconcile this draft against the deployed
database/storage policies, production logging/retention, final billing flow,
account deletion, processor agreements and the published privacy policy.

Official reference:
<https://support.google.com/googleplay/android-developer/answer/10787469>
