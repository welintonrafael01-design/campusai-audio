import 'package:flutter/foundation.dart';

class AppEnvironment {
  const AppEnvironment._();

  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get apiBaseUrl {
    final configured = _configuredApiBaseUrl.trim();

    if (configured.isNotEmpty) {
      return _withoutTrailingSlash(configured);
    }

    return kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';
  }

  static bool get isApiBaseUrlConfigured =>
      _configuredApiBaseUrl.trim().isNotEmpty;

  static String _withoutTrailingSlash(String value) {
    var clean = value.trim();

    while (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }

    return clean;
  }
}
