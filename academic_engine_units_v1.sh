#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
FLUTTER="$ROOT/mobile/campusai_mobile"
BACKEND="$ROOT/backend"

python3 <<'PY'
from pathlib import Path

path = Path("mobile/campusai_mobile/lib/screens/courses_screen.dart")
text = path.read_text()

old = """      final rawPlan = data['teaching_plan'];
      final plan = rawPlan is Map
          ? Map<String, dynamic>.from(rawPlan)
          : <String, dynamic>{};

      final content = jsonEncode(plan);
"""

new = """      final rawPlan = data['teaching_plan'];
      final plan = rawPlan is Map
          ? Map<String, dynamic>.from(rawPlan)
          : <String, dynamic>{};

      final rawWeeks = plan['weeks'];
      if (rawWeeks is List) {
        plan['weeks'] = rawWeeks.asMap().entries.map((entry) {
          final index = entry.key;
          final rawWeek = entry.value;
          final week = rawWeek is Map
              ? Map<String, dynamic>.from(rawWeek)
              : <String, dynamic>{};

          final unitNumber = week['week']?.toString().trim().isNotEmpty == true
              ? week['week'].toString()
              : '${index + 1}';

          return {
            ...week,
            'unit_id': '${course.id}_unit_$unitNumber',
            'course_id': course.id,
            'course_name': course.name,
            'course_code': course.code,
            'course_section': course.section,
            'course_period': course.period,
            'course_display_name': course.displayName,
            'source_document_id': program.documentId,
            'resources_status': {
              'planning': true,
              'question_bank': false,
              'exam': false,
              'rubric': false,
              'study_guide': false,
              'presentation': false,
            },
          };
        }).toList();
      }

      plan['course_id'] = course.id;
      plan['course_name'] = course.name;
      plan['course_code'] = course.code;
      plan['course_section'] = course.section;
      plan['course_period'] = course.period;
      plan['course_display_name'] = course.displayName;
      plan['source_document_id'] = program.documentId;

      final content = jsonEncode(plan);
"""

if old not in text:
    raise SystemExit("No se encontró el bloque rawPlan esperado.")

text = text.replace(old, new)
path.write_text(text)
PY

cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

cd "$FLUTTER"
flutter analyze || true

cd "$ROOT"
grep -R "unit_id\\|resources_status\\|course_display_name" \
mobile/campusai_mobile/lib/screens/courses_screen.dart -n

git status --short
