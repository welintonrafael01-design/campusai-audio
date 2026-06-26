import '../campus_intelligence/enterprise_result_repository.dart';
import 'marketplace_models.dart';

class CreatorProfile {
  final String id;
  final String displayName;
  final String bio;
  final CreatorVerification verification;
  const CreatorProfile(
      {this.id = '',
      this.displayName = '',
      this.bio = '',
      this.verification = const CreatorVerification()});
  factory CreatorProfile.fromJson(Map<String, dynamic> j) => CreatorProfile(
      id: j['id']?.toString() ?? '',
      displayName: j['display_name']?.toString() ?? '',
      bio: j['bio']?.toString() ?? '',
      verification: CreatorVerification.fromJson(_map(j['verification'])));
  Map<String, dynamic> toJson() => {
        'id': id,
        'display_name': displayName,
        'bio': bio,
        'verification': verification.toJson()
      };
}

class CreatorStatistics {
  final int sales;
  final int downloads;
  final double rating;
  final int publishedContent;
  const CreatorStatistics(
      {this.sales = 0,
      this.downloads = 0,
      this.rating = 0,
      this.publishedContent = 0});
  factory CreatorStatistics.fromJson(Map<String, dynamic> j) =>
      CreatorStatistics(
          sales: _int(j['sales']),
          downloads: _int(j['downloads']),
          rating: _double(j['rating']),
          publishedContent: _int(j['published_content']));
  Map<String, dynamic> toJson() => {
        'sales': sales,
        'downloads': downloads,
        'rating': rating,
        'published_content': publishedContent
      };
}

class CreatorRevenue {
  final int estimatedCoins;
  final int completedSales;
  const CreatorRevenue({this.estimatedCoins = 0, this.completedSales = 0});
  factory CreatorRevenue.fromJson(Map<String, dynamic> j) => CreatorRevenue(
      estimatedCoins: _int(j['estimated_coins']),
      completedSales: _int(j['completed_sales']));
  Map<String, dynamic> toJson() =>
      {'estimated_coins': estimatedCoins, 'completed_sales': completedSales};
}

class CreatorPortfolio {
  final List<MarketplaceItem> items;
  const CreatorPortfolio({this.items = const []});
  factory CreatorPortfolio.fromJson(Map<String, dynamic> j) => CreatorPortfolio(
      items: _maps(j['items']).map(MarketplaceItem.fromJson).toList());
  Map<String, dynamic> toJson() =>
      {'items': items.map((item) => item.toJson()).toList()};
}

class CreatorRanking {
  final int rank;
  final int score;
  const CreatorRanking({this.rank = 0, this.score = 0});
  factory CreatorRanking.fromJson(Map<String, dynamic> j) =>
      CreatorRanking(rank: _int(j['rank']), score: _int(j['score']));
  Map<String, dynamic> toJson() => {'rank': rank, 'score': score};
}

class CreatorFollowers {
  final int count;
  final bool following;
  const CreatorFollowers({this.count = 0, this.following = false});
  factory CreatorFollowers.fromJson(Map<String, dynamic> j) => CreatorFollowers(
      count: _int(j['count']), following: j['following'] == true);
  Map<String, dynamic> toJson() => {'count': count, 'following': following};
}

class CreatorSubscriptions {
  final int subscribers;
  final bool active;
  const CreatorSubscriptions({this.subscribers = 0, this.active = false});
  factory CreatorSubscriptions.fromJson(Map<String, dynamic> j) =>
      CreatorSubscriptions(
          subscribers: _int(j['subscribers']), active: j['active'] == true);
  Map<String, dynamic> toJson() =>
      {'subscribers': subscribers, 'active': active};
}

class CreatorVerification {
  final bool verified;
  final String status;
  const CreatorVerification(
      {this.verified = false, this.status = 'unverified'});
  factory CreatorVerification.fromJson(Map<String, dynamic> j) =>
      CreatorVerification(
          verified: j['verified'] == true,
          status: j['status']?.toString() ?? 'unverified');
  Map<String, dynamic> toJson() => {'verified': verified, 'status': status};
}

class CreatorEconomyService {
  final EnterpriseResultRepository repository;
  const CreatorEconomyService(
      {this.repository = const EnterpriseResultRepository()});
  Future<void> saveProfile(CreatorProfile profile) => repository.save(
      documentId: 'creator_profile_latest',
      type: 'creator_profile',
      payload: profile.toJson());
  Future<CreatorProfile?> getProfile() async {
    final raw = await repository.load(
        documentId: 'creator_profile_latest', type: 'creator_profile');
    return raw == null ? null : CreatorProfile.fromJson(raw);
  }

  CreatorStatistics calculateStatistics(CreatorPortfolio portfolio) =>
      CreatorStatistics(
          downloads:
              portfolio.items.fold(0, (sum, item) => sum + item.downloads),
          rating: portfolio.items.isEmpty
              ? 0
              : portfolio.items
                      .map((item) => item.rating)
                      .reduce((a, b) => a + b) /
                  portfolio.items.length,
          publishedContent: portfolio.items.length);
  CreatorRevenue calculateRevenue(CreatorStatistics stats) => CreatorRevenue(
      estimatedCoins: stats.downloads * 2, completedSales: stats.sales);
}

Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
List<Map<String, dynamic>> _maps(dynamic v) => v is List
    ? v.whereType<Map>().map((x) => Map<String, dynamic>.from(x)).toList()
    : <Map<String, dynamic>>[];
int _int(dynamic v) => v is num ? v.round() : int.tryParse('${v ?? ''}') ?? 0;
double _double(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse('${v ?? ''}') ?? 0;
