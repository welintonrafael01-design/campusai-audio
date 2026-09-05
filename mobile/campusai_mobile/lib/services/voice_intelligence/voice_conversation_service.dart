import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

typedef MicrophonePermissionRequester = Future<PermissionStatus> Function();

abstract interface class VoiceSpeechRecognizer {
  bool get isListening;

  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function(String message) onError,
  });

  Future<void> listen({
    required String localeId,
    required Duration listenFor,
    required Duration pauseFor,
    required void Function(String text, bool isFinal) onResult,
  });

  Future<void> stop();

  Future<void> cancel();
}

class DeviceVoiceSpeechRecognizer implements VoiceSpeechRecognizer {
  DeviceVoiceSpeechRecognizer({SpeechToText? speech})
      : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;

  @override
  bool get isListening => _speech.isListening;

  @override
  Future<bool> initialize({
    required void Function(String status) onStatus,
    required void Function(String message) onError,
  }) {
    return _speech.initialize(
      onStatus: onStatus,
      onError: (error) => onError(error.errorMsg),
      debugLogging: false,
    );
  }

  @override
  Future<void> listen({
    required String localeId,
    required Duration listenFor,
    required Duration pauseFor,
    required void Function(String text, bool isFinal) onResult,
  }) {
    return _speech.listen(
      onResult: (result) => onResult(
        result.recognizedWords.trim(),
        result.finalResult,
      ),
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        partialResults: true,
        listenMode: ListenMode.confirmation,
        listenFor: listenFor,
        pauseFor: pauseFor,
      ),
    );
  }

  @override
  Future<void> stop() => _speech.stop();

  @override
  Future<void> cancel() => _speech.cancel();
}

class VoiceConversationState {
  final String status;
  final String partialText;
  final String finalText;
  final String errorMessage;
  final bool isListening;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int durationSeconds;
  final bool requiresSettings;

  const VoiceConversationState({
    this.status = VoiceConversationService.idle,
    this.partialText = '',
    this.finalText = '',
    this.errorMessage = '',
    this.isListening = false,
    this.startedAt,
    this.endedAt,
    this.durationSeconds = 0,
    this.requiresSettings = false,
  });

  static const idleState = VoiceConversationState();

  VoiceConversationState copyWith({
    String? status,
    String? partialText,
    String? finalText,
    String? errorMessage,
    bool? isListening,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
    bool? requiresSettings,
  }) {
    return VoiceConversationState(
      status: status ?? this.status,
      partialText: partialText ?? this.partialText,
      finalText: finalText ?? this.finalText,
      errorMessage: errorMessage ?? this.errorMessage,
      isListening: isListening ?? this.isListening,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      requiresSettings: requiresSettings ?? this.requiresSettings,
    );
  }
}

class VoiceConversationService {
  static const String idle = 'idle';
  static const String requestingPermission = 'requestingPermission';
  static const String listening = 'listening';
  static const String processing = 'processing';
  static const String denied = 'denied';
  static const String error = 'error';

  VoiceConversationService({
    MicrophonePermissionRequester? requestMicrophonePermission,
    VoiceSpeechRecognizer? speechRecognizer,
  })  : _requestMicrophonePermission =
            requestMicrophonePermission ?? Permission.microphone.request,
        _speech = speechRecognizer ?? DeviceVoiceSpeechRecognizer();

  final VoiceSpeechRecognizer _speech;
  final MicrophonePermissionRequester _requestMicrophonePermission;
  VoiceConversationState _state = VoiceConversationState.idleState;
  DateTime? _startedAt;
  String _latestText = '';
  bool _completedTurn = false;

  VoiceConversationState get state => _state;
  bool get isListening => _speech.isListening;

