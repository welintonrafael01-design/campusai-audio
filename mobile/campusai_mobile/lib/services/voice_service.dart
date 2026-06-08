import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceService {
  final SpeechToText _speech = SpeechToText();

  bool _initialized = false;

  bool get isListening => _speech.isListening;
  bool get isAvailable => _speech.isAvailable;

  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(Object error)? onError,
  }) async {
    if (_initialized) return _speech.isAvailable;

    _initialized = await _speech.initialize(
      onStatus: onStatus,
      onError: onError,
      debugLogging: false,
    );

    return _initialized && _speech.isAvailable;
  }

  Future<bool> startListening({
    required void Function(String text) onResult,
    String? localeId,
    void Function(String status)? onStatus,
    void Function(Object error)? onError,
  }) async {
    final available = await initialize(
      onStatus: onStatus,
      onError: onError,
    );

    if (!available) return false;

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        final recognized = result.recognizedWords.trim();

        if (recognized.isNotEmpty) {
          onResult(recognized);
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        listenMode: ListenMode.confirmation,
        partialResults: true,
      ),
    );

    return true;
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> cancelListening() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
  }
}
