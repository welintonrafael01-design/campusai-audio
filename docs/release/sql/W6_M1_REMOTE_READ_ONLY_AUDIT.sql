-- StudyBook AI W6-M1 failed-migration forensic audit.
-- READ-ONLY ONLY. This file contains no DDL, DML or migration-history changes.
-- Run only through an approved read-only production connection.

begin read only;

-- Migration history must contain only the successfully committed bridge.
select version, name
from supabase_migrations.schema_migrations
order by version;

-- The public relation set must still be the 14-table post-bridge set.
select table_name
from information_schema.tables
where table_schema = 'public'
  and table_type = 'BASE TABLE'
order by table_name;

-- Core-only physical markers. A rolled-back Core has no update function,
-- no Core-named indexes and no update triggers.
select
  to_regprocedure('public.studybook_set_updated_at()') is not null
    as core_updated_at_function_exists,
  (
    select count(*)
    from pg_catalog.pg_indexes index_row
    where index_row.schemaname = 'public'
      and index_row.indexname = any(array[
        'workspaces_owner_created_idx',
        'documents_owner_uploaded_idx',
        'documents_workspace_idx',
        'study_results_owner_updated_idx',
        'audiobooks_owner_updated_idx',
        'chats_owner_created_idx',
        'messages_chat_created_idx',
        'usage_events_owner_type_created_idx',
        'educator_courses_owner_idx',
        'educator_students_owner_idx',
        'educator_attendance_owner_idx',
        'educator_gradebook_owner_idx',
        'educator_question_banks_owner_idx',
        'educator_rubrics_owner_idx'
      ])
  ) as core_index_count,
  (
    select count(*)
    from pg_catalog.pg_trigger trigger_row
    join pg_catalog.pg_class relation
      on relation.oid = trigger_row.tgrelid
    join pg_catalog.pg_namespace namespace
      on namespace.oid = relation.relnamespace
    where namespace.nspname = 'public'
      and trigger_row.tgname = 'studybook_set_updated_at'
      and not trigger_row.tgisinternal
  ) as core_trigger_count;

-- Statement 12 target: exact post-failure column shape.
select
  ordinal_position,
  column_name,
  data_type,
  udt_name,
  is_nullable,
  column_default,
  is_identity
from information_schema.columns
where table_schema = 'public'
  and table_name = 'educator_students'
order by ordinal_position;

select
  constraint_row.conname,
  constraint_row.contype,
  pg_get_constraintdef(constraint_row.oid, true) as definition
from pg_catalog.pg_constraint constraint_row
where constraint_row.conrelid = 'public.educator_students'::regclass
order by constraint_row.conname;

select index_row.indexname, index_row.indexdef
from pg_catalog.pg_indexes index_row
where index_row.schemaname = 'public'
  and index_row.tablename = 'educator_students'
order by index_row.indexname;

select trigger_row.tgname, pg_get_triggerdef(trigger_row.oid, true) as definition
from pg_catalog.pg_trigger trigger_row
where trigger_row.tgrelid = 'public.educator_students'::regclass
  and not trigger_row.tgisinternal
order by trigger_row.tgname;

-- Bridge accounting. Only aggregate counts are returned.
select
  (
    (select count(*) from public.workspaces) +
    (select count(*) from public.documents) +
    (select count(*) from public.study_results) +
    (select count(*) from public.audiobooks) +
    (select count(*) from public.chats) +
    (select count(*) from public.messages) +
    (select count(*) from public.user_subscriptions) +
    (select count(*) from public.user_usage_events) +
    (select count(*) from public.educator_courses) +
    (select count(*) from public.educator_students) +
    (select count(*) from public.educator_attendance) +
    (select count(*) from public.educator_gradebook) +
    (select count(*) from public.educator_question_banks) +
    (select count(*) from public.educator_rubrics)
  ) as active_rows,
  (select count(*) from private.studybook_legacy_quarantine)
    as quarantine_rows;

