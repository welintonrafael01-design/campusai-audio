import 'package:flutter/material.dart';

import '../config/app_plans.dart';

class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final current = AppPlans.currentPlan;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planes CampusAI'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: CampusPlan.values.map((plan) {
          final limits = AppPlans.limits[plan]!;
          final isCurrent = plan == current;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        AppPlans.planNames[plan]!,
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
                  Text('PDFs por día: ${limits.maxPdfUploadsPerDay}'),
                  Text('Chats por día: ${limits.maxChatMessagesPerDay}'),
                  Text('Flashcards por PDF: ${limits.maxFlashcardsPerPdf}'),
                  Text('Preguntas de examen por PDF: ${limits.maxExamQuestionsPerPdf}'),
                  const SizedBox(height: 12),
                  Text('Exportar PDF: ${limits.canExportPdf ? "Sí" : "No"}'),
                  Text('Exportar DOCX: ${limits.canExportDocx ? "Sí" : "No"}'),
                  Text('Exportar PPTX: ${limits.canExportPptx ? "Sí" : "No"}'),
                  Text('Analytics avanzado: ${limits.canUseAdvancedAnalytics ? "Sí" : "No"}'),
                  Text('Herramientas profesor: ${limits.canUseEducatorTools ? "Sí" : "No"}'),
                  Text('Voz guiada: ${limits.canUseVoiceOnboarding ? "Sí" : "No"}'),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
