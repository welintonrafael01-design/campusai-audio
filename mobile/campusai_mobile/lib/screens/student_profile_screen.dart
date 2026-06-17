import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/attendance_service.dart';
import '../services/gradebook_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class StudentProfileScreen extends StatefulWidget {
  final String studentCode;
  final String studentName;
  final String courseId;
  final String courseName;

  const StudentProfileScreen({
    super.key,
    required this.studentCode,
    required this.studentName,
    required this.courseId,
    required this.courseName,
  });

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  List<GradebookEntry> grades = [];
  List<AttendanceEntry> attendance = [];

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final allGrades = await GradebookService.getEntries();
    final allAttendance = await AttendanceService.getEntries();

    final filteredGrades = allGrades.where((entry) {
      final sameCourse = entry.courseId.isNotEmpty
          ? entry.courseId == widget.courseId
          : entry.course.toLowerCase().trim() ==
              widget.courseName.toLowerCase().trim();

      final sameStudentCode = widget.studentCode.isNotEmpty &&
          entry.studentCode.toLowerCase().trim() ==
              widget.studentCode.toLowerCase().trim();

      final sameStudentName = entry.studentName.toLowerCase().trim() ==
          widget.studentName.toLowerCase().trim();

      return sameCourse && (sameStudentCode || sameStudentName);
    }).toList();

    final filteredAttendance = allAttendance.where((entry) {
      final sameCourse = entry.courseId.isNotEmpty
          ? entry.courseId == widget.courseId
          : entry.course.toLowerCase().trim() ==
              widget.courseName.toLowerCase().trim();

      final sameStudentCode = widget.studentCode.isNotEmpty &&
          entry.studentId.toLowerCase().trim() ==
              widget.studentCode.toLowerCase().trim();

      final sameStudentName = entry.studentName.toLowerCase().trim() ==
          widget.studentName.toLowerCase().trim();

      return sameCourse && (sameStudentCode || sameStudentName);
    }).toList();

    if (!mounted) return;

    setState(() {
      grades = filteredGrades;
      attendance = filteredAttendance;
    });
  }

  double get average {
    final values = grades
        .where((entry) => entry.maxScore > 0)
        .map((entry) => (entry.score / entry.maxScore) * 100)
        .toList();

    if (values.isEmpty) return 0;

    return values.reduce((a, b) => a + b) / values.length;
  }

  double get attendanceRate {
    if (attendance.isEmpty) return 0;

    final attended = attendance.where((entry) {
      final status = entry.status.toLowerCase().trim();
      return status == 'presente' ||
          status == 'tardanza' ||
          status == 'excusa';
    }).length;

    return (attended / attendance.length) * 100;
  }

  String get riskLevel {
    if (average < 60 || attendanceRate < 65) return 'Alto';
    if (average < 70 || attendanceRate < 75) return 'Medio';
    return 'Bajo';
  }

  String get recommendation {
    if (riskLevel == 'Alto') {
      return 'Requiere seguimiento inmediato por bajo rendimiento o asistencia insuficiente.';
    }

    if (riskLevel == 'Medio') {
      return 'Conviene reforzar contenidos y monitorear la asistencia en las próximas clases.';
    }

    return 'Mantiene un desempeño académico favorable. Se recomienda continuar el seguimiento regular.';
  }

  @override
  Widget build(BuildContext context) {
    final approved = average >= 70;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil del Estudiante'),
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
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (widget.studentCode.isNotEmpty)
                      Chip(label: Text('Código: ${widget.studentCode}')),
                    Chip(label: Text(widget.courseName)),
                    Chip(label: Text(approved ? 'Aprobado' : 'Reprobado')),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricChip(
                      label: 'Promedio',
                      value: '${average.toStringAsFixed(1)}%',
                    ),
                    _MetricChip(
                      label: 'Asistencia',
                      value: '${attendanceRate.toStringAsFixed(1)}%',
                    ),
                    _MetricChip(
                      label: 'Evaluaciones',
                      value: grades.length.toString(),
                    ),
                    _MetricChip(
                      label: 'Riesgo',
                      value: riskLevel,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () => context.goNamed('academic-dashboard'),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Volver al Dashboard Académico'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Indicador académico',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Riesgo académico: $riskLevel',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  recommendation,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Historial de calificaciones',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                if (grades.isEmpty)
                  const Text(
                    'No hay calificaciones registradas.',
                    style: TextStyle(color: AppTheme.textMuted),
                  )
                else
                  ...grades.map(
                    (entry) {
                      final percentage = entry.maxScore <= 0
                          ? 0
                          : (entry.score / entry.maxScore) * 100;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(entry.rubricTitle),
                        subtitle: Text(entry.createdAt),
                        trailing: Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: AppTheme.accent,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Historial de asistencia',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                if (attendance.isEmpty)
                  const Text(
                    'No hay asistencia registrada.',
                    style: TextStyle(color: AppTheme.textMuted),
                  )
                else
                  ...attendance.map(
                    (entry) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(entry.date),
                      subtitle: Text(entry.note.isEmpty ? 'Sin nota' : entry.note),
                      trailing: Chip(label: Text(entry.status)),
                    ),
                  ),
              ],
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
