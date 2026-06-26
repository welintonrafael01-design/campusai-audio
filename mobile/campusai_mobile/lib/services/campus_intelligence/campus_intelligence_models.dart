class CampusIntelligenceSnapshot {
  final DateTime generatedAt;
  final int studentScore;
  final String academicRisk;
  final int engagementScore;
  final int masteryScore;
  final int consistencyScore;
  final String recommendedNextAction;
  final List<String> alerts;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<CampusPrediction> predictions;
  final List<LearningGraphNode> learningGraph;
  final List<AdaptiveLearningAction> adaptivePlan;
  final List<SmartNotification> notifications;

  const CampusIntelligenceSnapshot({
    required this.generatedAt,
    this.studentScore = 0,
    this.academicRisk = 'Sin datos',
    this.engagementScore = 0,
    this.masteryScore = 0,
    this.consistencyScore = 0,
    this.recommendedNextAction = 'Continúa con tu próxima actividad.',
    this.alerts = const [],
    this.strengths = const [],
    this.weaknesses = const [],
    this.predictions = const [],
    this.learningGraph = const [],
    this.adaptivePlan = const [],
    this.notifications = const [],
  });

  factory CampusIntelligenceSnapshot.empty() {
    return CampusIntelligenceSnapshot(
      generatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory CampusIntelligenceSnapshot.fromJson(Map<String, dynamic> json) {
    return CampusIntelligenceSnapshot(
      generatedAt: DateTime.tryParse(json['generated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      studentScore: _intFrom(json['student_score']),
      academicRisk: json['academic_risk']?.toString() ?? 'Sin datos',
      engagementScore: _intFrom(json['engagement_score']),
      masteryScore: _intFrom(json['mastery_score']),
      consistencyScore: _intFrom(json['consistency_score']),
      recommendedNextAction: json['recommended_next_action']?.toString() ??
          'Continúa con tu próxima actividad.',
      alerts: _stringList(json['alerts']),
      strengths: _stringList(json['strengths']),
      weaknesses: _stringList(json['weaknesses']),
      predictions: _mapList(json['predictions'])
          .map((item) => CampusPrediction.fromJson(item))
          .toList(),
      learningGraph: _mapList(json['learning_graph'])
          .map((item) => LearningGraphNode.fromJson(item))
          .toList(),
      adaptivePlan: _mapList(json['adaptive_plan'])
          .map((item) => AdaptiveLearningAction.fromJson(item))
          .toList(),
      notifications: _mapList(json['notifications'])
          .map((item) => SmartNotification.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'generated_at': generatedAt.toIso8601String(),
      'student_score': studentScore,
      'academic_risk': academicRisk,
      'engagement_score': engagementScore,
      'mastery_score': masteryScore,
      'consistency_score': consistencyScore,
      'recommended_next_action': recommendedNextAction,
      'alerts': alerts,
      'strengths': strengths,
      'weaknesses': weaknesses,
      'predictions': predictions.map((item) => item.toJson()).toList(),
      'learning_graph': learningGraph.map((item) => item.toJson()).toList(),
      'adaptive_plan': adaptivePlan.map((item) => item.toJson()).toList(),
      'notifications': notifications.map((item) => item.toJson()).toList(),
    };
  }
}

class CampusPrediction {
  final String key;
  final String title;
  final String description;
  final double probability;
  final String severity;
  final String recommendation;
  final String source;

  const CampusPrediction({
    this.key = '',
    this.title = '',
    this.description = '',
    this.probability = 0,
    this.severity = 'info',
    this.recommendation = '',
    this.source = 'rules',
  });

  factory CampusPrediction.fromJson(Map<String, dynamic> json) {
    return CampusPrediction(
      key: json['key']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      probability: _doubleFrom(json['probability']),
      severity: json['severity']?.toString() ?? 'info',
      recommendation: json['recommendation']?.toString() ?? '',
      source: json['source']?.toString() ?? 'rules',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'title': title,
      'description': description,
      'probability': probability,
      'severity': severity,
      'recommendation': recommendation,
      'source': source,
    };
  }
}

class LearningGraphNode {
  final String id;
  final String title;
  final String type;
  final int mastery;
  final String status;
  final List<String> dependencies;
  final List<String> relatedCompetencies;

  const LearningGraphNode({
    this.id = '',
    this.title = '',
    this.type = 'node',
    this.mastery = 0,
    this.status = 'pending',
    this.dependencies = const [],
    this.relatedCompetencies = const [],
  });

  factory LearningGraphNode.fromJson(Map<String, dynamic> json) {
    return LearningGraphNode(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      type: json['type']?.toString() ?? 'node',
      mastery: _intFrom(json['mastery']),
      status: json['status']?.toString() ?? 'pending',
      dependencies: _stringList(json['dependencies']),
      relatedCompetencies: _stringList(json['related_competencies']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'mastery': mastery,
      'status': status,
      'dependencies': dependencies,
      'related_competencies': relatedCompetencies,
    };
  }
}

class AdaptiveLearningAction {
  final String actionId;
  final String title;
  final String description;
  final String type;
  final int priority;
  final String targetId;
  final int estimatedMinutes;
  final String reason;

  const AdaptiveLearningAction({
    this.actionId = '',
    this.title = '',
    this.description = '',
    this.type = 'general',
    this.priority = 3,
    this.targetId = '',
    this.estimatedMinutes = 10,
    this.reason = '',
  });

  factory AdaptiveLearningAction.fromJson(Map<String, dynamic> json) {
    return AdaptiveLearningAction(
      actionId: json['action_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      type: json['type']?.toString() ?? 'general',
      priority: _intFrom(json['priority']),
      targetId: json['target_id']?.toString() ?? '',
      estimatedMinutes: _intFrom(json['estimated_minutes']),
      reason: json['reason']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'action_id': actionId,
      'title': title,
      'description': description,
      'type': type,
      'priority': priority,
      'target_id': targetId,
      'estimated_minutes': estimatedMinutes,
      'reason': reason,
    };
  }
}

class SmartNotification {
  final String notificationId;
  final String title;
  final String message;
  final int priority;
  final String category;
  final DateTime createdAt;

  const SmartNotification({
    this.notificationId = '',
    this.title = '',
    this.message = '',
    this.priority = 3,
    this.category = 'learning',
    required this.createdAt,
  });

  factory SmartNotification.fromJson(Map<String, dynamic> json) {
    return SmartNotification(
      notificationId: json['notification_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      priority: _intFrom(json['priority']),
      category: json['category']?.toString() ?? 'learning',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_id': notificationId,
      'title': title,
      'message': message,
      'priority': priority,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

List<Map<String, dynamic>> _mapList(dynamic raw) {
  if (raw is! List) return <Map<String, dynamic>>[];
  return raw
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

List<String> _stringList(dynamic raw) {
  if (raw is List) {
    return raw
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList();
  }

  final text = raw?.toString().trim() ?? '';
  return text.isEmpty ? <String>[] : <String>[text];
}

int _intFrom(dynamic value) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _doubleFrom(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
