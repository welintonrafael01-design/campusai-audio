import 'learning_analytics_service.dart';
import 'learning_models.dart';
import 'learning_progress_service.dart';

/// Rule-based recommendation engine for Student Studio.
class RecommendationEngine {
  final LearningAnalyticsService analyticsService;
  final LearningProgressService progressService;

  const RecommendationEngine({
    this.analyticsService = const LearningAnalyticsService(),
    this.progressService = const LearningProgressService(),
  });

  Future<List<LearningRecommendation>> generateRecommendations() async {
    try {
      final analytics = await analyticsService.buildAnalytics();
      final progressItems = await progressService.getAllProgress();
      return generateFromData(
        analytics: analytics,
        progressItems: progressItems,
      );
    } catch (_) {
      return const [];
    }
  }

  List<LearningRecommendation> generateFromData({
    required LearningAnalytics analytics,
    List<Map<String, dynamic>> progressItems = const [],
  }) {
    final recommendations = <LearningRecommendation>[];

    if (analytics.sessions == 0) {
      recommendations.add(
        const LearningRecommendation(
          id: 'start_first_session',
          title: 'Empieza tu primera sesión',
          description:
              'Escucha un capítulo y completa sus actividades iniciales.',
          type: 'start',
          priority: 1,
        ),
      );
      return recommendations;
    }

    if (analytics.averageQuizScore > 0 && analytics.averageQuizScore < 70) {
      recommendations.add(
        const LearningRecommendation(
          id: 'practice_flashcards',
          title: 'Practica las Flashcards',
          description: 'Refuerza los conceptos antes de repetir el mini quiz.',
          type: 'practice',
          priority: 1,
        ),
      );
    }

    if (analytics.audioMinutesListened < analytics.studyMinutes ~/ 3) {
      recommendations.add(
        const LearningRecommendation(
          id: 'listen_again',
          title: 'Escucha nuevamente un capítulo',
          description: 'Repetir el audio ayuda a consolidar la comprensión.',
          type: 'audio',
          priority: 2,
        ),
      );
    }

    final weakChapterId = _firstWeakChapter(progressItems);
    if (weakChapterId.isNotEmpty) {
      recommendations.add(
        LearningRecommendation(
          id: 'repeat_$weakChapterId',
          title: 'Repite el capítulo',
          description:
              'Ese capítulo tiene un resultado de quiz por debajo de 70%.',
          type: 'chapter',
          priority: 1,
          sourceId: weakChapterId,
        ),
      );
    }

    final competency = _firstCompetency(progressItems);
    if (competency.isNotEmpty && analytics.masteryPercentage < 80) {
      recommendations.add(
        LearningRecommendation(
          id: 'reinforce_$competency',
          title: 'Refuerza la competencia $competency',
          description: 'Dedica una sesión corta a practicar esta competencia.',
          type: 'competency',
          priority: 2,
          sourceId: competency,
        ),
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        const LearningRecommendation(
          id: 'continue_next_chapter',
          title: 'Continúa con el siguiente capítulo',
          description: 'Tu avance está estable. Mantén el ritmo de estudio.',
          type: 'continue',
          priority: 3,
        ),
      );
    }

    recommendations.sort((a, b) => a.priority.compareTo(b.priority));
    return recommendations.take(6).toList();
  }

  String _firstWeakChapter(List<Map<String, dynamic>> progressItems) {
    for (final progress in progressItems) {
      final quizResults = _mapList(progress['quiz_results']);
      for (final quiz in quizResults) {
        final percentage = _intFrom(quiz['percentage']);
        final chapterId = quiz['chapter_id']?.toString().trim() ?? '';
        if (chapterId.isNotEmpty && percentage > 0 && percentage < 70) {
          return chapterId;
        }
      }
    }
    return '';
  }

  String _firstCompetency(List<Map<String, dynamic>> progressItems) {
    for (final progress in progressItems) {
      final competencies = _stringList(progress['competencies']);
      if (competencies.isNotEmpty) return competencies.first;
    }
    return '';
  }

  int _intFrom(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<String> _stringList(dynamic raw) {
    if (raw is List) {
      return raw
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    final text = raw?.toString().trim() ?? '';
    return text.isEmpty ? <String>[] : <String>[text];
  }

  List<Map<String, dynamic>> _mapList(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
