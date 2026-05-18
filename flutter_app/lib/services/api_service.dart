import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_storage.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    } else {
      return 'https://ertegi-app.onrender.com';
    }
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
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'prompt': prompt,
        'ageCategory': ageCategory,
        'category': category,
        'language': language,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 400) {
      throw Exception(data['message'] ?? data['error'] ?? 'AI error');
    }

    return data;
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

    final data = jsonDecode(response.body);

    if (response.statusCode >= 400) {
      throw Exception(data['message'] ?? 'Register error');
    }

    return data;
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

    final data = jsonDecode(response.body);

    if (response.statusCode >= 400) {
      throw Exception(data['message'] ?? 'Login error');
    }

    return data;
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

    final data = jsonDecode(response.body);

    if (response.statusCode >= 400) {
      throw Exception(data['message'] ?? 'Google login error');
    }

    return data;
  }

  static Future<Map<String, dynamic>> getStories() async {
    final token = await AuthStorage.getToken();

    final response = await http.get(
      Uri.parse('$baseUrl/api/stories'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 400) {
      throw Exception(data['message'] ?? 'Stories error');
    }

    return data;
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
    } catch (e) {
      print("TTS API error: $e");
      return null;
    }
  }
  static Future<Map<String, dynamic>> saveFilter(String ageCategory) async {
    final token = await AuthStorage.getToken();

    final response = await http.post(
      Uri.parse('$baseUrl/api/filter'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'ageCategory': ageCategory,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode >= 400) {
      throw Exception(data['message'] ?? 'Filter error');
    }

    return data;
  }
}