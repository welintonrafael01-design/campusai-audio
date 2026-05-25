import 'package:flutter_test/flutter_test.dart';

import 'package:campusai_mobile/main.dart';

void main() {
  testWidgets(
    'StudyBook AI app loads correctly',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const StudyBookApp(),
      );

      expect(
        find.text('StudyBook AI'),
        findsWidgets,
      );
    },
  );
}