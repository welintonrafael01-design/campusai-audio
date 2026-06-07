import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_plans.dart';
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

    final client = Supabase.instance.client;

    final response = await client
        .from('user_subscriptions')
        .select('plan, subscription_status')
        .eq('user_id', user.id)
        .maybeSingle();

    if (response == null) {
      const PlanGuardService().resetToFree();
      return CampusPlan.free;
    }

    final planCode = response['plan']?.toString();
    final status = response['subscription_status']?.toString();

    final plan = status == 'active'
        ? planFromCode(planCode)
        : CampusPlan.free;

    const PlanGuardService().saveCurrentPlan(plan);

    return plan;
  }
}
