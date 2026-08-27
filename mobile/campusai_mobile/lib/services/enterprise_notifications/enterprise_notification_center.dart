import '../campus_intelligence/campus_snapshot_repository.dart';
import '../campus_intelligence/campus_intelligence_models.dart';
import '../campus_intelligence/enterprise_result_repository.dart';
import '../learning_engine/learning_models.dart';
import '../gamification/gamification_service.dart';
import '../gamification/gamification_models.dart';
import '../institution/institution_service.dart';
import '../institution/institution_models.dart';
import '../marketplace/marketplace_service.dart';
import '../marketplace/marketplace_models.dart';

enum NotificationPriority { critical, high, normal, low }

enum NotificationCategory {
  campus,
  gamification,
  marketplace,
  institution,
  voice,
  planner,
  achievement
}

class EnterpriseNotification {
  final String id;
  final String title;
  final String message;
  final NotificationPriority priority;
  final NotificationCategory category;
  final DateTime createdAt;
  const EnterpriseNotification(
      {this.id = '',
      this.title = '',
      this.message = '',
      this.priority = NotificationPriority.normal,
      this.category = NotificationCategory.campus,
      required this.createdAt});
  factory EnterpriseNotification.fromJson(
          Map<String, dynamic> j) =>
      EnterpriseNotification(
          id: j['id']?.toString() ?? '',
          title: j['title']?.toString() ?? '',
          message: j['message']?.toString() ?? '',
          priority: NotificationPriority.values.firstWhere(
              (x) => x.name == j['priority'],
              orElse: () => NotificationPriority.normal),
          category: NotificationCategory.values.firstWhere(
              (x) => x.name == j['category'],
              orElse: () => NotificationCategory.campus),
          createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0));
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'priority': priority.name,
        'category': category.name,
        'created_at': createdAt.toIso8601String()
      };
}

class NotificationHistory {
  final List<EnterpriseNotification> items;
  const NotificationHistory({this.items = const []});
  factory NotificationHistory.fromJson(Map<String, dynamic> j) =>
      NotificationHistory(
          items: (j['items'] as List? ?? const [])
              .whereType<Map>()
              .map((x) =>
                  EnterpriseNotification.fromJson(Map<String, dynamic>.from(x)))
              .toList());
  Map<String, dynamic> toJson() =>
      {'items': items.map((x) => x.toJson()).toList()};
}

class EnterpriseNotificationCenter {
  final CampusSnapshotRepository campus;
  final GamificationService gamification;
  final MarketplaceService marketplace;
  final InstitutionService institution;
  final EnterpriseResultRepository repository;
  const EnterpriseNotificationCenter(
      {this.campus = const CampusSnapshotRepository(),
      this.gamification = const GamificationService(),
      this.marketplace = const MarketplaceService(),
      this.institution = const InstitutionService(),
      this.repository = const EnterpriseResultRepository()});
  Future<NotificationHistory> build() async {
    try {
      final snapshot = await campus.getLatestSnapshot();
      final profile = await gamification.buildProfile();
      final catalog = await marketplace.buildCatalog();
      final dashboard = await institution.buildDashboard();
      final now = DateTime.now();
      final items = <EnterpriseNotification>[
        if (snapshot?.alerts.isNotEmpty == true)
          EnterpriseNotification(
              id: 'campus_alert',
              title: 'StudyBook AI',
              message: snapshot!.alerts.first,
              priority: NotificationPriority.high,
              category: NotificationCategory.campus,
              createdAt: now),
        if (profile.missions.any((m) => m.completed))
          EnterpriseNotification(
              id: 'mission_ready',
              title: 'Misión completada',
              message: 'Tienes recompensas disponibles.',
              priority: NotificationPriority.normal,
              category: NotificationCategory.gamification,
              createdAt: now),
        if (catalog.items.isNotEmpty)
          EnterpriseNotification(
              id: 'marketplace_ready',
              title: 'Marketplace',
              message: 'Hay ${catalog.items.length} recursos disponibles.',
              priority: NotificationPriority.low,
              category: NotificationCategory.marketplace,
              createdAt: now),
        if (dashboard.alerts.isNotEmpty)
          EnterpriseNotification(
              id: 'institution_alert',
              title: dashboard.alerts.first.title,
              message: dashboard.alerts.first.message,
              priority: NotificationPriority.high,
              category: NotificationCategory.institution,
              createdAt: now)
      ];
      final history = NotificationHistory(items: items);
      await repository.save(
          documentId: 'enterprise_notification_history_latest',
          type: 'enterprise_notification_history',
          payload: history.toJson());
      return history;
    } catch (_) {
      return const NotificationHistory();
    }
  }

  Future<NotificationHistory> buildLite({
    required CampusIntelligenceSnapshot campusSnapshot,
    required GamificationProfile gamificationProfile,
    required MarketplaceCatalog catalog,
    required InstitutionDashboard institutionDashboard,
    required SmartStudyPlan studyPlan,
    required LearningStreak streak,
  }) async {
    try {
      final now = DateTime.now();
      final items = <EnterpriseNotification>[
        if (campusSnapshot.alerts.isNotEmpty)
          EnterpriseNotification(
              id: 'campus_alert',
              title: 'Riesgo académico',
              message: campusSnapshot.alerts.first,
              priority: NotificationPriority.high,
              category: NotificationCategory.campus,
              createdAt: now),
        if (studyPlan.todayAction.trim().isNotEmpty)
          EnterpriseNotification(
              id: 'planner_today',
              title: 'Plan pendiente',
              message: studyPlan.todayAction,
              priority: NotificationPriority.normal,
              category: NotificationCategory.planner,
              createdAt: now),
        if (gamificationProfile.missions.any((m) => !m.completed))
          EnterpriseNotification(
              id: 'achievement_close',
              title: 'Logro cercano',
              message: gamificationProfile.missions.first.title,
              priority: NotificationPriority.low,
              category: NotificationCategory.achievement,
              createdAt: now),
        if (catalog.items.isNotEmpty)
          EnterpriseNotification(
              id: 'marketplace_recommended',
              title: 'Recurso recomendado',
              message: catalog.items.first.title,
              priority: NotificationPriority.low,
              category: NotificationCategory.marketplace,
              createdAt: now),
        if (streak.currentStreakDays <= 0)
          EnterpriseNotification(
              id: 'inactivity',
              title: 'Retoma tu racha',
              message: 'Completa una sesión corta para activar tu progreso.',
              priority: NotificationPriority.normal,
              category: NotificationCategory.voice,
              createdAt: now),
        if (institutionDashboard.alerts.isNotEmpty)
          EnterpriseNotification(
              id: 'institution_alert',
              title: institutionDashboard.alerts.first.title,
              message: institutionDashboard.alerts.first.message,
              priority: NotificationPriority.high,
              category: NotificationCategory.institution,
              createdAt: now),
      ];
      final prioritized = NotificationHistory(
        items: NotificationScheduler()
            .prioritize(NotificationHistory(items: items))
            .take(3)
            .toList(),
      );
      await repository.save(
          documentId: 'enterprise_notification_history_latest',
          type: 'enterprise_notification_history',
          payload: prioritized.toJson());
      return prioritized;
    } catch (_) {
      return const NotificationHistory();
    }
  }
}

class NotificationScheduler {
  const NotificationScheduler();
  List<EnterpriseNotification> prioritize(NotificationHistory history) {
    final items = [...history.items]
      ..sort((a, b) => a.priority.index.compareTo(b.priority.index));
    return items;
  }
}
