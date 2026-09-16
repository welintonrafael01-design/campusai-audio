# StudyBook AI W7-C5 Final Human Approval Sheet

Status: `HUMAN DECISIONS REQUIRED - NOT LEGAL APPROVAL`

Date prepared: `2026-09-16`

This sheet records only the unresolved launch decisions found in the current
public drafts and production configuration. It is not legal advice. No option
below becomes approved merely because it is listed here.

## Verified Technical And Product Facts

- Public pricing is Free `USD 0`, Student Pro `USD 6.99/month`, Teacher Pro
  `USD 13.99/month`, and Institution `Contact`.
- There is no public `$1` trial promise.
- The production data path uses Supabase for Auth/database/private Storage,
  OpenAI for selected AI/embedding/TTS processing, Render for the API, and
  Vercel for the public Web and Flutter Web surfaces.
- Stripe is implemented for Web checkout and subscription management. Google
  Play support exists in Android code, but its public legal wording must remain
  conditional until the Play products and verification configuration are
  approved and active.
- Platform/device speech services may process speech recognition. Voice Tutor
  does not intentionally persist the raw microphone recording as account
  history; recognized text may be processed and saved in user-scoped results.
- Authenticated account deletion inventories and attempts to remove known
  owner-scoped Storage, database, RAG, generated, academic and Auth data. Auth
  is deleted last. Partial failure is reported for retry. External billing is
  not automatically canceled by account deletion.
- The public Contact form is intentionally disabled and returns an honest
  unavailable response. No monitored address is approved in tracked project
  configuration.
- Privacy, Terms and Account Deletion remain visible drafts with page-level
  `noindex`. Public indexing remains disabled globally.

## Final Unanswered Decisions

| Field | Current status | Proposed text/options | Human decision required | Document affected |
| --- | --- | --- | --- | --- |
| Legal operator | Unresolved | Exact registered entity name or exact legal name of the individual operator; do not use the product name alone unless it is the legal operator | Supply the exact publishable legal name and operator type | Privacy, Terms, Contact, deletion |
| Publishable address | Unresolved | Registered business/service address, another counsel-approved notice address, or no address only if legal review confirms that omission is permissible | Supply the exact public address or explicitly keep launch blocked pending legal review | Privacy, Terms, Contact |
| Support contact | No monitored channel | A real monitored StudyBook AI mailbox or an explicitly approved professional mailbox used temporarily | Supply the exact address and confirm it is monitored | Contact, Terms, pricing/support surfaces |
| Privacy contact | No monitored channel | Same mailbox as support if explicitly approved, or a separate monitored privacy mailbox | Supply the exact address and confirm the privacy request process | Privacy, deletion, Contact |
| Governing law | No clause approved | If intended and approved: laws of the Dominican Republic, subject to mandatory consumer rights that cannot be waived; otherwise supply the approved jurisdiction | Approve the jurisdictional intent and final counsel-reviewed clause | Terms |
| Jurisdiction/venue | No clause approved | Courts of an explicitly named approved venue, arbitration/mediation, or another counsel-approved dispute process, preserving mandatory consumer venue rights | Select the process and exact venue; do not infer Santo Domingo or another city | Terms |
| Effective date | Unresolved | The actual publication/effective date, never backdated | Supply one exact ISO date after final-text approval | Privacy, Terms |
| Minimum age | Unresolved; no age gate exists | Adult-only; a defined minimum age with guardian consent; or institution/guardian-managed access | Select the minimum age and identify whether a runtime age/consent gate is required | Privacy, Terms, onboarding, stores |
| Minors/education policy | Unresolved | Do not target minors; guardian consent model; or school/institution-managed model with defined responsibilities | Approve the intended audience, consent model and school/guardian responsibilities | Privacy, Terms, onboarding, stores |
| Retention schedule | No universal schedule | Approve periods or criteria separately for active-account data, deleted-account data, backups, operational/security logs, billing records and support messages | Supply exact periods/criteria and lawful bases; engineering must not invent durations | Privacy, deletion, provider operations |
| Deletion language | Technical flow verified; legal exceptions and alternate request channel unresolved | State that the in-app flow attempts scoped deletion, reports partial failure for retry, does not itself cancel external billing, and may retain only approved legal/security/billing categories | Approve exceptions, public alternate verification method and response/completion timeframe | Privacy, deletion, Terms |
| Billing/renewal | Monthly prices verified; final contractual wording absent | Web subscriptions may renew monthly until canceled if that matches the approved Stripe catalog; Play wording must be conditional on active Play products | Approve renewal, charge timing, currency, taxes, price-change notice and provider-specific wording | Terms, Pricing, checkout |
| Cancellation | Provider management exists; final effect/timing absent | Cancel through the original provider; account deletion does not cancel billing. Continued access and effective cancellation date must match provider behavior | Approve exact cancellation timing and access-after-cancellation wording | Terms, Pricing, deletion |
| Refund policy | Unresolved | No general refund promise; provider rules and non-waivable statutory rights, or another counsel-approved policy | Select and approve the exact policy and request channel | Terms, Pricing, Contact |
| AI disclaimer | Draft says AI output may contain errors | “StudyBook AI provides educational assistance. AI-generated summaries, answers, assessments and resources may contain errors and should be reviewed before academic or professional reliance.” | Approve or replace this wording and identify prohibited/high-risk reliance | Terms, Privacy, product notices |
| User content | Responsibility stated; processing permission unresolved | User retains ownership; grants a limited, non-exclusive permission to host, process, transform and transmit content only to provide requested features, subject to deletion/retention terms | Approve license scope, user warranties and institutional responsibility | Terms, Privacy |
| IP/copyright contact | No process/contact approved | StudyBook AI retains rights in its software/brand without claiming unverified registrations; users retain their content rights; complaints use an approved monitored channel | Approve process, required notice information and monitored contact | Terms, Contact |
| Third-party disclosures | Incomplete public list | Supabase, OpenAI, Render and Vercel are current production providers; Stripe applies to active Web billing; Google Play applies only when Play billing is active; platform speech applies when voice recognition is used | Approve provider descriptions, roles, transfer language and conditional billing wording | Privacy, Terms |

