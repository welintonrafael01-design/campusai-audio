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

class CampusTrend {
  final String metric;
  final double currentValue;
  final double previousValue;
  final double delta;
  final String direction;
  final String description;

  const CampusTrend({
    this.metric = '',
    this.currentValue = 0,
    this.previousValue = 0,
    this.delta = 0,
    this.direction = 'stable',
    this.description = '',
  });

  factory CampusTrend.fromJson(Map<String, dynamic> json) {
    return CampusTrend(
      metric: json['metric']?.toString() ?? '',
      currentValue: _doubleFrom(json['current_value']),
      previousValue: _doubleFrom(json['previous_value']),
      delta: _doubleFrom(json['delta']),
      direction: json['direction']?.toString() ?? 'stable',
      description: json['description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metric': metric,
      'current_value': currentValue,
      'previous_value': previousValue,
      'delta': delta,
      'direction': direction,
      'description': description,
    };
  }
}

class StudentTimelineItem {
  final String itemId;
  final String title;
  final String description;
  final String category;
  final DateTime createdAt;
  final int score;
  final Map<String, dynamic> metadata;

  const StudentTimelineItem({
    this.itemId = '',
    this.title = '',
    this.description = '',
    this.category = 'snapshot',
    required this.createdAt,
    this.score = 0,
    this.metadata = const {},
  });

