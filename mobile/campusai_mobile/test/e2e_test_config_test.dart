import 'package:flutter_test/flutter_test.dart';

import '../integration_test/e2e_test_config.dart';

void main() {
  test('placeholder define values are not treated as configured credentials',
      () {
    expect(E2eTestConfig.isConfiguredValue(''), isFalse);
    expect(E2eTestConfig.isConfiguredValue('  '), isFalse);
    expect(E2eTestConfig.isConfiguredValue('<LOCAL_ONLY>'), isFalse);
    expect(E2eTestConfig.isConfiguredValue('<SUPABASE_ANON_KEY>'), isFalse);
    expect(E2eTestConfig.isConfiguredValue('student@example.com'), isTrue);
  });
}
