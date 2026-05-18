import 'dart:convert';
import 'package:http/http.dart' as http;

import 'auth_storage.dart';

class ApiService {
  static String get baseUrl {
    return 'https://ertegiapp-production.up.railway.app';
  }

  static Future<Map<String, dynamic>> generateStory({
    required String prompt,
    required String ageCategory,
    required String category,
    required String language,
  }) async {
    final token = await AuthStorage.getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/api/story/generate'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'prompt': prompt,
        'ageCategory': ageCategory,
        'category': category,
        'language': language,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String ageCategory,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'ageCategory': ageCategory,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> googleLogin({
    required String email,
    required String firebaseUid,
    String? name,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'firebaseUid': firebaseUid,
        'name': name,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getStories() async {
    final token = await AuthStorage.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/api/stories'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      },
    );

    return jsonDecode(response.body);
  }

  static Future<String?> tts(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/tts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      final data = jsonDecode(response.body);
      return data['url'];
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>> saveFilter(
    String ageCategory,
  ) async {
    final token = await AuthStorage.getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/api/filter'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'ageCategory': ageCategory,
      }),
    );

    return jsonDecode(response.body);
  }
}