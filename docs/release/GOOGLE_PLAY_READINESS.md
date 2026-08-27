# Google Play Readiness - StudyBook AI

Plan Master 7E status: `FAIL - NOT READY FOR INTERNAL TESTING UPLOAD`

This status is an engineering gate, not a Play Console or legal decision.

## Android Identity And Build

| Control | Result |
| --- | --- |
| App label | PASS: StudyBook AI |
| Version | PASS: 1.0.0 (1); first-release proposal pending history confirmation |
| minSdk | PASS: 24 |
| compileSdk / targetSdk | PASS: 36 / 36 |
| API 36 toolchain | PASS: Flutter 3.41.9, AGP 8.11.1, Gradle 8.14, JDK 21 |
| Package ID | BLOCKER: `com.example.campusai_mobile` is provisional |
| Release signing | BLOCKER: no upload key; QA artifact uses Android Debug certificate |
| 64-bit | PASS: arm64-v8a present |
| Other ABIs | armeabi-v7a and x86_64 present |
| 16 KB ZIP alignment | PASS on release APK |
| R8 / symbols | Mapping and native debug-symbol archive generated |

## Validation Artifacts (Not Uploadable)

| Artifact | Size | SHA-256 |
| --- | --- | --- |
| `build/app/outputs/flutter-apk/app-release.apk` | 69,297,556 bytes | `f41e38a997ee7b082060793ae1e4f9f7720e9623e2f9128eded2138dd2fe6678` |
| `build/app/outputs/bundle/release/app-release.aab` | 53,325,810 bytes | `2654032ce29e2433e1848b96a9cbb8bb5a6c223c617f51637e87eaf08181bcd5` |

Both artifacts were built with the explicit QA debug-signing override. The APK
signature verifies, but its certificate owner is `CN=Android Debug`; the AAB
is therefore not an upload candidate.

Artifact scanning found no QA account identifier, hardcoded admin key,
service-role marker, bearer token value or credible OpenAI key. Loopback text
is present only in the release URL rejection guard and Flutter engine strings;
no loopback `API_BASE_URL` was supplied. Generic `password`, `Authorization`
and `Bearer` labels are expected auth/UI code, not credentials.

Changing the application ID requires authorization and coordinated edits to:

- `mobile/campusai_mobile/android/app/build.gradle.kts` (`namespace`,
  `applicationId`)
- `mobile/campusai_mobile/android/app/src/main/kotlin/com/example/campusai_mobile/MainActivity.kt`
  and its directory/package declaration
- Supabase redirect URLs, any OAuth/app-link configuration, release automation,
  Play package registration and signing/API-provider registrations
- tests/docs that assert the old identifier

No final identifier was invented in 7E.

## Manifest And Security

- Release is non-debuggable by default and shows no debug banner.
- `usesCleartextTraffic=false`; debug/profile alone allow local HTTP.
- `allowBackup=false`, `fullBackupContent=false`.
- Only launcher activity is intentionally exported. Plugin activity/provider
  are not exported; Profile Installer receiver is protected by `DUMP`.
- No deep link intent filter exists in the release manifest.
- Permissions are minimal: Internet, Record Audio, Network State and the
  signature-protected AndroidX compatibility permission.
- Release code now rejects missing, cleartext or local `API_BASE_URL` values.

## Technical Blockers

1. Authorize the immutable production application ID.
2. Create/configure an upload key and enroll in Play App Signing.
3. Provide the approved production or remotely reachable internal-test HTTPS
   API URL and matching Supabase public configuration.
4. Resolve Android digital subscription purchase UX. The app currently opens
   Stripe Checkout from the Plans screen, which is a potential Google Play
   Payments policy violation unless an applicable program/exception is
   approved. No Play Billing implementation was added in 7E.
5. Add an in-app and web account-deletion request, backed by a tested complete
   owner-scoped erasure lifecycle.

## Policy / Human Actions

- Publish and link an approved privacy policy.
- Complete Data Safety from the technical draft and processor contracts.
- Confirm target audience, content rating, AI-generated-content declaration,
  support contact and app-access credentials.
- Approve feature graphic, phone/tablet screenshots and store copy.
- Confirm developer account type/date and whether 12 testers for 14 continuous
  days applies before production access.
- Confirm Google Play developer/package verification in the account.

## 7D Residual Risk Impact

| Risk | Internal | Closed | Production |
| --- | --- | --- | --- |
| Deployed Supabase RLS not evidenced | Conditional gate; backend ownership is primary | Verify | Block production until verified |
| Complete delete lifecycle absent | Blocks truthful account-deletion claim | Blocks | Blocks |
| Legacy certificate history | Does not affect artifact; verify synthetic/real status | Conditional | Conditional privacy gate |
| In-memory rate limiting | Acceptable for controlled internal cohort | Capacity review | Distributed protection review required |
| Web CSP/HSTS | Does not block Android track | Does not block Android track | Blocks web deployment, not Android artifact |
| CIAG legacy data | No current isolation bypass; separate migration | Does not block | Does not block absent new evidence |

## Decision

The codebase can generate API-36 APK/AAB artifacts and has adequate manifest,
permission, branding and ABI foundations. The current artifact must not be
uploaded because identity, signing, production endpoint, billing policy and
account deletion are unresolved. No Google Play Console action was performed.

Official policy references:

- <https://developer.android.com/google/play/requirements/target-sdk>
- <https://support.google.com/googleplay/android-developer/answer/9858738>
- <https://support.google.com/googleplay/android-developer/answer/13327111>
- <https://support.google.com/googleplay/android-developer/answer/10787469>
- <https://support.google.com/googleplay/android-developer/answer/14151465>
