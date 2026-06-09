import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _completedKey = 'studybook_onboarding_completed';

  const OnboardingService();

  Future<bool> shouldShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();

    return !(prefs.getBool(_completedKey) ?? false);
  }

  Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_completedKey, true);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_completedKey);
  }
}
