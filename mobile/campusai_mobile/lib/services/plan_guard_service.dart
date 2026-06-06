import 'dart:html' as html;

import '../config/app_plans.dart';

class PlanGuardService {
  const PlanGuardService();

  static const String _storageKey = 'studybook_ai_current_plan';

  CampusPlan get currentPlan {
    final storedPlan = html.window.localStorage[_storageKey];

    return planFromCode(storedPlan);
  }

  PlanLimits get limits => AppPlans.limits[currentPlan]!;

  bool get canExportPdf => limits.canExportPdf;
  bool get canExportDocx => limits.canExportDocx;
  bool get canExportPptx => limits.canExportPptx;
  bool get canUseAdvancedAnalytics => limits.canUseAdvancedAnalytics;
  bool get canUseEducatorTools => limits.canUseEducatorTools;
  bool get canUseVoiceOnboarding => limits.canUseVoiceOnboarding;

  String get currentPlanName => AppPlans.planNames[currentPlan]!;

  void saveCurrentPlan(CampusPlan plan) {
    html.window.localStorage[_storageKey] = planCode(plan);
  }

  void resetToFree() {
    html.window.localStorage[_storageKey] = planCode(CampusPlan.free);
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
    'pro' => CampusPlan.pro,
    'educator' => CampusPlan.educator,
    _ => CampusPlan.free,
  };
}

String planCode(CampusPlan plan) {
  return switch (plan) {
    CampusPlan.free => 'free',
    CampusPlan.pro => 'pro',
    CampusPlan.educator => 'educator',
  };
}
