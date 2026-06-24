#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
BACKEND="$ROOT/backend"
FLUTTER="$ROOT/mobile/campusai_mobile"

python3 <<'PY'
from pathlib import Path

# 1) Backend: permitir bancos de hasta 100 preguntas
path = Path("backend/app/services/ai_service.py")
text = path.read_text()
text = text.replace(
    "safe_number = max(1, min(number_of_questions, 20))",
    "safe_number = max(1, min(number_of_questions, 100))",
)
path.write_text(text)

# 2) Frontend: título dinámico del banco
path = Path("mobile/campusai_mobile/lib/screens/question_bank_screen.dart")
text = path.read_text()

if "String get bankTitle" not in text:
    marker = "  List<Map<String, dynamic>> get filteredQuestions {"
    insert = """  String get bankTitle {
    if (questions.isEmpty) return 'Banco de preguntas';

    final courseName = questions.first['course_name']?.toString().trim() ?? '';
    final topic = questions.first['program_topic']?.toString().trim() ?? '';

    if (courseName.isNotEmpty && topic.isNotEmpty) {
      return 'Banco de preguntas — $courseName / $topic';
    }

    if (courseName.isNotEmpty) {
      return 'Banco de preguntas — $courseName';
    }

    if (topic.isNotEmpty) {
      return 'Banco de preguntas — $topic';
    }

    return 'Banco de preguntas';
  }

"""
    text = text.replace(marker, insert + marker)

text = text.replace(
    "'Banco de preguntas Educator'",
    "bankTitle",
)

path.write_text(text)
PY

cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

cd "$FLUTTER"
flutter analyze || true

cd "$ROOT"
grep -R "safe_number = max(1, min(number_of_questions, 100))\|bankTitle\|Banco de preguntas —" \
backend/app/services/ai_service.py \
mobile/campusai_mobile/lib/screens/question_bank_screen.dart -n

git status --short
