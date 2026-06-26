import 'dart:convert';

import '../../models/study_result.dart';
import '../audiobook_progress_service.dart';
import '../learning_engine/learning_progress_service.dart';
import '../learning_engine/learning_session_service.dart';
import '../study_result_service.dart';
import '../voice_intelligence/voice_session_service.dart';
import 'adaptive_recommendation_service.dart';
import 'campus_intelligence_models.dart';
import 'campus_intelligence_service.dart';
import 'campus_snapshot_repository.dart';
import 'campus_trend_service.dart';
import 'student_timeline_service.dart';

class AdaptiveSchedulerService {
  static const String scheduleType = 'adaptive_schedule';
  static const String latestDocumentId = 'adaptive_schedule_latest';

  final CampusSnapshotRepository snapshotRepository;
  final CampusIntelligenceService campusIntelligenceService;
  final CampusTrendService trendService;
  final StudentTimelineService timelineService;
  final AdaptiveRecommendationService recommendationService;
  final LearningSessionService sessionService;
  final VoiceSessionService voiceSessionService;
  final AudiobookProgressService audiobookProgressService;
  final LearningProgressService progressService;

  const AdaptiveSchedulerService({
    this.snapshotRepository = const CampusSnapshotRepository(),
    this.campusIntelligenceService = const CampusIntelligenceService(),
    this.trendService = const CampusTrendService(),
    this.timelineService = const StudentTimelineService(),
    this.recommendationService = const AdaptiveRecommendationService(),
    this.sessionService = const LearningSessionService(),
    this.voiceSessionService = const VoiceSessionService(),
    this.audiobookProgressService = const AudiobookProgressService(),
    this.progressService = const LearningProgressService(),
  });

  Future<AdaptiveSchedule> buildSchedule({
    int days = 7,
    int dailyMinutes = 45,
  }) async {
    try {
      final safeDays = days.clamp(1, 14);
      final safeDailyMinutes = dailyMinutes.clamp(15, 120);
      final snapshot = await _snapshot();
      final trends = await trendService.buildTrends();
      final timeline = await timelineService.buildTimeline(limit: 20);
      final sessions = await sessionService.getSessions();
      final voiceSessions = await voiceSessionService.getSessions();
      final audiobookProgress = await audiobookProgressService.getAllProgress();
      final progressItems = await progressService.getAllProgress();
      final recommendations =
          await recommendationService.buildRecommendations();
      final bestHour = _bestStudyHour(sessions);
      final blocks = _studyBlocks(
        snapshot: snapshot,
        recommendations: recommendations,
        trends: trends,
        timeline: timeline,
        voiceSessionCount: voiceSessions.length,
        audiobookProgressCount: audiobookProgress.length,
        progressCount: progressItems.length,
      );
      final slots = <AdaptiveScheduleSlot>[];

      for (var dayIndex = 0; dayIndex < safeDays; dayIndex++) {
        final day = DateTime.now().add(Duration(days: dayIndex));
        var usedMinutes = 0;
        var blockIndex = 0;

        while (usedMinutes < safeDailyMinutes && blockIndex < blocks.length) {
          final block = blocks[(dayIndex + blockIndex) % blocks.length];
          final duration =
              block.estimatedMinutes.clamp(5, safeDailyMinutes - usedMinutes);
          if (duration <= 0) break;

          slots.add(
            AdaptiveScheduleSlot(
              slotId: 'slot_${dayIndex}_$blockIndex',
              recommendedAt: DateTime(
                day.year,
                day.month,
                day.day,
                bestHour,
                blockIndex * 20,
              ),
              activityType: block.activityType,
              title: block.title,
              durationMinutes: duration,
              priority: block.priority,
              reason: block.reason,
              studyBlock: block,
            ),
          );
          usedMinutes += duration;
          blockIndex++;

          if (usedMinutes >= safeDailyMinutes - 5) break;
        }

        if (safeDailyMinutes >= 35) {
          slots.add(
            AdaptiveScheduleSlot(
              slotId: 'slot_${dayIndex}_rest',
              recommendedAt: DateTime(
                day.year,
                day.month,
                day.day,
                bestHour,
                50,
              ),
              activityType: 'rest',
              title: 'Descanso activo',
              durationMinutes: 5,
              priority: 4,
              reason: 'Pausas breves ayudan a sostener retención.',
              studyBlock: const AdaptiveStudyBlock(
                blockId: 'rest',
                activityType: 'rest',
                title: 'Descanso activo',
                objective: 'Recuperar atención antes de continuar.',
                estimatedMinutes: 5,
                priority: 4,
                reason: 'Pausas breves ayudan a sostener retención.',
              ),
            ),
          );
        }
      }

      final first = slots.isNotEmpty
          ? slots.first
          : AdaptiveScheduleSlot(
              recommendedAt: DateTime.now(),
              title: snapshot.recommendedNextAction,
            );
      final schedule = AdaptiveSchedule(
        generatedAt: DateTime.now(),
        nextAction: first.title,
        nextActivityType: first.activityType,
        priority: first.priority,
        totalMinutes: slots.fold<int>(
          0,
          (sum, slot) => sum + slot.durationMinutes,
        ),
        reason: first.reason,
        slots: slots,
      );

      await _saveSchedule(schedule);
      return schedule;
    } catch (_) {
      return AdaptiveSchedule.empty();
    }
  }

