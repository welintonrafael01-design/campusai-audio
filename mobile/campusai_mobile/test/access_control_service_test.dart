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

    test('userMetadata cannot downgrade appMetadata admin', () {
      expect(
        AccessControlService.resolveRole(
          appMetadata: const {'role': 'admin'},
          userMetadata: const {'role': 'student'},
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
  });
}
