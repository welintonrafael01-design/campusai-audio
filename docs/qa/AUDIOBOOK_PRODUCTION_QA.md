# AudioBook Production QA

## Backend freshness

Backend changes require a clean process restart before QA. Start the API with
the commit under test exposed through `/health`:

```bash
cd /Users/welintonmejia/Desktop/campusai-audio
export APP_BUILD_SHA="$(git rev-parse HEAD)"
PYTHONPATH=backend backend/.venv/bin/uvicorn app.main:app \
  --host 127.0.0.1 --port 8000
```

In a second terminal, verify that the running process matches the checkout:

```bash
cd /Users/welintonmejia/Desktop/campusai-audio
EXPECTED_BUILD_SHA="$(git rev-parse HEAD)" tools/qa/check_backend.sh
```

Do not accept a physical or browser result when this check reports `STALE` or
when `build_sha` is `unknown` for a release evidence run.

## Production flow

1. Open Library and select a specific document.
2. Open Document Detail and choose AudioBook.
3. Confirm the Studio names the selected document before generation.
4. Generate once and verify the button remains disabled until completion.
5. Confirm chapters appear and the first chapter can play or use the explicit
   guided-reading fallback.
6. Verify play, pause, resume, seek, +/-10 seconds, speed and next chapter.
7. Simulate cloud failure: the local AudioBook must remain playable and show a
   synchronization retry.
8. Retry twice and confirm only one `${source_document_id}_audiobook` result
   exists.
9. Restart the app and confirm the same owner restores the AudioBook and its
   progress.
10. Sign in as a second user and confirm neither metadata nor audio is
    accessible.

## Responsive matrix

Validate widths 320, 360, 390, 411 and 430 px at text scales 1.0, 1.2 and 1.3.
Use long titles and each state: generating, ready, syncing and sync failed.
There must be no RenderFlex overflow or unreachable player control.

## Performance evidence

Compare debug, profile and release separately. Record startup, Studio entry,
player preparation and chapter-list interaction. Debug Choreographer warnings
alone are not a release defect; capture profile/release evidence before filing
a performance blocker.
