import '../config/app_plans.dart';

enum StudyBookRole {
  student,
  teacher,
  admin,
}

enum ProductCapability {
  exportPdf,
  exportDocx,
  exportPptx,
  advancedAnalytics,
  voiceExperience,
  questionBank,
  teacherWorkspace,
  teachingPlan,
  gradebook,
  certificates,
  academicBadges,
  premiumTranscript,
  adminConsole,
}

/// Resolves product access from two independent inputs: server role and plan.
///
/// This service is a client-side UX guard. Sensitive operations must continue
/// to enforce authentication, role, plan, and ownership in FastAPI.
class EntitlementService {
  const EntitlementService({
    required this.role,
    required this.plan,
  });

  final StudyBookRole role;
  final CampusPlan plan;

  PlanLimits get limits => AppPlans.limits[plan]!;

  bool get isTeacherRole =>
      role == StudyBookRole.teacher || role == StudyBookRole.admin;

  bool get isAdminRole => role == StudyBookRole.admin;

  bool can(ProductCapability capability) {
    return switch (capability) {
      ProductCapability.exportPdf => limits.canExportPdf,
      ProductCapability.exportDocx => limits.canExportDocx,
      ProductCapability.exportPptx => limits.canExportPptx,
      ProductCapability.advancedAnalytics => limits.canUseAdvancedAnalytics,
      ProductCapability.voiceExperience => limits.canUseVoiceOnboarding,
      ProductCapability.questionBank => limits.canUseQuestionBank,
      ProductCapability.teacherWorkspace =>
        isAdminRole || (isTeacherRole && limits.canUseEducatorTools),
      ProductCapability.teachingPlan =>
        isAdminRole || (isTeacherRole && limits.canUseTeachingPlan),
      ProductCapability.gradebook =>
        isAdminRole || (isTeacherRole && limits.canUseGradebook),
      ProductCapability.certificates => limits.canUseCertificates,
      ProductCapability.academicBadges => limits.canUseAcademicBadges,
      ProductCapability.premiumTranscript => limits.canUseTranscriptPremium,
      ProductCapability.adminConsole => isAdminRole,
    };
  }
}
