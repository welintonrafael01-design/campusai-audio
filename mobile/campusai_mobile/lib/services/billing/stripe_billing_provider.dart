import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_plans.dart';
import '../../utils/safe_external_url.dart';
import '../api_service.dart';
import '../auth_service.dart';
import '../plan_guard_service.dart';

class StripeBillingProvider {
  const StripeBillingProvider();

  Future<void> startCheckout(CampusPlan plan) async {
    final planCode = planCodeFromCampusPlan(plan);
    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/billing/create-checkout-session'),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders,
      },
      body: jsonEncode({'plan': planCode}),
    );
    final decoded = _decodeObject(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        decoded['detail']?.toString() ?? 'No se pudo iniciar el checkout.',
      );
    }

    final checkoutUrl = decoded['checkout_url']?.toString();
    final uri = checkoutUrl == null ? null : Uri.tryParse(checkoutUrl);
    if (uri == null || !isSafeExternalUri(uri)) {
      throw StateError('El servidor devolvió una URL de pago no segura.');
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('No se pudo abrir el checkout de pago.');
    }
  }

  Future<void> openCustomerPortal() async {
    final response = await http.post(
      Uri.parse(
        '${ApiService.baseUrl}/billing/create-customer-portal-session',
      ),
      headers: {
        'Content-Type': 'application/json',
        ...AuthService.authHeaders,
      },
    );
    final decoded = _decodeObject(response.body);

    if (response.statusCode != 200) {
      throw Exception(
        decoded['detail']?.toString() ??
            'No se pudo abrir el portal de cliente.',
      );
    }

    final portalUrl = decoded['portal_url']?.toString();
    final uri = portalUrl == null ? null : Uri.tryParse(portalUrl);
    if (uri == null || !isSafeExternalUri(uri)) {
      throw StateError(
        'El servidor devolvió una URL de facturación no segura.',
      );
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('No se pudo abrir el portal de facturación.');
    }
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
