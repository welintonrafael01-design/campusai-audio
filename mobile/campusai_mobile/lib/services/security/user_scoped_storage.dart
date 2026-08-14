import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserScopedStorage {
  const UserScopedStorage._();

  static String? _debugUserScopeOverride;

  static String get currentUserScope {
    final override = _debugUserScopeOverride?.trim();
    if (override != null && override.isNotEmpty) return override;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final id = user?.id.trim();
      if (id != null && id.isNotEmpty) return id;

      final email = user?.email?.trim().toLowerCase();
      if (email != null && email.isNotEmpty) {
        return email.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
      }
    } catch (_) {}

    return 'guest';
  }

  static String key(String baseKey) => '${baseKey}_$currentUserScope';

  static Future<String?> getString(String baseKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key(baseKey));
  }

  static Future<void> setString(String baseKey, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key(baseKey), value);
  }

  static Future<List<String>> getStringList(String baseKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key(baseKey)) ?? [];
  }

  static Future<void> setStringList(String baseKey, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key(baseKey), value);
  }

  static Future<void> remove(String baseKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key(baseKey));
  }

  static void debugSetUserScopeForTesting(String? scope) {
    _debugUserScopeOverride = scope;
  }
}
