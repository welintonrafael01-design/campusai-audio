import 'package:flutter/foundation.dart';

enum BillingChannel {
  stripeWeb,
  googlePlay,
  unsupported,
}

class BillingPlatform {
  const BillingPlatform._();

  static BillingChannel get current => select(
        isWeb: kIsWeb,
        platform: defaultTargetPlatform,
      );

  static BillingChannel select({
    required bool isWeb,
    required TargetPlatform platform,
  }) {
    if (isWeb) return BillingChannel.stripeWeb;
    if (platform == TargetPlatform.android) return BillingChannel.googlePlay;
    return BillingChannel.unsupported;
  }
}
