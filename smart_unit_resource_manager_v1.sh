#!/usr/bin/env bash
set -e

ROOT="$HOME/Desktop/campusai-audio"
FLUTTER="$ROOT/mobile/campusai_mobile"
BACKEND="$ROOT/backend"

python3 <<'PY'
from pathlib import Path

path = Path("mobile/campusai_mobile/lib/screens/teaching_plan_screen.dart")
text = path.read_text()

old = """    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Semana ${week['week'] ?? ''}: ${week['topic'] ?? ''}',
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
"""

new = """    final generatedResources = <String>[
      if (objectives.isNotEmpty) 'Planificación',
    ];

    final progress = generatedResources.length / 5;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unidad ${week['week'] ?? ''}: ${week['topic'] ?? ''}',
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            '\${(progress * 100).round()}% completado · \${generatedResources.length} de 5 recursos creados',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress.clamp(0, 1)),
          const SizedBox(height: 12),
"""

if old not in text:
    raise SystemExit("No se encontró el inicio de _WeekCard esperado.")

text = text.replace(old, new)

old = """          const Text(
            'Recursos de la unidad',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
"""

new = """          const Text(
            'Gestor de recursos de la unidad',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Genera materiales conectados a esta unidad para mantener el curso organizado.',
            style: TextStyle(
              color: AppTheme.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatusChip(label: 'Planificación', done: objectives.isNotEmpty),
              const _StatusChip(label: 'Banco', done: false),
              const _StatusChip(label: 'Examen', done: false),
              const _StatusChip(label: 'Rúbrica', done: false),
              const _StatusChip(label: 'Guía', done: false),
            ],
          ),
          const SizedBox(height: 12),
"""

if old not in text:
    raise SystemExit("No se encontró el bloque de Recursos de la unidad.")

text = text.replace(old, new)

insert_before = """class _InlineList extends StatelessWidget {"""

status_chip = """class _StatusChip extends StatelessWidget {
  final String label;
  final bool done;

  const _StatusChip({
    required this.label,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
        size: 18,
      ),
      label: Text(done ? '$label listo' : '$label pendiente'),
    );
  }
}

"""

if "class _StatusChip extends StatelessWidget" not in text:
    text = text.replace(insert_before, status_chip + insert_before)

path.write_text(text)
PY

cd "$BACKEND"
python -m py_compile $(find app -name "*.py")

cd "$FLUTTER"
flutter analyze || true

cd "$ROOT"
grep -R "Gestor de recursos de la unidad\|_StatusChip\|Unidad .*completado" \
mobile/campusai_mobile/lib/screens/teaching_plan_screen.dart -n

git status --short
