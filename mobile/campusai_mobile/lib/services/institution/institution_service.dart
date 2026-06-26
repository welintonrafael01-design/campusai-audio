import '../campus_intelligence/enterprise_result_repository.dart';
import '../campus_intelligence/predictive_success_engine.dart';
import '../campus_intelligence/student_analytics_enterprise_service.dart';
import '../learning_engine/learning_analytics_service.dart';
import '../voice_intelligence/voice_session_service.dart';
import 'institution_models.dart';

class InstitutionService {
  static const dashboardType = 'institution_dashboard';
  static const healthType = 'institution_health';
  static const predictionType = 'institution_prediction';
  final EnterpriseResultRepository repository;
  final LearningAnalyticsService analyticsService;
  final StudentAnalyticsEnterpriseService enterpriseAnalytics;
  final PredictiveSuccessEngine predictionEngine;
  final VoiceSessionService voiceSessions;
  const InstitutionService(
      {this.repository = const EnterpriseResultRepository(),
      this.analyticsService = const LearningAnalyticsService(),
      this.enterpriseAnalytics = const StudentAnalyticsEnterpriseService(),
      this.predictionEngine = const PredictiveSuccessEngine(),
      this.voiceSessions = const VoiceSessionService()});
  Future<InstitutionDashboard> buildDashboard() async {
    try {
      final analytics = await analyticsService.buildAnalytics();
      final enterprise = await enterpriseAnalytics.buildAnalytics();
      final prediction = await predictionEngine.predict(analytics: enterprise);
      final voice = await voiceSessions.getSessions();
      final metrics = InstitutionMetrics(
          risk: prediction.failureRisk,
          progress: analytics.masteryPercentage,
          retention: enterprise.retentionScore,
          dropout: prediction.dropoutRisk,
          aiUsage: enterprise.voiceEngagement,
          audiobookUsage: analytics.audioMinutesListened.clamp(0, 100),
          tutorUsage: enterprise.voiceEngagement,
          voiceUsage: (voice.length * 10).clamp(0, 100),
          learningPacks: analytics.flashcardsStudied.clamp(0, 100),
          plannerUsage: enterprise.consistencyScore,
          engagement: enterprise.effortScore);
      final dashboard = InstitutionDashboard(
          updatedAt: DateTime.now(),
          institution: const Institution(
              id: 'local_institution',
              name: 'StudyBook Institution',
              role: 'Institución'),
          metrics: metrics,
          alerts: _alerts(metrics),
          prediction: InstitutionPrediction(
              successProbability: prediction.courseCompletionProbability,
              riskProbability: prediction.dropoutRisk,
              recommendation: prediction.recommendation));
      await repository.save(
          documentId: 'institution_dashboard_latest',
          type: dashboardType,
          payload: dashboard.toJson(),
          createdAt: dashboard.updatedAt);
      await repository.save(
          documentId: 'institution_health_latest',
          type: healthType,
          payload: metrics.toJson());
      await repository.save(
          documentId: 'institution_prediction_latest',
          type: predictionType,
          payload: dashboard.prediction.toJson());
      return dashboard;
    } catch (_) {
      return InstitutionDashboard.empty();
    }
  }

  Future<InstitutionDashboard?> getLatestDashboard() async {
    final raw = await repository.load(
        documentId: 'institution_dashboard_latest', type: dashboardType);
    return raw == null ? null : InstitutionDashboard.fromJson(raw);
  }

  List<InstitutionAlert> _alerts(InstitutionMetrics m) => [
        if (m.risk >= 60)
          const InstitutionAlert(
              title: 'Riesgo institucional',
              message: 'Se requiere intervención de acompañamiento.',
              severity: 'high'),
        if (m.engagement < 40)
          const InstitutionAlert(
              title: 'Engagement bajo',
              message: 'Prioriza activación de aprendizaje.',
              severity: 'medium')
      ];
}

class InstitutionAnalytics {
  final InstitutionService service;
  const InstitutionAnalytics({this.service = const InstitutionService()});
  Future<InstitutionMetrics> build() =>
      service.buildDashboard().then((value) => value.metrics);
}

class InstitutionHierarchy {
  const InstitutionHierarchy();
  List<String> roles() => const [
        'Super Admin',
        'Institución',
        'Campus',
        'Facultad',
        'Escuela',
        'Departamento',
        'Coordinador',
        'Profesor',
        'Estudiante'
      ];
}

class InstitutionLicenseManager {
  const InstitutionLicenseManager();
  bool hasAccess(String role) => const [
        'Super Admin',
        'Institución',
        'Campus',
        'Facultad',
        'Escuela',
        'Departamento',
        'Coordinador',
        'Profesor',
        'Estudiante'
      ].contains(role);
}

class InstitutionHealthEngine {
  const InstitutionHealthEngine();
  int health(InstitutionMetrics m) =>
      ((m.progress + m.retention + m.engagement + (100 - m.risk)) / 4)
          .round()
          .clamp(0, 100);
}

class InstitutionPredictionEngine {
  const InstitutionPredictionEngine();
  InstitutionPrediction predict(InstitutionMetrics m) => InstitutionPrediction(
      successProbability:
          ((m.progress + m.retention + m.engagement) / 3).round(),
      riskProbability: ((m.risk + m.dropout) / 2).round(),
      recommendation: m.risk >= 60
          ? 'Prioriza retención y acompañamiento.'
          : 'Mantén el seguimiento institucional.');
}
