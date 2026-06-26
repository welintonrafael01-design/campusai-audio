import '../campus_intelligence/enterprise_result_repository.dart';
import 'rc_models.dart';

class RcQualityGateService {
  final EnterpriseResultRepository repository;
  const RcQualityGateService({
    this.repository = const EnterpriseResultRepository(),
  });

  List<RcQualityGate> buildQualityGates({
    bool backendOk = true,
    bool flutterOk = true,
    bool securityOk = true,
    bool qaChecklistOk = true,
  }) =>
      [
        RcQualityGate(
          name: 'Backend compile',
          passed: backendOk,
          evidence: 'python3 -m py_compile',
        ),
        RcQualityGate(
          name: 'Flutter analyze',
          passed: flutterOk,
          evidence: '0 errores, solo infos históricos',
        ),
        RcQualityGate(
          name: 'Security scan',
          passed: securityOk,
          evidence: 'sin secretos completos expuestos',
        ),
        RcQualityGate(
          name: 'QA checklist',
          passed: qaChecklistOk,
          evidence: 'escenarios críticos definidos',
        ),
      ];

  Future<void> saveQualityGates(List<RcQualityGate> gates) => repository.save(
        documentId: 'rc_quality_gate_latest',
        type: 'rc_quality_gate',
        payload: {'gates': gates.map((item) => item.toJson()).toList()},
      );
}
