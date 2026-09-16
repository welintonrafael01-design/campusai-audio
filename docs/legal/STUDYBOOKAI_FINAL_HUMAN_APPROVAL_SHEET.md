# StudyBook AI W7-C5 Final Human Approval Sheet

Status: `LEGAL CONTENT APPROVED FOR 16 SEPTEMBER 2026 DEPLOYMENT - PUBLIC INDEXING DISABLED`

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
  unavailable response. `studybookaiapp@gmail.com` is the approved monitored
  channel for initial support, privacy, deletion and legal communications.
- Privacy, Terms and Account Deletion remain final drafts with page-level
  `noindex`. The effective date is set only at final publication and the
  professional contact address is approved in `FINAL PUBLISHABLE ADDRESS
  APPROVAL`. Public indexing remains disabled globally.

## Pre-Approval Decision Inventory

This inventory records the questions that preceded the Product Owner response
later in this document. The `FINAL HUMAN APPROVAL RESPONSE` section supersedes
resolved rows. The `FINAL PUBLISHABLE ADDRESS APPROVAL` section resolves the
address. The final jurisdiction section resolves the substantive venue rule.
The effective date remains tied to the actual authorized deployment date.

| Field | Current status | Proposed text/options | Human decision required | Document affected |
| --- | --- | --- | --- | --- |
| Legal operator | Unresolved | Exact registered entity name or exact legal name of the individual operator; do not use the product name alone unless it is the legal operator | Supply the exact publishable legal name and operator type | Privacy, Terms, Contact, deletion |
| Publishable address | Resolved | Professional contact domicile approved in the final address section | No further address decision required | Privacy, Terms, Contact |
| Support contact | No monitored channel | A real monitored StudyBook AI mailbox or an explicitly approved professional mailbox used temporarily | Supply the exact address and confirm it is monitored | Contact, Terms, pricing/support surfaces |
| Privacy contact | No monitored channel | Same mailbox as support if explicitly approved, or a separate monitored privacy mailbox | Supply the exact address and confirm the privacy request process | Privacy, deletion, Contact |
| Governing law | Resolved | Laws of the Dominican Republic, preserving mandatory consumer rights | No further substantive decision required | Terms |
| Jurisdiction/venue | Resolved | Competent courts of the Dominican Republic under applicable competence rules; no arbitrary exclusive court or mandatory arbitration | No further substantive decision required | Terms |
| Effective date | Resolved | 16 September 2026, matching the authorized legal deployment date | No further date decision required for W7-C6 | Privacy, Terms |
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
| P2-A leaked-password protection | Supabase leaked-password protection is unavailable on the current Free plan | `ACCEPTED FOR INITIAL CONTROLLED LAUNCH` |
| P2-B rate limiting | API/contact throttling is per instance rather than distributed | `ACCEPTED FOR INITIAL CONTROLLED LAUNCH` |
| P2-C plan display propagation | A stale plan may appear briefly while backend authorization remains authoritative | `ACCEPTED FOR INITIAL CONTROLLED LAUNCH` |

## Approval Response Template

This template records the questions presented before the final decisions below.

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

- Contact uses the approved monitored email; automated form delivery remains disabled.
- Privacy and Terms remain final drafts pending publication approval.
- Public indexing remains disabled.
- No legal/contact runtime content is pushed or deployed.
- W7-C5 remains `NO-GO`.

---

# FINAL HUMAN APPROVAL RESPONSE
## StudyBook AI — Initial Controlled Launch

Approval authority: Product Owner
Decision status: APPROVED FOR CONTENT INTEGRATION
Final legal publication remains subject to final consistency review.

### LEGAL OPERATOR

LEGAL OPERATOR:
Welinton Rafael Mejía González

STATUS:
APPROVED

NOTE:
Use "Welinton Rafael Mejía González" exactly as approved by the Product Owner
unless a future explicit human decision changes this instruction.


### CONTACT CHANNEL

CONTACT CHANNEL:
READY

APPROVED CONTACT:
studybookaiapp@gmail.com

SUPPORT CONTACT:
studybookaiapp@gmail.com

PRIVACY CONTACT:
studybookaiapp@gmail.com

STATUS:
APPROVED

The same monitored email may be used initially for support, privacy,
account-deletion and legal communications.

The currently disabled contact form must not be represented as operational
until an actual delivery provider is configured.


### PUBLISHABLE ADDRESS

PUBLISHABLE ADDRESS:
RESOLVED BY FINAL PUBLISHABLE ADDRESS APPROVAL

