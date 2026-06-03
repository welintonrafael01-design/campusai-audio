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

  String relevanceLabel(ChatCitationModel citation) {
    final distance = citation.distance;

    if (distance == null) return 'Fuente';

    if (distance <= 0.35) {
      return '🟢 Alta confianza';
    }

    if (distance <= 0.60) {
      return '🟡 Confianza media';
    }

    return '🔴 Confianza baja';
  }

  @override
  Widget build(BuildContext context) {
    if (citations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: citations.map((citation) {
        final preview =
            citation.highlight?.trim() ??
            citation.preview?.trim() ??
            '';

        final rawCitation =
            '[FUENTE document=${citation.documentId} chunk=${citation.chunkIndex}]';

        return InkWell(
          onTap: () => onCitationTap?.call(rawCitation),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 360,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppTheme.accent.withValues(alpha: 0.22),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.article_rounded,
                    color: AppTheme.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${relevanceLabel(citation)} · Chunk ${citation.chunkIndex}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        preview.isEmpty
                            ? 'Abrir fragmento citado'
                            : preview,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
