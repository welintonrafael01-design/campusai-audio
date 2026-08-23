import 'package:campusai_mobile/l10n/app_localizations.dart';
import 'package:campusai_mobile/screens/exam_screen.dart';
import 'package:campusai_mobile/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.initialize();
  });

  testWidgets('practice mode is distinct and hides Teacher-only controls',
      (tester) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ExamScreen(
          documentId: 'doc-a',
          practiceMode: true,
          initialQuestions: [
            {
              'question': '¿Cuál es la respuesta correcta?',
              'options': ['A. Primera', 'B. Segunda'],
              'correct_answer': 'A',
            },
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quiz de práctica'), findsWidgets);
    expect(find.byTooltip('Clave docente PDF'), findsNothing);
    expect(find.byTooltip('Generar rúbrica desde examen'), findsNothing);
    expect(find.byTooltip('Crear versión B/C/D'), findsNothing);
    expect(find.text('Ver Libro de Calificaciones'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
