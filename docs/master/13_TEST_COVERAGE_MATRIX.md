# 13 — Test Coverage Matrix

| Module | Unit | Widget | Integration | E2E | Status |
|---|---|---|---|---|---|
| Auth | missing | minimal app load | missing | missing | Insufficient |
| Dashboard | missing | missing | missing | missing | Missing |
| Upload PDF | missing | missing | missing | missing | Critical gap |
| Chat | missing | missing | missing | missing | Missing |
| Library | missing | missing | missing | missing | Critical gap |
| AudioBook | missing | missing | missing | missing | Missing |
| Voice Tutor | missing | missing | missing | missing | Missing |
| Flashcards | missing | missing | missing | missing | Missing |
| Exam | missing | missing | missing | missing | Missing |
| Teacher Studio | missing | missing | missing | missing | Critical gap |
| Billing | backend pycache only | missing | missing | missing | Missing source tests |
| Route guards | missing | missing | missing | missing | Critical gap |
| Backend endpoints | missing source | n/a | missing | missing | Rebuild |

## Existing tests

- `mobile/campusai_mobile/test/widget_test.dart`: smoke-loads `StudyBookApp`.
- `backend/tests`: no `.py` source files found; only `__pycache__` artifacts.

## Required minimum suite

1. Flutter smoke: auth -> dashboard.
2. Upload controller unit with cancel/error/success.
3. Route guard tests by role/plan.
4. Library isolation and delete refresh.
5. AI feature API service tests with mocked HTTP.
6. Teacher Studio import/generate persistence tests.
7. Backend tests for upload, cloud isolation, billing webhook, document ownership.

