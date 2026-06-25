import 'learning_analytics_service.dart';
import 'learning_models.dart';
import 'streak_service.dart';

/// Builds lightweight achievements from analytics and streak data.
class AchievementService {
  final LearningAnalyticsService analyticsService;
  final StreakService streakService;

  const AchievementService({
    this.analyticsService = const LearningAnalyticsService(),
    this.streakService = const StreakService(),
  });

  Future<List<Achievement>> getAchievements() async {
    try {
      final analytics = await analyticsService.buildAnalytics();
      final streak = await streakService.calculateStreak();

      return [
        _achievement(
          id: 'first_audiobook',
          title: 'Primer AudioBook',
          description: 'Inicia tu primer audio libro educativo.',
          progress: analytics.audiobooksStarted,
          target: 1,
        ),
        _achievement(
          id: 'first_quiz',
          title: 'Primer Quiz',
          description: 'Completa tu primer mini quiz.',
          progress: analytics.quizCompleted,
          target: 1,
        ),
        _achievement(
          id: 'ten_chapters',
          title: '10 capítulos',
          description: 'Completa 10 capítulos de aprendizaje.',
          progress: analytics.completedChapters,
          target: 10,
        ),
        _achievement(
          id: 'hundred_minutes',
          title: '100 minutos',
          description: 'Acumula 100 minutos de estudio.',
          progress: analytics.studyMinutes,
          target: 100,
        ),
        _achievement(
          id: 'seven_day_streak',
          title: '7 días',
          description: 'Estudia durante 7 días consecutivos.',
          progress: streak.currentStreakDays,
          target: 7,
        ),
        _achievement(
          id: 'fifty_flashcards',
          title: '50 Flashcards',
          description: 'Estudia 50 flashcards.',
          progress: analytics.flashcardsStudied,
          target: 50,
        ),
        _achievement(
          id: 'twenty_quiz',
          title: '20 Quiz',
          description: 'Completa 20 sesiones con quiz.',
          progress: analytics.quizCompleted,
          target: 20,
        ),
      ];
    } catch (_) {
      return const [];
    }
  }

  Achievement _achievement({
    required String id,
    required String title,
    required String description,
    required int progress,
    required int target,
  }) {
    final unlocked = progress >= target;
    return Achievement(
      id: id,
      title: title,
      description: description,
      unlocked: unlocked,
      unlockedAt: unlocked ? DateTime.now() : null,
      progress: progress.clamp(0, target),
      target: target,
    );
  }
}
