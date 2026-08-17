import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('GUEST private routes stay on auth surface', (tester) async {
    await pumpStudyBookApp(tester);

    expect(find.text('StudyBook AI'), findsWidgets);
    expect(textAny(['Iniciar sesión', 'Entrar', 'Login']), findsWidgets);
  });
}
