-- Atomic monthly Free-plan quota reservations.
-- user_usage_events remains the durable consumed-usage history.

begin;

create table if not exists public.quota_reservations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  event_type text not null check (
    event_type in (
      'pdf_upload',
      'chat_message',
      'summary_generated',
      'flashcards_generated',
      'quiz_generated'
    )
  ),
  operation_id text not null check (
    char_length(operation_id) between 16 and 128
  ),
  plan text not null default 'free' check (plan = 'free'),
  status text not null default 'reserved' check (
    status in ('reserved', 'consumed', 'released')
  ),
  period_start timestamptz not null,
  period_end timestamptz not null,
  reserved_at timestamptz not null default now(),
  expires_at timestamptz not null,
  consumed_at timestamptz,
  released_at timestamptz,
  release_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, event_type, operation_id),
  check (period_end > period_start)
);

alter table public.user_usage_events
  add column if not exists quota_reservation_id uuid
  references public.quota_reservations(id) on delete set null;

create unique index if not exists usage_events_quota_reservation_unique_idx
  on public.user_usage_events (quota_reservation_id)
  where quota_reservation_id is not null;

create index if not exists quota_reservations_scope_status_idx
  on public.quota_reservations (
    user_id,
    event_type,
    period_start,
    status,
    expires_at
  );

alter table public.quota_reservations enable row level security;

revoke all privileges on table public.quota_reservations
from public, anon, authenticated;

grant select, insert, update, delete on table public.quota_reservations
to service_role;

create or replace function public.reserve_studybook_free_quota(
  p_user_id uuid,
  p_event_type text,
  p_operation_id text
)
returns table (
  reservation_id uuid,
  reservation_status text,
  acquired boolean,
  idempotent boolean,
  used_count integer,
  quota_limit integer,
  quota_period_start timestamptz,
  quota_period_end timestamptz,
  reservation_expires_at timestamptz
)
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_now timestamptz := clock_timestamp();
  v_period_start timestamptz;
  v_period_end timestamptz;
  v_limit integer;
  v_consumed integer;
  v_reserved integer;
  v_existing public.quota_reservations%rowtype;
  v_reservation public.quota_reservations%rowtype;
begin
  if p_user_id is null then
    raise exception 'quota user is required' using errcode = '22023';
  end if;

  v_limit := case p_event_type
    when 'pdf_upload' then 3
    when 'chat_message' then 10
    when 'summary_generated' then 3
    when 'flashcards_generated' then 1
    when 'quiz_generated' then 1
    else null
  end;
  if v_limit is null then
    raise exception 'unsupported quota event' using errcode = '22023';
  end if;
  if p_operation_id is null
    or char_length(p_operation_id) not between 16 and 128 then
    raise exception 'invalid quota operation' using errcode = '22023';
  end if;

  v_period_start := date_trunc('month', v_now at time zone 'UTC') at time zone 'UTC';
  v_period_end := v_period_start + interval '1 month';

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      p_user_id::text || ':' || p_event_type || ':' || v_period_start::text,
      0
    )
  );

  update public.quota_reservations reservation
  set status = 'released',
      released_at = v_now,
      release_reason = 'reservation_expired',
      updated_at = v_now
  where reservation.user_id = p_user_id
    and reservation.event_type = p_event_type
    and reservation.period_start = v_period_start
    and reservation.status = 'reserved'
    and reservation.expires_at <= v_now;

  select reservation.* into v_existing
  from public.quota_reservations reservation
  where reservation.user_id = p_user_id
    and reservation.event_type = p_event_type
    and reservation.operation_id = p_operation_id;

  select count(*)::integer into v_consumed
  from public.user_usage_events usage_event
  where usage_event.user_id = p_user_id
    and usage_event.event_type = p_event_type
    and usage_event.created_at >= v_period_start
    and usage_event.created_at < v_period_end;

  select count(*)::integer into v_reserved
  from public.quota_reservations reservation
  where reservation.user_id = p_user_id
    and reservation.event_type = p_event_type
    and reservation.period_start = v_period_start
    and reservation.status = 'reserved'
    and reservation.expires_at > v_now;

  if v_existing.id is not null and v_existing.status = 'consumed' then
    return query select
      v_existing.id,
      v_existing.status,
      false,
      true,
      v_consumed + v_reserved,
      v_limit,
      v_period_start,
      v_period_end,
      v_existing.expires_at;
    return;
  end if;

  if v_existing.id is not null
    and v_existing.status = 'reserved'
    and v_existing.expires_at > v_now then
    return query select
      v_existing.id,
      v_existing.status,
      false,
      true,
      v_consumed + v_reserved,
      v_limit,
      v_period_start,
      v_period_end,
      v_existing.expires_at;
    return;
  end if;

  if v_consumed + v_reserved >= v_limit then
    return query select
      null::uuid,
      'denied'::text,
      false,
      false,
      v_consumed + v_reserved,
      v_limit,
      v_period_start,
      v_period_end,
      null::timestamptz;
    return;
  end if;

  if v_existing.id is null then
    insert into public.quota_reservations (
      user_id,
      event_type,
      operation_id,
      period_start,
      period_end,
      reserved_at,
      expires_at
    ) values (
      p_user_id,
      p_event_type,
      p_operation_id,
      v_period_start,
      v_period_end,
      v_now,
      v_now + interval '30 minutes'
    ) returning * into v_reservation;
  else
    update public.quota_reservations reservation
    set status = 'reserved',
        period_start = v_period_start,
        period_end = v_period_end,
        reserved_at = v_now,
        expires_at = v_now + interval '30 minutes',
        consumed_at = null,
        released_at = null,
        release_reason = null,
        updated_at = v_now
    where reservation.id = v_existing.id
    returning * into v_reservation;
  end if;

  return query select
    v_reservation.id,
    v_reservation.status,
    true,
    false,
    v_consumed + v_reserved + 1,
    v_limit,
    v_period_start,
    v_period_end,
    v_reservation.expires_at;
