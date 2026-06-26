import '../audiobook_progress_service.dart';
import '../learning_engine/achievement_service.dart';
import '../learning_engine/learning_analytics_service.dart';
import '../learning_engine/learning_models.dart';
import '../learning_engine/learning_progress_service.dart';
import '../learning_engine/learning_session_service.dart';
import '../learning_engine/recommendation_engine.dart';
import '../learning_engine/streak_service.dart';
import '../learning_engine/student_intelligence_service.dart';
import '../voice_intelligence/voice_session_service.dart';
import '../gamification/gamification_service.dart';
import '../institution/institution_service.dart';
import '../marketplace/marketplace_service.dart';
import 'adaptive_learning_service.dart';
import 'campus_intelligence_models.dart';
import 'campus_prediction_engine.dart';
import 'campus_snapshot_repository.dart';
import 'campus_trend_service.dart';
import 'knowledge_map_service.dart';
import 'learning_graph_enterprise_service.dart';
import 'predictive_success_engine.dart';
import 'productivity_service.dart';
import 'smart_goals_engine.dart';
import 'student_digital_twin_service.dart';
import 'learning_graph_service.dart';
import 'smart_notification_engine.dart';
import 'student_timeline_service.dart';

class CampusIntelligenceService {
  static const String snapshotType = CampusSnapshotRepository.snapshotType;
  static const String latestDocumentId =
      CampusSnapshotRepository.latestDocumentId;

  final LearningAnalyticsService analyticsService;
  final RecommendationEngine recommendationEngine;
  final AchievementService achievementService;
  final StreakService streakService;
  final StudentIntelligenceService studentIntelligenceService;
  final LearningProgressService progressService;
  final LearningSessionService sessionService;
  final AudiobookProgressService audiobookProgressService;
  final VoiceSessionService voiceSessionService;
  final CampusPredictionEngine predictionEngine;
  final LearningGraphService learningGraphService;
  final AdaptiveLearningService adaptiveLearningService;
  final SmartNotificationEngine notificationEngine;
  final CampusSnapshotRepository snapshotRepository;
  final CampusTrendService trendService;
  final StudentTimelineService timelineService;
  final LearningGraphEnterpriseService learningGraphEnterpriseService;
  final KnowledgeMapService knowledgeMapService;
  final SmartGoalsEngine smartGoalsEngine;
  final ProductivityService productivityService;
  final StudentDigitalTwinService digitalTwinService;
  final PredictiveSuccessEngine predictiveSuccessEngine;
  final GamificationService gamificationService;
  final MarketplaceService marketplaceService;
  final InstitutionService institutionService;

  const CampusIntelligenceService({
    this.analyticsService = const LearningAnalyticsService(),
    this.recommendationEngine = const RecommendationEngine(),
    this.achievementService = const AchievementService(),
    this.streakService = const StreakService(),
    this.studentIntelligenceService = const StudentIntelligenceService(),
    this.progressService = const LearningProgressService(),
    this.sessionService = const LearningSessionService(),
    this.audiobookProgressService = const AudiobookProgressService(),
    this.voiceSessionService = const VoiceSessionService(),
    this.predictionEngine = const CampusPredictionEngine(),
    this.learningGraphService = const LearningGraphService(),
    this.adaptiveLearningService = const AdaptiveLearningService(),
    this.notificationEngine = const SmartNotificationEngine(),
    this.snapshotRepository = const CampusSnapshotRepository(),
    this.trendService = const CampusTrendService(),
    this.timelineService = const StudentTimelineService(),
    this.learningGraphEnterpriseService =
        const LearningGraphEnterpriseService(),
    this.knowledgeMapService = const KnowledgeMapService(),
    this.smartGoalsEngine = const SmartGoalsEngine(),
    this.productivityService = const ProductivityService(),
    this.digitalTwinService = const StudentDigitalTwinService(),
    this.predictiveSuccessEngine = const PredictiveSuccessEngine(),
    this.gamificationService = const GamificationService(),
    this.marketplaceService = const MarketplaceService(),
    this.institutionService = const InstitutionService(),
  });

