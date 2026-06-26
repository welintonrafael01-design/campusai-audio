/// Typed contracts shared by CampusAI Enterprise 3.0 services and widgets.
library;

class LearningNode {
  final String id;
  final String title;
  final String type;
  final int mastery;
  final int difficulty;
  final String status;
  final List<String> competencies;
  final List<String> relatedNodeIds;

  const LearningNode({
    this.id = '',
    this.title = '',
    this.type = 'concept',
    this.mastery = 0,
    this.difficulty = 1,
    this.status = 'pending',
    this.competencies = const [],
    this.relatedNodeIds = const [],
  });

  factory LearningNode.fromJson(Map<String, dynamic> json) => LearningNode(
        id: _text(json['id']),
        title: _text(json['title']),
        type: _text(json['type'], fallback: 'concept'),
        mastery: _score(json['mastery']),
        difficulty: _number(json['difficulty']).clamp(1, 5),
        status: _text(json['status'], fallback: 'pending'),
        competencies: _strings(json['competencies']),
        relatedNodeIds: _strings(json['related_node_ids']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'mastery': mastery,
        'difficulty': difficulty,
        'status': status,
        'competencies': competencies,
        'related_node_ids': relatedNodeIds,
      };
}

class LearningEdge {
  final String fromNodeId;
  final String toNodeId;
  final String relation;
  final int strength;

  const LearningEdge({
    this.fromNodeId = '',
    this.toNodeId = '',
    this.relation = 'related',
    this.strength = 50,
  });

  factory LearningEdge.fromJson(Map<String, dynamic> json) => LearningEdge(
        fromNodeId: _text(json['from_node_id']),
        toNodeId: _text(json['to_node_id']),
        relation: _text(json['relation'], fallback: 'related'),
        strength: _score(json['strength']),
      );

  Map<String, dynamic> toJson() => {
        'from_node_id': fromNodeId,
        'to_node_id': toNodeId,
        'relation': relation,
        'strength': strength,
      };
}

class LearningDependency {
  final String nodeId;
  final String prerequisiteId;
  final String status;
  final String recommendation;

  const LearningDependency({
    this.nodeId = '',
    this.prerequisiteId = '',
    this.status = 'ready',
    this.recommendation = '',
  });

  factory LearningDependency.fromJson(Map<String, dynamic> json) =>
      LearningDependency(
        nodeId: _text(json['node_id']),
        prerequisiteId: _text(json['prerequisite_id']),
        status: _text(json['status'], fallback: 'ready'),
        recommendation: _text(json['recommendation']),
      );

  Map<String, dynamic> toJson() => {
        'node_id': nodeId,
        'prerequisite_id': prerequisiteId,
        'status': status,
        'recommendation': recommendation,
      };
}

class LearningCluster {
  final String id;
  final String title;
  final String type;
  final int mastery;
  final List<String> nodeIds;

  const LearningCluster({
    this.id = '',
    this.title = '',
    this.type = 'competency',
    this.mastery = 0,
    this.nodeIds = const [],
  });

  factory LearningCluster.fromJson(Map<String, dynamic> json) =>
      LearningCluster(
        id: _text(json['id']),
        title: _text(json['title']),
        type: _text(json['type'], fallback: 'competency'),
        mastery: _score(json['mastery']),
        nodeIds: _strings(json['node_ids']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'mastery': mastery,
        'node_ids': nodeIds,
      };
}

class LearningRecommendation {
  final String id;
  final String title;
  final String description;
  final String nodeId;
  final int priority;
  final int estimatedMinutes;

  const LearningRecommendation({
    this.id = '',
    this.title = '',
    this.description = '',
    this.nodeId = '',
    this.priority = 3,
    this.estimatedMinutes = 10,
  });

  factory LearningRecommendation.fromJson(Map<String, dynamic> json) =>
      LearningRecommendation(
        id: _text(json['id']),
        title: _text(json['title']),
        description: _text(json['description']),
        nodeId: _text(json['node_id']),
        priority: _number(json['priority']).clamp(1, 5),
        estimatedMinutes: _number(json['estimated_minutes']).clamp(1, 180),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'node_id': nodeId,
        'priority': priority,
        'estimated_minutes': estimatedMinutes,
      };
}

class LearningDifficultyMap {
  final Map<String, int> byNodeId;
  final List<String> criticalNodeIds;

