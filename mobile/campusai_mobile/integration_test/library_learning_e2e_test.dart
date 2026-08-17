import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_test_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('LIBRARY and LEARNING journeys require generated QA data',
      (tester) async {
    if (!E2eTestConfig.hasStudentA) {
      markTestSkipped(
        'BLOCKED_EXTERNAL_CONFIG: LIBRARY and LEARNING need a logged-in QA '
        'student plus fixture-generated documents, chats, flashcards, quizzes '
        'and audiobooks.',
      );
      return;
    }

    markTestSkipped(
        'AUTOMATION_GAP: full Library/Learning path requires generated fixture data assertions.');
    return;
  });
}
