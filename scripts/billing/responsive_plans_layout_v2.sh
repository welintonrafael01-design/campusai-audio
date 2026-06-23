#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
FLUTTER="$ROOT/mobile/campusai_mobile"
BACKEND="$ROOT/backend"
FILE="$FLUTTER/lib/screens/plans_screen.dart"

python3 <<'PY'
from pathlib import Path
import re

file = Path.home() / "Desktop/campusai-audio/mobile/campusai_mobile/lib/screens/plans_screen.dart"
text = file.read_text()

old = re.search(
    r"""          LayoutBuilder\(
            builder: \(context, constraints\) \{
              final isWide = constraints\.maxWidth >= .*?
              if \(!isWide\) \{
                return Column\(
                  children: cards
                      \.map\(
                        \(card\) => Padding\(
                          padding: const EdgeInsets\.only\(bottom: 16\),
                          child: card,
                        \),
                      \)
                      \.toList\(\),
                \);
              \}

              return Row\(
                crossAxisAlignment: CrossAxisAlignment\.start,
                children: cards
                    \.map\(
                      \(card\) => Expanded\(
                        child: Padding\(
                          padding: const EdgeInsets\.only\(right: 16\),
                          child: card,
                        \),
                      \),
                    \)
                    \.toList\(\),
              \);
            \},
          \),""",
    text,
    re.S,
)

new = """          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;

              final columns = maxWidth >= 1500
                  ? 5
                  : maxWidth >= 1100
                      ? 3
                      : maxWidth >= 720
                          ? 2
                          : 1;

              const spacing = 16.0;
              final cardWidth =
                  (maxWidth - (spacing * (columns - 1))) / columns;

              final cards = _plans(context)
                  .map(
                    (planData) => SizedBox(
                      width: cardWidth,
                      child: _PlanCard(
                        data: planData,
                        isCurrent: current == planData.plan,
                        onSelect: () {
                          if (planData.plan == CampusPlan.free) {
                            return;
                          }

                          _startCheckout(context, planData.plan);
                        },
                      ),
                    ),
                  )
                  .toList();

              return Wrap(
                spacing: spacing,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.start,
                children: cards,
              );
            },
          ),"""

if old:
    text = text[:old.start()] + new + text[old.end():]
else:
    start = text.find("          LayoutBuilder(")
    if start == -1:
        raise SystemExit("No se encontró LayoutBuilder en plans_screen.dart")

    end = text.find("          const SizedBox(height:", start)
    if end == -1:
        raise SystemExit("No se encontró el cierre esperado después del LayoutBuilder")

    text = text[:start] + new + "\n" + text[end:]

# Restaurar nombres comerciales completos.
text = text.replace("name: 'Access Plan',", "name: 'Accessibility',")
text = text.replace("name: 'Ultra',", "name: 'Ultra Premium',")

file.write_text(text)
PY

cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

cd "$FLUTTER"
flutter analyze || true

cd "$ROOT"
grep -R "final columns = maxWidth\|WrapAlignment.center\|Accessibility\|Ultra Premium" \
mobile/campusai_mobile/lib/screens/plans_screen.dart -n

git status --short
