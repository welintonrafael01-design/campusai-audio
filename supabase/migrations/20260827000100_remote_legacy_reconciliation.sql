-- Reconcile the observed legacy remote schema before the StudyBook baseline.
-- This bridge is intentionally defensive and preserves unresolved rows in a
-- private quarantine instead of assigning them to an arbitrary user.

begin;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table if not exists private.studybook_legacy_quarantine (
  source_table text not null,
  source_id text not null,
  reason text not null,
  row_data jsonb not null,
  quarantined_at timestamptz not null default now(),
  primary key (source_table, source_id)
);

revoke all on private.studybook_legacy_quarantine
from public, anon, authenticated;
grant all on private.studybook_legacy_quarantine to service_role;

do $$
begin
  if to_regclass('public.documents') is not null then
    alter table public.documents add column if not exists user_id uuid;

    update public.documents document
    set user_id = workspace.user_id
    from public.workspaces workspace
    where document.user_id is null
      and document.workspace_id = workspace.id
      and workspace.user_id is not null;

    update public.documents document
    set user_id = substring(
      document.storage_path
      from '^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12})/documents/'
    )::uuid
    where document.user_id is null
      and document.workspace_id is null
      and document.storage_path ~
        '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}/documents/';

    insert into private.studybook_legacy_quarantine (
      source_table,
      source_id,
      reason,
      row_data
    )
    select
      'documents',
      document.id::text,
      'owner_not_deterministic',
      to_jsonb(document)
    from public.documents document
    where document.user_id is null
    on conflict (source_table, source_id) do update
    set reason = excluded.reason,
        row_data = excluded.row_data,
        quarantined_at = now();

    delete from public.documents where user_id is null;

    with ranked_documents as (
      select
        document.id,
        row_number() over (
          partition by document.user_id, document.document_id
          order by
            document.updated_at desc nulls last,
            document.uploaded_at desc nulls last,
            document.created_at desc nulls last,
            document.id
        ) as duplicate_rank
      from public.documents document
    )
    insert into private.studybook_legacy_quarantine (
      source_table,
      source_id,
      reason,
      row_data
    )
    select
      'documents',
      document.id::text,
      'duplicate_owner_document_key',
      to_jsonb(document)
    from public.documents document
    join ranked_documents ranked on ranked.id = document.id
    where ranked.duplicate_rank > 1
    on conflict (source_table, source_id) do update
    set reason = excluded.reason,
        row_data = excluded.row_data,
        quarantined_at = now();

    with ranked_documents as (
      select
        document.id,
        row_number() over (
          partition by document.user_id, document.document_id
          order by
            document.updated_at desc nulls last,
            document.uploaded_at desc nulls last,
            document.created_at desc nulls last,
            document.id
        ) as duplicate_rank
      from public.documents document
    )
    delete from public.documents document
    using ranked_documents ranked
    where ranked.id = document.id
      and ranked.duplicate_rank > 1;

    if exists (
      select 1
      from public.documents document
      join public.workspaces workspace on workspace.id = document.workspace_id
      where document.user_id is distinct from workspace.user_id
    ) then
      raise exception 'Legacy document/workspace ownership conflict.';
    end if;

    if exists (
      select 1
      from public.documents document
      where document.storage_path is not null
        and document.storage_path not like
          document.user_id::text || '/documents/%'
    ) then
      raise exception 'Legacy document/storage ownership conflict.';
    end if;

    if exists (
      select 1
      from public.documents
      group by user_id, document_id
      having count(*) > 1
    ) then
      raise exception 'Legacy documents contain duplicate owner/document keys.';
    end if;

    alter table public.documents alter column user_id set not null;

    if not exists (
      select 1
      from pg_constraint
      where conrelid = 'public.documents'::regclass
        and conname = 'documents_user_id_document_id_key'
    ) then
      alter table public.documents
        add constraint documents_user_id_document_id_key
        unique (user_id, document_id);
    end if;
  end if;

  if to_regclass('public.workspaces') is not null then
    alter table public.workspaces
      add column if not exists updated_at timestamptz default now();
    update public.workspaces set updated_at = created_at
    where updated_at is null;
    alter table public.workspaces alter column updated_at set default now();
    alter table public.workspaces alter column updated_at set not null;
  end if;
