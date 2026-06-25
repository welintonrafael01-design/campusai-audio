import 'dart:convert';

import '../../models/study_result.dart';
import '../study_result_service.dart';

class LearningProgressService {
  const LearningProgressService();

  static const String progressType = 'student_learning_progress';
  static const String sessionType = 'learning_session';

  Future<Map<String, dynamic>> getProgress(String audiobookId) async {
    final cleanId = audiobookId.trim();
    if (cleanId.isEmpty) return defaultProgress('');

    final result = await StudyResultService.getResult(
      documentId: '${cleanId}_learning_progress',
      type: progressType,
    );

    if (result == null) return defaultProgress(cleanId);

    try {
      final decoded = jsonDecode(result.content);
      if (decoded is Map) {
        final progress = Map<String, dynamic>.from(decoded);
        return {
          ...defaultProgress(cleanId),
          ...progress,
          'audiobook_id': cleanId,
          'completed_chapters': _stringList(progress['completed_chapters']),
          'mastered_chapters': _stringList(progress['mastered_chapters']),
          'quiz_results': _mapList(progress['quiz_results']),
          'competencies': _stringList(progress['competencies']),
          'recommendations': _stringList(progress['recommendations']),
        };
      }
    } catch (_) {}

    return defaultProgress(cleanId);
  }

