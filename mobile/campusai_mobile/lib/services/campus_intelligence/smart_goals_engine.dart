import '../learning_engine/learning_analytics_service.dart';
import '../learning_engine/streak_service.dart';
import 'campus_snapshot_repository.dart';
import 'enterprise_intelligence_models.dart';
import 'enterprise_result_repository.dart';
import 'knowledge_map_service.dart';

/// Generates practical, rule-based goals without introducing an AI dependency.
class SmartGoalsEngine {
  static const String resultType = 'study_goals';
  static const String latestDocumentId = 'study_goals_latest';

  final LearningAnalyticsService analyticsService;
  final StreakService streakService;
  final CampusSnapshotRepository snapshotRepository;
  final KnowledgeMapService knowledgeMapService;
  final EnterpriseResultRepository repository;

  const SmartGoalsEngine({
    this.analyticsService = const LearningAnalyticsService(),
    this.streakService = const StreakService(),
    this.snapshotRepository = const CampusSnapshotRepository(),
    this.knowledgeMapService = const KnowledgeMapService(),
    this.repository = const EnterpriseResultRepository(),
  });

  Future<StudyGoals> buildGoals({KnowledgeMap? knowledgeMap}) async {
    try {
      final analytics = await analyticsService.buildAnalytics();
      final streak = await streakService.calculateStreak();
      final snapshot = await snapshotRepository.getLatestSnapshot();
      final map = knowledgeMap ?? await knowledgeMapService.buildKnowledgeMap();
      final risk = snapshot?.academicRisk ?? 'Sin datos';
      final success = _score([
        analytics.masteryPercentage,
        analytics.averageQuizScore,
        streak.currentStreakDays * 12,
        snapshot?.studentScore ?? 0,
      ]);
      final goals = [
        SmartStudyGoal(
          id: 'pass_next_assessment',
          title: 'Aprobar la próxima evaluación',
          type: 'assessment',
          progress:
              _score([analytics.averageQuizScore, analytics.masteryPercentage]),
          probability: success,
          risk: risk,
          estimatedMinutes: map.tomorrowFocus.length * 20,
          recommendations: map.tomorrowFocus
              .take(2)
              .map((item) => 'Practica $item')
              .toList(),
        ),
        SmartStudyGoal(
          id: 'complete_learning_unit',
          title: 'Completar la unidad activa',
          type: 'unit',
          progress: analytics.masteryPercentage,
          probability: _score([
            analytics.masteryPercentage,
            analytics.completedChapters * 12,
            streak.currentStreakDays * 10
          ]),
          risk: risk,
          estimatedMinutes:
              (100 - analytics.masteryPercentage).clamp(0, 100) * 3,
          recommendations: const [
            'Sigue el plan de hoy.',
            'Completa una práctica de recuperación.'
          ],
        ),
        SmartStudyGoal(
          id: 'improve_consistency',
          title: 'Mejorar consistencia de estudio',
          type: 'consistency',
          progress: _score([streak.currentStreakDays * 14]),
          probability:
              _score([streak.currentStreakDays * 13, analytics.sessions * 8]),
          risk: streak.currentStreakDays == 0 ? 'Alto' : 'Moderado',
          estimatedMinutes: 7 * 25,
          recommendations: const [
            'Reserva un bloque corto diario.',
            'Evita recuperar todo en una sola sesión.'
          ],
        ),
      ];
      final result = StudyGoals(generatedAt: DateTime.now(), goals: goals);
      await repository.save(
          documentId: latestDocumentId,
          type: resultType,
          payload: result.toJson(),
          createdAt: result.generatedAt);
      return result;
    } catch (_) {
      return StudyGoals.empty();
    }
  }

  Future<StudyGoals?> getLatestGoals() async {
    final raw =
        await repository.load(documentId: latestDocumentId, type: resultType);
    return raw == null ? null : StudyGoals.fromJson(raw);
  }

  int _score(List<num> values) => values.isEmpty
      ? 0
      : (values.reduce((a, b) => a + b) / values.length).round().clamp(0, 100);
}
