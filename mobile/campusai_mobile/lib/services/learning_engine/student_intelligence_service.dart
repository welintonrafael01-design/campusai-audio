import 'learning_analytics_service.dart';
import 'learning_models.dart';
import 'learning_progress_service.dart';
import 'recommendation_engine.dart';

/// Rule-based student intelligence layer for dashboards and coaching.
class StudentIntelligenceService {
  final LearningAnalyticsService analyticsService;
  final LearningProgressService progressService;
  final RecommendationEngine recommendationEngine;

  const StudentIntelligenceService({
    this.analyticsService = const LearningAnalyticsService(),
    this.progressService = const LearningProgressService(),
    this.recommendationEngine = const RecommendationEngine(),
  });

  Future<StudentIntelligence> analyzeStudent() async {
    try {
      final analytics = await analyticsService.buildAnalytics();
      final progressItems = await progressService.getAllProgress();
      final recommendations =
          await recommendationEngine.generateRecommendations();
      final competencies = _competencyCounts(progressItems);

      return StudentIntelligence(
        strengths: _strengths(analytics),
        weaknesses: _weaknesses(analytics),
        strongCompetencies: _topCompetencies(competencies),
        weakCompetencies: _weakCompetencies(analytics, competencies),
        risk: _risk(analytics),
        level: _level(analytics),
        masteryPercentage: analytics.masteryPercentage,
        recommendations: recommendations,
      );
    } catch (_) {
      return StudentIntelligence.empty;
    }
  }

  List<String> _strengths(LearningAnalytics analytics) {
    final strengths = <String>[];
    if (analytics.averageQuizScore >= 80) {
      strengths.add('Buen desempeño en quiz');
    }
    if (analytics.masteryPercentage >= 80) {
      strengths.add('Dominio sólido');
    }
    if (analytics.studyMinutes >= 100) {
      strengths.add('Constancia de estudio');
    }
    if (analytics.flashcardsStudied >= 50) {
      strengths.add('Uso activo de flashcards');
    }
    if (analytics.audioMinutesListened >= 60) {
      strengths.add('Escucha activa');
    }
    return strengths.isEmpty ? ['Inicio de ruta de aprendizaje'] : strengths;
  }

  List<String> _weaknesses(LearningAnalytics analytics) {
    final weaknesses = <String>[];
    if (analytics.sessions == 0) weaknesses.add('Sin sesiones registradas');
    if (analytics.averageQuizScore > 0 && analytics.averageQuizScore < 70) {
      weaknesses.add('Quiz por debajo del umbral recomendado');
    }
    if (analytics.masteryPercentage < 50) {
      weaknesses.add('Dominio en desarrollo');
    }
    if (analytics.flashcardsStudied < 10) {
      weaknesses.add('Poca práctica con flashcards');
    }
    return weaknesses;
  }

  String _risk(LearningAnalytics analytics) {
    if (analytics.sessions == 0) return 'Sin datos';
    if (analytics.averageQuizScore > 0 && analytics.averageQuizScore < 60) {
      return 'Alto';
    }
    if (analytics.masteryPercentage < 50 || analytics.studyMinutes < 30) {
      return 'Medio';
    }
    return 'Bajo';
  }

  String _level(LearningAnalytics analytics) {
    if (analytics.masteryPercentage >= 85) return 'Avanzado';
    if (analytics.masteryPercentage >= 60) return 'Intermedio';
    if (analytics.sessions > 0) return 'Inicial';
    return 'Sin iniciar';
  }

  Map<String, int> _competencyCounts(List<Map<String, dynamic>> progressItems) {
    final counts = <String, int>{};
    for (final progress in progressItems) {
      for (final competency in _stringList(progress['competencies'])) {
        counts[competency] = (counts[competency] ?? 0) + 1;
      }
    }
    return counts;
  }

  List<String> _topCompetencies(Map<String, int> counts) {
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(3).map((entry) => entry.key).toList();
  }

  List<String> _weakCompetencies(
    LearningAnalytics analytics,
    Map<String, int> counts,
  ) {
    if (analytics.averageQuizScore >= 70 && analytics.masteryPercentage >= 60) {
      return const [];
    }
    if (counts.isEmpty) return ['Comprensión conceptual'];
    final entries = counts.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return entries.take(2).map((entry) => entry.key).toList();
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
}
