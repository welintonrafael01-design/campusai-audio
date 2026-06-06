import 'dart:convert';
import 'dart:html' as html;

import 'package:http/http.dart' as http;

import '../config/app_plans.dart';
import 'api_service.dart';
import 'auth_service.dart';

class BillingService {
  const BillingService();

  Future<void> startCheckout(CampusPlan plan) async {
    final planCode = switch (plan) {
      CampusPlan.pro => 'pro',
      CampusPlan.educator => 'educator',
      CampusPlan.free => throw Exception(
          'El plan Free no requiere checkout.',
        ),
    };

    final user = AuthService.currentUser;

    if (user == null) {
      throw Exception(
        'Debes iniciar sesión para actualizar tu plan.',
      );
    }

    final response = await http.post(
      Uri.parse('${ApiService.baseUrl}/billing/create-checkout-session'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'plan': planCode,
        'user_id': user.id,
        'email': user.email,
      }),
    );

    final decoded = jsonDecode(response.body);

    if (response.statusCode != 200) {
      final detail = decoded is Map<String, dynamic>
          ? decoded['detail']?.toString()
          : null;

      throw Exception(
        detail ?? 'No se pudo iniciar el checkout.',
      );
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
}
