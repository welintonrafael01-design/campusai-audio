#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
FLUTTER="$ROOT/mobile/campusai_mobile"
BACKEND="$ROOT/backend"

python3 <<'PY'
from pathlib import Path

path = Path("mobile/campusai_mobile/lib/screens/saved_exams_screen.dart")
text = path.read_text()

# Imports
if "dart:math" not in text:
    text = text.replace("import 'dart:convert';", "import 'dart:convert';\nimport 'dart:math';")

if "shared_preferences" not in text:
    text = text.replace(
        "import 'package:go_router/go_router.dart';",
        "import 'package:go_router/go_router.dart';\nimport 'package:shared_preferences/shared_preferences.dart';",
    )

if "study_result_service.dart" not in text:
    text = text.replace(
        "import '../services/cloud_api_service.dart';",
        "import '../services/cloud_api_service.dart';\nimport '../models/study_result.dart';\nimport '../services/study_result_service.dart';\nimport '../services/educator_sync_service.dart';",
    )

# Add helper methods before build()
marker = "  @override\n  Widget build(BuildContext context) {"

helpers = r'''  List<Map<String, dynamic>> parseQuestionListFromBank(Map<String, dynamic> bank) {
    final raw = bank['content'] ?? bank['questions'] ?? bank['payload'];

    if (raw is List) {
      return raw.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
    }

    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
        }

        if (decoded is Map && decoded['content'] is String) {
          final contentDecoded = jsonDecode(decoded['content'].toString());
          if (contentDecoded is List) {
            return contentDecoded.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
          }
        }
      } catch (_) {}
    }

    if (raw is Map && raw['content'] is String) {
      try {
        final decoded = jsonDecode(raw['content'].toString());
        if (decoded is List) {
          return decoded.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
        }
      } catch (_) {}
    }

    return [];
  }

  String bankTitle(Map<String, dynamic> bank) {
    final questions = parseQuestionListFromBank(bank);
    if (questions.isNotEmpty) {
      final first = questions.first;
      final course = first['course_display_name']?.toString().trim().isNotEmpty == true
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

    return raw.map((item) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
      return null;
    }).whereType<Map<String, dynamic>>().toList();
  }

  Future<void> createMultiBankExam() async {
    final banks = await loadQuestionBanks();

    if (!mounted) return;

    if (banks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay bancos guardados para crear un examen multi-banco.'),
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
                          examTitle = value.trim().isEmpty ? 'Examen multi-banco' : value.trim();
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
                            subtitle: Text('${questions.length} preguntas disponibles · Tomar ${counts[id]}'),
                            secondary: DropdownButton<int>(
                              value: counts[id],
                              items: [5, 10, 15, 20, 25, 30]
                                  .where((count) => count <= max(1, questions.length))
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
                            onSelected: (_) => setDialogState(() => version = item),
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

    final chosenIds = (options['selectedIds'] as List).map((item) => item.toString()).toSet();
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

'''

if "createMultiBankExam()" not in text:
    text = text.replace(marker, helpers + marker)

# Add button in header after search or before search. Use header actions block.
old = """                      Row(
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
"""

new = """                      Wrap(
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
"""

text = text.replace(old, new)

path.write_text(text)
PY

cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

cd "$FLUTTER"
flutter analyze || true

cd "$ROOT"
grep -R "createMultiBankExam\|Crear examen multi-banco\|Multi-Banco" \
mobile/campusai_mobile/lib/screens/saved_exams_screen.dart -n

git status --short
