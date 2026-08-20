import 'package:campusai_mobile/widgets/dashboard/dashboard_tools.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DashboardTools buildTools() {
    return DashboardTools(
      isLoading: false,
      hasActiveDocument: true,
      openChat: () {},
      openSummary: () {},
      openAudiobook: () {},
      openVoiceTutor: () {},
      openFlashcards: () {},
      openQuiz: () {},
      openQuestionBank: () {},
      openExam: () {},
    );
  }

  testWidgets('DashboardTools shows the eight core AI tools once',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: buildTools(),
          ),
        ),
      ),
    );

    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Resumir'), findsOneWidget);
    expect(find.text('AudioBook'), findsOneWidget);
    expect(find.text('Voice Tutor'), findsOneWidget);
    expect(find.text('Flashcards'), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget);
    expect(find.text('Banco de preguntas'), findsOneWidget);
    expect(find.text('Generar examen'), findsOneWidget);
    expect(find.text('Audio Libro'), findsNothing);
    expect(find.text('Audiolibro'), findsNothing);
  });

  testWidgets('DashboardTools desktop cards do not overflow at shell width',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 876,
                child: buildTools(),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('DashboardTools mobile cards do not overflow at 390 px',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22.5),
            child: buildTools(),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
