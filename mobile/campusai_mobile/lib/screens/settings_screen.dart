import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/app_plans.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/billing_service.dart';
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

  Future<void> openBillingPortal(
    BuildContext context,
  ) async {
    try {
      await const BillingService().openCustomerPortal();
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo abrir el portal de suscripción: $error',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> signOut(
    BuildContext context,
  ) async {
    await AuthService.signOut();

    if (!context.mounted) return;

    context.go('/auth');
  }

  Future<void> clearHistory(
    BuildContext context,
  ) async {
    await HistoryService.clearHistory();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context).historyCleared,
        ),
      ),
    );
  }

  Widget buildUsageSummaryCard(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.getUsageSummary(),
      builder: (context, snapshot) {
        Widget usageRow(
          String label,
          String value,
        ) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          );
        }

        String usedLimit(
          Map<String, dynamic>? usage,
          String key,
          String limitKey,
        ) {
          final item = usage?[key];

          if (item is! Map) {
            return '0 / -';
          }

          final used = item['used_today']?.toString() ?? '0';
          final limit = item[limitKey]?.toString() ?? '-';

          return '$used / $limit';
        }

        String exportsText(
          Map<String, dynamic>? usage,
        ) {
          final item = usage?['exports_generated'];

          if (item is! Map) {
            return '0 hoy';
          }

          final used = item['used_today']?.toString() ?? '0';
          final permissions = item['permissions'];

          if (permissions is! Map) {
            return '$used hoy';
          }

          final pdf = permissions['pdf'] == true ? 'PDF' : '';
          final docx = permissions['docx'] == true ? 'DOCX' : '';
          final pptx = permissions['pptx'] == true ? 'PPTX' : '';

          final allowed = [
            pdf,
            docx,
            pptx,
          ].where((item) => item.isNotEmpty).join(', ');

          return '$used hoy · $allowed';
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return SectionCard(
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 14),
                Text(
                  l10n.loadingPlanUsage,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return SectionCard(
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppTheme.danger,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'No se pudo cargar el uso del plan: ${snapshot.error}',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data ?? {};
        final plan = data['plan']?.toString() ??
            const PlanGuardService().currentPlanName;

        final rawUsage = data['usage'];
        final usage = rawUsage is Map<String, dynamic>
            ? rawUsage
            : rawUsage is Map
                ? Map<String, dynamic>.from(rawUsage)
                : <String, dynamic>{};

        return SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.analytics_rounded,
                    color: AppTheme.accent,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Uso del plan',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${l10n.activePlan}: $plan',
                style: TextStyle(
                  color: AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              usageRow(
                l10n.pdfsUploadedToday,
                usedLimit(
                  usage,
                  'pdf_uploads',
                  'limit',
                ),
              ),
              usageRow(
                l10n.chatMessagesToday,
                usedLimit(
                  usage,
                  'chat_messages',
                  'limit',
                ),
              ),
              usageRow(
                'Flashcards',
                '${usedLimit(
                  usage,
                  'flashcards_generated',
                  'limit_per_pdf',
                )} por PDF',
              ),
              usageRow(
                l10n.exams,
                '${usedLimit(
                  usage,
                  'exams_generated',
                  'limit_per_pdf',
                )} por PDF',
              ),
              usageRow(
                l10n.exports,
                exportsText(usage),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final l10n = AppLocalizations.of(context);

    final themeMode = ref.watch(themeProvider);

    final locale = ref.watch(localeProvider);

    final localeNotifier = ref.read(localeProvider.notifier);

    final themeNotifier = ref.read(themeProvider.notifier);

    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.settingsTitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Text(
            l10n.preferences,
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.settingsSubtitle,
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.mainGradient,
                    borderRadius: BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: const Icon(
                    Icons.palette_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Modo oscuro',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        l10n.darkModeDescription,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: isDark,
                  onChanged: (_) {
                    themeNotifier.toggleTheme();
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          /// LANGUAGE
          SectionCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.mainGradient,
                    borderRadius: BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: const Icon(
                    Icons.language_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.language,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        l10n.languageDescription,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                DropdownButton<String>(
                  value: locale.languageCode,
                  underline: const SizedBox.shrink(),
                  borderRadius: BorderRadius.circular(16),
                  items: const [
                    DropdownMenuItem(
                      value: 'es',
                      child: Text('Español'),
                    ),
                    DropdownMenuItem(
                      value: 'en',
                      child: Text('English'),
                    ),
                    DropdownMenuItem(
                      value: 'pt',
                      child: Text('Português'),
                    ),
                    DropdownMenuItem(
                      value: 'fr',
                      child: Text('Français'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }

                    localeNotifier.changeLocale(value);
                  },
                ),
              ],
            ),
          ),

          /// HISTORY
          SectionCard(
            onTap: () => clearHistory(context),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(
                      16,
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.danger,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.clearHistory,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        l10n.clearHistoryDescription,
                        style: TextStyle(
                          color: AppTheme.textMuted,
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.mainGradient,
                    borderRadius: BorderRadius.circular(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Plan actual: ${const PlanGuardService().currentPlanName}\n'
                        'Fuente: ${const PlanGuardService().currentPlanSource}\n'
                        'Estado: ${const PlanGuardService().currentSubscriptionStatus}',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ver planes Free, Pro y Educator, límites y beneficios.',
                        style: TextStyle(
                          color: AppTheme.textMuted,
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

          buildUsageSummaryCard(context, l10n),

          const SizedBox(height: 18),

          /// TEST PLAN SELECTOR
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.planAndSubscription,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.planAndSubscriptionDescription,
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
                        child: Text(l10n.useFree),
                      ),
                    ],
                    OutlinedButton(
                      onPressed: () {
                        syncRealPlan(context);
                      },
                      child: Text(l10n.syncReal),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        openBillingPortal(context);
                      },
                      icon: const Icon(Icons.credit_card_rounded),
                      label: Text(l10n.manageSubscription),
                    ),
                    if (enablePlanTester) ...[
                      FilledButton(
                        onPressed: () {
                          changeTestPlan(
                            context,
                            CampusPlan.pro,
                          );
                        },
                        child: Text(l10n.usePro),
                      ),
                      FilledButton(
                        onPressed: () {
                          changeTestPlan(
                            context,
                            CampusPlan.educator,
                          );
                        },
                        child: Text(l10n.useEducator),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          /// SIGN OUT
          SectionCard(
            onTap: () => signOut(context),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(
                      alpha: 0.15,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: AppTheme.danger,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cerrar sesión',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Cierra tu cuenta y vuelve al plan Free localmente.',
                        style: TextStyle(
                          color: AppTheme.textMuted,
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
