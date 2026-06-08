import 'package:supabase_flutter/supabase_flutter.dart';

import 'plan_guard_service.dart';
import 'usage_limit_service.dart';

class AuthService {
  static bool get isConfigured {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  static SupabaseClient get _client {
    if (!isConfigured) {
      throw Exception(
        'Supabase no está configurado. Ejecuta Flutter con SUPABASE_URL y SUPABASE_ANON_KEY.',
      );
    }

    return Supabase.instance.client;
  }

  static User? get currentUser =>
      isConfigured ? _client.auth.currentUser : null;

  static bool get isLoggedIn => currentUser != null;

  static String? get accessToken =>
      isConfigured ? _client.auth.currentSession?.accessToken : null;

  static String get requireAccessToken {
    final token = accessToken?.trim();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Debes iniciar sesión nuevamente para continuar.',
      );
    }

    return token;
  }

  static Map<String, String> get authHeaders {
    final token = requireAccessToken;

    return {
      'Authorization': 'Bearer $token',
    };
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(
      email: email.trim(),
      password: password,
    );
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();

    const PlanGuardService().resetToFree();
    const UsageLimitService().resetPdfUploadsToday();
  }
}
