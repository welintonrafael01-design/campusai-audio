class QaScenario {
  final String id;
  final String title;
  final String area;
  final List<String> steps;
  final String expectedResult;
  final String priority;

  const QaScenario({
    required this.id,
    required this.title,
    required this.area,
    this.steps = const [],
    this.expectedResult = '',
    this.priority = 'medium',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'area': area,
        'steps': steps,
        'expected_result': expectedResult,
        'priority': priority,
      };
}

class QaValidationResult {
  final String scenarioId;
  final bool ready;
  final List<String> findings;

  const QaValidationResult({
    required this.scenarioId,
    this.ready = true,
    this.findings = const [],
  });

  Map<String, dynamic> toJson() =>
      {'scenario_id': scenarioId, 'ready': ready, 'findings': findings};
}

class QaReport {
  final DateTime generatedAt;
  final List<QaScenario> scenarios;
  final List<QaValidationResult> results;

  const QaReport({
    required this.generatedAt,
    this.scenarios = const [],
    this.results = const [],
  });

  Map<String, dynamic> toJson() => {
        'generated_at': generatedAt.toIso8601String(),
        'scenarios': scenarios.map((item) => item.toJson()).toList(),
        'results': results.map((item) => item.toJson()).toList(),
      };
}

class QaManualChecklistItem {
  final String title;
  final String area;
  final bool required;

  const QaManualChecklistItem({
    required this.title,
    required this.area,
    this.required = true,
  });

  Map<String, dynamic> toJson() =>
      {'title': title, 'area': area, 'required': required};
}
