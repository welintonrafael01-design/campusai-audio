import '../ai_agents/agent_action_advisor.dart';
import '../campus_intelligence/campus_intelligence_models.dart';
import '../campus_intelligence/enterprise_intelligence_models.dart';
import '../decision_engine.dart';
import '../enterprise_notifications/enterprise_notification_center.dart';
import '../gamification/gamification_models.dart';
import '../learning_engine/learning_models.dart';
import '../marketplace/marketplace_models.dart';
import '../workflow_engine.dart';
import 'autonomous_action_models.dart';
import 'autonomous_action_repository.dart';
import 'decision_action_bridge.dart';

/// Combina señales existentes y produce un plan corto, explicable y seguro.
class AutonomousActionEngine {
  final DecisionEngine decisionEngine;
  final DecisionActionBridge bridge;
  final AgentActionAdvisor agentAdvisor;
  final WorkflowEngine workflowEngine;
  final AutonomousActionRepository repository;

  const AutonomousActionEngine({
    this.decisionEngine = const DecisionEngine(),
    this.bridge = const DecisionActionBridge(),
    this.agentAdvisor = const AgentActionAdvisor(),
    this.workflowEngine = const WorkflowEngine(),
    this.repository = const AutonomousActionRepository(),
  });

  Future<AutonomousActionPlan> generatePlan({
    required CampusIntelligenceSnapshot campusSnapshot,
    required SmartStudyPlan smartStudyPlan,
    required StudentDigitalTwin digitalTwin,
    required SuccessPrediction successPrediction,
    required KnowledgeMap knowledgeMap,
    required GamificationProfile gamificationProfile,
    required List<MarketplaceItem> marketplaceSuggestions,
    required NotificationHistory notificationHistory,
    required ContinueLearningItem continueLearning,
    required LearningStreak streak,
    bool refresh = false,
  }) async {
    if (!refresh) {
      final cached = await repository.loadLatestPlan();
      if (cached != null) return cached;
    }

    try {
      final weakness = _firstNonEmpty([
        ...knowledgeMap.criticalConcepts,
        ...campusSnapshot.weaknesses,
        ...digitalTwin.weaknesses,
      ]);
      final risk = successPrediction.failureRisk > 0
          ? successPrediction.failureRisk
          : _riskScore(campusSnapshot.academicRisk);
      final fatigue = (100 - digitalTwin.motivationScore).clamp(0, 100);
      final decision = await decisionEngine.decide(
        DecisionContext(
          risk: risk,
          engagement: campusSnapshot.engagementScore,
          goals: knowledgeMap.tomorrowFocus.length * 20,
          availableMinutes: smartStudyPlan.suggestedMinutes,
          fatigue: fatigue,
          plan: smartStudyPlan.todayAction.trim().isEmpty ? 0 : 100,
          recommendations: notificationHistory.items.length * 20,
          marketplace: marketplaceSuggestions.length * 10,
        ),
      );

      final candidates = <AutonomousAction>[
        bridge.fromDecision(decision, weakness: weakness),
        ...notificationHistory.items
            .map(bridge.fromNotification)
            .whereType<AutonomousAction>(),
      ];
      _addLearningActions(
        candidates,
        weakness: weakness,
        smartStudyPlan: smartStudyPlan,
        continueLearning: continueLearning,
      );
      _addMarketplaceIntervention(
        candidates,
        marketplaceSuggestions: marketplaceSuggestions,
        weakness: weakness,
        risk: risk,
      );
      _addMotivationActions(
        candidates,
        profile: gamificationProfile,
        streak: streak,
      );
      if (fatigue >= 70) {
        candidates.add(bridge.create(
          type: AutonomousActionTypes.rest,
          title: 'Haz una pausa breve',
          reason: 'Tu nivel de motivación sugiere reducir la carga por ahora.',
          actionLabel: 'Registrar pausa',
          priority: AutonomousActionPriority.high,
          metadata: {'source': 'digital_twin', 'fatigue': fatigue},
        ));
      }

      final agentAction = await agentAdvisor.advise(
        risk: risk,
        weakness: weakness,
        planAction: smartStudyPlan.todayAction,
      );
      if (agentAction != null) candidates.add(agentAction);

      final history = await repository.loadHistory();
      final terminalIds = history
          .where((item) =>
              item.status == AutonomousActionStatus.completed ||
              item.status == AutonomousActionStatus.dismissed)
          .map((item) => item.actionId)
          .toSet();
      final actions = _rankAndDeduplicate(candidates)
          .where((action) => !terminalIds.contains(action.id))
          .take(10)
          .toList();
      final plan = AutonomousActionPlan(
        id: 'autonomous_action_plan_${DateTime.now().millisecondsSinceEpoch}',
        generatedAt: DateTime.now(),
        actions: actions,
      );
      if (!validatePlan(plan)) return AutonomousActionPlan.empty();

      await repository.savePlan(plan);
      await _recordWorkflow(plan);
      return plan;
    } catch (_) {
      return AutonomousActionPlan.empty();
    }
  }

