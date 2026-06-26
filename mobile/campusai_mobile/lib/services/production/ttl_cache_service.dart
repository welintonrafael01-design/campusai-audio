class TtlCacheService {
  static final Map<String, ({Object value, DateTime time})> _cache = {};
  const TtlCacheService();
  T? get<T>(String key, {Duration ttl = const Duration(minutes: 15)}) {
    final e = _cache[key];
    return e == null || DateTime.now().difference(e.time) > ttl
        ? null
        : e.value as T?;
  }

  void put(String key, Object value) =>
      _cache[key] = (value: value, time: DateTime.now());
}
