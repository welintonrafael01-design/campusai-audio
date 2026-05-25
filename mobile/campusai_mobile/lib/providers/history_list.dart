import 'package:flutter/material.dart';

import '../../models/document_history.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_card.dart';

class HistoryList extends StatelessWidget {
  final List<DocumentHistory> history;
  final VoidCallback clearHistory;
  final void Function(DocumentHistory) loadDocument;
  final void Function(int) deleteDocument;

  const HistoryList({
    super.key,
    required this.history,
    required this.clearHistory,
    required this.loadDocument,
    required this.deleteDocument,
  });

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.history_rounded,
              color: AppTheme.textMuted,
            ),
            SizedBox(height: 12),
            Text(
              'Sin historial todavía',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Cuando subas documentos aparecerán aquí.',
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
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historial reciente',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Toca un documento para activarlo nuevamente.',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: clearHistory,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Limpiar'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...history.asMap().entries.map(
              (entry) => _HistoryItem(
                index: entry.key,
                item: entry.value,
                loadDocument: loadDocument,
                deleteDocument: deleteDocument,
              ),
            ),
      ],
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final int index;
  final DocumentHistory item;
  final void Function(DocumentHistory) loadDocument;
  final void Function(int) deleteDocument;

  const _HistoryItem({
    required this.index,
    required this.item,
    required this.loadDocument,
    required this.deleteDocument,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                  const SizedBox(height: 6),
                  Text(
                    item.cleanSummary,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
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
              onPressed: () => deleteDocument(index),
              icon: const Icon(
                Icons.close_rounded,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}