  const LearningDifficultyMap({
    this.byNodeId = const {},
    this.criticalNodeIds = const [],
  });

  factory LearningDifficultyMap.fromJson(Map<String, dynamic> json) {
    final raw = json['by_node_id'];
    final values = <String, int>{};
    if (raw is Map) {
      raw.forEach((key, value) => values[key.toString()] = _number(value));
    }
    return LearningDifficultyMap(
      byNodeId: values,
      criticalNodeIds: _strings(json['critical_node_ids']),
    );
  }

  Map<String, dynamic> toJson() => {
        'by_node_id': byNodeId,
        'critical_node_ids': criticalNodeIds,
      };
}

class LearningRoadmap {
  final DateTime generatedAt;
  final List<LearningNode> nodes;
  final List<LearningEdge> edges;
  final List<LearningCluster> clusters;
  final List<LearningDependency> dependencies;
  final List<LearningRecommendation> recommendations;
  final LearningDifficultyMap difficultyMap;

  const LearningRoadmap({
    required this.generatedAt,
    this.nodes = const [],
    this.edges = const [],
    this.clusters = const [],
    this.dependencies = const [],
    this.recommendations = const [],
    this.difficultyMap = const LearningDifficultyMap(),
  });

  factory LearningRoadmap.empty() =>
      LearningRoadmap(generatedAt: DateTime.fromMillisecondsSinceEpoch(0));

  factory LearningRoadmap.fromJson(Map<String, dynamic> json) =>
      LearningRoadmap(
        generatedAt: _date(json['generated_at']),
        nodes: _maps(json['nodes']).map(LearningNode.fromJson).toList(),
        edges: _maps(json['edges']).map(LearningEdge.fromJson).toList(),
        clusters:
            _maps(json['clusters']).map(LearningCluster.fromJson).toList(),
        dependencies: _maps(json['dependencies'])
            .map(LearningDependency.fromJson)
            .toList(),
        recommendations: _maps(json['recommendations'])
            .map(LearningRecommendation.fromJson)
            .toList(),
        difficultyMap:
            LearningDifficultyMap.fromJson(_map(json['difficulty_map'])),
      );

  Map<String, dynamic> toJson() => {
        'generated_at': generatedAt.toIso8601String(),
        'nodes': nodes.map((value) => value.toJson()).toList(),
        'edges': edges.map((value) => value.toJson()).toList(),
        'clusters': clusters.map((value) => value.toJson()).toList(),
        'dependencies': dependencies.map((value) => value.toJson()).toList(),
        'recommendations':
            recommendations.map((value) => value.toJson()).toList(),
        'difficulty_map': difficultyMap.toJson(),
      };
}

class KnowledgeConcept {
  final String nodeId;
  final String title;
  final int mastery;
  final String state;
  final bool critical;
  final bool unlocksOthers;

  const KnowledgeConcept({
    this.nodeId = '',
    this.title = '',
    this.mastery = 0,
    this.state = 'unknown',
    this.critical = false,
    this.unlocksOthers = false,
  });

  factory KnowledgeConcept.fromJson(Map<String, dynamic> json) =>
      KnowledgeConcept(
        nodeId: _text(json['node_id']),
        title: _text(json['title']),
        mastery: _score(json['mastery']),
        state: _text(json['state'], fallback: 'unknown'),
        critical: json['critical'] == true,
        unlocksOthers: json['unlocks_others'] == true,
      );

  Map<String, dynamic> toJson() => {
        'node_id': nodeId,
        'title': title,
        'mastery': mastery,
        'state': state,
        'critical': critical,
        'unlocks_others': unlocksOthers,
      };
}

class KnowledgeMap {
  final DateTime generatedAt;
  final List<KnowledgeConcept> concepts;
  final List<String> tomorrowFocus;
  final List<String> criticalConcepts;
  final String summary;

  const KnowledgeMap({
    required this.generatedAt,
    this.concepts = const [],
    this.tomorrowFocus = const [],
    this.criticalConcepts = const [],
    this.summary = '',
  });

  factory KnowledgeMap.empty() =>
      KnowledgeMap(generatedAt: DateTime.fromMillisecondsSinceEpoch(0));

