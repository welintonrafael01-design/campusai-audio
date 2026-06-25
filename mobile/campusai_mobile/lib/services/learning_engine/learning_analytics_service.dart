import 'dart:convert';

import '../audiobook_progress_service.dart';
import '../study_result_service.dart';
import 'learning_models.dart';
import 'learning_progress_service.dart';
import 'learning_session_service.dart';

/// Builds aggregate learning metrics from local Student Studio persistence.
class LearningAnalyticsService {
  final LearningProgressService progressService;
  final LearningSessionService sessionService;
  final AudiobookProgressService audiobookProgressService;

  const LearningAnalyticsService({
    this.progressService = const LearningProgressService(),
    this.sessionService = const LearningSessionService(),
    this.audiobookProgressService = const AudiobookProgressService(),
  });

  Future<LearningAnalytics> buildAnalytics() async {
    try {
      final sessions = await sessionService.getSessions();
      final progressItems = await progressService.getAllProgress();
      final audioProgressItems =
          await audiobookProgressService.getAllProgress();
      final audiobooks = await StudyResultService.getResultsByType('audiobook');

      final studySeconds = sessions.fold<int>(
        0,
        (sum, session) => sum + _intFrom(session['duration_seconds']),
      );
      final sessionCount = sessions.length;
      final studyMinutes = (studySeconds / 60).round();
      final completedChapters = _uniqueCount(
        progressItems.expand((item) => _stringList(item['completed_chapters'])),
      );
      final masteredChapters = _uniqueCount(
        progressItems.expand((item) => _stringList(item['mastered_chapters'])),
      );
      final quizPercentages = <int>[
        for (final item in progressItems)
          for (final quiz in _mapList(item['quiz_results']))
            _intFrom(quiz['percentage']),
      ].where((value) => value > 0).toList();
      final quizCompleted = progressItems.fold<int>(
        0,
        (sum, item) => sum + _mapList(item['quiz_results']).length,
      );
      final flashcardsStudied = sessions.fold<int>(
        0,
        (sum, session) => sum + _intFrom(session['flashcards_viewed']),
      );
      final audioSeconds = audioProgressItems.fold<int>(
        0,
        (sum, item) => sum + _intFrom(item['current_position_seconds']),
      );

      return LearningAnalytics(
        studyMinutes: studyMinutes,
        studyHours: _roundDouble(studyMinutes / 60),
        sessions: sessionCount,
        averageMinutesPerSession:
            sessionCount == 0 ? 0 : _roundDouble(studyMinutes / sessionCount),
        completedChapters: completedChapters,
        masteredChapters: masteredChapters,
        masteryPercentage: _average([
          for (final item in progressItems)
            _intFrom(item['mastery_percentage']),
        ]),
        quizCompleted: quizCompleted,
        averageQuizScore: _average(quizPercentages),
        flashcardsStudied: flashcardsStudied,
        audioSecondsListened: audioSeconds,
        audioMinutesListened: (audioSeconds / 60).round(),
        audiobooksStarted: audiobooks.length,
      );
    } catch (_) {
      return LearningAnalytics.empty;
    }
  }

  Future<ContinueLearningItem> buildContinueLearningItem() async {
    try {
      final progressItems = await audiobookProgressService.getAllProgress();
      if (progressItems.isEmpty) return ContinueLearningItem.empty;

      final activeItems = audiobookProgressService.activeProgressItems(
        progressItems,
      );
      final sortedItems = activeItems.isNotEmpty
          ? activeItems
          : _sortProgressByLastPlayed(progressItems);
      if (sortedItems.isEmpty) return ContinueLearningItem.empty;

      final progress = sortedItems.first;
      final audiobookId = _cleanText(progress['audiobook_id']);
      if (audiobookId.isEmpty) return ContinueLearningItem.empty;

      final audiobook = await _audioBookById(audiobookId);
      final currentChapterId = _cleanText(progress['current_chapter_id']);
      final chapters = _mapList(audiobook['chapters']);
      final chapter = chapters.firstWhere(
        (item) => _cleanText(item['chapter_id']) == currentChapterId,
        orElse: () => <String, dynamic>{},
      );

      return ContinueLearningItem(
        audiobookId: audiobookId,
        audiobookTitle: _audioBookTitle(audiobook, audiobookId),
        chapterId: currentChapterId,
        chapterTitle: _chapterTitle(chapter, currentChapterId),
        progressPercentage:
            _intFrom(progress['completion_percentage']).clamp(0, 100),
        lastPlayedAt: DateTime.tryParse(
          _cleanText(progress['last_played_at']),
        ),
      );
    } catch (_) {
      return ContinueLearningItem.empty;
    }
  }

  int _average(List<int> values) {
    final cleanValues = values.where((value) => value > 0).toList();
    if (cleanValues.isEmpty) return 0;
    return (cleanValues.fold<int>(0, (sum, value) => sum + value) /
            cleanValues.length)
        .round()
        .clamp(0, 100);
  }

  int _uniqueCount(Iterable<String> values) {
    return values
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .length;
  }

  double _roundDouble(double value) {
    return double.parse(value.toStringAsFixed(2));
  }

  int _intFrom(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
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
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<Map<String, dynamic>> _sortProgressByLastPlayed(
    List<Map<String, dynamic>> progressItems,
  ) {
    final sorted = [...progressItems];
    sorted.sort((a, b) {
      final dateA = DateTime.tryParse(_cleanText(a['last_played_at'])) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = DateTime.tryParse(_cleanText(b['last_played_at'])) ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });
    return sorted;
  }

  Future<Map<String, dynamic>> _audioBookById(String audiobookId) async {
    final result = await StudyResultService.getResult(
      documentId: audiobookId,
      type: 'audiobook',
    );

    if (result == null) return {'audiobook_id': audiobookId};

    try {
      final decoded = jsonDecode(result.content);
      if (decoded is Map) {
        return {
          'audiobook_id': audiobookId,
          ...Map<String, dynamic>.from(decoded),
        };
      }
    } catch (_) {}

    return {'audiobook_id': audiobookId};
  }

  String _audioBookTitle(Map<String, dynamic> audiobook, String fallbackId) {
    final title = _cleanText(audiobook['title']);
    if (title.isNotEmpty) return title;

    final unitTopic = _cleanText(audiobook['unit_topic']);
    if (unitTopic.isNotEmpty) return 'Audio Libro - $unitTopic';

    return fallbackId.isEmpty ? 'Audio Libro' : fallbackId;
  }

  String _chapterTitle(Map<String, dynamic> chapter, String fallbackId) {
    final title = _cleanText(chapter['title']);
    if (title.isNotEmpty) return title;

    final number = _intFrom(chapter['chapter_number']);
    if (number > 0) return 'Capítulo $number';

    return fallbackId.isEmpty ? 'Capítulo actual' : fallbackId;
  }

  String _cleanText(dynamic value) {
    return value?.toString().trim() ?? '';
  }
}