Use only the authorized professional contact address stated in the final
address approval section. It does not change the legal operator.


### GOVERNING LAW

GOVERNING LAW:
República Dominicana

STATUS:
APPROVED


### JURISDICTION

JURISDICTION:
República Dominicana

STATUS:
APPROVED

Competent courts are determined under applicable Dominican competence rules,
without prejudice to consumers' non-waivable rights.


### EFFECTIVE DATE

EFFECTIVE DATE:
16 DE SEPTIEMBRE DE 2026

RULE:
Do not backdate.

Use the actual date on which the final Privacy Policy and Terms of Service
are approved for public publication.


### MINIMUM AGE

MINIMUM AGE:
18 years

STATUS:
APPROVED FOR INITIAL CONTROLLED LAUNCH

Individual users must be at least 18 years old to independently create and
contract an individual StudyBook AI account during the initial launch phase.


### MINORS POLICY

MINORS POLICY:
APPROVED FOR INITIAL CONTROLLED LAUNCH

Persons under 18 may not independently create or contract an individual
StudyBook AI account during the initial launch phase.

Future access for minors may be enabled through:

- an authorized educational institution; or
- a parent or legal guardian with an appropriate consent mechanism.

Until StudyBook AI implements a specific parental/institutional consent
workflow, direct individual account creation is restricted to users
18 years of age or older.


### DATA RETENTION

DATA RETENTION:
APPROVED FOR INITIAL CONTROLLED LAUNCH

While an account remains active, StudyBook AI may retain the information
necessary to provide the service.

After a valid account-deletion request:

- personal data and user content should be deleted or anonymized from active
  production systems within a maximum operational target of 30 days;

- residual copies contained in backups may remain for up to 90 days before
  normal overwrite or deletion;

- records strictly required for security, fraud prevention, legal,
  accounting, tax, dispute-resolution or defense-of-rights purposes may be
  retained for the period legitimately required for those purposes.

StudyBook AI must not promise immediate deletion from every technical backup.


### ACCOUNT DELETION

ACCOUNT DELETION:
APPROVED FOR INITIAL CONTROLLED LAUNCH

The user may initiate account deletion through the Account section where
supported by the product.

After confirmed deletion:

1. access to the account is disabled as applicable;
2. deletion or anonymization from active systems begins;
3. the operational target for active-system deletion is a maximum of 30 days;
4. residual backup copies may remain for up to 90 days;
5. limited records may be retained when legitimately required for security,
   billing, legal obligations, claims or defense of rights.

Public legal text must remain consistent with actual backend behavior.


### BILLING AND RENEWAL

BILLING / RENEWAL:
APPROVED PRODUCT FACTS

Plans:

- Free: US$0
- Student Pro: US$6.99/month
- Teacher Pro: US$13.99/month
- Institution: Contact

There is no US$1 trial.

Paid subscription renewal language must match the actual payment provider and
checkout implementation before public billing is activated.


### CANCELLATION

CANCELLATION:
APPROVED FOR INITIAL CONTROLLED LAUNCH

Student Pro and Teacher Pro subscriptions may be cancelled at any time.

Cancellation:

- prevents the next renewal;
- does not immediately terminate an already-paid billing period;
- allows access to paid features until the end of the current paid period,
  subject to the actual billing-provider behavior;
- returns the account to the Free plan after the paid period ends unless the
  account is otherwise closed.

No separate cancellation penalty will be imposed by StudyBook AI.

Institution plans may also be governed by their applicable institutional
agreement.


### REFUND POLICY

REFUND POLICY:
APPROVED FOR INITIAL CONTROLLED LAUNCH

FIRST PAID SUBSCRIPTION:

A user may request a refund of the first Student Pro or Teacher Pro payment
within 7 calendar days following that initial charge.

This commercial first-payment refund benefit is intended to apply once per
user/account.

RENEWALS:

Ordinary renewal charges are not automatically refundable solely because the
service was not used when the service remained available and the renewal
occurred under the disclosed subscription terms.

Refund review remains available for situations including:

- duplicate charges;
- billing errors attributable to StudyBook AI;
- unauthorized or unrecognized charges, subject to verification;
- material service failure;
- inability to provide the purchased service;
- circumstances where applicable law requires a refund or other remedy.

Refund/contact requests should initially be sent to:

studybookaiapp@gmail.com


### TRIAL POLICY

TRIAL POLICY:
APPROVED

No US$1 trial.

