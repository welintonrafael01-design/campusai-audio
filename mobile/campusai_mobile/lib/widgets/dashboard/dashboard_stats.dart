import 'package:flutter/material.dart';

import '../../config/app_plans.dart';
import '../../layout/responsive_layout.dart';
import '../../services/api_service.dart';
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

    return '$used / $limit';
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

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = 1;

    if (ResponsiveLayout.isTablet(context)) {
      crossAxisCount = 2;
    }

    if (ResponsiveLayout.isDesktop(context)) {
      crossAxisCount = 4;
    }

    final currentPlan = const PlanGuardService().currentPlan;
    final currentPlanName = AppPlans.planNames[currentPlan] ?? 'Free';
    final canUseVoice = const PlanGuardService().canUseVoiceOnboarding;

    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.getUsageSummary(),
      builder: (context, snapshot) {
        final usage = _usageFromResponse(snapshot.data ?? {});
        final backendPlan = snapshot.data?['plan']?.toString();
        final planName = backendPlan?.isNotEmpty == true
            ? backendPlan!.toUpperCase()
            : currentPlanName.toUpperCase();

        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        final limits = AppPlans.limits[currentPlan]!;
        final fallbackPdfs = '0 / ${limits.maxPdfUploadsPerDay}';
        final fallbackChats = '0 / ${limits.maxChatMessagesPerDay}';

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: ResponsiveLayout.isDesktop(context) ? 1.8 : 1.5,
          children: [
            _StatCard(
              title: 'Plan actual',
              value: isLoading ? currentPlanName.toUpperCase() : planName,
              icon: Icons.workspace_premium_rounded,
              color: currentPlan == CampusPlan.free
                  ? AppTheme.textMuted
                  : AppTheme.accent,
            ),
            _StatCard(
              title: 'PDFs hoy',
              value: isLoading || usage.isEmpty
                  ? fallbackPdfs
                  : _usedLimit(
                      usage,
                      'pdf_uploads',
                      'limit',
                    ),
              icon: Icons.upload_file_rounded,
              color: AppTheme.primary,
            ),
            _StatCard(
              title: 'Chats hoy',
              value: isLoading || usage.isEmpty
                  ? fallbackChats
                  : _usedLimit(
                      usage,
                      'chat_messages',
                      'limit',
                    ),
              icon: Icons.chat_bubble_rounded,
              color: AppTheme.secondary,
            ),
            _StatCard(
              title: 'Audio y voz',
              value: canUseVoice ? 'Premium activo' : 'Bloqueado',
              icon: canUseVoice ? Icons.graphic_eq_rounded : Icons.lock_rounded,
              color: canUseVoice ? AppTheme.success : AppTheme.textMuted,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
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
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    maxLines: 1,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
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
