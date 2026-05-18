import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  kk,
  ru,
  en,
}

final ValueNotifier<AppLanguage> languageNotifier =
ValueNotifier<AppLanguage>(AppLanguage.kk);

class LanguageService {
  static const String _key = 'app_language';

  static Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);

    if (saved == 'ru') {
      languageNotifier.value = AppLanguage.ru;
    } else if (saved == 'en') {
      languageNotifier.value = AppLanguage.en;
    } else {
      languageNotifier.value = AppLanguage.kk;
    }
  }

  static Future<void> setLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();

    languageNotifier.value = language;

    if (language == AppLanguage.kk) {
      await prefs.setString(_key, 'kk');
    } else if (language == AppLanguage.ru) {
      await prefs.setString(_key, 'ru');
    } else {
      await prefs.setString(_key, 'en');
    }
  }

  static String languageName(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.kk:
        return 'Қазақша';
      case AppLanguage.ru:
        return 'Русский';
      case AppLanguage.en:
        return 'English';
    }
  }

  static String get code {
    switch (languageNotifier.value) {
      case AppLanguage.kk:
        return 'kk';
      case AppLanguage.ru:
        return 'ru';
      case AppLanguage.en:
        return 'en';
    }
  }
}