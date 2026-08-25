enum CampusPlan {
  free,
  student,
  teacher,
  institution,
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
  int get maxChatMessagesPerDay => maxChatsPerDay;
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
    CampusPlan.student: 'Student Pro',
    CampusPlan.teacher: 'Teacher Pro',
    CampusPlan.institution: 'Institution',
    CampusPlan.accessibility: 'Student Pro · Accesibilidad',
    CampusPlan.ultra: 'Student Pro · Legacy Ultra',
  };

  static const Map<CampusPlan, String> planPrices = {
    CampusPlan.free: r'US$0',
    CampusPlan.student: r'US$4.99',
    CampusPlan.accessibility: r'US$3.99',
    CampusPlan.teacher: r'US$9.99',
    CampusPlan.ultra: r'US$24.99',
    CampusPlan.institution: '',
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
    CampusPlan.institution: PlanLimits(
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
      canUseEducatorTools: false,
      canUseVoiceOnboarding: true,
      canUseQuestionBank: true,
      canUseTeachingPlan: false,
      canUseGradebook: false,
      canUseCertificates: true,
      canUseAcademicBadges: true,
      canUseTranscriptPremium: true,
    ),
  };

  static CampusPlan canonicalPlan(CampusPlan plan) {
    return switch (plan) {
      CampusPlan.accessibility || CampusPlan.ultra => CampusPlan.student,
      _ => plan,
    };
  }

  static bool subscriptionAllowsPaidCapabilities(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized == 'active' || normalized == 'trialing';
  }

  static CampusPlan effectivePlan(
    CampusPlan plan,
    String subscriptionStatus,
  ) {
    if (canonicalPlan(plan) == CampusPlan.free) return CampusPlan.free;
    return subscriptionAllowsPaidCapabilities(subscriptionStatus)
        ? plan
        : CampusPlan.free;
  }
}
