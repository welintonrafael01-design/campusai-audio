import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/academic_engine/academic_metadata_builder.dart';
import '../services/academic_engine/academic_resource_repository.dart';
import '../services/academic_engine/academic_unit_resource_manager.dart';
import '../services/academic_engine/curriculum_intelligence_engine.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';
import '../services/study_result_service.dart';
import '../theme/app_theme.dart';
import '../widgets/accessible_tip_card.dart';
import '../widgets/section_card.dart';
import '../widgets/studybook/booky_card.dart';

const int _unitQuestionBankQuestionCount = 20;
const int _unitExamQuestionCount = 10;
const int _unitExamTotalPoints = 100;
const int _unitRubricTotalPoints = 100;
const int _unitRubricCriteriaCount = 5;
const int _unitRubricPerformanceLevels = 4;
const String _unitQuestionBankBloomLevel = 'Analizar';
const String _unitRubricType = 'analytic';
const String _unitStudyGuideType = 'student';
const List<Map<String, String>> _resourceStatusDefinitions = [
  {'key': 'planning', 'label': 'Planificación'},
  {'key': 'question_bank', 'label': 'Banco'},
  {'key': 'exam', 'label': 'Examen'},
  {'key': 'rubric', 'label': 'Rúbrica'},
  {'key': 'study_guide', 'label': 'Guía'},
  {'key': 'teaching_resources', 'label': 'Recursos'},
  {'key': 'assessment_report', 'label': 'Reporte'},
];

String _cleanText(dynamic value) {
  return AcademicMetadataBuilder.cleanText(value);
}

List<String> _stringListFrom(dynamic raw) {
  return AcademicMetadataBuilder.stringListFrom(raw);
}

bool _truthy(dynamic value) {
  return AcademicUnitResourceManager.truthy(value);
}

Map<String, dynamic> _normalizedResourceStatus(
  Map<String, dynamic> week, {
  required bool planningDone,
}) {
  return AcademicUnitResourceManager.normalizedResourceStatus(
    week,
    planningDone: planningDone,
  );
}

class TeachingPlanScreen extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> initialPlan;

  const TeachingPlanScreen({
    super.key,
    required this.documentId,
    this.initialPlan = const {},
  });

  @override
  State<TeachingPlanScreen> createState() => _TeachingPlanScreenState();
}

class _TeachingPlanScreenState extends State<TeachingPlanScreen> {
  Map<String, dynamic> plan = {};
  bool isExportingPdf = false;
  bool isExportingDocx = false;
  bool isGeneratingCurriculumIntelligence = false;
  final Set<String> generatingQuestionBankUnitIds = {};
  final Set<String> generatingExamUnitIds = {};
  final Set<String> generatingRubricUnitIds = {};
  final Set<String> generatingStudyGuideUnitIds = {};
  final Set<String> generatingTeachingResourcesUnitIds = {};
  final Set<String> generatingAssessmentReportUnitIds = {};

  @override
  void initState() {
    super.initState();
    plan = Map<String, dynamic>.from(widget.initialPlan);
    if (plan.isEmpty) {
      loadSavedPlan();
    }
  }

