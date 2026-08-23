import 'dart:convert';

import 'package:campusai_mobile/l10n/app_localizations.dart';
import 'package:campusai_mobile/models/document_history.dart';
import 'package:campusai_mobile/models/study_result.dart';
import 'package:campusai_mobile/screens/audiobook_studio_screen.dart';
import 'package:campusai_mobile/screens/library_screen.dart';
import 'package:campusai_mobile/services/academic_engine/academic_resource_repository.dart';
import 'package:campusai_mobile/services/audiobook_service.dart';
import 'package:campusai_mobile/services/local_storage_service.dart';
import 'package:campusai_mobile/services/security/user_scoped_storage.dart';
import 'package:campusai_mobile/services/study_result_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

Widget _responsiveTestApp(Widget child, {double textScale = 1.3}) {
  return MaterialApp(
    builder: (context, appChild) {
      final mediaQuery = MediaQuery.of(context);
      return MediaQuery(
        data: mediaQuery.copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: appChild!,
      );
    },
    home: Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    ),
  );
}

class _FakeAudiobookService extends AudiobookService {
  StudyResult? savedResult;

  @override
  Future<List<StudyResult>> getAudioBooks({
    Future<List<dynamic>> Function()? cloudLoader,
  }) async {
    return savedResult == null ? [] : [savedResult!];
  }

  @override
  Future<Map<String, dynamic>> generateFromText({
    required String title,
    required String text,
    String sourceMode = 'solo',
    String sourceType = 'text',
    String sourceDocumentId = '',
    String courseId = '',
    String courseName = '',
    String unitId = '',
    String unitTopic = '',
    String language = 'es',
    String voiceProfile = 'standard',
  }) async {
    return {
      'audiobook_id': '${sourceDocumentId}_audiobook',
      'source_mode': sourceMode,
      'source_type': sourceType,
      'source_document_id': sourceDocumentId,
      'title': title,
      'description': 'AudioBook QA generado desde $sourceDocumentId.',
      'generation_source': 'backend',
      'estimated_duration_minutes': 3,
      'chapters': [
        {
          'chapter_id': 'chapter_1',
          'title': 'Capitulo Alpha',
          'summary': text,
          'script': text,
          'estimated_minutes': 3,
          'status': 'ready',
        },
      ],
    };
  }

  @override
  Future<AudioBookSaveResult> saveAudioBookWithStatus(
    Map<String, dynamic> audiobook, {
    Future<void> Function()? cloudSave,
  }) async {
    final documentId = documentIdForAudioBook(audiobook);
    final savedBook = {
      ...audiobook,
      'audiobook_id': documentId,
      'sync_status': AudioBookSyncStatus.synced.storageValue,
    };
    savedResult = StudyResult(
      documentId: documentId,
      type: AudiobookService.resultType,
      content: jsonEncode(savedBook),
      createdAt: '2026-08-23T12:00:00Z',
    );
    return AudioBookSaveResult(
      documentId: documentId,
      cloudSynced: true,
      syncStatus: AudioBookSyncStatus.synced,
      audiobook: savedBook,
    );
  }
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
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.initialize();
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

  test('canonical result type remains aligned with the cloud contract', () {
    expect(AudiobookService.resultType, 'audiobook');
  });

  test('save retry is idempotent and persists honest sync state', () async {
    const service = AudiobookService();
    final audiobook = service.fallbackAudioBookFromText(
      title: 'Documento Alpha',
      text: 'Contenido académico Alpha.',
      sourceDocumentId: 'document_alpha',
      sourceType: 'document',
    );

    final failed = await service.saveAudioBookWithStatus(
      audiobook,
      cloudSave: () async => throw Exception('offline'),
    );
    var stored = await StudyResultService.getResult(
      documentId: 'document_alpha_audiobook',
      type: AudiobookService.resultType,
    );

    expect(failed.cloudSynced, isFalse);
    expect(failed.syncStatus, AudioBookSyncStatus.syncFailed);
    expect(jsonDecode(stored!.content)['sync_status'], 'sync_failed');

    final synced = await service.saveAudioBookWithStatus(
      failed.audiobook,
      cloudSave: () async {},
    );
    stored = await StudyResultService.getResult(
      documentId: 'document_alpha_audiobook',
      type: AudiobookService.resultType,
    );
    final allResults = await StudyResultService.getResultsByType(
      AudiobookService.resultType,
    );

    expect(synced.cloudSynced, isTrue);
    expect(synced.syncStatus, AudioBookSyncStatus.synced);
    expect(jsonDecode(stored!.content)['sync_status'], 'synced');
    expect(allResults, hasLength(1));
  });

