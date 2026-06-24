#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
BACKEND="$ROOT/backend"
FLUTTER="$ROOT/mobile/campusai_mobile"

python3 <<'PY'
from pathlib import Path

path = Path("backend/app/routes/documents.py")
text = path.read_text()

start = text.index('@router.post("/question-bank/{document_id}")')
end = text.index('    current_user: AuthenticatedUser = Depends(require_current_user),', start)

signature_block = text[start:end + len('    current_user: AuthenticatedUser = Depends(require_current_user),')]

if 'program_topic: str = Query(default="")' not in signature_block:
    signature_block = signature_block.replace(
        '    language: str = Query(default="es"),\n',
        '''    language: str = Query(default="es"),
    program_topic: str = Query(default=""),
    learning_objective: str = Query(default=""),
    competency: str = Query(default=""),
    bloom_level: str = Query(default=""),
'''
    )

    text = text[:start] + signature_block + text[end + len('    current_user: AuthenticatedUser = Depends(require_current_user),'):]

path.write_text(text)
PY

cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

grep -n "question_bank_document_by_id" -A24 app/routes/documents.py

cd "$FLUTTER"
flutter analyze || true

cd "$ROOT"
git status --short
