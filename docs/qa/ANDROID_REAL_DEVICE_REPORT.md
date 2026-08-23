# Android Real Device Report - RC1

Status: `MANUAL_REQUIRED`

## Latest Physical Run

The 2026-08-22 Samsung run found release blockers in microphone permission,
keyboard-constrained chat layout and rotated scanned-PDF OCR. Their code causes
are remediated on the QA branch and documented in
`docs/qa/PHYSICAL_ANDROID_FAILURE_REMEDIATION.md`.

Current gate: `READY_FOR_PHYSICAL_RETEST`, not PASS.

## Automated Build Evidence

| Artifact | Status | Path |
| --- | --- | --- |
| Debug APK | PASS | `mobile/campusai_mobile/build/app/outputs/flutter-apk/app-debug.apk` |
| Release APK | PASS | `mobile/campusai_mobile/build/app/outputs/flutter-apk/app-release.apk` |

`adb devices` returned no connected Android device during this run, so install/open/crash validation was not performed.

## Samsung / Physical Android Instructions

1. Start backend locally:

```bash
cd /Users/welintonmejia/Desktop/campusai-audio/backend
source .venv/bin/activate
uvicorn app.main:app --host 127.0.0.1 --port 8000
```

2. Connect Android device with USB debugging enabled:

```bash
adb devices
adb reverse tcp:8000 tcp:8000
```

3. Install debug APK:

```bash
adb install -r /Users/welintonmejia/Desktop/campusai-audio/mobile/campusai_mobile/build/app/outputs/flutter-apk/app-debug.apk
```

4. Capture logs:

```bash
/Users/welintonmejia/Desktop/campusai-audio/tools/qa/clear_android_logs.sh
/Users/welintonmejia/Desktop/campusai-audio/tools/qa/start_android_logs.sh
```

5. Use API base URL in app configuration:

```bash
API_BASE_URL=http://127.0.0.1:8000
```

## Required Smoke Tests

| Test | Expected | Status |
| --- | --- | --- |
| App opens without crash | Dashboard/auth loads | MANUAL_REQUIRED |
| Login/logout | Correct user session | MANUAL_REQUIRED |
| PDF upload | Document becomes active | MANUAL_REQUIRED |
| Chat | Response tied to active document | MANUAL_REQUIRED |
| Library | Only current user data | MANUAL_REQUIRED |
| Teacher guard | Student cannot enter Teacher | MANUAL_REQUIRED |
| Admin guard | Non-admin sees friendly 403/redirect | MANUAL_REQUIRED |
| CIAG rotated scan | Summary matches inclusion/accessibility source | RETEST_REQUIRED |
| Chat with IME | No overflow with keyboard and active player | RETEST_REQUIRED |
| Voice Tutor microphone | One permission prompt and recognized input | RETEST_REQUIRED |
