import '../config/app_plans.dart';
import 'local_storage_service.dart';
import 'security/user_scoped_storage.dart';

class PlanGuardService {
  const PlanGuardService();

  static const String _planStorageKey = 'studybook_ai_current_plan';
  static const String _planSourceStorageKey = 'studybook_ai_plan_source';
  static const String _subscriptionStatusStorageKey =
      'studybook_ai_subscription_status';
  static const String _planOwnerStorageKey = 'studybook_ai_plan_owner';
  static const String _serverRoleStorageKey = 'studybook_ai_server_role';

  String? _storedValue(String key) {
    try {
      return LocalStorageService.getString(key);
    } catch (_) {
      return null;
    }
  }

  bool get _belongsToCurrentUser {
    final owner = _storedValue(_planOwnerStorageKey);
    return owner != null && owner == UserScopedStorage.currentUserScope;
  }

  CampusPlan get currentPlan {
    if (!_belongsToCurrentUser) return CampusPlan.free;
    final storedPlan = _storedValue(_planStorageKey);
    return planFromCode(storedPlan);
  }

  String get currentPlanSource {
    if (!_belongsToCurrentUser) return 'local';
    return _storedValue(_planSourceStorageKey) ?? 'local';
  }

  String get currentSubscriptionStatus {
    if (!_belongsToCurrentUser) return 'free';
    return _storedValue(_subscriptionStatusStorageKey) ?? 'free';
  }

  String get currentServerRole {
    if (!_belongsToCurrentUser) return '';
    return _storedValue(_serverRoleStorageKey)?.trim().toLowerCase() ?? '';
  }

  bool get isSyncedFromSupabase {
    return currentPlanSource == 'supabase';
  }

  CampusPlan get effectivePlan => AppPlans.effectivePlan(
        currentPlan,
        currentSubscriptionStatus,
      );

  PlanLimits get limits => AppPlans.limits[effectivePlan]!;

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
    String? serverRole,
  }) {
    LocalStorageService.setString(
      _planOwnerStorageKey,
      UserScopedStorage.currentUserScope,
    );
    LocalStorageService.setString(
      _planStorageKey,
      planCodeFromCampusPlan(plan),
    );
    LocalStorageService.setString(_planSourceStorageKey, source);
    LocalStorageService.setString(
      _subscriptionStatusStorageKey,
      subscriptionStatus,
    );
    final normalizedRole = serverRole?.trim().toLowerCase();
    if (normalizedRole != null && normalizedRole.isNotEmpty) {
      LocalStorageService.setString(_serverRoleStorageKey, normalizedRole);
    }
  }

  void resetToFree() {
    LocalStorageService.setString(
      _planOwnerStorageKey,
      UserScopedStorage.currentUserScope,
    );
    LocalStorageService.setString(
      _planStorageKey,
      planCodeFromCampusPlan(CampusPlan.free),
    );
    LocalStorageService.setString(_planSourceStorageKey, 'local');
    LocalStorageService.setString(
      _subscriptionStatusStorageKey,
      'free',
    );
    LocalStorageService.setString(_serverRoleStorageKey, 'student');
  }

  bool canGenerateFlashcards(int requestedAmount) {
    return requestedAmount <= limits.maxFlashcardsPerPdf;
  }

  bool canGenerateExamQuestions(int requestedAmount) {
    return requestedAmount <= limits.maxExamQuestionsPerPdf;
  }

  String upgradeMessage(String featureName) {
    return '$featureName está disponible con Student Pro.';
  }

  String limitMessage({
    required String featureName,
    required int requested,
    required int allowed,
  }) {
    return 'Tu plan actual permite $allowed en "$featureName". '
        'Solicitaste $requested.';
  }
}

CampusPlan planFromCode(String? value) {
  return switch (value) {
    'student' => CampusPlan.student,
    'teacher' => CampusPlan.teacher,
    'institution' => CampusPlan.institution,
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
    CampusPlan.institution => 'institution',
    CampusPlan.accessibility => 'accessibility',
    CampusPlan.ultra => 'ultra',
  };
}

String planCode(CampusPlan plan) => planCodeFromCampusPlan(plan);
