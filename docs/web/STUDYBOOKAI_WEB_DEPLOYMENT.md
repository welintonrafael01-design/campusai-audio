# StudyBook AI Web Deployment

Status: `PREVIEW READY - DO NOT DEPLOY IN W1`

## Vercel Project

```text
Root Directory: web/marketing
Framework Preset: Next.js
Install Command: pnpm install --frozen-lockfile
Build Command: pnpm build
Output: managed by Next.js/Vercel
Node.js: >=20.9.0
```

Required public environment values:

```text
NEXT_PUBLIC_WEB_URL=https://studybookai.com
NEXT_PUBLIC_APP_URL=https://app.studybookai.com
NEXT_PUBLIC_API_URL=https://api.studybookai.com
NEXT_PUBLIC_CONTACT_ENDPOINT=
```

The contact endpoint must remain empty until a reviewed, rate-limited backend
route exists. Never place Supabase service role, OpenAI, Stripe or Google
service-account secrets in the marketing project.

## Routing And Domains

Next.js owns route rendering; no Flutter-style SPA fallback is required.
`vercel.json` documents a permanent `www.studybookai.com` to apex redirect.
After a Vercel project exists, copy its exact DNS instructions. Do not invent
CNAME targets or IP addresses.

## Pre-deployment Gates

1. Complete legal placeholders and approve publication.
2. Add the official Booky asset.
3. Configure and security-review the contact endpoint.
4. Run Vercel preview Lighthouse and responsive/cross-browser QA.
5. Verify canonical, sitemap, robots and redirect behavior on the preview.
6. Approve DNS and production promotion separately.
