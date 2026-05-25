import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);

class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _themeKey = 'theme_mode';

  ThemeNotifier() : super(ThemeMode.dark) {
    loadTheme();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString(_themeKey);

    if (savedTheme == 'light') {
      state = ThemeMode.light;
      return;
    }

    if (savedTheme == 'dark') {
      state = ThemeMode.dark;
      return;
    }

    state = ThemeMode.dark;
  }

  Future<void> setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();

    state = mode;

    await prefs.setString(
      _themeKey,
      mode == ThemeMode.light ? 'light' : 'dark',
    );
  }

  Future<void> toggleTheme() async {
    if (state == ThemeMode.dark) {
      await setTheme(ThemeMode.light);
    } else {
      await setTheme(ThemeMode.dark);
    }
  }
}