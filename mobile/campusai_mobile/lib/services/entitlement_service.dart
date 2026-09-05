import '../config/app_plans.dart';

enum StudyBookRole {
  student,
  teacher,
  admin,
}

enum ProductCapability {
  library,
  documentUpload,
  chat,
  summary,
  audioBook,
  voiceTutor,
  flashcards,
  quiz,
  examGeneration,
  exportPdf,
  exportDocx,
  exportPptx,
  advancedAnalytics,
  voiceExperience,
  questionBank,
  cloudRestore,
  teacherWorkspace,
  manageCourses,
  manageStudents,
  manageAttendance,
  manageGrades,
  manageWeights,
  teachingPlan,
  rubrics,
  teacherExams,
  finalReport,
  gradebook,
  certificates,
  academicBadges,
  premiumTranscript,
  accessibilityExperience,
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
    this.subscriptionStatus = 'active',
  });

  final StudyBookRole role;
  final CampusPlan plan;
  final String subscriptionStatus;

  CampusPlan get effectivePlan => AppPlans.effectivePlan(
        plan,
        subscriptionStatus,
      );

  CampusPlan get canonicalPlan => AppPlans.canonicalPlan(effectivePlan);

  PlanLimits get limits => AppPlans.limits[effectivePlan]!;

  bool get isTeacherRole =>
      role == StudyBookRole.teacher || role == StudyBookRole.admin;

  bool get isAdminRole => role == StudyBookRole.admin;

  bool get hasPaidStudentCapabilities =>
      canonicalPlan == CampusPlan.student ||
      canonicalPlan == CampusPlan.teacher ||
      canonicalPlan == CampusPlan.institution;

  bool get hasTeacherPlan =>
      canonicalPlan == CampusPlan.teacher ||
      canonicalPlan == CampusPlan.institution;

  bool get hasLegacyUltraCapabilities => effectivePlan == CampusPlan.ultra;

  bool get hasAccessibilityCapabilities =>
      effectivePlan == CampusPlan.accessibility;

  bool can(ProductCapability capability) {
    if (isAdminRole) return true;

    return switch (capability) {
      ProductCapability.library ||
      ProductCapability.documentUpload ||
      ProductCapability.chat ||
      ProductCapability.summary ||
      ProductCapability.flashcards ||
      ProductCapability.quiz ||
      ProductCapability.cloudRestore =>
        true,
      ProductCapability.audioBook ||
      ProductCapability.voiceTutor ||
      ProductCapability.voiceExperience ||
      ProductCapability.examGeneration ||
      ProductCapability.questionBank =>
        hasPaidStudentCapabilities,
      ProductCapability.exportPdf => limits.canExportPdf,
      ProductCapability.exportDocx => limits.canExportDocx,
      ProductCapability.exportPptx => limits.canExportPptx,
      ProductCapability.advancedAnalytics => limits.canUseAdvancedAnalytics,
      ProductCapability.teacherWorkspace => isTeacherRole && hasTeacherPlan,
      ProductCapability.manageCourses ||
      ProductCapability.manageStudents ||
      ProductCapability.manageAttendance ||
      ProductCapability.manageGrades ||
      ProductCapability.manageWeights ||
      ProductCapability.rubrics ||
      ProductCapability.teacherExams ||
      ProductCapability.finalReport =>
        isTeacherRole && hasTeacherPlan,
      ProductCapability.teachingPlan =>
        isTeacherRole && hasTeacherPlan && limits.canUseTeachingPlan,
      ProductCapability.gradebook =>
        isTeacherRole && hasTeacherPlan && limits.canUseGradebook,
      ProductCapability.certificates => limits.canUseCertificates,
      ProductCapability.academicBadges => limits.canUseAcademicBadges,
      ProductCapability.premiumTranscript => limits.canUseTranscriptPremium,
      ProductCapability.accessibilityExperience => hasAccessibilityCapabilities,
      ProductCapability.adminConsole => false,
    };
  }

  String unavailableMessage(
    ProductCapability capability, {
    String? featureName,
  }) {
    final feature = featureName ?? _featureName(capability);
    if (_teacherCapabilities.contains(capability) && !isTeacherRole) {
      return '$feature requiere una cuenta docente autorizada.';
    }
    if (_teacherCapabilities.contains(capability)) {
      return '$feature está disponible con Teacher Pro.';
    }
    return '$feature está disponible con Student Pro.';
  }

  static const Set<ProductCapability> _teacherCapabilities = {
    ProductCapability.teacherWorkspace,
    ProductCapability.manageCourses,
    ProductCapability.manageStudents,
    ProductCapability.manageAttendance,
    ProductCapability.manageGrades,
    ProductCapability.manageWeights,
    ProductCapability.teachingPlan,
    ProductCapability.rubrics,
    ProductCapability.teacherExams,
    ProductCapability.finalReport,
    ProductCapability.gradebook,
  };

  String _featureName(ProductCapability capability) {
    return switch (capability) {
      ProductCapability.audioBook => 'AudioBook',
      ProductCapability.voiceTutor => 'Voice Tutor',
      ProductCapability.questionBank => 'El Banco de preguntas',
      ProductCapability.teacherWorkspace => 'Teacher Studio',
      ProductCapability.teachingPlan => 'La planificación docente',
      ProductCapability.rubrics => 'Las rúbricas',
      ProductCapability.gradebook => 'El Libro de calificaciones',
      _ => 'Esta función',
    };
  }
}
