import '../config/app_plans.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'plan_guard_service.dart';

class SubscriptionService {
  const SubscriptionService();

  CampusPlan cacheSubscriptionResponse(Map<String, dynamic> response) {
    final plan = planFromCode(response['plan']?.toString());
    final status = response['subscription_status']?.toString() ?? 'unknown';
    final source = response['source']?.toString() ?? 'backend';
    final role = response['role']?.toString();

    const PlanGuardService().saveCurrentPlan(
      plan,
      source: source,
      subscriptionStatus: status,
      serverRole: role,
    );

    return AppPlans.effectivePlan(plan, status);
  }

  Future<CampusPlan> syncCurrentUserPlan() async {
    final user = AuthService.currentUser;

    if (user == null) {
      const PlanGuardService().resetToFree();
      return CampusPlan.free;
    }

    final response = await ApiService.getSubscription();

    return cacheSubscriptionResponse(response);
  }
}
