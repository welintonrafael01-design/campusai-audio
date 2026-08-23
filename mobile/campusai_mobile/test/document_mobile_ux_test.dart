import 'package:campusai_mobile/l10n/app_localizations.dart';
import 'package:campusai_mobile/models/chat_message_model.dart';
import 'package:campusai_mobile/models/document_history.dart';
import 'package:campusai_mobile/screens/document_detail_screen.dart';
import 'package:campusai_mobile/screens/library_screen.dart';
import 'package:campusai_mobile/services/local_storage_service.dart';
import 'package:campusai_mobile/utils/document_display_title.dart';
import 'package:campusai_mobile/widgets/chat/chat_messages.dart';
import 'package:campusai_mobile/widgets/chat/source_references_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _document = DocumentHistory(
  documentId: 'doc-ciag',
  fileName:
      '638959530362933283-Resolución-núm.-0006-2025-Conformación-de-Inclusión-y-Accesibilidad-Gubernamental-CIAG.pdf',
  summary:
      'La resolución establece la conformación y las responsabilidades del comité de inclusión y accesibilidad.',
  audioUrl: '',
  createdAt: '2025-03-14T10:30:00Z',
);

Widget _testApp(Widget child, {double textScale = 1}) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, appChild) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: appChild!,
        );
      },
      home: child,
    ),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.initialize();
  });

  for (final width in const [360.0, 390.0, 411.0, 430.0]) {
    testWidgets(
      'Library remains responsive at ${width.toInt()} px and text scale 1.3',
      (tester) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _testApp(
            const LibraryScreen(initialDocuments: [_document]),
            textScale: 1.3,
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));

        expect(tester.takeException(), isNull);
        expect(find.textContaining('Todos ('), findsOneWidget);
        expect(find.textContaining('Documentos ('), findsOneWidget);
        expect(find.textContaining('Generados ('), findsOneWidget);
        expect(find.textContaining('Audio ('), findsOneWidget);
        expect(
            find.byKey(const Key('library-location-filter')), findsOneWidget);

        final categoryLabels = tester
            .widgetList<ChoiceChip>(find.byType(ChoiceChip))
            .map((chip) => (chip.label as Text).data)
            .toList();
        expect(categoryLabels, hasLength(4));
        expect(
          tester
              .widget<Text>(
                find.descendant(
                  of: find.byType(ChoiceChip).first,
                  matching: find.byType(Text),
                ),
              )
              .softWrap,
          isFalse,
        );

        expect(find.text('Chat'), findsNothing);
        expect(find.text('Flashcards'), findsNothing);
        expect(find.text('Examen'), findsNothing);
        expect(find.byKey(const Key('document-card-doc-ciag')), findsOneWidget);
      },
    );
  }

  testWidgets('compact document card opens the complete detail experience', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _testApp(
        const LibraryScreen(initialDocuments: [_document]),
        textScale: 1.3,
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final card = find.byKey(const Key('document-card-doc-ciag'));
    await tester.ensureVisible(card);
    await tester.pumpAndSettle();
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.byType(DocumentDetailScreen), findsOneWidget);
    expect(find.text('ESTUDIAR CON IA'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);
    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('AudioBook'), findsOneWidget);
    expect(find.text('Flashcards'), findsOneWidget);
    expect(find.text('Quiz'), findsOneWidget);
    expect(find.text('Banco de preguntas'), findsOneWidget);
    expect(find.text('Examen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('display title removes only unmistakable technical prefixes', () {
    expect(
      documentDisplayTitle(_document.fileName),
      'Resolución núm. 0006-2025 Conformación de Inclusión y Accesibilidad Gubernamental CIAG',
    );
    expect(
      documentDisplayTitle('Resolución-núm.-0006-2025.pdf'),
      'Resolución núm. 0006-2025',
    );
    expect(
      documentDisplayTitle('1234567890123-Informe.pdf'),
      '1234567890123 Informe',
    );
  });

  testWidgets('sources use academic labels and reveal a legible excerpt', (
    tester,
  ) async {
    const excerpt =
        'El comité coordina las medidas de accesibilidad institucional.';
    const source = ChatCitationModel(
      documentId: 'internal-doc-id',
      chunkIndex: 30,
      pageNumber: 3,
      preview: excerpt,
      distance: 0.52,
    );

    await tester.pumpWidget(
      _testApp(
        const Scaffold(
          body: SourceReferencesSection(sources: [source]),
        ),
        textScale: 1.3,
      ),
    );

    expect(find.text('Fuentes (1)'), findsOneWidget);
    expect(find.textContaining('internal-doc-id'), findsNothing);
    expect(find.textContaining('30'), findsNothing);

    await tester.tap(find.byKey(const Key('source-references-expansion')));
    await tester.pumpAndSettle();

    expect(find.text('Fuente 1 · Página 3'), findsOneWidget);
    expect(find.text(excerpt), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('chat stays usable with IME and expanded sources at 411 px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 860);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 380);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    final message = ChatMessageModel(
      text:
          'Esta respuesta académica es suficientemente larga para validar el comportamiento del chat en una pantalla física pequeña.',
      isUser: false,
      createdAt: DateTime(2025),
      citations: const [
        ChatCitationModel(
          documentId: 'doc-ciag',
          chunkIndex: 2,
          pageNumber: 6,
          preview:
              'La comisión dará seguimiento a las acciones de inclusión y accesibilidad.',
        ),
      ],
    );

    await tester.pumpWidget(
      _testApp(
        Scaffold(
          body: ChatMessages(messages: [message], isLoading: false),
        ),
        textScale: 1.3,
      ),
    );

    await tester.tap(find.byKey(const Key('source-references-expansion')));
    await tester.pumpAndSettle();

    expect(find.text('Fuente 1 · Página 6'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
