#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
FLUTTER="$ROOT/mobile/campusai_mobile"
BACKEND="$ROOT/backend"

python3 <<'PY'
from pathlib import Path

path = Path("mobile/campusai_mobile/lib/screens/courses_screen.dart")
text = path.read_text()

# Enriquecer exámenes generados desde curso
text = text.replace(
"""          'course_id': course.id,
          'course_name': course.name,
          'exam_topic': examTopic,
          'exam_objective': examObjective,
        };
""",
"""          'course_id': course.id,
          'course_name': course.name,
          'course_code': course.code,
          'course_section': course.section,
          'course_period': course.period,
          'course_display_name': course.displayName,
          'exam_topic': examTopic,
          'exam_objective': examObjective,
          'exam_source': 'Curso',
        };
"""
)

# Enriquecer bancos de preguntas por curso
text = text.replace(
"""                    'course_id': course.id,
                    'course_name': course.name,
                    'program_topic': programTopic,
""",
"""                    'course_id': course.id,
                    'course_name': course.name,
                    'course_code': course.code,
                    'course_section': course.section,
                    'course_period': course.period,
                    'course_display_name': course.displayName,
                    'program_topic': programTopic,
"""
)

path.write_text(text)

# Mejorar Mis Exámenes para mostrar course_display_name si existe
path = Path("mobile/campusai_mobile/lib/screens/saved_exams_screen.dart")
text = path.read_text()

text = text.replace(
"""      final courseName = questions.first['course_name']?.toString().trim() ?? '';
""",
"""      final courseName = questions.first['course_display_name']?.toString().trim().isNotEmpty == true
          ? questions.first['course_display_name']!.toString().trim()
          : questions.first['course_name']?.toString().trim() ?? '';
""",
1,
)

text = text.replace(
"""    final courseName = first['course_name']?.toString().trim() ?? '';
""",
"""    final courseName = first['course_display_name']?.toString().trim().isNotEmpty == true
        ? first['course_display_name']!.toString().trim()
        : first['course_name']?.toString().trim() ?? '';
""",
1,
)

path.write_text(text)
PY

cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

cd "$FLUTTER"
flutter analyze || true

cd "$ROOT"
grep -R "course_display_name\|course_section\|course_period\|exam_source': 'Curso" \
mobile/campusai_mobile/lib/screens/courses_screen.dart \
mobile/campusai_mobile/lib/screens/saved_exams_screen.dart -n

git status --short
