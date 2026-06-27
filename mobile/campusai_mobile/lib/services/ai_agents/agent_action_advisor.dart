import '../autonomous_ai/autonomous_action_models.dart';
import '../autonomous_ai/decision_action_bridge.dart';
import 'agent_models.dart';
import 'agent_orchestrator.dart';
import 'enterprise_agents.dart';

/// Adaptador mínimo que convierte consejo del orquestador en una acción tipada.
class AgentActionAdvisor {
  final AgentOrchestrator orchestrator;
  final DecisionActionBridge bridge;

  const AgentActionAdvisor({
    this.orchestrator = const AgentOrchestrator([
      RecommendationAgent(),
      LearningAgent(),
      PlannerAgent(),
    ]),
    this.bridge = const DecisionActionBridge(),
  });

  Future<AutonomousAction?> advise({
    required int risk,
    required String weakness,
    required String planAction,
  }) async {
    if (risk < 40 && weakness.trim().isEmpty && planAction.trim().isEmpty) {
      return null;
    }
    final response = await orchestrator.routeByCapability(
      AgentTask(
        id: 'autonomous_advice_${DateTime.now().millisecondsSinceEpoch}',
        agentId: 'recommendation_agent',
        prompt: 'Riesgo $risk. Debilidad: $weakness. Plan: $planAction.',
        createdAt: DateTime.now(),
      ),
      'next_best_action',
    );
    if (risk >= 60 || weakness.trim().isNotEmpty) {
      return bridge.create(
        type: AutonomousActionTypes.talkToTutor,
        title: weakness.trim().isEmpty
            ? 'Aclara tu próxima prioridad'
            : 'Trabaja $weakness con el Tutor IA',
        reason: _reason(
            response.text, 'Un agente detectó una prioridad académica.'),
        actionLabel: 'Abrir Tutor IA',
        targetId: weakness,
        priority: risk >= 60
            ? AutonomousActionPriority.high
            : AutonomousActionPriority.normal,
        metadata: {
          'source': 'agent_orchestrator',
          'agent_actions': response.actions.take(3).toList(),
        },
      );
    }
    return bridge.create(
      type: AutonomousActionTypes.followSmartPlan,
      title: 'Sigue la recomendación del plan',
      reason: _reason(response.text, planAction),
      actionLabel: 'Ver plan',
      priority: AutonomousActionPriority.normal,
      metadata: {'source': 'agent_orchestrator'},
    );
  }

  String _reason(String value, String fallback) {
    final text = value.trim().isEmpty ? fallback.trim() : value.trim();
    if (text.length <= 180) return text;
    return '${text.substring(0, 180)}...';
  }
}
