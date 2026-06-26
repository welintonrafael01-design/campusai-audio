import '../learning_engine/learning_analytics_service.dart';
import '../learning_engine/learning_session_service.dart';
import '../learning_engine/streak_service.dart';
import 'enterprise_intelligence_models.dart';
import 'enterprise_result_repository.dart';

/// Measures study quality from sessions, time, recovery, and consistency.
class ProductivityService {
  static const String resultType = 'productivity_snapshot';
  static const String latestDocumentId = 'productivity_snapshot_latest';

  final LearningSessionService sessionService;
  final LearningAnalyticsService analyticsService;
  final StreakService streakService;
  final EnterpriseResultRepository repository;

  const ProductivityService({
    this.sessionService = const LearningSessionService(),
    this.analyticsService = const LearningAnalyticsService(),
    this.streakService = const StreakService(),
    this.repository = const EnterpriseResultRepository(),
  });

  Future<ProductivitySnapshot> buildSnapshot() async {
    try {
      final sessions = await sessionService.getSessions();
      final analytics = await analyticsService.buildAnalytics();
      final streak = await streakService.calculateStreak();
      final qualities = sessions.take(20).map(_qualityFor).toList();
      final qualified =
          sessions.where((session) => _minutes(session) >= 25).toList();
      final deepMinutes =
          qualified.fold<int>(0, (sum, session) => sum + _minutes(session));
      final averageQuality = qualities.isEmpty
          ? 0
          : (qualities.map((item) => item.score).reduce((a, b) => a + b) /
                  qualities.length)
              .round();
      final fragmented = sessions
          .where((session) => _minutes(session) > 0 && _minutes(session) < 10)
          .length;
      final distraction = _score([
        fragmented * 16,
        sessions.isEmpty ? 35 : 0,
        analytics.averageMinutesPerSession < 12 && analytics.sessions > 2
            ? 20
            : 0,
      ]);
      final focus = _score([
        averageQuality,
        deepMinutes / 4,
        analytics.averageQuizScore,
      ]);
      final consistency = _score([
        streak.currentStreakDays * 12,
        analytics.sessions * 5,
      ]);
      final efficiency = _score([
        focus,
        analytics.masteryPercentage,
        100 - distraction,
      ]);
      final snapshot = ProductivitySnapshot(
        generatedAt: DateTime.now(),
        focus: StudyFocusScore(score: focus, level: _focusLevel(focus)),
        deepWork: DeepWorkCalculator(
            deepWorkMinutes: deepMinutes, qualifiedSessions: qualified.length),
        distraction: DistractionScore(
            score: distraction, estimatedLostMinutes: fragmented * 7),
        efficiency: StudyEfficiency(
            score: efficiency,
            recommendation: _efficiencyRecommendation(efficiency)),
        consistency: ConsistencyEngine(
            score: consistency, currentStreak: streak.currentStreakDays),
        sessionQualities: qualities,
      );
      await repository.save(
          documentId: latestDocumentId,
          type: resultType,
          payload: snapshot.toJson(),
          createdAt: snapshot.generatedAt);
      return snapshot;
    } catch (_) {
      return ProductivitySnapshot.empty();
    }
  }

  Future<ProductivitySnapshot?> getLatestSnapshot() async {
    final raw =
        await repository.load(documentId: latestDocumentId, type: resultType);
    return raw == null ? null : ProductivitySnapshot.fromJson(raw);
  }

  SessionQuality _qualityFor(Map<String, dynamic> session) {
    final minutes = _minutes(session);
    final total = _number(session['quiz_total']);
    final score = _number(session['quiz_score']);
    final quiz = total <= 0 ? 55 : ((score / total) * 100).round();
    final quality =
        _score([minutes * 3, quiz, _number(session['flashcards_viewed']) * 6]);
    return SessionQuality(
      sessionId: session['session_id']?.toString() ?? '',
      score: quality,
      label: quality >= 75
          ? 'Alta calidad'
          : quality >= 45
              ? 'Sostenida'
              : 'Fragmentada',
    );
  }

  int _minutes(Map<String, dynamic> session) =>
      (_number(session['duration_seconds']) / 60).round();
  int _number(dynamic value) =>
      value is num ? value.round() : int.tryParse('${value ?? ''}') ?? 0;
  int _score(List<num> values) => values.isEmpty
      ? 0
      : (values.reduce((a, b) => a + b) / values.length).round().clamp(0, 100);
  String _focusLevel(int score) => score >= 75
      ? 'Profundo'
      : score >= 45
          ? 'Estable'
          : 'Disperso';
  String _efficiencyRecommendation(int score) => score >= 70
      ? 'Mantén bloques de estudio de 25 minutos.'
      : 'Reduce interrupciones y prioriza un bloque corto de repaso activo.';
}
