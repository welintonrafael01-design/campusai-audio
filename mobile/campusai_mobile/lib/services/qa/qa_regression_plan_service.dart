import 'qa_models.dart';

class QaRegressionPlanService {
  const QaRegressionPlanService();

  Map<String, List<QaScenario>> groupByArea(List<QaScenario> scenarios) {
    final grouped = <String, List<QaScenario>>{};
    for (final scenario in scenarios) {
      grouped.putIfAbsent(scenario.area, () => []).add(scenario);
    }
    return grouped;
  }
}
