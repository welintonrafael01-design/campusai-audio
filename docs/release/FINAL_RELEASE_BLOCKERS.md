# Final Release Blockers

Date: `2026-08-31`

Technical P0: `0`

Technical P1: `0`

Public release decision: `BLOCKED BY HUMAN ACTION AND EXTERNAL CONFIGURATION`

## P1 Release Gates

These are release-critical gates, but are not unresolved product-code defects.

| ID | Type | Gate | Owner action | Exit evidence |
| --- | --- | --- | --- | --- |
| 7F-P1-01 | External config | `studybookai.com` is registered, but Vercel/Render DNS and TLS are not configured | Create the approved services, copy provider-issued DNS targets and verify Web/API TLS | Public HTTPS Web and API smoke tests |
| 7F-P1-02 | External config | Schema, RLS and durable persistence pass locally, but production Supabase is not migrated or verified | Follow the controlled migration runbook in an approved window; validate private Storage, pgvector, backfill and owner isolation | Backup plus sanitized catalog and two-user authorization evidence |
| 7F-P1-03 | Human action / external config | Play products and live purchase verification are absent | Create actual products, configure Play Developer API server credentials and license testers | Backend-verified test purchase and restore/cancel evidence |
| 7F-P1-04 | Human/legal action | Privacy and account-deletion pages remain drafts | Approve legal fields, monitored contacts, retention/age decisions and deploy both public pages | Accessible public URLs accepted by Play Console |
| 7F-P1-05 | Human action | Play Console application, declarations and internal track are not complete | Complete App Signing, App Content, Data Safety, reviewer access and listing inputs | Play Console checklist plus internal-track processing result |
| 7F-P1-06 | External config | No final artifact exists with real production public config | Rebuild from reviewed commit after gates 01-05; rescan signer, hash, URLs and secrets | New AAB hash/certificate/config report |

## P2 Open Risks

| Source | Risk | Disposition |
| --- | --- | --- |
| `SEC-7D-001` | Repository RLS/Storage evidence is closed; deployed policy state remains unknown | Conditional deployment verification gate |
| `SEC-7D-002` | Account erasure requires deployed schema/Storage and retention evidence | Verify before production |
| `SEC-7D-003` | Legacy unowned certificate records require synthetic/real-data confirmation | Verify before external release if records were real |
| `SEC-7D-004` | Rate limiting is in-memory and per-IP | Accepted only for controlled RC; monitor and plan distributed limits |
| `SEC-7D-005` | CSP/HSTS depend on final CDN/reverse proxy | Required at Web deployment |
| `SEC-7D-006` | CIAG legacy QA deduplication remains incomplete | Keep separate and owner-safe |
| `REL-7E-006` | Data Safety, store content and brand assets are not approved | Human review before track promotion |

## P3 Open Risks

| Source | Risk | Disposition |
| --- | --- | --- |
| `SEC-7D-007` | Local user cache relies on OS/browser sandbox | Accepted for v1; document shared-device clearing |
| `SEC-7D-009` | `flutter_markdown` is deprecated | Dependency-maintenance follow-up |

## Closed In 7F

`REL-7F-001`: certificate, badge and transcript QR links no longer embed a
localhost URL. Production verification URLs derive from the validated
`APP_WEB_URL`, with regression coverage for fail-closed behavior.

`7F-P1-07`: production code no longer depends on Render filesystem persistence.
The disposable local gate verified restart restoration for documents, RAG,
AudioBook audio and certificates, plus account-deletion cleanup. Remote
Supabase migration remains tracked separately by `7F-P1-02`.

`SEC-7D-008`: W5.1 removed all 8,445 `backend/.venv` dependency files from
the current Git index while preserving the ignored developer environment. No
history rewrite was performed.

## Stop Conditions

Do not upload or deploy if any of these occurs:

- A real public URL is absent, non-HTTPS, local or placeholder.
- A production secret is supplied through Flutter or a client artifact.
- The final AAB signer differs from the approved upload certificate.
- The backend grants an entitlement without provider verification.
- Student/Teacher/Admin or cross-user authorization evidence fails.
- Privacy/deletion URLs are unavailable or still contain draft placeholders.
- Deployed Supabase tables/buckets expose another user's data.
