# Secret Rotation Required - RC1

Generated: 2026-08-13

No secret values were printed or copied into this document.

## Current Tracked Files Review

| Secret type / pattern | Possible exposure | Rotation required | Recommended action |
| --- | --- | --- | --- |
| `.env` files | No tracked `.env` files found. Local ignored backend env files exist. | NO, unless manual history review finds prior commit. | Keep ignored; never commit local env files. |
| `ADMIN_API_KEY` | Server-side admin auth and documentation references found. No operational Flutter admin key found. | NO for current client bundle. | Continue keeping admin credentials server-side only. |
| `OPENAI_API_KEY` | Server-side `os.getenv` references found. Flutter contains security scanner detection string only. | NO for current client bundle. | Confirm production key storage in backend secret manager. |
| `STRIPE_SECRET_KEY` | Server-side billing and diagnostic scripts reference env var name. Flutter contains security scanner detection string only. | NO for current client bundle. | Validate Stripe test/live keys are never committed. |
| `SUPABASE_SERVICE_ROLE_KEY` | Server-side `os.getenv` reference found. | NO for current client bundle. | Keep service role key backend-only. |
| `backend/.venv` | W5.1 removed 8,445 dependency files from the current index. A pre-removal scan found no high-confidence secret pattern. Historical commits were not rewritten. | NO based on current evidence | Keep ignored and recreate locally from `backend/requirements.txt`; retain normal historical secret scanning. |

## History Review

`git log --all --name-only` did not show tracked `.env` paths in this pass. Git history was not rewritten.

## Required Before Public Release

- Run a secret scanner that ignores dependency false positives but inspects all historical commits.
- Confirm `git ls-files backend/.venv` remains empty in release checks.
- Rotate any Stripe, Supabase, OpenAI or admin credential if a real value is found in history.
- Do not pass `ADMIN_API_KEY` to Flutter `dart-define`, web bundles or APKs.
