-- Atomic Free quota lifecycle and privilege contract.
-- Local/disposable database only. All fixtures roll back.

begin;

insert into auth.users (
  id, aud, role, email, encrypted_password,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  (
    '00000000-0000-4000-8000-00000000000a',
    'authenticated', 'authenticated', 'quota-a@local.invalid', '',
    '{"role":"student"}'::jsonb, '{}'::jsonb, now(), now()
  ),
  (
    '00000000-0000-4000-8000-00000000000b',
    'authenticated', 'authenticated', 'quota-b@local.invalid', '',
    '{"role":"student"}'::jsonb, '{}'::jsonb, now(), now()
  );

insert into public.user_usage_events (user_id, event_type, plan)
values
  ('00000000-0000-4000-8000-00000000000a', 'pdf_upload', 'free'),
  ('00000000-0000-4000-8000-00000000000a', 'pdf_upload', 'free');

set local role service_role;

do $$
declare
  student_a uuid := '00000000-0000-4000-8000-00000000000a';
  student_b uuid := '00000000-0000-4000-8000-00000000000b';
  first_reservation uuid;
  released_reservation uuid;
  result_row record;
  usage_count integer;
begin
  select * into result_row
  from public.reserve_studybook_free_quota(
    student_a, 'pdf_upload', 'pdf-operation-00000001'
  );
  if not result_row.acquired or result_row.used_count <> 3 then
    raise exception 'Final document quota slot was not reserved.';
  end if;
  first_reservation := result_row.reservation_id;

  select * into result_row
  from public.reserve_studybook_free_quota(
    student_a, 'pdf_upload', 'pdf-operation-00000002'
  );
  if result_row.reservation_status <> 'denied' then
    raise exception 'Quota boundary exceeded.';
  end if;

  perform public.commit_studybook_free_quotas(
    student_a,
    array[first_reservation],
    '{"pdf_upload":{"mode":"sql_contract"}}'::jsonb
  );

  select count(*)::integer into usage_count
  from public.user_usage_events
  where user_id = student_a and event_type = 'pdf_upload';
  if usage_count <> 3 then
    raise exception 'Committed document usage count is incorrect.';
  end if;

  select * into result_row
  from public.reserve_studybook_free_quota(
    student_a, 'summary_generated', 'summary-idempotent-0001'
  );
  first_reservation := result_row.reservation_id;
  perform public.commit_studybook_free_quotas(
    student_a, array[first_reservation], '{}'::jsonb
  );
  perform public.commit_studybook_free_quotas(
    student_a, array[first_reservation], '{}'::jsonb
  );
  select count(*)::integer into usage_count
  from public.user_usage_events
  where user_id = student_a and event_type = 'summary_generated';
  if usage_count <> 1 then
    raise exception 'Idempotent commit duplicated usage.';
  end if;

  select * into result_row
  from public.reserve_studybook_free_quota(
    student_a, 'flashcards_generated', 'flashcards-release-0001'
  );
  released_reservation := result_row.reservation_id;
  if not public.release_studybook_free_quota(
    student_a, released_reservation, 'sql_contract_failure'
  ) then
    raise exception 'Reservation release failed.';
  end if;
  select * into result_row
  from public.reserve_studybook_free_quota(
    student_a, 'flashcards_generated', 'flashcards-release-0002'
  );
  if not result_row.acquired then
    raise exception 'Released reservation continued blocking quota.';
  end if;

  begin
    perform public.release_studybook_free_quota(
      student_b, result_row.reservation_id, 'cross_user_attempt'
    );
    raise exception 'Cross-user release was accepted.';
  exception
    when insufficient_privilege then null;
  end;

  select * into result_row
  from public.reserve_studybook_free_quota(
    student_b, 'flashcards_generated', 'student-b-independent-0001'
  );
  if not result_row.acquired then
    raise exception 'Student B quota was affected by Student A.';
  end if;
end
$$;

set local role authenticated;

do $$
begin
  begin
    perform public.reserve_studybook_free_quota(
      '00000000-0000-4000-8000-00000000000a',
      'quiz_generated',
      'client-bypass-attempt-0001'
    );
    raise exception 'Authenticated role executed quota reservation RPC.';
  exception
    when insufficient_privilege then null;
  end;
end
$$;

reset role;
rollback;