  factory KnowledgeMap.fromJson(Map<String, dynamic> json) => KnowledgeMap(
        generatedAt: _date(json['generated_at']),
        concepts:
            _maps(json['concepts']).map(KnowledgeConcept.fromJson).toList(),
        tomorrowFocus: _strings(json['tomorrow_focus']),
        criticalConcepts: _strings(json['critical_concepts']),
        summary: _text(json['summary']),
      );

  Map<String, dynamic> toJson() => {
        'generated_at': generatedAt.toIso8601String(),
        'concepts': concepts.map((value) => value.toJson()).toList(),
        'tomorrow_focus': tomorrowFocus,
        'critical_concepts': criticalConcepts,
        'summary': summary,
      };
}

class SmartStudyGoal {
  final String id;
  final String title;
  final String type;
  final int progress;
  final int probability;
  final String risk;
  final int estimatedMinutes;
  final List<String> recommendations;

  const SmartStudyGoal({
    this.id = '',
    this.title = '',
    this.type = 'learning',
    this.progress = 0,
    this.probability = 0,
    this.risk = 'Sin datos',
    this.estimatedMinutes = 0,
    this.recommendations = const [],
  });

  factory SmartStudyGoal.fromJson(Map<String, dynamic> json) => SmartStudyGoal(
        id: _text(json['id']),
        title: _text(json['title']),
        type: _text(json['type'], fallback: 'learning'),
        progress: _score(json['progress']),
        probability: _score(json['probability']),
        risk: _text(json['risk'], fallback: 'Sin datos'),
        estimatedMinutes: _number(json['estimated_minutes']).clamp(0, 100000),
        recommendations: _strings(json['recommendations']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type,
        'progress': progress,
        'probability': probability,
        'risk': risk,
        'estimated_minutes': estimatedMinutes,
        'recommendations': recommendations,
      };
}

class StudyGoals {
  final DateTime generatedAt;
  final List<SmartStudyGoal> goals;

  const StudyGoals({required this.generatedAt, this.goals = const []});

  factory StudyGoals.empty() =>
      StudyGoals(generatedAt: DateTime.fromMillisecondsSinceEpoch(0));

  factory StudyGoals.fromJson(Map<String, dynamic> json) => StudyGoals(
        generatedAt: _date(json['generated_at']),
        goals: _maps(json['goals']).map(SmartStudyGoal.fromJson).toList(),
      );

  Map<String, dynamic> toJson() => {
        'generated_at': generatedAt.toIso8601String(),
        'goals': goals.map((value) => value.toJson()).toList(),
      };
}

class StudyFocusScore {
  final int score;
  final String level;
  const StudyFocusScore({this.score = 0, this.level = 'Sin datos'});
  factory StudyFocusScore.fromJson(Map<String, dynamic> json) =>
      StudyFocusScore(
        score: _score(json['score']),
        level: _text(json['level'], fallback: 'Sin datos'),
      );
  Map<String, dynamic> toJson() => {'score': score, 'level': level};
}

class DeepWorkCalculator {
  final int deepWorkMinutes;
  final int qualifiedSessions;
  const DeepWorkCalculator(
      {this.deepWorkMinutes = 0, this.qualifiedSessions = 0});
  factory DeepWorkCalculator.fromJson(Map<String, dynamic> json) =>
      DeepWorkCalculator(
        deepWorkMinutes: _number(json['deep_work_minutes']),
        qualifiedSessions: _number(json['qualified_sessions']),
      );
  Map<String, dynamic> toJson() => {
        'deep_work_minutes': deepWorkMinutes,
        'qualified_sessions': qualifiedSessions,
      };
}

class SessionQuality {
  final String sessionId;
  final int score;
  final String label;
  const SessionQuality(
      {this.sessionId = '', this.score = 0, this.label = 'Sin datos'});
  factory SessionQuality.fromJson(Map<String, dynamic> json) => SessionQuality(
        sessionId: _text(json['session_id']),
        score: _score(json['score']),
        label: _text(json['label'], fallback: 'Sin datos'),
      );
  Map<String, dynamic> toJson() =>
      {'session_id': sessionId, 'score': score, 'label': label};
}

class DistractionScore {
  final int score;
  final int estimatedLostMinutes;
  const DistractionScore({this.score = 0, this.estimatedLostMinutes = 0});
  factory DistractionScore.fromJson(Map<String, dynamic> json) =>
      DistractionScore(
        score: _score(json['score']),
        estimatedLostMinutes: _number(json['estimated_lost_minutes']),
      );
  Map<String, dynamic> toJson() =>
      {'score': score, 'estimated_lost_minutes': estimatedLostMinutes};
}

class StudyEfficiency {
  final int score;
  final String recommendation;
  const StudyEfficiency({this.score = 0, this.recommendation = ''});
  factory StudyEfficiency.fromJson(Map<String, dynamic> json) =>
      StudyEfficiency(
        score: _score(json['score']),
        recommendation: _text(json['recommendation']),
      );
  Map<String, dynamic> toJson() =>
      {'score': score, 'recommendation': recommendation};
}

class ConsistencyEngine {
  final int score;
  final int currentStreak;
  const ConsistencyEngine({this.score = 0, this.currentStreak = 0});
  factory ConsistencyEngine.fromJson(Map<String, dynamic> json) =>
      ConsistencyEngine(
          score: _score(json['score']),
          currentStreak: _number(json['current_streak']));
  Map<String, dynamic> toJson() =>
      {'score': score, 'current_streak': currentStreak};
}

class ProductivitySnapshot {
  final DateTime generatedAt;
  final StudyFocusScore focus;
  final DeepWorkCalculator deepWork;
  final DistractionScore distraction;
  final StudyEfficiency efficiency;
  final ConsistencyEngine consistency;
  final List<SessionQuality> sessionQualities;

