import 'agent_models.dart';

abstract class BaseAgent {
  String get id;
  String get title;
  List<AgentCapability> get capabilities;
  Future<AgentResponse> execute(AgentTask task);
}
