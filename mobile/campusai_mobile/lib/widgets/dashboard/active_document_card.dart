import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/section_card.dart';

class ActiveDocumentCard extends StatelessWidget {
  final bool hasActiveDocument;
  final String fileName;
  final VoidCallback openChat;

  const ActiveDocumentCard({
    super.key,
    required this.hasActiveDocument,
    required this.fileName,
    required this.openChat,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasActiveDocument) {
      return const SizedBox.shrink();
    }

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.mainGradient,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.description_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workspace activo',
                      style: TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Documento listo para estudiar',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              _StatusBadge(),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            fileName.isEmpty ? 'Documento PDF' : fileName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _MiniBadge(
                icon: Icons.hub_rounded,
                label: 'RAG activo',
              ),
              _MiniBadge(
                icon: Icons.auto_awesome_rounded,
                label: 'IA lista',
              ),
              _MiniBadge(
                icon: Icons.graphic_eq_rounded,
                label: 'Audio disponible',
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: openChat,
            icon: const Icon(Icons.chat_bubble_rounded),
            label: const Text('Abrir Chat IA'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppTheme.success.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.success.withValues(alpha: 0.35),
        ),
      ),
      child: const Text(
        'Activo',
        style: TextStyle(
          color: AppTheme.success,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: AppTheme.background.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppTheme.accent,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}