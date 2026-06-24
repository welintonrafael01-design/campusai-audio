#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
FLUTTER="$ROOT/mobile/campusai_mobile"
BACKEND="$ROOT/backend"

python3 <<'PY'
from pathlib import Path

path = Path("mobile/campusai_mobile/lib/screens/saved_exams_screen.dart")
text = path.read_text()

text = text.replace(
"""  bool isLoading = true;
  List<Map<String, dynamic>> exams = [];
""",
"""  bool isLoading = true;
  String search = '';
  List<Map<String, dynamic>> exams = [];
""",
)

text = text.replace(
"""  String createdAt(Map<String, dynamic> item) {
    return item['created_at']?.toString() ??
        item['createdAt']?.toString() ??
        '';
  }
""",
"""  String createdAt(Map<String, dynamic> item) {
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
""",
)

text = text.replace(
"""    final documentId = item['document_id']?.toString() ??
        item['documentId']?.toString() ??
        item['id']?.toString() ??
        '';
""",
"""    final documentId = documentIdFor(item);
""",
)

text = text.replace(
"""                      Text(
                        '${exams.length} exámenes guardados. Aquí podrás abrir exámenes creados desde documentos, bancos de preguntas o cursos.',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
""",
"""                      Text(
                        '${filteredExams.length} de ${exams.length} exámenes. Aquí podrás abrir, buscar y eliminar exámenes creados desde documentos, bancos de preguntas o cursos.',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
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
""",
)

text = text.replace(
"""                if (exams.isEmpty)
""",
"""                if (filteredExams.isEmpty)
""",
)

text = text.replace(
"""                  ...exams.map((item) {
""",
"""                  ...filteredExams.map((item) {
""",
)

text = text.replace(
"""                            FilledButton.icon(
                              onPressed: () => openExam(item),
                              icon: const Icon(Icons.open_in_new_rounded),
                              label: const Text('Abrir'),
                            ),
""",
"""                            Wrap(
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
""",
)

path.write_text(text)
PY

cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

cd "$FLUTTER"
flutter analyze || true

cd "$ROOT"
grep -R "deleteExam\|filteredExams\|Buscar examen\|Eliminar examen" \
mobile/campusai_mobile/lib/screens/saved_exams_screen.dart -n

git status --short
