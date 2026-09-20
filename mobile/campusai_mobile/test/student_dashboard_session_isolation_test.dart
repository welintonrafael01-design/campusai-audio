import 'dart:async';

import 'package:campusai_mobile/services/security/user_scoped_storage.dart';
import 'package:campusai_mobile/services/student_dashboard_controller.dart';
import 'package:campusai_mobile/services/student_dashboard_session_isolation.dart';
import 'package:flutter_test/flutter_test.dart';

StudentDashboardData dashboardData(String privateTitle) {
  return StudentDashboardData.empty(
    recentSessions: [
      {
        'title': privateTitle,
        'document': privateTitle,
        'recommendation': privateTitle,
        'minutes': privateTitle == 'A-PRIVATE-DOCUMENT' ? 41 : 7,
      },
    ],
  );
}

String privateTitle(StudentDashboardData data) {
  return data.recentSessions.first['title'] as String;
}

void main() {
  setUp(() {
    StudentDashboardSessionIsolation.debugResetForTesting();
    UserScopedStorage.debugSetUserScopeForTesting('user_a');
  });

  tearDown(() {
    StudentDashboardSessionIsolation.debugResetForTesting();
    UserScopedStorage.debugSetUserScopeForTesting(null);
  });

  test('A logout then B never reuses A dashboard data in the same process',
      () async {
    var loadCount = 0;
    final controller = StudentDashboardController(
      dataLoader: (_) async {
        loadCount++;
        return dashboardData(
          UserScopedStorage.currentUserScope == 'user_a'
              ? 'A-PRIVATE-DOCUMENT'
              : 'B-DOCUMENT',
        );
      },
    );

    final userAData = await controller.load();
    expect(privateTitle(userAData), 'A-PRIVATE-DOCUMENT');

    StudentDashboardSessionIsolation.invalidateAuthenticatedState();
    UserScopedStorage.debugSetUserScopeForTesting('user_b');
    final userBData = await controller.load();

    expect(privateTitle(userBData), 'B-DOCUMENT');
    expect(userBData.recentSessions.toString(), isNot(contains('A-PRIVATE')));
    expect(loadCount, 2);
  });

  test('late A result after B login is discarded and cannot overwrite B cache',
      () async {
    final userAResult = Completer<StudentDashboardData>();
    final userBResult = Completer<StudentDashboardData>();
    final controller = StudentDashboardController(
      dataLoader: (_) {
        return UserScopedStorage.currentUserScope == 'user_a'
            ? userAResult.future
            : userBResult.future;
      },
    );

    final lateUserALoad = controller.load();
    StudentDashboardSessionIsolation.invalidateAuthenticatedState();
    UserScopedStorage.debugSetUserScopeForTesting('user_b');
    final userBLoad = controller.load();

    userBResult.complete(dashboardData('B-DOCUMENT'));
    expect(privateTitle(await userBLoad), 'B-DOCUMENT');

    userAResult.complete(dashboardData('A-PRIVATE-DOCUMENT'));
    await expectLater(
      lateUserALoad,
      throwsA(isA<StaleStudentDashboardSession>()),
    );

    expect(privateTitle(await controller.load()), 'B-DOCUMENT');
  });

  test('logout during load invalidates even a new session for the same user',
      () async {
    final oldSessionResult = Completer<StudentDashboardData>();
    var useDelayedResult = true;
    final controller = StudentDashboardController(
      dataLoader: (_) {
        if (useDelayedResult) return oldSessionResult.future;
        return Future.value(dashboardData('A-NEW-SESSION'));
      },
    );

    final oldLoad = controller.load();
    StudentDashboardSessionIsolation.invalidateAuthenticatedState();
    useDelayedResult = false;
    final newLoad = controller.load();
    expect(privateTitle(await newLoad), 'A-NEW-SESSION');

    oldSessionResult.complete(dashboardData('A-PRIVATE-DOCUMENT'));
    await expectLater(
      oldLoad,
      throwsA(isA<StaleStudentDashboardSession>()),
    );
    expect(privateTitle(await controller.load()), 'A-NEW-SESSION');
  });

  test('failed old request cannot replace the new user valid state', () async {
    final userAResult = Completer<StudentDashboardData>();
    final controller = StudentDashboardController(
      dataLoader: (_) async {
        if (UserScopedStorage.currentUserScope == 'user_a') {
          return userAResult.future;
        }
        return dashboardData('B-DOCUMENT');
      },
    );

    final failedUserALoad = controller.load();
    StudentDashboardSessionIsolation.invalidateAuthenticatedState();
    UserScopedStorage.debugSetUserScopeForTesting('user_b');
    expect(privateTitle(await controller.load()), 'B-DOCUMENT');

    userAResult.completeError(StateError('A request failed'));
    await expectLater(failedUserALoad, throwsStateError);
    expect(privateTitle(await controller.load()), 'B-DOCUMENT');
  });

  test('same authenticated session keeps the five-minute cache', () async {
    var loadCount = 0;
    final controller = StudentDashboardController(
      dataLoader: (_) async {
        loadCount++;
        return dashboardData('A-PRIVATE-DOCUMENT');
      },
    );

    expect(privateTitle(await controller.load()), 'A-PRIVATE-DOCUMENT');
    expect(privateTitle(await controller.load()), 'A-PRIVATE-DOCUMENT');
    expect(loadCount, 1);
  });

  test('refresh after account switch loads only the current user', () async {
    var userBLoads = 0;
    final controller = StudentDashboardController(
      dataLoader: (_) async {
        if (UserScopedStorage.currentUserScope == 'user_a') {
          return dashboardData('A-PRIVATE-DOCUMENT');
        }
        userBLoads++;
        return dashboardData('B-DOCUMENT-$userBLoads');
      },
    );

    await controller.load();
    StudentDashboardSessionIsolation.invalidateAuthenticatedState();
    UserScopedStorage.debugSetUserScopeForTesting('user_b');

    expect(privateTitle(await controller.load()), 'B-DOCUMENT-1');
    expect(
      privateTitle(await controller.load(refresh: true)),
      'B-DOCUMENT-2',
    );
  });

  test('session-bound async scope keeps A writes out of B storage scope',
      () async {
    final release = Completer<void>();
    final observedScopes = <String>[];
    final controller = StudentDashboardController(
      dataLoader: (_) async {
        await release.future;
        observedScopes.add(UserScopedStorage.currentUserScope);
        return dashboardData('A-PRIVATE-DOCUMENT');
      },
    );

    final oldLoad = controller.load();
    StudentDashboardSessionIsolation.invalidateAuthenticatedState();
    UserScopedStorage.debugSetUserScopeForTesting('user_b');
    release.complete();

    await expectLater(
      oldLoad,
      throwsA(isA<StaleStudentDashboardSession>()),
    );
    expect(observedScopes, ['user_a']);
  });
}
