/// Typed models for the local-first Enterprise gamification domain.
library;

class XP {
  final int total;
  final int earnedToday;
  const XP({this.total = 0, this.earnedToday = 0});
  factory XP.fromJson(Map<String, dynamic> json) =>
      XP(total: _int(json['total']), earnedToday: _int(json['earned_today']));
  Map<String, dynamic> toJson() =>
      {'total': total, 'earned_today': earnedToday};
}

class Level {
  final int number;
  final String title;
  final int currentXp;
  final int nextLevelXp;
  const Level(
      {this.number = 1,
      this.title = 'Explorador',
      this.currentXp = 0,
      this.nextLevelXp = 100});
  factory Level.fromJson(Map<String, dynamic> json) => Level(
      number: _int(json['number'], 1),
      title: _text(json['title'], 'Explorador'),
      currentXp: _int(json['current_xp']),
      nextLevelXp: _int(json['next_level_xp'], 100));
  Map<String, dynamic> toJson() => {
        'number': number,
        'title': title,
        'current_xp': currentXp,
        'next_level_xp': nextLevelXp
      };
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final bool unlocked;
  final int progress;
  final int target;
  final DateTime? unlockedAt;
  const Achievement(
      {this.id = '',
      this.title = '',
      this.description = '',
      this.unlocked = false,
      this.progress = 0,
      this.target = 1,
      this.unlockedAt});
  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
      id: _text(json['id']),
      title: _text(json['title']),
      description: _text(json['description']),
      unlocked: json['unlocked'] == true,
      progress: _int(json['progress']),
      target: _int(json['target'], 1),
      unlockedAt: DateTime.tryParse(_text(json['unlocked_at'])));
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'unlocked': unlocked,
        'progress': progress,
        'target': target,
        'unlocked_at': unlockedAt?.toIso8601String() ?? ''
      };
}

class Badge {
  final String id;
  final String title;
  final String category;
  final bool unlocked;
  const Badge(
      {this.id = '',
      this.title = '',
      this.category = 'learning',
      this.unlocked = false});
  factory Badge.fromJson(Map<String, dynamic> json) => Badge(
      id: _text(json['id']),
      title: _text(json['title']),
      category: _text(json['category'], 'learning'),
      unlocked: json['unlocked'] == true);
  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'category': category, 'unlocked': unlocked};
}

class Mission {
  final String id;
  final String title;
  final String period;
  final int progress;
  final int target;
  final int xpReward;
  final int coinReward;
  final bool completed;
  const Mission(
      {this.id = '',
      this.title = '',
      this.period = 'daily',
      this.progress = 0,
      this.target = 1,
      this.xpReward = 0,
      this.coinReward = 0,
      this.completed = false});
  factory Mission.fromJson(Map<String, dynamic> json) => Mission(
      id: _text(json['id']),
      title: _text(json['title']),
      period: _text(json['period'], 'daily'),
      progress: _int(json['progress']),
      target: _int(json['target'], 1),
      xpReward: _int(json['xp_reward']),
      coinReward: _int(json['coin_reward']),
      completed: json['completed'] == true);
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'period': period,
        'progress': progress,
        'target': target,
        'xp_reward': xpReward,
        'coin_reward': coinReward,
        'completed': completed
      };
}

class DailyMission extends Mission {
  const DailyMission(
      {super.id,
      super.title,
      super.progress,
      super.target,
      super.xpReward,
      super.coinReward,
      super.completed})
      : super(period: 'daily');
}

class WeeklyMission extends Mission {
  const WeeklyMission(
      {super.id,
      super.title,
      super.progress,
      super.target,
      super.xpReward,
      super.coinReward,
      super.completed})
      : super(period: 'weekly');
}

class MonthlyMission extends Mission {
  const MonthlyMission(
      {super.id,
      super.title,
      super.progress,
      super.target,
      super.xpReward,
      super.coinReward,
      super.completed})
      : super(period: 'monthly');
}

class Reward {
  final String id;
  final String title;
  final String type;
  final int value;
  final bool unlocked;
  const Reward(
      {this.id = '',
      this.title = '',
      this.type = 'xp',
      this.value = 0,
      this.unlocked = false});
  factory Reward.fromJson(Map<String, dynamic> json) => Reward(
      id: _text(json['id']),
      title: _text(json['title']),
      type: _text(json['type'], 'xp'),
      value: _int(json['value']),
      unlocked: json['unlocked'] == true);
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'value': value,
        'unlocked': unlocked
      };
}

class CoinWallet {
  final int balance;
  final int earnedToday;
  final int spent;
  const CoinWallet({this.balance = 0, this.earnedToday = 0, this.spent = 0});
  factory CoinWallet.fromJson(Map<String, dynamic> json) => CoinWallet(
      balance: _int(json['balance']),
      earnedToday: _int(json['earned_today']),
      spent: _int(json['spent']));
  Map<String, dynamic> toJson() =>
      {'balance': balance, 'earned_today': earnedToday, 'spent': spent};
}

