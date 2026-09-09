import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yanzee_app/core/api/api_config.dart';
import 'package:yanzee_app/data/models/auth_state.dart';


class DummyAuthCredentials {
  static const String username = 'emilys';
  static const String password = 'emilyspass';
}

class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AuthService {
  
  static Future<UserProfile> login(String email, String password) async {
    late final http.Response res;
    try {
      res = await http.post(
        ApiConfig.login(),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': DummyAuthCredentials.username,
          'password': DummyAuthCredentials.password,
        }),
      );
    } catch (_) {
      throw AuthException('Could not reach the server. Check your connection.');
    }

    if (res.statusCode != 200) {
      throw AuthException('Login failed. Please try again.');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final token = (json['accessToken'] ?? json['token']) as String?;

    final profile = UserProfile.fromDummyJson(json, overrideEmail: email);
    AuthState.instance.login(profile, token: token);
    return profile;
  }

  /// Refreshes the signed-in user's profile from GET /auth/me.
  static Future<UserProfile> fetchMe() async {
    final token = AuthState.instance.token;
    if (token == null) throw AuthException('Not logged in.');

    late final http.Response res;
    try {
      res = await http.get(
        ApiConfig.me(),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (_) {
      throw AuthException('Could not reach the server. Check your connection.');
    }

    if (res.statusCode != 200) {
      throw AuthException('Could not load profile.');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final current = AuthState.instance.user;
    final profile = UserProfile.fromDummyJson(json, overrideEmail: current?.email);
    AuthState.instance.updateProfile(profile);
    return profile;
  }


  static Future<UserProfile> updateProfile({
    required String name,
    required String email,
    required String phone,
    String? image,
  }) async {
    final current = AuthState.instance.user;
    final id = current?.id ?? 1;

    final parts = name.trim().split(RegExp(r'\s+'));
    final firstName = parts.isNotEmpty ? parts.first : '';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

    late final http.Response res;
    try {
      res = await http.put(
        ApiConfig.user(id),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'firstName': firstName, 'lastName': lastName}),
      );
    } catch (_) {
      throw AuthException('Could not reach the server. Check your connection.');
    }

    if (res.statusCode != 200) {
      throw AuthException('Could not save changes.');
    }

    final updated = (current ?? const UserProfile(name: '', email: '')).copyWith(
      name: name,
      email: email,
      phone: phone,
      image: image,
    );
    AuthState.instance.updateProfile(updated);
    return updated;
  }
}