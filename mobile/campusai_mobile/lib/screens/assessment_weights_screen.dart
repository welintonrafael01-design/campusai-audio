import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/assessment_weight_service.dart';
import '../services/course_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class AssessmentWeightsScreen extends StatefulWidget {
  const AssessmentWeightsScreen({super.key});

  @override
  State<AssessmentWeightsScreen> createState() =>
      _AssessmentWeightsScreenState();
}

class _AssessmentWeightsScreenState extends State<AssessmentWeightsScreen> {
  List<CourseRecord> courses = [];
  String activeCourseId = '';
  List<AssessmentWeight> weights = [];

  final nameController = TextEditingController();
  final weightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadWeights();
  }

  @override
  void dispose() {
    nameController.dispose();
    weightController.dispose();
    super.dispose();
  }

  double get totalWeight =>
      weights.fold<double>(0, (total, item) => total + item.weight);

  bool get isValidTotal => (totalWeight - 100).abs() < 0.01;

  CourseRecord? get activeCourse {
    return courses
        .where((item) => item.id == activeCourseId)
        .cast<CourseRecord?>()
        .firstOrNull;
  }

  Future<void> loadWeights() async {
    final loadedCourses = await CourseService.getCourses();
    final storedActiveCourseId = await CourseService.getActiveCourseId();

    final resolvedCourseId = storedActiveCourseId.isNotEmpty
        ? storedActiveCourseId
        : (loadedCourses.isNotEmpty ? loadedCourses.first.id : '');

    final loadedWeights = resolvedCourseId.isEmpty
        ? <AssessmentWeight>[]
        : await AssessmentWeightService.getWeights(resolvedCourseId);

    if (!mounted) return;

    setState(() {
      courses = loadedCourses;
      activeCourseId = resolvedCourseId;
      weights = loadedWeights;
    });
  }

  Future<void> changeCourse(String? courseId) async {
    if (courseId == null) return;

    await CourseService.setActiveCourse(courseId);

    setState(() {
      activeCourseId = courseId;
    });

    await loadWeights();
  }

  Future<void> addWeight() async {
    final course = activeCourse;
    if (course == null) return;

    final name = nameController.text.trim();
    final weight = double.tryParse(weightController.text.trim()) ?? 0;

    if (name.isEmpty || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe un nombre y un porcentaje válido.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final updated = [...weights];

    updated.removeWhere(
      (item) => item.name.toLowerCase().trim() == name.toLowerCase(),
    );

    updated.add(
      AssessmentWeight(
        name: name,
        weight: weight,
      ),
    );

    await AssessmentWeightService.saveWeights(
      courseId: course.id,
      weights: updated,
    );

    nameController.clear();
    weightController.clear();

    await loadWeights();
  }

  Future<void> deleteWeight(AssessmentWeight weight) async {
    final course = activeCourse;
    if (course == null) return;

    final updated = [...weights]
      ..removeWhere(
        (item) => item.name == weight.name && item.weight == weight.weight,
      );

    await AssessmentWeightService.saveWeights(
      courseId: course.id,
      weights: updated,
    );

    await loadWeights();
  }

  Future<void> loadDefaultWeights() async {
    final course = activeCourse;
    if (course == null) return;

    final defaults = [
      const AssessmentWeight(name: 'Parcial 1', weight: 20),
      const AssessmentWeight(name: 'Parcial 2', weight: 20),
      const AssessmentWeight(name: 'Proyecto', weight: 20),
      const AssessmentWeight(name: 'Final', weight: 40),
    ];

    await AssessmentWeightService.saveWeights(
      courseId: course.id,
      weights: defaults,
    );

    await loadWeights();
  }

  Future<void> saveWeights() async {
    final course = activeCourse;
    if (course == null) return;

    await AssessmentWeightService.saveWeights(
      courseId: course.id,
      weights: weights,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isValidTotal
              ? 'Ponderaciones guardadas correctamente.'
              : 'Guardado, pero el total no suma 100%.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalLabel = '${totalWeight.toStringAsFixed(1)}%';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ponderaciones'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configuración de Ponderaciones',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Define el peso de cada evaluación para calcular el promedio ponderado del curso.',
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
                    Chip(
                      label: Text('Total: $totalLabel'),
                      avatar: Icon(
                        isValidTotal
                            ? Icons.check_circle_rounded
                            : Icons.warning_rounded,
                        size: 18,
                      ),
                    ),
                    Chip(
                      label: Text(
                        isValidTotal
                            ? 'Listo para acta final'
                            : 'Debe sumar 100%',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: saveWeights,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Guardar'),
                    ),
                    OutlinedButton.icon(
                      onPressed: loadDefaultWeights,
                      icon: const Icon(Icons.auto_fix_high_rounded),
                      label: const Text('Usar plantilla'),
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
                const Text(
                  'Agregar evaluación',
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
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 240,
                      child: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          hintText: 'Ej.: Parcial 1',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Peso %',
                          hintText: '20',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: addWeight,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Agregar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (weights.isEmpty)
            const SectionCard(
              child: Text(
                'No hay ponderaciones configuradas. Puedes usar la plantilla inicial.',
                style: TextStyle(color: AppTheme.textMuted),
              ),
            )
          else
            ...weights.map(
              (weight) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SectionCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      weight.name,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    subtitle: Text('${weight.weight.toStringAsFixed(1)}%'),
                    trailing: IconButton(
                      tooltip: 'Eliminar',
                      onPressed: () => deleteWeight(weight),
                      icon: const Icon(Icons.delete_outline_rounded),
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
