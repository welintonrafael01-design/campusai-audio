from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import os
from threading import Barrier
from uuid import uuid4

import pytest
from postgrest.exceptions import APIError
from supabase import Client, create_client


RUN_LOCAL = os.getenv("RUN_LOCAL_SUPABASE_TESTS") == "1"
SUPABASE_URL = os.getenv("SUPABASE_URL", "")
SERVICE_ROLE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")
ANON_KEY = os.getenv("SUPABASE_ANON_KEY", "")

pytestmark = pytest.mark.skipif(
    not RUN_LOCAL,
    reason="Set RUN_LOCAL_SUPABASE_TESTS=1 for disposable local Supabase.",
)

LIMITS = {
    "pdf_upload": 3,
    "chat_message": 10,
    "summary_generated": 3,
    "flashcards_generated": 1,
    "quiz_generated": 1,
}


def _assert_local_configuration() -> None:
    assert SUPABASE_URL.startswith(("http://127.0.0.1:", "http://localhost:"))
    assert SERVICE_ROLE_KEY
    assert ANON_KEY


@pytest.fixture
def local_admin() -> Client:
    _assert_local_configuration()
    return create_client(SUPABASE_URL, SERVICE_ROLE_KEY)


@pytest.fixture
def local_user(local_admin: Client):
    suffix = uuid4().hex
    email = f"w5-quota-{suffix}@local.invalid"
    password = f"W5-local-{uuid4().hex}!"
    response = local_admin.auth.admin.create_user(
        {
            "email": email,
            "password": password,
            "email_confirm": True,
            "app_metadata": {"role": "student"},
        }
    )
    user_id = response.user.id
    try:
        yield {
            "id": user_id,
            "email": email,
            "password": password,
        }
    finally:
        local_admin.auth.admin.delete_user(user_id)


def _reserve(
    *,
    user_id: str,
    event_type: str,
    operation_id: str,
    barrier: Barrier | None = None,
) -> dict:
    if barrier is not None:
        barrier.wait(timeout=10)
    client = create_client(SUPABASE_URL, SERVICE_ROLE_KEY)
    response = client.rpc(
        "reserve_studybook_free_quota",
        {
            "p_user_id": user_id,
            "p_event_type": event_type,
            "p_operation_id": operation_id,
        },
    ).execute()
    assert len(response.data) == 1
    return response.data[0]


@pytest.mark.parametrize(("event_type", "limit"), LIMITS.items())
def test_concurrent_boundary_allows_exactly_one_final_slot(
    local_admin: Client,
    local_user: dict,
    event_type: str,
    limit: int,
):
    if limit > 1:
        local_admin.table("user_usage_events").insert(
            [
                {
                    "user_id": local_user["id"],
                    "event_type": event_type,
                    "plan": "free",
                }
                for _ in range(limit - 1)
            ]
        ).execute()

    attempts = 8
    barrier = Barrier(attempts)
    with ThreadPoolExecutor(max_workers=attempts) as executor:
        results = list(
            executor.map(
                lambda index: _reserve(
                    user_id=local_user["id"],
                    event_type=event_type,
                    operation_id=f"concurrent-{event_type}-{index}-{uuid4().hex}",
                    barrier=barrier,
                ),
                range(attempts),
            )
        )

    acquired = [row for row in results if row["acquired"]]
    denied = [row for row in results if row["reservation_status"] == "denied"]
    assert len(acquired) == 1
    assert len(denied) == attempts - 1

    reservation_id = acquired[0]["reservation_id"]
    local_admin.rpc(
        "commit_studybook_free_quotas",
        {
            "p_user_id": local_user["id"],
            "p_reservation_ids": [reservation_id],
            "p_metadata_by_event": {event_type: {"test": "concurrency"}},
        },
    ).execute()

    consumed = (
        local_admin.table("user_usage_events")
        .select("id", count="exact")
        .eq("user_id", local_user["id"])
        .eq("event_type", event_type)
        .execute()
    )
    assert consumed.count == limit


def test_release_and_stale_recovery_restore_capacity(
    local_admin: Client,
    local_user: dict,
):
    first = _reserve(
        user_id=local_user["id"],
        event_type="flashcards_generated",
        operation_id=f"release-{uuid4().hex}",
    )
    local_admin.rpc(
        "release_studybook_free_quota",
        {
            "p_user_id": local_user["id"],
            "p_reservation_id": first["reservation_id"],
            "p_reason": "provider_failed",
        },
    ).execute()
    second = _reserve(
        user_id=local_user["id"],
        event_type="flashcards_generated",
        operation_id=f"released-capacity-{uuid4().hex}",
    )
    assert second["acquired"] is True

    local_admin.rpc(
        "release_studybook_free_quota",
        {
            "p_user_id": local_user["id"],
            "p_reservation_id": second["reservation_id"],
            "p_reason": "prepare_stale_test",
        },
    ).execute()
    stale = _reserve(
        user_id=local_user["id"],
        event_type="flashcards_generated",
        operation_id=f"stale-{uuid4().hex}",
    )
    local_admin.table("quota_reservations").update(
        {"expires_at": "2000-01-01T00:00:00+00:00"}
    ).eq("id", stale["reservation_id"]).execute()
    recovered = _reserve(
        user_id=local_user["id"],
        event_type="flashcards_generated",
        operation_id=f"stale-recovered-{uuid4().hex}",
    )
    assert recovered["acquired"] is True


