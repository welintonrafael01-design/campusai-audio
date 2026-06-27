import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'section_card.dart';

class FeatureHighlightCard extends StatelessWidget {
  final String title;
  final String description;
  final String actionLabel;
  final IconData icon;
  final VoidCallback? onAction;

  const FeatureHighlightCard({
    super.key,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.icon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accent, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
                if (onAction != null) ...[
                  const SizedBox(height: 12),
                  FilledButton(onPressed: onAction, child: Text(actionLabel)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
