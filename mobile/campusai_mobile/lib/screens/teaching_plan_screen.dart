import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/export_service.dart';
import '../services/study_result_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

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
  String get evaluationStrategy => plan['evaluation_strategy']?.toString() ?? '';

  List<String> listFrom(String key) {
    final raw = plan[key];
    if (raw is List) return raw.map((item) => item.toString()).toList();
    return [];
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

    buffer.writeln(title.toUpperCase());
    buffer.writeln('');
    if (subject.isNotEmpty) buffer.writeln('Asignatura: $subject');
    if (generalObjective.isNotEmpty) {
      buffer.writeln('Objetivo general: $generalObjective');
    }
    buffer.writeln('');

    for (final section in [
      ['Competencias', 'competencies'],
      ['Recursos', 'resources'],
      ['Recomendaciones', 'recommendations'],
    ]) {
      final items = listFrom(section[1]);
      if (items.isNotEmpty) {
        buffer.writeln('${section[0]}:');
        for (final item in items) {
          buffer.writeln('- $item');
        }
        buffer.writeln('');
      }
    }

    if (methodology.isNotEmpty) {
      buffer.writeln('Metodología:');
      buffer.writeln(methodology);
      buffer.writeln('');
    }

    if (evaluationStrategy.isNotEmpty) {
      buffer.writeln('Estrategia de evaluación:');
      buffer.writeln(evaluationStrategy);
      buffer.writeln('');
    }

    for (final week in weeks) {
      buffer.writeln('Semana ${week['week'] ?? ''}: ${week['topic'] ?? ''}');
      for (final key in ['objectives', 'contents', 'activities', 'resources']) {
        final raw = week[key];
        if (raw is List && raw.isNotEmpty) {
          buffer.writeln('$key:');
          for (final item in raw) {
            buffer.writeln('- $item');
          }
        }
      }
      final assessment = week['assessment']?.toString() ?? '';
      if (assessment.isNotEmpty) buffer.writeln('Evaluación: $assessment');
      buffer.writeln('----------------------------------------');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  Future<void> exportPdf() async {
    await ExportService.exportTextToPdf(
      title: title,
      content: exportableContent(),
    );
  }

  Future<void> exportDocx() async {
    await ExportService.exportTextToDocx(
      title: title,
      content: exportableContent(),
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
            onPressed: plan.isEmpty ? null : exportPdf,
            icon: const Icon(Icons.picture_as_pdf_rounded),
          ),
          IconButton(
            tooltip: 'Exportar Word',
            onPressed: plan.isEmpty ? null : exportDocx,
            icon: const Icon(Icons.description_rounded),
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
                      onPressed: plan.isEmpty ? null : exportDocx,
                      icon: const Icon(Icons.description_rounded),
                      label: const Text('Exportar Word'),
                    ),
                    OutlinedButton.icon(
                      onPressed: plan.isEmpty ? null : exportPdf,
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text('Exportar PDF'),
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
          const SizedBox(height: 20),
          if (competencies.isNotEmpty)
            _ListSection(title: 'Competencias', items: competencies),
          if (methodology.isNotEmpty)
            _TextSection(title: 'Metodología', text: methodology),
          if (resources.isNotEmpty)
            _ListSection(title: 'Recursos', items: resources),
          if (evaluationStrategy.isNotEmpty)
            _TextSection(title: 'Estrategia de evaluación', text: evaluationStrategy),
          if (weeks.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Cronograma semanal',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            ...weeks.map(
              (week) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _WeekCard(week: week),
              ),
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
            Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            Text(text, style: const TextStyle(color: AppTheme.textMuted, height: 1.4)),
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
            Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Text('• $item', style: const TextStyle(color: AppTheme.textMuted, height: 1.35)),
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

  const _WeekCard({required this.week});

  List<String> listFrom(String key) {
    final raw = week[key];
    if (raw is List) return raw.map((item) => item.toString()).toList();
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final objectives = listFrom('objectives');
    final contents = listFrom('contents');
    final activities = listFrom('activities');
    final resources = listFrom('resources');

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Semana ${week['week'] ?? ''}: ${week['topic'] ?? ''}',
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          if (objectives.isNotEmpty) _InlineList(title: 'Objetivos', items: objectives),
          if (contents.isNotEmpty) _InlineList(title: 'Contenidos', items: contents),
          if (activities.isNotEmpty) _InlineList(title: 'Actividades', items: activities),
          if ((week['assessment']?.toString() ?? '').isNotEmpty)
            Text('Evaluación: ${week['assessment']}', style: const TextStyle(color: AppTheme.textMuted, height: 1.35)),
          if (resources.isNotEmpty) _InlineList(title: 'Recursos', items: resources),
        ],
      ),
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
      child: Text('$title: ${items.join(', ')}', style: const TextStyle(color: AppTheme.textMuted, height: 1.35)),
    );
  }
}
