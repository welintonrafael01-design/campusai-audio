library;

class MarketplaceCategory {
  final String id;
  final String title;
  final String icon;
  const MarketplaceCategory(
      {this.id = '', this.title = '', this.icon = 'category'});
  factory MarketplaceCategory.fromJson(Map<String, dynamic> json) =>
      MarketplaceCategory(
          id: _text(json['id']),
          title: _text(json['title']),
          icon: _text(json['icon'], 'category'));
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'icon': icon};
}

class MarketplaceAuthor {
  final String id;
  final String name;
  final bool verified;
  final int followers;
  const MarketplaceAuthor(
      {this.id = '',
      this.name = '',
      this.verified = false,
      this.followers = 0});
  factory MarketplaceAuthor.fromJson(Map<String, dynamic> json) =>
      MarketplaceAuthor(
          id: _text(json['id']),
          name: _text(json['name']),
          verified: json['verified'] == true,
          followers: _int(json['followers']));
  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'verified': verified, 'followers': followers};
}

class MarketplaceItem {
  final String id;
  final String title;
  final String description;
  final String categoryId;
  final MarketplaceAuthor author;
  final double rating;
  final int downloads;
  final bool premium;
  final List<String> tags;
  final DateTime publishedAt;
  const MarketplaceItem(
      {this.id = '',
      this.title = '',
      this.description = '',
      this.categoryId = '',
      this.author = const MarketplaceAuthor(),
      this.rating = 0,
      this.downloads = 0,
      this.premium = false,
      this.tags = const [],
      required this.publishedAt});
  factory MarketplaceItem.fromJson(Map<String, dynamic> json) =>
      MarketplaceItem(
          id: _text(json['id']),
          title: _text(json['title']),
          description: _text(json['description']),
          categoryId: _text(json['category_id']),
          author: MarketplaceAuthor.fromJson(_map(json['author'])),
          rating: _double(json['rating']),
          downloads: _int(json['downloads']),
          premium: json['premium'] == true,
          tags: _strings(json['tags']),
          publishedAt: DateTime.tryParse(_text(json['published_at'])) ??
              DateTime.fromMillisecondsSinceEpoch(0));
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category_id': categoryId,
        'author': author.toJson(),
        'rating': rating,
        'downloads': downloads,
        'premium': premium,
        'tags': tags,
        'published_at': publishedAt.toIso8601String()
      };
}

class MarketplaceReview {
  final String id;
  final String itemId;
  final String authorName;
  final int rating;
  final String comment;
  final DateTime createdAt;
  const MarketplaceReview(
      {this.id = '',
      this.itemId = '',
      this.authorName = '',
      this.rating = 0,
      this.comment = '',
      required this.createdAt});
  factory MarketplaceReview.fromJson(Map<String, dynamic> json) =>
      MarketplaceReview(
          id: _text(json['id']),
          itemId: _text(json['item_id']),
          authorName: _text(json['author_name']),
          rating: _int(json['rating']),
          comment: _text(json['comment']),
          createdAt: DateTime.tryParse(_text(json['created_at'])) ??
              DateTime.fromMillisecondsSinceEpoch(0));
  Map<String, dynamic> toJson() => {
        'id': id,
        'item_id': itemId,
        'author_name': authorName,
        'rating': rating,
        'comment': comment,
        'created_at': createdAt.toIso8601String()
      };
}

class MarketplacePurchase {
  final String itemId;
  final DateTime acquiredAt;
  final String status;
  const MarketplacePurchase(
      {this.itemId = '', required this.acquiredAt, this.status = 'owned'});
  factory MarketplacePurchase.fromJson(Map<String, dynamic> json) =>
      MarketplacePurchase(
          itemId: _text(json['item_id']),
          acquiredAt: DateTime.tryParse(_text(json['acquired_at'])) ??
              DateTime.fromMillisecondsSinceEpoch(0),
          status: _text(json['status'], 'owned'));
  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'acquired_at': acquiredAt.toIso8601String(),
        'status': status
      };
}

class MarketplaceLicense {
  final String itemId;
  final String type;
  final DateTime? expiresAt;
  const MarketplaceLicense(
      {this.itemId = '', this.type = 'personal', this.expiresAt});
  factory MarketplaceLicense.fromJson(Map<String, dynamic> json) =>
      MarketplaceLicense(
          itemId: _text(json['item_id']),
          type: _text(json['type'], 'personal'),
          expiresAt: DateTime.tryParse(_text(json['expires_at'])));
  Map<String, dynamic> toJson() => {
        'item_id': itemId,
        'type': type,
        'expires_at': expiresAt?.toIso8601String() ?? ''
      };
}

class MarketplaceCollection {
  final String id;
  final String title;
  final List<String> itemIds;
  const MarketplaceCollection(
      {this.id = '', this.title = '', this.itemIds = const []});
  factory MarketplaceCollection.fromJson(Map<String, dynamic> json) =>
      MarketplaceCollection(
          id: _text(json['id']),
          title: _text(json['title']),
          itemIds: _strings(json['item_ids']));
  Map<String, dynamic> toJson() =>
      {'id': id, 'title': title, 'item_ids': itemIds};
}

class MarketplaceCatalog {
  final DateTime updatedAt;
  final List<MarketplaceCategory> categories;
  final List<MarketplaceItem> items;
  const MarketplaceCatalog(
      {required this.updatedAt,
      this.categories = const [],
      this.items = const []});
  factory MarketplaceCatalog.empty() =>
      MarketplaceCatalog(updatedAt: DateTime.fromMillisecondsSinceEpoch(0));
  factory MarketplaceCatalog.fromJson(Map<String, dynamic> json) =>
      MarketplaceCatalog(
          updatedAt: DateTime.tryParse(_text(json['updated_at'])) ??
              DateTime.fromMillisecondsSinceEpoch(0),
          categories: _maps(json['categories'])
              .map(MarketplaceCategory.fromJson)
              .toList(),
          items: _maps(json['items']).map(MarketplaceItem.fromJson).toList());
  Map<String, dynamic> toJson() => {
        'updated_at': updatedAt.toIso8601String(),
        'categories': categories.map((item) => item.toJson()).toList(),
        'items': items.map((item) => item.toJson()).toList()
      };
}

int _int(dynamic value) =>
    value is num ? value.round() : int.tryParse('${value ?? ''}') ?? 0;
double _double(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse('${value ?? ''}') ?? 0;
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
