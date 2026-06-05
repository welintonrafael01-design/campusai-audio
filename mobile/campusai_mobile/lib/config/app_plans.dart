enum CampusPlan {
  free,
  pro,
  educator,
}

class PlanLimits {
  final int maxPdfUploadsPerDay;
  final int maxChatMessagesPerDay;
  final int maxFlashcardsPerPdf;
  final int maxExamQuestionsPerPdf;
  final bool canExportPdf;
  final bool canExportDocx;
  final bool canExportPptx;
  final bool canUseAdvancedAnalytics;
  final bool canUseEducatorTools;
  final bool canUseVoiceOnboarding;

  const PlanLimits({
    required this.maxPdfUploadsPerDay,
    required this.maxChatMessagesPerDay,
    required this.maxFlashcardsPerPdf,
    required this.maxExamQuestionsPerPdf,
    required this.canExportPdf,
    required this.canExportDocx,
    required this.canExportPptx,
    required this.canUseAdvancedAnalytics,
    required this.canUseEducatorTools,
    required this.canUseVoiceOnboarding,
  });
}

class AppPlans {
  static const CampusPlan currentPlan = CampusPlan.free;

  static const Map<CampusPlan, String> planNames = {
    CampusPlan.free: 'Free',
    CampusPlan.pro: 'Pro',
    CampusPlan.educator: 'Educator',
  };

  static const Map<CampusPlan, PlanLimits> limits = {
    CampusPlan.free: PlanLimits(
      maxPdfUploadsPerDay: 3,
      maxChatMessagesPerDay: 25,
      maxFlashcardsPerPdf: 10,
      maxExamQuestionsPerPdf: 10,
      canExportPdf: true,
      canExportDocx: false,
      canExportPptx: false,
      canUseAdvancedAnalytics: false,
      canUseEducatorTools: false,
      canUseVoiceOnboarding: false,
    ),
    CampusPlan.pro: PlanLimits(
      maxPdfUploadsPerDay: 50,
      maxChatMessagesPerDay: 500,
      maxFlashcardsPerPdf: 50,
      maxExamQuestionsPerPdf: 50,
      canExportPdf: true,
      canExportDocx: true,
      canExportPptx: true,
      canUseAdvancedAnalytics: false,
      canUseEducatorTools: false,
      canUseVoiceOnboarding: true,
    ),
    CampusPlan.educator: PlanLimits(
      maxPdfUploadsPerDay: 200,
      maxChatMessagesPerDay: 2000,
      maxFlashcardsPerPdf: 100,
      maxExamQuestionsPerPdf: 100,
      canExportPdf: true,
      canExportDocx: true,
      canExportPptx: true,
      canUseAdvancedAnalytics: true,
      canUseEducatorTools: true,
      canUseVoiceOnboarding: true,
    ),
  };

  static PlanLimits get currentLimits => limits[currentPlan]!;

  static String get currentPlanName => planNames[currentPlan]!;
}
