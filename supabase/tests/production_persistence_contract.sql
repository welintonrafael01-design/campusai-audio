-- End-to-end SQL authorization and durable persistence contract.
-- Local/disposable database only. All fixtures roll back.

begin;

insert into auth.users (
  id, aud, role, email, encrypted_password,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  (
    '00000000-0000-4000-8000-00000000000a',
    'authenticated', 'authenticated', 'student-a@local.invalid', '',
    '{"role":"student"}'::jsonb, '{}'::jsonb, now(), now()
  ),
  (
    '00000000-0000-4000-8000-00000000000b',
    'authenticated', 'authenticated', 'student-b@local.invalid', '',
    '{"role":"student"}'::jsonb, '{}'::jsonb, now(), now()
  ),
  (
    '00000000-0000-4000-8000-00000000000c',
    'authenticated', 'authenticated', 'teacher@local.invalid', '',
    '{"role":"teacher"}'::jsonb, '{}'::jsonb, now(), now()
  );

insert into public.user_subscriptions (
  user_id, plan, subscription_status
) values
  ('00000000-0000-4000-8000-00000000000a', 'student', 'active'),
  ('00000000-0000-4000-8000-00000000000b', 'student', 'active'),
  ('00000000-0000-4000-8000-00000000000c', 'teacher', 'active');

insert into public.workspaces (id, user_id, name) values
  (
    '10000000-0000-4000-8000-00000000000a',
    '00000000-0000-4000-8000-00000000000a', 'Student A'
  ),
  (
    '10000000-0000-4000-8000-00000000000b',
    '00000000-0000-4000-8000-00000000000b', 'Student B'
  );

insert into public.documents (
  user_id, workspace_id, document_id, document_name,
  storage_bucket, storage_path
) values
  (
    '00000000-0000-4000-8000-00000000000a',
    '10000000-0000-4000-8000-00000000000a',
    'document-a', 'Document A', 'studybook-documents',
    '00000000-0000-4000-8000-00000000000a/documents/document-a/file.pdf'
  ),
  (
    '00000000-0000-4000-8000-00000000000b',
    '10000000-0000-4000-8000-00000000000b',
    'document-b', 'Document B', 'studybook-documents',
    '00000000-0000-4000-8000-00000000000b/documents/document-b/file.pdf'
  );

insert into public.study_results (user_id, document_id, type, content) values
  ('00000000-0000-4000-8000-00000000000a', 'document-a', 'quiz', 'A'),
  ('00000000-0000-4000-8000-00000000000b', 'document-b', 'quiz', 'B');

insert into public.audiobooks (user_id, document_id, file_name, chapters) values
  ('00000000-0000-4000-8000-00000000000a', 'document-a', 'A', '[]'),
  ('00000000-0000-4000-8000-00000000000b', 'document-b', 'B', '[]');

insert into public.educator_courses (id, user_id, name) values
  ('teacher-course', '00000000-0000-4000-8000-00000000000c', 'Teacher course');

insert into public.document_chunks (
  user_id, document_id, chunk_index, page_number, content, embedding
) values
  (
    '00000000-0000-4000-8000-00000000000a', 'document-a', 0, 1,
    'Vector content A', array_fill(0.0::real, array[1536])::extensions.vector
  ),
  (
    '00000000-0000-4000-8000-00000000000b', 'document-b', 0, 1,
    'Vector content B', array_fill(1.0::real, array[1536])::extensions.vector
  );

insert into public.certificates (
  certificate_id, user_id, student_name, course_name
) values
  ('certificate-a', '00000000-0000-4000-8000-00000000000a', 'A', 'Course'),
  ('certificate-b', '00000000-0000-4000-8000-00000000000b', 'B', 'Course');

insert into storage.objects (bucket_id, name, owner_id) values
  (
    'studybook-documents',
    '00000000-0000-4000-8000-00000000000a/documents/document-a/file.pdf',
    '00000000-0000-4000-8000-00000000000a'
  ),
  (
    'studybook-documents',
    '00000000-0000-4000-8000-00000000000b/documents/document-b/file.pdf',
    '00000000-0000-4000-8000-00000000000b'
  ),
  (
    'studybook-private-artifacts',
    '00000000-0000-4000-8000-00000000000a/audio/audio-a.mp3',
    '00000000-0000-4000-8000-00000000000a'
  );

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-4000-8000-00000000000a","role":"authenticated","app_metadata":{"role":"student"},"user_metadata":{"role":"teacher"}}',
  true
);

