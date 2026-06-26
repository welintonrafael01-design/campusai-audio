class ObservabilityReadinessReport {
  final DateTime generatedAt;
  final bool logsAvailable;
  final bool metricsAvailable;
  final bool crashRecorderAvailable;
  final bool aiUsageMetricsAvailable;
  final bool serviceHealthAvailable;
  final bool eventRecorderAvailable;
  final bool localTelemetryAvailable;

  const ObservabilityReadinessReport({
    required this.generatedAt,
    this.logsAvailable = true,
    this.metricsAvailable = true,
    this.crashRecorderAvailable = true,
    this.aiUsageMetricsAvailable = true,
    this.serviceHealthAvailable = true,
    this.eventRecorderAvailable = true,
    this.localTelemetryAvailable = true,
  });

  int get score {
    final checks = [
      logsAvailable,
      metricsAvailable,
      crashRecorderAvailable,
      aiUsageMetricsAvailable,
      serviceHealthAvailable,
      eventRecorderAvailable,
      localTelemetryAvailable,
    ];
    return (checks.where((item) => item).length * 100 / checks.length).round();
  }

  Map<String, dynamic> toJson() => {
        'generated_at': generatedAt.toIso8601String(),
        'score': score,
        'logs_available': logsAvailable,
        'metrics_available': metricsAvailable,
        'crash_recorder_available': crashRecorderAvailable,
        'ai_usage_metrics_available': aiUsageMetricsAvailable,
        'service_health_available': serviceHealthAvailable,
        'event_recorder_available': eventRecorderAvailable,
        'local_telemetry_available': localTelemetryAvailable,
      };
}

class ObservabilityReadinessService {
  const ObservabilityReadinessService();

  ObservabilityReadinessReport evaluate() =>
      ObservabilityReadinessReport(generatedAt: DateTime.now());
}