  /// Verifica IDs, tipos permitidos y ausencia de duplicados.
  bool validatePlan(AutonomousActionPlan plan) {
    final ids = <String>{};
    final keys = <String>{};
    for (final action in plan.actions) {
      if (action.id.trim().isEmpty ||
          action.title.trim().isEmpty ||
          !_allowedTypes.contains(action.type)) {
        return false;
      }
      if (!ids.add(action.id) ||
          !keys.add('${action.type}:${action.targetId}')) {
        return false;
      }
    }
    return true;
  }

  void _addLearningActions(
    List<AutonomousAction> actions, {
    required String weakness,
    required SmartStudyPlan smartStudyPlan,
    required ContinueLearningItem continueLearning,
  }) {
    if (weakness.isNotEmpty) {
      actions.add(bridge.create(
        type: AutonomousActionTypes.reviewWeakness,
        title: 'Refuerza $weakness',
        reason: 'El mapa de conocimiento marcó este concepto como prioridad.',
        actionLabel: 'Revisar con Tutor IA',
        targetId: weakness,
        priority: AutonomousActionPriority.high,
        metadata: {'source': 'knowledge_map'},
      ));
    }
    if (continueLearning.hasProgress) {
      actions.add(bridge.create(
        type: AutonomousActionTypes.continueAudiobook,
        title: 'Continúa ${continueLearning.audiobookTitle}',
        reason: continueLearning.chapterTitle.isEmpty
            ? 'Tienes un AudioBook en progreso.'
            : 'Retoma ${continueLearning.chapterTitle}.',
        actionLabel: 'Continuar',
        targetId: continueLearning.audiobookId,
        priority: AutonomousActionPriority.normal,
        metadata: {
          'source': 'learning_progress',
          'audiobook_id': continueLearning.audiobookId,
          'chapter_id': continueLearning.chapterId,
        },
      ));
    }
    if (smartStudyPlan.todayAction.trim().isNotEmpty) {
      actions.add(bridge.create(
        type: AutonomousActionTypes.followSmartPlan,
        title: smartStudyPlan.todayAction,
        reason: smartStudyPlan.reason.trim().isEmpty
            ? 'Es el siguiente paso de tu plan inteligente.'
            : smartStudyPlan.reason,
        actionLabel: 'Ver plan',
        targetId: smartStudyPlan.nextActivity,
        priority: AutonomousActionPriority.normal,
        metadata: {
          'source': 'smart_study_planner',
          'minutes': smartStudyPlan.suggestedMinutes,
        },
      ));
    }
  }

