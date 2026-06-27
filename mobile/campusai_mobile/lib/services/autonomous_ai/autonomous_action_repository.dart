import '../campus_intelligence/enterprise_result_repository.dart';
import 'autonomous_action_models.dart';

/// Persistencia local de planes, acciones e historial autónomo.
class AutonomousActionRepository {
  static const actionType = 'autonomous_action';
  static const planType = 'autonomous_action_plan';
  static const historyType = 'autonomous_action_history';
  static const latestPlanId = 'autonomous_action_plan_latest';
  static const historyId = 'autonomous_action_history_latest';

  final EnterpriseResultRepository repository;

  const AutonomousActionRepository({
    this.repository = const EnterpriseResultRepository(),
  });

  Future<void> savePlan(AutonomousActionPlan plan) async {
    await repository.save(
      documentId: latestPlanId,
      type: planType,
      payload: plan.toJson(),
      createdAt: plan.generatedAt,
    );
    for (final action in plan.actions) {
      await saveAction(action);
    }
  }

  Future<void> saveAction(AutonomousAction action) => repository.save(
        documentId: action.id,
        type: actionType,
        payload: action.toJson(),
        createdAt: action.updatedAt,
      );

  Future<void> updateActionStatus(AutonomousAction action) async {
    await saveAction(action);
    final plan = await loadLatestPlan(maxAge: const Duration(days: 1));
    if (plan == null) return;
    final updatedActions = plan.actions
        .map((item) => item.id == action.id ? action : item)
        .toList();
    await repository.save(
      documentId: latestPlanId,
      type: planType,
      payload: plan.copyWith(actions: updatedActions).toJson(),
      createdAt: plan.generatedAt,
    );
  }

  Future<AutonomousActionPlan?> loadLatestPlan({
    Duration maxAge = const Duration(minutes: 5),
  }) async {
    final payload = await repository.load(
      documentId: latestPlanId,
      type: planType,
      maxAge: maxAge,
    );
    if (payload == null) return null;
    final plan = AutonomousActionPlan.fromJson(payload);
    if (DateTime.now().difference(plan.generatedAt) > maxAge) return null;
    return plan;
  }

  Future<List<AutonomousActionResult>> loadHistory() async {
    final payload = await repository.load(
      documentId: historyId,
      type: historyType,
      maxAge: Duration.zero,
    );
    final raw = payload?['results'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((item) => AutonomousActionResult.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();
  }

  Future<void> recordResult(AutonomousActionResult result) async {
    final history = await loadHistory();
    final updated = [
      result,
      ...history.where((item) => item.actionId != result.actionId),
    ].take(100).toList();
    await repository.save(
      documentId: historyId,
      type: historyType,
      payload: {
        'updated_at': DateTime.now().toIso8601String(),
        'results': updated.map((item) => item.toJson()).toList(),
      },
    );
  }
}
