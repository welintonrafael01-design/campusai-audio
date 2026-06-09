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
    final user = AuthService.currentUser;
    final email = user?.email ?? 'Usuario no disponible';
    final planSource = const PlanGuardService().currentPlanSource;
    final currentPlan = const PlanGuardService().currentPlan;
    final limits = AppPlans.limits[currentPlan]!;

    final friendlyPlanName = switch (currentPlan) {
      CampusPlan.free => 'Free',
      CampusPlan.pro => 'Pro',
      CampusPlan.educator => 'Educator',
    };

    final friendlyStatus =
        currentPlan == CampusPlan.free ? 'Cuenta activa' : 'Suscripción activa';

    final friendlySource = planSource == 'supabase' ? 'Sincronizado' : 'Local';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Cuenta'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          Text(
            'Mi Cuenta',
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gestiona tu perfil, suscripción, consumo y preferencias de StudyBook AI.',
            style: TextStyle(
              color: AppTheme.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          /// ACCOUNT HEADER
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: AppTheme.mainGradient,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.account_circle_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Usuario StudyBook AI',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _AccountBadge(
                      icon: Icons.workspace_premium_rounded,
                      label: 'Plan',
                      value: friendlyPlanName,
                    ),
                    _AccountBadge(
                      icon: Icons.verified_rounded,
                      label: 'Estado',
                      value: friendlyStatus,
                    ),
                    _AccountBadge(
                      icon: Icons.cloud_done_rounded,
                      label: 'Cuenta',
                      value: friendlySource,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          /// SUBSCRIPTION
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SettingsSectionTitle(
                  icon: Icons.workspace_premium_rounded,
                  title: 'Mi Suscripción',
                  subtitle:
                      'Consulta tu plan actual, límites y beneficios disponibles.',
                ),
                const SizedBox(height: 18),
                _PlanLimitRow(
                  label: 'PDFs por día',
                  value: limits.maxPdfUploadsPerDay.toString(),
                ),
                _PlanLimitRow(
                  label: 'Chats por día',
                  value: limits.maxChatMessagesPerDay.toString(),
                ),
                _PlanLimitRow(
                  label: 'Flashcards por PDF',
                  value: limits.maxFlashcardsPerPdf.toString(),
                ),
                _PlanLimitRow(
                  label: 'Preguntas de examen por PDF',
                  value: limits.maxExamQuestionsPerPdf.toString(),
                ),
                _PlanLimitRow(
                  label: 'Audiolibros y voz',
                  value: limits.canUseVoiceOnboarding ? 'Incluido' : 'Premium',
                ),
                _PlanLimitRow(
                  label: 'Exportaciones',
                  value:
                      'PDF${limits.canExportDocx ? ', DOCX' : ''}${limits.canExportPptx ? ', PPTX' : ''}',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        openBillingPortal(context);
                      },
                      icon: const Icon(Icons.credit_card_rounded),
                      label: const Text('Administrar suscripción'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        context.go('/plans');
                      },
                      icon: const Icon(Icons.rocket_launch_rounded),
                      label: const Text('Ver planes'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        syncRealPlan(context);
                      },
                      icon: const Icon(Icons.sync_rounded),
                      label: const Text('Sincronizar plan'),
                    ),
                  ],
                ),
                if (enablePlanTester) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text(
                    'Modo desarrollo: cambiar plan local',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton(
                        onPressed: () => changeTestPlan(
                          context,
                          CampusPlan.free,
                        ),
                        child: Text(l10n.useFree),
                      ),
                      FilledButton(
                        onPressed: () => changeTestPlan(
                          context,
                          CampusPlan.pro,
                        ),
                        child: Text(l10n.usePro),
                      ),
                      FilledButton(
                        onPressed: () => changeTestPlan(
                          context,
                          CampusPlan.educator,
                        ),
                        child: Text(l10n.useEducator),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 18),

          if (currentPlan == CampusPlan.free) ...[
            const SizedBox(height: 18),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SettingsSectionTitle(
                    icon: Icons.rocket_launch_rounded,
                    title: 'Desbloquea StudyBook AI Premium',
                    subtitle:
                        'Convierte tus PDFs en una experiencia completa de estudio con voz, audio y exportaciones avanzadas.',
                  ),
                  const SizedBox(height: 16),
                  const _PremiumUnlockRow(
                    text: 'Audiolibros y respuestas en audio',
                  ),
                  const _PremiumUnlockRow(
                    text: 'Modo voz para preguntar sin escribir',
                  ),
                  const _PremiumUnlockRow(
                    text: 'Exportación DOCX y PPTX',
                  ),
                  const _PremiumUnlockRow(
                    text: 'Más PDFs y chats por día',
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        context.go('/plans');
                      },
                      icon: const Icon(Icons.workspace_premium_rounded),
                      label: const Text('Actualizar ahora'),
                    ),
                  ),
                ],
              ),
            ),
          ],

          /// USAGE
          buildUsageSummaryCard(context, l10n),

          const SizedBox(height: 18),

          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SettingsSectionTitle(
                  icon: Icons.trending_up_rounded,
                  title: 'Mi Progreso',
                  subtitle:
                      'Resumen rápido de tu actividad dentro de StudyBook AI.',
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _ProgressChip(
                      icon: Icons.picture_as_pdf_rounded,
                      label: 'Documentos',
                      value: 'Activos',
                    ),
                    _ProgressChip(
                      icon: Icons.chat_bubble_rounded,
                      label: 'Chats',
                      value: 'IA',
                    ),
                    _ProgressChip(
                      icon: Icons.headphones_rounded,
                      label: 'Audiolibros',
                      value:
                          currentPlan == CampusPlan.free ? 'Premium' : 'Activo',
                    ),
                    _ProgressChip(
                      icon: Icons.quiz_rounded,
                      label: 'Exámenes',
                      value: 'Automáticos',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          /// PREFERENCES
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SettingsSectionTitle(
                  icon: Icons.tune_rounded,
                  title: 'Preferencias',
                  subtitle: 'Ajusta idioma, tema y experiencia visual.',
                ),
                const SizedBox(height: 18),
                _SettingsSwitchRow(
                  icon: Icons.dark_mode_rounded,
                  title: 'Modo oscuro',
                  subtitle: l10n.darkModeDescription,
                  value: isDark,
                  onChanged: (_) {
                    themeNotifier.toggleTheme();
                  },
                ),
                const Divider(height: 26),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.language_rounded,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.language,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.languageDescription,
                            style: const TextStyle(
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
                        if (value == null) return;

                        localeNotifier.changeLocale(value);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          /// HISTORY
          SectionCard(
            onTap: () => clearHistory(context),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
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
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.clearHistoryDescription,
                        style: const TextStyle(
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

          /// SIGN OUT
          SectionCard(
            onTap: () => signOut(context),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: AppTheme.danger,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
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
                        'Cierra tu cuenta y vuelve al inicio de sesión.',
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

class _AccountBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AccountBadge({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 13,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: AppTheme.accent,
            size: 17,
          ),
          const SizedBox(width: 7),
          Text(
            '$label: ',
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanLimitRow extends StatelessWidget {
  final String label;
  final String value;

  const _PlanLimitRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppTheme.success,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SettingsSectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: AppTheme.mainGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsSwitchRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
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
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _PremiumUnlockRow extends StatelessWidget {
  final String text;

  const _PremiumUnlockRow({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppTheme.success,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProgressChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.accent,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w900,
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
