import 'package:flutter/material.dart';

import '../services/campus_intelligence/campus_intelligence_models.dart';
import '../services/campus_intelligence/enterprise_intelligence_models.dart';
import '../theme/app_theme.dart';
import 'section_card.dart';

class EnterpriseDashboardTile extends StatelessWidget {
  final String title;
  final List<String> lines;
  final int? progress;

  const EnterpriseDashboardTile({
    super.key,
    required this.title,
    this.lines = const [],
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            if (progress != null) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(value: progress!.clamp(0, 100) / 100),
            ],
            if (lines.isNotEmpty) const SizedBox(height: 12),
            for (final line in lines.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(line, style: theme.textTheme.bodyMedium),
              ),
          ],
        ),
      ),
    );
  }
}

class TodaysPlanTile extends EnterpriseDashboardTile {
  const TodaysPlanTile({super.key, required super.lines})
      : super(title: "Today's Plan");
}

class InstitutionAlertsTile extends EnterpriseDashboardTile {
  const InstitutionAlertsTile({super.key, required super.lines})
      : super(title: 'Institution Alerts');
}

class MarketplaceSuggestionsTile extends EnterpriseDashboardTile {
  const MarketplaceSuggestionsTile({super.key, required super.lines})
      : super(title: 'Marketplace Suggestions');
}

class CreatorActivityTile extends EnterpriseDashboardTile {
  const CreatorActivityTile({super.key, required super.lines})
      : super(title: 'Creator Activity');
}

class AiDecisionsTile extends EnterpriseDashboardTile {
  const AiDecisionsTile({super.key, required super.lines})
      : super(title: 'AI Decisions');
}

class WorkflowStatusTile extends EnterpriseDashboardTile {
  const WorkflowStatusTile({super.key, required super.lines})
      : super(title: 'Workflow Status');
}

class PredictionTimelineTile extends EnterpriseDashboardTile {
  const PredictionTimelineTile({super.key, required super.lines})
      : super(title: 'Prediction Timeline');
}

class GoalProgressTile extends EnterpriseDashboardTile {
  const GoalProgressTile({super.key, required int progress})
      : super(title: 'Goal Progress', progress: progress);
}

class KnowledgeCoverageTile extends EnterpriseDashboardTile {
  const KnowledgeCoverageTile({super.key, required int progress})
      : super(title: 'Knowledge Coverage', progress: progress);
}

class KnowledgeMapWidget extends StatelessWidget {
  final KnowledgeMap knowledgeMap;
  const KnowledgeMapWidget({super.key, required this.knowledgeMap});

  @override
  Widget build(BuildContext context) => _EnterpriseCard(
        title: 'Knowledge Map',
        icon: Icons.hub_rounded,
        body: knowledgeMap.concepts.isEmpty
            ? 'Sin conceptos detectados'
            : knowledgeMap.concepts
                .take(3)
                .map((item) => '${item.title}: ${item.mastery}%')
                .join('\n'),
      );
}

class LearningRoadmapWidget extends StatelessWidget {
  final LearningRoadmap roadmap;
  const LearningRoadmapWidget({super.key, required this.roadmap});

  @override
  Widget build(BuildContext context) => _EnterpriseCard(
        title: 'Learning Roadmap',
        icon: Icons.route_rounded,
        body: roadmap.nodes.isEmpty
            ? 'Sin nodos de aprendizaje'
            : roadmap.nodes
                .take(3)
                .map((item) => '${item.title}: ${item.status}')
                .join('\n'),
      );
}

class DigitalTwinWidget extends StatelessWidget {
  final StudentDigitalTwin twin;
  const DigitalTwinWidget({super.key, required this.twin});

  @override
  Widget build(BuildContext context) => _EnterpriseCard(
        title: 'Digital Twin',
        icon: Icons.account_tree_rounded,
        body:
            'Conocimiento ${twin.knowledgeScore}% · Hábitos ${twin.habitScore}%\nEstado: ${twin.currentState}',
      );
}

class StudyHealthWidget extends StatelessWidget {
  final StudentDigitalTwin twin;
  final ProductivitySnapshot productivity;
  const StudyHealthWidget({
    super.key,
    required this.twin,
    required this.productivity,
  });

  @override
  Widget build(BuildContext context) => _EnterpriseCard(
        title: 'Study Health',
        icon: Icons.health_and_safety_rounded,
        body:
            'Riesgo: ${twin.risk}\nEficiencia: ${productivity.efficiency.score}%',
      );
}

class FocusScoreWidget extends StatelessWidget {
  final StudyFocusScore focus;
  const FocusScoreWidget({super.key, required this.focus});

  @override
  Widget build(BuildContext context) => _EnterpriseCard(
        title: 'Focus Score',
        icon: Icons.center_focus_strong_rounded,
        body: '${focus.score}% · ${focus.level}',
      );
}

class ProductivityWidget extends StatelessWidget {
  final ProductivitySnapshot productivity;
  const ProductivityWidget({super.key, required this.productivity});

  @override
  Widget build(BuildContext context) => _EnterpriseCard(
        title: 'Productivity',
        icon: Icons.speed_rounded,
        body:
            'Deep work: ${productivity.deepWork.deepWorkMinutes} min\nConsistencia: ${productivity.consistency.score}%',
      );
}

class GoalTrackerWidget extends StatelessWidget {
  final StudyGoals goals;
  const GoalTrackerWidget({super.key, required this.goals});

  @override
  Widget build(BuildContext context) => _EnterpriseCard(
        title: 'Goal Tracker',
        icon: Icons.flag_circle_rounded,
        body: goals.goals.isEmpty
            ? 'Sin objetivos activos'
            : goals.goals
                .take(3)
                .map((goal) => '${goal.title}: ${goal.progress}%')
                .join('\n'),
      );
}

class SuccessPredictionWidget extends StatelessWidget {
  final SuccessPrediction prediction;
  const SuccessPredictionWidget({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) => _EnterpriseCard(
        title: 'Success Prediction',
        icon: Icons.insights_rounded,
        body:
            'Aprobación ${prediction.passProbability}% · Riesgo ${prediction.failureRisk}%\n${prediction.recommendation}',
      );
}

class RiskMeterWidget extends StatelessWidget {
  final SuccessPrediction prediction;
  const RiskMeterWidget({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) => _EnterpriseCard(
        title: 'Risk Meter',
        icon: Icons.warning_rounded,
        body:
            'Deserción ${prediction.dropoutRisk}% · Reprobación ${prediction.failureRisk}%',
      );
}

class SmartTimelineWidget extends StatelessWidget {
  final List<StudentTimelineItem> items;
  const SmartTimelineWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context) => _EnterpriseCard(
        title: 'Smart Timeline',
        icon: Icons.timeline_rounded,
        body: items.isEmpty
            ? 'Sin eventos recientes'
            : items.take(3).map((item) => item.title).join('\n'),
      );
}

class _EnterpriseCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String body;

  const _EnterpriseCard({
    required this.title,
    required this.icon,
    required this.body,
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
            const SizedBox(height: 10),
            Text(
              body,
              style: const TextStyle(color: AppTheme.textMuted, height: 1.35),
            ),
          ],
        ),
      );
}