do $$
begin
  if (select count(*) from public.workspaces) <> 1 then
    raise exception 'Student A workspace isolation failed.';
  end if;
  if (select count(*) from public.documents) <> 1 then
    raise exception 'Student A document isolation failed.';
  end if;
  if (select count(*) from public.study_results) <> 1 then
    raise exception 'Student A study-result isolation failed.';
  end if;
  if (select count(*) from public.audiobooks) <> 1 then
    raise exception 'Student A audiobook isolation failed.';
  end if;
  if (select count(*) from public.educator_courses) <> 0 then
    raise exception 'Student A reached Teacher data.';
  end if;
  if (select count(*) from storage.objects) <> 1 then
    raise exception 'Student A Storage isolation failed.';
  end if;
  if has_table_privilege('authenticated', 'public.document_chunks', 'SELECT') then
    raise exception 'Authenticated received direct vector-table access.';
  end if;
  if has_table_privilege('authenticated', 'public.certificates', 'SELECT') then
    raise exception 'Authenticated received direct certificate-table access.';
  end if;
  if has_function_privilege(
    'authenticated',
    'public.match_studybook_document_chunks(uuid,extensions.vector,text[],integer)',
    'EXECUTE'
  ) then
    raise exception 'Authenticated received direct vector-RPC access.';
  end if;

  insert into public.workspaces (user_id, name)
  values ('00000000-0000-4000-8000-00000000000a', 'Own insert');

  begin
    insert into public.workspaces (user_id, name)
    values ('00000000-0000-4000-8000-00000000000b', 'Spoof');
    raise exception 'Owner spoof was accepted.';
  exception when insufficient_privilege then
    null;
  end;

  insert into storage.objects (bucket_id, name, owner_id) values (
    'studybook-documents',
    '00000000-0000-4000-8000-00000000000a/documents/document-new/file.pdf',
    '00000000-0000-4000-8000-00000000000a'
  );

  begin
    insert into storage.objects (bucket_id, name, owner_id) values (
      'studybook-documents',
      '00000000-0000-4000-8000-00000000000b/documents/spoof/file.pdf',
      '00000000-0000-4000-8000-00000000000a'
    );
    raise exception 'Storage owner-path spoof was accepted.';
  exception when insufficient_privilege then
    null;
  end;

  begin
    insert into storage.objects (bucket_id, name, owner_id) values (
      'studybook-private-artifacts',
      '00000000-0000-4000-8000-00000000000a/audio/spoof.mp3',
      '00000000-0000-4000-8000-00000000000a'
    );
    raise exception 'Direct private-artifact write was accepted.';
  exception when insufficient_privilege then
    null;
  end;
end
$$;

reset role;
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-4000-8000-00000000000c","role":"authenticated","app_metadata":{"role":"teacher"},"user_metadata":{}}',
  true
);

do $$
begin
  if not private.has_teacher_access() then
    raise exception 'Entitled Teacher was denied.';
  end if;
  if (select count(*) from public.educator_courses) <> 1 then
    raise exception 'Entitled Teacher cannot read its course.';
  end if;
end
$$;

reset role;
set local role service_role;

do $$
declare
  matched record;
begin
  select * into matched
  from public.match_studybook_document_chunks(
    '00000000-0000-4000-8000-00000000000a',
    array_fill(0.0::real, array[1536])::extensions.vector,
    array['document-a', 'document-b'],
    5
  );
  if matched.document_id <> 'document-a'
    or matched.content <> 'Vector content A' then
    raise exception 'Owner-scoped vector retrieval failed.';
  end if;
end
$$;

rollback;
