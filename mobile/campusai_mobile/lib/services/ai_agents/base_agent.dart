import 'agent_models.dart';

abstract class BaseAgent {
  const BaseAgent();

  String get id;
  String get title;
  List<AgentCapability> get capabilities;
  int get priority => 5;
  int get executionCost => 1;
  Duration get estimatedLatency => const Duration(milliseconds: 500);
  List<String> get dependencies => const [];
  String get healthStatus => 'healthy';
  Future<AgentResponse> execute(AgentTask task);

  Future<AgentResponse> collaborate(
    AgentTask task,
    List<BaseAgent> peers,
  ) =>
      execute(task);
}
