#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
FLUTTER="$ROOT/mobile/campusai_mobile"
BACKEND="$ROOT/backend"

echo "===== ADD FLUTTER EDUCATOR SYNC V1 ====="

cat > "$FLUTTER/lib/services/educator_sync_service.dart" <<'DART'
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';
import 'auth_service.dart';

class EducatorSyncService {
  const EducatorSyncService();

  static const String coursesKey = 'studybook_courses';
  static const String studentsKey = 'studybook_students_roster';
  static const String attendanceKey = 'studybook_attendance_entries';
  static const String gradebookKey = 'studybook_gradebook_entries';

  static Future<Map<String, dynamic>> getSnapshot() async {
    if (!AuthService.isLoggedIn) {
      return {};
    }

    final response = await http
        .get(
          Uri.parse('${ApiService.baseUrl}/educator/snapshot'),
          headers: AuthService.authHeaders,
        )
        .timeout(ApiService.timeoutDuration);

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar Educator desde Supabase.');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {};
  }

  static Future<void> pushLocalSnapshot() async {
    if (!AuthService.isLoggedIn) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    final payload = {
      'courses': _decodeStringList(
        prefs.getStringList(coursesKey) ?? const [],
      ),
      'students': _decodeStringList(
        prefs.getStringList(studentsKey) ?? const [],
      ),
      'attendance': _decodeStringList(
        prefs.getStringList(attendanceKey) ?? const [],
      ),
      'gradebook': _decodeStringList(
        prefs.getStringList(gradebookKey) ?? const [],
      ),
    };

    await http
        .post(
          Uri.parse('${ApiService.baseUrl}/educator/sync'),
          headers: {
            'Content-Type': 'application/json',
            ...AuthService.authHeaders,
          },
          body: jsonEncode(payload),
        )
        .timeout(ApiService.timeoutDuration);
  }

  static Future<void> pullRemoteIntoLocalIfAvailable() async {
    try {
      final snapshot = await getSnapshot();
      final prefs = await SharedPreferences.getInstance();

      await _saveListIfNotEmpty(
        prefs: prefs,
        key: coursesKey,
        value: snapshot['courses'],
      );
      await _saveListIfNotEmpty(
        prefs: prefs,
        key: studentsKey,
        value: snapshot['students'],
      );
      await _saveListIfNotEmpty(
        prefs: prefs,
        key: attendanceKey,
        value: snapshot['attendance'],
      );
      await _saveListIfNotEmpty(
        prefs: prefs,
        key: gradebookKey,
        value: snapshot['gradebook'],
      );
    } catch (_) {
      // Modo seguro: si falla Supabase, se conserva SharedPreferences.
    }
  }

  static Future<void> syncAfterLocalWrite() async {
    try {
      await pushLocalSnapshot();
    } catch (_) {
      // Modo offline/fallback local.
    }
  }

  static List<Map<String, dynamic>> _decodeStringList(List<String> raw) {
    return raw
        .map((item) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is Map<String, dynamic>) return decoded;
            if (decoded is Map) return Map<String, dynamic>.from(decoded);
          } catch (_) {}
          return null;
        })
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  static Future<void> _saveListIfNotEmpty({
    required SharedPreferences prefs,
    required String key,
    required dynamic value,
  }) async {
    if (value is! List || value.isEmpty) {
      return;
    }

    final encoded = value
        .whereType<Map>()
        .map((item) => jsonEncode(Map<String, dynamic>.from(item)))
        .toList();

    if (encoded.isNotEmpty) {
      await prefs.setStringList(key, encoded);
    }
  }
}
DART

python3 <<'PY'
from pathlib import Path

flutter = Path.home() / "Desktop/campusai-audio/mobile/campusai_mobile"

files = [
    "lib/services/course_service.dart",
    "lib/services/student_roster_service.dart",
    "lib/services/attendance_service.dart",
    "lib/services/gradebook_service.dart",
]

