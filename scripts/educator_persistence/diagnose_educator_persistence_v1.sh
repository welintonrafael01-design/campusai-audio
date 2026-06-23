#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
FLUTTER="$ROOT/mobile/campusai_mobile"
BACKEND="$ROOT/backend"

echo "===== EDUCATOR PERSISTENCE DIAGNOSTIC ====="

echo ""
echo "--- Flutter localStorage refs ---"
cd "$FLUTTER"
grep -R "localStorage\|window.localStorage\|studybook.*course\|course.*storage\|student.*storage\|attendance.*storage\|gradebook.*storage" lib -n || true

echo ""
echo "--- Educator services ---"
find lib/services -maxdepth 1 -type f | sort
echo ""
grep -R "class .*Service\|localStorage\|http\.|ApiService.baseUrl" lib/services -n || true

echo ""
echo "--- Educator screens refs ---"
grep -R "CourseService\|StudentRosterService\|AttendanceService\|GradebookService\|Rubric\|QuestionBank" lib/screens lib/widgets -n || true

echo ""
echo "--- Backend tables/services refs ---"
cd "$BACKEND"
grep -R "courses\|students\|attendance\|gradebook\|rubrics\|question_bank" app -n || true

echo ""
echo "--- Validation ---"
python -m py_compile $(find app -name "*.py")

cd "$FLUTTER"
flutter analyze || true

echo ""
echo "===== GIT STATUS ====="
cd "$ROOT"
git status --short

echo ""
echo "===== DONE ====="
