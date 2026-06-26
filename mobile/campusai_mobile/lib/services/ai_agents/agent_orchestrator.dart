import 'agent_models.dart';
import 'base_agent.dart';

class AgentOrchestrator {
  final List<BaseAgent> agents;
  const AgentOrchestrator(this.agents);

  Future<AgentResponse> route(AgentTask task) async {
    BaseAgent? agent;
    for (final candidate in agents) {
      if (candidate.id == task.agentId) {
        agent = candidate;
        break;
      }
    }
    if (agent == null) {
      return const AgentResponse(text: 'Agente no disponible.');
    }
    return agent.execute(task);
  }

  Future<AgentResponse> routeByCapability(
    AgentTask task,
    String capabilityId,
  ) async {
    final matches = agents
        .where((agent) => agent.capabilities
            .any((capability) => capability.id == capabilityId))
        .toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
    if (matches.isEmpty) {
      return const AgentResponse(text: 'Capacidad no disponible.');
    }
    return matches.first.execute(task);
  }

  Future<List<AgentResponse>> collaborate(AgentTask task) async {
    final ordered = [...agents]
      ..sort((a, b) => a.priority.compareTo(b.priority));
    final responses = <AgentResponse>[];
    for (final agent in ordered) {
      responses.add(await agent.collaborate(task, ordered));
    }
    return responses;
  }

  Map<String, dynamic> healthReport() => {
        'agents': agents
            .map((agent) => {
                  'id': agent.id,
                  'title': agent.title,
                  'priority': agent.priority,
                  'execution_cost': agent.executionCost,
                  'estimated_latency_ms': agent.estimatedLatency.inMilliseconds,
                  'dependencies': agent.dependencies,
                  'health_status': agent.healthStatus,
                  'capabilities':
                      agent.capabilities.map((item) => item.id).toList(),
                })
            .toList()
      };
}
