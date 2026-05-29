import 'package:flutter/material.dart';

import '../../models/chat_message_model.dart';
import '../../theme/app_theme.dart';

class CitationChips extends StatelessWidget {
  final String text;

  final List<ChatCitationModel> citations;

  final void Function(String citation)? onCitationTap;

  const CitationChips({
    super.key,
    required this.text,
    required this.citations,
    this.onCitationTap,
  });

  @override
  Widget build(BuildContext context) {
    if (citations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.menu_book_rounded,
          size: 15,
          color: AppTheme.accent,
        ),
        const SizedBox(width: 8),
        Text(
          '${citations.length} fuente${citations.length == 1 ? '' : 's'}',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 10),
        ...citations.map((citation) {
          final label =
              'Fuente ${citation.chunkIndex}';

          final rawCitation =
              '[FUENTE document=${citation.documentId} chunk=${citation.chunkIndex}]';

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              onTap: () =>
                  onCitationTap?.call(rawCitation),
              borderRadius:
                  BorderRadius.circular(999),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accent
                      .withValues(alpha: 0.14),
                  borderRadius:
                      BorderRadius.circular(999),
                  border: Border.all(
                    color: AppTheme.accent
                        .withValues(alpha: 0.28),
                  ),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
