import 'voice_models.dart';
import 'voice_session_service.dart';

class VoiceMemoryService {
  final VoiceSessionService sessionService;

  const VoiceMemoryService({
    this.sessionService = const VoiceSessionService(),
  });

  Future<List<VoiceMessage>> recentMessages({
    String audiobookId = '',
    String chapterId = '',
    int limit = 8,
  }) async {
    try {
      final sessions = await sessionService.getRecentSessions(
        audiobookId: audiobookId,
        chapterId: chapterId,
        limit: 4,
      );
      final messages = <VoiceMessage>[];

      for (final session in sessions) {
        messages.addAll(session.messages);
      }

      messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return messages
          .where((message) => message.content.trim().isNotEmpty)
          .take(limit)
          .toList()
          .reversed
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<String> summarizeMemory({
    String audiobookId = '',
    String chapterId = '',
  }) async {
    final messages = await recentMessages(
      audiobookId: audiobookId,
      chapterId: chapterId,
      limit: 6,
    );
    if (messages.isEmpty) return '';

    final userMessages = messages
        .where((message) => message.role == 'user')
        .map((message) => _limit(message.content, 90))
        .where((text) => text.isNotEmpty)
        .take(3)
        .toList();

    if (userMessages.isEmpty) return '';
    return 'Temas recientes consultados: ${userMessages.join(' | ')}';
  }

  List<Map<String, dynamic>> compactMessages(
    List<VoiceMessage> messages, {
    int limit = 8,
  }) {
    return messages.take(limit).map((message) {
      return {
        'role': message.role,
        'content': _limit(message.content, 180),
        'created_at': message.createdAt.toIso8601String(),
      };
    }).toList();
  }

  String _limit(String value, int maxLength) {
    final text = value.trim();
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
