import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceConversationState {
  final String status;
  final String partialText;
  final String finalText;
  final String errorMessage;
  final bool isListening;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int durationSeconds;

  const VoiceConversationState({
    this.status = VoiceConversationService.idle,
    this.partialText = '',
    this.finalText = '',
    this.errorMessage = '',
    this.isListening = false,
    this.startedAt,
    this.endedAt,
    this.durationSeconds = 0,
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

  final SpeechToText _speech = SpeechToText();
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
    _completedTurn = false;
    _latestText = '';
    _emit(
      const VoiceConversationState(
        status: requestingPermission,
      ),
      onStateChanged,
    );

    final permission = await Permission.microphone.request();
    if (!permission.isGranted) {
      return _emit(
        const VoiceConversationState(
          status: denied,
          errorMessage: 'Permiso de micrófono denegado.',
        ),
        onStateChanged,
      );
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        final normalized = status.toLowerCase();
        if (normalized == 'done' || normalized == 'notlistening') {
          _completeTurn(onStateChanged);
        }
      },
      onError: (speechError) {
        _emit(
          VoiceConversationState(
            status: error,
            errorMessage: speechError.errorMsg,
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
      debugLogging: false,
    );

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

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        _latestText = result.recognizedWords.trim();
        _emit(
          VoiceConversationState(
            status: result.finalResult ? processing : listening,
            partialText: _latestText,
            finalText: result.finalResult ? _latestText : '',
            isListening: !result.finalResult,
            startedAt: _startedAt,
            endedAt: result.finalResult ? DateTime.now() : null,
            durationSeconds: _durationSeconds(),
          ),
          onStateChanged,
        );

        if (result.finalResult) {
          _completedTurn = true;
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        partialResults: true,
        listenMode: ListenMode.confirmation,
      ),
    );

    return _state;
  }

  Future<VoiceConversationState> stopListening({
    required void Function(VoiceConversationState state) onStateChanged,
  }) async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    return _completeTurn(onStateChanged);
  }

  Future<VoiceConversationState> cancelListening({
    required void Function(VoiceConversationState state) onStateChanged,
  }) async {
    if (_speech.isListening) {
      await _speech.cancel();
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
