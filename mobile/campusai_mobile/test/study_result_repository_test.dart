import 'package:campusai_mobile/models/study_result.dart';
import 'package:campusai_mobile/services/security/user_scoped_storage.dart';
import 'package:campusai_mobile/services/study_result_repository.dart';
import 'package:campusai_mobile/services/study_result_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    UserScopedStorage.debugSetUserScopeForTesting('student-a');
  });

  tearDown(() {
    UserScopedStorage.debugSetUserScopeForTesting(null);
  });

  test('restores a missing result from cloud and hydrates local storage',
      () async {
    final repository = StudyResultRepository(
      authenticatedOverride: true,
      cloudLoader: (documentId, type) async => {
        'document_id': documentId,
        'type': type,
        'content': '[{"front":"A","back":"B"}]',
        'updated_at': '2026-08-23T12:00:00Z',
      },
    );

    final result = await repository.getResult(
      documentId: 'doc-a',
      type: 'flashcards',
    );
    final cached = await StudyResultService.getResult(
      documentId: 'doc-a',
      type: 'flashcards',
    );

    expect(result?.documentId, 'doc-a');
    expect(cached?.content, result?.content);
  });

  test('never returns a cloud result for another document', () async {
    final repository = StudyResultRepository(
      authenticatedOverride: true,
      cloudLoader: (_, __) async => {
        'document_id': 'doc-b',
        'type': 'flashcards',
        'content': '[]',
      },
    );

    final result = await repository.getResult(
      documentId: 'doc-a',
      type: 'flashcards',
    );

    expect(result, isNull);
  });

  test('merges cloud results by document and preserves offline local data',
      () async {
    await StudyResultService.saveResult(
      const StudyResult(
        documentId: 'local-doc',
        type: 'exam',
        content: '[]',
        createdAt: '2026-08-20T12:00:00Z',
      ),
    );
    final repository = StudyResultRepository(
      authenticatedOverride: true,
      cloudListLoader: (_) async => [
        {
          'document_id': 'cloud-doc',
          'type': 'exam',
          'content': '[]',
          'created_at': '2026-08-23T12:00:00Z',
        },
      ],
    );

    final results = await repository.getResultsByType('exam');

    expect(results.map((item) => item.documentId), [
      'cloud-doc',
      'local-doc',
    ]);
  });
}
