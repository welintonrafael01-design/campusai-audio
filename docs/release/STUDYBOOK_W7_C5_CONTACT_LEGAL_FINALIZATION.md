# StudyBook AI W7-C5 Contact And Legal Finalization

Status: `FINAL LEGAL CONTENT APPROVED FOR W7-C6 DEPLOYMENT - NOINDEX`

Date: `2026-09-16`

Source of truth:
`docs/legal/STUDYBOOKAI_FINAL_HUMAN_APPROVAL_SHEET.md`, section
`FINAL HUMAN APPROVAL RESPONSE`, as superseded for operator identity by
`FINAL OPERATOR IDENTITY AMENDMENT` and for address status by
`FINAL PUBLISHABLE ADDRESS APPROVAL`, plus the approved W7-C5.4 jurisdiction,
effective-date and consumer-contract gate.

## Integrated Decisions

| Field | Integrated state |
| --- | --- |
| Legal operator | Welinton Rafael Mejía González |
| Professional contact address | Bufete Jurídico “MULTISERVICIOS ZORRILLA”, Avenida Sabana Larga, núm. 148, Ensanche Ozama, Santo Domingo Este, República Dominicana; contact domicile only |
| Support/privacy/deletion/legal/IP contact | `studybookaiapp@gmail.com` |
| Contact form | Automated delivery remains disabled and is no longer presented as an operational form |
| Governing law/jurisdiction | Dominican Republic; competent Dominican courts under applicable competence rules, preserving consumers' non-waivable rights |
| Effective date | `16 de septiembre de 2026`, matching the authorized W7-C6 legal deployment date |
| Minimum age | 18 for independent individual accounts during the initial controlled launch |
| Minors | No independent account creation under 18; future guardian/institution access requires an implemented consent workflow |
| Active-system deletion | Maximum operational target of 30 days after a valid request |
| Residual backups | Up to 90 days |
| Retention exceptions | Narrow security, fraud, legal, accounting, tax, dispute and defense-of-rights purposes |
| Plans | Free US$0; Student Pro US$6.99/month; Teacher Pro US$13.99/month; Institution Contact |
| Trial | No US$1 or other trial approved |
| Cancellation | Before next renewal; paid access through the current period subject to provider behavior; no StudyBook AI penalty |
| Refund | First Student Pro/Teacher Pro payment may be requested within 7 calendar days once per account; approved renewal/exceptions wording included |
| AI | May contain errors; review required before academic, professional or high-impact reliance |
| User content | User retains lawful rights; only limited service-delivery processing permission is granted |
| Providers | Supabase, OpenAI, Render, Vercel; Stripe/Google Play/platform speech only when their respective channel is used |
| P2 risks | All three accepted for the initial controlled launch |

## Remaining Follow-Up Items

- Pro Consumidor contract review/registration: `DEFERRED BY PRODUCT OWNER`,
  classified as `POST-LAUNCH / COMPLIANCE FOLLOW-UP`; not filed, registered,
  resolved or determined inapplicable, and no registration number is claimed.
- Public indexing: not authorized and remains disabled.
- W7-D launch/indexing actions: outside W7-C6.

## Public Content Updated

- `web/marketing/src/app/privacy/page.tsx`
- `web/marketing/src/app/terms/page.tsx`
- `web/marketing/src/app/contact/page.tsx`
- `web/marketing/src/app/account-deletion/page.tsx`
- `web/marketing/src/app/security/page.tsx`
- `web/marketing/src/app/pricing/page.tsx`
- `docs/legal/STUDYBOOKAI_CONSUMER_TERMS_SUBMISSION_COPY.md`

Privacy, Terms and Account Deletion retain page-level `noindex` and explicit
final draft notices. Privacy and Contact publish the approved professional
contact domicile without presenting its host as the operator. Privacy and
Terms contain the final Dominican jurisdiction rule and the effective date
`16 de septiembre de 2026`. Contact exposes the approved monitored email while
the disabled automated delivery endpoint remains fail-closed.

## Consistency Result

The six public surfaces agree on operator, professional address, contact,
jurisdiction, age, retention, deletion, prices, no-trial position,
cancellation, first-payment refund, AI limitations, content rights, providers
and non-absolute security language. No resolved placeholder remains in the
public page sources.

## Validation

- Marketing lint: PASS.
- Marketing tests: `50 passed` across 8 files.
- Marketing production build: PASS, 17 routes generated.
- Local route smoke: 11 required routes PASS.
- Internal link check: 15 paths checked, 0 broken.
- Built legal-page noindex check: PASS for Privacy, Terms and Account Deletion.
- Tracked/intended first-party secret scan: PASS; 842 tracked/intended text files
  checked, 0 high-confidence or local-private-value matches.
- `git diff --check`: PASS.
- Public indexing: DISABLED.
- Deployment: NOT PERFORMED.
- Push: NOT PERFORMED.

## Required Placeholder Search

| Search category | Result | Classification |
| --- | --- | --- |
| Legacy final-publication marker | 0 occurrences | Cleared from tracked/current sources |
| Legacy blocked-address marker | 0 occurrences | Cleared; professional address is resolved |
| Former operator name | 0 occurrences | Cleared from tracked/current sources |
| Backlog annotations | 20 occurrences in 20 files | Intentional product backlog, README, generated platform or maintenance-script annotations; none are public legal placeholders |
| Manual external-action annotations | 26 occurrences in 8 files | Intentional historical QA or separate Play Console, reviewer-access, Data Safety, leaked-password-plan and release gates |

The manual-action files are historical or separately regulated operational
records: `docs/web/STUDYBOOKAI_WEB_QA.md`,
`docs/release/PRIVACY_POLICY_REQUIREMENTS.md`,
`docs/release/STUDYBOOK_W7_C_LAUNCH_READINESS.md`,
`docs/release/STUDYBOOK_W7_C4_UX_ACCESSIBILITY_LEGAL.md`,
`docs/release/PLAY_APP_CONTENT_CHECKLIST.md`,
`docs/release/FINAL_RELEASE_BLOCKERS.md`,
`docs/release/PLAY_REVIEWER_ACCESS.md` and
`docs/release/GOOGLE_PLAY_STORE_LISTING_CHECKLIST.md`. They do not appear in
the public legal page sources.

## Decision

```text
CONTACT CHANNEL: READY
PRIVACY: SUBSTANTIVE CONTENT FINAL
TERMS: SUBSTANTIVE CONTENT FINAL
PRO CONSUMIDOR: DEFERRED BY PRODUCT OWNER
CLASSIFICATION: POST-LAUNCH / COMPLIANCE FOLLOW-UP
LEGAL PUBLICATION: AUTHORIZED FOR W7-C6 ON 16 SEPTEMBER 2026
PUBLIC INDEXING: DISABLED
FINAL DECISION: GO FOR W7-C6 DEPLOYMENT
READY FOR LIVE LEGAL VALIDATION: YES
READY FOR W7-D: PENDING SUCCESSFUL W7-C6 LIVE VALIDATION
```
