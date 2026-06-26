import '../campus_intelligence/enterprise_result_repository.dart';
import '../audiobook_service.dart';
import '../study_result_service.dart';
import 'marketplace_models.dart';

class MarketplaceRepository {
  final EnterpriseResultRepository repository;
  const MarketplaceRepository(
      {this.repository = const EnterpriseResultRepository()});
  Future<void> saveCatalog(MarketplaceCatalog catalog) => repository.save(
      documentId: 'marketplace_catalog_latest',
      type: 'marketplace_catalog',
      payload: catalog.toJson(),
      createdAt: catalog.updatedAt);
  Future<MarketplaceCatalog?> getCatalog() async {
    final raw = await repository.load(
        documentId: 'marketplace_catalog_latest', type: 'marketplace_catalog');
    return raw == null ? null : MarketplaceCatalog.fromJson(raw);
  }

  Future<void> saveHistory(Map<String, dynamic> history) => repository.save(
      documentId: 'marketplace_history_latest',
      type: 'marketplace_history',
      payload: history);
  Future<Map<String, dynamic>?> getHistory() => repository.load(
      documentId: 'marketplace_history_latest', type: 'marketplace_history');
}

class MarketplaceService {
  final MarketplaceRepository repository;
  final AudiobookService audiobookService;
  const MarketplaceService({
    this.repository = const MarketplaceRepository(),
    this.audiobookService = const AudiobookService(),
  });
  Future<MarketplaceCatalog> buildCatalog({bool refresh = false}) async {
    if (!refresh) {
      final cached = await repository.getCatalog();
      if (cached != null) return cached;
    }
    try {
      final items = <MarketplaceItem>[];
      final mapping = {
        'audiobook': 'audiobooks',
        'learning_pack': 'learning_packs',
        'question_bank': 'question_banks',
        'study_guide': 'learning_packs',
        'exam': 'evaluations',
        'rubric': 'rubrics',
        'presentation': 'presentations',
        'teaching_plan': 'courses',
        'teaching_resources': 'templates',
        'course_resource': 'templates',
        'assessment_report': 'evaluations'
      };
      for (final entry in mapping.entries) {
        final results = await StudyResultService.getResultsByType(entry.key);
        for (final result in results.take(20)) {
          items.add(MarketplaceItem(
              id: 'local_${entry.key}_${result.documentId}',
              title: _title(result.content, entry.key),
              description: 'Recurso generado en StudyBook AI.',
              categoryId: entry.value,
              author: const MarketplaceAuthor(
                  id: 'studybook', name: 'StudyBook AI', verified: true),
              rating: 4.8,
              downloads: 0,
              tags: [entry.key, 'local'],
              publishedAt:
                  DateTime.tryParse(result.createdAt) ?? DateTime.now()));
        }
      }
      items.addAll(await _learningPacksFromAudiobooks());
      final catalog = MarketplaceCatalog(
          updatedAt: DateTime.now(), categories: _categories, items: items);
      await repository.saveCatalog(catalog);
      return catalog;
    } catch (_) {
      return MarketplaceCatalog.empty();
    }
  }

  Future<List<MarketplaceItem>> _learningPacksFromAudiobooks() async {
    final items = <MarketplaceItem>[];
    final audiobookResults = await audiobookService.getAudioBooks();
    for (final result in audiobookResults.take(20)) {
      final audiobook = audiobookService.decodeAudioBook(result);
      final audiobookId = _field(audiobook, ['audiobook_id', 'id', 'document_id']);
      final title = _field(audiobook, ['title', 'name'], 'AudioBook');
      final chapters = audiobook['chapters'];
      if (chapters is! List) continue;
      for (final chapter in chapters.whereType<Map>().take(8)) {
        final learningPack = chapter['learning_pack'];
        if (learningPack is! Map) continue;
        final chapterId = _field(chapter, ['chapter_id', 'id']);
        items.add(MarketplaceItem(
          id: 'local_learning_pack_${audiobookId}_$chapterId',
          title: _field(
            learningPack,
            ['title', 'guide_title'],
            'Learning Pack - ${_field(chapter, ['title'], title)}',
          ),
          description: _field(
            learningPack,
            ['summary', 'overview', 'description'],
            'Learning Pack generado desde AudioBook Studio.',
          ),
          categoryId: 'learning_packs',
          author: const MarketplaceAuthor(
              id: 'studybook', name: 'StudyBook AI', verified: true),
          rating: 4.8,
          downloads: 0,
          tags: const ['learning_pack', 'audiobook', 'local'],
          publishedAt: DateTime.now(),
        ));
      }
    }
    return items;
  }

