class MemoryCacheService {
  static final Map<String, Object> _values = {};
  const MemoryCacheService();
  T? get<T>(String key) => _values[key] as T?;
  void put(String key, Object value) => _values[key] = value;
  void remove(String key) => _values.remove(key);
}
