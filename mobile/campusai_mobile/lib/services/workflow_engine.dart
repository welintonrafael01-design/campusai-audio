import 'campus_intelligence/enterprise_result_repository.dart';

typedef WorkflowStepHandler = Future<Map<String, dynamic>> Function(
  WorkflowExecution execution,
);

class WorkflowStep {
  final String id;
  final String title;
  final List<String> dependsOn;
  final Map<String, dynamic> config;

  const WorkflowStep({
    required this.id,
    required this.title,
    this.dependsOn = const [],
    this.config = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'depends_on': dependsOn,
        'config': config,
      };
}

class WorkflowExecution {
  final String id;
  final String workflowId;
  final DateTime startedAt;
  final Map<String, dynamic> context;
  final List<Map<String, dynamic>> stepResults;

  const WorkflowExecution({
    required this.id,
    required this.workflowId,
    required this.startedAt,
    this.context = const {},
    this.stepResults = const [],
  });

  WorkflowExecution append(String stepId, Map<String, dynamic> result) =>
      WorkflowExecution(
        id: id,
        workflowId: workflowId,
        startedAt: startedAt,
        context: context,
        stepResults: [
          ...stepResults,
          {'step_id': stepId, 'result': result}
        ],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'workflow_id': workflowId,
        'started_at': startedAt.toIso8601String(),
        'context': context,
        'step_results': stepResults,
      };
}

class WorkflowResult {
  final String executionId;
  final String status;
  final DateTime completedAt;
  final List<Map<String, dynamic>> results;

  const WorkflowResult({
    required this.executionId,
    this.status = 'completed',
    required this.completedAt,
    this.results = const [],
  });

  Map<String, dynamic> toJson() => {
        'execution_id': executionId,
        'status': status,
        'completed_at': completedAt.toIso8601String(),
        'results': results,
      };
}

class WorkflowEngine {
  final EnterpriseResultRepository repository;
  final Map<String, WorkflowStepHandler> handlers;

  const WorkflowEngine({
    this.repository = const EnterpriseResultRepository(),
    this.handlers = const {},
  });

  Future<WorkflowResult> execute({
    required String workflowId,
    required List<WorkflowStep> steps,
    Map<String, dynamic> context = const {},
  }) async {
    var execution = WorkflowExecution(
      id: '${workflowId}_${DateTime.now().millisecondsSinceEpoch}',
      workflowId: workflowId,
      startedAt: DateTime.now(),
      context: context,
    );
    for (final step in _orderSteps(steps)) {
      final handler = handlers[step.id];
      final result = handler == null
          ? {'status': 'skipped', 'reason': 'handler_not_registered'}
          : await handler(execution);
      execution = execution.append(step.id, result);
    }
    final workflowResult = WorkflowResult(
      executionId: execution.id,
      completedAt: DateTime.now(),
      results: execution.stepResults,
    );
    await repository.save(
      documentId: execution.id,
      type: EnterpriseStudyResultTypes.workflowExecution,
      payload: workflowResult.toJson(),
    );
    await repository.save(
      documentId: '${workflowId}_history',
      type: EnterpriseStudyResultTypes.workflowHistory,
      payload: {'latest': workflowResult.toJson()},
    );
    return workflowResult;
  }

  List<WorkflowStep> defaultStudentOpenAppPipeline() => const [
        WorkflowStep(id: 'load_snapshot', title: 'Load snapshot'),
        WorkflowStep(
            id: 'prediction',
            title: 'Prediction',
            dependsOn: ['load_snapshot']),
        WorkflowStep(
            id: 'planner', title: 'Planner', dependsOn: ['prediction']),
        WorkflowStep(
            id: 'notifications',
            title: 'Notifications',
            dependsOn: ['planner']),
        WorkflowStep(
            id: 'voice_context',
            title: 'Voice context',
            dependsOn: ['notifications']),
        WorkflowStep(
            id: 'dashboard', title: 'Dashboard', dependsOn: ['voice_context']),
        WorkflowStep(
            id: 'marketplace_recommendations',
            title: 'Marketplace recommendations',
            dependsOn: ['dashboard']),
        WorkflowStep(
            id: 'save_snapshot',
            title: 'Save snapshot',
            dependsOn: ['marketplace_recommendations']),
      ];

  List<WorkflowStep> _orderSteps(List<WorkflowStep> steps) {
    final ordered = <WorkflowStep>[];
    final pending = [...steps];
    while (pending.isNotEmpty) {
      final index = pending.indexWhere((step) =>
          step.dependsOn.every((id) => ordered.any((done) => done.id == id)));
      ordered.add(pending.removeAt(index < 0 ? 0 : index));
    }
    return ordered;
  }
}

class WorkflowScheduler {
  final WorkflowEngine engine;
  const WorkflowScheduler({this.engine = const WorkflowEngine()});

  Future<WorkflowResult> runNow({
    required String workflowId,
    required List<WorkflowStep> steps,
    Map<String, dynamic> context = const {},
  }) =>
      engine.execute(workflowId: workflowId, steps: steps, context: context);
}

class EnterpriseStudyResultTypes {
  static const workflowExecution = 'workflow_execution';
  static const agentExecution = 'agent_execution';
  static const decisionHistory = 'decision_history';
  static const workflowHistory = 'workflow_history';
  static const creatorDashboard = 'creator_dashboard';
  static const marketplaceHistory = 'marketplace_history';
  static const institutionWorkspace = 'institution_workspace';
  static const voicePipeline = 'voice_pipeline';
  static const predictionCache = 'prediction_cache';
  static const dashboardCache = 'dashboard_cache';
}
