import 'qa_models.dart';

class QaFlowValidatorService {
  const QaFlowValidatorService();

  List<QaValidationResult> validate(List<QaScenario> scenarios) =>
      scenarios.map(_validateScenario).toList();

  QaValidationResult _validateScenario(QaScenario scenario) {
    final findings = <String>[
      if (scenario.id.trim().isEmpty) 'Escenario sin id',
      if (scenario.title.trim().isEmpty) 'Escenario sin título',
      if (scenario.area.trim().isEmpty) 'Escenario sin área',
    ];
    return QaValidationResult(
      scenarioId: scenario.id,
      ready: findings.isEmpty,
      findings: findings,
    );
  }
}
