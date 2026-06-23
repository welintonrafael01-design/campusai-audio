#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
BACKEND="$ROOT/backend"
STAMP="$(date +%Y%m%d_%H%M%S)"

echo "===== BILLING FINANCIAL DASHBOARD V1 ====="

cd "$ROOT"

mkdir -p scripts/billing reports/billing

mv diagnose_billing_phase2.sh scripts/billing/ 2>/dev/null || true
mv billing_phase2_stripe_prices_v1.sh scripts/billing/ 2>/dev/null || true
mv billing_phase2_diagnostic.txt reports/billing/ 2>/dev/null || true
mv billing_phase2_stripe_prices_v1_result.txt reports/billing/ 2>/dev/null || true

if ! git diff --quiet -- backend/app/routes/billing.py; then
  git add \
    backend/app/routes/billing.py \
    scripts/billing \
    reports/billing

  git commit -m "feat: support new Stripe billing price ids"
fi

mkdir -p "$ROOT/backups/billing_financial_$STAMP"
cp "$BACKEND/app/routes/billing.py" "$ROOT/backups/billing_financial_$STAMP/billing.py.bak"

python3 <<'PY'
from pathlib import Path

root = Path.home() / "Desktop/campusai-audio"
billing = root / "backend/app/routes/billing.py"
text = billing.read_text()

if "class FinancialDashboardResponse" not in text:
    insert_after = """class CustomerPortalResponse(BaseModel):
    portal_url: str
"""
    financial_models = """

class FinancialDashboardResponse(BaseModel):
    currency: str
    mrr: float
    arr: float
    paid_users: int
    free_users: int
    total_users: int
    conversion_rate: float
    estimated_ai_cost: float
    estimated_gross_margin: float
    estimated_gross_margin_rate: float
    plans: dict
"""
    text = text.replace(insert_after, insert_after + financial_models)

if "PLAN_MONTHLY_PRICES" not in text:
    anchor = """router = APIRouter(
    prefix="/billing",
    tags=["billing"],
)
"""
    constants = """

PLAN_MONTHLY_PRICES = {
    "free": 0.0,
    "student": 6.99,
    "accessibility": 3.99,
    "teacher": 13.99,
    "ultra": 24.99,
}

PLAN_ESTIMATED_AI_COSTS = {
    "free": 0.10,
    "student": 1.40,
    "accessibility": 1.25,
    "teacher": 3.25,
    "ultra": 7.50,
}
"""
    text = text.replace(anchor, anchor + constants)

if "def _require_billing_admin" not in text:
    marker = """def _normalize_plan(plan: str | None) -> str:
"""
    helpers = """def _require_billing_admin(current_user: AuthenticatedUser) -> None:
    admin_emails = {
        email.strip().lower()
        for email in os.getenv("ADMIN_EMAILS", "").split(",")
        if email.strip()
    }

    user_email = (current_user.email or "").strip().lower()

    if admin_emails and user_email in admin_emails:
        return

    raise HTTPException(
        status_code=403,
        detail="No tienes permiso para ver el dashboard financiero.",
    )


"""
    text = text.replace(marker, helpers + marker)

if '@router.get("/admin/financial-dashboard"' not in text:
    endpoint = r'''

@router.get(
    "/admin/financial-dashboard",
    response_model=FinancialDashboardResponse,
)
def get_financial_dashboard(
    current_user: AuthenticatedUser = Depends(require_current_user),
):
    _require_billing_admin(current_user)

    from app.database.supabase_client import get_supabase_admin_client

    client = get_supabase_admin_client()

    try:
        response = (
            client
            .table("user_subscriptions")
            .select("plan,subscription_status")
            .execute()
        )
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"No se pudo consultar user_subscriptions: {exc}",
        ) from exc

    rows = response.data or []

    plans = {
        plan: {
            "users": 0,
            "active_users": 0,
            "monthly_price": price,
            "mrr": 0.0,
            "estimated_ai_cost": 0.0,
            "estimated_gross_margin": 0.0,
        }
        for plan, price in PLAN_MONTHLY_PRICES.items()
    }

    for row in rows:
        raw_plan = row.get("plan") or "free"
        plan = _normalize_plan(raw_plan)
        status = row.get("subscription_status") or "unknown"

        if status != "active":
            plan = "free"

        if plan not in plans:
            plan = "free"

        plans[plan]["users"] += 1

        if status == "active" and plan != "free":
            plans[plan]["active_users"] += 1

    for plan, data in plans.items():
        active_users = data["active_users"] if plan != "free" else 0
        users_for_cost = data["users"]

        mrr = round(active_users * PLAN_MONTHLY_PRICES[plan], 2)
        estimated_cost = round(
            users_for_cost * PLAN_ESTIMATED_AI_COSTS.get(plan, 0.0),
            2,
        )
        gross_margin = round(mrr - estimated_cost, 2)

        data["mrr"] = mrr
        data["estimated_ai_cost"] = estimated_cost
        data["estimated_gross_margin"] = gross_margin

    mrr = round(sum(data["mrr"] for data in plans.values()), 2)
    arr = round(mrr * 12, 2)
    paid_users = sum(data["active_users"] for plan, data in plans.items() if plan != "free")
    total_users = sum(data["users"] for data in plans.values())
    free_users = plans["free"]["users"]
    estimated_ai_cost = round(
        sum(data["estimated_ai_cost"] for data in plans.values()),
        2,
    )
    estimated_gross_margin = round(mrr - estimated_ai_cost, 2)
    estimated_gross_margin_rate = (
        round((estimated_gross_margin / mrr) * 100, 2)
        if mrr > 0
        else 0.0
    )
    conversion_rate = (
        round((paid_users / total_users) * 100, 2)
        if total_users > 0
        else 0.0
    )

    return FinancialDashboardResponse(
        currency="USD",
        mrr=mrr,
        arr=arr,
        paid_users=paid_users,
        free_users=free_users,
        total_users=total_users,
        conversion_rate=conversion_rate,
        estimated_ai_cost=estimated_ai_cost,
        estimated_gross_margin=estimated_gross_margin,
        estimated_gross_margin_rate=estimated_gross_margin_rate,
        plans=plans,
    )
'''
    text = text.rstrip() + "\n" + endpoint + "\n"

billing.write_text(text)
PY

echo ""
echo "===== BACKEND COMPILE ====="
cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

echo ""
echo "===== ENDPOINT CHECK ====="
grep -n "financial-dashboard\|FinancialDashboardResponse\|PLAN_MONTHLY_PRICES\|ADMIN_EMAILS" app/routes/billing.py

echo ""
echo "===== FLUTTER ANALYZE ====="
cd "$ROOT/mobile/campusai_mobile"
flutter analyze

echo ""
echo "===== GIT STATUS ====="
cd "$ROOT"
git status --short

echo ""
echo "===== DONE ====="
