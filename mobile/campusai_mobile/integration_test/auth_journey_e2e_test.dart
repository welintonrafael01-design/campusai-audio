import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_test_config.dart';
import 'e2e_test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'USER A login journey reaches dashboard when QA credentials are provided',
    (tester) async {
      if (!E2eTestConfig.hasStudentA) {
        markTestSkipped(
          'BLOCKED_EXTERNAL_CONFIG: provide QA_STUDENT_A_EMAIL and '
          'QA_STUDENT_A_PASSWORD via dart-define.',
        );
        return;
      }

      await pumpStudyBookApp(tester);
      await enterAuthCredentials(
        tester,
        email: E2eTestConfig.studentAEmail,
        password: E2eTestConfig.studentAPassword,
      );
      await tapFirstText(tester, ['Iniciar sesión', 'Entrar', 'Login']);

      expect(
        textAny(['Dashboard', 'Continuar', 'Subir', 'Booky']),
        findsWidgets,
      );
    },
  );
}
