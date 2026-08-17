import 'dart:convert';

import '../models/recent_document_model.dart';
import 'security/user_scoped_storage.dart';

class RecentDocumentsService {
  static const String _key = 'recent_documents';
  static const int _maxItems = 20;

  static Future<List<RecentDocumentModel>> getDocuments() async {
    final raw = await UserScopedStorage.getString(_key);

    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;

      return decoded
          .map((item) => RecentDocumentModel.fromJson(
                item as Map<String, dynamic>,
              ))
          .where((item) => item.documentId.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveDocument(RecentDocumentModel document) async {
    final current = await getDocuments();

    final updated = [
      document,
      ...current.where(
        (item) => item.documentId != document.documentId,
      ),
    ].take(_maxItems).toList();

    final encoded = updated.map((item) => item.toJson()).toList();

    await UserScopedStorage.setString(
      _key,
      jsonEncode(encoded),
    );
  }

  static Future<void> removeDocument(String documentId) async {
    final current = await getDocuments();

    final updated =
        current.where((item) => item.documentId != documentId).toList();

    final encoded = updated.map((item) => item.toJson()).toList();

    await UserScopedStorage.setString(
      _key,
      jsonEncode(encoded),
    );
  }

  static Future<void> clearDocuments() async {
    await UserScopedStorage.remove(_key);
  }
}
