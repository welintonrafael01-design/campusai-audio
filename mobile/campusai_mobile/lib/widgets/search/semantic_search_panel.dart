import 'package:flutter/material.dart';

import '../../models/semantic_search_model.dart';
import '../../services/semantic_search_service.dart';
import '../../theme/app_theme.dart';
import '../section_card.dart';

class SemanticSearchPanel extends StatefulWidget {
  final void Function(String documentId)
      onOpenDocument;

  const SemanticSearchPanel({
    super.key,
    required this.onOpenDocument,
  });

  @override
  State<SemanticSearchPanel> createState() =>
      _SemanticSearchPanelState();
}

class _SemanticSearchPanelState
    extends State<SemanticSearchPanel> {
  final controller =
      TextEditingController();

  bool isLoading = false;

  List<SemanticSearchModel> results = [];

  Future<void> performSearch() async {
    final query =
        controller.text.trim();

    if (query.isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      final searchResults =
          await SemanticSearchService.search(
        query,
      );

      if (!mounted) return;

      setState(() {
        results = searchResults;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        results = [];
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Búsqueda Inteligente',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onSubmitted: (_) =>
                    performSearch(),
                decoration:
                    const InputDecoration(
                  hintText:
                      'Buscar en todos los documentos...',
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : performSearch,
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Buscar',
                    ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ...results.map(
          (result) => Padding(
            padding:
                const EdgeInsets.only(
              bottom: 12,
            ),
            child: SectionCard(
              onTap: () => widget
                  .onOpenDocument(
                result.documentId,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color:
                            AppTheme.accent,
                        size: 18,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Expanded(
                        child: Text(
                          result.documentId,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            color: AppTheme
                                .textPrimary,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    result.preview,
                    maxLines: 5,
                    overflow:
                        TextOverflow
                            .ellipsis,
                    style:
                        const TextStyle(
                      color: AppTheme
                          .textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration:
                            BoxDecoration(
                          color: AppTheme
                              .accent
                              .withValues(alpha: 
                            0.12,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            999,
                          ),
                        ),
                        child: Text(
                          'Chunk ${result.chunkIndex}',
                          style:
                              const TextStyle(
                            color: AppTheme
                                .accent,
                            fontSize: 12,
                            fontWeight:
                                FontWeight
                                    .w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Score ${(1 - result.distance).toStringAsFixed(2)}',
                        style:
                            const TextStyle(
                          color: AppTheme
                              .textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
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