for rel in files:
    path = flutter / rel
    text = path.read_text()

    if "educator_sync_service.dart" not in text:
        # Insert after shared_preferences import if available.
        text = text.replace(
            "import 'package:shared_preferences/shared_preferences.dart';",
            "import 'package:shared_preferences/shared_preferences.dart';\nimport 'educator_sync_service.dart';",
            1,
        )

    path.write_text(text)

# course_service.dart
path = flutter / "lib/services/course_service.dart"
text = path.read_text()
text = text.replace(
    "    await prefs.setStringList(\n      _key,",
    "    await prefs.setStringList(\n      _key,",
)
if "await EducatorSyncService.syncAfterLocalWrite();" not in text:
    text = text.replace(
        "    await prefs.setStringList(\n      _key,\n      courses\n          .where((item) => item.isValid)\n          .map((item) => jsonEncode(item.toJson()))\n          .toList(),\n    );",
        "    await prefs.setStringList(\n      _key,\n      courses\n          .where((item) => item.isValid)\n          .map((item) => jsonEncode(item.toJson()))\n          .toList(),\n    );\n\n    await EducatorSyncService.syncAfterLocalWrite();",
    )
path.write_text(text)

# student_roster_service.dart
path = flutter / "lib/services/student_roster_service.dart"
text = path.read_text()
if "await EducatorSyncService.syncAfterLocalWrite();" not in text:
    text = text.replace(
        "    await prefs.setStringList(_key, encoded);",
        "    await prefs.setStringList(_key, encoded);\n\n    await EducatorSyncService.syncAfterLocalWrite();",
        1,
    )
path.write_text(text)

# attendance_service.dart
path = flutter / "lib/services/attendance_service.dart"
text = path.read_text()
if "EducatorSyncService.syncAfterLocalWrite()" not in text:
    text = text.replace(
        "    await prefs.setStringList(\n      _key,\n      current.map((item) => jsonEncode(item.toJson())).toList(),\n    );",
        "    await prefs.setStringList(\n      _key,\n      current.map((item) => jsonEncode(item.toJson())).toList(),\n    );\n\n    await EducatorSyncService.syncAfterLocalWrite();",
        1,
    )
    text = text.replace(
        "    await prefs.setStringList(\n      _key,\n      entries.map((item) => jsonEncode(item.toJson())).toList(),\n    );",
        "    await prefs.setStringList(\n      _key,\n      entries.map((item) => jsonEncode(item.toJson())).toList(),\n    );\n\n    await EducatorSyncService.syncAfterLocalWrite();",
        1,
    )
path.write_text(text)

# gradebook_service.dart
path = flutter / "lib/services/gradebook_service.dart"
text = path.read_text()
if "EducatorSyncService.syncAfterLocalWrite()" not in text:
    text = text.replace(
        "    await prefs.setStringList(\n      _key,\n      entries.map((item) => jsonEncode(item.toJson())).toList(),\n    );",
        "    await prefs.setStringList(\n      _key,\n      entries.map((item) => jsonEncode(item.toJson())).toList(),\n    );\n\n    await EducatorSyncService.syncAfterLocalWrite();",
        1,
    )
    text = text.replace(
        "    await prefs.setStringList(\n      _key,\n      entries.map((item) => jsonEncode(item.toJson())).toList(),\n    );",
        "    await prefs.setStringList(\n      _key,\n      entries.map((item) => jsonEncode(item.toJson())).toList(),\n    );\n\n    await EducatorSyncService.syncAfterLocalWrite();",
        1,
    )
path.write_text(text)
PY

echo ""
echo "===== BACKEND COMPILE ====="
cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

echo ""
echo "===== FLUTTER ANALYZE ====="
cd "$FLUTTER"
flutter analyze || true

echo ""
echo "===== SYNC CHECK ====="
grep -R "EducatorSyncService\|educator/snapshot\|educator/sync" lib/services -n

echo ""
echo "===== GIT STATUS ====="
cd "$ROOT"
git status --short

echo ""
echo "===== DONE ====="
