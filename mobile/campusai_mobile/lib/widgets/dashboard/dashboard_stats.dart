import 'package:flutter/material.dart';

import '../../layout/responsive_layout.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../section_card.dart';

class DashboardStats extends StatelessWidget {
  final int documentCount;
  final bool hasActiveDocument;

  const DashboardStats({
    super.key,
    required this.documentCount,
    required this.hasActiveDocument,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    int crossAxisCount = 1;

    if (ResponsiveLayout.isTablet(context)) {
      crossAxisCount = 2;
    }

    if (ResponsiveLayout.isDesktop(context)) {
      crossAxisCount = 4;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: ResponsiveLayout.isDesktop(context) ? 1.8 : 1.5,
      children: [
        _StatCard(
          title: l10n.documents,
          value: '$documentCount',
          icon: Icons.folder_copy_rounded,
          color: AppTheme.primary,
        ),
        _StatCard(
          title: l10n.aiStatus,
          value: hasActiveDocument ? l10n.ragActive : l10n.noDocument,
          icon: Icons.auto_awesome_rounded,
          color: AppTheme.accent,
        ),
        _StatCard(
          title: l10n.flashcardsTitle,
          value: 'AI',
          icon: Icons.style_rounded,
          color: AppTheme.secondary,
        ),
        _StatCard(
          title: 'Audio',
          value: l10n.ready,
          icon: Icons.graphic_eq_rounded,
          color: AppTheme.success,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(
                alpha: 0.14,
              ),
              borderRadius: BorderRadius.circular(
                18,
              ),
            ),
            child: Icon(
              icon,
              color: color,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
