import '../learning_engine/learning_models.dart';
import 'campus_intelligence_models.dart';

class CampusPredictionEngine {
  const CampusPredictionEngine();

  List<CampusPrediction> generatePredictions({
    required LearningAnalytics analytics,
    required LearningStreak streak,
    required StudentIntelligence intelligence,
    required List<Map<String, dynamic>> progressItems,
    required List<Map<String, dynamic>> sessions,
    required int voiceSessionCount,
  }) {
    final predictions = <CampusPrediction>[];

    if (analytics.sessions == 0) {
      predictions.add(
        const CampusPrediction(
          key: 'no_activity',
          title: 'Sin actividad reciente',
          description: 'Todavía no hay sesiones suficientes para medir avance.',
          probability: 0.80,
          severity: 'medium',
          recommendation: 'Inicia una sesión corta de estudio o audio libro.',
        ),
      );
    }

    if (analytics.masteryPercentage > 0 && analytics.masteryPercentage < 55) {
      predictions.add(
        const CampusPrediction(
          key: 'low_mastery',
          title: 'Bajo dominio académico',
          description: 'El dominio promedio está por debajo del umbral.',
          probability: 0.72,
          severity: 'high',
          recommendation: 'Repite capítulos débiles y completa mini quizzes.',
        ),
      );
    }

    if (streak.currentStreakDays == 0 && analytics.sessions > 0) {
      predictions.add(
        const CampusPrediction(
          key: 'low_consistency',
          title: 'Baja consistencia',
          description: 'La racha actual está interrumpida.',
          probability: 0.64,
          severity: 'medium',
          recommendation: 'Agenda una sesión breve hoy para retomar ritmo.',
        ),
      );
    }

    if (analytics.completedChapters > analytics.masteredChapters) {
      predictions.add(
        const CampusPrediction(
          key: 'review_needed',
          title: 'Necesidad de repaso',
          description: 'Hay capítulos completados que aún no están dominados.',
          probability: 0.68,
          severity: 'medium',
          recommendation: 'Repasa conceptos clave y practica flashcards.',
        ),
      );
    }

    if (analytics.sessions >= 3 &&
        analytics.masteryPercentage >= 70 &&
        streak.currentStreakDays >= 2) {
      predictions.add(
        const CampusPrediction(
          key: 'high_progress_probability',
          title: 'Alta probabilidad de progreso',
          description: 'El patrón actual muestra buen ritmo de aprendizaje.',
          probability: 0.82,
          severity: 'positive',
          recommendation: 'Continúa con el siguiente capítulo.',
        ),
      );
    }

    if (progressItems.isNotEmpty &&
        analytics.completedChapters < progressItems.length &&
        analytics.sessions < 2) {
      predictions.add(
        const CampusPrediction(
          key: 'completion_risk',
          title: 'Riesgo de no completar contenido',
          description: 'Hay progreso registrado, pero pocas sesiones activas.',
          probability: 0.58,
          severity: 'medium',
          recommendation: 'Retoma el audio libro y completa una actividad.',
        ),
      );
    }

    if (voiceSessionCount == 0 && analytics.sessions > 0) {
      predictions.add(
        const CampusPrediction(
          key: 'coach_opportunity',
          title: 'Oportunidad de Tutor IA',
          description: 'El estudiante estudia, pero aún no usa el tutor.',
          probability: 0.62,
          severity: 'info',
          recommendation: 'Conversa con el Tutor IA para resolver dudas.',
        ),
      );
    }

    return predictions;
  }
}
