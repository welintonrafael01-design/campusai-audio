import '../campus_intelligence/enterprise_result_repository.dart';
import 'cache_coverage_analyzer.dart';
import 'dashboard_load_analyzer.dart';
import 'heavy_service_analyzer.dart';
import 'performance_readiness_models.dart';
import 'voice_pipeline_analyzer.dart';

class PerformanceReadinessService {
  final EnterpriseResultRepository repository;
  final DashboardLoadAnalyzer dashboardLoadAnalyzer;
  final CacheCoverageAnalyzer cacheCoverageAnalyzer;
  final HeavyServiceAnalyzer heavyServiceAnalyzer;
  final VoicePipelineAnalyzer voicePipelineAnalyzer;

  const PerformanceReadinessService({
    this.repository = const EnterpriseResultRepository(),
    this.dashboardLoadAnalyzer = const DashboardLoadAnalyzer(),
    this.cacheCoverageAnalyzer = const CacheCoverageAnalyzer(),
    this.heavyServiceAnalyzer = const HeavyServiceAnalyzer(),
    this.voicePipelineAnalyzer = const VoicePipelineAnalyzer(),
  });

  Future<PerformanceReadinessReport> buildReport() async {
    final findings = <PerformanceFinding>[
      dashboardLoadAnalyzer.analyze(serviceCount: 10),
      cacheCoverageAnalyzer.analyze(
        cachedAreas: const [
          'dashboard',
          'prediction',
          'voice',
          'marketplace',
          'institution',
        ],
        criticalAreas: const [
          'dashboard',
          'prediction',
          'voice',
          'marketplace',
          'institution',
          'campusai',
        ],
      ),
      voicePipelineAnalyzer.analyze(stages: 7),
      ...heavyServiceAnalyzer.analyze(const [
        'CampusAI Enterprise Services',
        'Student Enterprise Analytics',
        'Institution Enterprise Analytics',
      ]),
    ];
    final score = (100 -
            findings.where((item) => item.severity == 'medium').length * 8 -
            findings.where((item) => item.severity == 'high').length * 20)
        .clamp(0, 100);
    final report = PerformanceReadinessReport(
      generatedAt: DateTime.now(),
      score: score,
      findings: findings,
    );
    await repository.save(
      documentId: 'performance_readiness_latest',
      type: 'performance_readiness',
      payload: report.toJson(),
    );
    return report;
  }
}
