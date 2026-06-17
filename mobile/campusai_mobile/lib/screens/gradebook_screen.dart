import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/gradebook_service.dart';
import '../services/api_service.dart';
import '../services/course_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class GradebookScreen extends StatefulWidget {
  const GradebookScreen({super.key});

  @override
  State<GradebookScreen> createState() => _GradebookScreenState();
}

class _GradebookScreenState extends State<GradebookScreen> {
  List<GradebookEntry> entries = [];
  List<CourseRecord> courses = [];
  String activeCourseId = '';

  @override
  void initState() {
    super.initState();
    loadEntries();
  }

  Future<void> loadEntries() async {
    final data = await GradebookService.getEntries();

    await CourseService.ensureCoursesFromNames(
      data.map((item) => item.course).toList(),
    );

    final loadedCourses = await CourseService.getCourses();
    final storedActiveCourseId = await CourseService.getActiveCourseId();

    final resolvedActiveCourseId = storedActiveCourseId.isNotEmpty
        ? storedActiveCourseId
        : (loadedCourses.isNotEmpty ? loadedCourses.first.id : '');

    final activeCourse = loadedCourses
        .where((item) => item.id == resolvedActiveCourseId)
        .cast<CourseRecord?>()
        .firstOrNull;

    final filteredEntries = activeCourse == null
        ? data
        : data
            .where(
              (entry) =>
                  entry.course.toLowerCase().trim() ==
                  activeCourse.name.toLowerCase().trim(),
            )
            .toList();

    if (!mounted) return;

    setState(() {
      courses = loadedCourses;
      activeCourseId = resolvedActiveCourseId;
      entries = filteredEntries;
    });
  }

  Future<void> changeCourse(String? courseId) async {
    if (courseId == null) return;

    await CourseService.setActiveCourse(courseId);

    setState(() {
      activeCourseId = courseId;
    });

    await loadEntries();
  }

  double get average {
    if (entries.isEmpty) return 0;
    final values = entries
        .where((item) => item.maxScore > 0)
        .map((item) => (item.score / item.maxScore) * 100)
        .toList();

    if (values.isEmpty) return 0;

    return values.reduce((a, b) => a + b) / values.length;
  }

