#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
FLUTTER="$ROOT/mobile/campusai_mobile"
BACKEND="$ROOT/backend"

python3 <<'PY'
from pathlib import Path

# 1) QuestionBankScreen: importar CloudApiService y guardar examen en Cloud
path = Path("mobile/campusai_mobile/lib/screens/question_bank_screen.dart")
text = path.read_text()

if "cloud_api_service.dart" not in text:
    text = text.replace(
        "import '../services/api_service.dart';",
        "import '../services/api_service.dart';\nimport '../services/cloud_api_service.dart';",
    )

old = """    await StudyResultService.saveResult(
      StudyResult(
        documentId: examId,
        type: 'exam',
        content: content,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    if (!mounted) return;
"""

new = """    await StudyResultService.saveResult(
      StudyResult(
        documentId: examId,
        type: 'exam',
        content: content,
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    try {
      await CloudApiService.saveStudyResult(
        documentId: examId,
        type: 'exam',
        content: content,
      );
    } catch (cloudError) {
      debugPrint('No se pudo guardar examen de banco en cloud: $cloudError');
    }

    if (!mounted) return;
"""

if old not in text:
    raise SystemExit("No se encontró bloque de guardado de examen en question_bank_screen.dart")

text = text.replace(old, new, 1)
path.write_text(text)

# 2) CoursesScreen: importar CloudApiService si falta
path = Path("mobile/campusai_mobile/lib/screens/courses_screen.dart")
text = path.read_text()

if "cloud_api_service.dart" not in text:
    text = text.replace(
        "import '../services/course_service.dart';",
        "import '../services/course_service.dart';\nimport '../services/cloud_api_service.dart';",
    )

# 3) CoursesScreen: corregir limitación + metadata completa + cloud en generateCourseExam
text = text.replace(
"""      final limitedQuestions = questions.take(count).toList();

      final pointsPerQuestion = questions.isEmpty
          ? 0
          : totalPoints / questions.length;

      final enrichedQuestions = questions.map((item) {
""",
"""      final limitedQuestions = questions.take(count).toList();

      final pointsPerQuestion = limitedQuestions.isEmpty
          ? 0
          : totalPoints / limitedQuestions.length;

      final enrichedQuestions = limitedQuestions.map((item) {
""",
1,
)

old = """      await StudyResultService.saveResult(
        StudyResult(
          documentId: examId,
          type: 'exam',
          content: content,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      if (!mounted) return;
"""

new = """      await StudyResultService.saveResult(
        StudyResult(
          documentId: examId,
          type: 'exam',
          content: content,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );

      try {
        await CloudApiService.saveStudyResult(
          documentId: examId,
          type: 'exam',
          content: content,
        );
      } catch (cloudError) {
        debugPrint('No se pudo guardar examen de curso en cloud: $cloudError');
      }

      if (!mounted) return;
"""

if old not in text:
    raise SystemExit("No se encontró bloque de guardado de examen en courses_screen.dart")

text = text.replace(old, new, 1)

# Navegar con enrichedQuestions, no limitedQuestions
text = text.replace(
"""        extra: limitedQuestions,
      );
""",
"""        extra: enrichedQuestions,
      );
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
grep -R "CloudApiService.saveStudyResult\|examen de banco\|examen de curso\|extra: enrichedQuestions" \
mobile/campusai_mobile/lib/screens/question_bank_screen.dart \
mobile/campusai_mobile/lib/screens/courses_screen.dart -n

git status --short
