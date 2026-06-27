import 'package:flutter/material.dart';

import '../services/autonomous_ai/autonomous_action_models.dart';
import '../theme/app_theme.dart';
import 'section_card.dart';

/// Presents the highest-priority RC3 action without generating new data.
class NextBestActionCard extends StatelessWidget {
  final AutonomousAction? action;
  final bool isProcessing;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final VoidCallback? onDismiss;

  const NextBestActionCard({
    super.key,
    required this.action,
    required this.isProcessing,
    required this.onPrimary,
    required this.onSecondary,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final current = action;
    if (current == null) {
      return SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Title(),
            const SizedBox(height: 12),
            const Text(
              'Completa una sesión para que CampusAI prepare tu siguiente paso.',
              style: TextStyle(color: AppTheme.textMuted, height: 1.4),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onSecondary,
              icon: const Icon(Icons.record_voice_over_rounded),
              label: const Text('Hablar con Tutor IA'),
            ),
          ],
        ),
      );
    }

    final priorityColor = switch (current.priority) {
      AutonomousActionPriority.critical => AppTheme.danger,
      AutonomousActionPriority.high => AppTheme.warning,
      AutonomousActionPriority.normal => AppTheme.accent,
      AutonomousActionPriority.low => AppTheme.textMuted,
    };
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: _Title()),
              if (onDismiss != null)
                IconButton(
                  tooltip: 'Descartar recomendación',
                  onPressed: isProcessing ? null : onDismiss,
                  icon: const Icon(Icons.close_rounded),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                current.title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Chip(
                visualDensity: VisualDensity.compact,
                label: Text(_priorityLabel(current.priority)),
                side: BorderSide(color: priorityColor.withValues(alpha: .35)),
                backgroundColor: priorityColor.withValues(alpha: .1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            current.reason,
            style: const TextStyle(color: AppTheme.textMuted, height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            isProcessing
                ? 'Preparando tu siguiente paso...'
                : 'Lista para comenzar',
            style: TextStyle(
              color: isProcessing ? AppTheme.warning : AppTheme.success,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: isProcessing ? null : onPrimary,
                icon: isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
                label: Text(current.actionLabel),
              ),
              OutlinedButton.icon(
                onPressed: isProcessing ? null : onSecondary,
                icon: const Icon(Icons.record_voice_over_rounded),
                label: const Text('Consultar al Tutor'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _priorityLabel(AutonomousActionPriority priority) {
    return switch (priority) {
      AutonomousActionPriority.critical => 'Prioridad crítica',
      AutonomousActionPriority.high => 'Prioridad alta',
      AutonomousActionPriority.normal => 'Recomendada',
      AutonomousActionPriority.low => 'Opcional',
    };
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.auto_awesome_rounded, color: AppTheme.accent),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Siguiente mejor acción',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}
