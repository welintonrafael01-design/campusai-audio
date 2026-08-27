# Google Play Internal Testing Plan - StudyBook AI

Status: `PLAN READY; ARTIFACT BLOCKED`

## Entry Criteria

- Final application ID authorized.
- Non-debug upload key configured and backed up.
- Play App Signing enrollment plan approved.
- Production/approved test HTTPS API and matching Supabase public client
  configuration available.
- Android Stripe purchase surface resolved for Play Payments compliance.
- No P0/P1 product or security issue.

## Test Cohort

- Release owner.
- At least one Student-flow tester.
- At least one Teacher-flow tester.
- Accessibility/device-compatibility tester.
- Security/privacy reviewer for user isolation and logs.

No private email list belongs in this repository.

## Scenarios

1. Fresh install, launch, signup/signin, password recovery and logout.
2. Student PDF upload, Library restore, summary/chat with sources, quiz,
   flashcards, Voice Tutor and audible AudioBook.
3. Teacher courses, roster, attendance, grades, planning, rubric, question bank
   and exam.
4. Student A to Student B isolation, direct ownership denial and no stale cache
   flash.
5. Microphone deny/grant, offline/degraded network, human errors and retry.
6. Accessibility: TalkBack, 1.3x text, contrast, touch targets and keyboard.
7. Device/API matrix including Android 12 physical evidence plus Android 16,
   phone/tablet and 16 KB page-size capable environments.
8. Install update over prior internal build and cloud restore after reinstall.
9. Play Pre-launch report review for crashes, ANRs, permissions and layout.

## Severity And Exit

- P0/P1: stop rollout.
- P2: release owner documents acceptance or fixes before promotion.
- P3: backlog with evidence.
- Exit requires no P0/P1, successful auth/core Student/Teacher flows, no
  cross-user exposure, audible AudioBook, microphone path, acceptable startup/
  navigation performance and no critical accessibility barrier.

## Closed Testing Note

The Play account type and creation date are unknown. If it is a personal
developer account created after 13 November 2023, production access currently
requires at least 12 opted-in testers continuously for 14 days. Confirm in Play
Console; do not assume applicability.
