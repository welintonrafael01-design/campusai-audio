# StudyBook AI Legal Decisions Required

Status: `HUMAN LEGAL AND PRODUCT APPROVAL REQUIRED`

This inventory separates facts verified in the repository from decisions that
engineering cannot make. It is not legal advice and does not make the current
public drafts effective.

## Technically Derivable Facts

| Field | Verified implementation fact | Where used |
| --- | --- | --- |
| Public domains | Marketing, app and API are configured for `studybookai.com`, `app.studybookai.com` and `api.studybookai.com` | Marketing metadata, CTAs and release configuration |
| Account data | Supabase Auth identity, role/app metadata and subscription state support authentication and entitlements | Auth, billing and route authorization |
| Private content | Documents and generated artifacts use owner-scoped records/private Storage in production | Library, RAG, AudioBook and Academic Engine |
| AI processors | Selected document excerpts, prompts, embeddings, transcripts or TTS text can be processed by OpenAI | Summary, chat, generation, RAG and speech |
| Voice | Voice Tutor can use platform speech recognition; StudyBook does not intentionally persist raw microphone recordings in that flow | Voice Tutor |
| Payments | Web billing uses Stripe; Android billing supports Google Play; account deletion does not itself cancel an external subscription | Billing and account deletion |
| Account deletion | Authenticated deletion inventories owner data and deletes Auth last; partial failure remains retryable | Settings and `DELETE /account/me` |

## Human Decisions

| Field | Why required | Where used | Recommended options to evaluate | Product/technical consequence |
| --- | --- | --- | --- | --- |
| Legal entity and registered address | Identifies controller/contracting party | Privacy, Terms, receipts, stores | Approved company/legal name and service address | Replace draft placeholders consistently |
| Governing law, jurisdiction and dispute process | Defines contractual venue and required notices | Terms | Counsel-approved jurisdiction and dispute model | Terms cannot become effective before approval |
| Effective date and versioning | Establishes applicability and change history | Privacy and Terms | Launch date plus revision process | Publish versioned pages and retain change log |
| Privacy contact | Required for rights/privacy requests | Privacy, deletion and contact routing | Monitored role address or verified portal | Configure provider route and operational SLA |
| Support and sales contacts | Establishes monitored customer channels | Contact, stores and billing support | Separate or shared monitored queues | Configure delivery routing; do not publish inactive addresses |
| Retention schedule | Defines how long each data class and operational log remains | Privacy, deletion, backup/log operations | Category-by-category schedule with legal exceptions | Implement provider/storage lifecycle policies and evidence |
| Age/minor scope and parental consent | Determines eligibility and educational safeguards | Privacy, Terms, onboarding and stores | Adult-only, minimum age, or verified guardian/institution model | May require age gate, consent and restricted processing |
| Refund/cancellation policy | Required for paid subscriptions | Terms, pricing support, Stripe/Play | Provider-aligned counsel-approved terms | Product copy and support process must match |
| Subscription terms | Defines renewal, taxes, trial behavior and termination | Terms and checkout | Monthly terms aligned to actual catalog/providers | Billing disclosures and receipts must be consistent |
| AI disclosure and acceptable reliance | Describes limitations and prohibited/high-risk use | Privacy and Terms | Counsel/product-approved educational assistance language | UI warnings and policy enforcement may need updates |
| Rights/DSAR workflow | Operationalizes access, correction, deletion and objections | Privacy and contact | Verified in-app plus monitored alternate channel | Identity verification, tracking and response process required |

## Age And Minors Inventory

- **Current technical state:** no age gate, guardian-consent flow or verified
  minor-specific processing mode was found in the audited marketing, Flutter or
  backend paths.
- **Current legal copy:** public drafts state that age scope and consent remain
  unresolved and do not claim the product is directed to children.
- **Missing decision:** approved minimum age, target audience, school/guardian
  responsibility and consent model for each launch jurisdiction.
- **Product options for review:** adult-only access; a defined minimum-age model;
  or an institution/guardian-managed model. Engineering must not select one
  without product and legal approval because each option changes onboarding,
  store declarations, data handling and support obligations.

## Publication Rule

`/privacy`, `/terms` and `/account-deletion` must remain visibly marked as
drafts and excluded from indexing until the applicable rows above are resolved,
reviewed and approved. Enabling general production indexing does not override
their page-level `noindex` protection.
