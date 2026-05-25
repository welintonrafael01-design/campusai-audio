import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class EmptyChatState extends StatelessWidget {
  final bool shouldShow;

  const EmptyChatState({
    super.key,
    required this.shouldShow,
  });

  @override
  Widget build(BuildContext context) {
    if (!shouldShow) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(
        top: 40,
        bottom: 20,
      ),
      child: Column(
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 56,
            color: Colors.white.withValues(alpha: 0.16),
          ),
          const SizedBox(height: 16),
          const Text(
            'Comienza la conversación',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pregunta cualquier cosa sobre el documento.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMuted,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}