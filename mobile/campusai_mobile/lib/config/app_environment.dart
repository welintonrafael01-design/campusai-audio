import 'package:flutter/foundation.dart';

class AppEnvironment {
  const AppEnvironment._();

  static const String _configuredApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String _configuredPrivacyUrl = String.fromEnvironment(
    'PRIVACY_URL',
  );
  static const String _configuredPrivacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
  );

  static String get apiBaseUrl {
    return resolveApiBaseUrl(
      configuredValue: _configuredApiBaseUrl,
      isWeb: kIsWeb,
      isRelease: kReleaseMode,
    );
  }

  static String resolveApiBaseUrl({
    required String configuredValue,
    required bool isWeb,
    required bool isRelease,
  }) {
    final configured = configuredValue.trim();

    if (configured.isNotEmpty) {
      final normalized = _withoutTrailingSlash(configured);

      if (isRelease) {
        _validateReleaseApiBaseUrl(normalized);
      }

      return normalized;
    }

    if (isRelease) {
      throw StateError(
        'API_BASE_URL debe configurarse para una build release.',
      );
    }

    return isWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000';
  }

  static bool get isApiBaseUrlConfigured =>
      _configuredApiBaseUrl.trim().isNotEmpty;

  static Uri? get privacyPolicyUri {
    return resolveOptionalHttpsUrl(
      preferredPublicUrl(
        primaryValue: _configuredPrivacyUrl,
        legacyValue: _configuredPrivacyPolicyUrl,
      ),
    );
  }

  static String preferredPublicUrl({
    required String primaryValue,
    required String legacyValue,
  }) {
    final primary = primaryValue.trim();
    return primary.isNotEmpty ? primary : legacyValue.trim();
  }

  static Uri? resolveOptionalHttpsUrl(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return null;

    final uri = Uri.tryParse(clean);
    final host = uri?.host.toLowerCase() ?? '';
    final isBlockedHost = _isBlockedPublicHost(host);

    if (uri == null ||
        uri.scheme != 'https' ||
        host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty ||
        isBlockedHost) {
      throw StateError('La URL publica debe ser HTTPS y no local.');
    }

    return uri;
  }

  static String _withoutTrailingSlash(String value) {
    var clean = value.trim();

    while (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }

    return clean;
  }

  static void _validateReleaseApiBaseUrl(String value) {
    final uri = Uri.tryParse(value);
    final host = uri?.host.toLowerCase() ?? '';
    final isBlockedHost = _isBlockedPublicHost(host);

    if (uri == null ||
        uri.scheme != 'https' ||
        host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty ||
        isBlockedHost) {
      throw StateError(
        'API_BASE_URL de release debe ser un origen HTTPS no local.',
      );
    }
  }

  static bool _isBlockedPublicHost(String host) {
    return host == 'localhost' ||
        host == '127.0.0.1' ||
        host == '::1' ||
        host == '10.0.2.2' ||
        host.endsWith('.invalid');
  }
}
