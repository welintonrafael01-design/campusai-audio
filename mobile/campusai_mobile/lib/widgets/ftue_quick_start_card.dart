import 'package:flutter/material.dart';

import '../services/ftue/ftue_models.dart';
import '../theme/app_theme.dart';
import 'ftue_step_card.dart';
import 'studybook/premium_section_card.dart';

class FtueQuickStartCard extends StatelessWidget {
  final FtueProgress progress;
  final List<FtueStep> steps;
  final ValueChanged<FtueStep> onOpenStep;
  final VoidCallback onDismiss;

  const FtueQuickStartCard({
    super.key,
    required this.progress,
    required this.steps,
    required this.onOpenStep,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = progress.completionPercentage(steps.length);
    return PremiumSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_stories_rounded, color: AppTheme.accent),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Comienza con Booky',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Sube cualquier contenido. Booky lo convierte en una experiencia de aprendizaje.',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Ocultar guía inicial',
                onPressed: onDismiss,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Empecemos por algo sencillo. Puedes lograr tu primer avance en menos de 2 minutos.',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Semantics(
            label: 'Progreso de inicio, $percentage por ciento',
            child: LinearProgressIndicator(value: percentage / 100),
          ),
          const SizedBox(height: 8),
          Text(
            '${progress.completedStepIds.length} de ${steps.length} pasos completados',
            style: const TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < steps.length; index++)
            FtueStepCard(
              step: steps[index],
              completed: progress.isStepComplete(steps[index].id),
              onOpen: () => onOpenStep(steps[index]),
              showDivider: index < steps.length - 1,
            ),
        ],
      ),
    );
  }
}
