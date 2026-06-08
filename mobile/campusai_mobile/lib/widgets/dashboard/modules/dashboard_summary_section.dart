import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../services/export_service.dart';
import '../../../services/plan_guard_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/upgrade_dialog.dart';
import '../../section_card.dart';

class DashboardSummarySection extends StatelessWidget {
  final String summary;
  final VoidCallback onListenSummary;
  final VoidCallback onVoiceChat;
  final bool isGeneratingAudio;

  const DashboardSummarySection({
    super.key,
    required this.summary,
    required this.onListenSummary,
    required this.onVoiceChat,
    required this.isGeneratingAudio,
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

  bool get canUseVoiceFeatures {
    return const PlanGuardService().canUseVoiceOnboarding;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (summary.isEmpty) return const SizedBox.shrink();

    void requireVoiceOrRun({
      required String featureName,
      required VoidCallback action,
    }) {
      if (!canUseVoiceFeatures) {
        showUpgradeRequired(
          context,
          featureName: featureName,
        );
        return;
      }

      action();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _DashboardSectionTitle(
                title: l10n.aiSummary,
                subtitle: l10n.summarySubtitle,
              ),
            ),
            IconButton(
              tooltip: l10n.exportSummaryToWord,
              onPressed: () {
                if (!const PlanGuardService().canExportDocx) {
                  showUpgradeRequired(
                    context,
                    featureName: l10n.exportSummaryToWord,
                  );
                  return;
                }

                ExportService.exportTextToDocx(
                  title: l10n.aiSummary,
                  content: _cleanMarkdown(summary),
                );
              },
              icon: const Icon(
                Icons.description_rounded,
                color: AppTheme.accent,
              ),
            ),
            IconButton(
              tooltip: l10n.exportSummaryToPowerPoint,
              onPressed: () {
                if (!const PlanGuardService().canExportPptx) {
                  showUpgradeRequired(
                    context,
                    featureName: l10n.exportSummaryToPowerPoint,
                  );
                  return;
                }

                ExportService.exportTextToPptx(
                  title: l10n.aiSummary,
                  content: _cleanMarkdown(summary),
                );
              },
              icon: const Icon(
                Icons.slideshow_rounded,
                color: AppTheme.accent,
              ),
            ),
            IconButton(
              tooltip: l10n.exportSummaryToPdf,
              onPressed: () {
                if (!const PlanGuardService().canExportPdf) {
                  showUpgradeRequired(
                    context,
                    featureName: l10n.exportSummaryToPdf,
                  );
                  return;
                }

                ExportService.exportTextToPdf(
                  title: l10n.aiSummary,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _cleanMarkdown(summary),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: isGeneratingAudio
                        ? null
                        : () {
                            requireVoiceOrRun(
                              featureName: l10n.generatedAudio,
                              action: onListenSummary,
                            );
                          },
                    icon: isGeneratingAudio
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                            ),
                          )
                        : Icon(
                            canUseVoiceFeatures
                                ? Icons.volume_up_rounded
                                : Icons.workspace_premium_rounded,
                          ),
                    label: Text(
                      isGeneratingAudio
                          ? l10n.generating
                          : canUseVoiceFeatures
                              ? l10n.playAudio
                              : '🔊 ${l10n.playAudio}',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      requireVoiceOrRun(
                        featureName: l10n.voiceMode,
                        action: onVoiceChat,
                      );
                    },
                    icon: Icon(
                      canUseVoiceFeatures
                          ? Icons.mic_rounded
                          : Icons.lock_rounded,
                    ),
                    label: Text(
                      canUseVoiceFeatures
                          ? l10n.voiceMode
                          : '🎙️ ${l10n.voiceMode}',
                    ),
                  ),
                ],
              ),
            ],
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
