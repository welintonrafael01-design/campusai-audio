import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/course_service.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<CourseRecord> courses = [];
  String activeCourseId = '';
  CourseRecord? editingCourse;

  final nameController = TextEditingController();
  final codeController = TextEditingController();
  final sectionController = TextEditingController();
  final periodController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadCourses();
  }

  @override
  void dispose() {
    nameController.dispose();
    codeController.dispose();
    sectionController.dispose();
    periodController.dispose();
    super.dispose();
  }

  Future<void> loadCourses() async {
    final loadedCourses = await CourseService.getCourses();
    final active = await CourseService.getActiveCourseId();

    if (!mounted) return;

    setState(() {
      courses = loadedCourses;
      activeCourseId = active;
    });
  }

  Future<void> saveCourse({CourseRecord? current}) async {
    final editing = current ?? editingCourse;

    final name = nameController.text.trim();
    final code = codeController.text.trim();
    final section = sectionController.text.trim();
    final period = periodController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre del curso es obligatorio.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final course = CourseRecord(
      id: editing?.id ??
          CourseService.buildId(
            name,
            section: section.isEmpty ? code : section,
            period: period,
          ),
      name: name,
      code: code.isEmpty ? CourseService.inferCourseCode(name) : code,
      section: section,
      period: period,
    );

    final updated = [...courses];

    updated.removeWhere((item) => item.id == course.id);
    updated.add(course);

    await CourseService.saveCourses(updated);
    await CourseService.setActiveCourse(course.id);

    clearForm();
    await loadCourses();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Curso guardado correctamente.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> selectCourse(CourseRecord course) async {
    await CourseService.setActiveCourse(course.id);
    await loadCourses();
  }

  Future<void> deleteCourse(CourseRecord course) async {
    final updated = [...courses]..removeWhere((item) => item.id == course.id);

    await CourseService.saveCourses(updated);

    if (activeCourseId == course.id && updated.isNotEmpty) {
      await CourseService.setActiveCourse(updated.first.id);
    }

    if (updated.isEmpty) {
      await CourseService.setActiveCourse('');
    }

    await loadCourses();
  }

  void editCourse(CourseRecord course) {
    setState(() {
      editingCourse = course;
    });

    nameController.text = course.name;
    codeController.text = course.code;
    sectionController.text = course.section;
    periodController.text = course.period;
  }

  void clearForm() {
    editingCourse = null;
    nameController.clear();
    codeController.clear();
    sectionController.clear();
    periodController.clear();
  }


  List<Map<String, dynamic>> get exportRows {
    return courses.map((course) {
      return {
        'code': course.code,
        'name': course.name,
        'section': course.section,
        'period': course.period,
        'active': course.id == activeCourseId ? 'Sí' : 'No',
      };
    }).toList();
  }

  Future<void> exportExcel() async {
    await ExportService.exportRowsToXlsx(
      title: 'studybook_cursos',
      rows: exportRows,
    );
  }

  Future<void> exportPdf() async {
    final buffer = StringBuffer();

    buffer.writeln('LISTADO DE CURSOS');
    buffer.writeln('Total: ${courses.length}');
    buffer.writeln('');

    for (final course in courses) {
      buffer.writeln(
        '${course.code} | ${course.name} | ${course.section} | ${course.period} | ${course.id == activeCourseId ? 'Activo' : ''}',
      );
    }

    await ExportService.exportTextToPdf(
      title: 'studybook_cursos',
      content: buffer.toString(),
    );
  }

  Future<void> exportCsv() async {
    await CourseService.exportCsv();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Cursos'),
        actions: [
          IconButton(
            tooltip: 'Exportar PDF',
            onPressed: courses.isEmpty ? null : exportPdf,
            icon: const Icon(Icons.picture_as_pdf_rounded),
          ),
          IconButton(
            tooltip: 'Exportar Excel',
            onPressed: courses.isEmpty ? null : exportExcel,
            icon: const Icon(Icons.grid_on_rounded),
          ),
          IconButton(
            tooltip: 'Exportar CSV',
            onPressed: courses.isEmpty ? null : exportCsv,
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
                  'Mis Cursos',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Crea, edita y selecciona el curso activo para el Centro Educator.',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
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
                const Text(
                  'Crear / editar curso',
                  style: TextStyle(
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
                          labelText: 'Nombre del curso',
                          hintText: 'Derecho Empresarial',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: codeController,
                        decoration: const InputDecoration(
                          labelText: 'Código',
                          hintText: 'DEX269',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 140,
                      child: TextField(
                        controller: sectionController,
                        decoration: const InputDecoration(
                          labelText: 'Sección',
                          hintText: '016',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: periodController,
                        decoration: const InputDecoration(
                          labelText: 'Período',
                          hintText: '2026-02',
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
                      onPressed: () => saveCourse(),
                      icon: const Icon(Icons.save_rounded),
                      label: Text(
                        editingCourse == null
                            ? 'Guardar curso'
                            : 'Actualizar curso',
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
          if (courses.isEmpty)
            const SectionCard(
              child: Text(
                'Todavía no hay cursos creados.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            )
          else
            ...courses.map(
              (course) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SectionCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      course.id == activeCourseId
                          ? Icons.check_circle_rounded
                          : Icons.school_rounded,
                      color: course.id == activeCourseId
                          ? AppTheme.success
                          : AppTheme.accent,
                    ),
                    title: Text(
                      course.displayName,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: Text(
                      course.id == activeCourseId
                          ? 'Curso activo'
                          : 'Toca seleccionar para usarlo como curso activo',
                      style: const TextStyle(color: AppTheme.textMuted),
                    ),
                    onTap: () => selectCourse(course),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          tooltip: 'Editar',
                          onPressed: () => editCourse(course),
                          icon: const Icon(Icons.edit_rounded),
                        ),
                        IconButton(
                          tooltip: 'Eliminar',
                          onPressed: () => deleteCourse(course),
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
