#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
BACKEND="$ROOT/backend"
FLUTTER="$ROOT/mobile/campusai_mobile"
FILE="$FLUTTER/lib/screens/plans_screen.dart"

python3 <<'PY'
from pathlib import Path

file = Path("mobile/campusai_mobile/lib/screens/plans_screen.dart")
text = file.read_text()

old = """    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showCheckoutSnackBar();
    });"""

new = """    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _syncCheckoutSuccess();
      _showCheckoutSnackBar();
    });"""

text = text.replace(old, new)

old_method = """  String? _checkoutMessage() {
    final status = _checkoutStatus();
    final plan = planFromCode(_checkoutPlanCode());
    final planName = AppPlans.planNames[plan] ?? 'Premium';

    if (status == 'success') {
      const PlanGuardService().saveCurrentPlan(plan);

      return AppLocalizations.of(context).checkoutSuccessMessage(planName);
    }

    if (status == 'cancel') {
      return AppLocalizations.of(context).checkoutCancelMessage;
    }

    return null;
  }"""

new_method = """  Future<void> _syncCheckoutSuccess() async {
    if (_checkoutStatus() != 'success') {
      return;
    }

    final fallbackPlan = planFromCode(_checkoutPlanCode());

    try {
      await const BillingService().refreshSubscriptionFromServer();
    } catch (_) {
      if (fallbackPlan != CampusPlan.free) {
        const PlanGuardService().saveCurrentPlan(
          fallbackPlan,
          source: 'checkout_pending',
          subscriptionStatus: 'pending',
        );
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  String? _checkoutMessage() {
    final status = _checkoutStatus();
    final plan = planFromCode(_checkoutPlanCode());
    final planName = AppPlans.planNames[plan] ?? 'Premium';

    if (status == 'success') {
      return AppLocalizations.of(context).checkoutSuccessMessage(planName);
    }

    if (status == 'cancel') {
      return AppLocalizations.of(context).checkoutCancelMessage;
    }

    return null;
  }"""

if old_method not in text:
    raise SystemExit("No se encontró _checkoutMessage esperado.")

text = text.replace(old_method, new_method)

file.write_text(text)
PY

cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

cd "$FLUTTER"
flutter analyze || true

cd "$ROOT"
grep -R "_syncCheckoutSuccess\|refreshSubscriptionFromServer\|checkout_pending" \
mobile/campusai_mobile/lib/screens/plans_screen.dart \
mobile/campusai_mobile/lib/services/billing_service.dart -n

git status --short
