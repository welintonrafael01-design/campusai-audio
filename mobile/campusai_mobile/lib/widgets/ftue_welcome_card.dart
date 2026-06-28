import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'studybook/premium_section_card.dart';
import 'studybook/studybook_buttons.dart';

class FtueWelcomeCard extends StatelessWidget {
  final String title;
  final String message;
  final List<String> benefits;
  final String actionLabel;
  final VoidCallback onAction;
  final IconData icon;

  const FtueWelcomeCard({
    super.key,
    required this.title,
    required this.message,
    required this.benefits,
    required this.actionLabel,
    required this.onAction,
    this.icon = Icons.auto_stories_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title. $message. ${benefits.join(' ')}',
      child: PremiumSectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.accent, size: 30),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(color: AppTheme.textMuted, height: 1.4),
            ),
            const SizedBox(height: 12),
            for (final benefit in benefits)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppTheme.success,
                      size: 19,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            StudyBookPrimaryButton(
              label: actionLabel,
              icon: Icons.arrow_forward_rounded,
              onPressed: onAction,
            ),
          ],
        ),
      ),
    );
  }
}
