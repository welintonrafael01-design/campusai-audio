import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../config/app_plans.dart';
import '../services/access_control_service.dart';
import '../services/plan_guard_service.dart';

class Sidebar extends StatelessWidget {
  final String currentRoute;

  const Sidebar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final plan = const PlanGuardService().currentPlan;
    final access = const AccessControlService();
    final showTeacherStudio = access.hasTeacherTools;

    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          right: BorderSide(
            color: Colors.white.withValues(
              alpha: 0.06,
            ),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.accent,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'StudyBook AI',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          _SidebarItem(
            title: 'Inicio',
            icon: Icons.home_rounded,
            selected: currentRoute == '/dashboard',
            onTap: () {
              context.go('/dashboard');
            },
          ),
          _SidebarItem(
            title: 'Biblioteca',
            icon: Icons.library_books_rounded,
            selected: currentRoute == '/library',
            onTap: () {
              context.go('/library');
            },
          ),
          _SidebarItem(
            title: 'Aprendizaje',
            icon: Icons.auto_stories_rounded,
            selected: currentRoute == '/learning' ||
                currentRoute == '/student-dashboard',
            onTap: () {
              context.go('/learning');
            },
          ),
          if (showTeacherStudio)
            _SidebarItem(
              title: 'Teacher Studio',
              icon: Icons.school_rounded,
              selected:
                  currentRoute == '/teacher' || currentRoute == '/courses',
              onTap: () {
                context.go('/teacher');
              },
            ),
          _SidebarItem(
            title: 'Cuenta',
            icon: Icons.account_circle_rounded,
            selected: currentRoute == '/account' || currentRoute == '/settings',
            onTap: () {
              context.go('/account');
            },
          ),
          const Spacer(),
          Builder(
            builder: (context) {
              final title = switch (plan) {
                CampusPlan.free => 'Cuenta Free',
                CampusPlan.student => 'Cuenta Student',
                CampusPlan.accessibility => 'Cuenta Accessibility',
                CampusPlan.teacher => 'Cuenta Teacher',
                CampusPlan.ultra => 'Cuenta Ultra Premium',
              };

              final description = switch (plan) {
                CampusPlan.free =>
                  'Prueba StudyBook AI y descubre cómo Booky puede ayudarte.',
                CampusPlan.student =>
                  'Convierte contenido en audiolibros, quizzes, flashcards y tutoría inteligente.',
                CampusPlan.accessibility =>
                  'Aprende a tu manera con audio, lectura y explicaciones simples.',
                CampusPlan.teacher =>
                  'Prepara clases, rúbricas, exámenes y recursos en menos tiempo.',
                CampusPlan.ultra =>
                  'Máximo poder con límites ampliados y funciones premium.',
              };

              final icon = switch (plan) {
                CampusPlan.free => Icons.school_outlined,
                CampusPlan.student => Icons.workspace_premium_rounded,
                CampusPlan.accessibility => Icons.accessibility_new_rounded,
                CampusPlan.teacher => Icons.school_rounded,
                CampusPlan.ultra => Icons.auto_awesome_rounded,
              };

              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppTheme.mainGradient,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      icon,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppTheme.primary.withValues(
                      alpha: 0.16,
                    )
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(
                18,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected ? AppTheme.accent : AppTheme.textMuted,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color:
                          selected ? AppTheme.textPrimary : AppTheme.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