def test_duplicate_operation_is_idempotent_under_concurrency(
    local_admin: Client,
    local_user: dict,
):
    attempts = 8
    barrier = Barrier(attempts)
    operation_id = f"same-operation-{uuid4().hex}"
    with ThreadPoolExecutor(max_workers=attempts) as executor:
        results = list(
            executor.map(
                lambda _: _reserve(
                    user_id=local_user["id"],
                    event_type="quiz_generated",
                    operation_id=operation_id,
                    barrier=barrier,
                ),
                range(attempts),
            )
        )

    assert sum(1 for row in results if row["acquired"]) == 1
    assert {row["reservation_id"] for row in results} == {
        results[0]["reservation_id"]
    }

    payload = {
        "p_user_id": local_user["id"],
        "p_reservation_ids": [results[0]["reservation_id"]],
        "p_metadata_by_event": {"quiz_generated": {"test": "idempotency"}},
    }
    local_admin.rpc("commit_studybook_free_quotas", payload).execute()
    local_admin.rpc("commit_studybook_free_quotas", payload).execute()

    consumed = (
        local_admin.table("user_usage_events")
        .select("id", count="exact")
        .eq("user_id", local_user["id"])
        .eq("event_type", "quiz_generated")
        .execute()
    )
    assert consumed.count == 1


def test_batch_commit_failure_is_atomic(
    local_admin: Client,
    local_user: dict,
):
    pdf = _reserve(
        user_id=local_user["id"],
        event_type="pdf_upload",
        operation_id=f"batch-pdf-{uuid4().hex}",
    )
    summary = _reserve(
        user_id=local_user["id"],
        event_type="summary_generated",
        operation_id=f"batch-summary-{uuid4().hex}",
    )
    local_admin.rpc(
        "release_studybook_free_quota",
        {
            "p_user_id": local_user["id"],
            "p_reservation_id": summary["reservation_id"],
            "p_reason": "controlled_partial_failure",
        },
    ).execute()

    with pytest.raises(APIError):
        local_admin.rpc(
            "commit_studybook_free_quotas",
            {
                "p_user_id": local_user["id"],
                "p_reservation_ids": [
                    pdf["reservation_id"],
                    summary["reservation_id"],
                ],
                "p_metadata_by_event": {},
            },
        ).execute()

    consumed = (
        local_admin.table("user_usage_events")
        .select("id", count="exact")
        .eq("user_id", local_user["id"])
        .in_("event_type", ["pdf_upload", "summary_generated"])
        .execute()
    )
    assert consumed.count == 0
    pdf_row = (
        local_admin.table("quota_reservations")
        .select("status")
        .eq("id", pdf["reservation_id"])
        .single()
        .execute()
    )
    assert pdf_row.data["status"] == "reserved"


def test_commit_accounts_usage_in_the_reserved_utc_period(
    local_admin: Client,
    local_user: dict,
):
    reservation = _reserve(
        user_id=local_user["id"],
        event_type="chat_message",
        operation_id=f"month-boundary-{uuid4().hex}",
    )
    now = datetime.now(timezone.utc)
    if now.month == 1:
        previous_period_start = datetime(now.year - 1, 12, 1, tzinfo=timezone.utc)
    else:
        previous_period_start = datetime(
            now.year,
            now.month - 1,
            1,
            tzinfo=timezone.utc,
        )
    current_period_start = datetime(now.year, now.month, 1, tzinfo=timezone.utc)
    reserved_at = previous_period_start.replace(day=2)
    local_admin.table("quota_reservations").update(
        {
            "period_start": previous_period_start.isoformat(),
            "period_end": current_period_start.isoformat(),
            "reserved_at": reserved_at.isoformat(),
        }
    ).eq("id", reservation["reservation_id"]).execute()

    local_admin.rpc(
        "commit_studybook_free_quotas",
        {
            "p_user_id": local_user["id"],
            "p_reservation_ids": [reservation["reservation_id"]],
            "p_metadata_by_event": {},
        },
    ).execute()

    usage = (
        local_admin.table("user_usage_events")
        .select("created_at")
        .eq("quota_reservation_id", reservation["reservation_id"])
        .single()
        .execute()
    )
    assert datetime.fromisoformat(usage.data["created_at"]) == reserved_at


def test_authenticated_client_cannot_read_or_mutate_quota_state(
    local_user: dict,
):
    client = create_client(SUPABASE_URL, ANON_KEY)
    client.auth.sign_in_with_password(
        {"email": local_user["email"], "password": local_user["password"]}
    )

    with pytest.raises(APIError):
        client.table("quota_reservations").select("id").execute()
    with pytest.raises(APIError):
        client.rpc(
            "reserve_studybook_free_quota",
            {
                "p_user_id": local_user["id"],
                "p_event_type": "quiz_generated",
                "p_operation_id": f"client-bypass-{uuid4().hex}",
            },
        ).execute()
