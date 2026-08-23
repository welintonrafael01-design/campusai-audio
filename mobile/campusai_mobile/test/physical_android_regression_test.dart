import 'dart:async';
import 'dart:io';

import 'package:campusai_mobile/l10n/app_localizations.dart';
import 'package:campusai_mobile/providers/audio_provider.dart';
import 'package:campusai_mobile/screens/chat_screen.dart';
import 'package:campusai_mobile/services/local_storage_service.dart';
import 'package:campusai_mobile/services/voice_intelligence/voice_conversation_service.dart';
import 'package:campusai_mobile/utils/safe_debug_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ActiveAudioNotifier extends AudioNotifier {
  _ActiveAudioNotifier() {
    state = const AudioState(
      audioUrl: 'https://example.test/audio.mp3',
      title: 'Audio activo',
      duration: Duration(minutes: 2),
    );
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.initialize();
  });

  test('Android manifest declares the microphone permission', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    expect(
      manifest,
      contains('android.permission.RECORD_AUDIO'),
    );
  });

  test('permanently denied microphone directs the user to settings', () async {
    final service = VoiceConversationService(
      requestMicrophonePermission: () async =>
          PermissionStatus.permanentlyDenied,
    );
    final states = <VoiceConversationState>[];

    final result = await service.startListening(
      onStateChanged: states.add,
    );

    expect(result.status, VoiceConversationService.denied);
    expect(result.requiresSettings, isTrue);
    expect(result.errorMessage, contains('Ajustes'));
    expect(states.first.status, VoiceConversationService.requestingPermission);
  });

  test('microphone request cannot be started twice concurrently', () async {
    final permission = Completer<PermissionStatus>();
    var requests = 0;
    final service = VoiceConversationService(
      requestMicrophonePermission: () {
        requests += 1;
        return permission.future;
      },
    );

    final first = service.startListening(onStateChanged: (_) {});
    await Future<void>.delayed(Duration.zero);
    final second = await service.startListening(onStateChanged: (_) {});

    expect(second.status, VoiceConversationService.requestingPermission);
    expect(requests, 1);

    permission.complete(PermissionStatus.denied);
    await first;
  });

  test('upload log redacts document content and internal metadata', () {
    const response = <String, dynamic>{
      'document_id': '1234567890abcdef',
      'text_preview': 'PRIVATE DOCUMENT CONTENT',
      'ai_summary': 'PRIVATE SUMMARY',
      'file_path': '/private/server/path.pdf',
      'user_id': 'private-user',
    };

    final message = SafeDebugLog.uploadCompletedMessage(response);

    expect(message, '[UPLOAD] success document=12345678...');
    expect(message, isNot(contains('PRIVATE')));
    expect(message, isNot(contains('/private/server')));
    expect(message, isNot(contains('private-user')));
  });

  testWidgets('chat remains usable with Samsung-sized viewport and IME', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 860);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 380);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          audioProvider.overrideWith((ref) => _ActiveAudioNotifier()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ChatScreen(
            documentId: 'doc-alpha',
            fileName: 'Documento académico con un nombre suficientemente largo',
            workspaceId: 'workspace-alpha',
            workspaceDocumentIds: ['doc-alpha', 'doc-beta'],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(ChatScreen), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
