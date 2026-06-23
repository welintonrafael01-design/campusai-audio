#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
BACKEND="$ROOT/backend"
FLUTTER="$ROOT/mobile/campusai_mobile"
STAMP="$(date +%Y%m%d_%H%M%S)"

echo "===== BILLING CORE MIGRATION V1 ====="

cd "$ROOT"

echo "Rama actual:"
git branch --show-current

if [ "$(git branch --show-current)" != "development" ]; then
  echo "ERROR: Debes estar en rama development."
  exit 1
fi

echo "Creando backups..."
mkdir -p "$ROOT/backups/billing_$STAMP"

cp "$BACKEND/app/routes/billing.py" "$ROOT/backups/billing_$STAMP/billing.py.bak"
cp "$BACKEND/app/services/subscription_service.py" "$ROOT/backups/billing_$STAMP/subscription_service.py.bak"
cp "$BACKEND/app/services/usage_limit_service.py" "$ROOT/backups/billing_$STAMP/usage_limit_service.py.bak"

cp "$FLUTTER/lib/config/app_plans.dart" "$ROOT/backups/billing_$STAMP/app_plans.dart.bak"
cp "$FLUTTER/lib/services/billing_service.dart" "$ROOT/backups/billing_$STAMP/billing_service.dart.bak"
cp "$FLUTTER/lib/services/plan_guard_service.dart" "$ROOT/backups/billing_$STAMP/plan_guard_service.dart.bak"
cp "$FLUTTER/lib/screens/plans_screen.dart" "$ROOT/backups/billing_$STAMP/plans_screen.dart.bak"

python3 <<'PY'
from pathlib import Path
import re

root = Path.home() / "Desktop/campusai-audio"
backend = root / "backend"
flutter = root / "mobile/campusai_mobile"

# -------------------------
# Backend: subscription_service.py
# -------------------------
subscription_file = backend / "app/services/subscription_service.py"
text = subscription_file.read_text()

text = re.sub(
    r"VALID_PLANS\s*=\s*\{[^}]+\}",
    'VALID_PLANS = {"free", "student", "teacher", "accessibility", "ultra"}',
    text,
)

text = text.replace('"pro"', '"student"')
text = text.replace('"educator"', '"teacher"')
text = text.replace("'pro'", "'student'")
text = text.replace("'educator'", "'teacher'")

subscription_file.write_text(text)

# -------------------------
# Backend: billing.py
# -------------------------
billing_file = backend / "app/routes/billing.py"
text = billing_file.read_text()

text = text.replace('{"pro", "educator"}', '{"student", "teacher", "accessibility", "ultra"}')
text = text.replace('"pro", "educator"', '"student", "teacher", "accessibility", "ultra"')
text = text.replace("'pro', 'educator'", "'student', 'teacher', 'accessibility', 'ultra'")
text = text.replace("'pro'", "'student'")
text = text.replace("'educator'", "'teacher'")
text = text.replace('"pro"', '"student"')
text = text.replace('"educator"', '"teacher"')

# Replace price resolver function if present.
pattern = r"def _get_price_id\(plan: str\) -> str:\n(?:    .+\n)+?\n(?=@router|async def|def |\Z)"
replacement = '''def _get_price_id(plan: str) -> str:
    price_map = {
        "student": os.getenv("STRIPE_STUDENT_PRICE_ID", ""),
        "teacher": os.getenv("STRIPE_TEACHER_PRICE_ID", ""),
        "accessibility": os.getenv("STRIPE_ACCESSIBILITY_PRICE_ID", ""),
        "ultra": os.getenv("STRIPE_ULTRA_PRICE_ID", ""),
    }

    price_id = price_map.get(plan)

    if not price_id:
        raise HTTPException(
            status_code=400,
            detail=f"El plan {plan} no tiene Price ID configurado en Stripe.",
        )

    return price_id

'''
new_text, count = re.subn(pattern, replacement, text, flags=re.MULTILINE)
if count:
    text = new_text

