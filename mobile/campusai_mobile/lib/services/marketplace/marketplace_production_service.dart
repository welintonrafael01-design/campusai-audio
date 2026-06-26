import '../campus_intelligence/enterprise_result_repository.dart';
import 'marketplace_models.dart';

enum PublishingStatus { draft, published, archived, pendingReview, rejected }

enum MarketplaceResourceType {
  course,
  audiobook,
  questionBank,
  exam,
  presentation,
  teachingPlan,
  resource,
}

class LicensingModel {
  final String id;
  final String title;
  final bool allowsInstitutionUse;
  final bool allowsCommercialUse;

  const LicensingModel({
    this.id = 'standard',
    this.title = 'Standard',
    this.allowsInstitutionUse = true,
    this.allowsCommercialUse = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'allows_institution_use': allowsInstitutionUse,
        'allows_commercial_use': allowsCommercialUse,
      };
}

class VersionHistoryEntry {
  final String version;
  final String status;
  final DateTime createdAt;
  final String notes;

  const VersionHistoryEntry({
    this.version = '1.0.0',
    this.status = 'draft',
    required this.createdAt,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'notes': notes,
      };
}

class PublishingContract {
  final String id;
  final MarketplaceResourceType type;
  final PublishingStatus status;
  final LicensingModel licensing;
  final List<VersionHistoryEntry> versions;
  final Map<String, dynamic> payload;

  const PublishingContract({
    required this.id,
    required this.type,
    this.status = PublishingStatus.draft,
    this.licensing = const LicensingModel(),
    this.versions = const [],
    this.payload = const {},
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'status': _statusName(status),
        'licensing': licensing.toJson(),
        'versions': versions.map((entry) => entry.toJson()).toList(),
        'payload': payload,
      };
}

class PublisherDashboard {
  final int drafts;
  final int published;
  final int pendingReview;
  final int rejected;
  final List<PublishingContract> resources;

  const PublisherDashboard({
    this.drafts = 0,
    this.published = 0,
    this.pendingReview = 0,
    this.rejected = 0,
    this.resources = const [],
  });

  Map<String, dynamic> toJson() => {
        'drafts': drafts,
        'published': published,
        'pending_review': pendingReview,
        'rejected': rejected,
        'resources': resources.map((item) => item.toJson()).toList(),
      };
}

class MarketplaceProductionService {
  final EnterpriseResultRepository repository;
  const MarketplaceProductionService({
    this.repository = const EnterpriseResultRepository(),
  });

  Future<void> saveDraft(PublishingContract contract) => repository.save(
        documentId: 'marketplace_contract_${contract.id}',
        type: 'marketplace_history',
        payload: contract.toJson(),
      );

  Future<PublisherDashboard> buildPublisherDashboard(
    List<PublishingContract> contracts,
  ) async {
    final dashboard = PublisherDashboard(
      drafts: contracts
          .where((item) => item.status == PublishingStatus.draft)
          .length,
      published: contracts
          .where((item) => item.status == PublishingStatus.published)
          .length,
      pendingReview: contracts
          .where((item) => item.status == PublishingStatus.pendingReview)
          .length,
      rejected: contracts
          .where((item) => item.status == PublishingStatus.rejected)
          .length,
      resources: contracts,
    );
    await repository.save(
      documentId: 'publisher_dashboard_latest',
      type: 'publisher_dashboard',
      payload: dashboard.toJson(),
    );
    return dashboard;
  }

  MarketplaceItem toMarketplaceItem(PublishingContract contract) =>
      MarketplaceItem(
        id: contract.id,
        title: contract.payload['title']?.toString() ?? 'Marketplace resource',
        description: contract.payload['description']?.toString() ?? '',
        categoryId: contract.type.name,
        author: const MarketplaceAuthor(
            id: 'local_creator', name: 'StudyBook Creator', verified: false),
        rating: 0,
        downloads: 0,
        tags: [contract.type.name, _statusName(contract.status)],
        publishedAt: DateTime.now(),
      );
}

class MarketplaceSearch2Service {
  const MarketplaceSearch2Service();

  List<MarketplaceItem> search(
    List<MarketplaceItem> items, {
    String semantic = '',
    String tag = '',
    String category = '',
    String teacher = '',
    String institution = '',
    String creator = '',
    String difficulty = '',
    String language = '',
  }) {
    final query = [
      semantic,
      tag,
      category,
      teacher,
      institution,
      creator,
      difficulty,
      language
    ].where((part) => part.trim().isNotEmpty).join(' ').toLowerCase();
    if (query.isEmpty) return items;
    return items.where((item) {
      final haystack =
          '${item.title} ${item.description} ${item.categoryId} ${item.author.name} ${item.tags.join(' ')}'
              .toLowerCase();
      return query.split(' ').every(haystack.contains);
    }).toList();
  }

  List<MarketplaceItem> trending(List<MarketplaceItem> items) =>
      [...items]..sort((a, b) => b.downloads.compareTo(a.downloads));

  List<MarketplaceItem> popular(List<MarketplaceItem> items) =>
      [...items]..sort((a, b) => b.rating.compareTo(a.rating));

  List<MarketplaceItem> newArrivals(List<MarketplaceItem> items) =>
      [...items]..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

  List<MarketplaceItem> favorites(
    List<MarketplaceItem> items,
    List<String> favoriteIds,
  ) =>
      items.where((item) => favoriteIds.contains(item.id)).toList();
}

String _statusName(PublishingStatus status) =>
    status == PublishingStatus.pendingReview ? 'pending_review' : status.name;
