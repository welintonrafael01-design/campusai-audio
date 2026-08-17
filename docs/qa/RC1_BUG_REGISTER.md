# RC1 Bug Register - StudyBook AI v1.0

Generated: 2026-08-13

## Open Findings

| ID | Priority | Area | Status | Finding | Evidence | Recommendation |
| --- | --- | --- | --- | --- | --- | --- |
| RC1-P2-001 | P2 MEDIUM | Formatting | FIXED_IN_QA_BRANCH | `dart format --output=none --set-exit-if-changed .` reports 33 files would be formatted. | Baseline command returned exit code 1. The E2E automation sprint ran `dart format`, producing only mechanical formatting changes. | Re-run format check in final validation. |
| RC1-P2-002 | P2 MEDIUM | Repository hygiene | OPEN | `backend/.venv` is tracked in Git history/current index. | `git ls-files backend/.venv` returns 8445 files. | Remove tracked virtualenv in a dedicated cleanup commit and rebuild environment from `requirements.txt`; do not rewrite history without explicit approval. |
| RC1-P2-003 | P2 MEDIUM | Manual QA evidence | OPEN | Android real device, web two-user isolation, Stripe test and accessibility passes are not yet manually executed. | No Android device connected; Stripe config not verified. | Execute the manual QA matrix before promoting to RC2/Android Beta. |

## P0 Blockers

None reproduced in this automated pass.

## P1 High

None reproduced in this automated pass.

## Notes

No functional code was changed during this QA pass. No new features were added.
