#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
BACKEND="$ROOT/backend"
FLUTTER="$ROOT/mobile/campusai_mobile"

python3 <<'PY'
from pathlib import Path

billing = Path("backend/app/routes/billing.py")
text = billing.read_text()
text = text.replace('"student": 6.99,', '"student": 4.99,')
text = text.replace('"teacher": 13.99,', '"teacher": 9.99,')
billing.write_text(text)

service = Path("mobile/campusai_mobile/lib/services/billing_service.dart")
text = service.read_text()

if "Future<Map<String, dynamic>> refreshSubscriptionFromServer()" not in text:
    insert = r'''
  Future<Map<String, dynamic>> refreshSubscriptionFromServer() async {
    if (!AuthService.isLoggedIn) {
      throw Exception('Debes iniciar sesión para sincronizar tu suscripción.');
    }

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/billing/subscription/me'),
      headers: AuthService.authHeaders,
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      final detail = decoded is Map<String, dynamic>
          ? decoded['detail']?.toString()
          : null;

      throw Exception(detail ?? 'No se pudo sincronizar la suscripción.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Respuesta inválida del servidor.');
    }

    final plan = planFromCode(decoded['plan']?.toString());
    final status = decoded['subscription_status']?.toString() ?? 'unknown';

    const PlanGuardService().saveCurrentPlan(
      plan,
      source: decoded['source']?.toString() ?? 'supabase',
      subscriptionStatus: status,
    );

    return decoded;
  }
'''
    text = text.replace("\n  Future<void> openCustomerPortal() async {", insert + "\n  Future<void> openCustomerPortal() async {")

service.write_text(text)
PY

cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

cd "$FLUTTER"
flutter analyze || true

cd "$ROOT"
grep -R "student.*4.99\|teacher.*9.99\|refreshSubscriptionFromServer\|subscription/me" \
backend/app/routes/billing.py \
mobile/campusai_mobile/lib/services/billing_service.dart -n

git status --short
