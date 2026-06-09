import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/document_history.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/sidebar.dart';
import '../layout/responsive_layout.dart';
import '../widgets/section_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<DocumentHistory> documents = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    loadLibrary();
  }

  Future<void> loadLibrary() async {
    final items = await HistoryService.getHistory();

    if (!mounted) return;

    setState(() {
      documents = items;
      isLoading = false;
    });
  }

  Future<void> setActiveDocument(DocumentHistory document) async {
    await HistoryService.saveActiveDocument(document);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${document.fileName} seleccionado como documento activo.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> deleteDocument(int index) async {
    await HistoryService.deleteDocument(index);
    await loadLibrary();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Documento eliminado de la biblioteca.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void openChat(DocumentHistory document) {
    context.go(
      Uri(
        path: '/chat/${document.documentId}',
        queryParameters: {
          'fileName': document.fileName,
        },
      ).toString(),
    );
  }

  void openExam(DocumentHistory document) {
    context.go('/exam/${document.documentId}');
  }

  void openFlashcards(DocumentHistory document) {
    context.go('/flashcards/${document.documentId}');
  }

  Widget buildEmptyState() {
    return SectionCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: AppTheme.mainGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.library_books_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Tu biblioteca está vacía',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sube tu primer PDF para comenzar a crear resúmenes, audiolibros, flashcards y exámenes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () {
              context.go('/dashboard');
            },
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Subir PDF'),
          ),
        ],
      ),
    );
  }

  Widget buildLibraryContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (documents.isEmpty) {
      return buildEmptyState();
    }

    return Column(
      children: [
        _LibrarySummary(
          totalDocuments: documents.length,
          audioCount: documents.where((item) => item.hasAudio).length,
          summaryCount: documents.where((item) => item.hasSummary).length,
        ),
        const SizedBox(height: 18),
        ...documents.asMap().entries.map(
          (entry) {
            final index = entry.key;
            final document = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _DocumentLibraryCard(
                document: document,
                onSetActive: () => setActiveDocument(document),
                onChat: () => openChat(document),
                onAudio: () async {
                  await setActiveDocument(document);

                  if (!mounted) return;

                  context.go('/dashboard');
                },
                onFlashcards: () => openFlashcards(document),
                onExam: () => openExam(document),
                onDelete: () => deleteDocument(index),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget buildBody() {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Container(
          padding: const EdgeInsets.all(26),
          decoration: BoxDecoration(
            gradient: AppTheme.mainGradient,
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.library_books_rounded,
                color: Colors.white,
                size: 34,
              ),
              SizedBox(height: 12),
              Text(
                'Biblioteca Inteligente',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Organiza tus documentos, chats, audiolibros, flashcards y exámenes en un solo lugar.',
                style: TextStyle(
                  color: Colors.white,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        buildLibraryContent(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = buildBody();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: content,
          tablet: content,
          desktop: Row(
            children: [
              const Sidebar(currentRoute: '/library'),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: content,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibrarySummary extends StatelessWidget {
  final int totalDocuments;
  final int audioCount;
  final int summaryCount;

  const _LibrarySummary({
    required this.totalDocuments,
    required this.audioCount,
    required this.summaryCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LibraryMetric(
            icon: Icons.picture_as_pdf_rounded,
            label: 'Documentos',
            value: totalDocuments.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LibraryMetric(
            icon: Icons.summarize_rounded,
            label: 'Resúmenes',
            value: summaryCount.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _LibraryMetric(
            icon: Icons.headphones_rounded,
            label: 'Audios',
            value: audioCount.toString(),
          ),
        ),
      ],
    );
  }
}

class _LibraryMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _LibraryMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.accent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentLibraryCard extends StatelessWidget {
  final DocumentHistory document;
  final VoidCallback onSetActive;
  final VoidCallback onChat;
  final VoidCallback onAudio;
  final VoidCallback onFlashcards;
  final VoidCallback onExam;
  final VoidCallback onDelete;

  const _DocumentLibraryCard({
    required this.document,
    required this.onSetActive,
    required this.onChat,
    required this.onAudio,
    required this.onFlashcards,
    required this.onExam,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: AppTheme.accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      document.formattedDate,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Eliminar',
                onPressed: onDelete,
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppTheme.danger,
                ),
              ),
            ],
          ),
          if (document.cleanSummary.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              document.cleanSummary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textMuted,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onChat,
                icon: const Icon(Icons.chat_bubble_rounded),
                label: const Text('Chat'),
              ),
              OutlinedButton.icon(
                onPressed: onAudio,
                icon: const Icon(Icons.headphones_rounded),
                label: Text(
                  document.hasAudio ? 'Escuchar' : 'Crear audio',
                ),
              ),
              OutlinedButton.icon(
                onPressed: onFlashcards,
                icon: const Icon(Icons.style_rounded),
                label: const Text('Flashcards'),
              ),
              OutlinedButton.icon(
                onPressed: onExam,
                icon: const Icon(Icons.quiz_rounded),
                label: const Text('Examen'),
              ),
              OutlinedButton.icon(
                onPressed: onSetActive,
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Usar como activo'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
