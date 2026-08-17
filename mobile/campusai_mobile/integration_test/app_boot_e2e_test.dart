import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'e2e_test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AUTH boot shows login surface and handles empty submit',
      (tester) async {
    await pumpStudyBookApp(tester);

    expect(find.text('StudyBook AI'), findsWidgets);
    expect(textAny(['Iniciar sesión', 'Entrar', 'Login']), findsWidgets);

    await tapFirstText(tester, ['Iniciar sesión', 'Entrar', 'Login']);

    expect(
      textAny([
        'Completa',
        'correo',
        'contraseña',
        'email',
      ]),
      findsWidgets,
    );
  });
}
