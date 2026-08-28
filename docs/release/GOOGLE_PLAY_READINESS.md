# Google Play Readiness - StudyBook AI

Plan Master 7E-R status: `TECHNICAL REMEDIATION IMPLEMENTED`

No artifact has been uploaded. Internal Testing remains blocked until the
human/deployment configuration listed below is supplied and a non-debug AAB is
generated.

## Remediated Release Controls

| Control | Result |
| --- | --- |
| Android identity | `com.studybookai.app`; regression test rejects `com.example` |
| Version | 1.0.0 (1) |
| minSdk / compileSdk / targetSdk | 24 / 36 / 36 |
| Release API | Fail-closed unless `API_BASE_URL` is a non-local HTTPS origin |
| Release signing | Reads ignored `key.properties`; production build fails without it |
| Android checkout | Google Play Billing client; Android never opens Stripe Checkout |
| Web checkout | Stripe preserved |
| Entitlement authority | Backend subscription state only |
| Play purchase verification | Authenticated server contract; fail-closed verifier pending external credentials |
| Account deletion | In-app reauthentication plus owner-scoped backend purge, Auth last |
| Privacy action | Visible and configurable; no false URL when absent |
| Data Safety | Technical draft updated for deletion and Play Billing |

## Account Deletion Scope

`DELETE /account/me` derives the account exclusively from the bearer token and
rejects extra owner fields. It inventories private Storage objects and document
IDs, removes Storage, local PDFs, Chroma collections, owner-prefixed MP3s,
certificates, chats/messages, StudyResults, AudioBooks, educator tables, usage,
subscription mappings, workspaces/documents and finally Supabase Auth. If a
stage fails, Auth remains available and the response requires a retry.

External Stripe/Google subscriptions are not silently canceled. The user must
manage them with the provider; web deletion requirements are documented in
`ACCOUNT_DELETION_WEB_REQUIREMENTS.md`.

## Billing Safety

Android product IDs are supplied through release configuration and queried via
the official Flutter `in_app_purchase` plugin. Purchased/restored results are
sent to `/billing/google-play/verify-purchase`; unknown products, inactive
purchases, wrong account bindings and client-injected plans are denied. The
default backend verifier grants nothing until Google Play Developer API
credentials and the approved verifier are deployed.

## Remaining Human / Deployment Actions

1. Register `com.studybookai.app` in Play Console and enroll in Play App Signing.
2. Generate and securely back up the upload key; configure ignored
   `android/key.properties`.
3. Provision the approved production HTTPS API and public Supabase client
   values outside the repository.
4. Create Student Pro and Teacher Pro subscription products and deploy backend
   Google Play verification credentials.
5. Publish the legally approved privacy policy and external account-deletion
   page, then supply both HTTPS URLs.
6. Complete Play Data Safety, app access, content rating, audience, support and
   store assets.
7. Build a non-debug AAB and rerun `tools/qa/check_android_release.sh` before
   any upload.

## 7E-R Validation Evidence

- Backend: 117 tests passed; `compileall` passed.
- Flutter: 125 tests passed; `flutter analyze` reported no issues.
- Web release build: passed with a non-local HTTPS validation origin.
- QA APK: passed; SHA-256
  `00a61a46e790f261cfbfb24a95a468dec6637f370dcc56ba441d9d0040dbdd75`.
- QA AAB: passed; SHA-256
  `0d839129122f7f3156bf19603c6dffc85a8085d6b0132d929bf9e9442b5f9ea1`.
- Both Android artifacts report `com.studybookai.app`, version `1.0.0` (1),
  target SDK 36 and the Play Billing permission. They are local QA artifacts
  signed by the Android debug certificate under the explicit QA override and
  are not uploadable release candidates.
- The production AAB command without the override stopped as required because
  no upload signing configuration exists. Release config and artifact scans
  passed; the placeholder example config was rejected.

## Decision

The five 7E technical designs are remediated. Internal Testing remains `NO`
because signing, production URLs, Play products/verifier and Play Console/legal
publication are external actions. A QA artifact generated with the explicit
debug-signing override is never uploadable.

Official references:

- <https://developer.android.com/google/play/requirements/target-sdk>
- <https://developer.android.com/google/play/billing/integrate>
- <https://support.google.com/googleplay/android-developer/answer/9858738>
- <https://support.google.com/googleplay/android-developer/answer/13327111>
- <https://support.google.com/googleplay/android-developer/answer/10787469>
