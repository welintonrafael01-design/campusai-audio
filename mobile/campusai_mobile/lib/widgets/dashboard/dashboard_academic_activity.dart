import 'package:flutter/material.dart';

import '../../layout/responsive_layout.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../section_card.dart';

class DashboardAcademicActivity extends StatelessWidget {
  final int workspaceCount;
  final int workspaceDocumentCount;

  const DashboardAcademicActivity({
    super.key,
    required this.workspaceCount,
    required this.workspaceDocumentCount,
  });

  int _intFromMap(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic> _totalsFromResponse(Map<String, dynamic> data) {
    final totals = data['totals'];
    if (totals is Map<String, dynamic>) return totals;
    if (totals is Map) return Map<String, dynamic>.from(totals);
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);

    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.getUsageSummary(),
      builder: (context, snapshot) {
        final totals = _totalsFromResponse(snapshot.data ?? {});

        final pdfs = _intFromMap(totals, 'pdf_uploads');
        final chats = _intFromMap(totals, 'chat_messages');
        final flashcards = _intFromMap(totals, 'flashcards_generated');
        final exams = _intFromMap(totals, 'exams_generated');
        final exports = _intFromMap(totals, 'exports_generated');
        final audiobooks = _intFromMap(totals, 'audiobooks_generated');

        final generatedResources =
            flashcards + exams + exports + audiobooks;

        final cards = [
          _ActivityCard(
            title: 'Actividad Académica',
            icon: Icons.analytics_rounded,
            color: AppTheme.primary,
            lines: [
              'PDFs procesados: $pdfs',
              'Chats IA: $chats',
              'Flashcards: $flashcards',
              'Exámenes: $exams',
              'Audiolibros: $audiobooks',
              'Exportaciones: $exports',
            ],
          ),
          _ActivityCard(
            title: 'Workspaces',
            icon: Icons.hub_rounded,
            color: AppTheme.accent,
            lines: [
              'Workspaces activos: $workspaceCount',
              'Documentos conectados: $workspaceDocumentCount',
              workspaceCount > 0
                  ? 'Multi-PDF habilitado'
                  : 'Crea tu primer workspace',
            ],
          ),
          _ActivityCard(
            title: 'Productividad',
            icon: Icons.bolt_rounded,
            color: AppTheme.success,
            lines: [
              'Recursos IA generados: $generatedResources',
              'PDFs base: $pdfs',
              'Interacciones IA: $chats',
              'Salida académica: ${exports + exams + flashcards}',
            ],
          ),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Panel Educator',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: isMobile ? 24 : 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Resumen inteligente de tu actividad académica y productividad con IA.',
              style: TextStyle(
                color: AppTheme.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: isMobile ? 1 : 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: isMobile ? 1.55 : 1.05,
              children: cards,
            ),
          ],
        );
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> lines;

  const _ActivityCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: lines
                  .map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        '✓ $line',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
