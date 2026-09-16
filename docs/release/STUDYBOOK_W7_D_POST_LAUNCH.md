# StudyBook AI W7-D Post-Launch Monitoring

Status: `PUBLIC LAUNCH COMPLETE - MONITORING ACTIVE`

Public launch date: `16 de septiembre de 2026`

Public surfaces:

- Marketing: `https://studybookai.com`
- Application: `https://app.studybookai.com`
- API health: `https://api.studybookai.com/health`

## Launch Controls

- Marketing product pages become indexable only when Vercel Production sets
  `ENABLE_PUBLIC_INDEXING=true`.
- Preview deployments remain noindex because indexing also requires
  `VERCEL_ENV=production`.
- Privacy, Terms and Account Deletion remain explicitly noindex and are omitted
  from the sitemap.
- No authenticated Flutter route or private API route belongs in the Marketing
  sitemap.
- Search Console registration or submission is not part of W7-D.

## Immediate Monitoring Checklist

| Area | What to monitor | Escalation signal |
| --- | --- | --- |
| API health | `/health`, startup and latency | Repeated non-200 responses or prolonged cold starts |
| Render | Deploy/runtime logs | Crash loops, memory pressure or repeated 5xx |
| Vercel | Build/runtime logs and domain status | Failed build, routing errors or unexpected noindex/index changes |
| Supabase Auth | Login, logout, session restore and recovery delivery | Increased auth failures, callback errors or recovery-email failures |
| Password reset | Delivery and PKCE recovery | Expired-link spikes, failed exchange or failed post-reset login |
| OpenAI | Authentication, quota and upstream errors | 401/403, quota exhaustion or sustained upstream failures |
| Upload/storage | Upload, private object access and restore | Failed uploads, ownership errors or missing durable objects |
| CORS | Official App origin and rejected unknown origins | Official origin denied or unknown origin allowed |
| HTTP errors | Unexpected 4xx/5xx by route | Sustained increase outside expected authorization denials |
| Contact | `studybookaiapp@gmail.com` | Unmonitored backlog or failed mailto flow |
| Entitlements | Student/Teacher subscription authority | Incorrect capability grant or denial |
| Plan UI | Account plan synchronization | Persistent stale plan after entitlement sync |
| Rate limiting | Abuse and burst behavior | Repeated abusive traffic or multi-instance bypass evidence |
| Accessibility | User reports and critical flows | Keyboard, reader, contrast or text-scale regression |

## Response Priorities

- P0: data exposure, privilege escalation, secret exposure, unrecoverable data
  loss or broad outage. Disable affected surface or roll back immediately.
- P1: broken authentication, payments/entitlements, upload, core learning flow,
  legal route or public indexing policy. Roll back the responsible deployment
  if a safe correction is not immediate.
- P2/P3: document, triage and schedule without hiding impact from users.

If public Marketing is broken after indexing activation, restore
`ENABLE_PUBLIC_INDEXING=false`, redeploy the last known-good Marketing source
and verify the global noindex header plus blocking `robots.txt` before closing
the incident.

## Accepted And Deferred Follow-Up

- Leaked-password protection remains an accepted P2 until the required
  Supabase plan/control is approved.
- Per-instance rate limiting remains an accepted P2 for the controlled initial
  launch; shared enforcement is required before horizontal scale or when abuse
  evidence appears.
- Transient plan visualization remains P2 while backend entitlement authority
  stays correct.
- Pro Consumidor review/registration is `DEFERRED BY PRODUCT OWNER` and remains
  a post-launch compliance follow-up. No filing or registration is claimed.

## Launch Evidence

| Field | Result |
| --- | --- |
| Launch commit | `f196ec53588724cc27dfda20902b7ff114976264` |
| Vercel deployment | `dpl_6UUJdYoCLsLg4nRFhzrFphLCPhPe` |
| Deployment state | Production / Current / READY |
| Validated launch timestamp | `2026-09-16 13:09:01 AST` (`America/Santo_Domingo`) |
| Public indexing | ENABLED for normal Marketing product pages |
| Legal indexing policy | Privacy, Terms and Account Deletion remain noindex |
| Robots | Allows Marketing crawling and disallows the three legal routes |
| Sitemap | Canonical Marketing URLs only; no App, API, preview, localhost or legal routes |
| Release tag | Annotated `v1.0.0`, pushed to `origin`, targeting the launch commit |
| Marketing/App/API/TLS | PASS |
| Auth/session restore | PASS |
| CORS | Official App origin allowed; unknown origin rejected |
| Secret/source-map check | PASS; no client secret exposure and source map probe not public |

Search Console registration/submission was not performed. No DNS, database,
backend, Flutter, Supabase or secret change was part of W7-D.
