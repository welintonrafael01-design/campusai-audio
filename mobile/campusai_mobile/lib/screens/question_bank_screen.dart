import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/study_result.dart';
import '../services/study_result_service.dart';
import '../services/study_result_repository.dart';
import '../services/export_service.dart';
import '../services/api_service.dart';
import '../services/cloud_api_service.dart';
import '../services/plan_guard_service.dart';
import '../theme/app_theme.dart';
import '../utils/upgrade_dialog.dart';
import '../widgets/section_card.dart';

class QuestionBankScreen extends StatefulWidget {
  final String documentId;
  final List<Map<String, dynamic>> initialQuestions;

  const QuestionBankScreen({
    super.key,
    required this.documentId,
    this.initialQuestions = const [],
  });

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  List<Map<String, dynamic>> questions = [];
  String search = '';

  @override
  void initState() {
    super.initState();
    questions = _usableQuestions(widget.initialQuestions);
    if (questions.isEmpty) {
      loadSavedQuestionBank();
    }
  }

  Future<void> loadSavedQuestionBank() async {
    final result = await const StudyResultRepository().getResult(
      documentId: widget.documentId,
      type: 'question_bank',
    );

    if (result == null || !mounted) return;

    try {
      final decoded = jsonDecode(result.content);

      if (decoded is List) {
        setState(() {
          questions = decoded
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .where(_isUsableQuestion)
              .toList();
        });
      }
    } catch (_) {}
  }

  String get sourceDocumentId {
    if (questions.isNotEmpty) {
      final raw = questions.first['source_document_id'];
      final clean = raw?.toString().trim() ?? '';
      if (clean.isNotEmpty) return clean;
    }

    return widget.documentId
        .replaceAll(RegExp(r'_question_bank$'), '')
        .replaceAll(RegExp(r'_bank_exam$'), '');
  }

  int get requestedQuestionsCount {
    if (questions.isEmpty) return 0;

    final value = questions.first['requested_questions'] ??
        questions.first['number_of_questions'] ??
        questions.first['requested_count'];

    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? questions.length;
  }

  String get bankScopeLabel {
    if (questions.isEmpty) return 'Banco general';

    final courseName = questions.first['course_name']?.toString().trim() ?? '';
    final courseId = questions.first['course_id']?.toString().trim() ?? '';

    if (courseName.isNotEmpty || courseId.isNotEmpty) {
      return 'Banco del curso';
    }

    return 'Banco general';
  }

  String get bankExplanation {
    if (bankScopeLabel == 'Banco del curso') {
      return 'Banco asociado a un curso, programa, tema, objetivo y competencia. Ideal para docentes que desean reutilizar preguntas y crear exámenes por asignatura.';
    }

    return 'Banco generado desde el PDF activo del Dashboard. Ideal para estudiar, repasar o crear preguntas rápidas desde cualquier documento.';
  }

  String get bankTitle {
    if (questions.isEmpty) return 'Banco de preguntas';

    final courseName = questions.first['course_name']?.toString().trim() ?? '';
    final topic = questions.first['program_topic']?.toString().trim() ?? '';

    if (courseName.isNotEmpty && topic.isNotEmpty) {
      return 'Banco de preguntas — $courseName / $topic';
    }

    if (courseName.isNotEmpty) {
      return 'Banco de preguntas — $courseName';
    }

    if (topic.isNotEmpty) {
      return 'Banco de preguntas — $topic';
    }

    return 'Banco de preguntas';
  }

  List<Map<String, dynamic>> get filteredQuestions {
    final cleanSearch = search.trim().toLowerCase();

    final normalized = questions
        .map((item) => Map<String, dynamic>.from(item))
        .where((item) => item.isNotEmpty)
        .toList();

    if (cleanSearch.isEmpty) {
      return normalized;
    }

    return normalized.where((question) {
      final text = question.values.join(' ').toLowerCase();
      return text.contains(cleanSearch);
    }).toList();
  }

