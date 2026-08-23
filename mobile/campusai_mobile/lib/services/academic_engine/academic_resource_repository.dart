import 'package:flutter/foundation.dart';

import '../../models/study_result.dart';
import '../cloud_api_service.dart';
import '../study_result_service.dart';

class AcademicResourceRepository {
  static Future<bool> saveResource({
    required String documentId,
    required String type,
    required String content,
    String cloudDebugLabel = 'recurso académico',
    Future<void> Function()? cloudSave,
  }) async {
    await StudyResultService.saveResult(
      StudyResult(
        documentId: documentId,
        type: type,
        content: content,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    try {
      if (cloudSave != null) {
        await cloudSave();
      } else {
        await CloudApiService.saveStudyResult(
          documentId: documentId,
          type: type,
          content: content,
        );
      }
      return true;
    } catch (cloudError) {
      debugPrint('No se pudo guardar $cloudDebugLabel en cloud: $cloudError');
      return false;
    }
  }

  static Future<String> saveQuestionBank({
    required String unitId,
    required String content,
  }) async {
    final documentId = '${unitId}_question_bank';

    await saveResource(
      documentId: documentId,
      type: 'question_bank',
      content: content,
      cloudDebugLabel: 'banco de unidad',
    );

    return documentId;
  }

  static Future<String> saveExam({
    required String unitId,
    required String content,
  }) async {
    final documentId = '${unitId}_unit_exam';

    await saveResource(
      documentId: documentId,
      type: 'exam',
      content: content,
      cloudDebugLabel: 'examen de unidad',
    );

    return documentId;
  }

  static Future<String> saveRubric({
    required String unitId,
    required String content,
  }) async {
    final documentId = '${unitId}_rubric';

    await saveResource(
      documentId: documentId,
      type: 'rubric',
      content: content,
      cloudDebugLabel: 'rúbrica de unidad',
    );

    return documentId;
  }

  static Future<String> saveStudyGuide({
    required String unitId,
    required String content,
  }) async {
    final documentId = '${unitId}_study_guide';

    await saveResource(
      documentId: documentId,
      type: 'study_guide',
      content: content,
      cloudDebugLabel: 'guía de estudio de unidad',
    );

    return documentId;
  }

  static Future<String> saveTeachingResources({
    required String unitId,
    required String content,
  }) async {
    final documentId = '${unitId}_teaching_resources';

    await saveResource(
      documentId: documentId,
      type: 'teaching_resources',
      content: content,
      cloudDebugLabel: 'recursos docentes de unidad',
    );

    return documentId;
  }

  static Future<String> saveAssessmentReport({
    required String unitId,
    required String content,
  }) async {
    final documentId = '${unitId}_assessment_report';

    await saveResource(
      documentId: documentId,
      type: 'assessment_report',
      content: content,
      cloudDebugLabel: 'reporte de evaluación de unidad',
    );

    return documentId;
  }

  static Future<String> saveCurriculumIntelligence({
    required String teachingPlanDocumentId,
    required String content,
  }) async {
    final documentId = '${teachingPlanDocumentId}_curriculum_intelligence';

    await saveResource(
      documentId: documentId,
      type: 'curriculum_intelligence',
      content: content,
      cloudDebugLabel: 'inteligencia curricular',
    );

    return documentId;
  }
}
