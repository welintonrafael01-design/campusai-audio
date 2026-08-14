# Web Multiuser Report - RC1

Status: `MANUAL_REQUIRED`

## Launch Command

```bash
cd /Users/welintonmejia/Desktop/campusai-audio/mobile/campusai_mobile
flutter run -d chrome --web-port=3000 \
  --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Do not pass `ADMIN_API_KEY` to Flutter.

## Two-User Checklist

| Area | Usuario A | Usuario B | Expected | Status |
| --- | --- | --- | --- | --- |
| Login | Required | Required | Independent sessions | MANUAL_REQUIRED |
| Library documents | Upload PDF A | Login B | B cannot see A document | MANUAL_REQUIRED |
| Chats | Create chat A | Login B | B cannot see A chat | MANUAL_REQUIRED |
| StudyResults | Generate quiz A | Login B | B cannot see A result | MANUAL_REQUIRED |
| AudioBooks | Create audio A | Login B | B cannot see A audio | MANUAL_REQUIRED |
| Favorites | Favorite A | Login B | B cannot see A favorite | MANUAL_REQUIRED |
| Logout/login | Logout A, login B | Logout B, login A | Scope switches cleanly | MANUAL_REQUIRED |
| Role/plan | Student vs Teacher | Different role | Correct dashboard/tools | MANUAL_REQUIRED |

## Evidence Required

- Screenshots for Usuario A and Usuario B library/dashboard.
- Browser console with no privacy-related errors.
- Backend logs showing authenticated user context.
- `QA/runs/<timestamp>/` bundle from `tools/qa/collect_qa_bundle.sh`.

