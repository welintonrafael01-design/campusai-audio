import 'dart:convert';

import '../../models/study_result.dart';
import '../study_result_service.dart';
import '../gamification/gamification_service.dart';
import 'adaptive_scheduler_service.dart';
import 'campus_intelligence_models.dart';
import 'personal_ai_assistant_memory_service.dart';

class SmartStudyPlannerService {
  static const String planType = 'smart_study_plan';
  static const String latestDocumentId = 'smart_study_plan_latest';

  final AdaptiveSchedulerService schedulerService;
  final PersonalAiAssistantMemoryService assistantMemoryService;
  final GamificationService gamificationService;

  const SmartStudyPlannerService({
    this.schedulerService = const AdaptiveSchedulerService(),
    this.assistantMemoryService = const PersonalAiAssistantMemoryService(),
    this.gamificationService = const GamificationService(),
  });

  Future<SmartStudyPlan> buildPlan({
    int days = 7,
    int dailyMinutes = 45,
    AdaptiveSchedule? schedule,
  }) async {
    try {
      final activeSchedule = schedule ??
          await schedulerService.buildSchedule(
            days: days,
            dailyMinutes: dailyMinutes,
          );
      final memory = await assistantMemoryService.getMemory();
      final gamification = await gamificationService.getLatestProfile();
      final grouped = <String, List<AdaptiveScheduleSlot>>{};
      for (final slot in activeSchedule.slots) {
        final key = _dayKey(slot.recommendedAt);
        grouped.putIfAbsent(key, () => <AdaptiveScheduleSlot>[]).add(slot);
      }

      final studyDays = <SmartStudyDay>[];
      for (final entry in grouped.entries) {
        final slots = entry.value
          ..sort((a, b) => a.recommendedAt.compareTo(b.recommendedAt));
        final studySlots =
            slots.where((slot) => slot.activityType != 'rest').toList();
        final restSlots = slots.where((slot) => slot.activityType == 'rest');
        final primary = studySlots.isNotEmpty
            ? studySlots.first.studyBlock
            : const AdaptiveStudyBlock(
                blockId: 'continue',
                activityType: 'continue',
                title: 'Continuar aprendiendo',
                objective: 'Mantener continuidad con una sesión breve.',
                estimatedMinutes: 12,
                priority: 3,
              );
        final secondary = studySlots.length > 1
            ? studySlots[1].studyBlock
            : const AdaptiveStudyBlock(
                blockId: 'micro_review',
                activityType: 'review',
                title: 'Repaso breve',
                objective: 'Cerrar la sesión recuperando ideas clave.',
                estimatedMinutes: 5,
                priority: 3,
              );
        final studyMinutes = studySlots.fold<int>(
          0,
          (sum, slot) => sum + slot.durationMinutes,
        );
        final restMinutes = restSlots.fold<int>(
          0,
          (sum, slot) => sum + slot.durationMinutes,
        );

        studyDays.add(
          SmartStudyDay(
            date: slots.first.recommendedAt,
            goal: _goalFor(primary.activityType),
            primaryActivity: primary,
            secondaryActivity: secondary,
            studyMinutes: studyMinutes,
            restMinutes: restMinutes,
            summary:
                '${primary.title} durante ${primary.estimatedMinutes} min; luego ${secondary.title}.',
          ),
        );
      }

      studyDays.sort((a, b) => a.date.compareTo(b.date));
      final today = studyDays.isNotEmpty ? studyDays.first : null;
      final plan = SmartStudyPlan(
        generatedAt: DateTime.now(),
        summary: _summary(
          activeSchedule,
          studyDays,
          '${memory?.learningStyle ?? ''}${gamification == null ? '' : ' · nivel ${gamification.level.number}'}',
        ),
        todayAction: today?.primaryActivity.title ?? activeSchedule.nextAction,
        suggestedMinutes: today?.studyMinutes ??
            (activeSchedule.slots.isNotEmpty
                ? activeSchedule.slots.first.durationMinutes
                : 0),
        nextActivity: today?.primaryActivity.activityType ??
            activeSchedule.nextActivityType,
        reason: today?.primaryActivity.reason ?? activeSchedule.reason,
        days: studyDays,
      );

      await _savePlan(plan);
      return plan;
    } catch (_) {
      return SmartStudyPlan.empty();
    }
  }

  Future<SmartStudyPlan?> getLatestPlan() async {
    try {
      final result = await StudyResultService.getResult(
        documentId: latestDocumentId,
        type: planType,
      );
      if (result == null) return null;
      final decoded = jsonDecode(result.content);
      if (decoded is Map) {
        return SmartStudyPlan.fromJson(Map<String, dynamic>.from(decoded));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _savePlan(SmartStudyPlan plan) async {
    if (plan.generatedAt.millisecondsSinceEpoch <= 0) return;
    await StudyResultService.saveResult(
      StudyResult(
        documentId: latestDocumentId,
        type: planType,
        content: jsonEncode(plan.toJson()),
        createdAt: plan.generatedAt.toIso8601String(),
      ),
    );
  }

  String _summary(
    AdaptiveSchedule schedule,
    List<SmartStudyDay> days,
    String learningStyle,
  ) {
    if (days.isEmpty) {
      return 'Plan listo para iniciar con una sesión breve.';
    }
    final minutes = days.fold<int>(0, (sum, day) => sum + day.studyMinutes);
    final style = learningStyle.isEmpty ? '' : ' Estilo: $learningStyle.';
    return 'Plan de ${days.length} días con $minutes minutos sugeridos. '
        'Próxima acción: ${schedule.nextAction}.$style';
  }

  String _goalFor(String activityType) {
    switch (activityType) {
      case 'quiz':
        return 'Comprobar dominio con práctica breve.';
      case 'flashcards':
        return 'Reforzar memoria activa de conceptos clave.';
      case 'tutor':
        return 'Resolver dudas con Tutor IA.';
      case 'audiobook':
        return 'Avanzar contenido sin perder continuidad.';
      case 'rest':
        return 'Recuperar energía cognitiva.';
      case 'review':
        return 'Repasar puntos débiles antes de avanzar.';
      default:
        return 'Mantener progreso constante.';
    }
  }

  String _dayKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }
}