  factory StudentTimelineItem.fromJson(Map<String, dynamic> json) {
    return StudentTimelineItem(
      itemId: json['item_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'snapshot',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      score: _intFrom(json['score']),
      metadata: _mapFrom(json['metadata']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'title': title,
      'description': description,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'score': score,
      'metadata': metadata,
    };
  }
}

class AdaptiveStudyBlock {
  final String blockId;
  final String activityType;
  final String title;
  final String objective;
  final int estimatedMinutes;
  final int priority;
  final String reason;
  final String targetId;

  const AdaptiveStudyBlock({
    this.blockId = '',
    this.activityType = 'review',
    this.title = '',
    this.objective = '',
    this.estimatedMinutes = 10,
    this.priority = 3,
    this.reason = '',
    this.targetId = '',
  });

  factory AdaptiveStudyBlock.fromJson(Map<String, dynamic> json) {
    return AdaptiveStudyBlock(
      blockId: json['block_id']?.toString() ?? '',
      activityType: json['activity_type']?.toString() ?? 'review',
      title: json['title']?.toString() ?? '',
      objective: json['objective']?.toString() ?? '',
      estimatedMinutes: _intFrom(json['estimated_minutes']),
      priority: _intFrom(json['priority']),
      reason: json['reason']?.toString() ?? '',
      targetId: json['target_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'block_id': blockId,
      'activity_type': activityType,
      'title': title,
      'objective': objective,
      'estimated_minutes': estimatedMinutes,
      'priority': priority,
      'reason': reason,
      'target_id': targetId,
    };
  }
}

class AdaptiveScheduleSlot {
  final String slotId;
  final DateTime recommendedAt;
  final String activityType;
  final String title;
  final int durationMinutes;
  final int priority;
  final String reason;
  final AdaptiveStudyBlock studyBlock;

  const AdaptiveScheduleSlot({
    this.slotId = '',
    required this.recommendedAt,
    this.activityType = 'review',
    this.title = '',
    this.durationMinutes = 10,
    this.priority = 3,
    this.reason = '',
    this.studyBlock = const AdaptiveStudyBlock(),
  });

  factory AdaptiveScheduleSlot.fromJson(Map<String, dynamic> json) {
    return AdaptiveScheduleSlot(
      slotId: json['slot_id']?.toString() ?? '',
      recommendedAt:
          DateTime.tryParse(json['recommended_at']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
      activityType: json['activity_type']?.toString() ?? 'review',
      title: json['title']?.toString() ?? '',
      durationMinutes: _intFrom(json['duration_minutes']),
      priority: _intFrom(json['priority']),
      reason: json['reason']?.toString() ?? '',
      studyBlock: AdaptiveStudyBlock.fromJson(_mapFrom(json['study_block'])),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slot_id': slotId,
      'recommended_at': recommendedAt.toIso8601String(),
      'activity_type': activityType,
      'title': title,
      'duration_minutes': durationMinutes,
      'priority': priority,
      'reason': reason,
      'study_block': studyBlock.toJson(),
    };
  }
}

class AdaptiveSchedule {
  final DateTime generatedAt;
  final String nextAction;
  final String nextActivityType;
  final int priority;
  final int totalMinutes;
  final String reason;
  final List<AdaptiveScheduleSlot> slots;

  const AdaptiveSchedule({
    required this.generatedAt,
    this.nextAction = 'Continúa con tu próxima actividad.',
    this.nextActivityType = 'review',
    this.priority = 3,
    this.totalMinutes = 0,
    this.reason = '',
    this.slots = const [],
  });

  factory AdaptiveSchedule.empty() {
    return AdaptiveSchedule(
      generatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory AdaptiveSchedule.fromJson(Map<String, dynamic> json) {
    return AdaptiveSchedule(
      generatedAt: DateTime.tryParse(json['generated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      nextAction: json['next_action']?.toString() ??
          'Continúa con tu próxima actividad.',
      nextActivityType: json['next_activity_type']?.toString() ?? 'review',
      priority: _intFrom(json['priority']),
      totalMinutes: _intFrom(json['total_minutes']),
      reason: json['reason']?.toString() ?? '',
      slots: _mapList(json['slots'])
          .map((item) => AdaptiveScheduleSlot.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'generated_at': generatedAt.toIso8601String(),
      'next_action': nextAction,
      'next_activity_type': nextActivityType,
      'priority': priority,
      'total_minutes': totalMinutes,
      'reason': reason,
      'slots': slots.map((item) => item.toJson()).toList(),
    };
  }
}

class SmartStudyDay {
  final DateTime date;
  final String goal;
  final AdaptiveStudyBlock primaryActivity;
  final AdaptiveStudyBlock secondaryActivity;
  final int studyMinutes;
  final int restMinutes;
  final String summary;

  const SmartStudyDay({
    required this.date,
    this.goal = '',
    this.primaryActivity = const AdaptiveStudyBlock(),
    this.secondaryActivity = const AdaptiveStudyBlock(),
    this.studyMinutes = 0,
    this.restMinutes = 5,
    this.summary = '',
  });

  factory SmartStudyDay.fromJson(Map<String, dynamic> json) {
    return SmartStudyDay(
      date: DateTime.tryParse(json['date']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      goal: json['goal']?.toString() ?? '',
      primaryActivity:
          AdaptiveStudyBlock.fromJson(_mapFrom(json['primary_activity'])),
      secondaryActivity:
          AdaptiveStudyBlock.fromJson(_mapFrom(json['secondary_activity'])),
      studyMinutes: _intFrom(json['study_minutes']),
      restMinutes: _intFrom(json['rest_minutes']),
      summary: json['summary']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'goal': goal,
      'primary_activity': primaryActivity.toJson(),
      'secondary_activity': secondaryActivity.toJson(),
      'study_minutes': studyMinutes,
      'rest_minutes': restMinutes,
      'summary': summary,
    };
  }
}

class SmartStudyPlan {
  final DateTime generatedAt;
  final String summary;
  final String todayAction;
  final int suggestedMinutes;
  final String nextActivity;
  final String reason;
  final List<SmartStudyDay> days;

  const SmartStudyPlan({
    required this.generatedAt,
    this.summary = '',
    this.todayAction = 'Continúa con tu próxima actividad.',
    this.suggestedMinutes = 0,
    this.nextActivity = 'review',
    this.reason = '',
    this.days = const [],
  });

  factory SmartStudyPlan.empty() {
    return SmartStudyPlan(
      generatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory SmartStudyPlan.fromJson(Map<String, dynamic> json) {
    return SmartStudyPlan(
      generatedAt: DateTime.tryParse(json['generated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      summary: json['summary']?.toString() ?? '',
      todayAction: json['today_action']?.toString() ??
          'Continúa con tu próxima actividad.',
      suggestedMinutes: _intFrom(json['suggested_minutes']),
      nextActivity: json['next_activity']?.toString() ?? 'review',
      reason: json['reason']?.toString() ?? '',
      days: _mapList(json['days'])
          .map((item) => SmartStudyDay.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'generated_at': generatedAt.toIso8601String(),
      'summary': summary,
      'today_action': todayAction,
      'suggested_minutes': suggestedMinutes,
      'next_activity': nextActivity,
      'reason': reason,
      'days': days.map((item) => item.toJson()).toList(),
    };
  }
}

class AdaptiveRecommendation {
  final String recommendationId;
  final String type;
  final String title;
  final String description;
  final int priority;
  final String reason;
  final int estimatedMinutes;
  final String targetId;

  const AdaptiveRecommendation({
    this.recommendationId = '',
    this.type = 'continue',
    this.title = '',
    this.description = '',
    this.priority = 3,
    this.reason = '',
    this.estimatedMinutes = 10,
    this.targetId = '',
  });

  factory AdaptiveRecommendation.fromJson(Map<String, dynamic> json) {
    return AdaptiveRecommendation(
      recommendationId: json['recommendation_id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'continue',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      priority: _intFrom(json['priority']),
      reason: json['reason']?.toString() ?? '',
      estimatedMinutes: _intFrom(json['estimated_minutes']),
      targetId: json['target_id']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recommendation_id': recommendationId,
      'type': type,
      'title': title,
      'description': description,
      'priority': priority,
      'reason': reason,
      'estimated_minutes': estimatedMinutes,
      'target_id': targetId,
    };
  }
}

class StudentEnterpriseAnalytics {
  final DateTime generatedAt;
  final int learningVelocity;
  final int retentionScore;
  final int effortScore;
  final int consistencyScore;
  final int voiceEngagement;
  final int quizReliability;
  final int masteryMomentum;
  final String riskTrajectory;
  final int predictedCompletionDays;
  final int predictedSuccessProbability;

  const StudentEnterpriseAnalytics({
    required this.generatedAt,
    this.learningVelocity = 0,
    this.retentionScore = 0,
    this.effortScore = 0,
    this.consistencyScore = 0,
    this.voiceEngagement = 0,
    this.quizReliability = 0,
    this.masteryMomentum = 0,
    this.riskTrajectory = 'Sin datos',
    this.predictedCompletionDays = 0,
    this.predictedSuccessProbability = 0,
  });

  factory StudentEnterpriseAnalytics.empty() {
    return StudentEnterpriseAnalytics(
      generatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory StudentEnterpriseAnalytics.fromJson(Map<String, dynamic> json) {
    return StudentEnterpriseAnalytics(
      generatedAt: DateTime.tryParse(json['generated_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      learningVelocity: _intFrom(json['learning_velocity']),
      retentionScore: _intFrom(json['retention_score']),
      effortScore: _intFrom(json['effort_score']),
      consistencyScore: _intFrom(json['consistency_score']),
      voiceEngagement: _intFrom(json['voice_engagement']),
      quizReliability: _intFrom(json['quiz_reliability']),
      masteryMomentum: _intFrom(json['mastery_momentum']),
      riskTrajectory: json['risk_trajectory']?.toString() ?? 'Sin datos',
      predictedCompletionDays: _intFrom(json['predicted_completion_days']),
      predictedSuccessProbability:
          _intFrom(json['predicted_success_probability']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'generated_at': generatedAt.toIso8601String(),
      'learning_velocity': learningVelocity,
      'retention_score': retentionScore,
      'effort_score': effortScore,
      'consistency_score': consistencyScore,
      'voice_engagement': voiceEngagement,
      'quiz_reliability': quizReliability,
      'mastery_momentum': masteryMomentum,
      'risk_trajectory': riskTrajectory,
      'predicted_completion_days': predictedCompletionDays,
      'predicted_success_probability': predictedSuccessProbability,
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

Map<String, dynamic> _mapFrom(dynamic raw) {
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
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
