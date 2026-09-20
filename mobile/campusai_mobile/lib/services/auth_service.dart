import 'package:supabase_flutter/supabase_flutter.dart';

import 'plan_guard_service.dart';
import 'security/user_scoped_storage.dart';
import 'student_dashboard_session_isolation.dart';
import 'usage_limit_service.dart';

enum PasswordRecoveryStatus {
  idle,
  ready,
  invalid,
}

/// Resolves the PKCE callback without retaining or exposing the auth code.
class PasswordRecoveryCallback {
  const PasswordRecoveryCallback._();

  static bool isRecoveryRoute(Uri uri) {
    final fragmentPath = uri.fragment.split('?').first;
    return uri.path == '/reset-password' || fragmentPath == '/reset-password';
  }

  static Future<PasswordRecoveryStatus> resolve({
    required Uri uri,
    required Future<bool> Function(String code) exchangeCode,
  }) async {
    final code = uri.queryParameters['code']?.trim() ?? '';
    if (!isRecoveryRoute(uri) || code.isEmpty) {
      return PasswordRecoveryStatus.invalid;
    }

    try {
      final hasSession = await exchangeCode(code);
      return hasSession
          ? PasswordRecoveryStatus.ready
          : PasswordRecoveryStatus.invalid;
    } catch (_) {
      return PasswordRecoveryStatus.invalid;
    }
  }
}

class AuthService {
  static PasswordRecoveryStatus _passwordRecoveryStatus =
      PasswordRecoveryStatus.idle;

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

  static PasswordRecoveryStatus get passwordRecoveryStatus =>
      _passwordRecoveryStatus;

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
      emailRedirectTo: '${Uri.base.origin}/#/auth',
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
      redirectTo: '${Uri.base.origin}/#/reset-password',
    );
  }

  /// Processes the initial Web auth callback before the router starts.
  ///
  /// Supabase PKCE codes are intentionally never logged or persisted here.
  static Future<void> processInitialWebAuthCallback(Uri uri) async {
    final code = uri.queryParameters['code']?.trim() ?? '';
    if (PasswordRecoveryCallback.isRecoveryRoute(uri)) {
      _passwordRecoveryStatus = await PasswordRecoveryCallback.resolve(
        uri: uri,
        exchangeCode: (authCode) async {
          await _client.auth.exchangeCodeForSession(authCode);
          return _client.auth.currentSession != null;
        },
      );
      return;
    }

    if (code.isEmpty) return;

    try {
      await _client.auth.exchangeCodeForSession(code);
    } catch (_) {
      // Authentication failures are handled by the destination screen.
    }
  }

  static Future<void> completePasswordRecovery(String password) async {
    if (_passwordRecoveryStatus != PasswordRecoveryStatus.ready) {
      throw StateError('Password recovery session is not available.');
    }

    await _client.auth.updateUser(UserAttributes(password: password));
    _passwordRecoveryStatus = PasswordRecoveryStatus.idle;
    try {
      await signOut();
    } catch (_) {
      // The SDK removes the local session before attempting remote sign-out.
      // Keep the successful password update visible even if that request fails.
      await const PlanGuardService().resetToFree();
      const UsageLimitService().resetPdfUploadsToday();
    }
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
    StudentDashboardSessionIsolation.invalidateAuthenticatedState();
    await _client.auth.signOut();

    await const PlanGuardService().resetToFree();
    const UsageLimitService().resetPdfUploadsToday();
  }

  static Future<void> reauthenticateCurrentUser(String password) async {
    final user = currentUser;
    final email = user?.email?.trim();
    if (email == null || email.isEmpty || password.isEmpty) {
      throw Exception('Confirma tu contraseña para continuar.');
    }

    await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> clearAfterAccountDeletion() async {
    StudentDashboardSessionIsolation.invalidateAuthenticatedState();
    final userScope = currentUser?.id.trim() ?? '';
    if (userScope.isNotEmpty) {
      await UserScopedStorage.clearUserScope(userScope);
    }
    await const PlanGuardService().clearCachedAccountState();

    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      await _client.auth.signOut();
    }
  }
}
