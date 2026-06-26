import '../study_result_service.dart';
import 'marketplace_service.dart';

class UnifiedSearchResult {
  final String id;
  final String title;
  final String type;
  final String subtitle;
  const UnifiedSearchResult(
      {this.id = '', this.title = '', this.type = '', this.subtitle = ''});
}

class UnifiedSearchEngine {
  final MarketplaceService marketplace;
  final MarketplaceSearchEngine marketplaceSearch;
  const UnifiedSearchEngine(
      {this.marketplace = const MarketplaceService(),
      this.marketplaceSearch = const MarketplaceSearchEngine()});
  Future<List<UnifiedSearchResult>> search(String query) async {
    final catalog = await marketplace.buildCatalog();
    final market = marketplaceSearch.search(catalog, query).map((item) =>
        UnifiedSearchResult(
            id: item.id,
            title: item.title,
            type: 'Marketplace',
            subtitle: item.categoryId));
    final results = <UnifiedSearchResult>[...market];
    for (final type in const [
      'audiobook',
      'question_bank',
      'study_guide',
      'flashcards'
    ]) {
      for (final item
          in (await StudyResultService.getResultsByType(type)).take(10)) {
        if (query.trim().isEmpty ||
            item.content.toLowerCase().contains(query.toLowerCase()) ||
            item.documentId.toLowerCase().contains(query.toLowerCase())) {
          results.add(UnifiedSearchResult(
              id: item.documentId,
              title: item.documentId,
              type: type,
              subtitle: 'Recurso local'));
        }
      }
    }
    return results.take(40).toList();
  }
}
