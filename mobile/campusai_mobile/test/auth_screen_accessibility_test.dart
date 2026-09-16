import 'package:campusai_mobile/l10n/app_localizations.dart';
import 'package:campusai_mobile/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login exposes localized names for its primary controls',
      (tester) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('es'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: AuthScreen(),
      ),
    );

    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(2));
    expect(find.bySemanticsLabel('Correo electrónico'), findsOneWidget);
    expect(find.bySemanticsLabel('Contraseña'), findsOneWidget);
    expect(find.bySemanticsLabel('Entrar'), findsOneWidget);

    expect(tester.widget<TextField>(fields.at(0)).enabled, isNot(false));
    expect(tester.widget<TextField>(fields.at(1)).enabled, isNot(false));
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );

    semantics.dispose();
  });
}
