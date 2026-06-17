import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/export_service.dart';
import '../services/gradebook_service.dart';
import '../services/student_roster_service.dart';
import '../services/study_result_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class RubricScreen extends StatefulWidget {
  final String documentId;
  final Map<String, dynamic> initialRubric;

  const RubricScreen({
    super.key,
    required this.documentId,
    this.initialRubric = const {},
  });

  @override
  State<RubricScreen> createState() => _RubricScreenState();
}

class _RubricScreenState extends State<RubricScreen> {
  Map<String, dynamic> rubric = {};
  List<StudentRecord> students = [];
  StudentRecord? selectedStudent;

  final Map<int, double> scores = {};
  final Map<int, TextEditingController> observationControllers = {};

  @override
  void initState() {
    super.initState();
    rubric = Map<String, dynamic>.from(widget.initialRubric);
    if (rubric.isEmpty) loadSavedRubric();
    loadStudents();
  }

  @override
  void dispose() {
    for (final controller in observationControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> loadStudents() async {
    final data = await StudentRosterService.getStudents();
    if (!mounted) return;
    setState(() => students = data);
  }

  Future<void> loadSavedRubric() async {
    final result = await StudyResultService.getResult(
      documentId: widget.documentId,
      type: 'rubric',
    );

    if (result == null || !mounted) return;

    try {
      final decoded = jsonDecode(result.content);
      if (decoded is Map<String, dynamic>) {
        setState(() => rubric = decoded);
      } else if (decoded is Map) {
        setState(() => rubric = Map<String, dynamic>.from(decoded));
      }
    } catch (_) {}
  }

  String get title => rubric['title']?.toString() ?? 'Rúbrica académica';

  int get totalPoints {
    final value = rubric['total_points'];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 100;
  }

  List<Map<String, dynamic>> get criteria {
    final raw = rubric['criteria'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return [];
  }

  List<String> get recommendations {
    final raw = rubric['recommendations'];
    if (raw is List) return raw.map((item) => item.toString()).toList();
    return [];
  }

  double get assignedTotal {
    return scores.values.fold<double>(0, (sum, value) => sum + value);
  }

  double criterionPoints(Map<String, dynamic> item) {
    final value = item['points'];
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  TextEditingController observationController(int index) {
    return observationControllers.putIfAbsent(
      index,
      () => TextEditingController(),
    );
  }

  Future<void> addStudentDialog() async {
    final nameController = TextEditingController();
    final courseController = TextEditingController();
    final emailController = TextEditingController();

    final student = await showDialog<StudentRecord>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Agregar estudiante'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: courseController,
                  decoration: const InputDecoration(labelText: 'Curso/sección'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Correo'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;

                Navigator.pop(
                  context,
                  StudentRecord(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    name: name,
                    course: courseController.text.trim(),
                    email: emailController.text.trim(),
                  ),
                );
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    if (student == null) return;

    await StudentRosterService.addStudent(student);
    await loadStudents();

    if (!mounted) return;
    setState(() => selectedStudent = student);
  }

  Future<void> importStudents() async {
    final imported = await StudentRosterService.importCsvFromUser();
    await loadStudents();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Estudiantes importados: ${imported.length}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> exportStudents() async {
    await StudentRosterService.exportCsv();
  }

  String exportableContent() {
    final buffer = StringBuffer();

    buffer.writeln(title.toUpperCase());
    buffer.writeln('');
    buffer.writeln('Código: ${selectedStudent?.studentCode ?? 'No especificado'}');
    buffer.writeln('Estudiante: ${selectedStudent?.name ?? 'No especificado'}');
    buffer.writeln('Curso/sección: ${selectedStudent?.course ?? 'No especificado'}');
    buffer.writeln('Correo: ${selectedStudent?.email ?? 'No especificado'}');
    buffer.writeln('');
    buffer.writeln('Puntuación obtenida: ${assignedTotal.toStringAsFixed(1)} / $totalPoints');
    buffer.writeln('');

    final items = criteria;

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final max = criterionPoints(item);
      final assigned = scores[i] ?? 0;
      final obs = observationController(i).text.trim();

      buffer.writeln('Criterio ${i + 1}: ${item['criterion'] ?? ''}');
      buffer.writeln('Descripción: ${item['description'] ?? ''}');
      buffer.writeln('Puntos asignados: ${assigned.toStringAsFixed(1)} / ${max.toStringAsFixed(1)}');
      if (obs.isNotEmpty) buffer.writeln('Observación: $obs');
      buffer.writeln('');

      final levels = item['levels'];
      if (levels is Map) {
        buffer.writeln('Niveles de desempeño:');
        buffer.writeln('Excelente: ${levels['excellent'] ?? ''}');
        buffer.writeln('Bueno: ${levels['good'] ?? ''}');
        buffer.writeln('Básico: ${levels['basic'] ?? ''}');
        buffer.writeln('Insuficiente: ${levels['insufficient'] ?? ''}');
      }

      buffer.writeln('');
      buffer.writeln('----------------------------------------');
      buffer.writeln('');
    }

    if (recommendations.isNotEmpty) {
      buffer.writeln('Recomendaciones:');
      for (final item in recommendations) {
        buffer.writeln('- $item');
      }
    }

    return buffer.toString();
  }

  Future<void> exportPdf() async {
    await ExportService.exportTextToPdf(
      title: 'Rúbrica Evaluada',
      content: exportableContent(),
    );
  }

  Future<void> exportDocx() async {
    await ExportService.exportTextToDocx(
      title: 'Rúbrica Evaluada',
      content: exportableContent(),
    );
  }

  Future<void> saveEvaluationToGradebook() async {
    if (selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un estudiante antes de guardar.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await GradebookService.saveEntry(
      GradebookEntry(
        id: '${widget.documentId}_${selectedStudent!.id}_${DateTime.now().millisecondsSinceEpoch}',
        studentId: selectedStudent!.id,
        studentName: selectedStudent!.name,
        studentCode: selectedStudent!.studentCode,
        course: selectedStudent!.course,
        rubricTitle: title,
        score: assignedTotal,
        maxScore: totalPoints.toDouble(),
        createdAt: DateTime.now().toIso8601String(),
        notes: exportableContent(),
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Evaluación guardada en el Libro de Calificaciones.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final criteriaItems = criteria;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rúbrica académica'),
        actions: [
          IconButton(
            tooltip: 'Importar CSV / Excel',
            onPressed: importStudents,
            icon: const Icon(Icons.upload_file_rounded),
          ),
          IconButton(
            tooltip: 'Exportar CSV para Excel',
            onPressed: exportStudents,
            icon: const Icon(Icons.download_rounded),
          ),
          IconButton(
            tooltip: 'Exportar PDF',
            onPressed: criteriaItems.isEmpty ? null : exportPdf,
            icon: const Icon(Icons.picture_as_pdf_rounded),
          ),
          IconButton(
            tooltip: 'Exportar Word',
            onPressed: criteriaItems.isEmpty ? null : exportDocx,
            icon: const Icon(Icons.description_rounded),
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
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total asignado: ${assignedTotal.toStringAsFixed(1)} / $totalPoints puntos',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    SizedBox(
                      width: 320,
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedStudent?.id,
                        decoration: const InputDecoration(
                          labelText: 'Estudiante evaluado',
                          border: OutlineInputBorder(),
                        ),
                        items: students
                            .map(
                              (student) => DropdownMenuItem(
                                value: student.id,
                                child: Text(
                                  student.studentCode.isNotEmpty
                                      ? '${student.studentCode} - ${student.name}'
                                      : student.name,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (id) {
                          setState(() {
                            selectedStudent = students
                                .where((item) => item.id == id)
                                .cast<StudentRecord?>()
                                .firstOrNull;
                          });
                        },
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: saveEvaluationToGradebook,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Guardar evaluación'),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: addStudentDialog,
                      icon: const Icon(Icons.person_add_rounded),
                      label: const Text('Agregar estudiante'),
                    ),
                    OutlinedButton.icon(
                      onPressed: importStudents,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Importar CSV / Excel'),
                    ),
                    OutlinedButton.icon(
                      onPressed: exportStudents,
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
          if (criteriaItems.isEmpty)
            const SectionCard(
              child: Text(
                'No hay criterios para mostrar.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            )
          else
            ...criteriaItems.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _CriterionCard(
                      index: entry.key,
                      item: entry.value,
                      assignedScore: scores[entry.key] ?? 0,
                      observationController: observationController(entry.key),
                      onScoreChanged: (value) {
                        setState(() => scores[entry.key] = value);
                      },
                    ),
                  ),
                ),
          if (recommendations.isNotEmpty) ...[
            const SizedBox(height: 6),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recomendaciones',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...recommendations.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '• $item',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CriterionCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> item;
  final double assignedScore;
  final TextEditingController observationController;
  final ValueChanged<double> onScoreChanged;

  const _CriterionCard({
    required this.index,
    required this.item,
    required this.assignedScore,
    required this.observationController,
    required this.onScoreChanged,
  });

  double get maxPoints {
    final value = item['points'];
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final levels = item['levels'];
    final levelMap = levels is Map ? levels : {};

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['criterion']?.toString() ?? 'Criterio',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item['description']?.toString() ?? '',
            style: const TextStyle(
              color: AppTheme.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Puntuación: ${assignedScore.toStringAsFixed(1)} / ${maxPoints.toStringAsFixed(1)}',
            style: const TextStyle(
              color: AppTheme.accent,
              fontWeight: FontWeight.w900,
            ),
          ),
          Slider(
            value: assignedScore.clamp(0, maxPoints),
            min: 0,
            max: maxPoints <= 0 ? 1 : maxPoints,
            divisions: maxPoints <= 0 ? 1 : maxPoints.round(),
            label: assignedScore.toStringAsFixed(1),
            onChanged: onScoreChanged,
          ),
          TextField(
            controller: observationController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Observación del docente',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          _LevelRow(label: 'Excelente', text: levelMap['excellent']?.toString() ?? ''),
          _LevelRow(label: 'Bueno', text: levelMap['good']?.toString() ?? ''),
          _LevelRow(label: 'Básico', text: levelMap['basic']?.toString() ?? ''),
          _LevelRow(label: 'Insuficiente', text: levelMap['insufficient']?.toString() ?? ''),
        ],
      ),
    );
  }
}

class _LevelRow extends StatelessWidget {
  final String label;
  final String text;

  const _LevelRow({
    required this.label,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: AppTheme.textMuted,
            height: 1.35,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}
