import 'package:campusai_mobile/models/study_result.dart';
import 'package:campusai_mobile/services/security/user_scoped_storage.dart';
import 'package:campusai_mobile/services/study_result_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    UserScopedStorage.debugSetUserScopeForTesting(null);
  });

  testWidgets('LOCAL SESSION isolation keeps StudyResults separated by user',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    UserScopedStorage.debugSetUserScopeForTesting('qa_user_a');
    await StudyResultService.saveResult(
      const StudyResult(
        documentId: 'QA-A-document',
        type: 'quiz',
        content: '[{"question":"A only"}]',
        createdAt: '2026-08-17T00:00:00.000Z',
      ),
    );

    UserScopedStorage.debugSetUserScopeForTesting('qa_user_b');
    final leaked = await StudyResultService.getResult(
      documentId: 'QA-A-document',
      type: 'quiz',
    );
    expect(leaked, isNull);

    await StudyResultService.saveResult(
      const StudyResult(
        documentId: 'QA-B-document',
        type: 'quiz',
        content: '[{"question":"B only"}]',
        createdAt: '2026-08-17T00:05:00.000Z',
      ),
    );

    final userBResults = await StudyResultService.getResultsByType('quiz');
    expect(userBResults.map((result) => result.documentId), ['QA-B-document']);

    UserScopedStorage.debugSetUserScopeForTesting('qa_user_a');
    final userAResults = await StudyResultService.getResultsByType('quiz');
    expect(userAResults.map((result) => result.documentId), ['QA-A-document']);
  });
}
