import '../learning_engine/achievement_service.dart';
import '../learning_engine/learning_analytics_service.dart';
import '../learning_engine/learning_models.dart';
import '../learning_engine/learning_progress_service.dart';
import '../learning_engine/learning_session_service.dart';
import '../voice_intelligence/voice_session_service.dart';
import 'campus_intelligence_models.dart';
import 'campus_snapshot_repository.dart';
import 'campus_trend_service.dart';
import 'learning_graph_service.dart';
import 'personal_ai_assistant_memory_service.dart';
import 'student_timeline_service.dart';

class AdaptiveRecommendationService {
  final CampusSnapshotRepository snapshotRepository;
  final CampusTrendService trendService;
  final StudentTimelineService timelineService;
  final LearningGraphService graphService;
  final LearningAnalyticsService analyticsService;
  final LearningSessionService sessionService;
  final LearningProgressService progressService;
  final VoiceSessionService voiceSessionService;
  final AchievementService achievementService;
  final PersonalAiAssistantMemoryService assistantMemoryService;

  const AdaptiveRecommendationService({
    this.snapshotRepository = const CampusSnapshotRepository(),
    this.trendService = const CampusTrendService(),
    this.timelineService = const StudentTimelineService(),
    this.graphService = const LearningGraphService(),
    this.analyticsService = const LearningAnalyticsService(),
    this.sessionService = const LearningSessionService(),
    this.progressService = const LearningProgressService(),
    this.voiceSessionService = const VoiceSessionService(),
    this.achievementService = const AchievementService(),
    this.assistantMemoryService = const PersonalAiAssistantMemoryService(),
  });

