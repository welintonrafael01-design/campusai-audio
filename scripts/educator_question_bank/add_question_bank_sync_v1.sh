#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
BACKEND="$ROOT/backend"
FLUTTER="$ROOT/mobile/campusai_mobile"

python3 <<'PY'
from pathlib import Path

# 1) Backend: agregar question_banks al payload/snapshot/sync
path = Path("backend/app/routes/educator.py")
text = path.read_text()

text = text.replace(
    "gradebook: list[dict[str, Any]] = Field(default_factory=list)",
    "gradebook: list[dict[str, Any]] = Field(default_factory=list)\n    question_banks: list[dict[str, Any]] = Field(default_factory=list)",
)

text = text.replace(
    '''        gradebook = _select_for_user_candidates(
            table="educator_gradebook",
            user_ids=user_ids,
        )''',
    '''        gradebook = _select_for_user_candidates(
            table="educator_gradebook",
            user_ids=user_ids,
        )
        question_banks = _select_for_user_candidates(
            table="educator_question_banks",
            user_ids=user_ids,
        )''',
)

text = text.replace(
    '''        "gradebook": [row.get("payload") or row for row in gradebook],
        "source": "supabase",''',
    '''        "gradebook": [row.get("payload") or row for row in gradebook],
        "question_banks": [row.get("payload") or row for row in question_banks],
        "source": "supabase",''',
)

insert_after = '''    gradebook_rows = []
    for item in payload.gradebook:
        record_id = _safe_text(item.get("id")).strip()
        if not record_id:
            continue

        gradebook_rows.append(
            {
                "id": record_id,
                "user_id": user_id,
                "course_id": _safe_text(item.get("courseId") or item.get("course_id")),
                "student_id": _safe_text(item.get("studentId") or item.get("student_id")),
                "assessment_name": _safe_text(
                    item.get("rubricTitle")
                    or item.get("assessmentName")
                    or item.get("assessment_name")
                ),
                "score": item.get("score") or 0,
                "max_score": item.get("maxScore") or item.get("max_score") or 0,
                "weight": item.get("weight"),
                "payload": item,
            }
        )
'''

addition = insert_after + '''
    question_bank_rows = []
    for item in payload.question_banks:
        record_id = _safe_text(item.get("id") or item.get("documentId")).strip()
        if not record_id:
            continue

        question_bank_rows.append(
            {
                "id": record_id,
                "user_id": user_id,
                "course_id": _safe_text(item.get("courseId") or item.get("course_id")),
                "title": _safe_text(item.get("title") or item.get("documentTitle") or "Banco de preguntas"),
                "payload": item,
            }
        )
'''

if "question_bank_rows = []" not in text:
    text = text.replace(insert_after, addition)

text = text.replace(
    '''            "gradebook": _upsert("educator_gradebook", gradebook_rows),
        }''',
    '''            "gradebook": _upsert("educator_gradebook", gradebook_rows),
            "question_banks": _upsert("educator_question_banks", question_bank_rows),
        }''',
)

path.write_text(text)

# 2) Flutter: EducatorSyncService sync question banks
path = Path("mobile/campusai_mobile/lib/services/educator_sync_service.dart")
text = path.read_text()

if "questionBanksKey" not in text:
    text = text.replace(
        "static const String gradebookKey = 'studybook_gradebook_entries';",
        "static const String gradebookKey = 'studybook_gradebook_entries';\n  static const String questionBanksKey = 'studybook_question_banks';",
    )

text = text.replace(
    '''      'gradebook': _decodeStringList(
        prefs.getStringList(gradebookKey) ?? const [],
      ),''',
    '''      'gradebook': _decodeStringList(
        prefs.getStringList(gradebookKey) ?? const [],
      ),
      'question_banks': _decodeStringList(
        prefs.getStringList(questionBanksKey) ?? const [],
      ),''',
)

text = text.replace(
    '''      await _saveListIfNotEmpty(
        prefs: prefs,
        key: gradebookKey,
        value: snapshot['gradebook'],
      );''',
    '''      await _saveListIfNotEmpty(
        prefs: prefs,
        key: gradebookKey,
        value: snapshot['gradebook'],
      );
      await _saveListIfNotEmpty(
        prefs: prefs,
        key: questionBanksKey,
        value: snapshot['question_banks'],
      );''',
)

path.write_text(text)

# 3) Flutter: StudyResultService guarda question_bank en lista sincronizable
path = Path("mobile/campusai_mobile/lib/services/study_result_service.dart")
text = path.read_text()

if "educator_sync_service.dart" not in text:
    text = text.replace(
        "import '../models/study_result.dart';",
        "import '../models/study_result.dart';\nimport 'educator_sync_service.dart';",
    )

old = '''    await prefs.setString(
      _buildKey(result.documentId, result.type),
      jsonEncode(result.toJson()),
    );'''

new = '''    await prefs.setString(
      _buildKey(result.documentId, result.type),
      jsonEncode(result.toJson()),
    );

    if (result.type == 'question_bank') {
      final current = prefs.getStringList(EducatorSyncService.questionBanksKey) ?? [];
      final asJson = result.toJson();
      asJson['id'] = result.documentId;
      asJson['documentId'] = result.documentId;

      final updated = current
          .map((item) {
            try {
              final decoded = jsonDecode(item);
              if (decoded is Map && decoded['documentId']?.toString() == result.documentId) {
                return null;
              }
            } catch (_) {}
            return item;
          })
          .whereType<String>()
          .toList();

      updated.insert(0, jsonEncode(asJson));
      await prefs.setStringList(EducatorSyncService.questionBanksKey, updated);
      await EducatorSyncService.syncAfterLocalWrite();
    }'''

text = text.replace(old, new)
path.write_text(text)
PY

cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

cd "$FLUTTER"
flutter analyze || true

cd "$ROOT"
grep -R "question_banks\|questionBanksKey\|studybook_question_banks" \
backend/app/routes/educator.py \
mobile/campusai_mobile/lib/services/educator_sync_service.dart \
mobile/campusai_mobile/lib/services/study_result_service.dart -n

git status --short
