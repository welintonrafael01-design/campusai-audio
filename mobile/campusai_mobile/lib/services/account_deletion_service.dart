import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_service.dart';
import 'auth_service.dart';

class AccountDeletionResponse {
  final bool deleted;
  final bool externalSubscriptionActionRequired;

  const AccountDeletionResponse({
    required this.deleted,
    required this.externalSubscriptionActionRequired,
  });
}

class AccountDeletionService {
  final http.Client _client;
  final String _apiBaseUrl;
  final Future<void> Function(String password) _reauthenticate;
  final Future<void> Function() _clearLocalState;
  final Map<String, String> Function() _authHeaders;

  AccountDeletionService({
    http.Client? client,
    String? apiBaseUrl,
    Future<void> Function(String password)? reauthenticate,
    Future<void> Function()? clearLocalState,
    Map<String, String> Function()? authHeaders,
  })  : _client = client ?? http.Client(),
        _apiBaseUrl = apiBaseUrl ?? ApiService.baseUrl,
        _reauthenticate =
            reauthenticate ?? AuthService.reauthenticateCurrentUser,
        _clearLocalState =
            clearLocalState ?? AuthService.clearAfterAccountDeletion,
        _authHeaders = authHeaders ?? (() => AuthService.authHeaders);

  Future<AccountDeletionResponse> deleteCurrentAccount({
    required String password,
  }) async {
    await _reauthenticate(password);

    final response = await _client.delete(
      Uri.parse('$_apiBaseUrl/account/me'),
      headers: {
        'Content-Type': 'application/json',
        ..._authHeaders(),
      },
      body: jsonEncode({
        'confirmation': 'ELIMINAR MI CUENTA',
      }),
    );

    final decoded = _decodeObject(response.body);
    if (response.statusCode != 200 || decoded['deleted'] != true) {
      throw Exception(_friendlyFailure(decoded));
    }

    await _clearLocalState();
    return AccountDeletionResponse(
      deleted: true,
      externalSubscriptionActionRequired:
          decoded['external_subscription_action_required'] == true,
    );
  }

  Map<String, dynamic> _decodeObject(String body) {
    try {
      final value = jsonDecode(body);
      return value is Map<String, dynamic> ? value : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String _friendlyFailure(Map<String, dynamic> decoded) {
    final detail = decoded['detail'];
    if (detail is Map<String, dynamic>) {
      final message = detail['message']?.toString().trim();
      if (message != null && message.isNotEmpty) return message;
    }
    if (detail is String && detail.trim().isNotEmpty) return detail.trim();
    return 'No se pudo eliminar la cuenta. Tus datos permanecen protegidos; intenta nuevamente.';
  }
}
