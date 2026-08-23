import 'package:campusai_mobile/models/study_result.dart';
import 'package:campusai_mobile/services/document_resource_cleanup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = DocumentResourceCleanupService();

  test('matches direct, derived, and metadata-linked resources', () {
    const direct = StudyResult(
      documentId: 'doc-a',
      type: 'flashcards',
      content: '[]',
      createdAt: '2026-08-23T12:00:00Z',
    );
    const derived = StudyResult(
      documentId: 'doc-a_bank_exam',
      type: 'exam',
      content: '[]',
      createdAt: '2026-08-23T12:00:00Z',
    );
    const linked = StudyResult(
      documentId: 'unit-1_question_bank',
      type: 'question_bank',
      content: '[{"source_document_id":"doc-a"}]',
      createdAt: '2026-08-23T12:00:00Z',
    );

    expect(service.belongsToDocument(direct, 'doc-a'), isTrue);
    expect(service.belongsToDocument(derived, 'doc-a'), isTrue);
    expect(service.belongsToDocument(linked, 'doc-a'), isTrue);
  });

  test('does not match another document or a text-only mention', () {
    const unrelated = StudyResult(
      documentId: 'doc-b',
      type: 'study_guide',
      content: '{"summary":"This mentions doc-a but is not linked."}',
      createdAt: '2026-08-23T12:00:00Z',
    );

    expect(service.belongsToDocument(unrelated, 'doc-a'), isFalse);
  });
}
