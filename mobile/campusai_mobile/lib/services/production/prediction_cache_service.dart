import 'ttl_cache_service.dart';

class PredictionCacheService {
  final TtlCacheService cache;
  const PredictionCacheService({this.cache = const TtlCacheService()});
  T? get<T>() => cache.get<T>('prediction');
  void save(Object value) => cache.put('prediction', value);
}
