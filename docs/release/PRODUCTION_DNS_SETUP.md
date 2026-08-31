# Production DNS Setup

Status: `RECORD NAMES KNOWN - PROVIDER TARGETS PENDING`

This document does not modify DNS and intentionally contains no guessed IP,
CNAME or verification target.

## Planned Records

| Host | Purpose | Provider | Record type | Target/value |
| --- | --- | --- | --- | --- |
| `@` | Canonical Web app | Vercel | Use the type Vercel displays | Copy from Vercel after project creation |
| `www` | Web alias/redirect | Vercel | Use the type Vercel displays | Copy from Vercel after project creation |
| `api` | FastAPI custom domain | Render | Use the type Render displays | Copy from Render after service creation |

Do not use a remembered Vercel apex IP, a generic Render hostname or a value
from another project. Provider verification records, if requested, must also
be copied exactly from the matching project.

## Safe Order Of Operations

1. Create the Vercel project from `mobile/campusai_mobile` and complete a
   preview build.
2. Create the Render service from `render.yaml`, supply secrets in Render and
   pass `/health` without attaching production traffic.
3. Resolve and test the Render persistent-state blocker.
4. Add the three custom domains in the provider dashboards.
5. Record the exact provider-generated DNS instructions in the release ticket.
6. Apply those records in the authoritative DNS provider.
7. Wait for Vercel/Render domain verification and valid TLS.
8. Verify canonical redirect, API health and CORS from both Web origins.
9. Update Supabase and Stripe only after the HTTPS endpoints are stable.

## Verification Checklist

- `https://studybookai.com` serves the reviewed Flutter artifact.
- `https://www.studybookai.com` redirects to the canonical apex.
- `https://api.studybookai.com/health` returns the expected build SHA.
- HTTP redirects to HTTPS at all three hosts.
- Certificates cover the exact hosts and renew automatically.
- No wildcard CORS or wildcard Supabase redirect was introduced.
- DNS screenshots/exports contain no provider credentials or secret values.
