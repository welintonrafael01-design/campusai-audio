class PerformanceFinding {
  final String area;
  final String severity;
  final String message;
  final String recommendation;

  const PerformanceFinding({
    required this.area,
    this.severity = 'low',
    this.message = '',
    this.recommendation = '',
  });

  Map<String, dynamic> toJson() => {
        'area': area,
        'severity': severity,
        'message': message,
        'recommendation': recommendation,
      };
}

class PerformanceReadinessReport {
  final DateTime generatedAt;
  final int score;
  final List<PerformanceFinding> findings;

  const PerformanceReadinessReport({
    required this.generatedAt,
    this.score = 100,
    this.findings = const [],
  });

  Map<String, dynamic> toJson() => {
        'generated_at': generatedAt.toIso8601String(),
        'score': score,
        'findings': findings.map((item) => item.toJson()).toList(),
      };
}
