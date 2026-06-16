import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class DashboardHero extends StatelessWidget {
  final int documentCount;
  final bool hasActiveDocument;
  final String userName;
  final String planName;
  final String activeFileName;
  final VoidCallback? onContinueStudy;
  final VoidCallback? onUploadPdf;

  const DashboardHero({
    super.key,
    required this.documentCount,
    required this.hasActiveDocument,
    required this.userName,
    required this.planName,
    required this.activeFileName,
    this.onContinueStudy,
    this.onUploadPdf,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: AppTheme.mainGradient,
        borderRadius: BorderRadius.circular(34),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.28),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 560;
          final cleanName = userName.trim().isEmpty ? 'Estudiante' : userName;
          final cleanPlan = planName.trim().isEmpty ? 'Free' : planName;
          final activeDoc = activeFileName.trim();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: isMobile
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  Expanded(
                    flex: isMobile ? 0 : 1,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: isMobile ? 26 : 32,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _PlanBadge(planName: cleanPlan),
                                  const _HeroPill(
                                    icon: Icons.verified_rounded,
                                    text: 'IA Académica',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Hola, $cleanName',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: isMobile ? 25 : 34,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.05,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                hasActiveDocument && activeDoc.isNotEmpty
                                    ? 'Continúa estudiando: $activeDoc'
                                    : 'Convierte tus PDFs en resúmenes, audiolibros, flashcards, exámenes y conversaciones inteligentes.',
                                maxLines: isMobile ? 3 : 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                  height: 1.45,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: isMobile ? 18 : 0,
                    width: isMobile ? 0 : 18,
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: isMobile ? WrapAlignment.start : WrapAlignment.end,
                    children: [
                      FilledButton.icon(
                        onPressed:
                            hasActiveDocument ? onContinueStudy : onUploadPdf,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                        ),
                        icon: Icon(
                          hasActiveDocument
                              ? Icons.play_arrow_rounded
                              : Icons.upload_file_rounded,
                        ),
                        label: Text(
                          hasActiveDocument
                              ? 'Continuar estudiando'
                              : 'Subir PDF',
                        ),
                      ),
                      IconButton(
                        tooltip: 'Mi Cuenta',
                        onPressed: () => context.pushNamed('settings'),
                        style: IconButton.styleFrom(
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.16),
                        ),
                        icon: const Icon(
                          Icons.account_circle_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _HeroPill(
                    icon: Icons.upload_file_rounded,
                    text: 'PDF → IA',
                  ),
                  _HeroPill(
                    icon: Icons.headphones_rounded,
                    text: 'Audio',
                  ),
                  _HeroPill(
                    icon: Icons.quiz_rounded,
                    text: 'Exámenes',
                  ),
                  _HeroPill(
                    icon: Icons.chat_bubble_rounded,
                    text: 'Chat RAG',
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Flex(
                direction: isMobile ? Axis.vertical : Axis.horizontal,
                children: [
                  Expanded(
                    flex: isMobile ? 0 : 1,
                    child: _HeroMetric(
                      label: l10n.docsShort,
                      value: documentCount.toString(),
                      icon: Icons.folder_copy_rounded,
                    ),
                  ),
                  SizedBox(
                    width: isMobile ? 0 : 12,
                    height: isMobile ? 12 : 0,
                  ),
                  Expanded(
                    flex: isMobile ? 0 : 1,
                    child: _HeroMetric(
                      label: 'Estado RAG',
                      value: hasActiveDocument ? l10n.ragActive : l10n.ragReady,
                      icon: Icons.hub_rounded,
                    ),
                  ),
                  SizedBox(
                    width: isMobile ? 0 : 12,
                    height: isMobile ? 12 : 0,
                  ),
                  Expanded(
                    flex: isMobile ? 0 : 1,
                    child: _HeroMetric(
                      label: 'Plan',
                      value: cleanPlan,
                      icon: Icons.workspace_premium_rounded,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final String planName;

  const _PlanBadge({
    required this.planName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        planName.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HeroPill({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _HeroMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $value',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
