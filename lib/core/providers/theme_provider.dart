import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeMode = prefs.getString('themeMode');

    if (savedThemeMode != null) {
      state = _themeModeFromValue(savedThemeMode);
      return;
    }

    final legacyIsDark = prefs.getBool('isDarkMode');
    if (legacyIsDark == null) {
      state = ThemeMode.system;
      return;
    }

    state = legacyIsDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  Future<void> setLightMode() async {
    await setThemeMode(ThemeMode.light);
  }

  Future<void> setDarkMode() async {
    await setThemeMode(ThemeMode.dark);
  }

  Future<void> setSystemMode() async {
    await setThemeMode(ThemeMode.system);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', mode.name);
    await prefs.setBool('isDarkMode', mode == ThemeMode.dark);
  }

  ThemeMode _themeModeFromValue(String value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}
