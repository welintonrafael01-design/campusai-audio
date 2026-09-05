import 'package:campusai_mobile/screens/plans_screen.dart';
import 'package:campusai_mobile/services/local_storage_service.dart';
import 'package:campusai_mobile/services/plan_guard_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _plansApp({required double textScale}) {
  return MaterialApp(
    builder: (context, child) {
      final mediaQuery = MediaQuery.of(context);
      return MediaQuery(
        data: mediaQuery.copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: child!,
      );
    },
    home: const PlansScreen(),
  );
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.initialize();
    const PlanGuardService().resetToFree();
  });

  for (final width in const [320.0, 360.0, 430.0]) {
    testWidgets(
      'canonical plans remain responsive at ${width.toInt()} px',
      (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(_plansApp(textScale: 1.3));
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('Free'), findsOneWidget);
        expect(find.text('Student Pro'), findsOneWidget);
        expect(find.text('Teacher Pro'), findsOneWidget);
        expect(find.text('Institution'), findsOneWidget);
        expect(find.text('3 documentos al mes'), findsOneWidget);
        expect(find.text('10 mensajes de Chat IA al mes'), findsOneWidget);
        expect(find.text('Accessibility'), findsNothing);
        expect(find.text('Ultra Premium'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
