class AcademicMetadataBuilder {
  static String cleanText(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  static List<String> stringListFrom(dynamic raw) {
    if (raw is List) {
      return raw
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final text = cleanText(raw);
    return text.isEmpty ? [] : [text];
  }

  static String unitIdForWeek({
    required Map<String, dynamic> plan,
    required Map<String, dynamic> week,
    required String teachingPlanDocumentId,
    required int index,
  }) {
    final unitId = cleanText(week['unit_id']);
    if (unitId.isNotEmpty) return unitId;

    final courseId = cleanText(week['course_id']).isNotEmpty
        ? cleanText(week['course_id'])
        : cleanText(plan['course_id']);
    final unitNumber = cleanText(week['week']).isNotEmpty
        ? cleanText(week['week'])
        : '${index + 1}';

    if (courseId.isNotEmpty) {
      return '${courseId}_unit_$unitNumber';
    }

    return '${teachingPlanDocumentId}_unit_$unitNumber';
  }

  static String sourceDocumentIdForWeek({
    required Map<String, dynamic> plan,
    required Map<String, dynamic> week,
    required String teachingPlanDocumentId,
  }) {
    final fromWeek = cleanText(week['source_document_id']);
    if (fromWeek.isNotEmpty) return fromWeek;

    final fromPlan = cleanText(plan['source_document_id']);
    if (fromPlan.isNotEmpty) return fromPlan;

    const planSuffix = '_teaching_plan';
    if (teachingPlanDocumentId.endsWith(planSuffix)) {
      return teachingPlanDocumentId.substring(
        0,
        teachingPlanDocumentId.length - planSuffix.length,
      );
    }

    return teachingPlanDocumentId;
  }

  static String metadataForWeek({
    required Map<String, dynamic> plan,
    required Map<String, dynamic> week,
    required String key,
  }) {
    final fromWeek = cleanText(week[key]);
    if (fromWeek.isNotEmpty) return fromWeek;

    return cleanText(plan[key]);
  }

  static String metadataForWeekOrResource({
    required Map<String, dynamic> plan,
    required Map<String, dynamic> week,
    required Map<String, dynamic> resource,
    required String key,
  }) {
    final metadata = metadataForWeek(plan: plan, week: week, key: key);
    if (metadata.isNotEmpty) return metadata;

    return cleanText(resource[key]);
  }

  static Map<String, dynamic> buildCourseMetadata({
    required Map<String, dynamic> plan,
    required Map<String, dynamic> week,
    Map<String, dynamic> fallbackResource = const {},
  }) {
    String value(String key) {
      return metadataForWeekOrResource(
        plan: plan,
        week: week,
        resource: fallbackResource,
        key: key,
      );
    }

    return {
      'course_id': value('course_id'),
      'course_name': value('course_name'),
      'course_code': value('course_code'),
      'course_section': value('course_section'),
      'course_period': value('course_period'),
      'course_display_name': value('course_display_name'),
    };
  }

  static Map<String, dynamic> buildUnitMetadata({
    required Map<String, dynamic> plan,
    required Map<String, dynamic> week,
    required String unitId,
    required String topic,
    required String sourceDocumentId,
    Map<String, dynamic> fallbackResource = const {},
  }) {
    return {
      'unit_id': unitId,
      'unit_topic': topic,
      ...buildCourseMetadata(
        plan: plan,
        week: week,
        fallbackResource: fallbackResource,
      ),
      'source_document_id': sourceDocumentId,
    };
  }

  static Map<String, dynamic> buildAcademicMetadata({
    required Map<String, dynamic> plan,
    required Map<String, dynamic> week,
    required String unitId,
    required String topic,
    required String sourceDocumentId,
    Map<String, dynamic> fallbackResource = const {},
  }) {
    return buildUnitMetadata(
      plan: plan,
      week: week,
      unitId: unitId,
      topic: topic,
      sourceDocumentId: sourceDocumentId,
      fallbackResource: fallbackResource,
    );
  }
}
