import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const String _tokenKey = 'token';
  static const String _emailKey = 'email';
  static const String _ageCategoryKey = 'ageCategory';

  static Future<void> saveAuth({
    required String token,
    required String email,
    required String ageCategory,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_ageCategoryKey, ageCategory);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<String?> getAgeCategory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ageCategoryKey);
  }

  static Future<void> saveAgeCategory(String ageCategory) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ageCategoryKey, ageCategory);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_ageCategoryKey);
  }
}