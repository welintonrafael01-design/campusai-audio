import 'package:campusai_mobile/main.dart';
import 'package:campusai_mobile/services/local_storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> pumpStudyBookApp(
  WidgetTester tester, {
  bool useMockLocalStorage = true,
}) async {
  if (useMockLocalStorage) {
    SharedPreferences.setMockInitialValues({});
  }
  await LocalStorageService.initialize();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    try {
      Supabase.instance.client;
    } catch (_) {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
    }
  }

  await tester.pumpWidget(
    const ProviderScope(
      child: StudyBookApp(),
    ),
  );
  await tester.pumpAndSettle(const Duration(seconds: 2));
}

Finder textAny(List<String> values) {
  return find.byWidgetPredicate((widget) {
    if (widget is Text) {
      final text = widget.data ?? widget.textSpan?.toPlainText() ?? '';
      return values.any(text.contains);
    }
    return false;
  });
}

Future<void> enterAuthCredentials(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  final fields = find.byType(TextField);
  expect(fields, findsAtLeastNWidgets(2));

  await tester.enterText(fields.at(0), email);
  await tester.enterText(fields.at(1), password);
  await tester.pumpAndSettle();
}

Future<void> tapFirstText(
  WidgetTester tester,
  List<String> labels,
) async {
  final finder = textAny(labels);
  expect(finder, findsWidgets);
  await tester.tap(finder.first);
  await tester.pumpAndSettle(const Duration(seconds: 2));
}
