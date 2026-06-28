import 'package:flutter/material.dart';

import '../services/ftue/ftue_models.dart';
import '../theme/app_theme.dart';
import 'studybook/premium_section_card.dart';
import 'studybook/studybook_buttons.dart';

class TimeToValueCard extends StatelessWidget {
  final FtueStep nextStep;
  final int completionPercentage;
  final VoidCallback onContinue;
  final VoidCallback onDismiss;

  const TimeToValueCard({
    super.key,
    required this.nextStep,
    required this.completionPercentage,
    required this.onContinue,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumSectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.flag_rounded, color: AppTheme.success, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu primer logro',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Ya comenzaste. El siguiente paso es: ${nextStep.title.toLowerCase()}.',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$completionPercentage% de la ruta inicial',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                StudyBookPrimaryButton(
                  label: nextStep.actionLabel,
                  onPressed: onContinue,
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
    );
  }
}