billing_file.write_text(text)

# -------------------------
# Backend: usage_limit_service.py
# -------------------------
usage_file = backend / "app/services/usage_limit_service.py"
text = usage_file.read_text()

text = text.replace('"pro"', '"student"')
text = text.replace('"educator"', '"teacher"')
text = text.replace("'pro'", "'student'")
text = text.replace("'educator'", "'teacher'")

# Replace known plan limit dictionaries safely.
replacements = {
    "PLAN_UPLOAD_LIMITS": '''PLAN_UPLOAD_LIMITS = {
    "free": 3,
    "student": 25,
    "teacher": 100,
    "accessibility": 15,
    "ultra": 999999,
}''',
    "PLAN_CHAT_LIMITS": '''PLAN_CHAT_LIMITS = {
    "free": 30,
    "student": 300,
    "teacher": 1000,
    "accessibility": 200,
    "ultra": 999999,
}''',
    "PLAN_FLASHCARD_LIMITS": '''PLAN_FLASHCARD_LIMITS = {
    "free": 20,
    "student": 200,
    "teacher": 1000,
    "accessibility": 100,
    "ultra": 999999,
}''',
    "PLAN_EXAM_LIMITS": '''PLAN_EXAM_LIMITS = {
    "free": 10,
    "student": 100,
    "teacher": 300,
    "accessibility": 80,
    "ultra": 999999,
}''',
}

for name, value in replacements.items():
    pattern = rf"{name}\s*=\s*\{{.*?\n\}}"
    text, count = re.subn(pattern, value, text, flags=re.DOTALL)
    if count == 0:
        print(f"AVISO: no se encontró {name}; se mantiene lógica existente.")

usage_file.write_text(text)

