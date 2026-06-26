import 'campus_intelligence_models.dart';
import 'enterprise_intelligence_models.dart';
import 'enterprise_result_repository.dart';
import 'smart_goals_engine.dart';
import 'student_analytics_enterprise_service.dart';
import 'student_digital_twin_service.dart';

/// Rule-based success and risk predictions. It deliberately has no backend call.
class PredictiveSuccessEngine {
  static const String riskType = 'risk_prediction';
  static const String successType = 'success_prediction';
  static const String latestDocumentId = 'success_prediction_latest';

  final StudentAnalyticsEnterpriseService analyticsService;
  final StudentDigitalTwinService twinService;
  final SmartGoalsEngine goalsEngine;
  final EnterpriseResultRepository repository;

  const PredictiveSuccessEngine({
    this.analyticsService = const StudentAnalyticsEnterpriseService(),
    this.twinService = const StudentDigitalTwinService(),
    this.goalsEngine = const SmartGoalsEngine(),
    this.repository = const EnterpriseResultRepository(),
  });

  Future<SuccessPrediction> predict({
    StudentEnterpriseAnalytics? analytics,
    StudentDigitalTwin? twin,
    StudyGoals? goals,
  }) async {
    try {
      final resolvedAnalytics =
          analytics ?? await analyticsService.buildAnalytics();
      final resolvedTwin = twin ?? await twinService.buildTwin();
      final resolvedGoals = goals ?? await goalsEngine.buildGoals();
      final goalProbability = resolvedGoals.goals.isEmpty
          ? 0
          : (resolvedGoals.goals
                      .map((goal) => goal.probability)
                      .reduce((a, b) => a + b) /
                  resolvedGoals.goals.length)
              .round();
      final pass = _score([
        resolvedAnalytics.predictedSuccessProbability,
        resolvedTwin.knowledgeScore,
        resolvedTwin.habitScore
      ]);
      final failure = _score([
        100 - pass,
        100 - resolvedAnalytics.quizReliability,
        resolvedTwin.risk == 'Alto'
            ? 90
            : resolvedTwin.risk == 'Moderado'
                ? 55
                : 20
      ]);
      final dropout = _score([
        100 - resolvedTwin.habitScore,
        100 - resolvedTwin.motivationScore,
        resolvedAnalytics.riskTrajectory == 'Empeorando' ? 80 : 20
      ]);
      final completion = _score([
        pass,
        resolvedAnalytics.learningVelocity,
        resolvedTwin.motivationScore
      ]);
      final prediction = SuccessPrediction(
        generatedAt: DateTime.now(),
        dropoutRisk: dropout,
        failureRisk: failure,
        passProbability: pass,
        courseCompletionProbability: completion,
        goalCompletionProbability: goalProbability,
        recommendation: dropout >= 60 || failure >= 60
            ? 'Reduce el riesgo con una sesión breve diaria y un repaso guiado.'
            : 'Mantén el plan actual y valida el avance con una práctica corta.',
      );
      await repository.save(
          documentId: latestDocumentId,
          type: successType,
          payload: prediction.toJson(),
          createdAt: prediction.generatedAt);
      await repository.save(
          documentId: 'risk_prediction_latest',
          type: riskType,
          payload: prediction.toJson(),
          createdAt: prediction.generatedAt);
      return prediction;
    } catch (_) {
      return SuccessPrediction.empty();
    }
  }

  Future<SuccessPrediction?> getLatestPrediction() async {
    final raw =
        await repository.load(documentId: latestDocumentId, type: successType);
    return raw == null ? null : SuccessPrediction.fromJson(raw);
  }

  int _score(List<num> values) => values.isEmpty
      ? 0
      : (values.reduce((a, b) => a + b) / values.length).round().clamp(0, 100);
}
