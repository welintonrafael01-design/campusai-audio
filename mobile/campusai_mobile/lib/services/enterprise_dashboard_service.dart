class EnterpriseDashboardSnapshot {
  final List<String> todaysPlan;
  final List<String> institutionAlerts;
  final List<String> marketplaceSuggestions;
  final List<String> creatorActivity;
  final List<String> aiDecisions;
  final List<String> workflowStatus;
  final List<String> predictionTimeline;
  final int goalProgress;
  final Map<String, int> studyHeatmap;
  final int knowledgeCoverage;

  const EnterpriseDashboardSnapshot({
    this.todaysPlan = const [],
    this.institutionAlerts = const [],
    this.marketplaceSuggestions = const [],
    this.creatorActivity = const [],
    this.aiDecisions = const [],
    this.workflowStatus = const [],
    this.predictionTimeline = const [],
    this.goalProgress = 0,
    this.studyHeatmap = const {},
    this.knowledgeCoverage = 0,
  });

  Map<String, dynamic> toJson() => {
        'todays_plan': todaysPlan,
        'institution_alerts': institutionAlerts,
        'marketplace_suggestions': marketplaceSuggestions,
        'creator_activity': creatorActivity,
        'ai_decisions': aiDecisions,
        'workflow_status': workflowStatus,
        'prediction_timeline': predictionTimeline,
        'goal_progress': goalProgress,
        'study_heatmap': studyHeatmap,
        'knowledge_coverage': knowledgeCoverage,
      };
}

class EnterpriseDashboardService {
  const EnterpriseDashboardService();

  EnterpriseDashboardSnapshot build({
    List<String> todaysPlan = const [],
    List<String> institutionAlerts = const [],
    List<String> marketplaceSuggestions = const [],
    List<String> creatorActivity = const [],
    List<String> aiDecisions = const [],
    List<String> workflowStatus = const [],
    List<String> predictionTimeline = const [],
    int goalProgress = 0,
    Map<String, int> studyHeatmap = const {},
    int knowledgeCoverage = 0,
  }) =>
      EnterpriseDashboardSnapshot(
        todaysPlan: todaysPlan,
        institutionAlerts: institutionAlerts,
        marketplaceSuggestions: marketplaceSuggestions,
        creatorActivity: creatorActivity,
        aiDecisions: aiDecisions,
        workflowStatus: workflowStatus,
        predictionTimeline: predictionTimeline,
        goalProgress: goalProgress.clamp(0, 100),
        studyHeatmap: studyHeatmap,
        knowledgeCoverage: knowledgeCoverage.clamp(0, 100),
      );
}
