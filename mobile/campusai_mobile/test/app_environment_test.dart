import 'package:campusai_mobile/config/app_environment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppEnvironment release safety', () {
    test('requires API_BASE_URL in release', () {
      expect(
        () => AppEnvironment.resolveApiBaseUrl(
          configuredValue: '',
          isWeb: false,
          isRelease: true,
        ),
        throwsStateError,
      );
    });

    test('rejects local and cleartext release origins', () {
      for (final value in [
        'http://api.studybook.example',
        'http://127.0.0.1:8000',
        'https://localhost:8000',
        'https://10.0.2.2:8000',
        'https://release-validation.invalid',
        'https://example.com/api',
      ]) {
        expect(
          () => AppEnvironment.resolveApiBaseUrl(
            configuredValue: value,
            isWeb: false,
            isRelease: true,
          ),
          throwsStateError,
          reason: value,
        );
      }
    });

    test('accepts and normalizes a production HTTPS origin', () {
      expect(
        AppEnvironment.resolveApiBaseUrl(
          configuredValue: 'https://api.studybook.example/',
          isWeb: false,
          isRelease: true,
        ),
        'https://api.studybook.example',
      );
    });

    test('keeps local defaults for non-release development', () {
      expect(
        AppEnvironment.resolveApiBaseUrl(
          configuredValue: '',
          isWeb: true,
          isRelease: false,
        ),
        'http://127.0.0.1:8000',
      );
      expect(
        AppEnvironment.resolveApiBaseUrl(
          configuredValue: '',
          isWeb: false,
          isRelease: false,
        ),
        'http://10.0.2.2:8000',
      );
    });
  });

  group('AppEnvironment public URL safety', () {
    test('prefers PRIVACY_URL while preserving the legacy key', () {
      expect(
        AppEnvironment.preferredPublicUrl(
          primaryValue: 'https://studybookai.com/privacy',
          legacyValue: 'https://legacy.example/privacy',
        ),
        'https://studybookai.com/privacy',
      );
      expect(
        AppEnvironment.preferredPublicUrl(
          primaryValue: '',
          legacyValue: 'https://legacy.example/privacy',
        ),
        'https://legacy.example/privacy',
      );
    });

    test('allows an absent optional privacy URL', () {
      expect(AppEnvironment.resolveOptionalHttpsUrl(''), isNull);
    });

    test('accepts a production HTTPS privacy URL', () {
      expect(
        AppEnvironment.resolveOptionalHttpsUrl(
          'https://studybookai.com/privacy',
        ),
        Uri.parse('https://studybookai.com/privacy'),
      );
    });

    test('rejects local or cleartext privacy URLs', () {
      for (final value in <String>[
        'http://studybook.example/privacy',
        'https://localhost/privacy',
        'https://release-validation.invalid/privacy',
      ]) {
        expect(
          () => AppEnvironment.resolveOptionalHttpsUrl(value),
          throwsStateError,
        );
      }
    });
  });
}
