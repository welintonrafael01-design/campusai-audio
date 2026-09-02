-- Synthetic legacy ownership test. Local/disposable database only.

begin;

alter table public.documents alter column user_id drop not null;

insert into auth.users (
  id, aud, role, email, encrypted_password,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  (
    '00000000-0000-4000-8000-00000000000a',
    'authenticated', 'authenticated', 'backfill-a@local.invalid', '',
    '{"role":"student"}'::jsonb, '{}'::jsonb, now(), now()
  ),
  (
    '00000000-0000-4000-8000-00000000000b',
    'authenticated', 'authenticated', 'backfill-b@local.invalid', '',
    '{"role":"student"}'::jsonb, '{}'::jsonb, now(), now()
  );

insert into public.workspaces (id, user_id, name) values
  (
    '10000000-0000-4000-8000-00000000000a',
    '00000000-0000-4000-8000-00000000000a',
    'Legacy A'
  );

insert into public.documents (
  id, user_id, workspace_id, document_id, document_name
) values (
  '20000000-0000-4000-8000-00000000000a',
  null,
  '10000000-0000-4000-8000-00000000000a',
  'legacy-workspace-a',
  'Workspace legacy'
);

insert into public.documents (
  id, user_id, document_id, document_name, storage_bucket, storage_path
) values (
  '20000000-0000-4000-8000-00000000000b',
  null,
  'legacy-storage-b',
  'Storage legacy',
  'studybook-documents',
  '00000000-0000-4000-8000-00000000000b/documents/legacy-storage-b/file.pdf'
);

\ir ../backfills/document_ownership_backfill.sql
\ir ../backfills/document_ownership_backfill.sql

do $$
begin
  if (
    select user_id from public.documents
    where document_id = 'legacy-workspace-a'
  ) <> '00000000-0000-4000-8000-00000000000a'::uuid then
    raise exception 'Workspace ownership backfill failed.';
  end if;

  if (
    select user_id from public.documents
    where document_id = 'legacy-storage-b'
  ) <> '00000000-0000-4000-8000-00000000000b'::uuid then
    raise exception 'Storage ownership backfill failed.';
  end if;

  if (
    select count(*) from public.documents
    where document_id in ('legacy-workspace-a', 'legacy-storage-b')
  ) <> 2 then
    raise exception 'Backfill duplicated or removed legacy rows.';
  end if;
end
$$;

rollback;
