import '../api_service.dart';
import 'voice_models.dart';

typedef VoiceTtsGenerator = Future<Map<String, dynamic>> Function({
  required String messageId,
  required String text,
  required String voiceProfile,
  required String language,
});

class VoiceTtsService {
  const VoiceTtsService({this.generator});

  final VoiceTtsGenerator? generator;

  Future<VoiceMessage> generateAudioForMessage({
    required VoiceMessage message,
    String voiceProfile = 'standard',
    String language = 'es',
  }) async {
    final cleanText = message.content.trim();

    if (cleanText.isEmpty) return message;

    final response = await (generator ?? ApiService.generateVoiceTts)(
      messageId: message.messageId,
      text: cleanText,
      voiceProfile: voiceProfile,
      language: language,
    );

    final audioUrl = response['audio_url']?.toString().trim() ?? '';
    final durationSeconds = _intFrom(response['duration_seconds']);

    final metadata = {
      ...message.metadata,
      'audio_url': audioUrl,
      'duration_seconds': durationSeconds,
      'tts_duration': durationSeconds,
      'voice_profile': voiceProfile,
      'language': language,
      'tts_generated_at': DateTime.now().toIso8601String(),
    };

    final updated = Map<String, dynamic>.from(message.toJson());
    updated['metadata'] = metadata;

    return VoiceMessage.fromJson(updated);
  }

  bool hasAudio(VoiceMessage message) {
    return audioUrl(message).isNotEmpty;
  }

  String audioUrl(VoiceMessage message) {
    return message.metadata['audio_url']?.toString().trim() ?? '';
  }

  int durationSeconds(VoiceMessage message) {
    return _intFrom(message.metadata['duration_seconds']);
  }

  int _intFrom(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