No other free or paid trial should be advertised unless later expressly
approved and implemented.


### AI-GENERATED CONTENT

AI DISCLAIMER:
APPROVED PRINCIPLE

StudyBook AI uses artificial intelligence to generate educational and study
content.

AI-generated content may contain errors, omissions or inaccurate information.

Users should review important output before relying on it for academic,
professional, legal, medical, financial or other high-impact decisions.

StudyBook AI must not advertise AI output as guaranteed to be accurate,
complete or error-free.


### USER CONTENT

USER CONTENT:
APPROVED PRINCIPLE

Users retain the rights they lawfully hold in content they upload.

StudyBook AI should receive only the permissions reasonably necessary to:

- store;
- process;
- analyze;
- transform;
- generate study materials from;

user-provided content for the purpose of delivering the requested service.

The legal text must not unnecessarily transfer ownership of user content to
StudyBook AI.


### INTELLECTUAL PROPERTY / COPYRIGHT

IP / COPYRIGHT:
APPROVED PRINCIPLE

StudyBook AI retains rights in its software, product design, branding and
original platform materials to the extent legally applicable.

No trademark-registration, copyright-registration or similar registration
claim may be published unless that registration has actually been verified.

Copyright and intellectual-property inquiries may initially be directed to:

studybookaiapp@gmail.com


### THIRD-PARTY PROVIDERS

THIRD-PARTY DISCLOSURES:
APPROVED FOR FACTUAL DISCLOSURE

Production providers currently relevant for legal/privacy review include:

- OpenAI
- Supabase
- Render
- Vercel

Only providers actually active in production should appear in final public
legal documents.

A payment processor should be identified only when the production billing
flow is actually active and its use has been confirmed.


### SECURITY LANGUAGE

SECURITY LANGUAGE:
APPROVED

StudyBook AI may describe its technical and organizational security measures.

Do not make absolute claims such as:

- 100% secure
- unhackable
- zero risk
- guaranteed security

Security language must remain factual and non-absolute.


# P2 RISK ACCEPTANCE

## P2-A — LEAKED PASSWORD PROTECTION

DECISION:
ACCEPT FOR INITIAL CONTROLLED LAUNCH

The current Supabase Free configuration does not include leaked-password
protection.

This additional protection is accepted as a post-launch infrastructure
improvement.

It should be reevaluated when the Supabase plan is upgraded or when risk,
scale or product requirements justify the change.


## P2-B — PER-INSTANCE RATE LIMITING

DECISION:
ACCEPT FOR INITIAL CONTROLLED LAUNCH

The current backend rate limiting is per instance rather than distributed.

This is accepted for the initial controlled deployment operating with a
limited production footprint.

Distributed rate limiting should be implemented when scaling to multiple
instances or when traffic/security requirements justify centralized state.


## P2-C — TEMPORARY PLAN DISPLAY PROPAGATION

DECISION:
ACCEPT FOR INITIAL CONTROLLED LAUNCH

A temporary visual delay may occur while subscription state is synchronized.

Backend authorization remains the source of truth.

Testing did not demonstrate privilege escalation or unauthorized Teacher
access.

This is accepted as a non-blocking UX P2 for initial launch.


# FINAL STATUS OF THIS APPROVAL RESPONSE

LEGAL OPERATOR:
APPROVED

CONTACT CHANNEL:
READY

SUPPORT CONTACT:
APPROVED

PRIVACY CONTACT:
APPROVED

GOVERNING LAW:
APPROVED

JURISDICTION:
APPROVED

MINIMUM AGE:
APPROVED

MINORS POLICY:
APPROVED

DATA RETENTION:
APPROVED

ACCOUNT DELETION:
APPROVED

CANCELLATION:
APPROVED

REFUND POLICY:
APPROVED

AI DISCLAIMER:
APPROVED PRINCIPLE

USER CONTENT:
APPROVED PRINCIPLE

THIRD-PARTY DISCLOSURES:
APPROVED PRINCIPLE

P2 LEAKED PASSWORD RISK:
ACCEPTED

P2 RATE LIMITING RISK:
ACCEPTED

P2 PLAN DISPLAY RISK:
ACCEPTED

PUBLISHABLE ADDRESS:
RESOLVED BY FINAL PUBLISHABLE ADDRESS APPROVAL

EFFECTIVE DATE:
16 DE SEPTIEMBRE DE 2026

PRIVACY:
READY FOR FINAL DRAFT INTEGRATION

