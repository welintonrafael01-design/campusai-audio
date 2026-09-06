# StudyBook AI Web Security Headers

Status: `W4 IMPLEMENTED LOCALLY - PRODUCTION NOT DEPLOYED`

## Enforced Headers

All marketing routes receive:

- `Content-Security-Policy`
- `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `Permissions-Policy: camera=(), microphone=(), geolocation=()`
- `X-Robots-Tag: noindex, nofollow, noarchive` unless production indexing is
  explicitly approved.

The production CSP is:

```text
default-src 'self'; base-uri 'self'; connect-src 'self'; font-src 'self' data:; form-action 'self'; frame-ancestors 'none'; frame-src 'none'; img-src 'self' data: blob:; manifest-src 'self'; media-src 'self' blob:; object-src 'none'; script-src 'self' 'unsafe-inline'; script-src-attr 'none'; style-src 'self' 'unsafe-inline'; worker-src 'self' blob:
```

`unsafe-inline` remains in script/style policy for Next.js hydration and
framework styling. `unsafe-eval` and WebSocket sources are development-only for
Next HMR. A future nonce/hash migration can tighten this further, but it should
be measured against the deployed framework output.

`upgrade-insecure-requests` is intentionally omitted: production URLs already
fail closed to HTTPS and HSTS is emitted, while forcing upgrades in a local HTTP
production build breaks WebKit QA by converting local asset requests to TLS.

No analytics, tag manager, advertising, external font or media domain is
currently allowed. Any future provider requires a documented data-flow review,
minimal directive allowlisting, Preview console QA and explicit approval. Do
not widen `default-src` to accommodate a provider.

## Indexing Gate

Public indexing is allowed only when both conditions hold:

```text
VERCEL_ENV=production
ENABLE_PUBLIC_INDEXING=true
```

All other environments fail closed through metadata robots, `robots.txt` and
`X-Robots-Tag`. Legal drafts keep page-level `noindex` independently.

HSTS preload submission is a separate human action and must occur only after
all required subdomains are HTTPS-ready. Merely emitting the header does not
submit the domain to the preload list.
