import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/document_history.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_card.dart';

class HistoryList extends StatelessWidget {
  final List<DocumentHistory> history;
  final VoidCallback clearHistory;
  final Function(DocumentHistory) loadDocument;
  final Function(int) deleteDocument;

  const HistoryList({
    super.key,
    required this.history,
    required this.clearHistory,
    required this.loadDocument,
    required this.deleteDocument,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (history.isEmpty) {
      return SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.history_rounded,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noHistoryYet,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.historyEmptyDescription,
              style: TextStyle(
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.recentHistory,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.historyHint,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: clearHistory,
              icon: const Icon(
                Icons.delete_outline_rounded,
              ),
              label: Text(l10n.clear),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...history.asMap().entries.map(
          (entry) {
            final index = entry.key;
            final item = entry.value;

            return Padding(
              padding: const EdgeInsets.only(
                bottom: 12,
              ),
              child: SectionCard(
                onTap: () => loadDocument(item),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.article_rounded,
                      color: AppTheme.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.fileName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          Text(
                            item.cleanSummary,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          Text(
                            item.formattedDate,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => deleteDocument(
                        index,
                      ),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
