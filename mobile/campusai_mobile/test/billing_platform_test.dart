import 'package:campusai_mobile/config/app_plans.dart';
import 'package:campusai_mobile/services/billing/billing_platform.dart';
import 'package:campusai_mobile/services/billing/google_play_billing_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android uses Google Play and never the Stripe web channel', () {
    expect(
      BillingPlatform.select(isWeb: false, platform: TargetPlatform.android),
      BillingChannel.googlePlay,
    );
  });

  test('Web preserves Stripe checkout', () {
    expect(
      BillingPlatform.select(isWeb: true, platform: TargetPlatform.android),
      BillingChannel.stripeWeb,
    );
  });

  test('Play product mapping fails closed without configured product IDs', () {
    expect(
      GooglePlayProductConfig.productIdForPlan(
        CampusPlan.student,
        studentId: '',
      ),
      isNull,
    );
    expect(
      GooglePlayProductConfig.productIdForPlan(
        CampusPlan.teacher,
        teacherId: 'REQUIRED_PLAY_CONSOLE_PRODUCT_ID',
      ),
      isNull,
    );
  });

  test('Play product mapping supports only configured consumer plans', () {
    expect(
      GooglePlayProductConfig.productIdForPlan(
        CampusPlan.student,
        studentId: 'student-pro-product',
      ),
      'student-pro-product',
    );
    expect(
      GooglePlayProductConfig.productIdForPlan(
        CampusPlan.institution,
        studentId: 'student-pro-product',
        teacherId: 'teacher-pro-product',
      ),
      isNull,
    );
  });
}
