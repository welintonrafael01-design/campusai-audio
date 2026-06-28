import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'premium_section_card.dart';
import 'studybook_buttons.dart';

class BookyCard extends StatelessWidget {
  final String title;
  final String message;
  final String primaryLabel;
  final String secondaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onSecondary;

  const BookyCard({
    super.key,
    this.title = 'Hola, soy Booky.',
    required this.message,
    this.primaryLabel = '',
    this.secondaryLabel = '',
    this.onPrimary,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: PremiumSectionCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _BookyAvatar(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TU COMPAÑERO DE APRENDIZAJE',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
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
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      height: 1.4,
                    ),
                  ),
                  if (onPrimary != null || onSecondary != null) ...[
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        if (onPrimary != null)
                          StudyBookPrimaryButton(
                            label: primaryLabel,
                            icon: Icons.arrow_forward_rounded,
                            onPressed: onPrimary,
                          ),
                        if (onSecondary != null)
                          StudyBookSecondaryButton(
                            label: secondaryLabel,
                            icon: Icons.chat_bubble_outline_rounded,
                            onPressed: onSecondary,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookyAvatar extends StatelessWidget {
  const _BookyAvatar();

  @override
  Widget build(BuildContext context) {
    // TODO(booky-asset): replace this icon with the official Booky artwork.
    return ExcludeSemantics(
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: .16),
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.accent.withValues(alpha: .35)),
        ),
        child: const Icon(
          Icons.auto_stories_rounded,
          color: AppTheme.accent,
          size: 30,
        ),
      ),
    );
  }
}
