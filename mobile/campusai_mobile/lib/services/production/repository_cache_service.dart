import 'ttl_cache_service.dart';

class RepositoryCacheService {
  final TtlCacheService cache;
  const RepositoryCacheService({this.cache = const TtlCacheService()});
  Future<T> read<T>(String key, Future<T> Function() loader) async {
    final c = cache.get<T>(key);
    if (c != null) return c;
    final v = await loader();
    cache.put(key, v as Object);
    return v;
  }
}
