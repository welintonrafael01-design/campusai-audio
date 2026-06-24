import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/cloud_api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class SavedExamsScreen extends StatefulWidget {
  const SavedExamsScreen({super.key});

  @override
  State<SavedExamsScreen> createState() => _SavedExamsScreenState();
}

class _SavedExamsScreenState extends State<SavedExamsScreen> {
  bool isLoading = true;
  String search = '';
  List<Map<String, dynamic>> exams = [];

  @override
  void initState() {
    super.initState();
    loadExams();
  }

  Future<void> loadExams() async {
    setState(() => isLoading = true);

    try {
      final data = await CloudApiService.getStudyResults(type: 'exam');

      final parsed = data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      parsed.sort((a, b) {
        final aDate = a['created_at']?.toString() ??
            a['createdAt']?.toString() ??
            '';
        final bDate = b['created_at']?.toString() ??
            b['createdAt']?.toString() ??
            '';
        return bDate.compareTo(aDate);
      });

      if (!mounted) return;

      setState(() {
        exams = parsed;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  List<Map<String, dynamic>> parseQuestions(Map<String, dynamic> item) {
    final raw = item['content'] ?? item['result'] ?? item['payload'];

    if (raw is List) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }

    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
      } catch (_) {}
    }

    return [];
  }

  String examTitle(Map<String, dynamic> item, List<Map<String, dynamic>> questions) {
    if (questions.isNotEmpty) {
      final courseName = questions.first['course_display_name']?.toString().trim().isNotEmpty == true
          ? questions.first['course_display_name']!.toString().trim()
          : questions.first['course_name']?.toString().trim() ?? '';
      final topic = questions.first['exam_topic']?.toString().trim() ?? '';
      final version = questions.first['exam_version']?.toString().trim() ?? '';

      final base = topic.isNotEmpty
          ? topic
          : courseName.isNotEmpty
              ? courseName
              : 'Examen guardado';

      if (version.isNotEmpty) {
        return '$base - Versión $version';
      }

      return base;
    }

    return item['title']?.toString() ??
        item['document_name']?.toString() ??
        item['documentId']?.toString() ??
        'Examen guardado';
  }

  String examSubtitle(Map<String, dynamic> item, List<Map<String, dynamic>> questions) {
    final date = createdAt(item);

    if (questions.isEmpty) {
      return '0 preguntas · $date';
    }

    final first = questions.first;
    final courseName = first['course_display_name']?.toString().trim().isNotEmpty == true
        ? first['course_display_name']!.toString().trim()
        : first['course_name']?.toString().trim() ?? '';
    final source = first['exam_source']?.toString().trim() ?? '';
    final bloom = first['bloom_level']?.toString().trim() ?? '';

    final parts = <String>[
      '${questions.length} preguntas',
      if (courseName.isNotEmpty) courseName,
      if (source.isNotEmpty) source,
      if (bloom.isNotEmpty) 'Bloom: $bloom',
      if (date.isNotEmpty) date,
    ];

    return parts.join(' · ');
  }

  String createdAt(Map<String, dynamic> item) {
    final raw = item['created_at']?.toString() ??
        item['createdAt']?.toString() ??
        '';

    if (raw.isEmpty) return '';

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;

    final local = parsed.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  List<Map<String, dynamic>> get filteredExams {
    final query = search.trim().toLowerCase();

    if (query.isEmpty) return exams;

    return exams.where((item) {
      final questions = parseQuestions(item);
      final title = examTitle(item, questions).toLowerCase();
      final subtitle = examSubtitle(item, questions).toLowerCase();
      return title.contains(query) || subtitle.contains(query);
    }).toList();
  }

  String documentIdFor(Map<String, dynamic> item) {
    return item['document_id']?.toString() ??
        item['documentId']?.toString() ??
        item['id']?.toString() ??
        '';
  }

  Future<void> deleteExam(Map<String, dynamic> item) async {
    final documentId = documentIdFor(item);

    if (documentId.isEmpty) return;

    final questions = parseQuestions(item);
    final title = examTitle(item, questions);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar examen'),
          content: Text(
            '¿Deseas eliminar "$title"? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await CloudApiService.deleteStudyResult(
        documentId: documentId,
        type: 'exam',
      );

      if (!mounted) return;

      setState(() {
        exams.removeWhere((exam) => documentIdFor(exam) == documentId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Examen eliminado correctamente.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar el examen: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void openExam(Map<String, dynamic> item) {
    final documentId = documentIdFor(item);

    final questions = parseQuestions(item);

    if (documentId.isEmpty) return;

    context.goNamed(
      'exam',
      pathParameters: {'documentId': documentId},
      extra: questions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mis Exámenes'),
        actions: [
          IconButton(
            onPressed: loadExams,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(22),
              children: [
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Repositorio docente de exámenes',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${filteredExams.length} de ${exams.length} exámenes. Aquí podrás abrir, buscar y eliminar exámenes creados desde documentos, bancos de preguntas o cursos.',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => context.goNamed('dashboard'),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Volver al Dashboard'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () => context.goNamed('courses'),
                            icon: const Icon(Icons.school_rounded),
                            label: const Text('Ir a Mis Cursos'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search_rounded),
                          labelText: 'Buscar examen',
                          hintText: 'Curso, tema, banco, Bloom o fecha...',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() => search = value);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (filteredExams.isEmpty)
                  const SectionCard(
                    child: Text(
                      'Aún no hay exámenes guardados. Crea un examen desde un documento o desde un banco de preguntas.',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  )
                else
                  ...filteredExams.map((item) {
                    final questions = parseQuestions(item);
                    final title = examTitle(item, questions);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: SectionCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(
                              child: Icon(Icons.assignment_rounded),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    examSubtitle(item, questions),
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton.icon(
                                  onPressed: () => openExam(item),
                                  icon: const Icon(Icons.open_in_new_rounded),
                                  label: const Text('Abrir'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => deleteExam(item),
                                  icon: const Icon(Icons.delete_outline_rounded),
                                  label: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
