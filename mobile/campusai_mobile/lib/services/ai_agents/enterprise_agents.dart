import 'agent_models.dart';
import 'base_agent.dart';

class LearningAgent extends _EnterpriseAgent {
  const LearningAgent()
      : super(
            id: 'learning_agent',
            title: 'Learning Agent',
            capabilityIds: const ['learning', 'student_progress', 'mastery'],
            priority: 1,
            executionCost: 2,
            dependencies: const ['learning_engine']);
}

class PlannerAgent extends _EnterpriseAgent {
  const PlannerAgent()
      : super(
            id: 'planner_agent',
            title: 'Planner Agent',
            capabilityIds: const ['planning', 'goals', 'schedule'],
            priority: 2,
            executionCost: 1,
            dependencies: const ['learning_agent']);
}

class PredictionAgent extends _EnterpriseAgent {
  const PredictionAgent()
      : super(
            id: 'prediction_agent',
            title: 'Prediction Agent',
            capabilityIds: const ['prediction', 'risk', 'forecast'],
            priority: 1,
            executionCost: 3,
            dependencies: const ['campus_intelligence']);
}

class MarketplaceAgent extends _EnterpriseAgent {
  const MarketplaceAgent()
      : super(
            id: 'marketplace_agent',
            title: 'Marketplace Agent',
            capabilityIds: const ['marketplace', 'resource_recommendation'],
            priority: 4,
            executionCost: 1);
}

class VoiceAgent extends _EnterpriseAgent {
  const VoiceAgent()
      : super(
            id: 'voice_agent',
            title: 'Voice Agent',
            capabilityIds: const ['voice_context', 'conversation'],
            priority: 3,
            executionCost: 2,
            dependencies: const ['voice_intelligence']);
}

class InstitutionAgent extends _EnterpriseAgent {
  const InstitutionAgent()
      : super(
            id: 'institution_agent',
            title: 'Institution Agent',
            capabilityIds: const ['institution', 'tenant', 'policy'],
            priority: 3,
            executionCost: 2,
            dependencies: const ['institution_platform']);
}

class AnalyticsAgent extends _EnterpriseAgent {
  const AnalyticsAgent()
      : super(
            id: 'analytics_agent',
            title: 'Analytics Agent',
            capabilityIds: const ['analytics', 'metrics', 'dashboard'],
            priority: 2,
            executionCost: 2);
}

class NotificationAgent extends _EnterpriseAgent {
  const NotificationAgent()
      : super(
            id: 'notification_agent',
            title: 'Notification Agent',
            capabilityIds: const ['notifications', 'alerts'],
            priority: 5,
            executionCost: 1);
}

class RecommendationAgent extends _EnterpriseAgent {
  const RecommendationAgent()
      : super(
            id: 'recommendation_agent',
            title: 'Recommendation Agent',
            capabilityIds: const ['recommendations', 'next_best_action'],
            priority: 2,
            executionCost: 2,
            dependencies: const ['decision_engine']);
}

class MemoryAgent extends _EnterpriseAgent {
  const MemoryAgent()
      : super(
            id: 'memory_agent',
            title: 'Memory Agent',
            capabilityIds: const ['memory', 'context', 'snapshot'],
            priority: 1,
            executionCost: 1);
}

class EnterpriseAgentRegistry {
  const EnterpriseAgentRegistry();

  List<BaseAgent> buildDefaultAgents() => const [
        LearningAgent(),
        PlannerAgent(),
        PredictionAgent(),
        MarketplaceAgent(),
        VoiceAgent(),
        InstitutionAgent(),
        AnalyticsAgent(),
        NotificationAgent(),
        RecommendationAgent(),
        MemoryAgent(),
      ];
}

class _EnterpriseAgent implements BaseAgent {
  @override
  final String id;
  @override
  final String title;
  final List<String> capabilityIds;
  @override
  final int priority;
  @override
  final int executionCost;
  @override
  final Duration estimatedLatency = const Duration(milliseconds: 650);
  @override
  final List<String> dependencies;
  @override
  final String healthStatus = 'healthy';

  const _EnterpriseAgent({
    required this.id,
    required this.title,
    required this.capabilityIds,
    required this.priority,
    required this.executionCost,
    this.dependencies = const [],
  });

  @override
  List<AgentCapability> get capabilities => capabilityIds
      .map((id) => AgentCapability(id: id, title: id.replaceAll('_', ' ')))
      .toList();

  @override
  Future<AgentResponse> execute(AgentTask task) async => AgentResponse(
        text: '$title procesó: ${task.prompt}',
        actions: ['agent_execution', id],
      );

  @override
  Future<AgentResponse> collaborate(
    AgentTask task,
    List<BaseAgent> peers,
  ) async {
    final peerIds = peers
        .where((agent) => dependencies.contains(agent.id))
        .map((agent) => agent.id)
        .toList();
    return AgentResponse(
      text: '$title colaboró con ${peerIds.join(', ')}',
      actions: ['agent_collaboration', ...peerIds],
    );
  }
}
