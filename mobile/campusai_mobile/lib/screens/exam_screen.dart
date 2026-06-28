import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../models/study_result.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';
import '../services/gradebook_service.dart';
import '../services/academic_period_lock_service.dart';
import '../services/course_service.dart';
import '../services/student_roster_service.dart';
import '../services/plan_guard_service.dart';
import '../utils/upgrade_dialog.dart';
import '../services/study_result_service.dart';
import '../services/cloud_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class ExamScreen extends StatefulWidget {
  final String documentId;
  final List<Map<String, dynamic>> initialQuestions;

  const ExamScreen({
    super.key,
    required this.documentId,
    this.initialQuestions = const [],
  });

  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen> {
  bool isLoading = false;
  String errorMessage = '';

  int currentIndex = 0;
  int score = 0;

  bool isAnswered = false;
  bool showResult = false;

  String selectedAnswer = '';

  List<Map<String, dynamic>> questions = [];
  List<StudentRecord> students = [];
  StudentRecord? selectedStudent;
  CourseRecord? activeCourse;

  final Map<int, String> selectedAnswers = {};
  final Map<int, String> writtenAnswers = {};
  final Set<int> correctIndexes = {};

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();

    loadCourseAndStudents();

    if (widget.initialQuestions.isNotEmpty) {
      questions = widget.initialQuestions;
      resetQuizState();
    } else {
      loadSavedExam();
    }
  }

  Future<void> loadCourseAndStudents() async {
    final courseId = await CourseService.getActiveCourseId();
    final courses = await CourseService.getCourses();
    final loadedStudents = await StudentRosterService.getStudents();

    final course = courses
        .where((item) => item.id == courseId)
        .cast<CourseRecord?>()
        .firstOrNull;

    final filteredStudents = course == null
        ? loadedStudents
        : loadedStudents
            .where(
              (student) =>
                  student.courseId == course.id ||
                  student.course.toLowerCase().trim() ==
                      course.name.toLowerCase().trim(),
            )
            .toList();

    if (!mounted) return;

    setState(() {
      activeCourse = course;
      students = filteredStudents;
      selectedStudent =
          filteredStudents.isNotEmpty ? filteredStudents.first : null;
    });
  }

  double get examTotalPoints {
    if (questions.isEmpty) return 100;

    final raw = questions.first['exam_total_points'];
    if (raw is num) return raw.toDouble();

    return double.tryParse(raw?.toString() ?? '') ?? 100;
  }

  double get pointsObtained {
    if (questions.isEmpty) return 0;

    return (score / questions.length) * examTotalPoints;
  }

  String get examTitleForGradebook {
    final type = questions.isEmpty
        ? 'Examen IA'
        : (questions.first['exam_type']?.toString() ?? 'Examen IA');

    final difficulty = questions.isEmpty
        ? ''
        : (questions.first['exam_difficulty']?.toString() ?? '');

    return difficulty.trim().isEmpty ? type : '$type - $difficulty';
  }

  Future<void> saveExamResultToGradebook() async {
    if (selectedStudent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un estudiante antes de guardar la nota.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final course = activeCourse;

    final closed = await AcademicPeriodLockService.isClosed(
      course?.id ?? selectedStudent!.courseId,
    );

    if (closed) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se puede guardar la nota porque el período académico está cerrado.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await GradebookService.saveEntry(
      GradebookEntry(
        id: 'exam_${widget.documentId}_${selectedStudent!.id}_${DateTime.now().millisecondsSinceEpoch}',
        studentId: selectedStudent!.id,
        studentName: selectedStudent!.name,
        studentCode: selectedStudent!.studentCode,
        course: course?.name ?? selectedStudent!.course,
        courseId: course?.id ?? selectedStudent!.courseId,
        rubricTitle: examTitleForGradebook,
        score: pointsObtained,
        maxScore: examTotalPoints,
        createdAt: DateTime.now().toIso8601String(),
        notes: buildExamExportContent(),
      ),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Resultado guardado en el Libro de Calificaciones.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String get sourceDocumentId {
    if (questions.isNotEmpty) {
      final raw = questions.first['source_document_id'];
      final clean = raw?.toString().trim() ?? '';
      if (clean.isNotEmpty) return clean;
    }

    return widget.documentId.replaceAll(RegExp(r'_exam$'), '');
  }

  String get currentExamType {
    if (questions.isEmpty) return 'Selección múltiple';
    return questions.first['exam_type']?.toString() ?? 'Selección múltiple';
  }

  String get currentDifficulty {
    if (questions.isEmpty) return 'Intermedio';
    return questions.first['exam_difficulty']?.toString() ?? 'Intermedio';
  }

  Future<void> loadSavedExam() async {
    final savedResult = await StudyResultService.getResult(
      documentId: widget.documentId,
      type: 'exam',
    );

    if (savedResult == null) return;

    final parsedQuestions = _parseQuestions(savedResult.content);

    if (!mounted) return;

    setState(() {
      questions = parsedQuestions;
      resetQuizState();
    });
  }

  Future<void> generateExam() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data = await ApiService.generateExamByDocumentId(
        documentId: sourceDocumentId,
        numberOfQuestions: questions.isNotEmpty ? questions.length : 10,
        examType: currentExamType,
        difficulty: currentDifficulty,
        totalPoints: examTotalPoints.round(),
      );

      final parsedQuestions = _parseQuestions(data['questions']);

      if (!mounted) return;

      setState(() {
        questions = parsedQuestions;
        resetQuizState();
      });

      final content = jsonEncode(parsedQuestions);

      await StudyResultService.saveResult(
        StudyResult(
          documentId: widget.documentId,
          type: 'exam',
          content: content,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      try {
        await CloudApiService.saveStudyResult(
          documentId: widget.documentId,
          type: 'exam',
          content: content,
        );
      } catch (cloudError) {
        debugPrint('No se pudo guardar examen cloud: $cloudError');
      }
    } catch (error) {
      debugPrint('No se pudo generar el examen: $error');
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Booky no pudo preparar el examen esta vez. Podemos intentarlo otra vez.';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void resetQuizState() {
    currentIndex = 0;
    score = 0;
    isAnswered = false;
    showResult = false;
    selectedAnswer = '';
    selectedAnswers.clear();
    writtenAnswers.clear();
    correctIndexes.clear();
  }

  List<Map<String, dynamic>> _parseQuestions(dynamic raw) {
    dynamic decoded = raw;

    if (raw is String) {
      final clean = raw.replaceAll('```json', '').replaceAll('```', '').trim();

      decoded = jsonDecode(clean);
    }

    if (decoded is Map<String, dynamic>) {
      final list = decoded['questions'] ?? decoded['preguntas'] ?? [];

      if (list is List) {
        return list
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }
    }

    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    return [];
  }

  List<String> _parseOptions(dynamic options) {
    if (options is Map<String, dynamic>) {
      return options.entries
          .map((entry) => '${entry.key}. ${entry.value}')
          .toList();
    }

    if (options is List) {
      return options.map((item) => item.toString()).toList();
    }

    return [];
  }

  String getQuestionText(Map<String, dynamic> item) {
    return (item['question'] ??
            item['pregunta'] ??
            item['text'] ??
            item['texto'] ??
            item['statement'] ??
            item['enunciado'] ??
            item['prompt'] ??
            item['frase'] ??
            item['sentence'] ??
            l10n.questionNotAvailable)
        .toString();
  }

  String getQuestionType(Map<String, dynamic> item) {
    return (item['question_type'] ??
            item['tipo'] ??
            item['type'] ??
            'Selección múltiple')
        .toString();
  }

  bool isObjectiveQuestion(Map<String, dynamic> item) {
    final type = getQuestionType(item).toLowerCase();
    return type.contains('selección') ||
        type.contains('seleccion') ||
        type.contains('verdadero') ||
        type.contains('falso');
  }

  List<String> getOptions(Map<String, dynamic> item) {
    final options = _parseOptions(
      item['options'] ?? item['opciones'],
    );

    if (options.isNotEmpty) return options;

    return [];
  }

  String getCorrectAnswer(Map<String, dynamic> item) {
    return (item['correct_answer'] ??
            item['respuesta_correcta'] ??
            item['respuesta'] ??
            '')
        .toString();
  }

  String getExplanation(Map<String, dynamic> item) {
    return (item['explanation'] ??
            item['explicacion'] ??
            item['justificacion'] ??
            '')
        .toString();
  }

  String? getOptionLetter(
    String value,
  ) {
    final match = RegExp(
      r'^\s*([A-Da-d])[\.\)]?\s+',
    ).firstMatch(value);

    return match?.group(1)?.toUpperCase();
  }

  String? getCorrectAnswerLetter(
    String value,
  ) {
    final clean = value.trim();

    if (RegExp(r'^[A-Da-d]$').hasMatch(clean)) {
      return clean.toUpperCase();
    }

    final match = RegExp(
      r'^\s*([A-Da-d])[\.\)]?\s+',
    ).firstMatch(clean);

    return match?.group(1)?.toUpperCase();
  }

  bool isCorrectSelection(
    String selected,
    String correct,
  ) {
    final selectedLetter = getOptionLetter(selected);
    final correctLetter = getCorrectAnswerLetter(correct);

    if (selectedLetter != null && correctLetter != null) {
      return selectedLetter == correctLetter;
    }

    final cleanSelected = normalizeAnswer(selected);
    final cleanCorrect = normalizeAnswer(correct);

    if (cleanSelected.isEmpty || cleanCorrect.isEmpty) {
      return false;
    }

    return cleanSelected == cleanCorrect;
  }

  String normalizeAnswer(
    String value,
  ) {
    return value
        .toLowerCase()
        .replaceAll(
          RegExp(r'^[a-d][\.\)]?\s*'),
          '',
        )
        .replaceAll(
          RegExp(r'\s+'),
          ' ',
        )
        .trim();
  }

  String buildExamExportContent() {
    return questions.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final question = entry.value;

      final options = getOptions(question).join("\n");

      return """
${l10n.examExportQuestion} $index:
Tipo: ${getQuestionType(question)}

${getQuestionText(question)}

${l10n.examExportOptions}:
$options

${l10n.examExportCorrectAnswer}:
${getCorrectAnswer(question)}

${l10n.examExportExplanation}:
${getExplanation(question)}

Respuesta del estudiante:
${writtenAnswers[entry.key] ?? selectedAnswers[entry.key] ?? ''}
""";
    }).join("\n\n==============================\n\n");
  }

  Future<void> exportExamToPdf() async {
    if (!const PlanGuardService().canExportPdf) {
      showUpgradeRequired(
        context,
        featureName: l10n.exportExamToPdf,
      );
      return;
    }

    if (questions.isEmpty) return;

    await ExportService.exportExamToPdf(
      title: professionalExamTitle,
      questions: questions,
      includeAnswers: false,
    );
  }

  String get currentExamVersion {
    if (questions.isEmpty) return '';
    return questions.first['exam_version']?.toString() ?? '';
  }

  String get professionalExamTitle {
    final version = currentExamVersion.trim();
    if (version.isEmpty) {
      return l10n.examTitle;
    }

    return '${l10n.examTitle} - Versión $version';
  }

  String get currentExamTopic {
    if (questions.isEmpty) return '';
    return questions.first['exam_topic']?.toString() ?? '';
  }

  String get currentExamObjective {
    if (questions.isEmpty) return '';
    return questions.first['exam_objective']?.toString() ?? '';
  }

  String get currentBloomLevel {
    if (questions.isEmpty) return '';
    return questions.first['bloom_level']?.toString() ?? '';
  }

  Future<String?> pickExamVersion() async {
    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Crear versión alterna'),
          content: const Text(
            'Selecciona la versión que deseas generar con el mismo tipo, puntaje, tema y objetivo.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            for (final version in ['B', 'C', 'D'])
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(version),
                child: Text('Versión $version'),
              ),
          ],
        );
      },
    );
  }

  Future<void> generateAlternateExamVersion() async {
    if (questions.isEmpty) return;

    final version = await pickExamVersion();
    if (version == null) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data = await ApiService.generateExamByDocumentId(
        documentId: sourceDocumentId,
        numberOfQuestions: questions.length,
        examType: currentExamType,
        difficulty: currentDifficulty,
        totalPoints: examTotalPoints.round(),
        examTopic: currentExamTopic,
        examObjective: currentExamObjective,
      );

      final parsedQuestions = _parseQuestions(data['questions']);

      final enriched = parsedQuestions.map((item) {
        return {
          ...item,
          'exam_total_points': examTotalPoints,
          'exam_points_per_question': parsedQuestions.isEmpty
              ? 0
              : examTotalPoints / parsedQuestions.length,
          'exam_difficulty': currentDifficulty,
          'exam_type': currentExamType,
          'exam_topic': currentExamTopic,
          'exam_objective': currentExamObjective,
          'bloom_level': currentBloomLevel,
          'exam_version': version,
          'source_document_id': sourceDocumentId,
        };
      }).toList();

      if (enriched.isEmpty) {
        throw Exception('No se generaron preguntas para la versión $version.');
      }

      final versionId = '${sourceDocumentId}_exam_version_$version';
      final content = jsonEncode(enriched);

      await StudyResultService.saveResult(
        StudyResult(
          documentId: versionId,
          type: 'exam',
          content: content,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      if (!mounted) return;

      context.pushNamed(
        'exam',
        pathParameters: {'documentId': versionId},
        extra: enriched,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'No se pudo generar versión alterna: $error';
      });
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> generateRubricFromExam() async {
    if (questions.isEmpty) return;

    final total = examTotalPoints.round();
    final examType = questions.first['exam_type']?.toString() ?? 'Examen IA';
    final bloom = questions.first['bloom_level']?.toString() ?? '';
    final objective = questions.first['exam_objective']?.toString() ?? '';
    final topic = questions.first['exam_topic']?.toString() ?? '';

    final cleanType = examType.toLowerCase();
    final cleanBloom = bloom.toLowerCase();

    List<Map<String, dynamic>> buildCriteria(
      List<String> names,
      List<String> descriptions,
    ) {
      final base = total ~/ names.length;
      final remainder = total - (base * names.length);

      return List.generate(names.length, (index) {
        final points = base + (index == names.length - 1 ? remainder : 0);

        return {
          'criterion': names[index],
          'description': descriptions[index],
          'points': points,
          'levels': {
            'excellent':
                'Cumple el criterio de forma sobresaliente, precisa y plenamente alineada al objetivo evaluado.',
            'good':
                'Cumple el criterio de forma adecuada, con leves oportunidades de mejora.',
            'basic':
                'Cumple parcialmente el criterio, con vacíos conceptuales o argumentativos.',
            'insufficient':
                'No evidencia dominio suficiente del criterio evaluado.',
          },
        };
      });
    }

    late final List<Map<String, dynamic>> criteria;

    if (cleanType.contains('selección') ||
        cleanType.contains('seleccion') ||
        cleanType.contains('verdadero') ||
        cleanType.contains('falso')) {
      criteria = buildCriteria(
        [
          'Corrección objetiva',
          'Dominio conceptual',
          'Consistencia de respuestas',
          'Resultado global',
        ],
        [
          'Evalúa la cantidad de respuestas correctas conforme a la clave docente.',
          'Mide la comprensión de los conceptos evaluados por el instrumento.',
          'Considera la coherencia del desempeño general en las preguntas objetivas.',
          'Determina el rendimiento final según el porcentaje obtenido.',
        ],
      );
    } else if (cleanType.contains('caso')) {
      criteria = buildCriteria(
        [
          'Identificación del problema',
          'Análisis del caso',
          'Aplicación normativa o conceptual',
          'Argumentación',
          'Conclusión o solución propuesta',
        ],
        [
          'Reconoce el problema central, los hechos relevantes y las variables del caso.',
          'Interpreta la situación planteada con profundidad y coherencia.',
          'Aplica correctamente normas, conceptos, principios o procedimientos pertinentes.',
          'Sustenta la respuesta con razonamientos claros, pertinentes y bien organizados.',
          'Formula una conclusión o solución viable, fundamentada y alineada al caso.',
        ],
      );
    } else if (cleanType.contains('análisis') ||
        cleanType.contains('analisis') ||
        cleanType.contains('práctico') ||
        cleanType.contains('practico')) {
      criteria = buildCriteria(
        [
          'Diagnóstico de la situación',
          'Aplicación de conceptos',
          'Resolución propuesta',
          'Justificación',
          'Claridad académica',
        ],
        [
          'Describe adecuadamente la situación o problema que debe resolverse.',
          'Utiliza los conceptos del curso de forma pertinente y correcta.',
          'Propone una solución coherente, viable y vinculada al objetivo evaluado.',
          'Explica las razones que sustentan su respuesta.',
          'Presenta la respuesta de manera clara, ordenada y comprensible.',
        ],
      );
    } else if (cleanType.contains('ensayo')) {
      criteria = buildCriteria(
        [
          'Tesis o idea central',
          'Argumentación',
          'Uso de conceptos',
          'Estructura y coherencia',
          'Conclusión',
        ],
        [
          'Plantea una posición clara frente al tema u objetivo evaluado.',
          'Desarrolla argumentos pertinentes, ordenados y suficientemente fundamentados.',
          'Integra conceptos del curso con precisión académica.',
          'Organiza el texto de forma lógica, coherente y comprensible.',
          'Cierra el ensayo con una conclusión consistente con el desarrollo.',
        ],
      );
    } else if (cleanType.contains('abierta')) {
      criteria = buildCriteria(
        [
          'Dominio conceptual',
          'Precisión de la respuesta',
          'Fundamentación',
          'Claridad',
        ],
        [
          'Demuestra comprensión del contenido evaluado.',
          'Responde de manera directa y pertinente a lo solicitado.',
          'Sustenta la respuesta con conceptos, ejemplos o argumentos adecuados.',
          'Presenta la respuesta con redacción clara y estructura comprensible.',
        ],
      );
    } else if (cleanType.contains('completar')) {
      criteria = buildCriteria(
        [
          'Exactitud de términos',
          'Comprensión contextual',
          'Dominio conceptual',
        ],
        [
          'Completa correctamente los espacios solicitados.',
          'Selecciona términos coherentes con el contexto de la pregunta.',
          'Evidencia comprensión de los conceptos evaluados.',
        ],
      );
    } else if (cleanType.contains('relacionar')) {
      criteria = buildCriteria(
        [
          'Relación correcta de conceptos',
          'Comprensión de categorías',
          'Precisión académica',
        ],
        [
          'Relaciona correctamente elementos, conceptos o categorías.',
          'Comprende la lógica entre columnas o pares propuestos.',
          'Evita asociaciones incorrectas o ambiguas.',
        ],
      );
    } else {
      criteria = buildCriteria(
        [
          'Comprensión del contenido',
          'Análisis y razonamiento',
          'Aplicación práctica',
          'Claridad de respuesta',
          'Conclusión',
        ],
        [
          'Demuestra dominio conceptual del tema u objetivo evaluado.',
          'Organiza ideas, interpreta situaciones y fundamenta respuestas.',
          'Aplica conocimientos a problemas o situaciones concretas.',
          'Presenta respuestas ordenadas y académicamente comprensibles.',
          'Formula una conclusión o respuesta final coherente.',
        ],
      );
    }

    final bloomRecommendation = cleanBloom.isEmpty
        ? ''
        : 'La rúbrica fue alineada al nivel cognitivo Bloom: $bloom.';

    final rubric = {
      'title': 'Rúbrica automática para $examType',
      'total_points': total,
      'criteria': criteria,
      'recommendations': [
        if (topic.trim().isNotEmpty) 'Tema evaluado: $topic',
        if (objective.trim().isNotEmpty) 'Objetivo de evaluación: $objective',
        if (bloomRecommendation.isNotEmpty) bloomRecommendation,
        'Rúbrica generada automáticamente desde el examen.',
      ],
    };

    final rubricId = '${widget.documentId}_rubric_from_exam';

    await StudyResultService.saveResult(
      StudyResult(
        documentId: rubricId,
        type: 'rubric',
        content: jsonEncode(rubric),
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    if (!mounted) return;

    context.pushNamed(
      'rubric',
      pathParameters: {'documentId': rubricId},
      extra: rubric,
    );
  }

  Future<void> exportExamAnswerKeyToPdf() async {
    if (!const PlanGuardService().canExportPdf) {
      showUpgradeRequired(
        context,
        featureName: 'Clave docente PDF',
      );
      return;
    }

    if (questions.isEmpty) return;

    await ExportService.exportExamToPdf(
      title: 'Clave docente - ${l10n.examTitle}',
      questions: questions,
      includeAnswers: true,
    );
  }

  Future<void> exportExamToDocx() async {
    if (!const PlanGuardService().canExportDocx) {
      showUpgradeRequired(
        context,
        featureName: l10n.exportExamToWord,
      );
      return;
    }

    if (questions.isEmpty) return;

    await ExportService.exportTextToDocx(
      title: professionalExamTitle,
      content: buildExamExportContent(),
    );
  }

  bool isWrittenQuestion(Map<String, dynamic> item) {
    final options = getOptions(item);
    if (options.isNotEmpty) return false;

    final type = getQuestionType(item).toLowerCase();
    return type.contains('abierta') ||
        type.contains('caso') ||
        type.contains('análisis') ||
        type.contains('analisis') ||
        type.contains('ensayo') ||
        type.contains('completar') ||
        type.contains('relacionar') ||
        options.isEmpty;
  }

  void saveWrittenAnswer(String value) {
    writtenAnswers[currentIndex] = value.trim();
  }

  void finishWrittenQuestion() {
    selectedAnswers[currentIndex] = writtenAnswers[currentIndex]?.trim() ?? '';

    if (currentIndex >= questions.length - 1) {
      setState(() {
        showResult = true;
      });
      return;
    }

    setState(() {
      currentIndex++;
      selectedAnswer = '';
      isAnswered = false;
    });
  }

  void selectAnswer(String answer) {
    if (isAnswered) return;

    setState(() {
      selectedAnswer = answer;
    });
  }

  void verifyAnswer() {
    if (selectedAnswer.isEmpty || questions.isEmpty) return;

    final currentQuestion = questions[currentIndex];
    final correctAnswer = getCorrectAnswer(currentQuestion);
    final isCorrect = isCorrectSelection(
      selectedAnswer,
      correctAnswer,
    );

    setState(() {
      isAnswered = true;
      selectedAnswers[currentIndex] = selectedAnswer;

      if (isCorrect) {
        score++;
        correctIndexes.add(currentIndex);
      }
    });
  }

  void nextQuestion() {
    if (currentIndex >= questions.length - 1) {
      setState(() {
        showResult = true;
      });
      return;
    }

    setState(() {
      currentIndex++;
      selectedAnswer = '';
      isAnswered = false;
    });
  }

  void restartQuiz() {
    setState(() {
      resetQuizState();
    });
  }

  Widget buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.mainGradient,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.quiz_rounded,
            color: Colors.white,
            size: 36,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.examTitle,
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.examSubtitle,
            style: TextStyle(
              color: Colors.white,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Tooltip(
                message: l10n.exportWord,
                child: IconButton(
                  onPressed: questions.isEmpty ? null : exportExamToDocx,
                  icon: const Icon(
                    Icons.description_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              Tooltip(
                message: l10n.exportPdf,
                child: IconButton(
                  onPressed: questions.isEmpty ? null : exportExamToPdf,
                  icon: const Icon(
                    Icons.picture_as_pdf_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              Tooltip(
                message: 'Clave docente PDF',
                child: IconButton(
                  onPressed:
                      questions.isEmpty ? null : exportExamAnswerKeyToPdf,
                  icon: const Icon(
                    Icons.key_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              Tooltip(
                message: 'Generar rúbrica desde examen',
                child: IconButton(
                  onPressed: questions.isEmpty ? null : generateRubricFromExam,
                  icon: const Icon(
                    Icons.rule_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
              Tooltip(
                message: 'Crear versión B/C/D',
                child: IconButton(
                  onPressed:
                      questions.isEmpty ? null : generateAlternateExamVersion,
                  icon: const Icon(
                    Icons.copy_all_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildEmptyResult() {
    if (isLoading || errorMessage.isNotEmpty || questions.isNotEmpty) {
      return const SizedBox.shrink();
    }

    return SectionCard(
      child: Text(
        l10n.examEmptyPrompt,
        style: TextStyle(
          color: AppTheme.textSecondary,
          height: 1.4,
        ),
      ),
    );
  }

  Widget buildQuiz() {
    if (questions.isEmpty || showResult) {
      return const SizedBox.shrink();
    }

    final currentQuestion = questions[currentIndex];
    final questionText = getQuestionText(currentQuestion);
    final options = getOptions(currentQuestion);
    final correctAnswer = getCorrectAnswer(currentQuestion);
    final explanation = getExplanation(currentQuestion);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.questionOf(currentIndex + 1, questions.length),
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Chip(
            label: Text(getQuestionType(currentQuestion)),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: (currentIndex + 1) / questions.length,
            minHeight: 8,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 24),
          Text(
            questionText,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 22),
          if (options.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  minLines: 5,
                  maxLines: 10,
                  decoration: const InputDecoration(
                    labelText: 'Respuesta del estudiante',
                    hintText:
                        'Escribe aquí tu análisis, explicación o respuesta.',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: saveWrittenAnswer,
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.background.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.accent.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Text(
                    'Esta respuesta quedará pendiente de evaluación docente. '
                    'La respuesta modelo no se muestra al estudiante durante el examen.',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            )
          else
            ...options.map(
              (option) => buildOptionTile(
                option: option,
                correctAnswer: correctAnswer,
              ),
            ),
          if (isAnswered) ...[
            const SizedBox(height: 18),
            buildFeedback(
              correctAnswer: correctAnswer,
              explanation: explanation,
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: restartQuiz,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: Text(l10n.restart),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: options.isEmpty
                      ? finishWrittenQuestion
                      : (isAnswered ? nextQuestion : verifyAnswer),
                  icon: Icon(
                    isAnswered
                        ? Icons.arrow_forward_rounded
                        : Icons.check_rounded,
                  ),
                  label: Text(
                    options.isEmpty
                        ? currentIndex >= questions.length - 1
                            ? 'Finalizar'
                            : 'Guardar respuesta'
                        : isAnswered
                            ? currentIndex >= questions.length - 1
                                ? l10n.viewResult
                                : l10n.next
                            : l10n.verify,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildOptionTile({
    required String option,
    required String correctAnswer,
  }) {
    final selected = selectedAnswer == option;

    final optionLetter = getOptionLetter(option);

    final correctLetter = getCorrectAnswerLetter(correctAnswer);

    final isCorrect = optionLetter != null &&
        correctLetter != null &&
        optionLetter == correctLetter;

    Color borderColor = Colors.white.withValues(alpha: 0.08);
    Color backgroundColor = AppTheme.background.withValues(alpha: 0.4);
    IconData icon = Icons.circle_outlined;

    if (isAnswered && selected && isCorrect) {
      borderColor = Colors.greenAccent;
      backgroundColor = Colors.green.withValues(alpha: 0.18);
      icon = Icons.check_circle_rounded;
    } else if (isAnswered && selected && !isCorrect) {
      borderColor = Colors.redAccent;
      backgroundColor = Colors.red.withValues(alpha: 0.16);
      icon = Icons.cancel_rounded;
    } else if (isAnswered && isCorrect) {
      borderColor = Colors.greenAccent;
      backgroundColor = Colors.green.withValues(alpha: 0.10);
      icon = Icons.check_circle_outline_rounded;
    } else if (selected) {
      borderColor = AppTheme.accent;
      backgroundColor = AppTheme.accent.withValues(alpha: 0.12);
      icon = Icons.radio_button_checked_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => selectAnswer(option),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    selected || isAnswered ? borderColor : AppTheme.textMuted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  option,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFeedback({
    required String correctAnswer,
    required String explanation,
  }) {
    final isCorrect = isCorrectSelection(
      selectedAnswer,
      correctAnswer,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCorrect
            ? Colors.green.withValues(alpha: 0.14)
            : Colors.red.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCorrect ? Colors.greenAccent : Colors.redAccent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCorrect ? l10n.correct : l10n.incorrect,
            style: TextStyle(
              color: isCorrect ? Colors.greenAccent : Colors.redAccent,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
          if (!isCorrect) ...[
            const SizedBox(height: 8),
            Text(
              '${l10n.correctAnswer}: $correctAnswer',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (explanation.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              explanation,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget buildResult() {
    if (!showResult || questions.isEmpty) {
      return const SizedBox.shrink();
    }

    final objectiveCount =
        questions.where((item) => getOptions(item).isNotEmpty).length;
    final writtenCount = questions.length - objectiveCount;
    final percent =
        objectiveCount == 0 ? 0 : ((score / objectiveCount) * 100).round();
    final obtained =
        objectiveCount == 0 ? 0 : (score / objectiveCount) * examTotalPoints;
    final maxPoints = examTotalPoints;

    return SectionCard(
      child: Column(
        children: [
          const Icon(
            Icons.emoji_events_rounded,
            color: AppTheme.accent,
            size: 52,
          ),
          const SizedBox(height: 14),
          Text(
            l10n.finalResult,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            objectiveCount == 0 ? 'Pendiente' : '$score / $objectiveCount',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 38,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${obtained.toStringAsFixed(1)} / ${maxPoints.toStringAsFixed(1)} puntos',
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            objectiveCount == 0 ? 'Evaluación docente requerida' : '$percent%',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (objectiveCount > 0) ...[
            const SizedBox(height: 8),
            Chip(
              avatar: Icon(
                percent >= 70
                    ? Icons.check_circle_rounded
                    : Icons.warning_rounded,
              ),
              label: Text(
                percent >= 70 ? 'Estado: APROBADO' : 'Estado: REPROBADO',
              ),
            ),
          ],
          if (writtenCount > 0) ...[
            const SizedBox(height: 8),
            Text(
              '$writtenCount respuesta(s) pendiente(s) de evaluación docente.',
              style: const TextStyle(
                color: AppTheme.accent,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
          const SizedBox(height: 22),
          if (students.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: selectedStudent?.id,
              decoration: const InputDecoration(
                labelText: 'Estudiante',
                border: OutlineInputBorder(),
              ),
              items: students
                  .map(
                    (student) => DropdownMenuItem(
                      value: student.id,
                      child: Text(
                        student.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedStudent = students
                      .where((item) => item.id == value)
                      .cast<StudentRecord?>()
                      .firstOrNull;
                });
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: saveExamResultToGradebook,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Guardar en Libro de Calificaciones'),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.goNamed('gradebook'),
                icon: const Icon(Icons.fact_check_rounded),
                label: const Text('Ver Libro de Calificaciones'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.goNamed('final-report'),
                icon: const Icon(Icons.workspace_premium_rounded),
                label: const Text('Ver Acta Final'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.goNamed('courses'),
                icon: const Icon(Icons.school_rounded),
                label: const Text('Volver a Mis Cursos'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.goNamed('dashboard'),
                icon: const Icon(Icons.dashboard_rounded),
                label: const Text('Dashboard'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: restartQuiz,
            icon: const Icon(Icons.restart_alt_rounded),
            label: Text(l10n.retakeExam),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(l10n.examTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            buildHeader(),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: isLoading ? null : generateExam,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(
                questions.isEmpty ? l10n.generateExam : l10n.regenerateExam,
              ),
            ),
            const SizedBox(height: 20),
            buildEmptyResult(),
            if (isLoading)
              SectionCard(
                child: Row(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        l10n.generatingExam,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (errorMessage.isNotEmpty)
              SectionCard(
                child: Text(
                  errorMessage,
                  style: const TextStyle(
                    color: Colors.redAccent,
                  ),
                ),
              ),
            buildQuiz(),
            buildResult(),
          ],
        ),
      ),
    );
  }
}
