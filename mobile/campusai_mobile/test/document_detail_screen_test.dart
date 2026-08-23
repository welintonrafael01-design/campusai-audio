import 'package:campusai_mobile/models/document_history.dart';
import 'package:campusai_mobile/screens/document_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const document = DocumentHistory(
    documentId: 'doc-a',
    fileName: 'Biología molecular.pdf',
    summary: 'Resumen de la unidad.',
    audioUrl: '',
    createdAt: '2026-08-23T12:00:00Z',
  );

  Widget subject() {
    Future<void> noop() async {}

    return MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          size: Size(320, 720),
          textScaler: TextScaler.linear(1.3),
        ),
        child: DocumentDetailScreen(
          document: document,
          isCloud: false,
          isFavorite: false,
          isGeneratingAudiobook: false,
          onChat: noop,
          onAudioBook: noop,
          onVoiceTutor: noop,
          onFlashcards: noop,
          onQuiz: noop,
          onQuestionBank: noop,
          onExam: noop,
          onOpenPdf: noop,
          onSetActive: noop,
          onToggleFavorite: noop,
          onDelete: noop,
        ),
      ),
    );
  }

  testWidgets('exposes every primary document action at 320px text scale 1.3',
      (tester) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Resumen'), findsWidgets);
    expect(find.text('AudioBook'), findsOneWidget);
    expect(find.text('Tutor IA'), findsOneWidget);
    expect(find.text('Flashcards'), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget);
    expect(find.text('Banco de preguntas'), findsOneWidget);
    expect(find.text('Examen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
