import 'package:campusai_mobile/screens/audiobook_studio_screen.dart';
import 'package:campusai_mobile/services/academic_engine/academic_resource_repository.dart';
import 'package:campusai_mobile/services/security/user_scoped_storage.dart';
import 'package:campusai_mobile/services/study_result_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _chapterTestApp({required double textScale}) {
  return MaterialApp(
    builder: (context, child) {
      final mediaQuery = MediaQuery.of(context);
      return MediaQuery(
        data: mediaQuery.copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      );
    },
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: AudioBookChapterCard(
          chapter: const {
            'chapter_number': 12,
            'title':
                'Un capítulo con un título deliberadamente largo para validar teléfonos compactos',
            'summary':
                'Resumen suficientemente largo para comprobar que el contenido crece verticalmente sin forzar anchos fijos.',
            'key_concepts': [
              'Concepto académico extenso que debe ajustarse correctamente',
            ],
            'reflection_questions': [
              '¿Cómo aplicarías este concepto en una situación de aprendizaje real?',
            ],
          },
          isCurrent: true,
          isCompleted: false,
          isGeneratingAudio: false,
          hasAudioError: true,
          isGeneratingLearningPack: false,
          hasLearningPackError: true,
          currentPositionSeconds: 37,
          durationSeconds: 240,
          onListen: _noop,
          onGenerateAudio: _noop,
          onGenerateLearningPack: _noop,
          onLearningPack: _noop,
          onTranscript: _noop,
          onTutor: _noop,
          onVoiceTutor: _noop,
          onProgress: _noop,
          stringListFrom: _stringListFrom,
          cleanText: _cleanText,
          intFrom: _intFrom,
          formatDuration: _formatDuration,
        ),
      ),
    ),
  );
}

void _noop() {}

List<String> _stringListFrom(dynamic raw) {
  if (raw is! List) return const [];
  return raw.map((item) => item.toString()).toList();
}

String _cleanText(dynamic value) => value?.toString().trim() ?? '';

int _intFrom(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

String _formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    UserScopedStorage.debugSetUserScopeForTesting('audiobook-release-test');
  });

  tearDown(() {
    UserScopedStorage.debugSetUserScopeForTesting(null);
  });

  for (final width in const [320.0, 360.0, 390.0, 411.0, 430.0]) {
    for (final textScale in const [1.0, 1.2, 1.3]) {
      testWidgets(
        'chapter card fits ${width.toInt()} px at text scale $textScale',
        (tester) async {
          tester.view.physicalSize = Size(width, 1400);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(_chapterTestApp(textScale: textScale));
          await tester.pump();

          expect(find.text('Continuar capítulo'), findsOneWidget);
          expect(find.text('Generar flashcards y mini quiz'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('chapter card fits reported Samsung content width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(325.4, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_chapterTestApp(textScale: 1.3));
    await tester.pump();

    expect(find.text('Probemos otra vez con el audio'), findsOneWidget);
    expect(
      find.text('Probemos otra vez con las actividades'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  test('local audiobook remains saved when cloud persistence fails', () async {
    const documentId = 'audiobook_local_fallback';
    const content = '{"title":"AudioBook local"}';

    final cloudSynced = await AcademicResourceRepository.saveResource(
      documentId: documentId,
      type: 'audiobook',
      content: content,
      cloudDebugLabel: 'AudioBook de prueba',
      cloudSave: () async => throw Exception('cloud unavailable'),
    );
    final localResult = await StudyResultService.getResult(
      documentId: documentId,
      type: 'audiobook',
    );

    expect(cloudSynced, isFalse);
    expect(localResult, isNotNull);
    expect(localResult!.documentId, documentId);
    expect(localResult.type, 'audiobook');
    expect(localResult.content, content);
  });
}
