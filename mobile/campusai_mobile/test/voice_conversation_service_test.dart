import 'package:campusai_mobile/services/voice_intelligence/voice_conversation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

class _FakeSpeechRecognizer implements VoiceSpeechRecognizer {
  bool available = true;
  bool throwOnInitialize = false;
  bool throwOnListen = false;
  bool throwOnStop = false;
  bool throwOnCancel = false;
  bool _isListening = false;
  int initializeCalls = 0;
  int listenCalls = 0;
  int stopCalls = 0;
  int cancelCalls = 0;
  String localeId = '';
  Duration? listenFor;
  Duration? pauseFor;
  void Function(String status)? onStatus;
  void Function(String message)? onError;
  void Function(String text, bool isFinal)? onResult;

  @override
  bool get isListening => _isListening;

  @override
  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function(String message) onError,
  }) async {
    initializeCalls += 1;
    this.onStatus = onStatus;
    this.onError = onError;
    if (throwOnInitialize) throw StateError('synthetic initialize failure');
    return available;
  }

  @override
  Future<void> listen({
    required String localeId,
    required Duration listenFor,
    required Duration pauseFor,
    required void Function(String text, bool isFinal) onResult,
  }) async {
    listenCalls += 1;
    if (throwOnListen) throw StateError('synthetic listen failure');
    this.localeId = localeId;
    this.listenFor = listenFor;
    this.pauseFor = pauseFor;
    this.onResult = onResult;
    _isListening = true;
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
    if (throwOnStop) throw StateError('synthetic stop failure');
    _isListening = false;
  }

  @override
  Future<void> cancel() async {
    cancelCalls += 1;
    if (throwOnCancel) throw StateError('synthetic cancel failure');
    _isListening = false;
  }

  void emitResult(String text, {required bool isFinal}) {
    onResult?.call(text, isFinal);
    if (isFinal) _isListening = false;
  }
}

void main() {
  test('initializes, listens and publishes partial and final transcription',
      () async {
    final speech = _FakeSpeechRecognizer();
    final service = VoiceConversationService(
      requestMicrophonePermission: () async => PermissionStatus.granted,
      speechRecognizer: speech,
    );
    final states = <VoiceConversationState>[];

    final started = await service.startListening(
      onStateChanged: states.add,
    );
    speech.emitResult('Explica la inteligencia', isFinal: false);
    speech.emitResult(
      'Explica la inteligencia artificial',
      isFinal: true,
    );

    expect(started.status, VoiceConversationService.listening);
    expect(speech.initializeCalls, 1);
    expect(speech.listenCalls, 1);
    expect(speech.localeId, 'es_ES');
    expect(speech.listenFor, const Duration(seconds: 45));
    expect(speech.pauseFor, const Duration(seconds: 3));
    expect(states.first.status, VoiceConversationService.requestingPermission);
    expect(states, hasLength(4));
    expect(states[2].partialText, 'Explica la inteligencia');
    expect(states.last.status, VoiceConversationService.processing);
    expect(
      states.last.finalText,
      'Explica la inteligencia artificial',
    );
  });

  test('stop finalizes the latest partial transcription', () async {
    final speech = _FakeSpeechRecognizer();
    final service = VoiceConversationService(
      requestMicrophonePermission: () async => PermissionStatus.granted,
      speechRecognizer: speech,
    );
    final states = <VoiceConversationState>[];

    await service.startListening(onStateChanged: states.add);
    speech.emitResult('Pregunta parcial', isFinal: false);
    final stopped = await service.stopListening(onStateChanged: states.add);

    expect(speech.stopCalls, 1);
    expect(stopped.status, VoiceConversationService.processing);
    expect(stopped.finalText, 'Pregunta parcial');
    expect(stopped.isListening, isFalse);
  });

  test('cancel and release clean up an active recognizer', () async {
    final speech = _FakeSpeechRecognizer();
    final service = VoiceConversationService(
      requestMicrophonePermission: () async => PermissionStatus.granted,
      speechRecognizer: speech,
    );
    final states = <VoiceConversationState>[];

    await service.startListening(onStateChanged: states.add);
    final cancelled = await service.cancelListening(
      onStateChanged: states.add,
    );
    expect(cancelled.status, VoiceConversationService.idle);
    expect(speech.cancelCalls, 1);

    await service.startListening(onStateChanged: states.add);
    await service.release();
    expect(speech.cancelCalls, 2);
    expect(speech.isListening, isFalse);
  });

  test('unavailable recognizer and plugin failures become retryable states',
      () async {
    final speech = _FakeSpeechRecognizer()..available = false;
    final service = VoiceConversationService(
      requestMicrophonePermission: () async => PermissionStatus.granted,
      speechRecognizer: speech,
    );
    final states = <VoiceConversationState>[];

    final unavailable = await service.startListening(
      onStateChanged: states.add,
    );
    expect(unavailable.status, VoiceConversationService.error);
    expect(unavailable.errorMessage, contains('no está disponible'));

    speech.available = true;
    speech.throwOnListen = true;
    final failed = await service.startListening(onStateChanged: states.add);
    expect(failed.status, VoiceConversationService.error);
    expect(failed.errorMessage, contains('reconocimiento de voz'));

    speech.throwOnListen = false;
    final retried = await service.startListening(onStateChanged: states.add);
    expect(retried.status, VoiceConversationService.listening);
  });

  test('permission plugin failure does not escape to the UI', () async {
    final service = VoiceConversationService(
      requestMicrophonePermission: () async =>
          throw StateError('synthetic permission failure'),
      speechRecognizer: _FakeSpeechRecognizer(),
    );
    final states = <VoiceConversationState>[];

    final result = await service.startListening(onStateChanged: states.add);

    expect(result.status, VoiceConversationService.error);
    expect(result.errorMessage, contains('reconocimiento de voz'));
  });
}
