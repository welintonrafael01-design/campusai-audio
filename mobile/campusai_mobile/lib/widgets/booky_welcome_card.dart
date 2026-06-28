import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'studybook/premium_section_card.dart';

class BookyWelcomeAction {
  final String label;
  final String prompt;
  final String mode;
  final bool readAloud;

  const BookyWelcomeAction({
    required this.label,
    required this.prompt,
    this.mode = 'general',
    this.readAloud = false,
  });
}

class BookyWelcomeCard extends StatelessWidget {
  final List<BookyWelcomeAction> actions;
  final ValueChanged<BookyWelcomeAction> onAction;
  final bool isBusy;

  const BookyWelcomeCard({
    super.key,
    required this.actions,
    required this.onAction,
    this.isBusy = false,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_stories_rounded,
                  color: AppTheme.accent, size: 30),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hola, soy Booky.',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Puedo explicarte temas, hacerte preguntas o ayudarte a repasar. Elige una opción cuando quieras comenzar.',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final action in actions)
                OutlinedButton(
                  onPressed: isBusy ? null : () => onAction(action),
                  child: Text(action.label),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
