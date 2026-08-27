import '../audiobook_progress_service.dart';
import '../learning_engine/achievement_service.dart';
import '../learning_engine/learning_session_service.dart';
import '../voice_intelligence/voice_session_service.dart';
import 'campus_intelligence_models.dart';
import 'campus_snapshot_repository.dart';

class StudentTimelineService {
  final CampusSnapshotRepository snapshotRepository;
  final LearningSessionService sessionService;
  final VoiceSessionService voiceSessionService;
  final AudiobookProgressService audiobookProgressService;
  final AchievementService achievementService;

  const StudentTimelineService({
    this.snapshotRepository = const CampusSnapshotRepository(),
    this.sessionService = const LearningSessionService(),
    this.voiceSessionService = const VoiceSessionService(),
    this.audiobookProgressService = const AudiobookProgressService(),
    this.achievementService = const AchievementService(),
  });

  Future<List<StudentTimelineItem>> buildTimeline({int limit = 30}) async {
    try {
      final snapshots = await snapshotRepository.getSnapshotHistory(limit: 10);
      final latest = await snapshotRepository.getLatestSnapshot();
      final sessions = await sessionService.getSessions();
      final voiceSessions = await voiceSessionService.getSessions();
      final audiobookProgress = await audiobookProgressService.getAllProgress();
      final achievements = await achievementService.getAchievements();
      final items = <StudentTimelineItem>[];

      if (latest != null) {
        items.add(_snapshotItem(latest, 'snapshot_latest'));
        if (latest.recommendedNextAction.trim().isNotEmpty) {
          items.add(
            StudentTimelineItem(
              itemId:
                  'recommendation_${latest.generatedAt.millisecondsSinceEpoch}',
              title: 'Recomendación longitudinal',
              description: latest.recommendedNextAction,
              category: 'recommendation',
              createdAt: latest.generatedAt,
              score: latest.studentScore,
              metadata: {
                'academic_risk': latest.academicRisk,
                'mastery_score': latest.masteryScore,
              },
            ),
          );
        }
      }

      items.addAll(
        snapshots
            .where((snapshot) => snapshot.generatedAt != latest?.generatedAt)
            .map(
              (snapshot) => _snapshotItem(
                snapshot,
                'snapshot_${snapshot.generatedAt.millisecondsSinceEpoch}',
              ),
            ),
      );

      for (final session in sessions.take(12)) {
        final endedAt = _dateFrom(session['ended_at']);
        items.add(
          StudentTimelineItem(
            itemId: _firstText([
              session['session_id'],
              'learning_${endedAt.millisecondsSinceEpoch}',
            ]),
            title: 'Sesión de aprendizaje',
            description:
                '${_durationLabel(session['duration_seconds'])} de estudio'
                '${_cleanText(session['chapter_id']).isEmpty ? '' : ' · ${_cleanText(session['chapter_id'])}'}',
            category: 'learning_session',
            createdAt: endedAt,
            score: _intFrom(session['quiz_score']),
            metadata: {
              'audiobook_id': _cleanText(session['audiobook_id']),
              'chapter_id': _cleanText(session['chapter_id']),
              'flashcards_viewed': _intFrom(session['flashcards_viewed']),
            },
          ),
        );
      }

      for (final session in voiceSessions.take(8)) {
        items.add(
          StudentTimelineItem(
            itemId: session.sessionId,
            title: 'Tutor IA',
            description:
                '${session.messages.length} mensajes · ${session.mode}',
            category: 'voice_session',
            createdAt: session.updatedAt,
            score: session.messages.length,
            metadata: {
              'audiobook_id': session.audiobookId,
              'chapter_id': session.chapterId,
              'status': session.status,
            },
          ),
        );
      }

      for (final progress in audiobookProgress.take(8)) {
        final lastPlayedAt = _dateFrom(progress['last_played_at']);
        if (lastPlayedAt.millisecondsSinceEpoch <= 0) continue;
        items.add(
          StudentTimelineItem(
            itemId: 'audiobook_${_cleanText(progress['audiobook_id'])}',
            title: 'Progreso de AudioBook',
            description:
                '${_intFrom(progress['completion_percentage'])}% completado',
            category: 'audiobook',
            createdAt: lastPlayedAt,
            score: _intFrom(progress['completion_percentage']),
            metadata: {
              'audiobook_id': _cleanText(progress['audiobook_id']),
              'current_chapter_id': _cleanText(progress['current_chapter_id']),
            },
          ),
        );
      }

      for (final achievement in achievements.where((item) => item.unlocked)) {
        items.add(
          StudentTimelineItem(
            itemId: 'achievement_${achievement.id}',
            title: achievement.title,
            description: achievement.description,
            category: 'achievement',
            createdAt: achievement.unlockedAt ?? DateTime.now(),
            score: 100,
            metadata: achievement.toJson(),
          ),
        );
      }

      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items.take(limit < 1 ? 1 : limit).toList();
    } catch (_) {
      return const [];
    }
  }

  StudentTimelineItem _snapshotItem(
    CampusIntelligenceSnapshot snapshot,
    String itemId,
  ) {
    return StudentTimelineItem(
      itemId: itemId,
      title: 'Snapshot StudyBook AI',
      description:
          'Score ${snapshot.studentScore}% · Riesgo ${snapshot.academicRisk}',
      category: 'snapshot',
      createdAt: snapshot.generatedAt,
      score: snapshot.studentScore,
      metadata: {
        'mastery_score': snapshot.masteryScore,
        'engagement_score': snapshot.engagementScore,
        'consistency_score': snapshot.consistencyScore,
      },
    );
  }

  DateTime _dateFrom(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _durationLabel(dynamic secondsValue) {
    final minutes = (_intFrom(secondsValue) / 60).round();
    if (minutes <= 0) return 'Menos de 1 min';
    return '$minutes min';
  }

  String _firstText(List<dynamic> values) {
    for (final value in values) {
      final text = _cleanText(value);
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  String _cleanText(dynamic value) {
    return value?.toString().trim() ?? '';
  }

  int _intFrom(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
