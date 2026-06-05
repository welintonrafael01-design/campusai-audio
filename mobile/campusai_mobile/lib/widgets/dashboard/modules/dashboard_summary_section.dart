import 'package:flutter/material.dart';

import '../../../services/export_service.dart';
import '../../../services/plan_guard_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/upgrade_dialog.dart';
import '../../section_card.dart';

class DashboardSummarySection extends StatelessWidget {
  final String summary;

  const DashboardSummarySection({
    super.key,
    required this.summary,
  });

  String _cleanMarkdown(String text) {
    return text
        .replaceAll('###', '')
        .replaceAll('##', '')
        .replaceAll('#', '')
        .replaceAll('**', '')
        .replaceAll('*', '')
        .replaceAll('__', '')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    if (summary.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: _DashboardSectionTitle(
                title: 'Resumen IA',
                subtitle: 'Síntesis clara del documento cargado.',
              ),
            ),
            IconButton(
              tooltip: 'Exportar resumen a Word',
              onPressed: () {
                if (!const PlanGuardService().canExportDocx) {
                  showUpgradeRequired(
                    context,
                    featureName: 'Exportar resumen a Word',
                  );
                  return;
                }

                ExportService.exportTextToDocx(
                  title: 'Resumen IA',
                  content: _cleanMarkdown(summary),
                );
              },
              icon: const Icon(
                Icons.description_rounded,
                color: AppTheme.accent,
              ),
            ),
            IconButton(
              tooltip: 'Exportar resumen a PowerPoint',
              onPressed: () {
                if (!const PlanGuardService().canExportPptx) {
                  showUpgradeRequired(
                    context,
                    featureName: 'Exportar resumen a PowerPoint',
                  );
                  return;
                }

                ExportService.exportTextToPptx(
                  title: 'Resumen IA',
                  content: _cleanMarkdown(summary),
                );
              },
              icon: const Icon(
                Icons.slideshow_rounded,
                color: AppTheme.accent,
              ),
            ),
            IconButton(
              tooltip: 'Exportar resumen a PDF',
              onPressed: () {
                if (!const PlanGuardService().canExportPdf) {
                  showUpgradeRequired(
                    context,
                    featureName: 'Exportar resumen a PDF',
                  );
                  return;
                }

                ExportService.exportTextToPdf(
                  title: 'Resumen IA',
                  content: _cleanMarkdown(summary),
                );
              },
              icon: const Icon(
                Icons.picture_as_pdf_rounded,
                color: AppTheme.accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SectionCard(
          child: Text(
            _cleanMarkdown(summary),
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardSectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _DashboardSectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.textMuted,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}