  Future<void> importGradesExcel() async {
    final activeCourse = courses
        .where((item) => item.id == activeCourseId)
        .cast<CourseRecord?>()
        .firstOrNull;

    if (activeCourse == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const AlertDialog(
          title: Text('Importando notas desde Excel'),
          content: Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(width: 18),
              Expanded(
                child: Text(
                  'StudyBook AI está leyendo el Excel y organizando las calificaciones...',
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      final data = await ApiService.importGradesExcel();
      final rawGrades = data['grades'];

      var count = 0;

      if (rawGrades is List) {
        final entries = await GradebookService.getEntries();

        for (var i = 0; i < rawGrades.length; i++) {
          final raw = rawGrades[i];
          if (raw is! Map) continue;

          final item = Map<String, dynamic>.from(raw);

          final studentCode = item['student_code']?.toString().trim() ?? '';
          final studentName = item['student_name']?.toString().trim() ?? '';
          final assessment = item['assessment']?.toString().trim() ??
              'Evaluación importada';

          final score = double.tryParse(item['score']?.toString() ?? '') ?? 0;
          final maxScore =
              double.tryParse(item['max_score']?.toString() ?? '') ?? 100;

          if (studentCode.isEmpty && studentName.isEmpty) continue;

          entries.insert(
            0,
            GradebookEntry(
              id: '${activeCourse.id}_${studentCode}_${assessment}_${DateTime.now().millisecondsSinceEpoch}_$i',
              studentId: studentCode,
              studentCode: studentCode,
              studentName: studentName.isEmpty ? studentCode : studentName,
              course: activeCourse.name,
              courseId: activeCourse.id,
              rubricTitle: assessment,
              score: score,
              maxScore: maxScore,
              createdAt: DateTime.now().toIso8601String(),
              notes: 'Importado desde Excel',
            ),
          );

          count++;
        }

        for (final entry in entries) {
          await GradebookService.saveEntry(entry);
        }
      }

      await loadEntries();

      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notas Excel importadas: $count'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo importar Excel: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> importGradesCsv() async {
    final activeCourse = courses
        .where((item) => item.id == activeCourseId)
        .cast<CourseRecord?>()
        .firstOrNull;

    if (activeCourse == null) return;

    final count = await GradebookService.importGradesCsvFromUser(
      courseId: activeCourse.id,
      courseName: activeCourse.name,
    );

    await loadEntries();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notas importadas: $count'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> exportCsv() async {
    await GradebookService.exportCsv();
  }

  Future<void> deleteEntry(GradebookEntry entry) async {
    await GradebookService.deleteEntry(entry.id);
    await loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Libro de Calificaciones'),
        actions: [
          IconButton(
            tooltip: 'Importar notas Excel',
            onPressed: courses.isEmpty ? null : importGradesExcel,
            icon: const Icon(Icons.table_chart_rounded),
          ),
          IconButton(
            tooltip: 'Importar notas CSV',
            onPressed: courses.isEmpty ? null : importGradesCsv,
            icon: const Icon(Icons.upload_file_rounded),
          ),
          IconButton(
            tooltip: 'Exportar CSV para Excel',
            onPressed: entries.isEmpty ? null : exportCsv,
            icon: const Icon(Icons.download_rounded),
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
                  'Libro de Calificaciones',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Consulta, exporta y administra las evaluaciones guardadas desde las rúbricas.',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
                if (courses.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: 360,
                    child: DropdownButtonFormField<String>(
                      initialValue: activeCourseId.isEmpty ? null : activeCourseId,
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
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricChip(
                      label: 'Evaluaciones',
                      value: entries.length.toString(),
                      icon: Icons.assignment_turned_in_rounded,
                    ),
                    _MetricChip(
                      label: 'Promedio',
                      value: '${average.toStringAsFixed(1)}%',
                      icon: Icons.analytics_rounded,
                    ),
                    FilledButton.icon(
                      onPressed: courses.isEmpty ? null : importGradesExcel,
                      icon: const Icon(Icons.table_chart_rounded),
                      label: const Text('Importar notas Excel'),
                    ),
                    OutlinedButton.icon(
                      onPressed: courses.isEmpty ? null : importGradesCsv,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Importar notas CSV'),
                    ),
                    OutlinedButton.icon(
                      onPressed: entries.isEmpty ? null : exportCsv,
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Exportar CSV para Excel'),
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
          if (entries.isEmpty)
            const SectionCard(
              child: Text(
                'Todavía no hay evaluaciones guardadas.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            )
          else
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _GradebookEntryCard(
                  entry: entry,
                  onDelete: () => deleteEntry(entry),
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
  final IconData icon;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text('$label: $value'),
    );
  }
}

class _GradebookEntryCard extends StatelessWidget {
  final GradebookEntry entry;
  final VoidCallback onDelete;

  const _GradebookEntryCard({
    required this.entry,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = entry.maxScore <= 0
        ? 0
        : (entry.score / entry.maxScore) * 100;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_rounded, color: AppTheme.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.studentName,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Eliminar evaluación',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
            ],
          ),
          if (entry.studentCode.isNotEmpty) ...[
            const SizedBox(height: 6),
            Chip(label: Text('Código: ${entry.studentCode}')),
          ],
          const SizedBox(height: 8),
          Text(
            entry.rubricTitle,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Curso: ${entry.course.isEmpty ? 'No especificado' : entry.course}',
            style: const TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (percentage / 100).clamp(0, 1),
          ),
          const SizedBox(height: 8),
          Text(
            '${entry.score.toStringAsFixed(1)} / ${entry.maxScore.toStringAsFixed(1)} puntos (${percentage.toStringAsFixed(1)}%)',
            style: const TextStyle(
              color: AppTheme.accent,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fecha: ${entry.createdAt}',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
