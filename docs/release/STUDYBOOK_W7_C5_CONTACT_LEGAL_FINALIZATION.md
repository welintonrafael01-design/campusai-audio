# StudyBook AI W7-C5 Contact And Legal Finalization

Status: `FINAL DRAFT INTEGRATED - FINAL HUMAN PUBLICATION APPROVAL PENDING`

Date: `2026-09-16`

Source of truth:
`docs/legal/STUDYBOOKAI_FINAL_HUMAN_APPROVAL_SHEET.md`, section
`FINAL HUMAN APPROVAL RESPONSE`, as superseded for operator identity by
`FINAL OPERATOR IDENTITY AMENDMENT` and for address status by
`FINAL PUBLISHABLE ADDRESS APPROVAL`.

## Integrated Decisions

| Field | Integrated state |
| --- | --- |
| Legal operator | Welinton Rafael Mejía González |
| Professional contact address | Bufete Jurídico “MULTISERVICIOS ZORRILLA”, Avenida Sabana Larga, núm. 148, Ensanche Ozama, Santo Domingo Este, República Dominicana; contact domicile only |
| Support/privacy/deletion/legal/IP contact | `studybookaiapp@gmail.com` |
| Contact form | Automated delivery remains disabled and is no longer presented as an operational form |
| Governing law/jurisdiction | Dominican Republic; specific venue/court wording remains under legal review |
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

## Deliberately Unresolved

- Specific venue/court/dispute wording: pending legal consistency review.
- Effective date: set only when final publication is explicitly approved; it
  must not be backdated.
- Final legal publication: not yet authorized.
- Public launch and indexing: not authorized.

## Public Content Updated

- `web/marketing/src/app/privacy/page.tsx`
- `web/marketing/src/app/terms/page.tsx`
- `web/marketing/src/app/contact/page.tsx`
- `web/marketing/src/app/account-deletion/page.tsx`
- `web/marketing/src/app/security/page.tsx`
- `web/marketing/src/app/pricing/page.tsx`

Privacy, Terms and Account Deletion retain page-level `noindex` and explicit
final draft notices. Privacy and Contact publish the approved professional
contact domicile without presenting its host as the operator. The effective
date remains pending. Contact exposes the approved monitored email while the
disabled automated delivery endpoint remains fail-closed.

## Consistency Result

The six public surfaces agree on operator, contact, age, retention, deletion,
prices, no-trial position, cancellation, first-payment refund, AI limitations,
content rights, providers and non-absolute security language. No resolved
placeholder remains in the public page sources.

## Validation

- Marketing lint: PASS.
- Marketing tests: `48 passed` across 8 files.
- Marketing production build: PASS, 17 routes generated.
- Local route smoke: 11 required routes PASS.
- Internal link check: 15 paths checked, 0 broken.
- Built legal-page noindex check: PASS for Privacy, Terms and Account Deletion.
- Tracked/intended first-party secret scan: PASS; 841 tracked text files
  checked, 0 high-confidence or local-private-value matches.
- `git diff --check`: PASS.
- Public indexing: DISABLED.
- Deployment: NOT PERFORMED.
- Push: NOT PERFORMED.

## Decision

```text
CONTACT CHANNEL: READY
PRIVACY: FINAL DRAFT
TERMS: FINAL DRAFT
LEGAL PUBLICATION: PENDING HUMAN/COUNSEL APPROVAL
PUBLIC INDEXING: DISABLED
FINAL DECISION: NO-GO
READY FOR FINAL TEXT REVIEW: YES
READY FOR W7-D: NO
```
