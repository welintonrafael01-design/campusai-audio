import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../layout/responsive_layout.dart';
import '../services/access_control_service.dart';
import '../theme/app_theme.dart';
import 'sidebar.dart';

class StudyBookAppShell extends StatelessWidget {
  final String currentRoute;
  final Widget child;
  final double maxContentWidth;

  const StudyBookAppShell({
    super.key,
    required this.currentRoute,
    required this.child,
    this.maxContentWidth = 1120,
  });

  @override
  Widget build(BuildContext context) {
    final access = const AccessControlService();
    final navigationItems = _navigationItems(access.hasTeacherTools);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: Column(
            children: [
              Expanded(child: child),
              NavigationBar(
                selectedIndex: _selectedIndex(navigationItems),
                onDestinationSelected: (index) {
                  context.go(navigationItems[index].route);
                },
                destinations: [
                  for (final item in navigationItems)
                    NavigationDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: item.label,
                    ),
                ],
              ),
            ],
          ),
          tablet: Row(
            children: [
              Sidebar(currentRoute: currentRoute),
              Expanded(child: child),
            ],
          ),
          desktop: Row(
            children: [
              Sidebar(currentRoute: currentRoute),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_ShellNavigationItem> _navigationItems(bool includeTeacher) {
    return [
      const _ShellNavigationItem(
        label: 'Inicio',
        route: '/dashboard',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
      ),
      const _ShellNavigationItem(
        label: 'Biblioteca',
        route: '/library',
        icon: Icons.library_books_outlined,
        selectedIcon: Icons.library_books_rounded,
      ),
      const _ShellNavigationItem(
        label: 'Aprendizaje',
        route: '/learning',
        icon: Icons.auto_stories_outlined,
        selectedIcon: Icons.auto_stories_rounded,
      ),
      if (includeTeacher)
        const _ShellNavigationItem(
          label: 'Teacher',
          route: '/teacher',
          icon: Icons.school_outlined,
          selectedIcon: Icons.school_rounded,
        ),
      const _ShellNavigationItem(
        label: 'Cuenta',
        route: '/account',
        icon: Icons.account_circle_outlined,
        selectedIcon: Icons.account_circle_rounded,
      ),
    ];
  }

  int _selectedIndex(List<_ShellNavigationItem> items) {
    final index = items.indexWhere((item) {
      if (item.route == currentRoute) return true;
      if (item.route == '/learning' && currentRoute == '/student-dashboard') {
        return true;
      }
      if (item.route == '/teacher' && currentRoute == '/courses') return true;
      if (item.route == '/account' && currentRoute == '/settings') return true;
      return false;
    });

    return index < 0 ? 0 : index;
  }
}

class _ShellNavigationItem {
  final String label;
  final String route;
  final IconData icon;
  final IconData selectedIcon;

  const _ShellNavigationItem({
    required this.label,
    required this.route,
    required this.icon,
    required this.selectedIcon,
  });
}
