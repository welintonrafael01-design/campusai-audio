import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_message_model.dart';

class ChatHistoryService {
  static const String _chatPrefix = 'chat_history_';

  // =========================
  // SAVE CHAT
  // =========================

  static Future<void> saveMessages({
    required String documentId,
    required List<ChatMessageModel> messages,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = messages.map((message) {
      return {
        'text': message.text,
        'isUser': message.isUser,
        'createdAt': message.createdAt.toIso8601String(),
      };
    }).toList();

    await prefs.setString(
      '$_chatPrefix$documentId',
      jsonEncode(encoded),
    );
  }

  // =========================
  // LOAD CHAT
  // =========================

  static Future<List<ChatMessageModel>> loadMessages({
    required String documentId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(
      '$_chatPrefix$documentId',
    );

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;

      return decoded.map((item) {
        final map = item as Map<String, dynamic>;

        return ChatMessageModel(
          text: map['text'] ?? '',
          isUser: map['isUser'] ?? false,
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

  // =========================
  // CLEAR CHAT
  // =========================

  static Future<void> clearChat({
    required String documentId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(
      '$_chatPrefix$documentId',
    );
  }
}
