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
      emailRedirectTo: Uri.base.origin,
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

  static Future<void> sendPasswordResetEmail({
    required String email,
  }) {
    return _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: Uri.base.origin,
    );
  }

  static Future<void> resendSignupConfirmation({
    required String email,
    required String password,
  }) async {
    await signUp(
      email: email,
      password: password,
    );
  }

  static String friendlyAuthError(Object error) {
    var message = error.toString().toLowerCase();

    if (error is AuthException) {
      final authMessage = error.message.toLowerCase();
      final authCode = (error.statusCode ?? '').toLowerCase();
      message = '$message $authMessage $authCode';
    }

    if (message.contains('email not confirmed') ||
        message.contains('email_not_confirmed') ||
        message.contains('email_not_verified') ||
        message.contains('not confirmed') ||
        message.contains('confirm your email')) {
      return 'Debes confirmar tu correo electrónico antes de iniciar sesión. Revisa tu bandeja de entrada o spam.';
    }

    if (message.contains('invalid login credentials') ||
        message.contains('invalid_credentials') ||
        message.contains('invalid_grant') ||
        message.contains('invalid credentials')) {
      return 'Correo o contraseña incorrectos, o la cuenta aún no ha sido confirmada. Verifica tus datos o revisa tu correo.';
    }

    if (message.contains('user already registered') ||
        message.contains('already registered') ||
        message.contains('already exists')) {
      return 'Si la cuenta ya fue creada, revisa tu correo para confirmarla antes de iniciar sesión.';
    }

    if (message.contains('for security purposes') ||
        message.contains('rate limit') ||
        message.contains('too many')) {
      return 'Por seguridad, debes esperar unos minutos antes de solicitar otro correo.';
    }

    if (message.contains('password') && message.contains('6')) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }

    return 'No se pudo completar la autenticación. Verifica tus datos e intenta nuevamente.';
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();

    const PlanGuardService().resetToFree();
    const UsageLimitService().resetPdfUploadsToday();
  }
}
