import 'package:campusai_mobile/config/app_plans.dart';
import 'package:campusai_mobile/services/entitlement_service.dart';
import 'package:campusai_mobile/services/local_storage_service.dart';
import 'package:campusai_mobile/services/plan_guard_service.dart';
import 'package:campusai_mobile/services/security/user_scoped_storage.dart';
import 'package:campusai_mobile/services/subscription_service.dart';
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

    test('Free keeps core study value and denies paid cost capabilities', () {
      const entitlements = EntitlementService(
        role: StudyBookRole.student,
        plan: CampusPlan.free,
        subscriptionStatus: 'free',
      );

      expect(entitlements.can(ProductCapability.library), isTrue);
      expect(entitlements.can(ProductCapability.chat), isTrue);
      expect(entitlements.can(ProductCapability.summary), isTrue);
      expect(entitlements.can(ProductCapability.flashcards), isTrue);
      expect(entitlements.can(ProductCapability.quiz), isTrue);
      expect(entitlements.can(ProductCapability.cloudRestore), isTrue);
      expect(entitlements.can(ProductCapability.audioBook), isFalse);
      expect(entitlements.can(ProductCapability.voiceTutor), isFalse);
      expect(entitlements.can(ProductCapability.questionBank), isFalse);
    });

    test('Student Pro enables learning capabilities without Teacher Studio',
        () {
      const entitlements = EntitlementService(
        role: StudyBookRole.student,
        plan: CampusPlan.student,
      );

      expect(entitlements.can(ProductCapability.audioBook), isTrue);
      expect(entitlements.can(ProductCapability.voiceTutor), isTrue);
      expect(entitlements.can(ProductCapability.cloudRestore), isTrue);
      expect(entitlements.can(ProductCapability.questionBank), isTrue);
      expect(entitlements.can(ProductCapability.teacherWorkspace), isFalse);
    });

    test('Institution enables Teacher Core only for Teacher role', () {
      const student = EntitlementService(
        role: StudyBookRole.student,
        plan: CampusPlan.institution,
      );
      const teacher = EntitlementService(
        role: StudyBookRole.teacher,
        plan: CampusPlan.institution,
      );

      expect(student.can(ProductCapability.teacherWorkspace), isFalse);
      expect(teacher.can(ProductCapability.teacherWorkspace), isTrue);
      expect(teacher.can(ProductCapability.manageCourses), isTrue);
      expect(teacher.can(ProductCapability.manageStudents), isTrue);
    });

    test('unknown paid subscription state fails closed', () {
      const entitlements = EntitlementService(
        role: StudyBookRole.teacher,
        plan: CampusPlan.teacher,
        subscriptionStatus: 'unexpected_state',
      );

      expect(entitlements.effectivePlan, CampusPlan.free);
      expect(entitlements.can(ProductCapability.audioBook), isFalse);
      expect(entitlements.can(ProductCapability.teacherWorkspace), isFalse);
      expect(entitlements.can(ProductCapability.chat), isTrue);
    });

    test('commercial labels hide internal aliases', () {
      expect(AppPlans.planNames[CampusPlan.student], 'Student Pro');
      expect(AppPlans.planNames[CampusPlan.teacher], 'Teacher Pro');
      expect(
        AppPlans.canonicalPlan(CampusPlan.accessibility),
        CampusPlan.student,
      );
      expect(AppPlans.canonicalPlan(CampusPlan.ultra), CampusPlan.student);
      expect(planFromCode('pro'), CampusPlan.student);
      expect(planFromCode('educator'), CampusPlan.teacher);
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
      expect(guard.currentServerRole, '');
    });

    test('server subscription context is replaced on user switch', () async {
      const service = SubscriptionService();
      const guard = PlanGuardService();

      service.cacheSubscriptionResponse({
        'plan': 'teacher',
        'subscription_status': 'active',
        'source': 'supabase',
        'role': 'teacher',
      });
      await Future<void>.delayed(Duration.zero);

      expect(guard.currentPlan, CampusPlan.teacher);
      expect(guard.currentServerRole, 'teacher');

      UserScopedStorage.debugSetUserScopeForTesting('student-b');

      expect(guard.currentPlan, CampusPlan.free);
      expect(guard.currentServerRole, '');

      service.cacheSubscriptionResponse({
        'plan': 'student',
        'subscription_status': 'active',
        'source': 'supabase',
        'role': 'student',
      });
      await Future<void>.delayed(Duration.zero);

      expect(guard.currentPlan, CampusPlan.student);
      expect(guard.currentServerRole, 'student');
      expect(guard.canUseEducatorTools, isFalse);
    });
  });
}
