import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class DashboardHero extends StatelessWidget {
  final int documentCount;
  final bool hasActiveDocument;

  const DashboardHero({
    super.key,
    required this.documentCount,
    required this.hasActiveDocument,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppTheme.mainGradient,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.school_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Estudia 10 veces más rápido con IA',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.08,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Mi Cuenta',
                onPressed: () {
                  context.pushNamed('settings');
                },
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                ),
                icon: const Icon(
                  Icons.account_circle_rounded,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Convierte tus PDFs en resúmenes, audiolibros, flashcards, exámenes y conversaciones inteligentes.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _HeroPill(
                icon: Icons.upload_file_rounded,
                text: 'Sube un PDF',
              ),
              _HeroPill(
                icon: Icons.headphones_rounded,
                text: 'Escúchalo',
              ),
              _HeroPill(
                icon: Icons.quiz_rounded,
                text: 'Practica',
              ),
              _HeroPill(
                icon: Icons.chat_bubble_rounded,
                text: 'Pregunta a la IA',
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: l10n.docsShort,
                  value: documentCount.toString(),
                  icon: Icons.folder_copy_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMetric(
                  label: 'RAG',
                  value: hasActiveDocument ? l10n.ragActive : l10n.ragReady,
                  icon: Icons.hub_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.17),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 17,
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeroMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $value',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
