-- StudyBook AI Supabase security contract.
-- Repository artifact only: review against the deployed schema before apply.

begin;

create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

do $$
declare
  relation_name text;
begin
  foreach relation_name in array array[
    'workspaces',
    'documents',
    'study_results',
    'audiobooks',
    'chats',
    'messages',
    'user_subscriptions',
    'user_usage_events',
    'educator_courses',
    'educator_students',
    'educator_attendance',
    'educator_gradebook',
    'educator_question_banks',
    'educator_rubrics'
  ] loop
    if to_regclass(format('public.%I', relation_name)) is null then
      raise exception 'Required StudyBook relation is missing: public.%', relation_name;
    end if;
  end loop;

end
$$;

alter table public.documents
  add column if not exists user_id uuid references auth.users(id) on delete cascade;

do $$
begin
  if exists (
    select 1
    from (values
      ('workspaces', 'id'), ('workspaces', 'user_id'),
      ('documents', 'document_id'), ('documents', 'user_id'),
      ('documents', 'workspace_id'),
      ('documents', 'storage_bucket'), ('documents', 'storage_path'),
      ('study_results', 'user_id'), ('study_results', 'document_id'),
      ('audiobooks', 'user_id'), ('audiobooks', 'document_id'),
      ('chats', 'id'), ('chats', 'user_id'),
      ('messages', 'chat_id'),
      ('user_subscriptions', 'user_id'), ('user_subscriptions', 'plan'),
      ('user_subscriptions', 'subscription_status'),
      ('user_usage_events', 'user_id'),
      ('educator_courses', 'user_id'),
      ('educator_students', 'user_id'),
      ('educator_attendance', 'user_id'),
      ('educator_gradebook', 'user_id'),
      ('educator_question_banks', 'user_id'),
      ('educator_rubrics', 'user_id')
    ) as required_column(table_name, column_name)
    where not exists (
      select 1
      from information_schema.columns c
      where c.table_schema = 'public'
        and c.table_name = required_column.table_name
        and c.column_name = required_column.column_name
    )
  ) then
    raise exception 'The deployed StudyBook schema is missing required ownership columns.';
  end if;
end
$$;

create or replace function private.current_rls_role()
returns text
language sql
stable
set search_path = ''
as $$
  select case
    when lower(coalesce(auth.jwt() -> 'app_metadata' ->> 'role', ''))
      in ('teacher', 'educator') then 'teacher'
    else 'student'
  end
$$;

create or replace function private.is_current_user(owner_id text)
returns boolean
language sql
stable
set search_path = ''
as $$
  select auth.uid() is not null
    and nullif(owner_id, '') = auth.uid()::text
$$;

create or replace function private.has_teacher_access()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select private.current_rls_role() = 'teacher'
    and exists (
      select 1
      from public.user_subscriptions subscription
      where subscription.user_id::text = auth.uid()::text
        and lower(subscription.plan::text)
          in ('teacher', 'educator', 'institution')
        and lower(coalesce(subscription.subscription_status::text, ''))
          in ('active', 'trialing')
    )
$$;

