import 'package:shared_preferences/shared_preferences.dart';

class AcademicPeriodLockService {
  static const String _prefix = 'studybook_academic_period_closed_';

  static Future<bool> isClosed(String courseId) async {
    if (courseId.trim().isEmpty) return false;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_prefix$courseId') ?? false;
  }

  static Future<void> setClosed({
    required String courseId,
    required bool closed,
  }) async {
    if (courseId.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$courseId', closed);
  }
}
