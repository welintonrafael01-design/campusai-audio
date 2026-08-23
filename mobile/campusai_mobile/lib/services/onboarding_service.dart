import 'package:shared_preferences/shared_preferences.dart';

import 'security/user_scoped_storage.dart';

class OnboardingService {
  static const String _completedKey = 'studybook_onboarding_completed';
  static String get _scopedCompletedKey => UserScopedStorage.key(_completedKey);

  const OnboardingService();

  Future<bool> shouldShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    return !(prefs.getBool(_scopedCompletedKey) ?? false);
  }

  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_scopedCompletedKey, true);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_scopedCompletedKey);
  }
}
