import 'package:campusai_mobile/services/security/user_scoped_storage.dart';
import 'package:campusai_mobile/services/voice_intelligence/ai_coach_service.dart';
import 'package:campusai_mobile/services/voice_intelligence/voice_models.dart';
import 'package:campusai_mobile/services/voice_intelligence/voice_session_service.dart';
import 'package:campusai_mobile/services/voice_intelligence/voice_tts_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    UserScopedStorage.debugSetUserScopeForTesting('voice-student-a');
  });

  tearDown(() {
    UserScopedStorage.debugSetUserScopeForTesting(null);
  });

  test('TTS response enriches the assistant message without losing metadata',
      () async {
    final service = VoiceTtsService(
      generator: ({
        required messageId,
        required text,
        required voiceProfile,
        required language,
      }) async {
        expect(messageId, 'assistant-1');
        expect(text, 'Respuesta clara');
        expect(voiceProfile, 'standard');
        expect(language, 'es');
        return {
          'audio_url': '/audio/owned-response.mp3',
          'duration_seconds': 7,
        };
      },
    );
    final message = VoiceMessage(
      messageId: 'assistant-1',
      role: 'assistant',
      content: 'Respuesta clara',
      createdAt: DateTime.utc(2026, 9, 5),
      metadata: const {'conversation_turn': 1},
    );

    final result = await service.generateAudioForMessage(message: message);

    expect(service.hasAudio(result), isTrue);
    expect(service.audioUrl(result), '/audio/owned-response.mp3');
    expect(service.durationSeconds(result), 7);
    expect(result.metadata['conversation_turn'], 1);
  });

  test('AI coach uses backend content and falls back safely after a failure',
      () async {
    final success = AiCoachService(
      requester: ({
        required message,
        required mode,
        required context,
        required recentMessages,
      }) async {
        expect(message, 'Explícame el tema');
        expect(mode, 'explain');
        expect(context['chapterTitle'], 'Inteligencia artificial');
        return {
          'text': 'La IA aprende patrones para resolver tareas.',
          'suggestions': ['Dame un ejemplo'],
          'follow_up_questions': ['¿Quieres practicar?'],
          'confidence': 0.9,
        };
      },
    );
    const context = VoiceContext(
      chapterTitle: 'Inteligencia artificial',
      chapterSummary: 'Sistemas que procesan información.',
    );

    final response = await success.askCoach(
      userMessage: 'Explícame el tema',
      context: context,
      mode: 'explain',
    );
    expect(response.text, contains('aprende patrones'));
    expect(response.detectedIntent, 'explain');

    final fallback = AiCoachService(
      requester: ({
        required message,
        required mode,
        required context,
        required recentMessages,
      }) async {
        throw StateError('synthetic provider timeout');
      },
    );
    final recovered = await fallback.askCoach(
      userMessage: 'Explícame el tema',
      context: context,
      mode: 'explain',
    );
    expect(recovered.text, isNotEmpty);
    expect(recovered.detectedIntent, 'explain');
  });

  test('voice sessions persist and remain isolated by authenticated user',
      () async {
    const service = VoiceSessionService();
    final session = await service.createSession(
      audiobookId: 'book-a',
      chapterId: 'chapter-1',
    );
    final message = service.createMessage(
      role: 'user',
      content: 'Pregunta privada de Student A',
    );
    await service.addMessage(session: session, message: message);

    UserScopedStorage.debugSetUserScopeForTesting('voice-student-b');
    expect(await service.getSession(session.sessionId), isNull);
    expect(await service.getSessions(), isEmpty);

    UserScopedStorage.debugSetUserScopeForTesting('voice-student-a');
    final restored = await service.getSession(session.sessionId);
    expect(restored, isNotNull);
    expect(restored!.messages.single.content, contains('Student A'));
  });
}
