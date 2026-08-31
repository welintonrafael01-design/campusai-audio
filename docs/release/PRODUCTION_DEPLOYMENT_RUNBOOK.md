# Production Deployment Runbook

Status: `DOMAIN READY - DO NOT DEPLOY WITHOUT REMAINING APPROVALS`

Registered domain: `studybookai.com`.

This runbook prepares Vercel and Render but does not authorize deployment, DNS
changes, Play upload, push or tagging.

## 1. Remaining Human Inputs

- Approved legal entity, privacy/support contacts, effective date, retention
  criteria, age scope and account-deletion response process.
- Authorized production Supabase project and reviewed deployed RLS/Storage.
- Backend secret-manager values for the implemented variable names.
- Actual Student Pro and Teacher Pro product IDs from Play Console.
- Backend-only Google Play Developer API verifier and service identity.
- A decision for backend local writable state on Render.

Stop if any required value is represented by `REQUIRED_*`, a bracketed
placeholder, localhost, HTTP, `.invalid`, a guessed value or a client-side
secret.

## 2. Create The Vercel Project

Use the repository and select:

```text
Root Directory: mobile/campusai_mobile
Framework Preset: Other
Build Command: bash tool/build_vercel_web.sh
Output Directory: build/web
```

Add the exact public variables and authorized Supabase public values listed in
`PRODUCTION_DOMAIN_AND_PUBLIC_URLS.md`. Do not add service-role, OpenAI, Stripe,
Google service-account, password or signing values.

Keep the initial deployment as preview evidence. The legal pages intentionally
carry `noindex` and draft notices until human review is complete.

## 3. Create The Render Service

Review and import `render.yaml`. It uses:

```text
Python: backend/.python-version
Build: python -m pip install --upgrade pip && python -m pip install -r requirements.txt
Start: python -m uvicorn app.main:app --host 0.0.0.0 --port $PORT
Health: /health
Auto deploy: off
```

Render prompts for each `sync: false` value. Supply only authorized values in
the dashboard; never place them in Git. Confirm `/health` reports `status=ok`,
service `StudyBook AI API` and the Render commit SHA before attaching DNS.

### Render Persistent-State Blocker

The backend currently writes mutable data to several local locations,
including `backend/chroma_db`, `backend/app/database/document_registry.json`,
`backend/app/audio`, `backend/storage` and certificate/usage files. Render's
filesystem is ephemeral unless a paid persistent disk is attached, and one
disk preserves only its mount subtree.

Do not send production traffic until one of these is reviewed and tested:

1. Consolidate all required mutable paths under one configurable persistent
   data root and attach a single-instance Render disk; or
2. Move the remaining state to Supabase/object storage and a shared vector
   store so the API is stateless and horizontally scalable.

This runbook does not choose a paid plan, disk size or architecture by guess.

## 4. Configure Domains And DNS

After both projects exist:

1. Add `studybookai.com` and `www.studybookai.com` to Vercel.
2. Add `api.studybookai.com` to the Render service.
3. Copy the exact records displayed by each provider into the DNS dashboard.
4. Wait for provider verification and valid public TLS.
5. Redirect `www` to canonical `https://studybookai.com`.

Use `PRODUCTION_DNS_SETUP.md`. Never substitute a remembered Vercel IP or a
guessed Render CNAME.

## 5. Supabase And Stripe

After Web TLS is active:

1. Set Supabase Site URL to `https://studybookai.com`.
2. Add only `https://studybookai.com/#/reset-password` as the tested Web reset
   redirect.
3. Configure the Stripe webhook at
   `https://api.studybookai.com/billing/webhook`.
4. Confirm success, cancel and portal returns remain under
   `https://studybookai.com`.
5. Verify webhook signatures, checkout ownership and subscription sync.

## 6. Public Legal Pages

The static paths exist at `/privacy` and `/account-deletion`, but they are
drafts. Before public launch:

1. Approve every legal/contact/retention/age field.
2. Deploy and test the verified account-deletion alternative.
3. Remove draft banners and `noindex` only after approval.
4. Test keyboard, mobile width, screen reader and plain-language readability.
5. Submit the final public URLs to Play Console.

## 7. Production Verification

Before traffic:

1. Run backend compile and tests from the release commit.
2. Run Flutter analyze/tests and the Vercel build contract.
3. Verify exact CORS preflight from apex and `www`; reject other origins.
4. Verify Student A/B isolation, Teacher authorization and denied Admin.
5. Verify uploads, RAG, Voice Tutor and AudioBook across a restart.
6. Verify privacy-safe logs, health/build SHA and rollback procedure.
7. Verify the deployed filesystem strategy survives redeploy/restart.

## 8. Final Android Artifact

Create an external configuration from
`mobile/campusai_mobile/config/release.example.json`, fill only authorized
public Supabase/Play values, then run:

```bash
tools/qa/check_android_release.sh /secure/path/release-public-config.json

cd mobile/campusai_mobile
flutter build appbundle --release \
  --dart-define-from-file=/secure/path/release-public-config.json
```

Confirm package `com.studybookai.app`, version `1.0.0+1`, target SDK `36`, the
approved signer and a new SHA-256. The prior signing artifact is not the final
domain-configured artifact.

## 9. Rollback

- Preserve the previous backend/Web artifact and configuration revision.
- Roll back application and configuration together when contracts differ.
- Disable affected billing/AI routes server-side if verification or cost
  controls fail.
- Never restore a client-side entitlement or bypass server verification.
- Document incident scope without copying tokens, documents or user content.
