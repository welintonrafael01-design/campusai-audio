import 'package:flutter/material.dart';

import '../services/ftue/ftue_models.dart';
import '../theme/app_theme.dart';

class FtueStepCard extends StatelessWidget {
  final FtueStep step;
  final bool completed;
  final VoidCallback onOpen;
  final bool showDivider;

  const FtueStepCard({
    super.key,
    required this.step,
    required this.completed,
    required this.onOpen,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          '${step.title}. ${completed ? 'Completado' : 'Pendiente'}. ${step.description}',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  completed
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: completed ? AppTheme.success : AppTheme.textMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.description,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        completed
                            ? 'Completado'
                            : 'Aproximadamente ${step.estimatedMinutes} min',
                        style: TextStyle(
                          color: completed
                              ? AppTheme.success
                              : AppTheme.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!completed) ...[
                  const SizedBox(width: 10),
                  TextButton(
                    onPressed: onOpen,
                    child: Text(step.actionLabel),
                  ),
                ],
              ],
            ),
          ),
          if (showDivider) const Divider(height: 1),
        ],
      ),
    );
  }
}
