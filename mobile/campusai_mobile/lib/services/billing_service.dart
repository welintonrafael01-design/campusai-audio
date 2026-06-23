import 'dart:convert';
import 'dart:html' as html;

import 'package:http/http.dart' as http;

import '../config/app_plans.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'plan_guard_service.dart';

class BillingService {
  const BillingService();

  Future<void> startCheckout(CampusPlan plan) async {
    final planCode = planCodeFromCampusPlan(plan);

    if (plan == CampusPlan.free) {
      throw Exception('El plan Free no requiere checkout.');
    }

    if (!AuthService.isLoggedIn) {
      throw Exception('Debes iniciar sesión para actualizar tu plan.');
    }

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/billing/create-checkout-session'),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders,
      },
      body: jsonEncode({
        'plan': planCode,
      }),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      final detail = decoded is Map<String, dynamic>
          ? decoded['detail']?.toString()
          : null;

      throw Exception(detail ?? 'No se pudo iniciar el checkout.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Respuesta inválida del servidor.');
    }

    final checkoutUrl = decoded['checkout_url']?.toString();

    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      throw Exception('El servidor no devolvió la URL de checkout.');
    }

    html.window.location.href = checkoutUrl;
  }

  Future<Map<String, dynamic>> refreshSubscriptionFromServer() async {
    if (!AuthService.isLoggedIn) {
      throw Exception('Debes iniciar sesión para sincronizar tu suscripción.');
    }

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/billing/subscription/me'),
      headers: AuthService.authHeaders,
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      final detail = decoded is Map<String, dynamic>
          ? decoded['detail']?.toString()
          : null;

      throw Exception(detail ?? 'No se pudo sincronizar la suscripción.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Respuesta inválida del servidor.');
    }

    final plan = planFromCode(decoded['plan']?.toString());
    final status = decoded['subscription_status']?.toString() ?? 'unknown';

    const PlanGuardService().saveCurrentPlan(
      plan,
      source: decoded['source']?.toString() ?? 'supabase',
      subscriptionStatus: status,
    );

    return decoded;
  }

  Future<void> openCustomerPortal() async {
    if (!AuthService.isLoggedIn) {
      throw Exception('Debes iniciar sesión para administrar tu suscripción.');
    }

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/billing/create-customer-portal-session'),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders,
      },
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      final detail = decoded is Map<String, dynamic>
          ? decoded['detail']?.toString()
          : null;

      throw Exception(detail ?? 'No se pudo abrir el portal de cliente.');
    }

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Respuesta inválida del servidor.');
    }

    final portalUrl = decoded['portal_url']?.toString();

    if (portalUrl == null || portalUrl.isEmpty) {
      throw Exception('El servidor no devolvió la URL del portal.');
    }

    html.window.location.href = portalUrl;
  }
}
