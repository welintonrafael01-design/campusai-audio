import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_test_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ACCOUNT logout/login restore requires QA student account',
      (tester) async {
    if (!E2eTestConfig.hasStudentA) {
      markTestSkipped(
        'BLOCKED_EXTERNAL_CONFIG: ACCOUNT and logout/login restore need QA '
        'student credentials and persisted fixture data.',
      );
      return;
    }

    markTestSkipped(
        'AUTOMATION_GAP: full Account/session restore path requires persisted fixture data.');
    return;
  });
}
