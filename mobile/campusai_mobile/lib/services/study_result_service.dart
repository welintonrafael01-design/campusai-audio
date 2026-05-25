import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/study_result.dart';

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