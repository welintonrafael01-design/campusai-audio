import 'package:campusai_mobile/widgets/dashboard/dashboard_tools.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DashboardTools shows the eight core AI tools once',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: DashboardTools(
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
            ),
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
}
