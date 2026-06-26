import '../campus_intelligence/enterprise_result_repository.dart';
import 'rc_checklist_service.dart';
import 'rc_models.dart';
import 'rc_module_status_service.dart';
import 'rc_quality_gate_service.dart';
import 'rc_risk_assessment_service.dart';

class RcReadinessService {
  final EnterpriseResultRepository repository;
  final RcModuleStatusService moduleStatusService;
  final RcQualityGateService qualityGateService;
  final RcRiskAssessmentService riskAssessmentService;
  final RcChecklistService checklistService;

  const RcReadinessService({
    this.repository = const EnterpriseResultRepository(),
    this.moduleStatusService = const RcModuleStatusService(),
    this.qualityGateService = const RcQualityGateService(),
    this.riskAssessmentService = const RcRiskAssessmentService(),
    this.checklistService = const RcChecklistService(),
  });

  Future<ReleaseCandidateReport> buildReport({
    bool backendOk = true,
    bool flutterOk = true,
    bool securityOk = true,
    bool qaChecklistOk = true,
  }) async {
    final modules = moduleStatusService.buildModuleStatuses();
    final gates = qualityGateService.buildQualityGates(
      backendOk: backendOk,
      flutterOk: flutterOk,
      securityOk: securityOk,
      qaChecklistOk: qaChecklistOk,
    );
    final risks = riskAssessmentService.assess(modules);
    final checklist = checklistService.buildChecklist();
    final score = _score(modules, gates, risks);
    final report = ReleaseCandidateReport(
      score: score,
      generatedAt: DateTime.now(),
      modules: modules,
      qualityGates: gates,
      risks: risks,
      checklist: checklist,
    );
    await repository.save(
      documentId: 'release_candidate_report_latest',
      type: 'release_candidate_report',
      payload: report.toJson(),
    );
    await qualityGateService.saveQualityGates(gates);
    return report;
  }

  int _score(
    List<RcModuleStatus> modules,
    List<RcQualityGate> gates,
    List<RcRisk> risks,
  ) {
    final moduleScore = modules.isEmpty
        ? 0
        : modules.map((item) => item.readiness).reduce((a, b) => a + b) ~/
            modules.length;
    final gatePenalty = gates.where((gate) => !gate.passed).length * 12;
    final riskPenalty =
        risks.where((risk) => risk.severity == 'medium').length * 5 +
            risks.where((risk) => risk.severity == 'high').length * 15;
    return (moduleScore - gatePenalty - riskPenalty).clamp(0, 100);
  }
}
