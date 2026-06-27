import '../decision_engine.dart';
import '../enterprise_notifications/enterprise_notification_center.dart';
import 'autonomous_action_models.dart';

/// Traduce decisiones y notificaciones existentes a acciones ejecutables.
class DecisionActionBridge {
  const DecisionActionBridge();

  AutonomousAction fromDecision(
    DecisionScore decision, {
    String weakness = '',
  }) {
    final reason = decision.reasons.isEmpty
        ? 'El motor de decisión recomienda el siguiente paso.'
        : decision.reasons.first.message;
    return switch (decision.action) {
      'intervention' => create(
          type: AutonomousActionTypes.reviewWeakness,
          title: weakness.isEmpty
              ? 'Refuerza una debilidad'
              : 'Refuerza $weakness',
          reason: reason,
          actionLabel: 'Hablar con Tutor IA',
          targetId: weakness,
          priority: AutonomousActionPriority.critical,
          metadata: {
            'decision_score': decision.score,
            'source': 'decision_engine'
          },
        ),
      'light_review' => create(
          type: AutonomousActionTypes.reviewFlashcards,
          title: 'Haz un repaso ligero',
          reason: reason,
          actionLabel: 'Repasar',
          priority: AutonomousActionPriority.high,
          metadata: {
            'decision_score': decision.score,
            'source': 'decision_engine'
          },
        ),
      'advance' => create(
          type: AutonomousActionTypes.followSmartPlan,
          title: 'Continúa con tu plan inteligente',
          reason: reason,
          actionLabel: 'Ver plan',
          priority: AutonomousActionPriority.normal,
          metadata: {
            'decision_score': decision.score,
            'source': 'decision_engine'
          },
        ),
      _ => create(
          type: AutonomousActionTypes.takeQuiz,
          title: 'Comprueba tu dominio',
          reason: reason,
          actionLabel: 'Practicar',
          priority: AutonomousActionPriority.normal,
          metadata: {
            'decision_score': decision.score,
            'source': 'decision_engine'
          },
        ),
    };
  }

  AutonomousAction? fromNotification(EnterpriseNotification notification) {
    final priority = switch (notification.priority) {
      NotificationPriority.critical => AutonomousActionPriority.critical,
      NotificationPriority.high => AutonomousActionPriority.high,
      NotificationPriority.normal => AutonomousActionPriority.normal,
      NotificationPriority.low => AutonomousActionPriority.low,
    };
    return switch (notification.category) {
      NotificationCategory.campus => create(
          type: AutonomousActionTypes.talkToTutor,
          title: notification.title,
          reason: notification.message,
          actionLabel: 'Hablar con Tutor IA',
          priority: priority,
          metadata: {'notification_id': notification.id},
        ),
      NotificationCategory.planner => create(
          type: AutonomousActionTypes.followSmartPlan,
          title: notification.title,
          reason: notification.message,
          actionLabel: 'Ver plan',
          priority: priority,
          metadata: {'notification_id': notification.id},
        ),
      NotificationCategory.achievement ||
      NotificationCategory.gamification =>
        create(
          type: AutonomousActionTypes.maintainStreak,
          title: notification.title,
          reason: notification.message,
          actionLabel: 'Estudiar ahora',
          priority: priority,
          metadata: {'notification_id': notification.id},
        ),
      NotificationCategory.marketplace => create(
          type: AutonomousActionTypes.exploreMarketplaceResource,
          title: notification.title,
          reason: notification.message,
          actionLabel: 'Ver recurso',
          targetId: notification.id,
          priority: priority,
          metadata: {'notification_id': notification.id},
        ),
      NotificationCategory.institution => create(
          type: AutonomousActionTypes.institutionAlert,
          title: notification.title,
          reason: notification.message,
          actionLabel: 'Revisar',
          priority: priority,
          metadata: {'notification_id': notification.id},
        ),
      NotificationCategory.voice => create(
          type: AutonomousActionTypes.talkToTutor,
          title: notification.title,
          reason: notification.message,
          actionLabel: 'Abrir Tutor IA',
          priority: priority,
          metadata: {'notification_id': notification.id},
        ),
    };
  }

  AutonomousAction create({
    required String type,
    required String title,
    required String reason,
    required String actionLabel,
    String targetId = '',
    AutonomousActionPriority priority = AutonomousActionPriority.normal,
    Map<String, dynamic> metadata = const {},
  }) {
    final now = DateTime.now();
    return AutonomousAction(
      id: actionId(type, targetId, now),
      type: type,
      title: title,
      reason: reason,
      actionLabel: actionLabel,
      targetId: targetId,
      priority: priority,
      metadata: metadata,
      createdAt: now,
      updatedAt: now,
    );
  }

  String actionId(String type, String targetId, DateTime date) {
    final day = '${date.year}${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
    final target = targetId
        .trim()
        .toLowerCase()
        .replaceAll(RegExp('[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return target.isEmpty ? '${type}_$day' : '${type}_${target}_$day';
  }
}
