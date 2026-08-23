import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'auth_service.dart';
import 'security/user_scoped_storage.dart';

class EducatorSyncService {
  const EducatorSyncService();

  static const String coursesKey = 'studybook_courses';
  static const String studentsKey = 'studybook_students_roster';
  static const String attendanceKey = 'studybook_attendance_entries';
  static const String gradebookKey = 'studybook_gradebook_entries';
  static const String questionBanksKey = 'studybook_question_banks';
  static const String courseDocumentsKey = 'studybook_course_documents';

  static String scopedKey(String key) => UserScopedStorage.key(key);

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

    final courses = _decodeStringList(
      prefs.getStringList(scopedKey(coursesKey)) ?? const [],
    );
    final courseDocuments = _decodeStringList(
      prefs.getStringList(scopedKey(courseDocumentsKey)) ?? const [],
    );

    final payload = {
      'courses': _coursesWithDocuments(courses, courseDocuments),
      'students': _decodeStringList(
        prefs.getStringList(scopedKey(studentsKey)) ?? const [],
      ),
      'attendance': _decodeStringList(
        prefs.getStringList(scopedKey(attendanceKey)) ?? const [],
      ),
      'gradebook': _decodeStringList(
        prefs.getStringList(scopedKey(gradebookKey)) ?? const [],
      ),
      'question_banks': _decodeStringList(
        prefs.getStringList(scopedKey(questionBanksKey)) ?? const [],
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
        key: scopedKey(coursesKey),
        value: snapshot['courses'],
      );
      await _saveCourseDocumentsFromCourses(
        prefs: prefs,
        value: snapshot['courses'],
      );
      await _saveListIfNotEmpty(
        prefs: prefs,
        key: scopedKey(studentsKey),
        value: snapshot['students'],
      );
      await _saveListIfNotEmpty(
        prefs: prefs,
        key: scopedKey(attendanceKey),
        value: snapshot['attendance'],
      );
      await _saveListIfNotEmpty(
        prefs: prefs,
        key: scopedKey(gradebookKey),
        value: snapshot['gradebook'],
      );
      await _saveListIfNotEmpty(
        prefs: prefs,
        key: scopedKey(questionBanksKey),
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

  static Future<List<Map<String, dynamic>>> getLocalQuestionBanks() async {
    final prefs = await SharedPreferences.getInstance();
    return _decodeStringList(
      prefs.getStringList(scopedKey(questionBanksKey)) ?? const [],
    );
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

  static List<Map<String, dynamic>> _coursesWithDocuments(
    List<Map<String, dynamic>> courses,
    List<Map<String, dynamic>> documents,
  ) {
    final byCourse = {
      for (final item in documents)
        (item['courseId'] ?? item['course_id'])?.toString() ?? '': item,
    };
    return courses.map((course) {
      final courseId = course['id']?.toString() ?? '';
      final document = byCourse[courseId];
      if (document == null) return course;
      return {
        ...course,
        'programDocumentId':
            document['documentId'] ?? document['document_id'] ?? '',
        'programFileName': document['fileName'] ?? document['file_name'] ?? '',
        'programUploadedAt':
            document['uploadedAt'] ?? document['uploaded_at'] ?? '',
      };
    }).toList();
  }

  static Future<void> _saveCourseDocumentsFromCourses({
    required SharedPreferences prefs,
    required dynamic value,
  }) async {
    if (value is! List) return;
    final documents = value.whereType<Map>().map((raw) {
      final course = Map<String, dynamic>.from(raw);
      final documentId =
          (course['programDocumentId'] ?? course['program_document_id'])
              ?.toString()
              .trim();
      if (documentId == null || documentId.isEmpty) return null;
      return {
        'courseId': course['id']?.toString() ?? '',
        'documentId': documentId,
        'fileName': (course['programFileName'] ??
                course['program_file_name'] ??
                'Programa de clase.pdf')
            .toString(),
        'uploadedAt':
            (course['programUploadedAt'] ?? course['program_uploaded_at'] ?? '')
                .toString(),
      };
    }).whereType<Map<String, dynamic>>();

    final encoded = documents.map(jsonEncode).toList();
    if (encoded.isNotEmpty) {
      await prefs.setStringList(scopedKey(courseDocumentsKey), encoded);
    }
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
