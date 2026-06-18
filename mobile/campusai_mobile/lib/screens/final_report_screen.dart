import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/academic_analytics_service.dart';
import '../services/course_service.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class FinalReportScreen extends StatefulWidget {
  const FinalReportScreen({super.key});

  @override
  State<FinalReportScreen> createState() => _FinalReportScreenState();
}

class _FinalReportScreenState extends State<FinalReportScreen> {
  List<CourseRecord> courses = [];
  String activeCourseId = '';
  List<StudentAcademicSummary> summaries = [];

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  Future<void> loadReport() async {
    final loadedCourses = await CourseService.getCourses();
    final storedActiveCourseId = await CourseService.getActiveCourseId();

    final resolvedActiveCourseId = storedActiveCourseId.isNotEmpty
        ? storedActiveCourseId
        : (loadedCourses.isNotEmpty ? loadedCourses.first.id : '');

    final activeCourse = loadedCourses
        .where((item) => item.id == resolvedActiveCourseId)
        .cast<CourseRecord?>()
        .firstOrNull;

    final report = activeCourse == null
        ? <StudentAcademicSummary>[]
        : await AcademicAnalyticsService.buildFinalReport(
            courseId: activeCourse.id,
            courseName: activeCourse.name,
          );

    if (!mounted) return;

    setState(() {
      courses = loadedCourses;
      activeCourseId = resolvedActiveCourseId;
      summaries = report;
    });
  }

  Future<void> changeCourse(String? courseId) async {
    if (courseId == null) return;
    await CourseService.setActiveCourse(courseId);
    await loadReport();
  }

  double get average {
    if (summaries.isEmpty) return 0;
    return summaries.map((item) => item.average).reduce((a, b) => a + b) /
        summaries.length;
  }

  double get attendanceAverage {
    if (summaries.isEmpty) return 0;
    return summaries
            .map((item) => item.attendanceRate)
            .reduce((a, b) => a + b) /
        summaries.length;
  }

  int get approvedCount => summaries.where((item) => item.approved).length;

  CourseRecord? get activeCourse {
    return courses
        .where((item) => item.id == activeCourseId)
        .cast<CourseRecord?>()
        .firstOrNull;
  }

  Future<void> exportPdf() async {
    final course = activeCourse;
    if (course == null) return;

    final failed = summaries.length - approvedCount;

    await ExportService.exportFinalReportToPdf(
      title: 'studybook_acta_final',
      courseName: course.displayName,
      rows: summaries.map((item) => item.toRow()).toList(),
      stats: {
        'students': summaries.length,
        'average': '${average.toStringAsFixed(1)}%',
        'approved': approvedCount,
        'failed': failed,
      },
    );
  }

  Future<void> exportExcel() async {
    await ExportService.exportRowsToXlsx(
      title: 'studybook_acta_final',
      rows: summaries.map((item) => item.toRow()).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acta Final Automática'),
        actions: [
          IconButton(
            tooltip: 'Exportar PDF Oficial',
            onPressed: summaries.isEmpty ? null : exportPdf,
            icon: const Icon(Icons.picture_as_pdf_rounded),
          ),
          IconButton(
            tooltip: 'Exportar Excel',
            onPressed: summaries.isEmpty ? null : exportExcel,
            icon: const Icon(Icons.grid_on_rounded),
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
                const Text(
                  'Acta Final Automática',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Promedio general, asistencia y estado académico por estudiante.',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
                if (courses.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: 380,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue:
                          activeCourseId.isEmpty ? null : activeCourseId,
                      decoration: const InputDecoration(
                        labelText: 'Curso / Sección',
                        border: OutlineInputBorder(),
                      ),
                      items: courses
                          .map(
                            (course) => DropdownMenuItem(
                              value: course.id,
                              child: Text(
                                course.displayName,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: changeCourse,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricChip(
                      label: 'Estudiantes',
                      value: summaries.length.toString(),
                    ),
                    _MetricChip(
                      label: 'Promedio',
                      value: '${average.toStringAsFixed(1)}%',
                    ),
                    _MetricChip(
                      label: 'Asistencia',
                      value: '${attendanceAverage.toStringAsFixed(1)}%',
                    ),
                    _MetricChip(
                      label: 'Aprobados',
                      value: approvedCount.toString(),
                    ),
                    _MetricChip(
                      label: 'Reprobados',
                      value: (summaries.length - approvedCount).toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: summaries.isEmpty ? null : exportPdf,
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text('Exportar PDF Oficial'),
                    ),
                    OutlinedButton.icon(
                      onPressed: summaries.isEmpty ? null : exportExcel,
                      icon: const Icon(Icons.grid_on_rounded),
                      label: const Text('Exportar Excel'),
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
          if (summaries.isEmpty)
            const SectionCard(
              child: Text(
                'No hay datos suficientes para generar el acta final.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            )
          else
            ...summaries.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _SummaryCard(summary: item),
              ),
            ),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text('$label: $value'));
  }
}

class _SummaryCard extends StatelessWidget {
  final StudentAcademicSummary summary;

  const _SummaryCard({
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.studentName,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (summary.studentCode.isNotEmpty) ...[
            const SizedBox(height: 6),
            Chip(label: Text('Código: ${summary.studentCode}')),
          ],
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (summary.average / 100).clamp(0, 1),
          ),
          const SizedBox(height: 8),
          Text(
            'Promedio: ${summary.average.toStringAsFixed(1)}% | Asistencia: ${summary.attendanceRate.toStringAsFixed(1)}%',
            style: const TextStyle(
              color: AppTheme.accent,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Evaluaciones: ${summary.evaluations} | Clases: ${summary.attendedClasses}/${summary.totalClasses}',
            style: const TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 6),
          Text(
            summary.approved ? 'Estado: Aprobado' : 'Estado: Reprobado',
            style: TextStyle(
              color: summary.approved ? AppTheme.success : Colors.red,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