## P2 Risk Acceptance

Each item requires an explicit `ACCEPT FOR INITIAL CONTROLLED LAUNCH` or
`DO NOT ACCEPT` decision.

| Risk | Current state | Human decision |
| --- | --- | --- |
| P2-A leaked-password protection | Supabase leaked-password protection is unavailable on the current Free plan | `PENDING` |
| P2-B rate limiting | API/contact throttling is per instance rather than distributed | `PENDING` |
| P2-C plan display propagation | A stale plan may appear briefly while backend authorization remains authoritative | `PENDING` |

## Approval Response Template

Complete every value. Use `BLOCKED PENDING COUNSEL` instead of guessing.

```text
LEGAL OPERATOR:
OPERATOR TYPE:
PUBLISHABLE ADDRESS:
SUPPORT CONTACT:
PRIVACY CONTACT:
CONTACTS CONFIRMED MONITORED: YES / NO

GOVERNING LAW:
JURISDICTION / VENUE / DISPUTE PROCESS:
EFFECTIVE DATE (YYYY-MM-DD):

MINIMUM AGE:
MINORS / GUARDIAN / INSTITUTION POLICY:

ACTIVE ACCOUNT RETENTION:
DELETED ACCOUNT RETENTION:
BACKUP RETENTION:
OPERATIONAL / SECURITY LOG RETENTION:
BILLING RECORD RETENTION:
SUPPORT MESSAGE RETENTION:
LEGAL / SECURITY RETENTION EXCEPTIONS:

PUBLIC DELETION ALTERNATE METHOD:
DELETION RESPONSE / COMPLETION TIMEFRAME:
DELETION LANGUAGE APPROVED: YES / NO

BILLING / RENEWAL WORDING:
CANCELLATION WORDING:
REFUND POLICY:
TAX WORDING:
PRICE CHANGE NOTICE:

AI DISCLAIMER: APPROVE PROPOSED / REPLACEMENT TEXT
USER CONTENT: APPROVE PROPOSED / REPLACEMENT TEXT
IP / COPYRIGHT PROCESS AND CONTACT:
THIRD-PARTY DISCLOSURES: APPROVE PROPOSED / REPLACEMENT TEXT

P2-A LEAKED PASSWORD RISK: ACCEPT FOR INITIAL CONTROLLED LAUNCH / DO NOT ACCEPT
P2-B RATE LIMITING RISK: ACCEPT FOR INITIAL CONTROLLED LAUNCH / DO NOT ACCEPT
P2-C PLAN DISPLAY RISK: ACCEPT FOR INITIAL CONTROLLED LAUNCH / DO NOT ACCEPT

I EXPLICITLY APPROVE THE COMPLETED PRODUCT/LEGAL DECISIONS FOR IMPLEMENTATION:
YES / NO

APPROVER NAME/ROLE:
APPROVAL DATE:
```

## Publication Gate

Until the completed sheet is explicitly approved:

- Contact remains `HUMAN ACTION` and delivery remains disabled.
- Privacy and Terms remain `DRAFT`.
- Public indexing remains disabled.
- No legal/contact runtime content is pushed or deployed.
- W7-C5 remains `NO-GO`.
