# StudyBook AI Plan and Capability Matrix

## Production contract

StudyBook AI treats identity, commercial access, and product behavior as three
separate dimensions:

- **Role:** `student`, `teacher`, or backend-authorized `admin`.
- **Stored plan:** `free`, `student`, `teacher`, `institution`, or a retained
  legacy variant.
- **Capability:** one concrete operation such as `audiobook`,
  `question_bank`, or `teacher_workspace`.

Flutter uses this contract for navigation and human UX. FastAPI is the access
authority for authenticated, paid, role-sensitive, and owner-sensitive work.
No local value can grant a backend privilege.

## Commercial plans

| Commercial name | Stored plan | Required role for core product | Production status |
|---|---|---|---|
| Free | `free` | Student or Teacher | Production |
| Student Pro | `student` | Student or Teacher | Production |
| Teacher Pro | `teacher` | Teacher for Teacher Core | Production |
| Institution | `institution` | Teacher for Teacher Core | Limited, production-safe foundation |

Institution has no public checkout. It is displayed as an administered
agreement and does not claim multi-institution administration, enterprise
analytics, marketplace, digital twins, or autonomous agents.

## Role and plan rules

| Role | Plan | Effective experience |
|---|---|---|
| Student | Free | Core study experience with current Free limits |
| Student | Student Pro | Premium student learning tools |
| Student | Teacher Pro / Institution | Student experience; Teacher Core denied |
| Teacher | Free / Student Pro | Student capabilities only; Teacher Core denied |
| Teacher | Teacher Pro | Student Pro plus Teacher Core |
| Teacher | Institution | Current Teacher Core foundation only |
| Backend-authorized Admin | Any | Admin capabilities; authority is independent of plan |

Teacher access requires both a server role and a server subscription. Admin
access requires the backend `ADMIN_EMAILS` allowlist; metadata alone is not
admin authority.

## Capability matrix

`Yes*` means the capability also depends on Teacher role. Backend columns name
the authoritative enforcement used by production routes.

| Capability | Free | Student Pro | Teacher Pro | Institution | Backend authority |
|---|---:|---:|---:|---:|---|
| Library and owned cloud restore | Yes | Yes | Yes | Yes | Auth + owner scope |
| PDF upload | 3/month | Expanded | Expanded | Expanded | Auth + monthly server quota |
| Chat | 10/month | Expanded | Expanded | Expanded | Auth + owner + monthly server quota |
| Summary | 3/month | Expanded | Expanded | Expanded | Auth + monthly server quota |
| Flashcards | 1 set/month | Expanded | Expanded | Expanded | Auth + owner + monthly server quota |
| Quiz | 1 quiz/month | Expanded | Expanded | Expanded | Auth + owner + monthly server quota |
| Exam generation | No | Yes | Yes | Yes | Auth + owner + server capability |
| AudioBook generation | No | Yes | Yes | Yes | Auth + server plan capability |
| Owned AudioBook restore/playback | Yes | Yes | Yes | Yes | Auth + owner scope |
| Voice Tutor / TTS | No | Yes | Yes | Yes | Auth + server plan capability |
| Question bank | No | Yes | Yes | Yes | Auth + owner + server plan/usage limits |
| PDF export | Yes | Yes | Yes | Yes | Auth + server export policy |
| DOCX export | No | Yes | Yes | Yes | Auth + server export policy |
| PPTX/XLSX export | No | No | Yes | Yes | Auth + server export policy |
| Teacher Studio | No | No | Yes* | Yes* | Server role + active plan |
| Courses, students, attendance | No | No | Yes* | Yes* | Server role + active plan |
| Grades, weights, planning | No | No | Yes* | Yes* | Server role + active plan |
| Rubrics and Teacher exams | No | No | Yes* | Yes* | Server role + active plan |
| Certificates and recognitions | No | No | Yes* | Yes* | Server role + active plan |
| Admin console / analytics | No | No | No | No | Backend admin allowlist |

## Launch quota contract

Free quotas reset at the beginning of each UTC calendar month and are counted
from server-owned `user_usage_events`. Flutter may display cached usage but
cannot grant access or reset the server quota.

| Free event | Monthly limit | Usage event |
|---|---:|---|
| Document upload | 3 | `pdf_upload` |
| Chat message | 10 | `chat_message` |
| Summary generation | 3 | `summary_generated` |
| Flashcard set generation | 1 | `flashcards_generated` |
| Quiz generation | 1 | `quiz_generated` |

Paid plans retain their existing expanded operational safeguards and
per-generation size caps. Marketing does not describe them as unlimited.
AudioBook, Voice Tutor, Question Bank, Exam Generator, and Teacher Core are
server-denied for Free. Audio-minute values remain in the legacy client model
for compatibility and are not a public quota promise.

## Structured denials

FastAPI returns `capability_required` or `monthly_quota_exceeded` with a human
message, required commercial plan, and CTA metadata. Free premium learning
operations point to Student Pro. Teacher Core points to Teacher Pro. Flutter
preserves the human message and upgrade metadata; sensitive authorization is
still decided exclusively by FastAPI.

## Subscription states

| State | Paid capabilities | Notes |
|---|---|---|
| `active` | Enabled | Server subscription remains authority |
| `trialing` | Enabled | Treated as entitled |
| `past_due` | Disabled | Effective plan is Free |
| `canceled` | Disabled | Effective plan is Free |
| `inactive` | Disabled | Effective plan is Free |
| `expired` | Disabled | Effective plan is Free |
| `unknown` or missing | Disabled | Fails closed |

The client may cache server context to avoid visual churn. The cache is scoped
to the authenticated user and is never an authorization source.

## Legacy normalization

| Legacy value | Normalized result | Classification |
|---|---|---|
| `pro` | `student` | Legacy required |
| `educator` | `teacher` | Legacy required |
| `accessibility` | Student Pro base plus retained accessibility flags | Legacy required |
| `ultra` | Student Pro base plus retained historical premium flags | Legacy required |

Accessibility and Ultra are not shown as new checkout cards. Ultra does not
grant Teacher Core and cannot convert a Student into a Teacher. Existing
Stripe mappings remain only for compatibility with historical subscriptions.

## Inventory classification

| Element | Classification | Decision |
|---|---|---|
| FastAPI `ProductCapability` and resolver | Canonical | Server capability source |
| Flutter `EntitlementService` | Canonical | UX/navigation capability source |
| `AccessControlService` | Canonical | Route visibility using server context |
| `PlanGuardService` | Canonical cache | User-scoped UX cache only |
| `AppPlans` limits | Canonical compatibility | Existing numeric and export policy |
| `pro`, `educator` aliases | Legacy required | Normalize at boundaries |
| Accessibility/Ultra stored plans | Legacy required | Retain benefits, hide as new products |
| Direct plan checks in billing/plan display | Required boundary checks | Product selection/display only |
| Direct Teacher plan checks for authorization | Unsafe | Replaced by role + capability checks |
| Metadata-only Admin access | Unsafe | Denied; backend allowlist required |
| Exact AudioBook monthly marketing quota | Unsupported | Removed from visible plan promises |

## Session behavior

Login resets cached access to Free, synchronizes subscription and server role,
then conditionally loads Teacher data. User switching replaces plan, role,
status, navigation, and capabilities before privileged UI is shown. Unknown or
stale paid state remains Free until server confirmation.
