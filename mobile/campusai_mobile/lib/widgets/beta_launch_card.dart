import 'package:flutter/material.dart';

import '../services/launch/launch_models.dart';
import '../theme/app_theme.dart';
import 'section_card.dart';

class BetaLaunchCard extends StatelessWidget {
  final LaunchReadinessReport report;
  final bool isLoading;
  final VoidCallback onFeedback;
  final VoidCallback onOnboarding;

  const BetaLaunchCard({
    super.key,
    required this.report,
    required this.isLoading,
    required this.onFeedback,
    required this.onOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    final hasReport = report.generatedAt.millisecondsSinceEpoch > 0;
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rocket_launch_outlined, color: AppTheme.accent),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Beta y lanzamiento',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const LinearProgressIndicator()
          else if (!hasReport)
            const Text(
              'La evaluación de lanzamiento estará disponible al actualizar.',
              style: TextStyle(color: AppTheme.textMuted),
            )
          else ...[
            Text(
              report.readyForClosedBeta
                  ? 'StudyBook AI está preparado para beta cerrada.'
                  : 'Aún quedan verificaciones antes de abrir la beta.',
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: report.score / 100),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text('Readiness ${report.score}%')),
                Chip(label: Text('${report.feedbackCount} feedback')),
                Chip(
                  label: Text(
                    'Onboarding ${report.onboardingProgress}%',
                  ),
                ),
              ],
            ),
            if (report.nextSteps.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Próximo paso: ${report.nextSteps.first}',
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ],
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onFeedback,
                icon: const Icon(Icons.feedback_outlined),
                label: const Text('Enviar feedback'),
              ),
              OutlinedButton.icon(
                onPressed: onOnboarding,
                icon: const Icon(Icons.explore_outlined),
                label: const Text('Guía inicial'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
