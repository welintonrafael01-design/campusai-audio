import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:campusai_mobile/main.dart';
import 'package:campusai_mobile/services/local_storage_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService.initialize();
  });

  testWidgets(
    'StudyBook AI app loads correctly',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: StudyBookApp(),
        ),
      );

      expect(
        find.text('StudyBook AI'),
        findsWidgets,
      );
    },
  );
}
