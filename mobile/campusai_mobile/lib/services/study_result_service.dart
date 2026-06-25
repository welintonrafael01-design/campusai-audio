import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/study_result.dart';
import 'educator_sync_service.dart';

class StudyResultService {
  static const String _key = 'study_results';

  static String _buildKey(String documentId, String type) {
    return '${_key}_${documentId}_$type';
  }

  static Future<void> saveResult(StudyResult result) async {
    if (!result.isValid) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _buildKey(result.documentId, result.type),
      jsonEncode(result.toJson()),
    );

    if (result.type == 'question_bank') {
      final current =
          prefs.getStringList(EducatorSyncService.questionBanksKey) ?? [];
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
      await prefs.setStringList(EducatorSyncService.questionBanksKey, updated);
      await EducatorSyncService.syncAfterLocalWrite();
    }
  }

  static Future<StudyResult?> getResult({
    required String documentId,
    required String type,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(
      _buildKey(documentId, type),
    );

    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is Map<String, dynamic>) {
        final result = StudyResult.fromJson(decoded);
        return result.isValid ? result : null;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<StudyResult>> getResultsByType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final suffix = '_$type';
    final results = <StudyResult>[];

    for (final key in prefs.getKeys()) {
      if (!key.startsWith('${_key}_') || !key.endsWith(suffix)) continue;

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
      _buildKey(documentId, type),
    );
  }
}
