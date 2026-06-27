import '../campus_intelligence/enterprise_result_repository.dart';
import 'beta_program_service.dart';
import 'commercial_readiness_service.dart';
import 'launch_models.dart';
import 'onboarding_flow_service.dart';
import 'onboarding_readiness_service.dart';

class LaunchReadinessService {
  static const reportType = 'launch_readiness_report';
  static const reportId = 'launch_readiness_report_latest';

  final EnterpriseResultRepository repository;
  final BetaProgramService betaProgramService;
  final OnboardingReadinessService onboardingReadinessService;
  final OnboardingFlowService onboardingFlowService;
  final CommercialReadinessService commercialReadinessService;

  const LaunchReadinessService({
    this.repository = const EnterpriseResultRepository(),
    this.betaProgramService = const BetaProgramService(),
    this.onboardingReadinessService = const OnboardingReadinessService(),
    this.onboardingFlowService = const OnboardingFlowService(),
    this.commercialReadinessService = const CommercialReadinessService(),
  });

  Future<LaunchReadinessReport> buildReport({
    bool documentationReady = true,
    bool metricsReady = true,
    bool demoReady = true,
  }) async {
    try {
      final beta = await betaProgramService.buildSummary();
      final onboarding = await onboardingReadinessService.loadProgress();
      final onboardingFlowReady =
          onboardingFlowService.stepsForRole('student').isNotEmpty &&
              onboardingFlowService.stepsForRole('teacher').isNotEmpty;
      final commercial = commercialReadinessService.evaluate(
        documentationReady: documentationReady,
        onboardingReady: onboardingFlowReady,
        demoReady: demoReady,
      );
      final checks = <LaunchReadinessCheck>[
        LaunchReadinessCheck(
          id: 'critical_flows',
          title: 'Flujos críticos definidos',
          area: 'QA',
          status: beta.criticalFlowCount >= 7
              ? LaunchCheckStatus.ready
              : LaunchCheckStatus.blocked,
          evidence: '${beta.criticalFlowCount} flujos en checklist manual.',
        ),
        LaunchReadinessCheck(
          id: 'feedback',
          title: 'Canal de feedback beta',
          area: 'Beta',
          status: beta.feedbackChannelReady
              ? LaunchCheckStatus.ready
              : LaunchCheckStatus.blocked,
          evidence: 'Persistencia local sin identificadores personales.',
        ),
        LaunchReadinessCheck(
          id: 'onboarding',
          title: 'Onboarding por rol',
          area: 'UX',
          status: onboardingFlowReady
              ? LaunchCheckStatus.ready
              : LaunchCheckStatus.blocked,
          evidence: 'Rutas de estudiante y docente disponibles.',
        ),
        LaunchReadinessCheck(
          id: 'documentation',
          title: 'Documentación de beta',
          area: 'Docs',
          status: documentationReady
              ? LaunchCheckStatus.ready
              : LaunchCheckStatus.blocked,
        ),
        LaunchReadinessCheck(
          id: 'metrics',
          title: 'Métricas de aprendizaje',
          area: 'Product',
          status: metricsReady
              ? LaunchCheckStatus.ready
              : LaunchCheckStatus.blocked,
        ),
        LaunchReadinessCheck(
          id: 'commercial',
          title: 'Preparación comercial',
          area: 'Commercial',
          status: commercial.score >= 80
              ? LaunchCheckStatus.ready
              : LaunchCheckStatus.pending,
          evidence: '${commercial.score}% completado.',
          requiredForClosedBeta: false,
        ),
      ];
      final blockers = checks
          .where((check) =>
              check.requiredForClosedBeta &&
              check.status == LaunchCheckStatus.blocked)
          .map((check) => check.title)
          .toList();
      final score = _score(checks);
      final report = LaunchReadinessReport(
        generatedAt: DateTime.now(),
        score: score,
        readyForClosedBeta: blockers.isEmpty && score >= 75,
        checks: checks,
        blockers: blockers,
        nextSteps:
            [...beta.nextSteps, ...commercial.pendingItems].take(5).toList(),
        feedbackCount: beta.feedback.total,
        onboardingProgress: onboarding.percentage,
      );
      await repository.save(
        documentId: reportId,
        type: reportType,
        payload: report.toJson(),
      );
      return report;
    } catch (_) {
      return LaunchReadinessReport.empty();
    }
  }

  Future<LaunchReadinessReport?> loadLatest() async {
    final payload = await repository.load(
      documentId: reportId,
      type: reportType,
      maxAge: const Duration(minutes: 15),
    );
    return payload == null ? null : LaunchReadinessReport.fromJson(payload);
  }

  int _score(List<LaunchReadinessCheck> checks) {
    if (checks.isEmpty) return 0;
    final points = checks.fold<int>(0, (total, check) {
      return total +
          switch (check.status) {
            LaunchCheckStatus.ready => 100,
            LaunchCheckStatus.pending => 50,
            LaunchCheckStatus.blocked => 0,
          };
    });
    return (points / checks.length).round().clamp(0, 100);
  }
}
