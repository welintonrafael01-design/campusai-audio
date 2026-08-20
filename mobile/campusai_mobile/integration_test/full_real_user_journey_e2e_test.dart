import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_test_config.dart';
import 'full_real_e2e_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'FULL REAL USER JOURNEY uses real auth backend cloud and ownership',
    (tester) async {
      final teacherDiagnostic = E2eTestConfig.journeyScope == 'teacher';
      final configurationReady = teacherDiagnostic
          ? E2eTestConfig.hasTeacher
          : E2eTestConfig.hasStudentA &&
              E2eTestConfig.hasStudentB &&
              E2eTestConfig.hasTeacher;
      if (!configurationReady) {
        markTestSkipped(
          'BLOCKED_EXTERNAL_CONFIG: required local QA identities are missing.',
        );
        return;
      }

      final journey = FullRealE2eJourney(tester);
      if (teacherDiagnostic) {
        await journey.runTeacherDiagnostic();
      } else {
        await journey.run();
      }

      if (journey.blockedExternalConfig.isNotEmpty) {
        markTestSkipped(
          'BLOCKED_EXTERNAL_CONFIG: ${journey.blockedExternalConfig.join(', ')}',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
}