create or replace function private.owns_workspace(workspace_id text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null
    and exists (
      select 1
      from public.workspaces workspace
      where workspace.id::text = workspace_id
        and workspace.user_id::text = auth.uid()::text
    )
$$;

create or replace function private.owns_document(
  document_user_id text,
  workspace_id text,
  storage_bucket text,
  storage_path text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null
    and (
      coalesce(document_user_id, '') = ''
      or private.is_current_user(document_user_id)
    )
    and (
      coalesce(workspace_id, '') = ''
      or private.owns_workspace(workspace_id)
    )
    and (
      coalesce(storage_path, '') = ''
      or (
        coalesce(nullif(storage_bucket, ''), 'studybook-documents')
          = 'studybook-documents'
        and coalesce(storage_path, '') like auth.uid()::text || '/documents/%'
        and coalesce(storage_path, '') !~ '(^|/)\.{1,2}(/|$)'
        and position(chr(92) in coalesce(storage_path, '')) = 0
      )
    )
    and (
      coalesce(document_user_id, '') <> ''
      or coalesce(workspace_id, '') <> ''
      or coalesce(storage_path, '') <> ''
    )
$$;

create or replace function private.owns_chat(chat_id text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null
    and exists (
      select 1
      from public.chats chat
      where chat.id::text = chat_id
        and chat.user_id::text = auth.uid()::text
    )
$$;

create or replace function private.owns_document_object(
  bucket_id text,
  object_name text
)
returns boolean
language sql
stable
set search_path = ''
as $$
  select auth.uid() is not null
    and bucket_id = 'studybook-documents'
    and split_part(coalesce(object_name, ''), '/', 1) = auth.uid()::text
    and split_part(coalesce(object_name, ''), '/', 2) = 'documents'
    and split_part(coalesce(object_name, ''), '/', 3) <> ''
    and split_part(coalesce(object_name, ''), '/', 4) <> ''
    and coalesce(object_name, '') !~ '(^|/)\.{1,2}(/|$)'
    and position(chr(92) in coalesce(object_name, '')) = 0
$$;

revoke all on function private.current_rls_role() from public, anon;
revoke all on function private.is_current_user(text) from public, anon;
revoke all on function private.has_teacher_access() from public, anon;
revoke all on function private.owns_workspace(text) from public, anon;
revoke all on function private.owns_document(text, text, text, text) from public, anon;
revoke all on function private.owns_chat(text) from public, anon;
revoke all on function private.owns_document_object(text, text) from public, anon;

grant execute on function private.current_rls_role() to authenticated;
grant execute on function private.is_current_user(text) to authenticated;
grant execute on function private.has_teacher_access() to authenticated;
grant execute on function private.owns_workspace(text) to authenticated;
grant execute on function private.owns_document(text, text, text, text) to authenticated;
grant execute on function private.owns_chat(text) to authenticated;
grant execute on function private.owns_document_object(text, text) to authenticated;

do $$
begin
  if exists (
    select 1
    from pg_policies policy
    where policy.schemaname = 'public'
      and policy.tablename = any(array[
        'workspaces', 'documents', 'study_results', 'audiobooks', 'chats',
        'messages', 'user_subscriptions', 'user_usage_events',
        'educator_courses', 'educator_students', 'educator_attendance',
        'educator_gradebook', 'educator_question_banks',
        'educator_rubrics'
      ])
      and not (
        (
          policy.tablename = any(array[
            'workspaces', 'documents', 'study_results', 'audiobooks', 'chats',
            'educator_courses', 'educator_students', 'educator_attendance',
            'educator_gradebook', 'educator_question_banks',
            'educator_rubrics'
          ])
          and policy.policyname = any(array[
            'studybook_' || policy.tablename || '_select',
            'studybook_' || policy.tablename || '_insert',
            'studybook_' || policy.tablename || '_update',
            'studybook_' || policy.tablename || '_delete'
          ])
        )
        or (
          policy.tablename = 'messages'
          and policy.policyname = any(array[
            'studybook_messages_select',
            'studybook_messages_insert',
            'studybook_messages_delete'
          ])
        )
        or (
          policy.tablename = any(array[
            'user_subscriptions', 'user_usage_events'
          ])
          and policy.policyname = 'studybook_' || policy.tablename || '_select'
        )
      )
  ) then
    raise exception 'Unknown public policy detected; review it before applying StudyBook RLS.';
  end if;

  if exists (
    select 1
    from pg_policies policy
    where policy.schemaname = 'storage'
      and policy.tablename = 'objects'
      and policy.policyname not in (
        'studybook_documents_select',
        'studybook_documents_insert',
        'studybook_documents_update',
        'studybook_documents_delete'
      )
  ) then
    raise exception 'Unknown Storage policy detected; review it before applying StudyBook RLS.';
  end if;
end
$$;

create or replace procedure private.ensure_policy(
  policy_schema text,
  policy_table text,
  policy_name text,
  policy_command text,
  using_expression text default null,
  check_expression text default null
)
language plpgsql
set search_path = ''
as $$
declare
  statement text;
begin
  if upper(policy_command) not in ('SELECT', 'INSERT', 'UPDATE', 'DELETE') then
    raise exception 'Unsupported policy command: %', policy_command;
  end if;

  if to_regclass(format('%I.%I', policy_schema, policy_table)) is null then
    raise exception 'Policy relation does not exist: %.%', policy_schema, policy_table;
  end if;

  if exists (
    select 1
    from pg_policies policy
    where policy.schemaname = policy_schema
      and policy.tablename = policy_table
      and policy.policyname = policy_name
  ) then
    return;
  end if;

  statement := format(
    'create policy %I on %I.%I as permissive for %s to authenticated',
    policy_name,
    policy_schema,
    policy_table,
    upper(policy_command)
  );

  if using_expression is not null then
    statement := statement || format(' using (%s)', using_expression);
  end if;

  if check_expression is not null then
    statement := statement || format(' with check (%s)', check_expression);
  end if;

  execute statement;
end
$$;

revoke all on procedure private.ensure_policy(
  text, text, text, text, text, text
) from public, anon, authenticated;

alter table public.workspaces enable row level security;
alter table public.documents enable row level security;
alter table public.study_results enable row level security;
alter table public.audiobooks enable row level security;
alter table public.chats enable row level security;
alter table public.messages enable row level security;
alter table public.user_subscriptions enable row level security;
alter table public.user_usage_events enable row level security;
alter table public.educator_courses enable row level security;
alter table public.educator_students enable row level security;
alter table public.educator_attendance enable row level security;
alter table public.educator_gradebook enable row level security;
alter table public.educator_question_banks enable row level security;
alter table public.educator_rubrics enable row level security;

revoke all privileges on table
  public.workspaces,
  public.documents,
  public.study_results,
  public.audiobooks,
  public.chats,
  public.messages,
  public.user_subscriptions,
  public.user_usage_events,
  public.educator_courses,
  public.educator_students,
  public.educator_attendance,
  public.educator_gradebook,
  public.educator_question_banks,
  public.educator_rubrics
from anon, authenticated;

grant select, insert, update, delete on table
  public.workspaces,
  public.documents,
  public.study_results,
  public.audiobooks,
  public.chats,
  public.educator_courses,
  public.educator_students,
  public.educator_attendance,
  public.educator_gradebook,
  public.educator_question_banks,
  public.educator_rubrics
to authenticated;

grant select, insert, delete on table public.messages to authenticated;
grant select on table
  public.user_subscriptions,
  public.user_usage_events
to authenticated;

call private.ensure_policy(
  'public', 'workspaces', 'studybook_workspaces_select', 'select',
  'private.is_current_user(user_id::text)', null
);
call private.ensure_policy(
  'public', 'workspaces', 'studybook_workspaces_insert', 'insert',
  null, 'private.is_current_user(user_id::text)'
);
call private.ensure_policy(
  'public', 'workspaces', 'studybook_workspaces_update', 'update',
  'private.is_current_user(user_id::text)',
  'private.is_current_user(user_id::text)'
);
call private.ensure_policy(
  'public', 'workspaces', 'studybook_workspaces_delete', 'delete',
  'private.is_current_user(user_id::text)', null
);

call private.ensure_policy(
  'public', 'documents', 'studybook_documents_select', 'select',
  'private.owns_document(user_id::text, workspace_id::text, storage_bucket::text, storage_path::text)',
  null
);
call private.ensure_policy(
  'public', 'documents', 'studybook_documents_insert', 'insert',
  null,
  'private.is_current_user(user_id::text) and private.owns_document(user_id::text, workspace_id::text, storage_bucket::text, storage_path::text)'
);
call private.ensure_policy(
  'public', 'documents', 'studybook_documents_update', 'update',
  'private.owns_document(user_id::text, workspace_id::text, storage_bucket::text, storage_path::text)',
  'private.is_current_user(user_id::text) and private.owns_document(user_id::text, workspace_id::text, storage_bucket::text, storage_path::text)'
);
call private.ensure_policy(
  'public', 'documents', 'studybook_documents_delete', 'delete',
  'private.owns_document(user_id::text, workspace_id::text, storage_bucket::text, storage_path::text)',
  null
);

call private.ensure_policy(
  'public', 'study_results', 'studybook_study_results_select', 'select',
  'private.is_current_user(user_id::text)', null
);
call private.ensure_policy(
  'public', 'study_results', 'studybook_study_results_insert', 'insert',
  null, 'private.is_current_user(user_id::text)'
);
call private.ensure_policy(
  'public', 'study_results', 'studybook_study_results_update', 'update',
  'private.is_current_user(user_id::text)',
  'private.is_current_user(user_id::text)'
);
call private.ensure_policy(
  'public', 'study_results', 'studybook_study_results_delete', 'delete',
  'private.is_current_user(user_id::text)', null
);

call private.ensure_policy(
  'public', 'audiobooks', 'studybook_audiobooks_select', 'select',
  'private.is_current_user(user_id::text)', null
);
call private.ensure_policy(
  'public', 'audiobooks', 'studybook_audiobooks_insert', 'insert',
  null, 'private.is_current_user(user_id::text)'
);
call private.ensure_policy(
  'public', 'audiobooks', 'studybook_audiobooks_update', 'update',
  'private.is_current_user(user_id::text)',
  'private.is_current_user(user_id::text)'
);
call private.ensure_policy(
  'public', 'audiobooks', 'studybook_audiobooks_delete', 'delete',
  'private.is_current_user(user_id::text)', null
);

call private.ensure_policy(
  'public', 'chats', 'studybook_chats_select', 'select',
  'private.is_current_user(user_id::text)', null
);
call private.ensure_policy(
  'public', 'chats', 'studybook_chats_insert', 'insert',
  null, 'private.is_current_user(user_id::text)'
);
call private.ensure_policy(
  'public', 'chats', 'studybook_chats_update', 'update',
  'private.is_current_user(user_id::text)',
  'private.is_current_user(user_id::text)'
);
call private.ensure_policy(
  'public', 'chats', 'studybook_chats_delete', 'delete',
  'private.is_current_user(user_id::text)', null
);

call private.ensure_policy(
  'public', 'messages', 'studybook_messages_select', 'select',
  'private.owns_chat(chat_id::text)', null
);
call private.ensure_policy(
  'public', 'messages', 'studybook_messages_insert', 'insert',
  null,
  'private.owns_chat(chat_id::text) and lower(role::text) = ''user'''
);
call private.ensure_policy(
  'public', 'messages', 'studybook_messages_delete', 'delete',
  'private.owns_chat(chat_id::text)', null
);

call private.ensure_policy(
  'public', 'user_subscriptions', 'studybook_user_subscriptions_select',
  'select', 'private.is_current_user(user_id::text)', null
);
call private.ensure_policy(
  'public', 'user_usage_events', 'studybook_user_usage_events_select',
  'select', 'private.is_current_user(user_id::text)', null
);

call private.ensure_policy(
  'public', 'educator_courses', 'studybook_educator_courses_select', 'select',
  'private.is_current_user(user_id::text) and private.has_teacher_access()', null
);
call private.ensure_policy(
  'public', 'educator_courses', 'studybook_educator_courses_insert', 'insert',
  null, 'private.is_current_user(user_id::text) and private.has_teacher_access()'
);
call private.ensure_policy(
  'public', 'educator_courses', 'studybook_educator_courses_update', 'update',
  'private.is_current_user(user_id::text) and private.has_teacher_access()',
  'private.is_current_user(user_id::text) and private.has_teacher_access()'
);
call private.ensure_policy(
  'public', 'educator_courses', 'studybook_educator_courses_delete', 'delete',
  'private.is_current_user(user_id::text) and private.has_teacher_access()', null
);

call private.ensure_policy(
  'public', 'educator_students', 'studybook_educator_students_select', 'select',
  'private.is_current_user(user_id::text) and private.has_teacher_access()', null
);
call private.ensure_policy(
  'public', 'educator_students', 'studybook_educator_students_insert', 'insert',
  null, 'private.is_current_user(user_id::text) and private.has_teacher_access()'
);
call private.ensure_policy(
  'public', 'educator_students', 'studybook_educator_students_update', 'update',
  'private.is_current_user(user_id::text) and private.has_teacher_access()',
  'private.is_current_user(user_id::text) and private.has_teacher_access()'
);
call private.ensure_policy(
  'public', 'educator_students', 'studybook_educator_students_delete', 'delete',
  'private.is_current_user(user_id::text) and private.has_teacher_access()', null
);

call private.ensure_policy(
  'public', 'educator_attendance', 'studybook_educator_attendance_select', 'select',
  'private.is_current_user(user_id::text) and private.has_teacher_access()', null
);
call private.ensure_policy(
  'public', 'educator_attendance', 'studybook_educator_attendance_insert', 'insert',
  null, 'private.is_current_user(user_id::text) and private.has_teacher_access()'
);
call private.ensure_policy(
  'public', 'educator_attendance', 'studybook_educator_attendance_update', 'update',
  'private.is_current_user(user_id::text) and private.has_teacher_access()',
  'private.is_current_user(user_id::text) and private.has_teacher_access()'
);
call private.ensure_policy(
  'public', 'educator_attendance', 'studybook_educator_attendance_delete', 'delete',
  'private.is_current_user(user_id::text) and private.has_teacher_access()', null
);

call private.ensure_policy(
  'public', 'educator_gradebook', 'studybook_educator_gradebook_select', 'select',
  'private.is_current_user(user_id::text) and private.has_teacher_access()', null
);
call private.ensure_policy(
  'public', 'educator_gradebook', 'studybook_educator_gradebook_insert', 'insert',
  null, 'private.is_current_user(user_id::text) and private.has_teacher_access()'
);
call private.ensure_policy(
  'public', 'educator_gradebook', 'studybook_educator_gradebook_update', 'update',
  'private.is_current_user(user_id::text) and private.has_teacher_access()',
  'private.is_current_user(user_id::text) and private.has_teacher_access()'
);
call private.ensure_policy(
  'public', 'educator_gradebook', 'studybook_educator_gradebook_delete', 'delete',
  'private.is_current_user(user_id::text) and private.has_teacher_access()', null
);

call private.ensure_policy(
  'public', 'educator_question_banks',
  'studybook_educator_question_banks_select', 'select',
  'private.is_current_user(user_id::text) and private.has_teacher_access()', null
);

call private.ensure_policy(
  'public', 'educator_rubrics', 'studybook_educator_rubrics_select', 'select',
  'private.is_current_user(user_id::text) and private.has_teacher_access()', null
);
call private.ensure_policy(
  'public', 'educator_rubrics', 'studybook_educator_rubrics_insert', 'insert',
  null, 'private.is_current_user(user_id::text) and private.has_teacher_access()'
);
call private.ensure_policy(
  'public', 'educator_rubrics', 'studybook_educator_rubrics_update', 'update',
  'private.is_current_user(user_id::text) and private.has_teacher_access()',
  'private.is_current_user(user_id::text) and private.has_teacher_access()'
);
call private.ensure_policy(
  'public', 'educator_rubrics', 'studybook_educator_rubrics_delete', 'delete',
  'private.is_current_user(user_id::text) and private.has_teacher_access()', null
);
call private.ensure_policy(
  'public', 'educator_question_banks',
  'studybook_educator_question_banks_insert', 'insert',
  null, 'private.is_current_user(user_id::text) and private.has_teacher_access()'
);
call private.ensure_policy(
  'public', 'educator_question_banks',
  'studybook_educator_question_banks_update', 'update',
  'private.is_current_user(user_id::text) and private.has_teacher_access()',
  'private.is_current_user(user_id::text) and private.has_teacher_access()'
);
call private.ensure_policy(
  'public', 'educator_question_banks',
  'studybook_educator_question_banks_delete', 'delete',
  'private.is_current_user(user_id::text) and private.has_teacher_access()', null
);

insert into storage.buckets (id, name, public)
values ('studybook-documents', 'studybook-documents', false)
on conflict (id) do update set public = false;

do $$
begin
  if not exists (
    select 1
    from pg_class relation
    join pg_namespace namespace on namespace.oid = relation.relnamespace
    where namespace.nspname = 'storage'
      and relation.relname = 'objects'
      and relation.relrowsecurity
  ) then
    raise exception 'RLS must already be enabled on storage.objects.';
  end if;
end
$$;

call private.ensure_policy(
  'storage', 'objects', 'studybook_documents_select', 'select',
  'private.owns_document_object(bucket_id::text, name::text)', null
);
call private.ensure_policy(
  'storage', 'objects', 'studybook_documents_insert', 'insert',
  null, 'private.owns_document_object(bucket_id::text, name::text)'
);
call private.ensure_policy(
  'storage', 'objects', 'studybook_documents_update', 'update',
  'private.owns_document_object(bucket_id::text, name::text)',
  'private.owns_document_object(bucket_id::text, name::text)'
);
call private.ensure_policy(
  'storage', 'objects', 'studybook_documents_delete', 'delete',
  'private.owns_document_object(bucket_id::text, name::text)', null
);

drop procedure private.ensure_policy(text, text, text, text, text, text);

commit;
