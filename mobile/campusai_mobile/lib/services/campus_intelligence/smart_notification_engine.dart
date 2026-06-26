import '../learning_engine/learning_models.dart';
import 'campus_intelligence_models.dart';

class SmartNotificationEngine {
  const SmartNotificationEngine();

  List<SmartNotification> buildNotifications({
    required LearningAnalytics analytics,
    required LearningStreak streak,
    required List<CampusPrediction> predictions,
    required List<AdaptiveLearningAction> adaptivePlan,
    List<CampusTrend> trends = const [],
    List<StudentTimelineItem> timeline = const [],
    List<Achievement> achievements = const [],
  }) {
    final now = DateTime.now();
    final notifications = <SmartNotification>[];
    final masteryTrend = _trendByMetric(trends, 'Dominio');
    final consistencyTrend = _trendByMetric(trends, 'Consistencia');
    final recentQuiz = timeline.any((item) =>
        item.category == 'learning_session' &&
        item.metadata['quiz_score'] != null);
    final recentTutor =
        timeline.any((item) => item.category == 'voice_session');

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

    if (analytics.sessions == 0) {
      notifications.add(
        SmartNotification(
          notificationId: 'start_${now.millisecondsSinceEpoch}',
          title: 'Empieza con una sesión corta',
          message: 'Un bloque de 10 minutos es suficiente para abrir progreso.',
          priority: 2,
          category: 'inactivity',
          createdAt: now,
        ),
      );
    }

    if ((masteryTrend?.delta ?? 0) < 0) {
      notifications.add(
        SmartNotification(
          notificationId: 'mastery_drop_${now.millisecondsSinceEpoch}',
          title: 'Tu dominio bajó esta semana',
          message: 'Haz repaso y mini quiz antes de avanzar contenido.',
          priority: 1,
          category: 'mastery_drop',
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

    if ((consistencyTrend?.delta ?? 0) < 0 || streak.currentStreakDays <= 1) {
      notifications.add(
        SmartNotification(
          notificationId: 'consistency_${now.millisecondsSinceEpoch}',
          title: 'Baja consistencia detectada',
          message: 'Agenda una sesión breve para sostener el hábito.',
          priority: 2,
          category: 'consistency',
          createdAt: now,
        ),
      );
    }

    if (!recentQuiz && analytics.sessions > 0) {
      notifications.add(
        SmartNotification(
          notificationId: 'quiz_${now.millisecondsSinceEpoch}',
          title: 'Quiz pendiente',
          message: 'Valida comprensión con preguntas cortas.',
          priority: 2,
          category: 'quiz',
          createdAt: now,
        ),
      );
    }

    if (analytics.flashcardsStudied < 20) {
      notifications.add(
        SmartNotification(
          notificationId: 'flashcards_${now.millisecondsSinceEpoch}',
          title: 'Practica flashcards',
          message: 'Refuerza memoria activa con una ronda rápida.',
          priority: 3,
          category: 'flashcards',
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

    if (adaptivePlan.any((item) => item.type == 'ai_tutor') || !recentTutor) {
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

    if (predictions.any((item) => item.severity == 'high')) {
      notifications.add(
        SmartNotification(
          notificationId: 'risk_${now.millisecondsSinceEpoch}',
          title: 'Riesgo alto detectado',
          message: 'Prioriza repaso guiado y Tutor IA antes de avanzar.',
          priority: 1,
          category: 'risk',
          createdAt: now,
        ),
      );
    }

    final closeAchievement = achievements.firstWhere(
      (achievement) =>
          !achievement.unlocked && achievement.completionRatio >= 0.75,
      orElse: () => const Achievement(
        id: '',
        title: '',
        description: '',
      ),
    );
    if (closeAchievement.id.isNotEmpty) {
      notifications.add(
        SmartNotification(
          notificationId: 'achievement_${now.millisecondsSinceEpoch}',
          title: 'Logro cercano',
          message: 'Estás cerca de completar ${closeAchievement.title}.',
          priority: 3,
          category: 'achievement',
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
    return _deduplicate(notifications).take(8).toList();
  }

  CampusTrend? _trendByMetric(List<CampusTrend> trends, String metric) {
    final cleanMetric = metric.trim().toLowerCase();
    for (final trend in trends) {
      if (trend.metric.trim().toLowerCase() == cleanMetric) return trend;
    }
    return null;
  }

  List<SmartNotification> _deduplicate(List<SmartNotification> notifications) {
    final seen = <String>{};
    final unique = <SmartNotification>[];
    for (final notification in notifications) {
      final key = '${notification.category}_${notification.title}';
      if (seen.add(key)) unique.add(notification);
    }
    return unique;
  }
}
