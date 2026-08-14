import 'package:flutter/material.dart';

import '../../config/app_plans.dart';
import '../../layout/responsive_layout.dart';
import '../../services/api_service.dart';
import '../../services/cloud_api_service.dart';
import '../../services/plan_guard_service.dart';
import '../../theme/app_theme.dart';
import '../section_card.dart';

class DashboardStats extends StatelessWidget {
  final int documentCount;
  final bool hasActiveDocument;

  const DashboardStats({
    super.key,
    required this.documentCount,
    required this.hasActiveDocument,
  });

  String _usedLimit(
    Map<String, dynamic> usage,
    String key,
    String limitKey,
  ) {
    final item = usage[key];

    if (item is! Map) {
      return '0 / -';
    }

    final used = item['used_today']?.toString() ?? '0';
    final limit = item[limitKey]?.toString() ?? '-';

    return '$used/$limit';
  }

  Map<String, dynamic> _usageFromResponse(
    Map<String, dynamic> data,
  ) {
    final rawUsage = data['usage'];

    if (rawUsage is Map<String, dynamic>) {
      return rawUsage;
    }

    if (rawUsage is Map) {
      return Map<String, dynamic>.from(rawUsage);
    }

    return {};
  }

  Map<String, dynamic> _totalsFromResponse(
    Map<String, dynamic> data,
  ) {
    final rawTotals = data['totals'];

    if (rawTotals is Map<String, dynamic>) {
      return rawTotals;
    }

    if (rawTotals is Map) {
      return Map<String, dynamic>.from(rawTotals);
    }

    return {};
  }

