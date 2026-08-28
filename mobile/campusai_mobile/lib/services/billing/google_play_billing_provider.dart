import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../config/app_plans.dart';
import '../api_service.dart';
import '../auth_service.dart';
import '../subscription_service.dart';

class GooglePlayProductConfig {
  const GooglePlayProductConfig._();

  static const studentProductId = String.fromEnvironment(
    'STUDENT_PRO_PLAY_PRODUCT_ID',
  );
  static const teacherProductId = String.fromEnvironment(
    'TEACHER_PRO_PLAY_PRODUCT_ID',
  );

  static String? productIdForPlan(
    CampusPlan plan, {
    String studentId = studentProductId,
    String teacherId = teacherProductId,
  }) {
    final value = switch (plan) {
      CampusPlan.student => studentId,
      CampusPlan.teacher => teacherId,
      _ => '',
    };
    final clean = value.trim();
    if (clean.isEmpty || clean.startsWith('REQUIRED_')) return null;
    return clean;
  }
}

class GooglePlayBillingProvider {
  GooglePlayBillingProvider._();

  static final GooglePlayBillingProvider instance =
      GooglePlayBillingProvider._();

  final InAppPurchase _store = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  Future<void> initialize() async {
    _purchaseSubscription ??= _store.purchaseStream.listen(
      (purchases) => unawaited(_processPurchases(purchases)),
      onError: (_) {},
    );
  }

  Future<void> startCheckout(CampusPlan plan) async {
    final productId = GooglePlayProductConfig.productIdForPlan(plan);
    if (productId == null) {
      throw Exception(
        'Las suscripciones para este plan estarán disponibles a través de Google Play cuando la configuración esté completa.',
      );
    }
    if (!AuthService.isLoggedIn) {
      throw Exception('Debes iniciar sesión para actualizar tu plan.');
    }

    await initialize();
    if (!await _store.isAvailable()) {
      throw Exception('Google Play Billing no está disponible en este equipo.');
    }

    final response = await _store.queryProductDetails({productId});
    if (response.error != null || response.productDetails.isEmpty) {
      throw Exception(
        'Este producto todavía no está disponible en Google Play.',
      );
    }

    final product = response.productDetails.firstWhere(
      (item) => item.id == productId,
    );
    final started = await _store.buyNonConsumable(
      purchaseParam: PurchaseParam(
        productDetails: product,
        applicationUserName: AuthService.currentUser?.id,
      ),
    );
    if (!started) {
      throw Exception('No se pudo iniciar la compra en Google Play.');
    }
  }

  Future<void> restorePurchases() async {
    await initialize();
    if (!await _store.isAvailable()) {
      throw Exception('Google Play Billing no está disponible en este equipo.');
    }
    await _store.restorePurchases();
  }

  Future<void> _processPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status != PurchaseStatus.purchased &&
          purchase.status != PurchaseStatus.restored) {
        continue;
      }

      final verified = await _verifyWithServer(purchase);
      if (!verified) continue;

      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
      await const SubscriptionService().syncCurrentUserPlan();
    }
  }

  Future<bool> _verifyWithServer(PurchaseDetails purchase) async {
    final token = purchase.verificationData.serverVerificationData.trim();
    if (token.isEmpty) return false;

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/billing/google-play/verify-purchase'),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders,
      },
      body: jsonEncode({
        'product_id': purchase.productID,
        'purchase_token': token,
        'transaction_id': purchase.purchaseID,
      }),
    );
    if (response.statusCode != 200) return false;

    try {
      final decoded = jsonDecode(response.body);
      return decoded is Map<String, dynamic> && decoded['verified'] == true;
    } catch (_) {
      return false;
    }
  }
}
