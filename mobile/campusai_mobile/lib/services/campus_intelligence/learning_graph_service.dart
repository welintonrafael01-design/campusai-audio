import '../audiobook_service.dart';
import '../learning_engine/learning_progress_service.dart';
import '../study_result_service.dart';
import 'campus_intelligence_models.dart';

class LearningGraphService {
  final AudiobookService audiobookService;
  final LearningProgressService progressService;

  const LearningGraphService({
    this.audiobookService = const AudiobookService(),
    this.progressService = const LearningProgressService(),
  });

  Future<List<LearningGraphNode>> buildGraph() async {
    try {
      final results = await StudyResultService.getResultsByType('audiobook');
      final progressItems = await progressService.getAllProgress();
      final progressByAudioBook = {
        for (final item in progressItems)
          _cleanText(item['audiobook_id']): item,
      };
      final nodes = <LearningGraphNode>[];

      for (final result in results) {
        final audiobook = audiobookService.decodeAudioBook(result);
        final audiobookId = _firstText([
          audiobook['audiobook_id'],
          result.documentId,
        ]);
        final progress = progressByAudioBook[audiobookId] ?? {};
        final chapters =
            audiobookService.chapterListFrom(audiobook['chapters']);
        final completed = _stringList(progress['completed_chapters']).toSet();
        final mastered = _stringList(progress['mastered_chapters']).toSet();
        final competencies = _stringList(progress['competencies']);

        nodes.add(
          LearningGraphNode(
            id: audiobookId,
            title: _firstText([audiobook['title'], 'Audio Libro']),
            type: 'audiobook',
            mastery: _intFrom(progress['mastery_percentage']),
            status: completed.length >= chapters.length && chapters.isNotEmpty
                ? 'completed'
                : completed.isNotEmpty
                    ? 'in_progress'
                    : 'pending',
            relatedCompetencies: competencies,
          ),
        );

        for (final chapter in chapters) {
          final chapterId = _cleanText(chapter['chapter_id']);
          if (chapterId.isEmpty) continue;

          final learningPack = _mapFrom(chapter['learning_pack']);
          final chapterCompetencies = {
            ..._stringList(chapter['key_concepts']),
            ..._stringList(learningPack['competencies']),
          }.take(6).toList();
          final isMastered = mastered.contains(chapterId);
          final isCompleted = completed.contains(chapterId);

          nodes.add(
            LearningGraphNode(
              id: chapterId,
              title: _firstText([chapter['title'], 'Capítulo']),
              type: 'chapter',
              mastery: isMastered
                  ? 100
                  : isCompleted
                      ? 70
                      : 0,
              status: isMastered
                  ? 'mastered'
                  : isCompleted
                      ? 'completed'
                      : 'pending',
              dependencies: [audiobookId],
              relatedCompetencies: chapterCompetencies,
            ),
          );

          for (final competency in chapterCompetencies) {
            nodes.add(
              LearningGraphNode(
                id: 'competency_${_slug(competency)}',
                title: competency,
                type: 'competency',
                mastery: isMastered ? 85 : 45,
                status: isMastered ? 'strong' : 'developing',
                dependencies: [chapterId],
                relatedCompetencies: [competency],
              ),
            );
          }

          final flashcards = _mapList(learningPack['flashcards']);
          if (flashcards.isNotEmpty) {
            nodes.add(
              LearningGraphNode(
                id: '${chapterId}_flashcards',
                title: 'Flashcards',
                type: 'flashcard',
                mastery: isCompleted ? 65 : 20,
                status: isCompleted ? 'available' : 'pending',
                dependencies: [chapterId],
                relatedCompetencies: chapterCompetencies,
              ),
            );
          }

          final quiz = _mapList(learningPack['mini_quiz']);
          if (quiz.isNotEmpty) {
            nodes.add(
              LearningGraphNode(
                id: '${chapterId}_quiz',
                title: 'Mini quiz',
                type: 'quiz',
                mastery: isMastered ? 90 : 35,
                status: isMastered ? 'passed' : 'pending',
                dependencies: [chapterId],
                relatedCompetencies: chapterCompetencies,
              ),
            );
          }
        }
      }

      return _deduplicate(nodes).take(120).toList();
    } catch (_) {
      return const [];
    }
  }

  List<LearningGraphNode> _deduplicate(List<LearningGraphNode> nodes) {
    final byId = <String, LearningGraphNode>{};
    for (final node in nodes) {
      if (node.id.trim().isEmpty) continue;
      byId.putIfAbsent(node.id, () => node);
    }
    return byId.values.toList();
  }

  Map<String, dynamic> _mapFrom(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _mapList(dynamic raw) {
    if (raw is! List) return <Map<String, dynamic>>[];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  List<String> _stringList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    final text = _cleanText(raw);
    return text.isEmpty ? <String>[] : <String>[text];
  }

  String _firstText(List<dynamic> values) {
    for (final value in values) {
      final text = _cleanText(value);
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  String _cleanText(dynamic value) => value?.toString().trim() ?? '';

  int _intFrom(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _slug(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9áéíóúñ]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
