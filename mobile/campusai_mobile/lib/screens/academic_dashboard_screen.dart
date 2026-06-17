import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/academic_analytics_service.dart';
import '../services/course_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class AcademicDashboardScreen extends StatefulWidget {
  const AcademicDashboardScreen({super.key});

  @override
  State<AcademicDashboardScreen> createState() =>
      _AcademicDashboardScreenState();
}

class _AcademicDashboardScreenState extends State<AcademicDashboardScreen> {
  List<CourseRecord> courses = [];
  String activeCourseId = '';
  List<StudentAcademicSummary> summaries = [];

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final loadedCourses = await CourseService.getCourses();
    final storedActiveCourseId = await CourseService.getActiveCourseId();

    final resolvedActiveCourseId = storedActiveCourseId.isNotEmpty
        ? storedActiveCourseId
        : (loadedCourses.isNotEmpty ? loadedCourses.first.id : '');

    final activeCourse = loadedCourses
        .where((item) => item.id == resolvedActiveCourseId)
        .cast<CourseRecord?>()
        .firstOrNull;

    final data = activeCourse == null
        ? <StudentAcademicSummary>[]
        : await AcademicAnalyticsService.buildFinalReport(
            courseId: activeCourse.id,
            courseName: activeCourse.name,
          );

    if (!mounted) return;

    setState(() {
      courses = loadedCourses;
      activeCourseId = resolvedActiveCourseId;
      summaries = data;
    });
  }

  Future<void> changeCourse(String? courseId) async {
    if (courseId == null) return;
    await CourseService.setActiveCourse(courseId);
    await loadDashboard();
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

  List<StudentAcademicSummary> get topStudents {
    final data = [...summaries];
    data.sort((a, b) => b.average.compareTo(a.average));
    return data.take(5).toList();
  }

  List<StudentAcademicSummary> get riskStudents {
    final data = summaries
        .where((item) => item.average < 70 || item.attendanceRate < 75)
        .toList();
    data.sort((a, b) => a.average.compareTo(b.average));
    return data.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final reprobados = summaries.length - approvedCount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Académico'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard Académico por Curso',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Resumen ejecutivo de rendimiento, asistencia y riesgo académico.',
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
                              child: Text(course.displayName),
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
                    _MetricCard(
                      label: 'Estudiantes',
                      value: summaries.length.toString(),
                      icon: Icons.groups_rounded,
                    ),
                    _MetricCard(
                      label: 'Promedio',
                      value: '${average.toStringAsFixed(1)}%',
                      icon: Icons.analytics_rounded,
                    ),
                    _MetricCard(
                      label: 'Asistencia',
                      value: '${attendanceAverage.toStringAsFixed(1)}%',
                      icon: Icons.event_available_rounded,
                    ),
                    _MetricCard(
                      label: 'Aprobados',
                      value: approvedCount.toString(),
                      icon: Icons.verified_rounded,
                    ),
                    _MetricCard(
                      label: 'En riesgo',
                      value: reprobados.toString(),
                      icon: Icons.warning_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: () => context.goNamed('dashboard'),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Volver al Dashboard'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _RankingSection(
            title: 'Top estudiantes',
            emptyText: 'No hay datos suficientes para ranking.',
            students: topStudents,
          ),
          const SizedBox(height: 14),
          _RankingSection(
            title: 'Estudiantes en riesgo',
            emptyText: 'No hay estudiantes en riesgo detectados.',
            students: riskStudents,
            riskMode: true,
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.accent),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankingSection extends StatelessWidget {
  final String title;
  final String emptyText;
  final List<StudentAcademicSummary> students;
  final bool riskMode;

  const _RankingSection({
    required this.title,
    required this.emptyText,
    required this.students,
    this.riskMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          if (students.isEmpty)
            Text(
              emptyText,
              style: const TextStyle(color: AppTheme.textMuted),
            )
          else
            ...students.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _StudentRankTile(
                      position: entry.key + 1,
                      summary: entry.value,
                      riskMode: riskMode,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _StudentRankTile extends StatelessWidget {
  final int position;
  final StudentAcademicSummary summary;
  final bool riskMode;

  const _StudentRankTile({
    required this.position,
    required this.summary,
    required this.riskMode,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        context.goNamed(
          'student-profile',
          extra: {
            'studentCode': summary.studentCode,
            'studentName': summary.studentName,
            'courseId': summary.courseId,
            'courseName': summary.courseName,
          },
        );
      },
      leading: CircleAvatar(
        child: Text(position.toString()),
      ),
      title: Text(summary.studentName),
      subtitle: Text(
        '${summary.studentCode} · Promedio ${summary.average.toStringAsFixed(1)}% · Asistencia ${summary.attendanceRate.toStringAsFixed(1)}%',
      ),
      trailing: Icon(
        riskMode ? Icons.warning_rounded : Icons.star_rounded,
        color: riskMode ? Colors.orange : AppTheme.accent,
      ),
    );
  }
}
