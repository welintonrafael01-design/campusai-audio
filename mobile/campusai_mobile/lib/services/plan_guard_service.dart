import 'dart:html' as html;

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
