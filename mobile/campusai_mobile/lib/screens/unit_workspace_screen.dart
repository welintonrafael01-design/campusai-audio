import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/academic_engine/academic_metadata_builder.dart';
import '../services/academic_engine/academic_unit_resource_manager.dart';
import '../services/study_result_service.dart';
import '../theme/app_theme.dart';
import '../widgets/accessible_tip_card.dart';
import '../widgets/section_card.dart';

class UnitWorkspaceScreen extends StatefulWidget {
  final String teachingPlanDocumentId;
  final Map<String, dynamic> plan;
  final Map<String, dynamic> week;
  final int weekIndex;

  const UnitWorkspaceScreen({
    super.key,
    required this.teachingPlanDocumentId,
    required this.plan,
    required this.week,
    required this.weekIndex,
  });

  @override
  State<UnitWorkspaceScreen> createState() => _UnitWorkspaceScreenState();
}

class _UnitWorkspaceScreenState extends State<UnitWorkspaceScreen> {
  final Map<String, _LoadedResource> loadedResources = {};
  bool isLoadingResources = true;

  static const List<_UnitResourceDefinition> resourceDefinitions = [
    _UnitResourceDefinition(
      key: 'planning',
      title: 'Planificación',
      description: 'Objetivos, contenidos y actividades de la unidad.',
      icon: Icons.event_note_rounded,
    ),
    _UnitResourceDefinition(
      key: 'question_bank',
      title: 'Banco IA',
      description: 'Banco de preguntas generado para esta unidad.',
      icon: Icons.inventory_2_rounded,
    ),
    _UnitResourceDefinition(
      key: 'exam',
      title: 'Examen IA',
      description: 'Evaluación construida desde el banco de la unidad.',
      icon: Icons.assignment_rounded,
    ),
    _UnitResourceDefinition(
      key: 'rubric',
      title: 'Rúbrica IA',
      description: 'Criterios de evaluación y niveles de desempeño.',
      icon: Icons.fact_check_rounded,
    ),
    _UnitResourceDefinition(
      key: 'study_guide',
      title: 'Guía IA',
      description: 'Guía de estudio para reforzar el aprendizaje autónomo.',
      icon: Icons.menu_book_rounded,
    ),
    _UnitResourceDefinition(
      key: 'teaching_resources',
      title: 'Recursos IA',
      description: 'Paquete de recursos docentes y actividades sugeridas.',
      icon: Icons.school_rounded,
    ),
    _UnitResourceDefinition(
      key: 'assessment_report',
      title: 'Reporte IA',
      description: 'Análisis de coherencia académica de la unidad.',
      icon: Icons.insights_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    loadUnitResources();
  }

  Map<String, dynamic> get week => widget.week;

  String get unitId => AcademicMetadataBuilder.unitIdForWeek(
        plan: widget.plan,
        week: week,
        teachingPlanDocumentId: widget.teachingPlanDocumentId,
        index: widget.weekIndex,
      );

  String get sourceDocumentId =>
      AcademicMetadataBuilder.sourceDocumentIdForWeek(
        plan: widget.plan,
        week: week,
        teachingPlanDocumentId: widget.teachingPlanDocumentId,
      );

  String get unitTopic {
    final topic = safeText(week['topic']);
    if (topic.isNotEmpty) return topic;

    return 'Unidad ${widget.weekIndex + 1}';
  }

  Map<String, dynamic> get academicMetadata {
    return AcademicMetadataBuilder.buildAcademicMetadata(
      plan: widget.plan,
      week: week,
      unitId: unitId,
      topic: unitTopic,
      sourceDocumentId: sourceDocumentId,
    );
  }

  Map<String, dynamic> get resourcesStatus {
    return AcademicUnitResourceManager.normalizedResourceStatus(
      week,
      planningDone: objectives.isNotEmpty,
    );
  }

  List<String> get objectives {
    return AcademicMetadataBuilder.stringListFrom(week['objectives']);
  }

  List<String> get contents {
    return AcademicMetadataBuilder.stringListFrom(week['contents']);
  }

  List<String> get activities {
    return AcademicMetadataBuilder.stringListFrom(week['activities']);
  }

  bool get planningAvailable {
    return objectives.isNotEmpty ||
        contents.isNotEmpty ||
        activities.isNotEmpty ||
        AcademicUnitResourceManager.truthy(resourcesStatus['planning']);
  }

  Future<void> loadUnitResources() async {
    setState(() => isLoadingResources = true);

    final loaded = <String, _LoadedResource>{};

    for (final definition in resourceDefinitions) {
      if (definition.key == 'planning') continue;

      final documentId = documentIdForResource(definition.key);
      final result = await StudyResultService.getResult(
        documentId: documentId,
        type: typeForResource(definition.key),
      );

      if (result == null) continue;

      loaded[definition.key] = _LoadedResource(
        key: definition.key,
        documentId: documentId,
        content: result.content,
        decoded: decodeJsonContent(result.content),
      );
    }

    if (!mounted) return;

    setState(() {
      loadedResources
        ..clear()
        ..addAll(loaded);
      isLoadingResources = false;
    });
  }

  String documentIdForResource(String key) {
    switch (key) {
      case 'question_bank':
        return '${unitId}_question_bank';
      case 'exam':
        return '${unitId}_unit_exam';
      case 'rubric':
        return '${unitId}_rubric';
      case 'study_guide':
        return '${unitId}_study_guide';
      case 'teaching_resources':
        return '${unitId}_teaching_resources';
      case 'assessment_report':
        return '${unitId}_assessment_report';
      default:
        return unitId;
    }
  }

  String typeForResource(String key) {
    switch (key) {
      case 'exam':
        return 'exam';
      case 'rubric':
        return 'rubric';
      case 'study_guide':
        return 'study_guide';
      case 'teaching_resources':
        return 'teaching_resources';
      case 'assessment_report':
        return 'assessment_report';
      case 'question_bank':
      default:
        return 'question_bank';
    }
  }

  bool resourceAvailable(String key) {
    if (key == 'planning') return planningAvailable;

    return loadedResources.containsKey(key);
  }

  int calculateProgress() {
    final available = resourceDefinitions
        .where((definition) => resourceAvailable(definition.key))
        .length;

    return ((available / resourceDefinitions.length) * 100).round();
  }

  dynamic decodeJsonContent(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is String && decoded.trim() != content.trim()) {
        return decodeJsonContent(decoded);
      }

      return decoded;
    } catch (_) {
      return content;
    }
  }

  List<Map<String, dynamic>> listFromContent(
    dynamic raw, {
    List<String> keys = const [
      'questions',
      'question_bank',
      'exam',
      'items',
      'data',
      'content',
    ],
  }) {
    dynamic value = raw;

    if (value is String) {
      value = decodeJsonContent(value);
    }

    if (value is Map) {
      final rawMap = Map<String, dynamic>.from(value);
      for (final key in keys) {
        if (!rawMap.containsKey(key)) continue;
        value = rawMap[key];
        break;
      }
    }

    if (value is String) {
      return listFromContent(value, keys: keys);
    }

    if (value is List) {
      return value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }

  Map<String, dynamic> mapFromContent(
    dynamic raw, {
    List<String> keys = const ['rubric', 'study_guide', 'data', 'content'],
  }) {
    dynamic value = raw;

    if (value is String) {
      value = decodeJsonContent(value);
    }

    if (value is Map) {
      final rawMap = Map<String, dynamic>.from(value);
      for (final key in keys) {
        final nested = rawMap[key];
        if (nested is Map) return Map<String, dynamic>.from(nested);
        if (nested is String) return mapFromContent(nested, keys: keys);
      }

      return rawMap;
    }

    return {};
  }

  int countQuestions(dynamic raw) {
    return listFromContent(raw).length;
  }

  String safeText(dynamic value) {
    return AcademicMetadataBuilder.cleanText(value);
  }

  String questionText(Map<String, dynamic> question) {
    final candidates = [
      question['question'],
      question['prompt'],
      question['text'],
      question['statement'],
      question['title'],
    ];

    for (final candidate in candidates) {
      final text = safeText(candidate);
      if (text.isNotEmpty) return text;
    }

    return 'Pregunta sin texto disponible.';
  }

  void showResourceSummary(_UnitResourceDefinition definition) {
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
                  Text(
                    definition.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...summaryWidgetsFor(definition.key),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> summaryWidgetsFor(String key) {
    if (key == 'planning') return planningSummaryWidgets();

    final loaded = loadedResources[key];
    if (loaded == null) {
      return const [
        Text(
          'Genera este recurso desde la planificación.',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      ];
    }

    switch (key) {
      case 'question_bank':
        return questionListSummaryWidgets(loaded.decoded);
      case 'exam':
        return examSummaryWidgets(loaded.decoded);
      case 'rubric':
        return rubricSummaryWidgets(loaded.decoded);
      case 'study_guide':
        return studyGuideSummaryWidgets(loaded.decoded);
      case 'teaching_resources':
        return teachingResourcesSummaryWidgets(loaded.decoded);
      case 'assessment_report':
        return assessmentReportSummaryWidgets(loaded.decoded);
      default:
        return genericSummaryWidgets(loaded.decoded);
    }
  }

  List<Widget> planningSummaryWidgets() {
    return [
      _SummaryLine(label: 'Tema', value: unitTopic),
      if (objectives.isNotEmpty)
        _SummaryBlock(title: 'Objetivos', items: objectives),
      if (contents.isNotEmpty)
        _SummaryBlock(title: 'Contenidos', items: contents),
      if (activities.isNotEmpty)
        _SummaryBlock(title: 'Actividades', items: activities),
      if (safeText(week['assessment']).isNotEmpty)
        _SummaryLine(label: 'Evaluación', value: safeText(week['assessment'])),
    ];
  }

  List<Widget> questionListSummaryWidgets(dynamic decoded) {
    final questions = listFromContent(decoded);

    return [
      _SummaryLine(label: 'Preguntas', value: '${questions.length}'),
      _SummaryBlock(
        title: 'Primeras preguntas',
        items: questions.take(3).map(questionText).toList(),
        emptyText: 'No se pudieron leer preguntas.',
      ),
    ];
  }

  List<Widget> examSummaryWidgets(dynamic decoded) {
    final questions = listFromContent(decoded);
    final totalPoints = firstTextFromMaps(
      questions,
      ['exam_total_points', 'total_points', 'points'],
    );

    return [
      _SummaryLine(label: 'Preguntas', value: '${questions.length}'),
      if (totalPoints.isNotEmpty)
        _SummaryLine(label: 'Puntaje total', value: totalPoints),
      _SummaryBlock(
        title: 'Primeras preguntas',
        items: questions.take(3).map(questionText).toList(),
        emptyText: 'No se pudieron leer preguntas.',
      ),
    ];
  }

  List<Widget> rubricSummaryWidgets(dynamic decoded) {
    final rubric = mapFromContent(decoded, keys: const ['rubric', 'data']);
    final criteria = listFromContent(
      rubric,
      keys: const ['criteria', 'criterios', 'items'],
    );

    return [
      _SummaryLine(label: 'Criterios', value: '${criteria.length}'),
      _SummaryLine(
        label: 'Puntaje total',
        value: safeText(rubric['total_points']).isNotEmpty
            ? safeText(rubric['total_points'])
            : 'No especificado',
      ),
      _SummaryBlock(
        title: 'Criterios principales',
        items: criteria
            .take(4)
            .map((item) => safeText(item['criterion']).isNotEmpty
                ? safeText(item['criterion'])
                : safeText(item['title']))
            .where((item) => item.isNotEmpty)
            .toList(),
        emptyText: 'No se pudieron leer criterios.',
      ),
    ];
  }

  List<Widget> studyGuideSummaryWidgets(dynamic decoded) {
    final guide = mapFromContent(
      decoded,
      keys: const ['study_guide', 'guide', 'data'],
    );

    return [
      _SummaryLine(
        label: 'Resumen',
        value: safeText(guide['summary']).isNotEmpty
            ? safeText(guide['summary'])
            : 'No disponible',
      ),
      _SummaryBlock(
        title: 'Conceptos clave',
        items: stringItemsFrom(guide['key_concepts']),
      ),
      _SummaryBlock(
        title: 'Pasos de estudio',
        items: stringItemsFrom(guide['study_steps']),
      ),
    ];
  }

  List<Widget> teachingResourcesSummaryWidgets(dynamic decoded) {
    final resources = mapFromContent(
      decoded,
      keys: const ['teaching_resources', 'resources', 'data'],
    );

    return [
      _SummaryBlock(
        title: 'Presentación',
        items: stringItemsFrom(resources['presentation_outline']),
      ),
      _SummaryBlock(
        title: 'Actividades de clase',
        items: stringItemsFrom(resources['class_activities']),
      ),
      _SummaryBlock(
        title: 'Preguntas de discusión',
        items: stringItemsFrom(resources['discussion_questions']),
      ),
      _SummaryBlock(
        title: 'Tareas',
        items: stringItemsFrom(resources['homework']),
      ),
    ];
  }

  List<Widget> assessmentReportSummaryWidgets(dynamic decoded) {
    final report = mapFromContent(
      decoded,
      keys: const ['assessment_report', 'report', 'data'],
    );

    return [
      _SummaryLine(
        label: 'Calidad académica',
        value: safeText(report['academic_quality_score']).isNotEmpty
            ? '${safeText(report['academic_quality_score'])}%'
            : '0%',
      ),
      _SummaryLine(
        label: 'Cobertura de objetivos',
        value: safeText(report['objectives_coverage']).isNotEmpty
            ? '${safeText(report['objectives_coverage'])}%'
            : '0%',
      ),
      _SummaryLine(
        label: 'Cobertura de competencias',
        value: safeText(report['competencies_coverage']).isNotEmpty
            ? '${safeText(report['competencies_coverage'])}%'
            : '0%',
      ),
      _SummaryBlock(title: 'Riesgos', items: stringItemsFrom(report['risks'])),
      _SummaryBlock(
        title: 'Recomendaciones',
        items: stringItemsFrom(report['recommendations']),
      ),
    ];
  }

  List<Widget> genericSummaryWidgets(dynamic decoded) {
    return [
      Text(
        safeText(decoded).isNotEmpty
            ? safeText(decoded)
            : 'Recurso disponible.',
        style: const TextStyle(color: AppTheme.textMuted, height: 1.35),
      ),
    ];
  }

  String firstTextFromMaps(
    List<Map<String, dynamic>> items,
    List<String> keys,
  ) {
    for (final item in items) {
      for (final key in keys) {
        final text = safeText(item[key]);
        if (text.isNotEmpty) return text;
      }
    }

    return '';
  }

  List<String> stringItemsFrom(dynamic raw) {
    if (raw is List) {
      return raw
          .map((item) {
            if (item is Map) {
              final title = safeText(item['title']);
              final text = safeText(item['text']);
              final name = safeText(item['name']);
              final description = safeText(item['description']);
              return [title, text, name, description]
                  .firstWhere((value) => value.isNotEmpty, orElse: () => '');
            }

            return safeText(item);
          })
          .where((item) => item.isNotEmpty)
          .take(6)
          .toList();
    }

    final text = safeText(raw);
    return text.isEmpty ? [] : [text];
  }

  @override
  Widget build(BuildContext context) {
    final metadata = academicMetadata;
    final courseDisplayName = safeText(metadata['course_display_name']);
    final progress = calculateProgress();
    final availableCount = resourceDefinitions
        .where((definition) => resourceAvailable(definition.key))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Centro de Unidad'),
      ),
      body: RefreshIndicator(
        onRefresh: loadUnitResources,
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    unitTopic,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _MetaText(
                        label: 'Curso',
                        value: courseDisplayName.isNotEmpty
                            ? courseDisplayName
                            : safeText(metadata['course_name']),
                      ),
                      _MetaText(
                        label: 'Código',
                        value: safeText(metadata['course_code']),
                      ),
                      _MetaText(
                        label: 'Sección',
                        value: safeText(metadata['course_section']),
                      ),
                      _MetaText(
                        label: 'Período',
                        value: safeText(metadata['course_period']),
                      ),
                      if (sourceDocumentId.isNotEmpty)
                        _MetaText(
                          label: 'Documento fuente',
                          value: sourceDocumentId,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$progress% completado',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (isLoadingResources)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$availableCount de ${resourceDefinitions.length} recursos disponibles',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: (progress / 100).clamp(0.0, 1.0).toDouble(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Estos materiales pueden enriquecer tu clase.',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Revisa lo que ya está disponible y vuelve a la planificación para crear lo que falta.',
              style: TextStyle(color: AppTheme.textMuted, height: 1.35),
            ),
            const SizedBox(height: 14),
            const AccessibleTipCard(
              title: 'Accesibilidad para esta unidad',
              tips: [
                'Booky también puede generar versiones accesibles del contenido.',
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'Materiales relacionados',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            ...resourceDefinitions.map(
              (definition) {
                final available = resourceAvailable(definition.key);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ResourceCard(
                    definition: definition,
                    available: available,
                    onView: available
                        ? () {
                            showResourceSummary(definition);
                          }
                        : null,
                  ),
                );
              },
            ),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Tutor por Voz',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Espacio reservado para conversación guiada por voz sobre esta unidad.',
                    style: TextStyle(color: AppTheme.textMuted, height: 1.35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitResourceDefinition {
  final String key;
  final String title;
  final String description;
  final IconData icon;

  const _UnitResourceDefinition({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _LoadedResource {
  final String key;
  final String documentId;
  final String content;
  final dynamic decoded;

  const _LoadedResource({
    required this.key,
    required this.documentId,
    required this.content,
    required this.decoded,
  });
}

class _ResourceCard extends StatelessWidget {
  final _UnitResourceDefinition definition;
  final bool available;
  final VoidCallback? onView;

  const _ResourceCard({
    required this.definition,
    required this.available,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(definition.icon, color: AppTheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      definition.title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      available ? 'Disponible' : 'Pendiente',
                      style: TextStyle(
                        color:
                            available ? AppTheme.success : AppTheme.textMuted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            available
                ? definition.description
                : 'Vuelve a la planificación para crear este material con Booky.',
            style: const TextStyle(color: AppTheme.textMuted, height: 1.35),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: onView,
                icon: const Icon(Icons.visibility_rounded),
                label: const Text('Ver'),
              ),
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.file_download_rounded),
                label: const Text('Exportar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  final String label;
  final String value;

  const _MetaText({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();

    return Text(
      '$label: $value',
      style: const TextStyle(
        color: AppTheme.textMuted,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryLine({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        '$label: $value',
        style: const TextStyle(color: AppTheme.textMuted, height: 1.35),
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  final String title;
  final List<String> items;
  final String emptyText;

  const _SummaryBlock({
    required this.title,
    required this.items,
    this.emptyText = 'No disponible.',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          if (items.isEmpty)
            Text(
              emptyText,
              style: const TextStyle(color: AppTheme.textMuted, height: 1.35),
            )
          else
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  '• $item',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.35,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
