import 'campus_intelligence/adaptive_scheduler_service.dart';
import 'campus_intelligence/campus_intelligence_models.dart';
import 'campus_intelligence/campus_intelligence_service.dart';
import 'campus_intelligence/campus_trend_service.dart';
import 'campus_intelligence/enterprise_intelligence_models.dart'
    hide LearningRecommendation;
import 'campus_intelligence/knowledge_map_service.dart';
import 'campus_intelligence/learning_graph_enterprise_service.dart';
import 'campus_intelligence/predictive_success_engine.dart';
import 'campus_intelligence/productivity_service.dart';
import 'campus_intelligence/smart_goals_engine.dart';
import 'campus_intelligence/smart_study_planner_service.dart';
import 'campus_intelligence/student_analytics_enterprise_service.dart';
import 'campus_intelligence/student_digital_twin_service.dart';
import 'campus_intelligence/student_timeline_service.dart';
import 'enterprise_notifications/enterprise_notification_center.dart';
import 'gamification/gamification_models.dart' hide Achievement;
import 'gamification/gamification_service.dart';
import 'institution/institution_models.dart';
import 'institution/institution_service.dart';
import 'learning_engine/achievement_service.dart';
import 'learning_engine/learning_analytics_service.dart';
import 'learning_engine/learning_models.dart';
import 'learning_engine/learning_session_service.dart';
import 'learning_engine/recommendation_engine.dart';
import 'learning_engine/streak_service.dart';
import 'learning_engine/student_intelligence_service.dart';
import 'marketplace/marketplace_models.dart';
import 'marketplace/marketplace_service.dart';
import 'production/enterprise_cache_service.dart';
import 'release_candidate/rc_models.dart';
import 'release_candidate/rc_readiness_service.dart';

class StudentDashboardData {
  final LearningAnalytics analytics;
  final ContinueLearningItem continueLearning;
  final LearningStreak streak;
  final List<LearningRecommendation> recommendations;
  final List<Achievement> achievements;
  final StudentIntelligence intelligence;
  final CampusIntelligenceSnapshot campusSnapshot;
  final List<CampusTrend> campusTrends;
  final AdaptiveSchedule adaptiveSchedule;
  final SmartStudyPlan smartStudyPlan;
  final StudentEnterpriseAnalytics enterpriseAnalytics;
  final LearningRoadmap learningRoadmap;
  final KnowledgeMap knowledgeMap;
  final StudyGoals studyGoals;
  final ProductivitySnapshot productivity;
  final StudentDigitalTwin digitalTwin;
  final SuccessPrediction successPrediction;
  final List<StudentTimelineItem> smartTimeline;
  final GamificationProfile gamificationProfile;
  final List<MarketplaceItem> marketplaceSuggestions;
  final InstitutionDashboard institutionDashboard;
  final NotificationHistory notificationHistory;
  final ReleaseCandidateReport? rcReport;
  final List<Map<String, dynamic>> recentSessions;
  final DateTime loadedAt;

  const StudentDashboardData({
    required this.analytics,
    required this.continueLearning,
    required this.streak,
    required this.recommendations,
    required this.achievements,
    required this.intelligence,
    required this.campusSnapshot,
    required this.campusTrends,
    required this.adaptiveSchedule,
    required this.smartStudyPlan,
    required this.enterpriseAnalytics,
    required this.learningRoadmap,
    required this.knowledgeMap,
    required this.studyGoals,
    required this.productivity,
    required this.digitalTwin,
    required this.successPrediction,
    required this.smartTimeline,
    required this.gamificationProfile,
    required this.marketplaceSuggestions,
    required this.institutionDashboard,
    required this.notificationHistory,
    required this.rcReport,
    required this.recentSessions,
    required this.loadedAt,
  });

