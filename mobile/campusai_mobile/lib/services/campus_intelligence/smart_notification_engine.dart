import '../learning_engine/learning_models.dart';
import 'campus_intelligence_models.dart';

class SmartNotificationEngine {
  const SmartNotificationEngine();

  List<SmartNotification> buildNotifications({
    required LearningAnalytics analytics,
    required LearningStreak streak,
    required List<CampusPrediction> predictions,
    required List<AdaptiveLearningAction> adaptivePlan,
  }) {
    final now = DateTime.now();
    final notifications = <SmartNotification>[];

    if (streak.currentStreakDays == 0 && analytics.sessions > 0) {
      notifications.add(
        SmartNotification(
          notificationId: 'streak_${now.millisecondsSinceEpoch}',
          title: 'Hace varios días que no estudias',
          message: 'Retoma con una sesión corta para recuperar consistencia.',
          priority: 1,
          category: 'consistency',
          createdAt: now,
        ),
      );
    }

    if (analytics.masteryPercentage < 60 && analytics.sessions > 0) {
      notifications.add(
        SmartNotification(
          notificationId: 'mastery_${now.millisecondsSinceEpoch}',
          title: 'Refuerza esta competencia',
          message: 'Tu dominio puede mejorar con repaso y mini quiz.',
          priority: 1,
          category: 'mastery',
          createdAt: now,
        ),
      );
    }

    if (predictions.any((item) => item.key == 'high_progress_probability')) {
      notifications.add(
        SmartNotification(
          notificationId: 'progress_${now.millisecondsSinceEpoch}',
          title: 'Tienes progreso alto, sigue así',
          message: 'Continúa con el siguiente capítulo para mantener ritmo.',
          priority: 3,
          category: 'positive',
          createdAt: now,
        ),
      );
    }

    if (adaptivePlan.any((item) => item.type == 'ai_tutor')) {
      notifications.add(
        SmartNotification(
          notificationId: 'tutor_${now.millisecondsSinceEpoch}',
          title: 'Practica con el Tutor IA',
          message: 'Haz una pregunta por voz para aclarar dudas.',
          priority: 2,
          category: 'voice_tutor',
          createdAt: now,
        ),
      );
    }

    if (notifications.isEmpty) {
      notifications.add(
        SmartNotification(
          notificationId: 'next_${now.millisecondsSinceEpoch}',
          title: 'Continúa con el siguiente capítulo',
          message: 'Una sesión breve es suficiente para sostener el avance.',
          priority: 3,
          category: 'learning',
          createdAt: now,
        ),
      );
    }

    notifications.sort((a, b) => a.priority.compareTo(b.priority));
    return notifications.take(5).toList();
  }
}
