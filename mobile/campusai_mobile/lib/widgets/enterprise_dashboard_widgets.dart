import 'package:flutter/material.dart';

import '../services/campus_intelligence/campus_intelligence_models.dart';
import '../services/campus_intelligence/enterprise_intelligence_models.dart';
import '../theme/app_theme.dart';
import 'section_card.dart';

class KnowledgeMapWidget extends StatelessWidget {
  final KnowledgeMap knowledgeMap;
  const KnowledgeMapWidget({super.key, required this.knowledgeMap});

  @override
  Widget build(BuildContext context) => _EnterpriseSection(
        title: 'Knowledge Map',
        icon: Icons.account_tree_rounded,
        child: _TextList(
          empty: 'Aún no hay conceptos suficientes para analizar.',
          values: knowledgeMap.tomorrowFocus,
          label: 'Mañana: ',
        ),
      );
}

class DigitalTwinWidget extends StatelessWidget {
  final StudentDigitalTwin twin;
  const DigitalTwinWidget({super.key, required this.twin});

  @override
  Widget build(BuildContext context) => _EnterpriseSection(
        title: 'Digital Twin',
        icon: Icons.person_search_rounded,
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          _MetricChip('Conocimiento', '${twin.knowledgeScore}%'),
          _MetricChip('Hábitos', '${twin.habitScore}%'),
          _MetricChip('Motivación', '${twin.motivationScore}%'),
          _MetricChip('Riesgo', twin.risk),
        ]),
      );
}

class StudyHealthWidget extends StatelessWidget {
  final StudentDigitalTwin twin;
  final ProductivitySnapshot productivity;
  const StudyHealthWidget(
      {super.key, required this.twin, required this.productivity});

  @override
  Widget build(BuildContext context) => _EnterpriseSection(
        title: 'Study Health',
        icon: Icons.health_and_safety_rounded,
        child: Text(
          twin.currentState.isEmpty
              ? productivity.efficiency.recommendation
              : twin.currentState,
          style: const TextStyle(color: AppTheme.textMuted, height: 1.35),
        ),
      );
}

class FocusScoreWidget extends StatelessWidget {
  final StudyFocusScore focus;
  const FocusScoreWidget({super.key, required this.focus});

  @override
  Widget build(BuildContext context) => _EnterpriseSection(
        title: 'Focus Score',
        icon: Icons.center_focus_strong_rounded,
        child: _BigScore(value: focus.score, label: focus.level),
      );
}

class GoalTrackerWidget extends StatelessWidget {
  final StudyGoals goals;
  const GoalTrackerWidget({super.key, required this.goals});

  @override
  Widget build(BuildContext context) => _EnterpriseSection(
        title: 'Goal Tracker',
        icon: Icons.flag_rounded,
        child: goals.goals.isEmpty
            ? const _MutedText('No hay metas disponibles todavía.')
            : Column(
                children: goals.goals
                    .take(2)
                    .map((goal) => _GoalRow(goal: goal))
                    .toList(),
              ),
      );
}

class ProductivityWidget extends StatelessWidget {
  final ProductivitySnapshot productivity;
  const ProductivityWidget({super.key, required this.productivity});

  @override
  Widget build(BuildContext context) => _EnterpriseSection(
        title: 'Productividad',
        icon: Icons.timer_rounded,
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          _MetricChip(
              'Deep work', '${productivity.deepWork.deepWorkMinutes} min'),
          _MetricChip('Eficiencia', '${productivity.efficiency.score}%'),
          _MetricChip('Distracción', '${productivity.distraction.score}%'),
        ]),
      );
}

class RiskMeterWidget extends StatelessWidget {
  final SuccessPrediction prediction;
  const RiskMeterWidget({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) => _EnterpriseSection(
        title: 'Risk Meter',
        icon: Icons.warning_amber_rounded,
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          _MetricChip('Abandono', '${prediction.dropoutRisk}%'),
          _MetricChip('Reprobación', '${prediction.failureRisk}%'),
        ]),
      );
}

class SuccessPredictionWidget extends StatelessWidget {
  final SuccessPrediction prediction;
  const SuccessPredictionWidget({super.key, required this.prediction});

  @override
  Widget build(BuildContext context) => _EnterpriseSection(
        title: 'Success Prediction',
        icon: Icons.insights_rounded,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _BigScore(
              value: prediction.passProbability,
              label: 'Probabilidad de aprobar'),
          const SizedBox(height: 8),
          Text(prediction.recommendation,
              style: const TextStyle(color: AppTheme.textMuted, height: 1.35)),
        ]),
      );
}

class SmartTimelineWidget extends StatelessWidget {
  final List<StudentTimelineItem> items;
  const SmartTimelineWidget({super.key, required this.items});

  @override
  Widget build(BuildContext context) => _EnterpriseSection(
        title: 'Smart Timeline',
        icon: Icons.timeline_rounded,
        child: items.isEmpty
            ? const _MutedText('Sin actividad reciente.')
            : Column(
                children: items
                    .take(3)
                    .map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.circle,
                                    size: 8, color: AppTheme.accent),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(item.title,
                                        style: const TextStyle(
                                            color: AppTheme.textPrimary))),
                              ]),
                        ))
                    .toList(),
              ),
      );
}

class LearningRoadmapWidget extends StatelessWidget {
  final LearningRoadmap roadmap;
  const LearningRoadmapWidget({super.key, required this.roadmap});

  @override
  Widget build(BuildContext context) => _EnterpriseSection(
        title: 'Learning Roadmap',
        icon: Icons.route_rounded,
        child: _TextList(
          empty: 'Aún no hay una ruta de aprendizaje.',
          values: roadmap.recommendations.map((item) => item.title).toList(),
        ),
      );
}

class _EnterpriseSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _EnterpriseSection(
      {required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) => SectionCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: AppTheme.accent),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800))
          ]),
          const SizedBox(height: 12),
          child,
        ]),
      );
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  const _MetricChip(this.label, this.value);
  @override
  Widget build(BuildContext context) => Chip(label: Text('$label: $value'));
}

class _BigScore extends StatelessWidget {
  final int value;
  final String label;
  const _BigScore({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Row(children: [
        Text('$value%',
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w900)),
        const SizedBox(width: 10),
        Expanded(
            child:
                Text(label, style: const TextStyle(color: AppTheme.textMuted))),
      ]);
}

class _TextList extends StatelessWidget {
  final List<String> values;
  final String empty;
  final String label;
  const _TextList({required this.values, required this.empty, this.label = ''});
  @override
  Widget build(BuildContext context) => values.isEmpty
      ? _MutedText(empty)
      : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: values
              .take(3)
              .map((value) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('$label$value',
                      style: const TextStyle(color: AppTheme.textMuted))))
              .toList());
}

class _GoalRow extends StatelessWidget {
  final SmartStudyGoal goal;
  const _GoalRow({required this.goal});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(goal.title,
              style: const TextStyle(
                  color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          LinearProgressIndicator(value: goal.progress / 100),
          const SizedBox(height: 4),
          Text('${goal.progress}% avance · ${goal.probability}% probabilidad',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
        ]),
      );
}

class _MutedText extends StatelessWidget {
  final String text;
  const _MutedText(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(color: AppTheme.textMuted));
}