  int _intFromMap(
    Map<String, dynamic> data,
    String key,
  ) {
    final value = data[key];

    if (value is int) return value;

    if (value is num) return value.toInt();

    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<_DashboardMetrics> _loadMetrics() async {
    final currentPlan = const PlanGuardService().currentPlan;
    final currentPlanName = AppPlans.planNames[currentPlan] ?? 'Free';

    final usageFuture = ApiService.getUsageSummary();
    final flashcardsFuture =
        CloudApiService.getStudyResults(type: 'flashcards');
    final examsFuture = CloudApiService.getStudyResults(type: 'exam');
    final audiobooksFuture = CloudApiService.getAudiobooks();

    final results = await Future.wait<dynamic>([
      usageFuture,
      flashcardsFuture,
      examsFuture,
      audiobooksFuture,
    ]);

    final usageData = results[0] is Map<String, dynamic>
        ? results[0] as Map<String, dynamic>
        : <String, dynamic>{};

    final flashcards = results[1] is List ? results[1] as List : const [];
    final exams = results[2] is List ? results[2] as List : const [];
    final audiobooks = results[3] is List ? results[3] as List : const [];

    final backendPlan = usageData['plan']?.toString();
    final planName = backendPlan?.isNotEmpty == true
        ? backendPlan!.toUpperCase()
        : currentPlanName.toUpperCase();

    final usage = _usageFromResponse(usageData);
    final totals = _totalsFromResponse(usageData);
    final limits = AppPlans.limits[currentPlan]!;

    final pdfTotal = _intFromMap(totals, 'pdf_uploads');
    final chatTotal = _intFromMap(totals, 'chat_messages');
    final flashcardsTotal = _intFromMap(totals, 'flashcards_generated');
    final examsTotal = _intFromMap(totals, 'exams_generated');
    final exportsTotal = _intFromMap(totals, 'exports_generated');
    final audiobooksTotal = _intFromMap(totals, 'audiobooks_generated');

    final pdfUsage = usage.isEmpty
        ? '0/${limits.maxPdfUploadsPerDay}'
        : _usedLimit(
            usage,
            'pdf_uploads',
            'limit',
          );

    final chatUsage = usage.isEmpty
        ? '0/${limits.maxChatMessagesPerDay}'
        : _usedLimit(
            usage,
            'chat_messages',
            'limit',
          );

    return _DashboardMetrics(
      planName: planName,
      audiobooksCount:
          audiobooksTotal > 0 ? audiobooksTotal : audiobooks.length,
      flashcardsCount:
          flashcardsTotal > 0 ? flashcardsTotal : flashcards.length,
      examsCount: examsTotal > 0 ? examsTotal : exams.length,
      pdfUsage: pdfUsage,
      chatUsage: chatUsage,
      pdfTotal: pdfTotal,
      chatTotal: chatTotal,
      exportsTotal: exportsTotal,
      currentPlan: currentPlan,
    );
  }

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = 1;

    if (ResponsiveLayout.isTablet(context)) {
      crossAxisCount = 2;
    }

    if (ResponsiveLayout.isDesktop(context)) {
      crossAxisCount = 3;
    }

    final currentPlan = const PlanGuardService().currentPlan;
    final currentPlanName = AppPlans.planNames[currentPlan] ?? 'Free';

    return FutureBuilder<_DashboardMetrics>(
      future: _loadMetrics(),
      builder: (context, snapshot) {
        final metrics = snapshot.data ??
            _DashboardMetrics(
              planName: currentPlanName.toUpperCase(),
              audiobooksCount: 0,
              flashcardsCount: 0,
              examsCount: 0,
              pdfUsage: '-',
              chatUsage: '-',
              pdfTotal: documentCount,
              chatTotal: 0,
              exportsTotal: 0,
              currentPlan: currentPlan,
            );

        final isPremium = metrics.currentPlan != CampusPlan.free;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: ResponsiveLayout.isDesktop(context) ? 2.05 : 1.55,
          children: [
            _StatCard(
              title: 'Plan actual',
              value: metrics.planName,
              subtitle:
                  isPremium ? 'Funciones premium activas' : 'Plan inicial',
              icon: Icons.workspace_premium_rounded,
              color: isPremium ? AppTheme.accent : AppTheme.textMuted,
            ),
            _StatCard(
              title: 'Documentos',
              value: metrics.pdfTotal > 0
                  ? metrics.pdfTotal.toString()
                  : documentCount.toString(),
              subtitle: (metrics.pdfTotal > 0 || documentCount > 0)
                  ? 'PDFs procesados en total'
                  : 'Sube tu primer PDF',
              icon: Icons.picture_as_pdf_rounded,
              color: AppTheme.primary,
            ),
            _StatCard(
              title: 'AudioBooks',
              value: metrics.audiobooksCount.toString(),
              subtitle: 'Generados desde tus PDFs',
              icon: Icons.headphones_rounded,
              color: AppTheme.success,
            ),
            _StatCard(
              title: 'Flashcards',
              value: metrics.flashcardsCount.toString(),
              subtitle: 'Sets de estudio guardados',
              icon: Icons.style_rounded,
              color: AppTheme.secondary,
            ),
            _StatCard(
              title: 'Exámenes',
              value: metrics.examsCount.toString(),
              subtitle: 'Prácticas creadas con IA',
              icon: Icons.quiz_rounded,
              color: AppTheme.accent,
            ),
            _StatCard(
              title: 'Actividad total',
              value: '${metrics.chatTotal} chats',
              subtitle: '${metrics.exportsTotal} exportaciones',
              icon: Icons.monitor_heart_rounded,
              color: AppTheme.primary,
            ),
          ],
        );
      },
    );
  }
}

class _DashboardMetrics {
  final String planName;
  final int audiobooksCount;
  final int flashcardsCount;
  final int examsCount;
  final String pdfUsage;
  final String chatUsage;
  final int pdfTotal;
  final int chatTotal;
  final int exportsTotal;
  final CampusPlan currentPlan;

  const _DashboardMetrics({
    required this.planName,
    required this.audiobooksCount,
    required this.flashcardsCount,
    required this.examsCount,
    required this.pdfUsage,
    required this.chatUsage,
    required this.pdfTotal,
    required this.chatTotal,
    required this.exportsTotal,
    required this.currentPlan,
  });
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              icon,
              color: color,
              size: ResponsiveLayout.isMobile(context) ? 22 : 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
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
