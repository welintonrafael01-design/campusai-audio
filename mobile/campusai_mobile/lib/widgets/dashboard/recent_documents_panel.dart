import 'package:flutter/material.dart';

import '../../models/recent_document_model.dart';
import '../../theme/app_theme.dart';
import '../section_card.dart';

class RecentDocumentsPanel extends StatelessWidget {
  final List<RecentDocumentModel> documents;
  final void Function(RecentDocumentModel document) onOpen;
  final void Function(RecentDocumentModel document) onDelete;

  const RecentDocumentsPanel({
    super.key,
    required this.documents,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documentos recientes',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        ...documents.map(
          (document) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SectionCard(
              onTap: () => onOpen(document),
              child: Row(
                children: [
                  const Icon(
                    Icons.description_rounded,
                    color: AppTheme.accent,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      document.fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => onDelete(document),
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
