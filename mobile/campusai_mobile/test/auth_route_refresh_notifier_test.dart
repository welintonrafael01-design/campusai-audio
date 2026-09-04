import 'dart:async';

import 'package:campusai_mobile/router/auth_route_refresh_notifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('refreshes route guards for restored and changed auth states', () async {
    final authStates = StreamController<Object?>();
    final notifier = AuthRouteRefreshNotifier();
    var refreshCount = 0;
    notifier.addListener(() => refreshCount++);

    await notifier.bind(authStates.stream);
    expect(refreshCount, 1);

    authStates.add('initialSession');
    await Future<void>.delayed(Duration.zero);
    expect(refreshCount, 2);

    authStates.add('signedOut');
    await Future<void>.delayed(Duration.zero);
    expect(refreshCount, 3);

    notifier.dispose();
    await authStates.close();
  });

  test('rebinding stops listening to the previous auth stream', () async {
    final first = StreamController<Object?>();
    final second = StreamController<Object?>();
    final notifier = AuthRouteRefreshNotifier();
    var refreshCount = 0;
    notifier.addListener(() => refreshCount++);

    await notifier.bind(first.stream);
    await notifier.bind(second.stream);
    expect(refreshCount, 2);

    first.add('stale');
    second.add('current');
    await Future<void>.delayed(Duration.zero);
    expect(refreshCount, 3);

    notifier.dispose();
    await first.close();
    await second.close();
  });
}