  test('cloud restore hydrates the owner-scoped local library', () async {
    const service = AudiobookService();
    final restored = await service.getAudioBooks(
      cloudLoader: () async => [
        {
          'document_id': 'document_alpha_audiobook',
          'type': 'audiobook',
          'content': jsonEncode({
            'audiobook_id': 'document_alpha_audiobook',
            'source_document_id': 'document_alpha',
            'title': 'AudioBook Alpha',
            'chapters': [],
          }),
          'updated_at': '2026-08-23T12:00:00Z',
        },
      ],
    );
    final local = await StudyResultService.getResult(
      documentId: 'document_alpha_audiobook',
      type: AudiobookService.resultType,
    );

    expect(restored, hasLength(1));
    expect(local, isNotNull);
    expect(jsonDecode(local!.content)['sync_status'], 'synced');
  });

  test('document context cannot drift from Alpha to Beta', () {
    const service = AudiobookService();
    final normalized = service.normalizeAudioBookPayload(
      {
        'audiobook_id': 'backend_beta',
        'source_document_id': 'document_beta',
        'title': 'Respuesta del backend',
        'chapters': [],
      },
      fallbackTitle: 'Documento Alpha',
      fallbackText: 'Contenido Alpha',
      sourceDocumentId: 'document_alpha',
      sourceType: 'document',
    );

    expect(normalized['source_document_id'], 'document_alpha');
    expect(
        service.documentIdForAudioBook(normalized), 'document_alpha_audiobook');
    expect(
        service.documentIdForAudioBook({
          ...normalized,
          'source_document_id': 'document_beta',
        }),
        'document_beta_audiobook');
  });

  testWidgets('Library to AudioBook generation opens the player', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const document = DocumentHistory(
      documentId: 'document_alpha',
      fileName: 'Documento Alpha.pdf',
      summary: 'Contenido académico Alpha para el AudioBook.',
      audioUrl: '',
      createdAt: '2026-08-23T12:00:00Z',
    );
    final audiobookService = _FakeAudiobookService();
    late final GoRouter router;
    router = GoRouter(
      initialLocation: '/library',
      routes: [
        GoRoute(
          path: '/library',
          builder: (_, __) => const LibraryScreen(
            initialDocuments: [document],
          ),
        ),
        GoRoute(
          path: '/audiobook-studio',
          name: 'audioBookStudio',
          builder: (_, state) {
            final extra = Map<String, dynamic>.from(state.extra! as Map);
            return AudioBookStudioScreen(
              sourceMode: extra['sourceMode']?.toString() ?? 'solo',
              sourceType: extra['sourceType']?.toString() ?? 'document',
              sourceDocumentId: extra['sourceDocumentId']?.toString() ?? '',
              initialTitle: extra['initialTitle']?.toString() ?? '',
              initialText: extra['initialText']?.toString() ?? '',
              audiobookService: audiobookService,
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.byKey(const Key('document-card-document_alpha')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AudioBook'));
    await tester.pumpAndSettle();

    expect(find.byType(AudioBookStudioScreen), findsOneWidget);
    expect(find.text('Documento Alpha'), findsWidgets);

    for (var attempt = 0;
        attempt < 4 && find.text('Generar AudioBook').evaluate().isEmpty;
        attempt++) {
      await tester.drag(
        find.byType(ListView).first,
        const Offset(0, -600),
      );
      await tester.pumpAndSettle();
    }
    expect(find.text('Generar AudioBook'), findsOneWidget);
    await tester.ensureVisible(find.text('Generar AudioBook'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Generar AudioBook'));
    await tester.pumpAndSettle();

    expect(find.byType(AudioBookPlaybackPanel), findsOneWidget);
    expect(find.text('Capitulo Alpha'), findsWidgets);
    expect(
        audiobookService.savedResult?.documentId, 'document_alpha_audiobook');
    expect(tester.takeException(), isNull);
  });

  for (final width in const [320.0, 360.0, 390.0, 411.0, 430.0]) {
    testWidgets('player fits ${width.toInt()} px with loading and error states',
        (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _responsiveTestApp(
          AudioBookPlaybackPanel(
            currentChapterId: 'chapter_1',
            currentPositionSeconds: 3723,
            currentChapterDuration: 10800,
            isPlaying: false,
            isLoading: true,
            errorMessage:
                'El audio real no está disponible. Puedes continuar en modo lectura guiada.',
            playbackSpeed: 1,
            onSpeedChanged: (_) {},
            onSeek: (_) {},
            onSkipBackward: _noop,
            onSkipForward: _noop,
            onResume: _noop,
            onPause: () async {},
            onRestart: () async {},
            onComplete: () async {},
            onNext: () async {},
            formatDuration: _formatDuration,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Preparando audio'), findsOneWidget);
      expect(find.textContaining('modo lectura guiada'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final status in const [
    'local',
    'syncing',
    'synced',
    'sync_failed',
  ]) {
    testWidgets('sync state $status remains readable on compact mobile', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _responsiveTestApp(
          AudioBookSyncIndicator(
            status: status,
            isSyncing: status == 'syncing',
            onRetry: _noop,
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  }
}
