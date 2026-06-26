import 'ttl_cache_service.dart';

class EnterpriseCacheService {
  final TtlCacheService ttl;
  const EnterpriseCacheService({this.ttl = const TtlCacheService()});

  T? snapshot<T>(String id) => ttl.get<T>('snapshot_cache:$id');
  T? workflow<T>(String id) => ttl.get<T>('workflow_cache:$id');
  T? marketplace<T>(String id) => ttl.get<T>('marketplace_cache:$id');
  T? voice<T>(String id) => ttl.get<T>('voice_cache:$id');
  T? institution<T>(String id) => ttl.get<T>('institution_cache:$id');
  T? prediction<T>(String id) => ttl.get<T>('prediction_cache:$id');
  T? dashboard<T>(String id) => ttl.get<T>('dashboard_cache:$id');

  void putSnapshot(String id, Object value) =>
      ttl.put('snapshot_cache:$id', value);
  void putWorkflow(String id, Object value) =>
      ttl.put('workflow_cache:$id', value);
  void putMarketplace(String id, Object value) =>
      ttl.put('marketplace_cache:$id', value);
  void putVoice(String id, Object value) => ttl.put('voice_cache:$id', value);
  void putInstitution(String id, Object value) =>
      ttl.put('institution_cache:$id', value);
  void putPrediction(String id, Object value) =>
      ttl.put('prediction_cache:$id', value);
  void putDashboard(String id, Object value) =>
      ttl.put('dashboard_cache:$id', value);
}
