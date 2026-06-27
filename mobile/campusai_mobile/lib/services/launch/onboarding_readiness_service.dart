import 'dart:convert';

import '../../models/study_result.dart';
import '../onboarding_service.dart';
import '../study_result_service.dart';
import 'launch_models.dart';
import 'onboarding_flow_service.dart';

class OnboardingReadinessService {
  static const progressType = 'onboarding_progress';
  static const progressId = 'onboarding_progress_latest';

  final OnboardingService onboardingService;
  final OnboardingFlowService flowService;

  const OnboardingReadinessService({
    this.onboardingService = const OnboardingService(),
    this.flowService = const OnboardingFlowService(),
  });

  Future<OnboardingProgress> loadProgress({String role = 'student'}) async {
    final steps = flowService.stepsForRole(role);
    final result = await StudyResultService.getResult(
      documentId: progressId,
      type: progressType,
    );
    if (result != null) {
      try {
        final decoded = jsonDecode(result.content);
        if (decoded is Map) {
          return OnboardingProgress.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {}
    }
    final alreadyCompleted = !(await onboardingService.shouldShowOnboarding());
    return OnboardingProgress(
      role: role,
      completedStepIds:
          alreadyCompleted ? steps.map((step) => step.id).toList() : const [],
      totalSteps: steps.length,
      updatedAt: DateTime.now(),
    );
  }

  Future<OnboardingProgress> completeStep(
    String stepId, {
    String role = 'student',
  }) async {
    final current = await loadProgress(role: role);
    final completed = {...current.completedStepIds, stepId}.toList();
    final updated = OnboardingProgress(
      role: role,
      completedStepIds: completed,
      totalSteps: flowService.stepsForRole(role).length,
      updatedAt: DateTime.now(),
    );
    await _save(updated);
    if (updated.completed) await onboardingService.markCompleted();
    return updated;
  }

  Future<OnboardingProgress> skip({String role = 'student'}) async {
    final steps = flowService.stepsForRole(role);
    final progress = OnboardingProgress(
      role: role,
      completedStepIds: const [],
      totalSteps: steps.length,
      skipped: true,
      updatedAt: DateTime.now(),
    );
    await _save(progress);
    await onboardingService.markCompleted();
    return progress;
  }

  Future<void> _save(OnboardingProgress progress) =>
      StudyResultService.saveResult(
        StudyResult(
          documentId: progressId,
          type: progressType,
          content: jsonEncode(progress.toJson()),
          createdAt: progress.updatedAt.toIso8601String(),
        ),
      );
}
