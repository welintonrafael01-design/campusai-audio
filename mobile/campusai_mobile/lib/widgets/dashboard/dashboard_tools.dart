import 'package:flutter/material.dart';

import '../../layout/responsive_layout.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../section_card.dart';

class DashboardTools extends StatelessWidget {
  final bool isLoading;
  final bool hasActiveDocument;

  final VoidCallback uploadPdf;
  final VoidCallback openChat;
  final VoidCallback openExam;
  final VoidCallback openFlashcards;
  final VoidCallback openAudiobook;

  const DashboardTools({
    super.key,
    required this.isLoading,
    required this.hasActiveDocument,
    required this.uploadPdf,
    required this.openChat,
    required this.openExam,
    required this.openFlashcards,
    required this.openAudiobook,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isMobile = ResponsiveLayout.isMobile(context);

    int crossAxisCount = isMobile ? 2 : 1;

    if (ResponsiveLayout.isTablet(context)) {
      crossAxisCount = 2;
    }

    if (ResponsiveLayout.isDesktop(context)) {
      crossAxisCount = 5;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.aiTools,
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.aiToolsSubtitle,
          style: const TextStyle(
            color: AppTheme.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: ResponsiveLayout.isDesktop(context)
              ? 0.74
              : isMobile
                  ? 1.05
                  : 0.90,
          children: [
            _ToolCard(
              title: l10n.uploadPdf,
              subtitle: l10n.uploadPdfDescription,
              icon: Icons.upload_file_rounded,
              color: AppTheme.primary,
              onTap: isLoading ? null : uploadPdf,
            ),
            _ToolCard(
              title: l10n.aiChat,
              subtitle: l10n.aiChatDescription,
              icon: Icons.chat_bubble_rounded,
              color: AppTheme.accent,
              enabled: hasActiveDocument,
              onTap: hasActiveDocument ? openChat : null,
            ),
            _ToolCard(
              title: 'Audiolibro',
              subtitle: 'Escucha el resumen del documento activo.',
              icon: Icons.headphones_rounded,
              color: AppTheme.success,
              enabled: hasActiveDocument,
              onTap: hasActiveDocument ? openAudiobook : null,
            ),
            _ToolCard(
              title: l10n.aiExam,
              subtitle: l10n.aiExamDescription,
              icon: Icons.quiz_rounded,
              color: AppTheme.secondary,
              enabled: hasActiveDocument,
              onTap: hasActiveDocument ? openExam : null,
            ),
            _ToolCard(
              title: l10n.flashcardsTitle,
              subtitle: l10n.flashcardsDescription,
              icon: Icons.style_rounded,
              color: AppTheme.success,
              enabled: hasActiveDocument,
              onTap: hasActiveDocument ? openFlashcards : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  const _ToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: SectionCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                color: color,
                size: ResponsiveLayout.isMobile(context) ? 22 : 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: ResponsiveLayout.isMobile(context) ? 15 : 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              maxLines: ResponsiveLayout.isMobile(context) ? 3 : 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
