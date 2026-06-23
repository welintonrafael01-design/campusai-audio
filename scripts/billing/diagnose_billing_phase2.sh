#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
BACKEND="$ROOT/backend"

echo "===== BILLING PHASE 2 DIAGNOSTIC ====="

cd "$ROOT"
echo "--- git ---"
git status --short
git log --oneline -4

echo ""
echo "--- billing.py ---"
sed -n '1,420p' "$BACKEND/app/routes/billing.py"

echo ""
echo "--- subscription_service.py ---"
sed -n '1,220p' "$BACKEND/app/services/subscription_service.py"

echo ""
echo "--- env price refs ---"
grep -R "STRIPE_.*PRICE_ID\|STRIPE_WEBHOOK\|STRIPE_SECRET" "$BACKEND" -n || true

echo ""
echo "--- supabase subscription refs ---"
grep -R "subscriptions\|subscription" "$BACKEND/app" -n | head -120 || true

echo ""
echo "===== BACKEND COMPILE ====="
cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

echo ""
echo "===== DONE ====="
