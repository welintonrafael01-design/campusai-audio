#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
FLUTTER="$ROOT/mobile/campusai_mobile"
BACKEND="$ROOT/backend"

python3 <<'PY'
from pathlib import Path

path = Path("mobile/campusai_mobile/lib/screens/question_bank_screen.dart")
text = path.read_text()

# 1) Agregar outputMode si no existe
text = text.replace(
    "    String examVersion = 'Estudiante';\n",
    "    String examVersion = 'A';\n    String outputMode = 'Estudiante';\n",
)

# 2) Cambiar bloque visual de versión vieja por tipo de salida + versión A/B/C
old = """                      const Text(
                        'Versión del examen',
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
                            selected: examVersion == item,
                            onSelected: (_) {
                              setDialogState(() => examVersion = item);
                            },
                          );
                        }).toList(),
                      ),
"""

new = """                      const Text(
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
"""

if old not in text:
    raise SystemExit("No se encontró el bloque de versión esperado.")

text = text.replace(old, new)

# 3) Retornar outputMode
text = text.replace(
    "                      'examVersion': examVersion,\n                      'examTopic': examTopic,",
    "                      'examVersion': examVersion,\n                      'outputMode': outputMode,\n                      'examTopic': examTopic,",
)

# 4) Leer outputMode en openAsExam
text = text.replace(
    "    final examVersion = options['examVersion'] as String;\n    final examTopic = options['examTopic'] as String;",
    "    final examVersion = options['examVersion'] as String;\n    final outputMode = options['outputMode'] as String;\n    final examTopic = options['examTopic'] as String;",
)

# 5) Enriquecer preguntas
text = text.replace(
    "        'exam_version': examVersion,\n        'exam_source': 'Banco de Preguntas',",
    "        'exam_version': examVersion,\n        'exam_output_mode': outputMode,\n        'exam_source': 'Banco de Preguntas',",
)

# 6) Versiones B/C: mezclar preguntas
text = text.replace(
    "    final pointsPerQuestion = selected.isEmpty ? 0 : totalPoints / selected.length;\n",
    """    if (examVersion == 'B' || examVersion == 'C') {
      selected.shuffle(Random());
    }

    final pointsPerQuestion = selected.isEmpty ? 0 : totalPoints / selected.length;
""",
)

path.write_text(text)
PY

cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

cd "$FLUTTER"
flutter analyze || true

cd "$ROOT"
grep -n "Tipo de salida\\|Versión A\\|exam_output_mode\\|outputMode" \
mobile/campusai_mobile/lib/screens/question_bank_screen.dart

git status --short
