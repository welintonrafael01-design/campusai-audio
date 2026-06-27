import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LaunchEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;
  final IconData icon;
  final VoidCallback? onAction;

  const LaunchEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel = '',
    this.icon = Icons.rocket_launch_outlined,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.accent, size: 30),
        const SizedBox(height: 10),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          message,
          style: const TextStyle(color: AppTheme.textMuted, height: 1.4),
        ),
        if (onAction != null && actionLabel.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ],
    );
  }
}
