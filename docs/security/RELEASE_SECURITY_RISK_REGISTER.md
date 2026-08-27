# Release Security Risk Register

| ID | Severity | Description | Affected area | Mitigation / next action | Release blocker? | Status |
|---|---|---|---|---|---|---|
| SEC-7D-001 | P2 | Deployed Supabase RLS/storage policy state is not evidenced by repository SQL. Service-role calls bypass RLS. | Supabase | Deployment owner must verify private bucket, RLS, policies, and least privilege before external production. | Conditional yes | Open deployment gate |
| SEC-7D-002 | P2 | Document deletion does not prove complete purge of backend PDF, Chroma vectors, Supabase object, all results, and MP3s. | Privacy/deletion | Design an idempotent owner-scoped erasure workflow and retention policy; test each store. | No for code RC; yes for a promised erasure SLA | Open |
| SEC-7D-003 | P2 | Three unowned legacy certificate records were tracked in recent Git history and are not clearly marked synthetic. | Repository/privacy | Removed from tracked HEAD and runtime file ignored. Confirm synthetic status; if real, authorize restricted history cleanup and privacy response. | Conditional yes | Mitigated in HEAD; verification open |
| SEC-7D-004 | P2 | Rate limiting is per-IP, in-memory, and per process. | Costly AI/API endpoints | Move to distributed/user-aware limits at production scale; retain subscription usage gates. | No for controlled RC | Accepted for RC |
| SEC-7D-005 | P2 | CSP/HSTS and final web headers are not represented in Flutter build output. | Web hosting | Configure and verify on production CDN/reverse proxy without blocking Flutter assets. | Yes at deployment | Open deployment gate |
| SEC-7D-006 | P2 | CIAG QA legacy deduplication/migration remains incomplete. No cross-user bypass was observed. | QA legacy data | Perform separately with backup and owner verification; no destructive change in 7D. | No | Inherited open |
| SEC-7D-007 | P3 | User-scoped SharedPreferences/browser cache is not app-encrypted and may remain after logout. | Compromised/shared device | Rely on OS/browser sandbox for v1; document device-data clearing and evaluate secure storage for selected fields. | No | Accepted |
| SEC-7D-008 | P3 | `backend/.venv` remains tracked despite ignore rules. | Repository hygiene | Remove in a dedicated reviewed commit; recreate from requirements. | No | Open |
| SEC-7D-009 | P3 | `flutter_markdown` is deprecated; no executable-link or raw HTML exploit was demonstrated and chat links have no launcher callback. | Web/content rendering | Pin/audit replacement during dependency maintenance; retain safe URL policy for launch surfaces. | No | Open |

P0 open: 0. P1 open: 0 after 7D remediation. Conditional deployment gates
must be completed before public production even though they do not require a
new product feature.