  Future<List<Map<String, dynamic>>> getAllProgress() async {
    final results = await StudyResultService.getResultsByType(progressType);
    final items = <Map<String, dynamic>>[];

    for (final result in results) {
      try {
        final decoded = jsonDecode(result.content);
        if (decoded is Map) {
          final map = Map<String, dynamic>.from(decoded);
          final audiobookId = map['audiobook_id']?.toString().trim() ?? '';
          items.add({
            ...defaultProgress(audiobookId),
            ...map,
            'audiobook_id': audiobookId,
            'completed_chapters': _stringList(map['completed_chapters']),
            'mastered_chapters': _stringList(map['mastered_chapters']),
            'quiz_results': _mapList(map['quiz_results']),
            'competencies': _stringList(map['competencies']),
            'recommendations': _stringList(map['recommendations']),
          });
        }
      } catch (_) {}
    }

    items.sort((a, b) {
      final aDate = DateTime.tryParse(a['updated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse(b['updated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return items;
  }

  Future<Map<String, dynamic>> saveQuizResult({
    required String audiobookId,
    required String chapterId,
    required int score,
    required int total,
    List<String> competencies = const [],
  }) async {
    final cleanId = audiobookId.trim();
    final cleanChapterId = chapterId.trim();

    if (cleanId.isEmpty || cleanChapterId.isEmpty) {
      return defaultProgress(cleanId);
    }

    final current = await getProgress(cleanId);
    final quizResults = _mapList(current['quiz_results']);

    quizResults.removeWhere(
      (item) => item['chapter_id']?.toString().trim() == cleanChapterId,
    );

    final safeTotal = total <= 0 ? 1 : total;
    final percentage = ((score / safeTotal) * 100).round().clamp(0, 100);

    quizResults.add({
      'chapter_id': cleanChapterId,
      'score': score.clamp(0, safeTotal),
      'total': safeTotal,
      'percentage': percentage,
      'passed': percentage >= 70,
      'completed_at': DateTime.now().toIso8601String(),
    });

    final mastered = _stringList(current['mastered_chapters']).toSet();
    if (percentage >= 80) {
      mastered.add(cleanChapterId);
    } else {
      mastered.remove(cleanChapterId);
    }

    final mergedCompetencies = {
      ..._stringList(current['competencies']),
      ...competencies.map((item) => item.trim()).where((item) => item.isNotEmpty),
    }.toList();

    final updated = {
      ...current,
      'audiobook_id': cleanId,
      'quiz_results': quizResults,
      'mastered_chapters': mastered.toList(),
      'competencies': mergedCompetencies,
      'mastery_percentage': calculateMasteryPercentage(
        quizResults: quizResults,
        masteredChapters: mastered.toList(),
      ),
      'recommendations': buildRecommendations(
        quizResults: quizResults,
        masteredChapters: mastered.toList(),
      ),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _saveProgress(cleanId, updated);
    return updated;
  }

  Future<Map<String, dynamic>> markChapterLearned({
    required String audiobookId,
    required String chapterId,
    int totalChapters = 0,
  }) async {
    final cleanId = audiobookId.trim();
    final cleanChapterId = chapterId.trim();

    if (cleanId.isEmpty || cleanChapterId.isEmpty) {
      return defaultProgress(cleanId);
    }

    final current = await getProgress(cleanId);
    final completed = _stringList(current['completed_chapters']).toSet();
    final mastered = _stringList(current['mastered_chapters']).toSet();

    completed.add(cleanChapterId);
    mastered.add(cleanChapterId);

    final updated = {
      ...current,
      'audiobook_id': cleanId,
      'completed_chapters': completed.toList(),
      'mastered_chapters': mastered.toList(),
      'completion_percentage': totalChapters <= 0
          ? _intFrom(current['completion_percentage'])
          : ((completed.length / totalChapters) * 100).round().clamp(0, 100),
      'mastery_percentage': totalChapters <= 0
          ? _intFrom(current['mastery_percentage'])
          : ((mastered.length / totalChapters) * 100).round().clamp(0, 100),
      'recommendations': buildRecommendations(
        quizResults: _mapList(current['quiz_results']),
        masteredChapters: mastered.toList(),
      ),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _saveProgress(cleanId, updated);
    return updated;
  }

  Future<void> saveLearningSession({
    required String audiobookId,
    required String chapterId,
    required int durationSeconds,
    int quizScore = 0,
    int quizTotal = 0,
    int flashcardsViewed = 0,
  }) async {
    final cleanId = audiobookId.trim();
    if (cleanId.isEmpty) return;

    final sessionId =
        '${cleanId}_${chapterId.trim()}_${DateTime.now().millisecondsSinceEpoch}';

    final payload = {
      'session_id': sessionId,
      'audiobook_id': cleanId,
      'chapter_id': chapterId.trim(),
      'duration_seconds': durationSeconds < 0 ? 0 : durationSeconds,
      'quiz_score': quizScore,
      'quiz_total': quizTotal,
      'flashcards_viewed': flashcardsViewed < 0 ? 0 : flashcardsViewed,
      'started_at': DateTime.now()
          .subtract(Duration(seconds: durationSeconds < 0 ? 0 : durationSeconds))
          .toIso8601String(),
      'ended_at': DateTime.now().toIso8601String(),
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

  Future<List<Map<String, dynamic>>> getLearningSessions() async {
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
      final aDate = DateTime.tryParse(a['ended_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = DateTime.tryParse(b['ended_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });

    return sessions;
  }

  int calculateMasteryPercentage({
    required List<Map<String, dynamic>> quizResults,
    required List<String> masteredChapters,
  }) {
    if (quizResults.isEmpty && masteredChapters.isEmpty) return 0;

    final quizAverage = quizResults.isEmpty
        ? 0
        : (quizResults
                    .map((item) => _intFrom(item['percentage']))
                    .fold<int>(0, (sum, value) => sum + value) /
                quizResults.length)
            .round();

    final masteryBoost = masteredChapters.isEmpty ? 0 : 10;

    return (quizAverage + masteryBoost).clamp(0, 100);
  }

  List<String> buildRecommendations({
    required List<Map<String, dynamic>> quizResults,
    required List<String> masteredChapters,
  }) {
    final recommendations = <String>[];

    final weakResults = quizResults
        .where((item) => _intFrom(item['percentage']) < 70)
        .toList();

    if (quizResults.isEmpty) {
      recommendations.add('Realiza el mini quiz del capítulo para medir tu comprensión.');
    }

    if (weakResults.isNotEmpty) {
      recommendations.add('Repite los capítulos con menor puntuación antes de avanzar.');
      recommendations.add('Repasa las flashcards y vuelve a intentar el mini quiz.');
    }

    if (masteredChapters.isEmpty && quizResults.isNotEmpty) {
      recommendations.add('Marca como aprendidos los capítulos que ya dominas.');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Buen progreso. Continúa con el siguiente capítulo.');
    }

    return recommendations;
  }

  Map<String, dynamic> defaultProgress(String audiobookId) {
    return {
      'audiobook_id': audiobookId.trim(),
      'completed_chapters': <String>[],
      'mastered_chapters': <String>[],
      'quiz_results': <Map<String, dynamic>>[],
      'competencies': <String>[],
      'recommendations': <String>[],
      'completion_percentage': 0,
      'mastery_percentage': 0,
      'updated_at': '',
    };
  }

  Future<void> _saveProgress(
    String audiobookId,
    Map<String, dynamic> payload,
  ) async {
    await StudyResultService.saveResult(
      StudyResult(
        documentId: '${audiobookId}_learning_progress',
        type: progressType,
        content: jsonEncode(payload),
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  List<String> _stringList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final text = raw?.toString().trim() ?? '';
    return text.isEmpty ? <String>[] : <String>[text];
  }

  List<Map<String, dynamic>> _mapList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return <Map<String, dynamic>>[];
  }

  int _intFrom(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
