import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/attendance_service.dart';
import '../services/academic_period_lock_service.dart';
import '../services/course_service.dart';
import '../services/api_service.dart';
import '../services/student_roster_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  List<StudentRecord> students = [];
  List<CourseRecord> courses = [];
  String activeCourseId = '';
  List<AttendanceEntry> savedEntries = [];
  final Map<String, String> statuses = {};
  final Map<String, TextEditingController> noteControllers = {};
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    for (final controller in noteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String get dateKey {
    final y = selectedDate.year.toString().padLeft(4, '0');
    final m = selectedDate.month.toString().padLeft(2, '0');
    final d = selectedDate.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
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
          'El período académico está cerrado. No se permiten cambios en asistencia.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );

    return false;
  }

  Future<void> loadData() async {
    final roster = await StudentRosterService.getStudents();

    final entries = await AttendanceService.getEntries();
    final loadedCourses = await CourseService.getCourses();
    final storedActiveCourseId = await CourseService.getActiveCourseId();

    final resolvedActiveCourseId = storedActiveCourseId.isNotEmpty
        ? storedActiveCourseId
        : (loadedCourses.isNotEmpty ? loadedCourses.first.id : '');

    final activeCourse = loadedCourses
        .where((item) => item.id == resolvedActiveCourseId)
        .cast<CourseRecord?>()
        .firstOrNull;

    final filteredRoster = activeCourse == null
        ? roster
        : roster
            .where(
              (student) =>
                  student.courseId == activeCourse.id ||
                  student.course.toLowerCase().trim() ==
                      activeCourse.name.toLowerCase().trim(),
            )
            .toList();

    if (!mounted) return;

    setState(() {
      courses = loadedCourses;
      activeCourseId = resolvedActiveCourseId;
      students = filteredRoster;
      savedEntries = activeCourse == null
          ? entries
          : entries
              .where(
                (entry) =>
                    entry.courseId == activeCourse.id ||
                    entry.course.toLowerCase().trim() ==
                        activeCourse.name.toLowerCase().trim(),
              )
              .toList();

      for (final student in roster) {
        final existing = entries.where(
          (item) =>
              item.date == dateKey &&
              item.studentId == student.id &&
              item.courseId == activeCourseId,
        );

        statuses[student.id] =
            existing.isNotEmpty ? existing.first.status : 'Presente';

        noteControllers.putIfAbsent(
          student.id,
          () => TextEditingController(
            text: existing.isNotEmpty ? existing.first.note : '',
          ),
        );
      }
    });
  }

  Future<void> changeCourse(String? courseId) async {
    if (courseId == null) return;

    await CourseService.setActiveCourse(courseId);

    setState(() {
      activeCourseId = courseId;
      statuses.clear();
      for (final controller in noteControllers.values) {
        controller.clear();
      }
    });

    await loadData();
  }

  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      selectedDate = picked;
      statuses.clear();
      for (final controller in noteControllers.values) {
        controller.clear();
      }
    });

    await loadData();
  }

  Future<void> saveAttendance() async {
    final entries = students.map((student) {
      return AttendanceEntry(
        id: '${student.id}_${activeCourseId}_$dateKey',
        studentId: student.id,
        studentName: student.name,
        course: student.course,
        courseId: activeCourseId,
        date: dateKey,
        status: statuses[student.id] ?? 'Presente',
        note: noteControllers[student.id]?.text.trim() ?? '',
      );
    }).toList();

    if (!await ensurePeriodOpen()) return;

    await AttendanceService.saveEntriesForDate(
      date: dateKey,
      entries: entries,
    );

    await loadData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Asistencia guardada correctamente.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> exportCsv() async {
    await AttendanceService.exportCsv();
  }

  Future<void> importAttendanceCsv() async {
    if (!await ensurePeriodOpen()) return;

    final count = await AttendanceService.importAttendanceCsvFromUser();

    await loadData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Registros de asistencia importados: $count'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> importStudentsPdf() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const AlertDialog(
          title: Text('Importando estudiantes desde PDF'),
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
                  'StudyBook AI está leyendo el PDF y detectando estudiantes...',
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      final data = await ApiService.importStudentsPdf();
      final rawStudents = data['students'];

      final imported = <StudentRecord>[];

      if (rawStudents is List) {
        for (var i = 0; i < rawStudents.length; i++) {
          final raw = rawStudents[i];
          if (raw is! Map) continue;

          final item = Map<String, dynamic>.from(raw);
          final name = item['name']?.toString().trim() ?? '';
          if (name.isEmpty) continue;

          final course = item['course']?.toString().trim() ?? '';
          final email = item['email']?.toString().trim() ?? '';
          final code = item['student_code']?.toString().trim() ?? '';

          final id = code.isNotEmpty
              ? code
              : '${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}_${course.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}_$i';

          imported.add(
            StudentRecord(
              id: id,
              name: name,
              course: course,
              email: email,
              studentCode: code,
            ),
          );
        }
      }

      final current = await StudentRosterService.getStudents();
      final merged = [...current];

      for (final student in imported) {
        merged.removeWhere(
          (item) =>
              item.name.toLowerCase().trim() ==
                  student.name.toLowerCase().trim() &&
              item.course.toLowerCase().trim() ==
                  student.course.toLowerCase().trim(),
        );
        merged.add(student);
      }

      merged.sort((a, b) => a.name.compareTo(b.name));
      await StudentRosterService.saveStudents(merged);

      await loadData();

      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Estudiantes importados desde PDF: ${imported.length}'),
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
          content: Text('No se pudo importar el PDF: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  int countStatus(String status) {
    return students
        .where((student) => (statuses[student.id] ?? 'Presente') == status)
        .length;
  }

  double get attendancePercentage {
    if (students.isEmpty) return 0;

    final present = countStatus('Presente') + countStatus('Tardanza');
    final percentage = (present / students.length) * 100;
    return percentage.clamp(0, 100).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final present = countStatus('Presente');
    final absent = countStatus('Ausente');
    final late = countStatus('Tardanza');
    final excused = countStatus('Excusa');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Asistencia'),
        actions: [
          IconButton(
            tooltip: 'Importar estudiantes desde PDF',
            onPressed: importStudentsPdf,
            icon: const Icon(Icons.picture_as_pdf_rounded),
          ),
          IconButton(
            tooltip: 'Importar asistencia CSV / Excel',
            onPressed: importAttendanceCsv,
            icon: const Icon(Icons.upload_file_rounded),
          ),
          IconButton(
            tooltip: 'Exportar CSV para Excel',
            onPressed: savedEntries.isEmpty ? null : exportCsv,
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
                  'Control de Asistencia',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Fecha: $dateKey',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w700,
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
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MetricChip(label: 'Presente', value: present.toString()),
                    _MetricChip(label: 'Ausente', value: absent.toString()),
                    _MetricChip(label: 'Tardanza', value: late.toString()),
                    _MetricChip(label: 'Excusa', value: excused.toString()),
                    _MetricChip(
                      label: 'Asistencia',
                      value: '${attendancePercentage.toStringAsFixed(1)}%',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: students.isEmpty ? null : saveAttendance,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Guardar asistencia'),
                    ),
                    OutlinedButton.icon(
                      onPressed: pickDate,
                      icon: const Icon(Icons.calendar_month_rounded),
                      label: const Text('Cambiar fecha'),
                    ),
                    OutlinedButton.icon(
                      onPressed: importStudentsPdf,
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text('Importar PDF'),
                    ),
                    OutlinedButton.icon(
                      onPressed: importAttendanceCsv,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Importar CSV / Excel'),
                    ),
                    OutlinedButton.icon(
                      onPressed: savedEntries.isEmpty ? null : exportCsv,
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
          if (students.isEmpty)
            const SectionCard(
              child: Text(
                'No hay estudiantes registrados. Agrega o importa estudiantes desde la pantalla de Rúbrica.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            )
          else
            ...students.map(
              (student) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _AttendanceStudentCard(
                  student: student,
                  status: statuses[student.id] ?? 'Presente',
                  noteController: noteControllers.putIfAbsent(
                    student.id,
                    () => TextEditingController(),
                  ),
                  onStatusChanged: (value) {
                    setState(() {
                      statuses[student.id] = value;
                    });
                  },
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
    return Chip(
      label: Text('$label: $value'),
    );
  }
}

class _AttendanceStudentCard extends StatelessWidget {
  final StudentRecord student;
  final String status;
  final TextEditingController noteController;
  final ValueChanged<String> onStatusChanged;

  const _AttendanceStudentCard({
    required this.student,
    required this.status,
    required this.noteController,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    const options = ['Presente', 'Ausente', 'Tardanza', 'Excusa'];

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            student.name,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              if (student.studentCode.isNotEmpty)
                Chip(
                  label: Text('Código: ${student.studentCode}'),
                ),
              if (student.course.isNotEmpty)
                Chip(
                  label: Text(student.course),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((option) {
              return ChoiceChip(
                label: Text(option),
                selected: status == option,
                onSelected: (_) => onStatusChanged(option),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Nota u observación',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
