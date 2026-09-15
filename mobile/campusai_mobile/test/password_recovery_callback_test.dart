import 'package:campusai_mobile/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const callbackCode = 'redacted-test-code';

  test('recognizes the hash-based production recovery route', () {
    final uri = Uri.parse(
      'https://app.example.test/?code=$callbackCode#/reset-password',
    );

    expect(PasswordRecoveryCallback.isRecoveryRoute(uri), isTrue);
  });

  test('exchanges a recovery code before enabling password update', () async {
    final uri = Uri.parse(
      'https://app.example.test/?code=$callbackCode#/reset-password',
    );
    var exchanges = 0;

    final status = await PasswordRecoveryCallback.resolve(
      uri: uri,
      exchangeCode: (code) async {
        exchanges++;
        expect(code, callbackCode);
        return true;
      },
    );

    expect(status, PasswordRecoveryStatus.ready);
    expect(exchanges, 1);
  });

  test('rejects a recovery route without an auth code', () async {
    final status = await PasswordRecoveryCallback.resolve(
      uri: Uri.parse('https://app.example.test/#/reset-password'),
      exchangeCode: (_) async => true,
    );

    expect(status, PasswordRecoveryStatus.invalid);
  });

  test('rejects a callback when the PKCE exchange fails', () async {
    final status = await PasswordRecoveryCallback.resolve(
      uri: Uri.parse(
        'https://app.example.test/?code=$callbackCode#/reset-password',
      ),
      exchangeCode: (_) async => throw StateError('expired'),
    );

    expect(status, PasswordRecoveryStatus.invalid);
  });
}
