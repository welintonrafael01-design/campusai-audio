# Android Build Baseline - StudyBook AI

Captured during Plan Master 7E on branch `qa/studybook-ai-rc1`.

| Item | Value |
| --- | --- |
| Flutter | 3.41.9 stable |
| Dart | 3.11.5 |
| Java | OpenJDK 21.0.10 (Android Studio JBR) |
| Gradle | 8.14 |
| Android Gradle Plugin | 8.11.1 |
| Kotlin plugin | 2.2.20 |
| Android SDK installed | 36.1 |
| compileSdk | 36 |
| targetSdk | 36 |
| minSdk | 24 (Android 7.0) |
| NDK default | 28.2.13676358 |
| Version | 1.0.0+1 |
| Application ID | `com.studybookai.app` - authorized final Android identity |

## Release Configuration Contract

- `API_BASE_URL` is mandatory in release and must be a non-local HTTPS origin.
- `APP_WEB_URL`, `PRIVACY_POLICY_URL` and `ACCOUNT_DELETION_URL` must be final
  public HTTPS values before any Play upload.
- Supabase URL and anon/publishable key are public client configuration, not
  secret storage. They still must match the approved production project.
- Never provide admin, service-role, Stripe secret, OpenAI secret, password or
  bearer token through `dart-define`.
- Release signing requires ignored `android/key.properties`.
- `STUDYBOOK_ALLOW_DEBUG_RELEASE_SIGNING=true` is only for a non-uploadable QA
  artifact and must not appear in a Play release workflow.
- Start from `mobile/campusai_mobile/config/release.example.json`, replace every
  `REQUIRED_` placeholder outside the repository, and run
  `tools/qa/check_android_release.sh` before building.
- Public URL validation rejects loopback and reserved `.invalid` hosts. Android Play product IDs are public
  identifiers; Google service credentials remain backend-only secrets.

## Environment Separation

| Environment | Runtime/API contract | Intended build |
| --- | --- | --- |
| Development | Loopback fallback permitted | debug |
| QA physical | Explicit loopback with `adb reverse tcp:8000 tcp:8000` | debug/profile only |
| Production | Explicit non-local HTTPS API/Web/privacy/deletion URLs, public Supabase config and Play product IDs | release AAB |

Do not use `QA/secrets` or the debug-signing override as input to a production
AAB. The release scanner validates the external public config before the
canonical build.

Canonical production command after blockers are resolved:

```bash
flutter build appbundle --release \
  --dart-define-from-file=/secure/path/release-public-config.json
```

The referenced config file may contain only public client configuration. A
dart define is extractable from the application and is never secret storage.

## Build Behavior

R8/resource shrinking and native debug-symbol generation are provided by the
current Flutter/AGP release pipeline. Dart obfuscation is not enabled and must
not be introduced without preserving symbol files and rerunning regression QA.
