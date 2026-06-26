import '../campus_intelligence/enterprise_result_repository.dart';
import 'agent_models.dart';

class AgentTaskService {
  final EnterpriseResultRepository repository;
  const AgentTaskService(
      {this.repository = const EnterpriseResultRepository()});
  Future<void> save(AgentTask task) => repository.save(
      documentId: task.id,
      type: 'agent_task',
      payload: task.toJson(),
      createdAt: task.createdAt);
  Future<void> record(AgentExecution execution) => repository.save(
      documentId: execution.taskId,
      type: 'agent_execution',
      payload: execution.toJson(),
      createdAt: execution.executedAt);
}
