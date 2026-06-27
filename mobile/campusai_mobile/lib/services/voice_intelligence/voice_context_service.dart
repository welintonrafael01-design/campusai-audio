import '../audiobook_progress_service.dart';
import '../audiobook_service.dart';
import '../autonomous_ai/autonomous_action_repository.dart';
import '../campus_intelligence/adaptive_scheduler_service.dart';
import '../campus_intelligence/campus_intelligence_models.dart';
import '../campus_intelligence/campus_intelligence_service.dart';
import '../campus_intelligence/campus_trend_service.dart';
import '../campus_intelligence/enterprise_intelligence_models.dart';
import '../campus_intelligence/knowledge_map_service.dart';
import '../campus_intelligence/learning_graph_enterprise_service.dart';
import '../campus_intelligence/personal_ai_assistant_memory_service.dart';
import '../campus_intelligence/predictive_success_engine.dart';
import '../campus_intelligence/productivity_service.dart';
import '../campus_intelligence/smart_study_planner_service.dart';
import '../campus_intelligence/smart_goals_engine.dart';
import '../campus_intelligence/student_analytics_enterprise_service.dart';
import '../campus_intelligence/student_digital_twin_service.dart';
import '../gamification/gamification_service.dart';
import '../institution/institution_service.dart';
import '../marketplace/marketplace_service.dart';
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
  final AdaptiveSchedulerService adaptiveSchedulerService;
  final SmartStudyPlannerService smartStudyPlannerService;
  final StudentAnalyticsEnterpriseService enterpriseAnalyticsService;
  final LearningGraphEnterpriseService learningGraphEnterpriseService;
  final KnowledgeMapService knowledgeMapService;
  final SmartGoalsEngine smartGoalsEngine;
  final ProductivityService productivityService;
  final PersonalAiAssistantMemoryService assistantMemoryService;
  final StudentDigitalTwinService digitalTwinService;
  final PredictiveSuccessEngine predictiveSuccessEngine;
  final GamificationService gamificationService;
  final MarketplaceService marketplaceService;
  final InstitutionService institutionService;
  final AutonomousActionRepository autonomousActionRepository;

  const VoiceContextService({
    this.audiobookService = const AudiobookService(),
    this.audiobookProgressService = const AudiobookProgressService(),
    this.learningProgressService = const LearningProgressService(),
    this.analyticsService = const LearningAnalyticsService(),
    this.recommendationEngine = const RecommendationEngine(),
    this.intelligenceService = const StudentIntelligenceService(),
    this.campusIntelligenceService = const CampusIntelligenceService(),
    this.campusTrendService = const CampusTrendService(),
    this.adaptiveSchedulerService = const AdaptiveSchedulerService(),
    this.smartStudyPlannerService = const SmartStudyPlannerService(),
    this.enterpriseAnalyticsService = const StudentAnalyticsEnterpriseService(),
    this.learningGraphEnterpriseService =
        const LearningGraphEnterpriseService(),
    this.knowledgeMapService = const KnowledgeMapService(),
    this.smartGoalsEngine = const SmartGoalsEngine(),
    this.productivityService = const ProductivityService(),
    this.assistantMemoryService = const PersonalAiAssistantMemoryService(),
    this.digitalTwinService = const StudentDigitalTwinService(),
    this.predictiveSuccessEngine = const PredictiveSuccessEngine(),
    this.gamificationService = const GamificationService(),
    this.marketplaceService = const MarketplaceService(),
    this.institutionService = const InstitutionService(),
    this.autonomousActionRepository = const AutonomousActionRepository(),
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
      final adaptiveSchedule =
          await adaptiveSchedulerService.buildSchedule(days: 3);
      final smartStudyPlan = await smartStudyPlannerService.buildPlan(
        days: 3,
        schedule: adaptiveSchedule,
      );
      final enterpriseAnalytics =
          await enterpriseAnalyticsService.buildAnalytics();
      final learningRoadmap =
          await learningGraphEnterpriseService.buildRoadmap();
      final knowledgeMap = await knowledgeMapService.buildKnowledgeMap(
        roadmap: learningRoadmap,
      );
      final goals = await smartGoalsEngine.buildGoals(
        knowledgeMap: knowledgeMap,
      );
      final productivity = await productivityService.buildSnapshot();
      final memory = await assistantMemoryService.buildMemory(
        preferredStudyHours: _bestStudyHours(adaptiveSchedule),
      );
      final digitalTwin = await digitalTwinService.buildTwin(
        productivity: productivity,
      );
      final prediction = await predictiveSuccessEngine.predict(
        analytics: enterpriseAnalytics,
        twin: digitalTwin,
        goals: goals,
      );
      final gamification = await gamificationService.buildProfile();
      final marketplace = await marketplaceService.buildCatalog();
      final institution = await institutionService.buildDashboard();
      final autonomousPlan = await autonomousActionRepository.loadLatestPlan(
        maxAge: const Duration(hours: 6),
      );
      final autonomousActions = autonomousPlan?.pendingActions ?? const [];
      final nextBestAction =
          autonomousActions.isEmpty ? null : autonomousActions.first;

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
        adaptiveScheduleSummary: _limit(
          _scheduleSummary(adaptiveSchedule),
          220,
        ),
        smartStudyPlanSummary: _limit(smartStudyPlan.summary, 220),
        enterpriseAnalyticsSummary: _limit(
          _enterpriseSummary(enterpriseAnalytics),
          220,
        ),
        bestStudyHours: _bestStudyHours(adaptiveSchedule),
        priorityNextAction: _limit(
          smartStudyPlan.todayAction.isNotEmpty
              ? smartStudyPlan.todayAction
              : adaptiveSchedule.nextAction,
          160,
        ),
        knowledgeMapSummary: _limit(knowledgeMap.summary, 220),
        digitalTwinSummary: _limit(_digitalTwinSummary(digitalTwin), 220),
        goalsSummary: _limit(_goalsSummary(goals), 220),
        productivitySummary: _limit(_productivitySummary(productivity), 220),
        successPredictionSummary: _limit(_predictionSummary(prediction), 220),
        learningRoadmapSummary: _limit(_roadmapSummary(learningRoadmap), 220),
        assistantMemorySummary: _limit(_memorySummary(memory), 220),
        gamificationSummary: _limit(
            'Nivel ${gamification.level.number}, ${gamification.xp.total} XP, ${gamification.wallet.balance} coins.',
            160),
        marketplaceSummary: _limit(
            '${marketplace.items.length} recursos disponibles para tu ruta.',
            160),
        institutionSummary: _limit(
            'Progreso ${institution.metrics.progress}%, retención ${institution.metrics.retention}%, riesgo ${institution.metrics.risk}%.',
            160),
        nextBestAction: _limit(nextBestAction?.title ?? '', 160),
        autonomousActionsTop3: autonomousActions
            .take(3)
            .map((action) => _limit(action.title, 120))
            .toList(),
        actionReason: _limit(nextBestAction?.reason ?? '', 180),
        studyPlanStatus: autonomousActions.isEmpty
            ? 'Sin acciones pendientes'
            : 'Plan activo con ${autonomousActions.length} acciones',
        riskPriority:
            nextBestAction?.priority.name ?? campusSnapshot.academicRisk,
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

  String _scheduleSummary(AdaptiveSchedule schedule) {
    if (schedule.generatedAt.millisecondsSinceEpoch <= 0) return '';
    return '${schedule.nextAction} · ${schedule.nextActivityType} · '
        '${schedule.reason}';
  }

  String _digitalTwinSummary(StudentDigitalTwin twin) =>
      'Conocimiento ${twin.knowledgeScore}%, hábitos ${twin.habitScore}%, motivación ${twin.motivationScore}%, riesgo ${twin.risk}.';

  String _goalsSummary(StudyGoals goals) => goals.goals.isEmpty
      ? ''
      : goals.goals
          .take(2)
          .map((goal) => '${goal.title}: ${goal.progress}%')
          .join(' | ');

  String _productivitySummary(ProductivitySnapshot productivity) =>
      'Foco ${productivity.focus.score}%, deep work ${productivity.deepWork.deepWorkMinutes} min, eficiencia ${productivity.efficiency.score}%.';

  String _predictionSummary(SuccessPrediction prediction) =>
      'Aprobar ${prediction.passProbability}%, terminar ${prediction.courseCompletionProbability}%, riesgo de abandono ${prediction.dropoutRisk}%.';

  String _roadmapSummary(LearningRoadmap roadmap) => roadmap.recommendations
      .take(3)
      .map((recommendation) => recommendation.title)
      .join(' | ');

  String _memorySummary(AssistantMemory memory) =>
      'Estilo ${memory.learningStyle}; horario ${memory.preferredStudyHours.take(2).join(', ')}; dificultades ${memory.difficulties.take(2).join(', ')}.';

  String _enterpriseSummary(StudentEnterpriseAnalytics analytics) {
    if (analytics.generatedAt.millisecondsSinceEpoch <= 0) return '';
    return 'Velocidad ${analytics.learningVelocity}%, '
        'retención ${analytics.retentionScore}%, '
        'consistencia ${analytics.consistencyScore}%, '
        'éxito ${analytics.predictedSuccessProbability}%, '
        'riesgo ${analytics.riskTrajectory}.';
  }

  List<String> _bestStudyHours(AdaptiveSchedule schedule) {
    final hours = <String>{};
    for (final slot in schedule.slots.take(6)) {
      hours.add('${slot.recommendedAt.hour.toString().padLeft(2, '0')}:00');
    }
    return hours.take(3).toList();
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
