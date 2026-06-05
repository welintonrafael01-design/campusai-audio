import 'package:flutter/material.dart';

import '../config/app_plans.dart';
import '../services/billing_service.dart';
import '../theme/app_theme.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

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
            'No se pudo iniciar el pago de $planName: $error',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = AppPlans.currentPlan;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planes StudyBook AI'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Elige el plan que se adapte a tu forma de estudiar o enseñar.',
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
                          const Chip(
                            label: Text('Plan actual'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _PlanFeature(
                      label: 'PDFs por día',
                      value: limits.maxPdfUploadsPerDay.toString(),
                    ),
                    _PlanFeature(
                      label: 'Chats por día',
                      value: limits.maxChatMessagesPerDay.toString(),
                    ),
                    _PlanFeature(
                      label: 'Flashcards por PDF',
                      value: limits.maxFlashcardsPerPdf.toString(),
                    ),
                    _PlanFeature(
                      label: 'Preguntas de examen por PDF',
                      value: limits.maxExamQuestionsPerPdf.toString(),
                    ),
                    const SizedBox(height: 12),
                    _PlanFeature(
                      label: 'Exportar PDF',
                      value: limits.canExportPdf ? 'Sí' : 'No',
                    ),
                    _PlanFeature(
                      label: 'Exportar DOCX',
                      value: limits.canExportDocx ? 'Sí' : 'No',
                    ),
                    _PlanFeature(
                      label: 'Exportar PPTX',
                      value: limits.canExportPptx ? 'Sí' : 'No',
                    ),
                    _PlanFeature(
                      label: 'Analytics avanzado',
                      value: limits.canUseAdvancedAnalytics ? 'Sí' : 'No',
                    ),
                    _PlanFeature(
                      label: 'Herramientas profesor',
                      value: limits.canUseEducatorTools ? 'Sí' : 'No',
                    ),
                    _PlanFeature(
                      label: 'Voz guiada',
                      value: limits.canUseVoiceOnboarding ? 'Sí' : 'No',
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: isCurrent
                          ? OutlinedButton.icon(
                              onPressed: null,
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('Plan actual'),
                            )
                          : FilledButton.icon(
                              onPressed: () {
                                _startCheckout(context, plan);
                              },
                              icon: const Icon(
                                Icons.workspace_premium_rounded,
                              ),
                              label: Text('Actualizar a $planName'),
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
