import '../audiobook_progress_service.dart';
import '../audiobook_service.dart';
import '../campus_intelligence/campus_intelligence_models.dart';
import '../campus_intelligence/campus_intelligence_service.dart';
import '../campus_intelligence/campus_trend_service.dart';
import '../learning_engine/learning_analytics_service.dart';
import '../learning_engine/learning_progress_service.dart';
import '../learning_engine/recommendation_engine.dart';
import '../learning_engine/student_intelligence_service.dart';
import '../study_result_service.dart';
import 'voice_models.dart';

class VoiceContextService {
  final AudiobookService audiobookService;
  final AudiobookProgressService audiobookProgressService;
  final LearningProgressService learningProgressService;
  final LearningAnalyticsService analyticsService;
  final RecommendationEngine recommendationEngine;
  final StudentIntelligenceService intelligenceService;
  final CampusIntelligenceService campusIntelligenceService;
  final CampusTrendService campusTrendService;

  const VoiceContextService({
    this.audiobookService = const AudiobookService(),
    this.audiobookProgressService = const AudiobookProgressService(),
    this.learningProgressService = const LearningProgressService(),
    this.analyticsService = const LearningAnalyticsService(),
    this.recommendationEngine = const RecommendationEngine(),
    this.intelligenceService = const StudentIntelligenceService(),
    this.campusIntelligenceService = const CampusIntelligenceService(),
    this.campusTrendService = const CampusTrendService(),
  });

  Future<VoiceContext> buildContext({
    String audiobookId = '',
    String chapterId = '',
    Map<String, dynamic> extra = const {},
  }) async {
    try {
      final cleanAudiobookId = _firstText([
        audiobookId,
        extra['audiobookId'],
        extra['audiobook_id'],
      ]);
      final cleanChapterId = _firstText([
        chapterId,
        extra['chapterId'],
        extra['chapter_id'],
      ]);

      final audiobook = await _loadAudiobook(cleanAudiobookId, extra);
      final resolvedAudiobookId = _firstText([
        audiobook['audiobook_id'],
        cleanAudiobookId,
      ]);
      final chapters = audiobookService.chapterListFrom(audiobook['chapters']);
      final chapter = _chapterById(chapters, cleanChapterId);
      final resolvedChapterId = _firstText([
        chapter['chapter_id'],
        cleanChapterId,
      ]);
      final learningPack = _mapFrom(chapter['learning_pack']);
      final learningProgress = resolvedAudiobookId.isEmpty
          ? <String, dynamic>{}
          : await learningProgressService.getProgress(resolvedAudiobookId);
      final recommendations =
          await recommendationEngine.generateRecommendations();
      final intelligence = await intelligenceService.analyzeStudent();
      final campusSnapshot = await campusIntelligenceService.buildSnapshot();
      final campusTrends = await campusTrendService.buildTrends();
      final masteryTrend = _trendDescription(campusTrends, 'Dominio');
      final riskTrend = _trendDescription(campusTrends, 'Riesgo');
      final latestRelevantChange = _latestRelevantChange(campusTrends);

      // Touch analytics/progress services here so callers get one contextual API.
      await analyticsService.buildAnalytics();
      if (resolvedAudiobookId.isNotEmpty) {
        await audiobookProgressService.getProgress(resolvedAudiobookId);
      }

      return VoiceContext(
        audiobookId: resolvedAudiobookId,
        chapterId: resolvedChapterId,
        audiobookTitle: _firstText([
          audiobook['title'],
          extra['title'],
          'Audio Libro',
        ]),
        chapterTitle: _firstText([
          chapter['title'],
          extra['chapterTitle'],
          extra['chapter_title'],
          resolvedChapterId,
        ]),
        chapterSummary: _firstText([
          chapter['summary'],
          learningPack['summary'],
        ]),
        transcript: _limit(
          _firstText([
            chapter['transcript'],
            chapter['script'],
            chapter['content'],
          ]),
          1800,
        ),
        keyConcepts: {
          ..._stringList(chapter['key_concepts']),
          ..._stringList(audiobook['key_concepts']),
        }.take(8).toList(),
        learningPackSummary: _limit(
          _firstText([
            learningPack['summary'],
            learningPack['overview'],
            chapter['summary'],
          ]),
          900,
        ),
        flashcards: _mapList(learningPack['flashcards']).take(6).toList(),
        miniQuiz: _mapList(learningPack['mini_quiz']).take(6).toList(),
        competencies: {
          ..._stringList(learningPack['competencies']),
          ..._stringList(learningProgress['competencies']),
          ...intelligence.strongCompetencies,
          ...intelligence.weakCompetencies,
        }.take(10).toList(),
        mastery: _intFrom(learningProgress['mastery_percentage']),
        recommendations:
            recommendations.map((item) => item.title).take(5).toList(),
        recommendedNextAction: _limit(
          campusSnapshot.recommendedNextAction,
          160,
        ),
        academicRisk: campusSnapshot.academicRisk,
        campusWeaknesses: campusSnapshot.weaknesses.take(4).toList(),
        adaptivePlanSummary: campusSnapshot.adaptivePlan
            .map((item) => item.title)
            .take(4)
            .toList(),
        masteryTrend: _limit(masteryTrend, 160),
        riskTrend: _limit(riskTrend, 160),
        latestRelevantChange: _limit(latestRelevantChange, 180),
        longitudinalRecommendation: _limit(
          campusSnapshot.recommendedNextAction,
          160,
        ),
      );
    } catch (_) {
      return VoiceContext.empty;
    }
  }

  Future<Map<String, dynamic>> _loadAudiobook(
    String audiobookId,
    Map<String, dynamic> extra,
  ) async {
    final extraAudiobook = extra['audiobook'];
    if (extraAudiobook is Map) {
      return Map<String, dynamic>.from(extraAudiobook);
    }

    if (audiobookId.trim().isEmpty) return <String, dynamic>{};

    final result = await StudyResultService.getResult(
      documentId: audiobookId.trim(),
      type: 'audiobook',
    );
    if (result == null) return {'audiobook_id': audiobookId.trim()};

    return audiobookService.decodeAudioBook(result);
  }

  Map<String, dynamic> _chapterById(
    List<Map<String, dynamic>> chapters,
    String chapterId,
  ) {
    if (chapters.isEmpty) return <String, dynamic>{};

    final cleanChapterId = chapterId.trim();
    if (cleanChapterId.isEmpty) return chapters.first;

    return chapters.firstWhere(
      (chapter) => _cleanText(chapter['chapter_id']) == cleanChapterId,
      orElse: () => chapters.first,
    );
  }

  String _firstText(List<dynamic> values) {
    for (final value in values) {
      final text = _cleanText(value);
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  String _limit(String value, int maxLength) {
    final text = value.trim();
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  String _trendDescription(List<CampusTrend> trends, String metric) {
    final cleanMetric = metric.trim().toLowerCase();
    for (final trend in trends) {
      final trendMetric = trend.metric.trim().toLowerCase();
      if (trendMetric == cleanMetric) {
        return trend.description;
      }
    }
    return '';
  }

  String _latestRelevantChange(List<CampusTrend> trends) {
    for (final trend in trends) {
      final direction = trend.direction;
      final description = trend.description;
      if (direction != 'stable' && description.trim().isNotEmpty) {
        return description;
      }
    }
    return trends.isNotEmpty
        ? trends.first.description
        : 'Sin cambios longitudinales suficientes.';
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

  String _cleanText(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  int _intFrom(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
