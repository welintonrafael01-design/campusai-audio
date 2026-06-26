class AgentCapability {
  final String id;
  final String title;
  const AgentCapability({this.id = '', this.title = ''});
}

class AgentTask {
  final String id;
  final String agentId;
  final String prompt;
  final DateTime createdAt;
  const AgentTask(
      {this.id = '',
      this.agentId = '',
      this.prompt = '',
      required this.createdAt});
  Map<String, dynamic> toJson() => {
        'id': id,
        'agent_id': agentId,
        'prompt': prompt,
        'created_at': createdAt.toIso8601String()
      };
}

class AgentResponse {
  final String text;
  final List<String> actions;
  const AgentResponse({this.text = '', this.actions = const []});
}

class AgentExecution {
  final String taskId;
  final String status;
  final DateTime executedAt;
  const AgentExecution(
      {this.taskId = '', this.status = 'completed', required this.executedAt});
  Map<String, dynamic> toJson() => {
        'task_id': taskId,
        'status': status,
        'executed_at': executedAt.toIso8601String()
      };
}

class AgentMemory {
  final String agentId;
  final List<String> facts;
  final DateTime updatedAt;
  const AgentMemory(
      {this.agentId = '', this.facts = const [], required this.updatedAt});
  Map<String, dynamic> toJson() => {
        'agent_id': agentId,
        'facts': facts,
        'updated_at': updatedAt.toIso8601String()
      };
}
