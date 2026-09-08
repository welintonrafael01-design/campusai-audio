-- StudyBook AI W6-P0 emergency confidentiality containment.
--
-- Scope: legacy remote schema only. This is not the final migration chain.
-- The patch is intentionally data-preserving and safe to re-run.

begin;

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
    'messages',
    'study_results',
    'user_subscriptions',
    'user_usage_events',
    'workspaces'
  ] loop
    if to_regclass(format('public.%I', relation_name)) is null then
      raise exception 'W6-P0 expected relation is missing: public.%', relation_name;
    end if;
  end loop;

  if to_regclass('storage.buckets') is null
    or to_regclass('storage.objects') is null then
    raise exception 'W6-P0 expected Storage relations are missing.';
  end if;

  if not exists (
    select 1
    from storage.buckets
    where id = 'studybook-documents'
  ) then
    raise exception 'W6-P0 expected private document bucket is missing.';
  end if;
end
$$;

alter table public.audiobooks enable row level security;
alter table public.chats enable row level security;
alter table public.documents enable row level security;
alter table public.educator_attendance enable row level security;
alter table public.educator_courses enable row level security;
alter table public.educator_gradebook enable row level security;
alter table public.educator_question_banks enable row level security;
alter table public.educator_rubrics enable row level security;
alter table public.educator_students enable row level security;
alter table public.messages enable row level security;
alter table public.study_results enable row level security;
alter table public.user_subscriptions enable row level security;
alter table public.user_usage_events enable row level security;
alter table public.workspaces enable row level security;

revoke all privileges on table
  public.audiobooks,
  public.chats,
  public.documents,
  public.educator_attendance,
  public.educator_courses,
  public.educator_gradebook,
  public.educator_question_banks,
  public.educator_rubrics,
  public.educator_students,
  public.messages,
  public.study_results,
  public.user_subscriptions,
  public.user_usage_events,
  public.workspaces
from anon;

-- The application does not expose anonymous document Storage. Keep the
-- existing authenticated/service-role privileges untouched.
update storage.buckets
set public = false
where id = 'studybook-documents'
  and public is distinct from false;

revoke all privileges on table storage.buckets, storage.objects from anon;

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
    'messages',
    'study_results',
    'user_subscriptions',
    'user_usage_events',
    'workspaces'
  ] loop
    if has_table_privilege('anon', format('public.%I', relation_name), 'SELECT')
      or has_table_privilege('anon', format('public.%I', relation_name), 'INSERT')
      or has_table_privilege('anon', format('public.%I', relation_name), 'UPDATE')
      or has_table_privilege('anon', format('public.%I', relation_name), 'DELETE') then
      raise exception 'W6-P0 anon privilege remains on public.%', relation_name;
    end if;

    if not has_table_privilege(
      'service_role', format('public.%I', relation_name), 'SELECT'
    )
      or not has_table_privilege(
        'service_role', format('public.%I', relation_name), 'INSERT'
      )
      or not has_table_privilege(
        'service_role', format('public.%I', relation_name), 'UPDATE'
      )
      or not has_table_privilege(
        'service_role', format('public.%I', relation_name), 'DELETE'
      ) then
      raise exception 'W6-P0 service role lost required access to public.%', relation_name;
    end if;
  end loop;

  if has_table_privilege('anon', 'storage.buckets', 'SELECT')
    or has_table_privilege('anon', 'storage.objects', 'SELECT')
    or has_table_privilege('anon', 'storage.objects', 'INSERT')
    or has_table_privilege('anon', 'storage.objects', 'UPDATE')
    or has_table_privilege('anon', 'storage.objects', 'DELETE') then
    raise exception 'W6-P0 anonymous Storage privilege remains.';
  end if;

  if exists (
    select 1
    from storage.buckets
    where id = 'studybook-documents'
      and public
  ) then
    raise exception 'W6-P0 document bucket remains public.';
  end if;
end
$$;

commit;
