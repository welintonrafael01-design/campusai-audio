import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/gradebook_service.dart';
import '../services/academic_period_lock_service.dart';
import '../services/student_roster_service.dart';
import '../services/api_service.dart';
import '../services/course_service.dart';
import '../services/assessment_weight_service.dart';
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
  List<AssessmentWeight> weights = [];
  String activeCourseId = '';

  @override
  void initState() {
    super.initState();
    loadEntries();
  }


  Future<bool> ensurePeriodOpen() async {
    final courseId = activeCourseId.trim();

    if (courseId.isEmpty) return true;

    final closed = await AcademicPeriodLockService.isClosed(courseId);

    if (!closed) return true;

    if (!mounted) return false;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'El período académico está cerrado. No se permiten cambios en calificaciones.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    return false;
  }

  Future<void> loadEntries() async {
    final data = await GradebookService.getEntries();

    var loadedCourses = await CourseService.getCourses();

    if (loadedCourses.isEmpty) {
      final students = await StudentRosterService.getStudents();
      final recovered = <CourseRecord>[];

      for (final student in students) {
        final courseName = student.course.trim();
        if (courseName.isEmpty) continue;

        final courseId = student.courseId.trim().isNotEmpty
            ? student.courseId.trim()
            : CourseService.buildId(courseName);

        if (recovered.any((item) => item.id == courseId)) continue;

        recovered.add(
          CourseRecord(
            id: courseId,
            name: courseName,
          ),
        );
      }

      for (final entry in data) {
        final courseName = entry.course.trim();
        if (courseName.isEmpty) continue;

        final courseId = entry.courseId.trim().isNotEmpty
            ? entry.courseId.trim()
            : CourseService.buildId(courseName);

        if (recovered.any((item) => item.id == courseId)) continue;

        recovered.add(
          CourseRecord(
            id: courseId,
            name: courseName,
          ),
        );
      }

      if (recovered.isNotEmpty) {
        await CourseService.saveCourses(recovered);
        await CourseService.setActiveCourse(recovered.first.id);
        loadedCourses = recovered;
      }
    }

    final storedActiveCourseId = await CourseService.getActiveCourseId();

    final resolvedActiveCourseId = storedActiveCourseId.isNotEmpty
        ? storedActiveCourseId
        : (loadedCourses.isNotEmpty ? loadedCourses.first.id : '');

    final activeCourse = loadedCourses
        .where((item) => item.id == resolvedActiveCourseId)
        .cast<CourseRecord?>()
        .firstOrNull;

    final loadedWeights = activeCourse == null
        ? <AssessmentWeight>[]
        : await AssessmentWeightService.getWeights(activeCourse.id);

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
      weights = loadedWeights;
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

  Future<void> importGradesPdf() async {
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
          title: Text('Importando notas desde PDF'),
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
                  'StudyBook AI está leyendo el PDF y detectando calificaciones...',
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      final data = await ApiService.importGradesPdf();
      final rawGrades = data['grades'];

      var count = 0;

      if (rawGrades is List) {
        final currentEntries = await GradebookService.getEntries();

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

          currentEntries.insert(
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
              notes: 'Importado desde PDF',
            ),
          );

          count++;
        }

        for (final entry in currentEntries) {
          if (!await ensurePeriodOpen()) return;
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
          content: Text('Notas PDF importadas: $count'),
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
          content: Text('No se pudo importar PDF: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
          if (!await ensurePeriodOpen()) return;
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

    if (!await ensurePeriodOpen()) return;

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
    if (!await ensurePeriodOpen()) return;

    await GradebookService.deleteEntry(entry.id);
    await loadEntries();
  }




  List<String> get assessmentColumns {
    final names = <String>{};

    for (final entry in entries) {
      final clean = entry.rubricTitle.trim();
      if (clean.isNotEmpty) {
        names.add(clean);
      }
    }

    final ordered = names.toList()..sort();
    return ordered;
  }

  List<_StudentGradeRow> get gradeRows {
    final grouped = <String, List<GradebookEntry>>{};

    for (final entry in entries) {
      final key = entry.studentCode.trim().isNotEmpty
          ? entry.studentCode.trim()
          : entry.studentName.trim().toLowerCase();

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(entry);
    }

    final rows = <_StudentGradeRow>[];

    for (final item in grouped.entries) {
      final data = item.value;
      if (data.isEmpty) continue;

      final first = data.first;
      final scores = <String, double>{};
      final maxScores = <String, double>{};

      for (final entry in data) {
        final assessment = entry.rubricTitle.trim().isEmpty
            ? 'Evaluación'
            : entry.rubricTitle.trim();

        scores[assessment] = entry.score;
        maxScores[assessment] = entry.maxScore;
      }

      rows.add(
        _StudentGradeRow(
          studentKey: item.key,
          studentName: first.studentName,
          studentCode: first.studentCode,
          scores: scores,
          maxScores: maxScores,
        ),
      );
    }

    rows.sort((a, b) => a.studentName.compareTo(b.studentName));
    return rows;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Libro de Calificaciones'),
        actions: [
          IconButton(
            tooltip: 'Importar notas PDF',
            onPressed: courses.isEmpty ? null : importGradesPdf,
            icon: const Icon(Icons.picture_as_pdf_rounded),
          ),
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
                      isExpanded: true,
                      initialValue: activeCourseId.isEmpty ? null : activeCourseId,
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
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricChip(
                      label: 'Evaluaciones',
                      value: entries.length.toString(),
                      icon: Icons.assignment_turned_in_rounded,
                    ),
                    _MetricChip(
                      label: weights.isEmpty ? 'Promedio' : 'Ponderaciones',
                      value: weights.isEmpty
                          ? '${average.toStringAsFixed(1)}%'
                          : '${weights.fold<double>(0, (total, item) => total + item.weight).toStringAsFixed(1)}%',
                      icon: Icons.analytics_rounded,
                    ),
                    FilledButton.icon(
                      onPressed: courses.isEmpty ? null : importGradesPdf,
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text('Importar notas PDF'),
                    ),
                    OutlinedButton.icon(
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
          else ...[
            _GradebookTable(
              rows: gradeRows,
              assessments: assessmentColumns,
            ),
            const SizedBox(height: 20),
            const Text(
              'Detalle de evaluaciones',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
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
        ],
      ),
    );
  }
}


class _StudentGradeRow {
  final String studentKey;
  final String studentName;
  final String studentCode;
  final Map<String, double> scores;
  final Map<String, double> maxScores;

  const _StudentGradeRow({
    required this.studentKey,
    required this.studentName,
    required this.studentCode,
    required this.scores,
    required this.maxScores,
  });

  double percentageFor(String assessment) {
    final score = scores[assessment] ?? 0;
    final max = maxScores[assessment] ?? 0;
    if (max <= 0) return 0;
    return (score / max) * 100;
  }

  double get average {
    final values = scores.keys
        .map(percentageFor)
        .where((value) => value > 0)
        .toList();

    if (values.isEmpty) return 0;

    return values.reduce((a, b) => a + b) / values.length;
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


class _GradebookTable extends StatelessWidget {
  final List<_StudentGradeRow> rows;
  final List<String> assessments;

  const _GradebookTable({
    required this.rows,
    required this.assessments,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vista académica consolidada',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Calificaciones agrupadas por estudiante y evaluación.',
            style: TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 16),
          if (rows.isEmpty || assessments.isEmpty)
            const Text(
              'No hay datos suficientes para construir la tabla.',
              style: TextStyle(color: AppTheme.textMuted),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 44,
                dataRowMinHeight: 46,
                dataRowMaxHeight: 56,
                columns: [
                  const DataColumn(label: Text('Matrícula')),
                  const DataColumn(label: Text('Estudiante')),
                  ...assessments.map(
                    (assessment) => DataColumn(
                      label: SizedBox(
                        width: 110,
                        child: Text(
                          assessment,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ),
                  ),
                  const DataColumn(label: Text('Promedio')),
                  const DataColumn(label: Text('Estado')),
                ],
                rows: rows.map((row) {
                  final average = row.average;
                  final approved = average >= 70;

                  return DataRow(
                    cells: [
                      DataCell(Text(row.studentCode.isEmpty ? '-' : row.studentCode)),
                      DataCell(
                        SizedBox(
                          width: 180,
                          child: Text(
                            row.studentName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      ...assessments.map(
                        (assessment) {
                          final hasScore = row.scores.containsKey(assessment);
                          final value = hasScore
                              ? '${row.percentageFor(assessment).toStringAsFixed(1)}%'
                              : '-';

                          return DataCell(Text(value));
                        },
                      ),
                      DataCell(
                        Text(
                          '${average.toStringAsFixed(1)}%',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      DataCell(
                        Chip(
                          label: Text(approved ? 'Aprobado' : 'Riesgo'),
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