end
$$;

create or replace function public.commit_studybook_free_quotas(
  p_user_id uuid,
  p_reservation_ids uuid[],
  p_metadata_by_event jsonb default '{}'::jsonb
)
returns integer
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_now timestamptz := clock_timestamp();
  v_expected integer;
  v_found integer;
  v_committed integer := 0;
  v_reservation public.quota_reservations%rowtype;
  v_inserted integer;
begin
  v_expected := cardinality(p_reservation_ids);
  if p_user_id is null or v_expected is null or v_expected < 1 then
    raise exception 'quota reservations are required' using errcode = '22023';
  end if;
  if (select count(distinct value) from unnest(p_reservation_ids) value)
    <> v_expected then
    raise exception 'duplicate quota reservation' using errcode = '22023';
  end if;

  select count(*)::integer into v_found
  from public.quota_reservations reservation
  where reservation.user_id = p_user_id
    and reservation.id = any(p_reservation_ids);
  if v_found <> v_expected then
    raise exception 'quota reservation ownership mismatch'
      using errcode = '42501';
  end if;

  for v_reservation in
    select reservation.*
    from public.quota_reservations reservation
    where reservation.user_id = p_user_id
      and reservation.id = any(p_reservation_ids)
    order by reservation.event_type, reservation.id
  loop
    perform pg_catalog.pg_advisory_xact_lock(
      pg_catalog.hashtextextended(
        p_user_id::text || ':' || v_reservation.event_type || ':' ||
        v_reservation.period_start::text,
        0
      )
    );
  end loop;

  if exists (
    select 1
    from public.quota_reservations reservation
    where reservation.user_id = p_user_id
      and reservation.id = any(p_reservation_ids)
      and reservation.status not in ('reserved', 'consumed')
  ) then
    raise exception 'quota reservation is not committable'
      using errcode = '55000';
  end if;

  for v_reservation in
    select reservation.*
    from public.quota_reservations reservation
    where reservation.user_id = p_user_id
      and reservation.id = any(p_reservation_ids)
    order by reservation.event_type, reservation.id
  loop
    if v_reservation.status = 'consumed' then
      continue;
    end if;

    insert into public.user_usage_events (
      user_id,
      event_type,
      plan,
      metadata,
      quota_reservation_id,
      created_at
    ) values (
      p_user_id,
      v_reservation.event_type,
      'free',
      coalesce(p_metadata_by_event -> v_reservation.event_type, '{}'::jsonb)
        || pg_catalog.jsonb_build_object(
          'quota_reservation_id', v_reservation.id,
          'quota_period_start', v_reservation.period_start,
          'quota_period_end', v_reservation.period_end
        ),
      v_reservation.id,
      v_reservation.reserved_at
    ) on conflict (quota_reservation_id)
      where quota_reservation_id is not null
      do nothing;

    get diagnostics v_inserted = row_count;

    update public.quota_reservations reservation
    set status = 'consumed',
        consumed_at = v_now,
        updated_at = v_now
    where reservation.id = v_reservation.id
      and reservation.user_id = p_user_id
      and reservation.status = 'reserved';

    v_committed := v_committed + v_inserted;
  end loop;

  return v_committed;
end
$$;

create or replace function public.release_studybook_free_quota(
  p_user_id uuid,
  p_reservation_id uuid,
  p_reason text default 'operation_failed'
)
returns boolean
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_reservation public.quota_reservations%rowtype;
begin
  select reservation.* into v_reservation
  from public.quota_reservations reservation
  where reservation.id = p_reservation_id
    and reservation.user_id = p_user_id;

  if v_reservation.id is null then
    raise exception 'quota reservation ownership mismatch'
      using errcode = '42501';
  end if;

  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      p_user_id::text || ':' || v_reservation.event_type || ':' ||
      v_reservation.period_start::text,
      0
    )
  );

  update public.quota_reservations reservation
  set status = 'released',
      released_at = clock_timestamp(),
      release_reason = left(coalesce(nullif(p_reason, ''), 'operation_failed'), 80),
      updated_at = clock_timestamp()
  where reservation.id = p_reservation_id
    and reservation.user_id = p_user_id
    and reservation.status = 'reserved';

  return found;
end
$$;

revoke all on function public.reserve_studybook_free_quota(uuid, text, text)
from public, anon, authenticated;
revoke all on function public.commit_studybook_free_quotas(uuid, uuid[], jsonb)
from public, anon, authenticated;
revoke all on function public.release_studybook_free_quota(uuid, uuid, text)
from public, anon, authenticated;

grant execute on function public.reserve_studybook_free_quota(uuid, text, text)
to service_role;
grant execute on function public.commit_studybook_free_quotas(uuid, uuid[], jsonb)
to service_role;
grant execute on function public.release_studybook_free_quota(uuid, uuid, text)
to service_role;

commit;
