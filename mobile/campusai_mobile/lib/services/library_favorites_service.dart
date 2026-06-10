import 'package:shared_preferences/shared_preferences.dart';

class LibraryFavoritesService {
  static const String _key = 'studybook_library_favorites';

  const LibraryFavoritesService();

  Future<Set<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).toSet();
  }

  Future<bool> isFavorite(String documentId) async {
    final favorites = await getFavorites();
    return favorites.contains(documentId);
  }

  Future<void> toggleFavorite(String documentId) async {
    final cleanDocumentId = documentId.trim();

    if (cleanDocumentId.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();

    if (favorites.contains(cleanDocumentId)) {
      favorites.remove(cleanDocumentId);
    } else {
      favorites.add(cleanDocumentId);
    }

    await prefs.setStringList(_key, favorites.toList());
  }

  Future<void> removeFavorite(String documentId) async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await getFavorites();

    favorites.remove(documentId);

    await prefs.setStringList(_key, favorites.toList());
  }
}
