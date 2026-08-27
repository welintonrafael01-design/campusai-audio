import '../qa/qa_manual_checklist_service.dart';
import '../qa/qa_models.dart';
import 'launch_models.dart';
import 'user_feedback_service.dart';

class BetaProgramService {
  final QaManualChecklistService qaChecklistService;
  final UserFeedbackService feedbackService;

  const BetaProgramService({
    this.qaChecklistService = const QaManualChecklistService(),
    this.feedbackService = const UserFeedbackService(),
  });

  List<QaManualChecklistItem> buildRuntimeChecklist() => [
        ...qaChecklistService.buildChecklist(),
        const QaManualChecklistItem(
          title: 'Generar, abrir y continuar un AudioBook',
          area: 'AudioBook',
        ),
        const QaManualChecklistItem(
          title: 'Revisar snapshot y acciones de StudyBook AI',
          area: 'StudyBook AI',
        ),
        const QaManualChecklistItem(
          title: 'Enviar feedback local de beta',
          area: 'Launch',
        ),
      ];

  Future<BetaProgramSummary> buildSummary() async {
    final checklist = buildRuntimeChecklist();
    final feedback = await feedbackService.buildSummary();
    return BetaProgramSummary(
      feedbackChannelReady: true,
      criticalFlowCount: checklist.length,
      feedback: feedback,
      nextSteps: [
        if (feedback.total == 0) 'Recoger feedback de los primeros testers.',
        if (feedback.open > 0) 'Revisar ${feedback.open} reportes abiertos.',
        'Ejecutar el checklist manual en desktop y móvil.',
      ],
    );
  }
}
