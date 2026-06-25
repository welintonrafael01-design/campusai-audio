import 'learning_models.dart';
import 'learning_session_service.dart';

/// Calculates study streaks from completed learning sessions.
class StreakService {
  final LearningSessionService sessionService;

  const StreakService({
    this.sessionService = const LearningSessionService(),
  });

  Future<LearningStreak> calculateStreak() async {
    try {
      final sessions = await sessionService.getSessions();
      final studyDates = sessions
          .map((session) => _dateOnly(_dateFrom(session['ended_at'])))
          .whereType<DateTime>()
          .toSet()
          .toList()
        ..sort();

      if (studyDates.isEmpty) return LearningStreak.empty;

      return LearningStreak(
        currentStreakDays: _currentStreak(studyDates),
        bestStreakDays: _bestStreak(studyDates),
        lastStudyDate: studyDates.last,
        studyDates: studyDates,
      );
    } catch (_) {
      return LearningStreak.empty;
    }
  }

  int _currentStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;

    var cursor = _dateOnly(DateTime.now())!;
    if (dates.last.isBefore(cursor.subtract(const Duration(days: 1)))) {
      return 0;
    }
    if (dates.last == cursor.subtract(const Duration(days: 1))) {
      cursor = dates.last;
    }

    var streak = 0;
    final dateSet = dates.map((date) => date.toIso8601String()).toSet();
    while (dateSet.contains(cursor.toIso8601String())) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _bestStreak(List<DateTime> dates) {
    if (dates.isEmpty) return 0;

    var best = 1;
    var current = 1;
    for (var index = 1; index < dates.length; index++) {
      final previous = dates[index - 1];
      final currentDate = dates[index];
      if (currentDate.difference(previous).inDays == 1) {
        current++;
      } else {
        current = 1;
      }
      if (current > best) best = current;
    }
    return best;
  }

  DateTime? _dateFrom(dynamic raw) {
    return DateTime.tryParse(raw?.toString() ?? '');
  }

  DateTime? _dateOnly(DateTime? date) {
    if (date == null) return null;
    return DateTime(date.year, date.month, date.day);
  }
}
