#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
BACKEND="$ROOT/backend"

python3 <<'PY'
from pathlib import Path

file = Path("backend/app/routes/billing.py")
text = file.read_text()

old = '''    elif event_type in {
        "customer.subscription.created",
        "customer.subscription.updated",
        "customer.subscription.deleted",
    }:'''

new = '''    elif event_type in {
        "customer.subscription.created",
        "customer.subscription.updated",
        "customer.subscription.deleted",
        "invoice.paid",
        "invoice.payment_succeeded",
    }:'''

text = text.replace(old, new)

old2 = '''        metadata = data_object.get("metadata", {}) or {}
        checkout_metadata = _metadata_from_checkout_session(data_object.get("id"))'''

new2 = '''        metadata = data_object.get("metadata", {}) or {}
        subscription_id = data_object.get("id")

        if event_type in {"invoice.paid", "invoice.payment_succeeded"}:
            subscription_id = data_object.get("subscription")

        checkout_metadata = _metadata_from_checkout_session(subscription_id)'''

text = text.replace(old2, new2)

old3 = '''                stripe_subscription_id=data_object.get("id"),'''

new3 = '''                stripe_subscription_id=subscription_id,'''

text = text.replace(old3, new3)

file.write_text(text)
PY

cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

grep -n "invoice.paid\\|invoice.payment_succeeded\\|subscription_id = data_object" app/routes/billing.py

cd "$ROOT"
git status --short