# -------------------------
# Flutter: app_plans.dart
# -------------------------
app_plans = flutter / "lib/config/app_plans.dart"
app_plans.write_text(r'''enum CampusPlan {
  free,
  student,
  teacher,
  accessibility,
  ultra,
}

class PlanLimits {
  const PlanLimits({
    required this.maxPdfUploadsPerDay,
    required this.maxChatsPerDay,
    required this.maxFlashcardsPerPdf,
    required this.maxExamQuestionsPerPdf,
    required this.maxAudioMinutesPerMonth,
    required this.canExportPdf,
    required this.canExportDocx,
    required this.canExportPptx,
    required this.canUseAdvancedAnalytics,
    required this.canUseEducatorTools,
    required this.canUseVoiceOnboarding,
    required this.canUseQuestionBank,
    required this.canUseTeachingPlan,
    required this.canUseGradebook,
    required this.canUseCertificates,
    required this.canUseAcademicBadges,
    required this.canUseTranscriptPremium,
  });

  final int maxPdfUploadsPerDay;
  final int maxChatsPerDay;
  final int maxFlashcardsPerPdf;
  final int maxExamQuestionsPerPdf;
  final int maxAudioMinutesPerMonth;

  final bool canExportPdf;
  final bool canExportDocx;
  final bool canExportPptx;
  final bool canUseAdvancedAnalytics;
  final bool canUseEducatorTools;
  final bool canUseVoiceOnboarding;
  final bool canUseQuestionBank;
  final bool canUseTeachingPlan;
  final bool canUseGradebook;
  final bool canUseCertificates;
  final bool canUseAcademicBadges;
  final bool canUseTranscriptPremium;
}

class AppPlans {
  const AppPlans._();

  static const Map<CampusPlan, String> planNames = {
    CampusPlan.free: 'Free',
    CampusPlan.student: 'Student',
    CampusPlan.teacher: 'Teacher',
    CampusPlan.accessibility: 'Accessibility',
    CampusPlan.ultra: 'Ultra Premium',
  };

  static const Map<CampusPlan, String> planPrices = {
    CampusPlan.free: r'US$0',
    CampusPlan.student: r'US$6.99',
    CampusPlan.accessibility: r'US$3.99',
    CampusPlan.teacher: r'US$13.99',
    CampusPlan.ultra: r'US$24.99',
  };

  static const Map<CampusPlan, PlanLimits> limits = {
    CampusPlan.free: PlanLimits(
      maxPdfUploadsPerDay: 3,
      maxChatsPerDay: 30,
      maxFlashcardsPerPdf: 20,
      maxExamQuestionsPerPdf: 10,
      maxAudioMinutesPerMonth: 5,
      canExportPdf: true,
      canExportDocx: false,
      canExportPptx: false,
      canUseAdvancedAnalytics: false,
      canUseEducatorTools: false,
      canUseVoiceOnboarding: false,
      canUseQuestionBank: false,
      canUseTeachingPlan: false,
      canUseGradebook: false,
      canUseCertificates: false,
      canUseAcademicBadges: false,
      canUseTranscriptPremium: false,
    ),
    CampusPlan.student: PlanLimits(
      maxPdfUploadsPerDay: 25,
      maxChatsPerDay: 300,
      maxFlashcardsPerPdf: 200,
      maxExamQuestionsPerPdf: 100,
      maxAudioMinutesPerMonth: 60,
      canExportPdf: true,
      canExportDocx: true,
      canExportPptx: false,
      canUseAdvancedAnalytics: false,
      canUseEducatorTools: false,
      canUseVoiceOnboarding: true,
      canUseQuestionBank: true,
      canUseTeachingPlan: false,
      canUseGradebook: false,
      canUseCertificates: false,
      canUseAcademicBadges: false,
      canUseTranscriptPremium: false,
    ),
    CampusPlan.accessibility: PlanLimits(
      maxPdfUploadsPerDay: 15,
      maxChatsPerDay: 200,
      maxFlashcardsPerPdf: 100,
      maxExamQuestionsPerPdf: 80,
      maxAudioMinutesPerMonth: 120,
      canExportPdf: true,
      canExportDocx: true,
      canExportPptx: false,
      canUseAdvancedAnalytics: false,
      canUseEducatorTools: false,
      canUseVoiceOnboarding: true,
      canUseQuestionBank: true,
      canUseTeachingPlan: false,
      canUseGradebook: false,
      canUseCertificates: true,
      canUseAcademicBadges: true,
      canUseTranscriptPremium: false,
    ),
    CampusPlan.teacher: PlanLimits(
      maxPdfUploadsPerDay: 100,
      maxChatsPerDay: 1000,
      maxFlashcardsPerPdf: 1000,
      maxExamQuestionsPerPdf: 300,
      maxAudioMinutesPerMonth: 300,
      canExportPdf: true,
      canExportDocx: true,
      canExportPptx: true,
      canUseAdvancedAnalytics: true,
      canUseEducatorTools: true,
      canUseVoiceOnboarding: true,
      canUseQuestionBank: true,
      canUseTeachingPlan: true,
      canUseGradebook: true,
      canUseCertificates: true,
      canUseAcademicBadges: true,
      canUseTranscriptPremium: true,
    ),
    CampusPlan.ultra: PlanLimits(
      maxPdfUploadsPerDay: 999999,
      maxChatsPerDay: 999999,
      maxFlashcardsPerPdf: 999999,
      maxExamQuestionsPerPdf: 999999,
      maxAudioMinutesPerMonth: 999999,
      canExportPdf: true,
      canExportDocx: true,
      canExportPptx: true,
      canUseAdvancedAnalytics: true,
      canUseEducatorTools: true,
      canUseVoiceOnboarding: true,
      canUseQuestionBank: true,
      canUseTeachingPlan: true,
      canUseGradebook: true,
      canUseCertificates: true,
      canUseAcademicBadges: true,
      canUseTranscriptPremium: true,
    ),
  };
}
''')

