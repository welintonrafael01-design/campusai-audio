# Production Domain And Public URLs

Status: `CONFIGURATION CONTRACT READY - HUMAN DOMAIN REQUIRED`

This document defines the production URL contract without selecting or
claiming ownership of a domain. Every `<DOMAIN>` value is a placeholder and
must be replaced only after DNS, TLS, hosting and ownership are approved.

## Canonical Public URLs

| Purpose | Required value | Consumer |
| --- | --- | --- |
| Public Web app | `APP_WEB_URL=https://<DOMAIN>` | Backend CORS and billing redirects |
| Public API | `API_BASE_URL=https://api.<DOMAIN>` | Flutter release build |
| Privacy policy | `PRIVACY_POLICY_URL=https://<DOMAIN>/privacy` | Flutter settings and Play Console |
| Account deletion | `ACCOUNT_DELETION_URL=https://<DOMAIN>/account-deletion` | Play Console and public support |

`APP_WEB_URL` must be an HTTPS origin without a path. The other public URLs
must be HTTPS, non-local and must not use the reserved `.invalid` suffix.

## Backend Environment Contract

Production must set:

```text
APP_ENV=production
APP_WEB_URL=https://<DOMAIN>
BACKEND_CORS_ORIGINS=https://<DOMAIN>
APP_SUCCESS_URL=https://<DOMAIN>/#/plans?checkout=success
APP_CANCEL_URL=https://<DOMAIN>/#/plans?checkout=cancel
STRIPE_CUSTOMER_PORTAL_RETURN_URL=https://<DOMAIN>/#/settings
```

`BACKEND_CORS_ORIGIN_REGEX` must remain unset in production. If exact Stripe
redirect variables are omitted, the backend derives them from `APP_WEB_URL`.
Production startup/requests fail closed when required public configuration is
missing or uses HTTP, loopback, credentials in the URL, or `.invalid`.

The Stripe webhook destination, configured in Stripe rather than Flutter, is:

```text
https://api.<DOMAIN>/billing/webhook
```

## Flutter Release Contract

Start from `mobile/campusai_mobile/config/release.example.json` and create an
external public configuration file. It may contain public URLs, the Supabase
publishable/anon key and Play product IDs. It must never contain service-role,
OpenAI, Stripe, Google service-account, password, bearer-token or keystore
secrets.

Validate before building:

```bash
tools/qa/check_android_release.sh \
  /secure/path/release-public-config.json

flutter build appbundle --release \
  --dart-define-from-file=/secure/path/release-public-config.json
```

The current signed AAB is signing evidence only. It must not be uploaded until
the final domain values pass this validation and a new artifact is generated.

## Supabase Dashboard Actions

After the domain is approved, configure the production project with:

- Site URL: `https://<DOMAIN>`.
- Allowed password-reset redirect: `https://<DOMAIN>/#/reset-password`.
- Any future mobile deep link only after the app implements and tests it.

Do not add wildcard redirect domains unless a separate security review
authorizes them.

## Human Deployment Gate

1. Approve and register `<DOMAIN>`.
2. Configure DNS and valid TLS for Web and API hosts.
3. Deploy the API with exact CORS origins and production environment values.
4. Configure Supabase and Stripe redirects.
5. Publish privacy and deletion pages after legal review.
6. Rebuild, scan and hash the final AAB. Do not reuse a validation artifact.
