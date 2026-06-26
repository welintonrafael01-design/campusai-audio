import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../models/study_result.dart';
import '../study_result_service.dart';

/// Shared, local-only persistence and small TTL cache for Enterprise outputs.
class EnterpriseResultRepository {
  static final Map<String, _CachedValue> _cache = {};

  const EnterpriseResultRepository();

  Future<void> save({
    required String documentId,
    required String type,
    required Map<String, dynamic> payload,
    DateTime? createdAt,
  }) async {
    try {
      final timestamp = createdAt ?? DateTime.now();
      await StudyResultService.saveResult(
        StudyResult(
          documentId: documentId,
          type: type,
          content: jsonEncode(payload),
          createdAt: timestamp.toIso8601String(),
        ),
      );
      _cache['$type:$documentId'] = _CachedValue(payload, timestamp);
    } catch (error) {
      debugPrint('EnterpriseResultRepository.save: $error');
    }
  }

  Future<Map<String, dynamic>?> load({
    required String documentId,
    required String type,
    Duration maxAge = const Duration(minutes: 15),
  }) async {
    final key = '$type:$documentId';
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.savedAt) <= maxAge) {
      return Map<String, dynamic>.from(cached.payload);
    }
    try {
      final result = await StudyResultService.getResult(
        documentId: documentId,
        type: type,
      );
      if (result == null || result.content.trim().isEmpty) return null;
      final decoded = jsonDecode(result.content);
      if (decoded is! Map) return null;
      final payload = Map<String, dynamic>.from(decoded);
      _cache[key] = _CachedValue(payload, DateTime.now());
      return payload;
    } catch (error) {
      debugPrint('EnterpriseResultRepository.load: $error');
      return null;
    }
  }
}

class _CachedValue {
  final Map<String, dynamic> payload;
  final DateTime savedAt;
  const _CachedValue(this.payload, this.savedAt);
}
