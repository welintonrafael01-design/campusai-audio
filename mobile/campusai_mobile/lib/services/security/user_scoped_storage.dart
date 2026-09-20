import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserScopedStorage {
  const UserScopedStorage._();

  static String? _debugUserScopeOverride;
  static final Object _asyncScopeKey = Object();

  static String get currentAuthenticatedUserId {
    final override = _debugUserScopeOverride?.trim();
    if (override != null && override.isNotEmpty) return override;

    try {
      return Supabase.instance.client.auth.currentUser?.id.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  static String get currentUserScope {
    final asyncScope = Zone.current[_asyncScopeKey]?.toString().trim();
    if (asyncScope != null && asyncScope.isNotEmpty) return asyncScope;

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

  static T runWithUserScope<T>(String userScope, T Function() action) {
    final scope = userScope.trim();
    if (scope.isEmpty || scope == 'guest') {
      throw ArgumentError.value(userScope, 'userScope');
    }
    return runZoned(action, zoneValues: {_asyncScopeKey: scope});
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

  static Future<int> clearUserScope(String userScope) async {
    final cleanScope = userScope.trim();
    if (cleanScope.isEmpty || cleanScope == 'guest') return 0;

    final prefs = await SharedPreferences.getInstance();
    final suffix = '_$cleanScope';
    final keys = prefs.getKeys().where((key) => key.endsWith(suffix)).toList();

    for (final key in keys) {
      await prefs.remove(key);
    }

    return keys.length;
  }

  static void debugSetUserScopeForTesting(String? scope) {
    _debugUserScopeOverride = scope;
  }
}
