import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'studybook/studybook_buttons.dart';

class AccessibleEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  const AccessibleEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel = '',
    this.onAction,
    this.icon = Icons.accessibility_new_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title. $message',
      child: Column(
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
          const SizedBox(height: 5),
          Text(
            message,
            style: const TextStyle(color: AppTheme.textMuted, height: 1.4),
          ),
          if (onAction != null && actionLabel.isNotEmpty) ...[
            const SizedBox(height: 12),
            StudyBookSecondaryButton(
              label: actionLabel,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
