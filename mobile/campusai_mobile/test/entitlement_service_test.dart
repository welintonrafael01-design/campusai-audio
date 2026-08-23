import 'package:campusai_mobile/config/app_plans.dart';
import 'package:campusai_mobile/services/entitlement_service.dart';
import 'package:campusai_mobile/services/local_storage_service.dart';
import 'package:campusai_mobile/services/plan_guard_service.dart';
import 'package:campusai_mobile/services/security/user_scoped_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('role and plan capabilities', () {
    test('Teacher tools require both Teacher role and Teacher-capable plan',
        () {
      const studentWithTeacherPlan = EntitlementService(
        role: StudyBookRole.student,
        plan: CampusPlan.teacher,
      );
      const teacherWithStudentPlan = EntitlementService(
        role: StudyBookRole.teacher,
        plan: CampusPlan.student,
      );
      const teacher = EntitlementService(
        role: StudyBookRole.teacher,
        plan: CampusPlan.teacher,
      );

      expect(
        studentWithTeacherPlan.can(ProductCapability.teacherWorkspace),
        isFalse,
      );
      expect(
        teacherWithStudentPlan.can(ProductCapability.teacherWorkspace),
        isFalse,
      );
      expect(teacher.can(ProductCapability.teacherWorkspace), isTrue);
    });

    test('Ultra never turns a Student role into Teacher', () {
      const entitlements = EntitlementService(
        role: StudyBookRole.student,
        plan: CampusPlan.ultra,
      );

      expect(entitlements.can(ProductCapability.teacherWorkspace), isFalse);
      expect(entitlements.can(ProductCapability.questionBank), isTrue);
    });
  });

  group('plan cache isolation', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LocalStorageService.initialize();
      UserScopedStorage.debugSetUserScopeForTesting('student-a');
    });

    tearDown(() {
      UserScopedStorage.debugSetUserScopeForTesting(null);
    });

    test('a cached plan is visible only to its owner scope', () async {
      const guard = PlanGuardService();
      guard.saveCurrentPlan(
        CampusPlan.teacher,
        source: 'supabase',
      );
      await Future<void>.delayed(Duration.zero);

      expect(guard.currentPlan, CampusPlan.teacher);

      UserScopedStorage.debugSetUserScopeForTesting('student-b');

      expect(guard.currentPlan, CampusPlan.free);
      expect(guard.currentPlanSource, 'local');
      expect(guard.currentSubscriptionStatus, 'free');
    });
  });
}
