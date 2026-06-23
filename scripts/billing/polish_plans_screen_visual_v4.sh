#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
FLUTTER="$ROOT/mobile/campusai_mobile"
BACKEND="$ROOT/backend"

python3 <<'PY'
from pathlib import Path

file = Path.home() / "Desktop/campusai-audio/mobile/campusai_mobile/lib/screens/plans_screen.dart"
text = file.read_text()

# Badges más comerciales
text = text.replace("badge: 'ESTUDIANTES',", "badge: 'MÁS POPULAR',")
text = text.replace("badge: 'PREMIUM',", "badge: 'MÁXIMO NIVEL',")
text = text.replace("isHighlighted: false,\n        benefits: [\n          'Límites ampliados premium'", "isHighlighted: true,\n        benefits: [\n          'Límites ampliados premium'")

# Textos más elegantes
text = text.replace(
    "audience: 'Para máximo rendimiento',",
    "audience: 'Para usuarios intensivos e instituciones',",
)
text = text.replace(
    "'Funciones beta y capacidades premium'",
    "'Acceso anticipado a funciones premium'",
)

# Reducir lockedBenefits visuales en Teacher
text = text.replace(
    """        lockedBenefits: [
          'Límites ilimitados',
          'Procesamiento prioritario',
          'Funciones beta premium',
        ],""",
    """        lockedBenefits: [
          'Procesamiento prioritario Ultra',
        ],""",
)

# Reducir lockedBenefits en Free para hacerlo más limpio
text = text.replace(
    """        lockedBenefits: [
          'Exportar DOCX y PPTX',
          'Modo voz completo',
          'Herramientas docentes',
          'Certificados e insignias',
        ],""",
    """        lockedBenefits: [
          'Funciones premium disponibles al actualizar',
        ],""",
)

# Mejorar footer
text = text.replace(
    "Puedes cambiar o cancelar tu plan desde la configuración de tu cuenta. Los precios pueden variar según promociones de lanzamiento.",
    "Puedes cambiar, mejorar o cancelar tu plan desde tu cuenta. Precios especiales de lanzamiento para StudyBook AI.",
)

file.write_text(text)
PY

cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

cd "$FLUTTER"
flutter analyze || true

cd "$ROOT"
grep -n "MÁS POPULAR\|MÁXIMO NIVEL\|instituciones\|Precios especiales" mobile/campusai_mobile/lib/screens/plans_screen.dart

git status --short
