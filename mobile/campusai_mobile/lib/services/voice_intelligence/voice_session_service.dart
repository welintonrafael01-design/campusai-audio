import 'dart:convert';

import '../../models/study_result.dart';
import '../study_result_service.dart';
import 'voice_models.dart';

class VoiceSessionService {
  const VoiceSessionService();

  static const String voiceSessionType = 'voice_session';

  Future<VoiceSession> createSession({
    String audiobookId = '',
    String chapterId = '',
    String title = 'Tutor IA',
    String mode = 'general',
  }) async {
    final now = DateTime.now();
    final safeAudiobookId = audiobookId.trim();
    final safeChapterId = chapterId.trim();
    final prefix = [
      safeAudiobookId,
      safeChapterId,
      'voice_session',
    ].where((item) => item.isNotEmpty).join('_');
    final sessionId =
        '${prefix.isEmpty ? 'voice_session' : prefix}_${now.millisecondsSinceEpoch}';

    final session = VoiceSession(
      sessionId: sessionId,
      audiobookId: safeAudiobookId,
      chapterId: safeChapterId,
      title: title.trim().isEmpty ? 'Tutor IA' : title.trim(),
      startedAt: now,
      updatedAt: now,
      status: 'active',
      mode: mode.trim().isEmpty ? 'general' : mode.trim(),
    );

    await saveSession(session);
    return session;
  }

  Future<void> saveSession(VoiceSession session) async {
    if (session.sessionId.trim().isEmpty) return;

    await StudyResultService.saveResult(
      StudyResult(
        documentId: session.sessionId,
        type: voiceSessionType,
        content: jsonEncode(session.toJson()),
        createdAt: session.startedAt.toIso8601String(),
      ),
    );
  }

  Future<VoiceSession?> getSession(String sessionId) async {
    final cleanSessionId = sessionId.trim();
    if (cleanSessionId.isEmpty) return null;

    final result = await StudyResultService.getResult(
      documentId: cleanSessionId,
      type: voiceSessionType,
    );
    if (result == null) return null;

    return _decodeSession(result);
  }

  Future<List<VoiceSession>> getSessions() async {
    final results = await StudyResultService.getResultsByType(
      voiceSessionType,
    );
    final sessions = <VoiceSession>[];

    for (final result in results) {
      final session = _decodeSession(result);
      if (session != null) sessions.add(session);
    }

    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions;
  }

  Future<List<VoiceSession>> getRecentSessions({
    String audiobookId = '',
    String chapterId = '',
    int limit = 5,
  }) async {
    final sessions = await getSessions();
    final safeAudiobookId = audiobookId.trim();
    final safeChapterId = chapterId.trim();

    return sessions
        .where((session) {
          final matchesAudiobook = safeAudiobookId.isEmpty ||
              session.audiobookId.trim() == safeAudiobookId;
          final matchesChapter = safeChapterId.isEmpty ||
              session.chapterId.trim() == safeChapterId;
          return matchesAudiobook && matchesChapter;
        })
        .take(limit)
        .toList();
  }

  Future<VoiceSession> addMessage({
    required VoiceSession session,
    required VoiceMessage message,
  }) async {
    final updated = session.copyWith(
      updatedAt: DateTime.now(),
      messages: [...session.messages, message],
    );
    await saveSession(updated);
    return updated;
  }

  Future<VoiceSession> finishSession(VoiceSession session) async {
    final updated = session.copyWith(
      status: 'finished',
      updatedAt: DateTime.now(),
    );
    await saveSession(updated);
    return updated;
  }

  VoiceMessage createMessage({
    required String role,
    required String content,
    String source = 'text',
    Map<String, dynamic> metadata = const {},
  }) {
    final now = DateTime.now();
    return VoiceMessage(
      messageId: 'voice_message_${now.microsecondsSinceEpoch}',
      role: role.trim().isEmpty ? 'user' : role.trim(),
      content: content.trim(),
      createdAt: now,
      source: source.trim().isEmpty ? 'text' : source.trim(),
      metadata: metadata,
    );
  }

  VoiceSession? _decodeSession(StudyResult result) {
    try {
      final decoded = jsonDecode(result.content);
      if (decoded is Map) {
        return VoiceSession.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}

    return null;
  }
}
