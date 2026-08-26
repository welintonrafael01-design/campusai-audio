import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../layout/responsive_layout.dart';
import '../services/accessibility/accessibility_content_service.dart';
import '../services/accessibility/accessibility_models.dart';
import '../services/accessibility/accessibility_preferences_service.dart';
import '../services/autonomous_ai/autonomous_action_executor.dart';
import '../services/autonomous_ai/autonomous_action_models.dart';
import '../services/campus_intelligence/campus_intelligence_models.dart';
import '../services/campus_intelligence/enterprise_intelligence_models.dart'
    hide LearningRecommendation;
import '../services/enterprise_notifications/enterprise_notification_center.dart';
import '../services/ftue/ftue_models.dart';
import '../services/ftue/ftue_service.dart';
import '../services/gamification/gamification_models.dart' hide Achievement;
import '../services/learning_engine/learning_models.dart';
import '../services/launch/launch_models.dart';
import '../services/launch/launch_readiness_service.dart';
import '../services/launch/onboarding_flow_service.dart';
import '../services/launch/onboarding_readiness_service.dart';
import '../services/launch/user_feedback_service.dart';
import '../services/marketplace/marketplace_models.dart';
import '../services/plan_guard_service.dart';
import '../services/student_dashboard_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/accessibility_card.dart';
import '../widgets/accessibility_toggle_tile.dart';
import '../widgets/beta_launch_card.dart';
import '../widgets/ftue_quick_start_card.dart';
import '../widgets/enterprise_dashboard_widgets.dart';
import '../widgets/enterprise4_dashboard_widgets.dart';
import '../widgets/next_best_action_card.dart';
import '../widgets/onboarding_step_card.dart';
import '../widgets/section_card.dart';
import '../widgets/studybook/booky_card.dart';
import '../widgets/studybook/premium_section_card.dart';
import '../widgets/studybook/studybook_buttons.dart';
import '../widgets/studybook/studybook_states.dart';
import '../widgets/studybook_app_shell.dart';
import '../widgets/time_to_value_card.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final dashboardController = const StudentDashboardController();
  final autonomousActionExecutor = const AutonomousActionExecutor();
  final launchReadinessService = const LaunchReadinessService();
  final feedbackService = const UserFeedbackService();
  final onboardingReadinessService = const OnboardingReadinessService();
  final onboardingFlowService = const OnboardingFlowService();
  final accessibilityPreferencesService =
      const AccessibilityPreferencesService();
  final accessibilityContentService = const AccessibilityContentService();
  final ftueService = const FtueService();
  final planGuardService = const PlanGuardService();

  bool isLoading = true;
  bool isRefreshing = false;
  bool isLaunchLoading = true;
  bool isDashboardLoadInFlight = false;
  String errorMessage = '';
  final Set<String> processingActionIds = {};
  final progressSectionKey = GlobalKey();

  LearningAnalytics analytics = LearningAnalytics.empty;
  ContinueLearningItem continueLearning = ContinueLearningItem.empty;
  LearningStreak streak = LearningStreak.empty;
  List<LearningRecommendation> recommendations = [];
  List<Achievement> achievements = [];
  StudentIntelligence intelligence = StudentIntelligence.empty;
  CampusIntelligenceSnapshot campusSnapshot =
      CampusIntelligenceSnapshot.empty();
  List<CampusTrend> campusTrends = [];
  AdaptiveSchedule adaptiveSchedule = AdaptiveSchedule.empty();
  SmartStudyPlan smartStudyPlan = SmartStudyPlan.empty();
  StudentEnterpriseAnalytics enterpriseAnalytics =
      StudentEnterpriseAnalytics.empty();
  LearningRoadmap learningRoadmap = LearningRoadmap.empty();
  KnowledgeMap knowledgeMap = KnowledgeMap.empty();
  StudyGoals studyGoals = StudyGoals.empty();
  ProductivitySnapshot productivity = ProductivitySnapshot.empty();
  StudentDigitalTwin digitalTwin = StudentDigitalTwin.empty();
  SuccessPrediction successPrediction = SuccessPrediction.empty();
  List<StudentTimelineItem> smartTimeline = [];
  GamificationProfile gamificationProfile = GamificationProfile.empty();
  List<MarketplaceItem> marketplaceSuggestions = [];
  NotificationHistory notificationHistory = const NotificationHistory();
  AutonomousActionPlan autonomousActionPlan = AutonomousActionPlan.empty();
  LaunchReadinessReport launchReport = LaunchReadinessReport.empty();
  List<Map<String, dynamic>> recentSessions = [];
  AccessibilityPreferences accessibilityPreferences =
      AccessibilityPreferences.defaults();
  FtueProgress ftueProgress = FtueProgress.initial(FtueUserPath.student);
  List<FtueStep> ftueSteps = const [];

  @override
  void initState() {
    super.initState();
    loadStudentDashboard();
  }

  Future<void> loadStudentDashboard({bool refresh = false}) async {
    if (isDashboardLoadInFlight) return;
    isDashboardLoadInFlight = true;
    setState(() {
      if (refresh) {
        isRefreshing = true;
      } else {
        isLoading = true;
      }
      isLaunchLoading = true;
      errorMessage = '';
    });

    try {
      final loaded = await dashboardController.load(refresh: refresh);
      final loadedLaunchReport = await launchReadinessService.buildReport();
      final loadedAccessibilityPreferences =
          await accessibilityPreferencesService.load();
      final loadedFtueProgress = await ftueService.load(FtueUserPath.student);
      final synchronizedFtueProgress =
          await ftueService.synchronizeStudentActivity(
        loadedFtueProgress,
        hasAudioBook: loaded.continueLearning.hasProgress ||
            loaded.analytics.audiobooksStarted > 0,
        hasQuiz: loaded.analytics.quizCompleted > 0,
        hasLearningActivity: loaded.analytics.sessions > 0,
      );

      if (!mounted) return;

      setState(() {
        analytics = loaded.analytics;
        continueLearning = loaded.continueLearning;
        streak = loaded.streak;
        recommendations = loaded.recommendations;
        achievements = loaded.achievements;
        intelligence = loaded.intelligence;
        campusSnapshot = loaded.campusSnapshot;
        campusTrends = loaded.campusTrends;
        adaptiveSchedule = loaded.adaptiveSchedule;
        smartStudyPlan = loaded.smartStudyPlan;
        enterpriseAnalytics = loaded.enterpriseAnalytics;
        learningRoadmap = loaded.learningRoadmap;
        knowledgeMap = loaded.knowledgeMap;
        studyGoals = loaded.studyGoals;
        productivity = loaded.productivity;
        digitalTwin = loaded.digitalTwin;
        successPrediction = loaded.successPrediction;
        smartTimeline = loaded.smartTimeline;
        gamificationProfile = loaded.gamificationProfile;
        marketplaceSuggestions = loaded.marketplaceSuggestions;
        notificationHistory = loaded.notificationHistory;
        autonomousActionPlan = loaded.autonomousActionPlan;
        launchReport = loadedLaunchReport;
        recentSessions = loaded.recentSessions;
        accessibilityPreferences = loadedAccessibilityPreferences;
        ftueProgress = synchronizedFtueProgress;
        ftueSteps = ftueService.stepsForPath(FtueUserPath.student);
        isLoading = false;
        isRefreshing = false;
        isLaunchLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'No se pudo cargar tu panel de aprendizaje.';
        isLoading = false;
        isRefreshing = false;
        isLaunchLoading = false;
      });
    } finally {
      isDashboardLoadInFlight = false;
    }
  }

  String intelligentDayMessage(List<AutonomousAction> pendingActions) {
    if (pendingActions.isNotEmpty) {
      return 'Si tienes poco tiempo, empieza por ${pendingActions.first.title.toLowerCase()}.';
    }
    if (continueLearning.hasProgress) {
      return 'Retoma ${continueLearning.audiobookTitle} y conserva tu ritmo.';
    }
    if (smartStudyPlan.suggestedMinutes > 0) {
      return 'Con ${smartStudyPlan.suggestedMinutes} minutos puedes dar un paso importante hoy.';
    }
    if (analytics.sessions <= 0) {
      return 'Hoy podemos dar el primer paso y crear una ruta a tu medida.';
    }
    return 'Vas al día. Elige una actividad breve y sigamos avanzando.';
  }

  String bookyGuidanceMessage(AutonomousAction? nextBestAction) {
    if (nextBestAction != null) {
      return 'Hoy podemos avanzar juntos. Te preparé una ruta sencilla y ${nextBestAction.title.toLowerCase()} es un buen comienzo.';
    }
    if (continueLearning.hasProgress) {
      return 'Tu AudioBook está listo para continuar. Cuando quieras, también puedo ayudarte como Tutor IA.';
    }
    return 'Sube tu primer documento y lo convertiré en una experiencia clara para aprender mejor.';
  }

  void scrollToProgress() {
    final progressContext = progressSectionKey.currentContext;
    if (progressContext == null) return;
    Scrollable.ensureVisible(
      progressContext,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> executeAutonomousAction(AutonomousAction action) async {
    if (processingActionIds.contains(action.id)) return;
    setState(() => processingActionIds.add(action.id));
    final result = await autonomousActionExecutor.execute(
      action,
      navigate: (route, extra) {
        if (!mounted || route == 'studentDashboard') return;
        context.goNamed(route, extra: extra);
      },
    );
    dashboardController.invalidateCache();
    if (!mounted) return;
    setState(() {
      processingActionIds.remove(action.id);
      autonomousActionPlan = autonomousActionPlan.copyWith(
        actions: autonomousActionPlan.actions
            .where((item) => item.id != action.id)
            .toList(),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  Future<void> dismissAutonomousAction(AutonomousAction action) async {
    if (processingActionIds.contains(action.id)) return;
    setState(() => processingActionIds.add(action.id));
    final result = await autonomousActionExecutor.dismiss(action);
    dashboardController.invalidateCache();
    if (!mounted) return;
    setState(() {
      processingActionIds.remove(action.id);
      autonomousActionPlan = autonomousActionPlan.copyWith(
        actions: autonomousActionPlan.actions
            .where((item) => item.id != action.id)
            .toList(),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
  }

  Future<void> openBetaFeedback() async {
    final controller = TextEditingController();
    var category = FeedbackCategory.ux;
    var isSaving = false;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Compartir feedback beta'),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<FeedbackCategory>(
                      initialValue: category,
                      decoration: const InputDecoration(
                        labelText: 'Categoría',
                      ),
                      items: FeedbackCategory.values
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(_feedbackCategoryLabel(item)),
                            ),
                          )
                          .toList(),
                      onChanged: isSaving
                          ? null
                          : (value) {
                              if (value == null) return;
                              setDialogState(() => category = value);
                            },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller,
                      minLines: 4,
                      maxLines: 7,
                      maxLength: 2000,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: const InputDecoration(
                        labelText: '¿Qué ocurrió o qué mejorarías?',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'No incluyas contraseñas, tokens ni datos personales.',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: isSaving || controller.text.trim().isEmpty
                      ? null
                      : () async {
                          setDialogState(() => isSaving = true);
                          final saved = await feedbackService.submit(
                            category: category,
                            message: controller.text,
                            source: 'student_dashboard',
                          );
                          if (!dialogContext.mounted) return;
                          Navigator.of(dialogContext).pop(saved != null);
                        },
                  child: isSaving
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
    if (submitted != true || !mounted) return;
    final updated = await launchReadinessService.buildReport();
    if (!mounted) return;
    setState(() => launchReport = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Gracias. Tu feedback beta quedó guardado.')),
    );
  }

  Future<void> openOnboardingGuide() async {
    final progress = await onboardingReadinessService.loadProgress();
    if (!mounted) return;
    final steps = onboardingFlowService.stepsForRole('student');
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Guía inicial',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Elige un primer paso. Puedes volver a esta guía cuando quieras.',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 14),
                  for (final step in steps)
                    OnboardingStepCard(
                      step: step,
                      completed: progress.completedStepIds.contains(step.id),
                      onOpen: () async {
                        await onboardingReadinessService.completeStep(step.id);
                        if (!sheetContext.mounted) return;
                        Navigator.of(sheetContext).pop();
                        if (!mounted || step.routeName.isEmpty) return;
                        context.goNamed(step.routeName);
                      },
                    ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                      await onboardingReadinessService.skip();
                      if (!sheetContext.mounted) return;
                      Navigator.of(sheetContext).pop();
                    },
                    child: const Text('Saltar por ahora'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    final updated = await launchReadinessService.buildReport();
    if (!mounted) return;
    setState(() => launchReport = updated);
  }

  Future<void> openAccessibilityPreferences() async {
    var draft = accessibilityPreferences;
    final selected = await showModalBottomSheet<AccessibilityPreferences>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void update(AccessibilityPreferences value) {
              setSheetState(() => draft = value);
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  22,
                  8,
                  22,
                  24 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Aprende a tu manera',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'No todos aprendemos igual. Booky puede adaptar tu experiencia a lo que mejor funcione para ti.',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AccessibilityToggleTile(
                        title: 'Preferir audio',
                        description:
                            'Prioriza opciones para escuchar el contenido.',
                        value: draft.preferAudio,
                        icon: Icons.headphones_rounded,
                        onChanged: (value) =>
                            update(draft.copyWith(preferAudio: value)),
                      ),
                      AccessibilityToggleTile(
                        title: 'Texto grande',
                        description:
                            'Registra tu preferencia por contenido más legible.',
                        value: draft.largeText,
                        icon: Icons.text_increase_rounded,
                        onChanged: (value) =>
                            update(draft.copyWith(largeText: value)),
                      ),
                      AccessibilityToggleTile(
                        title: 'Lenguaje simple',
                        description:
                            'Pide explicaciones breves y fáciles de seguir.',
                        value: draft.simpleLanguage,
                        icon: Icons.short_text_rounded,
                        onChanged: (value) =>
                            update(draft.copyWith(simpleLanguage: value)),
                      ),
                      AccessibilityToggleTile(
                        title: 'Alto contraste',
                        description:
                            'Registra tu preferencia por mayor contraste visual.',
                        value: draft.highContrast,
                        icon: Icons.contrast_rounded,
                        onChanged: (value) =>
                            update(draft.copyWith(highContrast: value)),
                      ),
                      AccessibilityToggleTile(
                        title: 'Reducir animaciones',
                        description:
                            'Prefiere transiciones más tranquilas y predecibles.',
                        value: draft.reduceMotion,
                        icon: Icons.motion_photos_off_rounded,
                        onChanged: (value) =>
                            update(draft.copyWith(reduceMotion: value)),
                      ),
                      AccessibilityToggleTile(
                        title: 'Quiz paso a paso',
                        description: 'Presenta una pregunta a la vez.',
                        value: draft.stepByStepQuiz,
                        icon: Icons.checklist_rounded,
                        onChanged: (value) =>
                            update(draft.copyWith(stepByStepQuiz: value)),
                      ),
                      AccessibilityToggleTile(
                        title: 'Navegación simplificada',
                        description:
                            'Prioriza las acciones esenciales de aprendizaje.',
                        value: draft.simplifiedNavigation,
                        icon: Icons.route_rounded,
                        onChanged: (value) => update(
                          draft.copyWith(simplifiedNavigation: value),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            child: const Text('Cancelar'),
                          ),
                          const SizedBox(width: 10),
                          FilledButton.icon(
                            onPressed: () => Navigator.of(sheetContext).pop(
                              draft.copyWith(updatedAt: DateTime.now()),
                            ),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Guardar preferencias'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (selected == null) return;

    final saved = await accessibilityPreferencesService.save(selected);
    if (saved) {
      await accessibilityContentService.buildAndSaveProfile(selected);
    }
    if (!mounted) return;

    if (saved) {
      setState(() => accessibilityPreferences = selected);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Tus preferencias quedaron listas.'
              : 'Booky no pudo guardar los cambios esta vez. Probemos de nuevo.',
        ),
      ),
    );
  }

  FtueStep? nextFtueStep() {
    for (final step in ftueSteps) {
      if (!ftueProgress.isStepComplete(step.id)) return step;
    }
    return null;
  }

  Future<void> openFtueStep(FtueStep step) async {
    if (step.id == 'student_progress') {
      final updated = await ftueService.completeStep(ftueProgress, step.id);
      if (!mounted) return;
      setState(() => ftueProgress = updated);
      scrollToProgress();
      return;
    }
    if (step.routeName.isEmpty || step.routeName == 'studentDashboard') return;
    context.goNamed(step.routeName);
  }

  Future<void> dismissFtue() async {
    final updated = await ftueService.dismiss(ftueProgress);
    if (!mounted) return;
    setState(() => ftueProgress = updated);
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveLayout.isMobile(context);
    final pendingActions = autonomousActionPlan.pendingActions;
    final nextBestAction = pendingActions.isEmpty ? null : pendingActions.first;
    final remainingActions = pendingActions.skip(1).toList();
    final dayDetail = nextBestAction?.reason ??
        (analytics.sessions <= 0 && !continueLearning.hasProgress
            ? 'Crea tu primer AudioBook o pregúntale a Booky para comenzar.'
            : campusSnapshot.recommendedNextAction);
    final nextFirstStep = nextFtueStep();
    final showFtue = ftueSteps.isNotEmpty &&
        !ftueProgress.dismissed &&
        !ftueProgress.isComplete(ftueSteps.length);
    final isFreePlan = planCode(planGuardService.currentPlan) == 'free';

    return StudyBookAppShell(
      currentRoute: '/learning',
      maxContentWidth: 1180,
      child: isLoading
          ? const StudyBookLoadingState(
              message: 'Booky está preparando tu día inteligente...',
            )
          : RefreshIndicator(
              onRefresh: () => loadStudentDashboard(refresh: true),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(isMobile ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      isMobile: isMobile,
                      isRefreshing: isRefreshing,
                      onRefresh: () => loadStudentDashboard(refresh: true),
                    ),
                    if (errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _ErrorCard(
                        message: errorMessage,
                        onRetry: () => loadStudentDashboard(refresh: true),
                      ),
                    ],
                    const SizedBox(height: 18),
                    BookyCard(
                      message: bookyGuidanceMessage(nextBestAction),
                    ),
                    if (showFtue) ...[
                      const SizedBox(height: 18),
                      if (ftueProgress.completedStepIds.isEmpty)
                        FtueQuickStartCard(
                          progress: ftueProgress,
                          steps: ftueSteps,
                          onOpenStep: openFtueStep,
                          onDismiss: dismissFtue,
                        )
                      else if (nextFirstStep != null)
                        TimeToValueCard(
                          nextStep: nextFirstStep,
                          completionPercentage:
                              ftueProgress.completionPercentage(
                            ftueSteps.length,
                          ),
                          onContinue: () => openFtueStep(nextFirstStep),
                          onDismiss: dismissFtue,
                        ),
                    ],
                    const SizedBox(height: 18),
                    _IntelligentDayCard(
                      message: intelligentDayMessage(pendingActions),
                      detail: dayDetail,
                    ),
                    const SizedBox(height: 18),
                    NextBestActionCard(
                      action: nextBestAction,
                      isProcessing: nextBestAction != null &&
                          processingActionIds.contains(nextBestAction.id),
                      onPrimary: nextBestAction == null
                          ? () => context.goNamed('voiceTutor')
                          : () => executeAutonomousAction(nextBestAction),
                      onSecondary: () => context.goNamed(
                        'voiceTutor',
                        extra: {
                          'title': nextBestAction?.title ?? 'Tutor IA',
                          'suggested_prompt': nextBestAction?.reason ?? '',
                        },
                      ),
                      onDismiss: nextBestAction == null
                          ? null
                          : () => dismissAutonomousAction(nextBestAction),
                    ),
                    const SizedBox(height: 18),
                    _ContinueLearningCard(
                      item: continueLearning,
                      onContinue: continueLearning.hasProgress
                          ? () => context.goNamed(
                                'audioBookStudio',
                                extra: {
                                  'sourceMode': 'solo',
                                  'sourceType': 'text',
                                },
                              )
                          : null,
                      onCreate: () => context.goNamed(
                        'audioBookStudio',
                        extra: const {
                          'sourceMode': 'solo',
                          'sourceType': 'text',
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    _PrimaryActionsCard(
                      hasProgress: continueLearning.hasProgress,
                      onContinue: continueLearning.hasProgress
                          ? () => context.goNamed(
                                'audioBookStudio',
                                extra: const {
                                  'sourceMode': 'solo',
                                  'sourceType': 'text',
                                },
                              )
                          : null,
                      onCreate: () => context.goNamed(
                        'audioBookStudio',
                        extra: const {
                          'sourceMode': 'solo',
                          'sourceType': 'text',
                        },
                      ),
                      onTutor: () => context.goNamed('voiceTutor'),
                      onProgress: scrollToProgress,
                    ),
                    if (isFreePlan) ...[
                      const SizedBox(height: 18),
                      const _FreePlanNote(),
                    ],
                    const SizedBox(height: 18),
                    AccessibilityCard(
                      preferences: accessibilityPreferences,
                      onAdjust: openAccessibilityPreferences,
                    ),
                    const SizedBox(height: 18),
                    _SmartStudyPlanCard(
                      plan: smartStudyPlan,
                      schedule: adaptiveSchedule,
                    ),
                    const SizedBox(height: 18),
                    _ResponsivePair(
                      left: _AutonomousActionsCard(
                        actions: remainingActions,
                        processingActionIds: processingActionIds,
                        onExecute: executeAutonomousAction,
                        onDismiss: dismissAutonomousAction,
                      ),
                      right: _SmartAlertsCard(
                        history: notificationHistory,
                      ),
                    ),
                    const SizedBox(height: 24),
                    KeyedSubtree(
                      key: progressSectionKey,
                      child: const _DashboardSectionLabel(
                        title: 'Progreso y logros',
                        subtitle:
                            'Mira lo que ya lograste y descubre tu próximo paso.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (analytics.sessions <= 0)
                      PremiumSectionCard(
                        child: StudyBookEmptyState(
                          title: 'Tu progreso comienza aquí',
                          message:
                              'Completa tu primera sesión para que Booky pueda mostrar tu progreso.',
                          actionLabel: 'Crea tu primer AudioBook con Booky',
                          onAction: () => context.goNamed(
                            'audioBookStudio',
                            extra: const {
                              'sourceMode': 'solo',
                              'sourceType': 'text',
                            },
                          ),
                        ),
                      ),
                    if (analytics.sessions > 0) ...[
                      _MetricsGrid(analytics: analytics),
                      const SizedBox(height: 18),
                      _ResponsivePair(
                        left: XpCard(xp: gamificationProfile.xp),
                        right: CurrentLevelWidget(
                          level: gamificationProfile.level,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _ResponsivePair(
                        left: NextLevelWidget(
                          level: gamificationProfile.level,
                        ),
                        right: MissionCard(
                          missions: gamificationProfile.missions,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _ResponsivePair(
                        left: AchievementGrid(
                          achievements: gamificationProfile.achievements,
                        ),
                        right: CoinWalletWidget(
                          wallet: gamificationProfile.wallet,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _ResponsivePair(
                        left: _StreakCard(streak: streak),
                        right: _RecommendationsCard(
                          recommendations: recommendations,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _ResponsivePair(
                        left: _AchievementsCard(
                          achievements: achievements,
                        ),
                        right: _StudentIntelligenceCard(
                          intelligence: intelligence,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _RecentSessionsCard(sessions: recentSessions),
                    ],
                    const SizedBox(height: 24),
                    const _DashboardSectionLabel(
                      title: 'Recursos recomendados',
                      subtitle:
                          'Materiales reales para reforzar tus áreas débiles.',
                    ),
                    const SizedBox(height: 12),
                    _ResponsivePair(
                      left: _RecommendedResourcesCard(
                        items: marketplaceSuggestions,
                      ),
                      right: CreatorProfileWidget(
                        author: marketplaceSuggestions.isEmpty
                            ? const MarketplaceAuthor(name: 'StudyBook AI')
                            : marketplaceSuggestions.first.author,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _DashboardExpansionSection(
                      title: 'Profundizar en mi progreso',
                      subtitle:
                          'Indicadores avanzados disponibles cuando quieras explorar más.',
                      icon: Icons.insights_rounded,
                      children: [
                        _ResponsivePair(
                          left: _CampusIntelligenceCard(
                            snapshot: campusSnapshot,
                          ),
                          right: _EnterpriseAnalyticsCard(
                            analytics: enterpriseAnalytics,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _CampusTrendsCard(
                          trends: campusTrends,
                          latestSnapshot: campusSnapshot,
                        ),
                        const SizedBox(height: 18),
                        _ResponsivePair(
                          left: KnowledgeMapWidget(
                            knowledgeMap: knowledgeMap,
                          ),
                          right: LearningRoadmapWidget(
                            roadmap: learningRoadmap,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _ResponsivePair(
                          left: DigitalTwinWidget(twin: digitalTwin),
                          right: StudyHealthWidget(
                            twin: digitalTwin,
                            productivity: productivity,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _ResponsivePair(
                          left: FocusScoreWidget(
                            focus: productivity.focus,
                          ),
                          right: ProductivityWidget(
                            productivity: productivity,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _ResponsivePair(
                          left: GoalTrackerWidget(goals: studyGoals),
                          right: SuccessPredictionWidget(
                            prediction: successPrediction,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _ResponsivePair(
                          left: RiskMeterWidget(
                            prediction: successPrediction,
                          ),
                          right: SmartTimelineWidget(
                            items: smartTimeline,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const PremiumSectionCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.apartment_rounded,
                            color: AppTheme.textMuted,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Próximamente para instituciones, colegios y universidades.',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  'La versión 1.0 está enfocada en estudiantes y docentes.',
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _DashboardExpansionSection(
                      title: 'Beta y lanzamiento',
                      subtitle:
                          'Comparte tu experiencia o vuelve a consultar la guía inicial.',
                      icon: Icons.rocket_launch_outlined,
                      children: [
                        BetaLaunchCard(
                          report: launchReport,
                          isLoading: isLaunchLoading,
                          onFeedback: openBetaFeedback,
                          onOnboarding: openOnboardingGuide,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isMobile;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  const _Header({
    required this.isMobile,
    required this.isRefreshing,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Mi Aprendizaje',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: isMobile ? 30 : 42,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (isRefreshing)
              const Padding(
                padding: EdgeInsets.all(10),
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                tooltip: 'Actualizar aprendizaje',
                onPressed: onRefresh,
                icon: const Icon(
                  Icons.refresh_rounded,
                  color: AppTheme.textPrimary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Lee menos. Aprende más.',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _IntelligentDayCard extends StatelessWidget {
  final String message;
  final String detail;

  const _IntelligentDayCard({required this.message, required this.detail});

  @override
  Widget build(BuildContext context) {
    return PremiumSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Tu día inteligente',
            icon: Icons.wb_sunny_outlined,
            color: AppTheme.warning,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1.3,
            ),
          ),
          if (detail.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              detail,
              style: const TextStyle(color: AppTheme.textMuted, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashboardSectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;

  const _DashboardSectionLabel({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: AppTheme.textMuted)),
      ],
    );
  }
}

class _DashboardExpansionSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  const _DashboardExpansionSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final border = BorderSide(
      color: Colors.white.withValues(alpha: .08),
    );
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, color: AppTheme.accent),
        title: Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppTheme.textMuted, height: 1.35),
        ),
        tilePadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        childrenPadding: const EdgeInsets.only(top: 12),
        expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
        collapsedShape: Border(top: border, bottom: border),
        shape: Border(top: border, bottom: border),
        children: children,
      ),
    );
  }
}

class _PrimaryActionsCard extends StatelessWidget {
  final bool hasProgress;
  final VoidCallback? onContinue;
  final VoidCallback onCreate;
  final VoidCallback onTutor;
  final VoidCallback onProgress;

  const _PrimaryActionsCard({
    required this.hasProgress,
    required this.onContinue,
    required this.onCreate,
    required this.onTutor,
    required this.onProgress,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu espacio de aprendizaje',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Elige cómo quieres avanzar ahora.',
            style: TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              StudyBookPrimaryButton(
                label: hasProgress
                    ? 'Continúa donde te quedaste'
                    : 'Crea tu primer AudioBook con Booky',
                icon:
                    hasProgress ? Icons.play_arrow_rounded : Icons.add_rounded,
                onPressed: hasProgress ? onContinue : onCreate,
              ),
              StudyBookSecondaryButton(
                label: 'Preguntar a Booky',
                icon: Icons.chat_bubble_outline_rounded,
                onPressed: onTutor,
              ),
              if (hasProgress)
                StudyBookSecondaryButton(
                  label: 'Crear contenido',
                  icon: Icons.add_rounded,
                  onPressed: onCreate,
                ),
              StudyBookSecondaryButton(
                label: 'Ver progreso',
                icon: Icons.insights_rounded,
                onPressed: onProgress,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FreePlanNote extends StatelessWidget {
  const _FreePlanNote();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          'Estás probando StudyBook AI gratis. Puedes crear tu primer recurso y descubrir cómo Booky te ayuda.',
      child: const PremiumSectionCard(
        padding: EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.favorite_outline_rounded, color: AppTheme.accent),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Estás probando StudyBook AI gratis. Puedes crear tu primer recurso y descubrir cómo Booky te ayuda.',
                style: TextStyle(color: AppTheme.textMuted, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueLearningCard extends StatelessWidget {
  final ContinueLearningItem item;
  final VoidCallback? onContinue;
  final VoidCallback onCreate;

  const _ContinueLearningCard({
    required this.item,
    required this.onContinue,
    required this.onCreate,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumSectionCard(
      child: item.hasProgress
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(
                  title: 'Continúa donde te quedaste',
                  icon: Icons.play_circle_fill_rounded,
                  color: AppTheme.accent,
                ),
                const SizedBox(height: 14),
                Text(
                  item.audiobookTitle,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.chapterTitle,
                  style: const TextStyle(color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: item.progressPercentage / 100,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      '${item.progressPercentage}% completado',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: onContinue,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Continuar capítulo'),
                    ),
                  ],
                ),
              ],
            )
          : StudyBookEmptyState(
              title: 'Tu primera experiencia está por comenzar',
              message:
                  'Sube tu primer documento y Booky lo convertirá en conocimiento.',
              actionLabel: 'Crea tu primer AudioBook con Booky',
              onAction: onCreate,
            ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final LearningAnalytics analytics;

  const _MetricsGrid({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final isMobile = ResponsiveLayout.isMobile(context);

    return GridView.count(
      crossAxisCount: isDesktop ? 3 : (isMobile ? 2 : 3),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: isMobile ? 1.12 : 1.85,
      children: [
        _MetricCard(
          title: 'Minutos que dedicaste',
          value: '${analytics.studyMinutes} min',
          icon: Icons.schedule_rounded,
          color: AppTheme.primary,
        ),
        _MetricCard(
          title: 'Sesiones completadas',
          value: '${analytics.sessions}',
          icon: Icons.bolt_rounded,
          color: AppTheme.accent,
        ),
        _MetricCard(
          title: 'Capítulos terminados',
          value: '${analytics.completedChapters}',
          icon: Icons.menu_book_rounded,
          color: AppTheme.success,
        ),
        _MetricCard(
          title: 'Dominio que construyes',
          value: '${analytics.masteryPercentage}%',
          icon: Icons.insights_rounded,
          color: AppTheme.secondary,
        ),
        _MetricCard(
          title: 'Quiz realizados',
          value: '${analytics.quizCompleted}',
          icon: Icons.quiz_rounded,
          color: AppTheme.warning,
        ),
        _MetricCard(
          title: 'Flashcards repasadas',
          value: '${analytics.flashcardsStudied}',
          icon: Icons.style_rounded,
          color: AppTheme.danger,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CampusIntelligenceCard extends StatelessWidget {
  final CampusIntelligenceSnapshot snapshot;

  const _CampusIntelligenceCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Inteligencia de aprendizaje',
            icon: Icons.hub_rounded,
            color: AppTheme.accent,
          ),
          const SizedBox(height: 14),
          Text(
            snapshot.recommendedNextAction,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              Chip(label: Text('Riesgo: ${snapshot.academicRisk}')),
              Chip(label: Text('Dominio: ${snapshot.masteryScore}%')),
              Chip(label: Text('Engagement: ${snapshot.engagementScore}%')),
              Chip(label: Text('Score: ${snapshot.studentScore}%')),
            ],
          ),
          const SizedBox(height: 12),
          if (snapshot.alerts.isEmpty)
            const Text(
              'Sin alertas críticas.',
              style: TextStyle(color: AppTheme.textMuted),
            )
          else
            _ChipGroup(
              title: 'Alertas principales',
              values: snapshot.alerts.take(3).toList(),
            ),
        ],
      ),
    );
  }
}

class _CampusTrendsCard extends StatelessWidget {
  final List<CampusTrend> trends;
  final CampusIntelligenceSnapshot latestSnapshot;

  const _CampusTrendsCard({
    required this.trends,
    required this.latestSnapshot,
  });

  @override
  Widget build(BuildContext context) {
    final mastery = _trendFor('Dominio');
    final engagement = _trendFor('Engagement');
    final risk = _trendFor('Riesgo');
    final score = _trendFor('Score general');

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Tendencias',
            icon: Icons.trending_up_rounded,
            color: AppTheme.secondary,
          ),
          const SizedBox(height: 14),
          _InfoRow(
            label: 'Último snapshot',
            value: _formatDate(latestSnapshot.generatedAt),
          ),
          if (score != null)
            _InfoRow(
              label: 'Comparación anterior',
              value: _deltaLabel(score, suffix: '%'),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (mastery != null)
                _TrendChip(trend: mastery, label: 'Dominio', suffix: '%'),
              if (engagement != null)
                _TrendChip(
                  trend: engagement,
                  label: 'Engagement',
                  suffix: '%',
                ),
              if (risk != null) _TrendChip(trend: risk, label: 'Riesgo'),
            ],
          ),
          const SizedBox(height: 12),
          if (trends.isEmpty)
            const Text(
              'Aún no hay historial suficiente para calcular tendencias.',
              style: TextStyle(color: AppTheme.textMuted),
            )
          else
            for (final trend in trends.take(4))
              _ListItem(
                title: trend.metric,
                subtitle: trend.description,
                icon: _trendIcon(trend.direction),
              ),
        ],
      ),
    );
  }

  CampusTrend? _trendFor(String metric) {
    final cleanMetric = metric.trim().toLowerCase();
    for (final trend in trends) {
      if (trend.metric.trim().toLowerCase() == cleanMetric) return trend;
    }
    return null;
  }

  String _deltaLabel(CampusTrend trend, {String suffix = ''}) {
    if (trend.previousValue <= 0) return 'Sin snapshot anterior';
    final sign = trend.delta > 0 ? '+' : '';
    return '$sign${_formatTrendNumber(trend.delta)}$suffix';
  }

  IconData _trendIcon(String direction) {
    if (direction == 'up') return Icons.trending_up_rounded;
    if (direction == 'down') return Icons.trending_down_rounded;
    return Icons.trending_flat_rounded;
  }
}

class _TrendChip extends StatelessWidget {
  final CampusTrend trend;
  final String label;
  final String suffix;

  const _TrendChip({
    required this.trend,
    required this.label,
    this.suffix = '',
  });

  @override
  Widget build(BuildContext context) {
    final icon = trend.direction == 'up'
        ? Icons.arrow_upward_rounded
        : trend.direction == 'down'
            ? Icons.arrow_downward_rounded
            : Icons.remove_rounded;
    final color = trend.direction == 'up'
        ? AppTheme.success
        : trend.direction == 'down'
            ? AppTheme.warning
            : AppTheme.textMuted;

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        '$label: ${_formatTrendNumber(trend.currentValue)}$suffix',
      ),
    );
  }
}

class _SmartStudyPlanCard extends StatelessWidget {
  final SmartStudyPlan plan;
  final AdaptiveSchedule schedule;

  const _SmartStudyPlanCard({
    required this.plan,
    required this.schedule,
  });

  @override
  Widget build(BuildContext context) {
    final today = plan.days.isNotEmpty ? plan.days.first : null;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Tu plan inteligente',
            icon: Icons.event_note_rounded,
            color: AppTheme.accent,
          ),
          const SizedBox(height: 14),
          Text(
            plan.todayAction.isEmpty ? schedule.nextAction : plan.todayAction,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            label: 'Tiempo sugerido',
            value: '${plan.suggestedMinutes} min',
          ),
          _InfoRow(
            label: 'Próxima actividad',
            value: plan.nextActivity.isEmpty
                ? schedule.nextActivityType
                : plan.nextActivity,
          ),
          _InfoRow(
            label: 'Prioridad',
            value: '${schedule.priority}',
          ),
          const SizedBox(height: 10),
          Text(
            plan.reason.isEmpty ? schedule.reason : plan.reason,
            style: const TextStyle(color: AppTheme.textMuted, height: 1.35),
          ),
          if (today != null) ...[
            const SizedBox(height: 12),
            _ListItem(
              title: today.goal,
              subtitle: today.summary,
              icon: Icons.flag_rounded,
            ),
          ],
        ],
      ),
    );
  }
}

class _SmartAlertsCard extends StatelessWidget {
  final NotificationHistory history;

  const _SmartAlertsCard({required this.history});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Alertas inteligentes',
            icon: Icons.notifications_active_outlined,
            color: AppTheme.warning,
          ),
          const SizedBox(height: 10),
          if (history.items.isEmpty)
            const Text(
              'Todo está en orden por ahora. Te avisaremos cuando algo necesite tu atención.',
              style: TextStyle(color: AppTheme.textMuted),
            )
          else
            for (final item in history.items.take(3))
              _ListItem(
                title: item.title,
                subtitle: item.message,
                icon: item.priority == NotificationPriority.critical ||
                        item.priority == NotificationPriority.high
                    ? Icons.warning_amber_rounded
                    : Icons.lightbulb_outline_rounded,
              ),
        ],
      ),
    );
  }
}

class _AutonomousActionsCard extends StatelessWidget {
  final List<AutonomousAction> actions;
  final Set<String> processingActionIds;
  final Future<void> Function(AutonomousAction action) onExecute;
  final Future<void> Function(AutonomousAction action) onDismiss;

  const _AutonomousActionsCard({
    required this.actions,
    required this.processingActionIds,
    required this.onExecute,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final visibleActions = actions.take(3).toList();
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Acciones inteligentes',
            icon: Icons.auto_awesome_rounded,
            color: AppTheme.accent,
          ),
          const SizedBox(height: 10),
          if (visibleActions.isEmpty)
            const Text(
              'Tu ruta está al día. Cuando quieras, Booky puede ayudarte a elegir el próximo paso.',
              style: TextStyle(color: AppTheme.textMuted),
            )
          else
            for (var index = 0; index < visibleActions.length; index++) ...[
              if (index > 0) const Divider(height: 24),
              _AutonomousActionRow(
                action: visibleActions[index],
                isProcessing:
                    processingActionIds.contains(visibleActions[index].id),
                onExecute: onExecute,
                onDismiss: onDismiss,
              ),
            ],
        ],
      ),
    );
  }
}

class _AutonomousActionRow extends StatelessWidget {
  final AutonomousAction action;
  final bool isProcessing;
  final Future<void> Function(AutonomousAction action) onExecute;
  final Future<void> Function(AutonomousAction action) onDismiss;

  const _AutonomousActionRow({
    required this.action,
    required this.isProcessing,
    required this.onExecute,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = switch (action.priority) {
      AutonomousActionPriority.critical => AppTheme.danger,
      AutonomousActionPriority.high => AppTheme.warning,
      AutonomousActionPriority.normal => AppTheme.accent,
      AutonomousActionPriority.low => AppTheme.textMuted,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.bolt_rounded, color: priorityColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    action.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(_priorityLabel(action.priority)),
                    side:
                        BorderSide(color: priorityColor.withValues(alpha: .3)),
                    backgroundColor: priorityColor.withValues(alpha: .1),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                action.reason,
                style: const TextStyle(color: AppTheme.textMuted, height: 1.35),
              ),
              const SizedBox(height: 10),
              FilledButton(
                onPressed: isProcessing ? null : () => onExecute(action),
                child: isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(action.actionLabel),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Descartar',
          onPressed: isProcessing ? null : () => onDismiss(action),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }

  String _priorityLabel(AutonomousActionPriority priority) {
    return switch (priority) {
      AutonomousActionPriority.critical => 'Crítica',
      AutonomousActionPriority.high => 'Alta',
      AutonomousActionPriority.normal => 'Normal',
      AutonomousActionPriority.low => 'Baja',
    };
  }
}

class _RecommendedResourcesCard extends StatelessWidget {
  final List<MarketplaceItem> items;

  const _RecommendedResourcesCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Recursos recomendados',
            icon: Icons.auto_stories_outlined,
            color: AppTheme.secondary,
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Text(
              'Booky te recomendará recursos después de conocer mejor tu forma de aprender.',
              style: TextStyle(color: AppTheme.textMuted),
            )
          else
            for (final item in items.take(3))
              _ListItem(
                title: item.title,
                subtitle: item.description.isEmpty
                    ? item.categoryId
                    : item.description,
                icon: Icons.menu_book_rounded,
              ),
        ],
      ),
    );
  }
}

class _EnterpriseAnalyticsCard extends StatelessWidget {
  final StudentEnterpriseAnalytics analytics;

  const _EnterpriseAnalyticsCard({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Analítica Avanzada',
            icon: Icons.analytics_rounded,
            color: AppTheme.secondary,
          ),
          const SizedBox(height: 14),
          _InfoRow(
            label: 'Velocidad',
            value: '${analytics.learningVelocity}%',
          ),
          _InfoRow(
            label: 'Retención',
            value: '${analytics.retentionScore}%',
          ),
          _InfoRow(
            label: 'Consistencia',
            value: '${analytics.consistencyScore}%',
          ),
          _InfoRow(
            label: 'Probabilidad de éxito',
            value: '${analytics.predictedSuccessProbability}%',
          ),
          _InfoRow(
            label: 'Riesgo',
            value: analytics.riskTrajectory,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              Chip(label: Text('Esfuerzo: ${analytics.effortScore}%')),
              Chip(label: Text('Tutor IA: ${analytics.voiceEngagement}%')),
              Chip(label: Text('Quiz: ${analytics.quizReliability}%')),
            ],
          ),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final LearningStreak streak;

  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Racha',
            icon: Icons.local_fire_department_rounded,
            color: AppTheme.warning,
          ),
          const SizedBox(height: 16),
          _InfoRow(
              label: 'Racha actual', value: '${streak.currentStreakDays} días'),
          _InfoRow(
              label: 'Mejor racha', value: '${streak.bestStreakDays} días'),
          _InfoRow(
            label: 'Último estudio',
            value: _formatDate(streak.lastStudyDate),
          ),
        ],
      ),
    );
  }
}

class _RecommendationsCard extends StatelessWidget {
  final List<LearningRecommendation> recommendations;

  const _RecommendationsCard({required this.recommendations});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Recomendaciones',
            icon: Icons.tips_and_updates_rounded,
            color: AppTheme.accent,
          ),
          const SizedBox(height: 12),
          if (recommendations.isEmpty)
            const Text(
              'Booky preparará nuevas recomendaciones a medida que avances.',
              style: TextStyle(color: AppTheme.textMuted),
            )
          else
            for (final recommendation in recommendations.take(4))
              _ListItem(
                title: recommendation.title,
                subtitle: recommendation.description,
                icon: Icons.arrow_right_rounded,
              ),
        ],
      ),
    );
  }
}

class _AchievementsCard extends StatelessWidget {
  final List<Achievement> achievements;

  const _AchievementsCard({required this.achievements});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Logros',
            icon: Icons.emoji_events_rounded,
            color: AppTheme.warning,
          ),
          const SizedBox(height: 14),
          if (achievements.isEmpty)
            const Text(
              'Completa tu primera sesión para desbloquear logros.',
              style: TextStyle(color: AppTheme.textMuted),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final achievement in achievements)
                  _AchievementBadge(achievement: achievement),
              ],
            ),
        ],
      ),
    );
  }
}

class _StudentIntelligenceCard extends StatelessWidget {
  final StudentIntelligence intelligence;

  const _StudentIntelligenceCard({required this.intelligence});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Student Intelligence',
            icon: Icons.psychology_rounded,
            color: AppTheme.secondary,
          ),
          const SizedBox(height: 14),
          _InfoRow(label: 'Nivel', value: intelligence.level),
          _InfoRow(label: 'Riesgo', value: intelligence.risk),
          const SizedBox(height: 12),
          _ChipGroup(title: 'Fortalezas', values: intelligence.strengths),
          _ChipGroup(title: 'Debilidades', values: intelligence.weaknesses),
          _ChipGroup(
            title: 'Competencias fuertes',
            values: intelligence.strongCompetencies,
          ),
          _ChipGroup(
            title: 'Competencias débiles',
            values: intelligence.weakCompetencies,
          ),
        ],
      ),
    );
  }
}

class _RecentSessionsCard extends StatelessWidget {
  final List<Map<String, dynamic>> sessions;

  const _RecentSessionsCard({required this.sessions});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Historial reciente',
            icon: Icons.history_rounded,
            color: AppTheme.primary,
          ),
          const SizedBox(height: 12),
          if (sessions.isEmpty)
            const Text(
              'Tu historial aparecerá después de completar una sesión de estudio.',
              style: TextStyle(color: AppTheme.textMuted),
            )
          else
            for (final session in sessions)
              _ListItem(
                title: _cleanText(session['audiobook_id']).isEmpty
                    ? 'Sesión de aprendizaje'
                    : _cleanText(session['audiobook_id']),
                subtitle:
                    '${_formatDate(_dateFrom(session['ended_at']))} · ${_durationLabel(session['duration_seconds'])} · ${_cleanText(session['chapter_id']).isEmpty ? 'Capítulo' : _cleanText(session['chapter_id'])} · Quiz ${_quizLabel(session)} · ${_intFrom(session['flashcards_viewed'])} flashcards',
                icon: Icons.play_lesson_rounded,
              ),
        ],
      ),
    );
  }
}

