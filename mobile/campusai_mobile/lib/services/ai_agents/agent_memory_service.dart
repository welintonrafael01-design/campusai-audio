import '../campus_intelligence/enterprise_result_repository.dart';
import 'agent_models.dart';

class AgentMemoryService {
  final EnterpriseResultRepository repository;
  const AgentMemoryService(
      {this.repository = const EnterpriseResultRepository()});
  Future<void> save(AgentMemory memory) => repository.save(
      documentId: '${memory.agentId}_memory',
      type: 'agent_memory',
      payload: memory.toJson(),
      createdAt: memory.updatedAt);
  Future<AgentMemory?> load(String id) async {
    final data =
        await repository.load(documentId: '${id}_memory', type: 'agent_memory');
    if (data == null) return null;
    return AgentMemory(
        agentId: data['agent_id']?.toString() ?? id,
        facts: (data['facts'] as List? ?? const [])
            .map((x) => x.toString())
            .toList(),
        updatedAt: DateTime.tryParse(data['updated_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0));
  }
}
