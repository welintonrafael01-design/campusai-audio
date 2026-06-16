import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/study_result_service.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';
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
    questions = widget.initialQuestions;
    if (questions.isEmpty) {
      loadSavedQuestionBank();
    }
  }

  Future<void> loadSavedQuestionBank() async {
    final result = await StudyResultService.getResult(
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
              .toList();
        });
      }
    } catch (_) {}
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

  void openAsExam() {
    context.pushNamed(
      'exam',
      pathParameters: {
        'documentId': widget.documentId,
      },
      extra: questions,
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
    await ExportService.exportTextToPdf(
      title: 'Banco de Preguntas',
      content: exportableContent(),
    );
  }

  Future<void> exportQuestionBankToDocx() async {
    await ExportService.exportTextToDocx(
      title: 'Banco de Preguntas',
      content: exportableContent(),
    );
  }

  Future<void> exportQuestionBankToPptx() async {
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
                const Text(
                  'Banco de preguntas Educator',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${questions.length} preguntas reutilizables generadas con IA.',
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
