import '../learning_engine/learning_models.dart' as learning;
import 'gamification_models.dart';

class ExperienceEngine {
  const ExperienceEngine();
  XP calculate(learning.LearningAnalytics analytics,
          learning.LearningStreak streak) =>
      XP(
          total: analytics.studyMinutes * 2 +
              analytics.completedChapters * 40 +
              analytics.quizCompleted * 25 +
              streak.bestStreakDays * 15,
          earnedToday: analytics.sessions == 0
              ? 0
              : analytics.averageMinutesPerSession.round() +
                  streak.currentStreakDays * 5);
}

class LevelEngine {
  const LevelEngine();
  Level calculate(XP xp) {
    final number = (xp.total / 250).floor() + 1;
    final start = (number - 1) * 250;
    return Level(
        number: number,
        title: number >= 10
            ? 'Maestro'
            : number >= 5
                ? 'Especialista'
                : number >= 2
                    ? 'Aprendiz'
                    : 'Explorador',
        currentXp: xp.total - start,
        nextLevelXp: 250);
  }
}

class AchievementEngine {
  const AchievementEngine();
  List<Achievement> calculate(
          learning.LearningAnalytics a, learning.LearningStreak s) =>
      [
        Achievement(
            id: 'first_session',
            title: 'Primer paso',
            description: 'Completa tu primera sesión.',
            progress: a.sessions,
            target: 1,
            unlocked: a.sessions >= 1,
            unlockedAt: a.sessions >= 1 ? DateTime.now() : null),
        Achievement(
            id: 'chapter_10',
            title: 'Lector constante',
            description: 'Completa 10 capítulos.',
            progress: a.completedChapters,
            target: 10,
            unlocked: a.completedChapters >= 10,
            unlockedAt: a.completedChapters >= 10 ? DateTime.now() : null),
        Achievement(
            id: 'streak_7',
            title: 'Racha semanal',
            description: 'Estudia 7 días seguidos.',
            progress: s.currentStreakDays,
            target: 7,
            unlocked: s.currentStreakDays >= 7,
            unlockedAt: s.currentStreakDays >= 7 ? DateTime.now() : null)
      ];
}

class ProgressBadgeEngine {
  const ProgressBadgeEngine();
  List<Badge> calculate(List<Achievement> achievements) => achievements
      .map((item) => Badge(
          id: 'badge_${item.id}',
          title: item.title,
          category: 'progress',
          unlocked: item.unlocked))
      .toList();
}

class MissionEngine {
  const MissionEngine();
  List<Mission> calculate(
          learning.LearningAnalytics a, learning.LearningStreak s) =>
      [
        DailyMission(
            id: 'daily_session',
            title: 'Completa una sesión hoy',
            progress: a.sessions > 0 ? 1 : 0,
            target: 1,
            xpReward: 25,
            coinReward: 5,
            completed: a.sessions > 0),
        WeeklyMission(
            id: 'weekly_streak',
            title: 'Estudia 5 días esta semana',
            progress: s.currentStreakDays,
            target: 5,
            xpReward: 100,
            coinReward: 20,
            completed: s.currentStreakDays >= 5),
        MonthlyMission(
            id: 'monthly_chapters',
            title: 'Completa 12 capítulos',
            progress: a.completedChapters,
            target: 12,
            xpReward: 250,
            coinReward: 50,
            completed: a.completedChapters >= 12)
      ];
}

class RewardEngine {
  const RewardEngine();
  List<Reward> calculate(List<Mission> missions) => missions
      .where((item) => item.completed)
      .map((item) => Reward(
          id: 'reward_${item.id}',
          title: 'Recompensa: ${item.title}',
          type: 'coins',
          value: item.coinReward,
          unlocked: true))
      .toList();
}

class CoinEngine {
  const CoinEngine();
  CoinWallet calculate(List<Mission> missions, List<Achievement> achievements) {
    final missionCoins = missions
        .where((item) => item.completed)
        .fold<int>(0, (sum, item) => sum + item.coinReward);
    final achievementCoins =
        achievements.where((item) => item.unlocked).length * 10;
    return CoinWallet(
        balance: missionCoins + achievementCoins,
        earnedToday: missionCoins,
        spent: 0);
  }
}

class LeaderboardEngine {
  const LeaderboardEngine();
  Leaderboard build(XP xp, Level level) =>
      Leaderboard(scope: 'personal', rank: 1, score: xp.total, entries: [
        LeaderboardEntry(
            id: 'current_student', label: 'Tú', score: xp.total, rank: 1),
        LeaderboardEntry(
            id: 'level',
            label: 'Nivel ${level.number}',
            score: level.currentXp,
            rank: 2)
      ]);
}

class SkillTreeEngine {
  const SkillTreeEngine();
  SkillTree build(learning.LearningAnalytics a) => SkillTree(nodes: [
        SkillNode(
            id: 'study_habit',
            title: 'Hábito de estudio',
            progress: (a.sessions * 10).clamp(0, 100),
            unlocked: a.sessions > 0),
        SkillNode(
            id: 'content_mastery',
            title: 'Dominio de contenido',
            progress: a.masteryPercentage,
            unlocked: a.masteryPercentage >= 20,
            dependencies: const ['study_habit']),
        SkillNode(
            id: 'assessment',
            title: 'Evaluación activa',
            progress: a.averageQuizScore,
            unlocked: a.quizCompleted > 0,
            dependencies: const ['content_mastery'])
      ]);
}

class StreakRewardEngine {
  const StreakRewardEngine();
  Reward? rewardFor(learning.LearningStreak streak) =>
      streak.currentStreakDays > 0 && streak.currentStreakDays % 7 == 0
          ? Reward(
              id: 'streak_${streak.currentStreakDays}',
              title: 'Bono por racha',
              type: 'xp',
              value: streak.currentStreakDays * 10,
              unlocked: true)
          : null;
}
