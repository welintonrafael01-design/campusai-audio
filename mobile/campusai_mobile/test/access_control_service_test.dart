import 'package:campusai_mobile/config/app_plans.dart';
import 'package:campusai_mobile/services/access_control_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('server-controlled role metadata', () {
    test('appMetadata teacher resolves Teacher', () {
      expect(
        AccessControlService.resolveRole(
          appMetadata: const {'role': 'teacher'},
        ),
        StudyBookRole.teacher,
      );
    });

    test('userMetadata cannot elevate appMetadata student', () {
      expect(
        AccessControlService.resolveRole(
          appMetadata: const {'role': 'student'},
          userMetadata: const {'role': 'teacher'},
        ),
        StudyBookRole.student,
      );
    });

    test('userMetadata cannot downgrade appMetadata teacher', () {
      expect(
        AccessControlService.resolveRole(
          appMetadata: const {'role': 'teacher'},
          userMetadata: const {'role': 'student'},
        ),
        StudyBookRole.teacher,
      );
    });

    test('appMetadata admin alone is not Admin authority', () {
      expect(
        AccessControlService.resolveRole(
          appMetadata: const {'role': 'admin'},
          userMetadata: const {'role': 'student'},
        ),
        StudyBookRole.student,
      );
    });

    test('server verified Admin role resolves Admin', () {
      expect(
        AccessControlService.resolveRole(
          appMetadata: const {'role': 'student'},
          serverRole: 'admin',
        ),
        StudyBookRole.admin,
      );
    });

    test('missing app role falls back to Student', () {
      expect(
        AccessControlService.resolveRole(),
        StudyBookRole.student,
      );
    });

    test('userMetadata admin without app role is not Admin', () {
      expect(
        AccessControlService.resolveRole(
          userMetadata: const {'role': 'admin'},
        ),
        StudyBookRole.student,
      );
    });

    test('userMetadata teacher without app role is not Teacher', () {
      expect(
        AccessControlService.resolveRole(
          userMetadata: const {'role': 'teacher'},
        ),
        StudyBookRole.student,
      );
    });
  });

  group('route guard', () {
    test('Student is denied Teacher and Admin paths', () {
      const access = AccessControlService(
        authenticatedOverride: true,
        appMetadataOverride: {'role': 'student'},
        planOverride: CampusPlan.student,
      );

      expect(access.redirectForPath('/teacher'), '/dashboard');
      expect(access.redirectForPath('/admin'), '/dashboard');
    });

    test('Teacher with active cached Teacher plan can open Teacher path', () {
      const access = AccessControlService(
        authenticatedOverride: true,
        appMetadataOverride: {'role': 'teacher'},
        planOverride: CampusPlan.teacher,
      );

      expect(access.redirectForPath('/teacher'), isNull);
      expect(access.redirectForPath('/admin'), '/dashboard');
    });

    test('local Teacher plan cannot elevate a Student role', () {
      const access = AccessControlService(
        authenticatedOverride: true,
        appMetadataOverride: {'role': 'student'},
        planOverride: CampusPlan.teacher,
      );

      expect(access.redirectForPath('/teacher'), '/dashboard');
    });

    test('Guest is redirected to Auth for private paths', () {
      const access = AccessControlService(
        authenticatedOverride: false,
        appMetadataOverride: {},
        planOverride: CampusPlan.free,
      );

      expect(access.redirectForPath('/dashboard'), '/auth');
    });

    test('Free users are guided to plans for gated learning capabilities', () {
      const access = AccessControlService(
        authenticatedOverride: true,
        appMetadataOverride: {'role': 'student'},
        planOverride: CampusPlan.free,
      );

      expect(access.redirectForPath('/voice-tutor'), '/plans');
      expect(access.redirectForPath('/audiobook-studio'), '/plans');
      expect(access.redirectForPath('/question-bank/document-1'), '/plans');
    });

    test('Student plan can open voice and question bank', () {
      const access = AccessControlService(
        authenticatedOverride: true,
        appMetadataOverride: {'role': 'student'},
        planOverride: CampusPlan.student,
      );

      expect(access.redirectForPath('/voice-tutor'), isNull);
      expect(access.redirectForPath('/audiobook-studio'), isNull);
      expect(access.redirectForPath('/question-bank/document-1'), isNull);
    });

    test('pending checkout never grants paid capabilities', () {
      const access = AccessControlService(
        authenticatedOverride: true,
        appMetadataOverride: {'role': 'teacher'},
        planOverride: CampusPlan.teacher,
        subscriptionStatusOverride: 'pending',
      );

      expect(access.redirectForPath('/teacher'), '/dashboard');
      expect(access.redirectForPath('/voice-tutor'), '/plans');
      expect(access.redirectForPath('/audiobook-studio'), '/plans');
    });

    test('legacy Ultra never grants Teacher visibility', () {
      const access = AccessControlService(
        authenticatedOverride: true,
        appMetadataOverride: {'role': 'teacher'},
        planOverride: CampusPlan.ultra,
      );

      expect(access.redirectForPath('/teacher'), '/dashboard');
      expect(access.redirectForPath('/audiobook-studio'), isNull);
    });

    test('Institution Teacher can open Teacher Studio but Student cannot', () {
      const teacher = AccessControlService(
        authenticatedOverride: true,
        serverRoleOverride: 'teacher',
        planOverride: CampusPlan.institution,
      );
      const student = AccessControlService(
        authenticatedOverride: true,
        serverRoleOverride: 'student',
        planOverride: CampusPlan.institution,
      );

      expect(teacher.redirectForPath('/teacher'), isNull);
      expect(student.redirectForPath('/teacher'), '/dashboard');
    });
  });
}
