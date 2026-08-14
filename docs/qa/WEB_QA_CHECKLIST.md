# Web QA Checklist

Status: READY FOR MANUAL QA.

- Login/logout.
- `/dashboard` requires auth.
- `/auth` redirects when already authenticated.
- Upload PDF opens picker before progress dialog.
- Cancel upload is silent.
- Library shows own documents.
- `/admin` redirects for non-admin.
- `/teacher` redirects for non-teacher.
- AI tools remain visible and named consistently.
- No duplicate `Audio Libro` / `Audiolibro` labels in active UI.
- `/learning` renders inside the shared app shell.
- `/teacher` renders inside the shared app shell for teacher-capable users.
- `/account` and `/plans` render inside the shared app shell.
- Production web build succeeds.
