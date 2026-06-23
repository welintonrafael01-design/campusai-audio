#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
BACKEND="$ROOT/backend"

echo "===== STRIPE READINESS DIAGNOSTIC ====="

cd "$BACKEND"

echo "--- Stripe price keys ---"
grep -n "STRIPE_.*PRICE" .env || true

echo ""
echo "--- Required billing env ---"
grep -n "STRIPE_SECRET_KEY\|STRIPE_WEBHOOK_SECRET\|APP_SUCCESS_URL\|APP_CANCEL_URL\|STRIPE_CUSTOMER_PORTAL_RETURN_URL\|ADMIN_EMAILS" .env || true

echo ""
echo "--- billing endpoint duplicate check ---"
grep -n "admin/financial-dashboard" app/routes/billing.py

echo ""
echo "--- backend compile ---"
python -m py_compile $(find app -name "*.py")

echo ""
echo "===== FLUTTER ANALYZE ====="
cd "$ROOT/mobile/campusai_mobile"
flutter analyze || true

echo ""
echo "===== GIT STATUS ====="
cd "$ROOT"
git status --short
git log --oneline -10

echo ""
echo "===== DONE ====="