  static StudentDashboardData empty() => StudentDashboardData(
        analytics: LearningAnalytics.empty,
        continueLearning: ContinueLearningItem.empty,
        streak: LearningStreak.empty,
        recommendations: const [],
        achievements: const [],
        intelligence: StudentIntelligence.empty,
        campusSnapshot: CampusIntelligenceSnapshot.empty(),
        campusTrends: const [],
        adaptiveSchedule: AdaptiveSchedule.empty(),
        smartStudyPlan: SmartStudyPlan.empty(),
        enterpriseAnalytics: StudentEnterpriseAnalytics.empty(),
        learningRoadmap: LearningRoadmap.empty(),
        knowledgeMap: KnowledgeMap.empty(),
        studyGoals: StudyGoals.empty(),
        productivity: ProductivitySnapshot.empty(),
        digitalTwin: StudentDigitalTwin.empty(),
        successPrediction: SuccessPrediction.empty(),
        smartTimeline: const [],
        gamificationProfile: GamificationProfile.empty(),
        marketplaceSuggestions: const [],
        institutionDashboard: InstitutionDashboard.empty(),
        notificationHistory: const NotificationHistory(),
        rcReport: null,
        recentSessions: const [],
        loadedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
}

class StudentDashboardController {
  static StudentDashboardData? _cachedData;
  static DateTime? _cachedAt;

  final LearningAnalyticsService analyticsService;
  final StreakService streakService;
  final RecommendationEngine recommendationEngine;
  final AchievementService achievementService;
  final StudentIntelligenceService intelligenceService;
  final LearningSessionService sessionService;
  final CampusIntelligenceService campusIntelligenceService;
  final CampusTrendService campusTrendService;
  final AdaptiveSchedulerService adaptiveSchedulerService;
  final SmartStudyPlannerService smartStudyPlannerService;
  final StudentAnalyticsEnterpriseService enterpriseAnalyticsService;
  final LearningGraphEnterpriseService graphEnterpriseService;
  final KnowledgeMapService knowledgeMapService;
  final SmartGoalsEngine smartGoalsEngine;
  final ProductivityService productivityService;
  final StudentDigitalTwinService digitalTwinService;
  final PredictiveSuccessEngine predictiveSuccessEngine;
  final StudentTimelineService timelineService;
  final GamificationService gamificationService;
  final MarketplaceService marketplaceService;
  final MarketplaceRecommendationEngine marketplaceRecommendationEngine;
  final InstitutionService institutionService;
  final EnterpriseNotificationCenter notificationCenter;
  final RcReadinessService rcReadinessService;
  final EnterpriseCacheService cacheService;

  const StudentDashboardController({
    this.analyticsService = const LearningAnalyticsService(),
    this.streakService = const StreakService(),
    this.recommendationEngine = const RecommendationEngine(),
    this.achievementService = const AchievementService(),
    this.intelligenceService = const StudentIntelligenceService(),
    this.sessionService = const LearningSessionService(),
    this.campusIntelligenceService = const CampusIntelligenceService(),
    this.campusTrendService = const CampusTrendService(),
    this.adaptiveSchedulerService = const AdaptiveSchedulerService(),
    this.smartStudyPlannerService = const SmartStudyPlannerService(),
    this.enterpriseAnalyticsService = const StudentAnalyticsEnterpriseService(),
    this.graphEnterpriseService = const LearningGraphEnterpriseService(),
    this.knowledgeMapService = const KnowledgeMapService(),
    this.smartGoalsEngine = const SmartGoalsEngine(),
    this.productivityService = const ProductivityService(),
    this.digitalTwinService = const StudentDigitalTwinService(),
    this.predictiveSuccessEngine = const PredictiveSuccessEngine(),
    this.timelineService = const StudentTimelineService(),
    this.gamificationService = const GamificationService(),
    this.marketplaceService = const MarketplaceService(),
    this.marketplaceRecommendationEngine =
        const MarketplaceRecommendationEngine(),
    this.institutionService = const InstitutionService(),
    this.notificationCenter = const EnterpriseNotificationCenter(),
    this.rcReadinessService = const RcReadinessService(),
    this.cacheService = const EnterpriseCacheService(),
  });