  String _title(String content, String fallback) {
    final line = content.replaceAll(RegExp(r'[{}\[\]"]'), ' ').trim();
    return line.isEmpty
        ? 'Recurso ${fallback.replaceAll('_', ' ')}'
        : line.substring(0, line.length > 60 ? 60 : line.length);
  }

  String _field(Map<dynamic, dynamic> map, List<String> keys,
      [String fallback = '']) {
    for (final key in keys) {
      final value = map[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return fallback;
  }

  static const _categories = [
    MarketplaceCategory(id: 'courses', title: 'Cursos'),
    MarketplaceCategory(id: 'learning_packs', title: 'Learning Packs'),
    MarketplaceCategory(id: 'audiobooks', title: 'AudioBooks'),
    MarketplaceCategory(id: 'flashcards', title: 'Flashcards'),
    MarketplaceCategory(id: 'question_banks', title: 'Bancos de preguntas'),
    MarketplaceCategory(id: 'presentations', title: 'Presentaciones'),
    MarketplaceCategory(id: 'rubrics', title: 'Rubricas'),
    MarketplaceCategory(id: 'ai_prompts', title: 'Prompts IA'),
    MarketplaceCategory(id: 'ai_assistants', title: 'Asistentes IA'),
    MarketplaceCategory(id: 'templates', title: 'Plantillas'),
    MarketplaceCategory(id: 'evaluations', title: 'Evaluaciones'),
    MarketplaceCategory(id: 'premium', title: 'Recursos Premium')
  ];
}

class MarketplaceSearchEngine {
  const MarketplaceSearchEngine();
  List<MarketplaceItem> search(MarketplaceCatalog catalog, String query) {
    final terms = query.toLowerCase().trim();
    if (terms.isEmpty) return catalog.items;
    return catalog.items
        .where((item) =>
            '${item.title} ${item.description} ${item.tags.join(' ')} ${item.categoryId}'
                .toLowerCase()
                .contains(terms))
        .toList();
  }
}

class MarketplaceRecommendationEngine {
  const MarketplaceRecommendationEngine();
  List<MarketplaceItem> recommend(MarketplaceCatalog catalog,
      {List<String> focus = const [], String risk = ''}) {
    final terms = focus.join(' ').toLowerCase();
    final ranked = [
      ...catalog.items
    ]..sort((a, b) => _score(b, terms, risk).compareTo(_score(a, terms, risk)));
    return ranked.take(6).toList();
  }

  int _score(MarketplaceItem item, String terms, String risk) =>
      (item.rating * 10).round() +
      item.downloads +
      (terms.isNotEmpty &&
              '${item.title} ${item.tags.join(' ')}'
                  .toLowerCase()
                  .contains(terms)
          ? 30
          : 0) +
      (risk.toLowerCase().contains('alto') &&
              item.categoryId == 'learning_packs'
          ? 15
          : 0);
}

class MarketplacePublisher {
  final MarketplaceRepository repository;
  const MarketplacePublisher({this.repository = const MarketplaceRepository()});
  Future<void> publish(MarketplaceItem item) async {
    final history = await repository.getHistory() ?? {};
    final published = _strings(history['published'])..add(item.id);
    await repository.saveHistory({...history, 'published': published});
  }
}

class MarketplaceReviewService {
  final MarketplaceRepository repository;
  const MarketplaceReviewService(
      {this.repository = const MarketplaceRepository()});
  Future<void> saveReview(MarketplaceReview review) async {
    final history = await repository.getHistory() ?? {};
    final reviews = _maps(history['reviews'])..add(review.toJson());
    await repository.saveHistory({...history, 'reviews': reviews});
  }
}

class MarketplaceFavoritesService {
  final MarketplaceRepository repository;
  const MarketplaceFavoritesService(
      {this.repository = const MarketplaceRepository()});
  Future<void> toggle(String itemId) async {
    final history = await repository.getHistory() ?? {};
    final favorites = _strings(history['favorites']);
    favorites.contains(itemId)
        ? favorites.remove(itemId)
        : favorites.add(itemId);
    await repository.saveHistory({...history, 'favorites': favorites});
  }
}

class MarketplaceDownloadService {
  final MarketplaceRepository repository;
  const MarketplaceDownloadService(
      {this.repository = const MarketplaceRepository()});
  Future<void> registerDownload(String itemId) async {
    final history = await repository.getHistory() ?? {};
    final downloads = _strings(history['downloads'])..add(itemId);
    await repository.saveHistory({...history, 'downloads': downloads});
  }
}

List<String> _strings(dynamic value) =>
    value is List ? value.map((item) => item.toString()).toList() : <String>[];
List<Map<String, dynamic>> _maps(dynamic value) => value is List
    ? value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList()
    : <Map<String, dynamic>>[];
