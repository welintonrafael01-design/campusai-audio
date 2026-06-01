import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/document_service.dart';
import '../../theme/app_theme.dart';

class SourceViewerSheet extends StatelessWidget {
  final String documentId;
  final int chunkIndex;
  final String content;
  final Map<String, dynamic> metadata;

  const SourceViewerSheet({
    super.key,
    required this.documentId,
    required this.chunkIndex,
    required this.content,
    this.metadata = const {},
  });

  String get shortDocumentId {
    if (documentId.length <= 12) return documentId;
    return '${documentId.substring(0, 8)}...${documentId.substring(documentId.length - 4)}';
  }

  int? get pageNumber {
    final value = metadata['page_number'];

    if (value is int) return value;

    return int.tryParse(value?.toString() ?? '');
  }

  Future<void> openPdf(BuildContext context) async {
    final url = DocumentService.getPdfUrl(
      documentId,
      pageNumber: pageNumber,
    );
    final uri = Uri.parse(url);

    final opened = await launchUrl(
      uri,
      webOnlyWindowName: '_blank',
    );

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el PDF.'),
        ),
      );
    }
  }

  Future<void> copySource(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(text: content),
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fuente copiada al portapapeles.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final metadataEntries = metadata.entries
        .where(
          (entry) =>
              entry.value != null &&
              entry.value.toString().trim().isNotEmpty,
        )
        .take(6)
        .toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.source_rounded,
                    color: AppTheme.accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Fuente citada',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copiar fuente',
                  onPressed: () => copySource(context),
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: AppTheme.textMuted,
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _InfoPill(
                  icon: Icons.description_outlined,
                  label: 'Documento',
                  value: shortDocumentId,
                ),
                if (metadata['page_number'] != null)
                  _InfoPill(
                    icon: Icons.menu_book_rounded,
                    label: 'Página',
                    value: metadata['page_number'].toString(),
                  ),
                _InfoPill(
                  icon: Icons.tag_rounded,
                  label: 'Chunk',
                  value: chunkIndex.toString(),
                ),
                if (metadataEntries.isNotEmpty)
                  _InfoPill(
                    icon: Icons.dataset_outlined,
                    label: 'Metadata',
                    value: '${metadataEntries.length} campos',
                  ),
              ],
            ),

            if (metadataEntries.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.035),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: metadataEntries.map((entry) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${entry.key}: ${entry.value}',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            const SizedBox(height: 18),

            Row(
              children: [
                const Text(
                  'Fragmento original',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => openPdf(context),
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Abrir PDF'),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    content,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.65,
                      fontSize: 15.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppTheme.accent,
            size: 15,
          ),
          const SizedBox(width: 7),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
