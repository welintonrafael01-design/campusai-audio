import 'package:flutter/material.dart';

import '../models/document_history.dart';
import '../theme/app_theme.dart';
import '../utils/document_display_title.dart';
import '../widgets/section_card.dart';

typedef DocumentAction = Future<void> Function();

class DocumentDetailScreen extends StatefulWidget {
  final DocumentHistory document;
  final bool isCloud;
  final bool isFavorite;
  final bool isGeneratingAudiobook;
  final DocumentAction onChat;
  final DocumentAction onAudioBook;
  final DocumentAction onVoiceTutor;
  final DocumentAction onFlashcards;
  final DocumentAction onQuiz;
  final DocumentAction onQuestionBank;
  final DocumentAction onExam;
  final DocumentAction onOpenPdf;
  final DocumentAction onSetActive;
  final DocumentAction onToggleFavorite;
  final DocumentAction onDelete;

  const DocumentDetailScreen({
    super.key,
    required this.document,
    required this.isCloud,
    required this.isFavorite,
    required this.isGeneratingAudiobook,
    required this.onChat,
    required this.onAudioBook,
    required this.onVoiceTutor,
    required this.onFlashcards,
    required this.onQuiz,
    required this.onQuestionBank,
    required this.onExam,
    required this.onOpenPdf,
    required this.onSetActive,
    required this.onToggleFavorite,
    required this.onDelete,
  });

  @override
  State<DocumentDetailScreen> createState() => _DocumentDetailScreenState();
}

class _DocumentDetailScreenState extends State<DocumentDetailScreen> {
  late bool isFavorite = widget.isFavorite;

  Future<void> runAndClose(DocumentAction action) async {
    Navigator.of(context).pop();
    await action();
  }

  Future<void> showSummary() async {
    final summary = widget.document.cleanSummary;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resumen',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: SelectableText(
                    summary.isEmpty
                        ? 'Este documento todavía no tiene un resumen guardado.'
                        : summary,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      height: 1.55,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    final title = documentDisplayTitle(document.fileName);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Detalle del documento'),
        backgroundColor: AppTheme.background,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(16),
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
                                title,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${document.formattedDate} · ${widget.isCloud ? 'Cloud' : 'Local'}',
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    if (document.cleanSummary.isNotEmpty) ...[
                      const _SectionTitle('Resumen breve'),
                      const SizedBox(height: 8),
                      Text(
                        document.cleanSummary,
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    const _SectionTitle('Estudiar con IA'),
                    const SizedBox(height: 12),
                    _ActionGrid(
                      actions: [
                        _DetailAction(
                          label: 'Chat',
                          icon: Icons.chat_bubble_rounded,
                          onTap: () => runAndClose(widget.onChat),
                        ),
                        _DetailAction(
                          label: 'Resumen',
                          icon: Icons.summarize_rounded,
                          onTap: showSummary,
                        ),
                        _DetailAction(
                          label: widget.isGeneratingAudiobook
                              ? 'Creando AudioBook...'
                              : 'AudioBook',
                          icon: Icons.headphones_rounded,
                          onTap: widget.isGeneratingAudiobook
                              ? null
                              : () => runAndClose(widget.onAudioBook),
                        ),
                        _DetailAction(
                          label: 'Tutor IA',
                          icon: Icons.record_voice_over_rounded,
                          onTap: () => runAndClose(widget.onVoiceTutor),
                        ),
                        _DetailAction(
                          label: 'Flashcards',
                          icon: Icons.style_rounded,
                          onTap: () => runAndClose(widget.onFlashcards),
                        ),
                        _DetailAction(
                          label: 'Quiz',
                          icon: Icons.psychology_alt_rounded,
                          onTap: () => runAndClose(widget.onQuiz),
                        ),
                        _DetailAction(
                          label: 'Banco de preguntas',
                          icon: Icons.fact_check_rounded,
                          onTap: () => runAndClose(widget.onQuestionBank),
                        ),
                        _DetailAction(
                          label: 'Examen',
                          icon: Icons.quiz_rounded,
                          onTap: () => runAndClose(widget.onExam),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle('Documento'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => runAndClose(widget.onOpenPdf),
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('Abrir PDF'),
                    ),
                    const SizedBox(height: 24),
                    const _SectionTitle('Más acciones'),
                    const SizedBox(height: 12),
                    SectionCard(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          ListTile(
                            minVerticalPadding: 12,
                            leading: Icon(
                              isFavorite
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              color: isFavorite
                                  ? AppTheme.warning
                                  : AppTheme.textMuted,
                            ),
                            title: Text(
                              isFavorite
                                  ? 'Quitar de favoritos'
                                  : 'Agregar a favoritos',
                            ),
                            onTap: () async {
                              await widget.onToggleFavorite();
                              if (!mounted) return;
                              setState(() => isFavorite = !isFavorite);
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            minVerticalPadding: 12,
                            leading: const Icon(
                              Icons.check_circle_outline_rounded,
                              color: AppTheme.accent,
                            ),
                            title: const Text('Usar como documento activo'),
                            onTap: widget.onSetActive,
                          ),
                          const Divider(height: 1),
                          ListTile(
                            minVerticalPadding: 12,
                            leading: const Icon(
                              Icons.delete_outline_rounded,
                              color: AppTheme.danger,
                            ),
                            title: const Text('Eliminar documento'),
                            onTap: () => runAndClose(widget.onDelete),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium,
    );
  }
}

class _DetailAction {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _DetailAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class _ActionGrid extends StatelessWidget {
  final List<_DetailAction> actions;

  const _ActionGrid({required this.actions});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 640 ? 3 : 2;
        const spacing = 10.0;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: actions.map((action) {
            return SizedBox(
              width: width,
              height: 76,
              child: OutlinedButton(
                onPressed: action.onTap,
                style: OutlinedButton.styleFrom(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: Row(
                  children: [
                    Icon(action.icon, size: 21),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        action.label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