  const ProductivitySnapshot({
    required this.generatedAt,
    this.focus = const StudyFocusScore(),
    this.deepWork = const DeepWorkCalculator(),
    this.distraction = const DistractionScore(),
    this.efficiency = const StudyEfficiency(),
    this.consistency = const ConsistencyEngine(),
    this.sessionQualities = const [],
  });

  factory ProductivitySnapshot.empty() =>
      ProductivitySnapshot(generatedAt: DateTime.fromMillisecondsSinceEpoch(0));
  factory ProductivitySnapshot.fromJson(Map<String, dynamic> json) =>
      ProductivitySnapshot(
        generatedAt: _date(json['generated_at']),
        focus: StudyFocusScore.fromJson(_map(json['focus'])),
        deepWork: DeepWorkCalculator.fromJson(_map(json['deep_work'])),
        distraction: DistractionScore.fromJson(_map(json['distraction'])),
        efficiency: StudyEfficiency.fromJson(_map(json['efficiency'])),
        consistency: ConsistencyEngine.fromJson(_map(json['consistency'])),
        sessionQualities: _maps(json['session_qualities'])
            .map(SessionQuality.fromJson)
            .toList(),
      );
  Map<String, dynamic> toJson() => {
        'generated_at': generatedAt.toIso8601String(),
        'focus': focus.toJson(),
        'deep_work': deepWork.toJson(),
        'distraction': distraction.toJson(),
        'efficiency': efficiency.toJson(),
        'consistency': consistency.toJson(),
        'session_qualities':
            sessionQualities.map((value) => value.toJson()).toList(),
      };
}

class AssistantMemory {
  final DateTime updatedAt;
  final String preferredTone;
  final String language;
  final List<String> preferredStudyHours;
  final List<String> favoriteSubjects;
  final List<String> difficulties;
  final List<String> objectives;
  final String learningStyle;

  const AssistantMemory({
    required this.updatedAt,
    this.preferredTone = 'supportive',
    this.language = 'es',
    this.preferredStudyHours = const [],
    this.favoriteSubjects = const [],
    this.difficulties = const [],
    this.objectives = const [],
    this.learningStyle = 'mixed',
  });

