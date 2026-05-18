import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

final ValueNotifier<ThemeMode> themeNotifier =
ValueNotifier<ThemeMode>(ThemeMode.light);

class AppTheme {
  static const String _themeKey = 'themeMode';

  static Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themeKey);

    if (value == 'dark') {
      themeNotifier.value = ThemeMode.dark;
    } else {
      themeNotifier.value = ThemeMode.light;
    }
  }

  static Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();

    if (themeNotifier.value == ThemeMode.dark) {
      themeNotifier.value = ThemeMode.light;
      await prefs.setString(_themeKey, 'light');
    } else {
      themeNotifier.value = ThemeMode.dark;
      await prefs.setString(_themeKey, 'dark');
    }
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorSchemeSeed: const Color(0xFF7E57C2),
    scaffoldBackgroundColor: const Color(0xFFFFF7F0),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF7E57C2),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorSchemeSeed: const Color(0xFFB388FF),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
  );
}