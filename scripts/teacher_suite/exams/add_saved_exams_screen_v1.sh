#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
FLUTTER="$ROOT/mobile/campusai_mobile"
BACKEND="$ROOT/backend"

python3 <<'PY'
from pathlib import Path

# 1) Crear pantalla Mis Exámenes
screen = Path("mobile/campusai_mobile/lib/screens/saved_exams_screen.dart")
screen.write_text(r'''import 'dart:convert';

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
      final topic = questions.first['exam_topic']?.toString().trim() ?? '';
      final version = questions.first['exam_version']?.toString().trim() ?? '';
      if (topic.isNotEmpty && version.isNotEmpty) {
        return '$topic - Versión $version';
      }
      if (topic.isNotEmpty) return topic;
    }

    return item['title']?.toString() ??
        item['document_name']?.toString() ??
        item['documentId']?.toString() ??
        'Examen guardado';
  }

  String createdAt(Map<String, dynamic> item) {
    return item['created_at']?.toString() ??
        item['createdAt']?.toString() ??
        '';
  }

  void openExam(Map<String, dynamic> item) {
    final documentId = item['document_id']?.toString() ??
        item['documentId']?.toString() ??
        item['id']?.toString() ??
        '';

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
                        '${exams.length} exámenes guardados. Aquí podrás abrir exámenes creados desde documentos, bancos de preguntas o cursos.',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (exams.isEmpty)
                  const SectionCard(
                    child: Text(
                      'Aún no hay exámenes guardados. Crea un examen desde un documento o desde un banco de preguntas.',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  )
                else
                  ...exams.map((item) {
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
                                    '${questions.length} preguntas · ${createdAt(item)}',
                                    style: const TextStyle(
                                      color: AppTheme.textMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FilledButton.icon(
                              onPressed: () => openExam(item),
                              icon: const Icon(Icons.open_in_new_rounded),
                              label: const Text('Abrir'),
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
''')

# 2) Router
router = Path("mobile/campusai_mobile/lib/router/app_router.dart")
text = router.read_text()

if "saved_exams_screen.dart" not in text:
    text = text.replace(
        "import '../screens/students_screen.dart';",
        "import '../screens/students_screen.dart';\nimport '../screens/saved_exams_screen.dart';",
    )

if "name: 'saved-exams'" not in text:
    marker = """    GoRoute(
      path: '/gradebook',
      name: 'gradebook',
      pageBuilder: (context, state) {
        return _buildPage(
          state: state,
          child: const GradebookScreen(),
        );
      },
    ),
"""
    route = marker + """    GoRoute(
      path: '/saved-exams',
      name: 'saved-exams',
      pageBuilder: (context, state) {
        return _buildPage(
          state: state,
          child: const SavedExamsScreen(),
        );
      },
    ),
"""
    text = text.replace(marker, route)

router.write_text(text)

# 3) Tarjeta Centro Educator
center = Path("mobile/campusai_mobile/lib/widgets/dashboard/dashboard_educator_center.dart")
text = center.read_text()

if "title: 'Mis Exámenes'" not in text:
    marker = """      _EducatorAction(
        title: 'Mis Cursos',
        subtitle: 'Crea, edita y selecciona cursos activos.',
        icon: Icons.school_rounded,
        color: AppTheme.primary,
        enabled: true,
        onTap: () => context.goNamed('courses'),
      ),
"""
    addition = marker + """      _EducatorAction(
        title: 'Mis Exámenes',
        subtitle: 'Repositorio docente de exámenes, versiones y claves.',
        icon: Icons.assignment_add_rounded,
        color: AppTheme.accent,
        enabled: true,
        onTap: () => context.goNamed('saved-exams'),
      ),
"""
    text = text.replace(marker, addition)

center.write_text(text)
PY

cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

cd "$FLUTTER"
flutter analyze || true

cd "$ROOT"
grep -R "SavedExamsScreen\|saved-exams\|Mis Exámenes" \
mobile/campusai_mobile/lib -n

git status --short
