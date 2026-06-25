import 'dart:convert';

import 'academic_metadata_builder.dart';
import 'academic_resource_repository.dart';

class AcademicUnitResourceManager {
  static const List<String> resourceStatusKeys = [
    'planning',
    'question_bank',
    'exam',
    'rubric',
    'study_guide',
    'teaching_resources',
    'assessment_report',
    'presentation',
  ];

  static bool truthy(dynamic value) {
    if (value is bool) return value;

    final text = AcademicMetadataBuilder.cleanText(value).toLowerCase();
    return text == 'true' ||
        text == '1' ||
        text == 'yes' ||
        text == 'si' ||
        text == 'sí';
  }

  static Map<String, dynamic> normalizedResourceStatus(
    Map<String, dynamic> week, {
    required bool planningDone,
  }) {
    final raw = week['resources_status'];
    final status =
        raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};

    for (final key in resourceStatusKeys) {
      status[key] = truthy(status[key]);
    }

    if (planningDone) {
      status['planning'] = true;
    }

    return status;
  }

  static Map<String, dynamic> updateWeek({
    required Map<String, dynamic> week,
    required String resourceKey,
    required String unitId,
    required String sourceDocumentId,
  }) {
    final status = normalizedResourceStatus(
      week,
      planningDone:
          AcademicMetadataBuilder.stringListFrom(week['objectives']).isNotEmpty,
    );

    status[resourceKey] = true;

    return {
      ...week,
      'unit_id': unitId,
      'source_document_id': sourceDocumentId,
      'resources_status': status,
    };
  }

  static Map<String, dynamic> updateResourceStatus({
    required Map<String, dynamic> plan,
    required int weekIndex,
    required String resourceKey,
    required String unitId,
    required String sourceDocumentId,
  }) {
    final rawWeeks = plan['weeks'];
    if (rawWeeks is! List) return plan;

    final updatedWeeks = rawWeeks.asMap().entries.map((entry) {
      final rawWeek = entry.value;
      final week = rawWeek is Map
          ? Map<String, dynamic>.from(rawWeek)
          : <String, dynamic>{};

      if (entry.key != weekIndex) {
        return week;
      }

      return updateWeek(
        week: week,
        resourceKey: resourceKey,
        unitId: unitId,
        sourceDocumentId: sourceDocumentId,
      );
    }).toList();

    return {
      ...plan,
      if (AcademicMetadataBuilder.cleanText(plan['source_document_id']).isEmpty)
        'source_document_id': sourceDocumentId,
      'weeks': updatedWeeks,
    };
  }

  static Future<void> saveTeachingPlan({
    required String documentId,
    required Map<String, dynamic> plan,
  }) async {
    await AcademicResourceRepository.saveResource(
      documentId: documentId,
      type: 'teaching_plan',
      content: jsonEncode(plan),
      cloudDebugLabel: 'planificación actualizada',
    );
  }
}
