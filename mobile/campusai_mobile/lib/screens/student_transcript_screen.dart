import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/student_transcript_service.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class StudentTranscriptScreen extends StatefulWidget {
  final String studentCode;
  final String studentName;

  const StudentTranscriptScreen({
    super.key,
    required this.studentCode,
    required this.studentName,
  });

  @override
  State<StudentTranscriptScreen> createState() =>
      _StudentTranscriptScreenState();
}

class _StudentTranscriptScreenState extends State<StudentTranscriptScreen> {
  bool loading = true;
  StudentTranscript? transcript;

  @override
  void initState() {
    super.initState();
    loadTranscript();
  }

  Future<void> exportTranscriptPdf() async {
    final data = transcript;
    if (data == null) return;

    await ExportService.exportStudentTranscriptToPdf(
      studentName: data.studentName,
      studentCode: data.studentCode,
      generalAverage: '${data.generalAverage.toStringAsFixed(1)}%',
      attendanceAverage: '${data.attendanceAverage.toStringAsFixed(1)}%',
      gpa4: data.gpa4.toStringAsFixed(2),
      academicStanding: data.academicStanding,
      distinctions: data.distinctions,
      rankingPosition: data.rankingPosition,
      rankingTotal: data.rankingTotal,
      rankingPercentile: data.rankingPercentile,
      courses: data.courses
          .map(
            (course) => {
              'course_name': course.courseName,
              'average': course.hasGrades
                  ? '${course.average.toStringAsFixed(1)}%'
                  : 'Sin evaluar',
              'attendance': course.hasAttendance
                  ? '${course.attendanceRate.toStringAsFixed(1)}%'
                  : 'Sin asistencia',
              'status': course.hasGrades
                  ? (course.approved ? 'Aprobado' : 'Reprobado')
                  : 'Pendiente',
            },
          )
          .toList(),
    );
  }

  Future<void> loadTranscript() async {
    final data = await StudentTranscriptService.buildTranscript(
      studentCode: widget.studentCode,
      studentName: widget.studentName,
    );

    if (!mounted) return;

    setState(() {
      transcript = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = transcript;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expediente Académico'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.studentName,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Código / Matrícula: ${widget.studentCode}',
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 18),
                if (loading)
                  const LinearProgressIndicator()
                else if (data == null || data.courses.isEmpty)
                  const Text(
                    'No hay historial académico disponible para este estudiante.',
                    style: TextStyle(color: AppTheme.textMuted),
                  )
                else
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MetricChip(
                        label: 'Promedio general',
                        value: '${data.generalAverage.toStringAsFixed(1)}%',
                      ),
                      _MetricChip(
                        label: 'Asistencia promedio',
                        value: '${data.attendanceAverage.toStringAsFixed(1)}%',
                      ),
                      _MetricChip(
                        label: 'Aprobados',
                        value: data.approvedCourses.toString(),
                      ),
                      _MetricChip(
                        label: 'Reprobados',
                        value: data.failedCourses.toString(),
                      ),
                      _MetricChip(
                        label: 'Pendientes',
                        value: data.pendingCourses.toString(),
                      ),
                      _MetricChip(
                        label: 'GPA 4.0',
                        value: data.gpa4.toStringAsFixed(2),
                      ),
                      _MetricChip(
                        label: 'Estado académico',
                        value: data.academicStanding,
                      ),
                    ],
                  ),
                if (data != null && data.rankingTotal > 0) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'Ranking académico',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _MetricChip(
                        label: 'Posición',
                        value: '#${data.rankingPosition}',
                      ),
                      _MetricChip(
                        label: 'Total estudiantes',
                        value: data.rankingTotal.toString(),
                      ),
                      _MetricChip(
                        label: 'Percentil',
                        value: '${data.rankingPercentile.toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                ],
                if (data != null && data.distinctions.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'Distinciones automáticas',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: data.distinctions
                        .map((item) => Chip(
                              avatar:
                                  const Icon(Icons.workspace_premium_rounded),
                              label: Text(item),
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    OutlinedButton.icon(
                      onPressed: data == null || data.courses.isEmpty
                          ? null
                          : exportTranscriptPdf,
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text('Exportar PDF'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Volver'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          if (data != null && data.courses.isNotEmpty)
            ...data.courses.map(
              (course) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SectionCard(
                  child: ListTile(
                    leading: Icon(
                      course.hasGrades && course.approved
                          ? Icons.verified_rounded
                          : course.hasGrades
                              ? Icons.warning_rounded
                              : Icons.pending_actions_rounded,
                      color: course.hasGrades && course.approved
                          ? AppTheme.success
                          : Colors.orange,
                    ),
                    title: Text(
                      course.courseName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: Text(
                      'Promedio: ${course.hasGrades ? '${course.average.toStringAsFixed(1)}%' : 'Sin evaluar'} · '
                      'Asistencia: ${course.hasAttendance ? '${course.attendanceRate.toStringAsFixed(1)}%' : 'Sin registro'} · '
                      'Evaluaciones: ${course.evaluations}',
                    ),
                    trailing: Text(
                      !course.hasGrades
                          ? 'Pendiente'
                          : course.approved
                              ? 'Aprobado'
                              : 'Reprobado',
                      style: TextStyle(
                        color: !course.hasGrades
                            ? AppTheme.textMuted
                            : course.approved
                                ? AppTheme.success
                                : Colors.redAccent,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
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
