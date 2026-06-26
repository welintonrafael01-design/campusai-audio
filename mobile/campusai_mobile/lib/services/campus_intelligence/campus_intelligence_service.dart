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
import 'adaptive_learning_service.dart';
import 'campus_intelligence_models.dart';
import 'campus_prediction_engine.dart';
import 'learning_graph_service.dart';
import 'smart_notification_engine.dart';

class CampusIntelligenceService {
  static const String snapshotType = 'campus_intelligence_snapshot';
  static const String latestDocumentId = 'campus_intelligence_latest';

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
      }.take(6).toList();
      final weaknesses = {
        ...intelligence.weaknesses,
        ...predictions
            .where((prediction) => prediction.severity == 'high')
            .map((prediction) => prediction.title),
      }.take(6).toList();

      return CampusIntelligenceSnapshot(
        generatedAt: DateTime.now(),
        studentScore: studentScore,
        academicRisk: risk,
        engagementScore: engagementScore,
        masteryScore: masteryScore,
        consistencyScore: consistencyScore,
        recommendedNextAction: adaptivePlan.isNotEmpty
            ? adaptivePlan.first.title
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
