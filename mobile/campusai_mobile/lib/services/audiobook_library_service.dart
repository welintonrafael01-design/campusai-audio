import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/audiobook_history.dart';

class AudiobookLibraryService {
  static const String _key = 'studybook_audiobook_library';
  static const int _maxItems = 50;

  const AudiobookLibraryService();

  Future<List<AudiobookHistory>> getAudiobooks() async {
    final prefs = await SharedPreferences.getInstance();
    final rawData = prefs.getStringList(_key) ?? [];

    return rawData
        .map(_decode)
        .whereType<AudiobookHistory>()
        .where((item) => item.isValid)
        .toList();
  }

  Future<AudiobookHistory?> getByDocumentId(String documentId) async {
    final cleanDocumentId = documentId.trim();

    if (cleanDocumentId.isEmpty) return null;

    final items = await getAudiobooks();

    for (final item in items) {
      if (item.documentId == cleanDocumentId) {
        return item;
      }
    }

    return null;
  }

  Future<void> saveAudiobook(AudiobookHistory audiobook) async {
    if (!audiobook.isValid) return;

    final items = await getAudiobooks();

    items.removeWhere(
      (item) => item.documentId == audiobook.documentId,
    );

    items.insert(0, audiobook);

    await _save(items);
  }

  Future<void> deleteAudiobook(String documentId) async {
    final items = await getAudiobooks();

    items.removeWhere(
      (item) => item.documentId == documentId,
    );

    await _save(items);
  }

  Future<int> totalAudiobooks() async {
    final items = await getAudiobooks();
    return items.length;
  }

  Future<void> _save(List<AudiobookHistory> items) async {
    final prefs = await SharedPreferences.getInstance();

    final encoded = items
        .where((item) => item.isValid)
        .take(_maxItems)
        .map((item) => jsonEncode(item.toJson()))
        .toList();

    await prefs.setStringList(_key, encoded);
  }

  AudiobookHistory? _decode(String rawData) {
    try {
      final decoded = jsonDecode(rawData);

      if (decoded is Map<String, dynamic>) {
        return AudiobookHistory.fromJson(decoded);
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