  factory AssistantMemory.empty() =>
      AssistantMemory(updatedAt: DateTime.fromMillisecondsSinceEpoch(0));
  factory AssistantMemory.fromJson(Map<String, dynamic> json) =>
      AssistantMemory(
        updatedAt: _date(json['updated_at']),
        preferredTone: _text(json['preferred_tone'], fallback: 'supportive'),
        language: _text(json['language'], fallback: 'es'),
        preferredStudyHours: _strings(json['preferred_study_hours']),
        favoriteSubjects: _strings(json['favorite_subjects']),
        difficulties: _strings(json['difficulties']),
        objectives: _strings(json['objectives']),
        learningStyle: _text(json['learning_style'], fallback: 'mixed'),
      );
  Map<String, dynamic> toJson() => {
        'updated_at': updatedAt.toIso8601String(),
        'preferred_tone': preferredTone,
        'language': language,
        'preferred_study_hours': preferredStudyHours,
        'favorite_subjects': favoriteSubjects,
        'difficulties': difficulties,
        'objectives': objectives,
        'learning_style': learningStyle,
      };
}

class StudentDigitalTwin {
  final DateTime updatedAt;
  final int knowledgeScore;
  final int habitScore;
  final int motivationScore;
  final String risk;
  final List<String> strengths;
  final List<String> weaknesses;
  final List<String> objectives;
  final String currentState;

  const StudentDigitalTwin({
    required this.updatedAt,
    this.knowledgeScore = 0,
    this.habitScore = 0,
    this.motivationScore = 0,
    this.risk = 'Sin datos',
    this.strengths = const [],
    this.weaknesses = const [],
    this.objectives = const [],
    this.currentState = 'Sin datos',
  });
  factory StudentDigitalTwin.empty() =>
      StudentDigitalTwin(updatedAt: DateTime.fromMillisecondsSinceEpoch(0));
  factory StudentDigitalTwin.fromJson(Map<String, dynamic> json) =>
      StudentDigitalTwin(
          updatedAt: _date(json['updated_at']),
          knowledgeScore: _score(json['knowledge_score']),
          habitScore: _score(json['habit_score']),
          motivationScore: _score(json['motivation_score']),
          risk: _text(json['risk'], fallback: 'Sin datos'),
          strengths: _strings(json['strengths']),
          weaknesses: _strings(json['weaknesses']),
          objectives: _strings(json['objectives']),
          currentState: _text(json['current_state'], fallback: 'Sin datos'));
  Map<String, dynamic> toJson() => {
        'updated_at': updatedAt.toIso8601String(),
        'knowledge_score': knowledgeScore,
        'habit_score': habitScore,
        'motivation_score': motivationScore,
        'risk': risk,
        'strengths': strengths,
        'weaknesses': weaknesses,
        'objectives': objectives,
        'current_state': currentState,
      };
}

class SuccessPrediction {
  final DateTime generatedAt;
  final int dropoutRisk;
  final int failureRisk;
  final int passProbability;
  final int courseCompletionProbability;
  final int goalCompletionProbability;
  final String recommendation;

  const SuccessPrediction({
    required this.generatedAt,
    this.dropoutRisk = 0,
    this.failureRisk = 0,
    this.passProbability = 0,
    this.courseCompletionProbability = 0,
    this.goalCompletionProbability = 0,
    this.recommendation = '',
  });
  factory SuccessPrediction.empty() =>
      SuccessPrediction(generatedAt: DateTime.fromMillisecondsSinceEpoch(0));
  factory SuccessPrediction.fromJson(
          Map<String, dynamic> json) =>
      SuccessPrediction(
          generatedAt: _date(json['generated_at']),
          dropoutRisk: _score(json['dropout_risk']),
          failureRisk: _score(json['failure_risk']),
          passProbability: _score(json['pass_probability']),
          courseCompletionProbability:
              _score(json['course_completion_probability']),
          goalCompletionProbability:
              _score(json['goal_completion_probability']),
          recommendation: _text(json['recommendation']));
  Map<String, dynamic> toJson() => {
        'generated_at': generatedAt.toIso8601String(),
        'dropout_risk': dropoutRisk,
        'failure_risk': failureRisk,
        'pass_probability': passProbability,
        'course_completion_probability': courseCompletionProbability,
        'goal_completion_probability': goalCompletionProbability,
        'recommendation': recommendation,
      };
}

int _number(dynamic value) =>
    value is num ? value.round() : int.tryParse('${value ?? ''}') ?? 0;
int _score(dynamic value) => _number(value).clamp(0, 100);
String _text(dynamic value, {String fallback = ''}) {
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
List<String> _strings(dynamic value) => value is List
    ? value.map((item) => _text(item)).where((item) => item.isNotEmpty).toList()
    : _text(value).isEmpty
        ? <String>[]
        : [_text(value)];
