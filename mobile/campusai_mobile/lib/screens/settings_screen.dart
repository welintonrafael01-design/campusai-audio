import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/app_plans.dart';
import '../providers/theme_provider.dart';
import '../services/history_service.dart';
import '../services/plan_guard_service.dart';
import '../services/subscription_service.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const bool enablePlanTester = bool.fromEnvironment(
    'ENABLE_PLAN_TESTER',
    defaultValue: false,
  );

  Future<void> syncRealPlan(
    BuildContext context,
  ) async {
    try {
      final plan = await const SubscriptionService().syncCurrentUserPlan();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Plan sincronizado desde Supabase: ${AppPlans.planNames[plan]}.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo sincronizar el plan: $error',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void changeTestPlan(
    BuildContext context,
    CampusPlan plan,
  ) {
    const PlanGuardService().saveCurrentPlan(plan);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Plan de prueba cambiado a ${AppPlans.planNames[plan]}.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> clearHistory(
    BuildContext context,
  ) async {
    await HistoryService.clearHistory();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Historial eliminado correctamente.',
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final themeMode =
        ref.watch(themeProvider);

    final themeNotifier =
        ref.read(themeProvider.notifier);

    final isDark =
        themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Text(
            'Preferencias',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Personaliza tu experiencia StudyBook AI.',
            style: TextStyle(
              color: AppTheme.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          /// THEME
          SectionCard(
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient:
                        AppTheme.mainGradient,
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: const Icon(
                    Icons.palette_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'Modo oscuro',
                        style: TextStyle(
                          color: AppTheme
                              .textPrimary,
                          fontWeight:
                              FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Cambia entre tema claro y oscuro.',
                        style: TextStyle(
                          color: AppTheme
                              .textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isDark,
                  onChanged: (_) {
                    themeNotifier
                        .toggleTheme();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          /// HISTORY
          SectionCard(
            onTap: () =>
                clearHistory(context),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger
                        .withValues(
                      alpha: 0.15,
                    ),
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.danger,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'Limpiar historial',
                        style: TextStyle(
                          color: AppTheme
                              .textPrimary,
                          fontWeight:
                              FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Elimina documentos y datos locales.',
                        style: TextStyle(
                          color: AppTheme
                              .textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: AppTheme.textMuted,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          /// PREMIUM
          SectionCard(
            onTap: () => context.go('/plans'),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient:
                        AppTheme.mainGradient,
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: const Icon(
                    Icons.workspace_premium,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        'Plan actual: ${const PlanGuardService().currentPlanName}',
                        style: TextStyle(
                          color: AppTheme
                              .textPrimary,
                          fontWeight:
                              FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ver planes Free, Pro y Educator, límites y beneficios.',
                        style: TextStyle(
                          color: AppTheme
                              .textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 18,
                  color: AppTheme.textMuted,
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          /// TEST PLAN SELECTOR
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Plan y suscripción',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sincroniza tu plan real desde Supabase. El selector manual solo se activa en modo desarrollo.',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (enablePlanTester) ...[
                      OutlinedButton(
                        onPressed: () {
                          changeTestPlan(
                            context,
                            CampusPlan.free,
                          );
                        },
                        child: const Text('Usar Free'),
                      ),
                    ],
                    OutlinedButton(
                      onPressed: () {
                        syncRealPlan(context);
                      },
                      child: const Text('Sincronizar real'),
                    ),
                    if (enablePlanTester) ...[
                      FilledButton(
                        onPressed: () {
                          changeTestPlan(
                            context,
                            CampusPlan.pro,
                          );
                        },
                        child: const Text('Usar Pro'),
                      ),
                      FilledButton(
                        onPressed: () {
                          changeTestPlan(
                            context,
                            CampusPlan.educator,
                          );
                        },
                        child: const Text('Usar Educator'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          const Center(
            child: Text(
              'StudyBook AI v1.0.0',
              style: TextStyle(
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}