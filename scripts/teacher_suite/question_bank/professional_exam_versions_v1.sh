#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
FLUTTER="$ROOT/mobile/campusai_mobile"
BACKEND="$ROOT/backend"

python3 <<'PY'
from pathlib import Path

exam = Path("mobile/campusai_mobile/lib/screens/exam_screen.dart")
text = exam.read_text()

if "currentExamVersion" not in text:
    marker = """  String get currentExamTopic {
    if (questions.isEmpty) return '';
    return questions.first['exam_topic']?.toString() ?? '';
  }
"""
    insert = """  String get currentExamVersion {
    if (questions.isEmpty) return '';
    return questions.first['exam_version']?.toString() ?? '';
  }

  String get professionalExamTitle {
    final version = currentExamVersion.trim();
    if (version.isEmpty) {
      return l10n.examTitle;
    }

    return '${l10n.examTitle} - Versión $version';
  }

""" + marker
    text = text.replace(marker, insert)

text = text.replace(
    "title: l10n.examTitle,\n      questions: questions,",
    "title: professionalExamTitle,\n      questions: questions,",
)

text = text.replace(
    "title: l10n.examTitle,",
    "title: professionalExamTitle,",
)

exam.write_text(text)
PY

cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

cd "$FLUTTER"
flutter analyze || true

cd "$ROOT"
grep -R "currentExamVersion\|professionalExamTitle\|Versión" \
mobile/campusai_mobile/lib/screens/exam_screen.dart -n

git status --short
