import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String localePreferenceKey = 'studybook_locale';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('es')) {
    loadSavedLocale();
  }

  Future<void> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(localePreferenceKey);

    if (code == null || code.trim().isEmpty) {
      state = const Locale('es');
      return;
    }

    state = Locale(code);
  }

  Future<void> changeLocale(String languageCode) async {
    final cleanCode = languageCode.trim();

    if (cleanCode.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      localePreferenceKey,
      cleanCode,
    );

    state = Locale(cleanCode);
  }
}
