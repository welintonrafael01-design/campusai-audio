import 'dart:convert';

import 'package:campusai_mobile/services/account_deletion_service.dart';
import 'package:campusai_mobile/services/security/user_scoped_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
      'account deletion reauthenticates, uses own token, then clears local data',
      () async {
    final events = <String>[];
    final client = MockClient((request) async {
      events.add('request');
      expect(request.method, 'DELETE');
      expect(request.url.path, '/account/me');
      expect(request.headers['Authorization'], 'Bearer own-token');
      expect(
        jsonDecode(request.body),
        {'confirmation': 'ELIMINAR MI CUENTA'},
      );
      return http.Response(
        jsonEncode({
          'deleted': true,
          'external_subscription_action_required': true,
        }),
        200,
      );
    });

    final response = await AccountDeletionService(
      client: client,
      apiBaseUrl: 'https://api.studybook.example',
      authHeaders: () => {'Authorization': 'Bearer own-token'},
      reauthenticate: (password) async {
        expect(password, 'current-password');
        events.add('reauthenticate');
      },
      clearLocalState: () async => events.add('clear'),
    ).deleteCurrentAccount(password: 'current-password');

    expect(response.deleted, isTrue);
    expect(response.externalSubscriptionActionRequired, isTrue);
    expect(events, ['reauthenticate', 'request', 'clear']);
  });

  test('partial backend deletion never clears the local session', () async {
    var cleared = false;
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'detail': {
            'status': 'retry_required',
            'message': 'La eliminación no terminó.',
          },
        }),
        503,
      );
    });

    await expectLater(
      AccountDeletionService(
        client: client,
        apiBaseUrl: 'https://api.studybook.example',
        authHeaders: () => {'Authorization': 'Bearer own-token'},
        reauthenticate: (_) async {},
        clearLocalState: () async => cleared = true,
      ).deleteCurrentAccount(password: 'current-password'),
      throwsA(
        predicate((error) => error.toString().contains('no terminó')),
      ),
    );
    expect(cleared, isFalse);
  });

  test('user scoped cleanup removes only the deleted account data', () async {
    SharedPreferences.setMockInitialValues({
      'document_history_user-a': 'private-a',
      'study_result_doc_user-a': 'private-a',
      'document_history_user-b': 'private-b',
      'theme_mode': 'dark',
    });

    final removed = await UserScopedStorage.clearUserScope('user-a');
    final prefs = await SharedPreferences.getInstance();

    expect(removed, 2);
    expect(prefs.getString('document_history_user-a'), isNull);
    expect(prefs.getString('study_result_doc_user-a'), isNull);
    expect(prefs.getString('document_history_user-b'), 'private-b');
    expect(prefs.getString('theme_mode'), 'dark');
  });
}