  Future<CampusIntelligenceSnapshot> buildSnapshot() async {
    try {
      final analytics = await analyticsService.buildAnalytics();
      final recommendations =
          await recommendationEngine.generateRecommendations();
      final achievements = await achievementService.getAchievements();
      final streak = await streakService.calculateStreak();
      final intelligence = await studentIntelligenceService.analyzeStudent();
      final progressItems = await progressService.getAllProgress();
      final sessions = await sessionService.getSessions();
      final audiobookProgress = await audiobookProgressService.getAllProgress();
      final voiceSessions = await voiceSessionService.getSessions();
      final graph = await learningGraphService.buildGraph();
      final trends = await trendService.buildTrends();
      final timeline = await timelineService.buildTimeline(limit: 12);
      final enterpriseRoadmap =
          await learningGraphEnterpriseService.getLatestRoadmap();
      final knowledgeMap = await knowledgeMapService.getLatestKnowledgeMap();
      final studyGoals = await smartGoalsEngine.getLatestGoals();
      final productivity = await productivityService.getLatestSnapshot();
      final digitalTwin = await digitalTwinService.getLatestTwin();
      final successPrediction =
          await predictiveSuccessEngine.getLatestPrediction();
      final gamification = await gamificationService.getLatestProfile() ??
          await gamificationService.buildProfile();
      final marketplace = await marketplaceService.buildCatalog();
      final institution = await institutionService.getLatestDashboard() ??
          await institutionService.buildDashboard();
      final predictions = predictionEngine.generatePredictions(
        analytics: analytics,
        streak: streak,
        intelligence: intelligence,
        progressItems: progressItems,
        sessions: sessions,
        voiceSessionCount: voiceSessions.length,
      );
      final adaptivePlan = adaptiveLearningService.buildAdaptivePlan(
        analytics: analytics,
        intelligence: intelligence,
        graph: graph,
        predictions: predictions,
        recommendations: recommendations,
      );
      final notifications = notificationEngine.buildNotifications(
        analytics: analytics,
        streak: streak,
        predictions: predictions,
        adaptivePlan: adaptivePlan,
        trends: trends,
        timeline: timeline,
        achievements: achievements,
      );

      final engagementScore = _engagementScore(
        analytics,
        streak.currentStreakDays,
        voiceSessions.length,
        audiobookProgress.length,
      );
      final masteryScore = _clampScore(
        intelligence.masteryPercentage > 0
            ? intelligence.masteryPercentage
            : analytics.masteryPercentage,
      );
      final consistencyScore = _consistencyScore(streak.currentStreakDays);
      final studentScore = _average([
        engagementScore,
        masteryScore,
        consistencyScore,
      ]);
      final risk = _riskFrom(
        intelligence,
        predictions,
        analytics,
      );
      final alerts = _alertsFrom(predictions, notifications);
      final strengths = {
        ...intelligence.strengths,
        ...achievements
            .where((achievement) => achievement.unlocked)
            .map((achievement) => achievement.title),
        if (digitalTwin != null) ...digitalTwin.strengths,
        ...gamification.badges
            .where((badge) => badge.unlocked)
            .map((badge) => badge.title),
      }.take(6).toList();
      final weaknesses = {
        ...intelligence.weaknesses,
        ...predictions
            .where((prediction) => prediction.severity == 'high')
            .map((prediction) => prediction.title),
        if (knowledgeMap != null) ...knowledgeMap.tomorrowFocus,
        if (digitalTwin != null) ...digitalTwin.weaknesses,
        ...institution.alerts.map((alert) => alert.title),
        if (marketplace.items.isEmpty)
          'No hay recursos del Marketplace disponibles.',
      }.take(6).toList();

      final snapshot = CampusIntelligenceSnapshot(
        generatedAt: DateTime.now(),
        studentScore: studentScore,
        academicRisk: risk,
        engagementScore: engagementScore,
        masteryScore: masteryScore,
        consistencyScore: consistencyScore,
        recommendedNextAction: adaptivePlan.isNotEmpty
            ? adaptivePlan.first.title
            : enterpriseRoadmap?.recommendations.isNotEmpty == true
                ? enterpriseRoadmap!.recommendations.first.title
                : studyGoals?.goals.isNotEmpty == true
                    ? studyGoals!.goals.first.title
                    : productivity?.efficiency.recommendation.isNotEmpty == true
                        ? productivity!.efficiency.recommendation
                        : successPrediction?.recommendation.isNotEmpty == true
                            ? successPrediction!.recommendation
                            : recommendations.isNotEmpty
                                ? recommendations.first.title
                                : 'Continúa con tu próxima actividad.',
        alerts: alerts,
        strengths: strengths,
        weaknesses: weaknesses,
        predictions: predictions,
        learningGraph: graph,
        adaptivePlan: adaptivePlan,
        notifications: notifications,
      );
      await snapshotRepository.saveSnapshot(snapshot);
      return snapshot;
    } catch (_) {
      return CampusIntelligenceSnapshot.empty();
    }
  }

  int _engagementScore(
    LearningAnalytics analytics,
    int streakDays,
    int voiceSessionCount,
    int audiobookProgressCount,
  ) {
    final sessionScore = (analytics.sessions * 12).clamp(0, 45);
    final timeScore = (analytics.studyMinutes / 3).round().clamp(0, 25);
    final streakScore = (streakDays * 8).clamp(0, 20);
    final activityScore =
        ((voiceSessionCount + audiobookProgressCount) * 3).clamp(0, 10);
    return _clampScore(
      sessionScore + timeScore + streakScore + activityScore,
    );
  }

  int _consistencyScore(int streakDays) {
    if (streakDays <= 0) return 20;
    if (streakDays == 1) return 45;
    if (streakDays < 4) return 70;
    if (streakDays < 7) return 85;
    return 100;
  }

  String _riskFrom(
    StudentIntelligence intelligence,
    List<CampusPrediction> predictions,
    LearningAnalytics analytics,
  ) {
    if (intelligence.risk != 'Sin datos') return intelligence.risk;
    if (predictions.any((item) => item.severity == 'high')) return 'Alto';
    if (analytics.sessions == 0) return 'Sin datos';
    if (predictions.any((item) => item.severity == 'medium')) return 'Medio';
    return 'Bajo';
  }

  List<String> _alertsFrom(
    List<CampusPrediction> predictions,
    List<SmartNotification> notifications,
  ) {
    final alerts = <String>{
      ...predictions
          .where((item) => item.severity == 'high' || item.severity == 'medium')
          .map((item) => item.title),
      ...notifications
          .where((item) => item.priority <= 2)
          .map((item) => item.title),
    };
    return alerts.take(5).toList();
  }

  int _average(List<int> values) {
    if (values.isEmpty) return 0;
    return _clampScore(
      (values.fold<int>(0, (sum, value) => sum + value) / values.length)
          .round(),
    );
  }

  int _clampScore(num value) {
    return value.round().clamp(0, 100);
  }
}
