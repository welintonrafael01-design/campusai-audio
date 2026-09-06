# StudyBook AI Contact Architecture

Status: `IMPLEMENTED, DELIVERY PROVIDER REQUIRES HUMAN CONFIGURATION`

## Public Contract

The marketing form posts JSON to the same-origin `POST /api/contact` route.
The browser receives one of these structured outcomes:

- `202`: a configured provider accepted the message.
- `400/413/415`: invalid, stale, oversized or unsupported input.
- `403`: origin validation failed.
- `429`: the local abuse threshold was exceeded.
- `503 contact_unavailable`: no reviewed provider is configured, so no data was
  transmitted.
- `503 delivery_failed`: a configured provider rejected or failed delivery.

The UI never declares success unless the provider accepts the request.

## Controls

- Same-origin and `Sec-Fetch-Site` checks.
- JSON-only requests and an 8 KiB request limit.
- Typed allowlist validation, 100-character name, 254-character email and
  2,000-character message limits.
- Honeypot field and a form dwell window from 2.5 seconds to one hour.
- Five attempts per ten-minute client bucket, with `Retry-After` on rejection.
- Request IDs, `Cache-Control: no-store`, an eight-second provider timeout and
  no message-body logging.
- HTTPS-only webhook target with a server-only shared secret.

The in-memory limiter is useful defense in depth but is scoped to an individual
serverless instance. Production still requires a reviewed provider and a
distributed control such as Vercel Firewall/WAF, provider-side throttling or a
durable rate-limit store. Spam protection is therefore `PARTIAL` until that
human infrastructure decision is complete.

## Server Environment

```text
CONTACT_DELIVERY_PROVIDER=disabled | webhook
CONTACT_DELIVERY_WEBHOOK_URL=<HTTPS_PROVIDER_ENDPOINT>
CONTACT_DELIVERY_WEBHOOK_SECRET=<SERVER_ONLY_SECRET>
```

Do not use `NEXT_PUBLIC_` for delivery credentials. The endpoint and secret
must exist only in Vercel server environments. The current implementation is
provider-neutral at the form boundary; replacing the webhook adapter does not
change the browser contract.

Potential future routing aliases are `support@studybookai.com`,
`privacy@studybookai.com` and `sales@studybookai.com`. They are planning names,
not verified or active addresses, and must not be published as monitored
contacts until human configuration and delivery testing are complete.

## Production Activation

1. Select the monitored support/privacy workflow and accountable team.
2. Configure a provider endpoint that accepts the documented server payload.
3. Store its URL and secret in Vercel, scoped to Preview first.
4. Test success, rejection, timeout, abuse limits and redaction.
5. Configure distributed spam protection.
6. Promote the reviewed variables to Production.
7. Confirm retention and deletion handling for submitted messages.

No provider, support address or privacy address is claimed as active by this
document.
