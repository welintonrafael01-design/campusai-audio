import 'package:flutter/material.dart';

import '../../layout/responsive_layout.dart';
import '../../theme/app_theme.dart';
import '../section_card.dart';

class DashboardTools extends StatelessWidget {
  final bool isLoading;
  final bool hasActiveDocument;

  final VoidCallback uploadPdf;
  final VoidCallback openChat;
  final VoidCallback openExam;
  final VoidCallback openFlashcards;

  const DashboardTools({
    super.key,
    required this.isLoading,
    required this.hasActiveDocument,
    required this.uploadPdf,
    required this.openChat,
    required this.openExam,
    required this.openFlashcards,
  });

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = 1;

    if (ResponsiveLayout.isTablet(context)) {
      crossAxisCount = 2;
    }

    if (ResponsiveLayout.isDesktop(context)) {
      crossAxisCount = 4;
    }

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        const Text(
          'Herramientas IA',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 6),

        const Text(
          'Explora funciones inteligentes para estudiar más rápido.',
          style: TextStyle(
            color: AppTheme.textMuted,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 20),

        GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics:
              const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio:
              ResponsiveLayout.isDesktop(context)
                  ? 1.15
                  : 1.1,
          children: [
            _ToolCard(
              title: 'Subir PDF',
              subtitle:
                  'Carga documentos para resumir con IA.',
              icon: Icons.upload_file_rounded,
              color: AppTheme.primary,
              onTap: isLoading
                  ? null
                  : uploadPdf,
            ),

            _ToolCard(
              title: 'Chat IA',
              subtitle:
                  'Pregunta sobre el documento activo.',
              icon:
                  Icons.chat_bubble_rounded,
              color: AppTheme.accent,
              enabled:
                  hasActiveDocument,
              onTap:
                  hasActiveDocument
                      ? openChat
                      : null,
            ),

            _ToolCard(
              title: 'Examen IA',
              subtitle:
                  'Genera preguntas automáticas.',
              icon:
                  Icons.quiz_rounded,
              color:
                  AppTheme.secondary,
              enabled:
                  hasActiveDocument,
              onTap:
                  hasActiveDocument
                      ? openExam
                      : null,
            ),

            _ToolCard(
              title: 'Flashcards',
              subtitle:
                  'Crea tarjetas de estudio inteligentes.',
              icon:
                  Icons.style_rounded,
              color:
                  AppTheme.success,
              enabled:
                  hasActiveDocument,
              onTap:
                  hasActiveDocument
                      ? openFlashcards
                      : null,
            ),
          ],
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  const _ToolCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: SectionCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(
                  alpha: 0.14,
                ),
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),

            const Spacer(),

            Text(
              title,
              style: const TextStyle(
                color:
                    AppTheme.textPrimary,
                fontSize: 18,
                fontWeight:
                    FontWeight.w900,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              subtitle,
              style: const TextStyle(
                color:
                    AppTheme.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}