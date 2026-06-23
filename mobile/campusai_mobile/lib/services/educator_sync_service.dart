import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'auth_service.dart';

class EducatorSyncService {
  const EducatorSyncService();

  static const String coursesKey = 'studybook_courses';
  static const String studentsKey = 'studybook_students_roster';
  static const String attendanceKey = 'studybook_attendance_entries';
  static const String gradebookKey = 'studybook_gradebook_entries';
  static const String questionBanksKey = 'studybook_question_banks';

  static Future<Map<String, dynamic>> getSnapshot() async {
    if (!AuthService.isLoggedIn) {
      return {};
    }

    final response = await http
        .get(
          Uri.parse('${ApiService.baseUrl}/educator/snapshot'),
          headers: AuthService.authHeaders,
        )
        .timeout(ApiService.timeoutDuration);

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar Educator desde Supabase.');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {};
  }

  static Future<void> pushLocalSnapshot() async {
    if (!AuthService.isLoggedIn) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    final payload = {
      'courses': _decodeStringList(
        prefs.getStringList(coursesKey) ?? const [],
      ),
      'students': _decodeStringList(
        prefs.getStringList(studentsKey) ?? const [],
      ),
      'attendance': _decodeStringList(
        prefs.getStringList(attendanceKey) ?? const [],
      ),
      'gradebook': _decodeStringList(
        prefs.getStringList(gradebookKey) ?? const [],
      ),
      'question_banks': _decodeStringList(
        prefs.getStringList(questionBanksKey) ?? const [],
      ),
    };

    await http
        .post(
          Uri.parse('${ApiService.baseUrl}/educator/sync'),
          headers: {
            'Content-Type': 'application/json',
            ...AuthService.authHeaders,
          },
          body: jsonEncode(payload),
        )
        .timeout(ApiService.timeoutDuration);
  }

  static Future<void> pullRemoteIntoLocalIfAvailable() async {
    try {
      final snapshot = await getSnapshot();
      final prefs = await SharedPreferences.getInstance();

      await _saveListIfNotEmpty(
        prefs: prefs,
        key: coursesKey,
        value: snapshot['courses'],
      );
      await _saveListIfNotEmpty(
        prefs: prefs,
        key: studentsKey,
        value: snapshot['students'],
      );
      await _saveListIfNotEmpty(
        prefs: prefs,
        key: attendanceKey,
        value: snapshot['attendance'],
      );
      await _saveListIfNotEmpty(
        prefs: prefs,
        key: gradebookKey,
        value: snapshot['gradebook'],
      );
      await _saveListIfNotEmpty(
        prefs: prefs,
        key: questionBanksKey,
        value: snapshot['question_banks'],
      );
    } catch (_) {
      // Modo seguro: si falla Supabase, se conserva SharedPreferences.
    }
  }

  static Future<void> syncAfterLocalWrite() async {
    try {
      await pushLocalSnapshot();
    } catch (_) {
      // Modo offline/fallback local.
    }
  }

  static List<Map<String, dynamic>> _decodeStringList(List<String> raw) {
    return raw
        .map((item) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is Map<String, dynamic>) return decoded;
            if (decoded is Map) return Map<String, dynamic>.from(decoded);
          } catch (_) {}
          return null;
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  static Future<void> _saveListIfNotEmpty({
    required SharedPreferences prefs,
    required String key,
    required dynamic value,
  }) async {
    if (value is! List || value.isEmpty) {
      return;
    }

    final encoded = value
        .whereType<Map>()
        .map((item) => jsonEncode(Map<String, dynamic>.from(item)))
        .toList();

    if (encoded.isNotEmpty) {
      await prefs.setStringList(key, encoded);
    }
  }
}
