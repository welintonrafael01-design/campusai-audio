import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

class Sidebar extends StatelessWidget {
  final String currentRoute;

  const Sidebar({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
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
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: AppTheme.accent,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'StudyBook AI',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),

          _SidebarItem(
            title: 'Dashboard',
            icon: Icons.dashboard_rounded,
            selected:
                currentRoute == '/dashboard',
            onTap: () {
              context.go('/dashboard');
            },
          ),

          _SidebarItem(
            title: 'Configuración',
            icon: Icons.settings_rounded,
            selected:
                currentRoute == '/settings',
            onTap: () {
              context.go('/settings');
            },
          ),

          const Spacer(),

          Container(
            padding:
                const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient:
                  AppTheme.mainGradient,
              borderRadius:
                  BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                ),
                SizedBox(height: 12),
                Text(
                  'Premium AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Lectura completa IA y sincronización cloud próximamente.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ],
            ),
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
      padding:
          const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              color:
                  selected
                      ? AppTheme.primary
                          .withValues(
                          alpha: 0.16,
                        )
                      : Colors.transparent,
              borderRadius:
                  BorderRadius.circular(
                18,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color:
                      selected
                          ? AppTheme.accent
                          : AppTheme
                              .textMuted,
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: TextStyle(
                    color:
                        selected
                            ? AppTheme
                                .textPrimary
                            : AppTheme
                                .textMuted,
                    fontWeight:
                        FontWeight.w700,
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