/// Prioridad operativa de una acción autónoma.
enum AutonomousActionPriority { critical, high, normal, low }

/// Estado persistido de una acción autónoma.
enum AutonomousActionStatus {
  pending,
  inProgress,
  completed,
  dismissed,
  failed
}

/// Tipos de acciones seguras soportadas por RC3.
abstract final class AutonomousActionTypes {
  static const studyNow = 'study_now';
  static const reviewWeakness = 'review_weakness';
  static const continueAudiobook = 'continue_audiobook';
  static const takeQuiz = 'take_quiz';
  static const reviewFlashcards = 'review_flashcards';
  static const talkToTutor = 'talk_to_tutor';
  static const followSmartPlan = 'follow_smart_plan';
  static const exploreMarketplaceResource = 'explore_marketplace_resource';
  static const maintainStreak = 'maintain_streak';
  static const rest = 'rest';
  static const teacherIntervention = 'teacher_intervention';
  static const institutionAlert = 'institution_alert';
}

/// Acción local, explicable y no destructiva sugerida al estudiante.
class AutonomousAction {
  final String id;
  final String type;
  final String title;
  final String reason;
  final String actionLabel;
  final String targetId;
  final AutonomousActionPriority priority;
  final AutonomousActionStatus status;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AutonomousAction({
    required this.id,
    required this.type,
    required this.title,
    required this.reason,
    required this.actionLabel,
    required this.createdAt,
    required this.updatedAt,
    this.targetId = '',
    this.priority = AutonomousActionPriority.normal,
    this.status = AutonomousActionStatus.pending,
    this.metadata = const {},
  });

  factory AutonomousAction.fromJson(Map<String, dynamic> json) {
    return AutonomousAction(
      id: _text(json['id']),
      type: _text(json['type']),
      title: _text(json['title']),
      reason: _text(json['reason']),
      actionLabel: _text(json['action_label'], 'Comenzar'),
      targetId: _text(json['target_id']),
      priority: _enumValue(
        AutonomousActionPriority.values,
        json['priority'],
        AutonomousActionPriority.normal,
      ),
      status: _enumValue(
        AutonomousActionStatus.values,
        json['status'],
        AutonomousActionStatus.pending,
      ),
      metadata: _map(json['metadata']),
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }

  AutonomousAction copyWith({
    AutonomousActionStatus? status,
    DateTime? updatedAt,
  }) {
    return AutonomousAction(
      id: id,
      type: type,
      title: title,
      reason: reason,
      actionLabel: actionLabel,
      targetId: targetId,
      priority: priority,
      status: status ?? this.status,
      metadata: metadata,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'reason': reason,
        'action_label': actionLabel,
        'target_id': targetId,
        'priority': priority.name,
        'status': status.name,
        'metadata': metadata,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

/// Plan ordenado de acciones generado para un único snapshot del estudiante.
class AutonomousActionPlan {
  final String id;
  final DateTime generatedAt;
  final List<AutonomousAction> actions;

  const AutonomousActionPlan({
    required this.id,
    required this.generatedAt,
    this.actions = const [],
  });

  factory AutonomousActionPlan.empty() => AutonomousActionPlan(
        id: 'autonomous_action_plan_empty',
        generatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

  factory AutonomousActionPlan.fromJson(Map<String, dynamic> json) {
    return AutonomousActionPlan(
      id: _text(json['id'], 'autonomous_action_plan_latest'),
      generatedAt: _date(json['generated_at']),
      actions: _maps(json['actions']).map(AutonomousAction.fromJson).toList(),
    );
  }

  List<AutonomousAction> get pendingActions => actions
      .where((action) => action.status == AutonomousActionStatus.pending)
      .toList();

  AutonomousActionPlan copyWith({List<AutonomousAction>? actions}) {
    return AutonomousActionPlan(
      id: id,
      generatedAt: generatedAt,
      actions: actions ?? this.actions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'generated_at': generatedAt.toIso8601String(),
        'actions': actions.map((action) => action.toJson()).toList(),
      };
}

/// Resultado auditable de ejecutar o descartar una acción.
class AutonomousActionResult {
  final String actionId;
  final AutonomousActionStatus status;
  final String message;
  final String route;
  final DateTime executedAt;

  const AutonomousActionResult({
    required this.actionId,
    required this.status,
    required this.message,
    required this.executedAt,
    this.route = '',
  });

  factory AutonomousActionResult.fromJson(Map<String, dynamic> json) {
    return AutonomousActionResult(
      actionId: _text(json['action_id']),
      status: _enumValue(
        AutonomousActionStatus.values,
        json['status'],
        AutonomousActionStatus.failed,
      ),
      message: _text(json['message']),
      route: _text(json['route']),
      executedAt: _date(json['executed_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'action_id': actionId,
        'status': status.name,
        'message': message,
        'route': route,
        'executed_at': executedAt.toIso8601String(),
      };
}

T _enumValue<T extends Enum>(List<T> values, dynamic raw, T fallback) {
  final name = raw?.toString().trim() ?? '';
  return values.firstWhere((value) => value.name == name,
      orElse: () => fallback);
}

String _text(dynamic value, [String fallback = '']) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

DateTime _date(dynamic value) =>
    DateTime.tryParse(_text(value)) ?? DateTime.fromMillisecondsSinceEpoch(0);

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<Map<String, dynamic>> _maps(dynamic value) => value is List
    ? value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList()
    : <Map<String, dynamic>>[];
