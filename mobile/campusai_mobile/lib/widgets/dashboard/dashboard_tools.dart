import 'package:flutter/material.dart';
import '../../layout/responsive_layout.dart';
import '../../theme/app_theme.dart';
import '../section_card.dart';

class DashboardTools extends StatelessWidget {
  final bool isLoading;
  final bool hasActiveDocument;

  final VoidCallback openChat;
  final VoidCallback openSummary;
  final VoidCallback openAudiobook;
  final VoidCallback openVoiceTutor;
  final VoidCallback openFlashcards;
  final VoidCallback openQuiz;
  final VoidCallback openQuestionBank;
  final VoidCallback openExam;

  const DashboardTools({
    super.key,
    required this.isLoading,
    required this.hasActiveDocument,
    required this.openChat,
    required this.openSummary,
    required this.openAudiobook,
    required this.openVoiceTutor,
    required this.openFlashcards,
    required this.openQuiz,
    required this.openQuestionBank,
    required this.openExam,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    int crossAxisCount = isMobile ? 2 : 2;

    if (ResponsiveLayout.isTablet(context)) {
      crossAxisCount = 2;
    }

    if (ResponsiveLayout.isDesktop(context)) {
      crossAxisCount = 4;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Herramientas AI',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: isMobile ? 24 : 30,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Elige qué quieres hacer con tu documento.',
          style: TextStyle(
            color: AppTheme.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: ResponsiveLayout.isDesktop(context)
              ? 1.18
              : isMobile
                  ? 0.90
                  : 1.14,
          children: [
            _ToolCard(
              title: 'Chat',
              subtitle: 'Pregunta y conversa con tu documento.',
              icon: Icons.chat_bubble_rounded,
              color: AppTheme.accent,
              enabled: hasActiveDocument,
              onTap: hasActiveDocument ? openChat : null,
            ),
            _ToolCard(
              title: 'Resumir',
              subtitle: 'Lee la idea principal sin ruido.',
              icon: Icons.summarize_rounded,
              color: AppTheme.primary,
              enabled: hasActiveDocument,
              onTap: hasActiveDocument ? openSummary : null,
            ),
            _ToolCard(
              title: 'AudioBook',
              subtitle: 'Convierte contenido en escucha guiada.',
              icon: Icons.auto_stories_rounded,
              color: AppTheme.success,
              onTap: isLoading ? null : openAudiobook,
            ),
            _ToolCard(
              title: 'Voice Tutor',
              subtitle: 'Practica hablando con Booky.',
              icon: Icons.record_voice_over_rounded,
              color: AppTheme.secondary,
              onTap: isLoading ? null : openVoiceTutor,
            ),
            _ToolCard(
              title: 'Flashcards',
              subtitle: 'Crea tarjetas para repasar rápido.',
              icon: Icons.style_rounded,
              color: AppTheme.success,
              enabled: hasActiveDocument,
              onTap: hasActiveDocument ? openFlashcards : null,
            ),
            _ToolCard(
              title: 'Quiz',
              subtitle: 'Practica con preguntas del contenido.',
              icon: Icons.quiz_rounded,
              color: AppTheme.secondary,
              enabled: hasActiveDocument,
              onTap: hasActiveDocument ? openQuiz : null,
            ),
            _ToolCard(
              title: 'Banco de preguntas',
              subtitle: 'Genera preguntas reutilizables.',
              icon: Icons.inventory_2_rounded,
              color: AppTheme.primary,
              enabled: hasActiveDocument,
              onTap: hasActiveDocument ? openQuestionBank : null,
            ),
            _ToolCard(
              title: 'Generar examen',
              subtitle: 'Crea una evaluación completa.',
              icon: Icons.assignment_rounded,
              color: AppTheme.accent,
              enabled: hasActiveDocument,
              onTap: hasActiveDocument ? openExam : null,
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
    final isMobile = ResponsiveLayout.isMobile(context);

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: SectionCard(
        padding: EdgeInsets.all(isMobile ? 14 : 16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                color: color,
                size: ResponsiveLayout.isMobile(context) ? 22 : 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: isMobile ? 14.5 : 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              maxLines: ResponsiveLayout.isMobile(context) ? 3 : 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textMuted,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
