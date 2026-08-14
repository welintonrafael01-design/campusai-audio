# 09 — Role / Plan / Permission Matrix

## Current plans

| Plan | Current role behavior | Target migration |
|---|---|---|
| Free | limited uploads/chats; basic tools | Keep |
| Student | student premium | Rename to Student Pro |
| Accessibility | separate plan | Convert to accessibility capability/add-on |
| Teacher | teacher tools | Rename to Teacher Pro |
| Ultra | everything enabled | Convert to add-on/limits bundle |

## User types

| User type | Role | Plan | Allowed modules | Backend authority | Frontend authority today | Gap |
|---|---|---|---|---|---|---|
| Guest | none | free/local | auth only, maybe public verify | none | local fallback | require auth before app |
| Student Free | student | free | dashboard, library, limited AI | partial usage endpoints | local `PlanGuardService` | backend entitlement |
| Student Pro | student | student | all student tools | billing/subscription | local after sync | route guard |
| Accessibility | student + accessibility | accessibility/capability | audio, voice, reading prefs | subscription | local plan | model as capability |
| Teacher Pro | teacher | teacher | Teacher Studio + student tools | subscription | local plan | role vs plan split |
| Institution Admin | admin | institution | admin console, billing, rosters | backend role/claims | missing | rebuild |
| Billing Admin | admin | any | financial dashboard | backend email allowlist | route visible risk | hidden route + guard |

## Required guard

Implement one global guard:

- public routes: `/auth`, `/reset-password`, `/verify/:certificateId`.
- authenticated routes: all product routes.
- teacher routes: courses, students, attendance, gradebook, teaching plan, rubric, saved exams, academic dashboard.
- admin routes: `/admin`, `/admin/financial-dashboard`.

