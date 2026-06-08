import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/app_plans.dart';
import '../l10n/app_localizations.dart';
import '../services/billing_service.dart';
import '../services/plan_guard_service.dart';
import '../theme/app_theme.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showCheckoutSnackBar();
    });
  }

  String? _checkoutStatus() {
    String? checkoutStatus;

    try {
      checkoutStatus = GoRouterState.of(
        context,
      ).uri.queryParameters['checkout'];
    } catch (_) {
      checkoutStatus = null;
    }

    checkoutStatus ??= Uri.base.queryParameters['checkout'];

    if (checkoutStatus == null || checkoutStatus.isEmpty) {
      final fragment = Uri.base.fragment;

      if (fragment.isNotEmpty) {
        final normalizedFragment =
            fragment.startsWith('/') ? fragment : '/$fragment';

        final fragmentUri = Uri.tryParse(normalizedFragment);
        checkoutStatus = fragmentUri?.queryParameters['checkout'];
      }
    }

    return checkoutStatus;
  }

  String? _checkoutPlanCode() {
    String? planCode;

    try {
      planCode = GoRouterState.of(
        context,
      ).uri.queryParameters['plan'];
    } catch (_) {
      planCode = null;
    }

    planCode ??= Uri.base.queryParameters['plan'];

    if (planCode == null || planCode.isEmpty) {
      final fragment = Uri.base.fragment;

      if (fragment.isNotEmpty) {
        final normalizedFragment =
            fragment.startsWith('/') ? fragment : '/$fragment';

        final fragmentUri = Uri.tryParse(normalizedFragment);
        planCode = fragmentUri?.queryParameters['plan'];
      }
    }

    return planCode;
  }

  String? _checkoutMessage() {
    final status = _checkoutStatus();
    final plan = planFromCode(_checkoutPlanCode());
    final planName = AppPlans.planNames[plan] ?? 'Premium';

    if (status == 'success') {
      const PlanGuardService().saveCurrentPlan(plan);

      return AppLocalizations.of(context).checkoutSuccessMessage(planName);
    }

    if (status == 'cancel') {
      return AppLocalizations.of(context).checkoutCancelMessage;
    }

    return null;
  }

  IconData _checkoutIcon() {
    final status = _checkoutStatus();

    return switch (status) {
      'success' => Icons.check_circle_rounded,
      'cancel' => Icons.info_rounded,
      _ => Icons.info_rounded,
    };
  }

  void _showCheckoutSnackBar() {
    final message = _checkoutMessage();

    if (message == null || !mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _startCheckout(
    BuildContext context,
    CampusPlan plan,
  ) async {
    final planName = AppPlans.planNames[plan] ?? 'Premium';

    try {
      await const BillingService().startCheckout(plan);
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)
                .paymentStartError(planName, error.toString()),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final current = const PlanGuardService().currentPlan;
    final checkoutMessage = _checkoutMessage();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.plansStudyBookTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (checkoutMessage != null) ...[
            Card(
              child: ListTile(
                leading: Icon(
                  _checkoutIcon(),
                  color: AppTheme.accent,
                ),
                title: Text(
                  checkoutMessage,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                subtitle: Text(
                  l10n.checkoutTestModeMessage,
                  style: TextStyle(
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            l10n.plansIntro,
            style: TextStyle(
              color: AppTheme.textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          ...CampusPlan.values.map((plan) {
            final limits = AppPlans.limits[plan]!;
            final isCurrent = plan == current;
            final planName = AppPlans.planNames[plan]!;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          planName,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(width: 12),
                        if (isCurrent)
                          Chip(
                            label: Text(l10n.currentPlan),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _PlanFeature(
                      label: l10n.pdfsPerDay,
                      value: limits.maxPdfUploadsPerDay.toString(),
                    ),
                    _PlanFeature(
                      label: l10n.chatsPerDay,
                      value: limits.maxChatMessagesPerDay.toString(),
                    ),
                    _PlanFeature(
                      label: l10n.flashcardsPerPdf,
                      value: limits.maxFlashcardsPerPdf.toString(),
                    ),
                    _PlanFeature(
                      label: l10n.examQuestionsPerPdf,
                      value: limits.maxExamQuestionsPerPdf.toString(),
                    ),
                    const SizedBox(height: 12),
                    _PlanFeature(
                      label: l10n.exportPdf,
                      value: limits.canExportPdf ? l10n.yes : l10n.no,
                    ),
                    _PlanFeature(
                      label: l10n.exportDocx,
                      value: limits.canExportDocx ? l10n.yes : l10n.no,
                    ),
                    _PlanFeature(
                      label: l10n.exportPptx,
                      value: limits.canExportPptx ? l10n.yes : l10n.no,
                    ),
                    _PlanFeature(
                      label: l10n.advancedAnalytics,
                      value:
                          limits.canUseAdvancedAnalytics ? l10n.yes : l10n.no,
                    ),
                    _PlanFeature(
                      label: l10n.teacherTools,
                      value: limits.canUseEducatorTools ? l10n.yes : l10n.no,
                    ),
                    _PlanFeature(
                      label: l10n.guidedVoice,
                      value: limits.canUseVoiceOnboarding ? l10n.yes : l10n.no,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: isCurrent
                          ? OutlinedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.check_circle_outline),
                              label: Text(l10n.currentPlan),
                            )
                          : FilledButton.icon(
                              onPressed: () {
                                _startCheckout(context, plan);
                              },
                              icon: const Icon(
                                Icons.workspace_premium_rounded,
                              ),
                              label: Text(l10n.upgradeToPlan(planName)),
                            ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PlanFeature extends StatelessWidget {
  final String label;
  final String value;

  const _PlanFeature({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
