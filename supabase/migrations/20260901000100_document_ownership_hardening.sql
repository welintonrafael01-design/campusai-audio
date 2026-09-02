-- Fail-closed ownership hardening for legacy document rows.

begin;

update public.documents document
set user_id = workspace.user_id
from public.workspaces workspace
where document.user_id is null
  and document.workspace_id = workspace.id;

update public.documents document
set user_id = auth_user.id
from auth.users auth_user
where document.user_id is null
  and document.workspace_id is null
  and auth_user.id::text = substring(
    document.storage_path
    from '^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12})/documents/'
  );

do $$
begin
  if exists (
    select 1
    from public.documents document
    join public.workspaces workspace on workspace.id = document.workspace_id
    where document.user_id is distinct from workspace.user_id
  ) then
    raise exception 'Document/workspace ownership conflict requires quarantine.';
  end if;

  if exists (
    select 1
    from public.documents document
    where document.user_id is not null
      and document.storage_path is not null
      and document.storage_path not like document.user_id::text || '/documents/%'
  ) then
    raise exception 'Document/storage ownership conflict requires quarantine.';
  end if;

  if exists (
    select 1 from public.documents where user_id is null
  ) then
    raise exception 'Unowned documents require quarantine before hardening.';
  end if;
end
$$;

alter table public.documents alter column user_id set not null;

commit;
