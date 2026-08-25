from __future__ import annotations

from datetime import datetime, timezone

from app.database.supabase_client import get_supabase_admin_client
from app.security.entitlements import (
    SUPPORTED_STORED_PLANS,
    canonical_plan,
    effective_stored_plan,
    normalize_stored_plan,
    normalize_subscription_status,
    subscription_is_entitled,
)


VALID_PLANS = SUPPORTED_STORED_PLANS


def default_free_subscription(user_id: str) -> dict:
    return {
        "user_id": user_id,
        "plan": "free",
        "subscribed_plan": "free",
        "canonical_plan": "free",
        "subscription_status": "free",
        "entitled": True,
        "email": None,
        "stripe_customer_id": None,
        "stripe_subscription_id": None,
        "source": "default",
    }


def upsert_user_subscription(
    *,
    user_id: str,
    email: str | None,
    plan: str,
    stripe_customer_id: str | None = None,
    stripe_subscription_id: str | None = None,
    subscription_status: str | None = None,
) -> dict:
    clean_plan = normalize_stored_plan(plan)

    if not user_id:
        raise ValueError("user_id es requerido.")

    client = get_supabase_admin_client()

    payload = {
        "user_id": user_id,
        "email": email,
        "plan": clean_plan,
        "stripe_customer_id": stripe_customer_id,
        "stripe_subscription_id": stripe_subscription_id,
        "subscription_status": subscription_status,
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }

    response = (
        client
        .table("user_subscriptions")
        .upsert(
            payload,
            on_conflict="user_id",
        )
        .execute()
    )

    if not response.data:
        return payload

    return response.data[0]


def downgrade_user_to_free(
    *,
    user_id: str,
    email: str | None = None,
    stripe_customer_id: str | None = None,
    stripe_subscription_id: str | None = None,
    subscription_status: str | None = "canceled",
) -> dict:
    return upsert_user_subscription(
        user_id=user_id,
        email=email,
        plan="free",
        stripe_customer_id=stripe_customer_id,
        stripe_subscription_id=stripe_subscription_id,
        subscription_status=subscription_status,
    )


def get_user_subscription(
    *,
    user_id: str,
) -> dict:
    if not user_id:
        raise ValueError("user_id es requerido.")

    client = get_supabase_admin_client()

    try:
        response = (
            client
            .table("user_subscriptions")
            .select("*")
            .eq("user_id", user_id)
            .maybe_single()
            .execute()
        )
    except Exception:
        return default_free_subscription(user_id)

    if response is None or not getattr(response, "data", None):
        return default_free_subscription(user_id)

    data = response.data

    if not isinstance(data, dict):
        return default_free_subscription(user_id)

    subscribed_plan = normalize_stored_plan(data.get("plan"))
    status = normalize_subscription_status(data.get("subscription_status"))
    plan = effective_stored_plan(plan=subscribed_plan, status=status)

    return {
        "user_id": data.get("user_id") or user_id,
        "email": data.get("email"),
        "plan": plan,
        "subscribed_plan": subscribed_plan,
        "canonical_plan": canonical_plan(plan),
        "subscription_status": status,
        "entitled": subscription_is_entitled(
            plan=subscribed_plan,
            status=status,
        ),
        "stripe_customer_id": data.get("stripe_customer_id"),
        "stripe_subscription_id": data.get("stripe_subscription_id"),
        "source": "supabase",
    }
