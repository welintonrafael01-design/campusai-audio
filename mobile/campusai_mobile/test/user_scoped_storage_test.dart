import 'package:campusai_mobile/models/study_result.dart';
import 'package:campusai_mobile/services/security/user_scoped_storage.dart';
import 'package:campusai_mobile/services/study_result_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() {
    UserScopedStorage.debugSetUserScopeForTesting(null);
  });

  test('UserScopedStorage builds different keys per user scope', () {
    UserScopedStorage.debugSetUserScopeForTesting('user_a');
    final userAKey = UserScopedStorage.key('study_results');

    UserScopedStorage.debugSetUserScopeForTesting('user_b');
    final userBKey = UserScopedStorage.key('study_results');

    expect(userAKey, isNot(userBKey));
    expect(userAKey, endsWith('_user_a'));
    expect(userBKey, endsWith('_user_b'));
  });

  test('StudyResultService isolates saved results by user scope', () async {
    SharedPreferences.setMockInitialValues({});

    UserScopedStorage.debugSetUserScopeForTesting('user_a');
    await StudyResultService.saveResult(
      const StudyResult(
        documentId: 'doc_1',
        type: 'exam',
        content: '[{"question":"A"}]',
        createdAt: '2026-01-01T00:00:00.000Z',
      ),
    );

    UserScopedStorage.debugSetUserScopeForTesting('user_b');
    expect(
      await StudyResultService.getResult(documentId: 'doc_1', type: 'exam'),
      isNull,
    );

    await StudyResultService.saveResult(
      const StudyResult(
        documentId: 'doc_2',
        type: 'exam',
        content: '[{"question":"B"}]',
        createdAt: '2026-01-02T00:00:00.000Z',
      ),
    );

    final userBResults = await StudyResultService.getResultsByType('exam');
    expect(userBResults.map((result) => result.documentId), ['doc_2']);

    UserScopedStorage.debugSetUserScopeForTesting('user_a');
    final userAResults = await StudyResultService.getResultsByType('exam');
    expect(userAResults.map((result) => result.documentId), ['doc_1']);
  });

  test('StudyResultService validates legacy scoped keys before returning',
      () async {
    SharedPreferences.setMockInitialValues({
      r'${_key}_${documentId.trim()}_${type.trim()}_user_a':
          '{"documentId":"legacy_doc","type":"exam","content":"[]","createdAt":"2026-01-01T00:00:00.000Z"}',
    });

    UserScopedStorage.debugSetUserScopeForTesting('user_a');

    expect(
      await StudyResultService.getResult(
        documentId: 'other_doc',
        type: 'exam',
      ),
      isNull,
    );

    final result = await StudyResultService.getResult(
      documentId: 'legacy_doc',
      type: 'exam',
    );

    expect(result?.documentId, 'legacy_doc');
  });
}
