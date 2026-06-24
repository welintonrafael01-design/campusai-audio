import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/course_service.dart';
import '../services/cloud_api_service.dart';
import '../services/api_service.dart';
import '../services/course_document_service.dart';
import '../services/export_service.dart';
import '../services/study_result_service.dart';
import '../models/study_result.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  List<CourseRecord> courses = [];
  List<CourseDocument> courseDocuments = [];
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
    final loadedCourseDocuments = await CourseDocumentService.getDocuments();
    final active = await CourseService.getActiveCourseId();

    if (!mounted) return;

    setState(() {
      courses = loadedCourses;
      courseDocuments = loadedCourseDocuments;
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



  CourseDocument? documentForCourse(CourseRecord course) {
    return courseDocuments
        .where((item) => item.courseId == course.id)
        .cast<CourseDocument?>()
        .firstOrNull;
  }

  Future<void> uploadProgramForCourse(CourseRecord course) async {
    await CourseService.setActiveCourse(course.id);
    await loadCourses();

    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return const AlertDialog(
          title: Text('Subiendo programa de clase'),
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
                  'StudyBook AI está subiendo el programa y asociándolo al curso.',
                ),
              ),
            ],
          ),
        );
      },
    );

    try {
      final data = await ApiService.uploadPdf();

      final documentId = data['document_id']?.toString() ?? '';
      final fileName = data['file_name']?.toString() ??
          data['filename']?.toString() ??
          'Programa de clase';

      if (documentId.isEmpty) {
        throw Exception('No se recibió documentId del programa.');
      }

      await CourseDocumentService.saveDocument(
        CourseDocument(
          courseId: course.id,
          documentId: documentId,
          fileName: fileName,
          uploadedAt: DateTime.now().toIso8601String(),
        ),
      );

      await loadCourses();

      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Programa asociado a ${course.displayName}.'),
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
          content: Text('No se pudo subir el programa: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> removeProgramForCourse(CourseRecord course) async {
    await CourseDocumentService.deleteDocumentForCourse(course.id);
    await loadCourses();
  }


  Future<int?> pickTeachingPlanWeeks() async {
    int selectedWeeks = 4;
    final customController = TextEditingController();

    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Duración de la planificación'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Selecciona la cantidad de semanas que deseas generar.',
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [2, 4, 8, 12, 16].map((weeks) {
                        return ChoiceChip(
                          label: Text('$weeks semanas'),
                          selected: selectedWeeks == weeks,
                          onSelected: (_) {
                            setDialogState(() {
                              selectedWeeks = weeks;
                              customController.clear();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: customController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Personalizado',
                        hintText: 'Ej.: 10',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        final custom = int.tryParse(value.trim());
                        if (custom != null && custom > 0) {
                          setDialogState(() => selectedWeeks = custom);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar generación'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(selectedWeeks.clamp(1, 16));
                  },
                  child: const Text('Generar'),
                ),
              ],
            );
          },
        );
      },
    );

    customController.dispose();
    return result;
  }

  Future<bool> confirmRegenerateCourseArtifact(String title) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('$title existente'),
          content: Text(
            'Ya existe $title guardada para el programa de este curso. '
            'Puedes abrir la existente o generar una nueva.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Abrir existente'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Generar nueva'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<Map<String, dynamic>?> pickRubricOptions() async {
    String rubricType = 'Analítica';
    int totalPoints = 100;
    int criteriaCount = 5;
    int performanceLevels = 4;

    final customTypeController = TextEditingController();
    final customPointsController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Configurar rúbrica inteligente'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 520,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tipo de rúbrica',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'Analítica',
                          'Holística',
                          'Lista de cotejo',
                          'Escala estimativa',
                          'Proyecto',
                          'Ensayo',
                          'Exposición oral',
                          'Investigación',
                          'Personalizada',
                        ].map((item) {
                          return ChoiceChip(
                            label: Text(item),
                            selected: rubricType == item,
                            onSelected: (_) {
                              setDialogState(() => rubricType = item);
                            },
                          );
                        }).toList(),
                      ),
                      if (rubricType == 'Personalizada') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: customTypeController,
                          decoration: const InputDecoration(
                            labelText: 'Describe el tipo de rúbrica',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      const Text(
                        'Puntaje total',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [25, 50, 75, 100, 150, 200].map((points) {
                          return ChoiceChip(
                            label: Text('$points puntos'),
                            selected: totalPoints == points,
                            onSelected: (_) {
                              setDialogState(() {
                                totalPoints = points;
                                customPointsController.clear();
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: customPointsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Puntaje personalizado',
                          hintText: 'Ej.: 120',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          final custom = int.tryParse(value.trim());
                          if (custom != null && custom > 0) {
                            setDialogState(() => totalPoints = custom);
                          }
                        },
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Cantidad de criterios',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [3, 4, 5, 6, 8, 10].map((count) {
                          return ChoiceChip(
                            label: Text('$count criterios'),
                            selected: criteriaCount == count,
                            onSelected: (_) {
                              setDialogState(() => criteriaCount = count);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Niveles de desempeño',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [3, 4, 5, 6].map((levels) {
                          return ChoiceChip(
                            label: Text('$levels niveles'),
                            selected: performanceLevels == levels,
                            onSelected: (_) {
                              setDialogState(() => performanceLevels = levels);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar generación'),
                ),
                FilledButton(
                  onPressed: () {
                    final cleanType = rubricType == 'Personalizada'
                        ? customTypeController.text.trim()
                        : rubricType;

                    Navigator.of(dialogContext).pop({
                      'rubricType': cleanType.isEmpty ? 'Analítica' : cleanType,
                      'totalPoints': totalPoints.clamp(10, 200),
                      'criteriaCount': criteriaCount.clamp(3, 10),
                      'performanceLevels': performanceLevels.clamp(3, 6),
                    });
                  },
                  child: const Text('Generar rúbrica'),
                ),
              ],
            );
          },
        );
      },
    );

    customTypeController.dispose();
    customPointsController.dispose();

    return result;
  }

  Future<void> generateCourseTeachingPlan(
    CourseRecord course,
    CourseDocument program,
  ) async {
    await CourseService.setActiveCourse(course.id);
    await loadCourses();

    final planId = '${program.documentId}_teaching_plan';

    final existing = await StudyResultService.getResult(
      documentId: planId,
      type: 'teaching_plan',
    );

    if (existing != null) {
      try {
        final decoded = jsonDecode(existing.content);
        final map = decoded is Map<String, dynamic>
            ? decoded
            : (decoded is Map ? Map<String, dynamic>.from(decoded) : null);

        if (map != null && map.isNotEmpty) {
          final regenerate =
              await confirmRegenerateCourseArtifact('Planificación');

          if (!regenerate) {
            if (!mounted) return;

            context.goNamed(
              'teaching-plan',
              pathParameters: {'documentId': planId},
              extra: map,
            );
            return;
          }
        }
      } catch (_) {}
    }

    final weeks = await pickTeachingPlanWeeks();
    if (weeks == null) return;

    var cancelled = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Generando planificación del curso'),
          content: const Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(width: 18),
              Expanded(
                child: Text(
                  'StudyBook AI está usando el programa asociado al curso.',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                cancelled = true;
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar generación'),
            ),
          ],
        );
      },
    );

    try {
      final data = await ApiService.generateTeachingPlanByDocumentId(
        documentId: program.documentId,
        weeks: weeks,
      );

      if (cancelled) return;

      final rawPlan = data['teaching_plan'];
      final plan = rawPlan is Map
          ? Map<String, dynamic>.from(rawPlan)
          : <String, dynamic>{};

      final content = jsonEncode(plan);

      await StudyResultService.saveResult(
        StudyResult(
          documentId: planId,
          type: 'teaching_plan',
          content: content,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      context.goNamed(
        'teaching-plan',
        pathParameters: {'documentId': planId},
        extra: plan,
      );
    } catch (error) {
      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo generar planificación: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> generateCourseRubric(
    CourseRecord course,
    CourseDocument program,
  ) async {
    await CourseService.setActiveCourse(course.id);
    await loadCourses();

    final rubricId = '${program.documentId}_rubric';

    final existing = await StudyResultService.getResult(
      documentId: rubricId,
      type: 'rubric',
    );

    if (existing != null) {
      try {
        final decoded = jsonDecode(existing.content);
        final map = decoded is Map<String, dynamic>
            ? decoded
            : (decoded is Map ? Map<String, dynamic>.from(decoded) : null);

        if (map != null && map.isNotEmpty) {
          final regenerate = await confirmRegenerateCourseArtifact('Rúbrica');

          if (!regenerate) {
            if (!mounted) return;

            context.goNamed(
              'rubric',
              pathParameters: {'documentId': rubricId},
              extra: map,
            );
            return;
          }
        }
      } catch (_) {}
    }

    final rubricOptions = await pickRubricOptions();
    if (rubricOptions == null) return;

    var cancelled = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Generando rúbrica del curso'),
          content: const Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(width: 18),
              Expanded(
                child: Text(
                  'StudyBook AI está usando el programa asociado al curso.',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                cancelled = true;
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar generación'),
            ),
          ],
        );
      },
    );

    try {
      final data = await ApiService.generateRubricByDocumentId(
        documentId: program.documentId,
        totalPoints: rubricOptions['totalPoints'] as int,
        rubricType: rubricOptions['rubricType'] as String,
        criteriaCount: rubricOptions['criteriaCount'] as int,
        performanceLevels: rubricOptions['performanceLevels'] as int,
      );

      if (cancelled) return;

      final rawRubric = data['rubric'];
      final rubric = rawRubric is Map
          ? Map<String, dynamic>.from(rawRubric)
          : <String, dynamic>{};

      final content = jsonEncode(rubric);

      await StudyResultService.saveResult(
        StudyResult(
          documentId: rubricId,
          type: 'rubric',
          content: content,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      context.goNamed(
        'rubric',
        pathParameters: {'documentId': rubricId},
        extra: rubric,
      );
    } catch (error) {
      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo generar rúbrica: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }





  Future<Map<String, dynamic>?> pickExamOptions() async {
    int selectedCount = 10;
    int totalPoints = 100;
    String difficulty = 'Intermedio';
    String examType = 'Selección múltiple';
    String examTopic = '';
    String examObjective = '';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final pointsPerQuestion = selectedCount <= 0
                ? 0
                : totalPoints / selectedCount;

            return AlertDialog(
              title: const Text('Configurar examen IA'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 520,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tipo de examen',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'Selección múltiple',
                          'Verdadero/Falso',
                          'Mixto',
                          'Mixto personalizable',
                          'Preguntas abiertas',
                          'Estudio de caso',
                          'Análisis práctico',
                          'Ensayo corto',
                          'Completar espacios',
                          'Relacionar columnas',
                        ].map((item) {
                          return ChoiceChip(
                            label: Text(item),
                            selected: examType == item,
                            onSelected: (_) {
                              setDialogState(() => examType = item);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Cantidad de preguntas',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [5, 10, 15, 20, 25, 30].map((count) {
                          return ChoiceChip(
                            label: Text('$count preguntas'),
                            selected: selectedCount == count,
                            onSelected: (_) {
                              setDialogState(() => selectedCount = count);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Cantidad personalizada',
                          hintText: 'Ej.: 12',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          final custom = int.tryParse(value.trim());
                          if (custom != null && custom > 0) {
                            setDialogState(() => selectedCount = custom);
                          }
                        },
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Valor total del examen',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [25, 50, 75, 100, 150, 200].map((points) {
                          return ChoiceChip(
                            label: Text('$points puntos'),
                            selected: totalPoints == points,
                            onSelected: (_) {
                              setDialogState(() => totalPoints = points);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Puntaje personalizado',
                          hintText: 'Ej.: 80',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          final custom = int.tryParse(value.trim());
                          if (custom != null && custom > 0) {
                            setDialogState(() => totalPoints = custom);
                          }
                        },
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Nivel de dificultad',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'Básico',
                          'Intermedio',
                          'Avanzado',
                        ].map((item) {
                          return ChoiceChip(
                            label: Text(item),
                            selected: difficulty == item,
                            onSelected: (_) {
                              setDialogState(() => difficulty = item);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      Chip(
                        avatar: const Icon(Icons.calculate_rounded, size: 18),
                        label: Text(
                          'Valor por pregunta: ${pointsPerQuestion.toStringAsFixed(2)} puntos',
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Tema específico del examen',
                          hintText: 'Ej.: Contratos comerciales',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => examTopic = value.trim(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Objetivo de evaluación',
                          hintText: 'Ej.: Evaluar la identificación de los elementos esenciales del contrato mercantil.',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => examObjective = value.trim(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop({
                      'numberOfQuestions': selectedCount.clamp(1, 100),
                      'totalPoints': totalPoints.clamp(1, 500),
                      'difficulty': difficulty,
                      'examType': examType,
                      'examTopic': examTopic,
                      'examObjective': examObjective,
                    });
                  },
                  child: const Text('Generar examen'),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  Future<void> generateCourseExam(
    CourseRecord course,
    CourseDocument program,
  ) async {
    await CourseService.setActiveCourse(course.id);
    await loadCourses();

    final examId = '${program.documentId}_exam';

    final existing = await StudyResultService.getResult(
      documentId: examId,
      type: 'exam',
    );

    if (existing != null) {
      try {
        final decoded = jsonDecode(existing.content);
        final existingQuestions = decoded is List
            ? decoded
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
            : <Map<String, dynamic>>[];

        if (existingQuestions.isNotEmpty) {
          final regenerate = await confirmRegenerateCourseArtifact('Examen');

          if (!regenerate) {
            if (!mounted) return;

            context.goNamed(
              'exam',
              pathParameters: {'documentId': examId},
              extra: existingQuestions,
            );
            return;
          }
        }
      } catch (_) {}
    }

    final examOptions = await pickExamOptions();
    if (examOptions == null) return;

    final count = examOptions['numberOfQuestions'] as int;
    final totalPoints = examOptions['totalPoints'] as int;
    final difficulty = examOptions['difficulty'] as String;
    final examType = examOptions['examType'] as String;
    final examTopic = examOptions['examTopic'] as String;
    final examObjective = examOptions['examObjective'] as String;

    var cancelled = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Generando examen del curso'),
          content: const Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(width: 18),
              Expanded(
                child: Text(
                  'StudyBook AI está creando el examen con base en el programa asociado al curso.',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                cancelled = true;
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar generación'),
            ),
          ],
        );
      },
    );

    try {
      final data = await ApiService.generateExamByDocumentId(
        documentId: program.documentId,
        numberOfQuestions: count,
        examType: examType,
        difficulty: difficulty,
        totalPoints: totalPoints,
        examTopic: examTopic,
        examObjective: examObjective,
      );

      if (cancelled) return;

      final rawQuestions = data['questions'];
      final questions = rawQuestions is List
          ? rawQuestions
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];

      if (questions.isEmpty) {
        throw Exception('La IA no devolvió preguntas válidas.');
      }

      final limitedQuestions = questions.take(count).toList();

      final pointsPerQuestion = limitedQuestions.isEmpty
          ? 0
          : totalPoints / limitedQuestions.length;

      final enrichedQuestions = limitedQuestions.map((item) {
        return {
          ...item,
          'exam_total_points': totalPoints,
          'exam_points_per_question': pointsPerQuestion,
          'exam_difficulty': difficulty,
          'exam_type': examType,
          'source_document_id': program.documentId,
          'course_id': course.id,
          'course_name': course.name,
          'course_code': course.code,
          'course_section': course.section,
          'course_period': course.period,
          'course_display_name': course.displayName,
          'exam_topic': examTopic,
          'exam_objective': examObjective,
          'exam_source': 'Curso',
        };
      }).toList();

      final content = jsonEncode(enrichedQuestions);

      await StudyResultService.saveResult(
        StudyResult(
          documentId: examId,
          type: 'exam',
          content: content,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      try {
        await CloudApiService.saveStudyResult(
          documentId: examId,
          type: 'exam',
          content: content,
        );
      } catch (cloudError) {
        debugPrint('No se pudo guardar examen de curso en cloud: $cloudError');
      }

      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      context.goNamed(
        'exam',
        pathParameters: {'documentId': examId},
        extra: enrichedQuestions,
      );
    } catch (error) {
      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo generar examen: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }


  Future<Map<String, dynamic>?> pickQuestionBankOptions() async {
    int selectedCount = 50;
    String programTopic = '';
    String learningObjective = '';
    String competency = '';
    String bloomLevel = 'Analizar';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Banco de Preguntas IA'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 560,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Personaliza el banco para que las preguntas estén alineadas al programa, objetivo y competencia.',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Tema del programa',
                          hintText: 'Ej.: Contratos comerciales',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => programTopic = value.trim(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Objetivo de aprendizaje',
                          hintText: 'Ej.: Analizar los elementos esenciales de los contratos mercantiles.',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => learningObjective = value.trim(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        minLines: 2,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Competencia',
                          hintText: 'Ej.: Interpretar y aplicar la normativa comercial vigente.',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => competency = value.trim(),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Nivel Bloom',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'Recordar',
                          'Comprender',
                          'Aplicar',
                          'Analizar',
                          'Evaluar',
                          'Crear',
                        ].map((item) {
                          return ChoiceChip(
                            label: Text(item),
                            selected: bloomLevel == item,
                            onSelected: (_) {
                              setDialogState(() => bloomLevel = item);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Cantidad de preguntas',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [10, 20, 30, 50, 75, 100].map((count) {
                          return ChoiceChip(
                            label: Text('$count preguntas'),
                            selected: selectedCount == count,
                            onSelected: (_) {
                              setDialogState(() => selectedCount = count);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop({
                      'count': selectedCount,
                      'programTopic': programTopic,
                      'learningObjective': learningObjective,
                      'competency': competency,
                      'bloomLevel': bloomLevel,
                    });
                  },
                  child: const Text('Generar banco'),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  Future<void> generateCourseQuestionBank(
    CourseRecord course,
    CourseDocument program,
  ) async {
    await CourseService.setActiveCourse(course.id);
    await loadCourses();

    final questionBankId = '${program.documentId}_question_bank';

    final existing = await StudyResultService.getResult(
      documentId: questionBankId,
      type: 'question_bank',
    );

    if (existing != null) {
      try {
        final decoded = jsonDecode(existing.content);
        final existingQuestions = decoded is List
            ? decoded
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList()
            : <Map<String, dynamic>>[];

        if (existingQuestions.isNotEmpty) {
          final regenerate =
              await confirmRegenerateCourseArtifact('Banco de Preguntas');

          if (!regenerate) {
            if (!mounted) return;

            context.goNamed(
              'question-bank',
              pathParameters: {'documentId': questionBankId},
              extra: existingQuestions,
            );
            return;
          }
        }
      } catch (_) {}
    }

    final bankOptions = await pickQuestionBankOptions();
    if (bankOptions == null) return;

    final count = bankOptions['count'] as int;
    final programTopic = bankOptions['programTopic'] as String;
    final learningObjective = bankOptions['learningObjective'] as String;
    final competency = bankOptions['competency'] as String;
    final bloomLevel = bankOptions['bloomLevel'] as String;

    var cancelled = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Generando banco de preguntas'),
          content: const Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              SizedBox(width: 18),
              Expanded(
                child: Text(
                  'StudyBook AI está creando preguntas reutilizables desde el programa asociado al curso.',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                cancelled = true;
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar generación'),
            ),
          ],
        );
      },
    );

    try {
      final data = await ApiService.generateQuestionBankByDocumentId(
        documentId: program.documentId,
        numberOfQuestions: count,
        programTopic: programTopic,
        learningObjective: learningObjective,
        competency: competency,
        bloomLevel: bloomLevel,
      );

      if (cancelled) return;

      final rawQuestions = data['questions'] ?? data['question_bank'] ?? data;
      final questions = rawQuestions is List
          ? rawQuestions
              .whereType<Map>()
              .map((item) => {
                    ...Map<String, dynamic>.from(item),
                    'source_document_id': program.documentId,
                    'course_id': course.id,
                    'course_name': course.name,
                    'course_code': course.code,
                    'course_section': course.section,
                    'course_period': course.period,
                    'course_display_name': course.displayName,
                    'program_topic': programTopic,
                    'learning_objective': learningObjective,
                    'competency': competency,
                    'bloom_level': bloomLevel,
                    'requested_questions': count,
                    'bank_scope': 'course',
                  })
              .toList()
          : <Map<String, dynamic>>[];

      if (questions.isEmpty) {
        throw Exception('La IA no devolvió preguntas válidas.');
      }

      final limitedQuestions = questions.take(count).toList();

      final content = jsonEncode(limitedQuestions);

      await StudyResultService.saveResult(
        StudyResult(
          documentId: questionBankId,
          type: 'question_bank',
          content: content,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      context.goNamed(
        'question-bank',
        pathParameters: {'documentId': questionBankId},
        extra: limitedQuestions,
      );
    } catch (error) {
      if (!mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo generar banco de preguntas: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> openCourseRoute(CourseRecord course, String routeName) async {
    await CourseService.setActiveCourse(course.id);
    await loadCourses();

    if (!mounted) return;

    context.goNamed(routeName);
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
                  child: Builder(
                    builder: (context) {
                      final program = documentForCourse(course);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(
                        children: [
                          Icon(
                            course.id == activeCourseId
                                ? Icons.check_circle_rounded
                                : Icons.school_rounded,
                            color: course.id == activeCourseId
                                ? AppTheme.success
                                : AppTheme.accent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              course.displayName,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
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
                      const SizedBox(height: 6),
                      Text(
                        course.id == activeCourseId
                            ? 'Curso activo para el Centro Educator'
                            : 'Selecciona este curso para trabajar estudiantes, asistencia, calificaciones y reportes.',
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                      if (program != null) ...[
                        const SizedBox(height: 10),
                        Chip(
                          avatar: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                          label: Text('Programa: ${program.fileName}'),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: () => selectCourse(course),
                            icon: const Icon(Icons.check_circle_rounded),
                            label: Text(
                              course.id == activeCourseId
                                  ? 'Activo'
                                  : 'Activar',
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => openCourseRoute(course, 'students'),
                            icon: const Icon(Icons.groups_rounded),
                            label: const Text('Estudiantes'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => openCourseRoute(course, 'attendance'),
                            icon: const Icon(Icons.event_available_rounded),
                            label: const Text('Asistencia'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => openCourseRoute(course, 'assessment-weights'),
                            icon: const Icon(Icons.percent_rounded),
                            label: const Text('Ponderaciones'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => openCourseRoute(course, 'gradebook'),
                            icon: const Icon(Icons.fact_check_rounded),
                            label: const Text('Calificaciones'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => openCourseRoute(course, 'academic-dashboard'),
                            icon: const Icon(Icons.analytics_rounded),
                            label: const Text('Dashboard'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => openCourseRoute(course, 'final-report'),
                            icon: const Icon(Icons.workspace_premium_rounded),
                            label: const Text('Acta Final'),
                          ),
                          OutlinedButton.icon(
                            onPressed: program == null
                                ? null
                                : () => generateCourseTeachingPlan(course, program),
                            icon: const Icon(Icons.calendar_month_rounded),
                            label: const Text('Planificación IA'),
                          ),
                          OutlinedButton.icon(
                            onPressed: program == null
                                ? null
                                : () => generateCourseRubric(course, program),
                            icon: const Icon(Icons.fact_check_rounded),
                            label: const Text('Rúbrica IA'),
                          ),
                          OutlinedButton.icon(
                            onPressed: program == null
                                ? null
                                : () => generateCourseExam(course, program),
                            icon: const Icon(Icons.quiz_rounded),
                            label: const Text('Examen IA'),
                          ),
                          OutlinedButton.icon(
                            onPressed: program == null
                                ? null
                                : () => generateCourseQuestionBank(course, program),
                            icon: const Icon(Icons.help_center_rounded),
                            label: const Text('Banco IA'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => uploadProgramForCourse(course),
                            icon: const Icon(Icons.menu_book_rounded),
                            label: Text(program == null ? 'Subir programa' : 'Cambiar programa'),
                          ),
                          if (program != null)
                            OutlinedButton.icon(
                              onPressed: () => removeProgramForCourse(course),
                              icon: const Icon(Icons.link_off_rounded),
                              label: const Text('Quitar programa'),
                            ),
                        ],
                      ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