# -------------------------
# Flutter: billing_service.dart
# -------------------------
billing_service = flutter / "lib/services/billing_service.dart"
billing_service.write_text(r'''import 'dart:convert';
import 'dart:html' as html;

import 'package:http/http.dart' as http;

import '../config/app_plans.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'plan_guard_service.dart';

class BillingService {
  const BillingService();

  Future<void> startCheckout(CampusPlan plan) async {
    final planCode = planCodeFromCampusPlan(plan);

    if (plan == CampusPlan.free) {
      throw Exception('El plan Free no requiere checkout.');
    }

    if (!AuthService.isLoggedIn) {
      throw Exception('Debes iniciar sesión para actualizar tu plan.');
    }

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/billing/create-checkout-session'),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders,
      },
      body: jsonEncode({
        'plan': planCode,
      }),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      final detail = decoded is Map<String, dynamic>
          ? decoded['detail']?.toString()
          : null;

      throw Exception(detail ?? 'No se pudo iniciar el checkout.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Respuesta inválida del servidor.');
    }

    final checkoutUrl = decoded['checkout_url']?.toString();

    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      throw Exception('El servidor no devolvió la URL de checkout.');
    }

    html.window.location.href = checkoutUrl;
  }

  Future<void> openCustomerPortal() async {
    if (!AuthService.isLoggedIn) {
      throw Exception('Debes iniciar sesión para administrar tu suscripción.');
    }

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/billing/create-customer-portal-session'),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders,
      },
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      final detail = decoded is Map<String, dynamic>
          ? decoded['detail']?.toString()
          : null;

      throw Exception(detail ?? 'No se pudo abrir el portal de cliente.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Respuesta inválida del servidor.');
    }

    final portalUrl = decoded['portal_url']?.toString();

    if (portalUrl == null || portalUrl.isEmpty) {
      throw Exception('El servidor no devolvió la URL del portal.');
    }

    html.window.location.href = portalUrl;
  }
}
''')

