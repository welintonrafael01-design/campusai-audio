import 'package:campusai_mobile/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('server failures never expose raw provider details', () {
    final message = ApiService.safeErrorMessage(
      statusCode: 500,
      body: '{"detail":"provider-secret /srv/private/path"}',
    );

    expect(message, contains('no pudo completar'));
    expect(message, isNot(contains('provider-secret')));
    expect(message, isNot(contains('/srv/private/path')));
  });

  test('controlled client errors preserve short human guidance', () {
    final message = ApiService.safeErrorMessage(
      statusCode: 403,
      body: '{"detail":"Tu plan no incluye esta función."}',
    );

    expect(message, 'Tu plan no incluye esta función.');
  });
}
