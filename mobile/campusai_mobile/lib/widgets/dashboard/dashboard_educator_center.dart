import 'package:flutter/material.dart';

import '../../config/app_plans.dart';
import '../../layout/responsive_layout.dart';
import '../../services/plan_guard_service.dart';
import '../../theme/app_theme.dart';
import '../section_card.dart';

class DashboardEducatorCenter extends StatelessWidget {
  final bool hasActiveDocument;
  final VoidCallback openExam;
  final VoidCallback openFlashcards;

  const DashboardEducatorCenter({
    super.key,
    required this.hasActiveDocument,
    required this.openExam,
    required this.openFlashcards,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final plan = const PlanGuardService().currentPlan;
    final isEducator = plan == CampusPlan.educator;

    if (!isEducator) {
      return const SizedBox.shrink();
    }

    final items = [
      _EducatorAction(
        title: 'Banco de preguntas',
        subtitle: 'Genera preguntas reutilizables desde tus PDFs.',
        icon: Icons.inventory_2_rounded,
        color: AppTheme.primary,
        enabled: hasActiveDocument,
        onTap: openExam,
      ),
      _EducatorAction(
        title: 'Examen masivo',
        subtitle: 'Crea evaluaciones amplias para tus estudiantes.',
        icon: Icons.assignment_rounded,
        color: AppTheme.secondary,
        enabled: hasActiveDocument,
        onTap: openExam,
      ),
      _EducatorAction(
        title: 'Guía de estudio',
        subtitle: 'Convierte documentos en material de repaso.',
        icon: Icons.menu_book_rounded,
        color: AppTheme.success,
        enabled: hasActiveDocument,
        onTap: openFlashcards,
      ),
      _EducatorAction(
        title: 'Rúbrica académica',
        subtitle: 'Próximamente: evaluación por criterios.',
        icon: Icons.fact_check_rounded,
        color: AppTheme.accent,
        enabled: false,
        onTap: null,
      ),
      _EducatorAction(
        title: 'Planificación docente',
        subtitle: 'Próximamente: clases, competencias y evaluación.',
        icon: Icons.calendar_month_rounded,
        color: AppTheme.primary,
        enabled: false,
        onTap: null,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Centro Educator',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Herramientas avanzadas para docentes, formadores y creadores de contenido académico.',
          style: TextStyle(
            color: AppTheme.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: isMobile ? 1 : 5,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isMobile ? 2.05 : 0.78,
          children: items,
        ),
      ],
    );
  }
}

class _EducatorAction extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  const _EducatorAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: SectionCard(
        onTap: enabled ? onTap : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                color: color,
                size: ResponsiveLayout.isMobile(context) ? 22 : 27,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: ResponsiveLayout.isMobile(context) ? 16 : 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              maxLines: ResponsiveLayout.isMobile(context) ? 2 : 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textMuted,
                height: 1.35,
                fontSize: 11.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