# -------------------------
# Flutter: plan_guard_service.dart
# -------------------------
plan_guard = flutter / "lib/services/plan_guard_service.dart"
plan_guard.write_text(r'''import 'dart:html' as html;

import '../config/app_plans.dart';

class PlanGuardService {
  const PlanGuardService();

  static const String _planStorageKey = 'studybook_ai_current_plan';
  static const String _planSourceStorageKey = 'studybook_ai_plan_source';
  static const String _subscriptionStatusStorageKey =
      'studybook_ai_subscription_status';

  CampusPlan get currentPlan {
    final storedPlan = html.window.localStorage[_planStorageKey];
    return planFromCode(storedPlan);
  }

  String get currentPlanSource {
    return html.window.localStorage[_planSourceStorageKey] ?? 'local';
  }

  String get currentSubscriptionStatus {
    return html.window.localStorage[_subscriptionStatusStorageKey] ?? 'free';
  }

  bool get isSyncedFromSupabase {
    return currentPlanSource == 'supabase';
  }

  PlanLimits get limits => AppPlans.limits[currentPlan]!;

  bool get canExportPdf => limits.canExportPdf;
  bool get canExportDocx => limits.canExportDocx;
  bool get canExportPptx => limits.canExportPptx;
  bool get canUseAdvancedAnalytics => limits.canUseAdvancedAnalytics;
  bool get canUseEducatorTools => limits.canUseEducatorTools;
  bool get canUseVoiceOnboarding => limits.canUseVoiceOnboarding;
  bool get canUseQuestionBank => limits.canUseQuestionBank;
  bool get canUseTeachingPlan => limits.canUseTeachingPlan;
  bool get canUseGradebook => limits.canUseGradebook;
  bool get canUseCertificates => limits.canUseCertificates;
  bool get canUseAcademicBadges => limits.canUseAcademicBadges;
  bool get canUseTranscriptPremium => limits.canUseTranscriptPremium;

  String get currentPlanName => AppPlans.planNames[currentPlan]!;

  void saveCurrentPlan(
    CampusPlan plan, {
    String source = 'local_test',
    String subscriptionStatus = 'active',
  }) {
    html.window.localStorage[_planStorageKey] = planCodeFromCampusPlan(plan);
    html.window.localStorage[_planSourceStorageKey] = source;
    html.window.localStorage[_subscriptionStatusStorageKey] =
        subscriptionStatus;
  }

  void resetToFree() {
    html.window.localStorage[_planStorageKey] =
        planCodeFromCampusPlan(CampusPlan.free);
    html.window.localStorage[_planSourceStorageKey] = 'local';
    html.window.localStorage[_subscriptionStatusStorageKey] = 'free';
  }

  bool canGenerateFlashcards(int requestedAmount) {
    return requestedAmount <= limits.maxFlashcardsPerPdf;
  }

  bool canGenerateExamQuestions(int requestedAmount) {
    return requestedAmount <= limits.maxExamQuestionsPerPdf;
  }

  String upgradeMessage(String featureName) {
    return 'La función "$featureName" requiere actualizar tu plan.';
  }

  String limitMessage({
    required String featureName,
    required int requested,
    required int allowed,
  }) {
    return 'Tu plan actual permite $allowed en "$featureName". Solicitaste $requested.';
  }
}

CampusPlan planFromCode(String? value) {
  return switch (value) {
    'student' => CampusPlan.student,
    'teacher' => CampusPlan.teacher,
    'accessibility' => CampusPlan.accessibility,
    'ultra' => CampusPlan.ultra,
    'pro' => CampusPlan.student,
    'educator' => CampusPlan.teacher,
    _ => CampusPlan.free,
  };
}

String planCodeFromCampusPlan(CampusPlan plan) {
  return switch (plan) {
    CampusPlan.free => 'free',
    CampusPlan.student => 'student',
    CampusPlan.teacher => 'teacher',
    CampusPlan.accessibility => 'accessibility',
    CampusPlan.ultra => 'ultra',
  };
}

String planCode(CampusPlan plan) => planCodeFromCampusPlan(plan);
''')

# -------------------------
# Flutter: plans_screen.dart
# Replace only plan data section references if simple replacement is possible.
# -------------------------
plans_screen = flutter / "lib/screens/plans_screen.dart"
text = plans_screen.read_text()

text = text.replace("CampusPlan.pro", "CampusPlan.student")
text = text.replace("CampusPlan.educator", "CampusPlan.teacher")
text = text.replace("name: 'Pro'", "name: 'Student'")
text = text.replace("name: 'Educator'", "name: 'Teacher'")
text = text.replace("price: 'RD\\$599'", "price: 'US\\$6.99'")
text = text.replace("price: 'RD\\$1,199'", "price: 'US\\$13.99'")
text = text.replace("price: 'RD\\$0'", "price: 'US\\$0'")
text = text.replace("badge: 'DOCENTES'", "badge: 'DOCENTES'")
text = text.replace("Para estudiar y producir más", "Para estudiantes intensivos")
text = text.replace("Para docentes e instituciones", "Para docentes y aulas")

plans_screen.write_text(text)

PY

echo "Migración base aplicada."

echo ""
echo "===== REVISANDO REFERENCIAS ANTIGUAS ====="
cd "$ROOT"
grep -R "CampusPlan.pro\|CampusPlan.educator\|'pro'\|'educator'\|\"pro\"\|\"educator\"" backend/app mobile/campusai_mobile/lib -n || true

echo ""
echo "===== BACKEND COMPILE ====="
cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

echo ""
echo "===== FLUTTER ANALYZE ====="
cd "$FLUTTER"
flutter analyze

echo ""
echo "===== GIT STATUS ====="
cd "$ROOT"
git status --short

echo ""
echo "===== DONE ====="
echo "Backups en: $ROOT/backups/billing_$STAMP"
