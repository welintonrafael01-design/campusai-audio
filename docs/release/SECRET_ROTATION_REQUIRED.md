# Secret Rotation Required

The audit detected local `.env` and backup env files in the repository working tree.

No secrets were printed or copied into this document.

Required before release:

- Verify whether any `.env` or backup secret file was committed historically.
- Rotate exposed Stripe, Supabase service-role, OpenAI or admin credentials if they were ever committed.
- Keep admin credentials out of Flutter `dart-define`, web bundles and APKs.
