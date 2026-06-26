import 'agent_models.dart';
import 'base_agent.dart';

class StudentAgent extends LocalAgent {
  StudentAgent() : super('student', 'Student Agent');
}

class LocalAgent implements BaseAgent {
  @override
  final String id;
  @override
  final String title;
  const LocalAgent(this.id, this.title);
  @override
  List<AgentCapability> get capabilities =>
      [AgentCapability(id: id, title: title)];
  @override
  Future<AgentResponse> execute(AgentTask task) async => AgentResponse(
      text: '$title: ${task.prompt}',
      actions: const ['Revisar el plan inteligente']);
}
