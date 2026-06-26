import '../learning_engine/learning_models.dart';
import 'campus_intelligence_models.dart';

class AdaptiveLearningService {
  const AdaptiveLearningService();

  List<AdaptiveLearningAction> buildAdaptivePlan({
    required LearningAnalytics analytics,
    required StudentIntelligence intelligence,
    required List<LearningGraphNode> graph,
    required List<CampusPrediction> predictions,
    required List<LearningRecommendation> recommendations,
  }) {
    final actions = <AdaptiveLearningAction>[];

    final weakChapter = graph.firstWhere(
      (node) => node.type == 'chapter' && node.mastery < 60,
      orElse: () => const LearningGraphNode(),
    );
    if (weakChapter.id.isNotEmpty) {
      actions.add(
        AdaptiveLearningAction(
          actionId: 'repeat_${weakChapter.id}',
          title: 'Repetir capítulo débil',
          description: 'Escucha nuevamente ${weakChapter.title}.',
          type: 'repeat_chapter',
          priority: 1,
          targetId: weakChapter.id,
          estimatedMinutes: 12,
          reason: 'Dominio por debajo del umbral recomendado.',
        ),
      );
    }

    final pendingQuiz = graph.firstWhere(
      (node) => node.type == 'quiz' && node.status == 'pending',
      orElse: () => const LearningGraphNode(),
    );
    if (pendingQuiz.id.isNotEmpty) {
      actions.add(
        AdaptiveLearningAction(
          actionId: 'quiz_${pendingQuiz.id}',
          title: 'Hacer mini quiz',
          description: 'Practica con el mini quiz disponible.',
          type: 'mini_quiz',
          priority: 2,
          targetId: pendingQuiz.id,
          estimatedMinutes: 8,
          reason: 'Los quizzes consolidan dominio y detectan brechas.',
        ),
      );
    }

    if (analytics.flashcardsStudied < 10) {
      actions.add(
        const AdaptiveLearningAction(
          actionId: 'study_flashcards',
          title: 'Estudiar flashcards',
          description: 'Revisa flashcards para reforzar conceptos clave.',
          type: 'flashcards',
          priority: 2,
          estimatedMinutes: 10,
          reason: 'Hay poca práctica registrada con flashcards.',
        ),
      );
    }

    if (intelligence.weakCompetencies.isNotEmpty) {
      final competency = intelligence.weakCompetencies.first;
      actions.add(
        AdaptiveLearningAction(
          actionId: 'competency_${_slug(competency)}',
          title: 'Repasar competencia débil',
          description: 'Refuerza la competencia: $competency.',
          type: 'competency_review',
          priority: 1,
          targetId: competency,
          estimatedMinutes: 15,
          reason: 'Student Intelligence la marcó como área débil.',
        ),
      );
    }

    if (predictions.any((item) => item.key == 'coach_opportunity')) {
      actions.add(
        const AdaptiveLearningAction(
          actionId: 'talk_to_ai_tutor',
          title: 'Conversar con Tutor IA',
          description: 'Haz una pregunta por voz o texto sobre tu capítulo.',
          type: 'ai_tutor',
          priority: 2,
          estimatedMinutes: 6,
          reason: 'El Tutor IA puede aclarar dudas de forma contextual.',
        ),
      );
    }

    if (actions.isEmpty && recommendations.isNotEmpty) {
      final recommendation = recommendations.first;
      actions.add(
        AdaptiveLearningAction(
          actionId: 'recommendation_${recommendation.id}',
          title: recommendation.title,
          description: recommendation.description,
          type: recommendation.type,
          priority: recommendation.priority,
          targetId: recommendation.sourceId,
          estimatedMinutes: 10,
          reason: 'Recomendación actual del Learning Engine.',
        ),
      );
    }

    if (actions.isEmpty) {
      actions.add(
        const AdaptiveLearningAction(
          actionId: 'continue_next_chapter',
          title: 'Continúa con el siguiente capítulo',
          description: 'Sigue avanzando con una sesión breve.',
          type: 'next_chapter',
          priority: 3,
          estimatedMinutes: 12,
          reason: 'No hay alertas críticas pendientes.',
        ),
      );
    }

    actions.sort((a, b) => a.priority.compareTo(b.priority));
    return actions.take(6).toList();
  }

  String _slug(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9áéíóúñ]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }
}
