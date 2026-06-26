import '../campus_intelligence/enterprise_result_repository.dart';
import 'creator_economy_service.dart';
import 'marketplace_models.dart';

class CreatorAnalytics {
  final int downloads;
  final int followers;
  final int following;
  final double ratings;
  final int topResources;
  final int engagement;
  final int productivity;
  final int revenueProjection;

  const CreatorAnalytics({
    this.downloads = 0,
    this.followers = 0,
    this.following = 0,
    this.ratings = 0,
    this.topResources = 0,
    this.engagement = 0,
    this.productivity = 0,
    this.revenueProjection = 0,
  });

  Map<String, dynamic> toJson() => {
        'downloads': downloads,
        'followers': followers,
        'following': following,
        'ratings': ratings,
        'top_resources': topResources,
        'engagement': engagement,
        'productivity': productivity,
        'revenue_projection': revenueProjection,
      };
}

class PublishingCalendarEntry {
  final String resourceId;
  final String title;
  final DateTime scheduledFor;

  const PublishingCalendarEntry({
    this.resourceId = '',
    this.title = '',
    required this.scheduledFor,
  });

  Map<String, dynamic> toJson() => {
        'resource_id': resourceId,
        'title': title,
        'scheduled_for': scheduledFor.toIso8601String(),
      };
}

class CreatorDashboard {
  final CreatorProfile profile;
  final CreatorAnalytics analytics;
  final List<MarketplaceItem> topResources;
  final List<PublishingCalendarEntry> publishingCalendar;

  const CreatorDashboard({
    this.profile = const CreatorProfile(),
    this.analytics = const CreatorAnalytics(),
    this.topResources = const [],
    this.publishingCalendar = const [],
  });

  Map<String, dynamic> toJson() => {
        'profile': profile.toJson(),
        'analytics': analytics.toJson(),
        'top_resources': topResources.map((item) => item.toJson()).toList(),
        'publishing_calendar':
            publishingCalendar.map((entry) => entry.toJson()).toList(),
      };
}

class CreatorDashboardService {
  final EnterpriseResultRepository repository;
  const CreatorDashboardService({
    this.repository = const EnterpriseResultRepository(),
  });

  Future<CreatorDashboard> build({
    CreatorProfile profile = const CreatorProfile(),
    List<MarketplaceItem> resources = const [],
    int followers = 0,
    int following = 0,
  }) async {
    final sorted = [...resources]
      ..sort((a, b) => b.downloads.compareTo(a.downloads));
    final downloads =
        resources.fold<int>(0, (sum, item) => sum + item.downloads);
    final rating = resources.isEmpty
        ? 0.0
        : resources.fold<double>(0, (sum, item) => sum + item.rating) /
            resources.length;
    final dashboard = CreatorDashboard(
      profile: profile,
      analytics: CreatorAnalytics(
        downloads: downloads,
        followers: followers,
        following: following,
        ratings: rating,
        topResources: sorted.take(5).length,
        engagement: (followers + downloads).clamp(0, 100),
        productivity: resources.length.clamp(0, 100),
        revenueProjection: downloads * 2,
      ),
      topResources: sorted.take(5).toList(),
      publishingCalendar: resources
          .take(6)
          .map((item) => PublishingCalendarEntry(
                resourceId: item.id,
                title: item.title,
                scheduledFor: DateTime.now().add(const Duration(days: 7)),
              ))
          .toList(),
    );
    await repository.save(
      documentId: 'creator_dashboard_latest',
      type: 'creator_dashboard',
      payload: dashboard.toJson(),
    );
    return dashboard;
  }
}
