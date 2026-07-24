import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  LocalStorageService._();

  static SharedPreferences? _preferences;

  static Future<void> initialize() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  static SharedPreferences get preferences {
    final instance = _preferences;

    if (instance == null) {
      throw StateError(
        'LocalStorageService no fue inicializado. '
        'Ejecuta LocalStorageService.initialize() antes de runApp().',
      );
    }

    return instance;
  }

  static String? getString(String key) {
    return preferences.getString(key);
  }

  static void setString(String key, String value) {
    unawaited(preferences.setString(key, value));
  }

  static void remove(String key) {
    unawaited(preferences.remove(key));
  }
}
