import '../learning_engine/learning_session_service.dart';
import '../voice_intelligence/voice_session_service.dart';
import 'campus_intelligence_models.dart';
import 'campus_snapshot_repository.dart';

class CampusTrendService {
  final CampusSnapshotRepository snapshotRepository;
  final LearningSessionService sessionService;
  final VoiceSessionService voiceSessionService;

  const CampusTrendService({
    this.snapshotRepository = const CampusSnapshotRepository(),
    this.sessionService = const LearningSessionService(),
    this.voiceSessionService = const VoiceSessionService(),
  });

  Future<List<CampusTrend>> buildTrends() async {
    try {
      final history = await snapshotRepository.getSnapshotHistory(limit: 20);
      final latest = await snapshotRepository.getLatestSnapshot();
      final ordered = <CampusIntelligenceSnapshot>[
        if (latest != null) latest,
        ...history.where((item) => item.generatedAt != latest?.generatedAt),
      ]..sort((a, b) => b.generatedAt.compareTo(a.generatedAt));

      final current = ordered.isNotEmpty ? ordered.first : null;
      final previous = ordered.length > 1 ? ordered[1] : null;
      final trends = <CampusTrend>[
        if (current != null)
          _trend(
            metric: 'Dominio',
            currentValue: current.masteryScore.toDouble(),
            previousValue: previous?.masteryScore.toDouble() ?? 0,
            suffix: '%',
          ),
        if (current != null)
          _trend(
            metric: 'Engagement',
            currentValue: current.engagementScore.toDouble(),
            previousValue: previous?.engagementScore.toDouble() ?? 0,
            suffix: '%',
          ),
        if (current != null)
          _trend(
            metric: 'Consistencia',
            currentValue: current.consistencyScore.toDouble(),
            previousValue: previous?.consistencyScore.toDouble() ?? 0,
            suffix: '%',
          ),
        if (current != null)
          _trend(
            metric: 'Score general',
            currentValue: current.studentScore.toDouble(),
            previousValue: previous?.studentScore.toDouble() ?? 0,
            suffix: '%',
          ),
        if (current != null)
          _trend(
            metric: 'Riesgo',
            currentValue: _riskValue(current.academicRisk),
            previousValue:
                previous == null ? 0 : _riskValue(previous.academicRisk),
            descriptionBuilder: (currentValue, previousValue, delta) {
              if (previousValue <= 0) {
                return 'Riesgo actual: ${current.academicRisk}.';
              }
              if (delta < 0) return 'El riesgo académico bajó.';
              if (delta > 0) return 'El riesgo académico subió.';
              return 'El riesgo académico se mantiene.';
            },
          ),
      ];

      trends.addAll(await _activityTrends());
      return trends;
    } catch (_) {
      return const [];
    }
  }

  CampusTrend? trendByMetric(List<CampusTrend> trends, String metric) {
    final cleanMetric = metric.trim().toLowerCase();
    for (final trend in trends) {
      if (trend.metric.trim().toLowerCase() == cleanMetric) return trend;
    }
    return null;
  }

  Future<List<CampusTrend>> _activityTrends() async {
    final now = DateTime.now();
    final currentStart = now.subtract(const Duration(days: 7));
    final previousStart = now.subtract(const Duration(days: 14));
    final sessions = await sessionService.getSessions();
    final voiceSessions = await voiceSessionService.getSessions();

    final currentSessions = sessions.where((session) {
      final endedAt = _dateFrom(session['ended_at']);
      return endedAt.isAfter(currentStart) && !endedAt.isAfter(now);
    }).toList();
    final previousSessions = sessions.where((session) {
      final endedAt = _dateFrom(session['ended_at']);
      return endedAt.isAfter(previousStart) && endedAt.isBefore(currentStart);
    }).toList();

    final currentVoice = voiceSessions
        .where((session) =>
            session.updatedAt.isAfter(currentStart) &&
            !session.updatedAt.isAfter(now))
        .length;
    final previousVoice = voiceSessions
        .where((session) =>
            session.updatedAt.isAfter(previousStart) &&
            session.updatedAt.isBefore(currentStart))
        .length;

    return [
      _trend(
        metric: 'Sesiones',
        currentValue: currentSessions.length.toDouble(),
        previousValue: previousSessions.length.toDouble(),
      ),
      _trend(
        metric: 'Tiempo estudiado',
        currentValue: _minutesFrom(currentSessions).toDouble(),
        previousValue: _minutesFrom(previousSessions).toDouble(),
        suffix: ' min',
      ),
      _trend(
        metric: 'Tutor IA',
        currentValue: currentVoice.toDouble(),
        previousValue: previousVoice.toDouble(),
      ),
    ];
  }

  CampusTrend _trend({
    required String metric,
    required double currentValue,
    required double previousValue,
    String suffix = '',
    String Function(double currentValue, double previousValue, double delta)?
        descriptionBuilder,
  }) {
    final delta = currentValue - previousValue;
    final direction = delta > 0
        ? 'up'
        : delta < 0
            ? 'down'
            : 'stable';
    final description = descriptionBuilder?.call(
          currentValue,
          previousValue,
          delta,
        ) ??
        _defaultDescription(metric, currentValue, previousValue, delta, suffix);

    return CampusTrend(
      metric: metric,
      currentValue: currentValue,
      previousValue: previousValue,
      delta: delta,
      direction: direction,
      description: description,
    );
  }

  String _defaultDescription(
    String metric,
    double currentValue,
    double previousValue,
    double delta,
    String suffix,
  ) {
    final current = _formatNumber(currentValue);
    final previous = _formatNumber(previousValue);
    if (previousValue <= 0) return '$metric actual: $current$suffix.';
    if (delta > 0) {
      return '$metric subió de $previous$suffix a $current$suffix.';
    }
    if (delta < 0) return '$metric bajó de $previous$suffix a $current$suffix.';
    return '$metric se mantiene en $current$suffix.';
  }

  int _minutesFrom(List<Map<String, dynamic>> sessions) {
    final seconds = sessions.fold<int>(
      0,
      (sum, session) => sum + _intFrom(session['duration_seconds']),
    );
    return (seconds / 60).round();
  }

  double _riskValue(String risk) {
    final clean = risk.trim().toLowerCase();
    if (clean.contains('alto')) return 3;
    if (clean.contains('medio')) return 2;
    if (clean.contains('bajo')) return 1;
    return 0;
  }

  DateTime _dateFrom(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  int _intFrom(dynamic value) {
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatNumber(double value) {
    if (value % 1 == 0) return value.round().toString();
    return value.toStringAsFixed(1);
  }
}
