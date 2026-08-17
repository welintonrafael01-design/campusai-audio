import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_test_config.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AI TOOLS journey requires document fixture and QA backend',
      (tester) async {
    if (!E2eTestConfig.hasStudentA) {
      markTestSkipped(
        'BLOCKED_EXTERNAL_CONFIG: CHAT, SUMMARY, FLASHCARDS, QUIZ, QUESTION '
        'BANK and EXAM need a logged-in QA student, uploaded fixture document '
        'and QA backend AI configuration.',
      );
      return;
    }

    markTestSkipped(
        'AUTOMATION_GAP: full AI tools path requires uploaded fixture and backend AI execution harness.');
    return;
  });
}
