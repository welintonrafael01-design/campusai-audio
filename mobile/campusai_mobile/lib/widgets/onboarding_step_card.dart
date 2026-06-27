import 'package:flutter/material.dart';

import '../services/launch/launch_models.dart';
import '../theme/app_theme.dart';

class OnboardingStepCard extends StatelessWidget {
  final OnboardingStep step;
  final bool completed;
  final VoidCallback onOpen;

  const OnboardingStepCard({
    super.key,
    required this.step,
    required this.completed,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        completed ? Icons.check_circle_rounded : Icons.circle_outlined,
        color: completed ? AppTheme.success : AppTheme.accent,
      ),
      title: Text(
        step.title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        step.description,
        style: const TextStyle(color: AppTheme.textMuted),
      ),
      trailing: TextButton(
        onPressed: completed ? null : onOpen,
        child: Text(completed ? 'Listo' : 'Abrir'),
      ),
    );
  }
}
