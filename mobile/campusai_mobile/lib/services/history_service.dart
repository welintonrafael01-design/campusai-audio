import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/document_history.dart';

class HistoryService {
  static const String _historyKey = 'document_history';
  static const String _activeDocumentKey = 'active_document';

  static String get _currentUserScope {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null && userId.trim().isNotEmpty) {
        return userId.trim();
      }
    } catch (_) {}

    return 'anonymous';
  }

  static String get _scopedHistoryKey => '${_historyKey}_$_currentUserScope';
  static String get _scopedActiveDocumentKey =>
      '${_activeDocumentKey}_$_currentUserScope';
  static const int _maxItems = 20;

  static Future<List<DocumentHistory>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getStringList(_scopedHistoryKey) ?? [];

    return rawData
        .map(_decodeDocument)
        .whereType<DocumentHistory>()
        .where((document) => document.isValid)
        .toList();
  }

  static Future<void> saveDocument(DocumentHistory document) async {
    if (!document.isValid) return;

    final history = await getHistory();

    history.removeWhere(
      (item) =>
          item.documentId == document.documentId ||
          item.fileName.toLowerCase() == document.fileName.toLowerCase(),
    );

    history.insert(0, document);

    await _saveHistory(history);
    await saveActiveDocument(document);
  }

  static Future<void> saveActiveDocument(DocumentHistory document) async {
    if (!document.isValid) return;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _scopedActiveDocumentKey,
      jsonEncode(document.toJson()),
    );
  }

  static Future<DocumentHistory?> getActiveDocument() async {
    final prefs = await SharedPreferences.getInstance();
    final rawDocument = prefs.getString(_activeDocumentKey);

    if (rawDocument == null || rawDocument.trim().isEmpty) {
      return null;
    }

    final document = _decodeDocument(rawDocument);

    if (document == null || !document.isValid) {
      return null;
    }

    return document;
  }

  static Future<void> deleteDocument(int index) async {
    final history = await getHistory();

    if (index < 0 || index >= history.length) return;

    final removedDocument = history.removeAt(index);

    await _saveHistory(history);

    final activeDocument = await getActiveDocument();

    if (activeDocument?.documentId == removedDocument.documentId) {
      if (history.isNotEmpty) {
        await saveActiveDocument(history.first);
      } else {
        await clearActiveDocument();
      }
    }
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_scopedHistoryKey);
    await prefs.remove(_scopedActiveDocumentKey);
  }

  static Future<void> clearActiveDocument() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_scopedActiveDocumentKey);
  }

  static Future<bool> hasDocuments() async {
    final history = await getHistory();
    return history.isNotEmpty;
  }

  static Future<int> totalDocuments() async {
    final history = await getHistory();
    return history.length;
  }

  static Future<void> _saveHistory(List<DocumentHistory> history) async {
    final prefs = await SharedPreferences.getInstance();

    final limitedHistory = history
        .where((item) => item.isValid)
        .take(_maxItems)
        .map((item) => jsonEncode(item.toJson()))
        .toList();

    await prefs.setStringList(_scopedHistoryKey, limitedHistory);
  }

  static DocumentHistory? _decodeDocument(String rawData) {
    try {
      final decoded = jsonDecode(rawData);

      if (decoded is Map<String, dynamic>) {
        return DocumentHistory.fromJson(decoded);
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}