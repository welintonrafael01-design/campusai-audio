# RC1 Bug Register - StudyBook AI v1.0

Generated: 2026-08-13

## Open Findings

| ID | Priority | Area | Status | Finding | Evidence | Recommendation |
| --- | --- | --- | --- | --- | --- | --- |
| RC1-P2-001 | P2 MEDIUM | Formatting | FIXED_IN_QA_BRANCH | `dart format --output=none --set-exit-if-changed .` reports 33 files would be formatted. | Baseline command returned exit code 1. The E2E automation sprint ran `dart format`, producing only mechanical formatting changes. | Re-run format check in final validation. |
| RC1-P2-002 | P2 MEDIUM | Repository hygiene | FIXED_IN_QA_BRANCH | `backend/.venv` was tracked in Git history/current index. | W5.1 removed 8,445 files from the current index while preserving the ignored local environment; `git ls-files backend/.venv` now returns 0. | Recreate environments from `requirements.txt`; no history rewrite was performed. |
| RC1-P2-003 | P2 MEDIUM | Manual QA evidence | OPEN | Android real device, web two-user isolation, Stripe test and accessibility passes are not yet manually executed. | No Android device connected; Stripe config not verified. | Execute the manual QA matrix before promoting to RC2/Android Beta. |
| RC1-P1-004 | P1 HIGH | Voice Tutor | FIXED_AWAITING_PHYSICAL_RETEST | Android manifest omitted microphone group 7 (`RECORD_AUDIO`). | Samsung log contained 18 plugin warnings; plugin source maps group 7 to microphone. | Repeat permission deny/grant/settings flow on Samsung. |
| RC1-P1-005 | P1 HIGH | Document pipeline | FIXED_AWAITING_PHYSICAL_RETEST | Image-only PDF pages rotated 270 degrees reached OCR laterally, corrupting summary input. | CIAG checksum `72bc94d8...a4950`; corrected extraction returns 8 forward pages. | Re-upload the same PDF and verify summary semantics. |
| RC1-P2-006 | P2 MEDIUM | Chat UI | FIXED_AWAITING_PHYSICAL_RETEST | Full header plus mini player overflowed when IME reduced available height. | Reduced-viewport widget regression passes. | Repeat with Samsung keyboard and long messages. |
| RC1-P2-007 | P2 MEDIUM | Upload privacy | FIXED | Upload response and Flutter debug line exposed unnecessary document text and internal metadata. | Privacy contract and redaction regressions pass. | Monitor release logs during physical retest. |

## P0 Blockers

No open P1 code defect remains after remediation. Physical confirmation is still required.

## P1 High

None reproduced in this automated pass.

## Notes

No functional code was changed during this QA pass. No new features were added.
