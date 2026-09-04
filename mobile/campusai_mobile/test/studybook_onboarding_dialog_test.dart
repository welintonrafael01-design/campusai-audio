import 'dart:async';

import 'package:campusai_mobile/widgets/onboarding/studybook_onboarding_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildDialog(StudyBookOnboardingDialog dialog) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(body: dialog),
      ),
    );
  }

  testWidgets('welcome timeout is recoverable and does not block onboarding',
      (tester) async {
    final pending = Completer<Map<String, dynamic>>();
    await tester.pumpWidget(
      buildDialog(
        StudyBookOnboardingDialog(
          welcomeAudioLoader: (_) => pending.future,
          welcomeAudioTimeout: const Duration(milliseconds: 10),
        ),
      ),
    );

    await tester.tap(find.text('Escuchar bienvenida'));
    await tester.pump();
    expect(find.text('Generando bienvenida...'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();

    expect(find.text('Reintentar bienvenida'), findsOneWidget);
    expect(find.textContaining('tardó demasiado'), findsOneWidget);
    expect(find.text('Saltar por ahora'), findsOneWidget);
    expect(find.text('Empezar con Booky'), findsOneWidget);
  });

  testWidgets('welcome audio success returns the control to its idle state',
      (tester) async {
    var playedUrl = '';
    await tester.pumpWidget(
      buildDialog(
        StudyBookOnboardingDialog(
          welcomeAudioLoader: (_) async => {'audio_url': '/audio/welcome.mp3'},
          welcomeAudioPlayer: (url, _) async {
            playedUrl = url;
          },
        ),
      ),
    );

    await tester.tap(find.text('Escuchar bienvenida'));
    await tester.pumpAndSettle();

    expect(playedUrl, isNotEmpty);
    expect(find.text('Escuchar bienvenida'), findsOneWidget);
    expect(find.textContaining('no pudo'), findsNothing);
  });
}
