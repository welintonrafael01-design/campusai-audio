import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_test_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TEACHER journey requires QA teacher account', (tester) async {
    if (!E2eTestConfig.hasTeacher) {
      markTestSkipped(
        'BLOCKED_EXTERNAL_CONFIG: TEACHER journey needs QA_TEACHER_EMAIL and '
        'QA_TEACHER_PASSWORD with teacher entitlement.',
      );
      return;
    }

    markTestSkipped(
        'AUTOMATION_GAP: full Teacher Studio path requires course/roster fixture harness.');
    return;
  });
}
