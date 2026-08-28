# Google Play Billing Setup

Status: `CLIENT AND SERVER CONTRACT READY - PLAY CONFIG REQUIRED`

StudyBook AI uses `in_app_purchase 3.3.0`. The resolved Android implementation
is `in_app_purchase_android 0.5.0`, compatible with the current Dart toolchain
and Android minSdk 24.

## Play Console Actions

1. Register `com.studybookai.app` in the authorized Play developer account.
2. Configure subscription products for Student Pro and Teacher Pro. Product IDs
   are controlled externally and must not be invented in source.
3. Supply public client values through `STUDENT_PRO_PLAY_PRODUCT_ID` and
   `TEACHER_PRO_PLAY_PRODUCT_ID`.
4. Supply matching backend values through
   `GOOGLE_PLAY_STUDENT_PRODUCT_ID` and `GOOGLE_PLAY_TEACHER_PRODUCT_ID`.
5. Configure Google Play Developer API credentials in backend-only secret
   storage and replace the unavailable verifier with the approved live
   implementation.
6. Verify package, product, token state, expiry and the obfuscated account ID
   before activating an entitlement.
7. Test purchased, pending, canceled, restored, expired and replayed purchases
   with Play license testers.

Android never opens Stripe Checkout. Existing server-side subscriptions remain
the entitlement authority and can be consumed after login. The current default
verifier returns `503` and grants nothing until external Play verification is
configured.

Official references:

- <https://pub.dev/packages/in_app_purchase>
- <https://developer.android.com/google/play/billing/integrate>
