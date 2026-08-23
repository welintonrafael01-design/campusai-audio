import 'dart:convert';

import '../models/study_result.dart';
import 'cloud_api_service.dart';
import 'study_result_repository.dart';
import 'study_result_service.dart';

class DocumentResourceCleanupService {
  const DocumentResourceCleanupService({
    this.repository = const StudyResultRepository(),
  });

  static const resultTypes = <String>[
    'assessment_report',
    'audiobook',
    'curriculum_intelligence',
    'exam',
    'final_report',
    'flashcards',
    'question_bank',
    'quiz',
    'rubric',
    'study_guide',
    'teaching_plan',
    'teaching_resources',
  ];

  final StudyResultRepository repository;

  Future<int> deleteAssociatedResults(String documentId) async {
    final cleanDocumentId = documentId.trim();
    if (cleanDocumentId.isEmpty) return 0;

    final associated = <String, StudyResult>{};
    for (final type in resultTypes) {
      final results = await repository.getResultsByType(type);
      for (final result in results) {
        if (!belongsToDocument(result, cleanDocumentId)) continue;
        associated['${result.type}:${result.documentId}'] = result;
      }
    }

    for (final result in associated.values) {
      await StudyResultService.deleteResult(
        documentId: result.documentId,
        type: result.type,
      );
      try {
        await CloudApiService.deleteStudyResult(
          documentId: result.documentId,
          type: result.type,
        );
      } catch (_) {
        // The local deletion remains valid while offline. A later cloud reload
        // can recover resources that the server still owns.
      }
    }

    return associated.length;
  }

  bool belongsToDocument(StudyResult result, String documentId) {
    final resultId = result.documentId.trim();
    if (resultId == documentId || resultId.startsWith('${documentId}_')) {
      return true;
    }

    try {
      return _containsDocumentReference(jsonDecode(result.content), documentId);
    } catch (_) {
      return false;
    }
  }

  bool _containsDocumentReference(dynamic value, String documentId) {
    if (value is List) {
      return value.any((item) => _containsDocumentReference(item, documentId));
    }
    if (value is! Map) return false;

    for (final entry in value.entries) {
      final key = entry.key.toString();
      if ((key == 'source_document_id' || key == 'document_id') &&
          entry.value?.toString().trim() == documentId) {
        return true;
      }
      if (_containsDocumentReference(entry.value, documentId)) return true;
    }
    return false;
  }
}
