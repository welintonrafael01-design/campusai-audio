import 'campus_intelligence/enterprise_result_repository.dart';
import 'workflow_engine.dart';

class DecisionContext {
  final int risk;
  final int engagement;
  final int goals;
  final int availableMinutes;
  final int fatigue;
  final int plan;
  final int history;
  final int recommendations;
  final int marketplace;
  final int institution;

  const DecisionContext({
    this.risk = 0,
    this.engagement = 0,
    this.goals = 0,
    this.availableMinutes = 0,
    this.fatigue = 0,
    this.plan = 0,
    this.history = 0,
    this.recommendations = 0,
    this.marketplace = 0,
    this.institution = 0,
  });

  Map<String, dynamic> toJson() => {
        'risk': risk,
        'engagement': engagement,
        'goals': goals,
        'available_minutes': availableMinutes,
        'fatigue': fatigue,
        'plan': plan,
        'history': history,
        'recommendations': recommendations,
        'marketplace': marketplace,
        'institution': institution,
      };
}

class DecisionPolicy {
  final String id;
  final String title;
  final Map<String, double> weights;

  const DecisionPolicy({
    this.id = 'default',
    this.title = 'Default policy',
    this.weights = const {
      'risk': 1.5,
      'engagement': 1,
      'goals': 1,
      'available_minutes': .5,
      'fatigue': -1,
      'plan': 1,
      'history': .5,
      'recommendations': 1,
      'marketplace': .4,
      'institution': .8,
    },
  });
}

class DecisionScore {
  final String action;
  final double score;
  final List<DecisionReason> reasons;

  const DecisionScore({
    required this.action,
    required this.score,
    this.reasons = const [],
  });

  Map<String, dynamic> toJson() => {
        'action': action,
        'score': score,
        'reasons': reasons.map((reason) => reason.toJson()).toList(),
      };
}

class DecisionReason {
  final String factor;
  final String message;
  final double weight;

  const DecisionReason({
    required this.factor,
    required this.message,
    required this.weight,
  });

  Map<String, dynamic> toJson() =>
      {'factor': factor, 'message': message, 'weight': weight};
}

class DecisionEngine {
  final EnterpriseResultRepository repository;
  final DecisionPolicy policy;

  const DecisionEngine({
    this.repository = const EnterpriseResultRepository(),
    this.policy = const DecisionPolicy(),
  });

  Future<DecisionScore> decide(DecisionContext context) async {
    final reasons = <DecisionReason>[
      if (context.risk >= 60)
        DecisionReason(
            factor: 'risk',
            message: 'Priorizar intervención por riesgo alto.',
            weight: policy.weights['risk'] ?? 1),
      if (context.fatigue >= 70)
        DecisionReason(
            factor: 'fatigue',
            message: 'Reducir carga por fatiga elevada.',
            weight: policy.weights['fatigue'] ?? -1),
      if (context.availableMinutes >= 30)
        DecisionReason(
            factor: 'available_minutes',
            message: 'Hay tiempo suficiente para sesión guiada.',
            weight: policy.weights['available_minutes'] ?? .5),
      if (context.recommendations > 0)
        DecisionReason(
            factor: 'recommendations',
            message: 'Existen recomendaciones activas.',
            weight: policy.weights['recommendations'] ?? 1),
    ];
    final score = _weighted(context);
    final action = context.risk >= 60
        ? 'intervention'
        : context.fatigue >= 70
            ? 'light_review'
            : score >= 70
                ? 'advance'
                : 'reinforce';
    final decision =
        DecisionScore(action: action, score: score, reasons: reasons);
    await repository.save(
      documentId: 'decision_${DateTime.now().millisecondsSinceEpoch}',
      type: EnterpriseStudyResultTypes.decisionHistory,
      payload: decision.toJson(),
    );
    return decision;
  }

  double _weighted(DecisionContext c) {
    final values = c.toJson();
    var total = 0.0;
    var weightTotal = 0.0;
    for (final entry in policy.weights.entries) {
      final value = values[entry.key];
      if (value is num) {
        total += value * entry.value;
        weightTotal += entry.value.abs();
      }
    }
    if (weightTotal == 0) return 0;
    return (total / weightTotal).clamp(0, 100).toDouble();
  }
}
