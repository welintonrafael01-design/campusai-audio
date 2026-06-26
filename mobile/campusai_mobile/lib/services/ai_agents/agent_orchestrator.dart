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
}
