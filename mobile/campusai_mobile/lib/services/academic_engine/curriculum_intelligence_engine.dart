import 'academic_metadata_builder.dart';
import 'academic_unit_resource_manager.dart';

class CurriculumIntelligenceEngine {
  static const List<String> resourceKeys = [
    'planning',
    'question_bank',
    'exam',
    'rubric',
    'study_guide',
    'teaching_resources',
    'assessment_report',
  ];

  static const List<String> completionResourceKeys = [
    'planning',
    'question_bank',
    'exam',
    'rubric',
    'study_guide',
  ];

  static const Map<String, String> resourceLabels = {
    'planning': 'planificación',
    'question_bank': 'banco de preguntas',
    'exam': 'examen',
    'rubric': 'rúbrica',
    'study_guide': 'guía de estudio',
    'teaching_resources': 'recursos docentes',
    'assessment_report': 'reporte de evaluación',
  };

  static Map<String, dynamic> analyzeTeachingPlan({
    required Map<String, dynamic> plan,
  }) {
    final weeks = _weeksFrom(plan);
    final totalUnits = weeks.length;
    final competencies =
        AcademicMetadataBuilder.stringListFrom(plan['competencies']);
    final courseId = _clean(plan['course_id']);
    final courseName = _clean(plan['course_name']);
    final courseCode = _clean(plan['course_code']);
    final courseSection = _clean(plan['course_section']);
    final coursePeriod = _clean(plan['course_period']);
    final courseDisplayName = _courseDisplayName(plan);
    final resourceCounts = {
      for (final key in resourceKeys) key: 0,
    };
    final missingResources = <Map<String, dynamic>>[];
    final unitReports = <Map<String, dynamic>>[];
    var completedUnits = 0;
    var totalCompletionScore = 0;
    var objectiveUnits = 0;

    for (var index = 0; index < weeks.length; index++) {
      final week = weeks[index];
      final objectives =
          AcademicMetadataBuilder.stringListFrom(week['objectives']);
      final status = _resourceStatusForWeek(week);
      if (objectives.isNotEmpty) {
        status['planning'] = true;
        objectiveUnits++;
      }

      for (final key in resourceKeys) {
        if (_truthy(status[key])) {
          resourceCounts[key] = (resourceCounts[key] ?? 0) + 1;
        }
      }

      final completionScore = completionResourceKeys.fold<int>(
        0,
        (sum, key) => sum + (_truthy(status[key]) ? 20 : 0),
      );
      final isCompleted =
          completionResourceKeys.every((key) => _truthy(status[key]));
      if (isCompleted) completedUnits++;
      totalCompletionScore += completionScore;

      final unitId = _unitIdForWeek(
        plan: plan,
        week: week,
        index: index,
      );
      final unitTopic = _unitTopicForWeek(week, index);
      final unitMissingResources = resourceKeys
          .where((key) => !_truthy(status[key]))
          .map((key) => {
                'resource_key': key,
                'resource_label': resourceLabels[key] ?? key,
              })
          .toList();

      for (final missing in unitMissingResources) {
        missingResources.add({
          'unit_id': unitId,
          'unit_topic': unitTopic,
          'week': _clean(week['week']),
          ...missing,
        });
      }

      unitReports.add({
        'unit_id': unitId,
        'unit_topic': unitTopic,
        'week': _clean(week['week']),
        'resources_status': {
          for (final key in resourceKeys) key: _truthy(status[key]),
        },
        'completion_score': completionScore,
        'missing_resources': unitMissingResources,
        'alerts': _unitAlerts(status),
        'recommendations': _unitRecommendations(status),
      });
    }

    final resourceCoverage = {
      for (final key in resourceKeys)
        key: _coveragePercent(resourceCounts[key] ?? 0, totalUnits),
    };
    final curriculumCoverage =
        totalUnits == 0 ? 0 : (totalCompletionScore / totalUnits).round();
    final objectiveCoverage = _coveragePercent(objectiveUnits, totalUnits);
    final examOrAssessmentUnits = weeks.asMap().entries.where((entry) {
      final status = _resourceStatusForWeek(entry.value);
      final objectives =
          AcademicMetadataBuilder.stringListFrom(entry.value['objectives']);
      if (objectives.isNotEmpty) status['planning'] = true;

      return _truthy(status['exam']) || _truthy(status['assessment_report']);
    }).length;
    final competencyCoverage = competencies.isEmpty
        ? 0
        : _competencyCoverage(examOrAssessmentUnits, totalUnits);
    final resourceQuality = _average([
      resourceCoverage['question_bank'] ?? 0,
      resourceCoverage['exam'] ?? 0,
      resourceCoverage['rubric'] ?? 0,
      resourceCoverage['study_guide'] ?? 0,
      resourceCoverage['teaching_resources'] ?? 0,
    ]);
    final assessmentQuality = _average([
      resourceCoverage['exam'] ?? 0,
      resourceCoverage['rubric'] ?? 0,
      resourceCoverage['assessment_report'] ?? 0,
    ]);
    final academicScore = _average([
      curriculumCoverage,
      competencyCoverage,
      objectiveCoverage,
      resourceQuality,
      assessmentQuality,
    ]);
    final alerts = _globalAlerts(
      totalUnits: totalUnits,
      competencies: competencies,
      curriculumCoverage: curriculumCoverage,
      resourceCounts: resourceCounts,
    );

    return {
      'course_id': courseId,
      'course_name': courseName,
      'course_code': courseCode,
      'course_section': courseSection,
      'course_period': coursePeriod,
      'course_display_name': courseDisplayName,
      'intelligence_source': 'TeachingPlan',
      'intelligence_title': 'Inteligencia curricular - $courseDisplayName',
      'intelligence_version': 'A',
      'total_units': totalUnits,
      'completed_units': completedUnits,
      'curriculum_coverage': curriculumCoverage,
      'competency_coverage': competencyCoverage,
      'objective_coverage': objectiveCoverage,
      'resource_coverage': resourceCoverage,
      'resource_counts': resourceCounts,
      'missing_resources': missingResources,
      'alerts': alerts,
      'recommendations': _globalRecommendations(resourceCounts, totalUnits),
      'quality': {
        'academic_score': academicScore,
        'assessment_quality': assessmentQuality,
        'resource_quality': resourceQuality,
      },
      'units': unitReports,
    };
  }

