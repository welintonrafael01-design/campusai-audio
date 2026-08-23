import 'package:flutter/material.dart';

import '../../models/chat_message_model.dart';
import '../../theme/app_theme.dart';

class SourceReferencesSection extends StatelessWidget {
  final List<ChatCitationModel> sources;
  final ValueChanged<ChatCitationModel>? onSourceTap;

  const SourceReferencesSection({
    super.key,
    required this.sources,
    this.onSourceTap,
  });

  @override
  Widget build(BuildContext context) {
    if (sources.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const Key('source-references-expansion'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          leading: const Icon(
            Icons.library_books_rounded,
            color: AppTheme.accent,
            size: 20,
          ),
          title: Text(
            'Fuentes (${sources.length})',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          children: List.generate(sources.length, (index) {
            final source = sources[index];
            final excerpt =
                source.highlight?.trim() ?? source.preview?.trim() ?? '';
            final page = source.pageNumber;
            final title = source.documentTitle?.trim() ?? '';
            final sourceLabel = title.isEmpty ? 'Fuente ${index + 1}' : title;
            final pageLabel = page != null && page > 0 ? 'Página $page' : '';

            return Semantics(
              button: true,
              label: '$sourceLabel. $pageLabel. Abrir fragmento citado.',
              child: InkWell(
                key: Key('source-reference-$index'),
                onTap: onSourceTap == null ? null : () => onSourceTap!(source),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.article_outlined,
                        color: AppTheme.accent,
                        size: 19,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sourceLabel,
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (pageLabel.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Text(
                                pageLabel,
                                style: const TextStyle(
                                  color: AppTheme.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                            const SizedBox(height: 5),
                            Text(
                              excerpt.isEmpty
                                  ? 'Abrir fragmento citado'
                                  : excerpt,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onSourceTap != null) ...[
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.textMuted,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
