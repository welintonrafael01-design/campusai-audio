from __future__ import annotations

from datetime import datetime, timezone

from app.database.supabase_client import get_supabase_admin_client


VALID_PLANS = {"free", "pro", "educator"}


def upsert_user_subscription(
    *,
    user_id: str,
    email: str | None,
    plan: str,
    stripe_customer_id: str | None = None,
    stripe_subscription_id: str | None = None,
    subscription_status: str | None = None,
) -> dict:
    clean_plan = plan.strip().lower()

    if clean_plan not in VALID_PLANS:
        clean_plan = "free"

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

    response = (
        client
        .table("user_subscriptions")
        .select("*")
        .eq("user_id", user_id)
        .maybe_single()
        .execute()
    )

    if not response.data:
        return {
            "user_id": user_id,
            "plan": "free",
            "subscription_status": "free",
            "email": None,
            "stripe_customer_id": None,
            "stripe_subscription_id": None,
            "source": "default",
        }

    data = response.data

    plan = data.get("plan") or "free"
    status = data.get("subscription_status") or "unknown"

    if status != "active":
        plan = "free"

    return {
        "user_id": data.get("user_id") or user_id,
        "email": data.get("email"),
        "plan": plan,
        "subscription_status": status,
        "stripe_customer_id": data.get("stripe_customer_id"),
        "stripe_subscription_id": data.get("stripe_subscription_id"),
        "source": "supabase",
    }