  String optionText(Map<String, dynamic> item, String key) {
    final options = item['options'];

    if (options is Map && options[key] != null) {
      return options[key].toString();
    }

    return item[key]?.toString() ?? '';
  }

  String questionText(Map<String, dynamic> item) {
    return item['question']?.toString() ??
        item['pregunta']?.toString() ??
        item['text']?.toString() ??
        item['enunciado']?.toString() ??
        item['prompt']?.toString() ??
        item.values.firstOrNull?.toString() ??
        'Pregunta sin texto';
  }

  String answerText(Map<String, dynamic> item) {
    return item['answer']?.toString() ??
        item['correct_answer']?.toString() ??
        item['respuesta']?.toString() ??
        item['respuesta_correcta']?.toString() ??
        item['correctOption']?.toString() ??
        item['correct_option']?.toString() ??
        '';
  }

  List<Map<String, dynamic>> _usableQuestions(List<Map<String, dynamic>> raw) {
    return raw.map(Map<String, dynamic>.from).where(_isUsableQuestion).toList();
  }

  bool _isUsableQuestion(Map<String, dynamic> item) {
    return questionText(item).trim().isNotEmpty &&
        questionText(item) != 'Pregunta sin texto' &&
        answerText(item).trim().isNotEmpty;
  }

  int maxQuestionsForExamType(String type) {
    final clean = type.toLowerCase();

    if (clean.contains('caso') ||
        clean.contains('análisis') ||
        clean.contains('analisis') ||
        clean.contains('ensayo')) {
      return 10;
    }

    if (clean.contains('abierta')) {
      return 15;
    }

    if (clean.contains('relacionar')) {
      return 30;
    }

    if (clean.contains('completar')) {
      return 50;
    }

    return 100;
  }

