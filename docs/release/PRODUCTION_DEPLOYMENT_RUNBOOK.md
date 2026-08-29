# Production Deployment Runbook

Status: `PREPARED - DO NOT EXECUTE WITHOUT APPROVED INPUTS`

This runbook intentionally contains no real domain, product ID, credential or
secret. It does not authorize deployment, Play upload, push or tagging.

## 1. Required Human Inputs

- Approved `<DOMAIN>` with DNS/TLS ownership.
- Approved legal entity, privacy/support contacts, effective date, retention
  criteria, age scope and account-deletion process.
- Authorized production Supabase project and reviewed RLS/Storage policies.
- Backend secret-manager entries for the existing server-side variable names.
- Actual Student Pro and Teacher Pro product IDs from Play Console.
- Backend-only Google Play Developer API service identity.
- Authorized Play Console application, testers, reviewer access and listing.

Stop if any input is represented by `REQUIRED_*`, `<...>`, localhost, HTTP,
`.invalid`, a guessed value or a client-side secret.

## 2. DNS And TLS

1. Configure the approved Web host at `https://<DOMAIN>`.
2. Configure the API host at `https://api.<DOMAIN>`.
3. Issue valid public TLS certificates and enforce HTTPS redirects.
4. Confirm certificates, hostname coverage and renewal monitoring.
5. Do not enable broad wildcard CORS or Supabase redirects.

## 3. Supabase Production Review

1. Confirm the project is the authorized production project.
2. Inventory every table/bucket used by the backend.
3. Verify RLS on sensitive tables where anon/authenticated access is possible.
4. Verify the document bucket is private and policies do not expose prefixes.
5. Confirm app metadata is role authority and user metadata cannot elevate it.
6. Confirm service-role access exists only in the backend runtime.
7. Execute two-user owner-isolation tests against documents, StudyResults,
   AudioBooks, Teacher data and signed downloads.
8. Record policy evidence without exporting secrets or personal content.

Repository SQL cannot be used as deployment evidence because this repository
does not contain the production migrations/RLS policy definitions.

## 4. Backend Deployment

Configure these value names in the approved server secret/config system:

```text
APP_ENV=production
APP_WEB_URL=https://<DOMAIN>
BACKEND_CORS_ORIGINS=https://<DOMAIN>
OPENAI_API_KEY=<SERVER_SECRET>
SUPABASE_URL=<APPROVED_PROJECT_URL>
SUPABASE_ANON_KEY=<SERVER_CONFIG>
SUPABASE_SERVICE_ROLE_KEY=<SERVER_SECRET>
STRIPE_SECRET_KEY=<SERVER_SECRET>
STRIPE_WEBHOOK_SECRET=<SERVER_SECRET>
GOOGLE_PLAY_STUDENT_PRODUCT_ID=<PLAY_PRODUCT_ID>
GOOGLE_PLAY_TEACHER_PRODUCT_ID=<PLAY_PRODUCT_ID>
```

Use only variable names implemented by the selected production verifier; do
not create an undocumented credential contract. Add its backend-only Google
credential variables only after that implementation is selected and reviewed.
Configure billing success, cancel and portal destinations from `APP_WEB_URL`
or exact approved HTTPS URLs.

Before traffic:

1. Run backend compile/tests from the release commit.
2. Start the production process with health/readiness checks.
3. Verify exact CORS preflight from the approved Web origin.
4. Verify authentication, owner isolation, AI errors and redaction.
5. Verify Stripe webhook signature and Play verification fail closed.
6. Verify certificate/badge/transcript QR links use the public Web origin.
7. Keep rollback artifact/config available.

## 5. Public Web And Legal Pages

1. Complete legal review of the privacy and deletion drafts.
2. Remove every draft placeholder only with approved facts.
3. Deploy `/privacy` and `/account-deletion` over HTTPS.
4. Deploy the Flutter Web app with the approved API/public configuration.
5. Configure CSP, HSTS, MIME types and cache rules at the CDN/reverse proxy.
6. Smoke-test Student, Teacher and denied Admin behavior.
7. Verify Settings links and the authenticated account deletion flow.

Do not describe a public deletion alternative as operational until its identity
verification workflow is deployed and tested.

## 6. Google Play Billing And Console

1. Register `com.studybookai.app` in the authorized developer account.
2. Enroll in Play App Signing using the approved upload certificate.
3. Create actual subscription products and activate the intended base plans.
4. Configure license testers and internal track access.
5. Configure the backend-only Developer API verifier and product mapping.
6. Test purchase, acknowledgement, restore, cancellation, expiry, replay and an
   unknown product; the backend must remain entitlement authority.
7. Complete App Content, Data Safety, content rating, target audience, reviewer
   access and public policy URLs.

## 7. Final Android Artifact

Create an external public configuration file based on
`mobile/campusai_mobile/config/release.example.json`. Never place server
secrets, passwords or signing data in it.

```bash
tools/qa/check_android_release.sh /secure/path/release-public-config.json

cd mobile/campusai_mobile
flutter analyze
flutter test
flutter build appbundle --release \
  --dart-define-from-file=/secure/path/release-public-config.json
```

Then verify:

- package `com.studybookai.app`, version `1.0.0+1`, target SDK `36`;
- approved upload certificate;
- new AAB SHA-256;
- release manifest, cleartext/backup/exported components and 64-bit ABIs;
- absence of secrets, QA identities, local hosts and reserved invalid hosts;
- working production API/auth/billing/account-deletion flows.

The 7F AAB hash is not the hash of this future final-config artifact.

## 8. Internal Test And Promotion

1. Upload only after every P1 gate in `FINAL_RELEASE_BLOCKERS.md` is closed.
2. Validate install/update, signup/login/logout, Student A/B isolation, Teacher
   authorization, denied Admin, documents, AI, Voice Tutor and AudioBook.
3. Validate purchase lifecycle and account deletion on the distributed build.
4. Review crashes, ANRs, startup, accessibility and privacy-safe logs.
5. Promote only with an explicit GO decision and recorded evidence.

## 9. Rollback

- Preserve the previous backend/Web artifact and configuration revision.
- Roll back application code and configuration together when contracts differ.
- Disable affected billing products or AI routes server-side if authorization,
  verification or cost controls fail.
- Never restore a client-side entitlement or bypass server verification.
- Document incident scope without copying tokens, documents or user content.