TERMS:
READY FOR FINAL DRAFT INTEGRATION

PUBLIC INDEXING:
DISABLED

PUBLIC LAUNCH:
NOT YET AUTHORIZED

NEXT ACTION:
Codex may integrate these approved decisions into the Privacy Policy,
Terms of Service, Contact, Account Deletion and related public legal content.

Codex must then perform a final cross-document consistency review and return
the resulting legal text for final human approval before deployment or
public indexing.

---

# FINAL OPERATOR IDENTITY AMENDMENT

## Superseding Human Decision

The prior operator identity decision is hereby superseded.

LEGAL OPERATOR:
Welinton Rafael Mejía González

PRODUCT / SERVICE NAME:
StudyBook AI

STATUS:
APPROVED FOR FINAL LEGAL DRAFT

PUBLIC LEGAL IDENTIFICATION:

StudyBook AI is a technology service operated by
Welinton Rafael Mejía González in the Dominican Republic.

PRIVACY RESPONSIBLE PARTY:

Welinton Rafael Mejía González, operator of StudyBook AI.

SUPPORT CONTACT:
studybookaiapp@gmail.com

PRIVACY CONTACT:
studybookaiapp@gmail.com

GOVERNING LAW:
República Dominicana

JURISDICTION:
República Dominicana

PUBLISHABLE ADDRESS:
RESOLVED BY FINAL PUBLISHABLE ADDRESS APPROVAL

EFFECTIVE DATE:
16 DE SEPTIEMBRE DE 2026

IMPORTANT:

Do not identify any commercial name as the operator of StudyBook AI in the
final public legal documents unless a future explicit human decision changes
this instruction.

Do not publish a personal identification number, tax identifier, national ID
number, or private residential address unless separately and explicitly
authorized.

This amendment is the current source of truth for the legal operator identity.

---

# FINAL PUBLISHABLE ADDRESS APPROVAL

PUBLISHABLE ADDRESS:
APPROVED

LEGAL OPERATOR:
Welinton Rafael Mejía González

PRODUCT / SERVICE:
StudyBook AI

AUTHORIZED PROFESSIONAL CONTACT ADDRESS:
Bufete Jurídico "MULTISERVICIOS ZORRILLA"
Avenida Sabana Larga, núm. 148
Ensanche Ozama
Santo Domingo Este
República Dominicana

PUBLICATION FORM:

Domicilio de contacto profesional:
Bufete Jurídico “MULTISERVICIOS ZORRILLA”,
Avenida Sabana Larga, núm. 148,
Ensanche Ozama, Santo Domingo Este,
República Dominicana.

IMPORTANT:

The professional address above is authorized for publication as the
contact/legal domicile used by StudyBook AI.

It does NOT change the legal operator.

The legal operator remains:

Welinton Rafael Mejía González

Do not describe MULTISERVICIOS ZORRILLA as the owner, operator,
controller, legal entity behind, or proprietor of StudyBook AI.

SUPPORT CONTACT:
studybookaiapp@gmail.com

PRIVACY CONTACT:
studybookaiapp@gmail.com

GOVERNING LAW:
República Dominicana

JURISDICTION:
República Dominicana

PUBLISHABLE ADDRESS:
RESOLVED

EFFECTIVE DATE:
16 DE SEPTIEMBRE DE 2026

---

# FINAL JURISDICTION AND CONSUMER CONTRACT GATE

GOVERNING LAW:
República Dominicana

FINAL JURISDICTION RULE:

Estos Términos se regirán e interpretarán conforme a las leyes de la República
Dominicana. Toda controversia relacionada con StudyBook AI será sometida a los
tribunales competentes de la República Dominicana, conforme a las reglas de
competencia aplicables, sin perjuicio de los derechos irrenunciables que
correspondan a los consumidores y usuarios conforme a la legislación vigente.

EFFECTIVE DATE RULE:

The authorized W7-C6 legal deployment date is 16 September 2026. Privacy and
Terms use `16 de septiembre de 2026` consistently. This date must not be reused
for a later first publication or retroactively applied to content that was not
deployed in this gate.

PRO CONSUMIDOR CONTRACT REVIEW / REGISTRATION:
DEFERRED BY PRODUCT OWNER

CLASSIFICATION:
POST-LAUNCH / COMPLIANCE FOLLOW-UP

No filing, registration or applicability determination has been performed, and
no registration number is claimed. This deferred item does not block W7-C6
technical/legal-content deployment and must remain in internal risk tracking.
