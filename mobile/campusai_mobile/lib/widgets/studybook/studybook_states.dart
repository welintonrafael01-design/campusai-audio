import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'premium_section_card.dart';
import 'studybook_buttons.dart';

class StudyBookEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback? onAction;
  final IconData icon;

  const StudyBookEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel = '',
    this.onAction,
    this.icon = Icons.auto_stories_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppTheme.accent,
            size: 30,
          ),
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

class StudyBookErrorState extends StatelessWidget {
  final String title;
  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;

  const StudyBookErrorState({
    super.key,
    this.title = 'No pudimos cargar esta sección',
    required this.message,
    this.retryLabel = 'Reintentar',
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return StudyBookEmptyState(
      title: title,
      message: message,
      icon: Icons.error_outline_rounded,
      actionLabel: retryLabel,
      onAction: onRetry,
    );
  }
}

class StudyBookLoadingState extends StatelessWidget {
  final String message;

  const StudyBookLoadingState({
    super.key,
    this.message = 'Booky está preparando tu experiencia...',
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      label: message,
      child: ExcludeSemantics(
        child: Center(
          child: PremiumSectionCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 14),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
