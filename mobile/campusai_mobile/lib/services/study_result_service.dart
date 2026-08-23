import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/study_result.dart';
import 'educator_sync_service.dart';
import 'security/user_scoped_storage.dart';

class StudyResultService {
  static const String _key = 'study_result';

  static String _buildBaseKey(String documentId, String type) {
    return '${_key}_${documentId.trim()}_${type.trim()}';
  }

  static String _buildLegacyBaseKey(String documentId, String type) {
    return r'${_key}_${documentId.trim()}_${type.trim()}';
  }

  static String _buildScopedKey(String documentId, String type) {
    return UserScopedStorage.key(_buildBaseKey(documentId, type));
  }

  static String _buildLegacyScopedKey(String documentId, String type) {
    return UserScopedStorage.key(_buildLegacyBaseKey(documentId, type));
  }

  static Future<void> saveResult(StudyResult result) async {
    if (!result.isValid) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _buildScopedKey(result.documentId, result.type),
      jsonEncode(result.toJson()),
    );

    if (result.type == 'question_bank') {
      final current = prefs.getStringList(EducatorSyncService.scopedKey(
              EducatorSyncService.questionBanksKey)) ??
          [];
      final asJson = result.toJson();
      asJson['id'] = result.documentId;
      asJson['documentId'] = result.documentId;

      final updated = current
          .map((item) {
            try {
              final decoded = jsonDecode(item);
              if (decoded is Map &&
                  decoded['documentId']?.toString() == result.documentId) {
                return null;
              }
            } catch (_) {}
            return item;
          })
          .whereType<String>()
          .toList();

      updated.insert(0, jsonEncode(asJson));
      await prefs.setStringList(
          EducatorSyncService.scopedKey(EducatorSyncService.questionBanksKey),
          updated);
      await EducatorSyncService.syncAfterLocalWrite();
    }
  }

  static Future<StudyResult?> getResult({
    required String documentId,
    required String type,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(
          _buildScopedKey(documentId, type),
        ) ??
        prefs.getString(
          _buildLegacyScopedKey(documentId, type),
        );

    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is Map<String, dynamic>) {
        final result = StudyResult.fromJson(decoded);
        return result.isValid &&
                result.documentId == documentId &&
                result.type == type
            ? result
            : null;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<StudyResult>> getResultsByType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final suffix = '_${type.trim()}_${UserScopedStorage.currentUserScope}';
    final legacySuffix = '_${UserScopedStorage.currentUserScope}';
    final prefix = '${_key}_';
    final legacyPrefix = r'${_key}_';
    final results = <StudyResult>[];

    for (final key in prefs.getKeys()) {
      final isCurrentKey = key.startsWith(prefix) && key.endsWith(suffix);
      final isLegacyKey =
          key.startsWith(legacyPrefix) && key.endsWith(legacySuffix);

      if (!isCurrentKey && !isLegacyKey) continue;

      final raw = prefs.getString(key);
      if (raw == null || raw.trim().isEmpty) continue;

      try {
        final decoded = jsonDecode(raw);
        final map = decoded is Map<String, dynamic>
            ? decoded
            : decoded is Map
                ? Map<String, dynamic>.from(decoded)
                : null;
        if (map == null) continue;

        final result = StudyResult.fromJson(map);
        if (result.isValid && result.type == type) {
          results.add(result);
        }
      } catch (_) {}
    }

    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }

  static Future<void> deleteResult({
    required String documentId,
    required String type,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(
      _buildScopedKey(documentId, type),
    );
    await prefs.remove(
      _buildLegacyScopedKey(documentId, type),
    );

    if (type == 'question_bank') {
      final key = EducatorSyncService.scopedKey(
        EducatorSyncService.questionBanksKey,
      );
      final current = prefs.getStringList(key) ?? const [];
      final updated = current.where((item) {
        try {
          final decoded = jsonDecode(item);
          if (decoded is Map) {
            final id = decoded['documentId'] ?? decoded['id'];
            return id?.toString() != documentId;
          }
        } catch (_) {}
        return true;
      }).toList();
      await prefs.setStringList(key, updated);
      await EducatorSyncService.syncAfterLocalWrite();
    }
  }
}
