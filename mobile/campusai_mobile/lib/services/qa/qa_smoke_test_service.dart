import '../campus_intelligence/enterprise_result_repository.dart';
import 'qa_flow_validator_service.dart';
import 'qa_models.dart';
import 'qa_scenario_service.dart';

class QaSmokeTestService {
  final EnterpriseResultRepository repository;
  final QaScenarioService scenarioService;
  final QaFlowValidatorService validatorService;

  const QaSmokeTestService({
    this.repository = const EnterpriseResultRepository(),
    this.scenarioService = const QaScenarioService(),
    this.validatorService = const QaFlowValidatorService(),
  });

  Future<QaReport> buildSmokeReport() async {
    final scenarios = scenarioService.buildCriticalScenarios();
    final results = validatorService.validate(scenarios);
    final report = QaReport(
      generatedAt: DateTime.now(),
      scenarios: scenarios,
      results: results,
    );
    await repository.save(
      documentId: 'qa_report_latest',
      type: 'qa_report',
      payload: report.toJson(),
    );
    await scenarioService.saveScenarios(scenarios);
    return report;
  }
}