  Future<void> loadSavedPlan() async {
    final result = await StudyResultService.getResult(
      documentId: widget.documentId,
      type: 'teaching_plan',
    );

    if (result == null || !mounted) return;

    try {
      final decoded = jsonDecode(result.content);
      if (decoded is Map<String, dynamic>) {
        setState(() => plan = decoded);
      } else if (decoded is Map) {
        setState(() => plan = Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
  }

  String get title => plan['title']?.toString() ?? 'Planificación docente';
  String get subject => plan['subject']?.toString() ?? '';
  String get generalObjective => plan['general_objective']?.toString() ?? '';
  String get methodology => plan['methodology']?.toString() ?? '';
  String get evaluationStrategy =>
      plan['evaluation_strategy']?.toString() ?? '';

  List<String> listFrom(String key) {
    return _stringListFrom(plan[key]);
  }

  List<Map<String, dynamic>> get weeks {
    final raw = plan['weeks'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return [];
  }

  String exportableContent() {
    final buffer = StringBuffer();

    void sectionTitle(String text) {
      buffer.writeln('');
      buffer.writeln('────────────────────────────────────────');
      buffer.writeln(text.toUpperCase());
      buffer.writeln('────────────────────────────────────────');
    }

    void writeList(String label, List<String> items) {
      if (items.isEmpty) return;
      buffer.writeln('');
      buffer.writeln(label.toUpperCase());
      for (final item in items) {
        buffer.writeln('• $item');
      }
    }

    void writeText(String label, String text) {
      if (text.trim().isEmpty) return;
      buffer.writeln('');
      buffer.writeln(label.toUpperCase());
      buffer.writeln(text.trim());
    }

    final weeksCount = weeks.length;

    buffer.writeln('STUDYBOOK AI');
    buffer.writeln('PLANIFICACIÓN DOCENTE');
    buffer.writeln('');
    buffer.writeln('Título: $title');
    if (subject.isNotEmpty) buffer.writeln('Asignatura: $subject');
    if (weeksCount > 0) buffer.writeln('Duración: $weeksCount semanas');
    buffer.writeln(
        'Fecha de emisión: ${DateTime.now().toIso8601String().substring(0, 10)}');

    writeText('Objetivo general', generalObjective);
    writeList('Competencias', listFrom('competencies'));
    writeText('Metodología', methodology);
    writeList('Recursos', listFrom('resources'));
    writeText('Estrategia de evaluación', evaluationStrategy);

    if (weeks.isNotEmpty) {
      sectionTitle('Cronograma semanal');
    }

    for (final week in weeks) {
      final weekNumber = week['week']?.toString() ?? '';
      final topic = week['topic']?.toString() ?? '';

      buffer.writeln('');
      buffer.writeln('SEMANA $weekNumber');
      if (topic.isNotEmpty) buffer.writeln('Tema: $topic');
      buffer.writeln('');

      final sections = [
        ['Objetivos', 'objectives'],
        ['Contenidos', 'contents'],
        ['Actividades', 'activities'],
        ['Recursos', 'resources'],
      ];

      for (final section in sections) {
        final label = section[0];
        final key = section[1];
        final raw = week[key];

        if (raw is List && raw.isNotEmpty) {
          buffer.writeln(label.toUpperCase());
          for (final item in raw) {
            buffer.writeln('• $item');
          }
          buffer.writeln('');
        }
      }

      final assessment = week['assessment']?.toString() ?? '';
      if (assessment.isNotEmpty) {
        buffer.writeln('EVALUACIÓN');
        buffer.writeln('• $assessment');
        buffer.writeln('');
      }

      buffer.writeln('────────────────────────────────────────');
    }

    writeList('Recomendaciones', listFrom('recommendations'));

    return buffer.toString();
  }

  Future<void> exportPdf() async {
    if (isExportingPdf) return;

    setState(() => isExportingPdf = true);

    try {
      await ExportService.exportTeachingPlanToPdf(
        title: title,
        plan: plan,
      );
    } finally {
      if (mounted) {
        setState(() => isExportingPdf = false);
      }
    }
  }

  Future<void> exportDocx() async {
    if (isExportingDocx) return;

    setState(() => isExportingDocx = true);

    try {
      await ExportService.exportTextToDocx(
        title: title,
        content: exportableContent(),
      );
    } finally {
      if (mounted) {
        setState(() => isExportingDocx = false);
      }
    }
  }

  Future<void> generateCurriculumIntelligence() async {
    if (isGeneratingCurriculumIntelligence || plan.isEmpty) return;

    setState(() => isGeneratingCurriculumIntelligence = true);

    try {
      final report = CurriculumIntelligenceEngine.analyzeTeachingPlan(
        plan: plan,
      );

      await AcademicResourceRepository.saveCurriculumIntelligence(
        teachingPlanDocumentId: widget.documentId,
        content: jsonEncode(report),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inteligencia curricular generada.'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      showCurriculumIntelligenceSummary(report);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo generar inteligencia curricular: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isGeneratingCurriculumIntelligence = false);
      }
    }
  }

  void showCurriculumIntelligenceSummary(Map<String, dynamic> report) {
    final quality = report['quality'] is Map
        ? Map<String, dynamic>.from(report['quality'] as Map)
        : <String, dynamic>{};
    final alerts = report['alerts'] is List
        ? List<dynamic>.from(report['alerts'] as List)
        : <dynamic>[];
    final recommendations = report['recommendations'] is List
        ? List<dynamic>.from(report['recommendations'] as List)
        : <dynamic>[];

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Inteligencia curricular',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _SummaryMetric(
                        label: 'Cobertura',
                        value: '${report['curriculum_coverage'] ?? 0}%',
                      ),
                      _SummaryMetric(
                        label: 'Score académico',
                        value: '${quality['academic_score'] ?? 0}%',
                      ),
                      _SummaryMetric(
                        label: 'Unidades',
                        value: '${report['total_units'] ?? 0}',
                      ),
                      _SummaryMetric(
                        label: 'Completas',
                        value: '${report['completed_units'] ?? 0}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (alerts.isNotEmpty) ...[
                    const Text(
                      'Alertas',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...alerts.take(4).map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '• ${_cleanText(item)}',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                    const SizedBox(height: 12),
                  ],
                  if (recommendations.isNotEmpty) ...[
                    const Text(
                      'Recomendaciones',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...recommendations.take(4).map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '• ${_cleanText(item)}',
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String unitIdForWeek(Map<String, dynamic> week, int index) {
    return AcademicMetadataBuilder.unitIdForWeek(
      plan: plan,
      week: week,
      teachingPlanDocumentId: widget.documentId,
      index: index,
    );
  }

  String sourceDocumentIdForWeek(Map<String, dynamic> week) {
    return AcademicMetadataBuilder.sourceDocumentIdForWeek(
      plan: plan,
      week: week,
      teachingPlanDocumentId: widget.documentId,
    );
  }

  int indexOfWeek(Map<String, dynamic> selectedWeek) {
    final rawWeeks = plan['weeks'];
    if (rawWeeks is! List) return -1;

    final selectedUnitId = _cleanText(selectedWeek['unit_id']);
    if (selectedUnitId.isNotEmpty) {
      for (var index = 0; index < rawWeeks.length; index++) {
        final rawWeek = rawWeeks[index];
        if (rawWeek is! Map) continue;

        final week = Map<String, dynamic>.from(rawWeek);
        if (_cleanText(week['unit_id']) == selectedUnitId) {
          return index;
        }
      }
    }

    final selectedWeekNumber = _cleanText(selectedWeek['week']);
    final selectedTopic = _cleanText(selectedWeek['topic']);

    for (var index = 0; index < rawWeeks.length; index++) {
      final rawWeek = rawWeeks[index];
      if (rawWeek is! Map) continue;

      final week = Map<String, dynamic>.from(rawWeek);
      final sameWeekNumber = _cleanText(week['week']) == selectedWeekNumber;
      final sameTopic = _cleanText(week['topic']) == selectedTopic;

      if (sameWeekNumber && sameTopic) {
        return index;
      }
    }

    return -1;
  }

  List<Map<String, dynamic>> questionsFromResponse(Map<String, dynamic> data) {
    dynamic rawQuestions =
        data['questions'] ?? data['question_bank'] ?? data['data'];

    if (rawQuestions is Map) {
      rawQuestions = rawQuestions['questions'] ??
          rawQuestions['question_bank'] ??
          rawQuestions['items'];
    }

    if (rawQuestions is List) {
      return rawQuestions
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }

  List<Map<String, dynamic>> questionsFromSavedContent(String content) {
    try {
      final decoded = jsonDecode(content);
      dynamic rawQuestions = decoded;

      if (decoded is Map) {
        rawQuestions = decoded['questions'] ??
            decoded['question_bank'] ??
            decoded['items'] ??
            decoded['data'] ??
            decoded['content'];
      }

      if (rawQuestions is String && rawQuestions != content) {
        return questionsFromSavedContent(rawQuestions);
      }

      if (rawQuestions is List) {
        return rawQuestions
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    } catch (_) {}

    return [];
  }

  List<Map<String, dynamic>> defaultPerformanceLevels() {
    return [
      {
        'level': 4,
        'label': 'Excelente',
        'description':
            'Evidencia dominio sólido, precisión académica y autonomía.',
      },
      {
        'level': 3,
        'label': 'Bueno',
        'description':
            'Cumple el criterio con claridad y pocos aspectos por mejorar.',
      },
      {
        'level': 2,
        'label': 'Básico',
        'description':
            'Cumple parcialmente el criterio y requiere mayor desarrollo.',
      },
      {
        'level': 1,
        'label': 'Inicial',
        'description': 'Presenta avances mínimos o evidencia insuficiente.',
      },
    ];
  }

  Map<String, dynamic> descriptorsFromCriterion(
      Map<String, dynamic> criterion) {
    final rawDescriptors = criterion['descriptors'];
    if (rawDescriptors is Map) {
      return {
        '4': _cleanText(rawDescriptors['4'] ?? rawDescriptors[4]),
        '3': _cleanText(rawDescriptors['3'] ?? rawDescriptors[3]),
        '2': _cleanText(rawDescriptors['2'] ?? rawDescriptors[2]),
        '1': _cleanText(rawDescriptors['1'] ?? rawDescriptors[1]),
      };
    }

    final rawLevels = criterion['levels'];
    if (rawLevels is Map) {
      return {
        '4': _cleanText(
          rawLevels['4'] ?? rawLevels[4] ?? rawLevels['excellent'],
        ),
        '3': _cleanText(
          rawLevels['3'] ?? rawLevels[3] ?? rawLevels['good'],
        ),
        '2': _cleanText(
          rawLevels['2'] ?? rawLevels[2] ?? rawLevels['basic'],
        ),
        '1': _cleanText(
          rawLevels['1'] ?? rawLevels[1] ?? rawLevels['insufficient'],
        ),
      };
    }

    return const {
      '4': 'Desempeño excelente y consistente.',
      '3': 'Desempeño bueno con detalles menores por mejorar.',
      '2': 'Desempeño básico con desarrollo parcial.',
      '1': 'Desempeño inicial o evidencia insuficiente.',
    };
  }

  Map<String, dynamic> compatibleLevelsFromDescriptors(
    Map<String, dynamic> descriptors,
  ) {
    return {
      'excellent': _cleanText(descriptors['4']),
      'good': _cleanText(descriptors['3']),
      'basic': _cleanText(descriptors['2']),
      'insufficient': _cleanText(descriptors['1']),
    };
  }

  List<Map<String, dynamic>> defaultRubricCriteria(
    String topic,
    List<String> objectives,
  ) {
    final objectiveText =
        objectives.isEmpty ? topic : objectives.take(2).join('; ');
    final names = [
      'Comprensión conceptual',
      'Aplicación del contenido',
      'Análisis y pensamiento crítico',
      'Evidencia y argumentación',
      'Comunicación académica',
    ];

    return names.map((name) {
      return {
        'criterion': name,
        'description': 'Evalúa $name en relación con $objectiveText.',
        'points': 20,
        'weight': 20,
        'descriptors': {
          '4': 'Integra el criterio con profundidad, precisión y autonomía.',
          '3': 'Desarrolla el criterio con claridad y pocos vacíos.',
          '2': 'Muestra comprensión parcial y requiere mayor elaboración.',
          '1': 'Presenta evidencia limitada o insuficiente del criterio.',
        },
        'levels': {
          'excellent':
              'Integra el criterio con profundidad, precisión y autonomía.',
          'good': 'Desarrolla el criterio con claridad y pocos vacíos.',
          'basic': 'Muestra comprensión parcial y requiere mayor elaboración.',
          'insufficient':
              'Presenta evidencia limitada o insuficiente del criterio.',
        },
      };
    }).toList();
  }

  List<Map<String, dynamic>> normalizedRubricCriteria(
    Map<String, dynamic> rawRubric,
    String topic,
    List<String> objectives,
  ) {
    final rawCriteria = rawRubric['criteria'];
    final items = rawCriteria is List
        ? rawCriteria
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : <Map<String, dynamic>>[];

    if (items.isEmpty) {
      return defaultRubricCriteria(topic, objectives);
    }

    final defaultPoints = _unitRubricTotalPoints / items.length;

    return items.map((criterion) {
      final pointsValue = criterion['points'] ?? criterion['weight'];
      final points = pointsValue is num
          ? pointsValue.toDouble()
          : double.tryParse(pointsValue?.toString() ?? '') ?? defaultPoints;
      final roundedPoints = points.round();
      final descriptors = descriptorsFromCriterion(criterion);

      return {
        ...criterion,
        'criterion': _cleanText(criterion['criterion']).isNotEmpty
            ? _cleanText(criterion['criterion'])
            : 'Criterio de evaluación',
        'description': _cleanText(criterion['description']),
        'points': roundedPoints,
        'weight': roundedPoints,
        'descriptors': descriptors,
        'levels': compatibleLevelsFromDescriptors(descriptors),
      };
    }).toList();
  }

  Map<String, dynamic> normalizeRubricPayload({
    required Map<String, dynamic> rawRubric,
    required Map<String, dynamic> academicMetadata,
    required String topic,
    required String learningObjective,
    required String competency,
    required List<String> objectives,
  }) {
    final criteria = normalizedRubricCriteria(rawRubric, topic, objectives);
    final recommendations = rawRubric['recommendations'] is List
        ? List<dynamic>.from(rawRubric['recommendations'] as List)
        : <dynamic>[];

    return {
      ...rawRubric,
      'title': 'Rúbrica - $topic',
      'total_points': _unitRubricTotalPoints,
      ...academicMetadata,
      'rubric_source': 'Unidad',
      'rubric_title': 'Rúbrica - $topic',
      'rubric_type': _unitRubricType,
      'rubric_version': 'A',
      'program_topic': topic,
      'learning_objective': learningObjective,
      'competency': competency,
      'performance_levels': defaultPerformanceLevels(),
      'criteria': criteria,
      'recommendations': recommendations,
    };
  }

  String firstCleanTextFrom(List<dynamic> values) {
    for (final value in values) {
      final text = _cleanText(value);
      if (text.isNotEmpty) return text;
    }

    return '';
  }

  List<dynamic> studyGuideItemsFrom(
    dynamic raw, {
    List<String> fallbackItems = const [],
  }) {
    if (raw is List) {
      final items = raw
          .where((item) {
            if (item is Map) return item.isNotEmpty;
            return _cleanText(item).isNotEmpty;
          })
          .map((item) => item is Map ? Map<String, dynamic>.from(item) : item)
          .toList();

      if (items.isNotEmpty) return items;
    }

    final text = _cleanText(raw);
    if (text.isNotEmpty) return [text];

    return List<dynamic>.from(fallbackItems);
  }

  Map<String, dynamic> normalizeStudyGuidePayload({
    required Map<String, dynamic> rawGuide,
    required Map<String, dynamic> academicMetadata,
    required String topic,
    required String learningObjective,
    required String competency,
    required List<String> objectives,
  }) {
    final summary = firstCleanTextFrom([
      rawGuide['summary'],
      rawGuide['overview'],
      rawGuide['introduction'],
      rawGuide['description'],
    ]);

    return {
      ...rawGuide,
      ...academicMetadata,
      'guide_source': 'Unidad',
      'guide_title': 'Guía de estudio - $topic',
      'guide_type': _unitStudyGuideType,
      'guide_version': 'A',
      'program_topic': topic,
      'learning_objective': learningObjective,
      'competency': competency,
      'summary': summary.isNotEmpty
          ? summary
          : learningObjective.isNotEmpty
              ? learningObjective
              : 'Guía de estudio para $topic.',
      'key_concepts': studyGuideItemsFrom(
        rawGuide['key_concepts'] ?? rawGuide['concepts'],
      ),
      'learning_objectives': studyGuideItemsFrom(
        rawGuide['learning_objectives'] ?? rawGuide['objectives'],
        fallbackItems: objectives,
      ),
      'study_steps': studyGuideItemsFrom(
        rawGuide['study_steps'] ?? rawGuide['steps'],
      ),
      'practice_activities': studyGuideItemsFrom(
        rawGuide['practice_activities'] ?? rawGuide['activities'],
      ),
      'self_assessment': studyGuideItemsFrom(
        rawGuide['self_assessment'] ?? rawGuide['assessment'],
      ),
      'recommendations': studyGuideItemsFrom(rawGuide['recommendations']),
    };
  }

  List<dynamic> teachingResourceItemsFrom(List<dynamic> rawValues) {
    for (final raw in rawValues) {
      final items = studyGuideItemsFrom(raw);
      if (items.isNotEmpty) return items;
    }

    return [];
  }

  Map<String, dynamic> normalizeTeachingResourcesPayload({
    required Map<String, dynamic> rawResources,
    required Map<String, dynamic> academicMetadata,
    required String topic,
    required String learningObjective,
    required String competency,
  }) {
    return {
      ...rawResources,
      ...academicMetadata,
      'resources_source': 'Unidad',
      'resources_title': 'Recursos docentes - $topic',
      'resources_version': 'A',
      'program_topic': topic,
      'learning_objective': learningObjective,
      'competency': competency,
      'presentation_outline': teachingResourceItemsFrom([
        rawResources['presentation_outline'],
        rawResources['presentation'],
        rawResources['slides'],
        rawResources['slide_outline'],
      ]),
      'class_activities': teachingResourceItemsFrom([
        rawResources['class_activities'],
        rawResources['classroom_activities'],
        rawResources['activities'],
      ]),
      'collaborative_activities': teachingResourceItemsFrom([
        rawResources['collaborative_activities'],
        rawResources['group_activities'],
        rawResources['team_activities'],
      ]),
      'discussion_questions': teachingResourceItemsFrom([
        rawResources['discussion_questions'],
        rawResources['discussion_prompts'],
        rawResources['questions'],
      ]),
      'problem_based_learning': teachingResourceItemsFrom([
        rawResources['problem_based_learning'],
        rawResources['pbl'],
        rawResources['problem_cases'],
      ]),
      'gamification_ideas': teachingResourceItemsFrom([
        rawResources['gamification_ideas'],
        rawResources['gamification'],
        rawResources['game_ideas'],
      ]),
      'homework': teachingResourceItemsFrom([
        rawResources['homework'],
        rawResources['assignments'],
        rawResources['homework_tasks'],
      ]),
      'accessibility_adaptations': teachingResourceItemsFrom([
        rawResources['accessibility_adaptations'],
        rawResources['accessibility'],
        rawResources['adaptations'],
      ]),
      'complementary_readings': teachingResourceItemsFrom([
        rawResources['complementary_readings'],
        rawResources['readings'],
        rawResources['suggested_readings'],
      ]),
      'multimedia_suggestions': teachingResourceItemsFrom([
        rawResources['multimedia_suggestions'],
        rawResources['multimedia'],
        rawResources['media_suggestions'],
        rawResources['videos'],
      ]),
      'web_resources': teachingResourceItemsFrom([
        rawResources['web_resources'],
        rawResources['online_resources'],
        rawResources['links'],
      ]),
      'ai_prompts_for_students': teachingResourceItemsFrom([
        rawResources['ai_prompts_for_students'],
        rawResources['student_ai_prompts'],
        rawResources['prompts_for_students'],
        rawResources['ai_prompts'],
      ]),
      'teacher_recommendations': teachingResourceItemsFrom([
        rawResources['teacher_recommendations'],
        rawResources['recommendations'],
        rawResources['teacher_tips'],
      ]),
    };
  }

  dynamic decodeSavedJson(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is String && decoded.trim() != content.trim()) {
        return decodeSavedJson(decoded);
      }

      return decoded;
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> listFromSavedContent(
    String content, {
    List<String> keys = const [
      'questions',
      'question_bank',
      'exam',
      'items',
      'data',
      'content',
    ],
  }) {
    dynamic rawValue = decodeSavedJson(content);

    if (rawValue is Map) {
      final rawMap = Map<String, dynamic>.from(rawValue);
      for (final key in keys) {
        if (!rawMap.containsKey(key)) continue;
        rawValue = rawMap[key];
        break;
      }
    }

    if (rawValue is String) {
      return listFromSavedContent(rawValue, keys: keys);
    }

    if (rawValue is List) {
      return rawValue
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }

  Map<String, dynamic> mapFromSavedContent(
    String content, {
    List<String> keys = const [
      'rubric',
      'study_guide',
      'guide',
      'data',
      'content',
    ],
  }) {
    dynamic rawValue = decodeSavedJson(content);

    if (rawValue is String) {
      return mapFromSavedContent(rawValue, keys: keys);
    }

    if (rawValue is Map) {
      final rawMap = Map<String, dynamic>.from(rawValue);
      for (final key in keys) {
        final nested = rawMap[key];
        if (nested is Map) return Map<String, dynamic>.from(nested);
        if (nested is String) return mapFromSavedContent(nested, keys: keys);
      }

      return rawMap;
    }

    return {};
  }

  String questionText(Map<String, dynamic> question) {
    return firstCleanTextFrom([
      question['question'],
      question['prompt'],
      question['text'],
      question['statement'],
      question['title'],
    ]);
  }

  int duplicateQuestionsCount(List<Map<String, dynamic>> questions) {
    final seen = <String>{};
    var duplicates = 0;

    for (final question in questions) {
      final text = questionText(question)
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (text.isEmpty) continue;

      if (seen.contains(text)) {
        duplicates++;
      } else {
        seen.add(text);
      }
    }

    return duplicates;
  }

  String? bloomKeyFrom(dynamic rawValue) {
    final text = _cleanText(rawValue).toLowerCase();
    if (text.isEmpty) return null;

    if (text.contains('recordar') || text.contains('remember')) {
      return 'recordar';
    }
    if (text.contains('comprender') || text.contains('understand')) {
      return 'comprender';
    }
    if (text.contains('aplicar') || text.contains('apply')) {
      return 'aplicar';
    }
    if (text.contains('analizar') || text.contains('analy')) {
      return 'analizar';
    }
    if (text.contains('evaluar') || text.contains('evaluat')) {
      return 'evaluar';
    }
    if (text.contains('crear') || text.contains('create')) {
      return 'crear';
    }

    return null;
  }

  Map<String, int> bloomDistributionFrom(
    List<Map<String, dynamic>> questions,
  ) {
    final distribution = {
      'recordar': 0,
      'comprender': 0,
      'aplicar': 0,
      'analizar': 0,
      'evaluar': 0,
      'crear': 0,
    };

    for (final question in questions) {
      final key = bloomKeyFrom(
        question['bloom_level'] ??
            question['bloomLevel'] ??
            question['bloom'] ??
            question['level'],
      );
      if (key == null) continue;

      distribution[key] = (distribution[key] ?? 0) + 1;
    }

    return distribution;
  }

  double minutesForQuestion(Map<String, dynamic> question) {
    final type = firstCleanTextFrom([
      question['question_type'],
      question['type'],
      question['format'],
      question['kind'],
    ]).toLowerCase();
    final rawOptions = question['options'] ?? question['choices'];
    final hasOptions = rawOptions is List && rawOptions.isNotEmpty;

    if (type.contains('abierta') ||
        type.contains('desarrollo') ||
        type.contains('essay') ||
        type.contains('open')) {
      return 4;
    }

    if (hasOptions ||
        type.contains('selección') ||
        type.contains('seleccion') ||
        type.contains('opción') ||
        type.contains('opcion') ||
        type.contains('multiple') ||
        type.contains('choice')) {
      return 2.5;
    }

    return 3;
  }

  int estimatedTimeMinutes(List<Map<String, dynamic>> questions) {
    final total = questions.fold<double>(
      0,
      (sum, question) => sum + minutesForQuestion(question),
    );

    return total.round();
  }

  String estimatedDifficultyFromBloom(Map<String, int> distribution) {
    final weights = {
      'recordar': 1,
      'comprender': 2,
      'aplicar': 3,
      'analizar': 4,
      'evaluar': 5,
      'crear': 6,
    };
    final total = distribution.values.fold<int>(0, (sum, value) => sum + value);
    if (total == 0) return 'Media';

    final weighted = distribution.entries.fold<int>(
      0,
      (sum, entry) => sum + entry.value * (weights[entry.key] ?? 3),
    );
    final average = weighted / total;

    if (average >= 4.5) return 'Alta';
    if (average <= 2.2) return 'Baja';
    return 'Media';
  }

  List<String> meaningfulTokens(String text) {
    const stopWords = {
      'para',
      'como',
      'este',
      'esta',
      'estos',
      'estas',
      'desde',
      'sobre',
      'entre',
      'unidad',
      'estudiante',
      'estudiantes',
      'aprendizaje',
      'competencia',
      'competencias',
      'objetivo',
      'objetivos',
    };

    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-záéíóúüñ0-9\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.length >= 5 && !stopWords.contains(token))
        .toList();
  }

  bool textLooksCovered(String item, String corpus) {
    final tokens = meaningfulTokens(item);
    if (tokens.isEmpty) return false;

    final cleanCorpus = corpus.toLowerCase();
    final matches = tokens.where(cleanCorpus.contains).length;
    final requiredMatches = tokens.length == 1 ? 1 : 2;

    return matches >= requiredMatches;
  }

  List<String> coveredItems(List<String> items, String corpus) {
    return items.where((item) => textLooksCovered(item, corpus)).toList();
  }

  int coveragePercent(List<String> items, List<String> covered) {
    if (items.isEmpty) return 0;
    return clampInt((covered.length / items.length) * 100, 0, 100);
  }

  int textOverlapScore(String source, String target) {
    final sourceTokens = meaningfulTokens(source).toSet();
    final targetTokens = meaningfulTokens(target).toSet();
    if (sourceTokens.isEmpty || targetTokens.isEmpty) return 0;

    final shared = sourceTokens.intersection(targetTokens).length;
    final denominator = sourceTokens.length < targetTokens.length
        ? sourceTokens.length
        : targetTokens.length;

    return clampInt((shared / denominator) * 100, 0, 100);
  }

  int clampInt(num value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;

    return value.round();
  }

  int clampedScore(dynamic rawValue, int fallback) {
    if (rawValue is num) return clampInt(rawValue, 0, 100);

    final parsed = num.tryParse(rawValue?.toString() ?? '');
    if (parsed == null) return clampInt(fallback, 0, 100);

    return clampInt(parsed, 0, 100);
  }

  int nonNegativeInt(dynamic rawValue, int fallback) {
    if (rawValue is num) return clampInt(rawValue, 0, 9999);

    final parsed = num.tryParse(rawValue?.toString() ?? '');
    if (parsed == null) return clampInt(fallback, 0, 9999);

    return clampInt(parsed, 0, 9999);
  }

  List<dynamic> assessmentItemsFrom(dynamic rawValue, List<dynamic> fallback) {
    final items = studyGuideItemsFrom(rawValue);
    if (items.isNotEmpty) return items;

    return List<dynamic>.from(fallback);
  }

  Map<String, int> normalizedBloomDistribution(
    dynamic rawValue,
    Map<String, int> fallback,
  ) {
    final distribution = {
      'recordar': fallback['recordar'] ?? 0,
      'comprender': fallback['comprender'] ?? 0,
      'aplicar': fallback['aplicar'] ?? 0,
      'analizar': fallback['analizar'] ?? 0,
      'evaluar': fallback['evaluar'] ?? 0,
      'crear': fallback['crear'] ?? 0,
    };

    if (rawValue is Map) {
      final rawMap = Map<String, dynamic>.from(rawValue);
      for (final key in distribution.keys) {
        distribution[key] = nonNegativeInt(rawMap[key], distribution[key] ?? 0);
      }
    }

    return distribution;
  }

  Map<String, dynamic> normalizedCoverageDetails(
    dynamic rawValue,
    Map<String, dynamic> fallback,
  ) {
    final rawMap = rawValue is Map ? Map<String, dynamic>.from(rawValue) : {};

    return {
      'covered_objectives': assessmentItemsFrom(
        rawMap['covered_objectives'],
        fallback['covered_objectives'] is List
            ? List<dynamic>.from(fallback['covered_objectives'] as List)
            : [],
      ),
      'uncovered_objectives': assessmentItemsFrom(
        rawMap['uncovered_objectives'],
        fallback['uncovered_objectives'] is List
            ? List<dynamic>.from(fallback['uncovered_objectives'] as List)
            : [],
      ),
      'covered_competencies': assessmentItemsFrom(
        rawMap['covered_competencies'],
        fallback['covered_competencies'] is List
            ? List<dynamic>.from(fallback['covered_competencies'] as List)
            : [],
      ),
      'uncovered_competencies': assessmentItemsFrom(
        rawMap['uncovered_competencies'],
        fallback['uncovered_competencies'] is List
            ? List<dynamic>.from(fallback['uncovered_competencies'] as List)
            : [],
      ),
    };
  }

  Map<String, dynamic> buildLocalAssessmentReportPayload({
    required Map<String, dynamic> academicMetadata,
    required String topic,
    required List<String> objectives,
    required List<String> competencies,
    required List<Map<String, dynamic>> questionBank,
    required List<Map<String, dynamic>> exam,
    required Map<String, dynamic> rubric,
    required Map<String, dynamic> studyGuide,
    String analysisWarning = '',
  }) {
    final questionsForBloom = exam.isNotEmpty ? exam : questionBank;
    final bloomDistribution = bloomDistributionFrom(questionsForBloom);
    final duplicateCount = duplicateQuestionsCount(exam);
    final estimatedMinutes = estimatedTimeMinutes(exam);
    final difficulty = estimatedDifficultyFromBloom(bloomDistribution);
    final corpus = jsonEncode({
      'question_bank': questionBank,
      'exam': exam,
      'rubric': rubric,
      'study_guide': studyGuide,
    }).toLowerCase();
    final coveredObjectives = coveredItems(objectives, corpus);
    final uncoveredObjectives =
        objectives.where((item) => !coveredObjectives.contains(item)).toList();
    final coveredCompetencies = coveredItems(competencies, corpus);
    final uncoveredCompetencies = competencies
        .where((item) => !coveredCompetencies.contains(item))
        .toList();
    final objectivesCoverage = coveragePercent(objectives, coveredObjectives);
    final competenciesCoverage =
        coveragePercent(competencies, coveredCompetencies);
    final examCorpus = jsonEncode(exam);
    final rubricCorpus = rubric.isEmpty ? '' : jsonEncode(rubric);
    final guideCorpus = studyGuide.isEmpty ? '' : jsonEncode(studyGuide);
    final examRubricAlignment =
        rubric.isEmpty ? 0 : textOverlapScore(examCorpus, rubricCorpus);
    final examGuideAlignment =
        studyGuide.isEmpty ? 0 : textOverlapScore(examCorpus, guideCorpus);
    final resourceCompleteness = [
      questionBank.isNotEmpty,
      exam.isNotEmpty,
      rubric.isNotEmpty,
      studyGuide.isNotEmpty,
    ].where((item) => item).length;
    final qualityParts = <int>[
      objectivesCoverage,
      if (competencies.isNotEmpty) competenciesCoverage,
      ((resourceCompleteness / 4) * 100).round(),
      if (rubric.isNotEmpty) examRubricAlignment,
      if (studyGuide.isNotEmpty) examGuideAlignment,
      bloomDistribution.values.any((value) => value > 0) ? 80 : 50,
    ];
    final qualityAverage = qualityParts.isEmpty
        ? 0
        : (qualityParts.reduce((a, b) => a + b) / qualityParts.length).round();
    final academicQualityScore =
        clampInt(qualityAverage - (duplicateCount * 5), 0, 100);
    final strengths = <String>[
      'El Examen IA está disponible para la unidad.',
      if (questionBank.isNotEmpty)
        'El reporte puede contrastar el examen con el Banco IA.',
      if (rubric.isNotEmpty)
        'La Rúbrica IA permite analizar alineación evaluativa.',
      if (studyGuide.isNotEmpty)
        'La Guía IA permite revisar coherencia de estudio y evaluación.',
      if (objectivesCoverage >= 70)
        'La cobertura estimada de objetivos es adecuada.',
    ];
    final risks = <String>[
      if (analysisWarning.isNotEmpty) analysisWarning,
      if (questionBank.isEmpty)
        'No se encontró Banco IA para contrastar cobertura de preguntas.',
      if (rubric.isEmpty)
        'No se encontró Rúbrica IA para medir alineación examen/rúbrica.',
      if (studyGuide.isEmpty)
        'No se encontró Guía IA para medir alineación examen/guía.',
      if (bloomDistribution.values.every((value) => value == 0))
        'Las preguntas no incluyen niveles Bloom detectables.',
      if (duplicateCount > 0)
        'Se detectaron preguntas repetidas dentro del examen.',
      if (objectives.isNotEmpty && objectivesCoverage < 70)
        'La cobertura estimada de objetivos puede ser insuficiente.',
      if (competencies.isNotEmpty && competenciesCoverage < 70)
        'La cobertura estimada de competencias puede ser insuficiente.',
    ];
    final recommendations = <String>[
      if (questionBank.isEmpty)
        'Generar Banco IA para mejorar el análisis de cobertura.',
      if (rubric.isEmpty)
        'Generar Rúbrica IA para validar criterios contra el examen.',
      if (studyGuide.isEmpty)
        'Generar Guía IA para revisar coherencia entre estudio y evaluación.',
      if (bloomDistribution.values.every((value) => value == 0))
        'Etiquetar preguntas con niveles Bloom para mejorar el diagnóstico.',
      if (duplicateCount > 0)
        'Reemplazar o reformular preguntas duplicadas del examen.',
      if (objectivesCoverage < 70)
        'Alinear más preguntas con los objetivos menos cubiertos.',
      if (competencies.isNotEmpty && competenciesCoverage < 70)
        'Incluir evidencias evaluativas vinculadas a las competencias del curso.',
    ];

    return {
      ...academicMetadata,
      'assessment_source': 'Unidad',
      'assessment_title': 'Reporte de evaluación - $topic',
      'assessment_version': 'A',
      'objectives_coverage': objectivesCoverage,
      'competencies_coverage': competenciesCoverage,
      'bloom_distribution': bloomDistribution,
      'estimated_difficulty': difficulty,
      'estimated_time_minutes': estimatedMinutes,
      'duplicate_questions_count': duplicateCount,
      'exam_rubric_alignment': examRubricAlignment,
      'exam_guide_alignment': examGuideAlignment,
      'academic_quality_score': academicQualityScore,
      'strengths': strengths,
      'risks': risks,
      'recommendations': recommendations,
      'coverage_details': {
        'covered_objectives': coveredObjectives,
        'uncovered_objectives': uncoveredObjectives,
        'covered_competencies': coveredCompetencies,
        'uncovered_competencies': uncoveredCompetencies,
      },
    };
  }

  Map<String, dynamic> normalizeAssessmentReportPayload({
    required Map<String, dynamic> rawReport,
    required Map<String, dynamic> localReport,
    required Map<String, dynamic> academicMetadata,
    required String topic,
  }) {
    final localBloom =
        Map<String, int>.from(localReport['bloom_distribution'] as Map);
    final localCoverageDetails =
        Map<String, dynamic>.from(localReport['coverage_details'] as Map);

    return {
      ...rawReport,
      ...academicMetadata,
      'assessment_source': 'Unidad',
      'assessment_title': 'Reporte de evaluación - $topic',
      'assessment_version': 'A',
      'objectives_coverage': clampedScore(
        rawReport['objectives_coverage'],
        localReport['objectives_coverage'] as int,
      ),
      'competencies_coverage': clampedScore(
        rawReport['competencies_coverage'],
        localReport['competencies_coverage'] as int,
      ),
      'bloom_distribution': normalizedBloomDistribution(
        rawReport['bloom_distribution'],
        localBloom,
      ),
      'estimated_difficulty':
          _cleanText(rawReport['estimated_difficulty']).isNotEmpty
              ? _cleanText(rawReport['estimated_difficulty'])
              : _cleanText(localReport['estimated_difficulty']),
      'estimated_time_minutes': nonNegativeInt(
        rawReport['estimated_time_minutes'],
        localReport['estimated_time_minutes'] as int,
      ),
      'duplicate_questions_count': nonNegativeInt(
        rawReport['duplicate_questions_count'],
        localReport['duplicate_questions_count'] as int,
      ),
      'exam_rubric_alignment': clampedScore(
        rawReport['exam_rubric_alignment'],
        localReport['exam_rubric_alignment'] as int,
      ),
      'exam_guide_alignment': clampedScore(
        rawReport['exam_guide_alignment'],
        localReport['exam_guide_alignment'] as int,
      ),
      'academic_quality_score': clampedScore(
        rawReport['academic_quality_score'],
        localReport['academic_quality_score'] as int,
      ),
      'strengths': assessmentItemsFrom(
        rawReport['strengths'],
        localReport['strengths'] as List,
      ),
      'risks': assessmentItemsFrom(
        rawReport['risks'],
        localReport['risks'] as List,
      ),
      'recommendations': assessmentItemsFrom(
        rawReport['recommendations'],
        localReport['recommendations'] as List,
      ),
      'coverage_details': normalizedCoverageDetails(
        rawReport['coverage_details'],
        localCoverageDetails,
      ),
    };
  }

  Future<void> generateQuestionBankForUnit(
    Map<String, dynamic> selectedWeek,
  ) async {
    final weekIndex = indexOfWeek(selectedWeek);

    if (weekIndex < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar la unidad seleccionada.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final rawWeeks = plan['weeks'];
    if (rawWeeks is! List) return;

    final currentRawWeek = rawWeeks[weekIndex];
    final week = currentRawWeek is Map
        ? Map<String, dynamic>.from(currentRawWeek)
        : Map<String, dynamic>.from(selectedWeek);

    final unitId = unitIdForWeek(week, weekIndex);
    if (generatingQuestionBankUnitIds.contains(unitId)) return;

    final sourceDocumentId = sourceDocumentIdForWeek(week);
    if (sourceDocumentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Esta unidad no tiene documento fuente para generar el banco.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final topic = _cleanText(week['topic']).isNotEmpty
        ? _cleanText(week['topic'])
        : 'Unidad ${weekIndex + 1}';
    final objectives = _stringListFrom(week['objectives']);
    final learningObjective = objectives.join('; ');
    final competency = listFrom('competencies').join('; ');

    setState(() {
      generatingQuestionBankUnitIds.add(unitId);
    });

    try {
      final data = await ApiService.generateQuestionBankByDocumentId(
        documentId: sourceDocumentId,
        numberOfQuestions: _unitQuestionBankQuestionCount,
        programTopic: topic,
        learningObjective: learningObjective,
        competency: competency,
        bloomLevel: _unitQuestionBankBloomLevel,
      );

      final questions = questionsFromResponse(data);

      if (questions.isEmpty) {
        throw Exception('La IA no devolvió preguntas válidas.');
      }

      final academicMetadata = AcademicMetadataBuilder.buildAcademicMetadata(
        plan: plan,
        week: week,
        unitId: unitId,
        topic: topic,
        sourceDocumentId: sourceDocumentId,
      );

      final enrichedQuestions =
          questions.take(_unitQuestionBankQuestionCount).map((question) {
        return {
          ...question,
          ...academicMetadata,
          'bank_scope': 'unit',
          'program_topic': topic,
          'learning_objective': learningObjective,
          'competency': competency,
          'bloom_level': _unitQuestionBankBloomLevel,
        };
      }).toList();

      final bankContent = jsonEncode(enrichedQuestions);

      await AcademicResourceRepository.saveQuestionBank(
        unitId: unitId,
        content: bankContent,
      );

      final updatedPlan = AcademicUnitResourceManager.updateResourceStatus(
        plan: plan,
        weekIndex: weekIndex,
        resourceKey: 'question_bank',
        unitId: unitId,
        sourceDocumentId: sourceDocumentId,
      );

      await AcademicUnitResourceManager.saveTeachingPlan(
        documentId: widget.documentId,
        plan: updatedPlan,
      );

      if (!mounted) return;

      setState(() {
        plan = updatedPlan;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Banco IA listo para: $topic'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo generar Banco IA: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          generatingQuestionBankUnitIds.remove(unitId);
        });
      }
    }
  }

  Future<void> generateExamForUnit(
    Map<String, dynamic> selectedWeek,
  ) async {
    final weekIndex = indexOfWeek(selectedWeek);

    if (weekIndex < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar la unidad seleccionada.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final rawWeeks = plan['weeks'];
    if (rawWeeks is! List) return;

    final currentRawWeek = rawWeeks[weekIndex];
    final week = currentRawWeek is Map
        ? Map<String, dynamic>.from(currentRawWeek)
        : Map<String, dynamic>.from(selectedWeek);

    final unitId = unitIdForWeek(week, weekIndex);
    if (generatingExamUnitIds.contains(unitId)) return;

    setState(() {
      generatingExamUnitIds.add(unitId);
    });

    try {
      final bankId = '${unitId}_question_bank';
      final bankResult = await StudyResultService.getResult(
        documentId: bankId,
        type: 'question_bank',
      );

      if (!mounted) return;

      if (bankResult == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Primero genera el Banco IA de esta unidad.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final bankQuestions = questionsFromSavedContent(bankResult.content);

      if (bankQuestions.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('El Banco IA de esta unidad no tiene preguntas válidas.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final shuffledQuestions = List<Map<String, dynamic>>.from(bankQuestions)
        ..shuffle(Random());
      final selectedQuestions =
          shuffledQuestions.take(_unitExamQuestionCount).toList();
      final pointsPerQuestion = selectedQuestions.isEmpty
          ? 0
          : _unitExamTotalPoints / selectedQuestions.length;
      final topic = _cleanText(week['topic']).isNotEmpty
          ? _cleanText(week['topic'])
          : _cleanText(selectedQuestions.first['unit_topic']).isNotEmpty
              ? _cleanText(selectedQuestions.first['unit_topic'])
              : 'Unidad ${weekIndex + 1}';
      final sourceDocumentId = sourceDocumentIdForWeek(week);

      final enrichedQuestions = selectedQuestions.map((question) {
        final questionSourceDocumentId =
            _cleanText(question['source_document_id']);
        final academicMetadata = AcademicMetadataBuilder.buildAcademicMetadata(
          plan: plan,
          week: week,
          unitId: unitId,
          topic: topic,
          sourceDocumentId: sourceDocumentId.isNotEmpty
              ? sourceDocumentId
              : questionSourceDocumentId,
          fallbackResource: question,
        );

        return {
          ...question,
          ...academicMetadata,
          'exam_source': 'Unidad',
          'exam_title': 'Examen - $topic',
          'exam_version': 'A',
          'exam_total_points': _unitExamTotalPoints,
          'exam_points_per_question': pointsPerQuestion,
          'exam_topic': topic,
          if (_cleanText(question['bloom_level']).isNotEmpty)
            'bloom_level': _cleanText(question['bloom_level']),
        };
      }).toList();

      final examContent = jsonEncode(enrichedQuestions);

      await AcademicResourceRepository.saveExam(
        unitId: unitId,
        content: examContent,
      );

      final updatedPlan = AcademicUnitResourceManager.updateResourceStatus(
        plan: plan,
        weekIndex: weekIndex,
        resourceKey: 'exam',
        unitId: unitId,
        sourceDocumentId: sourceDocumentId,
      );

      await AcademicUnitResourceManager.saveTeachingPlan(
        documentId: widget.documentId,
        plan: updatedPlan,
      );

      if (!mounted) return;

      setState(() {
        plan = updatedPlan;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Examen IA listo para: $topic'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo generar Examen IA: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          generatingExamUnitIds.remove(unitId);
        });
      }
    }
  }

  Future<void> generateRubricForUnit(
    Map<String, dynamic> selectedWeek,
  ) async {
    final weekIndex = indexOfWeek(selectedWeek);

    if (weekIndex < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar la unidad seleccionada.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final rawWeeks = plan['weeks'];
    if (rawWeeks is! List) return;

    final currentRawWeek = rawWeeks[weekIndex];
    final week = currentRawWeek is Map
        ? Map<String, dynamic>.from(currentRawWeek)
        : Map<String, dynamic>.from(selectedWeek);

    final unitId = unitIdForWeek(week, weekIndex);
    if (generatingRubricUnitIds.contains(unitId)) return;

    final sourceDocumentId = sourceDocumentIdForWeek(week);
    if (sourceDocumentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Esta unidad no tiene documento fuente para generar la rúbrica.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final topic = _cleanText(week['topic']).isNotEmpty
        ? _cleanText(week['topic'])
        : 'Unidad ${weekIndex + 1}';
    final objectives = _stringListFrom(week['objectives']);
    final learningObjective = objectives.join('; ');
    final competency = listFrom('competencies').join('; ');

    setState(() {
      generatingRubricUnitIds.add(unitId);
    });

    try {
      final data = await ApiService.generateRubricByDocumentId(
        documentId: sourceDocumentId,
        totalPoints: _unitRubricTotalPoints,
        rubricType: _unitRubricType,
        criteriaCount: _unitRubricCriteriaCount,
        performanceLevels: _unitRubricPerformanceLevels,
        programTopic: topic,
        learningObjective: learningObjective,
        competency: competency,
      );

      final rawRubric = data['rubric'];
      final rubric = rawRubric is Map
          ? Map<String, dynamic>.from(rawRubric)
          : Map<String, dynamic>.from(data);
      final academicMetadata = AcademicMetadataBuilder.buildAcademicMetadata(
        plan: plan,
        week: week,
        unitId: unitId,
        topic: topic,
        sourceDocumentId: sourceDocumentId,
      );

      final rubricPayload = normalizeRubricPayload(
        rawRubric: rubric,
        academicMetadata: academicMetadata,
        topic: topic,
        learningObjective: learningObjective,
        competency: competency,
        objectives: objectives,
      );

      final rubricContent = jsonEncode(rubricPayload);

      await AcademicResourceRepository.saveRubric(
        unitId: unitId,
        content: rubricContent,
      );

      final updatedPlan = AcademicUnitResourceManager.updateResourceStatus(
        plan: plan,
        weekIndex: weekIndex,
        resourceKey: 'rubric',
        unitId: unitId,
        sourceDocumentId: sourceDocumentId,
      );

      await AcademicUnitResourceManager.saveTeachingPlan(
        documentId: widget.documentId,
        plan: updatedPlan,
      );

      if (!mounted) return;

      setState(() {
        plan = updatedPlan;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rúbrica IA lista para: $topic'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo generar Rúbrica IA: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          generatingRubricUnitIds.remove(unitId);
        });
      }
    }
  }

  Future<void> generateStudyGuideForUnit(
    Map<String, dynamic> selectedWeek,
  ) async {
    final weekIndex = indexOfWeek(selectedWeek);

    if (weekIndex < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar la unidad seleccionada.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final rawWeeks = plan['weeks'];
    if (rawWeeks is! List) return;

    final currentRawWeek = rawWeeks[weekIndex];
    final week = currentRawWeek is Map
        ? Map<String, dynamic>.from(currentRawWeek)
        : Map<String, dynamic>.from(selectedWeek);

    final unitId = unitIdForWeek(week, weekIndex);
    if (generatingStudyGuideUnitIds.contains(unitId)) return;

    final sourceDocumentId = sourceDocumentIdForWeek(week);
    if (sourceDocumentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Esta unidad no tiene documento fuente para generar la guía.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final topic = _cleanText(week['topic']).isNotEmpty
        ? _cleanText(week['topic'])
        : 'Unidad ${weekIndex + 1}';
    final objectives = _stringListFrom(week['objectives']);
    final learningObjective = objectives.join('; ');
    final competency = listFrom('competencies').join('; ');

    setState(() {
      generatingStudyGuideUnitIds.add(unitId);
    });

    try {
      final data = await ApiService.generateStudyGuideByDocumentId(
        documentId: sourceDocumentId,
        programTopic: topic,
        learningObjective: learningObjective,
        competency: competency,
        guideType: _unitStudyGuideType,
        includeSummary: true,
        includeKeyConcepts: true,
        includePracticeActivities: true,
        includeSelfAssessment: true,
      );

      final rawStudyGuide =
          data['study_guide'] ?? data['guide'] ?? data['data'];
      final studyGuide = rawStudyGuide is Map
          ? Map<String, dynamic>.from(rawStudyGuide)
          : Map<String, dynamic>.from(data);
      final academicMetadata = AcademicMetadataBuilder.buildAcademicMetadata(
        plan: plan,
        week: week,
        unitId: unitId,
        topic: topic,
        sourceDocumentId: sourceDocumentId,
      );

      final guidePayload = normalizeStudyGuidePayload(
        rawGuide: studyGuide,
        academicMetadata: academicMetadata,
        topic: topic,
        learningObjective: learningObjective,
        competency: competency,
        objectives: objectives,
      );

      final guideContent = jsonEncode(guidePayload);

      await AcademicResourceRepository.saveStudyGuide(
        unitId: unitId,
        content: guideContent,
      );

      final updatedPlan = AcademicUnitResourceManager.updateResourceStatus(
        plan: plan,
        weekIndex: weekIndex,
        resourceKey: 'study_guide',
        unitId: unitId,
        sourceDocumentId: sourceDocumentId,
      );

      await AcademicUnitResourceManager.saveTeachingPlan(
        documentId: widget.documentId,
        plan: updatedPlan,
      );

      if (!mounted) return;

      setState(() {
        plan = updatedPlan;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Guía IA lista para: $topic'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo generar Guía IA: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          generatingStudyGuideUnitIds.remove(unitId);
        });
      }
    }
  }

  Future<void> generateTeachingResourcesForUnit(
    Map<String, dynamic> selectedWeek,
  ) async {
    final weekIndex = indexOfWeek(selectedWeek);

    if (weekIndex < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar la unidad seleccionada.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final rawWeeks = plan['weeks'];
    if (rawWeeks is! List) return;

    final currentRawWeek = rawWeeks[weekIndex];
    final week = currentRawWeek is Map
        ? Map<String, dynamic>.from(currentRawWeek)
        : Map<String, dynamic>.from(selectedWeek);

    final unitId = unitIdForWeek(week, weekIndex);
    if (generatingTeachingResourcesUnitIds.contains(unitId)) return;

    final sourceDocumentId = sourceDocumentIdForWeek(week);
    if (sourceDocumentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Esta unidad no tiene documento fuente para generar recursos docentes.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final topic = _cleanText(week['topic']).isNotEmpty
        ? _cleanText(week['topic'])
        : 'Unidad ${weekIndex + 1}';
    final objectives = _stringListFrom(week['objectives']);
    final learningObjective = objectives.join('; ');
    final competency = listFrom('competencies').join('; ');

    setState(() {
      generatingTeachingResourcesUnitIds.add(unitId);
    });

    try {
      final data = await ApiService.generateTeachingResourcesByDocumentId(
        documentId: sourceDocumentId,
        programTopic: topic,
        learningObjective: learningObjective,
        competency: competency,
        includePresentationOutline: true,
        includeClassActivities: true,
        includeCollaborativeActivities: true,
        includeDiscussionQuestions: true,
        includeProblemBasedLearning: true,
        includeGamificationIdeas: true,
        includeHomework: true,
        includeAccessibilityAdaptations: true,
        includeComplementaryReadings: true,
        includeMultimediaSuggestions: true,
        includeWebResources: true,
        includeAiPromptsForStudents: true,
      );

      final rawTeachingResources =
          data['teaching_resources'] ?? data['resources'] ?? data['data'];
      final teachingResources = rawTeachingResources is Map
          ? Map<String, dynamic>.from(rawTeachingResources)
          : Map<String, dynamic>.from(data);
      final academicMetadata = AcademicMetadataBuilder.buildAcademicMetadata(
        plan: plan,
        week: week,
        unitId: unitId,
        topic: topic,
        sourceDocumentId: sourceDocumentId,
      );

      final resourcesPayload = normalizeTeachingResourcesPayload(
        rawResources: teachingResources,
        academicMetadata: academicMetadata,
        topic: topic,
        learningObjective: learningObjective,
        competency: competency,
      );

      final resourcesContent = jsonEncode(resourcesPayload);

      await AcademicResourceRepository.saveTeachingResources(
        unitId: unitId,
        content: resourcesContent,
      );

      final updatedPlan = AcademicUnitResourceManager.updateResourceStatus(
        plan: plan,
        weekIndex: weekIndex,
        resourceKey: 'teaching_resources',
        unitId: unitId,
        sourceDocumentId: sourceDocumentId,
      );

      await AcademicUnitResourceManager.saveTeachingPlan(
        documentId: widget.documentId,
        plan: updatedPlan,
      );

      if (!mounted) return;

      setState(() {
        plan = updatedPlan;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Recursos docentes listos para: $topic'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo generar Recursos Docentes: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          generatingTeachingResourcesUnitIds.remove(unitId);
        });
      }
    }
  }

  Future<void> generateAssessmentReportForUnit(
    Map<String, dynamic> selectedWeek,
  ) async {
    final weekIndex = indexOfWeek(selectedWeek);

    if (weekIndex < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo identificar la unidad seleccionada.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final rawWeeks = plan['weeks'];
    if (rawWeeks is! List) return;

    final currentRawWeek = rawWeeks[weekIndex];
    final week = currentRawWeek is Map
        ? Map<String, dynamic>.from(currentRawWeek)
        : Map<String, dynamic>.from(selectedWeek);

    final unitId = unitIdForWeek(week, weekIndex);
    if (generatingAssessmentReportUnitIds.contains(unitId)) return;

    final sourceDocumentId = sourceDocumentIdForWeek(week);
    final topic = _cleanText(week['topic']).isNotEmpty
        ? _cleanText(week['topic'])
        : 'Unidad ${weekIndex + 1}';
    final objectives = _stringListFrom(week['objectives']);
    final competencies = listFrom('competencies');
    final academicMetadata = AcademicMetadataBuilder.buildAcademicMetadata(
      plan: plan,
      week: week,
      unitId: unitId,
      topic: topic,
      sourceDocumentId: sourceDocumentId,
    );

    setState(() {
      generatingAssessmentReportUnitIds.add(unitId);
    });

    try {
      final examResult = await StudyResultService.getResult(
        documentId: '${unitId}_unit_exam',
        type: 'exam',
      );

      if (!mounted) return;

      if (examResult == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Primero genera el Examen IA de esta unidad.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final exam = listFromSavedContent(
        examResult.content,
        keys: const ['questions', 'exam', 'items', 'data', 'content'],
      );

      if (exam.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('El Examen IA de esta unidad no tiene preguntas válidas.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final bankResult = await StudyResultService.getResult(
        documentId: '${unitId}_question_bank',
        type: 'question_bank',
      );
      final rubricResult = await StudyResultService.getResult(
        documentId: '${unitId}_rubric',
        type: 'rubric',
      );
      final guideResult = await StudyResultService.getResult(
        documentId: '${unitId}_study_guide',
        type: 'study_guide',
      );

      final questionBank = bankResult == null
          ? <Map<String, dynamic>>[]
          : listFromSavedContent(
              bankResult.content,
              keys: const [
                'questions',
                'question_bank',
                'items',
                'data',
                'content',
              ],
            );
      final rubric = rubricResult == null
          ? <String, dynamic>{}
          : mapFromSavedContent(
              rubricResult.content,
              keys: const ['rubric', 'data', 'content'],
            );
      final studyGuide = guideResult == null
          ? <String, dynamic>{}
          : mapFromSavedContent(
              guideResult.content,
              keys: const ['study_guide', 'guide', 'data', 'content'],
            );
      final localReport = buildLocalAssessmentReportPayload(
        academicMetadata: academicMetadata,
        topic: topic,
        objectives: objectives,
        competencies: competencies,
        questionBank: questionBank,
        exam: exam,
        rubric: rubric,
        studyGuide: studyGuide,
      );
      var reportPayload = localReport;

      try {
        final data = await ApiService.analyzeAssessmentForUnit(
          academicMetadata: academicMetadata,
          objectives: objectives,
          competencies: competencies,
          questionBank: questionBank,
          exam: exam,
          rubric: rubric,
          studyGuide: studyGuide,
        );
        final rawAssessmentReport =
            data['assessment_report'] ?? data['report'] ?? data['data'];
        final assessmentReport = rawAssessmentReport is Map
            ? Map<String, dynamic>.from(rawAssessmentReport)
            : Map<String, dynamic>.from(data);

        reportPayload = normalizeAssessmentReportPayload(
          rawReport: assessmentReport,
          localReport: localReport,
          academicMetadata: academicMetadata,
          topic: topic,
        );
      } catch (analysisError) {
        reportPayload = buildLocalAssessmentReportPayload(
          academicMetadata: academicMetadata,
          topic: topic,
          objectives: objectives,
          competencies: competencies,
          questionBank: questionBank,
          exam: exam,
          rubric: rubric,
          studyGuide: studyGuide,
          analysisWarning:
              'No se pudo completar el análisis IA: $analysisError',
        );
      }

      final reportContent = jsonEncode(reportPayload);

      await AcademicResourceRepository.saveAssessmentReport(
        unitId: unitId,
        content: reportContent,
      );

      final updatedPlan = AcademicUnitResourceManager.updateResourceStatus(
        plan: plan,
        weekIndex: weekIndex,
        resourceKey: 'assessment_report',
        unitId: unitId,
        sourceDocumentId: sourceDocumentId,
      );

      await AcademicUnitResourceManager.saveTeachingPlan(
        documentId: widget.documentId,
        plan: updatedPlan,
      );

      if (!mounted) return;

      setState(() {
        plan = updatedPlan;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reporte de evaluación listo para: $topic'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo generar Reporte de Evaluación: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          generatingAssessmentReportUnitIds.remove(unitId);
        });
      }
    }
  }

  void openUnitWorkspace(Map<String, dynamic> week, int index) {
    context.pushNamed(
      'unitWorkspace',
      extra: {
        'teachingPlanDocumentId': widget.documentId,
        'plan': plan,
        'week': week,
        'weekIndex': index,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final competencies = listFrom('competencies');
    final resources = listFrom('resources');
    final recommendations = listFrom('recommendations');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planificación docente'),
        actions: [
          IconButton(
            tooltip: 'Exportar PDF',
            onPressed: plan.isEmpty || isExportingPdf ? null : exportPdf,
            icon: isExportingPdf
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_rounded),
          ),
          IconButton(
            tooltip: 'Exportar Word',
            onPressed: plan.isEmpty || isExportingDocx ? null : exportDocx,
            icon: isExportingDocx
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.description_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (subject.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Asignatura: $subject',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (generalObjective.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    generalObjective,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed:
                          plan.isEmpty || isExportingDocx ? null : exportDocx,
                      icon: isExportingDocx
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.description_rounded),
                      label: Text(isExportingDocx
                          ? 'Exportando Word...'
                          : 'Exportar Word'),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          plan.isEmpty || isExportingPdf ? null : exportPdf,
                      icon: isExportingPdf
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.picture_as_pdf_rounded),
                      label: Text(
                          isExportingPdf ? 'Generando PDF...' : 'Exportar PDF'),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          plan.isEmpty || isGeneratingCurriculumIntelligence
                              ? null
                              : generateCurriculumIntelligence,
                      icon: isGeneratingCurriculumIntelligence
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_graph_rounded),
                      label: Text(isGeneratingCurriculumIntelligence
                          ? 'Analizando...'
                          : 'Revisar cobertura'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.goNamed('dashboard'),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Volver al Dashboard'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const BookyCard(
            title: 'Ya analicé tu contenido.',
            message:
                'Abre una unidad para editarla o genera sus recursos. También puedo crear la rúbrica. ¿Quieres preparar un examen?',
          ),
          const SizedBox(height: 16),
          const AccessibleTipCard(
            title: 'Enseñanza accesible',
            tips: [
              'Booky también puede generar versiones accesibles del contenido.',
            ],
          ),
          const SizedBox(height: 20),
          if (competencies.isNotEmpty)
            _ListSection(title: 'Competencias', items: competencies),
          if (methodology.isNotEmpty)
            _TextSection(title: 'Metodología', text: methodology),
          if (resources.isNotEmpty)
            _ListSection(title: 'Recursos', items: resources),
          if (evaluationStrategy.isNotEmpty)
            _TextSection(
                title: 'Estrategia de evaluación', text: evaluationStrategy),
          if (weeks.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Unidades y próximos pasos',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            ...weeks.asMap().entries.map(
              (entry) {
                final index = entry.key;
                final week = entry.value;
                final unitId = unitIdForWeek(week, index);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _WeekCard(
                    week: week,
                    isGeneratingQuestionBank:
                        generatingQuestionBankUnitIds.contains(unitId),
                    isGeneratingExam: generatingExamUnitIds.contains(unitId),
                    isGeneratingRubric:
                        generatingRubricUnitIds.contains(unitId),
                    isGeneratingStudyGuide:
                        generatingStudyGuideUnitIds.contains(unitId),
                    isGeneratingTeachingResources:
                        generatingTeachingResourcesUnitIds.contains(unitId),
                    isGeneratingAssessmentReport:
                        generatingAssessmentReportUnitIds.contains(unitId),
                    onGenerateQuestionBank: generateQuestionBankForUnit,
                    onGenerateExam: generateExamForUnit,
                    onGenerateRubric: generateRubricForUnit,
                    onGenerateStudyGuide: generateStudyGuideForUnit,
                    onGenerateTeachingResources:
                        generateTeachingResourcesForUnit,
                    onGenerateAssessmentReport: generateAssessmentReportForUnit,
                    onOpenUnit: (week) => openUnitWorkspace(week, index),
                  ),
                );
              },
            ),
          ],
          if (recommendations.isNotEmpty)
            _ListSection(title: 'Recomendaciones', items: recommendations),
          if (plan.isEmpty)
            const SectionCard(
              child: Text(
                'No hay planificación para mostrar.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextSection extends StatelessWidget {
  final String title;
  final String text;

  const _TextSection({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(text,
                style: const TextStyle(color: AppTheme.textMuted, height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _ListSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const _ListSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text('• $item',
                    style: const TextStyle(
                        color: AppTheme.textMuted, height: 1.35)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  final Map<String, dynamic> week;
  final bool isGeneratingQuestionBank;
  final bool isGeneratingExam;
  final bool isGeneratingRubric;
  final bool isGeneratingStudyGuide;
  final bool isGeneratingTeachingResources;
  final bool isGeneratingAssessmentReport;
  final Future<void> Function(Map<String, dynamic> week) onGenerateQuestionBank;
  final Future<void> Function(Map<String, dynamic> week) onGenerateExam;
  final Future<void> Function(Map<String, dynamic> week) onGenerateRubric;
  final Future<void> Function(Map<String, dynamic> week) onGenerateStudyGuide;
  final Future<void> Function(Map<String, dynamic> week)
      onGenerateTeachingResources;
  final Future<void> Function(Map<String, dynamic> week)
      onGenerateAssessmentReport;
  final void Function(Map<String, dynamic> week) onOpenUnit;

  const _WeekCard({
    required this.week,
    required this.isGeneratingQuestionBank,
    required this.isGeneratingExam,
    required this.isGeneratingRubric,
    required this.isGeneratingStudyGuide,
    required this.isGeneratingTeachingResources,
    required this.isGeneratingAssessmentReport,
    required this.onGenerateQuestionBank,
    required this.onGenerateExam,
    required this.onGenerateRubric,
    required this.onGenerateStudyGuide,
    required this.onGenerateTeachingResources,
    required this.onGenerateAssessmentReport,
    required this.onOpenUnit,
  });

  List<String> listFrom(String key) {
    return _stringListFrom(week[key]);
  }

  @override
  Widget build(BuildContext context) {
    final objectives = listFrom('objectives');
    final contents = listFrom('contents');
    final activities = listFrom('activities');
    final resources = listFrom('resources');
    final resourcesStatus = _normalizedResourceStatus(
      week,
      planningDone: objectives.isNotEmpty,
    );
    final generatedResourcesCount = _resourceStatusDefinitions
        .where((definition) => _truthy(resourcesStatus[definition['key']]))
        .length;
    final progress =
        generatedResourcesCount / _resourceStatusDefinitions.length;
    final nextStep = !_truthy(resourcesStatus['question_bank'])
        ? 'Siguiente paso: crea el banco de preguntas para esta unidad.'
        : !_truthy(resourcesStatus['rubric'])
            ? 'También puedo crear la rúbrica de esta unidad.'
            : !_truthy(resourcesStatus['exam'])
                ? '¿Quieres preparar un examen para esta unidad?'
                : !_truthy(resourcesStatus['teaching_resources'])
                    ? 'Genera materiales que puedan enriquecer tu clase.'
                    : 'La unidad está lista. Revisa los recursos y exporta cuando quieras.';

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unidad ${week['week'] ?? ''}: ${week['topic'] ?? ''}',
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).round()}% completado · $generatedResourcesCount de ${_resourceStatusDefinitions.length} recursos creados',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress.clamp(0.0, 1.0).toDouble()),
          const SizedBox(height: 12),
          Text(
            nextStep,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (objectives.isNotEmpty)
            _InlineList(title: 'Objetivos', items: objectives),
          if (contents.isNotEmpty)
            _InlineList(title: 'Contenidos', items: contents),
          if (activities.isNotEmpty)
            _InlineList(title: 'Actividades', items: activities),
          if ((week['assessment']?.toString() ?? '').isNotEmpty)
            Text('Evaluación: ${week['assessment']}',
                style:
                    const TextStyle(color: AppTheme.textMuted, height: 1.35)),
          if (resources.isNotEmpty)
            _InlineList(title: 'Recursos', items: resources),
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 10),
          const Text(
            'Recursos para preparar la clase',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Estos materiales pueden enriquecer tu clase y mantener cada actividad conectada a la unidad.',
            style: TextStyle(
              color: AppTheme.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _resourceStatusDefinitions.map((definition) {
              return _StatusChip(
                label: definition['label']!,
                statusKey: definition['key']!,
                resourcesStatus: resourcesStatus,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => onOpenUnit(week),
                icon: const Icon(Icons.dashboard_customize_rounded),
                label: const Text('Abrir unidad'),
              ),
              OutlinedButton.icon(
                onPressed: isGeneratingQuestionBank
                    ? null
                    : () {
                        onGenerateQuestionBank(week);
                      },
                icon: isGeneratingQuestionBank
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.inventory_2_rounded),
                label: Text(isGeneratingQuestionBank
                    ? 'Generando...'
                    : 'Banco de preguntas'),
              ),
              OutlinedButton.icon(
                onPressed: isGeneratingExam
                    ? null
                    : () {
                        onGenerateExam(week);
                      },
                icon: isGeneratingExam
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.assignment_rounded),
                label: Text(isGeneratingExam ? 'Generando...' : 'Crear examen'),
              ),
              OutlinedButton.icon(
                onPressed: isGeneratingRubric
                    ? null
                    : () {
                        onGenerateRubric(week);
                      },
                icon: isGeneratingRubric
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.fact_check_rounded),
                label:
                    Text(isGeneratingRubric ? 'Generando...' : 'Crear rúbrica'),
              ),
              OutlinedButton.icon(
                onPressed: isGeneratingStudyGuide
                    ? null
                    : () {
                        onGenerateStudyGuide(week);
                      },
                icon: isGeneratingStudyGuide
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.menu_book_rounded),
                label: Text(isGeneratingStudyGuide
                    ? 'Generando...'
                    : 'Guía de estudio'),
              ),
              OutlinedButton.icon(
                onPressed: isGeneratingTeachingResources
                    ? null
                    : () {
                        onGenerateTeachingResources(week);
                      },
                icon: isGeneratingTeachingResources
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.school_rounded),
                label: Text(isGeneratingTeachingResources
                    ? 'Generando...'
                    : 'Generar recursos'),
              ),
              OutlinedButton.icon(
                onPressed: isGeneratingAssessmentReport
                    ? null
                    : () {
                        onGenerateAssessmentReport(week);
                      },
                icon: isGeneratingAssessmentReport
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.insights_rounded),
                label: Text(isGeneratingAssessmentReport
                    ? 'Generando...'
                    : 'Revisar calidad'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final String statusKey;
  final Map<String, dynamic> resourcesStatus;

  const _StatusChip({
    required this.label,
    required this.statusKey,
    required this.resourcesStatus,
  });

  @override
  Widget build(BuildContext context) {
    final done = _truthy(resourcesStatus[statusKey]);

    return Chip(
      avatar: Icon(
        done
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        size: 18,
      ),
      label: Text(done ? '$label listo' : '$label pendiente'),
    );
  }
}

class _InlineList extends StatelessWidget {
  final String title;
  final List<String> items;

  const _InlineList({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text('$title: ${items.join(', ')}',
          style: const TextStyle(color: AppTheme.textMuted, height: 1.35)),
    );
  }
}
