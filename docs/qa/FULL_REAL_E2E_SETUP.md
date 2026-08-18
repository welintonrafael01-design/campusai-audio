# Full Real E2E Setup

The Full Real E2E runners require local, untracked QA credentials. Do not add
credentials to source control, test output, or shell history.

## Local configuration

Copy the tracked template at `QA/secrets.example/qa_android.example.json` into:

- `QA/secrets/qa_android.local.json` for the Android emulator.
- `QA/secrets/qa_web.local.json` for Chrome web testing.

Use `http://10.0.2.2:8000` as the Android emulator API base URL and
`http://127.0.0.1:8000` for the local web runner. Provide all required values
locally; placeholders are deliberately rejected.

## Validate configuration

```bash
tools/qa/validate_qa_secrets.sh QA/secrets/qa_android.local.json
tools/qa/validate_qa_secrets.sh QA/secrets/qa_web.local.json
```

## Start and check the backend

Start the backend through the normal local development workflow, then verify:

```bash
tools/qa/check_backend.sh
```

The runner never starts or changes backend services itself.

## Android emulator

Start an emulator available as `emulator-5554`, then run:

```bash
tools/qa/run_full_android_e2e.sh
```

## Chrome web runner

Ensure Chrome is available to Flutter, then run:

```bash
tools/qa/run_full_web_e2e.sh
```

Some scenarios remain explicitly marked `AUTOMATION_GAP` in the integration
suite and still require the associated manual QA evidence.

## Results

Each runner stores redacted output in `QA/automated/runs/<timestamp>_<target>/`.
The optional diagnostic bundle is written to `QA/runs/`. Both locations are
ignored by Git.

## Android log lifecycle

The Android runner clears logcat before Flutter starts and collects a finite,
redacted `adb logcat -d` dump after the test completes. It does not retain a
background `adb logcat` pipeline, so it does not need to wait for a live stream
at shutdown. If diagnostic log collection or the optional QA bundle fails, the
runner reports a warning and preserves the Flutter integration-test exit code.

## Known automation gaps

The following scenarios remain intentionally skipped as `AUTOMATION_GAP`; they
must not be treated as passing until their fixture or driver dependencies exist:

1. Teacher Studio: course and roster fixture harness.
2. AI Tools: uploaded fixture and backend AI execution harness.
3. Account/session restore: persisted fixture data.
4. Library/Learning: generated fixture assertions.
5. Home/Upload: Android file-picker driver support.
