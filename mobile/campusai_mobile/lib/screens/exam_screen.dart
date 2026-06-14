import 'dart:convert';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/study_result.dart';
import '../services/api_service.dart';
import '../services/export_service.dart';
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
  final Map<int, String> selectedAnswers = {};
  final Set<int> correctIndexes = {};

  AppLocalizations get l10n => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();

    if (widget.initialQuestions.isNotEmpty) {
      questions = widget.initialQuestions;
      resetQuizState();
    } else {
      loadSavedExam();
    }
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
        documentId: widget.documentId,
        numberOfQuestions: 10,
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
      if (!mounted) return;

      setState(() {
        errorMessage = 'Error: $error';
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

  List<String> getOptions(Map<String, dynamic> item) {
    final options = _parseOptions(
      item['options'] ?? item['opciones'],
    );

    if (options.isNotEmpty) return options;

    final answer = getCorrectAnswer(item);

    if (answer.isNotEmpty) {
      return [
        answer,
        l10n.notSpecifiedInDocument,
        l10n.allOfTheAbove,
        l10n.noneOfTheAbove,
      ];
    }

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
${getQuestionText(question)}

${l10n.examExportOptions}:
$options

${l10n.examExportCorrectAnswer}:
${getCorrectAnswer(question)}

${l10n.examExportExplanation}:
${getExplanation(question)}
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

    await ExportService.exportTextToPdf(
      title: l10n.examTitle,
      content: buildExamExportContent(),
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
      title: l10n.examTitle,
      content: buildExamExportContent(),
    );
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
            Text(
              '${l10n.answerLabel}: $correctAnswer',
              style: const TextStyle(
                color: AppTheme.accent,
                fontWeight: FontWeight.w800,
              ),
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
                  onPressed: isAnswered ? nextQuestion : verifyAnswer,
                  icon: Icon(
                    isAnswered
                        ? Icons.arrow_forward_rounded
                        : Icons.check_rounded,
                  ),
                  label: Text(
                    isAnswered
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

    final percent = ((score / questions.length) * 100).round();

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
            '$score / ${questions.length}',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 38,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$percent%',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 22),
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
