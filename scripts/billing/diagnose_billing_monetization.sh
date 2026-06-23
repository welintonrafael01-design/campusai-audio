#!/usr/bin/env bash
set -e

echo "===== GIT STATUS ====="
git status
git branch --show-current
git log --oneline -5

echo ""
echo "===== BACKEND BILLING DIAGNOSTIC ====="
cd ~/Desktop/campusai-audio/backend

echo "--- stripe refs ---"
grep -R "stripe" app -n || true

echo "--- plan refs ---"
grep -R "plan" app/routes app/services -n || true

echo "--- billing.py ---"
sed -n '1,220p' app/routes/billing.py || true

echo "--- subscription_service.py ---"
sed -n '1,240p' app/services/subscription_service.py || true

echo "--- usage_limit_service.py ---"
sed -n '1,260p' app/services/usage_limit_service.py || true

echo "--- backend compile ---"
python -m py_compile $(find app -name "*.py")

echo ""
echo "===== FLUTTER BILLING DIAGNOSTIC ====="
cd ~/Desktop/campusai-audio/mobile/campusai_mobile

echo "--- flutter refs ---"
grep -R "PlanType\|pro\|educator\|billing\|subscription\|checkout\|portal" lib -n || true

echo "--- billing_service.dart ---"
sed -n '1,220p' lib/services/billing_service.dart || true

echo "--- plan_guard_service.dart ---"
sed -n '1,260p' lib/services/plan_guard_service.dart || true

echo "--- plans_screen.dart ---"
sed -n '1,300p' lib/screens/plans_screen.dart || true

echo "--- flutter analyze ---"
flutter analyze

echo ""
echo "===== DIAGNOSTIC COMPLETE ====="
