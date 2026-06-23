#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
FLUTTER="$ROOT/mobile/campusai_mobile"
BACKEND="$ROOT/backend"

python3 <<'PY'
from pathlib import Path

root = Path.home() / "Desktop/campusai-audio"
flutter = root / "mobile/campusai_mobile"

router = flutter / "lib/router/app_router.dart"
text = router.read_text()

import_line = "import '../screens/admin/financial_dashboard_screen.dart';\n"
if import_line not in text:
    text = text.replace(
        "import '../screens/plans_screen.dart';\n",
        "import '../screens/plans_screen.dart';\n" + import_line,
    )

route_block = """    GoRoute(
      path: '/admin/financial-dashboard',
      name: 'financial-dashboard',
      builder: (context, state) => const FinancialDashboardScreen(),
    ),
"""

if "path: '/admin/financial-dashboard'" not in text:
    marker = "    GoRoute(\n      path: '/settings',"
    text = text.replace(marker, route_block + marker)

router.write_text(text)

sidebar = flutter / "lib/widgets/sidebar.dart"
text = sidebar.read_text()

admin_item = """          _SidebarItem(
            icon: Icons.query_stats_rounded,
            label: 'Finanzas',
            selected: currentRoute == '/admin/financial-dashboard',
            onTap: () {
              context.go('/admin/financial-dashboard');
            },
          ),
"""

if "/admin/financial-dashboard" not in text:
    marker = """          _SidebarItem(
            icon: Icons.settings_rounded,"""
    text = text.replace(marker, admin_item + marker)

sidebar.write_text(text)
PY

cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

cd "$FLUTTER"
flutter analyze

cd "$ROOT"
grep -R "financial-dashboard\|FinancialDashboardScreen\|Finanzas" mobile/campusai_mobile/lib/router mobile/campusai_mobile/lib/widgets -n
git status --short
