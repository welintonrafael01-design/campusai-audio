import 'dart:math' as math;

import 'package:campusai_mobile/theme/app_theme.dart';
import 'package:campusai_mobile/widgets/section_card.dart';
import 'package:campusai_mobile/widgets/studybook/studybook_states.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('primary action colors meet AA contrast with white text', () {
    expect(_contrastRatio(Colors.white, AppTheme.primary),
        greaterThanOrEqualTo(4.5));
    expect(
      _contrastRatio(Colors.white, AppTheme.secondary),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets(
    'shared error state stays actionable at 320 px and text scale 1.3',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var retryCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: const TextScaler.linear(1.3),
              ),
              child: child!,
            );
          },
          home: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SectionCard(
                  child: StudyBookErrorState(
                    message: 'Revisa tu conexión e intenta nuevamente.',
                    onRetry: () => retryCount += 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('No pudimos cargar esta sección'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(tester.takeException(), isNull);

      final button = find.ancestor(
        of: find.text('Reintentar'),
        matching: find.byType(OutlinedButton),
      );
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));

      await tester.tap(find.text('Reintentar'));
      expect(retryCount, 1);
    },
  );
}

double _contrastRatio(Color foreground, Color background) {
  final foregroundLuminance = _relativeLuminance(foreground);
  final backgroundLuminance = _relativeLuminance(background);
  final lighter = math.max(foregroundLuminance, backgroundLuminance);
  final darker = math.min(foregroundLuminance, backgroundLuminance);
  return (lighter + 0.05) / (darker + 0.05);
}

double _relativeLuminance(Color color) {
  double linearize(double channel) => channel <= 0.04045
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();

  return 0.2126 * linearize(color.r) +
      0.7152 * linearize(color.g) +
      0.0722 * linearize(color.b);
}