  static List<Map<String, dynamic>> _weeksFrom(Map<String, dynamic> plan) {
    final rawWeeks = plan['weeks'];
    if (rawWeeks is! List) return [];

    return rawWeeks
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static Map<String, dynamic> _resourceStatusForWeek(
    Map<String, dynamic> week,
  ) {
    final objectives = AcademicMetadataBuilder.stringListFrom(
      week['objectives'],
    );

    return AcademicUnitResourceManager.normalizedResourceStatus(
      week,
      planningDone: objectives.isNotEmpty,
    );
  }

  static String _courseDisplayName(Map<String, dynamic> plan) {
    final displayName = _clean(plan['course_display_name']);
    if (displayName.isNotEmpty) return displayName;

    final code = _clean(plan['course_code']);
    final name = _clean(plan['course_name']);
    final subject = _clean(plan['subject']);

    if (code.isNotEmpty && name.isNotEmpty) return '$code - $name';
    if (name.isNotEmpty) return name;
    if (subject.isNotEmpty) return subject;

    return 'Curso';
  }

  static String _unitIdForWeek({
    required Map<String, dynamic> plan,
    required Map<String, dynamic> week,
    required int index,
  }) {
    final unitId = _clean(week['unit_id']);
    if (unitId.isNotEmpty) return unitId;

    final courseId = _clean(week['course_id']).isNotEmpty
        ? _clean(week['course_id'])
        : _clean(plan['course_id']);
    final weekNumber =
        _clean(week['week']).isNotEmpty ? _clean(week['week']) : '${index + 1}';

    if (courseId.isNotEmpty) return '${courseId}_unit_$weekNumber';

    return 'unit_$weekNumber';
  }

  static String _unitTopicForWeek(Map<String, dynamic> week, int index) {
    final topic = _clean(week['topic']);
    if (topic.isNotEmpty) return topic;

    return 'Unidad ${index + 1}';
  }

  static List<String> _unitAlerts(Map<String, dynamic> status) {
    final alerts = <String>[];

    if (!_truthy(status['question_bank'])) {
      alerts.add('Unidad sin banco de preguntas.');
    }
    if (!_truthy(status['exam'])) {
      alerts.add('Unidad sin examen.');
    }
    if (!_truthy(status['rubric'])) {
      alerts.add('Unidad sin rúbrica.');
    }
    if (!_truthy(status['study_guide'])) {
      alerts.add('Unidad sin guía de estudio.');
    }
    if (!_truthy(status['assessment_report'])) {
      alerts.add('Unidad sin reporte de evaluación.');
    }

    return alerts;
  }

  static List<String> _unitRecommendations(Map<String, dynamic> status) {
    final recommendations = <String>[];

    if (!_truthy(status['question_bank'])) {
      recommendations.add('Genera Banco IA para esta unidad.');
    }
    if (!_truthy(status['exam'])) {
      recommendations.add('Genera Examen IA para esta unidad.');
    }
    if (!_truthy(status['rubric'])) {
      recommendations.add('Agrega Rúbrica IA para mejorar la trazabilidad.');
    }
    if (!_truthy(status['study_guide'])) {
      recommendations.add('Genera Guía IA para reforzar el aprendizaje.');
    }
    if (!_truthy(status['assessment_report'])) {
      recommendations.add('Genera Reporte IA para medir coherencia académica.');
    }

    return recommendations;
  }

  static List<String> _globalAlerts({
    required int totalUnits,
    required List<String> competencies,
    required int curriculumCoverage,
    required Map<String, int> resourceCounts,
  }) {
    final alerts = <String>[];

    if (totalUnits == 0) {
      alerts.add('El curso no tiene unidades registradas.');
      return alerts;
    }

    if ((resourceCounts['question_bank'] ?? 0) < totalUnits) {
      alerts.add('Hay unidades sin banco de preguntas.');
    }
    if ((resourceCounts['exam'] ?? 0) < totalUnits) {
      alerts.add('Hay unidades sin examen.');
    }
    if ((resourceCounts['rubric'] ?? 0) < totalUnits) {
      alerts.add('Hay unidades sin rúbrica.');
    }
    if ((resourceCounts['study_guide'] ?? 0) < totalUnits) {
      alerts.add('Hay unidades sin guía de estudio.');
    }
    if ((resourceCounts['assessment_report'] ?? 0) < totalUnits) {
      alerts.add('Hay unidades sin reporte de evaluación.');
    }
    if (competencies.isEmpty) {
      alerts.add('No se registraron competencias del curso.');
    }
    if (curriculumCoverage < 70) {
      alerts.add('La cobertura curricular está por debajo del 70%.');
    }

    return alerts;
  }

  static List<String> _globalRecommendations(
    Map<String, int> resourceCounts,
    int totalUnits,
  ) {
    if (totalUnits == 0) {
      return [
        'Agrega unidades didácticas para iniciar la inteligencia curricular.',
      ];
    }

    return [
      if ((resourceCounts['question_bank'] ?? 0) < totalUnits)
        'Genera bancos IA para las unidades pendientes.',
      if ((resourceCounts['exam'] ?? 0) < totalUnits)
        'Completa los exámenes IA antes de cerrar el curso.',
      if ((resourceCounts['rubric'] ?? 0) < totalUnits)
        'Agrega rúbricas para mejorar la trazabilidad de la evaluación.',
      if ((resourceCounts['study_guide'] ?? 0) < totalUnits)
        'Genera guías IA para reforzar el aprendizaje autónomo.',
      if ((resourceCounts['assessment_report'] ?? 0) < totalUnits)
        'Genera reportes IA para medir coherencia académica.',
    ];
  }

  static int _coveragePercent(int count, int total) {
    if (total <= 0) return 0;

    return ((count / total) * 100).round().clamp(0, 100);
  }

  static int _competencyCoverage(int coveredUnits, int totalUnits) {
    if (totalUnits <= 0) return 0;

    final coverage = coveredUnits / totalUnits;
    if (coverage >= 0.8) {
      return (85 + ((coverage - 0.8) / 0.2) * 15).round().clamp(85, 100);
    }

    return (coverage * 85).round().clamp(0, 84);
  }

  static int _average(List<int> values) {
    if (values.isEmpty) return 0;

    return (values.reduce((a, b) => a + b) / values.length).round();
  }

  static bool _truthy(dynamic value) {
    return AcademicUnitResourceManager.truthy(value);
  }

  static String _clean(dynamic value) {
    return AcademicMetadataBuilder.cleanText(value);
  }
}