  Future<Map<String, dynamic>?> pickExamFromBankOptions() async {
    int selectedCount = questions.length >= 10 ? 10 : questions.length;
    int totalPoints = 100;
    String difficulty = 'Intermedio';
    String examType = 'Mixto';
    String bloomLevel = 'Aplicar';
    String examVersion = 'A';
    String outputMode = 'Estudiante';
    String examTopic = '';
    String examObjective = '';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final maxAllowed = maxQuestionsForExamType(examType);

            if (selectedCount > maxAllowed) {
              selectedCount = maxAllowed;
            }

            final pointsPerQuestion =
                selectedCount <= 0 ? 0 : totalPoints / selectedCount;

            return AlertDialog(
              title: const Text('Crear examen desde banco'),
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
                          final available = questions.length;
                          final maxAllowed = maxQuestionsForExamType(examType);
                          final disabled =
                              count > available || count > maxAllowed;

                          return ChoiceChip(
                            label: Text('$count preguntas'),
                            selected: selectedCount == count,
                            onSelected: disabled
                                ? null
                                : (_) {
                                    setDialogState(() => selectedCount = count);
                                  },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Máximo recomendado para este tipo: ${maxQuestionsForExamType(examType)} preguntas',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Valor total',
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
                      const SizedBox(height: 18),
                      const Text(
                        'Nivel',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                            ['Básico', 'Intermedio', 'Avanzado'].map((item) {
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
                      const Text(
                        'Nivel cognitivo Bloom',
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
                        'Tipo de salida',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'Estudiante',
                          'Docente',
                        ].map((item) {
                          return ChoiceChip(
                            label: Text(item),
                            selected: outputMode == item,
                            onSelected: (_) {
                              setDialogState(() => outputMode = item);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Versión del examen',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          'A',
                          'B',
                          'C',
                        ].map((item) {
                          return ChoiceChip(
                            label: Text('Versión $item'),
                            selected: examVersion == item,
                            onSelected: (_) {
                              setDialogState(() => examVersion = item);
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
                          hintText:
                              'Ej.: Evaluar la aplicación práctica de los conceptos principales.',
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
                      'count': selectedCount,
                      'totalPoints': totalPoints,
                      'difficulty': difficulty,
                      'examType': examType,
                      'bloomLevel': bloomLevel,
                      'examVersion': examVersion,
                      'outputMode': outputMode,
                      'examTopic': examTopic,
                      'examObjective': examObjective,
                    });
                  },
                  child: const Text('Crear examen'),
                ),
              ],
            );
          },
        );
      },
    );

    return result;
  }

  bool matchesExamType(Map<String, dynamic> item, String examType) {
    if (examType == 'Mixto') return true;

    final type = (item['question_type'] ?? item['tipo'] ?? item['type'] ?? '')
        .toString()
        .toLowerCase();

    final requested = examType.toLowerCase();

    if (type.isEmpty) return true;

    return type.contains(requested.split('/').first.trim()) ||
        requested.contains(type);
  }

  Future<void> openAsExam() async {
    final options = await pickExamFromBankOptions();

    if (options == null) return;

    final count = options['count'] as int;
    final totalPoints = options['totalPoints'] as int;
    final difficulty = options['difficulty'] as String;
    final examType = options['examType'] as String;
    final bloomLevel = options['bloomLevel'] as String;
    final examVersion = options['examVersion'] as String;
    final outputMode = options['outputMode'] as String;
    final examTopic = options['examTopic'] as String;
    final examObjective = options['examObjective'] as String;

    final pool = questions
        .where((item) => matchesExamType(item, examType))
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    List<Map<String, dynamic>> selected;

    if (pool.isEmpty) {
      final generated = await ApiService.generateExamByDocumentId(
        documentId: sourceDocumentId,
        numberOfQuestions: count,
        examType: examType,
        difficulty: difficulty,
        totalPoints: totalPoints,
        examTopic: examTopic,
        examObjective: examObjective,
      );

      final raw = generated['questions'];
      selected = raw is List
          ? raw
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList()
          : <Map<String, dynamic>>[];

      if (selected.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'No se pudo generar preguntas compatibles con el tipo seleccionado.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } else {
      pool.shuffle(Random());
      selected = pool.take(min(count, pool.length)).toList();
    }
    if (examVersion == 'B' || examVersion == 'C') {
      selected.shuffle(Random());
    }

    final pointsPerQuestion =
        selected.isEmpty ? 0 : totalPoints / selected.length;

    final enriched = selected.map((item) {
      return {
        ...item,
        'exam_total_points': totalPoints,
        'exam_points_per_question': pointsPerQuestion,
        'exam_difficulty': difficulty,
        'exam_type': examType,
        'exam_topic': examTopic,
        'exam_objective': examObjective,
        'bloom_level': bloomLevel,
        'exam_version': examVersion,
        'exam_output_mode': outputMode,
        'exam_source': 'Banco de Preguntas',
      };
    }).toList();

    final examId = '${widget.documentId}_bank_exam';
    final content = jsonEncode(enriched);

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
      debugPrint('No se pudo guardar examen de banco en cloud: $cloudError');
    }

    if (!mounted) return;

    context.pushNamed(
      'exam',
      pathParameters: {
        'documentId': examId,
      },
      extra: enriched,
    );
  }

  String exportableContent() {
    final buffer = StringBuffer();

    buffer.writeln('BANCO DE PREGUNTAS STUDYBOOK AI');
    buffer.writeln('');
    buffer.writeln('Total de preguntas: ${questions.length}');
    buffer.writeln('');

    for (var i = 0; i < questions.length; i++) {
      final item = questions[i];

      buffer.writeln('Pregunta ${i + 1}');
      buffer.writeln(questionText(item));
      buffer.writeln('');

      final a = optionText(item, 'A');
      final b = optionText(item, 'B');
      final c = optionText(item, 'C');
      final d = optionText(item, 'D');

      if (a.trim().isNotEmpty) buffer.writeln('A. $a');
      if (b.trim().isNotEmpty) buffer.writeln('B. $b');
      if (c.trim().isNotEmpty) buffer.writeln('C. $c');
      if (d.trim().isNotEmpty) buffer.writeln('D. $d');

      final answer = answerText(item);
      if (answer.trim().isNotEmpty) {
        buffer.writeln('');
        buffer.writeln('Respuesta correcta: $answer');
      }

      buffer.writeln('');
      buffer.writeln('----------------------------------------');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  Future<void> exportQuestionBankToPdf() async {
    if (!const PlanGuardService().canExportPdf) {
      showUpgradeRequired(context, featureName: 'Exportar banco a PDF');
      return;
    }
    await ExportService.exportTextToPdf(
      title: 'Banco de Preguntas',
      content: exportableContent(),
    );
  }

  Future<void> exportQuestionBankToDocx() async {
    if (!const PlanGuardService().canExportDocx) {
      showUpgradeRequired(context, featureName: 'Exportar banco a Word');
      return;
    }
    await ExportService.exportTextToDocx(
      title: 'Banco de Preguntas',
      content: exportableContent(),
    );
  }

  Future<void> exportQuestionBankToPptx() async {
    if (!const PlanGuardService().canExportPptx) {
      showUpgradeRequired(
        context,
        featureName: 'Exportar banco a PowerPoint',
      );
      return;
    }
    await ExportService.exportTextToPptx(
      title: 'Banco de Preguntas',
      content: exportableContent(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredQuestions;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Banco de preguntas'),
        actions: [
          IconButton(
            tooltip: 'Exportar PDF',
            onPressed: questions.isEmpty ? null : exportQuestionBankToPdf,
            icon: const Icon(Icons.picture_as_pdf_rounded),
          ),
          IconButton(
            tooltip: 'Exportar Word',
            onPressed: questions.isEmpty ? null : exportQuestionBankToDocx,
            icon: const Icon(Icons.description_rounded),
          ),
          IconButton(
            tooltip: 'Exportar PowerPoint',
            onPressed: questions.isEmpty ? null : exportQuestionBankToPptx,
            icon: const Icon(Icons.slideshow_rounded),
          ),
          IconButton(
            tooltip: 'Usar como examen',
            onPressed: questions.isEmpty ? null : openAsExam,
            icon: const Icon(Icons.assignment_rounded),
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
                  bankTitle,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Solicitadas: ${requestedQuestionsCount == 0 ? questions.length : requestedQuestionsCount} | Generadas: ${questions.length}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  onChanged: (value) => setState(() => search = value),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText: 'Buscar pregunta, concepto o respuesta...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: questions.isEmpty ? null : openAsExam,
                      icon: const Icon(Icons.quiz_rounded),
                      label: const Text('Crear examen desde banco'),
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
          if (filtered.isEmpty)
            const SectionCard(
              child: Text(
                'No hay preguntas para mostrar.',
                style: TextStyle(
                  color: AppTheme.textMuted,
                ),
              ),
            )
          else
            ...filtered.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _QuestionCard(
                      index: entry.key + 1,
                      item: entry.value,
                      question: questionText(entry.value),
                      answer: answerText(entry.value),
                      optionA: optionText(entry.value, 'A'),
                      optionB: optionText(entry.value, 'B'),
                      optionC: optionText(entry.value, 'C'),
                      optionD: optionText(entry.value, 'D'),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> item;
  final String question;
  final String answer;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;

  const _QuestionCard({
    required this.index,
    required this.item,
    required this.question,
    required this.answer,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
  });

  @override
  Widget build(BuildContext context) {
    final options = [
      if (optionA.trim().isNotEmpty) 'A. $optionA',
      if (optionB.trim().isNotEmpty) 'B. $optionB',
      if (optionC.trim().isNotEmpty) 'C. $optionC',
      if (optionD.trim().isNotEmpty) 'D. $optionD',
    ];

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pregunta $index',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            question,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              height: 1.35,
            ),
          ),
          if (options.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...options.map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  option,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
          if (answer.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                'Respuesta correcta: $answer',
                style: const TextStyle(
                  color: AppTheme.success,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
