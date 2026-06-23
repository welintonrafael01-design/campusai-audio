#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
FLUTTER="$ROOT/mobile/campusai_mobile"
BACKEND="$ROOT/backend"

echo "===== UPDATE PLANS SCREEN V2 ====="

python3 <<'PY'
from pathlib import Path

root = Path.home() / "Desktop/campusai-audio"
app_plans = root / "mobile/campusai_mobile/lib/config/app_plans.dart"
plans_screen = root / "mobile/campusai_mobile/lib/screens/plans_screen.dart"

text = app_plans.read_text()
text = text.replace("CampusPlan.student: r'US$6.99',", "CampusPlan.student: r'US$4.99',")
text = text.replace("CampusPlan.teacher: r'US$13.99',", "CampusPlan.teacher: r'US$9.99',")
app_plans.write_text(text)

text = plans_screen.read_text()
start = text.index("  List<_PlanUiData> _plans(BuildContext context) {")
end = text.index("\n  @override\n  Widget build", start)

new_block = r'''  List<_PlanUiData> _plans(BuildContext context) {
    return [
      const _PlanUiData(
        plan: CampusPlan.free,
        name: 'Free',
        audience: 'Para comenzar',
        price: 'US\$0',
        period: '/mes',
        badge: '',
        icon: Icons.school_outlined,
        isHighlighted: false,
        benefits: [
          '3 PDFs diarios',
          '30 chats diarios',
          'Chat IA básico',
          '10 flashcards por PDF',
          '10 preguntas de examen por PDF',
          'Exportación PDF básica',
        ],
        lockedBenefits: [
          'Exportar DOCX y PPTX',
          'Modo voz completo',
          'Herramientas docentes',
          'Certificados e insignias',
        ],
      ),
      const _PlanUiData(
        plan: CampusPlan.student,
        name: 'Student',
        audience: 'Para estudiantes intensivos',
        price: 'US\$4.99',
        period: '/mes',
        badge: 'ESTUDIANTES',
        icon: Icons.workspace_premium_rounded,
        isHighlighted: true,
        benefits: [
          '25 PDFs diarios',
          '300 chats diarios',
          '200 flashcards por PDF',
          '100 preguntas de examen por PDF',
          '60 minutos de audio al mes',
          'Audiolibros y resumen en audio',
          'Modo voz y lectura asistida',
          'Exportar PDF y DOCX',
          'Banco de preguntas para estudiar',
        ],
        lockedBenefits: [
          'Herramientas docentes completas',
          'Gradebook y asistencia',
          'Certificados e insignias académicas',
        ],
      ),
      const _PlanUiData(
        plan: CampusPlan.accessibility,
        name: 'Accessibility',
        audience: 'Para accesibilidad e inclusión',
        price: 'US\$3.99',
        period: '/mes',
        badge: 'INCLUSIÓN',
        icon: Icons.accessibility_new_rounded,
        isHighlighted: false,
        benefits: [
          '15 PDFs diarios',
          '200 chats diarios',
          '120 minutos de audio al mes',
          'Lectura asistida y voz',
          'Resúmenes accesibles',
          '100 flashcards por PDF',
          '80 preguntas de examen por PDF',
          'Exportar PDF y DOCX',
          'Certificados e insignias académicas',
        ],
        lockedBenefits: [
          'Gradebook docente',
          'Planificación docente IA',
          'Analíticas avanzadas de aula',
        ],
      ),
      const _PlanUiData(
        plan: CampusPlan.teacher,
        name: 'Teacher',
        audience: 'Para docentes y aulas',
        price: 'US\$9.99',
        period: '/mes',
        badge: 'DOCENTES',
        icon: Icons.groups_rounded,
        isHighlighted: false,
        benefits: [
          '100 PDFs diarios',
          '1,000 chats diarios',
          '300 minutos de audio al mes',
          'Herramientas docentes completas',
          'Cursos, estudiantes y asistencia',
          'Gradebook y ponderaciones',
          'Rúbricas IA',
          'Banco de preguntas IA',
          'Planificación docente IA',
          'Certificados, insignias y reconocimientos',
          'Transcript premium y dashboard académico',
          'Exportar PDF, DOCX y PPTX',
        ],
        lockedBenefits: [
          'Límites ilimitados',
          'Procesamiento prioritario',
          'Funciones beta premium',
        ],
      ),
      const _PlanUiData(
        plan: CampusPlan.ultra,
        name: 'Ultra Premium',
        audience: 'Para máximo rendimiento',
        price: 'US\$24.99',
        period: '/mes',
        badge: 'TODO INCLUIDO',
        icon: Icons.auto_awesome_rounded,
        isHighlighted: false,
        benefits: [
          'PDFs, chats, flashcards y preguntas sin límites prácticos',
          'Audio mensual ampliado',
          'Todos los módulos Student',
          'Todos los módulos Accessibility',
          'Todos los módulos Teacher',
          'Analítica avanzada',
          'Reportes y exportaciones completas',
          'Certificados premium',
          'Insignias académicas premium',
          'Reconocimiento automático',
          'Funciones beta y capacidades premium',
          'Ideal para usuarios intensivos e instituciones pequeñas',
        ],
        lockedBenefits: [],
      ),
    ];
  }'''

text = text[:start] + new_block + text[end:]
plans_screen.write_text(text)
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
echo "===== PLAN CHECK ====="
grep -R "US\\$4.99\\|US\\$3.99\\|US\\$9.99\\|US\\$24.99\\|Ultra Premium\\|Accessibility" lib/config/app_plans.dart lib/screens/plans_screen.dart -n

echo ""
echo "===== GIT STATUS ====="
cd "$ROOT"
git status --short

echo ""
echo "===== DONE ====="
