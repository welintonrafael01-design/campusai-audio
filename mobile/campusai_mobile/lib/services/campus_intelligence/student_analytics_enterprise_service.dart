import '../learning_engine/achievement_service.dart';
import '../learning_engine/learning_analytics_service.dart';
import '../learning_engine/learning_models.dart';
import '../learning_engine/streak_service.dart';
import '../voice_intelligence/voice_session_service.dart';
import 'campus_intelligence_models.dart';
import 'campus_snapshot_repository.dart';
import 'campus_trend_service.dart';

class StudentAnalyticsEnterpriseService {
  final LearningAnalyticsService analyticsService;
  final StreakService streakService;
  final AchievementService achievementService;
  final VoiceSessionService voiceSessionService;
  final CampusTrendService trendService;
  final CampusSnapshotRepository snapshotRepository;

  const StudentAnalyticsEnterpriseService({
    this.analyticsService = const LearningAnalyticsService(),
    this.streakService = const StreakService(),
    this.achievementService = const AchievementService(),
    this.voiceSessionService = const VoiceSessionService(),
    this.trendService = const CampusTrendService(),
    this.snapshotRepository = const CampusSnapshotRepository(),
  });

  Future<StudentEnterpriseAnalytics> buildAnalytics() async {
    try {
      final analytics = await analyticsService.buildAnalytics();
      final streak = await streakService.calculateStreak();
      final achievements = await achievementService.getAchievements();
      final voiceSessions = await voiceSessionService.getSessions();
      final trends = await trendService.buildTrends();
      final snapshot = await snapshotRepository.getLatestSnapshot();

      final masteryTrend = trendService.trendByMetric(trends, 'Dominio');
      final riskTrend = trendService.trendByMetric(trends, 'Riesgo');
      final sessionTrend = trendService.trendByMetric(trends, 'Sesiones');
      final studyTimeTrend =
          trendService.trendByMetric(trends, 'Tiempo estudiado');

      final learningVelocity = _score([
        analytics.completedChapters * 12,
        analytics.sessions * 8,
        (sessionTrend?.currentValue ?? 0) * 8,
      ]);
      final retentionScore = _score([
        analytics.masteryPercentage,
        analytics.averageQuizScore,
        analytics.flashcardsStudied * 3,
      ]);
      final effortScore = _score([
        analytics.studyMinutes / 2,
        analytics.audioMinutesListened / 2,
        studyTimeTrend?.currentValue ?? 0,
      ]);
      final consistencyScore = _score([
        streak.currentStreakDays * 12,
        snapshot?.consistencyScore ?? 0,
      ]);
      final voiceEngagement = _score([
        voiceSessions.length * 12,
        analytics.sessions == 0
            ? 0
            : (voiceSessions.length / analytics.sessions) * 100,
      ]);
      final quizReliability = _score([
        analytics.quizCompleted * 10,
        analytics.averageQuizScore,
      ]);
      final masteryMomentum = _score([
        (masteryTrend?.delta ?? 0) * 10 + 50,
        snapshot?.masteryScore ?? analytics.masteryPercentage,
      ]);
      final riskTrajectory = _riskTrajectory(snapshot, riskTrend);
      final unlocked = achievements.where((item) => item.unlocked).length;
      final predictedSuccessProbability = _score([
        retentionScore,
        consistencyScore,
        masteryMomentum,
        unlocked * 8,
        riskTrajectory == 'Mejorando'
            ? 15
            : riskTrajectory == 'Empeorando'
                ? -15
                : 0,
      ]);

      return StudentEnterpriseAnalytics(
        generatedAt: DateTime.now(),
        learningVelocity: learningVelocity,
        retentionScore: retentionScore,
        effortScore: effortScore,
        consistencyScore: consistencyScore,
        voiceEngagement: voiceEngagement,
        quizReliability: quizReliability,
        masteryMomentum: masteryMomentum,
        riskTrajectory: riskTrajectory,
        predictedCompletionDays: _predictedCompletionDays(
          analytics,
          learningVelocity,
        ),
        predictedSuccessProbability: predictedSuccessProbability,
      );
    } catch (_) {
      return StudentEnterpriseAnalytics.empty();
    }
  }

  int _predictedCompletionDays(
    LearningAnalytics analytics,
    int learningVelocity,
  ) {
    if (analytics.sessions == 0 && analytics.completedChapters == 0) return 0;
    final remainingSignal = (100 - analytics.masteryPercentage).clamp(0, 100);
    final pace = learningVelocity <= 0 ? 10 : learningVelocity;
    return ((remainingSignal / pace) * 7).ceil().clamp(1, 90);
  }

  String _riskTrajectory(
    CampusIntelligenceSnapshot? snapshot,
    CampusTrend? riskTrend,
  ) {
    if (snapshot == null) return 'Sin datos';
    if (riskTrend == null || riskTrend.previousValue <= 0) {
      return snapshot.academicRisk;
    }
    if (riskTrend.delta < 0) return 'Mejorando';
    if (riskTrend.delta > 0) return 'Empeorando';
    return 'Estable';
  }

  int _score(List<num> values) {
    if (values.isEmpty) return 0;
    final total = values.fold<num>(0, (sum, value) => sum + value);
    return (total / values.length).round().clamp(0, 100);
  }
}
