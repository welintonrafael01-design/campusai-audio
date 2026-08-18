import '../config/app_plans.dart';
import 'auth_service.dart';
import 'plan_guard_service.dart';

enum StudyBookRole {
  student,
  teacher,
  admin,
}

class AccessControlService {
  const AccessControlService({
    this.authenticatedOverride,
    this.appMetadataOverride,
    this.userMetadataOverride,
    this.planOverride,
  });

  final bool? authenticatedOverride;
  final Map<String, dynamic>? appMetadataOverride;
  final Map<String, dynamic>? userMetadataOverride;
  final CampusPlan? planOverride;

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

  bool get isAuthenticated => authenticatedOverride ?? AuthService.isLoggedIn;

  CampusPlan get legacyPlan =>
      planOverride ?? const PlanGuardService().currentPlan;

  static StudyBookRole resolveRole({
    Map<String, dynamic>? appMetadata,
    Map<String, dynamic>? userMetadata,
  }) {
    // userMetadata is intentionally ignored because users can edit it.
    final metadata = appMetadata ?? const <String, dynamic>{};

    final rawRole = (metadata['role'] ?? '').toString().trim().toLowerCase();

    if (rawRole == 'admin' || rawRole == 'institution_admin') {
      return StudyBookRole.admin;
    }

    if (rawRole == 'teacher' || rawRole == 'educator') {
      return StudyBookRole.teacher;
    }

    return StudyBookRole.student;
  }

  StudyBookRole get role {
    final user = AuthService.currentUser;
    return resolveRole(
      appMetadata: appMetadataOverride ?? user?.appMetadata,
      userMetadata: userMetadataOverride ?? user?.userMetadata,
    );
  }

  bool get isTeacher =>
      role == StudyBookRole.teacher || role == StudyBookRole.admin;

  bool get isAdmin => role == StudyBookRole.admin;

  bool get hasTeacherTools {
    if (isAdmin) return true;
    return isTeacher && AppPlans.limits[legacyPlan]!.canUseEducatorTools;
  }

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

    if (isAdminPath(path) && !isAdmin) {
      return '/dashboard';
    }

    if (isTeacherPath(path) && !hasTeacherTools) {
      return '/dashboard';
    }

    return null;
  }
}
