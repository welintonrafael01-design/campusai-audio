import 'dart:convert';

import '../models/study_result.dart';
import 'study_result_service.dart';

class AudiobookProgressService {
  const AudiobookProgressService();

  Future<Map<String, dynamic>> getProgress(String audiobookId) async {
    final cleanId = audiobookId.trim();
    if (cleanId.isEmpty) return defaultProgress('');

    final result = await StudyResultService.getResult(
      documentId: '${cleanId}_progress',
      type: 'audiobook_progress',
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
        };
      }
    } catch (_) {}

    return defaultProgress(cleanId);
  }

  Future<List<Map<String, dynamic>>> getAllProgress() async {
    final results = await StudyResultService.getResultsByType(
      'audiobook_progress',
    );
    final progressItems = <Map<String, dynamic>>[];

    for (final result in results) {
      try {
        final decoded = jsonDecode(result.content);
        if (decoded is Map) {
          final progress = Map<String, dynamic>.from(decoded);
          final audiobookId = progress['audiobook_id']?.toString().trim() ?? '';
          progressItems.add({
            ...defaultProgress(audiobookId),
            ...progress,
            'audiobook_id': audiobookId,
            'completed_chapters': _stringList(progress['completed_chapters']),
          });
        }
      } catch (_) {
        // Progreso corrupto: se ignora para no romper la biblioteca.
      }
    }

    return progressItems;
  }

  Map<String, dynamic> progressForAudioBook(
    String audiobookId,
    List<Map<String, dynamic>> progressItems,
  ) {
    final cleanId = audiobookId.trim();
    if (cleanId.isEmpty) return defaultProgress('');

    for (final progress in progressItems) {
      if ((progress['audiobook_id']?.toString().trim() ?? '') == cleanId) {
        return {
          ...defaultProgress(cleanId),
          ...progress,
          'completed_chapters': _stringList(progress['completed_chapters']),
        };
      }
    }

    return defaultProgress(cleanId);
  }

  String statusFromProgress(Map<String, dynamic> progress) {
    final completion = _intFrom(progress['completion_percentage']);
    if (completion >= 100) return 'Completado';
    if (completion > 0 || _intFrom(progress['current_position_seconds']) > 0) {
      return 'En progreso';
    }
    return 'No iniciado';
  }

  DateTime? lastPlayedAt(Map<String, dynamic> progress) {
    final value = progress['last_played_at']?.toString().trim() ?? '';
    return DateTime.tryParse(value);
  }

  List<Map<String, dynamic>> activeProgressItems(
    List<Map<String, dynamic>> progressItems,
  ) {
    final active = progressItems.where((progress) {
      final completion = _intFrom(progress['completion_percentage']);
      return completion > 0 && completion < 100;
    }).toList();

    active.sort((a, b) {
      final dateA = lastPlayedAt(a) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateB = lastPlayedAt(b) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return dateB.compareTo(dateA);
    });

    return active;
  }

  Future<void> saveProgress({
    required String audiobookId,
    required String currentChapterId,
    int currentPositionSeconds = 0,
    List<String> completedChapters = const [],
    int totalChapters = 0,
  }) async {
    final cleanId = audiobookId.trim();
    if (cleanId.isEmpty) return;

    final uniqueCompleted = completedChapters
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
    final completionPercentage = totalChapters <= 0
        ? 0
        : ((uniqueCompleted.length / totalChapters) * 100).round();
    final payload = {
      'audiobook_id': cleanId,
      'current_chapter_id': currentChapterId,
      'current_position_seconds': currentPositionSeconds,
      'completed_chapters': uniqueCompleted,
      'completion_percentage': completionPercentage.clamp(0, 100),
      'last_played_at': DateTime.now().toIso8601String(),
    };

    await StudyResultService.saveResult(
      StudyResult(
        documentId: '${cleanId}_progress',
        type: 'audiobook_progress',
        content: jsonEncode(payload),
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  Future<Map<String, dynamic>> markChapterCompleted({
    required String audiobookId,
    required String chapterId,
    required List<Map<String, dynamic>> chapters,
    int currentPositionSeconds = 0,
  }) async {
    final cleanId = audiobookId.trim();
    final cleanChapterId = chapterId.trim();
    if (cleanId.isEmpty) return defaultProgress('');

    final current = await getProgress(cleanId);
    final completed = _stringList(current['completed_chapters']).toSet();
    if (cleanChapterId.isNotEmpty) completed.add(cleanChapterId);

    final nextId = nextChapterId(chapters, cleanChapterId);
    await saveProgress(
      audiobookId: cleanId,
      currentChapterId: nextId.isNotEmpty ? nextId : cleanChapterId,
      currentPositionSeconds: nextId.isNotEmpty ? 0 : currentPositionSeconds,
      completedChapters: completed.toList(),
      totalChapters: chapters.length,
    );

    return getProgress(cleanId);
  }

  int calculateCompletionPercentage({
    required List<String> completedChapters,
    required int totalChapters,
  }) {
    if (totalChapters <= 0) return 0;

    final uniqueCompleted = completedChapters
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet();

    return ((uniqueCompleted.length / totalChapters) * 100)
        .round()
        .clamp(0, 100);
  }

  String nextChapterId(
    List<Map<String, dynamic>> chapters,
    String currentChapterId,
  ) {
    if (chapters.isEmpty) return '';

    final currentIndex = chapters.indexWhere(
      (chapter) => chapter['chapter_id']?.toString().trim() == currentChapterId,
    );
    if (currentIndex < 0 || currentIndex + 1 >= chapters.length) return '';

    return chapters[currentIndex + 1]['chapter_id']?.toString().trim() ?? '';
  }

  Map<String, dynamic> defaultProgress(String audiobookId) {
    return {
      'audiobook_id': audiobookId.trim(),
      'current_chapter_id': '',
      'current_position_seconds': 0,
      'completed_chapters': <String>[],
      'completion_percentage': 0,
      'last_played_at': '',
    };
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

  int _intFrom(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
