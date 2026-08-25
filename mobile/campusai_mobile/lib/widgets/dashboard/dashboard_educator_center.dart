import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../layout/responsive_layout.dart';
import '../../services/access_control_service.dart';
import '../../theme/app_theme.dart';
import '../section_card.dart';
import '../studybook/booky_card.dart';

class DashboardEducatorCenter extends StatelessWidget {
  final bool hasActiveDocument;
  final VoidCallback openExam;
  final VoidCallback openFlashcards;
  final VoidCallback openQuestionBank;
  final VoidCallback openRubric;
  final VoidCallback openTeachingPlan;

  const DashboardEducatorCenter({
    super.key,
    required this.hasActiveDocument,
    required this.openExam,
    required this.openFlashcards,
    required this.openQuestionBank,
    required this.openRubric,
    required this.openTeachingPlan,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final isEducator = const AccessControlService().hasTeacherTools;

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
        onTap: openQuestionBank,
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
        subtitle: 'Genera criterios de evaluación y niveles de desempeño.',
        icon: Icons.fact_check_rounded,
        color: AppTheme.accent,
        enabled: hasActiveDocument,
        onTap: openRubric,
      ),
      _EducatorAction(
        title: 'Planificación docente',
        subtitle: 'Genera unidades, actividades y cronograma académico.',
        icon: Icons.calendar_month_rounded,
        color: AppTheme.primary,
        enabled: hasActiveDocument,
        onTap: openTeachingPlan,
      ),
      _EducatorAction(
        title: 'AudioBook',
        subtitle: 'Crea guiones narrados para audio aprendizaje.',
        icon: Icons.headphones_rounded,
        color: AppTheme.success,
        enabled: true,
        onTap: () => context.goNamed('audioBookStudio'),
      ),
      _EducatorAction(
        title: 'Asistencia',
        subtitle: 'Registra presencia, ausencias, tardanzas y excusas.',
        icon: Icons.fact_check_rounded,
        color: AppTheme.success,
        enabled: true,
        onTap: () => context.goNamed('attendance'),
      ),
      _EducatorAction(
        title: 'Dashboard académico',
        subtitle: 'Rendimiento, ranking y riesgo por curso.',
        icon: Icons.dashboard_customize_rounded,
        color: AppTheme.secondary,
        enabled: true,
        onTap: () => context.goNamed('academic-dashboard'),
      ),
      _EducatorAction(
        title: 'Mis Estudiantes',
        subtitle: 'Busca, edita y gestiona estudiantes.',
        icon: Icons.groups_rounded,
        color: AppTheme.secondary,
        enabled: true,
        onTap: () => context.goNamed('students'),
      ),
      _EducatorAction(
        title: 'Mis Cursos',
        subtitle: 'Crea, edita y selecciona cursos activos.',
        icon: Icons.school_rounded,
        color: AppTheme.primary,
        enabled: true,
        onTap: () => context.goNamed('courses'),
      ),
      _EducatorAction(
        title: 'Mis Exámenes',
        subtitle: 'Repositorio docente de exámenes, versiones y claves.',
        icon: Icons.assignment_turned_in_rounded,
        color: AppTheme.accent,
        enabled: true,
        onTap: () => context.goNamed('saved-exams'),
      ),
      _EducatorAction(
        title: 'Ponderaciones',
        subtitle: 'Define pesos por evaluación y promedio final.',
        icon: Icons.percent_rounded,
        color: AppTheme.success,
        enabled: true,
        onTap: () => context.goNamed('assessment-weights'),
      ),
      _EducatorAction(
        title: 'Acta final',
        subtitle: 'Promedios, asistencia y estado académico.',
        icon: Icons.summarize_rounded,
        color: AppTheme.accent,
        enabled: true,
        onTap: () => context.goNamed('final-report'),
      ),
      _EducatorAction(
        title: 'Libro de calificaciones',
        subtitle: 'Consulta y exporta evaluaciones guardadas.',
        icon: Icons.table_chart_rounded,
        color: AppTheme.primary,
        enabled: true,
        onTap: () => context.goNamed('gradebook'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Teacher Studio',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'De tu contenido a una clase lista para enseñar.',
          style: TextStyle(
            color: AppTheme.textMuted,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        BookyCard(
          title: 'Hoy puedes preparar tu próxima clase.',
          message: hasActiveDocument
              ? 'Ya analicé tu contenido. Puedo generar la planificación, crear la rúbrica, preparar un examen o revisar los recursos.'
              : 'Empieza por crear un curso y añadir el material que quieres convertir en una clase.',
          primaryLabel:
              hasActiveDocument ? 'Generar planificación' : 'Crear curso',
          secondaryLabel: 'Crear rúbrica',
          onPrimary: hasActiveDocument
              ? openTeachingPlan
              : () => context.goNamed('courses'),
          onSecondary: hasActiveDocument ? openRubric : null,
        ),
        const SizedBox(height: 18),
        const Text(
          'Herramientas para preparar tu clase',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 12),
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
