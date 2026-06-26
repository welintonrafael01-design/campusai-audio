class TelemetryDashboard {
  final Map<String, num> executionMetrics;
  final Map<String, num> agentMetrics;
  final Map<String, num> workflowMetrics;
  final Map<String, num> marketplaceMetrics;
  final Map<String, num> predictionMetrics;
  final Map<String, num> plannerMetrics;
  final Map<String, num> voiceMetrics;
  final Map<String, num> institutionMetrics;

  const TelemetryDashboard({
    this.executionMetrics = const {},
    this.agentMetrics = const {},
    this.workflowMetrics = const {},
    this.marketplaceMetrics = const {},
    this.predictionMetrics = const {},
    this.plannerMetrics = const {},
    this.voiceMetrics = const {},
    this.institutionMetrics = const {},
  });

  Map<String, dynamic> toJson() => {
        'execution_metrics': executionMetrics,
        'agent_metrics': agentMetrics,
        'workflow_metrics': workflowMetrics,
        'marketplace_metrics': marketplaceMetrics,
        'prediction_metrics': predictionMetrics,
        'planner_metrics': plannerMetrics,
        'voice_metrics': voiceMetrics,
        'institution_metrics': institutionMetrics,
      };
}

class EnterpriseObservabilityService {
  const EnterpriseObservabilityService();

  TelemetryDashboard buildDashboard({
    Map<String, num> execution = const {},
    Map<String, num> agents = const {},
    Map<String, num> workflows = const {},
    Map<String, num> marketplace = const {},
    Map<String, num> prediction = const {},
    Map<String, num> planner = const {},
    Map<String, num> voice = const {},
    Map<String, num> institution = const {},
  }) =>
      TelemetryDashboard(
        executionMetrics: execution,
        agentMetrics: agents,
        workflowMetrics: workflows,
        marketplaceMetrics: marketplace,
        predictionMetrics: prediction,
        plannerMetrics: planner,
        voiceMetrics: voice,
        institutionMetrics: institution,
      );
}
