import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api_service.dart';
import '../services/course_service.dart';
import '../services/export_service.dart';
import '../services/student_roster_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  List<StudentRecord> students = [];
  List<CourseRecord> courses = [];
  String activeCourseId = '';
  String query = '';
  StudentRecord? editingStudent;

  final searchController = TextEditingController();
  final nameController = TextEditingController();
  final codeController = TextEditingController();
  final emailController = TextEditingController();

  CourseRecord? get activeCourse {
    return courses
        .where((item) => item.id == activeCourseId)
        .cast<CourseRecord?>()
        .firstOrNull;
  }

  List<StudentRecord> get filteredStudents {
    final course = activeCourse;
    final q = query.toLowerCase().trim();

    return students.where((student) {
      final sameCourse = course == null
          ? true
          : (student.courseId == course.id ||
              student.course.toLowerCase().trim() ==
                  course.name.toLowerCase().trim());

      final matchesQuery = q.isEmpty ||
          student.name.toLowerCase().contains(q) ||
          student.studentCode.toLowerCase().contains(q) ||
          student.email.toLowerCase().contains(q);

      return sameCourse && matchesQuery;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    searchController.dispose();
    nameController.dispose();
    codeController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    final loadedStudents = await StudentRosterService.getStudents();
    final loadedCourses = await CourseService.getCourses();
    final storedCourseId = await CourseService.getActiveCourseId();

    if (!mounted) return;

    setState(() {
      students = loadedStudents;
      courses = loadedCourses;
      activeCourseId = storedCourseId.isNotEmpty
          ? storedCourseId
          : (loadedCourses.isNotEmpty ? loadedCourses.first.id : '');
    });
  }

  Future<void> changeCourse(String? courseId) async {
    if (courseId == null) return;
    await CourseService.setActiveCourse(courseId);
    await loadData();
  }

  void clearForm() {
    setState(() {
      editingStudent = null;
    });
    nameController.clear();
    codeController.clear();
    emailController.clear();
  }

  void editStudent(StudentRecord student) {
    setState(() {
      editingStudent = student;
    });

    nameController.text = student.name;
    codeController.text = student.studentCode;
    emailController.text = student.email;
  }

  Future<void> saveStudent() async {
    final course = activeCourse;

    if (course == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona o crea un curso primero.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final name = nameController.text.trim();
    final code = codeController.text.trim();
    final email = emailController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre del estudiante es obligatorio.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final student = StudentRecord(
      id: editingStudent?.id ??
          (code.isNotEmpty
              ? code
              : '${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}_${course.id}'),
      name: name,
      course: course.name,
      courseId: course.id,
      email: email,
      studentCode: code,
    );

    final updated = [...students];

    updated.removeWhere(
      (item) =>
          item.id == student.id ||
          (item.name.toLowerCase().trim() ==
                  student.name.toLowerCase().trim() &&
              item.courseId == student.courseId),
    );

    updated.add(student);

    await StudentRosterService.saveStudents(updated);

    clearForm();
    await loadData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Estudiante guardado correctamente.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> deleteStudent(StudentRecord student) async {
    final updated = [...students]..removeWhere((item) => item.id == student.id);
    await StudentRosterService.saveStudents(updated);
    await loadData();
  }

  void openProfile(StudentRecord student) {
    final course = activeCourse;

    context.goNamed(
      'student-profile',
      extra: {
        'studentCode':
            student.studentCode.isNotEmpty ? student.studentCode : student.id,
        'studentName': student.name,
        'courseId':
            student.courseId.isNotEmpty ? student.courseId : (course?.id ?? ''),
        'courseName':
            student.course.isNotEmpty ? student.course : (course?.name ?? ''),
      },
    );
  }

  List<Map<String, dynamic>> get exportRows {
    return filteredStudents.map((student) {
      return {
        'student_code': student.studentCode,
        'name': student.name,
        'course': student.course,
        'email': student.email,
      };
    }).toList();
  }

  Future<void> importCsv() async {
    final course = activeCourse;

    if (course == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona o crea un curso primero.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final imported = await StudentRosterService.importCsvFromUser();
    final current = await StudentRosterService.getStudents();

    final updated = current.map((student) {
      final isImported = imported.any(
        (item) =>
            item.name.toLowerCase().trim() == student.name.toLowerCase().trim(),
      );

      if (!isImported) return student;

      return StudentRecord(
        id: student.id,
        name: student.name,
        course: course.name,
        courseId: course.id,
        email: student.email,
        studentCode: student.studentCode,
      );
    }).toList();

    await StudentRosterService.saveStudents(updated);
    await loadData();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Estudiantes importados: ${imported.length}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> importPdf() async {
    final course = activeCourse;

    if (course == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona o crea un curso primero.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const AlertDialog(
          title: Text('Importando estudiantes'),
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

          final email = item['email']?.toString().trim() ?? '';
          final code = item['student_code']?.toString().trim() ?? '';

          imported.add(
            StudentRecord(
              id: code.isNotEmpty
                  ? code
                  : '${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}_${course.id}_$i',
              name: name,
              course: course.name,
              courseId: course.id,
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
              item.courseId == course.id,
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

      debugPrint('No se pudo importar estudiantes PDF (${error.runtimeType}).');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'No se pudo importar el PDF. Revisa el archivo e intenta nuevamente.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> exportExcel() async {
    final course = activeCourse;
    final title =
        'estudiantes_${course?.code.isNotEmpty == true ? course!.code : 'curso'}';

    await ExportService.exportRowsToXlsx(
      title: title,
      rows: exportRows,
    );
  }

  Future<void> exportPdf() async {
    final course = activeCourse;
    final buffer = StringBuffer();

    buffer.writeln('LISTADO DE ESTUDIANTES');
    buffer.writeln('Curso: ${course?.displayName ?? 'Curso activo'}');
    buffer.writeln('Total: ${filteredStudents.length}');
    buffer.writeln('');

    for (final student in filteredStudents) {
      buffer.writeln(
        '${student.studentCode.isEmpty ? '-' : student.studentCode} | ${student.name} | ${student.email}',
      );
    }

    await ExportService.exportTextToPdf(
      title:
          'estudiantes_${course?.code.isNotEmpty == true ? course!.code : 'curso'}',
      content: buffer.toString(),
    );
  }

  Future<void> exportCsv() async {
    final course = activeCourse;
    final safeCourse = (course?.displayName ?? 'curso')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    await StudentRosterService.exportCsvForStudents(
      students: filteredStudents,
      filename:
          'studybook_estudiantes_${safeCourse.isEmpty ? 'curso' : safeCourse}.csv',
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleStudents = filteredStudents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Estudiantes'),
        actions: [
          IconButton(
            tooltip: 'Exportar PDF',
            onPressed: filteredStudents.isEmpty ? null : exportPdf,
            icon: const Icon(Icons.picture_as_pdf_rounded),
          ),
          IconButton(
            tooltip: 'Exportar Excel',
            onPressed: filteredStudents.isEmpty ? null : exportExcel,
            icon: const Icon(Icons.grid_on_rounded),
          ),
          IconButton(
            tooltip: 'Exportar CSV',
            onPressed: filteredStudents.isEmpty ? null : exportCsv,
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
                  'Mis Estudiantes',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Administra estudiantes, cursos y perfiles académicos.',
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
                const SizedBox(height: 14),
                SizedBox(
                  width: 420,
                  child: TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      labelText: 'Buscar estudiante',
                      prefixIcon: Icon(Icons.search_rounded),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() => query = value);
                    },
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    Chip(label: Text('Estudiantes: ${visibleStudents.length}')),
                    FilledButton.icon(
                      onPressed: importPdf,
                      icon: const Icon(Icons.picture_as_pdf_rounded),
                      label: const Text('Importar PDF'),
                    ),
                    OutlinedButton.icon(
                      onPressed: importCsv,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Importar CSV / Excel'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.goNamed('courses'),
                      icon: const Icon(Icons.school_rounded),
                      label: const Text('Mis Cursos'),
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
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  editingStudent == null
                      ? 'Agregar estudiante'
                      : 'Editar estudiante',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 280,
                      child: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 180,
                      child: TextField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          labelText: 'Matrícula / Código',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 260,
                      child: TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Correo',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: saveStudent,
                      icon: const Icon(Icons.save_rounded),
                      label: Text(
                        editingStudent == null
                            ? 'Guardar estudiante'
                            : 'Actualizar estudiante',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: clearForm,
                      icon: const Icon(Icons.clear_rounded),
                      label: const Text('Limpiar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (visibleStudents.isEmpty)
            const SectionCard(
              child: Text(
                'No hay estudiantes para este curso.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            )
          else
            ...visibleStudents.map(
              (student) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SectionCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.person_rounded,
                      color: AppTheme.accent,
                    ),
                    title: Text(
                      student.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: Text(
                      [
                        if (student.studentCode.isNotEmpty)
                          'Código: ${student.studentCode}',
                        if (student.course.isNotEmpty) student.course,
                        if (student.email.isNotEmpty) student.email,
                      ].join(' · '),
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                    onTap: () => openProfile(student),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: 'Ver perfil',
                          onPressed: () => openProfile(student),
                          icon: const Icon(Icons.insights_rounded),
                        ),
                        IconButton(
                          tooltip: 'Editar',
                          onPressed: () => editStudent(student),
                          icon: const Icon(Icons.edit_rounded),
                        ),
                        IconButton(
                          tooltip: 'Eliminar',
                          onPressed: () => deleteStudent(student),
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
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
