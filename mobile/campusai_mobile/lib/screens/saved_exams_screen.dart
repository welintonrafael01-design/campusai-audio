import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/cloud_api_service.dart';
import '../models/study_result.dart';
import '../services/study_result_service.dart';
import '../services/educator_sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';
import '../widgets/studybook/studybook_states.dart';

class SavedExamsScreen extends StatefulWidget {
  const SavedExamsScreen({super.key});

  @override
  State<SavedExamsScreen> createState() => _SavedExamsScreenState();
}

class _SavedExamsScreenState extends State<SavedExamsScreen> {
  bool isLoading = true;
  String search = '';
  String loadErrorMessage = '';
  List<Map<String, dynamic>> exams = [];

  @override
  void initState() {
    super.initState();
    loadExams();
  }

  Future<void> loadExams() async {
    setState(() {
      isLoading = true;
      loadErrorMessage = '';
    });

    try {
      final data = await CloudApiService.getStudyResults(type: 'exam');

      final parsed = data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      parsed.sort((a, b) {
        final aDate =
            a['created_at']?.toString() ?? a['createdAt']?.toString() ?? '';
        final bDate =
            b['created_at']?.toString() ?? b['createdAt']?.toString() ?? '';
        return bDate.compareTo(aDate);
      });

      if (!mounted) return;

      setState(() {
        exams = parsed;
        isLoading = false;
      });
    } catch (error) {
      debugPrint('No se pudieron cargar los exámenes: $error');
      if (!mounted) return;
      setState(() {
        isLoading = false;
        loadErrorMessage =
            'Booky no pudo cargar tus exámenes esta vez. Podemos intentarlo otra vez.';
      });
    }
  }

