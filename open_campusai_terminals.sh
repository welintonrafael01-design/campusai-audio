#!/bin/bash

PROJECT="$HOME/Desktop/campusai-audio"
BACKEND="$PROJECT/backend"
FLUTTER="$PROJECT/mobile/campusai_mobile"

osascript <<EOF
tell application "Terminal"
    activate

    do script "printf '\\\\e]1;🚀 Backend API\\\\a'; printf '\\\\e]2;🚀 Backend API\\\\a'; cd $BACKEND; source .venv/bin/activate; uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"

    do script "printf '\\\\e]1;📱 Flutter Web\\\\a'; printf '\\\\e]2;📱 Flutter Web\\\\a'; cd $FLUTTER; flutter run -d chrome --dart-define=SUPABASE_URL=https://olegevhncmblxngurclt.supabase.co --dart-define=SUPABASE_ANON_KEY=sb_publishable_lN6s33WgVl8_hfbeLlDSfg__E-yA8H7 --dart-define=ADMIN_API_KEY=campusai-admin-local-2026"

    do script "printf '\\\\e]1;🌳 Git Control\\\\a'; printf '\\\\e]2;🌳 Git Control\\\\a'; cd $PROJECT; git status"

    do script "printf '\\\\e]1;📊 Analytics\\\\a'; printf '\\\\e]2;📊 Analytics\\\\a'; cd $BACKEND; while true; do clear; curl -s -H 'X-Admin-Key: campusai-admin-local-2026' http://localhost:8000/analytics/summary; echo; sleep 5; done"

    do script "printf '\\\\e]1;🧠 ChromaDB\\\\a'; printf '\\\\e]2;🧠 ChromaDB\\\\a'; cd $BACKEND; while true; do clear; du -sh chroma_db; echo; find chroma_db | wc -l; sleep 10; done"

    do script "printf '\\\\e]1;📜 Logs\\\\a'; printf '\\\\e]2;📜 Logs\\\\a'; cd $BACKEND; tail -f logs/usage_events.jsonl"
end tell
EOF
