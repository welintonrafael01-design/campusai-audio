import 'package:campusai_mobile/screens/attendance_screen.dart';
import 'package:campusai_mobile/screens/courses_screen.dart';
import 'package:campusai_mobile/screens/final_report_screen.dart';
import 'package:campusai_mobile/screens/gradebook_screen.dart';
import 'package:campusai_mobile/screens/question_bank_screen.dart';
import 'package:campusai_mobile/screens/rubric_screen.dart';
import 'package:campusai_mobile/screens/students_screen.dart';
import 'package:campusai_mobile/screens/teaching_plan_screen.dart';
import 'package:campusai_mobile/services/security/user_scoped_storage.dart';
import 'package:campusai_mobile/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    UserScopedStorage.debugSetUserScopeForTesting('teacher-responsive');
  });

  tearDown(() => UserScopedStorage.debugSetUserScopeForTesting(null));

  testWidgets('Teacher core empty states render at 320px and text scale 1.3',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final screens = <Widget>[
      const CoursesScreen(),
      const StudentsScreen(),
      const AttendanceScreen(),
      const GradebookScreen(),
      const FinalReportScreen(),
      const TeachingPlanScreen(documentId: 'plan-responsive'),
      const RubricScreen(documentId: 'rubric-responsive'),
      const QuestionBankScreen(documentId: 'bank-responsive'),
    ];

    for (final screen in screens) {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
            child: screen,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull,
          reason: screen.runtimeType.toString());
    }
  });
}
