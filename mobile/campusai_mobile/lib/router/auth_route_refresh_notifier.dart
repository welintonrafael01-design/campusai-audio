import 'dart:async';

import 'package:flutter/foundation.dart';

/// Refreshes route guards when the authentication state changes.
///
/// Supabase restores persisted sessions asynchronously. Keeping this listener
/// independent from Supabase makes the router behavior easy to verify and
/// avoids coupling route construction to SDK initialization order.
class AuthRouteRefreshNotifier extends ChangeNotifier {
  StreamSubscription<Object?>? _subscription;

  Future<void> bind(Stream<Object?> authStateChanges) async {
    await _subscription?.cancel();
    _subscription = authStateChanges.listen((_) => notifyListeners());
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final authRouteRefreshNotifier = AuthRouteRefreshNotifier();
