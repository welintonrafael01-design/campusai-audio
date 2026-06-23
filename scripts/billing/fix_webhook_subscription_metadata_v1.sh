#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
BACKEND="$ROOT/backend"

python3 <<'PY'
from pathlib import Path

file = Path("backend/app/routes/billing.py")
text = file.read_text()

if "def _metadata_from_checkout_session" not in text:
    marker = """def _resolve_plan_from_stripe_object(data_object: dict, fallback: str = "free") -> str:
"""
    helper = """def _metadata_from_checkout_session(subscription_id: str | None) -> dict:
    if not subscription_id:
        return {}

    try:
        sessions = stripe.checkout.Session.list(
            subscription=subscription_id,
            limit=1,
        )
    except Exception:
        return {}

    if not sessions.data:
        return {}

    session = sessions.data[0]
    metadata = dict(session.metadata or {})

    if session.customer_email and not metadata.get("email"):
        metadata["email"] = session.customer_email

    return metadata


"""
    text = text.replace(marker, helper + marker)

old = """        metadata = data_object.get("metadata", {}) or {}

        user_id = metadata.get("user_id", "")
        email = metadata.get("email")
        plan = _resolve_plan_from_stripe_object(
            data_object,
            metadata.get("plan", "free"),
        )

        if not user_id:
            return {
                "received": True,
                "type": event_type,
                "ignored": "missing_user_id",
            }
"""

new = """        metadata = data_object.get("metadata", {}) or {}
        checkout_metadata = _metadata_from_checkout_session(data_object.get("id"))

        merged_metadata = {
            **checkout_metadata,
            **metadata,
        }

        user_id = merged_metadata.get("user_id", "")
        email = merged_metadata.get("email")
        plan = _resolve_plan_from_stripe_object(
            data_object,
            merged_metadata.get("plan", "free"),
        )

        if not user_id:
            return {
                "received": True,
                "type": event_type,
                "ignored": "missing_user_id",
            }
"""

if old not in text:
    raise SystemExit("No se encontró el bloque de metadata de suscripción esperado.")

text = text.replace(old, new)

file.write_text(text)
PY

cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

grep -n "_metadata_from_checkout_session\|checkout_metadata\|merged_metadata" app/routes/billing.py

cd "$ROOT"
git status --short
