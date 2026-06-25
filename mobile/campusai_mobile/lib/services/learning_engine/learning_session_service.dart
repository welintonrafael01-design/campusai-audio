import 'dart:convert';

import '../../models/study_result.dart';
import '../study_result_service.dart';

class LearningSessionService {
  const LearningSessionService();

  static const String sessionType = 'learning_session';

  Future<void> saveSession({
    required String audiobookId,
    required String chapterId,
    required int durationSeconds,
    int quizScore = 0,
    int quizTotal = 0,
    int flashcardsViewed = 0,
  }) async {
    final cleanAudiobookId = audiobookId.trim();
    final cleanChapterId = chapterId.trim();

    if (cleanAudiobookId.isEmpty) return;

    final safeDuration = durationSeconds < 0 ? 0 : durationSeconds;
    final sessionId =
        '${cleanAudiobookId}_${cleanChapterId}_${DateTime.now().millisecondsSinceEpoch}';

    final payload = {
      'session_id': sessionId,
      'audiobook_id': cleanAudiobookId,
      'chapter_id': cleanChapterId,
      'duration_seconds': safeDuration,
      'quiz_score': quizScore,
      'quiz_total': quizTotal,
      'flashcards_viewed': flashcardsViewed < 0 ? 0 : flashcardsViewed,
      'started_at': DateTime.now()
          .subtract(Duration(seconds: safeDuration))
          .toIso8601String(),
      'ended_at': DateTime.now().toIso8601String(),
      'status': 'completed',
    };

    await StudyResultService.saveResult(
      StudyResult(
        documentId: sessionId,
        type: sessionType,
        content: jsonEncode(payload),
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    final results = await StudyResultService.getResultsByType(sessionType);
    final sessions = <Map<String, dynamic>>[];

    for (final result in results) {
      try {
        final decoded = jsonDecode(result.content);
        if (decoded is Map) {
          sessions.add(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {}
    }

    sessions.sort((a, b) {
      final dateA = DateTime.tryParse(a['ended_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = DateTime.tryParse(b['ended_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });

    return sessions;
  }

  Future<int> totalStudyMinutes() async {
    final sessions = await getSessions();

    final seconds = sessions.fold<int>(
      0,
      (sum, session) => sum + _intFrom(session['duration_seconds']),
    );

    return (seconds / 60).round();
  }

  Future<int> totalSessions() async {
    final sessions = await getSessions();
    return sessions.length;
  }

  int _intFrom(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
