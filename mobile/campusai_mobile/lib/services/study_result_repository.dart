import '../models/study_result.dart';
import 'auth_service.dart';
import 'cloud_api_service.dart';
import 'study_result_service.dart';

typedef StudyResultCloudLoader = Future<Map<String, dynamic>?> Function(
  String documentId,
  String type,
);
typedef StudyResultCloudListLoader = Future<List<dynamic>> Function(
    String type);

/// Provides local-first access to generated resources with transparent cloud
/// recovery. Cloud failures never make an already cached resource unavailable.
class StudyResultRepository {
  const StudyResultRepository({
    this.cloudLoader,
    this.cloudListLoader,
    this.authenticatedOverride,
  });

  final StudyResultCloudLoader? cloudLoader;
  final StudyResultCloudListLoader? cloudListLoader;
  final bool? authenticatedOverride;

  bool get _canUseCloud => authenticatedOverride ?? AuthService.isLoggedIn;

  Future<StudyResult?> getResult({
    required String documentId,
    required String type,
  }) async {
    final local = await StudyResultService.getResult(
      documentId: documentId,
      type: type,
    );
    if (local != null) return local;
    if (!_canUseCloud && cloudLoader == null) return null;

    try {
      final raw = await (cloudLoader ?? _loadCloudResult)(documentId, type);
      final cloud = fromCloud(raw, expectedType: type);
      if (cloud == null || cloud.documentId != documentId) return null;
      await StudyResultService.saveResult(cloud);
      return cloud;
    } catch (_) {
      return null;
    }
  }

  Future<List<StudyResult>> getResultsByType(String type) async {
    final local = await StudyResultService.getResultsByType(type);
    final byDocumentId = {
      for (final result in local) result.documentId: result,
    };
    if (!_canUseCloud && cloudListLoader == null) return local;

    try {
      final items = await (cloudListLoader ?? _loadCloudResults)(type);
      for (final item in items) {
        final cloud = fromCloud(item, expectedType: type);
        if (cloud == null) continue;
        byDocumentId[cloud.documentId] = cloud;
        await StudyResultService.saveResult(cloud);
      }
    } catch (_) {
      // Offline mode intentionally keeps the local collection available.
    }

    final results = byDocumentId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  StudyResult? fromCloud(dynamic raw, {required String expectedType}) {
    if (raw is! Map) return null;
    final item = Map<String, dynamic>.from(raw);
    final documentId =
        (item['document_id'] ?? item['documentId'])?.toString().trim() ?? '';
    final type = item['type']?.toString().trim() ?? '';
    final content = item['content']?.toString().trim() ?? '';
    final createdAt =
        (item['updated_at'] ?? item['created_at'] ?? item['createdAt'])
                ?.toString()
                .trim() ??
            '';

    final result = StudyResult(
      documentId: documentId,
      type: type,
      content: content,
      createdAt: createdAt.isEmpty
          ? DateTime.fromMillisecondsSinceEpoch(0).toIso8601String()
          : createdAt,
    );
    return result.isValid && type == expectedType ? result : null;
  }

  Future<Map<String, dynamic>?> _loadCloudResult(
    String documentId,
    String type,
  ) {
    return CloudApiService.getStudyResult(
      documentId: documentId,
      type: type,
    );
  }

  Future<List<dynamic>> _loadCloudResults(String type) {
    return CloudApiService.getStudyResults(type: type);
  }
}