end
$$;

do $$
begin
  if to_regclass('public.messages') is not null
    and to_regclass('public.chats') is not null then
    insert into private.studybook_legacy_quarantine (
      source_table,
      source_id,
      reason,
      row_data
    )
    select
      'messages',
      message.id::text,
      'parent_chat_owner_not_in_auth',
      to_jsonb(message)
    from public.messages message
    join public.chats chat on chat.id = message.chat_id
    left join auth.users auth_user on auth_user.id = chat.user_id
    left join public.workspaces workspace on workspace.id = chat.workspace_id
    left join auth.users workspace_user on workspace_user.id = workspace.user_id
    where auth_user.id is null
      or (
        chat.workspace_id is not null
        and (
          workspace.id is null
          or workspace_user.id is null
          or workspace.user_id is distinct from chat.user_id
        )
      )
    on conflict (source_table, source_id) do update
    set reason = excluded.reason,
        row_data = excluded.row_data,
        quarantined_at = now();

    delete from public.messages message
    using public.chats chat
    where chat.id = message.chat_id
      and (
        not exists (
          select 1 from auth.users auth_user
          where auth_user.id = chat.user_id
        )
        or (
          chat.workspace_id is not null
          and not exists (
            select 1
            from public.workspaces workspace
            join auth.users workspace_user on workspace_user.id = workspace.user_id
            where workspace.id = chat.workspace_id
              and workspace.user_id = chat.user_id
          )
        )
      );
  end if;

  if to_regclass('public.chats') is not null then
    insert into private.studybook_legacy_quarantine (
      source_table,
      source_id,
      reason,
      row_data
    )
    select
      'chats',
      chat.id::text,
      'owner_not_in_auth',
      to_jsonb(chat)
    from public.chats chat
    left join auth.users auth_user on auth_user.id = chat.user_id
    left join public.workspaces workspace on workspace.id = chat.workspace_id
    left join auth.users workspace_user on workspace_user.id = workspace.user_id
    where auth_user.id is null
      or (
        chat.workspace_id is not null
        and (
          workspace.id is null
          or workspace_user.id is null
          or workspace.user_id is distinct from chat.user_id
        )
      )
    on conflict (source_table, source_id) do update
    set reason = excluded.reason,
        row_data = excluded.row_data,
        quarantined_at = now();

    delete from public.chats chat
    where not exists (
        select 1 from auth.users auth_user
        where auth_user.id = chat.user_id
      )
      or (
        chat.workspace_id is not null
        and not exists (
          select 1
          from public.workspaces workspace
          join auth.users workspace_user on workspace_user.id = workspace.user_id
          where workspace.id = chat.workspace_id
            and workspace.user_id = chat.user_id
        )
      );

    alter table public.chats alter column user_id set not null;
  end if;

  if to_regclass('public.documents') is not null then
    insert into private.studybook_legacy_quarantine (
      source_table,
      source_id,
      reason,
      row_data
    )
    select
      'documents',
      document.id::text,
      'owner_not_in_auth',
      to_jsonb(document)
    from public.documents document
    left join auth.users auth_user on auth_user.id = document.user_id
    left join public.workspaces workspace on workspace.id = document.workspace_id
    left join auth.users workspace_user on workspace_user.id = workspace.user_id
    where auth_user.id is null
      or (
        document.workspace_id is not null
        and (
          workspace.id is null
          or workspace_user.id is null
          or workspace.user_id is distinct from document.user_id
        )
      )
    on conflict (source_table, source_id) do update
    set reason = excluded.reason,
        row_data = excluded.row_data,
        quarantined_at = now();

    delete from public.documents document
    where not exists (
        select 1 from auth.users auth_user
        where auth_user.id = document.user_id
      )
      or (
        document.workspace_id is not null
        and not exists (
          select 1
          from public.workspaces workspace
          join auth.users workspace_user on workspace_user.id = workspace.user_id
          where workspace.id = document.workspace_id
            and workspace.user_id = document.user_id
        )
      );
  end if;

  if to_regclass('public.workspaces') is not null then
    insert into private.studybook_legacy_quarantine (
      source_table,
      source_id,
      reason,
      row_data
    )
    select
      'workspaces',
      workspace.id::text,
      'owner_not_in_auth',
      to_jsonb(workspace)
    from public.workspaces workspace
    left join auth.users auth_user on auth_user.id = workspace.user_id
    where auth_user.id is null
    on conflict (source_table, source_id) do update
    set reason = excluded.reason,
        row_data = excluded.row_data,
        quarantined_at = now();

    delete from public.workspaces workspace
    where not exists (
      select 1 from auth.users auth_user
      where auth_user.id = workspace.user_id
    );

    alter table public.workspaces alter column user_id set not null;
  end if;
