import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_test_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HOME UPLOAD journey requires authenticated QA student',
      (tester) async {
    if (!E2eTestConfig.hasStudentA) {
      markTestSkipped(
        'BLOCKED_EXTERNAL_CONFIG: HOME/UPLOAD needs QA student credentials '
        'and fixture upload execution.',
      );
      return;
    }

    markTestSkipped(
        'AUTOMATION_GAP: full HOME/UPLOAD file-picker path still requires dedicated driver support.');
    return;
  });
}