class _ResponsivePair extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _ResponsivePair({
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveLayout.isMobile(context)) {
      return Column(
        children: [
          left,
          const SizedBox(height: 18),
          right,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 18),
        Expanded(child: right),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionTitle({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textMuted),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ListItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.accent, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final Achievement achievement;

  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final color = achievement.unlocked ? AppTheme.warning : AppTheme.textMuted;

    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: achievement.unlocked ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            achievement.unlocked
                ? Icons.emoji_events_rounded
                : Icons.lock_outline_rounded,
            color: color,
          ),
          const SizedBox(height: 8),
          Text(
            achievement.title,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${achievement.progress}/${achievement.target}',
            style: const TextStyle(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

class _ChipGroup extends StatelessWidget {
  final String title;
  final List<String> values;

  const _ChipGroup({
    required this.title,
    required this.values,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final value in values)
                Chip(
                  label: Text(value),
                  backgroundColor: AppTheme.primary.withValues(alpha: 0.12),
                  labelStyle: const TextStyle(color: AppTheme.textPrimary),
                  side: BorderSide(
                    color: AppTheme.primary.withValues(alpha: 0.18),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppTheme.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Sin registro';
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

String _durationLabel(dynamic seconds) {
  final minutes = (_intFrom(seconds) / 60).round();
  if (minutes <= 0) return '0 min';
  return '$minutes min';
}

String _formatTrendNumber(double value) {
  if (value % 1 == 0) return value.round().toString();
  return value.toStringAsFixed(1);
}

String _quizLabel(Map<String, dynamic> session) {
  final score = _intFrom(session['quiz_score']);
  final total = _intFrom(session['quiz_total']);
  if (total <= 0) return 'sin quiz';
  return '$score/$total';
}

DateTime? _dateFrom(dynamic value) {
  return DateTime.tryParse(value?.toString() ?? '');
}

String _cleanText(dynamic value) {
  return value?.toString().trim() ?? '';
}

int _intFrom(dynamic value) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

String _feedbackCategoryLabel(FeedbackCategory category) {
  return switch (category) {
    FeedbackCategory.bug => 'Algo no funcionó',
    FeedbackCategory.ux => 'Experiencia de usuario',
    FeedbackCategory.performance => 'Rendimiento',
    FeedbackCategory.content => 'Contenido',
    FeedbackCategory.voice => 'Tutor por voz',
    FeedbackCategory.dashboard => 'Dashboard',
    FeedbackCategory.audiobook => 'AudioBook',
    FeedbackCategory.teacher => 'Teacher Studio',
    FeedbackCategory.marketplace => 'Marketplace',
    FeedbackCategory.institution => 'Institution',
  };
}