  Future<VoiceConversationState> startListening({
    required void Function(VoiceConversationState state) onStateChanged,
    String localeId = 'es_ES',
  }) async {
    if (_state.status == requestingPermission || _speech.isListening) {
      return _state;
    }

    _completedTurn = false;
    _latestText = '';
    _emit(
      const VoiceConversationState(
        status: requestingPermission,
      ),
      onStateChanged,
    );

    PermissionStatus permission;
    try {
      permission = await _requestMicrophonePermission();
    } catch (_) {
      return _emitPluginError(onStateChanged);
    }
    if (!permission.isGranted) {
      final requiresSettings = permission.isPermanentlyDenied;
      return _emit(
        VoiceConversationState(
          status: denied,
          errorMessage: requiresSettings
              ? 'El permiso de micrófono está bloqueado. Actívalo en Ajustes.'
              : 'Permiso de micrófono denegado.',
          requiresSettings: requiresSettings,
        ),
        onStateChanged,
      );
    }

    bool available;
    try {
      available = await _speech.initialize(
        onStatus: (status) {
          final normalized = status.toLowerCase();
          if (normalized == 'done' || normalized == 'notlistening') {
            _completeTurn(onStateChanged);
          }
        },
        onError: (message) {
          _emit(
            VoiceConversationState(
              status: error,
              errorMessage: message,
              partialText: _latestText,
              finalText: _latestText,
              isListening: false,
              startedAt: _startedAt,
              endedAt: DateTime.now(),
              durationSeconds: _durationSeconds(),
            ),
            onStateChanged,
          );
        },
      );
    } catch (_) {
      return _emitPluginError(onStateChanged);
    }

    if (!available) {
      return _emit(
        const VoiceConversationState(
          status: error,
          errorMessage: 'El reconocimiento de voz no está disponible.',
        ),
        onStateChanged,
      );
    }

    _startedAt = DateTime.now();
    _emit(
      VoiceConversationState(
        status: listening,
        isListening: true,
        startedAt: _startedAt,
      ),
      onStateChanged,
    );

    try {
      await _speech.listen(
        localeId: localeId,
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 3),
        onResult: (text, isFinal) {
          _latestText = text.trim();
          _emit(
            VoiceConversationState(
              status: isFinal ? processing : listening,
              partialText: _latestText,
              finalText: isFinal ? _latestText : '',
              isListening: !isFinal,
              startedAt: _startedAt,
              endedAt: isFinal ? DateTime.now() : null,
              durationSeconds: _durationSeconds(),
            ),
            onStateChanged,
          );

          if (isFinal) {
            _completedTurn = true;
          }
        },
      );
    } catch (_) {
      return _emitPluginError(onStateChanged);
    }

    return _state;
  }

  Future<void> release() async {
    if (_speech.isListening) {
      try {
        await _speech.cancel();
      } catch (_) {}
    }
  }

  Future<bool> openPermissionSettings() => openAppSettings();

  Future<VoiceConversationState> stopListening({
    required void Function(VoiceConversationState state) onStateChanged,
  }) async {
    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
    } catch (_) {
      return _emitPluginError(onStateChanged);
    }
    return _completeTurn(onStateChanged);
  }

  Future<VoiceConversationState> cancelListening({
    required void Function(VoiceConversationState state) onStateChanged,
  }) async {
    try {
      if (_speech.isListening) {
        await _speech.cancel();
      }
    } catch (_) {
      return _emitPluginError(onStateChanged);
    }
    _completedTurn = true;
    return _emit(
      VoiceConversationState(
        status: idle,
        startedAt: _startedAt,
        endedAt: DateTime.now(),
        durationSeconds: _durationSeconds(),
      ),
      onStateChanged,
    );
  }

  VoiceConversationState _emitPluginError(
    void Function(VoiceConversationState state) onStateChanged,
  ) {
    return _emit(
      VoiceConversationState(
        status: error,
        errorMessage: 'No se pudo iniciar el reconocimiento de voz.',
        partialText: _latestText,
        finalText: _latestText,
        isListening: false,
        startedAt: _startedAt,
        endedAt: DateTime.now(),
        durationSeconds: _durationSeconds(),
      ),
      onStateChanged,
    );
  }

  VoiceConversationState _completeTurn(
    void Function(VoiceConversationState state) onStateChanged,
  ) {
    if (_completedTurn && _state.status == processing) return _state;
    _completedTurn = true;

    return _emit(
      VoiceConversationState(
        status: processing,
        partialText: _latestText,
        finalText: _latestText,
        isListening: false,
        startedAt: _startedAt,
        endedAt: DateTime.now(),
        durationSeconds: _durationSeconds(),
      ),
      onStateChanged,
    );
  }

  VoiceConversationState _emit(
    VoiceConversationState state,
    void Function(VoiceConversationState state) onStateChanged,
  ) {
    _state = state;
    onStateChanged(state);
    return state;
  }

  int _durationSeconds() {
    final startedAt = _startedAt;
    if (startedAt == null) return 0;
    return DateTime.now().difference(startedAt).inSeconds;
  }
}
