# StudyBook AI Web Deployment

Status: `W3 PREVIEW VALIDATED - PRODUCTION NOT AUTHORIZED`

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

## W3 Temporary Preview Evidence

The marketing root was validated on an anonymous temporary Vercel Preview:

```text
https://temporary-snappy-valley-ek1cq74.vercel.app
```

Validation occurred at `2026-09-05T23:56:24Z`. Vercel advertises a 60-minute
lifetime for this temporary URL. It is not an authenticated project, a durable
Preview alias or a production deployment. No claim URL, deployment credential or
token is stored in this repository.

Preview builds must receive:

```text
VERCEL_ENV=preview
NEXT_PUBLIC_WEB_URL=https://studybookai.com
NEXT_PUBLIC_APP_URL=https://app.studybookai.com
NEXT_PUBLIC_API_URL=https://api.studybookai.com
NEXT_PUBLIC_CONTACT_ENDPOINT=
```

`VERCEL_ENV=preview` activates three independent protections: route metadata with
`noindex`, a deny-all `robots.txt`, and the `X-Robots-Tag` response header. Normal
production behavior remains unchanged.

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

## W3 Promotion Blockers

- Create and authenticate the durable Vercel project with `web/marketing` as its
  root; do not deploy Flutter Web as the marketing root.
- Keep custom domains and GoDaddy DNS untouched until a separate production
  authorization.
- Deploy `app.studybookai.com`; it did not resolve during W3, so account CTAs are
  configured future targets rather than a live flow.
- Configure a reviewed contact endpoint or keep the honest unavailable state.
- Obtain legal approval before removing legal-page `noindex` directives.
- Add a tested Content Security Policy in a dedicated hardening pass. Existing
  HSTS, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy` and
  `Permissions-Policy` headers were verified on Preview.

The W3 Preview passed route, responsive, Booky asset, cross-browser, accessibility,
console, link and secret-exposure checks. Production deployment, DNS and custom
domain attachment remain explicitly unauthorized.
