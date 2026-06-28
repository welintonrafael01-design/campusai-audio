import 'dart:convert';

import '../models/chat_message_model.dart';
import 'security/user_scoped_storage.dart';

class ChatHistoryService {
  static String _keyForDocument(String documentId) {
    return '\${_chatPrefix}_\${documentId.trim()}';
  }

  static Future<void> saveMessages({
    required String documentId,
    required List<ChatMessageModel> messages,
  }) async {
    final cleanDocumentId = documentId.trim();
    if (cleanDocumentId.isEmpty) return;

    final encoded = messages.map((message) {
      return message.toMap();
    }).toList();

    await UserScopedStorage.setString(
      _keyForDocument(cleanDocumentId),
      jsonEncode(encoded),
    );
  }

  static Future<List<ChatMessageModel>> loadMessages({
    required String documentId,
  }) async {
    final cleanDocumentId = documentId.trim();
    if (cleanDocumentId.isEmpty) return [];

    final raw = await UserScopedStorage.getString(
      _keyForDocument(cleanDocumentId),
    );

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;

      return decoded.map((item) {
        final map = item as Map<String, dynamic>;

        final rawCitations = map['citations'];

        final citations = rawCitations is List
            ? rawCitations
                .whereType<Map>()
                .map(
                  (citation) => ChatCitationModel.fromMap(
                    Map<String, dynamic>.from(citation),
                  ),
                )
                .toList()
            : <ChatCitationModel>[];

        return ChatMessageModel(
          text: map['text'] ?? '',
          isUser: map['isUser'] ?? false,
          isStreaming: map['isStreaming'] ?? false,
          citations: citations,
          createdAt: DateTime.tryParse(
                map['createdAt'] ?? '',
              ) ??
              DateTime.now(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clearChat({
    required String documentId,
  }) async {
    final cleanDocumentId = documentId.trim();
    if (cleanDocumentId.isEmpty) return;

    await UserScopedStorage.remove(
      _keyForDocument(cleanDocumentId),
    );
  }
}
