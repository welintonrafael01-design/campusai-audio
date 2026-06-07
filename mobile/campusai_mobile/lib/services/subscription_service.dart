import '../config/app_plans.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'plan_guard_service.dart';

class SubscriptionService {
  const SubscriptionService();

  Future<CampusPlan> syncCurrentUserPlan() async {
    final user = AuthService.currentUser;

    if (user == null) {
      const PlanGuardService().resetToFree();
      return CampusPlan.free;
    }

    final response = await ApiService.getSubscription(
      userId: user.id,
    );

    final planCode = response['plan']?.toString();
    final status = response['subscription_status']?.toString();
    final source = response['source']?.toString() ?? 'backend';

    final plan = status == 'active'
        ? planFromCode(planCode)
        : CampusPlan.free;

    const PlanGuardService().saveCurrentPlan(
      plan,
      source: source,
      subscriptionStatus: status ?? 'unknown',
    );

    return plan;
  }
}
