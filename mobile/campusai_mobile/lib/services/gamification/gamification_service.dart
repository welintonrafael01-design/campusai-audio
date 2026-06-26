import '../campus_intelligence/enterprise_result_repository.dart';
import '../learning_engine/learning_analytics_service.dart';
import '../learning_engine/streak_service.dart';
import 'gamification_engines.dart';
import 'gamification_models.dart';

class GamificationService {
  static const String profileType = 'gamification_profile';
  static const String xpHistoryType = 'xp_history';
  static const String achievementHistoryType = 'achievement_history';
  static const String leaderboardType = 'leaderboard_snapshot';
  static const String walletType = 'coin_wallet';
  static const String missionsType = 'missions';
  static const String latestDocumentId = 'gamification_profile_latest';
  final LearningAnalyticsService analyticsService;
  final StreakService streakService;
  final EnterpriseResultRepository repository;
  final ExperienceEngine experienceEngine;
  final LevelEngine levelEngine;
  final AchievementEngine achievementEngine;
  final MissionEngine missionEngine;
  final RewardEngine rewardEngine;
  final CoinEngine coinEngine;
  final LeaderboardEngine leaderboardEngine;
  final SkillTreeEngine skillTreeEngine;
  final ProgressBadgeEngine badgeEngine;
  final StreakRewardEngine streakRewardEngine;
  const GamificationService(
      {this.analyticsService = const LearningAnalyticsService(),
      this.streakService = const StreakService(),
      this.repository = const EnterpriseResultRepository(),
      this.experienceEngine = const ExperienceEngine(),
      this.levelEngine = const LevelEngine(),
      this.achievementEngine = const AchievementEngine(),
      this.missionEngine = const MissionEngine(),
      this.rewardEngine = const RewardEngine(),
      this.coinEngine = const CoinEngine(),
      this.leaderboardEngine = const LeaderboardEngine(),
      this.skillTreeEngine = const SkillTreeEngine(),
      this.badgeEngine = const ProgressBadgeEngine(),
      this.streakRewardEngine = const StreakRewardEngine()});
  Future<GamificationProfile> buildProfile() async {
    try {
      final analytics = await analyticsService.buildAnalytics();
      final streak = await streakService.calculateStreak();
      final xp = experienceEngine.calculate(analytics, streak);
      final level = levelEngine.calculate(xp);
      final achievements = achievementEngine.calculate(analytics, streak);
      final missions = missionEngine.calculate(analytics, streak);
      final rewards = [
        ...rewardEngine.calculate(missions),
        if (streakRewardEngine.rewardFor(streak) case final reward?) reward
      ];
      final profile = GamificationProfile(
          updatedAt: DateTime.now(),
          xp: xp,
          level: level,
          wallet: coinEngine.calculate(missions, achievements),
          achievements: achievements,
          badges: badgeEngine.calculate(achievements),
          missions: missions,
          rewards: rewards,
          leaderboard: leaderboardEngine.build(xp, level),
          skillTree: skillTreeEngine.build(analytics));
      await _persist(profile);
      return profile;
    } catch (_) {
      return GamificationProfile.empty();
    }
  }

  Future<GamificationProfile?> getLatestProfile() async {
    final raw =
        await repository.load(documentId: latestDocumentId, type: profileType);
    return raw == null ? null : GamificationProfile.fromJson(raw);
  }

  Future<void> _persist(GamificationProfile profile) async {
    await repository.save(
        documentId: latestDocumentId,
        type: profileType,
        payload: profile.toJson(),
        createdAt: profile.updatedAt);
    await repository.save(
        documentId: 'xp_history_latest',
        type: xpHistoryType,
        payload: profile.xp.toJson());
    await repository.save(
        documentId: 'achievement_history_latest',
        type: achievementHistoryType,
        payload: {
          'achievements':
              profile.achievements.map((item) => item.toJson()).toList()
        });
    await repository.save(
        documentId: 'leaderboard_snapshot_latest',
        type: leaderboardType,
        payload: profile.leaderboard.toJson());
    await repository.save(
        documentId: 'coin_wallet_latest',
        type: walletType,
        payload: profile.wallet.toJson());
    await repository.save(
        documentId: 'missions_latest',
        type: missionsType,
        payload: {
          'missions': profile.missions.map((item) => item.toJson()).toList()
        });
  }
}
