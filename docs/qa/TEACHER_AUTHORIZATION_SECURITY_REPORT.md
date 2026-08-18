# Teacher Authorization Security Report

## Problem

Teacher routes were hidden in Flutter, but the corresponding FastAPI endpoints
only required a valid Supabase JWT. Any authenticated Student could invoke
Educator synchronization and teacher-only document generation directly.
Flutter also merged `user_metadata` after `app_metadata`, allowing editable
metadata to override a server-managed role in client-side navigation.

## Final Rule

`require_teacher_access` is the single backend dependency for Teacher-only
operations. Access is allowed when either:

- the user email is authorized by the existing server-side `ADMIN_EMAILS`
  policy; or
- `auth.users.raw_app_meta_data.role` is `teacher` or legacy `educator`, and
  `public.user_subscriptions.subscription_status` is `active`, and the plan is
  `teacher`, `ultra`, or legacy `educator` normalized to `teacher`.

An authenticated user that does not satisfy this rule receives HTTP 403 with a
generic message. Missing or invalid authentication continues to return HTTP
401. `user_metadata`, Flutter route parameters, and SharedPreferences never
participate in backend authorization.

## Sources Of Authority

- Identity: Supabase JWT validated server-side through `auth.get_user`.
- Role: server-managed `app_metadata.role` only.
- Plan and subscription status: `public.user_subscriptions`, resolved by the
  authenticated Supabase user ID.
- Admin: existing backend `ADMIN_EMAILS` policy.
- Flutter plan state: cache and UX hint only.

## Protected Endpoints

### Educator

- `GET /educator/snapshot`
- `POST /educator/sync`

### Teacher Documents

- `POST /documents/import-grades-excel`
- `POST /documents/import-grades-pdf`
- `POST /documents/import-students-pdf`
- `POST /documents/teaching-plan/{document_id}`
- `POST /documents/rubric/{document_id}`
- `POST /documents/study-guide/{document_id}`
- `POST /documents/teaching-resources/{document_id}`
- `POST /documents/analyze-assessment`

### Teacher Exports

- `POST /export/student-transcript-pdf`
- `POST /export/rubric-pdf`
- `POST /export/teaching-plan-pdf`
- `POST /export/final-report-pdf`

### Academic Recognition

- `GET /certificates/stats`
- `GET /certificates/list`
- `POST /certificates/auto-recognitions`

`GET /certificates/verify/{certificate_id}` remains public by design so an
external recipient can validate a certificate identifier.

Document-based operations retain their existing ownership checks after Teacher
authorization. Teacher access does not grant access to another user's document.

## Deliberately Shared Student And Teacher Endpoints

The following remain authenticated and controlled by plan limits and ownership,
without requiring a Teacher role:

- document upload, chat, AudioBook, audio, Voice Tutor and flashcards;
- `POST /documents/question-bank/{document_id}`;
- `POST /documents/exam/{document_id}`;
- workspace flashcards, question bank and exam;
- generic PDF, DOCX, PPTX and XLSX exports;
- exam, certificate and academic badge exports.

Question Bank and Exam are Student Pro capabilities as well as Teacher tools.
Converting them to Teacher-only would be a product regression.

## Flutter Access Control

`AccessControlService` resolves privileged roles exclusively from
`appMetadata.role`. `userMetadata` is accepted by the pure resolver only to make
the rejection behavior explicit in tests and is intentionally ignored. Missing
or unknown server role falls back to Student.

Teacher navigation now requires both a server-managed Teacher role and a cached
plan whose static capabilities include Educator tools. A modified local plan
cannot elevate a Student role. This remains a UX guard; FastAPI is the security
boundary.

## Tests

Backend tests cover:

- Student rejection from Educator snapshot and sync;
- HTTP 401 without authentication;
- central dependency role, plan and status combinations;
- legacy `educator` and `ultra` compatibility;
- current Admin policy;
- Teacher success for an owned document;
- Teacher rejection for a document owned by another user;
- Student access retained for Question Bank and Exam;
- Student rejection from recognition listing/writes while certificate
  verification remains public;
- server identity retaining `app_metadata` without user metadata.

Flutter tests cover:

- Teacher and Admin resolution from `appMetadata`;
- all requested `userMetadata` escalation and override cases;
- Student and Teacher route behavior;
- local Teacher plan failing to elevate Student;
- Guest redirect to Auth.

## Residual Risks

- SharedPreferences can temporarily display stale plan UI until subscription
  synchronization completes, but cannot authorize backend access.
- Flutter Admin navigation uses server-managed app metadata, while backend Admin
  authorization remains the separate `ADMIN_EMAILS` policy.
- Role and subscription are read in separate server operations; revocation takes
  effect on the next endpoint request, with no long-lived entitlement cache.