  Future<List<AdaptiveRecommendation>> buildRecommendations({
    AdaptiveSchedule? schedule,
  }) async {
    try {
      final snapshot = await snapshotRepository.getLatestSnapshot();
      final trends = await trendService.buildTrends();
      final timeline = await timelineService.buildTimeline(limit: 12);
      final graph = await graphService.buildGraph();
      final analytics = await analyticsService.buildAnalytics();
      final sessions = await sessionService.getSessions();
      await progressService.getAllProgress();
      final voiceSessions = await voiceSessionService.getSessions();
      final achievements = await achievementService.getAchievements();
      final memory = await assistantMemoryService.getMemory();
      final recommendations = <AdaptiveRecommendation>[];

      final masteryTrend = trendService.trendByMetric(trends, 'Dominio');
      final riskTrend = trendService.trendByMetric(trends, 'Riesgo');
      final weakNode = graph.firstWhere(
        (node) => node.mastery > 0 && node.mastery < 65,
        orElse: () => const LearningGraphNode(),
      );
      final pendingQuiz = graph.firstWhere(
        (node) => node.type == 'quiz' && node.status == 'pending',
        orElse: () => const LearningGraphNode(),
      );
      final pendingChapter = graph.firstWhere(
        (node) => node.type == 'chapter' && node.status != 'completed',
        orElse: () => const LearningGraphNode(),
      );
      final latestActivity = timeline.isNotEmpty ? timeline.first : null;

      if (memory != null && memory.difficulties.isNotEmpty) {
        recommendations.add(
          AdaptiveRecommendation(
            recommendationId: 'memory_difficulty_review',
            type: 'review',
            title: 'Refuerza ${memory.difficulties.first}',
            description:
                'La memoria de aprendizaje identifica este punto como una dificultad recurrente.',
            priority: 1,
            reason: 'Perfil de aprendizaje persistente.',
            estimatedMinutes: 15,
          ),
        );
      }

      if (_isHighRisk(snapshot) || (riskTrend?.delta ?? 0) > 0) {
        recommendations.add(
          const AdaptiveRecommendation(
            recommendationId: 'risk_review',
            type: 'review',
            title: 'Revisar riesgo académico',
            description: 'Haz una sesión breve de repaso guiado hoy.',
            priority: 1,
            reason: 'El riesgo actual o su trayectoria requiere intervención.',
            estimatedMinutes: 15,
          ),
        );
      }

      if ((masteryTrend?.delta ?? 0) < 0 || analytics.masteryPercentage < 60) {
        recommendations.add(
          AdaptiveRecommendation(
            recommendationId: 'mastery_recovery',
            type: 'review',
            title: 'Recuperar dominio',
            description: weakNode.id.isEmpty
                ? 'Repasa conceptos clave y luego completa un mini quiz.'
                : 'Repasa ${weakNode.title} y valida comprensión.',
            priority: 1,
            reason: 'La tendencia de dominio está baja o descendiendo.',
            estimatedMinutes: 18,
            targetId: weakNode.id,
          ),
        );
      }

      if (pendingQuiz.id.isNotEmpty || analytics.quizCompleted == 0) {
        recommendations.add(
          AdaptiveRecommendation(
            recommendationId: 'quiz_pending',
            type: 'quiz',
            title: 'Hacer quiz de comprobación',
            description: 'Responde preguntas cortas para medir retención.',
            priority: 2,
            reason: 'Los quizzes dan una señal rápida de dominio real.',
            estimatedMinutes: 8,
            targetId: pendingQuiz.id,
          ),
        );
      }

      if (analytics.flashcardsStudied < 20) {
        recommendations.add(
          const AdaptiveRecommendation(
            recommendationId: 'flashcards_low',
            type: 'flashcards',
            title: 'Practicar flashcards',
            description: 'Dedica unos minutos a conceptos de alta frecuencia.',
            priority: 2,
            reason: 'Hay poca práctica espaciada registrada.',
            estimatedMinutes: 10,
          ),
        );
      }

      if (voiceSessions.length < 2 || _isHighRisk(snapshot)) {
        recommendations.add(
          const AdaptiveRecommendation(
            recommendationId: 'voice_tutor',
            type: 'tutor',
            title: 'Hablar con Tutor IA',
            description: 'Pregunta por voz qué debes reforzar primero.',
            priority: 2,
            reason: 'El Tutor IA puede guiar una sesión contextual.',
            estimatedMinutes: 7,
          ),
        );
      }

      if (pendingChapter.id.isNotEmpty) {
        recommendations.add(
          AdaptiveRecommendation(
            recommendationId: 'continue_${pendingChapter.id}',
            type: 'audiobook',
            title: 'Continuar AudioBook',
            description: 'Escucha el siguiente bloque del contenido.',
            priority: 3,
            reason: 'Mantener avance reduce fricción de continuidad.',
            estimatedMinutes: 15,
            targetId: pendingChapter.id,
          ),
        );
      }

      if (sessions.length >= 4 && analytics.averageMinutesPerSession > 45) {
        recommendations.add(
          const AdaptiveRecommendation(
            recommendationId: 'rest_needed',
            type: 'rest',
            title: 'Tomar descanso activo',
            description: 'Haz una pausa breve antes de otra actividad intensa.',
            priority: 3,
            reason: 'El esfuerzo reciente es alto.',
            estimatedMinutes: 5,
          ),
        );
      }

      final nearAchievement = achievements.firstWhere(
        (achievement) =>
            !achievement.unlocked && achievement.completionRatio >= 0.75,
        orElse: () => const Achievement(
          id: '',
          title: '',
          description: '',
        ),
      );
      if (nearAchievement.id.isNotEmpty) {
        recommendations.add(
          AdaptiveRecommendation(
            recommendationId: 'challenge_${nearAchievement.id}',
            type: 'challenge',
            title: 'Completar logro cercano',
            description: nearAchievement.description,
            priority: 3,
            reason: 'Estás cerca de desbloquear ${nearAchievement.title}.',
            estimatedMinutes: 12,
            targetId: nearAchievement.id,
          ),
        );
      }

      if (schedule != null && schedule.slots.isNotEmpty) {
        recommendations.add(
          AdaptiveRecommendation(
            recommendationId: 'scheduled_next',
            type: schedule.nextActivityType,
            title: schedule.nextAction,
            description: 'Sigue el plan inteligente sugerido para hoy.',
            priority: schedule.priority,
            reason: schedule.reason,
            estimatedMinutes: schedule.slots.first.durationMinutes,
            targetId: schedule.slots.first.studyBlock.targetId,
          ),
        );
      }

      if (recommendations.isEmpty) {
        recommendations.add(
          AdaptiveRecommendation(
            recommendationId: 'continue_learning',
            type: 'continue',
            title: snapshot?.recommendedNextAction ??
                latestActivity?.title ??
                'Continúa aprendiendo',
            description: 'Avanza con una sesión corta y enfocada.',
            priority: 3,
            reason: 'No hay alertas críticas activas.',
            estimatedMinutes: 12,
          ),
        );
      }

      recommendations.sort((a, b) => a.priority.compareTo(b.priority));
      return _deduplicate(recommendations).take(8).toList();
    } catch (_) {
      return const [
        AdaptiveRecommendation(
          recommendationId: 'continue_learning',
          type: 'continue',
          title: 'Continúa aprendiendo',
          description: 'Haz una sesión breve para mantener el avance.',
          priority: 3,
          reason: 'No hay suficientes datos para una recomendación avanzada.',
          estimatedMinutes: 10,
        ),
      ];
    }
  }

  bool _isHighRisk(CampusIntelligenceSnapshot? snapshot) {
    final risk = snapshot?.academicRisk.trim().toLowerCase() ?? '';
    return risk.contains('alto');
  }

  List<AdaptiveRecommendation> _deduplicate(
    List<AdaptiveRecommendation> recommendations,
  ) {
    final seen = <String>{};
    final unique = <AdaptiveRecommendation>[];
    for (final recommendation in recommendations) {
      final key = recommendation.recommendationId.isEmpty
          ? '${recommendation.type}_${recommendation.title}'
          : recommendation.recommendationId;
      if (seen.add(key)) unique.add(recommendation);
    }
    return unique;
  }
}
