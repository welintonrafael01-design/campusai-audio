import 'package:flutter/material.dart';

import '../services/performance_readiness/performance_readiness_models.dart';
import '../services/qa/qa_models.dart';
import '../services/release_candidate/rc_models.dart';
import '../services/security/security_scan_service.dart';
import '../theme/app_theme.dart';
import 'section_card.dart';

class RcScoreCard extends StatelessWidget {
  final ReleaseCandidateReport report;
  const RcScoreCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) => _RcCard(
        title: 'RC Score',
        icon: Icons.verified_rounded,
        body: '${report.score}% · ${report.version}',
        progress: report.score,
      );
}

class QualityGateCard extends StatelessWidget {
  final List<RcQualityGate> gates;
  const QualityGateCard({super.key, required this.gates});

  @override
  Widget build(BuildContext context) => _RcCard(
        title: 'Quality Gates',
        icon: Icons.fact_check_rounded,
        body: gates.isEmpty
            ? 'Sin gates definidos'
            : gates
                .take(4)
                .map((gate) => '${gate.passed ? 'OK' : 'PEND'} ${gate.name}')
                .join('\n'),
      );
}

class ModuleStatusCard extends StatelessWidget {
  final List<RcModuleStatus> modules;
  const ModuleStatusCard({super.key, required this.modules});

  @override
  Widget build(BuildContext context) => _RcCard(
        title: 'Module Status',
        icon: Icons.dashboard_customize_rounded,
        body: modules.isEmpty
            ? 'Sin módulos'
            : modules
                .take(5)
                .map((module) => '${module.module}: ${module.status}')
                .join('\n'),
      );
}

class QaScenarioCard extends StatelessWidget {
  final List<QaScenario> scenarios;
  const QaScenarioCard({super.key, required this.scenarios});

  @override
  Widget build(BuildContext context) => _RcCard(
        title: 'QA Scenarios',
        icon: Icons.playlist_add_check_rounded,
        body: '${scenarios.length} escenarios críticos definidos',
      );
}

class RiskCard extends StatelessWidget {
  final List<RcRisk> risks;
  const RiskCard({super.key, required this.risks});

  @override
  Widget build(BuildContext context) => _RcCard(
        title: 'Risks',
        icon: Icons.warning_amber_rounded,
        body: risks.isEmpty
            ? 'Sin riesgos abiertos'
            : risks
                .take(4)
                .map((risk) => '${risk.area}: ${risk.severity}')
                .join('\n'),
      );
}

class SecurityScanCard extends StatelessWidget {
  final SecurityScanReport report;
  const SecurityScanCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) => _RcCard(
        title: 'Security Scan',
        icon: Icons.security_rounded,
        body: report.passed
            ? 'Sin hallazgos críticos'
            : '${report.findings.length} hallazgos requieren revisión',
      );
}

class PerformanceHealthCard extends StatelessWidget {
  final PerformanceReadinessReport report;
  const PerformanceHealthCard({super.key, required this.report});

  @override
  Widget build(BuildContext context) => _RcCard(
        title: 'Performance Health',
        icon: Icons.speed_rounded,
        body: '${report.score}% · ${report.findings.length} hallazgos',
        progress: report.score,
      );
}

class ReleaseNotesCard extends StatelessWidget {
  final List<String> highlights;
  const ReleaseNotesCard({super.key, required this.highlights});

  @override
  Widget build(BuildContext context) => _RcCard(
        title: 'Release Notes',
        icon: Icons.article_rounded,
        body: highlights.isEmpty ? 'Sin notas' : highlights.take(4).join('\n'),
      );
}

class _RcCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String body;
  final int? progress;

  const _RcCard({
    required this.title,
    required this.icon,
    required this.body,
    this.progress,
  });

  @override
  Widget build(BuildContext context) => SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (progress != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: progress!.clamp(0, 100) / 100),
            ],
            const SizedBox(height: 10),
            Text(
              body,
              style: const TextStyle(color: AppTheme.textMuted, height: 1.35),
            ),
          ],
        ),
      );
}