  void _addMarketplaceIntervention(
    List<AutonomousAction> actions, {
    required List<MarketplaceItem> marketplaceSuggestions,
    required String weakness,
    required int risk,
  }) {
    if (marketplaceSuggestions.isEmpty || (weakness.isEmpty && risk < 40)) {
      return;
    }
    final resource = marketplaceSuggestions.first;
    actions.add(bridge.create(
      type: AutonomousActionTypes.exploreMarketplaceResource,
      title: 'Explora ${resource.title}',
      reason: weakness.isEmpty
          ? 'Este recurso local puede apoyar tu progreso actual.'
          : 'Este recurso local puede ayudarte a reforzar $weakness.',
      actionLabel: 'Ver recurso',
      targetId: resource.id,
      priority: risk >= 60
          ? AutonomousActionPriority.high
          : AutonomousActionPriority.normal,
      metadata: {
        'source': 'marketplace',
        'resource_id': resource.id,
        'category_id': resource.categoryId,
      },
    ));
  }

  void _addMotivationActions(
    List<AutonomousAction> actions, {
    required GamificationProfile profile,
    required LearningStreak streak,
  }) {
    final activeMissions =
        profile.missions.where((mission) => !mission.completed);
    if (activeMissions.isNotEmpty) {
      final mission = activeMissions.first;
      actions.add(bridge.create(
        type: AutonomousActionTypes.studyNow,
        title: mission.title,
        reason:
            'Avanza ${mission.progress}/${mission.target} sin otorgar XP anticipado.',
        actionLabel: 'Estudiar ahora',
        targetId: mission.id,
        priority: AutonomousActionPriority.normal,
        metadata: {'source': 'gamification', 'mission_id': mission.id},
      ));
    }
    if (streak.currentStreakDays <= 0) {
      actions.add(bridge.create(
        type: AutonomousActionTypes.maintainStreak,
        title: 'Activa tu racha de estudio',
        reason: 'Una sesión corta hoy ayuda a recuperar consistencia.',
        actionLabel: 'Comenzar sesión',
        priority: AutonomousActionPriority.normal,
        metadata: {'source': 'streak_service'},
      ));
    }
  }

  List<AutonomousAction> _rankAndDeduplicate(List<AutonomousAction> actions) {
    final unique = <String, AutonomousAction>{};
    for (final action in actions) {
      final key = '${action.type}:${action.targetId}';
      final current = unique[key];
      if (current == null || action.priority.index < current.priority.index) {
        unique[key] = action;
      }
    }
    return unique.values.toList()
      ..sort((a, b) => a.priority.index.compareTo(b.priority.index));
  }

  Future<void> _recordWorkflow(AutonomousActionPlan plan) async {
    try {
      await workflowEngine.execute(
        workflowId: 'autonomous_action_generation',
        steps: const [],
        context: {
          'plan_id': plan.id,
          'action_count': plan.actions.length,
          'safe_local_only': true,
        },
      );
    } catch (_) {
      // El historial de workflow no debe bloquear las recomendaciones.
    }
  }

  int _riskScore(String risk) {
    final normalized = risk.trim().toLowerCase();
    if (normalized.contains('alto') || normalized.contains('crítico')) {
      return 80;
    }
    if (normalized.contains('medio') || normalized.contains('moderado')) {
      return 50;
    }
    if (normalized.contains('bajo')) {
      return 20;
    }
    return 0;
  }

  String _firstNonEmpty(List<String> values) {
    for (final value in values) {
      if (value.trim().isNotEmpty) return value.trim();
    }
    return '';
  }

  static const _allowedTypes = {
    AutonomousActionTypes.studyNow,
    AutonomousActionTypes.reviewWeakness,
    AutonomousActionTypes.continueAudiobook,
    AutonomousActionTypes.takeQuiz,
    AutonomousActionTypes.reviewFlashcards,
    AutonomousActionTypes.talkToTutor,
    AutonomousActionTypes.followSmartPlan,
    AutonomousActionTypes.exploreMarketplaceResource,
    AutonomousActionTypes.maintainStreak,
    AutonomousActionTypes.rest,
    AutonomousActionTypes.teacherIntervention,
    AutonomousActionTypes.institutionAlert,
  };
}
