#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
FLUTTER="$ROOT/mobile/campusai_mobile"
BACKEND="$ROOT/backend"

python3 <<'PY'
from pathlib import Path

path = Path("mobile/campusai_mobile/lib/screens/question_bank_screen.dart")
text = path.read_text()

if "int get requestedQuestionsCount" not in text:
    marker = "  String get bankTitle {"
    insert = """  int get requestedQuestionsCount {
    if (questions.isEmpty) return 0;

    final value = questions.first['requested_questions'] ??
        questions.first['number_of_questions'] ??
        questions.first['requested_count'];

    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? questions.length;
  }

  String get bankScopeLabel {
    if (questions.isEmpty) return 'Banco general';

    final courseName = questions.first['course_name']?.toString().trim() ?? '';
    final courseId = questions.first['course_id']?.toString().trim() ?? '';

    if (courseName.isNotEmpty || courseId.isNotEmpty) {
      return 'Banco del curso';
    }

    return 'Banco general';
  }

  String get bankExplanation {
    if (bankScopeLabel == 'Banco del curso') {
      return 'Banco asociado a un curso, programa, tema, objetivo y competencia. Ideal para docentes que desean reutilizar preguntas y crear exámenes por asignatura.';
    }

    return 'Banco generado desde el PDF activo del Dashboard. Ideal para estudiar, repasar o crear preguntas rápidas desde cualquier documento.';
  }

"""
    text = text.replace(marker, insert + marker)

text = text.replace(
    "'${questions.length} preguntas reutilizables generadas con IA.'",
    "'Solicitadas: ${requestedQuestionsCount == 0 ? questions.length : requestedQuestionsCount} | Generadas: ${questions.length}'",
)

# Agregar explicación debajo del contador, si el bloque existe.
old = """                  '${questions.length} preguntas reutilizables generadas con IA.',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),"""

new = """                  'Solicitadas: ${requestedQuestionsCount == 0 ? questions.length : requestedQuestionsCount} | Generadas: ${questions.length}',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$bankScopeLabel: $bankExplanation',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),"""

if old in text:
    text = text.replace(old, new)

path.write_text(text)

# Guardar metadata requested_questions al generar desde curso.
path = Path("mobile/campusai_mobile/lib/screens/courses_screen.dart")
text = path.read_text()

text = text.replace(
    """                    'bloom_level': bloomLevel,
                  })""",
    """                    'bloom_level': bloomLevel,
                    'requested_questions': count,
                    'bank_scope': 'course',
                  })""",
)

path.write_text(text)
PY

cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

cd "$FLUTTER"
flutter analyze || true

cd "$ROOT"
grep -R "requestedQuestionsCount\|bankExplanation\|requested_questions\|bank_scope" \
mobile/campusai_mobile/lib/screens/question_bank_screen.dart \
mobile/campusai_mobile/lib/screens/courses_screen.dart -n

git status --short