end
$$;

create or replace procedure private.studybook_quarantine_invalid_owner(
  relation_name text
)
language plpgsql
set search_path = ''
as $$
begin
  if to_regclass(format('public.%I', relation_name)) is null then
    return;
  end if;

  execute format(
    'insert into private.studybook_legacy_quarantine '
    '(source_table, source_id, reason, row_data) '
    'select %L, source_row.id::text, %L, to_jsonb(source_row) '
    'from public.%I source_row '
    'left join auth.users auth_user on auth_user.id = source_row.user_id '
    'where auth_user.id is null '
    'on conflict (source_table, source_id) do update '
    'set reason = excluded.reason, row_data = excluded.row_data, '
    'quarantined_at = now()',
    relation_name,
    'owner_not_in_auth',
    relation_name
  );

  execute format(
    'delete from public.%I source_row where not exists '
    '(select 1 from auth.users auth_user '
    'where auth_user.id = source_row.user_id)',
    relation_name
  );
end
$$;

revoke all on procedure private.studybook_quarantine_invalid_owner(text)
from public, anon, authenticated;

do $$
declare
  relation_name text;
begin
  foreach relation_name in array array[
    'audiobooks',
    'educator_attendance',
    'educator_courses',
    'educator_gradebook',
    'educator_question_banks',
    'educator_rubrics',
    'educator_students',
    'study_results',
    'user_subscriptions',
    'user_usage_events'
  ] loop
    call private.studybook_quarantine_invalid_owner(relation_name);
  end loop;
end
$$;

drop procedure private.studybook_quarantine_invalid_owner(text);

do $$
declare
  primary_key_name text;
  primary_key_columns text[];
begin
  if to_regclass('public.user_subscriptions') is not null then
    if exists (
      select 1
      from public.user_subscriptions
      group by user_id
      having count(*) > 1
    ) then
      raise exception 'Legacy subscriptions contain duplicate user_id values.';
    end if;

    select
      constraint_row.conname,
      array_agg(attribute_row.attname::text order by key_row.ordinality)
    into primary_key_name, primary_key_columns
    from pg_constraint constraint_row
    join lateral unnest(constraint_row.conkey) with ordinality
      key_row(attnum, ordinality) on true
    join pg_attribute attribute_row
      on attribute_row.attrelid = constraint_row.conrelid
      and attribute_row.attnum = key_row.attnum
    where constraint_row.conrelid = 'public.user_subscriptions'::regclass
      and constraint_row.contype = 'p'
    group by constraint_row.conname;

    if primary_key_columns = array['id']::text[] then
      execute format(
        'alter table public.user_subscriptions drop constraint %I',
        primary_key_name
      );

      if not exists (
        select 1 from pg_constraint
        where conrelid = 'public.user_subscriptions'::regclass
          and conname = 'user_subscriptions_legacy_id_key'
      ) then
        alter table public.user_subscriptions
          add constraint user_subscriptions_legacy_id_key unique (id);
      end if;

      alter table public.user_subscriptions
        add constraint user_subscriptions_pkey primary key (user_id);
    elsif primary_key_columns is distinct from array['user_id']::text[] then
      raise exception 'Unexpected legacy user_subscriptions primary key.';
    end if;
  end if;
