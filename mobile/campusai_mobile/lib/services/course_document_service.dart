import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'security/user_scoped_storage.dart';
import 'educator_sync_service.dart';

class CourseDocument {
  final String courseId;
  final String documentId;
  final String fileName;
  final String uploadedAt;

  const CourseDocument({
    required this.courseId,
    required this.documentId,
    required this.fileName,
    required this.uploadedAt,
  });

  Map<String, dynamic> toJson() => {
        'courseId': courseId,
        'documentId': documentId,
        'fileName': fileName,
        'uploadedAt': uploadedAt,
      };

  factory CourseDocument.fromJson(Map<String, dynamic> json) {
    return CourseDocument(
      courseId: json['courseId']?.toString() ?? '',
      documentId: json['documentId']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? '',
      uploadedAt: json['uploadedAt']?.toString() ?? '',
    );
  }
}

class CourseDocumentService {
  static const String _key = EducatorSyncService.courseDocumentsKey;
  static String get _scopedKey => UserScopedStorage.key(_key);

  static Future<List<CourseDocument>> getDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_scopedKey) ?? [];

    return raw
        .map((item) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is Map<String, dynamic>) {
              return CourseDocument.fromJson(decoded);
            }
            if (decoded is Map) {
              return CourseDocument.fromJson(
                  Map<String, dynamic>.from(decoded));
            }
          } catch (_) {}
          return null;
        })
        .whereType<CourseDocument>()
        .where((item) => item.courseId.isNotEmpty && item.documentId.isNotEmpty)
        .toList();
  }

  static Future<CourseDocument?> getDocumentForCourse(String courseId) async {
    final documents = await getDocuments();
    return documents
        .where((item) => item.courseId == courseId)
        .cast<CourseDocument?>()
        .firstOrNull;
  }

  static Future<void> saveDocument(CourseDocument document) async {
    final documents = await getDocuments();

    documents.removeWhere((item) => item.courseId == document.courseId);
    documents.insert(0, document);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _scopedKey,
      documents.map((item) => jsonEncode(item.toJson())).toList(),
    );
    await EducatorSyncService.syncAfterLocalWrite();
  }

  static Future<void> deleteDocumentForCourse(String courseId) async {
    final documents = await getDocuments();
    documents.removeWhere((item) => item.courseId == courseId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _scopedKey,
      documents.map((item) => jsonEncode(item.toJson())).toList(),
    );
    await EducatorSyncService.syncAfterLocalWrite();
  }
}
