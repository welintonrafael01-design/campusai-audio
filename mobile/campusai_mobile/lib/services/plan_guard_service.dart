import '../config/app_plans.dart';

class PlanGuardService {
  const PlanGuardService();

  CampusPlan get currentPlan => AppPlans.currentPlan;

  PlanLimits get limits => AppPlans.currentLimits;

  bool get canExportPdf => limits.canExportPdf;
  bool get canExportDocx => limits.canExportDocx;
  bool get canExportPptx => limits.canExportPptx;
  bool get canUseAdvancedAnalytics => limits.canUseAdvancedAnalytics;
  bool get canUseEducatorTools => limits.canUseEducatorTools;
  bool get canUseVoiceOnboarding => limits.canUseVoiceOnboarding;

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