  Future<StudentDashboardData> load({bool refresh = false}) async {
    final cached = _cachedData;
    final cachedAt = _cachedAt;
    if (!refresh &&
        cached != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < const Duration(minutes: 5)) {
      return cached;
    }

    final core = await _loadCore();
    final enterprise = await _loadEnterprise(core);
    final data = StudentDashboardData(
      analytics: core.analytics,
      continueLearning: core.continueLearning,
      streak: core.streak,
      recommendations: core.recommendations,
      achievements: core.achievements,
      intelligence: core.intelligence,
      recentSessions: core.recentSessions.take(6).toList(),
      campusSnapshot: enterprise.campusSnapshot,
      campusTrends: enterprise.campusTrends,
      adaptiveSchedule: enterprise.adaptiveSchedule,
      smartStudyPlan: enterprise.smartStudyPlan,
      enterpriseAnalytics: enterprise.enterpriseAnalytics,
      learningRoadmap: enterprise.learningRoadmap,
      knowledgeMap: enterprise.knowledgeMap,
      studyGoals: enterprise.studyGoals,
      productivity: enterprise.productivity,
      digitalTwin: enterprise.digitalTwin,
      successPrediction: enterprise.successPrediction,
      smartTimeline: enterprise.smartTimeline,
      gamificationProfile: enterprise.gamificationProfile,
      marketplaceSuggestions: enterprise.marketplaceSuggestions,
      institutionDashboard: enterprise.institutionDashboard,
      notificationHistory: enterprise.notificationHistory,
      rcReport: enterprise.rcReport,
      loadedAt: DateTime.now(),
    );
    _cachedData = data;
    _cachedAt = DateTime.now();
    cacheService.putDashboard('student_dashboard_latest', data);
    return data;
  }

  Future<_CoreDashboardData> _loadCore() async {
    final results = await Future.wait<Object>([
      analyticsService.buildAnalytics(),
      analyticsService.buildContinueLearningItem(),
      streakService.calculateStreak(),
      recommendationEngine.generateRecommendations(),
      achievementService.getAchievements(),
      intelligenceService.analyzeStudent(),
      sessionService.getSessions(),
    ]);
    return _CoreDashboardData(
      analytics: results[0] as LearningAnalytics,
      continueLearning: results[1] as ContinueLearningItem,
      streak: results[2] as LearningStreak,
      recommendations: results[3] as List<LearningRecommendation>,
      achievements: results[4] as List<Achievement>,
      intelligence: results[5] as StudentIntelligence,
      recentSessions: results[6] as List<Map<String, dynamic>>,
    );
  }

