import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_plans.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'billing/billing_platform.dart';
import 'billing/google_play_billing_provider.dart';
import 'billing/stripe_billing_provider.dart';
import 'subscription_service.dart';

class BillingService {
  const BillingService();

  Future<void> initialize() async {
    if (BillingPlatform.current == BillingChannel.googlePlay) {
      await GooglePlayBillingProvider.instance.initialize();
    }
  }

  Future<void> startCheckout(CampusPlan plan) async {
    if (plan == CampusPlan.free) {
      throw Exception('El plan Free no requiere checkout.');
    }
    if (plan == CampusPlan.institution) {
      throw Exception(
        'El plan Institution se gestiona mediante un acuerdo institucional.',
      );
    }
    if (!AuthService.isLoggedIn) {
      throw Exception('Debes iniciar sesión para actualizar tu plan.');
    }

    switch (BillingPlatform.current) {
      case BillingChannel.stripeWeb:
        return const StripeBillingProvider().startCheckout(plan);
      case BillingChannel.googlePlay:
        return GooglePlayBillingProvider.instance.startCheckout(plan);
      case BillingChannel.unsupported:
        throw Exception(
          'Las compras no están disponibles en esta plataforma. Puedes gestionar tu plan desde la versión web.',
        );
    }
  }

  Future<void> restorePurchases() async {
    if (BillingPlatform.current != BillingChannel.googlePlay) {
      throw Exception(
        'La restauración de Google Play solo está disponible en Android.',
      );
    }
    await GooglePlayBillingProvider.instance.restorePurchases();
  }

  Future<Map<String, dynamic>> refreshSubscriptionFromServer() async {
    if (!AuthService.isLoggedIn) {
      throw Exception('Debes iniciar sesión para sincronizar tu suscripción.');
    }

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/billing/subscription/me'),
      headers: AuthService.authHeaders,
    );
    final decoded = _decodeObject(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        decoded['detail']?.toString() ??
            'No se pudo sincronizar la suscripción.',
      );
    }

    const SubscriptionService().cacheSubscriptionResponse(decoded);
    return decoded;
  }

  Future<void> openCustomerPortal() async {
    if (!AuthService.isLoggedIn) {
      throw Exception('Debes iniciar sesión para administrar tu suscripción.');
    }
    if (BillingPlatform.current != BillingChannel.stripeWeb) {
      throw Exception(
        'Gestiona las suscripciones de Google Play desde Play Store. Las suscripciones web se administran desde StudyBook AI Web.',
      );
    }
    await const StripeBillingProvider().openCustomerPortal();
  }

  Map<String, dynamic> _decodeObject(String body) {
    try {
      final value = jsonDecode(body);
      return value is Map<String, dynamic> ? value : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