class Leaderboard {
  final String scope;
  final int rank;
  final int score;
  final List<LeaderboardEntry> entries;
  const Leaderboard(
      {this.scope = 'personal',
      this.rank = 0,
      this.score = 0,
      this.entries = const []});
  factory Leaderboard.fromJson(Map<String, dynamic> json) => Leaderboard(
      scope: _text(json['scope'], 'personal'),
      rank: _int(json['rank']),
      score: _int(json['score']),
      entries: _maps(json['entries']).map(LeaderboardEntry.fromJson).toList());
  Map<String, dynamic> toJson() => {
        'scope': scope,
        'rank': rank,
        'score': score,
        'entries': entries.map((item) => item.toJson()).toList()
      };
}

class LeaderboardEntry {
  final String id;
  final String label;
  final int score;
  final int rank;
  const LeaderboardEntry(
      {this.id = '', this.label = '', this.score = 0, this.rank = 0});
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
          id: _text(json['id']),
          label: _text(json['label']),
          score: _int(json['score']),
          rank: _int(json['rank']));
  Map<String, dynamic> toJson() =>
      {'id': id, 'label': label, 'score': score, 'rank': rank};
}

class SkillTree {
  final List<SkillNode> nodes;
  const SkillTree({this.nodes = const []});
  factory SkillTree.fromJson(Map<String, dynamic> json) =>
      SkillTree(nodes: _maps(json['nodes']).map(SkillNode.fromJson).toList());
  Map<String, dynamic> toJson() =>
      {'nodes': nodes.map((item) => item.toJson()).toList()};
}

class SkillNode {
  final String id;
  final String title;
  final int progress;
  final bool unlocked;
  final List<String> dependencies;
  const SkillNode(
      {this.id = '',
      this.title = '',
      this.progress = 0,
      this.unlocked = false,
      this.dependencies = const []});
  factory SkillNode.fromJson(Map<String, dynamic> json) => SkillNode(
      id: _text(json['id']),
      title: _text(json['title']),
      progress: _int(json['progress']),
      unlocked: json['unlocked'] == true,
      dependencies: _strings(json['dependencies']));
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'progress': progress,
        'unlocked': unlocked,
        'dependencies': dependencies
      };
}

class GamificationProfile {
  final DateTime updatedAt;
  final XP xp;
  final Level level;
  final CoinWallet wallet;
  final List<Achievement> achievements;
  final List<Badge> badges;
  final List<Mission> missions;
  final List<Reward> rewards;
  final Leaderboard leaderboard;
  final SkillTree skillTree;
  const GamificationProfile(
      {required this.updatedAt,
      this.xp = const XP(),
      this.level = const Level(),
      this.wallet = const CoinWallet(),
      this.achievements = const [],
      this.badges = const [],
      this.missions = const [],
      this.rewards = const [],
      this.leaderboard = const Leaderboard(),
      this.skillTree = const SkillTree()});
  factory GamificationProfile.empty() =>
      GamificationProfile(updatedAt: DateTime.fromMillisecondsSinceEpoch(0));
  factory GamificationProfile.fromJson(Map<String, dynamic> json) =>
      GamificationProfile(
          updatedAt: DateTime.tryParse(_text(json['updated_at'])) ??
              DateTime.fromMillisecondsSinceEpoch(0),
          xp: XP.fromJson(_map(json['xp'])),
          level: Level.fromJson(_map(json['level'])),
          wallet: CoinWallet.fromJson(_map(json['wallet'])),
          achievements:
              _maps(json['achievements']).map(Achievement.fromJson).toList(),
          badges: _maps(json['badges']).map(Badge.fromJson).toList(),
          missions: _maps(json['missions']).map(Mission.fromJson).toList(),
          rewards: _maps(json['rewards']).map(Reward.fromJson).toList(),
          leaderboard: Leaderboard.fromJson(_map(json['leaderboard'])),
          skillTree: SkillTree.fromJson(_map(json['skill_tree'])));
  Map<String, dynamic> toJson() => {
        'updated_at': updatedAt.toIso8601String(),
        'xp': xp.toJson(),
        'level': level.toJson(),
        'wallet': wallet.toJson(),
        'achievements': achievements.map((item) => item.toJson()).toList(),
        'badges': badges.map((item) => item.toJson()).toList(),
        'missions': missions.map((item) => item.toJson()).toList(),
        'rewards': rewards.map((item) => item.toJson()).toList(),
        'leaderboard': leaderboard.toJson(),
        'skill_tree': skillTree.toJson()
      };
}

int _int(dynamic value, [int fallback = 0]) =>
    value is num ? value.round() : int.tryParse('${value ?? ''}') ?? fallback;
String _text(dynamic value, [String fallback = '']) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
List<Map<String, dynamic>> _maps(dynamic value) => value is List
    ? value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList()
    : <Map<String, dynamic>>[];
List<String> _strings(dynamic value) => value is List
    ? value.map((item) => _text(item)).where((item) => item.isNotEmpty).toList()
    : const [];
