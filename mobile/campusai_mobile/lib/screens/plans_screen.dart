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
      checkoutStatus =
          GoRouterState.of(context).uri.queryParameters['checkout'];
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
      planCode = GoRouterState.of(context).uri.queryParameters['plan'];
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

    if (message == null || !mounted) return;

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

  List<_PlanUiData> _plans(BuildContext context) {
    return [
      const _PlanUiData(
        plan: CampusPlan.free,
        name: 'Free',
        audience: 'Para comenzar',
        price: 'RD\$0',
        period: '/mes',
        badge: '',
        icon: Icons.school_outlined,
        isHighlighted: false,
        benefits: [
          '3 PDFs diarios',
          'Chat IA básico',
          'Resúmenes inteligentes',
          '10 flashcards por PDF',
          '10 preguntas de examen',
        ],
        lockedBenefits: [
          'Audiolibros Premium',
          'Modo voz completo',
          'Exportar DOCX y PPTX',
        ],
      ),
      const _PlanUiData(
        plan: CampusPlan.pro,
        name: 'Pro',
        audience: 'Para estudiar y producir más',
        price: 'RD\$599',
        period: '/mes',
        badge: 'MÁS POPULAR',
        icon: Icons.workspace_premium_rounded,
        isHighlighted: true,
        benefits: [
          '50 PDFs diarios',
          '500 chats diarios',
          'Audiolibros y resumen en audio',
          'Modo voz completo',
          'Escuchar respuestas de la IA',
          'Exportar PDF, DOCX y PPTX',
          '50 flashcards por PDF',
          '50 preguntas de examen',
        ],
        lockedBenefits: [],
      ),
      const _PlanUiData(
        plan: CampusPlan.educator,
        name: 'Educator',
        audience: 'Para docentes e instituciones',
        price: 'RD\$1,199',
        period: '/mes',
        badge: 'DOCENTES',
        icon: Icons.groups_rounded,
        isHighlighted: false,
        benefits: [
          '200 PDFs diarios',
          '2,000 chats diarios',
          'Todo lo incluido en Pro',
          'Herramientas docentes',
          'Analíticas avanzadas',
          '100 flashcards por PDF',
          '100 preguntas de examen',
          'Mayor capacidad para clases',
        ],
        lockedBenefits: [],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final current = const PlanGuardService().currentPlan;
    final checkoutMessage = _checkoutMessage();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Planes StudyBook AI'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
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
                subtitle: const Text(
                  'Tu solicitud de pago fue procesada por Stripe.',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
          ],
          const _PlansHero(),
          const SizedBox(height: 22),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 980;
              final cards = _plans(context)
                  .map(
                    (planData) => _PlanCard(
                      data: planData,
                      isCurrent: current == planData.plan,
                      onSelect: () {
                        if (planData.plan == CampusPlan.free) {
                          return;
                        }

                        _startCheckout(context, planData.plan);
                      },
                    ),
                  )
                  .toList();

              if (!isWide) {
                return Column(
                  children: cards
                      .map(
                        (card) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: card,
                        ),
                      )
                      .toList(),
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: cards
                    .map(
                      (card) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: card,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 22),
          const _PlansFooterNote(),
        ],
      ),
    );
  }
}

class _PlansHero extends StatelessWidget {
  const _PlansHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: AppTheme.mainGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 34,
          ),
          SizedBox(height: 14),
          Text(
            'Elige cómo quieres estudiar con IA',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Convierte tus PDFs en resúmenes, audiolibros, flashcards, exámenes y conversaciones inteligentes.',
            style: TextStyle(
              color: Colors.white,
              height: 1.4,
              fontSize: 15.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final _PlanUiData data;
  final bool isCurrent;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.data,
    required this.isCurrent,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isFree = data.plan == CampusPlan.free;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: data.isHighlighted
              ? AppTheme.accent
              : Colors.white.withValues(alpha: 0.07),
          width: data.isHighlighted ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: data.isHighlighted
                ? AppTheme.accent.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.14),
            blurRadius: data.isHighlighted ? 28 : 18,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data.badge.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: data.isHighlighted ? AppTheme.mainGradient : null,
                color: data.isHighlighted ? null : AppTheme.surface,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                data.badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          if (data.badge.isNotEmpty) const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  data.icon,
                  color: AppTheme.accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  data.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              if (isCurrent)
                const Chip(
                  label: Text('Actual'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.audience,
            style: const TextStyle(
              color: AppTheme.textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data.price,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  data.period,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...data.benefits.map(
            (benefit) => _PlanBenefit(
              text: benefit,
              enabled: true,
            ),
          ),
          ...data.lockedBenefits.map(
            (benefit) => _PlanBenefit(
              text: benefit,
              enabled: false,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: isCurrent
                ? OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Plan actual'),
                  )
                : FilledButton.icon(
                    onPressed: isFree ? null : onSelect,
                    icon: Icon(
                      data.plan == CampusPlan.educator
                          ? Icons.school_rounded
                          : Icons.rocket_launch_rounded,
                    ),
                    label: Text(
                      data.plan == CampusPlan.educator
                          ? 'Obtener Educator'
                          : 'Actualizar a ${data.name}',
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlanBenefit extends StatelessWidget {
  final String text;
  final bool enabled;

  const _PlanBenefit({
    required this.text,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(
            enabled ? Icons.check_circle_rounded : Icons.lock_rounded,
            color: enabled ? AppTheme.success : AppTheme.textMuted,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: enabled ? AppTheme.textPrimary : AppTheme.textMuted,
                height: 1.35,
                fontWeight: enabled ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlansFooterNote extends StatelessWidget {
  const _PlansFooterNote();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Puedes cambiar o cancelar tu plan desde la configuración de tu cuenta. Los precios pueden variar según promociones de lanzamiento.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppTheme.textMuted,
        height: 1.45,
      ),
    );
  }
}

class _PlanUiData {
  final CampusPlan plan;
  final String name;
  final String audience;
  final String price;
  final String period;
  final String badge;
  final IconData icon;
  final bool isHighlighted;
  final List<String> benefits;
  final List<String> lockedBenefits;

  const _PlanUiData({
    required this.plan,
    required this.name,
    required this.audience,
    required this.price,
    required this.period,
    required this.badge,
    required this.icon,
    required this.isHighlighted,
    required this.benefits,
    required this.lockedBenefits,
  });
}