  Future<AdaptiveSchedule?> getLatestSchedule() async {
    try {
      final result = await StudyResultService.getResult(
        documentId: latestDocumentId,
        type: scheduleType,
      );
      if (result == null) return null;
      final decoded = jsonDecode(result.content);
      if (decoded is Map) {
        return AdaptiveSchedule.fromJson(Map<String, dynamic>.from(decoded));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveSchedule(AdaptiveSchedule schedule) async {
    if (schedule.generatedAt.millisecondsSinceEpoch <= 0) return;
    await StudyResultService.saveResult(
      StudyResult(
        documentId: latestDocumentId,
        type: scheduleType,
        content: jsonEncode(schedule.toJson()),
        createdAt: schedule.generatedAt.toIso8601String(),
      ),
    );
  }

  Future<CampusIntelligenceSnapshot> _snapshot() async {
    final latest = await snapshotRepository.getLatestSnapshot();
    if (latest != null) return latest;
    return campusIntelligenceService.buildSnapshot();
  }

  List<AdaptiveStudyBlock> _studyBlocks({
    required CampusIntelligenceSnapshot snapshot,
    required List<AdaptiveRecommendation> recommendations,
    required List<CampusTrend> trends,
    required List<StudentTimelineItem> timeline,
    required int voiceSessionCount,
    required int audiobookProgressCount,
    required int progressCount,
  }) {
    final blocks = <AdaptiveStudyBlock>[];
    final masteryTrend = trendService.trendByMetric(trends, 'Dominio');
    final recentTutor =
        timeline.any((item) => item.category == 'voice_session');

    for (final action in snapshot.adaptivePlan.take(4)) {
      blocks.add(_blockFromAction(action));
    }

    for (final recommendation in recommendations.take(5)) {
      blocks.add(_blockFromRecommendation(recommendation));
    }

    if ((masteryTrend?.delta ?? 0) < 0) {
      blocks.insert(
        0,
        const AdaptiveStudyBlock(
          blockId: 'mastery_drop_review',
          activityType: 'review',
          title: 'Repaso de recuperación',
          objective: 'Recuperar dominio perdido antes de avanzar.',
          estimatedMinutes: 18,
          priority: 1,
          reason: 'La tendencia de dominio bajó.',
        ),
      );
    }

    if (!recentTutor || voiceSessionCount == 0) {
      blocks.add(
        const AdaptiveStudyBlock(
          blockId: 'voice_tutor_context',
          activityType: 'tutor',
          title: 'Tutor IA contextual',
          objective: 'Resolver una duda concreta por voz.',
          estimatedMinutes: 7,
          priority: 2,
          reason: 'El Tutor IA aún tiene poca interacción registrada.',
        ),
      );
    }

    if (audiobookProgressCount == 0 && progressCount == 0) {
      blocks.add(
        const AdaptiveStudyBlock(
          blockId: 'start_audiobook',
          activityType: 'audiobook',
          title: 'Iniciar AudioBook',
          objective: 'Crear la primera señal de avance.',
          estimatedMinutes: 15,
          priority: 2,
          reason: 'No hay progreso de contenido registrado.',
        ),
      );
    }

    if (blocks.isEmpty) {
      blocks.add(
        AdaptiveStudyBlock(
          blockId: 'continue',
          activityType: 'continue',
          title: snapshot.recommendedNextAction,
          objective: 'Mantener continuidad con una sesión breve.',
          estimatedMinutes: 12,
          priority: 3,
          reason: 'No hay alertas críticas pendientes.',
        ),
      );
    }

    blocks.sort((a, b) => a.priority.compareTo(b.priority));
    return _deduplicateBlocks(blocks).take(8).toList();
  }

  AdaptiveStudyBlock _blockFromAction(AdaptiveLearningAction action) {
    return AdaptiveStudyBlock(
      blockId: action.actionId,
      activityType: _activityType(action.type),
      title: action.title,
      objective: action.description,
      estimatedMinutes: action.estimatedMinutes,
      priority: action.priority,
      reason: action.reason,
      targetId: action.targetId,
    );
  }

  AdaptiveStudyBlock _blockFromRecommendation(
    AdaptiveRecommendation recommendation,
  ) {
    return AdaptiveStudyBlock(
      blockId: recommendation.recommendationId,
      activityType: recommendation.type,
      title: recommendation.title,
      objective: recommendation.description,
      estimatedMinutes: recommendation.estimatedMinutes,
      priority: recommendation.priority,
      reason: recommendation.reason,
      targetId: recommendation.targetId,
    );
  }

  String _activityType(String rawType) {
    final type = rawType.trim().toLowerCase();
    if (type.contains('quiz')) return 'quiz';
    if (type.contains('flashcard')) return 'flashcards';
    if (type.contains('tutor')) return 'tutor';
    if (type.contains('chapter') || type.contains('audiobook')) {
      return 'audiobook';
    }
    if (type.contains('repeat') || type.contains('review')) return 'review';
    return type.isEmpty ? 'continue' : type;
  }

  int _bestStudyHour(List<Map<String, dynamic>> sessions) {
    if (sessions.isEmpty) return 19;
    final counts = <int, int>{};
    for (final session in sessions) {
      final endedAt = DateTime.tryParse(session['ended_at']?.toString() ?? '');
      if (endedAt == null) continue;
      counts[endedAt.hour] = (counts[endedAt.hour] ?? 0) + 1;
    }
    if (counts.isEmpty) return 19;
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key.clamp(6, 22);
  }

  List<AdaptiveStudyBlock> _deduplicateBlocks(
    List<AdaptiveStudyBlock> blocks,
  ) {
    final seen = <String>{};
    final unique = <AdaptiveStudyBlock>[];
    for (final block in blocks) {
      final key = block.blockId.isEmpty
          ? '${block.activityType}_${block.title}'
          : block.blockId;
      if (seen.add(key)) unique.add(block);
    }
    return unique;
  }
}
