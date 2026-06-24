#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
BACKEND="$ROOT/backend"
FLUTTER="$ROOT/mobile/campusai_mobile"

python3 <<'PY'
from pathlib import Path

# 1) Backend: aceptar campos académicos y enriquecer contexto
path = Path("backend/app/routes/documents.py")
text = path.read_text()

text = text.replace(
'''    language: str = Query(default="es"),
    current_user: AuthenticatedUser = Depends(require_current_user),
):''',
'''    language: str = Query(default="es"),
    program_topic: str = Query(default=""),
    learning_objective: str = Query(default=""),
    competency: str = Query(default=""),
    bloom_level: str = Query(default=""),
    current_user: AuthenticatedUser = Depends(require_current_user),
):''',
1,
)

old_question = '''            question=(
                "banco de preguntas conceptos clave evaluación "
                "comprensión aplicación análisis académico"
            ),'''

new_question = '''            question=(
                "banco de preguntas conceptos clave evaluación "
                "comprensión aplicación análisis académico "
                f"tema del programa: {program_topic} "
                f"objetivo de aprendizaje: {learning_objective} "
                f"competencia: {competency} "
                f"nivel bloom: {bloom_level}"
            ),'''

text = text.replace(old_question, new_question, 1)

text = text.replace(
'''                "mode": "single_document_question_bank",
            },''',
'''                "mode": "single_document_question_bank",
                "program_topic": program_topic,
                "learning_objective": learning_objective,
                "competency": competency,
                "bloom_level": bloom_level,
            },''',
1,
)

path.write_text(text)

# 2) Flutter ApiService: agregar parámetros opcionales
path = Path("mobile/campusai_mobile/lib/services/api_service.dart")
text = path.read_text()

old_sig = '''  static Future<Map<String, dynamic>> generateQuestionBankByDocumentId({
    required String documentId,
    int numberOfQuestions = 50,
  }) async {'''

new_sig = '''  static Future<Map<String, dynamic>> generateQuestionBankByDocumentId({
    required String documentId,
    int numberOfQuestions = 50,
    String programTopic = '',
    String learningObjective = '',
    String competency = '',
    String bloomLevel = '',
  }) async {'''

text = text.replace(old_sig, new_sig)

old_params = '''      queryParameters: {
        'number_of_questions': numberOfQuestions.toString(),
        'language': language,
      },'''

new_params = '''      queryParameters: {
        'number_of_questions': numberOfQuestions.toString(),
        'language': language,
        if (programTopic.trim().isNotEmpty) 'program_topic': programTopic.trim(),
        if (learningObjective.trim().isNotEmpty) 'learning_objective': learningObjective.trim(),
        if (competency.trim().isNotEmpty) 'competency': competency.trim(),
        if (bloomLevel.trim().isNotEmpty) 'bloom_level': bloomLevel.trim(),
      },'''

text = text.replace(old_params, new_params, 1)

path.write_text(text)

# 3) Courses: convertir pickQuestionBankCount en opciones académicas
path = Path("mobile/campusai_mobile/lib/screens/courses_screen.dart")
text = path.read_text()

old_method = text[text.index("  Future<int?> pickQuestionBankCount() async {"):text.index("  Future<void> generateCourseQuestionBank", text.index("  Future<int?> pickQuestionBankCount() async {"))]

new_method = r'''  Future<Map<String, dynamic>?> pickQuestionBankOptions() async {
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

'''

text = text.replace(old_method, new_method)

text = text.replace(
'''    final count = await pickQuestionBankCount();
    if (count == null) return;''',
'''    final bankOptions = await pickQuestionBankOptions();
    if (bankOptions == null) return;

    final count = bankOptions['count'] as int;
    final programTopic = bankOptions['programTopic'] as String;
    final learningObjective = bankOptions['learningObjective'] as String;
    final competency = bankOptions['competency'] as String;
    final bloomLevel = bankOptions['bloomLevel'] as String;''',
)

text = text.replace(
'''        documentId: program.documentId,
        numberOfQuestions: count,
      );''',
'''        documentId: program.documentId,
        numberOfQuestions: count,
        programTopic: programTopic,
        learningObjective: learningObjective,
        competency: competency,
        bloomLevel: bloomLevel,
      );''',
)

text = text.replace(
'''                    'course_name': course.name,
                  })''',
'''                    'course_name': course.name,
                    'program_topic': programTopic,
                    'learning_objective': learningObjective,
                    'competency': competency,
                    'bloom_level': bloomLevel,
                  })''',
)

path.write_text(text)

# 4) Dashboard: agregar defaults seguros para que compile y pase datos vacíos por ahora
path = Path("mobile/campusai_mobile/lib/screens/dashboard_screen.dart")
text = path.read_text()
text = text.replace(
'''        documentId: documentId,
        numberOfQuestions: 50,
      );''',
'''        documentId: documentId,
        numberOfQuestions: 50,
      );''',
1,
)
path.write_text(text)
PY

cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

cd "$FLUTTER"
flutter analyze || true

cd "$ROOT"
grep -R "programTopic\|learningObjective\|competency\|bloomLevel\|program_topic" \
backend/app/routes/documents.py \
mobile/campusai_mobile/lib/services/api_service.dart \
mobile/campusai_mobile/lib/screens/courses_screen.dart -n

git status --short
