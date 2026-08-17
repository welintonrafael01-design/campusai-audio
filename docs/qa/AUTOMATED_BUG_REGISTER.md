# Automated Bug Register - StudyBook AI RC1

Generated: 2026-08-17

| ID | SEVERITY | MODULE | DESCRIPTION | ROOT CAUSE | STATUS | FIX COMMIT | RETEST |
| --- | --- | --- | --- | --- | --- | --- | --- |
| AUTO-P2-001 | P2 MEDIUM | E2E Config | Full authenticated E2E cannot execute without QA Supabase credentials and user fixtures. | External QA credentials were not available in the environment. | OPEN | N/A | Provide `QA_STUDENT_A_EMAIL`, `QA_STUDENT_A_PASSWORD`, `QA_STUDENT_B_EMAIL`, `QA_STUDENT_B_PASSWORD`, `QA_TEACHER_EMAIL`, `QA_TEACHER_PASSWORD`. |
| AUTO-P2-002 | P2 MEDIUM | Audio/Voice | AudioBook sound quality and Voice Tutor microphone quality cannot be asserted automatically. | Requires physical audio output/input and browser/device permissions. | MANUAL_REQUIRED | N/A | Execute manual device QA and capture evidence. |
| AUTO-P2-003 | P2 MEDIUM | E2E Coverage | Several authenticated click paths are represented as integration-test placeholders until QA credentials and fixture upload harness are available. | File picker, generated AI resources and teacher data require an environment-safe fixture harness. | OPEN | N/A | Implement full click paths for Home Upload, AI Tools, Library/Learning, Teacher and Account once QA users are provisioned. |

## P0

None reproduced.

## P1

None reproduced.

## Bugs Auto-Fixed

None. No reproducible P0/P1 defect was found in this automated pass.