end
$$;

do $$
declare
  id_type text;
  primary_key_name text;
begin
  if to_regclass('public.user_usage_events') is not null then
    select data_type into id_type
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'user_usage_events'
      and column_name = 'id';

    if id_type = 'uuid' then
      if exists (
        select 1
        from pg_constraint
        where confrelid = 'public.user_usage_events'::regclass
      ) then
        raise exception 'Legacy usage event IDs have unexpected dependants.';
      end if;

      select conname into primary_key_name
      from pg_constraint
      where conrelid = 'public.user_usage_events'::regclass
        and contype = 'p';

      if primary_key_name is not null then
        execute format(
          'alter table public.user_usage_events drop constraint %I',
          primary_key_name
        );
      end if;

      alter table public.user_usage_events rename column id to legacy_id;
      alter table public.user_usage_events
        add column id bigint generated by default as identity;
      alter table public.user_usage_events
        add constraint user_usage_events_pkey primary key (id);
      alter table public.user_usage_events
        add constraint user_usage_events_legacy_id_key unique (legacy_id);

      revoke all on sequence public.user_usage_events_id_seq
      from public, anon, authenticated;
      grant usage, select on sequence public.user_usage_events_id_seq
      to service_role;
    elsif id_type <> 'bigint' then
      raise exception 'Unexpected legacy user_usage_events id type: %', id_type;
    end if;
  end if;
end
$$;

create or replace procedure private.studybook_add_legacy_owner_fk(
  relation_name text
)
language plpgsql
set search_path = ''
as $$
begin
  if to_regclass(format('public.%I', relation_name)) is null then
    return;
  end if;

  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = relation_name
      and column_name = 'user_id'
  ) then
    raise exception 'Legacy owner column missing on public.%', relation_name;
  end if;

  if not exists (
    select 1
    from pg_constraint constraint_row
    where constraint_row.conrelid =
        to_regclass(format('public.%I', relation_name))
      and constraint_row.contype = 'f'
      and constraint_row.confrelid = 'auth.users'::regclass
  ) then
    execute format(
      'alter table public.%I add constraint %I '
      'foreign key (user_id) references auth.users(id) '
      'on delete cascade',
      relation_name,
      relation_name || '_user_id_fkey'
    );
  end if;
end
$$;

do $$
declare
  relation_name text;
begin
  foreach relation_name in array array[
    'audiobooks',
    'chats',
    'documents',
    'educator_attendance',
    'educator_courses',
    'educator_gradebook',
    'educator_question_banks',
    'educator_rubrics',
    'educator_students',
    'study_results',
    'user_subscriptions',
    'user_usage_events',
    'workspaces'
  ] loop
    call private.studybook_add_legacy_owner_fk(relation_name);
  end loop;
end
$$;

drop procedure private.studybook_add_legacy_owner_fk(text);

do $$
begin
  if exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and not (
        tablename = 'user_subscriptions'
        and policyname = 'Users can read their own subscription'
        and cmd = 'SELECT'
        and roles = array['authenticated']::name[]
      )
  ) then
    raise exception 'Unexpected legacy public policy requires manual review.';
  end if;

  if exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
  ) then
    raise exception 'Unexpected legacy Storage policy requires manual review.';
  end if;

  if to_regclass('public.user_subscriptions') is not null then
    drop policy if exists "Users can read their own subscription"
      on public.user_subscriptions;
  end if;
end
$$;

commit;