  Future<_EnterpriseDashboardData> _loadEnterprise(
    _CoreDashboardData core,
  ) async {
    final adaptiveSchedule = await adaptiveSchedulerService.buildSchedule();
    final smartStudyPlan = await smartStudyPlannerService.buildPlan(
      schedule: adaptiveSchedule,
    );
    final firstPass = await Future.wait<Object>([
      campusIntelligenceService.buildSnapshot(),
      campusTrendService.buildTrends(),
      enterpriseAnalyticsService.buildAnalytics(),
      graphEnterpriseService.buildRoadmap(),
      productivityService.buildSnapshot(),
      timelineService.buildTimeline(limit: 8),
      gamificationService.buildProfile(),
      marketplaceService.buildCatalog(),
      institutionService.buildDashboard(),
      rcReadinessService.buildReport(),
    ]);

    final campusSnapshot = firstPass[0] as CampusIntelligenceSnapshot;
    final campusTrends = firstPass[1] as List<CampusTrend>;
    final enterpriseAnalytics = firstPass[2] as StudentEnterpriseAnalytics;
    final learningRoadmap = firstPass[3] as LearningRoadmap;
    final productivity = firstPass[4] as ProductivitySnapshot;
    final smartTimeline = firstPass[5] as List<StudentTimelineItem>;
    final gamificationProfile = firstPass[6] as GamificationProfile;
    final catalog = firstPass[7] as MarketplaceCatalog;
    final institutionDashboard = firstPass[8] as InstitutionDashboard;
    final rcReport = firstPass[9] as ReleaseCandidateReport;
    final knowledgeMap = await knowledgeMapService.buildKnowledgeMap(
      roadmap: learningRoadmap,
    );
    final studyGoals = await smartGoalsEngine.buildGoals(
      knowledgeMap: knowledgeMap,
    );
    final digitalTwin = await digitalTwinService.buildTwin(
      productivity: productivity,
    );
    final successPrediction = await predictiveSuccessEngine.predict(
      analytics: enterpriseAnalytics,
      twin: digitalTwin,
      goals: studyGoals,
    );
    final marketplaceSuggestions = marketplaceRecommendationEngine.recommend(
      catalog,
      focus: knowledgeMap.tomorrowFocus,
      risk: successPrediction.failureRisk >= 60 ? 'Alto' : 'Bajo',
    );
    final notificationHistory = await notificationCenter.buildLite(
      campusSnapshot: campusSnapshot,
      gamificationProfile: gamificationProfile,
      catalog: catalog,
      institutionDashboard: institutionDashboard,
      studyPlan: smartStudyPlan,
      streak: core.streak,
    );
    return _EnterpriseDashboardData(
      campusSnapshot: campusSnapshot,
      campusTrends: campusTrends,
      adaptiveSchedule: adaptiveSchedule,
      smartStudyPlan: smartStudyPlan,
      enterpriseAnalytics: enterpriseAnalytics,
      learningRoadmap: learningRoadmap,
      knowledgeMap: knowledgeMap,
      studyGoals: studyGoals,
      productivity: productivity,
      digitalTwin: digitalTwin,
      successPrediction: successPrediction,
      smartTimeline: smartTimeline,
      gamificationProfile: gamificationProfile,
      marketplaceSuggestions: marketplaceSuggestions,
      institutionDashboard: institutionDashboard,
      notificationHistory: notificationHistory,
      rcReport: rcReport,
    );
  }
}

class _CoreDashboardData {
  final LearningAnalytics analytics;
  final ContinueLearningItem continueLearning;
  final LearningStreak streak;
  final List<LearningRecommendation> recommendations;
  final List<Achievement> achievements;
  final StudentIntelligence intelligence;
  final List<Map<String, dynamic>> recentSessions;

  const _CoreDashboardData({
    required this.analytics,
    required this.continueLearning,
    required this.streak,
    required this.recommendations,
    required this.achievements,
    required this.intelligence,
    required this.recentSessions,
  });
}

class _EnterpriseDashboardData {
  final CampusIntelligenceSnapshot campusSnapshot;
  final List<CampusTrend> campusTrends;
  final AdaptiveSchedule adaptiveSchedule;
  final SmartStudyPlan smartStudyPlan;
  final StudentEnterpriseAnalytics enterpriseAnalytics;
  final LearningRoadmap learningRoadmap;
  final KnowledgeMap knowledgeMap;
  final StudyGoals studyGoals;
  final ProductivitySnapshot productivity;
  final StudentDigitalTwin digitalTwin;
  final SuccessPrediction successPrediction;
  final List<StudentTimelineItem> smartTimeline;
  final GamificationProfile gamificationProfile;
  final List<MarketplaceItem> marketplaceSuggestions;
  final InstitutionDashboard institutionDashboard;
  final NotificationHistory notificationHistory;
  final ReleaseCandidateReport? rcReport;

  const _EnterpriseDashboardData({
    required this.campusSnapshot,
    required this.campusTrends,
    required this.adaptiveSchedule,
    required this.smartStudyPlan,
    required this.enterpriseAnalytics,
    required this.learningRoadmap,
    required this.knowledgeMap,
    required this.studyGoals,
    required this.productivity,
    required this.digitalTwin,
    required this.successPrediction,
    required this.smartTimeline,
    required this.gamificationProfile,
    required this.marketplaceSuggestions,
    required this.institutionDashboard,
    required this.notificationHistory,
    required this.rcReport,
  });
}