  List<Map<String, dynamic>> parseQuestions(Map<String, dynamic> item) {
    final raw = item['content'] ?? item['result'] ?? item['payload'];

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      } catch (_) {}
    }

    return [];
  }

  String examTitle(
      Map<String, dynamic> item, List<Map<String, dynamic>> questions) {
    if (questions.isNotEmpty) {
      final courseName = questions.first['course_display_name']
                  ?.toString()
                  .trim()
                  .isNotEmpty ==
              true
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

  String examSubtitle(
      Map<String, dynamic> item, List<Map<String, dynamic>> questions) {
    final date = createdAt(item);

    if (questions.isEmpty) {
      return '0 preguntas · $date';
    }

    final first = questions.first;
    final courseName =
        first['course_display_name']?.toString().trim().isNotEmpty == true
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
    final raw =
        item['created_at']?.toString() ?? item['createdAt']?.toString() ?? '';

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

  List<Map<String, dynamic>> parseQuestionListFromBank(
      Map<String, dynamic> bank) {
    final raw = bank['content'] ?? bank['questions'] ?? bank['payload'];

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }

        if (decoded is Map && decoded['content'] is String) {
          final contentDecoded = jsonDecode(decoded['content'].toString());
          if (contentDecoded is List) {
            return contentDecoded
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          }
        }
      } catch (_) {}
    }

    if (raw is Map && raw['content'] is String) {
      try {
        final decoded = jsonDecode(raw['content'].toString());
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      } catch (_) {}
    }

    return [];
  }

  String bankTitle(Map<String, dynamic> bank) {
    final questions = parseQuestionListFromBank(bank);
    if (questions.isNotEmpty) {
      final first = questions.first;
      final course =
          first['course_display_name']?.toString().trim().isNotEmpty == true
              ? first['course_display_name']!.toString().trim()
              : first['course_name']?.toString().trim() ?? '';
      final topic = first['program_topic']?.toString().trim() ??
          first['exam_topic']?.toString().trim() ??
          '';

      if (course.isNotEmpty && topic.isNotEmpty) return '$course · $topic';
      if (course.isNotEmpty) return course;
      if (topic.isNotEmpty) return topic;
    }

    return bank['title']?.toString() ??
        bank['documentId']?.toString() ??
        bank['id']?.toString() ??
        'Banco de preguntas';
  }

  Future<List<Map<String, dynamic>>> loadQuestionBanks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(EducatorSyncService.questionBanksKey) ?? [];

    return raw
        .map((item) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is Map<String, dynamic>) return decoded;
            if (decoded is Map) return Map<String, dynamic>.from(decoded);
          } catch (_) {}
          return null;
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  Future<void> createMultiBankExam() async {
    final banks = await loadQuestionBanks();

    if (!mounted) return;

    if (banks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('No hay bancos guardados para crear un examen multi-banco.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedIds = <String>{};
    final counts = <String, int>{};
    String examTitle = 'Examen multi-banco';
    String version = 'A';

    final options = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Crear examen multi-banco'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 620,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Título del examen',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          examTitle = value.trim().isEmpty
                              ? 'Examen multi-banco'
                              : value.trim();
                        },
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Selecciona bancos y cantidad de preguntas por banco.',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      ...banks.map((bank) {
                        final id = bank['documentId']?.toString() ??
                            bank['id']?.toString() ??
                            bank.hashCode.toString();
                        final questions = parseQuestionListFromBank(bank);
                        counts[id] ??= min(5, questions.length);

                        return Card(
                          child: CheckboxListTile(
                            value: selectedIds.contains(id),
                            onChanged: (value) {
                              setDialogState(() {
                                if (value == true) {
                                  selectedIds.add(id);
                                } else {
                                  selectedIds.remove(id);
                                }
                              });
                            },
                            title: Text(bankTitle(bank)),
                            subtitle: Text(
                                '${questions.length} preguntas disponibles · Tomar ${counts[id]}'),
                            secondary: DropdownButton<int>(
                              value: counts[id],
                              items: [5, 10, 15, 20, 25, 30]
                                  .where((count) =>
                                      count <= max(1, questions.length))
                                  .map((count) => DropdownMenuItem<int>(
                                        value: count,
                                        child: Text('$count'),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) return;
                                setDialogState(() => counts[id] = value);
                              },
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      const Text(
                        'Versión',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Wrap(
                        spacing: 8,
                        children: ['A', 'B', 'C', 'D'].map((item) {
                          return ChoiceChip(
                            label: Text('Versión $item'),
                            selected: version == item,
                            onSelected: (_) =>
                                setDialogState(() => version = item),
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
                FilledButton.icon(
                  onPressed: selectedIds.isEmpty
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop({
                            'selectedIds': selectedIds.toList(),
                            'counts': Map<String, int>.from(counts),
                            'examTitle': examTitle,
                            'version': version,
                          });
                        },
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Crear examen'),
                ),
              ],
            );
          },
        );
      },
    );

    if (options == null) return;

    final chosenIds =
        (options['selectedIds'] as List).map((item) => item.toString()).toSet();
    final chosenCounts = Map<String, int>.from(options['counts'] as Map);
    final title = options['examTitle']?.toString() ?? 'Examen multi-banco';
    final selectedVersion = options['version']?.toString() ?? 'A';

    final selectedQuestions = <Map<String, dynamic>>[];
    final usedBanks = <String>[];

    for (final bank in banks) {
      final id = bank['documentId']?.toString() ??
          bank['id']?.toString() ??
          bank.hashCode.toString();

      if (!chosenIds.contains(id)) continue;

      final bankQuestions = parseQuestionListFromBank(bank);
      bankQuestions.shuffle(Random());

      final takeCount = chosenCounts[id] ?? 5;
      usedBanks.add(bankTitle(bank));

      selectedQuestions.addAll(
        bankQuestions.take(takeCount).map((item) {
          return {
            ...item,
            'exam_title': title,
            'exam_version': selectedVersion,
            'exam_source': 'Multi-Banco',
            'banks_used': usedBanks,
          };
        }),
      );
    }

    if (selectedQuestions.isEmpty) return;

    selectedQuestions.shuffle(Random());

    final examId = 'multi_bank_exam_${DateTime.now().millisecondsSinceEpoch}';
    final content = jsonEncode(selectedQuestions);

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
    } catch (_) {}

    await loadExams();

    if (!mounted) return;

    context.goNamed(
      'exam',
      pathParameters: {'documentId': examId},
      extra: selectedQuestions,
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
          ? const StudyBookLoadingState(
              message: 'Booky está preparando tus exámenes...',
            )
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
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => context.goNamed('dashboard'),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Volver al Dashboard'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => context.goNamed('courses'),
                            icon: const Icon(Icons.school_rounded),
                            label: const Text('Ir a Mis Cursos'),
                          ),
                          FilledButton.icon(
                            onPressed: createMultiBankExam,
                            icon: const Icon(Icons.auto_awesome_rounded),
                            label: const Text('Crear examen multi-banco'),
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
                if (loadErrorMessage.isNotEmpty)
                  SectionCard(
                    child: StudyBookEmptyState(
                      title: 'Podemos intentarlo otra vez',
                      message: loadErrorMessage,
                      actionLabel: 'Reintentar',
                      onAction: loadExams,
                    ),
                  )
                else if (filteredExams.isEmpty)
                  SectionCard(
                    child: StudyBookEmptyState(
                      title: search.trim().isEmpty
                          ? 'Tu repositorio está listo'
                          : 'No encontramos coincidencias',
                      message: search.trim().isEmpty
                          ? 'Crea un examen desde una unidad, un documento o un banco de preguntas.'
                          : 'Prueba con otro curso, tema o fecha.',
                      actionLabel:
                          search.trim().isEmpty ? 'Ir a Mis Cursos' : '',
                      onAction: search.trim().isEmpty
                          ? () => context.goNamed('courses')
                          : null,
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
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Siguiente paso: revisa las preguntas antes de publicar, guardar el banco o compartir.',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      height: 1.35,
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
                                  label: const Text('Revisar preguntas'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => deleteExam(item),
                                  icon:
                                      const Icon(Icons.delete_outline_rounded),
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