-- No active row may reference a missing Auth owner.
select sum(orphan_count) as active_owner_orphans
from (
  select count(*)::bigint orphan_count
  from public.workspaces row_value
  left join auth.users owner on owner.id = row_value.user_id
  where owner.id is null
  union all
  select count(*) from public.documents row_value
  left join auth.users owner on owner.id = row_value.user_id
  where owner.id is null
  union all
  select count(*) from public.study_results row_value
  left join auth.users owner on owner.id = row_value.user_id
  where owner.id is null
  union all
  select count(*) from public.audiobooks row_value
  left join auth.users owner on owner.id = row_value.user_id
  where owner.id is null
  union all
  select count(*) from public.chats row_value
  left join auth.users owner on owner.id = row_value.user_id
  where owner.id is null
  union all
  select count(*) from public.user_subscriptions row_value
  left join auth.users owner on owner.id = row_value.user_id
  where owner.id is null
  union all
  select count(*) from public.user_usage_events row_value
  left join auth.users owner on owner.id = row_value.user_id
  where owner.id is null
  union all
  select count(*) from public.educator_courses row_value
  left join auth.users owner on owner.id = row_value.user_id
  where owner.id is null
  union all
  select count(*) from public.educator_students row_value
  left join auth.users owner on owner.id = row_value.user_id
  where owner.id is null
  union all
  select count(*) from public.educator_attendance row_value
  left join auth.users owner on owner.id = row_value.user_id
  where owner.id is null
  union all
  select count(*) from public.educator_gradebook row_value
  left join auth.users owner on owner.id = row_value.user_id
  where owner.id is null
  union all
  select count(*) from public.educator_question_banks row_value
  left join auth.users owner on owner.id = row_value.user_id
  where owner.id is null
  union all
  select count(*) from public.educator_rubrics row_value
  left join auth.users owner on owner.id = row_value.user_id
  where owner.id is null
) orphan_counts;

-- Later-migration objects must all be absent in the failed Core state.
select
  to_regclass('public.document_chunks') is not null as document_chunks,
  to_regclass('public.certificates') is not null as certificates,
  to_regclass('public.quota_reservations') is not null as quota_reservations,
  exists(
    select 1 from pg_catalog.pg_extension extension_row
    where extension_row.extname = 'vector'
  ) as vector_extension,
  exists(
    select 1
    from pg_catalog.pg_proc procedure_row
    join pg_catalog.pg_namespace namespace
      on namespace.oid = procedure_row.pronamespace
    where namespace.nspname = 'public'
      and procedure_row.proname = 'match_studybook_document_chunks'
  ) as rag_rpc,
  exists(
    select 1
    from pg_catalog.pg_proc procedure_row
    join pg_catalog.pg_namespace namespace
      on namespace.oid = procedure_row.pronamespace
    where namespace.nspname = 'public'
      and procedure_row.proname = any(array[
        'reserve_studybook_free_quota',
        'commit_studybook_free_quotas',
        'release_studybook_free_quota'
      ])
  ) as any_quota_rpc;

-- P0 containment and Storage integrity. Effective API probes are separate.
select
  relation.relname as table_name,
  relation.relrowsecurity as rls_enabled,
  has_table_privilege('anon', relation.oid, 'select') as anon_select,
  has_table_privilege('anon', relation.oid, 'insert') as anon_insert,
  has_table_privilege('anon', relation.oid, 'update') as anon_update,
  has_table_privilege('anon', relation.oid, 'delete') as anon_delete
from pg_catalog.pg_class relation
join pg_catalog.pg_namespace namespace
  on namespace.oid = relation.relnamespace
where namespace.nspname = 'public'
  and relation.relkind = 'r'
order by relation.relname;

select
  bucket.id,
  bucket.public,
  count(object_row.id) as object_count
from storage.buckets bucket
left join storage.objects object_row on object_row.bucket_id = bucket.id
where bucket.id in ('studybook-documents', 'studybook-private-artifacts')
group by bucket.id, bucket.public
order by bucket.id;

select
  relation.relname,
  relation.relrowsecurity as rls_enabled
from pg_catalog.pg_class relation
join pg_catalog.pg_namespace namespace
  on namespace.oid = relation.relnamespace
where namespace.nspname = 'storage'
  and relation.relname in ('buckets', 'objects')
order by relation.relname;

select tablename, policyname, cmd, roles
from pg_catalog.pg_policies
where schemaname in ('public', 'storage')
order by schemaname, tablename, policyname;

rollback;
