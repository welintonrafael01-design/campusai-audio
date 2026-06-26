import 'rc_models.dart';

class RcRiskAssessmentService {
  const RcRiskAssessmentService();

  List<RcRisk> assess(List<RcModuleStatus> modules) {
    final risks = <RcRisk>[];
    for (final module in modules) {
      if (module.readiness < 80) {
        risks.add(RcRisk(
          area: module.module,
          severity: 'medium',
          description: 'Readiness menor a 80%.',
          mitigation: 'Completar checklist del módulo antes de RC.',
        ));
      }
      if (module.status == 'foundation') {
        risks.add(RcRisk(
          area: module.module,
          severity: 'low',
          description: 'Módulo en modo foundation/local-first.',
          mitigation: 'No prometer capacidades cloud o pagos reales en RC1.',
        ));
      }
    }
    return risks;
  }
}
