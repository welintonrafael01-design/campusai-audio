-- Run only against a disposable/local database after all migrations.
-- The transaction rolls back JWT test context and performs no application writes.

begin;

do $$
declare
  student_a uuid := '00000000-0000-4000-8000-00000000000a';
  student_b uuid := '00000000-0000-4000-8000-00000000000b';
  rls_table text;
begin
  foreach rls_table in array array[
    'workspaces', 'documents', 'study_results', 'audiobooks', 'chats',
    'messages', 'user_subscriptions', 'user_usage_events',
    'educator_courses', 'educator_students', 'educator_attendance',
    'educator_gradebook', 'educator_question_banks'
  ] loop
    if not exists (
      select 1
      from pg_class relation
      join pg_namespace namespace on namespace.oid = relation.relnamespace
      where namespace.nspname = 'public'
        and relation.relname = rls_table
        and relation.relrowsecurity
    ) then
      raise exception 'RLS is not enabled for public.%', rls_table;
    end if;
  end loop;

  if exists (
    select 1
    from pg_policies policy
    where policy.schemaname in ('public', 'storage')
      and policy.policyname like 'studybook_%'
      and policy.roles <> array['authenticated']::name[]
  ) then
    raise exception 'A StudyBook policy is available to a role other than authenticated.';
  end if;

  if (
    select count(*)
    from pg_policies policy
    where policy.schemaname = 'public'
      and policy.policyname like 'studybook_%'
  ) <> 45 then
    raise exception 'Unexpected public StudyBook policy count.';
  end if;

  if (
    select count(*)
    from pg_policies policy
    where policy.schemaname = 'storage'
      and policy.tablename = 'objects'
      and policy.policyname like 'studybook_%'
  ) <> 4 then
    raise exception 'Unexpected StudyBook Storage policy count.';
  end if;

  if exists (
    select 1
    from pg_policies policy
    where policy.schemaname = 'public'
      and policy.tablename in ('user_subscriptions', 'user_usage_events')
      and policy.cmd <> 'SELECT'
  ) then
    raise exception 'Subscription or usage writes are exposed to clients.';
  end if;

  if exists (
    select 1
    from pg_policies policy
    where policy.schemaname = 'public'
      and policy.tablename like 'educator_%'
      and concat_ws(' ', policy.qual, policy.with_check)
        not like '%has_teacher_access%'
  ) then
    raise exception 'An educator policy does not require teacher authorization.';
  end if;

  if exists (
    select 1
    from pg_policies policy
    where policy.schemaname = 'public'
      and policy.tablename in (
        'workspaces', 'study_results', 'audiobooks', 'chats',
        'user_subscriptions', 'user_usage_events'
      )
      and concat_ws(' ', policy.qual, policy.with_check)
        not like '%is_current_user%'
  ) then
    raise exception 'A direct-owner policy is missing its ownership predicate.';
  end if;

  if exists (
    select 1
    from pg_policies policy
    where policy.schemaname = 'public'
      and policy.tablename = 'documents'
      and concat_ws(' ', policy.qual, policy.with_check)
        not like '%owns_document%'
  ) then
    raise exception 'A document policy is missing its ownership predicate.';
  end if;

  if exists (
    select 1
    from pg_policies policy
    where policy.schemaname = 'public'
      and policy.tablename = 'messages'
      and concat_ws(' ', policy.qual, policy.with_check)
        not like '%owns_chat%'
  ) then
    raise exception 'A message policy is missing parent-chat ownership.';
  end if;

  if exists (
    select 1
    from pg_policies policy
    where policy.schemaname = 'storage'
      and policy.tablename = 'objects'
      and concat_ws(' ', policy.qual, policy.with_check)
        not like '%owns_document_object%'
  ) then
    raise exception 'A Storage policy is missing object ownership.';
  end if;

  if exists (
    select 1
    from pg_policies policy
    where policy.schemaname in ('public', 'storage')
      and policy.policyname like 'studybook_%'
      and lower(concat_ws(' ', policy.qual, policy.with_check))
        similar to '%(user_metadata|admin)%'
  ) then
    raise exception 'A client-controlled or Admin claim reached an RLS policy.';
  end if;

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object(
      'sub', student_a,
      'role', 'authenticated',
      'app_metadata', jsonb_build_object('role', 'student'),
      'user_metadata', jsonb_build_object('role', 'teacher')
    )::text,
    true
  );

  if private.current_rls_role() <> 'student' then
    raise exception 'user_metadata teacher spoof changed the RLS role.';
  end if;

  if private.has_teacher_access() then
    raise exception 'Student obtained Teacher access.';
  end if;

  if not private.is_current_user(student_a::text)
    or private.is_current_user(student_b::text) then
    raise exception 'Student A/B ownership isolation failed.';
  end if;

  if not private.owns_document(
    null,
    null,
    'studybook-documents',
    student_a::text || '/documents/document-a/file.pdf'
  ) then
    raise exception 'Student A cannot access its own document path.';
  end if;

  if private.owns_document(
    null,
    null,
    'studybook-documents',
    student_b::text || '/documents/document-b/file.pdf'
  ) then
    raise exception 'Student A can access Student B document path.';
  end if;

  if private.owns_document(
    null,
    null,
    'another-private-bucket',
    student_a::text || '/documents/document-a/file.pdf'
  ) then
    raise exception 'An arbitrary document bucket was accepted.';
  end if;

  if private.owns_document(
    student_b::text,
    null,
    'studybook-documents',
    student_a::text || '/documents/document-a/file.pdf'
  ) then
    raise exception 'A spoofed document user_id was accepted.';
  end if;

  if private.owns_document_object(
    'studybook-documents',
    student_a::text || '/documents/../student-b/file.pdf'
  ) then
    raise exception 'Storage path traversal was accepted.';
  end if;

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object(
      'sub', student_a,
      'role', 'authenticated',
      'app_metadata', jsonb_build_object('role', 'student'),
      'user_metadata', jsonb_build_object('role', 'admin')
    )::text,
    true
  );

  if private.current_rls_role() <> 'student' then
    raise exception 'user_metadata admin spoof changed the RLS role.';
  end if;

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object(
      'sub', student_a,
      'role', 'authenticated',
      'app_metadata', jsonb_build_object('role', 'admin')
    )::text,
    true
  );

  if private.current_rls_role() <> 'student' then
    raise exception 'app_metadata admin bypassed the backend Admin boundary.';
  end if;

  perform set_config(
    'request.jwt.claims',
    jsonb_build_object(
      'sub', student_a,
      'role', 'authenticated',
      'app_metadata', jsonb_build_object('role', 'teacher')
    )::text,
    true
  );

  if private.has_teacher_access() then
    raise exception 'Teacher role without an entitled subscription was accepted.';
  end if;

  perform set_config('request.jwt.claims', '{}', true);
  if private.is_current_user(student_a::text) then
    raise exception 'Unknown identity did not fail closed.';
  end if;
end
$$;

rollback;
