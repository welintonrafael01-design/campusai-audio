import 'ttl_cache_service.dart';

class AiContextCacheService {
  final TtlCacheService cache;
  const AiContextCacheService({this.cache = const TtlCacheService()});
  String? get context => cache.get<String>('ai_context');
  void save(String value) => cache.put('ai_context', value);
}
