import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/academic_analytics_service.dart';
import '../services/academic_engine/academic_resource_repository.dart';
import '../services/course_service.dart';
import '../services/export_service.dart';
import '../services/academic_period_lock_service.dart';
import '../services/gradebook_service.dart';
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
  Map<String, dynamic> gradebookFinalReport = {};
  bool periodClosed = false;
  bool isGeneratingFromGradebook = false;

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

    final closed =
        await AcademicPeriodLockService.isClosed(resolvedActiveCourseId);

    if (!mounted) return;

    setState(() {
      courses = loadedCourses;
      activeCourseId = resolvedActiveCourseId;
      summaries = report;
      periodClosed = closed;
    });
  }

  Future<void> changeCourse(String? courseId) async {
    if (courseId == null) return;
    await CourseService.setActiveCourse(courseId);
    await loadReport();
  }

  List<StudentAcademicSummary> get evaluatedSummaries {
    return summaries.where((item) => item.evaluations > 0).toList();
  }

  int get pendingEvaluationCount {
    return summaries.length - evaluatedSummaries.length;
  }

  double get evaluatedAverage {
    if (evaluatedSummaries.isEmpty) return 0;
    return evaluatedSummaries
            .map((item) => item.average)
            .reduce((a, b) => a + b) /
        evaluatedSummaries.length;
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

  int get approvedCount =>
      evaluatedSummaries.where((item) => item.approved).length;

  int get failedEvaluatedCount {
    return evaluatedSummaries.where((item) => !item.approved).length;
  }

  CourseRecord? get activeCourse {
    return courses
        .where((item) => item.id == activeCourseId)
        .cast<CourseRecord?>()
        .firstOrNull;
  }

  Future<void> togglePeriodClosed() async {
    if (activeCourseId.trim().isEmpty) return;

    final next = !periodClosed;

    await AcademicPeriodLockService.setClosed(
      courseId: activeCourseId,
      closed: next,
    );

    await loadReport();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          next
              ? 'Período académico cerrado. Las calificaciones quedan bloqueadas.'
              : 'Período académico reabierto.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> exportPdf() async {
    final course = activeCourse;
    if (course == null) return;

    final failed = failedEvaluatedCount;

    await ExportService.exportFinalReportToPdf(
      title: 'studybook_acta_final',
      courseName: course.displayName,
      rows: summaries.map((item) => item.toRow()).toList(),
      stats: {
        'students': summaries.length,
        'average': '${evaluatedAverage.toStringAsFixed(1)}%',
        'pending': pendingEvaluationCount,
        'approved': approvedCount,
        'failed': failed,
        'evaluated': evaluatedSummaries.length,
      },
    );
  }

  Future<void> exportExcel() async {
    await ExportService.exportRowsToXlsx(
      title: 'studybook_acta_final',
      rows: summaries.map((item) => item.toRow()).toList(),
    );
  }

  Future<void> generateFromGradebook() async {
    final course = activeCourse;

    if (isGeneratingFromGradebook) return;

    if (course == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un curso para generar el Acta Final.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isGeneratingFromGradebook = true);

    try {
      final report = await GradebookService.buildFinalReportFromGradebook(
        courseId: course.id,
        courseName: course.name,
        courseCode: course.code,
        courseSection: course.section,
        coursePeriod: course.period,
      );

      final students = listValue(report['students']);
      final expectedActivities = listValue(report['expected_activities']);
      final summary = mapValue(report['summary']);
      final completedCount =
          intValue(summary['approved']) + intValue(summary['failed']);

      if (students.isEmpty ||
          (expectedActivities.isEmpty && completedCount == 0)) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No hay calificaciones suficientes para generar el Acta Final.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final documentId = course.id.trim().isNotEmpty
          ? '${course.id}_final_report'
          : 'final_report_from_gradebook';

      await AcademicResourceRepository.saveResource(
        documentId: documentId,
        type: 'final_report',
        content: jsonEncode(report),
        cloudDebugLabel: 'acta final',
      );

      if (!mounted) return;

      setState(() {
        gradebookFinalReport = report;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Acta Final generada desde Libro de Calificaciones.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      debugPrint('No se pudo generar el Acta Final (${error.runtimeType}).');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('No se pudo generar el Acta Final. Intenta nuevamente.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isGeneratingFromGradebook = false);
      }
    }
  }

  List<dynamic> listValue(dynamic value) {
    return value is List ? value : const [];
  }

  Map<String, dynamic> mapValue(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  int intValue(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
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
                      label: 'Promedio evaluados',
                      value: '${evaluatedAverage.toStringAsFixed(1)}%',
                    ),
                    _MetricChip(
                      label: 'Sin evaluar',
                      value: pendingEvaluationCount.toString(),
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
                      label: 'Reprobados evaluados',
                      value: failedEvaluatedCount.toString(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Chip(
                  avatar: Icon(
                    periodClosed ? Icons.lock_rounded : Icons.lock_open_rounded,
                  ),
                  label: Text(
                    periodClosed
                        ? 'Estado del período: CERRADO'
                        : 'Estado del período: ABIERTO',
                  ),
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
                    FilledButton.icon(
                      onPressed:
                          activeCourse == null || isGeneratingFromGradebook
                              ? null
                              : generateFromGradebook,
                      icon: isGeneratingFromGradebook
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.fact_check_rounded),
                      label: Text(
                        isGeneratingFromGradebook
                            ? 'Generando acta...'
                            : 'Generar desde Libro de Calificaciones',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: summaries.isEmpty ? null : exportExcel,
                      icon: const Icon(Icons.grid_on_rounded),
                      label: const Text('Exportar Excel'),
                    ),
                    OutlinedButton.icon(
                      onPressed: togglePeriodClosed,
                      icon: Icon(
                        periodClosed
                            ? Icons.lock_open_rounded
                            : Icons.lock_rounded,
                      ),
                      label: Text(
                        periodClosed ? 'Reabrir período' : 'Cerrar período',
                      ),
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
          if (gradebookFinalReport.isNotEmpty) ...[
            _GradebookFinalReportSection(report: gradebookFinalReport),
            const SizedBox(height: 20),
          ],
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
                child: _SummaryCard(
                  summary: item,
                  courseName: activeCourse?.displayName ?? item.courseName,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GradebookFinalReportSection extends StatelessWidget {
  final Map<String, dynamic> report;

  const _GradebookFinalReportSection({required this.report});

  List<dynamic> listValue(dynamic value) {
    return value is List ? value : const [];
  }

  Map<String, dynamic> mapValue(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  String text(dynamic value) => value?.toString().trim() ?? '';

  int intValue(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Color statusColor(String status) {
    if (status == 'Aprobado') return AppTheme.success;
    if (status == 'Reprobado') return Colors.red;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final summary = mapValue(report['summary']);
    final students = listValue(report['students'])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acta Final desde Libro de Calificaciones',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Consolidado preparado para exportación a partir de actividades y notas registradas.',
            style: TextStyle(color: AppTheme.textMuted, height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricChip(
                label: 'Estudiantes',
                value: intValue(summary['total_students']).toString(),
              ),
              _MetricChip(
                label: 'Aprobado',
                value: intValue(summary['approved']).toString(),
              ),
              _MetricChip(
                label: 'Reprobado',
                value: intValue(summary['failed']).toString(),
              ),
              _MetricChip(
                label: 'Incompleto',
                value: intValue(summary['incomplete']).toString(),
              ),
              _MetricChip(
                label: 'Promedio',
                value: '${intValue(summary['average_score'])}%',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (students.isEmpty)
            const Text(
              'No hay calificaciones suficientes para generar el Acta Final.',
              style: TextStyle(color: AppTheme.textMuted),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 44,
                dataRowMinHeight: 50,
                dataRowMaxHeight: 72,
                columns: const [
                  DataColumn(label: Text('Estudiante')),
                  DataColumn(label: Text('Nota final')),
                  DataColumn(label: Text('Estado')),
                  DataColumn(label: Text('Faltantes')),
                  DataColumn(label: Text('Observaciones')),
                ],
                rows: students.map((student) {
                  final status = text(student['status']);
                  final missingActivities =
                      listValue(student['missing_activities'])
                          .map(text)
                          .where((item) => item.isNotEmpty)
                          .toList();
                  final observations = listValue(student['observations'])
                      .map(text)
                      .where((item) => item.isNotEmpty)
                      .toList();

                  return DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 190,
                          child: Text(
                            text(student['student_name']).isEmpty
                                ? 'Estudiante'
                                : text(student['student_name']),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Text('${intValue(student['final_score'])}%')),
                      DataCell(
                        Text(
                          status.isEmpty ? 'Incompleto' : status,
                          style: TextStyle(
                            color: statusColor(
                              status.isEmpty ? 'Incompleto' : status,
                            ),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 220,
                          child: Text(
                            missingActivities.isEmpty
                                ? 'Sin faltantes'
                                : missingActivities.join(', '),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 280,
                          child: Text(
                            observations.isEmpty
                                ? 'Sin observaciones'
                                : observations.join(' '),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
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
  final String courseName;

  const _SummaryCard({
    required this.summary,
    required this.courseName,
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
          if (summary.hasGrades && summary.approved) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    ExportService.exportCertificateToPdf(
                      studentName: summary.studentName,
                      studentCode: summary.studentCode,
                      courseName: courseName,
                      average: '${summary.average.toStringAsFixed(1)}%',
                    );
                  },
                  icon: const Icon(Icons.card_membership_rounded),
                  label: const Text('Generar certificado'),
                ),
                if (summary.average >= 90)
                  OutlinedButton.icon(
                    onPressed: () {
                      ExportService.exportCertificateToPdf(
                        studentName: summary.studentName,
                        studentCode: summary.studentCode,
                        courseName: courseName,
                        average: '${summary.average.toStringAsFixed(1)}%',
                        certificateTitle: 'CERTIFICADO DE EXCELENCIA ACADÉMICA',
                      );
                    },
                    icon: const Icon(Icons.workspace_premium_rounded),
                    label: const Text('Certificado de excelencia'),
                  ),
                OutlinedButton.icon(
                  onPressed: () {
                    ExportService.exportAcademicBadgeToPdf(
                      studentName: summary.studentName,
                      studentCode: summary.studentCode,
                      courseName: courseName,
                      average: '${summary.average.toStringAsFixed(1)}%',
                      badgeTitle: 'Curso Aprobado',
                    );
                  },
                  icon: const Icon(Icons.military_tech_rounded),
                  label: const Text('Generar insignia'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
