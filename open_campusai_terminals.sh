#!/bin/bash

PROJECT="$HOME/Desktop/campusai-audio"
BACKEND="$PROJECT/backend"
FLUTTER="$PROJECT/mobile/campusai_mobile"

API_BASE_URL="http://localhost:8000"
WEB_PORT="54713"
SUPABASE_URL="https://olegevhncmblxngurclt.supabase.co"
SUPABASE_ANON_KEY="sb_publishable_lN6s33WgVl8_hfbeLlDSfg__E-yA8H7"

echo "======================================"
echo " StudyBook AI Launcher"
echo "======================================"
echo "1) Modo normal"
echo "2) Modo desarrollo con selector de planes"
echo "======================================"
read -p "Selecciona una opción [1-2]: " MODE

PLAN_TESTER_DEFINE=""

if [ "$MODE" = "2" ]; then
  PLAN_TESTER_DEFINE="--dart-define=ENABLE_PLAN_TESTER=true"
  FLUTTER_TITLE="📱 Flutter Web DEV"
else
  FLUTTER_TITLE="📱 Flutter Web"
fi

osascript <<EOF2
tell application "Terminal"
    activate

    do script "printf '\\\\e]1;🚀 Backend API\\\\a'; printf '\\\\e]2;🚀 Backend API\\\\a'; cd $BACKEND; source .venv/bin/activate; uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload"

    do script "printf '\\\\e]1;$FLUTTER_TITLE\\\\a'; printf '\\\\e]2;$FLUTTER_TITLE\\\\a'; cd $FLUTTER; flutter run -d chrome --web-port=$WEB_PORT --dart-define=API_BASE_URL=$API_BASE_URL --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY $PLAN_TESTER_DEFINE"

    do script "printf '\\\\e]1;🌳 Git Control\\\\a'; printf '\\\\e]2;🌳 Git Control\\\\a'; cd $PROJECT; git status"

    do script "printf '\\\\e]1;📊 Analytics\\\\a'; printf '\\\\e]2;📊 Analytics\\\\a'; echo 'Monitor admin deshabilitado: usa una herramienta backend autenticada.'"

    do script "printf '\\\\e]1;🧠 ChromaDB\\\\a'; printf '\\\\e]2;🧠 ChromaDB\\\\a'; cd $BACKEND; while true; do clear; du -sh chroma_db; echo; find chroma_db | wc -l; sleep 10; done"

    do script "printf '\\\\e]1;📜 Logs\\\\a'; printf '\\\\e]2;📜 Logs\\\\a'; cd $BACKEND; tail -f logs/usage_events.jsonl"
end tell
EOF2
