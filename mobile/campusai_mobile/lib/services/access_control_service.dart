import '../config/app_plans.dart';
import 'auth_service.dart';
import 'entitlement_service.dart';
import 'plan_guard_service.dart';

export 'entitlement_service.dart'
    show EntitlementService, ProductCapability, StudyBookRole;

class AccessControlService {
  const AccessControlService({
    this.authenticatedOverride,
    this.appMetadataOverride,
    this.userMetadataOverride,
    this.planOverride,
    this.subscriptionStatusOverride,
    this.serverRoleOverride,
  });

  final bool? authenticatedOverride;
  final Map<String, dynamic>? appMetadataOverride;
  final Map<String, dynamic>? userMetadataOverride;
  final CampusPlan? planOverride;
  final String? subscriptionStatusOverride;
  final String? serverRoleOverride;

  static const Set<String> publicPaths = {
    '/auth',
    '/reset-password',
  };

  static const Set<String> teacherPaths = {
    '/teacher',
    '/courses',
    '/students',
    '/attendance',
    '/gradebook',
    '/assessment-weights',
    '/final-report',
    '/saved-exams',
    '/academic-dashboard',
    '/academic-recognition',
    '/student-profile',
    '/student-transcript',
    '/unit-workspace',
  };

  static const Set<String> adminPaths = {
    '/admin',
    '/admin/financial-dashboard',
  };

  static const Set<String> voicePaths = {
    '/voice-tutor',
  };

  static const Set<String> audioBookPaths = {
    '/audiobook-studio',
  };

  bool get isAuthenticated => authenticatedOverride ?? AuthService.isLoggedIn;

  CampusPlan get legacyPlan =>
      planOverride ?? const PlanGuardService().currentPlan;

  static StudyBookRole resolveRole({
    Map<String, dynamic>? appMetadata,
    Map<String, dynamic>? userMetadata,
    String? serverRole,
  }) {
    // userMetadata is intentionally ignored because users can edit it.
    final metadata = appMetadata ?? const <String, dynamic>{};

    final verifiedRole = serverRole?.trim().toLowerCase() ?? '';
    final rawRole = verifiedRole.isNotEmpty
        ? verifiedRole
        : (metadata['role'] ?? '').toString().trim().toLowerCase();

    if (verifiedRole == 'admin') {
      return StudyBookRole.admin;
    }

    if (rawRole == 'teacher' || rawRole == 'educator') {
      return StudyBookRole.teacher;
    }

    return StudyBookRole.student;
  }

  StudyBookRole get role {
    final user = AuthService.currentUser;
    final cachedServerRole = const PlanGuardService().currentServerRole;
    return resolveRole(
      appMetadata: appMetadataOverride ?? user?.appMetadata,
      userMetadata: userMetadataOverride ?? user?.userMetadata,
      serverRole: serverRoleOverride ?? cachedServerRole,
    );
  }

  bool get isTeacher =>
      role == StudyBookRole.teacher || role == StudyBookRole.admin;

  bool get isAdmin => role == StudyBookRole.admin;

  EntitlementService get entitlements => EntitlementService(
        role: role,
        plan: legacyPlan,
        subscriptionStatus: subscriptionStatusOverride ??
            (planOverride != null
                ? 'active'
                : const PlanGuardService().currentSubscriptionStatus),
      );

  bool get hasTeacherTools =>
      entitlements.can(ProductCapability.teacherWorkspace);

  bool isPublicPath(String path) {
    if (publicPaths.contains(path)) return true;
    return path.startsWith('/verify/');
  }

  bool isTeacherPath(String path) {
    if (teacherPaths.contains(path)) return true;
    return path.startsWith('/rubric/') || path.startsWith('/teaching-plan/');
  }

  bool isAdminPath(String path) {
    if (adminPaths.contains(path)) return true;
    return path.startsWith('/admin/');
  }

  String? redirectForPath(String path) {
    final public = isPublicPath(path);

    if (public) {
      if (path == '/auth' && isAuthenticated) {
        return '/dashboard';
      }

      return null;
    }

    if (!isAuthenticated) {
      return '/auth';
    }

    if (isAdminPath(path) &&
        !entitlements.can(ProductCapability.adminConsole)) {
      return '/dashboard';
    }

    if (isTeacherPath(path) && !hasTeacherTools) {
      return '/dashboard';
    }

    if (voicePaths.contains(path) &&
        !entitlements.can(ProductCapability.voiceTutor)) {
      return '/plans';
    }

    if (audioBookPaths.contains(path) &&
        !entitlements.can(ProductCapability.audioBook)) {
      return '/plans';
    }

    if (path.startsWith('/question-bank/') &&
        !entitlements.can(ProductCapability.questionBank)) {
      return '/plans';
    }

    return null;
  }
}
