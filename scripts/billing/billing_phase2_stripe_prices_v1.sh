#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
BACKEND="$ROOT/backend"
STAMP="$(date +%Y%m%d_%H%M%S)"

echo "===== BILLING PHASE 2 STRIPE PRICES V1 ====="

mkdir -p "$ROOT/backups/billing_phase2_$STAMP"
cp "$BACKEND/app/routes/billing.py" "$ROOT/backups/billing_phase2_$STAMP/billing.py.bak"
cp "$BACKEND/.env" "$ROOT/backups/billing_phase2_$STAMP/env.bak" 2>/dev/null || true

python3 <<'PY'
from pathlib import Path
import re

root = Path.home() / "Desktop/campusai-audio"
backend = root / "backend"
billing = backend / "app/routes/billing.py"

text = billing.read_text()

text = text.replace(
    'description="Plan solicitado: pro o educator.",',
    'description="Plan solicitado: student, teacher, accessibility o ultra.",',
)

text = re.sub(
    r'def _resolve_plan_from_stripe_object\(data_object: dict, fallback: str = "free"\) -> str:\n.*?\n\n(?=def _get_price_id)',
    '''def _normalize_plan(plan: str | None) -> str:
    value = (plan or "free").strip().lower()

    legacy_map = {
        "pro": "student",
        "educator": "teacher",
    }

    value = legacy_map.get(value, value)

    if value in {"free", "student", "teacher", "accessibility", "ultra"}:
        return value

    return "free"


def _stripe_price_map() -> dict[str, str]:
    return {
        "student": (
            os.getenv("STRIPE_STUDENT_PRICE_ID", "")
            or os.getenv("STRIPE_PRICE_STUDENT", "")
            or os.getenv("STRIPE_PRICE_PRO", "")
        ),
        "teacher": (
            os.getenv("STRIPE_TEACHER_PRICE_ID", "")
            or os.getenv("STRIPE_PRICE_TEACHER", "")
            or os.getenv("STRIPE_PRICE_EDUCATOR", "")
        ),
        "accessibility": (
            os.getenv("STRIPE_ACCESSIBILITY_PRICE_ID", "")
            or os.getenv("STRIPE_PRICE_ACCESSIBILITY", "")
        ),
        "ultra": (
            os.getenv("STRIPE_ULTRA_PRICE_ID", "")
            or os.getenv("STRIPE_PRICE_ULTRA", "")
        ),
    }


def _resolve_plan_from_stripe_object(data_object: dict, fallback: str = "free") -> str:
    metadata = data_object.get("metadata", {}) or {}

    plan = _normalize_plan(str(metadata.get("plan") or ""))
    if plan != "free":
        return plan

    price_map = _stripe_price_map()
    reverse_price_map = {
        price_id: plan_code
        for plan_code, price_id in price_map.items()
        if price_id
    }

    items = data_object.get("items", {}).get("data", []) or []

    for item in items:
        price = item.get("price", {}) or {}
        price_id = price.get("id") or item.get("plan", {}).get("id")

        if price_id in reverse_price_map:
            return reverse_price_map[price_id]

    return _normalize_plan(fallback)


''',
    text,
    flags=re.DOTALL,
)

text = re.sub(
    r'def _get_price_id\(plan: str\) -> str:\n.*?\n\n(?=@router\.post)',
    '''def _get_price_id(plan: str) -> str:
    price_map = _stripe_price_map()
    price_id = price_map.get(plan)

    if not price_id:
        raise HTTPException(
            status_code=400,
            detail=(
                f"El plan {plan} no tiene Price ID configurado en Stripe. "
                "Configura STRIPE_STUDENT_PRICE_ID, STRIPE_TEACHER_PRICE_ID, "
                "STRIPE_ACCESSIBILITY_PRICE_ID o STRIPE_ULTRA_PRICE_ID."
            ),
        )

    return price_id


''',
    text,
    flags=re.DOTALL,
)

text = text.replace(
    'detail="Plan inválido. Usa pro o educator.",',
    'detail="Plan inválido. Usa student, teacher, accessibility o ultra.",',
)

text = text.replace(
    'plan = payload.plan.strip().lower()',
    'plan = _normalize_plan(payload.plan)',
)

billing.write_text(text)

# .env: add placeholders only if missing. Do not remove existing legacy vars.
env = backend / ".env"
if env.exists():
    env_text = env.read_text()
else:
    env_text = ""

additions = []
for key in [
    "STRIPE_STUDENT_PRICE_ID",
    "STRIPE_TEACHER_PRICE_ID",
    "STRIPE_ACCESSIBILITY_PRICE_ID",
    "STRIPE_ULTRA_PRICE_ID",
]:
    if f"{key}=" not in env_text:
        additions.append(f"{key}=")

if additions:
    env_text = env_text.rstrip() + "\n\n# StudyBook AI Billing Plans\n" + "\n".join(additions) + "\n"
    env.write_text(env_text)
PY

echo ""
echo "===== BACKEND COMPILE ====="
cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

echo ""
echo "===== BILLING REFS CHECK ====="
grep -n "STRIPE_.*PRICE\|Plan inválido\|description=.*Plan solicitado\|def _normalize_plan\|def _stripe_price_map" app/routes/billing.py

echo ""
echo "===== ENV PRICE KEYS CHECK ====="
grep -n "STRIPE_.*PRICE" .env || true

echo ""
echo "===== GIT STATUS ====="
cd "$ROOT"
git status --short

echo ""
echo "===== DONE ====="
echo "Backups en: $ROOT/backups/billing_phase2_$STAMP"
