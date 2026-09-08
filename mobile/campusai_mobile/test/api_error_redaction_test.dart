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

  test('structured entitlement errors preserve upgrade metadata', () {
    expect(
      () => ApiService.decodeBody(
        statusCode: 403,
        body: '''
          {"detail":{"code":"monthly_quota_exceeded","message":"Has utilizado tus 3 usos gratuitos de este mes.","required_plan":"student_pro","cta":{"label":"Ver Student Pro"}}}
        ''',
      ),
      throwsA(
        isA<ApiEntitlementException>()
            .having((error) => error.code, 'code', 'monthly_quota_exceeded')
            .having((error) => error.requiredPlan, 'plan', 'student_pro')
            .having((error) => error.ctaLabel, 'cta', 'Ver Student Pro'),
      ),
    );
  });

  test('quota operation identifiers are opaque, unique, and reusable', () {
    final first = ApiService.createOperationId();
    final second = ApiService.createOperationId();

    expect(first, isNot(second));
    expect(first, matches(RegExp(r'^[A-Za-z0-9._:-]{8,128}$')));
    expect(
      ApiService.resolveOperationId('retry-operation-0001'),
      'retry-operation-0001',
    );
  });
}
