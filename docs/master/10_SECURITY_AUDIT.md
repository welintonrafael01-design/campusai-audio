# 10 — Security Audit

## Critical

| Finding | File | Impact | Recommendation |
|---|---|---|---|
| Frontend reads `ADMIN_API_KEY` | `mobile/campusai_mobile/lib/services/analytics_service.dart` | Admin secret can be exposed in web bundle | Remove from Flutter; admin analytics only through user claim/backend |
| No global route guard | `mobile/campusai_mobile/lib/router/app_router.dart` | Private/admin/teacher routes can be directly opened | Add auth/role/plan redirect |
| Local plan can unlock UI | `PlanGuardService` | User can spoof local storage | Backend entitlements as authority |

## High

| Finding | File | Impact | Recommendation |
|---|---|---|---|
| Hardcoded localhost API | `ApiService.baseUrl` | Android/prod broken; accidental env mismatch | Use `String.fromEnvironment('API_BASE_URL')` |
| Env/backups present | `backend/.env*`, `backups/**` | Secret leakage risk | Remove from repo, rotate if committed |
| Document file endpoints need ownership review | `documents.py` file routes | Potential document exposure | Require token and user ownership |
| Android cleartext enabled | `AndroidManifest.xml` | Production traffic risk | Dev-only network config |

## Medium

- Supabase config debug logs in `main.dart`.
- Mixed local/cloud source of truth creates stale/ghost data risk.
- CORS default is narrow and dev-specific.
- Backend static audio directory may expose generated audio by filename.

## Low

- `allowBackup=true` on Android can back up local educational data.
- Lack of automated security tests.

